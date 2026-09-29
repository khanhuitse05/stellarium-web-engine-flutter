import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mlastro_skymap/astro/coordinate_format.dart';
import 'package:mlastro_skymap/astro/planetary_ephemeris.dart';
import 'package:mlastro_skymap/features/sky_map/data/curated_targets.dart';
import 'package:mlastro_skymap/features/sky_map/logic/sky_map_cubit.dart';
import 'package:mlastro_skymap/features/sky_map/logic/sky_map_state.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object_kind.dart';

/// Preprocessed searchable item for instant in-memory lookup.
class _PreparedSearchTarget {
  const _PreparedSearchTarget({
    required this.target,
    required this.normalizedName,
    required this.compactName,
    required this.compactAliases,
  });

  final CuratedTarget target;
  final String normalizedName;
  final String compactName;
  final List<String> compactAliases;
}

/// Slide-up modal sheet merging Celestial Catalogs and Search.
///
/// - When search input is **empty**: displays curated celestial catalogs organized
///   in category tabs (Tonight's Best, Planets, Messier, Stars, Caldwell, DSOs).
/// - When user **types**: transitions dynamically to live search results (instant
///   in-memory lookup + Stellarium Web Engine bridge search).
class SkyMapSearchSheet extends StatefulWidget {
  const SkyMapSearchSheet({
    required this.packageCubit,
    this.onSelectObject,
    this.customSearch,
    this.autoFocusSearch = true,
    this.initialCatalogIndex = 0,
    super.key,
  });

  final SkyMapCubit packageCubit;
  final ValueChanged<SkyObject>? onSelectObject;
  final Future<List<SkyObject>> Function(String query)? customSearch;
  final bool autoFocusSearch;
  final int initialCatalogIndex;

  /// Convenience modal launcher.
  static Future<void> show(
    BuildContext context, {
    required SkyMapCubit packageCubit,
    ValueChanged<SkyObject>? onSelectObject,
    Future<List<SkyObject>> Function(String query)? customSearch,
    bool autoFocusSearch = true,
    int initialCatalogIndex = 0,
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
        initialCatalogIndex: initialCatalogIndex,
      ),
    );
  }

  @override
  State<SkyMapSearchSheet> createState() => _SkyMapSearchSheetState();
}

class _SkyMapSearchSheetState extends State<SkyMapSearchSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounceTimer;
  List<SkyObject> _results = const [];
  bool _searching = false;

  static List<_PreparedSearchTarget>? _preparedTargets;

  List<SkyObject> _tonightsBest = const [];
  List<SkyObject> _planets = const [];
  List<SkyObject> _messier = const [];
  List<SkyObject> _stars = const [];
  List<SkyObject> _caldwell = const [];
  List<SkyObject> _dsos = const [];

  static const List<String> _catalogTabs = [
    "Tonight's Best",
    'Planets',
    'Messier',
    'Stars',
    'Caldwell',
    'DSOs',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _catalogTabs.length,
      vsync: this,
      initialIndex: widget.initialCatalogIndex.clamp(0, _catalogTabs.length - 1),
    );
    _searchController.addListener(_onSearchChanged);
    _ensureTargetsPrepared();
    _initCatalogs();

    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static String _compact(String text) {
    return text.replaceAll(RegExp(r'[\s\-_]+'), '').toUpperCase();
  }

  static void _ensureTargetsPrepared() {
    if (_preparedTargets != null) return;
    _preparedTargets = kCuratedSkyTargets.map((t) {
      return _PreparedSearchTarget(
        target: t,
        normalizedName: t.name.toLowerCase(),
        compactName: _compact(t.name),
        compactAliases: t.aliases.map(_compact).toList(),
      );
    }).toList();
  }

  void _initCatalogs() {
    final nowUtc = widget.packageCubit.state.utc;
    final obsLat = widget.packageCubit.state.observerLat;
    final obsLon = widget.packageCubit.state.observerLonEast;

    final all = <SkyObject>[];
    final planets = <SkyObject>[];
    final messier = <SkyObject>[];
    final stars = <SkyObject>[];
    final caldwell = <SkyObject>[];
    final dsos = <SkyObject>[];

    for (final t in kCuratedSkyTargets) {
      final obj = _toSkyObject(t, nowUtc: nowUtc, obsLat: obsLat, obsLon: obsLon);
      all.add(obj);

      if (t.isSolarSystem ||
          t.kind == SkyObjectKind.planet ||
          t.kind == SkyObjectKind.moon ||
          t.kind == SkyObjectKind.sun) {
        planets.add(obj);
      } else if (t.kind == SkyObjectKind.messier) {
        messier.add(obj);
      } else if (t.kind == SkyObjectKind.star) {
        stars.add(obj);
      } else if (t.kind == SkyObjectKind.caldwell) {
        caldwell.add(obj);
      } else if (t.kind == SkyObjectKind.dso) {
        dsos.add(obj);
      }
    }

    // Stars sorted by brightness (magnitude ascending)
    stars.sort((a, b) => (a.magnitude ?? 99.0).compareTo(b.magnitude ?? 99.0));

    // Tonight's Best: targets with altitude >= 15° (or >= 0° if few above 15°)
    var best = all.where((o) => (o.altDeg ?? -90.0) >= 15.0).toList();
    if (best.length < 12) {
      best = all.where((o) => (o.altDeg ?? -90.0) >= 0.0).toList();
    }
    best.sort((a, b) {
      final magComp = (a.magnitude ?? 99.0).compareTo(b.magnitude ?? 99.0);
      if (magComp != 0) return magComp;
      return (b.altDeg ?? 0.0).compareTo(a.altDeg ?? 0.0);
    });

    _tonightsBest = best;
    _planets = planets;
    _messier = messier;
    _stars = stars;
    _caldwell = caldwell;
    _dsos = dsos;
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

    _debounceTimer = Timer(const Duration(milliseconds: 180), () {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    setState(() => _searching = true);

    try {
      _ensureTargetsPrepared();
      final nowUtc = widget.packageCubit.state.utc;
      final obsLat = widget.packageCubit.state.observerLat;
      final obsLon = widget.packageCubit.state.observerLonEast;

      // 1. Search local curated targets in-memory (instantaneous)
      final localMatches = _searchCuratedTargets(
        _preparedTargets ?? const [],
        query,
        nowUtc: nowUtc,
        obsLat: obsLat,
        obsLon: obsLon,
      );

      if (mounted) {
        setState(() {
          _results = localMatches;
        });
      }

      // 2. Query optional custom search provider
      List<SkyObject> customMatches = const [];
      if (widget.customSearch != null) {
        try {
          customMatches = await widget.customSearch!(query);
        } catch (_) {}
      }

      // 3. Query bridge in parallel (Stellarium Web Engine WASM search)
      List<SkyObject> bridgeMatches = const [];
      try {
        bridgeMatches = await widget.packageCubit.searchByName(query);
      } catch (_) {}

      // 4. Merge results with local matches
      var merged = _mergeResults(localMatches, customMatches);
      merged = _mergeResults(merged, bridgeMatches);

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

  List<SkyObject> _searchCuratedTargets(
    List<_PreparedSearchTarget> items,
    String query, {
    required DateTime nowUtc,
    required double obsLat,
    required double obsLon,
  }) {
    final qLower = query.toLowerCase();
    final qCompact = _compact(query);

    final scored = <({int score, CuratedTarget target})>[];

    for (final it in items) {
      int score = 0;
      final t = it.target;

      if (it.normalizedName == qLower || it.compactName == qCompact) {
        score = 1000;
      } else if (it.compactAliases.contains(qCompact)) {
        score = 900;
      } else if (it.normalizedName.startsWith(qLower) || it.compactName.startsWith(qCompact)) {
        score = 800;
      } else if (t.aliases.any((a) => a.toLowerCase().startsWith(qLower))) {
        score = 700;
      } else if (it.normalizedName.contains(qLower) || it.compactName.contains(qCompact)) {
        score = 600;
      } else if (t.aliases.any((a) => a.toLowerCase().contains(qLower))) {
        score = 500;
      } else if (t.constellation != null && t.constellation!.toLowerCase().startsWith(qLower)) {
        score = 400;
      } else if (t.constellation != null && t.constellation!.toLowerCase().contains(qLower)) {
        score = 250;
      }

      if (score > 0) {
        scored.add((score: score, target: t));
      }
    }

    // Sort: highest score first, then brighter magnitude first
    scored.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;
      final magA = a.target.magnitude ?? 99.0;
      final magB = b.target.magnitude ?? 99.0;
      return magA.compareTo(magB);
    });

    // Take top 40 results and convert to SkyObject
    return scored.take(40).map((s) {
      return _toSkyObject(s.target, nowUtc: nowUtc, obsLat: obsLat, obsLon: obsLon);
    }).toList();
  }

  SkyObject _toSkyObject(
    CuratedTarget target, {
    required DateTime nowUtc,
    required double obsLat,
    required double obsLon,
  }) {
    var ra = target.raHours;
    var dec = target.decDeg;

    if (target.isSolarSystem) {
      final ephem = celestialRaDec(target.name, nowUtc);
      ra = ephem.raHours;
      dec = ephem.decDeg;
    }

    final altAz = equatorialRaDecToAltAz(
      raHours: ra,
      decDeg: dec,
      latDeg: obsLat,
      lonEastDeg: obsLon,
      timeUtc: nowUtc,
    );

    return SkyObject(
      id: target.id,
      name: target.name,
      kind: target.kind,
      raHours: ra,
      decDeg: dec,
      magnitude: target.magnitude,
      altDeg: altAz.altDeg,
      azDeg: altAz.azDeg,
      constellation: target.constellation,
      typeDescription: target.typeDescription,
      aliases: target.aliases,
    );
  }

  List<SkyObject> _mergeResults(List<SkyObject> base, List<SkyObject> additions) {
    if (additions.isEmpty) return base;

    final merged = List<SkyObject>.from(base);
    for (final b in additions) {
      final idx = merged.indexWhere((l) {
        if (l.name.toLowerCase() == b.name.toLowerCase()) return true;
        final raDiff = (l.raHours - b.raHours).abs();
        final decDiff = (l.decDeg - b.decDeg).abs();
        return raDiff < 0.05 && decDiff < 0.5;
      });

      if (idx != -1) {
        final l = merged[idx];
        merged[idx] = l.copyWith(
          id: b.id,
          raHours: b.raHours != 0.0 ? b.raHours : l.raHours,
          decDeg: b.decDeg != 0.0 ? b.decDeg : l.decDeg,
          magnitude: b.magnitude ?? l.magnitude,
          altDeg: b.altDeg ?? l.altDeg,
          azDeg: b.azDeg ?? l.azDeg,
          typeDescription: (l.typeDescription != null && l.typeDescription!.isNotEmpty)
              ? l.typeDescription
              : b.typeDescription,
        );
      } else {
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
        final isCatalogMode = query.isEmpty;

        final viewInsets = MediaQuery.of(context).viewInsets;
        final sheetHeight = MediaQuery.sizeOf(context).height * 0.78;
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
                    Icon(
                      isCatalogMode ? Icons.auto_stories_rounded : Icons.search_rounded,
                      color: activeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCatalogMode ? 'CELESTIAL CATALOGS' : 'CELESTIAL SEARCH',
                      style: TextStyle(
                        color: isNight ? const Color(0xFFFF8888) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (!isCatalogMode && _results.isNotEmpty) ...[
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
                    hintText: 'Search stars, planets, Messier, DSOs…',
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

              // Catalog Category Tabs (only shown when search input is empty)
              if (isCatalogMode) ...[
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: activeColor,
                  labelColor: activeColor,
                  unselectedLabelColor: isNight ? const Color(0x99FF8888) : Colors.white60,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: _catalogTabs.map((t) => Tab(text: t)).toList(),
                ),
              ],

              const Divider(height: 1, color: Colors.white12),

              // Body Content: TabBarView in Catalog mode, Results list in Search mode
              Expanded(
                child: isCatalogMode
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCatalogList(
                            _tonightsBest,
                            isNight,
                            activeColor,
                            emptyMessage: 'No visible objects found tonight',
                          ),
                          _buildCatalogList(
                            _planets,
                            isNight,
                            activeColor,
                          ),
                          _buildCatalogList(
                            _messier,
                            isNight,
                            activeColor,
                          ),
                          _buildCatalogList(
                            _stars,
                            isNight,
                            activeColor,
                          ),
                          _buildCatalogList(
                            _caldwell,
                            isNight,
                            activeColor,
                          ),
                          _buildCatalogList(
                            _dsos,
                            isNight,
                            activeColor,
                          ),
                        ],
                      )
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

  Widget _buildCatalogList(
    List<SkyObject> items,
    bool isNight,
    Color activeColor, {
    String emptyMessage = 'No items found in this catalog',
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(
            color: isNight ? const Color(0x66FF6666) : Colors.white38,
            fontSize: 13,
          ),
        ),
      );
    }
    return _buildResultsList(context, isNight, activeColor, items);
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
