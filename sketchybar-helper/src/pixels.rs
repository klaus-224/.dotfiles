//! Pixel icons as PNG (1 pt = 2 px): the running cat inside a grass circle
//! (CPU), the pilo face (agent state) and the OpenCode mark. Colours come
//! from the Lua theme.
//!
//! `pixels <dir> text=0xAARRGGBB muted=… warn=… err=… done=… blade=… ground=…`

use crate::util::Out;
use serde_json::json;
use std::collections::HashMap;
use std::path::Path;

type Rgba = [u8; 4];
type Grid = Vec<Vec<Option<Rgba>>>;

fn color(hex: &str) -> Option<Rgba> {
    let v = u32::from_str_radix(hex.trim_start_matches("0x"), 16).ok()?;
    Some([(v >> 16) as u8, (v >> 8) as u8, v as u8, (v >> 24) as u8])
}

fn write_png(path: &Path, g: &Grid) -> Result<(), String> {
    let (h, w) = (g.len() as u32, g[0].len() as u32);
    let file = std::fs::File::create(path).map_err(|e| e.to_string())?;
    let mut enc = png::Encoder::new(std::io::BufWriter::new(file), w, h);
    enc.set_color(png::ColorType::Rgba);
    enc.set_depth(png::BitDepth::Eight);
    let mut writer = enc.write_header().map_err(|e| e.to_string())?;
    let data: Vec<u8> = g
        .iter()
        .flatten()
        .flat_map(|c| c.unwrap_or([0, 0, 0, 0]))
        .collect();
    writer.write_image_data(&data).map_err(|e| e.to_string())
}

/// Doubles every cell (pt grid → @2x pixels).
fn doubled(rows: &Grid) -> Grid {
    rows.iter()
        .flat_map(|r| {
            let line: Vec<Option<Rgba>> = r.iter().flat_map(|c| [*c, *c]).collect();
            [line.clone(), line]
        })
        .collect()
}

fn inside(x: usize, y: usize) -> bool {
    let (dx, dy) = (x as f64 + 0.5 - 33.0, y as f64 + 0.5 - 33.0);
    dx * dx + dy * dy <= 31.0 * 31.0
}

fn circle_mask(g: Grid) -> Grid {
    g.into_iter()
        .enumerate()
        .map(|(y, r)| {
            r.into_iter()
                .enumerate()
                .map(|(x, c)| if inside(x, y) { c } else { None })
                .collect()
        })
        .collect()
}

const CAT_TOP: [&str; 7] = [
    "...........#..#.",
    "#..........####.",
    "#..........#.##.",
    ".#.........####.",
    "..#############.",
    "..############..",
    "..###########...",
];
const CAT_LEGS: [[&str; 3]; 4] = [
    [".##.........##..", "#.............#.", "................"],
    ["..#.#.....#.#...", "..#..#...#..#...", "................"],
    ["...##.....##....", "....#.....#.....", "....#.....#....."],
    ["..#.#.....#.#...", "..#..#...#..#...", "................"],
];

/// 33×33 pt circle: grass along the bottom with the cat (2.5 px cells) on it.
fn cat(frame: usize, body: Rgba, blade: Rgba, ground: Rgba) -> Grid {
    const PATTERN: [u8; 9] = [0, 2, 1, 0, 2, 0, 1, 2, 0];
    let up = 2;
    let mut g: Grid = vec![vec![None; 66]; 66];
    for x in 0..66 {
        for row in g.iter_mut().take(66).skip(54 - up) {
            row[x] = Some(ground);
        }
        let h = PATTERN[(x / 2) % 9];
        if h >= 1 {
            g[52 - up][x] = Some(blade);
            g[53 - up][x] = Some(blade);
        }
        if h == 2 {
            g[50 - up][x] = Some(blade);
            g[51 - up][x] = Some(blade);
        }
    }
    let span = |i: usize| ((i as f64 * 2.5) as usize, ((i + 1) as f64 * 2.5) as usize);
    let (x0, y0) = (13, 27 - up);
    for (r, line) in CAT_TOP.iter().chain(CAT_LEGS[frame].iter()).enumerate() {
        for (c, ch) in line.chars().enumerate() {
            if ch == '#' {
                let ((ya, yb), (xa, xb)) = (span(r), span(c));
                for row in g.iter_mut().take(y0 + yb).skip(y0 + ya) {
                    for cell in row.iter_mut().take(x0 + xb).skip(x0 + xa) {
                        *cell = Some(body);
                    }
                }
            }
        }
    }
    circle_mask(g)
}

// Pilo: a round face with two arms. 16×12 cells; arm/eye/mouth cells are
// (row, column) on the left half and mirrored for the right.
const BODY: [&str; 10] = [
    "...####...",
    ".########.",
    "##########",
    "##########",
    "##########",
    "##########",
    "##########",
    "##########",
    ".########.",
    "...####...",
];

fn arm(name: &str) -> &'static [(usize, usize)] {
    match name {
        "down" => &[(6, 2), (7, 1), (8, 1)],
        "mid" => &[(6, 2), (6, 1), (6, 0)],
        "up" => &[(5, 2), (4, 1), (3, 0)],
        "upb" => &[(5, 2), (4, 1), (3, 1)],
        "droop" => &[(7, 2), (8, 2), (9, 2)],
        "tuck" => &[(7, 2), (8, 2)],
        _ => &[],
    }
}

fn eyes(name: &str) -> &'static [(usize, usize)] {
    match name {
        "open" => &[(4, 5), (5, 5)],
        "shut" => &[(5, 4), (5, 5)],
        "x" => &[(4, 4), (4, 6), (5, 5), (6, 4), (6, 6)],
        "happy" => &[(5, 4), (4, 5), (5, 6)],
        "dot" => &[(5, 5)],
        _ => &[],
    }
}

fn mouth(name: &str) -> &'static [(usize, usize)] {
    match name {
        "smile" => &[(7, 6), (8, 7), (8, 8), (7, 9)],
        "o" => &[(8, 7), (8, 8)],
        "flat" => &[(8, 6), (8, 7), (8, 8), (8, 9)],
        "frown" => &[(8, 6), (7, 7), (7, 8), (8, 9)],
        _ => &[],
    }
}

/// (left arm, right arm, eyes, mouth, breathing).
type Frame = (&'static str, &'static str, &'static str, &'static str, bool);
/// (state, colour key, frames).
type Pose = (&'static str, &'static str, Vec<Frame>);

fn poses() -> Vec<Pose> {
    vec![
        (
            "working",
            "text",
            vec![
                ("up", "down", "open", "smile", false),
                ("mid", "mid", "open", "smile", false),
                ("down", "up", "open", "smile", false),
                ("mid", "mid", "open", "smile", false),
            ],
        ),
        (
            "waiting",
            "warn",
            vec![
                ("down", "up", "open", "o", false),
                ("down", "upb", "open", "o", false),
            ],
        ),
        (
            "done",
            "done",
            vec![
                ("up", "up", "happy", "smile", false),
                ("upb", "upb", "happy", "smile", false),
            ],
        ),
        (
            "failed",
            "err",
            vec![
                ("up", "up", "x", "flat", false),
                ("upb", "upb", "x", "flat", false),
            ],
        ),
        (
            "stalled",
            "warn",
            vec![
                ("droop", "droop", "dot", "frown", false),
                ("droop", "droop", "shut", "frown", false),
            ],
        ),
        (
            "idle",
            "muted",
            vec![
                ("tuck", "tuck", "shut", "", false),
                ("tuck", "tuck", "shut", "", true),
            ],
        ),
        ("none", "muted", vec![("", "", "", "", false)]),
    ]
}

fn face(col: Rgba, frame: Frame) -> Grid {
    let (la, ra, e, m, breath) = frame;
    let mut g: Grid = vec![vec![None; 16]; 12];
    let rows: Vec<&str> = if breath {
        BODY[1..].to_vec()
    } else {
        BODY.to_vec()
    };
    let shift = breath as usize;
    for (r, line) in rows.iter().enumerate() {
        for (c, ch) in line.chars().enumerate() {
            if ch == '#' {
                g[r + 1 + shift][c + 3] = Some(col);
            }
        }
    }
    if e.is_empty() && la.is_empty() {
        // No session: outline only.
        let full: Vec<Vec<bool>> = g
            .iter()
            .map(|r| r.iter().map(Option::is_some).collect())
            .collect();
        for r in 1..11 {
            for c in 1..15 {
                if full[r][c]
                    && full[r + 1][c]
                    && full[r - 1][c]
                    && full[r][c + 1]
                    && full[r][c - 1]
                {
                    g[r][c] = None;
                }
            }
        }
        return g;
    }
    for &(r, c) in eyes(e).iter().chain(mouth(m)) {
        g[r][c] = None;
    }
    for &(r, c) in eyes(e) {
        g[r][15 - c] = None;
    }
    for &(r, c) in arm(la) {
        g[r][c] = Some(col);
    }
    for &(r, c) in arm(ra) {
        g[r][15 - c] = Some(col);
    }
    g
}

/// Face centred in a 66 px circle with 3 px cells.
fn face_circle(face: &Grid) -> Grid {
    let mut g: Grid = vec![vec![None; 66]; 66];
    for (r, row) in face.iter().enumerate() {
        for (c, cell) in row.iter().enumerate() {
            if let Some(col) = cell {
                for line in g.iter_mut().take(18 + r * 3).skip(15 + r * 3) {
                    for px in line.iter_mut().take(12 + c * 3).skip(9 + c * 3) {
                        *px = Some(*col);
                    }
                }
            }
        }
    }
    circle_mask(g)
}

/// The OpenCode mark: a 4×5 frame, empty top row inside, filled below.
/// Cells are 2 pt, so the mark is 8×10 pt (about the text's cap height).
fn opencode(frame: Rgba, fill: Rgba) -> Grid {
    const MARK: [&str; 5] = ["####", "#..#", "#++#", "#++#", "####"];
    let cells: Grid = MARK
        .iter()
        .map(|row| {
            row.chars()
                .map(|ch| match ch {
                    '#' => Some(frame),
                    '+' => Some(fill),
                    _ => None,
                })
                .collect()
        })
        .collect();
    // 2 pt cells, then @2x pixels.
    doubled(&doubled(&cells))
}

pub fn generate(dir: &str, args: &[&str]) -> Out {
    let mut colors: HashMap<&str, Rgba> = HashMap::from([
        ("text", [0xcd, 0xcd, 0xcd, 0xff]),
        ("muted", [0x60, 0x60, 0x79, 0xff]),
        ("warn", [0xe8, 0xb5, 0x89, 0xff]),
        ("err", [0xc4, 0x82, 0x82, 0xff]),
        ("done", [0x99, 0xb7, 0x82, 0xff]),
        ("blade", [0x3f, 0x5a, 0x3c, 0xff]),
        ("ground", [0x22, 0x30, 0x22, 0xff]),
    ]);
    for arg in args {
        if let Some((k, v)) = arg.split_once('=')
            && let Some(c) = color(v)
            && let Some(slot) = colors.get_mut(k)
        {
            *slot = c;
        }
    }
    let out = Path::new(dir);
    std::fs::create_dir_all(out).map_err(|e| e.to_string())?;
    let mut files = 0;
    for frame in 0..4 {
        for (suffix, key) in [("", "text"), ("_warn", "warn")] {
            write_png(
                &out.join(format!("cat_{}{suffix}.png", frame + 1)),
                &cat(frame, colors[key], colors["blade"], colors["ground"]),
            )?;
            files += 1;
        }
    }
    for (state, key, frames) in poses() {
        for (k, frame) in frames.into_iter().enumerate() {
            let f = face(colors[key], frame);
            write_png(
                &out.join(format!("pilo_{state}_{}.png", k + 1)),
                &face_circle(&f),
            )?;
            write_png(
                &out.join(format!("pilo_s_{state}_{}.png", k + 1)),
                &doubled(&f),
            )?;
            files += 2;
        }
    }
    write_png(
        &out.join("opencode.png"),
        &opencode(colors["text"], colors["muted"]),
    )?;
    files += 1;
    Ok(json!({ "dir": dir, "files": files }))
}

#[cfg(test)]
mod tests {
    #[test]
    fn colours() {
        assert_eq!(super::color("0xff102030"), Some([0x10, 0x20, 0x30, 0xff]));
        assert_eq!(super::color("zz"), None);
    }

    #[test]
    fn opencode_mark() {
        let g = super::opencode([1, 1, 1, 255], [2, 2, 2, 255]);
        // 4×5 cells of 2 pt at @2x: 16×20 px.
        assert_eq!((g[0].len(), g.len()), (16, 20));
        assert_eq!(g[4][4], None); // empty top row inside
        assert_eq!(g[8][4], Some([2, 2, 2, 255])); // fill
    }
}
