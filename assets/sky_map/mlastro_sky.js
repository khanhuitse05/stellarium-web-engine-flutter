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
        if (/^NAME Sun/i.test(n)) return 'sun';
        if (/^NAME Moon/i.test(n)) return 'moon';
        if (/^NAME (Mercury|Venus|Mars|Jupiter|Saturn|Uranus|Neptune|Pluto)/i.test(n)) {
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
    if (performance.now() - lastLimitTapTime < 350) return;
    var sel = stel.core.selection;
    if (!sel) {
      lastSelectionId = null;
      return;
    }
    temporaryRing = null;
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
        ['mouseup', 'pointerup', 'pointercancel'].forEach(
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
          var showEq = !!config.showEquatorialGrid;
          if (core.lines.equatorial) {
            core.lines.equatorial.visible = showEq;
            if (core.lines.equatorial_jnow) {
              core.lines.equatorial_jnow.visible = false;
            }
          } else if (core.lines.equatorial_jnow) {
            core.lines.equatorial_jnow.visible = showEq;
          }
        }
        if (config.showMeridianLine !== undefined && core.lines.meridian) {
          core.lines.meridian.visible = !!config.showMeridianLine;
        }
      }

      if (config.showMountLimits !== undefined) {
        _showMountLimitsConfig = !!config.showMountLimits;
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

  function getDefaultLongitude() {
    try {
      var offsetMinutes = -new Date().getTimezoneOffset();
      return (offsetMinutes / 60.0) * 15.0;
    } catch (e) {
      return 106.0;
    }
  }

  function setDefaultObserver(engine) {
    try {
      var defaultLon = getDefaultLongitude();
      if (!setObserverOnEngine(engine, 10, defaultLon, null)) {
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

  // -------------------------------------------------------------
  // Live Telescope Reticle & Stereographic Projection Subsystem
  // -------------------------------------------------------------
  var _telescope = null; // { raHours, decDeg, isTracking, isSlewing, isParked, isAtHome }
  var _displayTelescope = null; // { raHours, decDeg } for smooth interpolation
  var reticleCanvas = null;
  var reticleCtx = null;
  var reticleLoopActive = false;

  function setTelescope(raHours, decDeg, isTracking, isSlewing, isParked, isAtHome) {
    if (raHours === null || raHours === undefined || isNaN(Number(raHours))) {
      _telescope = null;
      _displayTelescope = null;
    } else {
      var targetRa = Number(raHours);
      var targetDec = Number(decDeg);
      _telescope = {
        raHours: targetRa,
        decDeg: targetDec,
        isTracking: Boolean(isTracking),
        isSlewing: Boolean(isSlewing),
        isParked: Boolean(isParked),
        isAtHome: Boolean(isAtHome)
      };
      if (!_displayTelescope) {
        _displayTelescope = { raHours: targetRa, decDeg: targetDec };
      } else {
        // If coordinate difference is very large (e.g. > 15 deg or initial sync), snap immediately
        var dRaSnap = Math.abs(targetRa - _displayTelescope.raHours);
        if (dRaSnap > 12) dRaSnap = Math.abs(dRaSnap - 24);
        var dDecSnap = Math.abs(targetDec - _displayTelescope.decDeg);
        if (dRaSnap > 1.0 || dDecSnap > 15.0) {
          _displayTelescope.raHours = targetRa;
          _displayTelescope.decDeg = targetDec;
        }
      }
    }
  }

  function centerOnTelescope() {
    if (!_telescope || !ready || !stel) return;
    window.MlastroSky.centerOn(_telescope.raHours, _telescope.decDeg);
  }

  // -------------------------------------------------------------
  // Mount Safety Limits Overlay Subsystem
  // -------------------------------------------------------------
  var _mountLimits = null;
  var _showMountLimitsConfig = false;
  var _renderedLimitLines = [];
  var lastLimitTapTime = 0;

  function setMountLimits(limits) {
    if (!limits) {
      _mountLimits = null;
    } else {
      _mountLimits = {
        minAltDeg: Number(limits.minAltDeg) || 0,
        maxAltDeg: Number(limits.maxAltDeg) || 90,
        meridianEastMinutes: Number(limits.meridianEastMinutes) || 0,
        meridianWestMinutes: Number(limits.meridianWestMinutes) || 0,
        activePierSide: limits.activePierSide || null,
        isGem: limits.isGem !== false,
        labels: limits.labels || {},
        enabled: limits.enabled !== false
      };
    }
  }

  function projectViewVector(v) {
    if (!v) return null;
    var vx = v[0];
    var vy = v[1];
    var vz = v[2];

    var d = Math.sqrt(vx * vx + vy * vy + vz * vz);
    if (d < 1e-9) return null;
    var ux = vx / d;
    var uy = vy / d;
    var uz = vz / d;

    // Discontinuity at (0, 0, 1) directly behind
    if (uz >= 0.999999) return null;

    var stelCanvas = document.getElementById('stel-canvas');
    if (!stelCanvas) return null;
    var w = stelCanvas.clientWidth;
    var h = stelCanvas.clientHeight;
    if (w <= 0 || h <= 0) return null;

    var aspect = w / h;
    var fov = stel.core.fov;
    var fovy;
    if (aspect < 1) {
      fovy = 4 * Math.atan(Math.tan(fov / 4) / aspect);
    } else {
      fovy = fov;
    }

    var fovy2 = 2 * Math.atan(2 * Math.tan(fovy / 4));
    var f = 1.0 / Math.tan(fovy2 / 2);

    var hStereo = 0.5 * (1.0 - uz);
    var px = ux / hStereo;
    var py = uy / hStereo;

    var p0 = (f / aspect) * px;
    var p1 = f * py;

    var winX = (+p0 + 1) / 2 * w;
    var winY = (-p1 + 1) / 2 * h;

    var onScreen = (uz < 0) && (winX >= 0 && winX <= w && winY >= 0 && winY <= h);
    var cosAng = Math.max(-1, Math.min(1, -uz));
    var angDistDeg = Math.acos(cosAng) * 180 / Math.PI;

    return {
      x: winX,
      y: winY,
      onScreen: onScreen,
      inFront: uz < 0,
      dirX: vx,
      dirY: -vy,
      angDistDeg: angDistDeg,
      width: w,
      height: h
    };
  }

  function projectObserved(azRad, altRad) {
    if (!ready || !stel) return null;
    try {
      var obs = stel.core.observer;
      var vObs = stel.s2c(azRad, altRad);
      var vView = stel.convertFrame(obs, 'OBSERVED', 'VIEW', vObs);
      return projectViewVector(vView);
    } catch (e) {
      return null;
    }
  }

  function projectHourAngle(hRad, decRad) {
    if (!ready || !stel) return null;
    try {
      var obs = stel.core.observer;
      var phi = (obs.latitude !== undefined) ? obs.latitude : (obs.phi || 0);
      var cd = Math.cos(decRad);
      var sd = Math.sin(decRad);
      var ch = Math.cos(hRad);
      var sh = Math.sin(hRad);
      var cp = Math.cos(phi);
      var sp = Math.sin(phi);

      var xp = cd * ch;
      var yp = -cd * sh;
      var zp = sd;

      var vx = xp * sp + zp * cp;
      var vy = yp;
      var vz = -xp * cp + zp * sp;

      var vObs = [vx, vy, vz];
      var vView = stel.convertFrame(obs, 'OBSERVED', 'VIEW', vObs);
      return projectViewVector(vView);
    } catch (e) {
      return null;
    }
  }

  function projectCoordinates(raHours, decDeg) {
    if (!ready || !stel) return null;
    try {
      var obs = stel.core.observer;
      var raRad = raHours * Math.PI / 12;
      var decRad = decDeg * Math.PI / 180;
      var icrs = stel.s2c(raRad, decRad);
      var v = stel.convertFrame(obs, 'ICRF', 'VIEW', icrs);
      return projectViewVector(v);
    } catch (e) {
      return null;
    }
  }

  function drawPolyline(ctx, points, style) {
    if (!points || points.length < 2) return [];
    var segments = [];
    ctx.save();
    ctx.strokeStyle = style.color;
    ctx.lineWidth = style.lineWidth || 1.5;
    ctx.setLineDash(style.dash || [6, 6]);

    var drawing = false;
    ctx.beginPath();
    for (var i = 0; i < points.length; i++) {
      var p = points[i];
      if (p && p.inFront) {
        if (!drawing) {
          ctx.moveTo(p.x, p.y);
          drawing = true;
        } else {
          ctx.lineTo(p.x, p.y);
          segments.push({ x1: points[i - 1].x, y1: points[i - 1].y, x2: p.x, y2: p.y });
        }
      } else {
        drawing = false;
      }
    }
    ctx.stroke();
    ctx.restore();
    return segments;
  }

  function drawLineLabel(ctx, points, labelText, style, offsetY) {
    if (!points || !labelText) return;
    var bestPoint = null;
    var bestDist = 1e9;
    var stelCanvas = document.getElementById('stel-canvas');
    var cx = (stelCanvas ? stelCanvas.clientWidth : 400) / 2;
    var cy = (stelCanvas ? stelCanvas.clientHeight : 400) / 2 + (offsetY || 0);

    for (var i = 0; i < points.length; i++) {
      var p = points[i];
      if (p && p.onScreen) {
        var d = Math.hypot(p.x - cx, p.y - cy);
        if (d < bestDist) {
          bestDist = d;
          bestPoint = p;
        }
      }
    }

    if (!bestPoint) return;

    ctx.save();
    ctx.font = '600 10px monospace';
    var textMetrics = ctx.measureText(labelText);
    var padX = 6;
    var padY = 3;
    var bgW = textMetrics.width + padX * 2;
    var bgH = 16;
    var bgX = bestPoint.x - bgW / 2;
    var bgY = bestPoint.y - bgH / 2;

    for (var r = 0; r < _drawnLabelRects.length; r++) {
      var prev = _drawnLabelRects[r];
      if (Math.abs(bgX + bgW / 2 - (prev.x + prev.w / 2)) < (bgW + prev.w) / 2 &&
          Math.abs(bgY + bgH / 2 - (prev.y + prev.h / 2)) < (bgH + prev.h) / 2 + 4) {
        bgY = prev.y + prev.h + 4;
      }
    }
    _drawnLabelRects.push({ x: bgX, y: bgY, w: bgW, h: bgH });

    ctx.fillStyle = style.badgeBg || 'rgba(15, 23, 42, 0.85)';
    drawRoundedRect(ctx, bgX, bgY, bgW, bgH, 4);
    ctx.fill();

    ctx.strokeStyle = style.color;
    ctx.lineWidth = 1;
    ctx.setLineDash([]);
    drawRoundedRect(ctx, bgX, bgY, bgW, bgH, 4);
    ctx.stroke();

    ctx.fillStyle = style.textColor || style.color;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(labelText, bgX + bgW / 2, bgY + bgH / 2);
    ctx.restore();
    return { x: bgX, y: bgY, w: bgW, h: bgH };
  }

  var _drawnLabelRects = [];

  function renderMountLimits(ctx, w, h, isNight) {
    _drawnLabelRects = [];
    if (!_showMountLimitsConfig || !_mountLimits || !_mountLimits.enabled || !ready || !stel) {
      _renderedLimitLines = [];
      return;
    }

    var newRendered = [];
    var labels = _mountLimits.labels || {};

    // 1. Overhead limit (altitude circle near zenith)
    if (_mountLimits.maxAltDeg < 90 && _mountLimits.maxAltDeg >= 40) {
      var maxAltRad = _mountLimits.maxAltDeg * Math.PI / 180;
      var overheadPts = [];
      for (var az = 0; az <= 360; az += 5) {
        var p = projectObserved(az * Math.PI / 180, maxAltRad);
        overheadPts.push(p);
      }
      var overheadStyle = {
        color: isNight ? 'rgba(255, 120, 80, 0.9)' : 'rgba(255, 175, 0, 0.9)',
        lineWidth: 1.8,
        dash: [6, 6]
      };
      var segs = drawPolyline(ctx, overheadPts, overheadStyle);
      var ohLabel = labels.overhead || ('Overhead ' + Math.round(_mountLimits.maxAltDeg) + '°');
      var bOh = drawLineLabel(ctx, overheadPts, ohLabel, overheadStyle);
      newRendered.push({
        kind: 'overhead',
        label: ohLabel,
        value: Math.round(_mountLimits.maxAltDeg) + '°',
        segments: segs,
        badgeRect: bOh
      });
    }

    // 2. Horizon limit (minimum altitude circle)
    if (_mountLimits.minAltDeg > -30 && _mountLimits.minAltDeg < 80) {
      var minAltRad = _mountLimits.minAltDeg * Math.PI / 180;
      var horizonPts = [];
      for (var az = 0; az <= 360; az += 5) {
        var p = projectObserved(az * Math.PI / 180, minAltRad);
        horizonPts.push(p);
      }
      var horizonStyle = {
        color: isNight ? 'rgba(255, 100, 70, 0.75)' : 'rgba(255, 150, 50, 0.75)',
        lineWidth: 1.4,
        dash: [5, 5]
      };
      var segs = drawPolyline(ctx, horizonPts, horizonStyle);
      var hzLabel = labels.horizon || ('Horizon ' + Math.round(_mountLimits.minAltDeg) + '°');
      var bHz = drawLineLabel(ctx, horizonPts, hzLabel, horizonStyle);
      newRendered.push({
        kind: 'horizon',
        label: hzLabel,
        value: Math.round(_mountLimits.minAltDeg) + '°',
        segments: segs,
        badgeRect: bHz
      });
    }

    // 3. Meridian Limits (East & West) - GEM mounts only
    if (_mountLimits.isGem) {
      var isEastActive = _mountLimits.activePierSide === 'East';
      var isWestActive = _mountLimits.activePierSide === 'West';

      // East limit
      var merERad = -(_mountLimits.meridianEastMinutes / 4.0) * Math.PI / 180;
      var merEPts = [];
      for (var dec = -85; dec <= 85; dec += 2.5) {
        var p = projectHourAngle(merERad, dec * Math.PI / 180);
        merEPts.push(p);
      }
      var merEStyle = {
        color: isNight
          ? (isEastActive ? 'rgba(255, 70, 70, 0.95)' : 'rgba(255, 70, 70, 0.40)')
          : (isEastActive ? 'rgba(255, 75, 50, 0.95)' : 'rgba(255, 75, 50, 0.40)'),
        lineWidth: isEastActive ? 2.2 : 1.2,
        dash: [6, 4]
      };
      var segsE = drawPolyline(ctx, merEPts, merEStyle);
      var labelE = labels.meridianEast || ('Meridian limit E ' + (_mountLimits.meridianEastMinutes >= 0 ? '+' : '') + Math.round(_mountLimits.meridianEastMinutes) + 'm');
      var bothZero = Math.round(_mountLimits.meridianEastMinutes) === 0 && Math.round(_mountLimits.meridianWestMinutes) === 0;

      var bE = null;
      if (!bothZero) {
        bE = drawLineLabel(ctx, merEPts, labelE, merEStyle, -45);
      }
      newRendered.push({
        kind: 'meridianEast',
        label: labelE,
        value: (_mountLimits.meridianEastMinutes >= 0 ? '+' : '') + Math.round(_mountLimits.meridianEastMinutes) + 'm',
        segments: segsE,
        badgeRect: bE
      });

      // West limit
      var merWRad = +(_mountLimits.meridianWestMinutes / 4.0) * Math.PI / 180;
      var merWPts = [];
      for (var dec = -85; dec <= 85; dec += 2.5) {
        var p = projectHourAngle(merWRad, dec * Math.PI / 180);
        merWPts.push(p);
      }
      var merWStyle = {
        color: isNight
          ? (isWestActive ? 'rgba(255, 70, 70, 0.95)' : 'rgba(255, 70, 70, 0.40)')
          : (isWestActive ? 'rgba(255, 75, 50, 0.95)' : 'rgba(255, 75, 50, 0.40)'),
        lineWidth: isWestActive ? 2.2 : 1.2,
        dash: [6, 4]
      };
      var segsW = drawPolyline(ctx, merWPts, merWStyle);
      var labelW = labels.meridianWest || (bothZero
        ? 'Meridian limit (0m)'
        : ('Meridian limit W ' + (_mountLimits.meridianWestMinutes >= 0 ? '+' : '') + Math.round(_mountLimits.meridianWestMinutes) + 'm'));
      var bW = drawLineLabel(ctx, merWPts, labelW, merWStyle, bothZero ? 0 : 45);
      newRendered.push({
        kind: 'meridianWest',
        label: labelW,
        value: (_mountLimits.meridianWestMinutes >= 0 ? '+' : '') + Math.round(_mountLimits.meridianWestMinutes) + 'm',
        segments: segsW,
        badgeRect: bW
      });
    }

    _renderedLimitLines = newRendered;
  }

  function distToSegment(px, py, x1, y1, x2, y2) {
    var l2 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
    if (l2 === 0) return Math.hypot(px - x1, py - y1);
    var t = ((px - x1) * (x2 - x1) + (py - y1) * (y2 - y1)) / l2;
    t = Math.max(0, Math.min(1, t));
    return Math.hypot(px - (x1 + t * (x2 - x1)), py - (y1 + t * (y2 - y1)));
  }

  function checkLimitLineHit(x, y) {
    if (!_renderedLimitLines || _renderedLimitLines.length === 0) return null;
    var threshold = 35;
    var bestHit = null;
    var minD = threshold;

    for (var i = 0; i < _renderedLimitLines.length; i++) {
      var line = _renderedLimitLines[i];
      if (line.badgeRect) {
        var b = line.badgeRect;
        var pad = 12;
        if (x >= b.x - pad && x <= b.x + b.w + pad && y >= b.y - pad && y <= b.y + b.h + pad) {
          return line;
        }
      }
      var segs = line.segments;
      for (var j = 0; j < segs.length; j++) {
        var s = segs[j];
        var d = distToSegment(x, y, s.x1, s.y1, s.x2, s.y2);
        if (d < minD) {
          minD = d;
          bestHit = line;
        }
      }
    }
    return bestHit;
  }

  function unprojectCoordinates(winX, winY) {
    if (!ready || !stel) return null;
    try {
      var stelCanvas = document.getElementById('stel-canvas');
      if (!stelCanvas) return null;
      var w = stelCanvas.clientWidth;
      var h = stelCanvas.clientHeight;
      if (w <= 0 || h <= 0) return null;

      var aspect = w / h;
      var fov = stel.core.fov;
      var fovy;
      if (aspect < 1) {
        fovy = 4 * Math.atan(Math.tan(fov / 4) / aspect);
      } else {
        fovy = fov;
      }

      var fovy2 = 2 * Math.atan(2 * Math.tan(fovy / 4));
      var f = 1.0 / Math.tan(fovy2 / 2);

      var p0 = 2 * (winX / w) - 1;
      var p1 = 1 - 2 * (winY / h);

      var px = p0 / (f / aspect);
      var py = p1 / f;

      var r2 = px * px + py * py;
      var hStereo = 4.0 / (r2 + 4.0);
      var ux = px * hStereo;
      var uy = py * hStereo;
      var uz = (r2 - 4.0) / (r2 + 4.0);

      var obs = stel.core.observer;
      var vView = [ux, uy, uz];

      // Observed horizontal coordinates (Alt/Az)
      var vObs = stel.convertFrame(obs, 'VIEW', 'OBSERVED', vView);
      if (!vObs) return null;
      var altaz = stel.c2s(vObs);
      var azDeg = stel.anp(altaz[0]) * 180 / Math.PI;
      var altDeg = altaz[1] * 180 / Math.PI;

      // Equatorial ICRF J2000 coordinates (RA/Dec)
      var vIcrf = stel.convertFrame(obs, 'VIEW', 'ICRF', vView);
      if (!vIcrf) return null;
      var radec = stel.c2s(vIcrf);
      var raHours = stel.anp(radec[0]) * 12 / Math.PI;
      var decDeg = stel.anpm(radec[1]) * 180 / Math.PI;

      return {
        raHours: raHours,
        decDeg: decDeg,
        altDeg: altDeg,
        azDeg: azDeg,
        aboveHorizon: altDeg > 0
      };
    } catch (e) {
      log('unprojectCoordinates: ' + e);
      return null;
    }
  }

  function angularDistanceDeg(ra1H, dec1D, ra2H, dec2D) {
    var r1 = ra1H * Math.PI / 12;
    var d1 = dec1D * Math.PI / 180;
    var r2 = ra2H * Math.PI / 12;
    var d2 = dec2D * Math.PI / 180;
    var cosD = Math.sin(d1) * Math.sin(d2) + Math.cos(d1) * Math.cos(d2) * Math.cos(r1 - r2);
    cosD = Math.max(-1, Math.min(1, cosD));
    return Math.acos(cosD) * 180 / Math.PI;
  }

  function drawRoundedRect(ctx, x, y, width, height, radius) {
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + width - radius, y);
    ctx.arcTo(x + width, y, x + width, y + radius, radius);
    ctx.lineTo(x + width, y + height - radius);
    ctx.arcTo(x + width, y + height, x + width - radius, y + height, radius);
    ctx.lineTo(x + radius, y + height);
    ctx.arcTo(x, y + height, x, y + height - radius, radius);
    ctx.lineTo(x, y + radius);
    ctx.arcTo(x, y, x + radius, y, radius);
    ctx.closePath();
  }

  function drawOnScreenReticle(ctx, x, y, telescope, isNight) {
    var mainColor, glowColor, statusText;
    var now = Date.now();

    if (isNight) {
      if (telescope.isSlewing) {
        mainColor = '#FF5252';
        glowColor = 'rgba(255, 82, 82, 0.6)';
        statusText = 'SLEWING';
      } else if (telescope.isParked) {
        mainColor = '#FF8A80';
        glowColor = 'rgba(255, 138, 128, 0.5)';
        statusText = 'PARK';
      } else if (telescope.isAtHome) {
        mainColor = '#FF6E40';
        glowColor = 'rgba(255, 110, 64, 0.5)';
        statusText = 'AT HOME';
      } else if (telescope.isTracking) {
        mainColor = '#FF3333';
        glowColor = 'rgba(255, 51, 51, 0.5)';
        statusText = 'TRACKING';
      } else {
        mainColor = '#B71C1C';
        glowColor = 'rgba(183, 28, 28, 0.3)';
        statusText = 'TRACKING OFF';
      }
    } else {
      if (telescope.isSlewing) {
        mainColor = '#FF9100';
        glowColor = 'rgba(255, 145, 0, 0.6)';
        statusText = 'SLEWING';
      } else if (telescope.isParked) {
        mainColor = '#FFAB40';
        glowColor = 'rgba(255, 171, 64, 0.5)';
        statusText = 'PARK';
      } else if (telescope.isAtHome) {
        mainColor = '#448AFF';
        glowColor = 'rgba(68, 138, 255, 0.5)';
        statusText = 'AT HOME';
      } else if (telescope.isTracking) {
        mainColor = '#00E5FF';
        glowColor = 'rgba(0, 229, 255, 0.5)';
        statusText = 'TRACKING';
      } else {
        mainColor = '#90A4AE';
        glowColor = 'rgba(144, 164, 174, 0.35)';
        statusText = 'TRACKING OFF';
      }
    }

    ctx.save();
    ctx.shadowColor = glowColor;
    ctx.shadowBlur = 6;
    ctx.strokeStyle = mainColor;
    ctx.fillStyle = mainColor;

    // Outer circle
    var outerRadius = 23;
    ctx.beginPath();
    ctx.arc(x, y, outerRadius, 0, 2 * Math.PI);
    ctx.lineWidth = 1.5;
    ctx.stroke();

    // Inner circle (pulsing if slewing)
    var innerRadius = 8;
    if (telescope.isSlewing) {
      var pulse = 0.5 + 0.5 * Math.sin(now / 150);
      innerRadius = 7 + 2 * pulse;
      ctx.globalAlpha = 0.7 + 0.3 * pulse;
    }
    ctx.beginPath();
    ctx.arc(x, y, innerRadius, 0, 2 * Math.PI);
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.globalAlpha = 1.0;

    // Center point
    ctx.beginPath();
    ctx.arc(x, y, 1.5, 0, 2 * Math.PI);
    ctx.fill();

    // 4 crosshair ticks (rotating slightly when slewing)
    var tickAngleOffset = telescope.isSlewing ? (now / 600) % (Math.PI / 2) : 0;
    ctx.lineWidth = 1.5;
    for (var i = 0; i < 4; i++) {
      var angle = tickAngleOffset + i * (Math.PI / 2);
      var cosA = Math.cos(angle);
      var sinA = Math.sin(angle);
      var r1 = outerRadius - 3;
      var r2 = outerRadius + 6;
      ctx.beginPath();
      ctx.moveTo(x + r1 * cosA, y + r1 * sinA);
      ctx.lineTo(x + r2 * cosA, y + r2 * sinA);
      ctx.stroke();
    }

    // Corner brackets at 45 deg, radius 30px
    var bracketR = 30;
    var bracketArc = 14 * Math.PI / 180;
    ctx.lineWidth = 1.0;
    for (var b = 0; b < 4; b++) {
      var bAngle = (Math.PI / 4) + b * (Math.PI / 2);
      ctx.beginPath();
      ctx.arc(x, y, bracketR, bAngle - bracketArc / 2, bAngle + bracketArc / 2);
      ctx.stroke();
    }

    // Badge pill below reticle
    ctx.shadowBlur = 0;
    var badgeY = y + outerRadius + 14;
    ctx.font = 'bold 9px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
    var textMetrics = ctx.measureText(statusText);
    var textW = textMetrics.width;
    var padX = 6;
    var badgeW = textW + padX * 2;
    var badgeH = 16;
    var badgeX = x - badgeW / 2;

    ctx.fillStyle = 'rgba(8, 12, 22, 0.75)';
    drawRoundedRect(ctx, badgeX, badgeY - badgeH / 2, badgeW, badgeH, 4);
    ctx.fill();
    ctx.strokeStyle = mainColor;
    ctx.lineWidth = 1;
    ctx.stroke();

    ctx.fillStyle = mainColor;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(statusText, x, badgeY);

    ctx.restore();
  }

  function drawOffScreenIndicator(ctx, proj, telescope, isNight) {
    var w = proj.width;
    var h = proj.height;
    var cx = w / 2;
    var cy = h / 2;

    var dx = proj.dirX;
    var dy = proj.dirY;
    var len = Math.sqrt(dx * dx + dy * dy);
    var nx = len < 1e-6 ? 0 : dx / len;
    var ny = len < 1e-6 ? 1 : dy / len;

    // Viewport padding margins
    var padX = 36;
    var padTop = 64;
    var padBottom = 54;

    var xmin = padX;
    var xmax = w - padX;
    var ymin = padTop;
    var ymax = h - padBottom;

    var tx = nx > 0 ? (xmax - cx) / nx : (nx < 0 ? (xmin - cx) / nx : 1e9);
    var ty = ny > 0 ? (ymax - cy) / ny : (ny < 0 ? (ymin - cy) / ny : 1e9);
    var t = Math.min(tx, ty);

    var ex = cx + nx * t;
    var ey = cy + ny * t;
    var phi = Math.atan2(ny, nx);

    var mainColor, glowColor;
    if (isNight) {
      if (telescope.isSlewing) {
        mainColor = '#FF5252';
        glowColor = 'rgba(255, 82, 82, 0.6)';
      } else if (telescope.isParked) {
        mainColor = '#FF8A80';
        glowColor = 'rgba(255, 138, 128, 0.5)';
      } else if (telescope.isAtHome) {
        mainColor = '#FF6E40';
        glowColor = 'rgba(255, 110, 64, 0.5)';
      } else if (telescope.isTracking) {
        mainColor = '#FF3333';
        glowColor = 'rgba(255, 51, 51, 0.5)';
      } else {
        mainColor = '#B71C1C';
        glowColor = 'rgba(183, 28, 28, 0.3)';
      }
    } else {
      if (telescope.isSlewing) {
        mainColor = '#FF9100';
        glowColor = 'rgba(255, 145, 0, 0.5)';
      } else if (telescope.isParked) {
        mainColor = '#FFAB40';
        glowColor = 'rgba(255, 171, 64, 0.5)';
      } else if (telescope.isAtHome) {
        mainColor = '#448AFF';
        glowColor = 'rgba(68, 138, 255, 0.4)';
      } else if (telescope.isTracking) {
        mainColor = '#00E5FF';
        glowColor = 'rgba(0, 229, 255, 0.4)';
      } else {
        mainColor = '#90A4AE';
        glowColor = 'rgba(144, 164, 174, 0.35)';
      }
    }

    ctx.save();
    ctx.shadowColor = glowColor;
    ctx.shadowBlur = 6;
    ctx.fillStyle = mainColor;
    ctx.strokeStyle = mainColor;

    // Draw directional pointer arrow
    ctx.save();
    ctx.translate(ex, ey);
    ctx.rotate(phi);
    ctx.beginPath();
    ctx.moveTo(9, 0);
    ctx.lineTo(-8, -6);
    ctx.lineTo(-4, 0);
    ctx.lineTo(-8, 6);
    ctx.closePath();
    ctx.fill();
    ctx.restore();

    // Badge text: SCOPE + angular separation
    ctx.shadowBlur = 0;
    var distText = Math.round(proj.angDistDeg) + '°';
    var badgeText = 'SCOPE ' + distText;
    ctx.font = 'bold 9px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
    var textW = ctx.measureText(badgeText).width;
    var badgeW = textW + 12;
    var badgeH = 18;

    // Position badge inward from the pointer arrow
    var offsetInward = 24 + badgeW / 2;
    var bx = ex - nx * offsetInward;
    var by = ey - ny * offsetInward;

    // Clamp badge within visible area
    bx = Math.max(badgeW / 2 + 10, Math.min(w - badgeW / 2 - 10, bx));
    by = Math.max(badgeH / 2 + 50, Math.min(h - badgeH / 2 - 40, by));

    ctx.fillStyle = 'rgba(8, 12, 22, 0.82)';
    drawRoundedRect(ctx, bx - badgeW / 2, by - badgeH / 2, badgeW, badgeH, 5);
    ctx.fill();
    ctx.strokeStyle = mainColor;
    ctx.lineWidth = 1;
    ctx.stroke();

    ctx.fillStyle = mainColor;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(badgeText, bx, by);

    ctx.restore();
  }

  function renderReticleLoop() {
    requestAnimationFrame(renderReticleLoop);

    if (!reticleCanvas) {
      reticleCanvas = document.getElementById('reticle-canvas');
      if (reticleCanvas) reticleCtx = reticleCanvas.getContext('2d');
    }
    if (!reticleCanvas || !reticleCtx) return;

    var stelCanvas = document.getElementById('stel-canvas');
    if (!stelCanvas) return;

    var w = stelCanvas.clientWidth;
    var h = stelCanvas.clientHeight;
    if (w <= 0 || h <= 0) return;

    var dpr = window.devicePixelRatio || 1;
    var rw = Math.round(w * dpr);
    var rh = Math.round(h * dpr);

    if (reticleCanvas.width !== rw || reticleCanvas.height !== rh) {
      reticleCanvas.width = rw;
      reticleCanvas.height = rh;
    }

    reticleCtx.clearRect(0, 0, rw, rh);

    reticleCtx.save();
    reticleCtx.scale(dpr, dpr);

    if (temporaryRing) {
      var now = performance.now();
      var elapsed = now - temporaryRing.startTime;
      if (temporaryRing.duration && temporaryRing.duration > 0 && elapsed > temporaryRing.duration) {
        temporaryRing = null;
      } else {
        var ringX = temporaryRing.x;
        var ringY = temporaryRing.y;
        if (temporaryRing.raHours !== undefined && temporaryRing.decDeg !== undefined) {
          var proj = projectCoordinates(temporaryRing.raHours, temporaryRing.decDeg);
          if (proj && proj.onScreen) {
            ringX = proj.x;
            ringY = proj.y;
          }
        }

        var pulse = 1.0 + 0.10 * Math.sin(now / 180.0);
        var baseRadius = 24 * pulse;
        var isNightRing = false;
        var rootEl = document.getElementById('stel-root');
        if (rootEl && rootEl.classList.contains('night-mode')) {
          isNightRing = true;
        }

        reticleCtx.save();
        reticleCtx.strokeStyle = isNightRing
          ? 'rgba(255, 82, 82, 0.9)'
          : 'rgba(0, 229, 255, 0.9)';
        reticleCtx.lineWidth = 2;
        reticleCtx.shadowColor = isNightRing ? '#FF5252' : '#00E5FF';
        reticleCtx.shadowBlur = 8;

        reticleCtx.beginPath();
        reticleCtx.arc(ringX, ringY, baseRadius, 0, 2 * Math.PI);
        reticleCtx.stroke();

        var tick = 6;
        reticleCtx.beginPath();
        reticleCtx.moveTo(ringX - baseRadius - tick, ringY);
        reticleCtx.lineTo(ringX - baseRadius + 3, ringY);
        reticleCtx.moveTo(ringX + baseRadius - 3, ringY);
        reticleCtx.lineTo(ringX + baseRadius + tick, ringY);
        reticleCtx.moveTo(ringX, ringY - baseRadius - tick);
        reticleCtx.lineTo(ringX, ringY - baseRadius + 3);
        reticleCtx.moveTo(ringX, ringY + baseRadius - 3);
        reticleCtx.lineTo(ringX, ringY + baseRadius + tick);
        reticleCtx.stroke();

        reticleCtx.restore();
      }
    }

    var isNight = false;
    var root = document.getElementById('stel-root');
    if (root && root.classList.contains('night-mode')) {
      isNight = true;
    }

    renderMountLimits(reticleCtx, w, h, isNight);

    if (!_telescope || !ready || !stel) {
      reticleCtx.restore();
      return;
    }

    if (_displayTelescope) {
      var dRa = _telescope.raHours - _displayTelescope.raHours;
      if (dRa > 12) dRa -= 24;
      else if (dRa < -12) dRa += 24;
      var dDec = _telescope.decDeg - _displayTelescope.decDeg;

      if (Math.abs(dRa) < 1e-7 && Math.abs(dDec) < 1e-7) {
        _displayTelescope.raHours = _telescope.raHours;
        _displayTelescope.decDeg = _telescope.decDeg;
      } else {
        var lerpFactor = 0.2;
        _displayTelescope.raHours += dRa * lerpFactor;
        if (_displayTelescope.raHours >= 24) _displayTelescope.raHours -= 24;
        else if (_displayTelescope.raHours < 0) _displayTelescope.raHours += 24;
        _displayTelescope.decDeg += dDec * lerpFactor;
      }
    } else {
      _displayTelescope = { raHours: _telescope.raHours, decDeg: _telescope.decDeg };
    }

    var proj = projectCoordinates(_displayTelescope.raHours, _displayTelescope.decDeg);
    if (proj) {
      var isNight = false;
      var root = document.getElementById('stel-root');
      if (root && root.classList.contains('night-mode')) {
        isNight = true;
      }

      if (proj.onScreen) {
        drawOnScreenReticle(reticleCtx, proj.x, proj.y, _telescope, isNight);
      } else {
        drawOffScreenIndicator(reticleCtx, proj, _telescope, isNight);
      }
    }

    reticleCtx.restore();
  }

  function startReticleLoop() {
    if (reticleLoopActive) return;
    reticleLoopActive = true;
    requestAnimationFrame(renderReticleLoop);
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

  var holdTimer = null;
  var holdStartPos = null;
  var holdTriggered = false;
  var temporaryRing = null;

  function triggerLongPress(x, y) {
    if (!ready || !stel) return;
    holdTriggered = true;
    holdTimer = null;

    var coords = unprojectCoordinates(x, y);
    if (!coords) return;

    if (!coords.aboveHorizon) {
      post('long_press', {
        aboveHorizon: false,
        altDeg: coords.altDeg,
        azDeg: coords.azDeg,
        raHours: coords.raHours,
        decDeg: coords.decDeg
      });
      return;
    }

    temporaryRing = {
      x: x,
      y: y,
      raHours: coords.raHours,
      decDeg: coords.decDeg,
      startTime: performance.now(),
      duration: 0
    };

    var targetObj = null;
    if (stel.core && stel.core.selection) {
      var selPayload = objectPayload(stel.core.selection);
      if (selPayload) {
        var dist = angularDistanceDeg(coords.raHours, coords.decDeg, selPayload.raHours, selPayload.decDeg);
        if (dist <= 1.5) {
          targetObj = selPayload;
        }
      }
    }

    releaseEngineInput(false);

    post('long_press', {
      aboveHorizon: true,
      raHours: coords.raHours,
      decDeg: coords.decDeg,
      altDeg: coords.altDeg,
      azDeg: coords.azDeg,
      object: targetObj
    });
  }

  function setupLongPress(canvas) {
    if (!canvas) return;

    function onDown(e) {
      if (e.button !== undefined && e.button !== 0) return;
      if (holdTimer) clearTimeout(holdTimer);
      holdTriggered = false;
      var rect = canvas.getBoundingClientRect();
      var x = e.clientX - rect.left;
      var y = e.clientY - rect.top;
      holdStartPos = { x: x, y: y, clientX: e.clientX, clientY: e.clientY };

      holdTimer = setTimeout(function () {
        if (holdStartPos) {
          triggerLongPress(holdStartPos.x, holdStartPos.y);
        }
      }, 500);
    }

    function onMove(e) {
      if (!holdStartPos) return;
      var dx = e.clientX - holdStartPos.clientX;
      var dy = e.clientY - holdStartPos.clientY;
      if (Math.sqrt(dx * dx + dy * dy) > 12) {
        if (holdTimer) {
          clearTimeout(holdTimer);
          holdTimer = null;
        }
        post('user_pan', {});
      }
    }

    function onUp(e) {
      if (holdTimer) {
        clearTimeout(holdTimer);
        holdTimer = null;
      }
      if (holdStartPos && !holdTriggered) {
        var dx = e.clientX - holdStartPos.clientX;
        var dy = e.clientY - holdStartPos.clientY;
        if (Math.hypot(dx, dy) < 25) {
          var hit = checkLimitLineHit(holdStartPos.x, holdStartPos.y);
          if (hit) {
            lastLimitTapTime = performance.now();
            post('limit_line_tap', {
              kind: hit.kind,
              label: hit.label,
              value: hit.value,
              screenX: holdStartPos.clientX !== undefined ? holdStartPos.clientX : holdStartPos.x,
              screenY: holdStartPos.clientY !== undefined ? holdStartPos.clientY : holdStartPos.y,
              x: holdStartPos.x,
              y: holdStartPos.y
            });
            releaseEngineInput(true);
          }
        }
      }
    }

    canvas.addEventListener('pointerdown', onDown, { passive: true });
    window.addEventListener('pointermove', onMove, { passive: true });
    window.addEventListener('pointerup', onUp, { passive: true });
    window.addEventListener('pointercancel', onUp, { passive: true });
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
      setupLongPress(canvas);
      startReticleLoop();
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }

  window.MlastroSky = {
    isReady: function () { return ready; },

    setTelescope: setTelescope,

    centerOnTelescope: centerOnTelescope,

    setMountLimits: setMountLimits,

    releaseInput: releaseEngineInput,

    resumeInteraction: function () {
      releaseEngineInput(false);
    },

    dismissPanel: function () {
      lastSelectionId = null;
      temporaryRing = null;
    },

    clearTargetRing: function () {
      temporaryRing = null;
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

    setSensorOrientation: function (azDeg, altDeg, rollDeg) {
      if (!ready || !stel) return;
      try {
        var azRad = azDeg * Math.PI / 180;
        var altRad = altDeg * Math.PI / 180;
        var obsVector = stel.s2c(azRad, altRad);
        stel.lookAt(obsVector, 0);
        if (rollDeg !== undefined && rollDeg !== null) {
          var obs = (stel.core && stel.core.observer) ? stel.core.observer : stel.observer;
          if (obs && typeof obs.roll !== 'undefined') {
            obs.roll = rollDeg * Math.PI / 180;
          }
        }
      } catch (e) {
        log('setSensorOrientation: ' + e);
      }
    },

    resetSensorOrientation: function () {
      if (!ready || !stel) return;
      try {
        var obs = (stel.core && stel.core.observer) ? stel.core.observer : stel.observer;
        if (obs && typeof obs.roll !== 'undefined') {
          obs.roll = 0;
        }
      } catch (e) {
        log('resetSensorOrientation: ' + e);
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
        temporaryRing = null;
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
