import 'package:flutter/material.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

class ExpandedObjectDetailSheet extends StatelessWidget {
  const ExpandedObjectDetailSheet({
    required this.object,
    this.onCenterOnObject,
    this.onSimulateGoto,
    this.isNight = false,
    super.key,
  });

  final SkyObject object;
  final VoidCallback? onCenterOnObject;
  final VoidCallback? onSimulateGoto;
  final bool isNight;

  static Future<void> show(
    BuildContext context, {
    required SkyObject object,
    VoidCallback? onCenterOnObject,
    VoidCallback? onSimulateGoto,
    bool isNight = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpandedObjectDetailSheet(
        object: object,
        onCenterOnObject: onCenterOnObject,
        onSimulateGoto: onSimulateGoto,
        isNight: isNight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isNight ? const Color(0xFF160202) : const Color(0xFF131722),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isNight ? const Color(0xFF661111) : Colors.white12,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      object.name,
                      style: TextStyle(
                        color: isNight ? const Color(0xFFFF8888) : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (object.id != object.name)
                      Text(
                        'Catalog ID: ${object.id}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white60),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Coordinates grid cards
          Row(
            children: [
              Expanded(
                child: _buildDataCard(
                  title: 'EQUATORIAL (J2000)',
                  items: [
                    'RA: ${hourToString(object.raHours)}',
                    'Dec: ${formatDeclinationForSd(object.decDeg)}',
                    'RA Deg: ${(object.raHours * 15).toStringAsFixed(2)}°',
                  ],
                  isNight: isNight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDataCard(
                  title: 'HORIZONTAL (LOCAL)',
                  items: [
                    if (object.altDeg != null)
                      'Alt: ${object.altDeg! >= 0 ? '+' : ''}${object.altDeg!.toStringAsFixed(2)}°',
                    if (object.azDeg != null)
                      'Az: ${object.azDeg!.toStringAsFixed(2)}° (${object.compassDirection})',
                    'Status: ${object.isAboveHorizon ? 'Visible' : 'Below horizon'}',
                  ],
                  statusColor: object.isAboveHorizon
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  isNight: isNight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Astrophysics card
          _buildDataCard(
            title: 'OBSERVATIONAL PROPERTIES',
            items: [
              if (object.magnitude != null)
                'Visual Magnitude (Vmag): ${object.magnitude!.toStringAsFixed(2)}',
              if (object.constellation != null &&
                  object.constellation!.isNotEmpty)
                'Constellation: ${object.constellation}',
              if (object.typeDescription != null &&
                  object.typeDescription!.isNotEmpty)
                'Morphology / Classification: ${object.typeDescription}',
              if (object.distance != null)
                'Distance: ${object.distance!.toStringAsFixed(1)} ly',
              if (object.aliases.isNotEmpty)
                'Designations: ${object.aliases.take(6).join(', ')}',
            ],
            isNight: isNight,
          ),
          const SizedBox(height: 18),
          // Action Buttons
          Row(
            children: [
              if (onCenterOnObject != null)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isNight ? Colors.redAccent : Colors.white24,
                      ),
                      foregroundColor:
                          isNight ? const Color(0xFFFF8888) : Colors.white,
                    ),
                    icon: const Icon(Icons.filter_center_focus, size: 18),
                    label: const Text('Center'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCenterOnObject!();
                    },
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: isNight ? Colors.redAccent : Colors.white24,
                    ),
                    foregroundColor:
                        isNight ? const Color(0xFFFF8888) : Colors.white,
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                  onPressed: () => copySkyObjectCoordinates(context, object),
                ),
              ),
              if (onSimulateGoto != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: isNight
                          ? const Color(0xFFCC1111)
                          : Theme.of(context).colorScheme.primary,
                    ),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('GOTO Mount'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSimulateGoto!();
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required String title,
    required List<String> items,
    Color? statusColor,
    required bool isNight,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNight
            ? const Color(0x33FF0000)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNight ? const Color(0x44FF2222) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isNight ? Colors.redAccent : Colors.lightBlueAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                item,
                style: TextStyle(
                  color: item.startsWith('Status:') && statusColor != null
                      ? statusColor
                      : Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
