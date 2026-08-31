#!/usr/bin/env rust
use std::env;
use std::fs;
use std::io;
use std::os::unix::fs as unix_fs;
use std::path::PathBuf;

fn home_dir() -> io::Result<PathBuf> {
    env::var_os("HOME")
        .map(PathBuf::from)
        .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "HOME is not set"))
}

fn target_exists(path: &PathBuf) -> bool {
    fs::symlink_metadata(path).is_ok()
}

fn main() -> io::Result<()> {
    let home = home_dir()?;

    let source_dir = home.join(".dotfiles/bin");
    let target_dir = home.join(".local/bin");

    fs::create_dir_all(&target_dir)?;

    for entry in fs::read_dir(&source_dir)? {
        let entry = entry?;
        let source = entry.path();

        let Some(file_name) = source.file_name() else {
            continue;
        };

        let target = target_dir.join(file_name);

        if target_exists(&target) {
            println!("skipping: {} already exists", target.display());
            continue;
        }

        println!("linking: {} -> {}", target.display(), source.display());
        unix_fs::symlink(&source, &target)?;
    }

    Ok(())
}
