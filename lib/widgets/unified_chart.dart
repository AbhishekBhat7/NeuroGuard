import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/eeg_data_packet.dart';
import '../theme/app_colors.dart';

class UnifiedChart extends StatelessWidget {
  final List<EegDataPacket> eegBuffer;
  final List<bool> activeChannels;
  final bool showDetails;

  const UnifiedChart({
    super.key,
    required this.eegBuffer,
    required this.activeChannels,
    this.showDetails = false,
  });

  static const List<String> channelLabels = ['CH1', 'CH2', 'CH3', 'CH4'];

  @override
  Widget build(BuildContext context) {
    List<LineChartBarData> lineBars = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    double minX = double.infinity;
    double maxX = double.negativeInfinity;

    for (int ch = 0; ch < 4; ch++) {
      if (!activeChannels[ch]) continue;

      final spots = _buildSpotsForChannel(ch);
      if (spots.isEmpty) continue;

      for (var spot in spots) {
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
        if (spot.x < minX) minX = spot.x;
        if (spot.x > maxX) maxX = spot.x;
      }

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.15,
          color: AppColors.channelColors[ch],
          barWidth: showDetails ? 2.5 : 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    if (lineBars.isEmpty) {
      return const Card(
        child: Center(
          child: Text(
            'Select a channel to display',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    double yRange = maxY - minY;
    if (yRange < 10) yRange = 10;
    double yPadding = yRange * 0.1;
    minY -= yPadding;
    maxY += yPadding;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
        child: Column(
          children: [
            _buildLegend(),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: minX,
                  maxX: maxX,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: showDetails,
                    horizontalInterval: _calculateInterval(yRange),
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: AppColors.borderLight,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => const FlLine(
                      color: AppColors.borderLight,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: _calculateInterval(yRange),
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: showDetails,
                        reservedSize: 22,
                        interval: (maxX - minX) / 5,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            (value ~/ 2).toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.borderLight, width: 1),
                      left: BorderSide(color: AppColors.borderLight, width: 1),
                    ),
                  ),
                  lineBarsData: lineBars,
                  lineTouchData: LineTouchData(
                    enabled: showDetails,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.textNavy.withValues(alpha: 0.9),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          int actualCh = _getActualChannelIndex(spot.barIndex);
                          return LineTooltipItem(
                            '${channelLabels[actualCh]}\nVal: ${spot.y.toInt()}',
                            TextStyle(
                              color: AppColors.channelColors[actualCh],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getActualChannelIndex(int barIndex) {
    int count = 0;
    for (int i = 0; i < 4; i++) {
      if (activeChannels[i]) {
        if (count == barIndex) return i;
        count++;
      }
    }
    return 0;
  }

  Widget _buildLegend() {
    List<Widget> legendItems = [];
    for (int ch = 0; ch < 4; ch++) {
      if (!activeChannels[ch]) continue;
      String latestValue = eegBuffer.isNotEmpty
          ? eegBuffer.last.sample2.getChannel(ch).toString()
          : '--';

      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.channelColors[ch],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'CH${ch + 1}: $latestValue',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: legendItems),
    );
  }

  List<FlSpot> _buildSpotsForChannel(int channelIndex) {
    if (eegBuffer.isEmpty) return [];
    List<FlSpot> spots = [];
    int startIdx = eegBuffer.length > 200 ? eegBuffer.length - 200 : 0;

    for (int i = startIdx; i < eegBuffer.length; i++) {
      final packet = eegBuffer[i];
      spots.add(FlSpot(
        (packet.sequenceNumber * 2).toDouble(),
        packet.sample1.getChannel(channelIndex).toDouble(),
      ));
      spots.add(FlSpot(
        (packet.sequenceNumber * 2 + 1).toDouble(),
        packet.sample2.getChannel(channelIndex).toDouble(),
      ));
    }
    return spots;
  }

  double _calculateInterval(double range) {
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    if (range <= 500) return 100;
    if (range <= 1000) return 200;
    if (range <= 2000) return 500;
    return 1000;
  }
}

