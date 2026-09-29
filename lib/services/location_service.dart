import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
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
    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
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
