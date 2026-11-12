//! The camera notch of the built-in display, when one is connected and on.
//! SketchyBar only applies `notch_width` on a notched display; Lua uses the
//! width and the screen frame to move items out from under the notch.

use crate::util::Out;
use objc2::MainThreadMarker;
use objc2_app_kit::NSScreen;
use serde_json::json;

/// `{"width": 0}` without a notched screen; otherwise the notch width and
/// the screen's x and width, which match SketchyBar's display frame.
pub fn notch() -> Out {
    let mtm = MainThreadMarker::new().ok_or("must run on the main thread")?;
    for screen in NSScreen::screens(mtm).iter() {
        if screen.safeAreaInsets().top <= 0.0 {
            continue;
        }
        let left = screen.auxiliaryTopLeftArea();
        let right = screen.auxiliaryTopRightArea();
        let width = right.origin.x - (left.origin.x + left.size.width);
        if width > 0.0 {
            let frame = screen.frame();
            return Ok(json!({
                "width": width.round(),
                "x": frame.origin.x,
                "w": frame.size.width,
            }));
        }
    }
    Ok(json!({ "width": 0 }))
}
