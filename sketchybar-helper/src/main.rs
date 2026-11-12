//! `sbar-helper`: the data side of the SketchyBar island config. The Lua UI
//! runs one subcommand per refresh; each prints exactly one JSON object
//! (errors as `{"error": "..."}`), which SbarLua parses into a table.

mod agents;
mod apps;
mod audio;
mod calendar;
mod clickaway;
mod containers;
mod notch;
mod pixels;
mod slack;
mod spotify;
mod system;
mod usage;
mod util;
mod watch;
mod wifi;

const USAGE: &str = "usage: sbar-helper <command>
  usage | agents | system | procs
  app <slack|teams|docker|rancher> | notifications <slack|teams>
  containers <docker|rancher>
  slack-status [set <emoji> <text> <minutes> | clear]
  wifi [scan | join <ssid>]
  audio [volume <0-100> | mute | output <device id>]
  spotify [playpause | next | previous | open]
  calendar [month offset] [--no-events]
  pixels <dir> [key=0xAARRGGBB ...]
  clickaway | mouse | notch | watch";

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let a: Vec<&str> = args.iter().map(String::as_str).collect();
    let result = match a.as_slice() {
        ["usage"] => usage::usage(),
        ["agents"] => agents::agents(),
        ["system"] => system::system(),
        ["procs"] => system::procs(5),
        ["app", key] => apps::status(key),
        ["notifications", key] => apps::notifications(key),
        ["containers", key] => containers::list(key),
        ["slack-status"] => slack::get(),
        ["slack-status", "set", emoji, text, minutes] => {
            slack::set(emoji, text, minutes.parse().unwrap_or(0))
        }
        ["slack-status", "clear"] => slack::set("", "", 0),
        ["wifi"] => wifi::info(),
        ["wifi", "scan"] => wifi::scan(),
        ["wifi", "join", ssid] => wifi::join(ssid),
        ["audio"] => audio::status(),
        ["audio", "volume", v] => audio::set_volume(v),
        ["audio", "mute"] => audio::toggle_mute(),
        ["audio", "output", id] => audio::set_output(id),
        ["spotify"] => spotify::status(),
        ["spotify", cmd] => spotify::control(cmd),
        ["calendar"] => calendar::month(0, true),
        ["calendar", offset] => calendar::month(offset.parse().unwrap_or(0), true),
        ["calendar", offset, "--no-events"] => calendar::month(offset.parse().unwrap_or(0), false),
        ["pixels", dir, rest @ ..] => pixels::generate(dir, rest),
        ["clickaway"] => clickaway::wait(),
        ["mouse"] => clickaway::position(),
        ["notch"] => notch::notch(),
        ["watch"] => watch::run(),
        ["help" | "--help" | "-h"] => {
            println!("{USAGE}");
            return;
        }
        _ => Err(format!("unknown command\n{USAGE}")),
    };
    match result {
        Ok(v) => println!("{v}"),
        Err(e) => {
            println!("{}", serde_json::json!({ "error": e }));
            std::process::exit(1);
        }
    }
}
