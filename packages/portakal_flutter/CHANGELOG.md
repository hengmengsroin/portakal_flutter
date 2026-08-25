## 1.0.0

- Frozen Portakal 1.0 Flutter integration package.
- Re-exported `portakal_core` with `hide Column;` to prevent symbol collision with Flutter's `Column` widget.
- Verified `LabelPreview` widget rendering with 1.0 AST and byte compilation.
- Added comprehensive documentation and Flutter integration examples.

## 0.3.0

- Split pure-Dart protocol engine into `portakal_core`.
- `portakal_flutter` is now a clean Flutter integration package providing `LabelPreview` widget rendering while re-exporting `portakal_core`.
- 100% backward compatible for existing Flutter applications importing `package:portakal_flutter/portakal_flutter.dart`.
