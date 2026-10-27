import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../theme/app_colors.dart';
import '../widgets/unified_chart.dart';
import '../widgets/channel_toggle_buttons.dart';

class EegChartScreen extends StatefulWidget {
  final List<bool> initialActiveChannels;

  const EegChartScreen({
    super.key,
    required this.initialActiveChannels,
  });

  @override
  State<EegChartScreen> createState() => _EegChartScreenState();
}

class _EegChartScreenState extends State<EegChartScreen> {
  Timer? _refreshTimer;
  late List<bool> _activeChannels;

  @override
  void initState() {
    super.initState();
    _activeChannels = List<bool>.from(widget.initialActiveChannels);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _refreshTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, bleService, _) {
        bool isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return Scaffold(
          appBar: isLandscape
              ? null
              : AppBar(
                  title: const Text('EEG Live View'),
                  actions: [
                    if (bleService.eegBuffer.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(
                          child: Text(
                            'Seq: ${bleService.eegBuffer.last.sequenceNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
          body: bleService.eegBuffer.isEmpty
              ? const Center(
                  child: Text(
                    'No EEG data available',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : Column(
                  children: [
                    if (!isLandscape) ...[
                      const SizedBox(height: 8),
                      ChannelToggleButtons(
                        activeChannels: _activeChannels,
                        onToggle: (index) {
                          setState(() {
                            _activeChannels[index] = !_activeChannels[index];
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(isLandscape ? 4 : 8),
                        child: UnifiedChart(
                          eegBuffer: bleService.eegBuffer,
                          activeChannels: _activeChannels,
                          showDetails: true,
                        ),
                      ),
                    ),
                    if (isLandscape) _buildLandscapeControls(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLandscapeControls() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.primaryBlue),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          ...List.generate(4, (index) {
            final color = AppColors.channelColors[index];
            bool isActive = _activeChannels[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _activeChannels[index] = !_activeChannels[index];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.12) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? color : AppColors.borderLight,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'CH${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? color : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
