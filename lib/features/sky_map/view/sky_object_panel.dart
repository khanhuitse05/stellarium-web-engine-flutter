import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlastro_skymap/astro/coordinate_format.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object_kind.dart';

class SkyObjectPanel extends StatelessWidget {
  const SkyObjectPanel({
    required this.object,
    this.onGoto,
    this.onCopyCoordinates,
    this.onClose,
    this.onMoreDetails,
    super.key,
  });

  final SkyObject object;
  final VoidCallback? onGoto;
  final VoidCallback? onCopyCoordinates;
  final VoidCallback? onClose;
  final VoidCallback? onMoreDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNight = theme.brightness == Brightness.dark &&
        theme.scaffoldBackgroundColor == Colors.black;

    return Material(
      color: isNight
          ? const Color(0xEE1E0505)
          : Colors.black.withValues(alpha: 0.88),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isNight
              ? const Color(0x88FF2222)
              : Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _KindBadge(kind: object.kind, isNight: isNight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    object.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isNight ? const Color(0xFFFF6666) : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (object.constellation != null &&
                    object.constellation!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      object.constellation!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (onClose != null)
                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: onClose,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'RA ${hourToString(object.raHours)}  ·  Dec ${formatDeclinationForSd(object.decDeg)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                if (object.magnitude != null)
                  Text(
                    'Mag ${object.magnitude!.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: isNight ? Colors.redAccent : Colors.amberAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (object.altDeg != null && object.azDeg != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    object.isAboveHorizon
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 12,
                    color:
                        object.isAboveHorizon ? Colors.greenAccent : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Alt ${object.altDeg! >= 0 ? '+' : ''}${object.altDeg!.toStringAsFixed(1)}°  ·  '
                    'Az ${object.azDeg!.toStringAsFixed(1)}° (${object.compassDirection})',
                    style: TextStyle(
                      color: object.isAboveHorizon
                          ? Colors.white70
                          : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    object.isAboveHorizon ? 'Visible' : 'Below horizon',
                    style: TextStyle(
                      color: object.isAboveHorizon
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (onMoreDetails != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: isNight
                              ? Colors.red.withValues(alpha: 0.5)
                              : Colors.white24,
                        ),
                        foregroundColor:
                            isNight ? const Color(0xFFFF8888) : Colors.white,
                      ),
                      onPressed: onMoreDetails,
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Details',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                if (onMoreDetails != null &&
                    (onGoto != null || onCopyCoordinates != null))
                  const SizedBox(width: 8),
                if (onCopyCoordinates != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: isNight
                              ? Colors.red.withValues(alpha: 0.5)
                              : Colors.white24,
                        ),
                        foregroundColor:
                            isNight ? const Color(0xFFFF8888) : Colors.white,
                      ),
                      onPressed: onCopyCoordinates,
                      icon: const Icon(Icons.copy, size: 16),
                      label:
                          const Text('Copy', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                if (onGoto != null &&
                    (onMoreDetails != null || onCopyCoordinates != null))
                  const SizedBox(width: 8),
                if (onGoto != null)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: isNight
                            ? const Color(0xFFCC1111)
                            : Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: onGoto,
                      icon: const Icon(Icons.navigation, size: 16),
                      label:
                          const Text('Goto', style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind, required this.isNight});

  final SkyObjectKind kind;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (kind) {
      SkyObjectKind.planet => (
          Icons.public,
          isNight ? Colors.redAccent : Colors.orangeAccent,
          'PLANET'
        ),
      SkyObjectKind.moon => (
          Icons.nightlight_round,
          isNight ? Colors.redAccent : Colors.amberAccent,
          'MOON'
        ),
      SkyObjectKind.sun => (
          Icons.wb_sunny,
          isNight ? Colors.redAccent : Colors.yellowAccent,
          'SUN'
        ),
      SkyObjectKind.messier => (
          Icons.blur_circular,
          isNight ? Colors.redAccent : Colors.cyanAccent,
          'MESSIER'
        ),
      SkyObjectKind.caldwell || SkyObjectKind.dso => (
          Icons.flare,
          isNight ? Colors.redAccent : Colors.purpleAccent,
          'DSO'
        ),
      SkyObjectKind.constellation => (
          Icons.auto_awesome,
          isNight ? Colors.redAccent : Colors.tealAccent,
          'CONST'
        ),
      _ => (
          Icons.star,
          isNight ? Colors.redAccent : Colors.blueAccent,
          'STAR'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

String skyObjectCoordinatesText(SkyObject object) {
  final altAz = (object.altDeg != null && object.azDeg != null)
      ? '\nAlt ${object.altDeg!.toStringAsFixed(2)}°  Az ${object.azDeg!.toStringAsFixed(2)}°'
      : '';
  return '${object.name}\n'
      'RA ${formatRaHoursForDisplay(object.raHours)}\n'
      'Dec ${formatDecDegreesForDisplay(object.decDeg)}'
      '$altAz';
}

Future<void> copySkyObjectCoordinates(
  BuildContext context,
  SkyObject object,
) async {
  await Clipboard.setData(
    ClipboardData(text: skyObjectCoordinatesText(object)),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coordinates for ${object.name} copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
