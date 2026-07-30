#!/usr/bin/env python3
"""Patch provisioning profiles to fix TeamIdentifier mismatch with self-signed cert."""
import plistlib, subprocess, tempfile, os, sys

profiles_dir = sys.argv[1] if len(sys.argv) > 1 else "build-system/fake-codesigning/profiles"
identity = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else "Apple Distribution: Telegram FZ-LLC (C67CF9S4VU)"

print("Patching profiles with identity: " + identity)

for fname in sorted(os.listdir(profiles_dir)):
    if not fname.endswith(".mobileprovision"):
        continue
    fpath = os.path.join(profiles_dir, fname)
    r = subprocess.run(["security", "cms", "-D", "-i", fpath], capture_output=True, text=True)
    if r.returncode != 0:
        continue
    plist = plistlib.loads(r.stdout.encode())
    plist["TeamIdentifier"] = []
    plist["TeamName"] = ["Organization"]
    if "Entitlements" in plist:
        plist["Entitlements"].pop("com.apple.developer.team-identifier", None)
    tmp = tempfile.mktemp(suffix=".plist")
    with open(tmp, "wb") as f:
        plistlib.dump(plist, f)
    subprocess.run(["security", "cms", "-S", "-N", identity, "-i", tmp, "-o", fpath], capture_output=True, text=True)
    os.unlink(tmp)
    print("  Patched " + fname)

print("All profiles patched.")
