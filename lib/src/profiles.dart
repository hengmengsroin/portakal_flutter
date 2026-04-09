

/// Cutter type for printer profiles.
enum CutterType { full, partial, none }

/// Image mode for printer profiles.
enum ImageMode { raster, line }

/// Printer profile — capabilities and defaults.
class PrinterProfile {
  final String name;
  final String vendor;
  final String language;
  final int paperWidth;
  final int dotsPerLine;
  final int dpi;
  final int? usbVendorId;
  final PrinterFeatures features;

  const PrinterProfile({
    required this.name,
    required this.vendor,
    required this.language,
    required this.paperWidth,
    required this.dotsPerLine,
    required this.dpi,
    this.usbVendorId,
    required this.features,
  });
}

/// Printer features.
class PrinterFeatures {
  final CutterType cutter;
  final bool cashDrawer;
  final ImageMode imageMode;
  final int maxSpeed;
  final List<int>? supportedWidths;

  const PrinterFeatures({
    this.cutter = CutterType.none,
    this.cashDrawer = false,
    this.imageMode = ImageMode.raster,
    this.maxSpeed = 6,
    this.supportedWidths,
  });
}

/// All printer profiles.
const Map<String, PrinterProfile> printerProfiles = {
  // Epson
  'epson-tm-t88vi': PrinterProfile(
    name: 'Epson TM-T88VI',
    vendor: 'Epson',
    language: 'escpos',
    paperWidth: 80,
    dotsPerLine: 576,
    dpi: 203,
    usbVendorId: 0x04B8,
    features: PrinterFeatures(cutter: CutterType.partial, cashDrawer: true),
  ),
  'epson-tm-t20iii': PrinterProfile(
    name: 'Epson TM-T20III',
    vendor: 'Epson',
    language: 'escpos',
    paperWidth: 80,
    dotsPerLine: 576,
    dpi: 203,
    usbVendorId: 0x04B8,
    features: PrinterFeatures(cutter: CutterType.partial, cashDrawer: true),
  ),
  'epson-tm-m30ii': PrinterProfile(
    name: 'Epson TM-m30II',
    vendor: 'Epson',
    language: 'escpos',
    paperWidth: 80,
    dotsPerLine: 576,
    dpi: 203,
    usbVendorId: 0x04B8,
    features: PrinterFeatures(cutter: CutterType.partial),
  ),
  'epson-tm-t82iii': PrinterProfile(
    name: 'Epson TM-T82III',
    vendor: 'Epson',
    language: 'escpos',
    paperWidth: 80,
    dotsPerLine: 576,
    dpi: 203,
    usbVendorId: 0x04B8,
    features: PrinterFeatures(cutter: CutterType.partial, cashDrawer: true),
  ),
  // Star Micronics
  'star-tsp143': PrinterProfile(
    name: 'Star TSP143IV',
    vendor: 'Star Micronics',
    language: 'starprnt',
    paperWidth: 80,
    dotsPerLine: 576,
    dpi: 203,
    usbVendorId: 0x0519,
    features: PrinterFeatures(cutter: CutterType.partial, cashDrawer: true),
  ),
  'star-mc-print3': PrinterProfile(
    name: 'Star mC-Print3',
    vendor: 'Star Micronics',
    language: 'starprnt',
    paperWidth: 80,
    dotsPerLine: 576,
    dpi: 203,
    usbVendorId: 0x0519,
    features: PrinterFeatures(cutter: CutterType.partial, cashDrawer: true),
  ),
  // Bixolon
  'bixolon-srp-350iii': PrinterProfile(
    name: 'Bixolon SRP-350III',
    vendor: 'Bixolon',
    language: 'escpos',
    paperWidth: 80,
    dotsPerLine: 576,
    dpi: 203,
    usbVendorId: 0x1504,
    features: PrinterFeatures(cutter: CutterType.partial, cashDrawer: true),
  ),
  'bixolon-spp-r310': PrinterProfile(
    name: 'Bixolon SPP-R310',
    vendor: 'Bixolon',
    language: 'escpos',
    paperWidth: 80,
    dotsPerLine: 576,
    dpi: 203,
    usbVendorId: 0x1504,
    features: PrinterFeatures(cutter: CutterType.none),
  ),
  // Citizen
  'citizen-ct-s310ii': PrinterProfile(
    name: 'Citizen CT-S310II',
    vendor: 'Citizen',
    language: 'escpos',
    paperWidth: 80,
    dotsPerLine: 576,
    dpi: 203,
    usbVendorId: 0x1D90,
    features: PrinterFeatures(cutter: CutterType.partial, cashDrawer: true),
  ),
  // Generic
  'generic-58mm': PrinterProfile(
    name: 'Generic 58mm',
    vendor: 'Generic',
    language: 'escpos',
    paperWidth: 58,
    dotsPerLine: 384,
    dpi: 203,
    features: PrinterFeatures(),
  ),
  'generic-80mm': PrinterProfile(
    name: 'Generic 80mm',
    vendor: 'Generic',
    language: 'escpos',
    paperWidth: 80,
    dotsPerLine: 576,
    dpi: 203,
    features: PrinterFeatures(),
  ),
  // TSC
  'tsc-te200': PrinterProfile(
    name: 'TSC TE200',
    vendor: 'TSC',
    language: 'tsc',
    paperWidth: 108,
    dotsPerLine: 864,
    dpi: 203,
    usbVendorId: 0x1203,
    features: PrinterFeatures(maxSpeed: 6),
  ),
  'tsc-te310': PrinterProfile(
    name: 'TSC TE310',
    vendor: 'TSC',
    language: 'tsc',
    paperWidth: 108,
    dotsPerLine: 1276,
    dpi: 300,
    usbVendorId: 0x1203,
    features: PrinterFeatures(maxSpeed: 6),
  ),
  // Zebra
  'zebra-zd420': PrinterProfile(
    name: 'Zebra ZD420',
    vendor: 'Zebra',
    language: 'zpl',
    paperWidth: 108,
    dotsPerLine: 864,
    dpi: 203,
    usbVendorId: 0x0A5F,
    features: PrinterFeatures(maxSpeed: 8),
  ),
  'zebra-gk420d': PrinterProfile(
    name: 'Zebra GK420d',
    vendor: 'Zebra',
    language: 'zpl',
    paperWidth: 108,
    dotsPerLine: 864,
    dpi: 203,
    usbVendorId: 0x0A5F,
    features: PrinterFeatures(maxSpeed: 5),
  ),
  // SATO
  'sato-cl4nx': PrinterProfile(
    name: 'SATO CL4NX',
    vendor: 'SATO',
    language: 'sbpl',
    paperWidth: 118,
    dotsPerLine: 944,
    dpi: 203,
    usbVendorId: 0x0828,
    features: PrinterFeatures(maxSpeed: 10),
  ),
  // Honeywell
  'honeywell-pc42t': PrinterProfile(
    name: 'Honeywell PC42t',
    vendor: 'Honeywell',
    language: 'dpl',
    paperWidth: 108,
    dotsPerLine: 864,
    dpi: 203,
    usbVendorId: 0x0C2E,
    features: PrinterFeatures(maxSpeed: 4),
  ),
};

/// Get a printer profile by model ID.
PrinterProfile? getProfile(String modelId) {
  return printerProfiles[modelId];
}

/// List all available profile IDs.
List<String> listProfiles() {
  return printerProfiles.keys.toList();
}

/// Find profiles by USB vendor ID.
List<PrinterProfile> findByVendorId(int vendorId) {
  return printerProfiles.values
      .where((p) => p.usbVendorId == vendorId)
      .toList();
}

/// Find profiles by printer language.
List<PrinterProfile> findByLanguage(String language) {
  return printerProfiles.values
      .where((p) => p.language == language)
      .toList();
}
