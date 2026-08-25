import 'dart:typed_data';
import 'package:portakal_flutter/portakal_flutter.dart';

/// Categories for organizing use-case examples in the gallery.
enum ExampleCategory {
  gettingStarted('Getting Started'),
  retail('Retail'),
  pharmacy('Pharmacy'),
  restaurant('Restaurant'),
  warehouse('Warehouse'),
  logistics('Logistics'),
  ticketsAndBadges('Tickets & Badges'),
  assetManagement('Asset Management'),
  advanced('General / Advanced');

  final String label;
  const ExampleCategory(this.label);
}

/// Printer protocols available for compilation in the example application.
enum ExampleProtocol {
  tsc('TSC (TSPL2)', 'tsc'),
  escpos('ESC/POS', 'escpos'),
  zpl('ZPL II', 'zpl'),
  epl('EPL2', 'epl'),
  cpcl('CPCL', 'cpcl'),
  dpl('DPL', 'dpl'),
  ipl('IPL', 'ipl'),
  sbpl('SBPL', 'sbpl'),
  starprnt('Star PRNT', 'starprnt');

  final String displayName;
  final String id;
  const ExampleProtocol(this.displayName, this.id);
}

/// Lightweight immutable descriptor for an executable Portakal use case.
final class ExampleCase {
  /// Unique case identifier (e.g. 'retail_price_label').
  final String id;

  /// Human-readable title displayed in the gallery.
  final String title;

  /// Concise description of the real-world scenario and design choices.
  final String description;

  /// Gallery category for grouping and filtering.
  final ExampleCategory category;

  /// Human-readable recommended media size (e.g. '40mm × 30mm', '80mm Continuous').
  final String recommendedMedia;

  /// Canonical relative file path to the Dart source file.
  final String sourcePath;

  /// Set of protocols explicitly tested and verified to compile with [UnsupportedFeaturePolicy.throwError].
  final Set<ExampleProtocol> testedProtocols;

  /// Factory function producing a configured [LabelBuilder].
  final LabelBuilder Function() buildLabel;

  /// Optional short code snippet demonstrating usage.
  final String? quickSnippet;

  const ExampleCase({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.recommendedMedia,
    required this.sourcePath,
    required this.testedProtocols,
    required this.buildLabel,
    this.quickSnippet,
  });
}

/// Compiles a [ResolvedLabel] into raw printer bytes for the given [protocol].
///
/// Uses [UnsupportedFeaturePolicy.throwError] to ensure unsupported commands
/// are honestly reported to developers.
Uint8List compileExample(
  ExampleProtocol protocol,
  ResolvedLabel job, {
  UnsupportedFeaturePolicy policy = UnsupportedFeaturePolicy.throwError,
}) {
  return switch (protocol) {
    ExampleProtocol.tsc => tsc.compileResolved(job, policy: policy),
    ExampleProtocol.escpos => escpos.compileResolved(job, policy: policy),
    ExampleProtocol.zpl => zpl.compileResolved(job, policy: policy),
    ExampleProtocol.epl => epl.compileResolved(job, policy: policy),
    ExampleProtocol.cpcl => cpcl.compileResolved(job, policy: policy),
    ExampleProtocol.dpl => dpl.compileResolved(job, policy: policy),
    ExampleProtocol.ipl => ipl.compileResolved(job, policy: policy),
    ExampleProtocol.sbpl => sbpl.compileResolved(job, policy: policy),
    ExampleProtocol.starprnt => starprnt.compileResolved(job, policy: policy),
  };
}
