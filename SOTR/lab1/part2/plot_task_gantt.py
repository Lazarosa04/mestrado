#!/usr/bin/env python3
"""Render a selected time window from task_trace.csv as a standalone SVG."""

import argparse
import csv
from html import escape
from pathlib import Path


TASK_ORDER = ["Plant", "Sensor", "Controller", "Actuator", "Load", "Display"]
TASK_COLORS = {
    "Plant": "#d9534f",
    "Sensor": "#f0ad4e",
    "Controller": "#5bc0de",
    "Actuator": "#5cb85c",
    "Load": "#8e6bbf",
    "Display": "#777777",
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_file", nargs="?", default="task_trace.csv")
    parser.add_argument("-o", "--output", default="task_gantt.svg")
    parser.add_argument("--start-ms", type=float, default=0.0)
    parser.add_argument("--duration-ms", type=float, default=100.0)
    args = parser.parse_args()

    if args.start_ms < 0 or args.duration_ms <= 0:
        parser.error("--start-ms must be non-negative and --duration-ms positive")

    window_start_ns = args.start_ms * 1_000_000
    window_end_ns = window_start_ns + args.duration_ms * 1_000_000
    records = []
    try:
        with Path(args.csv_file).open(newline="", encoding="utf-8") as trace_file:
            for row in csv.DictReader(trace_file):
                record = {
                    "task": row["task"],
                    "job": int(row["job"]),
                    "release": int(row["release_ns"]),
                    "start": int(row["start_ns"]),
                    "finish": int(row["finish_ns"]),
                    "cpu": int(row["cpu_ns"]),
                }
                if record["finish"] >= window_start_ns and record["start"] <= window_end_ns:
                    records.append(record)
    except (OSError, KeyError, ValueError) as error:
        parser.error(f"cannot read valid task trace {args.csv_file}: {error}")

    tasks = [task for task in TASK_ORDER if any(r["task"] == task for r in records)]
    tasks.extend(sorted({r["task"] for r in records} - set(tasks)))
    if not tasks:
        parser.error("the selected time window contains no recorded jobs")

    width = 1600
    left = 150
    right = 35
    top = 72
    row_height = 42
    bottom = 60
    plot_width = width - left - right
    height = top + row_height * len(tasks) + bottom
    scale = plot_width / (window_end_ns - window_start_ns)

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">',
        "<style>text{font-family:Arial,sans-serif;fill:#222}"
        ".axis{stroke:#555;stroke-width:1}.grid{stroke:#ddd;stroke-width:1}"
        ".bar{stroke:#333;stroke-width:.5}</style>",
        f'<rect width="{width}" height="{height}" fill="white"/>',
        f'<text x="{left}" y="28" font-size="19" font-weight="bold">'
        f"Task execution Gantt — {args.start_ms:g} to "
        f"{args.start_ms + args.duration_ms:g} ms</text>",
        f'<text x="{left}" y="50" font-size="12">'
        "Bars show wall-clock start-to-finish; tooltip includes thread CPU time "
        "(preemption/blocking is the difference).</text>",
    ]

    for tick in range(11):
        x = left + plot_width * tick / 10
        time_ms = args.start_ms + args.duration_ms * tick / 10
        svg.append(
            f'<line class="grid" x1="{x:.2f}" y1="{top}" x2="{x:.2f}" '
            f'y2="{height - bottom + 4}"/>'
        )
        svg.append(
            f'<text x="{x:.2f}" y="{height - bottom + 24}" text-anchor="middle" '
            f'font-size="11">{time_ms:.2f} ms</text>'
        )

    for task_index, task in enumerate(tasks):
        y = top + task_index * row_height
        svg.append(
            f'<text x="{left - 12}" y="{y + 22}" text-anchor="end" '
            f'font-size="14">{escape(task)}</text>'
        )
        svg.append(
            f'<line class="axis" x1="{left}" y1="{y + row_height - 2}" '
            f'x2="{width - right}" y2="{y + row_height - 2}"/>'
        )
        for record in records:
            if record["task"] != task:
                continue
            start = max(record["start"], window_start_ns)
            finish = min(record["finish"], window_end_ns)
            x = left + (start - window_start_ns) * scale
            bar_width = max(1.0, (finish - start) * scale)
            title = (
                f'{task} job {record["job"]}; '
                f'release={record["release"] / 1000:.3f} us; '
                f'start={record["start"] / 1000:.3f} us; '
                f'finish={record["finish"] / 1000:.3f} us; '
                f'wall={(record["finish"] - record["start"]) / 1000:.3f} us; '
                f'cpu={record["cpu"] / 1000:.3f} us'
            )
            svg.append(
                f'<rect class="bar" x="{x:.2f}" y="{y + 7}" '
                f'width="{bar_width:.2f}" height="24" rx="2" '
                f'fill="{TASK_COLORS.get(task, "#4c78a8")}">'
                f"<title>{escape(title)}</title></rect>"
            )

    svg.append("</svg>")
    try:
        Path(args.output).write_text("\n".join(svg) + "\n", encoding="utf-8")
    except OSError as error:
        parser.error(f"cannot write SVG {args.output}: {error}")
    print(f"Wrote {args.output} with {len(records)} jobs across {len(tasks)} tasks.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
