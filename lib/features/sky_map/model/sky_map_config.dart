import 'package:equatable/equatable.dart';

/// Configuration options controlling the visual layers and rendering of the sky map.
class SkyMapConfig extends Equatable {
  const SkyMapConfig({
    this.showConstellationLines = true,
    this.showConstellationArt = true,
    this.showConstellationLabels = true,
    this.showConstellationBoundaries = false,
    this.showAzimuthalGrid = false,
    this.showEquatorialGrid = false,
    this.showMeridianLine = false,
    this.showAtmosphere = true,
    this.showLandscape = true,
    this.showMilkyWay = true,
    this.showStars = true,
    this.showDsos = true,
    this.showPlanets = true,
    this.nightMode = false,
  });

  /// Preset tuned for general night sky observing and stargazing.
  factory SkyMapConfig.stargazing() => const SkyMapConfig(
        showConstellationLines: true,
        showConstellationArt: false,
        showConstellationLabels: true,
        showConstellationBoundaries: false,
        showAzimuthalGrid: false,
        showEquatorialGrid: false,
        showMeridianLine: false,
        showAtmosphere: true,
        showLandscape: true,
        showMilkyWay: true,
        showStars: true,
        showDsos: true,
        showPlanets: true,
        nightMode: false,
      );

  /// Preset tuned for deep sky astrophotography targeting nebulae and galaxies.
  factory SkyMapConfig.deepSky() => const SkyMapConfig(
        showConstellationLines: true,
        showConstellationArt: false,
        showConstellationLabels: false,
        showConstellationBoundaries: false,
        showAzimuthalGrid: false,
        showEquatorialGrid: true,
        showMeridianLine: true,
        showAtmosphere: false,
        showLandscape: false,
        showMilkyWay: true,
        showStars: true,
        showDsos: true,
        showPlanets: true,
        nightMode: false,
      );

  /// Preset tuned for educational planetarium demonstrations with art illustrations.
  factory SkyMapConfig.planetarium() => const SkyMapConfig(
        showConstellationLines: true,
        showConstellationArt: true,
        showConstellationLabels: true,
        showConstellationBoundaries: true,
        showAzimuthalGrid: true,
        showEquatorialGrid: false,
        showMeridianLine: true,
        showAtmosphere: true,
        showLandscape: true,
        showMilkyWay: true,
        showStars: true,
        showDsos: true,
        showPlanets: true,
        nightMode: false,
      );

  /// Preset for a clean, minimal sky chart.
  factory SkyMapConfig.minimalist() => const SkyMapConfig(
        showConstellationLines: true,
        showConstellationArt: false,
        showConstellationLabels: true,
        showConstellationBoundaries: false,
        showAzimuthalGrid: false,
        showEquatorialGrid: false,
        showMeridianLine: false,
        showAtmosphere: false,
        showLandscape: false,
        showMilkyWay: false,
        showStars: true,
        showDsos: false,
        showPlanets: true,
        nightMode: false,
      );

  final bool showConstellationLines;
  final bool showConstellationArt;
  final bool showConstellationLabels;
  final bool showConstellationBoundaries;
  final bool showAzimuthalGrid;
  final bool showEquatorialGrid;
  final bool showMeridianLine;
  final bool showAtmosphere;
  final bool showLandscape;
  final bool showMilkyWay;
  final bool showStars;
  final bool showDsos;
  final bool showPlanets;
  final bool nightMode;

  SkyMapConfig copyWith({
    bool? showConstellationLines,
    bool? showConstellationArt,
    bool? showConstellationLabels,
    bool? showConstellationBoundaries,
    bool? showAzimuthalGrid,
    bool? showEquatorialGrid,
    bool? showMeridianLine,
    bool? showAtmosphere,
    bool? showLandscape,
    bool? showMilkyWay,
    bool? showStars,
    bool? showDsos,
    bool? showPlanets,
    bool? nightMode,
  }) {
    return SkyMapConfig(
      showConstellationLines:
          showConstellationLines ?? this.showConstellationLines,
      showConstellationArt: showConstellationArt ?? this.showConstellationArt,
      showConstellationLabels:
          showConstellationLabels ?? this.showConstellationLabels,
      showConstellationBoundaries:
          showConstellationBoundaries ?? this.showConstellationBoundaries,
      showAzimuthalGrid: showAzimuthalGrid ?? this.showAzimuthalGrid,
      showEquatorialGrid: showEquatorialGrid ?? this.showEquatorialGrid,
      showMeridianLine: showMeridianLine ?? this.showMeridianLine,
      showAtmosphere: showAtmosphere ?? this.showAtmosphere,
      showLandscape: showLandscape ?? this.showLandscape,
      showMilkyWay: showMilkyWay ?? this.showMilkyWay,
      showStars: showStars ?? this.showStars,
      showDsos: showDsos ?? this.showDsos,
      showPlanets: showPlanets ?? this.showPlanets,
      nightMode: nightMode ?? this.nightMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'showConstellationLines': showConstellationLines,
        'showConstellationArt': showConstellationArt,
        'showConstellationLabels': showConstellationLabels,
        'showConstellationBoundaries': showConstellationBoundaries,
        'showAzimuthalGrid': showAzimuthalGrid,
        'showEquatorialGrid': showEquatorialGrid,
        'showMeridianLine': showMeridianLine,
        'showAtmosphere': showAtmosphere,
        'showLandscape': showLandscape,
        'showMilkyWay': showMilkyWay,
        'showStars': showStars,
        'showDsos': showDsos,
        'showPlanets': showPlanets,
        'nightMode': nightMode,
      };

  factory SkyMapConfig.fromJson(Map<String, dynamic> json) {
    return SkyMapConfig(
      showConstellationLines: json['showConstellationLines'] as bool? ?? true,
      showConstellationArt: json['showConstellationArt'] as bool? ?? true,
      showConstellationLabels: json['showConstellationLabels'] as bool? ?? true,
      showConstellationBoundaries:
          json['showConstellationBoundaries'] as bool? ?? false,
      showAzimuthalGrid: json['showAzimuthalGrid'] as bool? ?? false,
      showEquatorialGrid: json['showEquatorialGrid'] as bool? ?? false,
      showMeridianLine: json['showMeridianLine'] as bool? ?? false,
      showAtmosphere: json['showAtmosphere'] as bool? ?? true,
      showLandscape: json['showLandscape'] as bool? ?? true,
      showMilkyWay: json['showMilkyWay'] as bool? ?? true,
      showStars: json['showStars'] as bool? ?? true,
      showDsos: json['showDsos'] as bool? ?? true,
      showPlanets: json['showPlanets'] as bool? ?? true,
      nightMode: json['nightMode'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        showConstellationLines,
        showConstellationArt,
        showConstellationLabels,
        showConstellationBoundaries,
        showAzimuthalGrid,
        showEquatorialGrid,
        showMeridianLine,
        showAtmosphere,
        showLandscape,
        showMilkyWay,
        showStars,
        showDsos,
        showPlanets,
        nightMode,
      ];
}
