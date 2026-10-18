import 'package:equatable/equatable.dart';
import 'package:mlastro_skymap/features/sky_map/model/sky_object_kind.dart';

/// Represents a celestial object (star, planet, deep-sky object, or constellation).
class SkyObject extends Equatable {
  const SkyObject({
    required this.id,
    required this.name,
    required this.kind,
    required this.raHours,
    required this.decDeg,
    this.magnitude,
    this.altDeg,
    this.azDeg,
    this.constellation,
    this.typeDescription,
    this.distance,
    this.phase,
    this.diameter,
    this.parallax,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final SkyObjectKind kind;
  final double raHours;
  final double decDeg;
  final double? magnitude;

  /// Horizontal altitude in degrees relative to observer horizon (-90° to +90°).
  final double? altDeg;

  /// Horizontal azimuth in degrees (0° North, 90° East, 180° South, 270° West).
  final double? azDeg;

  /// Constellation abbreviation or designation where this object resides (e.g. "Ori", "UMa").
  final String? constellation;

  /// Detailed object classification or astrophysical type (e.g. "Spiral Galaxy", "Red Supergiant").
  final String? typeDescription;

  /// Distance in AU (or light-years) if known.
  final double? distance;

  /// Phase illumination fraction from 0.0 (dark) to 1.0 (fully illuminated) for solar system bodies.
  final double? phase;

  /// Apparent angular diameter in arcseconds.
  final double? diameter;

  /// Stellar parallax in milliarcseconds (mas) if known.
  final double? parallax;

  /// Alternative catalog designations and nicknames.
  final List<String> aliases;

  /// Whether the object is currently above the local observer's horizon.
  bool get isAboveHorizon => (altDeg ?? 0) > 0;

  /// Whether this object is the Sun (needs eye/optics safety prompts).
  bool get isSunTarget {
    if (kind == SkyObjectKind.sun) return true;
    final n = name.trim().toLowerCase();
    if (n == 'sun') return true;
    final i = id.trim().toLowerCase();
    if (i == 'sun' || i == 'name sun') return true;
    return aliases.any((a) => a.trim().toLowerCase() == 'sun');
  }

  /// Whether this object is the Moon (e.g. for km distance display).
  bool get isMoonTarget {
    if (kind == SkyObjectKind.moon) return true;
    final n = name.trim().toLowerCase();
    if (n == 'moon') return true;
    final i = id.trim().toLowerCase();
    if (i == 'moon' || i == 'name moon') return true;
    return aliases.any((a) => a.trim().toLowerCase() == 'moon');
  }

  /// Formatted compass direction string derived from [azDeg] (e.g. "N", "NE", "SSE").
  String get compassDirection {
    if (azDeg == null) return '';
    final az = (azDeg! % 360 + 360) % 360;
    const directions = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];
    final index = ((az + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  SkyObject copyWith({
    String? id,
    String? name,
    SkyObjectKind? kind,
    double? raHours,
    double? decDeg,
    double? magnitude,
    double? altDeg,
    double? azDeg,
    String? constellation,
    String? typeDescription,
    double? distance,
    double? phase,
    double? diameter,
    double? parallax,
    List<String>? aliases,
  }) {
    return SkyObject(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      raHours: raHours ?? this.raHours,
      decDeg: decDeg ?? this.decDeg,
      magnitude: magnitude ?? this.magnitude,
      altDeg: altDeg ?? this.altDeg,
      azDeg: azDeg ?? this.azDeg,
      constellation: constellation ?? this.constellation,
      typeDescription: typeDescription ?? this.typeDescription,
      distance: distance ?? this.distance,
      phase: phase ?? this.phase,
      diameter: diameter ?? this.diameter,
      parallax: parallax ?? this.parallax,
      aliases: aliases ?? this.aliases,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        kind,
        raHours,
        decDeg,
        magnitude,
        altDeg,
        azDeg,
        constellation,
        typeDescription,
        distance,
        phase,
        diameter,
        parallax,
        aliases,
      ];
}
