import 'dart:convert';

import 'package:test/test.dart';
import 'package:portakal_core/src/builder.dart';
import 'package:portakal_core/src/errors.dart';
import 'package:portakal_core/src/lang/cpcl.dart';
import 'package:portakal_core/src/lang/dpl.dart';
import 'package:portakal_core/src/lang/epl.dart';
import 'package:portakal_core/src/lang/escpos.dart';
import 'package:portakal_core/src/lang/ipl.dart';
import 'package:portakal_core/src/lang/sbpl.dart';
import 'package:portakal_core/src/lang/starprnt.dart';
import 'package:portakal_core/src/lang/tsc.dart';
import 'package:portakal_core/src/lang/zpl.dart';
import 'package:portakal_core/src/preview.dart';
import 'package:portakal_core/src/types.dart';

void main() {
  String tscCompile(LabelBuilder b) => utf8.decode(tsc.compile(b));

  group('Ellipse element', () {
    test('generates TSC ELLIPSE', () {
      final output = tscCompile(
        label(LabelConfig(width: 40, height: 30)).ellipse(
          EllipseOptions(x: 50, y: 50, width: 100, height: 60, thickness: 2),
        ),
      );
      expect(output, contains('ELLIPSE 50,50,100,60,2'));
    });

    test('renders in preview as SVG ellipse', () {
      final svg = renderPreview(
        label(LabelConfig(width: 40, height: 30))
            .ellipse(
              EllipseOptions(
                x: 50,
                y: 50,
                width: 100,
                height: 60,
                thickness: 2,
              ),
            )
            .resolve(),
      );
      expect(svg, contains('<ellipse'));
      expect(svg, contains('rx="50"'));
      expect(svg, contains('ry="30"'));
    });
  });

  group('Reverse element', () {
    test('generates TSC REVERSE', () {
      final output = tscCompile(
        label(
          LabelConfig(width: 40, height: 30),
        ).reverse(ReverseOptions(x: 10, y: 10, width: 200, height: 30)),
      );
      expect(output, contains('REVERSE 10,10,200,30'));
    });

    test('renders in preview as black rect', () {
      final svg = renderPreview(
        label(LabelConfig(width: 40, height: 30))
            .reverse(ReverseOptions(x: 10, y: 10, width: 200, height: 30))
            .resolve(),
      );
      expect(svg, contains('fill="#000"'));
      expect(svg, contains('width="200"'));
    });
  });

  group('Erase element', () {
    test('generates TSC ERASE', () {
      final output = tscCompile(
        label(
          LabelConfig(width: 40, height: 30),
        ).erase(EraseOptions(x: 10, y: 10, width: 50, height: 50)),
      );
      expect(output, contains('ERASE 10,10,50,50'));
    });

    test('renders in preview as white rect', () {
      final svg = renderPreview(
        label(
          LabelConfig(width: 40, height: 30),
        ).erase(EraseOptions(x: 10, y: 10, width: 50, height: 50)).resolve(),
      );
      expect(svg, contains('fill="#fff"'));
    });
  });

  group('Barcode element', () {
    test('generates TSC BARCODE', () {
      final output = tscCompile(
        label(LabelConfig(width: 40, height: 30)).barcode(
          '12345',
          BarcodeOptions(x: 10, y: 10, type: '128', height: 40),
        ),
      );
      expect(output, contains('BARCODE 10,10,"128",40,0,0,2,4,"12345"'));
    });
  });

  group('QRCode element', () {
    test('generates TSC QRCODE', () {
      final output = tscCompile(
        label(
          LabelConfig(width: 40, height: 30),
        ).qrcode('https://test.com', QRCodeOptions(x: 10, y: 10, cellWidth: 4)),
      );
      expect(output, contains('QRCODE 10,10,"H",4,"A",0,"https://test.com"'));
    });
  });

  group('All compilers handle new elements with policy', () {
    LabelBuilder b() => label(LabelConfig(width: 40, height: 30))
        .ellipse(EllipseOptions(x: 50, y: 50, width: 100, height: 60))
        .reverse(ReverseOptions(x: 10, y: 10, width: 200, height: 30))
        .erase(EraseOptions(x: 10, y: 10, width: 50, height: 50))
        .barcode('12345', BarcodeOptions(x: 10, y: 10, type: '128', height: 40))
        .qrcode('https://test.com', QRCodeOptions(x: 10, y: 10, cellWidth: 4));

    test('TSC', () {
      expect(tscCompile(b()), contains('ELLIPSE'));
    });
    test('ZPL', () {
      expect(() => zpl.compile(b()), returnsNormally);
    });
    test('EPL', () {
      expect(() => epl.compile(b()), returnsNormally);
    });
    test('CPCL', () {
      expect(() => cpcl.compile(b()), returnsNormally);
    });
    test('DPL - throws by default and succeeds with ignore policy', () {
      expect(() => dpl.compile(b()), throwsA(isA<UnsupportedFeatureError>()));
      expect(
        () => dpl.compile(b(), policy: UnsupportedFeaturePolicy.ignore),
        returnsNormally,
      );
    });
    test('SBPL - throws by default and succeeds with ignore policy', () {
      expect(() => sbpl.compile(b()), throwsA(isA<UnsupportedFeatureError>()));
      expect(
        () => sbpl.compile(b(), policy: UnsupportedFeaturePolicy.ignore),
        returnsNormally,
      );
    });
    test('IPL - throws by default and succeeds with ignore policy', () {
      expect(() => ipl.compile(b()), throwsA(isA<UnsupportedFeatureError>()));
      expect(
        () => ipl.compile(b(), policy: UnsupportedFeaturePolicy.ignore),
        returnsNormally,
      );
    });
    test('ESC/POS - throws by default and succeeds with ignore policy', () {
      expect(
        () => escpos.compile(b()),
        throwsA(isA<UnsupportedFeatureError>()),
      );
      expect(
        () => escpos.compile(b(), policy: UnsupportedFeaturePolicy.ignore),
        returnsNormally,
      );
    });
    test('Star PRNT - throws by default and succeeds with ignore policy', () {
      expect(
        () => starprnt.compile(b()),
        throwsA(isA<UnsupportedFeatureError>()),
      );
      expect(
        () => starprnt.compile(b(), policy: UnsupportedFeaturePolicy.ignore),
        returnsNormally,
      );
    });
    test('Preview', () {
      expect(renderPreview(b().resolve()), contains('<ellipse'));
    });
  });
}
