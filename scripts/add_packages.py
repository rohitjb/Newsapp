#!/usr/bin/env python3
"""
Adds 7 local Swift package references (XCLocalSwiftPackageReference) to
NewsApp.xcodeproj/project.pbxproj and wires them into the PBXProject object.
"""

import re
import sys

PBXPROJ = "NewsApp.xcodeproj/project.pbxproj"

PACKAGES = [
    ("NetworkModule",     "Packages/Core/NetworkModule"),
    ("StorageModule",     "Packages/Core/StorageModule"),
    ("FeatureFlagModule", "Packages/Core/FeatureFlagModule"),
    ("SourceModule",      "Packages/Features/SourceModule"),
    ("ArticleModule",     "Packages/Features/ArticleModule"),
    ("SavedModule",       "Packages/Features/SavedModule"),
    ("WebModule",         "Packages/Features/WebModule"),
]

# Fixed UUIDs with prefix A1B2C3 — clearly distinct from existing F974F8xx UUIDs
UUIDS = [
    "A1B2C3D4E5F600000000001A",
    "A1B2C3D4E5F600000000002B",
    "A1B2C3D4E5F600000000003C",
    "A1B2C3D4E5F600000000004D",
    "A1B2C3D4E5F600000000005E",
    "A1B2C3D4E5F600000000006F",
    "A1B2C3D4E5F600000000007G",
]

assert len(UUIDS) == len(PACKAGES), "UUID count must match package count"

def main():
    with open(PBXPROJ, "r") as f:
        content = f.read()

    # Guard: don't run twice
    if "XCLocalSwiftPackageReference" in content:
        print("ERROR: XCLocalSwiftPackageReference already present. Aborting to avoid double insertion.")
        sys.exit(1)

    # Verify none of our UUIDs already exist in the file
    for uid in UUIDS:
        if uid in content:
            print(f"ERROR: UUID {uid} already exists in project file. Aborting.")
            sys.exit(1)

    # ------------------------------------------------------------------ #
    # 1. Build the XCLocalSwiftPackageReference section text              #
    # ------------------------------------------------------------------ #
    section_lines = ["\n/* Begin XCLocalSwiftPackageReference section */"]
    for (name, path), uid in zip(PACKAGES, UUIDS):
        section_lines.append(
            f"\t\t{uid} /* {name} */ = {{\n"
            f"\t\t\tisa = XCLocalSwiftPackageReference;\n"
            f"\t\t\trelativePath = {path};\n"
            f"\t\t}};"
        )
    section_lines.append("/* End XCLocalSwiftPackageReference section */\n")
    section_text = "\n".join(section_lines)

    # Insert just before the closing `};` of the objects dictionary.
    # The objects dict ends with a line that is exactly "\t};" (one tab).
    # We look for the last occurrence of that pattern followed by a newline
    # and the rootObject line.
    objects_close = "\t};\n\trootObject"
    insert_point = content.rfind(objects_close)
    if insert_point == -1:
        print("ERROR: Could not find objects closing marker. Aborting.")
        sys.exit(1)

    content = content[:insert_point] + section_text + "\n" + content[insert_point:]

    # ------------------------------------------------------------------ #
    # 2. Add packageReferences to PBXProject, right before productRefGroup #
    # ------------------------------------------------------------------ #
    refs_items = ",\n".join(
        f"\t\t\t\t{uid} /* {name} */"
        for (name, _), uid in zip(PACKAGES, UUIDS)
    )
    package_references_block = (
        f"\t\t\tpackageReferences = (\n{refs_items},\n\t\t\t);\n"
    )

    # Target the specific line `\t\t\tproductRefGroup = ...`
    product_ref_pattern = r"(\t\t\tproductRefGroup = )"
    match = re.search(product_ref_pattern, content)
    if not match:
        print("ERROR: Could not find productRefGroup in PBXProject. Aborting.")
        sys.exit(1)

    insert_pos = match.start()
    content = content[:insert_pos] + package_references_block + content[insert_pos:]

    # ------------------------------------------------------------------ #
    # 3. Write modified file back                                         #
    # ------------------------------------------------------------------ #
    with open(PBXPROJ, "w") as f:
        f.write(content)
    print(f"Written: {PBXPROJ}")

    # ------------------------------------------------------------------ #
    # 4. Validate                                                         #
    # ------------------------------------------------------------------ #
    with open(PBXPROJ, "r") as f:
        result = f.read()

    missing = []
    for (name, path), uid in zip(PACKAGES, UUIDS):
        if uid not in result:
            missing.append(f"  UUID missing: {uid} ({name})")
        if f"XCLocalSwiftPackageReference" not in result:
            missing.append("  isa = XCLocalSwiftPackageReference not found")
        if path not in result:
            missing.append(f"  relativePath missing: {path}")

    if "packageReferences" not in result:
        missing.append("  packageReferences key not found in PBXProject")

    if missing:
        print("VALIDATION FAILED:")
        for m in missing:
            print(m)
        sys.exit(1)

    count = result.count("XCLocalSwiftPackageReference")
    print(f"Validation passed: found {count} XCLocalSwiftPackageReference occurrences.")
    print("All 7 packages successfully added.")

if __name__ == "__main__":
    main()
