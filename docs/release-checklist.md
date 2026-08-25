# Portakal 1.0 Release Checklist

This checklist defines the required release engineering steps for publishing Portakal 1.0.0 (`portakal_core` and `portakal_flutter`) to pub.dev.

---

## Pre-Release Verification Gate

- [ ] **1. API Surface Stability**
  - Verify `tool/api_surface.txt` matches the frozen 1.0 contract (`git diff tool/api_surface.txt` must be empty).
- [ ] **2. Code Formatting**
  - Run `dart format --output=none --set-exit-if-changed .` across workspace (0 formatted files).
- [ ] **3. Static Analysis**
  - Run `dart analyze --fatal-infos packages/portakal_core` (0 issues).
  - Run `flutter analyze --fatal-infos packages/portakal_flutter` (0 issues).
  - Run `flutter analyze --fatal-infos example` (0 issues).
- [ ] **4. Test Suite Execution**
  - Run `dart test packages/portakal_core` (all 817 tests pass).
  - Run `flutter test packages/portakal_flutter` (all 6 tests pass).
  - Run `flutter test example` (all 16 tests pass).
  - Total: 839 passing tests.
- [ ] **5. Documentation Validation**
  - Run `dart doc --dry-run packages/portakal_core` (0 errors, 0 warnings).
  - Run `dart doc --dry-run packages/portakal_flutter` (0 errors, 0 warnings).
- [ ] **6. Markdown Link Integrity**
  - Run Markdown link audit script (0 broken links across all markdown guides).

---

## Release Staging & Publishing Sequence

### Step 1: Version Bumps & Metadata Configuration
- [ ] In `packages/portakal_core/pubspec.yaml`:
  - Set `version: 1.0.0`
  - Ensure `topics: [printers, thermal-printer, esc-pos, zpl, tspl]`
- [ ] In `packages/portakal_core/CHANGELOG.md`:
  - Confirm `## 1.0.0` release notes are finalized.
- [ ] In `packages/portakal_flutter/pubspec.yaml`:
  - Set `version: 1.0.0`
  - Update `portakal_core` dependency from path to `portakal_core: ^1.0.0`
  - Ensure `topics: [printers, thermal-printer, flutter-widgets, label-preview, escpos]`
- [ ] In `packages/portakal_flutter/CHANGELOG.md`:
  - Confirm `## 1.0.0` release notes are finalized.

### Step 2: Publish `portakal_core`
- [ ] Run dry-run:
  ```bash
  cd packages/portakal_core
  dart pub publish --dry-run
  ```
- [ ] Execute publication:
  ```bash
  dart pub publish
  ```
- [ ] Verify package presence on [pub.dev/packages/portakal_core](https://pub.dev/packages/portakal_core).

### Step 3: Publish `portakal_flutter`
- [ ] Run dry-run:
  ```bash
  cd packages/portakal_flutter
  flutter pub publish --dry-run
  ```
- [ ] Execute publication:
  ```bash
  flutter pub publish
  ```
- [ ] Verify package presence on [pub.dev/packages/portakal_flutter](https://pub.dev/packages/portakal_flutter).

---

## Post-Release Smoke Test

- [ ] **Pure Dart Standalone Smoke Test**:
  ```bash
  mkdir -p /tmp/smoke_dart && cd /tmp/smoke_dart
  dart create -t console-simple .
  dart pub add portakal_core
  # Create sample compiling EscPosPrinter and TscPrinter
  dart run bin/smoke_dart.dart
  ```
- [ ] **Flutter Standalone Smoke Test**:
  ```bash
  mkdir -p /tmp/smoke_flutter && cd /tmp/smoke_flutter
  flutter create -t app .
  flutter pub add portakal_flutter
  # Add LabelPreview widget into main.dart
  flutter build bundle
  ```
- [ ] **Git Tagging & Monorepo Synchronization**:
  ```bash
  git tag -a v1.0.0 -m "Release Portakal 1.0.0"
  git push origin v1.0.0
  ```
