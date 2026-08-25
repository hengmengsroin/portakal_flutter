import 'case_model.dart';
import 'suites/cpcl_validation_suite.dart';
import 'suites/dpl_validation_suite.dart';
import 'suites/epl_validation_suite.dart';
import 'suites/escpos_validation_suite.dart';
import 'suites/ipl_validation_suite.dart';
import 'suites/sbpl_validation_suite.dart';
import 'suites/star_validation_suite.dart';
import 'suites/tsc_validation_suite.dart';
import 'suites/zpl_validation_suite.dart';

/// Registry of all supported printer protocol validation suites.
class ProtocolRegistry {
  static final List<ProtocolValidationSuite> allSuites = [
    EscPosValidationSuite(),
    TscValidationSuite(),
    ZplValidationSuite(),
    EplValidationSuite(),
    CpclValidationSuite(),
    DplValidationSuite(),
    IplValidationSuite(),
    SbplValidationSuite(),
    StarValidationSuite(),
  ];

  static ProtocolValidationSuite getSuite(ValidationProtocol protocol) {
    return allSuites.firstWhere(
      (s) => s.protocol == protocol,
      orElse: () => allSuites.first,
    );
  }
}
