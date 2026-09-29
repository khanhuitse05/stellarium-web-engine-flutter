import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlastro_skymap/astro/coordinate_format.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object_kind.dart';

class SkyObjectPanel extends StatefulWidget {
  const SkyObjectPanel({
    required this.object,
    this.onGoto,
    this.onSync,
    this.onCopyCoordinates,
    this.onClose,
    this.onMoreDetails,
    this.isSlewing = false,
    this.onStop,
    this.slewProgressText,
    this.expandedBuilder,
    super.key,
  });

  final SkyObject object;
  final VoidCallback? onGoto;
  final VoidCallback? onSync;
  final VoidCallback? onCopyCoordinates;
  final VoidCallback? onClose;
  final VoidCallback? onMoreDetails;
  final bool isSlewing;
  final VoidCallback? onStop;
  final String? slewProgressText;
  final Widget Function(BuildContext context, SkyObject object)? expandedBuilder;

  @override
  State<SkyObjectPanel> createState() => _SkyObjectPanelState();
}

class _SkyObjectPanelState extends State<SkyObjectPanel> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant SkyObjectPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.object.id != widget.object.id) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNight = theme.brightness == Brightness.dark &&
        theme.scaffoldBackgroundColor == Colors.black;
    final object = widget.object;
    final isSlewing = widget.isSlewing;
    final onStop = widget.onStop;
    final slewProgressText = widget.slewProgressText;
    final onClose = widget.onClose;
    final onGoto = widget.onGoto;
    final onSync = widget.onSync;
    final onCopyCoordinates = widget.onCopyCoordinates;
    final onMoreDetails = widget.onMoreDetails;
    final hasDetails = widget.expandedBuilder != null || widget.onMoreDetails != null;

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
                if (isSlewing)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.amberAccent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          slewProgressText != null
                              ? 'SLEWING $slewProgressText'
                              : 'SLEWING',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
            if (_expanded && widget.expandedBuilder != null) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: SingleChildScrollView(
                  child: widget.expandedBuilder!(context, object),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (hasDetails)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: isNight
                              ? Colors.red.withValues(alpha: 0.5)
                              : (_expanded ? Colors.cyanAccent.withValues(alpha: 0.6) : Colors.white24),
                        ),
                        foregroundColor: isNight
                            ? const Color(0xFFFF8888)
                            : (_expanded ? Colors.cyanAccent : Colors.white),
                      ),
                      onPressed: () {
                        if (widget.expandedBuilder != null) {
                          setState(() => _expanded = !_expanded);
                        } else {
                          widget.onMoreDetails?.call();
                        }
                      },
                      icon: Icon(
                        _expanded ? Icons.expand_less_rounded : Icons.info_outline_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _expanded ? 'Less' : 'Details',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                if (hasDetails &&
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
                if (onSync != null && !isSlewing) ...[
                  if (onMoreDetails != null || onCopyCoordinates != null)
                    const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: isNight
                              ? Colors.amber.withValues(alpha: 0.6)
                              : Colors.amberAccent.withValues(alpha: 0.6),
                        ),
                        foregroundColor: isNight
                            ? const Color(0xFFFFCC66)
                            : Colors.amberAccent,
                      ),
                      onPressed: onSync,
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text('Sync', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
                if (isSlewing && onStop != null) ...[
                  if (onMoreDetails != null || onCopyCoordinates != null)
                    const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onStop,
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: Text(
                        slewProgressText != null
                            ? 'STOP ($slewProgressText)'
                            : 'STOP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ] else if (onGoto != null) ...[
                  if (onMoreDetails != null ||
                      onCopyCoordinates != null ||
                      (onSync != null && !isSlewing))
                    const SizedBox(width: 8),
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
                ]
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
