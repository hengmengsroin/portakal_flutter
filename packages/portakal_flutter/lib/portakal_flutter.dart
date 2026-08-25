/// Portakal Flutter — Flutter integration package for Portakal printer SDK.
///
/// Previews labels via Flutter widgets, CustomPainters, and provides
/// full re-exports of the pure-Dart [portakal_core] engine.
library;

// Re-export complete pure Dart engine
export 'package:portakal_core/portakal_core.dart' hide Column;

// Flutter-specific widgets
export 'src/widgets/label_preview.dart';
