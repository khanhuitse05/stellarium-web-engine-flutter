import 'package:flutter_test/flutter_test.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

void main() {
  group('SkyMapConfig', () {
    test('default configuration has correct initial values', () {
      const config = SkyMapConfig();
      expect(config.showConstellationLines, isTrue);
      expect(config.showConstellationArt, isTrue);
      expect(config.showConstellationLabels, isTrue);
      expect(config.showConstellationBoundaries, isFalse);
      expect(config.showAzimuthalGrid, isFalse);
      expect(config.showEquatorialGrid, isFalse);
      expect(config.showMeridianLine, isFalse);
      expect(config.showAtmosphere, isTrue);
      expect(config.showLandscape, isTrue);
      expect(config.showMilkyWay, isTrue);
      expect(config.showStars, isTrue);
      expect(config.showDsos, isTrue);
      expect(config.showPlanets, isTrue);
      expect(config.nightMode, isFalse);
    });

    test('stargazing preset configures appropriate observing layers', () {
      final config = SkyMapConfig.stargazing();
      expect(config.showConstellationArt, isFalse);
      expect(config.showConstellationLines, isTrue);
      expect(config.showAtmosphere, isTrue);
      expect(config.nightMode, isFalse);
    });

    test('deepSky preset disables atmosphere and enables equatorial grid', () {
      final config = SkyMapConfig.deepSky();
      expect(config.showAtmosphere, isFalse);
      expect(config.showLandscape, isFalse);
      expect(config.showEquatorialGrid, isTrue);
      expect(config.showMeridianLine, isTrue);
    });

    test('planetarium preset enables constellation art and boundaries', () {
      final config = SkyMapConfig.planetarium();
      expect(config.showConstellationArt, isTrue);
      expect(config.showConstellationBoundaries, isTrue);
      expect(config.showAzimuthalGrid, isTrue);
    });

    test('minimalist preset shows only stars and planets without background', () {
      final config = SkyMapConfig.minimalist();
      expect(config.showAtmosphere, isFalse);
      expect(config.showLandscape, isFalse);
      expect(config.showMilkyWay, isFalse);
      expect(config.showDsos, isFalse);
      expect(config.showStars, isTrue);
      expect(config.showPlanets, isTrue);
    });

    test('copyWith updates specified fields only', () {
      const config = SkyMapConfig();
      final updated = config.copyWith(
        nightMode: true,
        showAzimuthalGrid: true,
        showAtmosphere: false,
      );
      expect(updated.nightMode, isTrue);
      expect(updated.showAzimuthalGrid, isTrue);
      expect(updated.showAtmosphere, isFalse);
      expect(updated.showStars, isTrue);
    });

    test('toJson and fromJson serialize and deserialize symmetrically', () {
      final original = SkyMapConfig.deepSky().copyWith(nightMode: true);
      final json = original.toJson();
      final restored = SkyMapConfig.fromJson(json);
      expect(restored, equals(original));
    });
  });
}
