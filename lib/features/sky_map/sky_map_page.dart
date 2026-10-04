import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mlastro_skymap/astro/coordinate_format.dart';
import 'package:mlastro_skymap/features/sky_map/logic/sky_map_cubit.dart';
import 'package:mlastro_skymap/features/sky_map/logic/sky_map_state.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_map_config.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_map_telescope_position.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_point_long_press_event.dart';
import 'package:mlastro_skymap/features/sky_map/view/open_source_licenses_page.dart';
import 'package:mlastro_skymap/features/sky_map/view/sky_map_loading_overlay.dart';
import 'package:mlastro_skymap/features/sky_map/view/sky_map_search_sheet.dart';
import 'package:mlastro_skymap/features/sky_map/view/sky_map_web_view.dart';
import 'package:mlastro_skymap/features/sky_map/view/sky_object_panel.dart';

typedef SkyMapCubitFactory = SkyMapCubit Function();
typedef SkyMapObjectAction = Future<void> Function(
  BuildContext context,
  SkyObject object,
);
typedef SkyMapLongPressAction = void Function(
  BuildContext context,
  SkyPointLongPressEvent event,
);
typedef SkyMapToolbarBuilder = Widget Function(
  BuildContext context,
  SkyMapCubit cubit,
);
typedef SkyMapHudBuilder = Widget Function(
  BuildContext context,
  SkyMapState state,
);
typedef SkyMapOverlayBuilder = List<Widget> Function(
  BuildContext context,
);

/// Full-screen interactive sky map powered by Stellarium Web Engine.
class SkyMapPage extends StatelessWidget {
  const SkyMapPage({
    super.key,
    this.createCubit,
    this.initialConfig,
    this.initialLat,
    this.initialLonEast,
    this.routeObserver,
    this.onGoto,
    this.onSync,
    this.onStop,
    this.isSlewing = false,
    this.slewProgressText,
    this.onMoreDetails,
    this.expandedDetailsBuilder,
    this.onSkyPointLongPress,
    this.toolbarBuilder,
    this.hudBuilder,
    this.overlayBuilder,
    this.showObjectPanel = true,
    this.showLicensesButton = true,
    this.showSearchButton = true,
    this.appBarActions = const [],
    this.panelBackgroundColor,
    this.panelBorderColor,
    this.panelAccentColor,
    this.loadingAccentColor,
    this.loadingSecondaryColor,
    this.loadingBackgroundColors,
  });

  final SkyMapCubitFactory? createCubit;
  final SkyMapConfig? initialConfig;
  final double? initialLat;
  final double? initialLonEast;
  final RouteObserver<ModalRoute<void>>? routeObserver;
  final SkyMapObjectAction? onGoto;
  final SkyMapObjectAction? onSync;
  final VoidCallback? onStop;
  final bool isSlewing;
  final String? slewProgressText;
  final SkyMapObjectAction? onMoreDetails;
  final Widget Function(BuildContext context, SkyObject object)? expandedDetailsBuilder;
  final SkyMapLongPressAction? onSkyPointLongPress;
  final SkyMapToolbarBuilder? toolbarBuilder;
  final SkyMapHudBuilder? hudBuilder;
  final SkyMapOverlayBuilder? overlayBuilder;
  final bool showObjectPanel;
  final bool showLicensesButton;
  final bool showSearchButton;
  final List<Widget> appBarActions;
  final Color? panelBackgroundColor;
  final Color? panelBorderColor;
  final Color? panelAccentColor;
  final Color? loadingAccentColor;
  final Color? loadingSecondaryColor;
  final List<Color>? loadingBackgroundColors;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (createCubit?.call() ??
          SkyMapCubit(
            initialConfig: initialConfig,
            initialLat: initialLat,
            initialLonEast: initialLonEast,
          ))
        ..start(),
      child: _SkyMapView(
        routeObserver: routeObserver,
        onGoto: onGoto,
        onSync: onSync,
        onStop: onStop,
        isSlewing: isSlewing,
        slewProgressText: slewProgressText,
        onMoreDetails: onMoreDetails,
        expandedDetailsBuilder: expandedDetailsBuilder,
        onSkyPointLongPress: onSkyPointLongPress,
        toolbarBuilder: toolbarBuilder,
        hudBuilder: hudBuilder,
        overlayBuilder: overlayBuilder,
        showObjectPanel: showObjectPanel,
        showLicensesButton: showLicensesButton,
        showSearchButton: showSearchButton,
        appBarActions: appBarActions,
        panelBackgroundColor: panelBackgroundColor,
        panelBorderColor: panelBorderColor,
        panelAccentColor: panelAccentColor,
        loadingAccentColor: loadingAccentColor,
        loadingSecondaryColor: loadingSecondaryColor,
        loadingBackgroundColors: loadingBackgroundColors,
      ),
    );
  }
}

class _SkyMapView extends StatefulWidget {
  const _SkyMapView({
    required this.routeObserver,
    required this.onGoto,
    required this.onSync,
    required this.onStop,
    required this.isSlewing,
    required this.slewProgressText,
    required this.onMoreDetails,
    this.expandedDetailsBuilder,
    this.onSkyPointLongPress,
    required this.toolbarBuilder,
    required this.hudBuilder,
    required this.overlayBuilder,
    this.showObjectPanel = true,
    required this.showLicensesButton,
    required this.showSearchButton,
    required this.appBarActions,
    this.panelBackgroundColor,
    this.panelBorderColor,
    this.panelAccentColor,
    this.loadingAccentColor,
    this.loadingSecondaryColor,
    this.loadingBackgroundColors,
  });

  final RouteObserver<ModalRoute<void>>? routeObserver;
  final SkyMapObjectAction? onGoto;
  final SkyMapObjectAction? onSync;
  final VoidCallback? onStop;
  final bool isSlewing;
  final String? slewProgressText;
  final SkyMapObjectAction? onMoreDetails;
  final Widget Function(BuildContext context, SkyObject object)? expandedDetailsBuilder;
  final SkyMapLongPressAction? onSkyPointLongPress;
  final SkyMapToolbarBuilder? toolbarBuilder;
  final SkyMapHudBuilder? hudBuilder;
  final SkyMapOverlayBuilder? overlayBuilder;
  final bool showObjectPanel;
  final bool showLicensesButton;
  final bool showSearchButton;
  final List<Widget> appBarActions;
  final Color? panelBackgroundColor;
  final Color? panelBorderColor;
  final Color? panelAccentColor;
  final Color? loadingAccentColor;
  final Color? loadingSecondaryColor;
  final List<Color>? loadingBackgroundColors;

  @override
  State<_SkyMapView> createState() => _SkyMapViewState();
}

class _SkyMapViewState extends State<_SkyMapView> with RouteAware {
  SkyMapCubit get _cubit => context.read<SkyMapCubit>();
  StreamSubscription<SkyPointLongPressEvent>? _longPressSub;

  @override
  void initState() {
    super.initState();
    _longPressSub = _cubit.longPressStream.listen((event) {
      if (!mounted) return;
      widget.onSkyPointLongPress?.call(context, event);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = widget.routeObserver;
    final route = ModalRoute.of(context);
    if (observer != null && route is PageRoute<void>) {
      observer.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _longPressSub?.cancel();
    widget.routeObserver?.unsubscribe(this);
    super.dispose();
  }

  /// iOS WebView loses touch after a covering route (search, goto) is popped.
  @override
  void didPopNext() {
    unawaited(_cubit.resumeMapInteraction());
  }

  Future<void> _resumeAfterOverlay() async {
    await _cubit.resumeMapInteraction();
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomToolbar = widget.toolbarBuilder != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: hasCustomToolbar
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              actions: [
                ...widget.appBarActions,
                if (widget.showLicensesButton)
                  IconButton(
                    tooltip: 'Open source licenses',
                    onPressed: () => _openLicenses(context),
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                  ),
                if (widget.showSearchButton)
                  BlocSelector<SkyMapCubit, SkyMapState, bool>(
                    selector: (state) => state.mapReady,
                    builder: (context, mapReady) {
                      return IconButton(
                        tooltip: 'Search object',
                        onPressed: mapReady ? () => _openSearch(context) : null,
                        icon: const Icon(Icons.search, color: Colors.white),
                      );
                    },
                  ),
              ],
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SkyMapWebView(cubit: _cubit),
          _SkyMapOverlayLayer(
            onGoto: widget.onGoto,
            onSync: widget.onSync,
            onStop: widget.onStop,
            isSlewing: widget.isSlewing,
            slewProgressText: widget.slewProgressText,
            onMoreDetails: widget.onMoreDetails,
            expandedDetailsBuilder: widget.expandedDetailsBuilder,
            hudBuilder: widget.hudBuilder,
            overlayBuilder: widget.overlayBuilder,
            showObjectPanel: widget.showObjectPanel,
            hasCustomToolbar: hasCustomToolbar,
            panelBackgroundColor: widget.panelBackgroundColor,
            panelBorderColor: widget.panelBorderColor,
            panelAccentColor: widget.panelAccentColor,
          ),
          if (hasCustomToolbar)
            Positioned(
              top: MediaQuery.paddingOf(context).top,
              left: 0,
              right: 0,
              child: widget.toolbarBuilder!(context, _cubit),
            ),
          BlocBuilder<SkyMapCubit, SkyMapState>(
            buildWhen: (prev, next) =>
                prev.mapReady != next.mapReady ||
                prev.config.nightMode != next.config.nightMode,
            builder: (context, state) {
              return SkyMapLoadingOverlay(
                isReady: state.mapReady,
                isNightMode: state.config.nightMode,
                accentColor: widget.loadingAccentColor,
                secondaryColor: widget.loadingSecondaryColor,
                backgroundColors: widget.loadingBackgroundColors,
                onRetry: () => _cubit.start(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openLicenses(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const OpenSourceLicensesPage()),
    );
    if (!mounted) return;
    await _resumeAfterOverlay();
  }

  Future<void> _openSearch(BuildContext context) async {
    await SkyMapSearchSheet.show(
      context,
      packageCubit: _cubit,
      onSelectObject: (picked) async {
        await _cubit.centerOnObject(picked);
        await _cubit.selectById(picked.id);
        await _cubit.resumeMapInteraction();
      },
    );
    if (!mounted) return;
    await _resumeAfterOverlay();
  }
}

class _SkyMapOverlayLayer extends StatelessWidget {
  const _SkyMapOverlayLayer({
    required this.onGoto,
    this.onSync,
    this.onStop,
    this.isSlewing = false,
    this.slewProgressText,
    this.onMoreDetails,
    this.expandedDetailsBuilder,
    this.hudBuilder,
    this.overlayBuilder,
    this.showObjectPanel = true,
    this.hasCustomToolbar = false,
    this.panelBackgroundColor,
    this.panelBorderColor,
    this.panelAccentColor,
  });

  final SkyMapObjectAction? onGoto;
  final SkyMapObjectAction? onSync;
  final VoidCallback? onStop;
  final bool isSlewing;
  final String? slewProgressText;
  final SkyMapObjectAction? onMoreDetails;
  final Widget Function(BuildContext context, SkyObject object)? expandedDetailsBuilder;
  final SkyMapHudBuilder? hudBuilder;
  final SkyMapOverlayBuilder? overlayBuilder;
  final bool showObjectPanel;
  final bool hasCustomToolbar;
  final Color? panelBackgroundColor;
  final Color? panelBorderColor;
  final Color? panelAccentColor;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SkyMapCubit, SkyMapState>(
      buildWhen: (prev, next) =>
          prev.statusLine != next.statusLine ||
          prev.mapReady != next.mapReady ||
          prev.locationReady != next.locationReady ||
          prev.telescope != next.telescope ||
          prev.selected?.id != next.selected?.id,
      builder: (context, state) {
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final selected = state.selected;
        final telescope = state.telescope;

        return Stack(
          children: [
            Positioned(
              left: 12,
              top: MediaQuery.paddingOf(context).top +
                  (hasCustomToolbar ? 64 : 8),
              child: hudBuilder != null
                  ? hudBuilder!(context, state)
                  : _StatusHud(
                      mapReady: state.mapReady,
                      telescope: telescope,
                    ),
            ),
            if (overlayBuilder != null) ...overlayBuilder!(context),
            if (state.statusLine != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: (selected != null ? 184 : 16) + bottomInset,
                child: Material(
                  elevation: 6,
                  color: const Color(0xF0151C2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white24, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_off_rounded,
                          color: Colors.amberAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.statusLine!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => context.read<SkyMapCubit>().clearStatusLine(),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close_rounded, size: 16, color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (showObjectPanel && selected != null)
              Positioned(
                key: ValueKey(selected.id),
                left: 12,
                right: 12,
                bottom: 16 + bottomInset,
                child: SkyObjectPanel(
                  object: selected,
                  isSlewing: isSlewing,
                  onStop: onStop,
                  slewProgressText: slewProgressText,
                  onClose: () => context.read<SkyMapCubit>().deselectObject(),
                  onGoto: onGoto == null
                      ? null
                      : () => onGoto!(context, selected),
                  onSync: isSlewing || onSync == null
                      ? null
                      : () => onSync!(context, selected),
                  onMoreDetails: onMoreDetails == null
                      ? null
                      : () => onMoreDetails!(context, selected),
                  expandedBuilder: expandedDetailsBuilder,
                  backgroundColor: panelBackgroundColor,
                  borderColor: panelBorderColor,
                  accentColor: panelAccentColor,
                  onCopyCoordinates: (onGoto == null && onSync == null)
                      ? () => copySkyObjectCoordinates(context, selected)
                      : null,
                ),
              )
          ],
        );
      },
    );
  }
}

class _StatusHud extends StatelessWidget {
  const _StatusHud({
    required this.mapReady,
    required this.telescope,
  });

  final bool mapReady;
  final SkyMapTelescopePosition? telescope;

  @override
  Widget build(BuildContext context) {
    if (telescope == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            'RA ${hourToString(telescope!.raHours)}  '
            'Dec ${formatDecDegreesForDisplay(telescope!.decDeg)}',
            style: const TextStyle(color: Colors.lightGreenAccent),
          ),
        ),
      ),
    );
  }
}

