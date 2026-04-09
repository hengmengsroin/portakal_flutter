import 'dart:typed_data';
import '../builder.dart';
import '../languages/starprnt.dart';

class StarprntLang {
  Uint8List compile(LabelBuilder builder) {
    return compileToStarPRNT(builder.resolve());
  }

  dynamic parse(Uint8List data) => throw UnimplementedError();
  String preview(LabelBuilder builder) => throw UnimplementedError();
  dynamic validate(String code) => throw UnimplementedError();
}

final starprnt = StarprntLang();
