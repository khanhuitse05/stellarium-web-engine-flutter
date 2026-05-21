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
