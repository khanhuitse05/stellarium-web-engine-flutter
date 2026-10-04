import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mlastro_skymap/astro/coordinate_format.dart';
import 'package:mlastro_skymap/features/sky_map/logic/sky_map_cubit.dart';
import 'package:mlastro_skymap/features/sky_map/logic/sky_map_state.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object_kind.dart';

/// Lightweight search sheet querying the Stellarium Web Engine database via JS bridge.
class SkyMapSearchSheet extends StatefulWidget {
  const SkyMapSearchSheet({
    required this.packageCubit,
    this.onSelectObject,
    this.customSearch,
    this.autoFocusSearch = true,
    super.key,
  });

  final SkyMapCubit packageCubit;
  final ValueChanged<SkyObject>? onSelectObject;
  final Future<List<SkyObject>> Function(String query)? customSearch;
  final bool autoFocusSearch;

  /// Convenience modal launcher.
  static Future<void> show(
    BuildContext context, {
    required SkyMapCubit packageCubit,
    ValueChanged<SkyObject>? onSelectObject,
    Future<List<SkyObject>> Function(String query)? customSearch,
    bool autoFocusSearch = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SkyMapSearchSheet(
        packageCubit: packageCubit,
        onSelectObject: onSelectObject,
        customSearch: customSearch,
        autoFocusSearch: autoFocusSearch,
      ),
    );
  }

  @override
  State<SkyMapSearchSheet> createState() => _SkyMapSearchSheetState();
}

class _SkyMapSearchSheetState extends State<SkyMapSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounceTimer;
  List<SkyObject> _results = const [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    setState(() => _searching = true);

    try {
      // 1. Query Stellarium Web Engine via JS bridge
      List<SkyObject> bridgeMatches = const [];
      try {
        bridgeMatches = await widget.packageCubit.searchByName(query);
      } catch (_) {}

      // 2. Query optional custom search provider
      List<SkyObject> customMatches = const [];
      if (widget.customSearch != null) {
        try {
          customMatches = await widget.customSearch!(query);
        } catch (_) {}
      }

      final merged = _mergeResults(bridgeMatches, customMatches);

      if (mounted) {
        setState(() {
          _results = merged;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  List<SkyObject> _mergeResults(List<SkyObject> base, List<SkyObject> additions) {
    if (additions.isEmpty) return base;

    final merged = List<SkyObject>.from(base);
    for (final b in additions) {
      final exists = merged.any(
        (l) => l.name.toLowerCase() == b.name.toLowerCase() || l.id == b.id,
      );
      if (!exists) {
        merged.add(b);
      }
    }
    return merged;
  }

  Future<void> _onSelectObject(SkyObject object) async {
    Navigator.of(context).pop();
    if (widget.onSelectObject != null) {
      widget.onSelectObject!(object);
    } else {
      await widget.packageCubit.centerOnObject(object);
      await widget.packageCubit.selectById(object.id);
      await widget.packageCubit.resumeMapInteraction();
    }
  }

  IconData _iconForKind(SkyObjectKind kind) {
    return switch (kind) {
      SkyObjectKind.planet ||
      SkyObjectKind.moon ||
      SkyObjectKind.sun =>
        Icons.public_rounded,
      SkyObjectKind.star => Icons.stars_rounded,
      SkyObjectKind.messier => Icons.blur_circular_rounded,
      SkyObjectKind.caldwell || SkyObjectKind.dso => Icons.scatter_plot_rounded,
      SkyObjectKind.constellation => Icons.polyline_rounded,
      SkyObjectKind.customPoint => Icons.my_location_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SkyMapCubit, SkyMapState>(
      bloc: widget.packageCubit,
      buildWhen: (p, n) => p.config.nightMode != n.config.nightMode,
      builder: (context, state) {
        final isNight = state.config.nightMode;

        final bgColor = isNight ? const Color(0xF21C0404) : const Color(0xF20F1626);
        final borderColor = isNight ? const Color(0x66FF2222) : const Color(0x33FFFFFF);
        final activeColor = isNight ? const Color(0xFFFF5252) : const Color(0xFF00E5FF);
        final query = _searchController.text.trim();

        final viewInsets = MediaQuery.of(context).viewInsets;
        final sheetHeight = MediaQuery.sizeOf(context).height * 0.75;
        final displayResults = _results;

        return Container(
          height: sheetHeight,
          margin: EdgeInsets.only(bottom: viewInsets.bottom),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: borderColor, width: 1.5)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(
                  color: isNight ? const Color(0x44FF2222) : Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: activeColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'CELESTIAL SEARCH',
                      style: TextStyle(
                        color: isNight ? const Color(0xFFFF8888) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (_results.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: activeColor.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${_results.length}',
                          style: TextStyle(
                            color: activeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isNight ? const Color(0x99FF6666) : Colors.white60,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Search Input Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: isNight ? const Color(0xFFFFCCCC) : Colors.white,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search stars, planets, Messier, NGC, IC…',
                    hintStyle: TextStyle(
                      color: isNight ? const Color(0x66FF6666) : Colors.white38,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isNight ? const Color(0x99FF6666) : Colors.white54,
                      size: 18,
                    ),
                    suffixIcon: _searching
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: activeColor,
                              ),
                            ),
                          )
                        : query.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: isNight ? const Color(0x99FF6666) : Colors.white54,
                                  size: 16,
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: isNight
                        ? const Color(0x333A0000)
                        : Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isNight ? const Color(0x44FF2222) : Colors.white12,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isNight ? const Color(0x44FF2222) : Colors.white12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: activeColor),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: Colors.white12),

              // Body Content
              Expanded(
                child: query.isEmpty
                    ? _buildSearchTipsView(context, isNight, activeColor)
                    : _searching && _results.isEmpty
                        ? Center(
                            child: CircularProgressIndicator(color: activeColor),
                          )
                        : displayResults.isEmpty
                            ? _buildNoResultsView(context, isNight, query)
                            : _buildResultsList(context, isNight, activeColor, displayResults),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchTipsView(BuildContext context, bool isNight, Color activeColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isNight
                ? const Color(0x18FF2222)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isNight ? const Color(0x33FF2222) : Colors.white10,
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: isNight ? const Color(0xAAFF5252) : const Color(0xAA00E5FF),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SEARCH TIPS',
                    style: TextStyle(
                      color: isNight ? const Color(0x88FF8888) : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Direct names: Jupiter, Mars, Vega, Sirius, Polaris\n'
                '• Catalog codes: M31, M42, NGC 7000, IC 434, C14\n'
                '• Constellations: Orion, Ursa Major, Cassiopeia\n'
                '• Deep-sky objects: Andromeda Galaxy, Orion Nebula, Pleiades',
                style: TextStyle(
                  color: isNight ? const Color(0x66FF9999) : Colors.white38,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsView(BuildContext context, bool isNight, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: isNight ? const Color(0x66FF4444) : Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No celestial targets found for "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isNight ? const Color(0xFFFF8888) : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check spelling or try catalog codes (e.g. "M42", "NGC 224", "Jupiter").',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isNight ? const Color(0x66FF6666) : Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(
    BuildContext context,
    bool isNight,
    Color activeColor,
    List<SkyObject> items,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final o = items[index];
        final hasMag = o.magnitude != null;
        final magStr = hasMag ? 'Mag ${o.magnitude!.toStringAsFixed(1)}' : '';
        final isAbove = o.isAboveHorizon;
        final altStr = o.altDeg != null
            ? (isAbove
                ? 'Alt +${o.altDeg!.toStringAsFixed(0)}°'
                : 'Alt ${o.altDeg!.toStringAsFixed(0)}°')
            : '';

        String? commonAlias;
        if (o.aliases.isNotEmpty) {
          for (final a in o.aliases) {
            if (a.toLowerCase() != o.name.toLowerCase() &&
                !RegExp(r'^[A-Z]+\s*\d+$', caseSensitive: false).hasMatch(a)) {
              commonAlias = a;
              break;
            }
          }
        }

        final subtitleParts = [
          ?commonAlias,
          if (o.typeDescription != null && o.typeDescription!.isNotEmpty)
            o.typeDescription!
          else
            o.kind.name.toUpperCase(),
          if (o.constellation != null && o.constellation!.isNotEmpty)
            o.constellation!,
          if (magStr.isNotEmpty) magStr,
        ].join('  ·  ');

        final icon = _iconForKind(o.kind);

        return ListTile(
          dense: true,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: activeColor,
              size: 18,
            ),
          ),
          title: Text(
            o.name,
            style: TextStyle(
              color: isNight ? const Color(0xFFFFCCCC) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          subtitle: subtitleParts.isNotEmpty
              ? Text(
                  subtitleParts,
                  style: TextStyle(
                    color: isNight ? const Color(0x99FF8888) : Colors.white60,
                    fontSize: 11,
                  ),
                )
              : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (altStr.isNotEmpty)
                Text(
                  altStr,
                  style: TextStyle(
                    color: isAbove
                        ? (isNight ? const Color(0xFFFF5252) : const Color(0xFF00E5FF))
                        : (isNight ? const Color(0x55FF5252) : Colors.white38),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                formatDeclinationForSd(o.decDeg),
                style: TextStyle(
                  color: isNight ? const Color(0x66FF8888) : Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          onTap: () => _onSelectObject(o),
        );
      },
    );
  }
}
