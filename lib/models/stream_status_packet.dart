class StreamStatusPacket {
  static const int packetType = 0x03;
  static const int expectedLength = 2;

  final bool isStreaming;
  final DateTime timestamp;

  StreamStatusPacket({
    required this.isStreaming,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get statusString => isStreaming ? 'Playing' : 'Paused';

  factory StreamStatusPacket.fromBytes(List<int> bytes) {
    List<int> parsed = _ensureBinaryBytes(bytes);

    if (parsed.length < expectedLength) {
      throw FormatException(
        'Stream status packet too short: expected $expectedLength bytes, got ${parsed.length}',
      );
    }

    if (parsed[0] != packetType) {
      throw FormatException(
        'Invalid packet type: expected 0x${packetType.toRadixString(16)}, '
        'got 0x${parsed[0].toRadixString(16)}',
      );
    }

    return StreamStatusPacket(
      isStreaming: parsed[1] == 0x01,
    );
  }

  static List<int> _ensureBinaryBytes(List<int> rawBytes) {
    if (rawBytes.length == expectedLength) {
      return rawBytes;
    }

    bool looksLikeAsciiHex = rawBytes.length == expectedLength * 2 &&
        rawBytes.every((b) =>
            (b >= 0x30 && b <= 0x39) ||
            (b >= 0x41 && b <= 0x46) ||
            (b >= 0x61 && b <= 0x66));

    if (looksLikeAsciiHex) {
      String hexString = String.fromCharCodes(rawBytes);
      List<int> binaryBytes = [];
      for (int i = 0; i < hexString.length; i += 2) {
        binaryBytes.add(int.parse(hexString.substring(i, i + 2), radix: 16));
      }
      return binaryBytes;
    }

    return rawBytes;
  }

  @override
  String toString() => 'StreamStatus($statusString)';
}