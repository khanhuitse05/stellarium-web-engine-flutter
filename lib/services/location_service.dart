import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Position? _cachedPosition;

  /// Fast synchronous-like check (<10ms) for last known position to prevent
  /// day/night jumping while waiting for a fresh GPS fix.
  Future<Position?> getLastKnownPosition() async {
    if (_cachedPosition != null) return _cachedPosition;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        _cachedPosition = pos;
      }
      return pos;
    } catch (_) {
      return null;
    }
  }

  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeLimit = const Duration(seconds: 6),
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Location services are turned off. Enable GPS in system settings.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission is permanently denied. Enable Location in system settings.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location permission denied. Enable Location in system settings.',
      );
    }

    // Attempt fast fallback to last known position if available
    Position? lastKnown = _cachedPosition;
    try {
      lastKnown ??= await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _cachedPosition = lastKnown;
      }
    } catch (_) {}

    try {
      final fresh = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
      _cachedPosition = fresh;
      return fresh;
    } on TimeoutException {
      if (lastKnown != null) {
        return lastKnown;
      }
      throw const LocationServiceException(
        'GPS location timed out — using default coordinates.',
      );
    } catch (e) {
      if (lastKnown != null) {
        return lastKnown;
      }
      final str = e.toString().toLowerCase();
      if (str.contains('timeout') ||
          str.contains('time limit') ||
          str.contains('future not completed')) {
        throw const LocationServiceException(
          'GPS location timed out — using default coordinates.',
        );
      }
      throw const LocationServiceException(
        'Location unavailable — using default coordinates.',
      );
    }
  }
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
