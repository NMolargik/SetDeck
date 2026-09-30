#!/usr/bin/env python3
"""
pin_package_strings.py — keep package-rendered strings safe in the app's String Catalog.

SetDeck's UI lives in Swift package modules, but SwiftUI's key-based initializers
(`Text("…")`, `Button("…")`, `Label("…", systemImage:)`, …) resolve against
`Bundle.main` at runtime. Translations therefore live in the *app target's*
`SetDeck/Localizable.xcstrings` — by design. Xcode's automatic extraction, however, only
scans app-target sources, so every key whose literal moved into the package gets flagged
"stale" and is one careless click away from deletion.

This script pins every catalog entry whose literal appears anywhere in
`Packages/SetDeck/Sources` to `extractionState: "manual"` (rescuing already-stale ones),
and reports package string literals that are missing from the catalog entirely.

Run it after adding user-facing strings to package code:

    python3 Scripts/pin_package_strings.py
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "SetDeck" / "Localizable.xcstrings"
PACKAGE_SOURCES = ROOT / "Packages" / "SetDeck" / "Sources"

# Format specifiers as they appear in catalog keys (source code uses \(…) interpolation).
SPECIFIER = re.compile(r"%(?:\d+\$)?(?:l?l?[du]|[@fgeasxX])")


def package_source_blob() -> str:
    parts = []
    for path in sorted(PACKAGE_SOURCES.rglob("*.swift")):
        parts.append(path.read_text())
    return "\n".join(parts)


def key_matches(key: str, blob: str) -> bool:
    """True if `key`'s literal fragments all appear in the package sources."""
    # Try the exact literal first (covers keys with no format specifiers), and the
    # Swift-escaped form for keys containing double quotes.
    escaped = key.replace('"', '\\"').replace("\n", "\\n")
    if key in blob or escaped in blob:
        return True
    # Keys with format specifiers: require every literal fragment to appear.
    fragments = [f for f in SPECIFIER.split(key) if f.strip()]
    if not fragments or fragments == [key]:
        return False
    return all(f in blob or f.replace('"', '\\"') in blob for f in fragments)


# SwiftUI/Foundation call sites whose first string literal is a localization key.
LITERAL_PATTERNS = [
    re.compile(p)
    for p in (
        r'Text\("((?:[^"\\]|\\.)+)"[,)]',
        r'Label\("((?:[^"\\]|\\.)+)",',
        r'Button\("((?:[^"\\]|\\.)+)"[,)]',
        r'Toggle\("((?:[^"\\]|\\.)+)",',
        r'Picker\("((?:[^"\\]|\\.)+)",',
        r'TextField\("((?:[^"\\]|\\.)+)",',
        r'Section\("((?:[^"\\]|\\.)+)"\)',
        r'ContentUnavailableView\("((?:[^"\\]|\\.)+)",',
        r'LabeledContent\("((?:[^"\\]|\\.)+)"[,)]',
        r'\.navigationTitle\("((?:[^"\\]|\\.)+)"\)',
        r'\.accessibilityLabel\("((?:[^"\\]|\\.)+)"\)',
        r'\.accessibilityHint\("((?:[^"\\]|\\.)+)"\)',
        r'\.alert\("((?:[^"\\]|\\.)+)",',
        r'String\(localized: "((?:[^"\\]|\\.)+)"\)',
        r'LocalizedStringResource\("((?:[^"\\]|\\.)+)"\)',
        r'ProgressView\("((?:[^"\\]|\\.)+)"\)',
        r'Stepper\("((?:[^"\\]|\\.)+)",',
        r'DatePicker\("((?:[^"\\]|\\.)+)",',
    )
]


def package_literals(blob: str) -> set[str]:
    found: set[str] = set()
    for pattern in LITERAL_PATTERNS:
        for match in pattern.finditer(blob):
            literal = match.group(1)
            # Normalize Swift interpolation to a catalog-style wildcard marker.
            literal = re.sub(r"\\\((?:[^()]|\([^()]*\))*\)", "%", literal)
            literal = literal.replace('\\"', '"').replace("\\n", "\n")
            found.add(literal)
    return found


def catalog_covers(literal: str, keys: list[str]) -> bool:
    if literal in keys:
        return True
    if "%" in literal:  # interpolated: match on fragments against some key
        fragments = [f for f in literal.split("%") if f.strip()]
        for key in keys:
            if all(f in key for f in fragments):
                return True
    return False


def main() -> int:
    catalog = json.loads(CATALOG.read_text())
    blob = package_source_blob()
    strings = catalog["strings"]

    pinned, rescued = [], []
    for key, entry in strings.items():
        if not key_matches(key, blob):
            continue
        state = entry.get("extractionState", "automatic")
        if state == "stale":
            rescued.append(key)
        elif state != "manual":
            pinned.append(key)
        entry["extractionState"] = "manual"
        # Manual entries opt into Xcode's symbol generation by default, which rejects
        # case-colliding keys ("Babies"/"babies"). We don't use generated symbols.
        entry["shouldGenerateSymbol"] = False

    # Match Xcode's own serialization (`"key" : value`) so the diff stays quiet.
    CATALOG.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True, separators=(",", " : ")) + "\n"
    )

    print(f"pinned {len(pinned)} entries to manual; rescued {len(rescued)} stale entries")
    for key in rescued:
        print(f"  rescued: {key!r}")

    keys = list(strings.keys())
    missing = sorted(
        literal for literal in package_literals(blob)
        if not catalog_covers(literal, keys)
    )
    if missing:
        print(f"\n{len(missing)} package literals missing from the catalog:")
        for literal in missing:
            print(f"  MISSING: {literal!r}")
    else:
        print("\nno package literals missing from the catalog")
    return 0


if __name__ == "__main__":
    sys.exit(main())
