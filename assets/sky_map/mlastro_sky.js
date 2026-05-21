/* MLASTRO bridge for Stellarium Web Engine (AGPL-3.0, Stellarium Labs) */
(function () {
  'use strict';

  var stel = null;
  var ready = false;
  var pendingObserver = null;
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
    var cirs = stel.convertFrame(obs, 'ICRF', 'CIRS', obj.getInfo('radec'));
    var radec = stel.c2s(cirs);
    var raRad = stel.anp(radec[0]);
    var decRad = stel.anpm(radec[1]);
    var vmag = obj.getInfo('vmag');
    return {
      kind: inferKind(obj),
      id: (names && names[0]) || label,
      name: label,
      raHours: raRad * 12 / Math.PI,
      decDeg: decRad * 180 / Math.PI,
      magnitude: typeof vmag === 'number' ? vmag : null
    };
  }

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

    [
      'Sun', 'Moon', 'Mercury', 'Venus', 'Mars', 'Jupiter', 'Saturn',
      'Uranus', 'Neptune', 'Pluto', 'Sirius', 'Vega', 'Polaris',
      'Betelgeuse', 'Rigel', 'Arcturus', 'Capella', 'Altair', 'Deneb',
      'Aldebaran', 'Antares', 'Spica', 'Regulus', 'Fomalhaut',
      'Andromeda Galaxy', 'Orion Nebula', 'Pleiades'
    ].forEach(function (name) {
      if (name.toUpperCase().indexOf(upper) >= 0 || upper.indexOf(name.toUpperCase().replace(/\s+/g, '')) >= 0) {
        add('NAME ' + name);
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
      // WebKit may synthesize mouse-down without a matching up when a Flutter
      // modal steals the gesture; release it so pan/zoom works again.
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
      core.lines.azimuthal.visible = false;
      core.lines.equatorial.visible = false;
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
