## 1.2.0-rc.1

Companion Flutter package release for Portakal 1.2 Hybrid Layout.

### Added
- Re-exported core Hybrid Layout elements (`RowElement`, `DividerElement`, `LabelCell`, `LabelColumn`, `LabelTextAlign`, `LabelTextStyle`, `BarcodeSymbology`, `sequentialLabel`) from `portakal_core`.
- Updated `LabelPreview` with visual SVG and Canvas rendering for `RowElement` (fixed and flex columns) and `DividerElement` vector lines.
- Updated dependency constraint to `portakal_core: ^1.2.0-rc.1`.

## 1.1.0

### Added
- **Preview-Before-Print Workflow**: Added `LabelPreview.resolved(job: resolvedLabel)` constructor allowing applications to render the exact resolved job that is subsequently compiled via `compileResolved(job)`.
- **Direct Scene Rendering**: Added `LabelPreview.scene(scene: previewScene)` for direct presentation of canonical `PreviewScene` models.
- **Standards-Conforming Code Rendering**: Direct visual rendering of Code 128 (Set B), Code 39, EAN-13, EAN-8, UPC-A, and 2D QR Code matrices with quiet zones in Flutter Canvas.
- **Dual-Axis Aspect Ratio Containment**: Added `fit: BoxFit.contain` parameter and robust `LayoutBuilder` constraint fitting to prevent `RenderFlex` overflow across dialogs, cards, sheets, and bounded height containers.
- **Accessibility Semantics**: Wrapped preview canvas with `Semantics` announcing physical millimeters and dot dimensions to screen readers.
- **Performance Optimization**: Wrapped painter with `RepaintBoundary` and implemented structural value equality on `_LabelPreviewPainter.shouldRepaint` to skip redundant repaints.

### Changed
- Refactored `LabelPreview` to consume canonical `PreviewScene` representation from `portakal_core`.

## 1.0.0

Stable production release of the Portakal Flutter companion package.

### Added
- Re-exported complete `portakal_core` pure-Dart engine with `ReceiptColumn` collision shielding (`hide Column`).
- Visual `LabelPreview` Flutter widget supporting real-time interactive label layout previews.
- Comprehensive Flutter integration tests and documentation examples.

### Changed
- Standardized `portakal_flutter` as a clean Flutter companion package dependent on hosted `portakal_core`.
- Updated SDK constraints to Dart `^3.6.0` and Flutter `>=3.27.0`.

### Hardware Validation
- Integrated interactive hardware test bench app supporting capability probe execution, manual override verification, and session evidence JSON export.

## 1.0.0-rc.1

- Release candidate for 1.0.0 contract freeze and external pub.dev validation.

## 0.3.0

- Split pure-Dart protocol engine into `portakal_core`.
- `portakal_flutter` is now a clean Flutter integration package providing `LabelPreview` widget rendering while re-exporting `portakal_core`.
- 100% backward compatible for existing Flutter applications importing `package:portakal_flutter/portakal_flutter.dart`.
