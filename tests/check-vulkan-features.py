#!/usr/bin/env python3
"""Check that Android Vulkan 1.3 advertising does not invent dEQP certification.

This is a module packaging/advertising check, not a Khronos conformance test.
"""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PERMS = ROOT / "system/vendor/etc/permissions"
VULKAN_VERSION = PERMS / "android.hardware.vulkan.version.xml"
DEQP = PERMS / "android.software.vulkan.deqp.level.xml"

if DEQP.exists():
    raise SystemExit(
        "FAIL: this module must not override the ROM's dEQP certification date. "
        "Remove android.software.vulkan.deqp.level.xml until actual CTS/dEQP passes."
    )

if not VULKAN_VERSION.is_file():
    raise SystemExit("FAIL: missing Vulkan version feature declaration")

root = ET.parse(VULKAN_VERSION).getroot()
versions = [
    int(feature.attrib["version"], 0)
    for feature in root.iter("feature")
    if feature.attrib.get("name") == "android.hardware.vulkan.version"
]
if len(versions) != 1:
    raise SystemExit("FAIL: expected exactly one android.hardware.vulkan.version")

api = versions[0]
major = (api >> 22) & 0x7F
minor = (api >> 12) & 0x3FF
patch = api & 0xFFF
if (major, minor) != (1, 3):
    raise SystemExit(f"FAIL: Vulkan 1.3 declaration changed to {major}.{minor}.{patch}")
print(f"OK: Android Vulkan version feature is {major}.{minor}.{patch}.")
print("OK: packaged module does not override the ROM's Vulkan dEQP claim.")
print("NOTE: this checks XML metadata only. Runtime Vulkan 1.3 and CTS must be tested on hardware.")
