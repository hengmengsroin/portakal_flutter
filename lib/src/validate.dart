import 'parsers/tsc.dart';
import 'parsers/zpl.dart';

/// Validation issue severity.
class ValidationIssue {
  final String level; // 'error', 'warning', 'info'
  final int? line;
  final String? command;
  final String message;

  const ValidationIssue({
    required this.level,
    this.line,
    this.command,
    required this.message,
  });
}

/// Validation result.
class ValidationResult {
  final bool valid;
  final List<ValidationIssue> issues;
  final int errors;
  final int warnings;
  final int infos;

  const ValidationResult({
    required this.valid,
    required this.issues,
    required this.errors,
    required this.warnings,
    required this.infos,
  });
}

/// Validate printer commands.
ValidationResult validate(String code, String language) {
  final issues = <ValidationIssue>[];

  if (code.trim().isEmpty) {
    issues.add(const ValidationIssue(level: 'error', message: 'Empty input'));
    return ValidationResult(valid: false, issues: issues, errors: 1, warnings: 0, infos: 0);
  }

  switch (language) {
    case 'tsc':
      _validateTSC(code, issues);
    case 'zpl':
      _validateZPL(code, issues);
    default:
      issues.add(ValidationIssue(
        level: 'info',
        message: 'Validation for ${language.toUpperCase()} is basic — only structure checks',
      ));
  }

  final errors = issues.where((i) => i.level == 'error').length;
  final warnings = issues.where((i) => i.level == 'warning').length;
  final infos = issues.where((i) => i.level == 'info').length;

  return ValidationResult(valid: errors == 0, issues: issues, errors: errors, warnings: warnings, infos: infos);
}

void _validateTSC(String code, List<ValidationIssue> issues) {
  final result = parseTSPL(code);
  final cmds = result.commands;

  // SIZE should be first non-comment command
  final firstCmd = cmds.where((c) => c.cmd != 'UNKNOWN' && c.cmd != 'REM').firstOrNull;
  if (firstCmd != null && firstCmd.cmd != 'SIZE') {
    issues.add(const ValidationIssue(level: 'warning', command: 'SIZE', message: 'SIZE should be the first command'));
  }

  // CLS before label elements
  final elementCmds = {'TEXT', 'BLOCK', 'BAR', 'BOX', 'CIRCLE', 'ELLIPSE', 'BITMAP', 'BARCODE', 'QRCODE', 'DMATRIX', 'PDF417', 'AZTEC', 'MAXICODE', 'RSS'};
  final clsIdx = cmds.indexWhere((c) => c.cmd == 'CLS');
  final firstElement = cmds.indexWhere((c) => elementCmds.contains(c.cmd));
  if (firstElement >= 0 && (clsIdx < 0 || clsIdx > firstElement)) {
    issues.add(const ValidationIssue(level: 'error', command: 'CLS', message: 'CLS must appear before label elements (TEXT, BOX, etc.)'));
  }

  // PRINT at end
  final printIdx = cmds.indexWhere((c) => c.cmd == 'PRINT');
  if (printIdx < 0) {
    issues.add(const ValidationIssue(level: 'warning', command: 'PRINT', message: 'No PRINT command found — label will not print'));
  }

  // Validate values
  for (final c in cmds) {
    if (c.cmd == 'DENSITY') {
      final v = c.value as num;
      if (v < 0 || v > 15) {
        issues.add(ValidationIssue(level: 'error', command: 'DENSITY', message: 'DENSITY value $v out of range (0-15)'));
      }
    }
    if (c.cmd == 'SPEED') {
      final v = c.value as num;
      if (v < 1 || v > 18) {
        issues.add(ValidationIssue(level: 'warning', command: 'SPEED', message: 'SPEED value $v may be out of range (1-18, model-dependent)'));
      }
    }
    if (c.cmd == 'UNKNOWN') {
      final raw = c.raw ?? '';
      issues.add(ValidationIssue(level: 'warning', command: raw.length > 20 ? raw.substring(0, 20) : raw, message: 'Unrecognized command: ${raw.length > 40 ? raw.substring(0, 40) : raw}'));
    }
  }
}

void _validateZPL(String code, List<ValidationIssue> issues) {
  final result = parseZPL(code);
  final cmds = result.commands;

  // ^XA at start
  if (cmds.isEmpty || cmds[0].code != '^XA') {
    issues.add(const ValidationIssue(level: 'error', command: '^XA', message: 'Label must start with ^XA'));
  }

  // ^XZ at end
  if (cmds.isEmpty || cmds.last.code != '^XZ') {
    issues.add(const ValidationIssue(level: 'error', command: '^XZ', message: 'Label must end with ^XZ'));
  }

  // ^FD without preceding ^FO
  var hasFieldOrigin = false;
  for (final c in cmds) {
    if (c.code == '^FO' || c.code == '^FT') hasFieldOrigin = true;
    if (c.code == '^FD' && !hasFieldOrigin) {
      issues.add(const ValidationIssue(level: 'warning', command: '^FD', message: '^FD without preceding ^FO — field position undefined'));
    }
    if (c.code == '^FS') hasFieldOrigin = false;
  }

  // ^PW range
  final pw = cmds.where((c) => c.code == '^PW').firstOrNull;
  if (pw != null && pw.params.isNotEmpty) {
    final w = int.tryParse(pw.params[0]) ?? 0;
    if (w < 2 || w > 65535) {
      issues.add(ValidationIssue(level: 'error', command: '^PW', message: '^PW value $w out of range (2-65535)'));
    }
  }
}
