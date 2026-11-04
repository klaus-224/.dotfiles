//! Long-running watcher: fires `sketchybar --trigger audio_change` when the
//! output device, its mute or its volume changes. SketchyBar's own
//! `volume_change` misses mute keys and device switches. Exits with SketchyBar.

use crate::audio::{self, Address};
use crate::util::{self, Out};
use std::ffi::c_void;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::{Duration, Instant};

static CHANGED: AtomicBool = AtomicBool::new(false);

extern "C" fn listener(_: u32, _: u32, _: *const Address, _: *mut c_void) -> i32 {
    CHANGED.store(true, Ordering::SeqCst);
    0
}

fn device_addresses(id: u32) -> Vec<Address> {
    let mut list = vec![audio::address(audio::MUTE, true, 0)];
    list.extend(
        audio::volume_elements(id)
            .into_iter()
            .map(|e| audio::address(audio::VOLUME, true, e)),
    );
    list
}

fn attach(id: u32, on: bool) {
    for a in device_addresses(id) {
        unsafe {
            if on {
                audio::AudioObjectAddPropertyListener(id, &a, listener, std::ptr::null_mut());
            } else {
                audio::AudioObjectRemovePropertyListener(id, &a, listener, std::ptr::null_mut());
            }
        }
    }
}

/// Replaces any previous watcher so reloads do not pile them up.
fn take_over() {
    let pid_file = util::cache_dir().join("watch.pid");
    if let Some(old) = std::fs::read_to_string(&pid_file)
        .ok()
        .and_then(|s| s.trim().parse::<i32>().ok())
        && old != std::process::id() as i32
        && util::run("/bin/ps", &["-p", &old.to_string(), "-o", "comm="])
            .is_some_and(|c| c.contains("sbar-helper"))
    {
        unsafe { libc::kill(old, libc::SIGTERM) };
    }
    let _ = std::fs::write(pid_file, std::process::id().to_string());
}

pub fn run() -> Out {
    take_over();
    let system = audio::address(audio::DEFAULT_OUTPUT, false, 0);
    unsafe {
        audio::AudioObjectAddPropertyListener(
            audio::SYSTEM,
            &system,
            listener,
            std::ptr::null_mut(),
        )
    };
    let mut device = audio::default_output();
    attach(device, true);
    let mut alive_check = Instant::now();
    let mut last_fire = Instant::now() - Duration::from_secs(1);
    loop {
        std::thread::sleep(Duration::from_millis(100));
        // Coalesce bursts (a slider drag fires dozens of changes).
        if CHANGED.load(Ordering::SeqCst) && last_fire.elapsed() >= Duration::from_millis(150) {
            CHANGED.store(false, Ordering::SeqCst);
            last_fire = Instant::now();
            let now = audio::default_output();
            if now != device {
                attach(device, false);
                device = now;
                attach(device, true);
            }
            util::sketchybar(&["--trigger", "audio_change"]);
        }
        if alive_check.elapsed() >= Duration::from_secs(30) {
            alive_check = Instant::now();
            if !util::sketchybar_running() {
                return Ok(serde_json::json!({ "stopped": "sketchybar exited" }));
            }
        }
    }
}
