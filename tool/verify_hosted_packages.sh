#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# verify_hosted_packages.sh
#
# Standalone manual / release verification script that validates Portakal's
# published packages from pub.dev in clean, isolated temporary environments.
#
# This script is decoupled from offline PR CI workflows to ensure PR CI does
# not depend on pub.dev network availability.
# -----------------------------------------------------------------------------

TARGET_VERSION="1.1.0"
WORK_DIR=$(mktemp -d /tmp/portakal_hosted_smoke.XXXXXX)

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "========================================================"
echo "Portakal Hosted Package Verification (Target: ${TARGET_VERSION})"
echo "Working directory: ${WORK_DIR}"
echo "========================================================"

# 1. Pure Dart Smoke Test
echo ""
echo "[1/2] Testing pure-Dart package: portakal_core:${TARGET_VERSION}..."
mkdir -p "${WORK_DIR}/dart_smoke"
cd "${WORK_DIR}/dart_smoke"

dart create -t console-simple . --force > /dev/null
dart pub add "portakal_core:${TARGET_VERSION}"

cat << 'EOF' > bin/smoke_test.dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

void main() {
  final builder = label(const LabelConfig(width: 80, height: 50))
    ..text('HOSTED DART SMOKE', const TextOptions(x: 20, y: 20, size: 2, bold: true))
    ..barcode('SMOKE-1001', const BarcodeOptions(x: 20, y: 70, type: '128', height: 60))
    ..qrcode('https://pub.dev/packages/portakal_core', const QRCodeOptions(x: 20, y: 150, cellWidth: 4));

  final ResolvedLabel job = builder.resolve();
  final String svg = renderPreview(job);
  assert(svg.contains('<svg'), 'SVG preview rendered');

  final Uint8List tscBytes = tsc.compileResolved(job);
  final Uint8List zplBytes = zpl.compileResolved(job);
  final Uint8List eplBytes = epl.compileResolved(job);

  assert(tscBytes.isNotEmpty && zplBytes.isNotEmpty && eplBytes.isNotEmpty);
  print('portakal_core hosted smoke: PASS');
}
EOF

dart run bin/smoke_test.dart

# 2. Flutter Smoke Test
echo ""
echo "[2/2] Testing Flutter integration package: portakal_flutter:${TARGET_VERSION}..."
mkdir -p "${WORK_DIR}/flutter_smoke"
cd "${WORK_DIR}/flutter_smoke"

flutter create --platforms=macos -t app . > /dev/null
flutter pub add "portakal_flutter:${TARGET_VERSION}"

cat << 'EOF' > test/smoke_widget_test.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

void main() {
  testWidgets('Hosted portakal_flutter smoke verification', (WidgetTester tester) async {
    final builder = label(const LabelConfig(width: 80, height: 50))
      ..text('HOSTED FLUTTER SMOKE', const TextOptions(x: 20, y: 20, size: 2, bold: true))
      ..barcode('FLUTTER-99', const BarcodeOptions(x: 20, y: 70, type: '128', height: 60))
      ..qrcode('https://pub.dev/packages/portakal_flutter', const QRCodeOptions(x: 20, y: 150, cellWidth: 4))
      ..box(const BoxOptions(x: 10, y: 10, width: 620, height: 380, thickness: 2));

    final ResolvedLabel job = builder.resolve();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 200,
              child: LabelPreview.resolved(job: job, showMeta: true),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(LabelPreview), findsOneWidget);

    final Uint8List tscBytes = tsc.compileResolved(job);
    expect(tscBytes, isNotEmpty);
  });
}
EOF

flutter test test/smoke_widget_test.dart

echo ""
echo "========================================================"
echo "All hosted package verification checks PASSED successfully!"
echo "========================================================"
