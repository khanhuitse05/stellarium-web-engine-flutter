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
    this.onCenterInFov,
    this.centerInFovLabel,
    this.isSlewing = false,
    this.onStop,
    this.slewProgressText,
    this.expandedBuilder,
    this.initiallyExpanded,
    this.backgroundColor,
    this.borderColor,
    this.accentColor,
    this.detailsTooltip,
    this.centerInFovTooltip,
    this.copyTooltip,
    this.syncTooltip,
    this.stopTooltip,
    this.gotoTooltip,
    super.key,
  });

  final SkyObject object;
  final VoidCallback? onGoto;
  final VoidCallback? onSync;
  final VoidCallback? onCopyCoordinates;
  final VoidCallback? onClose;
  final VoidCallback? onMoreDetails;
  final VoidCallback? onCenterInFov;
  final String? centerInFovLabel;
  final bool isSlewing;
  final VoidCallback? onStop;
  final String? slewProgressText;
  final Widget Function(BuildContext context, SkyObject object)?
  expandedBuilder;
  final bool? initiallyExpanded;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? accentColor;
  final String? detailsTooltip;
  final String? centerInFovTooltip;
  final String? copyTooltip;
  final String? syncTooltip;
  final String? stopTooltip;
  final String? gotoTooltip;

  @override
  State<SkyObjectPanel> createState() => _SkyObjectPanelState();
}

class _SkyObjectPanelState extends State<SkyObjectPanel> {
  late bool _expanded;

  bool get _defaultExpanded =>
      widget.initiallyExpanded ??
      (widget.object.kind == SkyObjectKind.customPoint);

  @override
  void initState() {
    super.initState();
    _expanded = _defaultExpanded;
  }

  @override
  void didUpdateWidget(covariant SkyObjectPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.object.id != widget.object.id) {
      _expanded = _defaultExpanded;
    } else if (oldWidget.initiallyExpanded != widget.initiallyExpanded &&
        widget.initiallyExpanded != null) {
      _expanded = widget.initiallyExpanded!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNight =
        theme.brightness == Brightness.dark &&
        theme.scaffoldBackgroundColor == Colors.black;
    final effectiveBgColor =
        widget.backgroundColor ??
        (isNight
            ? const Color(0xEE1E0505)
            : Colors.black.withValues(alpha: 0.88));
    final effectiveBorderColor =
        widget.borderColor ??
        (isNight
            ? const Color(0x88FF2222)
            : theme.colorScheme.primary.withValues(alpha: 0.45));
    final effectiveAccentColor =
        widget.accentColor ??
        (isNight ? const Color(0xFFFF5252) : theme.colorScheme.primary);

    final object = widget.object;
    final isSlewing = widget.isSlewing;
    final onStop = widget.onStop;
    final slewProgressText = widget.slewProgressText;
    final onClose = widget.onClose;
    final onGoto = widget.onGoto;
    final onSync = widget.onSync;
    final onCopyCoordinates = widget.onCopyCoordinates;
    final onMoreDetails = widget.onMoreDetails;
    final onCenterInFov = widget.onCenterInFov;
    final centerInFovLabel = widget.centerInFovLabel;
    final hasEphemDetails = object.distance != null ||
        (object.phase != null && !object.phase!.isNaN) ||
        object.diameter != null ||
        object.parallax != null;
    final hasDetails = widget.expandedBuilder != null ||
        widget.onMoreDetails != null ||
        hasEphemDetails;

    final isBelowHorizon = !object.isAboveHorizon;

    return Material(
      color: effectiveBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: effectiveBorderColor, width: 1.2),
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
                if (isSlewing) _buildSlewing(slewProgressText),
                if (object.constellation != null &&
                    object.constellation!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                    color: object.isAboveHorizon
                        ? Colors.greenAccent
                        : Colors.red,
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
            if (_expanded) ...[
              () {
                final ephemItems = <String>[];
                if (object.distance != null) {
                  final dStr = formatDistanceForDisplay(
                    object.distance!,
                    isMoon: object.isMoonTarget,
                  );
                  if (dStr.isNotEmpty) ephemItems.add('Distance $dStr');
                }
                if (object.phase != null && !object.phase!.isNaN) {
                  final p = object.phase!.clamp(0.0, 1.0);
                  ephemItems.add('Phase ${p.toStringAsFixed(2)}');
                }
                if (object.diameter != null) {
                  final diaStr = formatDiameterForDisplay(object.diameter!);
                  if (diaStr.isNotEmpty) ephemItems.add('Diameter $diaStr');
                }
                if (object.parallax != null) {
                  final plxStr = formatParallaxForDisplay(object.parallax!);
                  if (plxStr.isNotEmpty) ephemItems.add('Parallax $plxStr');
                }
                if (ephemItems.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ephemItems.join('  ·  '),
                          style: TextStyle(
                            color: isNight
                                ? const Color(0xFFFF9999)
                                : Colors.white70,
                            fontSize: 12,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                );
              }(),
              if (widget.expandedBuilder != null) ...[
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
            ],
            const SizedBox(height: 10),
            _buildActions(
              hasDetails,
              isNight,
              effectiveAccentColor,
              onMoreDetails,
              onCenterInFov,
              centerInFovLabel,
              onCopyCoordinates,
              onSync,
              isSlewing,
              isBelowHorizon,
              onStop,
              slewProgressText,
              onGoto,
            ),
          ],
        ),
      ),
    );
  }

  Row _buildActions(
    bool hasDetails,
    bool isNight,
    Color effectiveAccentColor,
    VoidCallback? onMoreDetails,
    VoidCallback? onCenterInFov,
    String? centerInFovLabel,
    VoidCallback? onCopyCoordinates,
    VoidCallback? onSync,
    bool isSlewing,
    bool isBelowHorizon,
    VoidCallback? onStop,
    String? slewProgressText,
    VoidCallback? onGoto,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      spacing: 4,
      children: [
        if (hasDetails)
          Expanded(
            flex: 4,
            child: Tooltip(
              message: widget.detailsTooltip ??
                  (_expanded ? 'Collapse details' : 'Show details'),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: isNight
                        ? Colors.red.withValues(alpha: 0.5)
                        : (_expanded
                              ? effectiveAccentColor.withValues(alpha: 0.6)
                              : Colors.white24),
                  ),
                  foregroundColor: isNight
                      ? const Color(0xFFFF8888)
                      : (_expanded ? effectiveAccentColor : Colors.white),
                ),
                onPressed: () {
                  if (widget.expandedBuilder != null || widget.onMoreDetails == null) {
                    setState(() => _expanded = !_expanded);
                  } else {
                    onMoreDetails?.call();
                  }
                },
                label: Text(
                  _expanded ? 'Less' : 'Details',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        if (onCenterInFov != null)
          Expanded(
            flex: 4,
            child: Tooltip(
              message: widget.centerInFovTooltip ?? 'Center target in view',
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: isNight
                        ? Colors.red.withValues(alpha: 0.5)
                        : Colors.white24,
                  ),
                  foregroundColor: isNight
                      ? const Color(0xFFFF8888)
                      : Colors.white,
                ),
                onPressed: onCenterInFov,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    centerInFovLabel ?? 'Center',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        if (onCopyCoordinates != null)
          Expanded(
            flex: 5,
            child: Tooltip(
              message: widget.copyTooltip ?? 'Copy coordinates to clipboard',
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: isNight
                        ? Colors.red.withValues(alpha: 0.5)
                        : Colors.white24,
                  ),
                  foregroundColor: isNight
                      ? const Color(0xFFFF8888)
                      : Colors.white,
                ),
                onPressed: onCopyCoordinates,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        if (onSync != null && !isSlewing)
          Expanded(
            flex: 5,
            child: Tooltip(
              message: widget.syncTooltip ??
                  (isBelowHorizon
                      ? 'Target is below horizon'
                      : 'Sync mount to target coordinates'),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: isBelowHorizon
                        ? (isNight ? const Color(0x33FF2222) : Colors.white12)
                        : (isNight
                              ? Colors.amber.withValues(alpha: 0.6)
                              : Colors.amberAccent.withValues(alpha: 0.6)),
                  ),
                  foregroundColor: isNight
                      ? const Color(0xFFFFCC66)
                      : Colors.amberAccent,
                  disabledForegroundColor: isNight
                      ? const Color(0x55FFCC66)
                      : Colors.white38,
                ),
                onPressed: isBelowHorizon ? null : onSync,
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Sync', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        if (isSlewing && onStop != null)
          Expanded(
            flex: 5,
            child: Tooltip(
              message: widget.stopTooltip ?? 'Stop telescope slewing',
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                ),
                onPressed: onStop,
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: Text(
                  slewProgressText != null ? 'STOP ($slewProgressText)' : 'STOP',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          )
        else if (onGoto != null)
          Expanded(
            flex: 5,
            child: Tooltip(
              message: widget.gotoTooltip ??
                  (isBelowHorizon
                      ? 'Target is below horizon'
                      : 'Slew telescope to target'),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: isNight
                      ? const Color(0xFFCC1111)
                      : effectiveAccentColor,
                  disabledBackgroundColor: isNight
                      ? const Color(0x33440000)
                      : Colors.white.withValues(alpha: 0.08),
                  disabledForegroundColor: isNight
                      ? const Color(0x66FF6666)
                      : Colors.white38,
                ),
                onPressed: isBelowHorizon ? null : onGoto,
                icon: const Icon(Icons.navigation, size: 16),
                label: const Text('Goto', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
      ],
    );
  }

  Container _buildSlewing(String? slewProgressText) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            slewProgressText != null ? 'SLEWING $slewProgressText' : 'SLEWING',
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
        'PLANET',
      ),
      SkyObjectKind.moon => (
        Icons.nightlight_round,
        isNight ? Colors.redAccent : Colors.amberAccent,
        'MOON',
      ),
      SkyObjectKind.sun => (
        Icons.wb_sunny,
        isNight ? Colors.redAccent : Colors.yellowAccent,
        'SUN',
      ),
      SkyObjectKind.messier => (
        Icons.blur_circular,
        isNight ? Colors.redAccent : Colors.cyanAccent,
        'MESSIER',
      ),
      SkyObjectKind.caldwell || SkyObjectKind.dso => (
        Icons.flare,
        isNight ? Colors.redAccent : Colors.purpleAccent,
        'DSO',
      ),
      SkyObjectKind.constellation => (
        Icons.auto_awesome,
        isNight ? Colors.redAccent : Colors.tealAccent,
        'CONST',
      ),
      SkyObjectKind.customPoint => (
        Icons.my_location_rounded,
        isNight ? Colors.redAccent : Colors.cyanAccent,
        'POINT',
      ),
      _ => (Icons.star, isNight ? Colors.redAccent : Colors.blueAccent, 'STAR'),
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
  final ephemItems = <String>[];
  if (object.distance != null) {
    final dStr = formatDistanceForDisplay(
      object.distance!,
      isMoon: object.isMoonTarget,
    );
    if (dStr.isNotEmpty) ephemItems.add('Distance: $dStr');
  }
  if (object.phase != null && !object.phase!.isNaN) {
    final p = object.phase!.clamp(0.0, 1.0);
    ephemItems.add('Phase: ${p.toStringAsFixed(2)}');
  }
  if (object.diameter != null) {
    final diaStr = formatDiameterForDisplay(object.diameter!);
    if (diaStr.isNotEmpty) ephemItems.add('Diameter: $diaStr');
  }
  if (object.parallax != null) {
    final plxStr = formatParallaxForDisplay(object.parallax!);
    if (plxStr.isNotEmpty) ephemItems.add('Parallax: $plxStr');
  }
  final ephemText = ephemItems.isNotEmpty ? '\n${ephemItems.join('  ·  ')}' : '';

  return '${object.name}\n'
      'RA ${formatRaHoursForDisplay(object.raHours)}\n'
      'Dec ${formatDecDegreesForDisplay(object.decDeg)}'
      '$altAz'
      '$ephemText';
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
