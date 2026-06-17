import 'package:test/test.dart';
import 'package:portakal_flutter/src/builder.dart';
import 'package:portakal_flutter/src/lang/cpcl.dart';
import 'package:portakal_flutter/src/lang/dpl.dart';
import 'package:portakal_flutter/src/lang/epl.dart';
import 'package:portakal_flutter/src/lang/escpos.dart';
import 'package:portakal_flutter/src/lang/ipl.dart';
import 'package:portakal_flutter/src/lang/sbpl.dart';
import 'package:portakal_flutter/src/lang/starprnt.dart';
import 'package:portakal_flutter/src/lang/tsc.dart';
import 'package:portakal_flutter/src/lang/zpl.dart';
import 'package:portakal_flutter/src/preview.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('Ellipse element', () {
    test('generates TSC ELLIPSE', () {
      final output = tsc.compile(
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
      final output = tsc.compile(
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
      final output = tsc.compile(
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
      final output = tsc.compile(
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
      final output = tsc.compile(
        label(
          LabelConfig(width: 40, height: 30),
        ).qrcode('https://test.com', QRCodeOptions(x: 10, y: 10, cellWidth: 4)),
      );
      expect(output, contains('QRCODE 10,10,"H",4,"A",0,"https://test.com"'));
    });
  });

  group('All compilers handle new elements without error', () {
    LabelBuilder b() => label(LabelConfig(width: 40, height: 30))
        .ellipse(EllipseOptions(x: 50, y: 50, width: 100, height: 60))
        .reverse(ReverseOptions(x: 10, y: 10, width: 200, height: 30))
        .erase(EraseOptions(x: 10, y: 10, width: 50, height: 50))
        .barcode('12345', BarcodeOptions(x: 10, y: 10, type: '128', height: 40))
        .qrcode('https://test.com', QRCodeOptions(x: 10, y: 10, cellWidth: 4));

    test('TSC', () {
      expect(tsc.compile(b()), contains('ELLIPSE'));
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
    test('DPL', () {
      expect(() => dpl.compile(b()), returnsNormally);
    });
    test('SBPL', () {
      expect(() => sbpl.compile(b()), returnsNormally);
    });
    test('IPL', () {
      expect(() => ipl.compile(b()), returnsNormally);
    });
    test('ESC/POS', () {
      expect(() => escpos.compile(b()), returnsNormally);
    });
    test('Star PRNT', () {
      expect(() => starprnt.compile(b()), returnsNormally);
    });
    test('Preview', () {
      expect(renderPreview(b().resolve()), contains('<ellipse'));
    });
  });
}
