class EegSample {
  final int channel1;
  final int channel2;
  final int channel3;
  final int channel4;

  EegSample({
    required this.channel1,
    required this.channel2,
    required this.channel3,
    required this.channel4,
  });

  int getChannel(int index) {
    switch (index) {
      case 0:
        return channel1;
      case 1:
        return channel2;
      case 2:
        return channel3;
      case 3:
        return channel4;
      default:
        throw ArgumentError('Channel index must be 0-3, got $index');
    }
  }

  double getChannelVoltage(int index) {
    int raw = getChannel(index);
    return (raw / 4095.0) * 3.3;
  }

  @override
  String toString() =>
      'EegSample(ch1: $channel1, ch2: $channel2, ch3: $channel3, ch4: $channel4)';
}

class EegDataPacket {
  static const int packetType = 0x01;
  static const int expectedLength = 19;

  final int sequenceNumber;
  final EegSample sample1;
  final EegSample sample2;
  final DateTime timestamp;

  EegDataPacket({
    required this.sequenceNumber,
    required this.sample1,
    required this.sample2,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory EegDataPacket.fromBytes(List<int> rawBytes) {
    List<int> bytes = _ensureBinaryBytes(rawBytes);

    if (bytes.length < expectedLength) {
      throw FormatException(
        'EEG packet too short: expected $expectedLength bytes, got ${bytes.length}',
      );
    }

    if (bytes[0] != packetType) {
      throw FormatException(
        'Invalid packet type: expected 0x${packetType.toRadixString(16)}, '
        'got 0x${bytes[0].toRadixString(16)}',
      );
    }

    final sequenceNumber = bytes[1] | (bytes[2] << 8);

    final sample1 = EegSample(
      channel1: bytes[3] | (bytes[4] << 8),
      channel2: bytes[5] | (bytes[6] << 8),
      channel3: bytes[7] | (bytes[8] << 8),
      channel4: bytes[9] | (bytes[10] << 8),
    );

    final sample2 = EegSample(
      channel1: bytes[11] | (bytes[12] << 8),
      channel2: bytes[13] | (bytes[14] << 8),
      channel3: bytes[15] | (bytes[16] << 8),
      channel4: bytes[17] | (bytes[18] << 8),
    );

    return EegDataPacket(
      sequenceNumber: sequenceNumber,
      sample1: sample1,
      sample2: sample2,
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
  String toString() =>
      'EegDataPacket(seq: $sequenceNumber, s1: $sample1, s2: $sample2)';
}