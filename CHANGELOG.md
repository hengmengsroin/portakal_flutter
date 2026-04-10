## 0.1.6

- Fixed analyzer warnings for `avoid_print` in example project.
- Minor formatting and documentation fixes to prepare for release.

## 0.1.5

- Prepared release for publish.
- Updated package version to `0.1.5`.
- Refreshed changelog for the latest release cycle.

## 0.1.4

- Cleaned up analyzer findings and code style across parser/language modules.
- Standardized formatting across source and test files for maintainability.
- Updated parser test accessors to lowerCamelCase (`typeStr`, `endVal`, `labelName`, `codeStr`).
- Updated internal task tracker milestones to reflect completed phases.
- Added `.pubignore` to exclude internal workspace files from the published package.

## 0.1.3

- Added Flutter `LabelPreview` widget for in-app label rendering before printing.
- Added `example/flutter_preview.dart` for a ready-to-run Flutter preview screen.
- Updated package metadata and README content to document Flutter preview support.

## 0.1.2

- Added `LabelPreview` Flutter widget for in-app label preview before printing.
- Added runnable package example under `example/main.dart`.
- Added Flutter UI example under `example/flutter_preview.dart`.
- Declared support for all pub.dev platforms in package metadata.
- Improved README with example run instructions and updated installation version.

## 0.1.1

- Migrated package tooling to pure Dart (`dart test`, `dart analyze`) and removed Flutter SDK dependency requirements.
- Updated README examples to use public package imports (`package:portakal_flutter/portakal_flutter.dart`).
- Expanded and clarified the Label Elements capability matrix across all supported printer languages.
- Added and corrected release metadata/doc alignment for publish readiness.

## 0.1.0

- Initial public release of `portakal_flutter`.
- Added multi-language printer support for TSC, ZPL, EPL, ESC/POS, CPCL, DPL, IPL, SBPL, and Star PRNT.
- Added label builder, markup parser, cross-language conversion, validators, parsers, SVG preview, and printer profile utilities.
- Added image-to-monochrome utilities with multiple dithering algorithms.
- Added test coverage for language modules, parsers, builders, image processing, and utilities.
