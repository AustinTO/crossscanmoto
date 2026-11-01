#!/usr/bin/env python3
"""Summarize structured data strings embedded in MotoScan's native ELF.

This intentionally emits a structural inventory, not a redistributed database.
Requires binutils `strings` and does not load or execute the Android library.
"""

import argparse
import collections
import hashlib
import json
import pathlib
import re
import subprocess


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("elf", type=pathlib.Path)
    parser.add_argument("--output", type=pathlib.Path)
    args = parser.parse_args()
    raw = args.elf.read_bytes()
    lines = subprocess.check_output(
        ["strings", "-a", "-n", "4", "-t", "d", str(args.elf)], text=True
    ).splitlines()

    rows = []
    values_by_offset = {}
    for line in lines:
        match = re.match(r"\s*(\d+)\s+(.*)$", line)
        if not match:
            continue
        offset, value = int(match.group(1)), match.group(2)
        values_by_offset[offset] = value
        if re.match(r"\d{2};", value):
            fields = value.split(";")
            rows.append({"offset": offset, "record_type": fields[0], "field_count": len(fields)})

    type_counts = collections.Counter(row["record_type"] for row in rows)
    known = {"00", "01", "06", "09", "10", "12"}
    data_rows = [row for row in rows if row["record_type"] in known]
    layouts = collections.defaultdict(collections.Counter)
    for row in rows:
        if row["record_type"] in {"06", "09", "10", "12"}:
            layouts[row["record_type"]][row["field_count"]] += 1
    result = {
        "artifact": args.elf.name,
        "sha256": hashlib.sha256(raw).hexdigest(),
        "elf_bytes": len(raw),
        "extraction": "printable strings with file offsets; no execution/decompilation",
        "semicolon_record_count": len(rows),
        "record_counts_by_type": dict(sorted(type_counts.items())),
        "known_record_family_count": len(data_rows),
        "candidate_layouts_by_family": {
            family: {str(fields): count for fields, count in sorted(counts.items())}
            for family, counts in sorted(layouts.items())
        },
        "sample_records": [],
        "notes": [
            "Record type numbers are preserved as opaque family identifiers.",
            "Offsets refer to the supplied ELF; repeated records may be reused across ECU datasets.",
            "Numeric identifiers and byte payloads are not semantically decoded here.",
        ],
    }
    for row in data_rows[:30]:
        value = values_by_offset[row["offset"]]
        result["sample_records"].append({**row, "prefix": value[:100]})
    output = json.dumps(result, indent=2) + "\n"
    if args.output:
        args.output.write_text(output)
    else:
        print(output, end="")


if __name__ == "__main__":
    main()
