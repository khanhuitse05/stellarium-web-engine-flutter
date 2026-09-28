import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

class TelescopeDashboardPage extends StatefulWidget {
  const TelescopeDashboardPage({super.key});

  @override
  State<TelescopeDashboardPage> createState() => _TelescopeDashboardPageState();
}

enum _MountState { parked, tracking, slewing }

class _TelescopeDashboardPageState extends State<TelescopeDashboardPage> {
  final _positionController =
      StreamController<SkyMapTelescopePosition?>.broadcast();
  late final SkyMapCubit _cubit;

  double _currentRaHours = 5.588; // Default M42 vicinity
  double _currentDecDeg = -5.39;
  double _targetRaHours = 5.588;
  double _targetDecDeg = -5.39;
  String _targetName = 'M 42 (Orion Nebula)';

  _MountState _mountState = _MountState.tracking;
  Timer? _slewTimer;

  static const List<Map<String, dynamic>> _quickTargets = [
    {
      'name': 'M 42 (Orion Nebula)',
      'ra': 5.588,
      'dec': -5.39,
      'type': 'Emission Nebula',
    },
    {
      'name': 'M 31 (Andromeda Galaxy)',
      'ra': 0.712,
      'dec': 41.27,
      'type': 'Spiral Galaxy',
    },
    {
      'name': 'M 45 (Pleiades)',
      'ra': 3.79,
      'dec': 24.11,
      'type': 'Open Cluster',
    },
    {
      'name': 'M 13 (Hercules Cluster)',
      'ra': 16.69,
      'dec': 36.46,
      'type': 'Globular Cluster',
    },
    {
      'name': 'Vega (Alpha Lyr)',
      'ra': 18.615,
      'dec': 38.78,
      'type': 'Bright Star',
    },
    {
      'name': 'Polaris (North Star)',
      'ra': 2.53,
      'dec': 89.26,
      'type': 'Pole Star',
    },
  ];

  @override
  void initState() {
    super.initState();
    _cubit = SkyMapCubit(
      telescopePositionStream: _positionController.stream,
    )..start();

    // Emit initial position
    _emitPosition();
  }

  @override
  void dispose() {
    _slewTimer?.cancel();
    _cubit.close();
    _positionController.close();
    super.dispose();
  }

  void _emitPosition() {
    if (_positionController.isClosed) return;
    _positionController.add(
      SkyMapTelescopePosition(
        raHours: _currentRaHours,
        decDeg: _currentDecDeg,
      ),
    );
  }

  void _startGoto({
    required double targetRa,
    required double targetDec,
    required String targetName,
  }) {
    _slewTimer?.cancel();
    setState(() {
      _targetRaHours = targetRa;
      _targetDecDeg = targetDec;
      _targetName = targetName;
      _mountState = _MountState.slewing;
    });

    const stepMs = 50;
    const slewSpeedDegPerSec = 4.0; // 4 deg/sec
    final stepDistanceDeg = slewSpeedDegPerSec * (stepMs / 1000.0);

    _slewTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      final deltaRaDeg = (_targetRaHours - _currentRaHours) * 15.0;
      final deltaDecDeg = _targetDecDeg - _currentDecDeg;
      final distDeg = sqrt(deltaRaDeg * deltaRaDeg + deltaDecDeg * deltaDecDeg);

      if (distDeg <= stepDistanceDeg) {
        // Arrived at target
        timer.cancel();
        setState(() {
          _currentRaHours = _targetRaHours;
          _currentDecDeg = _targetDecDeg;
          _mountState = _MountState.tracking;
        });
        _emitPosition();
      } else {
        final ratio = stepDistanceDeg / distDeg;
        setState(() {
          _currentRaHours += (deltaRaDeg * ratio) / 15.0;
          _currentDecDeg += deltaDecDeg * ratio;
        });
        _emitPosition();
      }
    });
  }

  void _parkMount() {
    _startGoto(
      targetRa: 0.0,
      targetDec: 90.0,
      targetName: 'Home Park Position',
    );
  }

  void _nudgeMount({required double deltaRaArcmin, required double deltaDecArcmin}) {
    setState(() {
      _currentRaHours += (deltaRaArcmin / 60.0) / 15.0;
      _currentDecDeg += deltaDecArcmin / 60.0;
    });
    _emitPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090C14),
      appBar: AppBar(
        title: const Text('Telescope Telemetry & GOTO'),
        backgroundColor: const Color(0xFF0F1420),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Center map on telescope position',
            icon: const Icon(Icons.my_location, color: Colors.lightGreenAccent),
            onPressed: () {
              _cubit.centerOnObject(
                SkyObject(
                  id: 'telescope',
                  name: 'Telescope Reticle',
                  kind: SkyObjectKind.star,
                  raHours: _currentRaHours,
                  decDeg: _currentDecDeg,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Upper Half: Interactive Sky Map with Reticle
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SkyMapWebView(cubit: _cubit),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatusIndicator(state: _mountState),
                        const SizedBox(width: 8),
                        Text(
                          switch (_mountState) {
                            _MountState.slewing => 'SLEWING TO TARGET',
                            _MountState.tracking => 'SIDEREAL TRACKING',
                            _MountState.parked => 'PARKED',
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          // Lower Half: Telescope Mount Control Panel
          Expanded(
            flex: 6,
            child: Container(
              color: const Color(0xFF0C101A),
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Mount Telemetry Cards
                  Row(
                    children: [
                      Expanded(
                        child: _TelemetryCard(
                          label: 'RIGHT ASCENSION',
                          value: hourToString(_currentRaHours),
                          subtitle:
                              '${(_currentRaHours * 15).toStringAsFixed(2)}° Decimal',
                          valueColor: Colors.lightGreenAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TelemetryCard(
                          label: 'DECLINATION',
                          value: formatDeclinationForSd(_currentDecDeg),
                          subtitle:
                              '${_currentDecDeg.toStringAsFixed(2)}° Decimal',
                          valueColor: Colors.lightGreenAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Target Info & Slew Control
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ACTIVE TARGET: $_targetName',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              icon: const Icon(Icons.home, size: 14),
                              label: const Text('Park', style: TextStyle(fontSize: 11)),
                              onPressed: _parkMount,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Target Coord: RA ${hourToString(_targetRaHours)}  ·  Dec ${formatDeclinationForSd(_targetDecDeg)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Quick Targets Selector
                  const Text(
                    'OBSERVING TARGETS (QUICK GOTO)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickTargets.map((t) {
                      final name = t['name'] as String;
                      final ra = t['ra'] as double;
                      final dec = t['dec'] as double;
                      final isSelected = _targetName == name;

                      return ActionChip(
                        label: Text(name),
                        backgroundColor: isSelected
                            ? Colors.cyan.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.06),
                        side: BorderSide(
                          color: isSelected ? Colors.cyanAccent : Colors.white12,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.cyanAccent : Colors.white,
                          fontSize: 12,
                        ),
                        onPressed: () => _startGoto(
                          targetRa: ra,
                          targetDec: dec,
                          targetName: name,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Manual Nudge Pad (Crosshair micro-adjustments)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MANUAL SLEW JOYSTICK',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Step: 10 arcmin',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: SizedBox(
                      width: 150,
                      height: 110,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: IconButton.filledTonal(
                              icon: const Icon(Icons.arrow_drop_up),
                              tooltip: 'North (+Dec)',
                              onPressed: () =>
                                  _nudgeMount(deltaRaArcmin: 0, deltaDecArcmin: 10),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: IconButton.filledTonal(
                              icon: const Icon(Icons.arrow_drop_down),
                              tooltip: 'South (-Dec)',
                              onPressed: () =>
                                  _nudgeMount(deltaRaArcmin: 0, deltaDecArcmin: -10),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton.filledTonal(
                              icon: const Icon(Icons.arrow_left),
                              tooltip: 'East (+RA)',
                              onPressed: () =>
                                  _nudgeMount(deltaRaArcmin: 10, deltaDecArcmin: 0),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton.filledTonal(
                              icon: const Icon(Icons.arrow_right),
                              tooltip: 'West (-RA)',
                              onPressed: () =>
                                  _nudgeMount(deltaRaArcmin: -10, deltaDecArcmin: 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.state});

  final _MountState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _MountState.slewing => Colors.amberAccent,
      _MountState.tracking => Colors.lightGreenAccent,
      _MountState.parked => Colors.orangeAccent,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
        ],
      ),
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
