//! Waits for the next mouse press and prints where it landed, in
//! SketchyBar's top-left coordinates. Lua compares the point with the open
//! popup's bounding rects.
//!
//! Presses are detected with the window server's per-type event counters,
//! not by sampling the button state: a trackpad tap can press and release
//! between two samples, and then the menu stayed open. Reading the counters
//! needs no permission.

use crate::util::Out;
use objc2::MainThreadMarker;
use objc2_app_kit::{NSEvent, NSScreen};
use serde_json::json;
use std::time::{Duration, Instant};

#[link(name = "CoreGraphics", kind = "framework")]
unsafe extern "C" {
    fn CGEventSourceCounterForEventType(state: i32, event_type: u32) -> u32;
}

/// kCGEventSourceStateCombinedSessionState: every source in the session.
const COMBINED_SESSION: i32 = 0;
/// kCGEventLeftMouseDown, kCGEventRightMouseDown, kCGEventOtherMouseDown.
const MOUSE_DOWN: [u32; 3] = [1, 3, 25];

fn presses() -> u64 {
    MOUSE_DOWN
        .iter()
        .map(|t| unsafe { CGEventSourceCounterForEventType(COMBINED_SESSION, *t) } as u64)
        .sum()
}

/// Height of the primary screen, which flips AppKit's bottom-left origin.
fn primary_height() -> Result<f64, String> {
    let mtm = MainThreadMarker::new().ok_or("must run on the main thread")?;
    Ok(NSScreen::screens(mtm)
        .firstObject()
        .map(|s| s.frame().size.height)
        .unwrap_or(0.0))
}

/// The pointer now, in SketchyBar's top-left coordinates. Lets a menu row
/// act on where it was clicked (SketchyBar reports no click position).
pub fn position() -> Out {
    let height = primary_height()?;
    let p = NSEvent::mouseLocation();
    Ok(json!({ "x": p.x, "y": height - p.y }))
}

pub fn wait() -> Out {
    let height = primary_height()?;
    let deadline = Instant::now() + Duration::from_secs(600);
    let start = presses();
    while Instant::now() < deadline {
        std::thread::sleep(Duration::from_millis(25));
        if presses() != start {
            // The pointer barely moves within one poll, so its position now
            // is where the press landed.
            let p = NSEvent::mouseLocation();
            return Ok(json!({ "x": p.x, "y": height - p.y }));
        }
    }
    Ok(json!({ "timeout": true }))
}
