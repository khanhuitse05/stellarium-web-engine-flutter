import 'package:flutter/material.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';
import '../models/observatory_preset.dart';

class LocationSelectorDialog extends StatelessWidget {
  const LocationSelectorDialog({required this.cubit, super.key});

  final SkyMapCubit cubit;

  static Future<void> show(BuildContext context, {required SkyMapCubit cubit}) {
    return showDialog(
      context: context,
      builder: (_) => LocationSelectorDialog(cubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = cubit.state;
    final isNight = state.config.nightMode;

    return AlertDialog(
      backgroundColor:
          isNight ? const Color(0xFF190303) : const Color(0xFF131722),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isNight ? const Color(0xFF661111) : Colors.white12,
        ),
      ),
      title: Row(
        children: [
          Icon(
            Icons.location_on,
            color: isNight ? Colors.redAccent : Colors.tealAccent,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            'Observer Location',
            style: TextStyle(
              color: isNight ? const Color(0xFFFF9999) : Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isNight
                    ? const Color(0x33FF0000)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.my_location,
                    size: 20,
                    color: isNight ? Colors.redAccent : Colors.lightBlueAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Coordinates',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          '${state.observerLat.toStringAsFixed(4)}° Lat · ${state.observerLonEast.toStringAsFixed(4)}° Lon',
                          style: TextStyle(
                            color: isNight
                                ? const Color(0xFFFF8888)
                                : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'WORLD OBSERVATORIES & PRESETS',
              style: TextStyle(
                color: isNight ? Colors.redAccent : Colors.lightBlueAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            ...ObservatoryPreset.presets.map((p) {
              final isCurrent =
                  (state.observerLat - p.latitude).abs() < 0.01 &&
                  (state.observerLonEast - p.longitudeEast).abs() < 0.01;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: isCurrent
                      ? (isNight
                          ? const Color(0x44FF2222)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2))
                      : (isNight
                          ? const Color(0x22FF0000)
                          : Colors.white.withValues(alpha: 0.03)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: isCurrent
                        ? BorderSide(
                            color: isNight
                                ? Colors.redAccent
                                : Theme.of(context).colorScheme.primary,
                          )
                        : BorderSide.none,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                  dense: true,
                  title: Text(
                    p.name,
                    style: TextStyle(
                      color: isNight ? const Color(0xFFFFCCCC) : Colors.white,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${p.locationName} (${p.latitude.toStringAsFixed(2)}°, ${p.longitudeEast.toStringAsFixed(2)}°) · ${p.elevationMeters}m',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  trailing: isCurrent
                      ? Icon(
                          Icons.check_circle,
                          color:
                              isNight ? Colors.redAccent : Colors.lightGreenAccent,
                          size: 18,
                        )
                      : null,
                  onTap: () {
                    cubit.setObserverLocation(
                      lat: p.latitude,
                      lonEast: p.longitudeEast,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: TextStyle(
              color: isNight ? Colors.redAccent : Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}
