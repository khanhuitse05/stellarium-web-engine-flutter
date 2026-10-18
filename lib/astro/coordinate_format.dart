import 'dart:math' as math;

double normalizeRaHours(double raHours) {
  var h = raHours % 24.0;
  if (h < 0) {
    h += 24.0;
  }
  return h;
}

String hourToString(double hour) {
  final hh = normalizeRaHours(hour);
  final hours = hh.floor();
  final mins = (hh * 60).floor() % 60;
  final secs = (hh * 3600).floor() % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${mins.toString().padLeft(2, '0')}:'
      '${secs.toString().padLeft(2, '0')}';
}

String formatRaHoursForDisplay(double raHours) {
  final parts = hourToString(raHours).split(':');
  return '${parts[0]}h ${parts[1]}m ${parts[2]}s';
}

String formatDecDegreesForDisplay(double decDeg) {
  final decStr = formatDeclinationForSd(decDeg);
  final t = decStr.replaceFirst(RegExp(r'^[+-]'), '');
  final p = t.split(':');
  if (p.length >= 3) {
    final sign = decStr.startsWith('-') ? '-' : '+';
    return '$sign${p[0]}° ${p[1]}\' ${p[2]}"';
  }
  return '${decDeg.toStringAsFixed(4)}°';
}

String formatDeclinationForSd(double dec) {
  final sign = dec < 0 ? '-' : '+';
  var ad = dec.abs();
  var d = ad.floor();
  ad = (ad - d) * 60;
  var m = ad.floor();
  ad = (ad - m) * 60;
  var s = ad.round();
  if (s >= 60) {
    s -= 60;
    m++;
  }
  if (m >= 60) {
    m -= 60;
    d++;
  }
  return '$sign${d.toString().padLeft(2, '0')}:'
      '${m.toString().padLeft(2, '0')}:'
      '${s.toString().padLeft(2, '0')}';
}

double _normDeg360(double x) {
  var v = x % 360;
  if (v < 0) v += 360;
  return v;
}

/// Julian date (UT) for apparent sidereal time.
double julianDateUtc(DateTime utc) {
  final u = utc.toUtc();
  var y = u.year;
  var m = u.month;
  final d = u.day +
      (u.hour + (u.minute + (u.second + u.millisecond / 1000) / 60) / 60) / 24;
  if (m <= 2) {
    m += 12;
    y -= 1;
  }
  final a = y ~/ 100;
  final b = 2 - a + a ~/ 4;
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      d +
      b -
      1524.5;
}

double _gmstDegrees(double jdUt) {
  final t = (jdUt - 2451545.0) / 36525.0;
  final t2 = t * t;
  final t3 = t2 * t;
  var gmst = 280.46061837 +
      360.98564736629 * (jdUt - 2451545.0) +
      0.000387933 * t2 -
      t3 / 38710000;
  return _normDeg360(gmst);
}

/// Converts celestial equatorial coordinates (RA hours, Dec degrees) to topocentric
/// horizontal coordinates (altitude and azimuth in degrees) for observer location and time.
({double altDeg, double azDeg}) equatorialRaDecToAltAz({
  required double raHours,
  required double decDeg,
  required double latDeg,
  required double lonEastDeg,
  DateTime? timeUtc,
}) {
  final jd = julianDateUtc(timeUtc ?? DateTime.now().toUtc());
  final gmst = _gmstDegrees(jd);
  final lstDeg = _normDeg360(gmst + lonEastDeg);
  final raDeg = raHours * 15;
  final hDeg = _normDeg360(lstDeg - raDeg);
  final h = hDeg * (3.141592653589793 / 180);
  final dec = decDeg * (3.141592653589793 / 180);
  final lat = latDeg * (3.141592653589793 / 180);

  final sinAlt =
      math.sin(dec) * math.sin(lat) + math.cos(dec) * math.cos(lat) * math.cos(h);
  final altRad = math.asin(sinAlt.clamp(-1.0, 1.0));

  final cosAz = (math.sin(dec) - math.sin(altRad) * math.sin(lat)) /
      (math.cos(altRad) * math.cos(lat));
  final az = math.acos(cosAz.clamp(-1.0, 1.0));
  final sinH = math.sin(h);
  final azRad = sinH > 0 ? 2 * 3.141592653589793 - az : az;

  return (
    altDeg: altRad * (180 / 3.141592653589793),
    azDeg: _normDeg360(azRad * (180 / 3.141592653589793)),
  );
}

/// Formats astronomical distance (in AU) into a human-readable display string using AU or light-years,
/// or km for the Moon (and near-Earth distances < 0.005 AU).
/// - Moon / near-Earth (< 0.005 AU or isMoon): e.g. "384,400 km".
/// - Solar system: e.g. "5.70 AU", "1.52 AU".
/// - Deep sky / stars: e.g. "4.2 ly", "25.0 kly", "2.54 Mly".
String formatDistanceForDisplay(double distanceAu, {bool isMoon = false}) {
  if (distanceAu.isNaN || distanceAu <= 0) return '';
  const auPerLy = 63241.077;
  const kmPerAu = 149597870.7;

  if (isMoon || distanceAu < 0.005) {
    final km = (distanceAu * kmPerAu).round();
    final formattedKm = km.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '$formattedKm km';
  }

  if (distanceAu >= auPerLy * 0.1) {
    final ly = distanceAu / auPerLy;
    if (ly >= 1000000) {
      return '${(ly / 1000000).toStringAsFixed(2)} Mly';
    } else if (ly >= 1000) {
      return '${(ly / 1000).toStringAsFixed(1)} kly';
    } else if (ly >= 10) {
      return '${ly.toStringAsFixed(1)} ly';
    } else {
      return '${ly.toStringAsFixed(2)} ly';
    }
  } else if (distanceAu >= 0.01) {
    return '${distanceAu.toStringAsFixed(2)} AU';
  } else {
    return '${distanceAu.toStringAsFixed(4)} AU';
  }
}

/// Formats angular diameter (in arcseconds) into a human-readable display string.
/// e.g. 33.82" -> 33.82", 31.4' -> 31.4', 1.2° -> 1.2°.
String formatDiameterForDisplay(double diameterArcsec) {
  if (diameterArcsec.isNaN || diameterArcsec <= 0) return '';
  if (diameterArcsec >= 3600) {
    final deg = diameterArcsec / 3600;
    return '${deg.toStringAsFixed(1)}°';
  } else if (diameterArcsec >= 60) {
    final arcmin = diameterArcsec / 60;
    return '${arcmin.toStringAsFixed(1)}\'';
  } else {
    return '${diameterArcsec.toStringAsFixed(2)}"';
  }
}

/// Formats stellar parallax (in milliarcseconds, mas).
/// e.g. 14.4 mas.
String formatParallaxForDisplay(double parallaxMas) {
  if (parallaxMas.isNaN || parallaxMas <= 0) return '';
  return '${parallaxMas.toStringAsFixed(1)} mas';
}

