import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, bleService, _) {
        if (bleService.connectionState == BleConnectionState.connected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
              _navigateBack();
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to Dashboard',
              onPressed: _navigateBack,
            ),
            title: const Text(
              'Connect Device',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),
              _buildStatusHeader(bleService),
              const SizedBox(height: 24),
              _buildScanButton(bleService),
              const SizedBox(height: 24),
              Expanded(child: _buildDeviceList(bleService)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(BleService bleService) {
    IconData icon;
    String text;
    Color color;

    switch (bleService.connectionState) {
      case BleConnectionState.scanning:
        icon = Icons.bluetooth_searching;
        text = 'Scanning for NeuroGuard devices...';
        color = AppColors.primaryBlue;
        break;
      case BleConnectionState.connecting:
        icon = Icons.bluetooth_connected;
        text = 'Connecting to ${bleService.connectedDeviceName}...';
        color = AppColors.warning;
        break;
      case BleConnectionState.connected:
        icon = Icons.check_circle;
        text = 'Connected to ${bleService.connectedDeviceName}!';
        color = AppColors.success;
        break;
      default:
        icon = Icons.bluetooth;
        text = 'Tap scan to find devices';
        color = AppColors.inactive;
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        double opacity = bleService.connectionState == BleConnectionState.scanning
            ? 0.5 + (_pulseController.value * 0.5)
            : 1.0;

        return Opacity(
          opacity: opacity,
          child: Column(
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanButton(BleService bleService) {
    bool isScanning = bleService.connectionState == BleConnectionState.scanning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: bleService.connectionState == BleConnectionState.connecting
              ? null
              : isScanning
                  ? bleService.stopScan
                  : bleService.startScan,
          icon: isScanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.search),
          label: Text(
            isScanning ? 'Stop Scan' : 'Scan for Devices',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isScanning ? AppColors.error : AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList(BleService bleService) {
    if (bleService.discoveredDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.devices, size: 48, color: AppColors.inactive),
            const SizedBox(height: 12),
            Text(
              bleService.connectionState == BleConnectionState.scanning
                  ? 'Searching...'
                  : 'No devices found yet',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make sure your ESP32 is powered on',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: bleService.discoveredDevices.length,
      itemBuilder: (context, index) {
        final scanResult = bleService.discoveredDevices[index];
        return _buildDeviceCard(scanResult, bleService);
      },
    );
  }

  Widget _buildDeviceCard(ScanResult scanResult, BleService bleService) {
    final device = scanResult.device;
    String name = device.platformName.isNotEmpty
        ? device.platformName
        : (scanResult.advertisementData.advName.isNotEmpty
            ? scanResult.advertisementData.advName
            : 'Unknown Device');
    int rssi = scanResult.rssi;

    Color signalColor;
    IconData signalIcon;
    if (rssi > -60) {
      signalColor = AppColors.success;
      signalIcon = Icons.signal_cellular_4_bar;
    } else if (rssi > -80) {
      signalColor = AppColors.warning;
      signalIcon = Icons.signal_cellular_alt_2_bar;
    } else {
      signalColor = AppColors.error;
      signalIcon = Icons.signal_cellular_alt_1_bar;
    }

    bool isConnecting =
        bleService.connectionState == BleConnectionState.connecting &&
            bleService.connectedDeviceId == device.remoteId.str;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.memory, color: AppColors.primaryBlue),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textNavy,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              device.remoteId.str,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(signalIcon, size: 14, color: signalColor),
                const SizedBox(width: 4),
                Text(
                  '$rssi dBm',
                  style: TextStyle(
                    fontSize: 12,
                    color: signalColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isConnecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              )
            : const Icon(Icons.chevron_right, color: AppColors.primaryBlue),
        onTap: isConnecting ? null : () => bleService.connectToDevice(device),
      ),
    );
  }
}
