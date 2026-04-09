import '../builder.dart';
import '../languages/epl.dart';

/// EPL2 language module.
class EplLang {
  String compile(LabelBuilder builder) {
    return compileToEPL(builder.resolve());
  }

  dynamic parse(String code) {
    throw UnimplementedError('EPL parse not yet implemented');
  }

  String preview(LabelBuilder builder) {
    throw UnimplementedError('EPL preview not yet implemented');
  }

  dynamic validate(String code) {
    throw UnimplementedError('EPL validate not yet implemented');
  }
}

final epl = EplLang();
