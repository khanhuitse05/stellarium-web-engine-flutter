import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

class SearchAndFilterSheet extends StatefulWidget {
  const SearchAndFilterSheet({
    required this.cubit,
    required this.onSelectObject,
    super.key,
  });

  final SkyMapCubit cubit;
  final ValueChanged<SkyObject> onSelectObject;

  static Future<void> show(
    BuildContext context, {
    required SkyMapCubit cubit,
    required ValueChanged<SkyObject> onSelectObject,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchAndFilterSheet(
        cubit: cubit,
        onSelectObject: onSelectObject,
      ),
    );
  }

  @override
  State<SearchAndFilterSheet> createState() => _SearchAndFilterSheetState();
}

enum _FilterCategory {
  all('All', null),
  planets('Planets', SkyObjectKind.planet),
  stars('Stars', SkyObjectKind.star),
  messier('Messier / DSO', SkyObjectKind.messier),
  constellations('Constellations', SkyObjectKind.constellation);

  const _FilterCategory(this.label, this.kind);
  final String label;
  final SkyObjectKind? kind;
}

class _SearchAndFilterSheetState extends State<SearchAndFilterSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  _FilterCategory _category = _FilterCategory.all;

  bool _isLoading = false;
  List<SkyObject> _results = [];
  Timer? _debounce;

  static const List<String> _curatedQuickPicks = [
    'Jupiter',
    'Saturn',
    'Mars',
    'Moon',
    'M 42', // Orion Nebula
    'M 31', // Andromeda
    'M 45', // Pleiades
    'M 13', // Hercules Cluster
    'Sirius',
    'Betelgeuse',
    'Vega',
    'Polaris',
    'Orion',
    'Ursa Major',
    'Cassiopeia',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialSuggestions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialSuggestions() async {
    setState(() => _isLoading = true);
    final all = <SkyObject>[];
    for (final name in _curatedQuickPicks.take(8)) {
      final res = await widget.cubit.searchByName(name);
      if (res.isNotEmpty) {
        all.add(res.first);
      }
    }
    if (mounted) {
      setState(() {
        _results = all;
        _isLoading = false;
      });
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final q = query.trim();
      if (q.isEmpty) {
        await _loadInitialSuggestions();
        return;
      }
      setState(() => _isLoading = true);
      final res = await widget.cubit.searchByName(q);
      if (mounted) {
        setState(() {
          _results = res;
          _isLoading = false;
        });
      }
    });
  }

  List<SkyObject> get _filteredResults {
    if (_category == _FilterCategory.all) return _results;
    if (_category == _FilterCategory.messier) {
      return _results
          .where(
            (o) =>
                o.kind == SkyObjectKind.messier ||
                o.kind == SkyObjectKind.dso ||
                o.kind == SkyObjectKind.caldwell,
          )
          .toList();
    }
    return _results.where((o) => o.kind == _category.kind).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isNight = widget.cubit.state.config.nightMode;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Material(
          color: isNight ? const Color(0xFF140202) : const Color(0xFF12151D),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(
              color: isNight ? const Color(0xFF661111) : Colors.white12,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: TextStyle(
                color: isNight ? const Color(0xFFFF8888) : Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Search stars, planets, Messier, constellations…',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: isNight ? Colors.redAccent : Colors.blueAccent,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isNight
                    ? const Color(0x33FF0000)
                    : Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _FilterCategory.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _FilterCategory.values[index];
                final selected = _category == cat;
                return ChoiceChip(
                  label: Text(cat.label),
                  selected: selected,
                  selectedColor: isNight
                      ? const Color(0xFF881111)
                      : Theme.of(context).colorScheme.primary,
                  backgroundColor: isNight
                      ? const Color(0x22FF0000)
                      : Colors.white.withValues(alpha: 0.06),
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : (isNight ? Colors.redAccent : Colors.white70),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _category = cat);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.explore_off,
                              size: 48,
                              color: isNight ? Colors.red.shade300 : Colors.white24,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No items in this category'
                                  : 'No celestial objects matched "${_searchController.text}"',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredResults.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (context, index) {
                          final obj = _filteredResults[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: _ObjectLeadingIcon(
                              kind: obj.kind,
                              isNight: isNight,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    obj.name,
                                    style: TextStyle(
                                      color: isNight
                                          ? const Color(0xFFFF9999)
                                          : Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (obj.magnitude != null)
                                  Text(
                                    'Mag ${obj.magnitude!.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      color: isNight
                                          ? Colors.redAccent
                                          : Colors.amberAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Text(
                                    'RA ${hourToString(obj.raHours)}  ·  Dec ${formatDeclinationForSd(obj.decDeg)}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (obj.altDeg != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          obj.isAboveHorizon
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          size: 12,
                                          color: obj.isAboveHorizon
                                              ? Colors.greenAccent
                                              : Colors.white24,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Alt ${obj.altDeg! >= 0 ? '+' : ''}${obj.altDeg!.toStringAsFixed(0)}°',
                                          style: TextStyle(
                                            color: obj.isAboveHorizon
                                                ? Colors.greenAccent
                                                : Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onSelectObject(obj);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

class _ObjectLeadingIcon extends StatelessWidget {
  const _ObjectLeadingIcon({required this.kind, required this.isNight});

  final SkyObjectKind kind;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (kind) {
      SkyObjectKind.planet => (
          Icons.public,
          isNight ? Colors.redAccent : Colors.orangeAccent
        ),
      SkyObjectKind.moon => (
          Icons.nightlight_round,
          isNight ? Colors.redAccent : Colors.amberAccent
        ),
      SkyObjectKind.sun => (
          Icons.wb_sunny,
          isNight ? Colors.redAccent : Colors.yellowAccent
        ),
      SkyObjectKind.messier => (
          Icons.blur_circular,
          isNight ? Colors.redAccent : Colors.cyanAccent
        ),
      SkyObjectKind.caldwell || SkyObjectKind.dso => (
          Icons.flare,
          isNight ? Colors.redAccent : Colors.purpleAccent
        ),
      SkyObjectKind.constellation => (
          Icons.auto_awesome,
          isNight ? Colors.redAccent : Colors.tealAccent
        ),
      _ => (
          Icons.star,
          isNight ? Colors.redAccent : Colors.blueAccent
        ),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      radius: 18,
      child: Icon(icon, color: color, size: 18),
    );
  }
}
