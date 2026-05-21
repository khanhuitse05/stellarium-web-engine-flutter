import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mlastro_skymap/sky_map_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled sky map assets are present', () async {
    for (final key in SkyMapAssets.bundled) {
      final data = await rootBundle.load(key);
      expect(data.lengthInBytes, greaterThan(0), reason: key);
    }
  });
}
