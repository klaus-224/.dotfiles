//! mnemonic: [P]ackage [J]son [S]cripts
//! Browse scripts in the nearest package.json with fzf,
//! then run the selected script. Auto-detects pnpm or
//! npm from the lockfile (pnpm-lock.yaml → pnpm,
//! package-lock.json → npm).
//!
//! Usage: pjs

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use dotfiles_scripts::{die, filter, run};
use serde_json::Value;

fn main() {
    let cwd = env::current_dir().unwrap_or_else(|err| die(format!("pjs: {err}")));
    let dir = package_dir(&cwd).unwrap_or_else(|| die("Error: No package.json found"));
    let pkg = dir.join("package.json");

    // Auto-detect package manager from lockfile
    let pm = if dir.join("pnpm-lock.yaml").is_file() {
        "pnpm"
    } else {
        "npm"
    };

    let manifest =
        fs::read_to_string(&pkg).unwrap_or_else(|err| die(format!("{}: {err}", pkg.display())));
    let scripts = scripts(&manifest).unwrap_or_else(|err| die(format!("{}: {err}", pkg.display())));

    // Let the user pick a script
    let name = dir.file_name().unwrap_or_default().to_string_lossy();
    let script = filter(
        Command::new("fzf").args([
            "--height=60%",
            &format!("--header=[{pm} run] Select a script from {name}/package.json"),
            &format!("--preview=echo {pm} run {{1}}"),
            "--preview-window=up:1",
        ]),
        &scripts
            .iter()
            .map(|(name, command)| format!("{name} → {command}\n"))
            .collect::<String>(),
    )
    .and_then(|line| line.split_whitespace().next().map(str::to_owned));

    let Some(script) = script else {
        println!("No script selected");
        return;
    };

    println!("Running: {pm} run {script}");
    run(Command::new(pm).args(["run", &script]).current_dir(&dir));
}

/// Walk up from `start` to the nearest directory containing package.json.
fn package_dir(start: &Path) -> Option<PathBuf> {
    start
        .ancestors()
        .find(|dir| dir.join("package.json").is_file())
        .map(Path::to_path_buf)
}

/// The `scripts` entries of a package.json, in file order.
fn scripts(manifest: &str) -> serde_json::Result<Vec<(String, String)>> {
    let package: Value = serde_json::from_str(manifest)?;
    Ok(package
        .get("scripts")
        .and_then(Value::as_object)
        .into_iter()
        .flatten()
        .filter_map(|(name, command)| Some((name.clone(), command.as_str()?.to_owned())))
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn scripts_keep_file_order() {
        let manifest = r#"{"scripts": {"test": "vitest", "build": "vite build"}}"#;
        assert_eq!(
            scripts(manifest).unwrap(),
            [
                ("test".to_owned(), "vitest".to_owned()),
                ("build".to_owned(), "vite build".to_owned()),
            ],
        );
    }

    #[test]
    fn scripts_are_empty_without_a_scripts_key() {
        assert!(scripts(r#"{"name": "x"}"#).unwrap().is_empty());
    }
}
