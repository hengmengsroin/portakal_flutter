import 'types.dart';
import 'parsers/tsc.dart';
import 'parsers/zpl.dart';
import 'parsers/epl.dart';
import 'parsers/cpcl.dart';
import 'parsers/dpl.dart';
import 'parsers/sbpl.dart';
import 'parsers/ipl.dart';
import 'languages/tsc.dart';
import 'languages/zpl.dart';
import 'languages/epl.dart';
import 'languages/escpos.dart';
import 'languages/cpcl.dart';
import 'languages/dpl.dart';
import 'languages/sbpl.dart';
import 'languages/starprnt.dart';
import 'languages/ipl.dart';

/// Conversion result.
class ConvertResult {
  final Object output; // String or Uint8List
  final List<LabelElement> elements;
  final int widthDots;
  final int heightDots;
  final List<String> warnings;

  const ConvertResult({
    required this.output,
    required this.elements,
    required this.widthDots,
    required this.heightDots,
    this.warnings = const [],
  });
}

/// Parse source code into elements.
({
  List<LabelElement> elements,
  int widthDots,
  int heightDots,
  List<String> warnings,
}) _parseSource(String code, String from) {
  switch (from) {
    case 'tsc':
      final r = parseTSC(code);
      return (
        elements: r.elements,
        widthDots: r.widthDots,
        heightDots: r.heightDots,
        warnings: <String>[],
      );
    case 'zpl':
      final r = parseZPL(code);
      return (
        elements: r.elements,
        widthDots: r.widthDots,
        heightDots: r.heightDots,
        warnings: r.warnings,
      );
    case 'epl':
      final r = parseEPL(code);
      return (
        elements: r.elements,
        widthDots: r.widthDots,
        heightDots: r.heightDots > 0 ? r.heightDots : 240,
        warnings: <String>[],
      );
    case 'cpcl':
      final r = parseCPCL(code);
      return (
        elements: r.elements,
        widthDots: r.widthDots,
        heightDots: r.heightDots,
        warnings: <String>[],
      );
    case 'dpl':
      final r = parseDPL(code);
      return (
        elements: r.elements,
        widthDots: r.widthDots,
        heightDots: 240,
        warnings: <String>[],
      );
    case 'sbpl':
      final r = parseSBPL(code);
      return (
        elements: r.elements,
        widthDots: 320,
        heightDots: 240,
        warnings: <String>[],
      );
    case 'ipl':
      final r = parseIPL(code);
      return (
        elements: r.elements,
        widthDots: r.widthDots,
        heightDots: r.heightDots,
        warnings: <String>[],
      );
    default:
      throw ArgumentError('Unsupported source language: $from');
  }
}

/// Compile elements to target language.
Object _compileTarget(
  ResolvedLabel resolved,
  String to, {
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.ignore,
}) {
  switch (to) {
    case 'tsc':
      return compileToTSC(resolved, policy: policy);
    case 'zpl':
      return compileToZPL(resolved, policy: policy);
    case 'epl':
      return compileToEPL(resolved, policy: policy);
    case 'escpos':
      return compileToESCPOS(resolved, policy: policy);
    case 'cpcl':
      return compileToCPCL(resolved, policy: policy);
    case 'dpl':
      return compileToDPL(resolved, policy: policy);
    case 'sbpl':
      return compileToSBPL(resolved, policy: policy);
    case 'starprnt':
      return compileToStarPRNT(resolved, policy: policy);
    case 'ipl':
      return compileToIPL(resolved, policy: policy);
    default:
      throw ArgumentError('Unsupported target language: $to');
  }
}

/// Convert printer commands from one language to another.
ConvertResult convert(
  String code,
  String from,
  String to, {
  int? dpi,
  int? speed,
  int? density,
  int? copies,
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.ignore,
}) {
  final parsed = _parseSource(code, from);

  final resolved = ResolvedLabel(
    widthDots: parsed.widthDots,
    heightDots: parsed.heightDots,
    dpi: dpi ?? 203,
    gapOffset: 0,
    gap: 3,
    speed: speed ?? 4,
    density: density ?? 8,
    direction: 0,
    copies: copies ?? 1,
    unit: Unit.dot,
    elements: parsed.elements,
  );

  final output = _compileTarget(resolved, to, policy: policy);

  return ConvertResult(
    output: output,
    elements: parsed.elements,
    widthDots: parsed.widthDots,
    heightDots: parsed.heightDots,
    warnings: parsed.warnings,
  );
}
