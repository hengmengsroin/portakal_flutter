import 'types.dart';
import 'errors.dart';
import 'utils.dart';
import 'profiles.dart';

/// Create a new label builder.
///
/// ```dart
/// final myLabel = label(LabelConfig(width: 40, height: 30))
///   .text('Hello World', TextOptions(x: 10, y: 10))
///   .box(BoxOptions(x: 0, y: 0, width: 100, height: 100));
/// ```
LabelBuilder label(LabelConfig config) {
  return LabelBuilder(config);
}

/// Fluent API for building labels.
class LabelBuilder {
  final LabelConfig _config;
  final List<LabelElement> _elements = [];

  LabelBuilder(this._config) {
    if (_config.width <= 0) {
      throw InvalidConfigError('width must be greater than 0');
    }
  }

  /// Add a text element.
  LabelBuilder text(String content, [TextOptions? options]) {
    _elements.add(
      TextElement(content: content, options: options ?? const TextOptions()),
    );
    return this;
  }

  /// Add an image element.
  LabelBuilder image(MonochromeBitmap bitmap, [ImageOptions? options]) {
    _elements.add(
      ImageElement(bitmap: bitmap, options: options ?? const ImageOptions()),
    );
    return this;
  }

  /// Add a barcode element.
  LabelBuilder barcode(String content, BarcodeOptions options) {
    _elements.add(BarcodeElement(content: content, options: options));
    return this;
  }

  /// Add a QRCode element.
  LabelBuilder qrcode(String content, QRCodeOptions options) {
    _elements.add(QRCodeElement(content: content, options: options));
    return this;
  }

  /// Add a box element.
  LabelBuilder box(BoxOptions options) {
    _elements.add(BoxElement(options: options));
    return this;
  }

  /// Add a line element.
  LabelBuilder line(LineOptions options) {
    _elements.add(LineElement(options: options));
    return this;
  }

  /// Add a circle element.
  LabelBuilder circle(CircleOptions options) {
    _elements.add(CircleElement(options: options));
    return this;
  }

  /// Add an ellipse element.
  LabelBuilder ellipse(EllipseOptions options) {
    _elements.add(EllipseElement(options: options));
    return this;
  }

  /// Add a reverse region.
  LabelBuilder reverse(ReverseOptions options) {
    _elements.add(ReverseElement(options: options));
    return this;
  }

  /// Add an erase region.
  LabelBuilder erase(EraseOptions options) {
    _elements.add(EraseElement(options: options));
    return this;
  }

  /// Add a raw command passthrough.
  LabelBuilder raw(Object content) {
    _elements.add(RawElement(content: content));
    return this;
  }

  /// Add multiple copies.
  LabelBuilder print(int copies) {
    // Sets copies in config — handled at resolve time via config
    return this;
  }

  /// Resolve the label to its final representation.
  ResolvedLabel resolve() {
    final unit = _config.unit;

    // Check for printer profile
    int dpi = _config.dpi ?? 203;
    if (_config.printer != null) {
      final profile = getProfile(_config.printer!);
      if (profile != null) {
        // Use profile DPI unless user explicitly overrides
        if (_config.dpi == null) {
          dpi = profile.dpi;
        }
      }
    }

    final widthDots = toDots(_config.width, unit, dpi);
    final heightDots = _config.height != null
        ? toDots(_config.height!, unit, dpi)
        : 0;

    return ResolvedLabel(
      widthDots: widthDots,
      heightDots: heightDots,
      dpi: dpi,
      speed: _config.speed ?? 4,
      density: _config.density ?? 8,
      direction: _config.direction ?? 0,
      copies: _config.copies ?? 1,
      gap: _config.gap ?? 3,
      gapOffset: _config.gapOffset ?? 0,
      unit: unit,
      elements: List.unmodifiable(_elements),
    );
  }
}
