import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ChannelToggleButtons extends StatelessWidget {
  final List<bool> activeChannels;
  final Function(int index) onToggle;

  const ChannelToggleButtons({
    super.key,
    required this.activeChannels,
    required this.onToggle,
  });

  static const List<String> channelNames = ['CH1', 'CH2', 'CH3', 'CH4'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(4, (index) {
          bool isActive = activeChannels[index];
          Color color = AppColors.channelColors[index];

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onToggle(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.1) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? color : AppColors.borderLight,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: isActive ? color : AppColors.inactive.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        channelNames[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? color : AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}