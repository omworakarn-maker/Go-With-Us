#!/usr/bin/env python3
"""Verify production presentation state transitions without UIKit/Simulator."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "GoWithUs/Views/Components/CustomTabBar.swift").read_text()
model = source.split("// MARK: - Trip presentation lifecycle\n", 1)[1]
model = model.split("// MARK: - End trip presentation lifecycle", 1)[0]
tests = (root / "Tests/TripPresentationLifecycleRegression.swift").read_text()
with tempfile.TemporaryDirectory(prefix="gowithus-presentation-tests-") as directory:
    temporary = Path(directory)
    combined = temporary / "PresentationCheck.swift"
    combined.write_text("import Foundation\n" + model + "\n" + tests)
    executable = temporary / "presentation-check"
    subprocess.run([
        "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc",
        "-parse-as-library", "-module-cache-path", str(temporary / "module-cache"),
        str(combined), "-o", str(executable),
    ], check=True)
    subprocess.run([str(executable)], check=True)
