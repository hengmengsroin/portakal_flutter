import 'dart:convert';
import 'package:portakal_core/portakal_core.dart';
import 'package:test/test.dart';

ResolvedLabel makeLabel(
  List<LabelElement> elements, {
  int widthDots = 800,
  int heightDots = 1200,
  int copies = 1,
}) {
  return ResolvedLabel(
    widthDots: widthDots,
    heightDots: heightDots,
    dpi: 203,
    unit: Unit.mm,
    speed: 4,
    density: 8,
    direction: 0,
    copies: copies,
    gap: 3,
    gapOffset: 0,
    elements: elements,
  );
}

void main() {
  group('Universal RowElement & DividerElement Page Compiler Lowering', () {
    // Shared test models
    final twoCellRow = RowElement(
      y: 100,
      startX: 20,
      width: 560,
      size: 1,
      cells: [
        RowCellElement(
          text: 'Coffee',
          x: 20,
          width: 400,
        ),
        RowCellElement(
          text: r'$5.00',
          x: 420,
          width: 160,
          align: LabelTextAlign.right,
          style: LabelTextStyle(bold: true),
        ),
      ],
    );

    final threeCellRow = RowElement(
      y: 120,
      startX: 10,
      width: 600,
      size: 1,
      cells: [
        RowCellElement(text: 'Widget A', x: 10, width: 300),
        RowCellElement(text: 'x2', x: 310, width: 100, align: LabelTextAlign.center),
        RowCellElement(text: r'$20.00', x: 410, width: 200, align: LabelTextAlign.right),
      ],
    );

    final emptyMiddleCellRow = RowElement(
      y: 150,
      startX: 20,
      width: 560,
      size: 1,
      cells: [
        RowCellElement(text: '', x: 20, width: 200),
        RowCellElement(text: 'TOTAL', x: 220, width: 180),
        RowCellElement(text: r'$25.00', x: 400, width: 180, align: LabelTextAlign.right),
      ],
    );

    final scaledRow = RowElement(
      y: 200,
      startX: 10,
      width: 500,
      size: 2,
      cells: [
        RowCellElement(text: 'BIG LEFT', x: 10, width: 250),
        RowCellElement(text: 'BIG RIGHT', x: 260, width: 250),
      ],
    );

    final divider = DividerElement(
      y: 80,
      thickness: 2,
      startX: 15,
      width: 570,
    );

    // ==========================================
    // TSC / TSPL2
    // ==========================================
    group('TSC Compiler Lowering', () {
      test('lowers 2-cell RowElement to positioned TEXT commands', () {
        final label = makeLabel([twoCellRow]);
        final bytes = compileToTSCBytes(label);
        final tscStr = latin1.decode(bytes);

        expect(tscStr, contains('TEXT 20,100,"2",0,1,1,"Coffee"'));
        expect(tscStr, contains('TEXT 420,100,"2",0,1,1,"\$5.00"'));
        expect(tscStr, contains('PRINT 1'));
      });

      test('lowers 3-cell RowElement in declaration order', () {
        final label = makeLabel([threeCellRow]);
        final tscStr = latin1.decode(compileToTSCBytes(label));
        final idx1 = tscStr.indexOf('Widget A');
        final idx2 = tscStr.indexOf('x2');
        final idx3 = tscStr.indexOf(r'$20.00');

        expect(idx1, isNot(-1));
        expect(idx2, isNot(-1));
        expect(idx3, isNot(-1));
        expect(idx1 < idx2 && idx2 < idx3, isTrue);
      });

      test('skips empty cells while preserving subsequent cell coordinates', () {
        final label = makeLabel([emptyMiddleCellRow]);
        final tscStr = latin1.decode(compileToTSCBytes(label));

        expect(tscStr, isNot(contains('TEXT 20,150')));
        expect(tscStr, contains('TEXT 220,150,"2",0,1,1,"TOTAL"'));
        expect(tscStr, contains('TEXT 400,150,"2",0,1,1,"\$25.00"'));
      });

      test('applies row.size uniformly to all cells', () {
        final label = makeLabel([scaledRow]);
        final tscStr = latin1.decode(compileToTSCBytes(label));

        expect(tscStr, contains('TEXT 10,200,"2",0,2,2,"BIG LEFT"'));
        expect(tscStr, contains('TEXT 260,200,"2",0,2,2,"BIG RIGHT"'));
      });

      test('lowers DividerElement to BAR command', () {
        final label = makeLabel([divider]);
        final tscStr = latin1.decode(compileToTSCBytes(label));

        expect(tscStr, contains('BAR 15,80,570,2'));
      });
    });

    // ==========================================
    // ZPL II
    // ==========================================
    group('ZPL II Compiler Lowering', () {
      test('lowers 2-cell RowElement with ^FB alignment', () {
        final label = makeLabel([twoCellRow]);
        final bytes = compileToZPLBytes(label);
        final zplStr = utf8.decode(bytes);

        // Left cell: ^FO20,100 ... ^FB400,1,0,L,0 ... ^FDCoffee^FS
        expect(zplStr, contains('^FO20,100^A0N,30,30^FB400,1,0,L,0^FDCoffee^FS'));
        // Right cell: ^FO420,100 ... ^FB160,1,0,R,0 ... ^FD$5.00^FS
        expect(zplStr, contains('^FO420,100^A0N,30,30^FB160,1,0,R,0^FD\$5.00^FS'));
      });

      test('lowers 3-cell RowElement with Center and Right ^FB alignment', () {
        final label = makeLabel([threeCellRow]);
        final zplStr = utf8.decode(compileToZPLBytes(label));

        expect(zplStr, contains('^FO10,120^A0N,30,30^FB300,1,0,L,0^FDWidget A^FS'));
        expect(zplStr, contains('^FO310,120^A0N,30,30^FB100,1,0,C,0^FDx2^FS'));
        expect(zplStr, contains('^FO410,120^A0N,30,30^FB200,1,0,R,0^FD\$20.00^FS'));
      });

      test('skips empty cells while preserving subsequent cell coordinates', () {
        final label = makeLabel([emptyMiddleCellRow]);
        final zplStr = utf8.decode(compileToZPLBytes(label));

        expect(zplStr, isNot(contains('^FO20,150')));
        expect(zplStr, contains('^FO220,150^A0N,30,30^FB180,1,0,L,0^FDTOTAL^FS'));
        expect(zplStr, contains('^FO400,150^A0N,30,30^FB180,1,0,R,0^FD\$25.00^FS'));
      });

      test('applies row.size uniformly to font height and width', () {
        final label = makeLabel([scaledRow]);
        final zplStr = utf8.decode(compileToZPLBytes(label));

        expect(zplStr, contains('^FO10,200^A0N,60,60^FB250,1,0,L,0^FDBIG LEFT^FS'));
        expect(zplStr, contains('^FO260,200^A0N,60,60^FB250,1,0,L,0^FDBIG RIGHT^FS'));
      });

      test('lowers DividerElement to ^GB graphic box', () {
        final label = makeLabel([divider]);
        final zplStr = utf8.decode(compileToZPLBytes(label));

        expect(zplStr, contains('^FO15,80^GB570,2,2,B,0^FS'));
      });
    });

    // ==========================================
    // EPL2
    // ==========================================
    group('EPL2 Compiler Lowering', () {
      test('lowers 2-cell RowElement to A commands', () {
        final label = makeLabel([twoCellRow]);
        final eplStr = latin1.decode(compileToEPLBytes(label));

        expect(eplStr, contains('A20,100,0,2,1,1,N,"Coffee"\n'));
        expect(eplStr, contains('A420,100,0,2,1,1,N,"\$5.00"\n'));
        expect(eplStr, contains('P1\n'));
      });

      test('skips empty cells in EPL', () {
        final label = makeLabel([emptyMiddleCellRow]);
        final eplStr = latin1.decode(compileToEPLBytes(label));

        expect(eplStr, isNot(contains('A20,150')));
        expect(eplStr, contains('A220,150,0,2,1,1,N,"TOTAL"'));
        expect(eplStr, contains('A400,150,0,2,1,1,N,"\$25.00"'));
      });

      test('lowers DividerElement to LO line command', () {
        final label = makeLabel([divider]);
        final eplStr = latin1.decode(compileToEPLBytes(label));

        expect(eplStr, contains('LO15,80,570,2'));
      });
    });

    // ==========================================
    // CPCL
    // ==========================================
    group('CPCL Compiler Lowering', () {
      test('lowers 2-cell RowElement to TEXT commands', () {
        final label = makeLabel([twoCellRow]);
        final cpclStr = latin1.decode(compileToCPCLBytes(label));

        expect(cpclStr, contains('TEXT 2 1 20 100\r\nCoffee\r\n'));
        expect(cpclStr, contains('TEXT 2 1 420 100\r\n\$5.00\r\n'));
        expect(cpclStr, contains('PRINT\r\n'));
      });

      test('lowers DividerElement to LINE command', () {
        final label = makeLabel([divider]);
        final cpclStr = latin1.decode(compileToCPCLBytes(label));

        expect(cpclStr, contains('LINE 15 80 585 80 2\r\n'));
      });
    });

    // ==========================================
    // DPL
    // ==========================================
    group('DPL Compiler Lowering', () {
      test('lowers 2-cell RowElement to 101 text records', () {
        final label = makeLabel([twoCellRow]);
        final dplStr = latin1.decode(compileToDPLBytes(label));

        expect(dplStr, contains('10100002000101Coffee\n'));
        expect(dplStr, contains('10100042000101\$5.00\n'));
      });

      test('lowers DividerElement to 1X line record', () {
        final label = makeLabel([divider]);
        final dplStr = latin1.decode(compileToDPLBytes(label));

        expect(dplStr, contains('1X00800015L05702\n'));
      });
    });

    // ==========================================
    // IPL
    // ==========================================
    group('IPL Compiler Lowering', () {
      test('lowers 2-cell RowElement to sequential IPL field numbers', () {
        final label = makeLabel([twoCellRow]);
        final iplStr = latin1.decode(compileToIPLBytes(label));

        expect(iplStr, contains('H1;o20,100;f0;h12;w12;c26;d3,Coffee\x03'));
        expect(iplStr, contains('H2;o420,100;f0;h12;w12;c26;d3,\$5.00\x03'));
      });

      test('lowers DividerElement to IPL line field', () {
        final label = makeLabel([divider]);
        final iplStr = latin1.decode(compileToIPLBytes(label));

        expect(iplStr, contains('L1;o15,80;f0;l570;w2\x03'));
      });
    });

    // ==========================================
    // SBPL
    // ==========================================
    group('SBPL Compiler Lowering', () {
      test('lowers 2-cell RowElement to ESC V/H and font commands', () {
        final label = makeLabel([twoCellRow]);
        final sbplStr = latin1.decode(compileToSBPLBytes(label));

        expect(sbplStr, contains('\x1BH0020\x1BV0100\x1BL0101\x1BK9BCoffee'));
        expect(sbplStr, contains('\x1BH0420\x1BV0100\x1BL0101\x1BK9B\$5.00'));
        expect(sbplStr, contains('\x1BZ'));
      });

      test('lowers DividerElement to FW line command', () {
        final label = makeLabel([divider]);
        final sbplStr = latin1.decode(compileToSBPLBytes(label));

        expect(sbplStr, contains('\x1BH0015\x1BV0080\x1BFW02H0570'));
      });
    });

    // ==========================================
    // ESC/POS & Star PRNT Guard Stubs
    // ==========================================
    group('Stream Protocol Stubs (Explicit UnsupportedFeatureError)', () {
      test('ESC/POS throws UnsupportedFeatureError on RowElement', () {
        final label = makeLabel([twoCellRow], widthDots: 576, heightDots: 800);
        expect(
          () => compileToESCPOS(label),
          throwsA(isA<UnsupportedFeatureError>()),
        );
      });

      test('ESC/POS throws UnsupportedFeatureError on DividerElement', () {
        final label = makeLabel([divider], widthDots: 576, heightDots: 800);
        expect(
          () => compileToESCPOS(label),
          throwsA(isA<UnsupportedFeatureError>()),
        );
      });

      test('Star PRNT throws UnsupportedFeatureError on RowElement', () {
        final label = makeLabel([twoCellRow], widthDots: 576, heightDots: 800);
        expect(
          () => compileToStarPRNT(label),
          throwsA(isA<UnsupportedFeatureError>()),
        );
      });

      test('Star PRNT throws UnsupportedFeatureError on DividerElement', () {
        final label = makeLabel([divider], widthDots: 576, heightDots: 800);
        expect(
          () => compileToStarPRNT(label),
          throwsA(isA<UnsupportedFeatureError>()),
        );
      });
    });
  });
}
