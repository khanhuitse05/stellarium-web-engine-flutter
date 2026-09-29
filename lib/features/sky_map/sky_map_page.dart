import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mlastro_skymap/astro/coordinate_format.dart';
import 'package:mlastro_skymap/features/sky_map/logic/sky_map_cubit.dart';
import 'package:mlastro_skymap/features/sky_map/logic/sky_map_state.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_map_config.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_map_telescope_position.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object.dart';
import 'package:mlastro_skymap/features/sky_map/view/open_source_licenses_page.dart';
import 'package:mlastro_skymap/features/sky_map/view/sky_map_web_view.dart';
import 'package:mlastro_skymap/features/sky_map/view/sky_object_panel.dart';

typedef SkyMapCubitFactory = SkyMapCubit Function();
typedef SkyMapObjectAction = Future<void> Function(
  BuildContext context,
  SkyObject object,
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
    this.routeObserver,
    this.onGoto,
    this.onSync,
    this.toolbarBuilder,
    this.hudBuilder,
    this.overlayBuilder,
    this.showLicensesButton = true,
    this.showSearchButton = true,
    this.appBarActions = const [],
  });

  final SkyMapCubitFactory? createCubit;
  final SkyMapConfig? initialConfig;
  final RouteObserver<ModalRoute<void>>? routeObserver;
  final SkyMapObjectAction? onGoto;
  final SkyMapObjectAction? onSync;
  final SkyMapToolbarBuilder? toolbarBuilder;
  final SkyMapHudBuilder? hudBuilder;
  final SkyMapOverlayBuilder? overlayBuilder;
  final bool showLicensesButton;
  final bool showSearchButton;
  final List<Widget> appBarActions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (createCubit?.call() ??
          SkyMapCubit(initialConfig: initialConfig))
        ..start(),
      child: _SkyMapView(
        routeObserver: routeObserver,
        onGoto: onGoto,
        onSync: onSync,
        toolbarBuilder: toolbarBuilder,
        hudBuilder: hudBuilder,
        overlayBuilder: overlayBuilder,
        showLicensesButton: showLicensesButton,
        showSearchButton: showSearchButton,
        appBarActions: appBarActions,
      ),
    );
  }
}

class _SkyMapView extends StatefulWidget {
  const _SkyMapView({
    required this.routeObserver,
    required this.onGoto,
    required this.onSync,
    required this.toolbarBuilder,
    required this.hudBuilder,
    required this.overlayBuilder,
    required this.showLicensesButton,
    required this.showSearchButton,
    required this.appBarActions,
  });

  final RouteObserver<ModalRoute<void>>? routeObserver;
  final SkyMapObjectAction? onGoto;
  final SkyMapObjectAction? onSync;
  final SkyMapToolbarBuilder? toolbarBuilder;
  final SkyMapHudBuilder? hudBuilder;
  final SkyMapOverlayBuilder? overlayBuilder;
  final bool showLicensesButton;
  final bool showSearchButton;
  final List<Widget> appBarActions;

  @override
  State<_SkyMapView> createState() => _SkyMapViewState();
}

class _SkyMapViewState extends State<_SkyMapView> with RouteAware {
  SkyMapCubit get _cubit => context.read<SkyMapCubit>();

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
            hudBuilder: widget.hudBuilder,
            overlayBuilder: widget.overlayBuilder,
            hasCustomToolbar: hasCustomToolbar,
          ),
          if (hasCustomToolbar)
            Positioned(
              top: MediaQuery.paddingOf(context).top,
              left: 0,
              right: 0,
              child: widget.toolbarBuilder!(context, _cubit),
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
    final picked = await showSearch<SkyObject?>(
      context: context,
      delegate: _SkyObjectSearchDelegate(search: _cubit.searchByName),
    );
    if (!mounted) return;
    await _resumeAfterOverlay();
    if (picked != null) {
      await _cubit.centerOnObject(picked);
    }
  }
}

class _SkyMapOverlayLayer extends StatelessWidget {
  const _SkyMapOverlayLayer({
    required this.onGoto,
    this.onSync,
    this.hudBuilder,
    this.overlayBuilder,
    this.hasCustomToolbar = false,
  });

  final SkyMapObjectAction? onGoto;
  final SkyMapObjectAction? onSync;
  final SkyMapHudBuilder? hudBuilder;
  final SkyMapOverlayBuilder? overlayBuilder;
  final bool hasCustomToolbar;

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
                bottom: (selected != null ? 168 : 16) + bottomInset,
                child: Material(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      state.statusLine!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            if (selected != null)
              Positioned(
                key: ValueKey(selected.id),
                left: 12,
                right: 12,
                bottom: 16 + bottomInset,
                child: SkyObjectPanel(
                  object: selected,
                  onClose: () => context.read<SkyMapCubit>().deselectObject(),
                  onGoto: onGoto == null
                      ? null
                      : () => onGoto!(context, selected),
                  onSync: onSync == null
                      ? null
                      : () => onSync!(context, selected),
                  onCopyCoordinates: (onGoto == null && onSync == null)
                      ? () => copySkyObjectCoordinates(context, selected)
                      : null,
                ),
              ),
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
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!mapReady) const Text('Loading sky map…'),
              if (telescope != null)
                Text(
                  'RA ${hourToString(telescope!.raHours)}  '
                  'Dec ${formatDecDegreesForDisplay(telescope!.decDeg)}',
                  style: const TextStyle(color: Colors.lightGreenAccent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkyObjectSearchDelegate extends SearchDelegate<SkyObject?> {
  _SkyObjectSearchDelegate({required this.search});

  final Future<List<SkyObject>> Function(String q) search;

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back),
      );

  @override
  Widget buildResults(BuildContext context) => _list(context);

  @override
  Widget buildSuggestions(BuildContext context) => _list(context);

  Widget _list(BuildContext context) {
    return FutureBuilder<List<SkyObject>>(
      future: search(query),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(
            child: Text(
              query.trim().isEmpty ? 'Type a star or DSO name' : 'No matches',
            ),
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final o = items[i];
            return ListTile(
              title: Text(o.name),
              subtitle: Text(
                'RA ${hourToString(o.raHours)}  '
                '${formatDeclinationForSd(o.decDeg)}',
              ),
              onTap: () => close(context, o),
            );
          },
        );
      },
    );
  }
}
