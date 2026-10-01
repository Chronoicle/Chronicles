<?php
define('ALLOWED_ACCESS', true);
require_once __DIR__ . '/../../includes/paths.php';
require_once $project_root . 'includes/session.php';
require_once $project_root . 'languages/language.php';
require_once $project_root . 'includes/config.settings.php';
$page_class = 'botwatch';
define('DB_SITE', $db_site_name);
if (!isset($_SESSION['user_id'])) { header("Location: {$base_path}login"); exit; }
global $site_db;
$stmt = $site_db->prepare("SELECT role FROM " . DB_SITE . ".user_currencies WHERE account_id = ?"); $stmt->bind_param("i", $_SESSION['user_id']); $stmt->execute(); $r = $stmt->get_result();
$_SESSION['role'] = $r->num_rows > 0 ? $r->fetch_assoc()['role'] : 'player'; $stmt->close();
if (!in_array($_SESSION['role'], ['admin', 'moderator'])) { header("Location: {$base_path}login"); exit; }
session_write_close();      // the page polls every 2 s: don't hold the session lock while reading (dev-check)
header('X-Content-Type-Options: nosniff');

// Navmesh outline for the map view (tools/mmap_to_json.py writes cache/botwatch/mesh_<map>.json).
if (isset($_GET['mesh'])) {
    header('Content-Type: application/json');
    $map = (int)$_GET['mesh'];
    if ($map < 0 || $map > 2000) { http_response_code(400); echo json_encode(['error' => 'bad map']); exit; }
    if (isset($_GET['demo'])) {
        if ($map !== 389) { http_response_code(404); echo json_encode(['error' => 'no mesh']); exit; }
        // fake Ragefire Chasm: rooms + corridors at the bots' level and a cave ~20 yd under it
        header('Cache-Control: max-age=3600');
        echo <<<'MESH'
{"map":389,"tiles":1,"bounds":[-372,-12,29,224],"polys":[[-22,5,12,29,12,19.4,26.4],
[-22,5,12,19.4,26.4,5,36],
[-22,5,12,5,36,-9.4,26.4],
[-22,5,12,-9.4,26.4,-19,12],
[-22,5,12,-19,12,-9.4,-2.4],
[-22,5,12,-9.4,-2.4,5,-12],
[-22,5,12,5,-12,19.4,-2.4],
[-22,5,12,19.4,-2.4,29,12],
[-21.7,1.9,2.5,-26.5,11.8,-20.2,30.8,8.1,21.5],
[-21,-26.5,11.8,-54.8,21.2,-48.5,40.2,-20.2,30.8],
[-20.3,-54.8,21.2,-83.1,30.5,-76.9,49.5,-48.5,40.2],
[-20,-80,40,-50,40,-62,58],
[-20,-80,40,-62,58,-80,70],
[-20,-80,40,-80,70,-98,58],
[-20,-80,40,-98,58,-110,40],
[-20,-80,40,-110,40,-98,22],
[-20,-80,40,-98,22,-80,10],
[-20,-80,40,-80,10,-62,22],
[-20,-80,40,-62,22,-50,40],
[-20.6,-85.8,31.8,-111.3,49.8,-99.7,66.2,-74.2,48.2],
[-21.9,-111.3,49.8,-136.8,67.8,-125.2,84.2,-99.7,66.2],
[-23.1,-136.8,67.8,-162.3,85.8,-150.7,102.2,-125.2,84.2],
[-24.4,-162.3,85.8,-187.8,103.8,-176.2,120.2,-150.7,102.2],
[-25,-182,112,-144,112,-159.2,134.8],
[-25,-182,112,-159.2,134.8,-182,150],
[-25,-182,112,-182,150,-204.8,134.8],
[-25,-182,112,-204.8,134.8,-220,112],
[-25,-182,112,-220,112,-204.8,89.2],
[-25,-182,112,-204.8,89.2,-182,74],
[-25,-182,112,-182,74,-159.2,89.2],
[-25,-182,112,-159.2,89.2,-144,112],
[-25.8,-185.7,103.8,-213.4,116.5,-205.9,132.8,-178.3,120.2],
[-27.5,-213.4,116.5,-241.1,129.2,-233.6,145.5,-205.9,132.8],
[-29.2,-241.1,129.2,-268.7,141.8,-261.3,158.2,-233.6,145.5],
[-30,-265,150,-235,150,-247,168],
[-30,-265,150,-247,168,-265,180],
[-30,-265,150,-265,180,-283,168],
[-30,-265,150,-283,168,-295,150],
[-30,-265,150,-295,150,-283,132],
[-30,-265,150,-283,132,-265,120],
[-30,-265,150,-265,120,-247,132],
[-30,-265,150,-247,132,-235,150],
[-30.5,-269.4,142.1,-294.4,156.1,-285.6,171.9,-260.6,157.9],
[-31.5,-294.4,156.1,-319.4,170.1,-310.6,185.9,-285.6,171.9],
[-32.5,-319.4,170.1,-344.4,184.1,-335.6,199.9,-310.6,185.9],
[-33,-340,192,-308,192,-320.8,211.2],
[-33,-340,192,-320.8,211.2,-340,224],
[-33,-340,192,-340,224,-359.2,211.2],
[-33,-340,192,-359.2,211.2,-372,192],
[-33,-340,192,-372,192,-359.2,172.8],
[-33,-340,192,-359.2,172.8,-340,160],
[-33,-340,192,-340,160,-320.8,172.8],
[-33,-340,192,-320.8,172.8,-308,192],
[-45,-130,150,-100,150,-112,168],
[-45,-130,150,-112,168,-130,180],
[-45,-130,150,-130,180,-148,168],
[-45,-130,150,-148,168,-160,150],
[-45,-130,150,-160,150,-148,132],
[-45,-130,150,-148,132,-130,120],
[-45,-130,150,-130,120,-112,132],
[-45,-130,150,-112,132,-100,150],
[-45.1,-123.3,144,-144.5,120.2,-158,132.3,-136.7,156],
[-45.4,-144.5,120.2,-165.8,96.5,-179.2,108.5,-158,132.3],
[-45.6,-165.8,96.5,-187,72.7,-200.5,84.8,-179.2,108.5],
[-45.9,-187,72.7,-208.3,49,-221.7,61,-200.5,84.8],
[-46,-215,55,-189,55,-199.4,70.6],
[-46,-215,55,-199.4,70.6,-215,81],
[-46,-215,55,-215,81,-230.6,70.6],
[-46,-215,55,-230.6,70.6,-241,55],
[-46,-215,55,-241,55,-230.6,39.4],
[-46,-215,55,-230.6,39.4,-215,29],
[-46,-215,55,-215,29,-199.4,39.4],
[-46,-215,55,-199.4,39.4,-189,55]]}
MESH;
        exit;
    }
    $f = $project_root . 'cache/botwatch/mesh_' . $map . '.json';
    if (!is_file($f)) { http_response_code(404); echo json_encode(['error' => 'no mesh']); exit; }
    header('Cache-Control: max-age=3600');
    readfile($f);
    exit;
}

// Live dungeon bot runs. The worldserver writes cache/botwatch/run_<id>.json every 2 s.
if (isset($_GET['json'])) {
    header('Content-Type: application/json');
    header('Cache-Control: no-store');
    $now = time();
    $runs = [];
    if (isset($_GET['demo'])) {
        $trail = [];
        for ($i = 0; $i < 40; $i++) {
            $trail[] = [round(-$i * 4.6, 1), round(10 + $i * 2.5 + 6 * sin($i / 4), 1)];
        }
        $runs[] = [
            'run' => 12, 'dungeon' => 7, 'name' => 'Ragefire Chasm', 'map' => 389, 'instance' => 123,
            'level' => 15, 'state' => 'fight', 'updated' => $now, 'elapsed' => 342,
            'wipes' => 0, 'killed' => 1, 'total' => 4,
            'bosses' => [
                ['entry' => 11517, 'name' => 'Oggleflint', 'x' => -80.0, 'y' => 40.0, 'z' => -20.1, 'status' => 'killed', 'hp' => 0],
                ['entry' => 11520, 'name' => 'Taragaman the Hungerer', 'x' => -182.0, 'y' => 112.0, 'z' => -25.4, 'status' => 'current', 'hp' => 62],
                ['entry' => 11518, 'name' => 'Jergosh the Invoker', 'x' => -265.0, 'y' => 150.0, 'z' => -30.2, 'status' => 'alive', 'hp' => 100],
                ['entry' => 11519, 'name' => 'Bazzalan', 'x' => -340.0, 'y' => 192.0, 'z' => -32.8, 'status' => 'alive', 'hp' => 100],
            ],
            'bots' => [
                ['name' => 'Tankbot', 'class' => 'Warrior', 'spec' => 'Protection', 'role' => 'tank', 'level' => 15, 'hp' => 1234, 'maxhp' => 1500, 'power' => 80, 'powerType' => 'rage', 'alive' => true, 'x' => -179.0, 'y' => 108.0, 'z' => -25.0, 'o' => 2.3, 'target' => 'Taragaman the Hungerer', 'targetHp' => 62],
                ['name' => 'Healbot', 'class' => 'Priest', 'spec' => 'Holy', 'role' => 'healer', 'level' => 15, 'hp' => 820, 'maxhp' => 880, 'power' => 45, 'powerType' => 'mana', 'alive' => true, 'x' => -160.0, 'y' => 92.0, 'z' => -24.0, 'o' => 2.5, 'target' => 'Tankbot', 'targetHp' => 82],
                ['name' => 'Frostbot', 'class' => 'Mage', 'spec' => 'Frost', 'role' => 'dps', 'level' => 15, 'hp' => 610, 'maxhp' => 790, 'power' => 30, 'powerType' => 'mana', 'alive' => true, 'x' => -165.0, 'y' => 118.0, 'z' => -24.5, 'o' => 2.0, 'target' => 'Taragaman the Hungerer', 'targetHp' => 62],
                ['name' => 'Stabbot', 'class' => 'Rogue', 'spec' => 'Outlaw', 'role' => 'dps', 'level' => 15, 'hp' => 0, 'maxhp' => 1010, 'power' => 0, 'powerType' => 'energy', 'alive' => false, 'x' => -186.0, 'y' => 104.0, 'z' => -25.2, 'o' => 0.4, 'target' => '', 'targetHp' => 0],
                ['name' => 'Shootbot', 'class' => 'Hunter', 'spec' => 'Marksmanship', 'role' => 'dps', 'level' => 15, 'hp' => 940, 'maxhp' => 1050, 'power' => 70, 'powerType' => 'focus', 'alive' => true, 'x' => -152.0, 'y' => 125.0, 'z' => -24.0, 'o' => 2.2, 'target' => 'Taragaman the Hungerer', 'targetHp' => 62],
            ],
            'trail' => $trail,
            'route' => [[-179.0, 108.0], [-196.0, 116.0], [-214.0, 125.0], [-232.0, 134.0], [-249.0, 142.0], [-262.0, 148.0]],
            'events' => [
                ['t' => '02:35:23', 'text' => 'event=start run=12 dungeon=7 map=389 level=15'],
                ['t' => '02:36:40', 'text' => 'event=pull run=12 target=Oggleflint'],
                ['t' => '02:37:58', 'text' => 'event=kill run=12 boss=Oggleflint killed=1/4'],
                ['t' => '02:38:10', 'text' => 'event=rest run=12 reason=mana'],
                ['t' => '02:39:30', 'text' => 'event=walk run=12 to=Taragaman the Hungerer'],
                ['t' => '02:40:52', 'text' => 'event=pull run=12 target=Taragaman the Hungerer'],
                ['t' => '02:41:05', 'text' => 'event=death run=12 bot=Stabbot'],
                ['t' => '02:41:12', 'text' => 'event=fight run=12 boss=Taragaman the Hungerer hp=62'],
            ],
        ];
    } else {
        $files = glob($project_root . 'cache/botwatch/run_*.json');
        foreach ($files ?: [] as $f) {
            $mt = @filemtime($f);
            if ($mt === false) continue;
            if ($now - $mt > 3600) { @unlink($f); continue; }     // a new run id every pass: old files go after an hour
            if ($now - $mt > 600 || @filesize($f) > 1048576) continue;
            // a name cut in half by the log line limit costs one character, not the whole run (dev-check)
            $run = json_decode((string)@file_get_contents($f), true, 512, JSON_INVALID_UTF8_SUBSTITUTE);
            if (!is_array($run)) continue;
            $runs[] = $run;
        }
        usort($runs, function ($a, $b) {
            return (int)($b['updated'] ?? 0) - (int)($a['updated'] ?? 0);
        });
    }
    echo json_encode(['now' => $now, 'runs' => $runs]);
    exit;
}
?><!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Bot Watch</title>
<style>
:root { --bg:#0f1115; --card:#181b22; --line:#2a2f3a; --text:#d8dce4; --dim:#8a92a3; }
* { box-sizing: border-box; }
body { margin:0; background:var(--bg); color:var(--text); font:14px/1.4 system-ui, "Segoe UI", Roboto, Arial, sans-serif; }
header { padding:12px 16px; border-bottom:1px solid var(--line); display:flex; gap:12px; align-items:baseline; flex-wrap:wrap; }
header h1 { margin:0; font-size:18px; }
#status { color:var(--dim); font-size:12px; }
#err { color:#ff6b6b; font-size:13px; padding:0 16px; }
#runs { padding:16px; display:flex; flex-direction:column; gap:16px; }
.empty { color:var(--dim); padding:40px; text-align:center; font-size:16px; }
.card { background:var(--card); border:1px solid var(--line); border-radius:8px; padding:12px; }
.title { display:flex; gap:10px; align-items:center; flex-wrap:wrap; margin-bottom:10px; }
.title h2 { margin:0; font-size:17px; }
.meta { color:var(--dim); font-size:13px; }
.badge { padding:2px 8px; border-radius:10px; font-size:12px; font-weight:600; color:#111; text-transform:uppercase; }
.s-gather { background:#9aa5b8; } .s-walk { background:#6fb3ff; } .s-pull { background:#ffb347; }
.s-fight { background:#ff5c5c; } .s-rest { background:#5ad17a; } .s-wipe { background:#c77dff; }
.s-ended { background:#5b6270; color:#ddd; } .stale { background:#d62828; color:#fff; }
.grid { display:grid; grid-template-columns:minmax(300px, 600px) 1fr; gap:12px; align-items:start; }
@media (max-width: 1000px) { .grid { grid-template-columns:1fr; } }
canvas { width:100%; max-width:600px; aspect-ratio:3/2; background:#0b0d11; border:1px solid var(--line); border-radius:6px; display:block; }
table { width:100%; border-collapse:collapse; font-size:13px; }
th, td { text-align:left; padding:4px 6px; border-bottom:1px solid var(--line); white-space:nowrap; }
th { color:var(--dim); font-weight:500; }
tr.dead td { color:#6b7280; }
.bar { position:relative; width:130px; height:16px; background:#2a2f3a; border-radius:3px; overflow:hidden; }
.bar > div { height:100%; }
.bar > span { position:absolute; inset:0; font-size:11px; line-height:16px; text-align:center; color:#fff; text-shadow:0 0 2px #000; }
.r-tank { color:#6fb3ff; } .r-healer { color:#5ad17a; } .r-dps { color:#ff7b7b; }
.feed { margin-top:10px; font:12px/1.5 Consolas, "Courier New", monospace; max-height:220px; overflow:auto; background:#0b0d11; border:1px solid var(--line); border-radius:6px; padding:6px 8px; }
.feed .t { color:var(--dim); margin-right:8px; }
</style>
</head>
<body>
<header><h1>Bot Watch</h1><span id="status">loading...</span></header>
<div id="err"></div>
<div id="runs"></div>
<script>
(function () {
  'use strict';
  var demo = /[?&]demo=1(&|$)/.test(location.search);
  var url = '?json=1' + (demo ? '&demo=1' : '');
  var STATES = ['gather', 'walk', 'pull', 'fight', 'rest', 'wipe', 'ended'];
  var POWER = { 'mana': '#3b82f6', 'rage': '#dc2626', 'energy': '#eab308', 'focus': '#f97316', 'runic power': '#22d3ee', 'runic_power': '#22d3ee', 'runicpower': '#22d3ee' };
  var DPS_COLORS = ['#ff5c5c', '#ffd23f', '#ff8fa3', '#f4a259'];

  function num(v) { v = Number(v); return isFinite(v) ? v : 0; }
  function str(v) { return v === undefined || v === null ? '' : String(v); }
  function arr(v) { return Array.isArray(v) ? v : []; }
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text !== undefined) e.textContent = text;
    return e;
  }
  function pad(n) { return (n < 10 ? '0' : '') + n; }
  function dur(s) {
    s = Math.max(0, Math.floor(num(s)));
    var h = Math.floor(s / 3600), m = Math.floor(s / 60) % 60, sec = s % 60;
    return h ? h + ':' + pad(m) + ':' + pad(sec) : m + ':' + pad(sec);
  }
  function bar(cur, max, pct, color, label) {
    var b = el('div', 'bar'), f = el('div');
    pct = Math.max(0, Math.min(100, pct));
    f.style.width = pct + '%';
    f.style.background = color;
    b.appendChild(f);
    b.appendChild(el('span', null, label));
    return b;
  }

  // Navmesh per map id, fetched once: 'loading', null (no mesh / failed) or [{z, v: Float32Array x,y,..., b: [minx,miny,maxx,maxy]}] in WoW coords.
  var meshes = {}, last = null;
  function prepMesh(d) {
    var out = [];
    arr(d && d.polys).forEach(function (p) {
      p = arr(p);
      if (p.length < 7) return;
      var n = (p.length - 1) >> 1, v = new Float32Array(n * 2), b = [Infinity, Infinity, -Infinity, -Infinity], area = 0, i, j;
      for (i = 0; i < n; i++) { j = (i + 1) % n; area += num(p[1 + 2 * i]) * num(p[2 + 2 * j]) - num(p[1 + 2 * j]) * num(p[2 + 2 * i]); }
      for (i = 0; i < n; i++) {
        j = area < 0 ? n - 1 - i : i; // one winding for all, or overlapping polygons cancel out in the single nonzero fill
        v[2 * i] = num(p[1 + 2 * j]); v[2 * i + 1] = num(p[2 + 2 * j]);
        b[0] = Math.min(b[0], v[2 * i]); b[1] = Math.min(b[1], v[2 * i + 1]);
        b[2] = Math.max(b[2], v[2 * i]); b[3] = Math.max(b[3], v[2 * i + 1]);
      }
      out.push({ z: num(p[0]), v: v, b: b });
    });
    return out.length ? out : null;
  }
  function getMesh(map) {
    if (Object.prototype.hasOwnProperty.call(meshes, map)) return meshes[map] === 'loading' ? null : meshes[map];
    meshes[map] = 'loading';
    // ponytail: any failure (404, network, bad JSON) is cached as "no mesh" until the page is reloaded
    fetch('?mesh=' + map + (demo ? '&demo=1' : ''), { credentials: 'same-origin' })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (d) { meshes[map] = prepMesh(d); }, function () { meshes[map] = null; })
      .then(function () { if (meshes[map] && last) render(last); });
    return null;
  }

  function drawMap(cv, run) {
    var W = 600, H = 400, dpr = window.devicePixelRatio || 1;
    cv.width = W * dpr; cv.height = H * dpr;
    var c = cv.getContext('2d');
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
    c.clearRect(0, 0, W, H);
    var bosses = arr(run.bosses), bots = arr(run.bots), trail = arr(run.trail), route = arr(run.route);
    var mesh = getMesh(num(run.map));
    var tank = bots.filter(function (b) { return b && str(b.role) === 'tank'; })[0] || bots[0];
    // WoW: x = north, y = west. Plot px = -y (east right), py = x (north up).
    var pts = [], actors = [];
    bosses.forEach(function (b) { actors.push([num(b.x), num(b.y)]); pts.push([-num(b.y), num(b.x)]); });
    bots.forEach(function (b) { actors.push([num(b.x), num(b.y)]); pts.push([-num(b.y), num(b.x)]); });
    trail.forEach(function (p) { p = arr(p); pts.push([-num(p[1]), num(p[0])]); });
    if (!pts.length) {
      c.fillStyle = '#8a92a3'; c.font = '14px system-ui, sans-serif';
      c.fillText('no positions', 20, 30);
      return;
    }
    var minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
    pts.forEach(function (p) {
      minX = Math.min(minX, p[0]); maxX = Math.max(maxX, p[0]);
      minY = Math.min(minY, p[1]); maxY = Math.max(maxY, p[1]);
    });
    if (mesh) {
      // grow the view to the mesh around the bosses and bots (within 150 yd), not the whole map
      var R = 150, ax0 = Infinity, ay0 = Infinity, ax1 = -Infinity, ay1 = -Infinity;
      actors.forEach(function (a) { ax0 = Math.min(ax0, a[0]); ay0 = Math.min(ay0, a[1]); ax1 = Math.max(ax1, a[0]); ay1 = Math.max(ay1, a[1]); });
      mesh.forEach(function (p) {
        var b = p.b;
        if (b[2] < ax0 - R || b[0] > ax1 + R || b[3] < ay0 - R || b[1] > ay1 + R) return;
        for (var i = 0; i < p.v.length; i += 2) {
          for (var k = 0; k < actors.length; k++) {
            var dx = p.v[i] - actors[k][0], dy = p.v[i + 1] - actors[k][1];
            if (dx * dx + dy * dy < R * R) {
              minX = Math.min(minX, -b[3]); maxX = Math.max(maxX, -b[1]);
              minY = Math.min(minY, b[0]); maxY = Math.max(maxY, b[2]);
              return;
            }
          }
        }
      });
    }
    var spanX = Math.max(maxX - minX, 20), spanY = Math.max(maxY - minY, 20);
    var M = 50; // padding in px, room for labels
    var s = Math.min((W - 2 * M) / spanX, (H - 2 * M) / spanY);
    var cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
    function P(x, y) { return [W / 2 + (-y - cx) * s, H / 2 - (x - cy) * s]; } // WoW (x,y) -> canvas

    // navmesh: polygons near the tank's height (within 8 yd) = the current floor, the rest faint
    if (mesh) {
      var vx0 = cx - W / 2 / s, vx1 = cx + W / 2 / s, vy0 = cy - H / 2 / s, vy1 = cy + H / 2 / s; // view box, plot coords
      var tz = tank ? num(tank.z) : NaN;
      [false, true].forEach(function (cur) {
        c.beginPath();
        mesh.forEach(function (p) {
          var b = p.b;
          if (-b[3] > vx1 || -b[1] < vx0 || b[0] > vy1 || b[2] < vy0) return;
          if ((isNaN(tz) || Math.abs(p.z - tz) <= 8) !== cur) return;
          for (var i = 0; i < p.v.length; i += 2) {
            var q = P(p.v[i], p.v[i + 1]);
            if (i) c.lineTo(q[0], q[1]); else c.moveTo(q[0], q[1]);
          }
          c.closePath();
        });
        c.fillStyle = cur ? '#343a46' : 'rgba(120,128,145,0.13)';
        c.fill();
      });
    }

    // planned path (corridor corners), from the tank
    if (route.length) {
      c.setLineDash([6, 5]); c.strokeStyle = 'rgba(255,209,102,0.85)'; c.lineWidth = 2; c.beginPath();
      var r0 = tank ? P(num(tank.x), num(tank.y)) : null;
      if (r0) c.moveTo(r0[0], r0[1]);
      route.forEach(function (p, i) {
        p = arr(p); var q = P(num(p[0]), num(p[1]));
        if (i || r0) c.lineTo(q[0], q[1]); else c.moveTo(q[0], q[1]);
      });
      c.stroke(); c.setLineDash([]);
    }

    // north arrow + scale hint
    c.fillStyle = '#5b6270'; c.font = '11px system-ui, sans-serif';
    c.fillText('N ↑', W - 30, 16);

    // tank trail
    if (trail.length > 1) {
      c.strokeStyle = 'rgba(111,179,255,0.35)'; c.lineWidth = 2; c.beginPath();
      trail.forEach(function (p, i) {
        p = arr(p); var q = P(num(p[0]), num(p[1]));
        if (i) c.lineTo(q[0], q[1]); else c.moveTo(q[0], q[1]);
      });
      c.stroke();
    }

    c.font = '12px system-ui, sans-serif';
    c.textBaseline = 'middle';
    var labels = []; // drawn after all markers, nudged so they do not overlap
    function label(text, x, y, color, center) { labels.push({ t: text, x: x, y: y, c: color, center: center }); }
    function drawLabels() {
      var placed = [];
      labels.forEach(function (l) {
        var w = c.measureText(l.t).width, x = l.center ? l.x - w / 2 : l.x;
        x = Math.max(2, Math.min(W - w - 2, x));
        var y = l.y, ox = l.x, oy = l.y;
        // ponytail: greedy downward nudge, fine for a party of 5 + a few bosses
        for (var k = 0; k < 12 && placed.some(function (p) {
          return x < p[0] + p[2] && x + w > p[0] && Math.abs(y - p[1]) < 13;
        }); k++) y += 13;
        placed.push([x, y, w]);
        if (y !== oy) { c.strokeStyle = 'rgba(138,146,163,0.5)'; c.lineWidth = 1; c.beginPath(); c.moveTo(ox, oy); c.lineTo(x, y); c.stroke(); }
        c.textAlign = 'left';
        c.lineWidth = 3; c.strokeStyle = '#0b0d11'; c.strokeText(l.t, x, y);
        c.fillStyle = l.c; c.fillText(l.t, x, y);
      });
    }

    // bosses: diamonds
    bosses.forEach(function (b) {
      var q = P(num(b.x), num(b.y)), st = str(b.status);
      var r = st === 'current' ? 11 : 7;
      var col = st === 'killed' ? '#6b7280' : st === 'current' ? '#ff9f1c' : '#e63946';
      c.fillStyle = col; c.strokeStyle = '#000'; c.lineWidth = 1.5;
      c.beginPath(); c.moveTo(q[0], q[1] - r); c.lineTo(q[0] + r, q[1]); c.lineTo(q[0], q[1] + r); c.lineTo(q[0] - r, q[1]); c.closePath();
      c.fill(); c.stroke();
      var txt = str(b.name) + (st !== 'killed' && num(b.hp) < 100 && b.hp !== undefined ? ' ' + num(b.hp) + '%' : '');
      label(txt, q[0], q[1] - r - 9, col, true);
    });

    // bots
    var dpsIdx = 0;
    bots.forEach(function (b) {
      var q = P(num(b.x), num(b.y)), role = str(b.role), alive = b.alive !== false;
      var col = role === 'tank' ? '#3b82f6' : role === 'healer' ? '#22c55e' : DPS_COLORS[dpsIdx++ % DPS_COLORS.length];
      if (!alive) col = '#6b7280';
      if (alive && b.o !== undefined) {
        var o = num(b.o); // WoW orientation: 0 = +x (north), CCW toward +y (west)
        var dx = Math.cos(o), dy = Math.sin(o);
        var e = P(num(b.x) + dx * 12 / s, num(b.y) + dy * 12 / s);
        c.strokeStyle = col; c.lineWidth = 2; c.beginPath(); c.moveTo(q[0], q[1]); c.lineTo(e[0], e[1]); c.stroke();
      }
      c.fillStyle = col; c.strokeStyle = '#000'; c.lineWidth = 1.5;
      c.beginPath(); c.arc(q[0], q[1], 6, 0, Math.PI * 2); c.fill(); c.stroke();
      if (!alive) {
        c.strokeStyle = '#ff5c5c'; c.lineWidth = 2; c.beginPath();
        c.moveTo(q[0] - 5, q[1] - 5); c.lineTo(q[0] + 5, q[1] + 5);
        c.moveTo(q[0] + 5, q[1] - 5); c.lineTo(q[0] - 5, q[1] + 5); c.stroke();
      }
      label(str(b.name), q[0] + 9, q[1] + 1, alive ? '#d8dce4' : '#8a92a3');
    });
    drawLabels();
  }

  function renderRun(run, now) {
    var card = el('div', 'card');
    var t = el('div', 'title');
    t.appendChild(el('h2', null, str(run.name) || ('Dungeon ' + num(run.dungeon))));
    var state = str(run.state);
    t.appendChild(el('span', 'badge ' + (STATES.indexOf(state) >= 0 ? 's-' + state : 's-ended'), state || '?'));
    if (now - num(run.updated) > 10) t.appendChild(el('span', 'badge stale', 'stale ' + dur(now - num(run.updated))));
    t.appendChild(el('span', 'meta',
      'level ' + num(run.level) + ' · run #' + num(run.run) + ' · map ' + num(run.map) +
      ' · ' + dur(run.elapsed) + ' · bosses ' + num(run.killed) + '/' + num(run.total) +
      ' · wipes ' + num(run.wipes)));
    card.appendChild(t);

    var grid = el('div', 'grid');
    var cv = el('canvas');
    grid.appendChild(cv);
    drawMap(cv, run);

    var right = el('div');
    var tbl = el('table'), hr = el('tr');
    ['Bot', 'Class / spec', 'Role', 'Lvl', 'HP', 'Power', 'Target'].forEach(function (h) { hr.appendChild(el('th', null, h)); });
    tbl.appendChild(hr);
    arr(run.bots).forEach(function (b) {
      var alive = b.alive !== false, tr = el('tr', alive ? '' : 'dead');
      tr.appendChild(el('td', null, str(b.name) + (alive ? '' : ' (dead)')));
      tr.appendChild(el('td', null, (str(b['class']) + ' ' + str(b.spec)).trim()));
      tr.appendChild(el('td', 'r-' + str(b.role), str(b.role)));
      tr.appendChild(el('td', null, String(num(b.level))));
      var hp = num(b.hp), mhp = num(b.maxhp), hpPct = mhp > 0 ? Math.round(hp * 100 / mhp) : 0;
      var td = el('td');
      td.appendChild(bar(hp, mhp, hpPct, hpPct > 50 ? '#16a34a' : hpPct > 25 ? '#ca8a04' : '#dc2626', hp + ' / ' + mhp + ' (' + hpPct + '%)'));
      tr.appendChild(td);
      var pt = str(b.powerType).toLowerCase(), pw = Math.round(num(b.power));
      td = el('td');
      td.appendChild(bar(pw, 100, pw, (Object.prototype.hasOwnProperty.call(POWER, pt) ? POWER[pt] : '#a855f7'), (pt || 'power') + ' ' + pw + '%'));
      tr.appendChild(td);
      tr.appendChild(el('td', null, str(b.target) ? str(b.target) + ' (' + Math.round(num(b.targetHp)) + '%)' : '-'));
      tbl.appendChild(tr);
    });
    right.appendChild(tbl);

    var feed = el('div', 'feed');
    var ev = arr(run.events).slice(-25).reverse();
    if (!ev.length) feed.appendChild(el('div', 'meta', 'no events'));
    ev.forEach(function (e) {
      var line = el('div');
      line.appendChild(el('span', 't', str(e && e.t)));
      line.appendChild(document.createTextNode(str(e && e.text)));
      feed.appendChild(line);
    });
    right.appendChild(feed);
    grid.appendChild(right);
    card.appendChild(grid);
    return card;
  }

  var box = document.getElementById('runs'), err = document.getElementById('err'), status = document.getElementById('status');
  function render(data) {
    last = data;
    var now = num(data && data.now) || Math.floor(Date.now() / 1000);
    var runs = arr(data && data.runs);
    box.textContent = '';
    if (!runs.length) box.appendChild(el('div', 'empty', 'No dungeon runs right now'));
    runs.forEach(function (r) { if (r && typeof r === 'object') box.appendChild(renderRun(r, now)); });
    status.textContent = runs.length + ' run(s) · updated ' + new Date().toLocaleTimeString() + (demo ? ' · DEMO' : '');
  }
  function poll() {
    fetch(url, { credentials: 'same-origin', cache: 'no-store' })
      .then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
      .then(function (d) { err.textContent = ''; render(d); })
      .catch(function (e) { err.textContent = 'Fetch failed: ' + e.message + ' (retrying)'; })
      .then(function () { setTimeout(poll, 2000); });
  }
  poll();
})();
</script>
</body>
</html>
