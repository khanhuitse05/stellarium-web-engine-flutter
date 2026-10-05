import 'package:equatable/equatable.dart';

/// Configuration for mount safety limit overlay rendering on the sky sphere.
class SkyMapMountLimits extends Equatable {
  const SkyMapMountLimits({
    this.minAltDeg = 0,
    this.maxAltDeg = 90,
    this.meridianEastMinutes = 0,
    this.meridianWestMinutes = 0,
    this.activePierSide,
    this.isGem = true,
    this.labels = const {},
    this.enabled = true,
  });

  /// Horizon / minimum altitude limit in degrees (e.g. 0° to 30°).
  final double minAltDeg;

  /// Overhead / maximum altitude limit in degrees (60° to 90°).
  /// 90° disables overhead limit in OnStep.
  final double maxAltDeg;

  /// East meridian limit in minutes of hour angle past meridian.
  final double meridianEastMinutes;

  /// West meridian limit in minutes of hour angle past meridian.
  final double meridianWestMinutes;

  /// Current active mount pier side ('East', 'West', or null).
  final String? activePierSide;

  /// Whether the mount is German Equatorial (GEM).
  /// Non-GEM mounts (Fork / Alt-Az) do not enforce meridian limits.
  final bool isGem;

  /// Optional display labels for lines (e.g. overhead, horizon, merE, merW).
  final Map<String, String> labels;

  /// Master switch for rendering this overlay on the canvas.
  final bool enabled;

  bool get overheadEnabled => maxAltDeg < 90;

  SkyMapMountLimits copyWith({
    double? minAltDeg,
    double? maxAltDeg,
    double? meridianEastMinutes,
    double? meridianWestMinutes,
    String? activePierSide,
    bool? isGem,
    Map<String, String>? labels,
    bool? enabled,
  }) {
    return SkyMapMountLimits(
      minAltDeg: minAltDeg ?? this.minAltDeg,
      maxAltDeg: maxAltDeg ?? this.maxAltDeg,
      meridianEastMinutes: meridianEastMinutes ?? this.meridianEastMinutes,
      meridianWestMinutes: meridianWestMinutes ?? this.meridianWestMinutes,
      activePierSide: activePierSide ?? this.activePierSide,
      isGem: isGem ?? this.isGem,
      labels: labels ?? this.labels,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'minAltDeg': minAltDeg,
        'maxAltDeg': maxAltDeg,
        'meridianEastMinutes': meridianEastMinutes,
        'meridianWestMinutes': meridianWestMinutes,
        'activePierSide': activePierSide,
        'isGem': isGem,
        'labels': labels,
        'enabled': enabled,
      };

  factory SkyMapMountLimits.fromJson(Map<String, dynamic> json) {
    return SkyMapMountLimits(
      minAltDeg: (json['minAltDeg'] as num?)?.toDouble() ?? 0,
      maxAltDeg: (json['maxAltDeg'] as num?)?.toDouble() ?? 90,
      meridianEastMinutes:
          (json['meridianEastMinutes'] as num?)?.toDouble() ?? 0,
      meridianWestMinutes:
          (json['meridianWestMinutes'] as num?)?.toDouble() ?? 0,
      activePierSide: json['activePierSide'] as String?,
      isGem: json['isGem'] as bool? ?? true,
      labels: (json['labels'] as Map?)?.cast<String, String>() ?? const {},
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        minAltDeg,
        maxAltDeg,
        meridianEastMinutes,
        meridianWestMinutes,
        activePierSide,
        isGem,
        labels,
        enabled,
      ];
}
