import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

class TimeMachineDock extends StatelessWidget {
  const TimeMachineDock({required this.cubit, super.key});

  final SkyMapCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SkyMapCubit, SkyMapState>(
      buildWhen: (prev, next) =>
          prev.utc != next.utc ||
          prev.timeMultiplier != next.timeMultiplier ||
          prev.isTimePaused != next.isTimePaused ||
          prev.config.nightMode != next.config.nightMode,
      builder: (context, state) {
        final isNight = state.config.nightMode;
        final utc = state.utc;

        final dateStr =
            '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';
        final timeStr =
            '${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}:${utc.second.toString().padLeft(2, '0')} UTC';

        return Material(
          color: isNight
              ? const Color(0xEE1A0404)
              : Colors.black.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isNight
                  ? const Color(0x66FF2222)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Play / Pause
                IconButton(
                  tooltip: state.isTimePaused ? 'Resume time' : 'Pause time',
                  icon: Icon(
                    state.isTimePaused ? Icons.play_arrow : Icons.pause,
                    color: isNight ? Colors.redAccent : Colors.cyanAccent,
                    size: 22,
                  ),
                  onPressed: () => cubit.toggleTimePause(),
                ),
                const SizedBox(width: 4),
                // Time Display & Picker trigger
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _pickDateTime(context, state.utc),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: isNight ? const Color(0xFFFF7777) : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Speed indicator popup menu
                PopupMenuButton<double>(
                  tooltip: 'Simulation speed',
                  initialValue: state.timeMultiplier,
                  color: isNight ? const Color(0xFF220505) : const Color(0xFF1E222D),
                  itemBuilder: (context) => [
                    _buildSpeedItem(1.0, '1x (Real-time)', isNight),
                    _buildSpeedItem(10.0, '10x Speed', isNight),
                    _buildSpeedItem(60.0, '60x (1 min/sec)', isNight),
                    _buildSpeedItem(300.0, '300x (5 min/sec)', isNight),
                  ],
                  onSelected: (speed) => cubit.setTimeRate(speed),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isNight
                          ? const Color(0x33FF0000)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${state.timeMultiplier.toStringAsFixed(0)}x',
                      style: TextStyle(
                        color: isNight ? Colors.redAccent : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Quick jump to Now
                IconButton(
                  tooltip: 'Jump to current time',
                  icon: const Icon(Icons.replay, size: 18),
                  color: Colors.white70,
                  onPressed: () => cubit.resetTimeToNow(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<double> _buildSpeedItem(
    double speed,
    String label,
    bool isNight,
  ) {
    return PopupMenuItem<double>(
      value: speed,
      child: Text(
        label,
        style: TextStyle(
          color: isNight ? const Color(0xFFFF9999) : Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context, DateTime currentUtc) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentUtc.toLocal(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentUtc.toLocal()),
    );
    if (pickedTime == null || !context.mounted) return;

    final local = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    await cubit.setTime(local.toUtc());
  }
}
