#!/usr/bin/env python3
"""Exercise the production motion model on macOS without a simulator."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "GoWithUs/Views/Components/CustomTabBar.swift").read_text()
model = source.split("// MARK: - Lens motion (independent of UIKit for deterministic verification)\n", 1)[1]
model = model.split("// MARK: - End lens motion", 1)[0]
tests = (root / "Tests/LensMotionRegression.swift").read_text()
with tempfile.TemporaryDirectory(prefix="gowithus-lens-tests-") as directory:
    temporary = Path(directory)
    combined = temporary / "LensMotionCheck.swift"
    combined.write_text("import Foundation\n" + model + "\n" + tests)
    executable = temporary / "lens-check"
    subprocess.run([
        "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc",
        "-parse-as-library", "-module-cache-path", str(temporary / "module-cache"),
        str(combined), "-o", str(executable),
    ], check=True)
    subprocess.run([str(executable)], check=True)
