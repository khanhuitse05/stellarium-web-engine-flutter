import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';

/// Astronomical orientation of the device's line of sight into the sky.
class SkyOrientation {
  const SkyOrientation({
    required this.azimuthDeg,
    required this.altitudeDeg,
    required this.rollDeg,
  });

  /// Compass azimuth heading in degrees [0, 360).
  /// 0 = North, 90 = East, 180 = South, 270 = West.
  final double azimuthDeg;

  /// Elevation angle above horizon in degrees [-90, +90].
  /// 0 = Horizon, +90 = Zenith, -90 = Nadir.
  final double altitudeDeg;

  /// Roll angle around the line of sight in degrees [-180, +180].
  final double rollDeg;

  @override
  String toString() =>
      'SkyOrientation(az: ${azimuthDeg.toStringAsFixed(1)}°, alt: ${altitudeDeg.toStringAsFixed(1)}°, roll: ${rollDeg.toStringAsFixed(1)}°)';
}

/// Service that streams real-time physical device pointing angles for AR sky tracking.
class SkyMapOrientationService {
  SkyOrientation? _previous;

  /// Whether sensor tracking is supported on the current platform/device.
  bool get isSupported => RotationSensor.isPlatformSupported;

  /// Request runtime sensor permission if required by the platform.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      if (RotationSensor.shouldRequestPermission) {
        final perm = await RotationSensor.requestPermission();
        return perm.name == 'granted';
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reset the smoothing filter state.
  void reset() {
    _previous = null;
  }

  /// Stream orientation updates at the specified interval with low-pass jitter smoothing.
  Stream<SkyOrientation> stream({
    Duration interval = const Duration(milliseconds: 33),
    double smoothing = 0.35,
  }) {
    if (!isSupported) {
      return const Stream.empty();
    }

    RotationSensor.samplingPeriod = interval;
    try {
      RotationSensor.referenceFrame = ReferenceFrame.trueNorth;
    } catch (_) {
      try {
        RotationSensor.referenceFrame = ReferenceFrame.magneticNorth;
      } catch (_) {}
    }

    return RotationSensor.orientationStream.map((event) {
      final orientation = calculateOrientation(
        event,
        previous: _previous,
        smoothing: smoothing,
      );
      _previous = orientation;
      return orientation;
    });
  }

  /// Computes horizontal astronomical pointing coordinates from an orientation event.
  static SkyOrientation calculateOrientation(
    OrientationEvent event, {
    SkyOrientation? previous,
    double smoothing = 0.35,
  }) {
    final m = event.rotationMatrix;

    // In the Earth-based ENU world coordinate system:
    // X = East, Y = North, Z = Zenith (Sky).
    // The device rotation matrix R maps body coordinates to world coordinates:
    // column(0) = [a, d, g] is device +X axis (screen right) in world frame.
    // column(1) = [b, e, h] is device +Y axis (screen top) in world frame.
    // column(2) = [c, f, i] is device +Z axis (out of front screen) in world frame.
    //
    // The optical line of sight points out through the back of the phone: -Z_device.
    // Therefore: v_look = -column(2) = [-c, -f, -i].
    final c = m.c;
    final f = m.f;
    final i = m.i;

    final zLook = (-i).clamp(-1.0, 1.0);
    final rawAltRad = math.asin(zLook);
    final rawAltDeg = rawAltRad * 180.0 / math.pi;

    // Azimuth:
    // In world frame, Y is North and X is East.
    // Horizontal component of line of sight is (East: -c, North: -f).
    final horizDistSq = c * c + f * f;
    double rawAzRad;
    if (horizDistSq > 0.001) {
      rawAzRad = math.atan2(-c, -f);
    } else {
      // Near Zenith (pointing straight up) or Nadir (straight down),
      // heading is determined by the top edge of the phone (+Y_device: [b, e, h]).
      final b = m.b;
      final e = m.e;
      rawAzRad = math.atan2(-b, -e);
    }
    var rawAzDeg = rawAzRad * 180.0 / math.pi;
    if (rawAzDeg < 0.0) rawAzDeg += 360.0;
    rawAzDeg %= 360.0;

    // Roll around line of sight:
    // Phone UP vector in world frame: column 1 [b, e, h]
    // Phone RIGHT vector in world frame: column 0 [a, d, g]
    // g is the vertical (Z) component of the screen right vector.
    // In the camera plane, horizontal right is [-f, c, 0].
    double rawRollDeg = 0.0;
    final horizNorm = math.sqrt(horizDistSq);
    if (horizNorm > 0.05) {
      final a = m.a;
      final d = m.d;
      final g = m.g;
      final cosRoll = (a * (-f) + d * c) / horizNorm;
      final sinRoll = -g;
      rawRollDeg = math.atan2(sinRoll, cosRoll) * 180.0 / math.pi;
    }

    if (previous == null) {
      return SkyOrientation(
        azimuthDeg: rawAzDeg,
        altitudeDeg: rawAltDeg,
        rollDeg: rawRollDeg,
      );
    }

    // Exponential moving average filter with shortest-arc angular wrap-around
    final smoothedAz = _smoothAngleDeg(previous.azimuthDeg, rawAzDeg, smoothing);
    final smoothedAlt = previous.altitudeDeg + (rawAltDeg - previous.altitudeDeg) * smoothing;
    final smoothedRoll = _smoothAngleDeg(previous.rollDeg, rawRollDeg, smoothing);

    return SkyOrientation(
      azimuthDeg: smoothedAz,
      altitudeDeg: smoothedAlt,
      rollDeg: smoothedRoll,
    );
  }

  static double _smoothAngleDeg(double prev, double target, double factor) {
    var diff = ((target - prev + 540.0) % 360.0) - 180.0;
    var result = (prev + diff * factor) % 360.0;
    if (result < 0.0) result += 360.0;
    return result;
  }
}
