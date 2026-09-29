// Low-precision Sun / Moon / planet equatorial coordinates for finder-chart plotting
// and sky-map display (~0.1–1° class).

import 'dart:math' as math;

import 'coordinate_format.dart';

double _deg2rad(double d) => d * math.pi / 180;
double _rad2deg(double r) => r * 180 / math.pi;

double _normDeg(double x) {
  var v = x % 360;
  if (v < 0) v += 360;
  return v;
}

double _meanObliquityRad(double jd) {
  final t = (jd - 2451545) / 36525;
  final sec =
      46.815 * t + 0.00059 * t * t - 0.001813 * t * t * t + 21.448;
  return _deg2rad(23.439291 - sec / 3600);
}

({double raHours, double decDeg}) _eclipticToEquatorial({
  required double lon,
  required double lat,
  required double eps,
}) {
  final sinLat = math.sin(lat);
  final cosLat = math.cos(lat);
  final sinLon = math.sin(lon);
  final cosLon = math.cos(lon);
  final sinE = math.sin(eps);
  final cosE = math.cos(eps);

  final ra = math.atan2(sinLon * cosE - math.tan(lat) * sinE, cosLon);
  final dec = math.asin(sinLat * cosE + cosLat * sinE * sinLon);
  var raH = _rad2deg(ra) / 15;
  if (raH < 0) raH += 24;
  return (raHours: raH, decDeg: _rad2deg(dec));
}

/// Sun's approximate apparent geocentric equatorial coordinates.
({double raHours, double decDeg}) sunRaDec(DateTime utc) {
  final jd = julianDateUtc(utc);
  final n = jd - 2451545;
  final l = _deg2rad((280.46 + 0.9856474 * n) % 360);
  final g = _deg2rad((357.528 + 0.9856003 * n) % 360);
  final lambda = l +
      _deg2rad(1.915) * math.sin(g) +
      _deg2rad(0.02) * math.sin(2 * g);
  final eps = _meanObliquityRad(jd);
  return _eclipticToEquatorial(lon: lambda, lat: 0, eps: eps);
}

/// Moon — truncated model (sufficient for sky-map catalog display).
({double raHours, double decDeg}) moonRaDec(DateTime utc) {
  final jd = julianDateUtc(utc);
  final d = jd - 2451545;
  final lMoonRad = _deg2rad((218.316 + 13.176396 * d) % 360);
  final mMoonRad = _deg2rad((134.963 + 13.064993 * d) % 360);
  final fMoonRad = _deg2rad((93.272 + 13.229350 * d) % 360);
  final lon = lMoonRad + _deg2rad(6.289) * math.sin(mMoonRad);
  final lat = _deg2rad(5.128) * math.sin(fMoonRad);
  final eps = _meanObliquityRad(jd);
  return _eclipticToEquatorial(lon: lon, lat: lat, eps: eps);
}

({double x, double y, double z}) _helioEclipticRect({
  required double d,
  required double n,
  required double i,
  required double w,
  required double a,
  required double e,
  required double meanAnomalyDeg,
}) {
  final meanAnomalyRad = _deg2rad(_normDeg(meanAnomalyDeg));
  final wr = _deg2rad(w);
  final ir = _deg2rad(i);
  final nodeRad = _deg2rad(n);

  var bigE = meanAnomalyRad;
  for (var k = 0; k < 16; k++) {
    bigE = meanAnomalyRad + e * math.sin(bigE);
  }

  final xv = a * (math.cos(bigE) - e);
  final yv = a * (math.sqrt(math.max(0.0, 1 - e * e)) * math.sin(bigE));
  final v = math.atan2(yv, xv);
  final r = math.sqrt(xv * xv + yv * yv);

  final vw = v + wr;
  final xh = r *
      (math.cos(nodeRad) * math.cos(vw) -
          math.sin(nodeRad) * math.sin(vw) * math.cos(ir));
  final yh = r *
      (math.sin(nodeRad) * math.cos(vw) +
          math.cos(nodeRad) * math.sin(vw) * math.cos(ir));
  final zh = r * (math.sin(vw) * math.sin(ir));
  return (x: xh, y: yh, z: zh);
}

({double raHours, double decDeg}) _eclipticRectToRaDec({
  required double xg,
  required double yg,
  required double zg,
  required DateTime utc,
}) {
  final lon = math.atan2(yg, xg);
  final lat = math.atan2(zg, math.sqrt(xg * xg + yg * yg));
  final eps = _meanObliquityRad(julianDateUtc(utc));
  return _eclipticToEquatorial(lon: lon, lat: lat, eps: eps);
}

/// Major planets — geocentric ecliptic from simplified Kepler + Earth vector.
({double raHours, double decDeg}) planetRaDec(String name, DateTime utc) {
  final jd = julianDateUtc(utc);
  final d = jd - 2451543.5; // Paul Schlyter elements use epoch 1999 Dec 31.0 UT

  final sunGeocentric = _helioEclipticRect(
    d: d,
    n: 0,
    i: 0,
    w: 282.9404 + 0.0000470935 * d,
    a: 1.000000,
    e: 0.016709 - 1.151e-9 * d,
    meanAnomalyDeg: 356.0470 + 0.9856002585 * d,
  );

  ({double raHours, double decDeg}) fromHelio({
    required double n,
    required double i,
    required double w,
    required double a,
    required double e,
    required double meanAnomaly0,
    required double meanMotion,
  }) {
    final h = _helioEclipticRect(
      d: d,
      n: n,
      i: i,
      w: w,
      a: a,
      e: e,
      meanAnomalyDeg: meanAnomaly0 + meanMotion * d,
    );
    final xg = h.x + sunGeocentric.x;
    final yg = h.y + sunGeocentric.y;
    final zg = h.z + sunGeocentric.z;
    return _eclipticRectToRaDec(xg: xg, yg: yg, zg: zg, utc: utc);
  }

  switch (name.toLowerCase()) {
    case 'mercury':
      return fromHelio(
        n: 48.3313,
        i: 7.0047,
        w: 29.1241,
        a: 0.387098,
        e: 0.205635,
        meanAnomaly0: 168.6562,
        meanMotion: 4.0923344368,
      );
    case 'venus':
      return fromHelio(
        n: 76.6799,
        i: 3.3946,
        w: 54.8910,
        a: 0.723330,
        e: 0.006773,
        meanAnomaly0: 48.0052,
        meanMotion: 1.6021302444,
      );
    case 'mars':
      return fromHelio(
        n: 49.5574,
        i: 1.8497,
        w: 286.5016,
        a: 1.523688,
        e: 0.093405,
        meanAnomaly0: 18.6021,
        meanMotion: 0.52402068,
      );
    case 'jupiter':
      return fromHelio(
        n: 100.4542,
        i: 1.3030,
        w: 273.8777,
        a: 5.20256,
        e: 0.048498,
        meanAnomaly0: 19.8950,
        meanMotion: 0.08308488,
      );
    case 'saturn':
      return fromHelio(
        n: 113.6634,
        i: 2.4886,
        w: 339.3939,
        a: 9.55475,
        e: 0.055546,
        meanAnomaly0: 316.9670,
        meanMotion: 0.03321256,
      );
    case 'uranus':
      return fromHelio(
        n: 74.0005,
        i: 0.7733,
        w: 96.6612,
        a: 19.18171,
        e: 0.047318,
        meanAnomaly0: 142.5905,
        meanMotion: 0.01176917,
      );
    case 'neptune':
      return fromHelio(
        n: 131.7806,
        i: 1.7700,
        w: 272.8461,
        a: 30.05826,
        e: 0.008606,
        meanAnomaly0: 260.2471,
        meanMotion: 0.00630302,
      );
    default:
      return (raHours: 0, decDeg: 0);
  }
}

/// Sun, Moon, and major-planet RA/Dec in one entry point (low precision).
({double raHours, double decDeg}) celestialRaDec(String name, DateTime utc) {
  final key = name.toLowerCase().trim();
  switch (key) {
    case 'sun':
      return sunRaDec(utc);
    case 'moon':
    case 'luna':
      return moonRaDec(utc);
    default:
      return planetRaDec(name, utc);
  }
}
