import 'types.dart';

/// Convert a value in the given unit to dots at the specified DPI.
///
/// - mm → dots: `(value / 25.4) * dpi`, rounded
/// - inch → dots: `value * dpi`, rounded
/// - dot → dots: `value`, rounded (passthrough)
int toDots(double value, Unit unit, int dpi) {
  switch (unit) {
    case Unit.mm:
      return (value / 25.4 * dpi).round();
    case Unit.inch:
      return (value * dpi).round();
    case Unit.dot:
      return value.round();
  }
}
