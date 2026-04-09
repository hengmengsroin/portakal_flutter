import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/src/parsers/dpl.dart';
import 'package:portakal_flutter/src/parsers/ipl.dart';
import 'package:portakal_flutter/src/parsers/sbpl.dart';
import 'package:portakal_flutter/src/parsers/starprnt.dart';
import 'package:portakal_flutter/src/parsers/escpos.dart';
import 'package:portakal_flutter/src/types.dart';

void main() {
  group('parseDPL', () {
    test('parses STX L (start label)', () {
      final result = parseDPL('\x02L\nD08\nS04\nA0320\nQ0001\nE\n');
      expect(result.commands.any((c) => c.type == 'STX_L'), isTrue);
    });

    test('parses density', () {
      final result = parseDPL('\x02L\nD08\nE\n');
      final cmd = result.commands.firstWhere((c) => c.type == 'DENSITY');
      expect(cmd.params, equals('08'));
    });

    test('parses speed', () {
      final result = parseDPL('\x02L\nS04\nE\n');
      final cmd = result.commands.firstWhere((c) => c.type == 'SPEED');
      expect(cmd.params, equals('04'));
    });

    test('parses width', () {
      final result = parseDPL('\x02L\nA0320\nE\n');
      expect(result.widthDots, equals(320));
    });

    test('parses quantity', () {
      final result = parseDPL('\x02L\nQ0003\nE\n');
      final cmd = result.commands.firstWhere((c) => c.type == 'QUANTITY');
      expect(cmd.params, equals('0003'));
    });

    test('parses end command', () {
      final result = parseDPL('\x02L\nE\n');
      expect(result.commands.any((c) => c.type == 'E'), isTrue);
    });
  });

  group('parseIPL', () {
    test('parses format creation', () {
      final result = parseIPL('\x02\x1bC1\x03\x02\x1bP\x03\x02\x1bE1\x03\x02R\x03');
      expect(result.commands.any((c) => c.type == 'CREATE_FORMAT'), isTrue);
      expect(result.commands.any((c) => c.type == 'PROGRAM_MODE'), isTrue);
      expect(result.commands.any((c) => c.type == 'END_FORMAT'), isTrue);
      expect(result.commands.any((c) => c.type == 'PRINT'), isTrue);
    });

    test('parses label dimensions', () {
      final result = parseIPL('\x02\x1bC1\x03\x02\x1bP\x03\x02<SI>L400\x03\x02<SI>W800\x03\x02\x1bE1\x03\x02R\x03');
      expect(result.heightDots, equals(400));
      expect(result.widthDots, equals(800));
    });

    test('parses text field', () {
      final result = parseIPL('\x02\x1bC1\x03\x02\x1bP\x03\x02H1;o50,100;f0;h12;w12;c26;d3,Hello\x03\x02\x1bE1\x03\x02R\x03');
      final texts = result.elements.whereType<TextElement>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].content, equals('Hello'));
      expect(texts[0].options.x, equals(50));
      expect(texts[0].options.y, equals(100));
    });

    test('parses box field', () {
      final result = parseIPL('\x02\x1bC1\x03\x02\x1bP\x03\x02W1;o10,20;f0;l200;h100;w2\x03\x02\x1bE1\x03\x02R\x03');
      final boxes = result.elements.whereType<BoxElement>().toList();
      expect(boxes, hasLength(1));
      expect(boxes[0].options.x, equals(10));
      expect(boxes[0].options.y, equals(20));
      expect(boxes[0].options.width, equals(200));
      expect(boxes[0].options.height, equals(100));
    });

    test('parses line field', () {
      final result = parseIPL('\x02\x1bC1\x03\x02\x1bP\x03\x02L1;o10,50;f0;l290;w2\x03\x02\x1bE1\x03\x02R\x03');
      final lines = result.elements.whereType<LineElement>().toList();
      expect(lines, hasLength(1));
      expect(lines[0].options.x1, equals(10));
      expect(lines[0].options.y1, equals(50));
    });

    test('parses multiple copies', () {
      final result = parseIPL('\x02\x1bC1\x03\x02\x1bP\x03\x02\x1bM5\x03\x02\x1bE1\x03\x02R\x03');
      final cmd = result.commands.firstWhere((c) => c.type == 'MULTIPLE');
      expect(cmd.params, equals('5'));
    });
  });

  group('parseSBPL', () {
    test('parses start and end', () {
      final result = parseSBPL('\x1bA\x1bCS\x1bZ');
      expect(result.commands.any((c) => c.cmd == 'START'), isTrue);
      expect(result.commands.any((c) => c.cmd == 'CS'), isTrue);
      expect(result.commands.any((c) => c.cmd == 'END'), isTrue);
    });

    test('parses position commands', () {
      final result = parseSBPL('\x1bA\x1bH0100\x1bV0050\x1bZ');
      final hCmd = result.commands.firstWhere((c) => c.cmd == 'H');
      expect(hCmd.params, equals('0100'));
      final vCmd = result.commands.firstWhere((c) => c.cmd == 'V');
      expect(vCmd.params, equals('0050'));
    });

    test('parses text output', () {
      final result = parseSBPL('\x1bA\x1bH0100\x1bV0050\x1bK9BHello SATO\x1bZ');
      final textElements = result.elements.whereType<TextElement>().toList();
      expect(textElements, hasLength(1));
      expect(textElements[0].content, equals('Hello SATO'));
    });
  });

  group('parseStarPRNT', () {
    test('parses ESC @ (init)', () {
      final result = parseStarPRNT(Uint8List.fromList([0x1B, 0x40]));
      expect(result.commands.any((c) => c.name == 'ESC @'), isTrue);
    });

    test('parses text', () {
      final bytes = [
        0x1B, 0x40, // ESC @
        ...('Hello Star'.codeUnits),
        0x0A, // LF
        0x1B, 0x64, 1 // partial cut
      ];
      final result = parseStarPRNT(Uint8List.fromList(bytes));
      final texts = result.elements.whereType<TextElement>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].content, equals('Hello Star'));
    });

    test('parses bold (ESC E / ESC F)', () {
      final bytes = [
        0x1B, 0x40, // ESC @
        0x1B, 0x45, // bold on
        ...('Bold'.codeUnits),
        0x1B, 0x46, // bold off
      ];
      final result = parseStarPRNT(Uint8List.fromList(bytes));
      expect(result.commands.any((c) => c.name == 'ESC E'), isTrue);
      expect(result.commands.any((c) => c.name == 'ESC F'), isTrue);
    });

    test('parses size (ESC i)', () {
      final bytes = [
        0x1B, 0x40,
        0x1B, 0x69, 3, 3, // size 3x3
      ];
      final result = parseStarPRNT(Uint8List.fromList(bytes));
      final cmd = result.commands.firstWhere((c) => c.name == 'ESC i');
      expect(cmd.params['height'], equals(3));
      expect(cmd.params['width'], equals(3));
    });

    test('parses alignment (ESC GS a)', () {
      final bytes = [
        0x1B, 0x40,
        0x1B, 0x1D, 0x61, 1, // center
      ];
      final result = parseStarPRNT(Uint8List.fromList(bytes));
      final cmd = result.commands.firstWhere((c) => c.name == 'ESC GS a');
      expect(cmd.params['n'], equals(1));
    });

    test('parses partial cut (ESC d)', () {
      final bytes = [0x1B, 0x40, 0x1B, 0x64, 1];
      final result = parseStarPRNT(Uint8List.fromList(bytes));
      final cmd = result.commands.firstWhere((c) => c.name == 'ESC d');
      expect(cmd.params['n'], equals(1));
    });

    test('parses raster mode (ESC * r A/B)', () {
      final bytes = [
        0x1B, 0x40,
        0x1B, 0x2A, 0x72, 0x41, // enter raster
        0x1B, 0x2A, 0x72, 0x42, // exit raster
      ];
      final result = parseStarPRNT(Uint8List.fromList(bytes));
      expect(result.commands.any((c) => c.name == 'ESC * r A'), isTrue);
      expect(result.commands.any((c) => c.name == 'ESC * r B'), isTrue);
    });
  });

  group('parseESCPOS', () {
    test('parses ESC @ (init)', () {
      final result = parseESCPOS(Uint8List.fromList([0x1B, 0x40]));
      expect(result.commands.any((c) => c.name == 'ESC @'), isTrue);
    });

    test('parses ESC a (alignment)', () {
      final bytes = [0x1B, 0x40, 0x1B, 0x61, 1]; // center
      final result = parseESCPOS(Uint8List.fromList(bytes));
      final cmd = result.commands.firstWhere((c) => c.name == 'ESC a');
      expect(cmd.params['align'], equals('center'));
    });

    test('parses ESC E (bold)', () {
      final bytes = [0x1B, 0x40, 0x1B, 0x45, 1]; // bold on
      final result = parseESCPOS(Uint8List.fromList(bytes));
      final cmd = result.commands.firstWhere((c) => c.name == 'ESC E');
      expect(cmd.params['bold'], isTrue);
    });

    test('parses GS ! (character size)', () {
      final bytes = [0x1B, 0x40, 0x1D, 0x21, 0x11]; // 2x width, 2x height
      final result = parseESCPOS(Uint8List.fromList(bytes));
      final cmd = result.commands.firstWhere((c) => c.name == 'GS !');
      expect(cmd.params['width'], equals(2));
      expect(cmd.params['height'], equals(2));
    });

    test('parses GS V B (cut)', () {
      final bytes = [0x1B, 0x40, 0x1D, 0x56, 0x42, 0x03];
      final result = parseESCPOS(Uint8List.fromList(bytes));
      final cmd = result.commands.firstWhere((c) => c.name == 'GS V');
      expect(cmd.params['mode'], equals(0x42));
      expect(cmd.params['feed'], equals(3));
    });

    test('parses text content', () {
      final bytes = [
        0x1B, 0x40,
        ...('Hello'.codeUnits),
        0x0A,
      ];
      final result = parseESCPOS(Uint8List.fromList(bytes));
      final texts = result.elements.whereType<TextElement>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].content, equals('Hello'));
    });

    test('parses ESC t (code page)', () {
      final bytes = [0x1B, 0x40, 0x1B, 0x74, 19]; // CP858
      final result = parseESCPOS(Uint8List.fromList(bytes));
      final cmd = result.commands.firstWhere((c) => c.name == 'ESC t');
      expect(cmd.params['codePage'], equals(19));
    });
  });
}
