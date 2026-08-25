/// Portakal Core — Universal printer language SDK.
///
/// Pure-Dart protocol engine for TSC, ZPL, EPL, ESC/POS, CPCL, DPL, IPL, SBPL, and Star PRNT.
/// Fluent AST builder, protocol compilers, native builders, parsers, encodings, and dithering.
library;

// Core
export 'src/types.dart';
export 'src/errors.dart';
export 'src/utils.dart';
export 'src/builder.dart';
export 'src/profiles.dart';

// Utilities
export 'src/image.dart';
export 'src/encoding.dart';
export 'src/receipt.dart';
export 'src/transport.dart';

// Preview & Validation
export 'src/preview.dart';
export 'src/validate.dart';

// Cross-compilation & Markup
export 'src/convert.dart';
export 'src/markup.dart';

// Language modules (compile + parse + preview + validate)
export 'src/lang/tsc.dart';
export 'src/lang/zpl.dart';
export 'src/lang/epl.dart';
export 'src/lang/escpos.dart';
export 'src/lang/cpcl.dart';
export 'src/lang/dpl.dart';
export 'src/lang/ipl.dart';
export 'src/lang/sbpl.dart';
export 'src/lang/starprnt.dart';

// Compilers
export 'src/languages/tsc.dart';
export 'src/languages/zpl.dart';
export 'src/languages/epl.dart';
export 'src/languages/escpos.dart';
export 'src/languages/cpcl.dart';
export 'src/languages/dpl.dart';
export 'src/languages/ipl.dart';
export 'src/languages/sbpl.dart';
export 'src/languages/starprnt.dart';

// Parsers
export 'src/parsers/tsc.dart';
export 'src/parsers/zpl.dart';
export 'src/parsers/epl.dart';
export 'src/parsers/escpos.dart';
export 'src/parsers/cpcl.dart';
export 'src/parsers/dpl.dart';
export 'src/parsers/ipl.dart';
export 'src/parsers/sbpl.dart';
export 'src/parsers/starprnt.dart';

// Native Protocol Builders
export 'src/native/tsc.dart';
export 'src/native/escpos.dart';
export 'src/native/zpl.dart';
export 'src/native/epl.dart';
export 'src/native/cpcl.dart';
export 'src/native/dpl.dart';
export 'src/native/ipl.dart';
export 'src/native/sbpl.dart';
export 'src/native/starprnt.dart';
