//! Noninteractive counterpart of the former ctx alias. Never install implicitly.

use std::env;
use std::process::{Command, exit};

use dotfiles_scripts::{exec, has_command};

fn main() {
    if !has_command("ctx7") {
        eprintln!("ctx: ctx7 is not on PATH. Optional manual installation: npm install -g ctx7");
        eprintln!("See docs/config-audit.md for dependency and documentation lookup guidance.");
        exit(127);
    }
    exec(Command::new("ctx7").args(env::args_os().skip(1)));
}
