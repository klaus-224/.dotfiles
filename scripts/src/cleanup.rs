//! Interactive cleanup of local branches and worktrees, shared by `gbd` and `gwd`.
//!
//! - Lists local branches and detached worktrees (or only worktrees), tagged
//!   `merged`, `gone` (upstream deleted), `wt`, `dirty`, and `locked`.
//! - Hides the default branch, the branch checked out in the main worktree,
//!   and the worktree you are standing in.
//! - Removes a worktree before its branch. Asks before discarding a dirty
//!   worktree or deleting an unmerged branch, and once more before running.

use std::collections::HashMap;
use std::io::{self, BufRead, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use serde_json::Value;

use crate::{capture, die, filter, has_command, read, status};

#[derive(Debug, Default, PartialEq)]
struct Worktree {
    path: PathBuf,
    branch: Option<String>,
    locked: bool,
}

struct Entry {
    branch: Option<String>,
    worktree: Option<PathBuf>,
    locked: bool,
    dirty: bool,
    merged: bool,
    gone: bool,
    upstream: Option<String>,
    /// Commit the local branch points at.
    tip: String,
    pr: PrStatus,
    age: String,
    subject: String,
}

/// The pull request for a branch, as far as `gh` can tell.
#[derive(Clone, Debug, PartialEq)]
enum PrStatus {
    /// `gh` is missing, failed, or the entry has no branch.
    Unknown,
    Missing,
    Found(Pr),
}

#[derive(Clone, Debug, PartialEq)]
struct Pr {
    number: u64,
    state: PrState,
    /// Head commit of the PR branch.
    head: String,
}

#[derive(Clone, Copy, Debug, PartialEq, PartialOrd)]
enum PrState {
    Open,
    Merged,
    Closed,
}

#[derive(Debug, PartialEq)]
enum Step {
    RemoveWorktree { path: PathBuf, force: bool },
    DeleteBranch { name: String, force: bool },
    DeleteRemote { name: String },
}

/// What a cleanup command lists and deletes.
pub struct Options {
    /// Name used in messages, such as `gbd`.
    pub name: &'static str,
    /// List only worktrees, not branches without one.
    pub worktrees_only: bool,
    /// Delete each picked worktree's branch as well.
    pub delete_branches: bool,
    /// Delete each picked branch on origin as well.
    pub remote: bool,
}

/// Pick entries with fzf, confirm, then delete them. Exits 1 if a step fails.
pub fn run(opts: &Options) {
    let name = opts.name;
    if !has_command("fzf") {
        die(format!("{name}: fzf is required"));
    }

    // Drop records for worktree directories that no longer exist.
    status(Command::new("git").args(["worktree", "prune"]));

    let worktrees = parse_worktrees(&read(Command::new("git").args([
        "worktree",
        "list",
        "--porcelain",
    ])));
    let main = worktrees
        .first()
        .unwrap_or_else(|| die(format!("{name}: no worktrees found")));
    let here = git_path(&["rev-parse", "--show-toplevel"]);
    let base = default_branch();

    let mut protected = vec![base.clone()];
    protected.extend(main.branch.clone());
    protected.extend(
        worktrees
            .iter()
            .filter(|wt| Some(&wt.path) == here.as_ref())
            .filter_map(|wt| wt.branch.clone()),
    );

    let mut entries = entries(&worktrees, &base, &protected, here.as_deref());
    if opts.worktrees_only {
        entries.retain(|e| e.worktree.is_some());
    }
    if entries.is_empty() {
        println!("Nothing to delete.");
        return;
    }

    let width = entries
        .iter()
        .map(|e| label(e).chars().count())
        .max()
        .unwrap_or(0);
    // Hidden fields carry the index, the ref to log, and the worktree path.
    let lines: String = entries
        .iter()
        .enumerate()
        .map(|(i, e)| {
            let wt = e.worktree.as_deref().unwrap_or(Path::new(""));
            let rev = e.branch.as_deref().unwrap_or("HEAD");
            format!("{i}\t{rev}\t{}\t{}\n", wt.display(), display(e, width))
        })
        .collect();
    let preview = "wt={3}; if [ -d \"$wt\" ]; then \
         git -C \"$wt\" log --color=always --oneline --graph -20 HEAD; \
         echo; echo \"── $wt\"; git -C \"$wt\" status --short; \
         else git log --color=always --oneline --graph -20 {2} --; fi";

    let picked = filter(
        Command::new("fzf").args([
            "--multi",
            "--height=80%",
            "--reverse",
            "--delimiter=\t",
            "--with-nth=4",
            &format!("--header=Base: {base}. TAB to select, ENTER to review, ESC to cancel"),
            &format!("--preview={preview}"),
            "--preview-window=right:55%",
        ]),
        &lines,
    );
    let Some(picked) = picked else {
        println!("Nothing selected");
        return;
    };

    // Ask about anything risky per entry; any "no" keeps the whole entry.
    let mut confirmed = Vec::new();
    for index in picked
        .lines()
        .filter_map(|line| line.split('\t').next()?.parse::<usize>().ok())
    {
        let entry = &entries[index];
        if entry.locked {
            println!(
                "Skip {}: worktree is locked; run `git worktree unlock <path>` first",
                label(entry)
            );
            continue;
        }
        if warnings(entry, opts.delete_branches, &base)
            .iter()
            .any(|warning| !ask(&format!("{warning} Continue?")))
        {
            println!("Keeping {}", label(entry));
            continue;
        }
        confirmed.extend(plan(entry, opts.delete_branches, opts.remote));
    }
    if confirmed.is_empty() {
        return;
    }

    println!();
    for step in &confirmed {
        println!("  {}", describe(step));
    }
    if !ask("Run these steps?") {
        println!("Nothing changed");
        return;
    }

    let mut failed = false;
    for step in &confirmed {
        if !execute(step).success() {
            failed = true;
            eprintln!("{name}: failed: {}", describe(step));
        }
    }
    if failed {
        std::process::exit(1);
    }
}

fn entries(
    worktrees: &[Worktree],
    base: &str,
    protected: &[String],
    here: Option<&Path>,
) -> Vec<Entry> {
    let refs = read(Command::new("git").args([
        "for-each-ref",
        "--sort=-committerdate",
        "--format=%(refname:short)%09%(objectname)%09%(upstream:short)%09%(upstream:track)%09%(committerdate:relative)%09%(subject)",
        "refs/heads",
    ]));
    let merged_into = merge_targets(base);
    let prs = pull_requests();

    let mut entries: Vec<Entry> = refs
        .lines()
        .filter_map(|line| {
            let mut fields = line.splitn(6, '\t');
            let name = fields.next()?.to_owned();
            let tip = fields.next()?.to_owned();
            let upstream = fields.next().filter(|s| !s.is_empty()).map(str::to_owned);
            let gone = fields.next() == Some("[gone]");
            let age = fields.next().unwrap_or_default().to_owned();
            let subject = fields.next().unwrap_or_default().to_owned();
            if protected.contains(&name) {
                return None;
            }
            let wt = worktrees
                .iter()
                .find(|wt| wt.branch.as_deref() == Some(&name));
            let merged = merged_into
                .iter()
                .chain(upstream.iter().filter(|_| !gone))
                .any(|target| is_ancestor(&name, target));
            let pr = match &prs {
                None => PrStatus::Unknown,
                Some(prs) => prs
                    .get(&name)
                    .cloned()
                    .map_or(PrStatus::Missing, PrStatus::Found),
            };
            Some(Entry {
                worktree: wt.map(|wt| wt.path.clone()),
                locked: wt.is_some_and(|wt| wt.locked),
                dirty: wt.is_some_and(|wt| is_dirty(&wt.path)),
                branch: Some(name),
                merged,
                gone,
                upstream,
                pr,
                tip,
                age,
                subject,
            })
        })
        .collect();

    // Detached worktrees have no branch but can still be removed.
    entries.extend(
        worktrees
            .iter()
            .skip(1)
            .filter(|wt| wt.branch.is_none() && Some(wt.path.as_path()) != here)
            .map(|wt| Entry {
                branch: None,
                worktree: Some(wt.path.clone()),
                locked: wt.locked,
                dirty: is_dirty(&wt.path),
                merged: false,
                gone: false,
                upstream: None,
                tip: String::new(),
                pr: PrStatus::Unknown,
                age: String::new(),
                subject: String::from("(detached)"),
            }),
    );
    entries
}

/// Reasons to double-check before removing a selected entry.
fn warnings(entry: &Entry, delete_branch: bool, base: &str) -> Vec<String> {
    let name = label(entry);
    let mut warnings = Vec::new();
    if entry.dirty {
        warnings.push(format!(
            "{name} has uncommitted or untracked files that will be discarded."
        ));
    }
    let landed = entry.merged || pr_merged_at_tip(entry);
    match &entry.pr {
        PrStatus::Missing if !landed => warnings.push(format!("{name} has no pull request.")),
        PrStatus::Found(pr) if pr.state == PrState::Open => {
            warnings.push(format!("{name} has an open pull request (#{}).", pr.number))
        }
        _ => {}
    }
    if delete_branch && entry.branch.is_some() && !landed {
        warnings.push(format!(
            "{name} is not merged into {base}; deleting the branch loses its commits."
        ));
    }
    warnings
}

/// A merged PR whose head is the local tip means the work landed, even if it
/// was squashed or rebased so Git cannot see the merge.
fn pr_merged_at_tip(entry: &Entry) -> bool {
    matches!(&entry.pr, PrStatus::Found(pr) if pr.state == PrState::Merged && pr.head == entry.tip)
}

/// Turn a selected entry into the steps that remove it.
fn plan(entry: &Entry, delete_branch: bool, remote: bool) -> Vec<Step> {
    let mut steps = Vec::new();
    if let Some(path) = &entry.worktree {
        steps.push(Step::RemoveWorktree {
            path: path.clone(),
            force: entry.dirty,
        });
    }
    if let Some(name) = entry.branch.as_ref().filter(|_| delete_branch) {
        steps.push(Step::DeleteBranch {
            name: name.clone(),
            force: !entry.merged,
        });
        if remote
            && !entry.gone
            && let Some(remote_branch) = entry
                .upstream
                .as_deref()
                .and_then(|up| up.strip_prefix("origin/"))
        {
            steps.push(Step::DeleteRemote {
                name: remote_branch.to_owned(),
            });
        }
    }
    steps
}

fn execute(step: &Step) -> std::process::ExitStatus {
    let mut git = Command::new("git");
    match step {
        Step::RemoveWorktree { path, force } => {
            git.args(["worktree", "remove"]);
            if *force {
                git.arg("--force");
            }
            git.arg(path)
        }
        Step::DeleteBranch { name, force } => {
            git.args(["branch", if *force { "-D" } else { "-d" }, name])
        }
        Step::DeleteRemote { name } => git.args(["push", "origin", "--delete", name]),
    };
    status(&mut git)
}

fn describe(step: &Step) -> String {
    match step {
        Step::RemoveWorktree { path, force } => format!(
            "remove worktree {}{}",
            path.display(),
            if *force { " (force)" } else { "" }
        ),
        Step::DeleteBranch { name, force } => format!(
            "delete branch {name}{}",
            if *force { " (force, -D)" } else { "" }
        ),
        Step::DeleteRemote { name } => format!("delete origin/{name}"),
    }
}

fn label(entry: &Entry) -> String {
    match (&entry.branch, &entry.worktree) {
        (Some(name), _) => name.clone(),
        (None, Some(path)) => path.display().to_string(),
        (None, None) => String::new(),
    }
}

fn display(entry: &Entry, width: usize) -> String {
    let pr = match &entry.pr {
        PrStatus::Unknown => String::new(),
        PrStatus::Missing => String::from("no-pr"),
        PrStatus::Found(pr) => {
            let state = match pr.state {
                PrState::Open => "open",
                PrState::Merged => "merged",
                PrState::Closed => "closed",
            };
            format!("pr#{}:{state}", pr.number)
        }
    };
    let mut tags: Vec<&str> = [
        (entry.merged, "merged"),
        (entry.gone, "gone"),
        (entry.worktree.is_some(), "wt"),
        (entry.dirty, "dirty"),
        (entry.locked, "locked"),
    ]
    .into_iter()
    .filter_map(|(on, tag)| on.then_some(tag))
    .collect();
    if !pr.is_empty() {
        tags.push(&pr);
    }
    format!(
        "{:width$}  {:<32}  {:<14}  {}",
        label(entry),
        tags.join(","),
        entry.age,
        entry.subject,
    )
}

/// Parse `git worktree list --porcelain`. The main worktree comes first.
fn parse_worktrees(porcelain: &str) -> Vec<Worktree> {
    porcelain
        .split("\n\n")
        .filter_map(|block| {
            let mut wt = Worktree::default();
            for line in block.lines() {
                if let Some(path) = line.strip_prefix("worktree ") {
                    wt.path = PathBuf::from(path);
                } else if let Some(branch) = line.strip_prefix("branch refs/heads/") {
                    wt.branch = Some(branch.to_owned());
                } else if line == "locked" || line.starts_with("locked ") {
                    wt.locked = true;
                }
            }
            (!wt.path.as_os_str().is_empty()).then_some(wt)
        })
        .collect()
}

/// Pull requests by head branch from `gh`, or `None` if it is unavailable.
/// When a branch has several, an open PR wins over a merged one over a closed one.
fn pull_requests() -> Option<HashMap<String, Pr>> {
    if !has_command("gh") {
        return None;
    }
    let output = Command::new("gh")
        .args([
            "pr",
            "list",
            "--state=all",
            "--limit=1000",
            "--json=number,state,headRefName,headRefOid",
        ])
        .stderr(Stdio::null())
        .output()
        .ok()
        .filter(|out| out.status.success())?;
    parse_pull_requests(&String::from_utf8_lossy(&output.stdout))
}

fn parse_pull_requests(json: &str) -> Option<HashMap<String, Pr>> {
    let list: Value = serde_json::from_str(json).ok()?;
    let mut prs: HashMap<String, Pr> = HashMap::new();
    for item in list.as_array()? {
        let state = match item["state"].as_str()? {
            "OPEN" => PrState::Open,
            "MERGED" => PrState::Merged,
            _ => PrState::Closed,
        };
        let pr = Pr {
            number: item["number"].as_u64()?,
            state,
            head: item["headRefOid"].as_str()?.to_owned(),
        };
        // gh lists newest first, so keep the first PR of each state.
        let branch = item["headRefName"].as_str()?.to_owned();
        if prs.get(&branch).is_none_or(|kept| pr.state < kept.state) {
            prs.insert(branch, pr);
        }
    }
    Some(prs)
}

/// `origin/HEAD` names the default branch; fall back to `main`.
fn default_branch() -> String {
    capture(
        Command::new("git")
            .args([
                "symbolic-ref",
                "--quiet",
                "--short",
                "refs/remotes/origin/HEAD",
            ])
            .stderr(Stdio::null()),
    )
    .and_then(|name| name.trim().strip_prefix("origin/").map(str::to_owned))
    .unwrap_or_else(|| String::from("main"))
}

/// Refs a branch counts as merged into: the local and remote default branch.
fn merge_targets(base: &str) -> Vec<String> {
    [base.to_owned(), format!("origin/{base}")]
        .into_iter()
        .filter(|target| {
            Command::new("git")
                .args(["rev-parse", "--verify", "--quiet", target])
                .stdout(Stdio::null())
                .status()
                .is_ok_and(|s| s.success())
        })
        .collect()
}

fn is_ancestor(commit: &str, target: &str) -> bool {
    Command::new("git")
        .args(["merge-base", "--is-ancestor", commit, target])
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|s| s.success())
}

fn is_dirty(path: &Path) -> bool {
    Command::new("git")
        .arg("-C")
        .arg(path)
        .args(["status", "--porcelain"])
        .stderr(Stdio::null())
        .output()
        .map_or(true, |out| !out.stdout.is_empty())
}

fn git_path(args: &[&str]) -> Option<PathBuf> {
    capture(Command::new("git").args(args)).map(|out| PathBuf::from(out.trim()))
}

/// Ask a yes/no question on the terminal; anything but `y` means no.
fn ask(question: &str) -> bool {
    print!("{question} [y/N] ");
    let _ = io::stdout().flush();
    let mut answer = String::new();
    io::stdin().lock().read_line(&mut answer).is_ok() && matches!(answer.trim(), "y" | "Y" | "yes")
}

#[cfg(test)]
mod tests {
    use super::*;

    fn entry() -> Entry {
        Entry {
            branch: Some("feat/x".into()),
            worktree: None,
            locked: false,
            dirty: false,
            merged: true,
            gone: false,
            upstream: None,
            tip: String::from("abc"),
            pr: PrStatus::Unknown,
            age: String::new(),
            subject: String::new(),
        }
    }

    fn pr(state: PrState, head: &str) -> PrStatus {
        PrStatus::Found(Pr {
            number: 7,
            state,
            head: head.into(),
        })
    }

    #[test]
    fn parse_worktrees_reads_branches_and_locks() {
        let porcelain = "worktree /code/repo\nHEAD a\nbranch refs/heads/main\n\n\
                         worktree /code/repo-worktrees/feat/x\nHEAD b\nbranch refs/heads/feat/x\nlocked reason\n\n\
                         worktree /code/repo-worktrees/tmp\nHEAD c\ndetached\n";
        assert_eq!(
            parse_worktrees(porcelain),
            [
                Worktree {
                    path: "/code/repo".into(),
                    branch: Some("main".into()),
                    locked: false
                },
                Worktree {
                    path: "/code/repo-worktrees/feat/x".into(),
                    branch: Some("feat/x".into()),
                    locked: true
                },
                Worktree {
                    path: "/code/repo-worktrees/tmp".into(),
                    branch: None,
                    locked: false
                },
            ]
        );
    }

    #[test]
    fn plan_removes_the_worktree_before_the_branch() {
        let e = Entry {
            worktree: Some("/wt".into()),
            dirty: true,
            merged: false,
            ..entry()
        };
        assert_eq!(
            plan(&e, true, false),
            [
                Step::RemoveWorktree {
                    path: "/wt".into(),
                    force: true
                },
                Step::DeleteBranch {
                    name: "feat/x".into(),
                    force: true
                },
            ]
        );
    }

    #[test]
    fn plan_deletes_the_remote_only_when_asked_and_present() {
        let e = Entry {
            upstream: Some("origin/feat/x".into()),
            ..entry()
        };
        assert_eq!(plan(&e, true, false).len(), 1);
        assert_eq!(
            plan(&e, true, true).last(),
            Some(&Step::DeleteRemote {
                name: "feat/x".into()
            })
        );
        let gone = Entry { gone: true, ..e };
        assert_eq!(plan(&gone, true, true).len(), 1);
    }

    #[test]
    fn plan_keeps_the_branch_unless_asked() {
        let e = Entry {
            worktree: Some("/wt".into()),
            upstream: Some("origin/feat/x".into()),
            ..entry()
        };
        assert_eq!(
            plan(&e, false, true),
            [Step::RemoveWorktree {
                path: "/wt".into(),
                force: false
            }]
        );
    }

    #[test]
    fn warnings_flag_missing_and_open_pull_requests() {
        let missing = Entry {
            merged: false,
            pr: PrStatus::Missing,
            ..entry()
        };
        assert!(warnings(&missing, false, "main")[0].contains("no pull request"));
        let open = Entry {
            pr: pr(PrState::Open, "abc"),
            ..entry()
        };
        assert!(warnings(&open, false, "main")[0].contains("open pull request (#7)"));
        let unknown = Entry {
            merged: false,
            ..entry()
        };
        assert!(warnings(&unknown, false, "main").is_empty());
    }

    #[test]
    fn a_merged_pr_at_the_tip_counts_as_merged() {
        let squashed = Entry {
            merged: false,
            pr: pr(PrState::Merged, "abc"),
            ..entry()
        };
        assert!(warnings(&squashed, true, "main").is_empty());
        let moved_on = Entry {
            pr: pr(PrState::Merged, "old"),
            ..squashed
        };
        assert!(warnings(&moved_on, true, "main")[0].contains("not merged"));
    }

    #[test]
    fn parse_pull_requests_prefers_open_then_merged() {
        let json = r#"[
            {"number": 3, "state": "CLOSED", "headRefName": "a", "headRefOid": "c3"},
            {"number": 2, "state": "MERGED", "headRefName": "a", "headRefOid": "c2"},
            {"number": 1, "state": "OPEN", "headRefName": "b", "headRefOid": "c1"}
        ]"#;
        let prs = parse_pull_requests(json).expect("valid json");
        assert_eq!(prs["a"].number, 2);
        assert_eq!(prs["b"].state, PrState::Open);
    }
}
