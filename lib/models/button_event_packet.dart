class ButtonEventPacket {
  static const int packetType = 0x02;
  static const int expectedLength = 3;

  final int buttonId;
  final bool isPressed;
  final DateTime timestamp;

  ButtonEventPacket({
    required this.buttonId,
    required this.isPressed,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get gpioPin {
    switch (buttonId) {
      case 1:
        return 'GPIO2';
      case 2:
        return 'GPIO3';
      case 3:
        return 'GPIO5';
      default:
        return 'Unknown';
    }
  }

  String get buttonName {
    switch (buttonId) {
      case 1:
        return 'Button 1';
      case 2:
        return 'Button 2';
      case 3:
        return 'Button 3';
      default:
        return 'Button $buttonId';
    }
  }

  String get stateString => isPressed ? 'Pressed' : 'Released';

  factory ButtonEventPacket.fromBytes(List<int> bytes) {
    List<int> parsed = _ensureBinaryBytes(bytes);

    if (parsed.length < expectedLength) {
      throw FormatException(
        'Button event packet too short: expected $expectedLength bytes, got ${parsed.length}',
      );
    }

    if (parsed[0] != packetType) {
      throw FormatException(
        'Invalid packet type: expected 0x${packetType.toRadixString(16)}, '
        'got 0x${parsed[0].toRadixString(16)}',
      );
    }

    return ButtonEventPacket(
      buttonId: parsed[1],
      isPressed: parsed[2] == 0x01,
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
      'ButtonEvent(button: $buttonId [$gpioPin], state: $stateString)';
}