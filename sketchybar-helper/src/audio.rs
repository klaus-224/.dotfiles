//! Output volume, mute and devices through CoreAudio (hand-written FFI).

use crate::util::Out;
use serde_json::{Value, json};
use std::ffi::c_void;

#[repr(C)]
#[derive(Clone, Copy)]
pub struct Address {
    selector: u32,
    scope: u32,
    element: u32,
}

pub type Listener = extern "C" fn(u32, u32, *const Address, *mut c_void) -> i32;

#[link(name = "CoreAudio", kind = "framework")]
unsafe extern "C" {
    fn AudioObjectHasProperty(id: u32, address: *const Address) -> u8;
    fn AudioObjectIsPropertySettable(id: u32, address: *const Address, settable: *mut u8) -> i32;
    fn AudioObjectGetPropertyDataSize(
        id: u32,
        address: *const Address,
        qs: u32,
        q: *const c_void,
        size: *mut u32,
    ) -> i32;
    fn AudioObjectGetPropertyData(
        id: u32,
        address: *const Address,
        qs: u32,
        q: *const c_void,
        size: *mut u32,
        data: *mut c_void,
    ) -> i32;
    fn AudioObjectSetPropertyData(
        id: u32,
        address: *const Address,
        qs: u32,
        q: *const c_void,
        size: u32,
        data: *const c_void,
    ) -> i32;
    pub fn AudioObjectAddPropertyListener(
        id: u32,
        address: *const Address,
        listener: Listener,
        client: *mut c_void,
    ) -> i32;
    pub fn AudioObjectRemovePropertyListener(
        id: u32,
        address: *const Address,
        listener: Listener,
        client: *mut c_void,
    ) -> i32;
}

#[link(name = "CoreFoundation", kind = "framework")]
unsafe extern "C" {
    fn CFStringGetCString(s: *const c_void, buffer: *mut u8, size: isize, encoding: u32) -> u8;
    fn CFRelease(s: *const c_void);
}

const fn fourcc(s: &[u8; 4]) -> u32 {
    u32::from_be_bytes(*s)
}

pub const SYSTEM: u32 = 1;
const GLOBAL: u32 = fourcc(b"glob");
const OUTPUT: u32 = fourcc(b"outp");
const DEVICES: u32 = fourcc(b"dev#");
pub const DEFAULT_OUTPUT: u32 = fourcc(b"dOut");
const NAME: u32 = fourcc(b"lnam");
const STREAMS: u32 = fourcc(b"slay");
const TRANSPORT: u32 = fourcc(b"tran");
const HIDDEN: u32 = fourcc(b"hidn");
pub const MUTE: u32 = fourcc(b"mute");
pub const VOLUME: u32 = fourcc(b"volm");

pub fn address(selector: u32, output: bool, element: u32) -> Address {
    Address {
        selector,
        scope: if output { OUTPUT } else { GLOBAL },
        element,
    }
}

fn get<T: Copy + Default>(id: u32, a: Address) -> Option<T> {
    let mut v = T::default();
    let mut size = std::mem::size_of::<T>() as u32;
    let r = unsafe {
        AudioObjectGetPropertyData(
            id,
            &a,
            0,
            std::ptr::null(),
            &mut size,
            &mut v as *mut T as *mut c_void,
        )
    };
    (r == 0).then_some(v)
}

fn set<T: Copy>(id: u32, a: Address, v: T) -> bool {
    unsafe {
        AudioObjectSetPropertyData(
            id,
            &a,
            0,
            std::ptr::null(),
            std::mem::size_of::<T>() as u32,
            &v as *const T as *const c_void,
        ) == 0
    }
}

fn has(id: u32, a: Address) -> bool {
    unsafe { AudioObjectHasProperty(id, &a) != 0 }
}

fn settable(id: u32, a: Address) -> bool {
    let mut s = 0u8;
    has(id, a) && unsafe { AudioObjectIsPropertySettable(id, &a, &mut s) } == 0 && s != 0
}

pub fn default_output() -> u32 {
    get::<u32>(SYSTEM, address(DEFAULT_OUTPUT, false, 0)).unwrap_or(0)
}

fn name(id: u32) -> String {
    let Some(s) = get::<usize>(id, address(NAME, false, 0)).filter(|p| *p != 0) else {
        return "?".into();
    };
    let mut buf = [0u8; 512];
    let ok = unsafe {
        CFStringGetCString(
            s as *const c_void,
            buf.as_mut_ptr(),
            buf.len() as isize,
            0x0800_0100,
        )
    };
    unsafe { CFRelease(s as *const c_void) };
    if ok == 0 {
        return "?".into();
    }
    let end = buf.iter().position(|b| *b == 0).unwrap_or(0);
    String::from_utf8_lossy(&buf[..end]).into_owned()
}

fn output_channels(id: u32) -> u32 {
    let a = address(STREAMS, true, 0);
    let mut size = 0u32;
    if unsafe { AudioObjectGetPropertyDataSize(id, &a, 0, std::ptr::null(), &mut size) } != 0
        || size < 8
    {
        return 0;
    }
    let mut buf = vec![0u64; (size as usize).div_ceil(8)];
    if unsafe {
        AudioObjectGetPropertyData(
            id,
            &a,
            0,
            std::ptr::null(),
            &mut size,
            buf.as_mut_ptr() as *mut c_void,
        )
    } != 0
    {
        return 0;
    }
    // AudioBufferList: u32 count, then 8-aligned AudioBuffer {u32 channels, u32 bytes, ptr}.
    let bytes = unsafe { std::slice::from_raw_parts(buf.as_ptr() as *const u8, size as usize) };
    let count = u32::from_ne_bytes(bytes[0..4].try_into().unwrap()) as usize;
    (0..count)
        .filter_map(|i| bytes.get(8 + i * 16..12 + i * 16))
        .map(|c| u32::from_ne_bytes(c.try_into().unwrap()))
        .sum()
}

fn kind(id: u32) -> &'static str {
    match get::<u32>(id, address(TRANSPORT, false, 0)).unwrap_or(0) {
        t if t == fourcc(b"bltn") => "builtin",
        t if t == fourcc(b"blue") || t == fourcc(b"blea") => "bluetooth",
        t if t == fourcc(b"grup") || t == fourcc(b"fgrp") => "aggregate",
        t if t == fourcc(b"airp") => "airplay",
        t if t == fourcc(b"hdmi") || t == fourcc(b"dprt") => "display",
        _ => "other",
    }
}

fn devices() -> Vec<u32> {
    let a = address(DEVICES, false, 0);
    let mut size = 0u32;
    if unsafe { AudioObjectGetPropertyDataSize(SYSTEM, &a, 0, std::ptr::null(), &mut size) } != 0 {
        return Vec::new();
    }
    let mut ids = vec![0u32; size as usize / 4];
    if unsafe {
        AudioObjectGetPropertyData(
            SYSTEM,
            &a,
            0,
            std::ptr::null(),
            &mut size,
            ids.as_mut_ptr() as *mut c_void,
        )
    } != 0
    {
        return Vec::new();
    }
    ids.truncate(size as usize / 4);
    ids
}

/// Volume elements: the main element when it has a volume, else channels 1 and 2.
pub fn volume_elements(id: u32) -> Vec<u32> {
    if has(id, address(VOLUME, true, 0)) {
        vec![0]
    } else {
        [1, 2]
            .into_iter()
            .filter(|e| has(id, address(VOLUME, true, *e)))
            .collect()
    }
}

fn volume(id: u32) -> Option<f32> {
    let values: Vec<f32> = volume_elements(id)
        .into_iter()
        .filter_map(|e| get::<f32>(id, address(VOLUME, true, e)))
        .collect();
    (!values.is_empty()).then(|| values.iter().sum::<f32>() / values.len() as f32)
}

fn muted(id: u32) -> bool {
    get::<u32>(id, address(MUTE, true, 0)).unwrap_or(0) != 0
}

pub fn status() -> Out {
    let current = default_output();
    let list: Vec<Value> = devices()
        .into_iter()
        .filter(|id| {
            output_channels(*id) > 0 && get::<u32>(*id, address(HIDDEN, false, 0)).unwrap_or(0) == 0
        })
        .filter(|id| kind(*id) != "aggregate")
        .map(|id| json!({ "id": id, "name": name(id), "kind": kind(id), "current": id == current }))
        .collect();
    Ok(json!({
        "volume": volume(current).map(|v| (v * 100.0).round() as i64),
        "muted": muted(current),
        "settable": volume_elements(current).iter().any(|e| settable(current, address(VOLUME, true, *e))),
        "device": name(current),
        "kind": kind(current),
        "devices": list,
    }))
}

pub fn set_volume(value: &str) -> Out {
    let v: f32 = value
        .parse::<f32>()
        .map_err(|_| "volume must be 0-100")?
        .clamp(0.0, 100.0)
        / 100.0;
    let id = default_output();
    let ok = volume_elements(id)
        .into_iter()
        .map(|e| set(id, address(VOLUME, true, e), v))
        .fold(false, |a, b| a | b);
    if ok && v > 0.0 && muted(id) {
        set(id, address(MUTE, true, 0), 0u32);
    }
    if !ok {
        return Err("this output has no adjustable volume".into());
    }
    status()
}

pub fn toggle_mute() -> Out {
    let id = default_output();
    if !set(
        id,
        address(MUTE, true, 0),
        if muted(id) { 0u32 } else { 1u32 },
    ) {
        return Err("this output cannot be muted".into());
    }
    status()
}

pub fn set_output(value: &str) -> Out {
    let id: u32 = value.parse().map_err(|_| "device id must be a number")?;
    if !set(SYSTEM, address(DEFAULT_OUTPUT, false, 0), id) || default_output() != id {
        return Err("could not switch output".into());
    }
    status()
}
