# Third-party notices

This app bundles third-party software. The notices below apply to those components.

## Stellarium Web Engine

- **Copyright:** Stellarium Labs SRL
- **License:** GNU Affero General Public License v3.0 (AGPL-3.0)
- **Upstream:** https://github.com/Stellarium/stellarium-web-engine
- **Flutter package & corresponding source:** https://github.com/khanhuitse05/stellarium-web-engine-flutter
- **License text:** [assets/sky_map/stellarium/LICENSE-AGPL-3.0.txt](assets/sky_map/stellarium/LICENSE-AGPL-3.0.txt)
- **Bundled files:** `stellarium-web-engine.js`, `stellarium-web-engine.wasm`, sky catalog data under `assets/sky_map/stellarium/`

Sky catalog data is derived from upstream `apps/test-skydata` (see the Stellarium Web Engine repository).

### AGPL distribution note

If you distribute this application, AGPL v3 requires you to provide corresponding source for the Stellarium Web Engine components and any modifications (including `assets/sky_map/mlastro_sky.js` and build patches in `scripts/setup_stellarium_web_engine.sh`).

The corresponding source code is openly published at:
https://github.com/khanhuitse05/stellarium-web-engine-flutter

For closed-source or commercial distribution, consider a commercial licence from [Stellarium Labs](https://stellarium-labs.com/).
