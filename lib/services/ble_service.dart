import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/eeg_data_packet.dart';
import '../models/button_event_packet.dart';
import '../models/stream_status_packet.dart';

class NeuroGuardUuids {
  static final Guid serviceUuid =
      Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  static final Guid rxCharUuid =
      Guid('6E400002-B5A3-F393-E0A9-E50E24DCCA9E');
  static final Guid txCharUuid =
      Guid('6E400003-B5A3-F393-E0A9-E50E24DCCA9E');
}

class BleCommands {
  static const List<int> startStreaming = [0x31];
  static const List<int> stopStreaming = [0x30];
  static const List<int> startStreamingBinary = [0x01];
  static const List<int> stopStreamingBinary = [0x00];
}

enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
}

class BleService extends ChangeNotifier {
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BleConnectionState get connectionState => _connectionState;

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  String? get connectedDeviceId => _connectedDevice?.remoteId.str;
  String? get connectedDeviceName {
    if (_connectedDevice == null) return null;
    String name = _connectedDevice!.platformName;
    return name.isNotEmpty ? name : _connectedDevice!.remoteId.str;
  }

  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  final Map<String, ScanResult> _discoveredDevicesMap = {};
  List<ScanResult> get discoveredDevices =>
      _discoveredDevicesMap.values.toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi));

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  bool useAsciiCommands = true;

  // Data streams
  final StreamController<EegDataPacket> _eegDataController =
      StreamController<EegDataPacket>.broadcast();
  Stream<EegDataPacket> get eegDataStream => _eegDataController.stream;

  final StreamController<ButtonEventPacket> _buttonEventController =
      StreamController<ButtonEventPacket>.broadcast();
  Stream<ButtonEventPacket> get buttonEventStream =>
      _buttonEventController.stream;

  final StreamController<StreamStatusPacket> _streamStatusController =
      StreamController<StreamStatusPacket>.broadcast();
  Stream<StreamStatusPacket> get streamStatusStream =>
      _streamStatusController.stream;

  // EEG data buffer
  final List<EegDataPacket> _eegBuffer = [];
  List<EegDataPacket> get eegBuffer => List.unmodifiable(_eegBuffer);
  static const int maxBufferSize = 500;

  // Button events history
  final List<ButtonEventPacket> _buttonEvents = [];
  List<ButtonEventPacket> get buttonEvents =>
      List.unmodifiable(_buttonEvents);
  ButtonEventPacket? _lastButtonEvent;
  ButtonEventPacket? get lastButtonEvent => _lastButtonEvent;

  // Statistics
  int _totalPacketsReceived = 0;
  int get totalPacketsReceived => _totalPacketsReceived;
  int _parseErrors = 0;
  int get parseErrors => _parseErrors;
  int _lastSequenceNumber = -1;
  int _missedPackets = 0;
  int get missedPackets => _missedPackets;

  BleService() {
    _initBle();
  }

  void _initBle() {
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning &&
          _connectionState == BleConnectionState.scanning) {
        _connectionState = BleConnectionState.disconnected;
        notifyListeners();
      }
    });
    FlutterBluePlus.setLogLevel(LogLevel.warning, color: true);
  }

  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every(
      (status) =>
          status == PermissionStatus.granted ||
          status == PermissionStatus.limited,
    );
  }

  Future<bool> isBluetoothOn() async {
    if (await FlutterBluePlus.isSupported == false) return false;
    BluetoothAdapterState state =
        await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  // -- Scanning --
  Future<void> startScan() async {
    bool granted = await requestPermissions();
    if (!granted) {
      debugPrint('BLE permissions not granted');
      return;
    }

    if (!await isBluetoothOn()) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        debugPrint('Could not turn on Bluetooth: $e');
        return;
      }
    }

    _discoveredDevicesMap.clear();
    _connectionState = BleConnectionState.scanning;
    notifyListeners();

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        for (ScanResult result in results) {
          _discoveredDevicesMap[result.device.remoteId.str] = result;
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Scan error: $error');
      },
    );

    try {
      await FlutterBluePlus.startScan(
        withServices: [NeuroGuardUuids.serviceUuid],
        timeout: const Duration(seconds: 15),
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (e) {
      debugPrint('Failed to start scan: $e');
      _connectionState = BleConnectionState.disconnected;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    if (_connectionState == BleConnectionState.scanning) {
      _connectionState = BleConnectionState.disconnected;
      notifyListeners();
    }
  }

  // -- Connection --
  Future<void> connectToDevice(BluetoothDevice device) async {
    await stopScan();

    _connectionState = BleConnectionState.connecting;
    _connectedDevice = device;
    notifyListeners();

    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen(
      (state) async {
        switch (state) {
          case BluetoothConnectionState.connected:
            _connectionState = BleConnectionState.connected;
            notifyListeners();
            await _onDeviceConnected(device);
            break;
          case BluetoothConnectionState.disconnected:
            _handleDisconnect();
            break;
          default:
            break;
        }
      },
      onError: (error) {
        debugPrint('Connection state error: $error');
        _handleDisconnect();
      },
    );

    try {
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
    } catch (e) {
      debugPrint('Failed to connect: $e');
      _handleDisconnect();
    }
  }

  Future<void> _onDeviceConnected(BluetoothDevice device) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await device.requestMtu(247);
        } catch (e) {
          debugPrint('MTU request failed: $e');
        }
      }

      List<BluetoothService> services = await device.discoverServices();

      BluetoothService? neuroService;
      for (var service in services) {
        if (service.uuid == NeuroGuardUuids.serviceUuid) {
          neuroService = service;
          break;
        }
      }

      if (neuroService == null) {
        debugPrint('NeuroGuard service not found!');
        await disconnect();
        return;
      }

      for (var characteristic in neuroService.characteristics) {
        if (characteristic.uuid == NeuroGuardUuids.rxCharUuid) {
          _rxCharacteristic = characteristic;
        } else if (characteristic.uuid == NeuroGuardUuids.txCharUuid) {
          _txCharacteristic = characteristic;
        }
      }

      if (_txCharacteristic == null) {
        debugPrint('TX characteristic not found!');
        await disconnect();
        return;
      }

      await _subscribeToNotifications();
    } catch (e) {
      debugPrint('Error setting up device: $e');
      await disconnect();
    }
  }

  void _handleDisconnect() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _connectionState = BleConnectionState.disconnected;
    _isStreaming = false;
    _connectedDevice = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    _connectionState = BleConnectionState.disconnecting;
    notifyListeners();

    try {
      _notificationSubscription?.cancel();
      _notificationSubscription = null;
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }

    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _connectionState = BleConnectionState.disconnected;
    _isStreaming = false;
    _connectedDevice = null;
    notifyListeners();
  }

  // -- Notifications --
  Future<void> _subscribeToNotifications() async {
    if (_txCharacteristic == null) return;

    try {
      await _txCharacteristic!.setNotifyValue(true);

      _notificationSubscription?.cancel();
      _notificationSubscription =
          _txCharacteristic!.lastValueStream.listen(
        (data) {
          _processIncomingData(data);
        },
        onError: (error) {
          debugPrint('Notification stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to notifications: $e');
    }
  }

  // -- Data Processing --
  void _processIncomingData(List<int> rawData) {
    if (rawData.isEmpty) return;

    _totalPacketsReceived++;

    List<int> bytes = _smartDecode(rawData);

    if (bytes.isEmpty) return;

    int packetTypeId = bytes[0];

    try {
      switch (packetTypeId) {
        case EegDataPacket.packetType:
          final packet = EegDataPacket.fromBytes(bytes);
          _handleEegPacket(packet);
          break;

        case ButtonEventPacket.packetType:
          final packet = ButtonEventPacket.fromBytes(bytes);
          _handleButtonEvent(packet);
          break;

        case StreamStatusPacket.packetType:
          final packet = StreamStatusPacket.fromBytes(bytes);
          _handleStreamStatus(packet);
          break;

        default:
          _parseErrors++;
          break;
      }
    } catch (e) {
      _parseErrors++;
      debugPrint('Parse error: $e');
    }

    notifyListeners();
  }

  List<int> _smartDecode(List<int> rawBytes) {
    bool allAsciiHex = rawBytes.every((b) =>
        (b >= 0x30 && b <= 0x39) ||
        (b >= 0x41 && b <= 0x46) ||
        (b >= 0x61 && b <= 0x66) ||
        b == 0x20);

    if (allAsciiHex && rawBytes.length > 3) {
      String hexStr =
          String.fromCharCodes(rawBytes).replaceAll(' ', '');

      if (hexStr.length % 2 == 0) {
        int decodedLen = hexStr.length ~/ 2;
        if (decodedLen == EegDataPacket.expectedLength ||
            decodedLen == ButtonEventPacket.expectedLength ||
            decodedLen == StreamStatusPacket.expectedLength) {
          try {
            List<int> decoded = [];
            for (int i = 0; i < hexStr.length; i += 2) {
              decoded.add(
                  int.parse(hexStr.substring(i, i + 2), radix: 16));
            }
            return decoded;
          } catch (_) {}
        }
      }
    }

    return rawBytes;
  }

  void _handleEegPacket(EegDataPacket packet) {
    if (_lastSequenceNumber >= 0) {
      int expected = (_lastSequenceNumber + 1) & 0xFFFF;
      if (packet.sequenceNumber != expected) {
        int gap = (packet.sequenceNumber - expected) & 0xFFFF;
        _missedPackets += gap;
      }
    }
    _lastSequenceNumber = packet.sequenceNumber;

    _eegBuffer.add(packet);
    if (_eegBuffer.length > maxBufferSize) {
      _eegBuffer.removeRange(0, _eegBuffer.length - maxBufferSize);
    }

    _eegDataController.add(packet);
  }

  void _handleButtonEvent(ButtonEventPacket packet) {
    _lastButtonEvent = packet;
    _buttonEvents.add(packet);
    if (_buttonEvents.length > 50) {
      _buttonEvents.removeAt(0);
    }
    _buttonEventController.add(packet);
  }

  void _handleStreamStatus(StreamStatusPacket packet) {
    _isStreaming = packet.isStreaming;
    _streamStatusController.add(packet);
  }

  // -- Commands --
  Future<void> sendCommand(List<int> command) async {
    if (_rxCharacteristic == null ||
        _connectionState != BleConnectionState.connected) {
      return;
    }

    try {
      await _rxCharacteristic!.write(command, withoutResponse: false);
    } catch (e) {
      try {
        await _rxCharacteristic!.write(command, withoutResponse: true);
      } catch (e2) {
        debugPrint('All write attempts failed: $e2');
      }
    }
  }

  Future<void> startEegStreaming() async {
    if (useAsciiCommands) {
      await sendCommand(BleCommands.startStreaming);
    } else {
      await sendCommand(BleCommands.startStreamingBinary);
    }
  }

  Future<void> stopEegStreaming() async {
    if (useAsciiCommands) {
      await sendCommand(BleCommands.stopStreaming);
    } else {
      await sendCommand(BleCommands.stopStreamingBinary);
    }
  }

  void clearBuffers() {
    _eegBuffer.clear();
    _buttonEvents.clear();
    _totalPacketsReceived = 0;
    _parseErrors = 0;
    _missedPackets = 0;
    _lastSequenceNumber = -1;
    _lastButtonEvent = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notificationSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _eegDataController.close();
    _buttonEventController.close();
    _streamStatusController.close();
    super.dispose();
  }
}