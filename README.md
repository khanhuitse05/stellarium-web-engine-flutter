# MLASTRO Sky Map

Flutter package with an interactive sky map powered by [Stellarium Web Engine](https://github.com/Stellarium/stellarium-web-engine) (AGPL-3.0) in a WebView.

Use as a standalone example app or as a dependency in the main MLASTRO app.

## Features

- Full-screen star map with landscape, atmosphere, and horizon
- GPS observer location and UTC time sync
- Tap stars/objects to view RA/Dec
- Search by object name
- Optional telescope position HUD and Goto action hooks
- In-app open-source license notices

## Use as a package

```yaml
dependencies:
  mlastro_skymap:
    path: ../mlastro-skymap
```

```dart
import 'package:mlastro_skymap/mlastro_skymap.dart';

SkyMapPage(
  createCubit: () => SkyMapCubit(
    telescopePositionStream: myTelescopeStream,
  ),
  routeObserver: myRouteObserver,
  onGoto: (context, object) async { /* ... */ },
)
```

## Example app

```bash
cd mlastro-skymap/example
flutter pub get
flutter run
```

Use a **full app restart** (not hot reload) after changing package `assets/sky_map/` or `mlastro_sky.js`.

## Rebuild Stellarium Web Engine assets

Bundled assets under `assets/sky_map/` are ready to run. To rebuild from source:

```bash
./scripts/setup_stellarium_web_engine.sh
```

Requires sibling repos `../stellarium-web-engine` and `../emsdk`.

## Project layout

```
lib/
  mlastro_skymap.dart   # Public API
  features/sky_map/     # UI, cubit, WebView bridge
  astro/                # RA/Dec formatting
  services/             # Location
assets/sky_map/         # HTML, JS bridge, WASM, skydata
example/                # Standalone demo app (android/, ios/, …)
scripts/                # SWE build helper
test/                   # Package tests
```

## License

The sky map renderer uses Stellarium Web Engine under **GNU AGPL v3**. See `THIRD_PARTY_NOTICES.md`, `assets/sky_map/NOTICE`, and `assets/sky_map/stellarium/LICENSE-AGPL-3.0.txt`.

This package's sky-map integration code is also licensed under **AGPL-3.0** when distributed with Stellarium Web Engine assets.
