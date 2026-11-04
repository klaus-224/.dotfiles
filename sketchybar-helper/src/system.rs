//! CPU, memory, disk, battery and the top memory processes (Mach / libproc).

use crate::util::{self, Out};
use serde_json::{Value, json};
use std::ffi::{CString, c_void};

unsafe extern "C" {
    fn mach_host_self() -> u32;
    fn host_statistics(host: u32, flavor: i32, info: *mut i32, count: *mut u32) -> i32;
    fn host_statistics64(host: u32, flavor: i32, info: *mut i32, count: *mut u32) -> i32;
    fn proc_listallpids(buffer: *mut c_void, size: i32) -> i32;
    fn proc_name(pid: i32, buffer: *mut c_void, size: u32) -> i32;
    fn proc_pid_rusage(pid: i32, flavor: i32, buffer: *mut c_void) -> i32;
}

const HOST_CPU_LOAD_INFO: i32 = 3;
const HOST_VM_INFO64: i32 = 4;
const RUSAGE_INFO_V2: i32 = 2;

/// `vm_statistics64` from <mach/vm_statistics.h>.
#[repr(C, align(8))]
#[derive(Default)]
struct VmStats {
    free_count: u32,
    active_count: u32,
    inactive_count: u32,
    wire_count: u32,
    zero_fill_count: u64,
    reactivations: u64,
    pageins: u64,
    pageouts: u64,
    faults: u64,
    cow_faults: u64,
    lookups: u64,
    hits: u64,
    purges: u64,
    purgeable_count: u32,
    speculative_count: u32,
    decompressions: u64,
    compressions: u64,
    swapins: u64,
    swapouts: u64,
    compressor_page_count: u32,
    throttled_count: u32,
    external_page_count: u32,
    internal_page_count: u32,
    total_uncompressed_pages_in_compressor: u64,
}

fn sysctl_u64(name: &str) -> Option<u64> {
    let name = CString::new(name).ok()?;
    let mut value: u64 = 0;
    let mut size = std::mem::size_of::<u64>();
    let r = unsafe {
        libc::sysctlbyname(
            name.as_ptr(),
            &mut value as *mut u64 as *mut c_void,
            &mut size,
            std::ptr::null_mut(),
            0,
        )
    };
    (r == 0).then_some(value)
}

fn cpu_ticks() -> Option<[u64; 4]> {
    let mut info = [0u32; 4];
    let mut count = 4u32;
    let r = unsafe {
        host_statistics(
            mach_host_self(),
            HOST_CPU_LOAD_INFO,
            info.as_mut_ptr() as *mut i32,
            &mut count,
        )
    };
    (r == 0).then(|| info.map(u64::from))
}

/// CPU busy % since the previous call (ticks are cached between runs).
fn cpu_percent() -> Option<u32> {
    let path = util::cache_dir().join("cpu.ticks");
    let parse = |s: String| -> Option<[u64; 4]> {
        let v: Vec<u64> = s
            .split_whitespace()
            .filter_map(|x| x.parse().ok())
            .collect();
        (v.len() == 4).then(|| [v[0], v[1], v[2], v[3]])
    };
    let mut before = std::fs::read_to_string(&path).ok().and_then(parse);
    let mut now = cpu_ticks()?;
    if before.is_none_or(|b| {
        now.iter()
            .zip(b)
            .map(|(n, b)| n.saturating_sub(b))
            .sum::<u64>()
            == 0
    }) {
        before = Some(now);
        std::thread::sleep(std::time::Duration::from_millis(250));
        now = cpu_ticks()?;
    }
    let _ = std::fs::write(&path, now.map(|t| t.to_string()).join(" "));
    let b = before?;
    let d: Vec<u64> = now
        .iter()
        .zip(b)
        .map(|(n, b)| n.saturating_sub(b))
        .collect();
    let total: u64 = d.iter().sum();
    // Order: user, system, idle, nice.
    (total > 0).then(|| (((d[0] + d[1] + d[3]) as f64 / total as f64) * 100.0).round() as u32)
}

/// Used memory as Activity Monitor counts it: app + wired + compressed.
fn memory() -> Option<(u64, u64)> {
    let total = sysctl_u64("hw.memsize")?;
    let page = unsafe { libc::sysconf(libc::_SC_PAGESIZE) } as u64;
    let mut vm = VmStats::default();
    let mut count = (std::mem::size_of::<VmStats>() / 4) as u32;
    let r = unsafe {
        host_statistics64(
            mach_host_self(),
            HOST_VM_INFO64,
            &mut vm as *mut VmStats as *mut i32,
            &mut count,
        )
    };
    if r != 0 {
        return None;
    }
    let app = (vm.internal_page_count as u64).saturating_sub(vm.purgeable_count as u64);
    let used = (app + vm.wire_count as u64 + vm.compressor_page_count as u64) * page;
    Some((used.min(total), total))
}

fn disk() -> Option<(u64, u64)> {
    let path = CString::new("/System/Volumes/Data").ok()?;
    let mut s: libc::statfs = unsafe { std::mem::zeroed() };
    if unsafe { libc::statfs(path.as_ptr(), &mut s) } != 0 {
        return None;
    }
    let block = s.f_bsize as u64;
    Some((s.f_blocks * block, s.f_bavail * block))
}

fn battery() -> Value {
    let Some(out) = util::run("/usr/bin/pmset", &["-g", "batt"]) else {
        return Value::Null;
    };
    let Some(pos) = out.find('%') else {
        return Value::Null;
    };
    let start = out[..pos]
        .rfind(|c: char| !c.is_ascii_digit())
        .map(|i| i + 1)
        .unwrap_or(0);
    let Ok(percent) = out[start..pos].parse::<u32>() else {
        return Value::Null;
    };
    let ac = out.contains("'AC Power'");
    let charging = out.contains("; charging") || out.contains("; finishing charge");
    let remaining = out
        .split_whitespace()
        .position(|w| w == "remaining")
        .and_then(|i| {
            let words: Vec<&str> = out.split_whitespace().collect();
            words
                .get(i.checked_sub(1)?)
                .filter(|w| w.contains(':'))
                .map(|w| w.to_string())
        });
    json!({ "percent": percent, "ac": ac, "charging": charging, "remaining": remaining })
}

pub fn system() -> Out {
    let gb = 1024f64.powi(3);
    let mem = memory();
    let disk = disk();
    Ok(json!({
        "cpu": cpu_percent(),
        "cores": sysctl_u64("hw.ncpu"),
        "memory": mem.map(|(used, total)| json!({
            "used": used, "total": total, "percent": (used as f64 / total as f64 * 100.0).round(),
            "used_gb": (used as f64 / gb * 10.0).round() / 10.0, "total_gb": (total as f64 / gb).round(),
        })),
        "disk": disk.map(|(total, free)| json!({
            "total_gb": (total as f64 / 1e9).round(), "free_gb": (free as f64 / 1e9).round(),
            "used_gb": ((total - free) as f64 / 1e9).round(),
        })),
        "battery": battery(),
    }))
}

/// The `limit` processes with the largest physical footprint (the "Memory"
/// column in Activity Monitor). Other users' processes are skipped.
pub fn procs(limit: usize) -> Out {
    let n = unsafe { proc_listallpids(std::ptr::null_mut(), 0) };
    if n <= 0 {
        return Err("process list unavailable".into());
    }
    let mut pids = vec![0i32; n as usize + 64];
    let n = unsafe { proc_listallpids(pids.as_mut_ptr() as *mut c_void, (pids.len() * 4) as i32) };
    pids.truncate(n.max(0) as usize);
    let mut found: Vec<(u64, i32, String)> = Vec::new();
    for pid in pids.into_iter().filter(|p| *p > 0) {
        let mut info = [0u64; 64];
        if unsafe { proc_pid_rusage(pid, RUSAGE_INFO_V2, info.as_mut_ptr() as *mut c_void) } != 0 {
            continue;
        }
        // rusage_info_v2: uuid (16 bytes), then u64 fields; phys_footprint is the 8th.
        let footprint = info[9];
        let mut name = [0u8; 256];
        let len = unsafe { proc_name(pid, name.as_mut_ptr() as *mut c_void, name.len() as u32) };
        let name = String::from_utf8_lossy(&name[..len.max(0) as usize]).into_owned();
        found.push((
            footprint,
            pid,
            if name.is_empty() {
                pid.to_string()
            } else {
                name
            },
        ));
    }
    found.sort_by_key(|(f, _, _)| std::cmp::Reverse(*f));
    let list: Vec<Value> = found
        .into_iter()
        .take(limit)
        .map(|(bytes, pid, name)| json!({ "pid": pid, "name": name, "bytes": bytes, "mb": (bytes as f64 / 1048576.0).round() }))
        .collect();
    Ok(json!({ "processes": list, "at": util::now() as i64 }))
}
