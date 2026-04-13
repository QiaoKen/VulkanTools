#!/usr/bin/env python3
"""
Analyze API timing logs produced by VK_LAYER_LUNARG_api_dump in timing-only mode.

Input format (one per line):
    vkFunctionName - API Duration: <number> <unit>
Examples:
    vkCreateInstance - API Duration: 1250 us
    vkQueuePresentKHR - API Duration: 423 us

By default, frames are delimited by vkQueuePresentKHR. You can change the
set of frame-boundary functions via --frame-boundary.

Outputs:
- Per-frame rankings (aggregate per API and top individual calls)
- Overall aggregate rankings across the entire run
- Optional JSON/CSV exports

Usage:
    python3 scripts/analyze_api_timing.py \
        /path/to/timing_only.txt \
        --top 20 \
        --frame-boundary vkQueuePresentKHR \
        --json-out timing_summary.json
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
from collections import defaultdict, Counter
from dataclasses import dataclass
from typing import Dict, List, Tuple, Iterable, Optional

# Match timing anywhere in the line, since logs can include rich prefixes/suffixes
DURATION_RE = re.compile(r"(vk\w+)\s*-\s*API Duration:\s*([0-9]+(?:\.[0-9]+)?)\s*(ns|us|ms|s)\b")

# Header of the form: "Thread 0, Frame 123:"
HEADER_RE = re.compile(r"^Thread\s+(?P<thread>\d+),\s*Frame\s+(?P<frame>\d+):\s*$")

UNIT_TO_US = {
    "ns": 1.0 / 1000.0,
    "us": 1.0,
    "ms": 1000.0,
    "s":  1000.0 * 1000.0,
}

@dataclass
class Event:
    line_no: int
    frame_index: int
    func: str
    duration_us: float

@dataclass
class Aggregate:
    total_us: float = 0.0
    count: int = 0

    def add(self, us: float):
        self.total_us += us
        self.count += 1

    @property
    def avg_us(self) -> float:
        return self.total_us / self.count if self.count else 0.0


def parse_args(argv: Optional[List[str]] = None):
    p = argparse.ArgumentParser(description="Analyze Vulkan API timing logs (timing-only)")
    p.add_argument("log", help="Path to timing_only.txt (or similar)")
    p.add_argument("--top", type=int, default=20, help="How many entries to show per ranking (default: 20)")
    p.add_argument("--frame-boundary", action="append", default=["vkQueuePresentKHR"],
                   help="Function(s) that mark the end of a frame (can be specified multiple times). Default: vkQueuePresentKHR")
    p.add_argument("--json-out", default=None, help="Path to write JSON summary (optional)")
    p.add_argument("--csv-overall", default=None, help="CSV file for overall aggregate per API (optional)")
    p.add_argument("--csv-per-frame-dir", default=None, help="Directory to write per-frame aggregate CSV files (optional)")
    p.add_argument("--include-boundary-in-frame", action="store_true", default=True,
                   help="Include boundary call (e.g., vkQueuePresentKHR) in the preceding frame (default: true)")
    p.add_argument("--no-include-boundary-in-frame", dest="include_boundary_in_frame", action="store_false")
    return p.parse_args(argv)


def parse_log(path: str, boundary_funcs: Iterable[str], include_boundary_in_frame: bool = True) -> List[Event]:
    """
    Parse the log and return a list of Events.

    Strategy:
    - Prefer explicit frame headers like "Thread X, Frame Y:" if present.
    - Otherwise, fallback to incrementing frames on boundary function calls (e.g., vkQueuePresentKHR).
    - Extract duration by searching timing pattern anywhere in the line.
    """
    boundary = set(boundary_funcs)
    events: List[Event] = []
    frame = 0
    current_frame_from_header: Optional[int] = None
    saw_header = False

    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            for i, raw in enumerate(f, start=1):
                line = raw.strip()
                if not line:
                    continue

                # Detect frame header
                h = HEADER_RE.match(line)
                if h:
                    try:
                        current_frame_from_header = int(h.group("frame"))
                        saw_header = True
                    except Exception:
                        pass
                    continue

                # Search for timing anywhere in the line
                m = DURATION_RE.search(line)
                if not m:
                    continue

                func = m.group(1)
                val = float(m.group(2))
                unit = m.group(3)
                us = val * UNIT_TO_US.get(unit, 1.0)

                # Determine frame index
                if saw_header and current_frame_from_header is not None:
                    frame_idx = current_frame_from_header
                else:
                    # Fallback to boundary-based framing
                    frame_idx = frame
                    if func in boundary and not include_boundary_in_frame:
                        # advance frame first, then attribute to new frame
                        frame += 1
                        frame_idx = frame
                    else:
                        # attribute to current frame, then advance if boundary
                        if func in boundary:
                            # attribute to current frame first
                            pass
                
                events.append(Event(i, frame_idx, func, us))

                # Advance frame after adding event if boundary and including boundary in current frame
                if not saw_header:
                    if func in boundary and include_boundary_in_frame:
                        frame += 1
    except FileNotFoundError:
        print(f"File not found: {path}", file=sys.stderr)
        sys.exit(1)
    return events


def aggregate_by_function(events: Iterable[Event]) -> Dict[str, Aggregate]:
    agg: Dict[str, Aggregate] = defaultdict(Aggregate)
    for e in events:
        agg[e.func].add(e.duration_us)
    return agg


def format_us(us: float) -> str:
    # Render in a human-friendly way
    if us >= 1_000_000.0:
        return f"{us/1_000_000.0:.3f} s"
    elif us >= 1_000.0:
        return f"{us/1_000.0:.3f} ms"
    else:
        return f"{us:.0f} us"


def print_overall_summary(events: List[Event], top: int):
    print("\n=== Overall API duration ranking (aggregate per API) ===")
    agg = aggregate_by_function(events)
    total_all_us = sum(e.duration_us for e in events)
    rows = sorted(((fn, a.total_us, a.count, a.avg_us) for fn, a in agg.items()), key=lambda x: x[1], reverse=True)
    for rank, (fn, total_us, count, avg_us) in enumerate(rows[:top], start=1):
        pct = (total_us / total_all_us * 100.0) if total_all_us > 0 else 0.0
        print(f"{rank:2d}. {fn:35s} total={format_us(total_us):>9}  count={count:6d}  avg={format_us(avg_us):>9}  ({pct:5.1f}%)")

    print("\n=== Overall slowest individual calls ===")
    top_calls = sorted(events, key=lambda e: e.duration_us, reverse=True)[:top]
    for rank, e in enumerate(top_calls, start=1):
        print(f"{rank:2d}. frame={e.frame_index:4d}  {e.func:35s}  {format_us(e.duration_us):>9}  (line {e.line_no})")


def print_per_frame_summary(events: List[Event], top: int):
    # Group events by frame
    frames: Dict[int, List[Event]] = defaultdict(list)
    for e in events:
        frames[e.frame_index].append(e)

    for frame_idx in sorted(frames.keys()):
        fevents = frames[frame_idx]
        if not fevents:
            continue
        total_us = sum(e.duration_us for e in fevents)
        print(f"\n=== Frame {frame_idx}  (total={format_us(total_us)}, {len(fevents)} calls) ===")

        # Aggregate per API for the frame
        agg = aggregate_by_function(fevents)
        rows = sorted(((fn, a.total_us, a.count, a.avg_us) for fn, a in agg.items()), key=lambda x: x[1], reverse=True)
        print(f"-- Top {top} APIs by total duration --")
        for rank, (fn, tsum, cnt, avg) in enumerate(rows[:top], start=1):
            pct = (tsum / total_us * 100.0) if total_us > 0 else 0.0
            print(f"{rank:2d}. {fn:35s} total={format_us(tsum):>9}  count={cnt:6d}  avg={format_us(avg):>9}  ({pct:5.1f}%)")

        # Slowest individual calls in the frame
        print(f"-- Top {top} slowest individual calls --")
        slow = sorted(fevents, key=lambda e: e.duration_us, reverse=True)[:top]
        for rank, e in enumerate(slow, start=1):
            print(f"{rank:2d}. {e.func:35s}  {format_us(e.duration_us):>9}  (line {e.line_no})")


def write_overall_csv(path: str, events: List[Event]):
    agg = aggregate_by_function(events)
    rows = sorted(((fn, a.total_us, a.count, a.avg_us) for fn, a in agg.items()), key=lambda x: x[1], reverse=True)
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["function", "total_us", "count", "avg_us"])
        for fn, total_us, count, avg_us in rows:
            w.writerow([fn, f"{total_us:.3f}", count, f"{avg_us:.3f}"])


def write_per_frame_csv(dir_path: str, events: List[Event]):
    frames: Dict[int, List[Event]] = defaultdict(list)
    for e in events:
        frames[e.frame_index].append(e)
    os.makedirs(dir_path, exist_ok=True)
    for frame_idx in sorted(frames.keys()):
        agg = aggregate_by_function(frames[frame_idx])
        rows = sorted(((fn, a.total_us, a.count, a.avg_us) for fn, a in agg.items()), key=lambda x: x[1], reverse=True)
        out = os.path.join(dir_path, f"frame_{frame_idx:04d}.csv")
        with open(out, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["function", "total_us", "count", "avg_us"])
            for fn, total_us, count, avg_us in rows:
                w.writerow([fn, f"{total_us:.3f}", count, f"{avg_us:.3f}"])


def write_json(path: str, events: List[Event]):
    frames: Dict[int, List[Event]] = defaultdict(list)
    for e in events:
        frames[e.frame_index].append({
            "line": e.line_no,
            "function": e.func,
            "duration_us": e.duration_us,
        })
    overall = aggregate_by_function(events)
    overall_rows = sorted(((fn, a.total_us, a.count, a.avg_us) for fn, a in overall.items()), key=lambda x: x[1], reverse=True)
    data = {
        "overall": [
            {"function": fn, "total_us": total_us, "count": count, "avg_us": avg_us}
            for fn, total_us, count, avg_us in overall_rows
        ],
        "frames": frames,
    }
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def main(argv: Optional[List[str]] = None):
    args = parse_args(argv)
    events = parse_log(args.log, args.frame_boundary, include_boundary_in_frame=args.include_boundary_in_frame)

    if not events:
        print("No timing lines found. Ensure the log is produced in timing-only mode.")
        return 1

    print_per_frame_summary(events, args.top)
    print_overall_summary(events, args.top)

    if args.csv_overall:
        write_overall_csv(args.csv_overall, events)
    if args.csv_per_frame_dir:
        write_per_frame_csv(args.csv_per_frame_dir, events)
    if args.json_out:
        write_json(args.json_out, events)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
