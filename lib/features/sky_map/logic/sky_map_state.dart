import 'package:equatable/equatable.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_map_config.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_map_telescope_position.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object.dart';

final class SkyMapState extends Equatable {
  const SkyMapState({
    required this.utc,
    required this.observerLat,
    required this.observerLonEast,
    this.config = const SkyMapConfig(),
    this.timeMultiplier = 1.0,
    this.isTimePaused = false,
    this.fovDeg = 75.0,
    this.selected,
    this.telescope,
    this.locationReady = false,
    this.mapReady = false,
    this.statusLine,
  });

  factory SkyMapState.initial() => SkyMapState(
        utc: DateTime.now().toUtc(),
        observerLat: 0,
        observerLonEast: 0,
      );

  final DateTime utc;
  final double observerLat;
  final double observerLonEast;
  final SkyMapConfig config;
  final double timeMultiplier;
  final bool isTimePaused;
  final double fovDeg;
  final SkyObject? selected;
  final SkyMapTelescopePosition? telescope;
  final bool locationReady;
  final bool mapReady;
  final String? statusLine;

  SkyMapState copyWith({
    DateTime? utc,
    double? observerLat,
    double? observerLonEast,
    SkyMapConfig? config,
    double? timeMultiplier,
    bool? isTimePaused,
    double? fovDeg,
    SkyObject? selected,
    bool clearSelected = false,
    SkyMapTelescopePosition? telescope,
    bool clearTelescope = false,
    bool? locationReady,
    bool? mapReady,
    String? statusLine,
    bool clearStatus = false,
  }) {
    return SkyMapState(
      utc: utc ?? this.utc,
      observerLat: observerLat ?? this.observerLat,
      observerLonEast: observerLonEast ?? this.observerLonEast,
      config: config ?? this.config,
      timeMultiplier: timeMultiplier ?? this.timeMultiplier,
      isTimePaused: isTimePaused ?? this.isTimePaused,
      fovDeg: fovDeg ?? this.fovDeg,
      selected: clearSelected ? null : (selected ?? this.selected),
      telescope: clearTelescope ? null : (telescope ?? this.telescope),
      locationReady: locationReady ?? this.locationReady,
      mapReady: mapReady ?? this.mapReady,
      statusLine: clearStatus ? null : (statusLine ?? this.statusLine),
    );
  }

  @override
  List<Object?> get props => [
        utc,
        observerLat,
        observerLonEast,
        config,
        timeMultiplier,
        isTimePaused,
        fovDeg,
        selected,
        telescope,
        locationReady,
        mapReady,
        statusLine,
      ];
}
