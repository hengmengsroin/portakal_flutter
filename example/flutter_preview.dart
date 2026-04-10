import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

void main() {
  runApp(const PreviewApp());
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Label Preview')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LabelPreview(
              label: label(LabelConfig(width: 40, height: 30))
                  .text(
                    'Preview before print',
                    TextOptions(x: 12, y: 20, size: 2, bold: true),
                  )
                  .line(
                    LineOptions(x1: 12, y1: 54, x2: 300, y2: 54, thickness: 2),
                  )
                  .box(
                    BoxOptions(
                      x: 8,
                      y: 8,
                      width: 304,
                      height: 210,
                      thickness: 2,
                    ),
                  )
                  .circle(
                    CircleOptions(x: 220, y: 90, diameter: 60, thickness: 2),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
