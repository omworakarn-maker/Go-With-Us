#!/usr/bin/env python3
"""Catch missing camera purpose strings in the configurations actually built."""
from pathlib import Path
import json
import plistlib
import subprocess

root = Path(__file__).resolve().parents[1]
project = root / 'native-ios26/gowithus1.xcodeproj/project.pbxproj'
data = json.loads(subprocess.check_output(['plutil', '-convert', 'json', '-o', '-', str(project)]))
checked = []
for value in data['objects'].values():
    settings = value.get('buildSettings', {})
    if settings.get('PRODUCT_BUNDLE_IDENTIFIER') != 'application.gowithus1':
        continue
    assert settings.get('GENERATE_INFOPLIST_FILE') == 'YES'
    assert settings.get('INFOPLIST_KEY_NSCameraUsageDescription', '').strip(), value['name']
    checked.append(value['name'])
assert set(checked) == {'Debug', 'Release'}, checked
legacy = plistlib.loads((root / 'native-ios/GoWithUs/Info.plist').read_bytes())
assert legacy.get('NSCameraUsageDescription', '').strip()
print('PASS: camera usage description in iOS26 Debug + Release and legacy iOS plist')
