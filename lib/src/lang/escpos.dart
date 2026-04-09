import 'dart:typed_data';
import '../builder.dart';
import '../languages/escpos.dart';

/// ESC/POS language module.
class EscposLang {
  Uint8List compile(LabelBuilder builder) {
    return compileToESCPOS(builder.resolve());
  }

  dynamic parse(Uint8List data) {
    throw UnimplementedError('ESC/POS parse not yet implemented');
  }

  String preview(LabelBuilder builder) {
    throw UnimplementedError('ESC/POS preview not yet implemented');
  }

  dynamic validate(String code) {
    throw UnimplementedError('ESC/POS validate not yet implemented');
  }
}

final escpos = EscposLang();
