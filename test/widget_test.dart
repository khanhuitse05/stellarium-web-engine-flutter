import 'package:flutter_test/flutter_test.dart';
import 'package:mlastro_skymap/mlastro_skymap.dart';

void main() {
  test('SkyMapAssets prefix targets package bundle', () {
    expect(
      SkyMapAssets.prefix,
      'packages/mlastro_skymap/assets/sky_map/',
    );
    expect(SkyMapAssets.bundled, isNotEmpty);
  });
}
