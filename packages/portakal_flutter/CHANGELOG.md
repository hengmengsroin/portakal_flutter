## 1.0.0-rc.1

### Added
- Re-exported complete `portakal_core` pure-Dart engine with `ReceiptColumn` collision shielding (`hide Column`).
- Visual `LabelPreview` Flutter widget supporting real-time interactive label layout previews.
- Comprehensive Flutter integration tests and documentation examples.

### Changed
- Standardized `portakal_flutter` as a clean Flutter companion package dependent on hosted `portakal_core`.
- Updated SDK constraints to Dart `^3.6.0` and Flutter `>=3.27.0`.

### Hardware Validation
- Integrated interactive hardware test bench app supporting capability probe execution, manual override verification, and session evidence JSON export.

## 0.3.0

- Split pure-Dart protocol engine into `portakal_core`.
- `portakal_flutter` is now a clean Flutter integration package providing `LabelPreview` widget rendering while re-exporting `portakal_core`.
- 100% backward compatible for existing Flutter applications importing `package:portakal_flutter/portakal_flutter.dart`.
