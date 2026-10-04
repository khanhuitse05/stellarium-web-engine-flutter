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
    this.sensorTrackingActive = false,
    this.sensorAvailable = false,
    this.statusLine,
  });

  /// Default longitude derived from device timezone (15° per hour of UTC offset).
  /// This ensures local solar time matches the device clock so night tests render night sky immediately.
  static double get defaultLongitudeEast {
    final offsetHours = DateTime.now().timeZoneOffset.inMinutes / 60.0;
    return (offsetHours * 15.0).clamp(-180.0, 180.0);
  }

  /// Default observer latitude (Vietnam / tropical standard default).
  static const double defaultLatitude = 10.0;

  factory SkyMapState.initial({
    double? initialLat,
    double? initialLonEast,
  }) =>
      SkyMapState(
        utc: DateTime.now().toUtc(),
        observerLat: initialLat ?? defaultLatitude,
        observerLonEast: initialLonEast ?? defaultLongitudeEast,
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
  final bool sensorTrackingActive;
  final bool sensorAvailable;
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
    bool? sensorTrackingActive,
    bool? sensorAvailable,
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
      sensorTrackingActive: sensorTrackingActive ?? this.sensorTrackingActive,
      sensorAvailable: sensorAvailable ?? this.sensorAvailable,
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
        sensorTrackingActive,
        sensorAvailable,
        statusLine,
      ];
}
