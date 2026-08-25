# Portakal Flutter

Flutter integration package for **Portakal**, the universal thermal printer SDK.

- Provides the `LabelPreview` widget to visually render and preview label layouts before sending them to hardware.
- Re-exports the complete pure-Dart `portakal_core` engine — fluent AST builder, 9 protocol compilers, 9 native protocol builders, 9 parsers, encodings, and dithering.

## Installation

```yaml
dependencies:
  portakal_flutter: ^0.3.0
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

class LabelPreviewScreen extends StatelessWidget {
  const LabelPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fluent builder from portakal_core re-export
    final sampleLabel = label(const LabelConfig(width: 80, height: 60))
      .text('Flutter Shipping Label', const TextOptions(x: 20, y: 20, size: 2, bold: true))
      .box(const BoxOptions(x: 10, y: 10, width: 620, height: 460, thickness: 2));

    return Scaffold(
      appBar: AppBar(title: const Text('Label Preview')),
      body: Center(
        child: LabelPreview(label: sampleLabel), // Flutter widget from portakal_flutter
      ),
    );
  }
}
```
