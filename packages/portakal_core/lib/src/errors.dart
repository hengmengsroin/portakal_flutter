/// Base error class for portakal.
class PortakalError implements Exception {
  final String message;

  const PortakalError(this.message);

  @override
  String toString() => 'PortakalError: $message';
}

/// Thrown when label configuration is invalid.
class InvalidConfigError extends PortakalError {
  const InvalidConfigError(super.message);

  @override
  String toString() => 'InvalidConfigError: $message';
}

/// Thrown when a feature is not supported by the target language.
class UnsupportedFeatureError extends PortakalError {
  const UnsupportedFeatureError(super.message);

  @override
  String toString() => 'UnsupportedFeatureError: $message';
}

/// Thrown when an encoding or character mapping error occurs.
class EncodingError extends PortakalError {
  const EncodingError(super.message);

  @override
  String toString() => 'EncodingError: $message';
}
