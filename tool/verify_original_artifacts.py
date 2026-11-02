#!/usr/bin/env python3
"""Verify local MotoScan APKs against docs/parity/original-artifacts.json."""

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs/parity/original-artifacts.json"
SDK_TOOLS = Path.home() / "Android/Sdk/build-tools/36.0.0"


def resolve_tool(name: str, override: str | None) -> str | None:
    return override or shutil.which(name) or (str(SDK_TOOLS / name) if (SDK_TOOLS / name).is_file() else None)


def run(command: list[str]) -> str:
    result = subprocess.run(command, text=True, capture_output=True)
    if result.returncode:
        raise ValueError(f"command failed ({result.returncode}): {' '.join(command)}\n{result.stderr.strip()}")
    return result.stdout


def verify(version: str, apk: Path, record: dict, aapt: str, apksigner: str) -> None:
    if not apk.is_file():
        raise ValueError(f"{version}: missing APK at {apk}; differential checks for this version are blocked")
    hasher = hashlib.sha256()
    with apk.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
    digest = hasher.hexdigest()
    if digest != record["sha256"]:
        raise ValueError(f"{version}: APK SHA-256 mismatch: expected {record['sha256']}, got {digest}")

    badging = run([aapt, "dump", "badging", str(apk)])
    package = re.search(r"^package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging, re.M)
    if not package:
        raise ValueError(f"{version}: could not parse package/version from aapt output")
    if package.groups() != (record["package"], record["version_code"], record["version_name"]):
        raise ValueError(f"{version}: package/version mismatch: {package.groups()}")

    signature = run([apksigner, "verify", "--verbose", "--print-certs", str(apk)])
    if "Verifies" not in signature:
        raise ValueError(f"{version}: apksigner did not verify the APK")
    signers = re.search(r"Number of signers: (\d+)", signature)
    if not signers or signers.group(1) != "1":
        raise ValueError(f"{version}: expected exactly one signer")
    fields = {
        "signer_dn": re.search(r"Signer #1 certificate DN: (.+)", signature),
        "certificate_sha256": re.search(r"Signer #1 certificate SHA-256 digest: ([0-9a-f]+)", signature),
        "certificate_sha1": re.search(r"Signer #1 certificate SHA-1 digest: ([0-9a-f]+)", signature),
    }
    for key, match in fields.items():
        if not match or match.group(1).lower() != record[key].lower():
            raise ValueError(f"{version}: {key} mismatch")

    with zipfile.ZipFile(apk) as archive:
        names = set(archive.namelist())
        actual_abis = sorted({name.split("/")[1] for name in names if name.startswith("lib/") and name.endswith(".so")})
        if actual_abis != sorted(record["abis"]):
            raise ValueError(f"{version}: ABI mismatch: expected {record['abis']}, got {actual_abis}")
        for entry, expected in record["entries"].items():
            if entry not in names:
                raise ValueError(f"{version}: missing expected APK entry {entry}")
            actual = hashlib.sha256(archive.read(entry)).hexdigest()
            if actual != expected:
                raise ValueError(f"{version}: SHA-256 mismatch for {entry}: expected {expected}, got {actual}")
    print(f"PASS {version}: package/version, APK SHA-256, signer, ABIs, DEX and native hashes verified ({apk})")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, choices=("1.110", "1.83"))
    parser.add_argument("--apk", required=True, type=Path, help="Path to the locally held APK; no download is attempted")
    parser.add_argument("--aapt", help="aapt executable (default: PATH or Android SDK build-tools/36.0.0)")
    parser.add_argument("--apksigner", help="apksigner executable (default: PATH or Android SDK build-tools/36.0.0)")
    args = parser.parse_args()
    aapt = resolve_tool("aapt", args.aapt)
    apksigner = resolve_tool("apksigner", args.apksigner)
    if not aapt or not apksigner:
        parser.error("aapt and apksigner are required (use --aapt/--apksigner or add Android SDK build-tools to PATH)")
    try:
        manifest = json.loads(MANIFEST.read_text())
        verify(args.version, args.apk.resolve(), manifest["artifacts"][args.version], aapt, apksigner)
    except (OSError, KeyError, json.JSONDecodeError, zipfile.BadZipFile, ValueError) as error:
        print(f"FAIL {args.version}: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
