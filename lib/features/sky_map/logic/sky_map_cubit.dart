import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mlastro_skymap/astro/coordinate_format.dart';
import 'package:mlastro_skymap/features/sky_map/logic/sky_map_state.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_map_config.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_map_telescope_position.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object_kind.dart';
import 'package:mlastro_skymap/services/location_service.dart';
import 'package:mlastro_skymap/utils/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SkyMapCubit extends Cubit<SkyMapState> {
  SkyMapCubit({
    LocationService? location,
    Stream<SkyMapTelescopePosition?>? telescopePositionStream,
    SkyMapConfig? initialConfig,
  })  : _location = location ?? LocationService(),
        _telescopePositionStream = telescopePositionStream,
        super(
          SkyMapState.initial().copyWith(
            config: initialConfig ?? const SkyMapConfig(),
          ),
        );

  final LocationService _location;
  final Stream<SkyMapTelescopePosition?>? _telescopePositionStream;

  WebViewController? _web;
  Timer? _utcTimer;
  StreamSubscription<SkyMapTelescopePosition?>? _telescopeSub;

  void attachWebController(WebViewController controller) {
    _web = controller;
  }

  Future<void> start() async {
    await _loadLocation();
    _utcTimer?.cancel();
    _utcTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isTimePaused) return;
      final stepSeconds = (state.timeMultiplier).round();
      final next = state.utc.add(Duration(seconds: stepSeconds));
      emit(state.copyWith(utc: next));
      unawaited(_pushObserverToMap(next));
    });

    _telescopeSub?.cancel();
    final stream = _telescopePositionStream;
    if (stream != null) {
      _telescopeSub = stream.listen(_onTelescopePosition);
    }
  }

  void _onTelescopePosition(SkyMapTelescopePosition? position) {
    if (isClosed) return;
    if (position == null) {
      emit(state.copyWith(clearTelescope: true));
      unawaited(_pushTelescopeToMap(null));
      return;
    }
    emit(state.copyWith(telescope: position));
    unawaited(_pushTelescopeToMap(position));
  }

  void onMapReady() {
    emit(state.copyWith(mapReady: true, clearStatus: true));
    unawaited(_pushObserverToMap(state.utc));
    unawaited(_pushConfigToMap(state.config));
    if (state.telescope != null) {
      unawaited(_pushTelescopeToMap(state.telescope));
    }
  }

  void onMapError(String message) {
    xLog.e('SkyMap: $message');
    emit(state.copyWith(statusLine: message));
  }

  void onObjectSelected(Map<String, dynamic> payload) {
    final object = _objectFromPayload(payload);
    if (object != null) {
      _logSelected(object, source: 'tap');
      emit(state.copyWith(selected: object));
    }
  }

  void deselectObject() {
    emit(state.copyWith(clearSelected: true));
    unawaited(_runMapJs('window.MlastroSky.dismissPanel();'));
  }

  Future<void> updateConfig(SkyMapConfig config) async {
    emit(state.copyWith(config: config));
    await _pushConfigToMap(config);
  }

  Future<void> setNightMode(bool active) async {
    final next = state.config.copyWith(nightMode: active);
    emit(state.copyWith(config: next));
    await _runMapJs('window.MlastroSky.setNightMode($active);');
  }

  Future<void> setObserverLocation({
    required double lat,
    required double lonEast,
  }) async {
    emit(
      state.copyWith(
        observerLat: lat,
        observerLonEast: lonEast,
        locationReady: true,
        clearStatus: true,
      ),
    );
    await _pushObserverToMap(state.utc);
  }

  Future<void> setTime(DateTime utc, {bool? paused}) async {
    emit(state.copyWith(utc: utc, isTimePaused: paused ?? state.isTimePaused));
    await _pushObserverToMap(utc);
  }

  void setTimeRate(double multiplier) {
    emit(
      state.copyWith(
        timeMultiplier: multiplier,
        isTimePaused: multiplier == 0,
      ),
    );
  }

  void toggleTimePause() {
    emit(state.copyWith(isTimePaused: !state.isTimePaused));
  }

  Future<void> resetTimeToNow() async {
    final now = DateTime.now().toUtc();
    emit(
      state.copyWith(
        utc: now,
        timeMultiplier: 1.0,
        isTimePaused: false,
      ),
    );
    await _pushObserverToMap(now);
  }

  Future<void> lookTowards({
    required double azDeg,
    required double altDeg,
  }) async {
    await _runMapJs('window.MlastroSky.lookTowards($azDeg, $altDeg);');
  }

  Future<void> lookZenith() async {
    await lookTowards(azDeg: 180, altDeg: 89.9);
  }

  Future<void> lookCardinal(double azDeg) async {
    await lookTowards(azDeg: azDeg, altDeg: 25.0);
  }

  Future<void> setFov(double fovDeg) async {
    emit(state.copyWith(fovDeg: fovDeg));
    await _runMapJs('window.MlastroSky.setFov($fovDeg);');
  }

  Future<void> zoomIn() async {
    await _runMapJs('window.MlastroSky.zoomBy(-10);');
  }

  Future<void> zoomOut() async {
    await _runMapJs('window.MlastroSky.zoomBy(10);');
  }

  Future<void> _loadLocation() async {
    try {
      final pos = await _location.getCurrentPosition(
        accuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 12),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            observerLat: pos.latitude,
            observerLonEast: pos.longitude,
            locationReady: true,
            clearStatus: true,
          ),
        );
        await _pushObserverToMap(state.utc);
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            locationReady: false,
            statusLine:
                'Location unavailable — enable location in system settings. ($e)',
          ),
        );
      }
    }
  }

  Future<void> _pushObserverToMap(DateTime utc) async {
    final web = _web;
    if (web == null || !state.mapReady) return;
    final iso = utc.toIso8601String();
    final lat = state.observerLat;
    final lon = state.observerLonEast;
    try {
      await web.runJavaScript(
        'window.MlastroSky.setObserver($lat, $lon, ${jsonEncode(iso)});',
      );
    } catch (_) {}
  }

  Future<void> _pushConfigToMap(SkyMapConfig config) async {
    final web = _web;
    if (web == null || !state.mapReady) return;
    try {
      await web.runJavaScript(
        'window.MlastroSky.setConfig(${jsonEncode(config.toJson())});',
      );
    } catch (_) {}
  }

  Future<void> _pushTelescopeToMap(SkyMapTelescopePosition? pos) async {
    final web = _web;
    if (web == null || !state.mapReady) return;
    try {
      if (pos == null) {
        await web.runJavaScript('window.MlastroSky.setTelescope(null);');
      } else {
        await web.runJavaScript(
          'window.MlastroSky.setTelescope(${pos.raHours}, ${pos.decDeg}, ${pos.isTracking}, ${pos.isSlewing});',
        );
      }
    } catch (_) {}
  }

  Future<void> centerOnTelescope() async {
    final t = state.telescope;
    if (t == null) return;
    final web = _web;
    if (web == null || !state.mapReady) return;
    try {
      await web.runJavaScript(
        'window.MlastroSky.centerOn(${t.raHours}, ${t.decDeg});',
      );
    } catch (_) {}
  }

  Future<void> centerOnObject(SkyObject object) async {
    final web = _web;
    if (web == null || !state.mapReady) return;
    _logSelected(object, source: 'search');
    emit(state.copyWith(selected: object));
    try {
      await web.runJavaScript(
        'window.MlastroSky.centerOn(${object.raHours}, ${object.decDeg});',
      );
    } catch (_) {}
  }

  Future<void> selectById(String id) async {
    final web = _web;
    if (web == null || !state.mapReady) return;
    try {
      await web.runJavaScript(
        'window.MlastroSky.selectById(${jsonEncode(id)});',
      );
    } catch (_) {}
  }

  Future<List<SkyObject>> searchByName(String query) async {
    final web = _web;
    if (web == null || !state.mapReady) return const [];
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      final raw = await web.runJavaScriptReturningResult(
        'window.MlastroSky.search(${jsonEncode(q)})',
      );
      return _parseSearchResults(raw);
    } catch (_) {
      return const [];
    }
  }

  Future<void> resumeMapInteraction() async {
    await _runMapJs('window.MlastroSky.resumeInteraction();');
  }

  Future<void> _runMapJs(String script) async {
    final web = _web;
    if (web == null || !state.mapReady) return;
    try {
      await web.runJavaScript(script);
    } catch (_) {}
  }

  List<SkyObject> _parseSearchResults(Object? raw) {
    if (raw == null) return const [];
    try {
      final text = raw is String ? raw : raw.toString();
      final decoded = jsonDecode(text);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => _objectFromPayload(Map<String, dynamic>.from(e)))
          .whereType<SkyObject>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  SkyObject? _objectFromPayload(Map<String, dynamic> payload) {
    final name = payload['name']?.toString();
    final id = payload['id']?.toString();
    final ra = payload['raHours'];
    final dec = payload['decDeg'];
    if (name == null || id == null || ra is! num || dec is! num) return null;
    return SkyObject(
      id: id,
      name: name,
      kind: _kindFromString(payload['kind']?.toString()),
      raHours: ra.toDouble(),
      decDeg: dec.toDouble(),
      magnitude: (payload['magnitude'] as num?)?.toDouble(),
      altDeg: (payload['altDeg'] as num?)?.toDouble(),
      azDeg: (payload['azDeg'] as num?)?.toDouble(),
      constellation: payload['constellation']?.toString(),
      typeDescription: payload['typeDescription']?.toString(),
      distance: (payload['distance'] as num?)?.toDouble(),
      aliases: (payload['aliases'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  SkyObjectKind _kindFromString(String? kind) {
    return switch (kind) {
      'planet' => SkyObjectKind.planet,
      'dso' => SkyObjectKind.dso,
      'messier' => SkyObjectKind.messier,
      'constellation' => SkyObjectKind.constellation,
      _ => SkyObjectKind.star,
    };
  }

  void _logSelected(SkyObject object, {required String source}) {
    final mag = object.magnitude != null
        ? ' mag=${object.magnitude!.toStringAsFixed(1)}'
        : '';
    final alt = object.altDeg != null
        ? ' Alt=${object.altDeg!.toStringAsFixed(1)}°'
        : '';
    final az = object.azDeg != null
        ? ' Az=${object.azDeg!.toStringAsFixed(1)}°'
        : '';
    xLog.d(
      'SkyMap: selected via $source — ${object.name} '
      '(${object.kind.name}, id=${object.id}) '
      'RA ${hourToString(object.raHours)} '
      'Dec ${formatDeclinationForSd(object.decDeg)}$mag$alt$az',
    );
  }

  @override
  Future<void> close() async {
    _utcTimer?.cancel();
    await _telescopeSub?.cancel();
    return super.close();
  }
}
