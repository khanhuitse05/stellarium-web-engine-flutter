/// Bundled asset paths for [mlastro_skymap] package resources.
abstract final class SkyMapAssets {
  static const packageName = 'mlastro_skymap';
  static const prefix = 'packages/$packageName/assets/sky_map/';

  static const notice = '${prefix}NOTICE';
  static const agplLicense = '${prefix}stellarium/LICENSE-AGPL-3.0.txt';

  static const bundled = [
    '${prefix}index.html',
    '${prefix}mlastro_sky.js',
    '${prefix}stellarium/stellarium-web-engine.js',
    '${prefix}stellarium/stellarium-web-engine.wasm',
    '${prefix}stellarium/skydata.tar.gz',
  ];
}
