#!/usr/bin/env python3
"""Print WallpaperTypes debug-model fields from macOS 26.5.2 reflection metadata.

This read-only extractor targets the active macOS 26.5.2 arm64e cache layout.
It decodes `__swift5_fieldmd` directly instead of relying on unavailable private
Swift modules or guessed Codable forms.
"""

from __future__ import annotations

import struct
from pathlib import Path


CACHE = Path(
    "/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/"
    "dyld_shared_cache_arm64e.05"
)
TEXT_VM_ADDRESS = 0x27B24D000
TEXT_FILE_OFFSET = 0x58475000
FIELD_METADATA_VM_ADDRESS = 0x27B2BE5CC
FIELD_METADATA_SIZE = 0x2658
TYPE_DESCRIPTOR_LIST_VM_ADDRESS = 0x27B2C214C
TYPE_DESCRIPTOR_LIST_SIZE = 0x380
EXPECTED_TYPE_NAMES = (
    "WallpaperDebugAssetType",
    "WallpaperDebugRequest",
    "WallpaperDebugResponse",
    "WallpaperAssetList",
    "WallpaperAssetDownloadState",
    "WallpaperDebugRequestMessage",
)
TYPE_KINDS = {16: "module", 17: "struct", 18: "enum"}


def read_cache_slice() -> bytes:
    text_size = 0x7A2C0
    descriptor_end = (FIELD_METADATA_VM_ADDRESS - TEXT_VM_ADDRESS) + FIELD_METADATA_SIZE
    if descriptor_end > text_size:
        raise RuntimeError("WallpaperTypes metadata lies outside the configured __TEXT range.")

    with CACHE.open("rb") as cache:
        cache.seek(TEXT_FILE_OFFSET)
        contents = cache.read(text_size)

    if len(contents) != text_size:
        raise RuntimeError("The dyld cache did not return the expected WallpaperTypes __TEXT bytes.")
    if contents[:4] != b"\xcf\xfa\xed\xfe":
        raise RuntimeError("The configured cache offset is not an arm64 Mach-O image.")
    return contents


def c_string(contents: bytes, virtual_address: int) -> str:
    offset = virtual_address - TEXT_VM_ADDRESS
    if not 0 <= offset < len(contents):
        return f"<outside WallpaperTypes __TEXT: 0x{virtual_address:x}>"

    end = contents.find(b"\0", offset)
    if end < 0:
        return "<unterminated string>"
    return contents[offset:end].decode("utf-8", errors="replace")


def field_descriptors(contents: bytes) -> dict[int, tuple[int, tuple[str, ...]]]:
    offset = FIELD_METADATA_VM_ADDRESS - TEXT_VM_ADDRESS
    end = offset + FIELD_METADATA_SIZE
    extracted: dict[int, tuple[int, tuple[str, ...]]] = {}

    while offset + 16 <= end:
        _, _, kind, record_size, count = struct.unpack_from("<iiHHI", contents, offset)
        descriptor_size = 16 + record_size * count
        if record_size < 12 or record_size > 128 or count > 64 or offset + descriptor_size > end:
            raise RuntimeError(f"Invalid field descriptor at 0x{TEXT_VM_ADDRESS + offset:x}.")

        fields: list[str] = []
        for index in range(count):
            record_offset = offset + 16 + record_size * index
            _, _, field_name_relative_offset = struct.unpack_from("<Iii", contents, record_offset)
            field_name_address = TEXT_VM_ADDRESS + record_offset + 8 + field_name_relative_offset
            fields.append(c_string(contents, field_name_address))

        extracted[TEXT_VM_ADDRESS + offset] = (kind, tuple(fields))
        offset += descriptor_size

    if offset != end:
        raise RuntimeError("WallpaperTypes field-descriptor scan did not finish on the expected boundary.")
    return extracted


def signed_32(contents: bytes, virtual_address: int) -> int:
    return struct.unpack_from("<i", contents, virtual_address - TEXT_VM_ADDRESS)[0]


def type_descriptors(contents: bytes) -> dict[str, tuple[str, tuple[str, ...]]]:
    fields = field_descriptors(contents)
    result: dict[str, tuple[str, tuple[str, ...]]] = {}
    end = TYPE_DESCRIPTOR_LIST_VM_ADDRESS + TYPE_DESCRIPTOR_LIST_SIZE

    for slot in range(TYPE_DESCRIPTOR_LIST_VM_ADDRESS, end, 4):
        descriptor = slot + signed_32(contents, slot)
        offset = descriptor - TEXT_VM_ADDRESS
        if not 0 <= offset + 20 <= len(contents):
            continue

        context_flags = struct.unpack_from("<I", contents, offset)[0]
        context_kind = context_flags & 0x1F
        type_name = c_string(contents, descriptor + 8 + signed_32(contents, descriptor + 8))
        field_descriptor = descriptor + 16 + signed_32(contents, descriptor + 16)
        field_data = fields.get(field_descriptor)
        if field_data is None:
            continue

        _, field_names = field_data
        result[type_name] = (TYPE_KINDS.get(context_kind, f"context-{context_kind}"), field_names)
    return result


def main() -> None:
    if not CACHE.is_file():
        raise SystemExit(f"Wallpaper dyld cache slice is unavailable: {CACHE}")

    matches = type_descriptors(read_cache_slice())
    missing = set(EXPECTED_TYPE_NAMES) - set(matches)
    if missing:
        raise SystemExit(f"Expected debug metadata was not found: {sorted(missing)!r}")

    for name in EXPECTED_TYPE_NAMES:
        kind, fields = matches[name]
        print(f"{name} ({kind}): {', '.join(fields)}")


if __name__ == "__main__":
    main()
