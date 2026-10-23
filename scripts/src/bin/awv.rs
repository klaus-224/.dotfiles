//! awv — AWS Resource Viewer (fzf-powered)
//!
//! Interactive viewer for AWS resources via CloudFormation,
//! S3, ECS Fargate, Step Functions, and IAM.
//! Dependencies: aws CLI v2, fzf, dasel

use std::env;
use std::process::{Command, Stdio, exit};

use dotfiles_scripts::{capture, die, exit_like, filter, has_command, shell_quote, status};

const USAGE: &str = "\
awv — AWS Resource Viewer

Usage: awv [--profile <profile>] [--auth login|sso] <command>

Commands:
  stacks    CloudFormation stacks (list, resources, outputs, events)
  s3        S3 buckets and object browser
  ecs       ECS Fargate clusters, services, and tasks
  sfn       Step Functions state machines and executions
  iam       IAM roles, users, and policies

Options:
  --profile <name>   AWS profile to use (passed to all aws calls)
  --auth <mode>      Auth mode to use: login or sso
                     Defaults to AWV_AUTH_MODE, or login if unset

If no command is given, an interactive picker is shown.";

fn main() {
    check_deps();

    let mut awv = Awv {
        opts: Vec::new(),
        auth_mode: env::var("AWV_AUTH_MODE").unwrap_or_else(|_| "login".to_owned()),
    };

    let mut args = env::args().skip(1).peekable();
    while let Some(option) = args.next_if(|arg| arg.starts_with('-')) {
        match option.as_str() {
            "--profile" => {
                let profile = args
                    .next()
                    .filter(|value| !value.is_empty())
                    .unwrap_or_else(|| die("awv: --profile requires a value"));
                awv.opts.extend(["--profile".to_owned(), profile]);
            }
            "--auth" => {
                awv.auth_mode = args
                    .next()
                    .filter(|value| !value.is_empty())
                    .unwrap_or_else(|| die("awv: --auth requires a value: login or sso"));
                if !matches!(awv.auth_mode.as_str(), "login" | "sso") {
                    invalid_auth_mode(&awv.auth_mode);
                }
            }
            "--help" | "-h" => {
                println!("{USAGE}");
                return;
            }
            _ => die(format!("awv: unknown option: {option}")),
        }
    }

    awv.require_session();

    let Some(command) = args.next().or_else(|| {
        awv.fzf(
            &lines(["stacks", "s3", "ecs", "sfn", "iam"]),
            &["--header=awv — pick a service", "--prompt=awv> "],
        )
    }) else {
        return;
    };

    match command.as_str() {
        "stacks" => awv.stacks(),
        "s3" => awv.s3(),
        "ecs" => awv.ecs(),
        "sfn" => awv.sfn(),
        "iam" => awv.iam(),
        _ => {
            eprintln!("awv: unknown command: {command}");
            println!("{USAGE}");
            exit(1);
        }
    }
}

fn check_deps() {
    let missing: Vec<&str> = ["aws", "fzf", "dasel"]
        .into_iter()
        .filter(|cmd| !has_command(cmd))
        .collect();
    if !missing.is_empty() {
        eprintln!("awv: missing dependencies: {}", missing.join(" "));
        eprintln!("  brew install {}", missing.join(" "));
        exit(1);
    }
}

fn invalid_auth_mode(mode: &str) -> ! {
    eprintln!("awv: invalid auth mode: {mode}");
    eprintln!("awv: expected one of: login, sso");
    exit(1);
}

struct Awv {
    /// Global options passed to every aws call, such as `--profile`.
    opts: Vec<String>,
    auth_mode: String,
}

impl Awv {
    fn aws(&self, args: &[&str]) -> Command {
        let mut command = Command::new("aws");
        command.args(args).args(&self.opts);
        command
    }

    /// `aws` and its global options, quoted for an fzf preview command.
    fn aws_sh(&self, args: &str) -> String {
        let opts: Vec<String> = self.opts.iter().map(|opt| shell_quote(opt)).collect();
        format!("aws {args} {}", opts.join(" "))
    }

    /// Text output of an aws call, or `None` if it fails.
    fn aws_text(&self, args: &[&str]) -> Option<String> {
        capture(&mut self.aws(args))
    }

    /// Pick a line with fzf, or `None` if the picker is cancelled.
    fn fzf(&self, input: &str, args: &[&str]) -> Option<String> {
        filter(
            Command::new("fzf")
                .args(["--height=80%", "--layout=reverse", "--border", "--ansi"])
                .args(args),
            input,
        )
        .map(|selection| selection.trim_end_matches('\n').to_owned())
    }

    /// Show a final list and print whatever the user selects.
    fn view(&self, input: &str, args: &[&str]) {
        if let Some(selection) = self.fzf(input, args) {
            println!("{selection}");
        }
    }

    // ── Auth ─────────────────────────────────────────────

    fn require_session(&self) {
        let identity = || self.aws(&["sts", "get-caller-identity"]);
        if status(identity().stdout(Stdio::null()).stderr(Stdio::null())).success() {
            return;
        }

        eprintln!("AWS session expired or not configured.");

        let login: &[&str] = match self.auth_mode.as_str() {
            "login" => &["login"],
            "sso" => &["sso", "login"],
            mode => invalid_auth_mode(mode),
        };
        eprintln!("Running: aws {} {}", login.join(" "), self.opts.join(" "));
        let login = status(&mut self.aws(login));
        if !login.success() {
            exit_like(login);
        }

        let check = status(identity().stdout(Stdio::null()));
        if !check.success() {
            exit_like(check);
        }
    }

    // ── CloudFormation Stacks ────────────────────────────

    fn stacks(&self) {
        let Some(stacks) = self.aws_text(&[
            "cloudformation",
            "list-stacks",
            "--stack-status-filter",
            "CREATE_COMPLETE",
            "UPDATE_COMPLETE",
            "UPDATE_ROLLBACK_COMPLETE",
            "ROLLBACK_COMPLETE",
            "DELETE_FAILED",
            "IMPORT_COMPLETE",
            "--query",
            "StackSummaries[].{Name:StackName,Status:StackStatus,Updated:LastUpdatedTime}",
            "--output",
            "text",
        ]) else {
            return;
        };

        let preview = format!(
            "--preview={} | dasel -i json -o yaml 'Stacks[0].Outputs'",
            self.aws_sh("cloudformation describe-stacks --stack-name {1} --output json"),
        );
        let Some(stack) = self.fzf(
            &sorted(&stacks),
            &[
                "--header=STACK NAME | STATUS | LAST UPDATED",
                &preview,
                "--preview-window=right:50%:wrap",
                "--prompt=stacks> ",
            ],
        ) else {
            return;
        };
        let Some(stack_name) = first_field(&stack) else {
            return;
        };

        let Some(view) = self.fzf(
            &lines(["resources", "outputs", "events"]),
            &[
                &format!("--header=Stack: {stack_name} — pick view"),
                "--prompt=view> ",
            ],
        ) else {
            return;
        };

        match view.as_str() {
            "resources" => {
                let Some(resources) = self.aws_text(&[
                    "cloudformation",
                    "describe-stack-resources",
                    "--stack-name",
                    stack_name,
                    "--query",
                    "StackResources[].{Type:ResourceType,LogicalId:LogicalResourceId,Status:ResourceStatus,PhysicalId:PhysicalResourceId}",
                    "--output",
                    "text",
                ]) else {
                    return;
                };
                self.view(
                    &sorted(&resources),
                    &[
                        "--header=TYPE | LOGICAL ID | STATUS | PHYSICAL ID",
                        &format!("--prompt=resources({stack_name})> "),
                        "--preview=echo {}",
                        "--preview-window=down:3:wrap",
                    ],
                );
            }
            "outputs" => {
                let Some(outputs) = self.aws_text(&[
                    "cloudformation",
                    "describe-stacks",
                    "--stack-name",
                    stack_name,
                    "--query",
                    "Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}",
                    "--output",
                    "text",
                ]) else {
                    return;
                };
                self.view(
                    &outputs,
                    &[
                        "--header=OUTPUT KEY | VALUE",
                        &format!("--prompt=outputs({stack_name})> "),
                    ],
                );
            }
            "events" => {
                let Some(events) = self.aws_text(&[
                    "cloudformation",
                    "describe-stack-events",
                    "--stack-name",
                    stack_name,
                    "--query",
                    "StackEvents[].{Time:Timestamp,Resource:LogicalResourceId,Status:ResourceStatus,Reason:ResourceStatusReason}",
                    "--output",
                    "text",
                ]) else {
                    return;
                };
                self.view(
                    &head(&events, 50),
                    &[
                        "--header=TIMESTAMP | RESOURCE | STATUS | REASON",
                        &format!("--prompt=events({stack_name})> "),
                        "--preview=echo {}",
                        "--preview-window=down:3:wrap",
                    ],
                );
            }
            _ => {}
        }
    }

    // ── S3 ───────────────────────────────────────────────

    fn s3(&self) {
        let Some(buckets) = self.aws_text(&[
            "s3api",
            "list-buckets",
            "--query",
            "Buckets[].{Name:Name,Created:CreationDate}",
            "--output",
            "text",
        ]) else {
            return;
        };
        let Some(bucket) = self.fzf(
            &sorted(&buckets),
            &["--header=BUCKET NAME | CREATED", "--prompt=s3> "],
        ) else {
            return;
        };
        let Some(bucket_name) = first_field(&bucket) else {
            return;
        };

        let mut prefix = String::new();
        loop {
            let Some(listing) = capture(
                self.aws(&["s3", "ls", &format!("s3://{bucket_name}/{prefix}")])
                    .stderr(Stdio::null()),
            ) else {
                return;
            };
            let Some(selection) = self.fzf(
                &listing,
                &[
                    &format!("--header=s3://{bucket_name}/{prefix}"),
                    &format!("--prompt=s3({bucket_name})> "),
                    "--expect=ctrl-h",
                ],
            ) else {
                return;
            };

            // --expect prints the pressed key (empty for enter), then the selection.
            let (key, line) = selection.split_once('\n').unwrap_or((&selection, ""));

            if key == "ctrl-h" {
                prefix = parent_prefix(&prefix);
                continue;
            }

            if let Some((_, dir)) = line.split_once("PRE ") {
                prefix.push_str(dir.split(' ').next().unwrap_or_default());
            } else {
                let file_name = line.split_whitespace().last().unwrap_or_default();
                let key = format!("{prefix}{file_name}");
                println!("s3://{bucket_name}/{key}");
                status(
                    self.aws(&[
                        "s3api",
                        "head-object",
                        "--bucket",
                        bucket_name,
                        "--key",
                        &key,
                        "--output",
                        "yaml",
                    ])
                    .stderr(Stdio::null()),
                );
                break;
            }
        }
    }

    // ── ECS Fargate ──────────────────────────────────────

    fn ecs(&self) {
        let Some(clusters) = self.aws_text(&[
            "ecs",
            "list-clusters",
            "--query",
            "clusterArns[]",
            "--output",
            "text",
        ]) else {
            return;
        };
        let Some(cluster) = self
            .fzf(
                &arn_names(&clusters),
                &["--header=ECS CLUSTERS", "--prompt=ecs> "],
            )
            .filter(|cluster| !cluster.is_empty())
        else {
            return;
        };

        let Some(services) = self.aws_text(&[
            "ecs",
            "list-services",
            "--cluster",
            &cluster,
            "--query",
            "serviceArns[]",
            "--output",
            "text",
        ]) else {
            return;
        };
        let preview = format!(
            "--preview={}",
            self.aws_sh(&format!(
                "ecs describe-services --cluster {} --services {{1}} --query 'services[0].{{Status:status,Desired:desiredCount,Running:runningCount,TaskDef:taskDefinition}}' --output yaml",
                shell_quote(&cluster),
            )),
        );
        let Some(service) = self
            .fzf(
                &arn_names(&services),
                &[
                    &format!("--header=SERVICES in {cluster}"),
                    &format!("--prompt=ecs({cluster})> "),
                    &preview,
                    "--preview-window=right:50%:wrap",
                ],
            )
            .filter(|service| !service.is_empty())
        else {
            return;
        };

        let Some(tasks) = self.aws_text(&[
            "ecs",
            "list-tasks",
            "--cluster",
            &cluster,
            "--service-name",
            &service,
            "--query",
            "taskArns[]",
            "--output",
            "text",
        ]) else {
            return;
        };
        let tasks: Vec<&str> = tasks.split_whitespace().collect();
        if tasks.is_empty() {
            eprintln!("No running tasks for {service}");
            return;
        }

        let mut args = vec!["ecs", "describe-tasks", "--cluster", &cluster, "--tasks"];
        args.extend(&tasks);
        args.extend([
            "--query",
            "tasks[].{TaskId:taskArn,Status:lastStatus,Health:healthStatus,CPU:cpu,Memory:memory,StartedAt:startedAt}",
            "--output",
            "text",
        ]);
        let Some(details) = self.aws_text(&args) else {
            return;
        };
        self.view(
            &details,
            &[
                &format!(
                    "--header=TASKS in {service} | TASK ARN | STATUS | HEALTH | CPU | MEM | STARTED"
                ),
                &format!("--prompt=tasks({service})> "),
                "--preview=echo {}",
                "--preview-window=down:3:wrap",
            ],
        );
    }

    // ── Step Functions ───────────────────────────────────

    fn sfn(&self) {
        let Some(machines) = self.aws_text(&[
            "stepfunctions",
            "list-state-machines",
            "--query",
            "stateMachines[].{Name:name,Arn:stateMachineArn}",
            "--output",
            "text",
        ]) else {
            return;
        };
        let Some(machine) = self.fzf(
            &machines,
            &["--header=STATE MACHINE NAME | ARN", "--prompt=sfn> "],
        ) else {
            return;
        };
        let mut fields = machine.split_whitespace();
        let (Some(name), Some(arn)) = (fields.next(), fields.next()) else {
            return;
        };

        let Some(executions) = self.aws_text(&[
            "stepfunctions",
            "list-executions",
            "--state-machine-arn",
            arn,
            "--max-results",
            "20",
            "--query",
            "executions[].{Name:name,Status:status,Start:startDate,Stop:stopDate}",
            "--output",
            "text",
        ]) else {
            return;
        };
        let execution_arn = self.aws_sh(&format!(
            "stepfunctions list-executions --state-machine-arn {} --query \"executions[?name=='{{1}}'].executionArn\" --output text",
            shell_quote(arn),
        ));
        let preview = format!(
            "--preview={} 2>/dev/null || echo 'No details'",
            self.aws_sh(&format!(
                "stepfunctions describe-execution --execution-arn $({execution_arn}) --output yaml"
            )),
        );
        self.view(
            &executions,
            &[
                &format!("--header=EXECUTIONS for {name} | NAME | STATUS | START | STOP"),
                &format!("--prompt=sfn({name})> "),
                &preview,
                "--preview-window=right:50%:wrap",
            ],
        );
    }

    // ── IAM ──────────────────────────────────────────────

    fn iam(&self) {
        let Some(category) = self.fzf(
            &lines(["roles", "users", "policies"]),
            &["--header=IAM — pick category", "--prompt=iam> "],
        ) else {
            return;
        };

        let (list, header, preview): (&[&str], &str, &str) = match category.as_str() {
            "roles" => (
                &[
                    "iam",
                    "list-roles",
                    "--query",
                    "Roles[].{RoleName:RoleName,Arn:Arn,Created:CreateDate}",
                ],
                "ROLE NAME | ARN | CREATED",
                "iam list-attached-role-policies --role-name {1} --output yaml",
            ),
            "users" => (
                &[
                    "iam",
                    "list-users",
                    "--query",
                    "Users[].{UserName:UserName,Arn:Arn,Created:CreateDate}",
                ],
                "USER NAME | ARN | CREATED",
                "iam list-attached-user-policies --user-name {1} --output yaml",
            ),
            "policies" => (
                &[
                    "iam",
                    "list-policies",
                    "--scope",
                    "Local",
                    "--query",
                    "Policies[].{PolicyName:PolicyName,Arn:Arn,Updated:UpdateDate}",
                ],
                "POLICY NAME | ARN | UPDATED",
                "iam get-policy --policy-arn {2} --output yaml",
            ),
            _ => return,
        };

        let Some(items) = self.aws_text(&[list, &["--output", "text"]].concat()) else {
            return;
        };
        self.view(
            &sorted(&items),
            &[
                &format!("--header={header}"),
                &format!("--prompt=iam({category})> "),
                &format!("--preview={}", self.aws_sh(preview)),
                "--preview-window=right:50%:wrap",
            ],
        );
    }
}

fn lines<const N: usize>(items: [&str; N]) -> String {
    items.map(|item| format!("{item}\n")).concat()
}

fn sorted(text: &str) -> String {
    let mut lines: Vec<&str> = text.lines().collect();
    lines.sort_unstable();
    lines.iter().map(|line| format!("{line}\n")).collect()
}

fn head(text: &str, count: usize) -> String {
    text.lines()
        .take(count)
        .map(|line| format!("{line}\n"))
        .collect()
}

fn first_field(line: &str) -> Option<&str> {
    line.split_whitespace().next()
}

/// Resource names from whitespace-separated ARNs: `arn:...:cluster/name` -> `name`.
fn arn_names(arns: &str) -> String {
    arns.split_whitespace()
        .map(|arn| format!("{}\n", arn.rsplit('/').next().unwrap_or(arn)))
        .collect()
}

/// `a/b/` -> `a/`, `a/` -> ``
fn parent_prefix(prefix: &str) -> String {
    let trimmed = prefix.strip_suffix('/').unwrap_or(prefix);
    match trimmed.rfind('/') {
        Some(index) => trimmed[..=index].to_owned(),
        None => String::new(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parent_prefix_moves_up_one_level() {
        assert_eq!(parent_prefix("a/b/"), "a/");
        assert_eq!(parent_prefix("a/"), "");
        assert_eq!(parent_prefix(""), "");
    }

    #[test]
    fn arn_names_keep_the_last_path_segment() {
        assert_eq!(
            arn_names("arn:aws:ecs:r:1:cluster/one\tarn:aws:ecs:r:1:cluster/two\n"),
            "one\ntwo\n",
        );
    }

    #[test]
    fn first_field_splits_tab_separated_output() {
        assert_eq!(first_field("stack\tCREATE_COMPLETE\t2026"), Some("stack"));
    }
}
