import 'dart:typed_data';

/// Computes the SHA-256 hash of [data] according to FIPS 180-2.
///
/// Returns a 64-character lowercase hexadecimal string.
String calculateSha256(Uint8List data) {
  // Initial hash values (first 32 bits of the fractional parts of the square roots of the first 8 primes 2..19)
  int h0 = 0x6a09e667;
  int h1 = 0xbb67ae85;
  int h2 = 0x3c6ef372;
  int h3 = 0xa54ff53a;
  int h4 = 0x510e527f;
  int h5 = 0x9b05688c;
  int h6 = 0x1f83d9ab;
  int h7 = 0x5be0cd19;

  // Round constants (first 32 bits of fractional parts of cube roots of first 64 primes 2..311)
  const k = <int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  // Pre-processing (Padding)
  final len = data.length;
  final bitLen = len * 8;

  // Length in bytes with 1 byte 0x80 + padding + 8 bytes length
  final padLen = (len % 64 < 56) ? (56 - (len % 64)) : (120 - (len % 64));
  final padded = Uint8List(len + padLen + 8);
  padded.setRange(0, len, data);
  padded[len] = 0x80;

  // Append original length in bits as 64-bit big-endian integer
  final byteData = ByteData.sublistView(padded);
  byteData.setUint32(padded.length - 4, bitLen & 0xFFFFFFFF, Endian.big);
  byteData.setUint32(
    padded.length - 8,
    (bitLen >> 32) & 0xFFFFFFFF,
    Endian.big,
  );

  int rotR(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xFFFFFFFF;
  int ch(int x, int y, int z) => ((x & y) ^ ((~x) & z)) & 0xFFFFFFFF;
  int maj(int x, int y, int z) => ((x & y) ^ (x & z) ^ (y & z)) & 0xFFFFFFFF;
  int sigma0(int x) => (rotR(x, 2) ^ rotR(x, 13) ^ rotR(x, 22)) & 0xFFFFFFFF;
  int sigma1(int x) => (rotR(x, 6) ^ rotR(x, 11) ^ rotR(x, 25)) & 0xFFFFFFFF;
  int gamma0(int x) => (rotR(x, 7) ^ rotR(x, 18) ^ (x >>> 3)) & 0xFFFFFFFF;
  int gamma1(int x) => (rotR(x, 17) ^ rotR(x, 19) ^ (x >>> 10)) & 0xFFFFFFFF;

  final w = List<int>.filled(64, 0);

  // Process message in successive 512-bit (64-byte) chunks
  for (int chunk = 0; chunk < padded.length; chunk += 64) {
    for (int t = 0; t < 16; t++) {
      w[t] = byteData.getUint32(chunk + (t * 4), Endian.big);
    }
    for (int t = 16; t < 64; t++) {
      w[t] =
          (gamma1(w[t - 2]) + w[t - 7] + gamma0(w[t - 15]) + w[t - 16]) &
          0xFFFFFFFF;
    }

    int a = h0;
    int b = h1;
    int c = h2;
    int d = h3;
    int e = h4;
    int f = h5;
    int g = h6;
    int h = h7;

    for (int t = 0; t < 64; t++) {
      final t1 = (h + sigma1(e) + ch(e, f, g) + k[t] + w[t]) & 0xFFFFFFFF;
      final t2 = (sigma0(a) + maj(a, b, c)) & 0xFFFFFFFF;
      h = g;
      g = f;
      f = e;
      e = (d + t1) & 0xFFFFFFFF;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & 0xFFFFFFFF;
    }

    h0 = (h0 + a) & 0xFFFFFFFF;
    h1 = (h1 + b) & 0xFFFFFFFF;
    h2 = (h2 + c) & 0xFFFFFFFF;
    h3 = (h3 + d) & 0xFFFFFFFF;
    h4 = (h4 + e) & 0xFFFFFFFF;
    h5 = (h5 + f) & 0xFFFFFFFF;
    h6 = (h6 + g) & 0xFFFFFFFF;
    h7 = (h7 + h) & 0xFFFFFFFF;
  }

  String hex(int val) => val.toRadixString(16).padLeft(8, '0');
  return '${hex(h0)}${hex(h1)}${hex(h2)}${hex(h3)}${hex(h4)}${hex(h5)}${hex(h6)}${hex(h7)}';
}
