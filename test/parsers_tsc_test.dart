import 'package:test/test.dart';
import 'package:portakal_flutter/src/parsers/tsc.dart';

void main() {
  group('parseTSPL', () {
    test('returns empty for empty input', () {
      final result = parseTSPL('');
      expect(result.commands, isEmpty);
      expect(result.elements, isEmpty);
    });

    test('returns empty for whitespace only', () {
      final result = parseTSPL('   \n  \n  ');
      expect(result.commands, isEmpty);
    });

    // --- Setup Commands ---
    group('SIZE command', () {
      test('parses SIZE with mm', () {
        final result = parseTSPL('SIZE 40 mm,30 mm');
        final size = result.commands.firstWhere((c) => c.cmd == 'SIZE');
        expect(size.widthMM, equals(40));
        expect(size.heightMM, equals(30));
        expect(size.unit, equals('mm'));
      });

      test('parses SIZE with inches', () {
        final result = parseTSPL('SIZE 4,3');
        final size = result.commands.firstWhere((c) => c.cmd == 'SIZE');
        expect(size.widthMM, equals(4));
        expect(size.heightMM, equals(3));
        expect(size.unit, equals('inch'));
      });

      test('parses SIZE with dots', () {
        final result = parseTSPL('SIZE 320 dot,240 dot');
        final size = result.commands.firstWhere((c) => c.cmd == 'SIZE');
        expect(size.widthMM, equals(320));
        expect(size.heightMM, equals(240));
        expect(size.unit, equals('dot'));
      });
    });

    group('GAP command', () {
      test('parses GAP with mm', () {
        final result = parseTSPL('GAP 3 mm,0 mm');
        final gap = result.commands.firstWhere((c) => c.cmd == 'GAP');
        expect(gap.distanceMM, equals(3));
        expect(gap.offsetMM, equals(0));
      });
    });

    group('SPEED and DENSITY', () {
      test('parses SPEED', () {
        final result = parseTSPL('SPEED 4');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'SPEED');
        expect(cmd.value, equals(4));
      });

      test('parses DENSITY', () {
        final result = parseTSPL('DENSITY 8');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'DENSITY');
        expect(cmd.value, equals(8));
      });
    });

    group('DIRECTION', () {
      test('parses DIRECTION', () {
        final result = parseTSPL('DIRECTION 0');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'DIRECTION');
        expect(cmd.direction, equals(0));
      });

      test('parses DIRECTION with mirror', () {
        final result = parseTSPL('DIRECTION 1,1');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'DIRECTION');
        expect(cmd.direction, equals(1));
        expect(cmd.mirror, equals(1));
      });
    });

    test('parses REFERENCE', () {
      final result = parseTSPL('REFERENCE 10,20');
      final cmd = result.commands.firstWhere((c) => c.cmd == 'REFERENCE');
      expect(cmd.x, equals(10));
      expect(cmd.y, equals(20));
    });

    test('parses CLS', () {
      final result = parseTSPL('CLS');
      expect(result.commands.any((c) => c.cmd == 'CLS'), isTrue);
    });

    // --- Text Commands ---
    group('TEXT command', () {
      test('parses TEXT with all params', () {
        final result = parseTSPL('TEXT 100,200,"2",0,1,1,"Hello World"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'TEXT');
        expect(cmd.x, equals(100));
        expect(cmd.y, equals(200));
        expect(cmd.font, equals('2'));
        expect(cmd.rotation, equals(0));
        expect(cmd.xMul, equals(1));
        expect(cmd.yMul, equals(1));
        expect(cmd.content, equals('Hello World'));
      });

      test('parses TEXT with scale multiplier', () {
        final result = parseTSPL('TEXT 50,60,"3",0,2,3,"Scaled"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'TEXT');
        expect(cmd.xMul, equals(2));
        expect(cmd.yMul, equals(3));
      });

      test('parses TEXT with rotation', () {
        final result = parseTSPL('TEXT 50,60,"2",90,1,1,"Rotated"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'TEXT');
        expect(cmd.rotation, equals(90));
      });

      test('creates text element', () {
        final result = parseTSPL('TEXT 10,20,"2",0,1,1,"Test"');
        expect(result.elements, hasLength(1));
        expect(result.elements[0].type, equals('text'));
      });
    });

    // --- Drawing Commands ---
    group('drawing commands', () {
      test('parses BOX', () {
        final result = parseTSPL('BOX 10,20,300,200,3');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'BOX');
        expect(cmd.x, equals(10));
        expect(cmd.y, equals(20));
        expect(cmd.xEnd, equals(300));
        expect(cmd.yEnd, equals(200));
        expect(cmd.thickness, equals(3));
      });

      test('parses BOX with radius', () {
        final result = parseTSPL('BOX 10,20,300,200,3,10');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'BOX');
        expect(cmd.radius, equals(10));
      });

      test('parses BAR', () {
        final result = parseTSPL('BAR 10,20,300,5');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'BAR');
        expect(cmd.x, equals(10));
        expect(cmd.y, equals(20));
        expect(cmd.width, equals(300));
        expect(cmd.height, equals(5));
      });

      test('parses CIRCLE', () {
        final result = parseTSPL('CIRCLE 100,100,50,2');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'CIRCLE');
        expect(cmd.x, equals(100));
        expect(cmd.y, equals(100));
        expect(cmd.diameter, equals(50));
        expect(cmd.thickness, equals(2));
      });

      test('parses ELLIPSE', () {
        final result = parseTSPL('ELLIPSE 100,100,80,40,2');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'ELLIPSE');
        expect(cmd.x, equals(100));
        expect(cmd.y, equals(100));
        expect(cmd.width, equals(80));
        expect(cmd.height, equals(40));
        expect(cmd.thickness, equals(2));
      });

      test('parses DIAGONAL', () {
        final result = parseTSPL('DIAGONAL 10,20,300,200,2');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'DIAGONAL');
        expect(cmd.x1, equals(10));
        expect(cmd.y1, equals(20));
        expect(cmd.x2, equals(300));
        expect(cmd.y2, equals(200));
        expect(cmd.thickness, equals(2));
      });

      test('parses REVERSE', () {
        final result = parseTSPL('REVERSE 50,50,200,100');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'REVERSE');
        expect(cmd.x, equals(50));
        expect(cmd.y, equals(50));
        expect(cmd.width, equals(200));
        expect(cmd.height, equals(100));
      });

      test('parses ERASE', () {
        final result = parseTSPL('ERASE 50,50,200,100');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'ERASE');
        expect(cmd.x, equals(50));
        expect(cmd.y, equals(50));
      });
    });

    // --- Barcode Commands ---
    group('barcode commands', () {
      test('parses BARCODE', () {
        final result = parseTSPL('BARCODE 50,100,"128",60,1,0,2,4,"ABC123"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'BARCODE');
        expect(cmd.x, equals(50));
        expect(cmd.y, equals(100));
        expect(cmd.typeStr, equals('128'));
        expect(cmd.height, equals(60));
        expect(cmd.readable, equals(1));
        expect(cmd.content, equals('ABC123'));
      });

      test('parses QRCODE', () {
        final result = parseTSPL(
          'QRCODE 100,200,L,4,A,0,M2,S3,"https://example.com"',
        );
        final cmd = result.commands.firstWhere((c) => c.cmd == 'QRCODE');
        expect(cmd.x, equals(100));
        expect(cmd.y, equals(200));
        expect(cmd.ecc, equals('L'));
        expect(cmd.cellWidth, equals(4));
        expect(cmd.mode, equals('A'));
        expect(cmd.content, equals('https://example.com'));
      });

      test('parses DMATRIX', () {
        final result = parseTSPL('DMATRIX 100,200,200,200,"DATA"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'DMATRIX');
        expect(cmd.x, equals(100));
        expect(cmd.y, equals(200));
        expect(cmd.content, equals('DATA'));
      });

      test('parses PDF417', () {
        final result = parseTSPL('PDF417 100,200,200,200,0,"Hello"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'PDF417');
        expect(cmd.x, equals(100));
        expect(cmd.y, equals(200));
        expect(cmd.content, equals('Hello'));
      });
    });

    // --- Image Commands ---
    group('image commands', () {
      test('parses BITMAP', () {
        final result = parseTSPL('BITMAP 10,20,4,100,0');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'BITMAP');
        expect(cmd.x, equals(10));
        expect(cmd.y, equals(20));
        expect(cmd.widthBytes, equals(4));
        expect(cmd.height, equals(100));
      });

      test('parses PUTBMP', () {
        final result = parseTSPL('PUTBMP 10,20,"LOGO.BMP"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'PUTBMP');
        expect(cmd.x, equals(10));
        expect(cmd.y, equals(20));
        expect(cmd.filename, equals('LOGO.BMP'));
      });

      test('parses PUTPCX', () {
        final result = parseTSPL('PUTPCX 10,20,"IMAGE.PCX"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'PUTPCX');
        expect(cmd.x, equals(10));
        expect(cmd.y, equals(20));
        expect(cmd.filename, equals('IMAGE.PCX'));
      });
    });

    // --- Printer Control Commands ---
    group('printer control commands', () {
      test('parses PRINT', () {
        final result = parseTSPL('PRINT 1');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'PRINT');
        expect(cmd.sets, equals(1));
      });

      test('parses PRINT with sets and copies', () {
        final result = parseTSPL('PRINT 3,2');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'PRINT');
        expect(cmd.sets, equals(3));
        expect(cmd.copies, equals(2));
      });

      test('parses FEED', () {
        final result = parseTSPL('FEED 100');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'FEED');
        expect(cmd.dots, equals(100));
      });

      test('parses BACKFEED', () {
        final result = parseTSPL('BACKFEED 50');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'BACKFEED');
        expect(cmd.dots, equals(50));
      });

      test('parses FORMFEED', () {
        final result = parseTSPL('FORMFEED');
        expect(result.commands.any((c) => c.cmd == 'FORMFEED'), isTrue);
      });

      test('parses HOME', () {
        final result = parseTSPL('HOME');
        expect(result.commands.any((c) => c.cmd == 'HOME'), isTrue);
      });

      test('parses CUT', () {
        final result = parseTSPL('CUT');
        expect(result.commands.any((c) => c.cmd == 'CUT'), isTrue);
      });

      test('parses SOUND', () {
        final result = parseTSPL('SOUND 2,100');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'SOUND');
        expect(cmd.level, equals(2));
        expect(cmd.interval, equals(100));
      });

      test('parses LIMITFEED', () {
        final result = parseTSPL('LIMITFEED 300');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'LIMITFEED');
        expect(cmd.maxLen, equals(300));
      });

      test('parses SELFTEST', () {
        final result = parseTSPL('SELFTEST');
        expect(result.commands.any((c) => c.cmd == 'SELFTEST'), isTrue);
      });

      test('parses DELAY', () {
        final result = parseTSPL('DELAY 1000');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'DELAY');
        expect(cmd.ms, equals(1000));
      });

      test('parses INITIALPRINTER', () {
        final result = parseTSPL('INITIALPRINTER');
        expect(result.commands.any((c) => c.cmd == 'INITIALPRINTER'), isTrue);
      });
    });

    // --- SET Command ---
    group('SET command', () {
      test('parses SET with key value', () {
        final result = parseTSPL('SET CUTTER BATCH');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'SET');
        expect(cmd.key, equals('CUTTER'));
      });
    });

    // --- BASIC Programming Commands ---
    group('BASIC programming', () {
      test('parses FOR loop', () {
        final result = parseTSPL('FOR I = 1 TO 10 STEP 2');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'FOR');
        expect(cmd.variable, equals('I'));
        expect(cmd.start, equals('1'));
        expect(cmd.endVal, equals('10'));
        expect(cmd.step, equals('2'));
      });

      test('parses NEXT', () {
        final result = parseTSPL('NEXT');
        expect(result.commands.any((c) => c.cmd == 'NEXT'), isTrue);
      });

      test('parses IF THEN', () {
        final result = parseTSPL('IF I > 5 THEN');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'IF');
        expect(cmd.condition, isNotNull);
      });

      test('parses ENDIF', () {
        final result = parseTSPL('ENDIF');
        expect(result.commands.any((c) => c.cmd == 'ENDIF'), isTrue);
      });

      test('parses GOTO', () {
        final result = parseTSPL('GOTO STARTLOOP');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'GOTO');
        expect(cmd.labelName, equals('STARTLOOP'));
      });

      test('parses GOSUB', () {
        final result = parseTSPL('GOSUB MYSUB');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'GOSUB');
        expect(cmd.labelName, equals('MYSUB'));
      });

      test('parses REM comment', () {
        final result = parseTSPL('REM This is a comment');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'REM');
        expect(cmd.comment, equals('This is a comment'));
      });

      test('parses LABEL', () {
        final result = parseTSPL('STARTLOOP:');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'LABEL');
        expect(cmd.name, equals('STARTLOOP'));
      });

      test('parses END', () {
        final result = parseTSPL('END');
        expect(result.commands.any((c) => c.cmd == 'END'), isTrue);
      });
    });

    // --- File Commands ---
    group('file commands', () {
      test('parses DOWNLOAD', () {
        final result = parseTSPL('DOWNLOAD "LOGO.BMP"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'DOWNLOAD');
        expect(cmd.filename, equals('LOGO.BMP'));
      });

      test('parses FILES', () {
        final result = parseTSPL('FILES');
        expect(result.commands.any((c) => c.cmd == 'FILES'), isTrue);
      });

      test('parses KILL', () {
        final result = parseTSPL('KILL "LOGO.BMP"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'KILL');
        expect(cmd.filename, equals('LOGO.BMP'));
      });
    });

    // --- Network Commands ---
    group('network commands', () {
      test('parses NET', () {
        final result = parseTSPL('NET DHCP');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'NET');
        expect(cmd.subcommand, equals('DHCP'));
      });

      test('parses WLAN', () {
        final result = parseTSPL('WLAN SSID MyNetwork');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'WLAN');
        expect(cmd.subcommand, equals('SSID'));
      });
    });

    // --- CODEPAGE ---
    test('parses CODEPAGE', () {
      final result = parseTSPL('CODEPAGE UTF-8');
      final cmd = result.commands.firstWhere((c) => c.cmd == 'CODEPAGE');
      expect(cmd.codepage, equals('UTF-8'));
    });

    // --- COUNTRY ---
    test('parses COUNTRY', () {
      final result = parseTSPL('COUNTRY 001');
      final cmd = result.commands.firstWhere((c) => c.cmd == 'COUNTRY');
      expect(cmd.codeStr, equals('001'));
    });

    // --- Multi-line Command Parsing ---
    group('multi-line parsing', () {
      test('parses complete label definition', () {
        final code = '''
SIZE 40 mm,30 mm
GAP 3 mm,0 mm
SPEED 4
DENSITY 8
DIRECTION 0
CLS
TEXT 10,20,"2",0,1,1,"Hello"
BOX 5,5,315,235,2
PRINT 1
''';
        final result = parseTSPL(code);
        expect(result.commands.length, greaterThan(5));
        expect(result.commands.any((c) => c.cmd == 'SIZE'), isTrue);
        expect(result.commands.any((c) => c.cmd == 'TEXT'), isTrue);
        expect(result.commands.any((c) => c.cmd == 'BOX'), isTrue);
        expect(result.commands.any((c) => c.cmd == 'PRINT'), isTrue);
      });

      test('generates elements for graphical commands', () {
        final code = '''
TEXT 10,20,"2",0,1,1,"Test"
BOX 5,5,315,235,2
CIRCLE 100,100,50,2
''';
        final result = parseTSPL(code);
        expect(result.elements.length, equals(3));
      });
    });

    // --- OFFSET ---
    test('parses OFFSET', () {
      final result = parseTSPL('OFFSET 10 mm');
      final cmd = result.commands.firstWhere((c) => c.cmd == 'OFFSET');
      expect(cmd.distance, equals(10));
    });

    // --- BLINE ---
    test('parses BLINE', () {
      final result = parseTSPL('BLINE 3 mm,0 mm');
      final cmd = result.commands.firstWhere((c) => c.cmd == 'BLINE');
      expect(cmd.height, equals(3));
    });

    // --- GAPDETECT ---
    test('parses GAPDETECT', () {
      final result = parseTSPL('GAPDETECT');
      expect(result.commands.any((c) => c.cmd == 'GAPDETECT'), isTrue);
    });

    // --- 2D Barcode Commands ---
    group('2D barcode commands', () {
      test('parses AZTEC', () {
        final result = parseTSPL('AZTEC 100,200,0,"DATA"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'AZTEC');
        expect(cmd.x, equals(100));
        expect(cmd.y, equals(200));
        expect(cmd.content, equals('DATA'));
      });

      test('parses MAXICODE', () {
        final result = parseTSPL('MAXICODE 100,200,2,"DATA"');
        final cmd = result.commands.firstWhere((c) => c.cmd == 'MAXICODE');
        expect(cmd.x, equals(100));
        expect(cmd.y, equals(200));
      });
    });

    // --- UNKNOWN ---
    test('Unknown commands are parsed as UNKNOWN', () {
      final result = parseTSPL('XYZCOMMAND whatever');
      final cmd = result.commands.firstWhere((c) => c.cmd == 'UNKNOWN');
      expect(cmd.raw, contains('XYZCOMMAND'));
    });
  });
}
