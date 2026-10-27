import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/ble_service.dart';
import '../services/database_service.dart';
import '../services/alert_service.dart';
import '../models/eeg_data_packet.dart';
import '../models/button_event_packet.dart';
import '../models/user_profile.dart';
import '../widgets/unified_chart.dart';
import '../widgets/channel_toggle_buttons.dart';
import '../widgets/profile_tab.dart';
import 'eeg_chart_screen.dart';
import 'scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<EegDataPacket>? _eegSub;
  StreamSubscription<ButtonEventPacket>? _buttonSub;
  Timer? _uiRefreshTimer;
  bool _needsRefresh = false;

  final List<bool> _activeChannels = [true, true, true, true];
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final bleService = context.read<BleService>();

    _loadInitialProfile();

    _eegSub = bleService.eegDataStream.listen((_) {
      _needsRefresh = true;
    });

    _buttonSub = bleService.buttonEventStream.listen((event) {
      _needsRefresh = true;
      if (event.isPressed && mounted) {
        _handleButtonAlert(event);
      }
    });

    _uiRefreshTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (_needsRefresh && mounted) {
        setState(() {});
        _needsRefresh = false;
      }
    });
  }

  Future<void> _loadInitialProfile() async {
    final profile = await DatabaseService.instance.getProfile();
    if (mounted) {
      setState(() {
        _currentProfile = profile;
      });
    }
  }

  @override
  void dispose() {
    _eegSub?.cancel();
    _buttonSub?.cancel();
    _uiRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  /// Handles physical button press:
  /// 1. Determines Abnormality Type (Button 1: Epilepsy Signal, Else: Seizure signal)
  /// 2. Sends alert to Azure API with profile details
  /// 3. Displays on-screen notification dialog
  Future<void> _handleButtonAlert(ButtonEventPacket event) async {
    final profile = _currentProfile ?? await DatabaseService.instance.getProfile();
    _currentProfile = profile;

    final String disease = AlertService.getDiseaseForButton(event.buttonId);

    _showEmergencyNotification(event, profile, disease);
  }

  void _showEmergencyNotification(
    ButtonEventPacket event,
    UserProfile profile,
    String disease,
  ) {
    bool isSending = true;
    AlertResult? alertResult;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            if (isSending && alertResult == null) {
              AlertService.sendAbnormalityAlert(
                profile: profile,
                buttonId: event.buttonId,
              ).then((result) {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    isSending = false;
                    alertResult = result;
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppColors.error, width: 2),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 44,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Abnormality Detected!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error, width: 1.2),
                    ),
                    child: Text(
                      disease.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Text(
                  //   'Triggered by ${event.buttonName} (${event.gpioPin})',
                  //   style: const TextStyle(
                  //     fontSize: 13,
                  //     color: AppColors.textSecondary,
                  //   ),
                  // ),
                  const Divider(color: AppColors.borderLight, height: 24),
                  _infoTextRow('Patient', profile.patientName),
                  const SizedBox(height: 4),
                  _infoTextRow('Location', profile.patientLocation),
                  const SizedBox(height: 4),
                  _infoTextRow('Caretaker', profile.caretakerEmail),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSending
                          ? AppColors.primaryBlue.withValues(alpha: 0.08)
                          : (alertResult?.success ?? false)
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSending) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: Text(
                              'Sending alert to caretaker API...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ] else if (alertResult?.success ?? false) ...[
                          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Caretaker notified successfully!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              alertResult?.message ?? 'Failed to send alert',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoTextRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textNavy,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, bleService, _) {
        return Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset(
                'assets/images/neuroguardlogo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.psychology,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            title: const Text(
              'NeuroGuard',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              _buildBleButton(bleService),
              _buildStreamToggle(bleService),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryBlue,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.show_chart), text: 'EEG Live Graph'),
                Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildEegTab(bleService),
              ProfileTab(
                onProfileUpdated: (updated) {
                  setState(() {
                    _currentProfile = updated;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// BLE Icon in the AppBar:
  /// - Disconnected: Clicking navigates directly to ScanScreen
  /// - Connecting / Scanning: Shows searching icon with status indicator
  /// - Connected: Shows connected icon (green), clicking shows device info & options
  Widget _buildBleButton(BleService bleService) {
    final isConnected = bleService.connectionState == BleConnectionState.connected;
    final isConnecting = bleService.connectionState == BleConnectionState.connecting;
    final isScanning = bleService.connectionState == BleConnectionState.scanning;

    IconData icon;
    Color iconColor;
    String tooltip;

    if (isConnected) {
      icon = Icons.bluetooth_connected;
      iconColor = AppColors.success;
      tooltip = 'Connected: ${bleService.connectedDeviceName}';
    } else if (isConnecting) {
      icon = Icons.bluetooth_searching;
      iconColor = AppColors.warning;
      tooltip = 'Connecting...';
    } else if (isScanning) {
      icon = Icons.bluetooth_searching;
      iconColor = AppColors.primaryBlue;
      tooltip = 'Scanning for devices...';
    } else {
      icon = Icons.bluetooth;
      iconColor = AppColors.primaryBlue;
      tooltip = 'Connect Bluetooth Device';
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(icon, color: iconColor, size: 26),
          tooltip: tooltip,
          onPressed: () {
            if (isConnected) {
              _showConnectedDeviceSheet(bleService);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
            }
          },
        ),
        if (isConnected)
          Positioned(
            right: 8,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  void _showConnectedDeviceSheet(BleService bleService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bluetooth_connected,
                        color: AppColors.success,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bleService.connectedDeviceName ?? 'Connected Device',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textNavy,
                            ),
                          ),
                          Text(
                            bleService.connectedDeviceId ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'CONNECTED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ScanScreen()),
                          );
                        },
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Scan Devices'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          bleService.disconnect();
                        },
                        icon: const Icon(Icons.bluetooth_disabled, size: 18),
                        label: const Text('Disconnect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreamToggle(BleService bleService) {
    final isConnected = bleService.connectionState == BleConnectionState.connected;

    return IconButton(
      onPressed: isConnected
          ? () {
              if (bleService.isStreaming) {
                bleService.stopEegStreaming();
              } else {
                bleService.startEegStreaming();
              }
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please connect your Bluetooth device first'),
                  action: SnackBarAction(
                    label: 'Connect',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanScreen()),
                      );
                    },
                  ),
                  backgroundColor: AppColors.primaryBlue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
      icon: Icon(
        bleService.isStreaming ? Icons.pause_circle : Icons.play_circle,
        size: 32,
        color: bleService.isStreaming
            ? AppColors.error
            : (isConnected ? AppColors.primaryBlue : AppColors.inactive),
      ),
    );
  }

  Widget _buildEegTab(BleService bleService) {
    final isConnected = bleService.connectionState == BleConnectionState.connected;

    if (bleService.eegBuffer.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                bleService.isStreaming
                    ? Icons.hourglass_top
                    : (isConnected ? Icons.play_arrow : Icons.bluetooth_searching),
                size: 64,
                color: isConnected ? AppColors.primaryBlue : AppColors.inactive,
              ),
              const SizedBox(height: 16),
              Text(
                bleService.isStreaming
                    ? 'Waiting for EEG signals...'
                    : (isConnected
                        ? 'Press Play to start capturing'
                        : 'No Bluetooth device connected'),
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (!isConnected) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                  },
                  icon: const Icon(Icons.bluetooth, size: 20),
                  label: const Text('Connect ESP32 Device'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        ChannelToggleButtons(
          activeChannels: _activeChannels,
          onToggle: (index) {
            setState(() {
              _activeChannels[index] = !_activeChannels[index];
            });
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EegChartScreen(
                    initialActiveChannels: List<bool>.from(_activeChannels),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: UnifiedChart(
                eegBuffer: bleService.eegBuffer,
                activeChannels: _activeChannels,
                showDetails: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
