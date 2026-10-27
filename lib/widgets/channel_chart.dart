import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/eeg_data_packet.dart';
import '../theme/app_colors.dart';

class ChannelChart extends StatelessWidget {
  final int channelIndex;
  final List<EegDataPacket> eegBuffer;
  final bool showDetails;

  const ChannelChart({
    super.key,
    required this.channelIndex,
    required this.eegBuffer,
    this.showDetails = false,
  });

  static const List<String> channelLabels = [
    'CH1',
    'CH2',
    'CH3',
    'CH4',
  ];

  @override
  Widget build(BuildContext context) {
    final color = AppColors.channelColors[channelIndex];
    final spots = _buildSpots();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    channelLabels[channelIndex],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (spots.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      '${spots.last.y.toInt()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: spots.isEmpty
                  ? const Center(
                      child: Text(
                        'No data',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: showDetails,
                          drawVerticalLine: false,
                          horizontalInterval: 1000,
                          getDrawingHorizontalLine: (value) => const FlLine(
                            color: AppColors.borderLight,
                            strokeWidth: 0.5,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: showDetails,
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: showDetails,
                              reservedSize: 45,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
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
                            bottom: BorderSide(
                              color: AppColors.borderLight,
                              width: 0.5,
                            ),
                            left: BorderSide(
                              color: AppColors.borderLight,
                              width: 0.5,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            curveSmoothness: 0.2,
                            color: color,
                            barWidth: showDetails ? 2 : 1.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: color.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: showDetails,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => AppColors.textNavy.withValues(alpha: 0.9),
                            getTooltipItems: (spots) {
                              return spots
                                  .map(
                                    (spot) => LineTooltipItem(
                                      'Seq: ${spot.x.toInt()}\nValue: ${spot.y.toInt()}',
                                      TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                  .toList();
                            },
                          ),
                        ),
                      ),
                      duration: const Duration(milliseconds: 0),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    if (eegBuffer.isEmpty) return [];

    List<FlSpot> spots = [];
    int startIdx = eegBuffer.length > 200 ? eegBuffer.length - 200 : 0;

    for (int i = startIdx; i < eegBuffer.length; i++) {
      final packet = eegBuffer[i];
      double x1 = (packet.sequenceNumber * 2).toDouble();
      double x2 = (packet.sequenceNumber * 2 + 1).toDouble();

      spots.add(FlSpot(
        x1,
        packet.sample1.getChannel(channelIndex).toDouble(),
      ));
      spots.add(FlSpot(
        x2,
        packet.sample2.getChannel(channelIndex).toDouble(),
      ));
    }

    return spots;
  }
}
