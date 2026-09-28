/* MLASTRO bridge for Stellarium Web Engine (AGPL-3.0, Stellarium Labs) */
(function () {
  'use strict';

  var stel = null;
  var ready = false;
  var pendingObserver = null;
  var pendingConfig = null;
  var lastSelectionId = null;

  function post(type, payload) {
    var msg = JSON.stringify({ type: type, payload: payload });
    function send() {
      if (window.MlastroBridge && window.MlastroBridge.postMessage) {
        window.MlastroBridge.postMessage(msg);
        return true;
      }
      return false;
    }
    if (send()) return;
    var tries = 0;
    (function retry() {
      if (send() || ++tries > 40) return;
      setTimeout(retry, 50);
    })();
  }

  function log(msg) {
    console.log('[SkyMap]', msg);
    post('log', String(msg));
  }

  function showError(msg) {
    var text = String(msg);
    console.error('[SkyMap]', text);
    var loading = document.getElementById('loading');
    if (loading) {
      loading.textContent = text;
      loading.className = 'error';
    }
    post('error', text);
  }

  function hideLoading() {
    var loading = document.getElementById('loading');
    if (loading) loading.style.display = 'none';
  }

  function getBaseUrl() {
    var url = document.location.href.split('/');
    url.pop();
    return url.join('/') + '/';
  }

  function cleanupName(raw) {
    if (!raw) return '?';
    return String(raw).replace(/^NAME\s+/, '');
  }

  function inferKind(obj) {
    try {
      var data = obj.jsonData;
      if (data && data.model) {
        if (data.model === 'jpl_sso' || data.model === 'moon') return 'planet';
        if (data.model === 'dso') return 'dso';
        if (data.model === 'star') return 'star';
        if (data.model === 'constellation') return 'constellation';
      }
      var names = obj.designations();
      if (names && names.length) {
        var n = names[0];
        if (/^NAME (Sun|Moon|Mercury|Venus|Mars|Jupiter|Saturn|Uranus|Neptune|Pluto)/i.test(n)) {
          return 'planet';
        }
        if (/^M\s+\d+/.test(n) || /^NGC\s+/.test(n) || /^IC\s+/.test(n)) return 'dso';
      }
    } catch (e) { /* ignore */ }
    return 'star';
  }

  function objectPayload(obj) {
    if (!obj || !stel) return null;
    var names = obj.designations();
    var label = cleanupName(names && names.length ? names[0] : '?');
    var obs = stel.core.observer;
    var radecInfo = obj.getInfo('radec');
    if (!radecInfo) return null;

    var cirs = stel.convertFrame(obs, 'ICRF', 'CIRS', radecInfo);
    var radec = stel.c2s(cirs);
    var raRad = stel.anp(radec[0]);
    var decRad = stel.anpm(radec[1]);
    var vmag = obj.getInfo('vmag');

    var altDeg = null;
    var azDeg = null;
    try {
      var observed = stel.convertFrame(obs, 'ICRF', 'OBSERVED', radecInfo);
      var altaz = stel.c2s(observed);
      azDeg = stel.anp(altaz[0]) * 180 / Math.PI;
      altDeg = altaz[1] * 180 / Math.PI;
    } catch (e) { /* ignore frame conversion error */ }

    var constellation = null;
    try {
      constellation = obj.getInfo('constellation');
    } catch (e) { /* ignore */ }

    var typeDesc = null;
    try {
      typeDesc = obj.getInfo('type') || obj.getInfo('morpho');
    } catch (e) { /* ignore */ }

    var distance = null;
    try {
      var d = obj.getInfo('distance');
      if (typeof d === 'number') distance = d;
    } catch (e) { /* ignore */ }

    var aliases = [];
    if (names && names.length) {
      for (var ni = 0; ni < names.length; ni++) {
        var clean = cleanupName(names[ni]);
        if (clean && aliases.indexOf(clean) === -1) {
          aliases.push(clean);
        }
      }
    }

    return {
      kind: inferKind(obj),
      id: (names && names[0]) || label,
      name: label,
      raHours: raRad * 12 / Math.PI,
      decDeg: decRad * 180 / Math.PI,
      magnitude: typeof vmag === 'number' ? vmag : null,
      altDeg: altDeg,
      azDeg: azDeg,
      constellation: constellation,
      typeDescription: typeDesc,
      distance: distance,
      aliases: aliases
    };
  }

  // Famous DSO Nicknames -> Catalog IDs
  var DSO_NICKNAMES = {
    'CRAB NEBULA': 'M 1',
    'LAGOON NEBULA': 'M 8',
    'WILD DUCK CLUSTER': 'M 11',
    'HERCULES CLUSTER': 'M 13',
    'HERCULES GLOBULAR CLUSTER': 'M 13',
    'EAGLE NEBULA': 'M 16',
    'SWAN NEBULA': 'M 17',
    'OMEGA NEBULA': 'M 17',
    'TRIFID NEBULA': 'M 20',
    'DUMBBELL NEBULA': 'M 27',
    'ANDROMEDA': 'M 31',
    'ANDROMEDA GALAXY': 'M 31',
    'TRIANGULUM GALAXY': 'M 33',
    'ORION NEBULA': 'M 42',
    'DE MAIRAN NEBULA': 'M 43',
    'BEEHIVE CLUSTER': 'M 44',
    'PRAESEPE': 'M 44',
    'PLEIADES': 'M 45',
    'SEVEN SISTERS': 'M 45',
    'WHIRLPOOL GALAXY': 'M 51',
    'RING NEBULA': 'M 57',
    'SUNFLOWER GALAXY': 'M 63',
    'BLACK EYE GALAXY': 'M 64',
    'BODE GALAXY': 'M 81',
    'BODES GALAXY': 'M 81',
    'CIGAR GALAXY': 'M 82',
    'PINWHEEL GALAXY': 'M 101',
    'SOMBRERO GALAXY': 'M 104'
  };

  var POPULAR_STARS = [
    'Sirius', 'Canopus', 'Rigil Kentaurus', 'Arcturus', 'Vega', 'Capella',
    'Rigel', 'Procyon', 'Achernar', 'Betelgeuse', 'Hadar', 'Altair',
    'Acrux', 'Aldebaran', 'Antares', 'Spica', 'Pollux', 'Fomalhaut',
    'Deneb', 'Mimosa', 'Regulus', 'Adhara', 'Castor', 'Gacrux',
    'Bellatrix', 'Elnath', 'Miaplacidus', 'Alnilam', 'Alnitak', 'Alioth',
    'Dubhe', 'Mirfak', 'Wezen', 'Sargas', 'Kaus Australis', 'Avior',
    'Alkaid', 'Menkalinan', 'Atria', 'Alhena', 'Peacock', 'Polaris',
    'Mirzam', 'Alphard', 'Hamal', 'Algieba', 'Diphda', 'Nunki'
  ];

  var SOLAR_SYSTEM = [
    'Sun', 'Moon', 'Mercury', 'Venus', 'Mars', 'Jupiter', 'Saturn',
    'Uranus', 'Neptune', 'Pluto'
  ];

  var CONSTELLATIONS = [
    'Andromeda', 'Antlia', 'Apus', 'Aquarius', 'Aquila', 'Ara', 'Aries',
    'Auriga', 'Bootes', 'Caelum', 'Camelopardalis', 'Cancer', 'Canes Venatici',
    'Canis Major', 'Canis Minor', 'Capricornus', 'Carina', 'Cassiopeia',
    'Centaurus', 'Cepheus', 'Cetus', 'Chamaeleon', 'Circinus', 'Columba',
    'Coma Berenices', 'Corona Australis', 'Corona Borealis', 'Corvus',
    'Crater', 'Crux', 'Cygnus', 'Delphinus', 'Dorado', 'Draco', 'Equuleus',
    'Eridanus', 'Fornax', 'Gemini', 'Grus', 'Hercules', 'Horologium',
    'Hydra', 'Hydrus', 'Indus', 'Lacerta', 'Leo', 'Leo Minor', 'Lepus',
    'Libra', 'Lupus', 'Lynx', 'Lyra', 'Mensa', 'Microscopium', 'Monoceros',
    'Musca', 'Norma', 'Octans', 'Ophiuchus', 'Orion', 'Pavo', 'Pegasus',
    'Perseus', 'Phoenix', 'Pictor', 'Pisces', 'Piscis Austrinus', 'Puppis',
    'Pyxis', 'Reticulum', 'Sagitta', 'Sagittarius', 'Scorpius', 'Sculptor',
    'Scutum', 'Serpens', 'Sextans', 'Taurus', 'Telescopium', 'Triangulum',
    'Triangulum Australe', 'Tucana', 'Ursa Major', 'Ursa Minor', 'Vela',
    'Virgo', 'Volans', 'Vulpecula'
  ];

  function searchCandidates(query) {
    var raw = (query || '').trim();
    if (!raw) return [];
    var upper = raw.toUpperCase();
    var compact = upper.replace(/\s+/g, '');
    var out = [];
    var seen = {};

    function add(id) {
      if (!id || seen[id]) return;
      seen[id] = true;
      out.push(id);
    }

    // Direct aliases
    if (DSO_NICKNAMES[upper]) {
      add(DSO_NICKNAMES[upper]);
    }
    for (var nick in DSO_NICKNAMES) {
      if (nick.indexOf(upper) >= 0 || upper.indexOf(nick) >= 0) {
        add(DSO_NICKNAMES[nick]);
      }
    }

    add('NAME ' + raw);
    add('NAME ' + upper);
    add(raw);
    add(upper);

    var m = compact.match(/^M(\d{1,3})$/);
    if (m) add('M ' + parseInt(m[1], 10));

    var ngc = compact.match(/^NGC(\d+)$/);
    if (ngc) add('NGC ' + ngc[1]);

    var ic = compact.match(/^IC(\d+)$/);
    if (ic) add('IC ' + ic[1]);

    var hip = compact.match(/^HIP(\d+)$/);
    if (hip) add('HIP ' + hip[1]);

    var hr = compact.match(/^HR(\d+)$/);
    if (hr) add('HR ' + hr[1]);

    SOLAR_SYSTEM.forEach(function (name) {
      if (name.toUpperCase().indexOf(upper) >= 0 || upper.indexOf(name.toUpperCase()) >= 0) {
        add('NAME ' + name);
      }
    });

    POPULAR_STARS.forEach(function (name) {
      if (name.toUpperCase().indexOf(upper) >= 0 || upper.indexOf(name.toUpperCase()) >= 0) {
        add('NAME ' + name);
      }
    });

    CONSTELLATIONS.forEach(function (name) {
      if (name.toUpperCase().indexOf(upper) >= 0 || upper.indexOf(name.toUpperCase()) >= 0) {
        add('NAME ' + name);
        add(name);
      }
    });

    return out;
  }

  function onSelectionChanged() {
    if (!ready || !stel) return;
    var sel = stel.core.selection;
    if (!sel) {
      lastSelectionId = null;
      return;
    }
    var payload = objectPayload(sel);
    if (!payload) return;
    if (payload.id === lastSelectionId) return;
    lastSelectionId = payload.id;
    post('select', payload);
  }

  function releaseEngineInput(clearSelection) {
    if (!stel) return;
    var canvas = document.getElementById('stel-canvas');
    var shouldClear = clearSelection !== false;
    try {
      if (shouldClear && stel.core) {
        stel.core.selection = null;
        stel.core.lock = null;
        lastSelectionId = null;
      }
      if (typeof stel._mlastroResetPointer === 'function') {
        stel._mlastroResetPointer();
      }
      if (typeof stel._core_on_mouse === 'function') {
        for (var i = 0; i < 16; i++) {
          stel._core_on_mouse(i, 0, 0, 0, 0);
        }
      }
      if (canvas) {
        ['mouseup', 'pointerup', 'pointercancel', 'touchend', 'touchcancel'].forEach(
          function (type) {
            try {
              canvas.dispatchEvent(new Event(type, { bubbles: true, cancelable: true }));
            } catch (e) { /* ignore */ }
          }
        );
      }
      try {
        document.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, cancelable: true, view: window }));
      } catch (e) { /* ignore */ }
    } catch (e) {
      log('releaseInput: ' + e);
    }
  }

  function applyPendingObserver() {
    if (!ready || !pendingObserver) return;
    var o = pendingObserver;
    pendingObserver = null;
    window.MlastroSky.setObserver(o.lat, o.lon, o.utcIso);
  }

  function setNightMode(active) {
    var root = document.getElementById('stel-root');
    if (!root) return;
    if (active) {
      root.classList.add('night-mode');
    } else {
      root.classList.remove('night-mode');
    }
  }

  function applyConfig(config) {
    if (!stel || !config) return;
    try {
      var core = stel.core;
      if (!core) return;

      if (config.showConstellationLines !== undefined && core.constellations) {
        core.constellations.lines_visible = !!config.showConstellationLines;
      }
      if (config.showConstellationArt !== undefined && core.constellations) {
        if ('art_visible' in core.constellations) {
          core.constellations.art_visible = !!config.showConstellationArt;
        }
        if ('images_visible' in core.constellations) {
          core.constellations.images_visible = !!config.showConstellationArt;
        }
      }
      if (config.showConstellationLabels !== undefined && core.constellations) {
        core.constellations.labels_visible = !!config.showConstellationLabels;
      }
      if (config.showConstellationBoundaries !== undefined && core.constellations) {
        if ('bounds_visible' in core.constellations) {
          core.constellations.bounds_visible = !!config.showConstellationBoundaries;
        }
      }

      if (core.lines) {
        if (config.showAzimuthalGrid !== undefined && core.lines.azimuthal) {
          core.lines.azimuthal.visible = !!config.showAzimuthalGrid;
        }
        if (config.showEquatorialGrid !== undefined) {
          if (core.lines.equatorial_jnow) {
            core.lines.equatorial_jnow.visible = !!config.showEquatorialGrid;
          }
          if (core.lines.equatorial) {
            core.lines.equatorial.visible = !!config.showEquatorialGrid;
          }
        }
        if (config.showMeridianLine !== undefined && core.lines.meridian) {
          core.lines.meridian.visible = !!config.showMeridianLine;
        }
      }

      if (config.showAtmosphere !== undefined && core.atmosphere) {
        core.atmosphere.visible = !!config.showAtmosphere;
      }
      if (config.showLandscape !== undefined && core.landscapes) {
        core.landscapes.visible = !!config.showLandscape;
      }
      if (config.showMilkyWay !== undefined && core.milkyway) {
        core.milkyway.visible = !!config.showMilkyWay;
      }
      if (config.showStars !== undefined && core.stars) {
        core.stars.visible = !!config.showStars;
      }
      if (config.showDsos !== undefined && core.dsos) {
        core.dsos.visible = !!config.showDsos;
      }
      if (config.showPlanets !== undefined && core.planets) {
        core.planets.visible = !!config.showPlanets;
      }

      if (config.nightMode !== undefined) {
        setNightMode(!!config.nightMode);
      }
    } catch (e) {
      log('applyConfig error: ' + e);
    }
  }

  // FOV limits (degrees). Larger FOV = zoomed out (wider sky).
  var MIN_FOV_DEG = 6;
  var MAX_FOV_DEG = 85;
  var DEFAULT_FOV_DEG = 75;

  function clampFov(core, engine) {
    if (!core || !engine) return false;
    var min = MIN_FOV_DEG * engine.D2R;
    var max = MAX_FOV_DEG * engine.D2R;
    var fov = core.fov;
    if (fov < min) {
      core.fov = min;
      return true;
    }
    if (fov > max) {
      core.fov = max;
      return true;
    }
    return false;
  }

  function startFovGuard(core, engine) {
    function tick() {
      if (stel && core) clampFov(core, engine);
      requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  }

  function configureScene(core, engine) {
    try {
      core.atmosphere.visible = true;
      core.landscapes.visible = true;
      if (core.lines) {
        if (core.lines.azimuthal) core.lines.azimuthal.visible = false;
        if (core.lines.equatorial_jnow) core.lines.equatorial_jnow.visible = false;
        if (core.lines.equatorial) core.lines.equatorial.visible = false;
        if (core.lines.meridian) core.lines.meridian.visible = false;
      }
      core.constellations.lines_visible = true;
      core.constellations.art_visible = true;
      core.constellations.labels_visible = true;
      core.dsos.visible = true;
      core.milkyway.visible = true;
      core.stars.visible = true;
      clampFov(core, engine);
    } catch (e) {
      log('configureScene partial: ' + e);
    }
  }

  function loadDataSources(core, baseUrl) {
    log('loading skydata from ' + baseUrl);
    core.stars.addDataSource({ url: baseUrl + 'stars' });
    core.skycultures.addDataSource({ url: baseUrl + 'skycultures/western', key: 'western' });
    core.dsos.addDataSource({ url: baseUrl + 'dso' });
    core.milkyway.addDataSource({ url: baseUrl + 'surveys/milkyway' });
    core.landscapes.addDataSource({ url: baseUrl + 'landscapes/guereins', key: 'guereins' });
    core.planets.addDataSource({ url: baseUrl + 'surveys/sso/moon', key: 'moon' });
    core.planets.addDataSource({ url: baseUrl + 'surveys/sso/sun', key: 'sun' });
    core.planets.addDataSource({ url: baseUrl + 'surveys/sso/moon', key: 'default' });
  }

  function setObserverOnEngine(engine, lat, lon, utcIso) {
    var obs = engine.core && engine.core.observer;
    if (!obs) {
      obs = engine.observer;
    }
    if (!obs) return false;
    var when = utcIso ? new Date(utcIso) : new Date();
    obs.latitude = lat * engine.D2R;
    obs.longitude = lon * engine.D2R;
    obs.utc = engine.date2MJD(when);
    return true;
  }

  function setDefaultObserver(engine) {
    try {
      if (!setObserverOnEngine(engine, 10, 106, null)) {
        log('setDefaultObserver: observer not available yet');
      }
    } catch (e) {
      log('setDefaultObserver: ' + e);
    }
  }

  function waitForCanvas(canvas, cb) {
    var tries = 0;
    function tick() {
      var rect = canvas.getBoundingClientRect();
      var w = rect.width || window.innerWidth || 0;
      var h = rect.height || window.innerHeight || 0;
      if (w > 8 && h > 8) {
        var dpr = window.devicePixelRatio || 1;
        canvas.width = Math.floor(w * dpr);
        canvas.height = Math.floor(h * dpr);
        cb({ width: w, height: h, dpr: dpr });
        return;
      }
      if (++tries > 150) {
        var fw = window.innerWidth || 390;
        var fh = window.innerHeight || 844;
        canvas.width = fw;
        canvas.height = fh;
        cb({ width: fw, height: fh, dpr: 1 });
        return;
      }
      requestAnimationFrame(tick);
    }
    tick();
  }

  function probeWebGl() {
    try {
      var probe = document.createElement('canvas');
      var gl2 = probe.getContext('webgl2');
      var gl1 = probe.getContext('webgl') || probe.getContext('experimental-webgl');
      log('WebGL probe webgl2=' + !!gl2 + ' webgl=' + !!gl1);
      if (gl2) return true;
      if (gl1) return true;
      return false;
    } catch (e) {
      log('WebGL probe failed: ' + e);
      return false;
    }
  }

  function bootEngine(canvas, baseUrl, wasmUrl, skyDataUrl) {
    log('StelWebEngine wasm=' + wasmUrl);
    if (!probeWebGl()) {
      showError('WebGL is not available in this WebView.');
      return;
    }

    window.__mlastroSweInitFailed = function (e) {
      showError('SWE init failed: ' + (e && e.stack ? e.stack : e));
    };

    var runtime = StelWebEngine({
      canvas: canvas,
      canvasElement: canvas,
      wasmFile: wasmUrl,
      printErr: function (msg) { log('stderr: ' + msg); },
      onAbort: function (what) { showError('WASM abort: ' + what); },
      translateFn: function (_domain, str) { return str; },
      onReady: function (engine) {
        try {
          log('onReady');
          stel = engine;
          var core = stel.core;
          setDefaultObserver(stel);
          loadDataSources(core, skyDataUrl);
          configureScene(core, stel);
          stel.zoomTo(DEFAULT_FOV_DEG * stel.D2R, 0);
          clampFov(core, stel);
          startFovGuard(core, stel);

          stel.change(function (_obj, attr) {
            if (attr === 'hovered') return;
            if (attr === 'fov') clampFov(core, stel);
            if (attr === 'selection') onSelectionChanged();
          });

          ready = true;
          hideLoading();
          applyPendingObserver();
          if (pendingConfig) {
            applyConfig(pendingConfig);
            pendingConfig = null;
          }
          post('ready', {});
          log('ready');
        } catch (e) {
          showError('onReady failed: ' + e);
        }
      }
    });

    if (runtime && typeof runtime.then === 'function') {
      runtime.then(function () {
        log('wasm runtime initialized');
        setTimeout(function () {
          if (!ready) {
            showError(
              'WASM loaded but onReady never ran — likely WebGL or core_init failure. '
              + 'Check SkyMap JS stderr lines above.'
            );
          }
        }, 1500);
      }).catch(function (err) {
        showError('WASM load failed: ' + err);
      });
    } else {
      log('no wasm promise returned');
    }

    setTimeout(function () {
      if (!ready && loading && loading.style.display !== 'none') {
        showError('Timed out waiting for Stellarium engine (>45s). Check WASM/skydata HTTP.');
      }
    }, 45000);
  }

  function boot() {
    log('boot');
    if (typeof StelWebEngine !== 'function') {
      showError('Stellarium Web Engine JS failed to load');
      return;
    }

    var canvas = document.getElementById('stel-canvas');
    if (!canvas) {
      showError('Canvas element missing');
      return;
    }

    var baseUrl = getBaseUrl();
    var wasmUrl = baseUrl + 'stellarium/stellarium-web-engine.wasm';
    var skyDataUrl = baseUrl + 'stellarium/skydata/';

    waitForCanvas(canvas, function (size) {
      log('canvas ' + size.width + 'x' + size.height + ' dpr=' + size.dpr);
      bootEngine(canvas, baseUrl, wasmUrl, skyDataUrl);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }

  window.MlastroSky = {
    isReady: function () { return ready; },

    releaseInput: releaseEngineInput,

    resumeInteraction: function () {
      releaseEngineInput(false);
    },

    dismissPanel: function () {
      lastSelectionId = null;
    },

    setConfig: function (config) {
      if (!ready || !stel) {
        pendingConfig = config;
        return;
      }
      applyConfig(config);
    },

    setNightMode: setNightMode,

    setObserver: function (lat, lon, utcIso) {
      if (!ready || !stel) {
        pendingObserver = { lat: lat, lon: lon, utcIso: utcIso };
        return;
      }
      try {
        if (!setObserverOnEngine(stel, lat, lon, utcIso)) {
          pendingObserver = { lat: lat, lon: lon, utcIso: utcIso };
        }
      } catch (e) {
        log('setObserver: ' + e);
      }
    },

    centerOn: function (raHours, decDeg) {
      if (!ready || !stel) return;
      try {
        var obs = stel.core.observer;
        var ra = raHours * Math.PI / 12;
        var dec = decDeg * Math.PI / 180;
        var icrs = stel.s2c(ra, dec);
        var observed = stel.convertFrame(obs, 'ICRF', 'OBSERVED', icrs);
        stel.lookAt(observed, 0.5);
      } catch (e) {
        showError('centerOn: ' + e);
      }
    },

    lookTowards: function (azDeg, altDeg) {
      if (!ready || !stel) return;
      try {
        var azRad = azDeg * Math.PI / 180;
        var altRad = altDeg * Math.PI / 180;
        var obsVector = stel.s2c(azRad, altRad);
        stel.lookAt(obsVector, 0.5);
      } catch (e) {
        log('lookTowards: ' + e);
      }
    },

    setFov: function (fovDeg) {
      if (!ready || !stel) return;
      try {
        var clamped = Math.max(MIN_FOV_DEG, Math.min(MAX_FOV_DEG, fovDeg));
        stel.zoomTo(clamped * stel.D2R, 0.3);
      } catch (e) {
        log('setFov: ' + e);
      }
    },

    zoomBy: function (deltaDeg) {
      if (!ready || !stel) return;
      try {
        var curFovDeg = stel.core.fov / stel.D2R;
        var target = Math.max(MIN_FOV_DEG, Math.min(MAX_FOV_DEG, curFovDeg + deltaDeg));
        stel.zoomTo(target * stel.D2R, 0.25);
      } catch (e) {
        log('zoomBy: ' + e);
      }
    },

    search: function (query) {
      if (!ready || !stel) return '[]';
      var candidates = searchCandidates(query);
      var results = [];
      var seen = {};

      for (var i = 0; i < candidates.length && results.length < 32; i++) {
        var id = candidates[i];
        var obj;
        try {
          obj = stel.getObj(id);
        } catch (e) {
          obj = null;
        }
        if (!obj) continue;
        var payload = objectPayload(obj);
        if (!payload || seen[payload.id]) continue;
        seen[payload.id] = true;
        results.push(payload);
      }
      return JSON.stringify(results);
    },

    selectById: function (id) {
      if (!ready || !stel || !id) return;
      try {
        var obj = stel.getObj(id);
        if (!obj) return;
        stel.core.selection = obj;
        stel.pointAndLock(obj, 0.5);
      } catch (e) {
        showError('selectById: ' + e);
      }
    }
  };
})();
