# Images & Raster Graphics Guide

Thermal printers print single-color (monochrome) images by depositing heat on sensitive paper dots. This guide covers image pre-processing, 1-bit bit-packing, dithering algorithms, and protocol-specific raster commands in Portakal 1.0.

---

## 1. The Monochrome Image Pipeline

Printing an arbitrary RGBA image involves four pipeline stages:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. RGBA Image Buffer (Width × Height)                       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Grayscale Conversion (rgbaToGrayscale)                    │
│    Luminance = 0.299*R + 0.587*G + 0.114*B                  │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Dithering (Floyd-Steinberg / Atkinson / Bayer / Threshold)│
│    Quantizes 8-bit grayscale (0..255) to 1-bit binary (0/1) │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Bit-Packing (MonochromeBitmap)                           │
│    Packs 8 horizontal pixels per byte (MSB first)           │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Protocol-Specific Raster Framing                         │
│    ESC/POS: GS v 0 | TSC: BITMAP | ZPL: ^GFA | EPL: GW      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. MonochromeBitmap Structure

`MonochromeBitmap` is Portakal's canonical 1-bit raster representation:

```dart
class MonochromeBitmap {
  final int width;
  final int height;
  final Uint8List data; // Packed bits: (width + 7) ~/ 8 bytes per row

  int get bytesPerRow => (width + 7) ~/ 8;
}
```

- Each byte stores 8 horizontal dots.
- Bit `1` represents a printed (black) dot.
- Bit `0` represents an unprinted (white) paper background.

---

## 3. Dithering Algorithms (`DitherAlgorithm`)

Portakal includes 4 dithering modes to convert grayscale pixel buffers:

```dart
enum DitherAlgorithm {
  /// Error-diffusion dithering for continuous-tone photos and smooth gradients.
  floydSteinberg,

  /// High-contrast error-diffusion for crisp logos, icons, and sharp line art.
  atkinson,

  /// 4x4 Bayer matrix ordered halftoning for fast processing and vintage print look.
  ordered,

  /// Strict 50% luminance cutoff (no diffusion) for pre-rendered black & white graphics.
  threshold,
}
```

### Converting RGBA Pixels to `MonochromeBitmap`

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

MonochromeBitmap processImage(Uint8List rgbaPixels, int width, int height) {
  return imageToMonochrome(
    rgbaPixels,
    width,
    height,
    const MonochromeOptions(
      dither: 'floyd-steinberg',
      threshold: 128,
    ),
  );
}
```

---

## 4. Protocol-Specific Raster Serialization

When a `MonochromeBitmap` is added to a `LabelBuilder` or native printer, Portakal formats the byte payload according to protocol specifications:

| Protocol | Native Command | Encoding & Framing | Binary Polarity |
| :--- | :--- | :--- | :--- |
| **ESC/POS** | `GS v 0` | 8-dot column byte packed | Standard (1 = Black) |
| **TSC** | `BITMAP` | Binary byte stream | Standard (1 = Black) |
| **ZPL II** | `^GFA` | Hex-encoded ASCII string | Inverted for ZPL (^GFA standard) |
| **EPL2** | `GW` | Binary byte stream | Inverted for EPL printhead |
| **CPCL** | `EG` | Hex-encoded ASCII string | Standard (1 = Black) |
| **Star PRNT** | `ESC * r` | Line Mode raster framing | Standard (1 = Black) |

---

## 5. Protocol Capability Boundaries (N/S-SDK Notice)

> [!WARNING]
> **Generic raster graphics are currently unsupported (`N/S-SDK`) on DPL, IPL, and SBPL.**
>
> On DPL, IPL, and SBPL printers, raster bitmap compilation is not implemented in the current SDK version. Attempting to compile labels containing `ImageElement` on these three protocols will throw `UnsupportedFeatureError` (or be omitted if `policy: UnsupportedFeaturePolicy.ignore` is used).
