#!/bin/sh
set -eu

wallpaper="/System/Library/PrivateFrameworks/Wallpaper.framework/Versions/A/Wallpaper"

print_header() {
    printf '\n## %s\n\n' "$1"
}

print_header 'Wallpaper ContentType and redraw-related exports'
xcrun dyld_info -exports "$wallpaper" |
    rg 'ContentType|ViewModelRefreshReason|ensureViewModelIsUpToDate|WallpaperDisplayAttributes' |
    swift demangle

print_header 'Wallpaper Swift field metadata case names'
python3 - <<'PY'
import re
import struct
import subprocess

IMAGE = "/System/Library/PrivateFrameworks/Wallpaper.framework/Versions/A/Wallpaper"
INTERESTING_NAMES = {
    "desktop",
    "screenSaver",
    "launch",
    "navigation",
    "wallpaperInstallation",
    "ensureViewModelIsUpToDate",
    "diagnosticState",
    "snapshotAllSpaces",
}


def section(segment, section_name):
    output = subprocess.check_output(
        ["xcrun", "dyld_info", "-section", segment, section_name, IMAGE],
        text=True,
        stderr=subprocess.STDOUT,
    )
    values = {}
    for line in output.splitlines():
        match = re.match(r"(0x[0-9A-Fa-f]+):\s*(.*)$", line)
        if not match:
            continue
        address = int(match.group(1), 16)
        bytes_on_line = re.findall(r"\b[0-9A-Fa-f]{2}\b", match.group(2))
        for index, value in enumerate(bytes_on_line):
            values[address + index] = int(value, 16)

    if not values:
        raise RuntimeError(f"dyld_info did not return bytes for {segment},{section_name}")

    low = min(values)
    high = max(values) + 1
    blob = bytes(values.get(address, 0) for address in range(low, high))
    return low, high, blob


field_base, _, field_metadata = section("__TEXT", "__swift5_fieldmd")
refl_base, refl_high, reflection_strings = section("__TEXT", "__swift5_reflstr")


def int32(offset):
    return struct.unpack_from("<i", field_metadata, offset)[0]


def uint16(offset):
    return struct.unpack_from("<H", field_metadata, offset)[0]


def uint32(offset):
    return struct.unpack_from("<I", field_metadata, offset)[0]


def reflection_string(address):
    if not (refl_base <= address < refl_high):
        return None
    offset = address - refl_base
    end = reflection_strings.find(b"\0", offset)
    if end == -1:
        return None
    return reflection_strings[offset:end].decode("utf-8", "replace")


offset = 0
descriptor_index = 0
while offset + 16 <= len(field_metadata):
    descriptor_address = field_base + offset
    kind = uint16(offset + 8)
    record_size = uint16(offset + 10)
    field_count = uint32(offset + 12)
    if record_size < 12 or record_size > 64 or field_count > 2000:
        raise RuntimeError(
            f"Unexpected field descriptor shape at {descriptor_address:#x}: "
            f"record_size={record_size}, field_count={field_count}"
        )

    names = []
    record_offset = offset + 16
    for _ in range(field_count):
        name_relative = int32(record_offset + 8)
        name_address = field_base + record_offset + 8 + name_relative
        names.append(reflection_string(name_address) or f"<unresolved:{name_address:#x}>")
        record_offset += record_size

    if INTERESTING_NAMES.intersection(names):
        joined = ", ".join(names)
        print(
            f"descriptor[{descriptor_index}] address={descriptor_address:#x} "
            f"kind={kind} fields={field_count}: {joined}"
        )

    offset = record_offset
    descriptor_index += 1

print(f"parsedDescriptors={descriptor_index}")
PY

print_header 'Wallpaper ContentType disassembly anchors'
xcrun dyld_info -all_sections "$wallpaper" |
    rg '\$s9Wallpaper11ContentTypeO8allCases|\$s9Wallpaper11ContentTypeO11description|\$s9Wallpaper0A17DisplayAttributesV7desktop|\$s9Wallpaper0A17DisplayAttributesV11screenSaver' -C 8
