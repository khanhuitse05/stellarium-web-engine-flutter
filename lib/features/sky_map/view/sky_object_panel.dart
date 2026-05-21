import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlastro_skymap/astro/coordinate_format.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object.dart';

class SkyObjectPanel extends StatelessWidget {
  const SkyObjectPanel({
    required this.object,
    this.onGoto,
    this.onCopyCoordinates,
    super.key,
  });

  final SkyObject object;
  final VoidCallback? onGoto;
  final VoidCallback? onCopyCoordinates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              object.name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'RA ${hourToString(object.raHours)}    '
              'Dec ${formatDeclinationForSd(object.decDeg)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (object.magnitude != null) ...[
              const SizedBox(height: 4),
              Text(
                'Mag ${object.magnitude!.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            if (onGoto != null || onCopyCoordinates != null) ...[
              const SizedBox(height: 12),
              if (onGoto != null)
                FilledButton.icon(
                  onPressed: onGoto,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Goto target'),
                ),
              if (onCopyCoordinates != null) ...[
                if (onGoto != null) const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onCopyCoordinates,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy coordinates'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

String skyObjectCoordinatesText(SkyObject object) {
  return '${object.name}\n'
      'RA ${formatRaHoursForDisplay(object.raHours)}\n'
      'Dec ${formatDecDegreesForDisplay(object.decDeg)}';
}

Future<void> copySkyObjectCoordinates(BuildContext context, SkyObject object) async {
  await Clipboard.setData(
    ClipboardData(text: skyObjectCoordinatesText(object)),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordinates copied')),
    );
  }
}
