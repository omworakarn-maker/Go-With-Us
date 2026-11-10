#!/usr/bin/env python3
"""Run production loader lifecycle logic on macOS with a minimal image stand-in."""
from pathlib import Path
import platform
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
sdk = subprocess.check_output(['xcrun', '--sdk', 'macosx', '--show-sdk-path'], text=True).strip()
compiler = subprocess.check_output(['xcrun', '--find', 'swiftc'], text=True).strip()
harness = (root / 'native-ios26/Tests/ImageLoaderLifecycleRegression.swift').read_text()
for edition in ['native-ios', 'native-ios26']:
    source = (root / edition / 'GoWithUs/Utils/ImageLoader.swift').read_text().replace('import SwiftUI', 'import Foundation')
    with tempfile.TemporaryDirectory(prefix='gowithus-loader-') as directory:
        folder = Path(directory)
        fixture = folder / 'Main.swift'
        fixture.write_text(harness + '\n' + source)
        binary = folder / 'check'
        subprocess.run([compiler, '-parse-as-library', '-swift-version', '5', '-sdk', sdk,
                        '-target', platform.machine() + '-apple-macosx14.0', '-module-cache-path',
                        '/tmp/gowithus-branding-cache-intel', str(fixture), '-o', str(binary)], check=True)
        print(edition, flush=True)
        subprocess.run([str(binary)], check=True)
