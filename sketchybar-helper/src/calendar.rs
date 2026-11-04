//! Calendar popup data: a month grid and today's events (EventKit).

use crate::util::{self, Out};
use block2::RcBlock;
use objc2::runtime::Bool;
use objc2_event_kit::{EKAuthorizationStatus, EKEntityType, EKEventStore};
use objc2_foundation::{NSDate, NSError, NSRunLoop};
use serde_json::{Value, json};
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

fn days_in_month(year: i32, month0: i32) -> i64 {
    (util::local_time(year, month0 + 1, 1) - util::local_time(year, month0, 1) + 43_200) / 86_400
}

/// Requests Calendar access the first time; returns whether we may read.
fn authorized(store: &EKEventStore) -> Result<(), &'static str> {
    let status = unsafe { EKEventStore::authorizationStatusForEntityType(EKEntityType::Event) };
    if status == EKAuthorizationStatus::FullAccess {
        return Ok(());
    }
    if status != EKAuthorizationStatus::NotDetermined {
        return Err("Calendar access needed");
    }
    let done = Arc::new(AtomicBool::new(false));
    let granted = Arc::new(AtomicBool::new(false));
    let (d, g) = (done.clone(), granted.clone());
    let block = RcBlock::new(move |ok: Bool, _err: *mut NSError| {
        g.store(ok.as_bool(), Ordering::SeqCst);
        d.store(true, Ordering::SeqCst);
    });
    unsafe { store.requestFullAccessToEventsWithCompletion(RcBlock::as_ptr(&block)) };
    for _ in 0..240 {
        if done.load(Ordering::SeqCst) {
            break;
        }
        NSRunLoop::currentRunLoop().runUntilDate(&NSDate::dateWithTimeIntervalSinceNow(0.25));
    }
    if granted.load(Ordering::SeqCst) {
        Ok(())
    } else {
        Err("Calendar access needed")
    }
}

fn today_events() -> Result<Vec<Value>, &'static str> {
    let store = unsafe { EKEventStore::new() };
    authorized(&store)?;
    let start = util::local_midnight() as f64;
    let (y, m, d) = util::local_date(start as i64);
    let end = util::local_time(y, m as i32 - 1, d as i32 + 1) as f64;
    let now = util::now();
    let mut list: Vec<(f64, Value)> = unsafe {
        let predicate = store.predicateForEventsWithStartDate_endDate_calendars(
            &NSDate::dateWithTimeIntervalSince1970(start),
            &NSDate::dateWithTimeIntervalSince1970(end),
            None,
        );
        store
            .eventsMatchingPredicate(&predicate)
            .iter()
            .map(|e| {
                let s = e.startDate().timeIntervalSince1970();
                let f = e.endDate().timeIntervalSince1970();
                let title = e.title().to_string();
                let calendar = e
                    .calendar()
                    .map(|c| c.title().to_string())
                    .unwrap_or_default();
                (
                    s,
                    json!({
                        "title": util::clean(&title, 80),
                        "start": s as i64,
                        "end": f as i64,
                        "all_day": e.isAllDay(),
                        "ended": f <= now,
                        "now": s <= now && now < f,
                        "calendar": calendar,
                    }),
                )
            })
            .collect()
    };
    // All-day events first, then by start time.
    list.sort_by(|a, b| {
        let ad = |v: &Value| !v["all_day"].as_bool().unwrap_or(false);
        ad(&a.1).cmp(&ad(&b.1)).then(a.0.total_cmp(&b.0))
    });
    Ok(list.into_iter().map(|(_, v)| v).collect())
}

/// `offset` months from now. Weekday of the 1st: 0 = Sunday.
pub fn month(offset: i32, with_events: bool) -> Out {
    let (y, m, today) = util::local_date(util::now() as i64);
    let first = util::local_time(y, m as i32 - 1 + offset, 1);
    let (fy, fm, _) = util::local_date(first);
    let weekday = unsafe {
        let t = first as libc::time_t;
        let mut tm: libc::tm = std::mem::zeroed();
        libc::localtime_r(&t, &mut tm);
        tm.tm_wday
    };
    let mut out = json!({
        "year": fy,
        "month": fm,
        "first_weekday": weekday,
        "days": days_in_month(fy, fm as i32 - 1),
        "today": if offset == 0 { today } else { 0 },
        "offset": offset,
    });
    if with_events {
        match today_events() {
            Ok(events) => out["events"] = json!(events),
            Err(e) => out["error"] = json!(e),
        }
    }
    Ok(out)
}

#[cfg(test)]
mod tests {
    #[test]
    fn month_lengths() {
        assert_eq!(super::days_in_month(2026, 1), 28);
        assert_eq!(super::days_in_month(2028, 1), 29);
        assert_eq!(super::days_in_month(2026, 9), 31);
        assert_eq!(super::days_in_month(2026, 10), 30);
    }
}
