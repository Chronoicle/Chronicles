#!/usr/bin/env python3
"""Convert one map's navmesh tiles (.mmtile) to a compact JSON floor plan.

Usage: mmap_to_json.py <map> [mmaps dir, default /home/wow/data/mmaps] > mesh_<map>.json
       mmap_to_json.py --selftest
Read-only. Output: {"map","tiles","bounds":[minX,minY,maxX,maxY],"polys":[[z,x1,y1,x2,y2,...],...]}
"""
import glob, json, os, struct, sys, tempfile
from collections import Counter

# src/common/collision/Maps/MapDefines.h:23 MmapTileHeader (static_assert size 20 at :37):
# uint32 mmapMagic, dtVersion, mmapVersion, size; char usesLiquids; char padding[3]
TILE_HEADER = struct.Struct('<4I c3x')
MMAP_MAGIC = 0x4d4d4150          # MapDefines.h:7 'MMAP'
MMAP_VERSION = 9                 # MapDefines.h:8
# dep/recastnavigation/Detour/Include/DetourNavMesh.h:258 dtMeshHeader: 15 int/uint + 3 floats
# (walkableHeight/Radius/Climb) + bmin[3] + bmax[3] + bvQuantFactor = 100 bytes (already 4-aligned)
MESH_HEADER = struct.Struct('<iiiiiIiiiiiiiii3f3f3ff')
DT_NAVMESH_MAGIC = ord('D') << 24 | ord('N') << 16 | ord('A') << 8 | ord('V')  # DetourNavMesh.h:84
DT_NAVMESH_VERSION = 7           # DetourNavMesh.h:87
DT_VERTS_PER_POLYGON = 6         # DetourNavMesh.h:75
# DetourNavMesh.h:164 dtPoly: unsigned int firstLink; ushort verts[6]; ushort neis[6];
# ushort flags; uchar vertCount; uchar areaAndtype = 32 bytes, no padding
POLY = struct.Struct('<I6H6HHBB')
DT_POLYTYPE_OFFMESH_CONNECTION = 1  # DetourNavMesh.h:158; type = areaAndtype >> 6
VERT = struct.Struct('<3f')


def align4(n):
    return (n + 3) & ~3


def read_tile(data):
    """Return list of polys [[wowX, wowY, wowZ], ...] or raise ValueError(reason)."""
    if len(data) < TILE_HEADER.size:
        raise ValueError('short file')
    magic, dtver, mver, size, _liquids = TILE_HEADER.unpack_from(data)
    if magic != MMAP_MAGIC:
        raise ValueError('bad mmap magic')
    if mver != MMAP_VERSION or dtver != DT_NAVMESH_VERSION:
        raise ValueError('bad mmap/dt version')
    d = data[TILE_HEADER.size:TILE_HEADER.size + size]
    if len(d) != size or size < MESH_HEADER.size:
        raise ValueError('truncated')
    h = MESH_HEADER.unpack_from(d)
    dmagic, dver, poly_count, vert_count = h[0], h[1], h[6], h[7]
    if dmagic != DT_NAVMESH_MAGIC or dver != DT_NAVMESH_VERSION:
        raise ValueError('bad DNAV magic/version')
    # section order per DetourNavMesh.cpp:930 addTile: header, verts, polys, links, ... (each dtAlign4)
    off = align4(MESH_HEADER.size)
    if off + align4(VERT.size * vert_count) + POLY.size * poly_count > len(d):
        raise ValueError('truncated')
    verts = [VERT.unpack_from(d, off + i * VERT.size) for i in range(vert_count)]
    off += align4(VERT.size * vert_count)
    polys = []
    for i in range(poly_count):
        p = POLY.unpack_from(d, off + i * POLY.size)
        idx, nverts, area_type = p[1:1 + DT_VERTS_PER_POLYGON], p[-2], p[-1]
        if area_type >> 6 == DT_POLYTYPE_OFFMESH_CONNECTION:
            continue
        # recast = (wowY, wowZ, wowX): PathGenerator.cpp:221 {startPos.y, startPos.z, startPos.x}
        polys.append([(verts[j][2], verts[j][0], verts[j][1]) for j in idx[:nverts]])
    return polys


def convert(map_id, mmaps_dir):
    # tile names: MMMMYYXX.mmtile (MapBuilder.cpp:834 "%04u%02i%02i", mapID, tileY, tileX); we take them all
    files = sorted(glob.glob(os.path.join(mmaps_dir, '%04d????.mmtile' % map_id)))
    if not files:
        return None, 'no .mmtile for map %d in %s' % (map_id, mmaps_dir)
    out, skipped, read = [], Counter(), 0
    for f in files:
        with open(f, 'rb') as fh:
            try:
                polys = read_tile(fh.read())
            except (ValueError, struct.error) as e:
                skipped[str(e)] += 1
                continue
        read += 1
        for poly in polys:
            row = [round(sum(v[2] for v in poly) / len(poly) * 2) / 2]
            for x, y, _ in poly:
                row += [round(x, 1), round(y, 1)]
            out.append(row)
    xs = [x for r in out for x in r[1::2]]
    ys = [y for r in out for y in r[2::2]]
    bounds = [min(xs), min(ys), max(xs), max(ys)] if out else []
    result = {'map': map_id, 'tiles': read, 'bounds': bounds, 'polys': out}
    summary = 'map %d: tiles read %d, skipped %d %s, polys %d, bounds %s' % (
        map_id, read, sum(skipped.values()), dict(skipped), len(out), bounds)
    return result, summary


def selftest():
    # recast verts (wowY, wowZ, wowX); 4th vert is used only by the off-mesh poly
    verts = [(10.04, 5.0, 100.0), (20.0, 6.0, 100.0), (20.0, 7.4, 110.06), (0.0, 0.0, 0.0)]
    polys = [POLY.pack(0, 0, 1, 2, 0, 0, 0, *[0] * 6, 1, 3, 63),
             POLY.pack(0, 2, 3, 0, 0, 0, 0, *[0] * 6, 1, 2, (DT_POLYTYPE_OFFMESH_CONNECTION << 6) | 63)]
    body = b''.join(VERT.pack(*v) for v in verts) + b''.join(polys)
    mesh = MESH_HEADER.pack(DT_NAVMESH_MAGIC, DT_NAVMESH_VERSION, 0, 0, 0, 0, 2, len(verts),
                            0, 0, 0, 0, 0, 1, 1, 2.0, 0.5, 1.0, 0, 0, 0, 0, 0, 0, 1.0) + body
    tile = TILE_HEADER.pack(MMAP_MAGIC, DT_NAVMESH_VERSION, MMAP_VERSION, len(mesh), b'\x01') + mesh
    with tempfile.TemporaryDirectory() as d:
        with open(os.path.join(d, '03893231.mmtile'), 'wb') as f:
            f.write(tile)
        with open(os.path.join(d, '03893232.mmtile'), 'wb') as f:
            f.write(b'XXXX' + tile[4:])  # bad magic: must be skipped, not crash
        assert convert(1, d)[0] is None
        res, summary = convert(389, d)
    # z avg = (5+6+7.4)/3 = 6.13 -> 6.0; wowX = v[2], wowY = v[0]
    assert res['polys'] == [[6.0, 100.0, 10.0, 100.0, 20.0, 110.1, 20.0]], res
    assert res['tiles'] == 1 and res['bounds'] == [100.0, 10.0, 110.1, 20.0], res
    assert 'bad mmap magic' in summary, summary
    print(summary, file=sys.stderr)
    print('selftest ok')


def main():
    if sys.argv[1:] == ['--selftest']:
        return selftest()
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    res, summary = convert(int(sys.argv[1]), sys.argv[2] if len(sys.argv) == 3 else '/home/wow/data/mmaps')
    print(summary, file=sys.stderr)
    if res is None:
        sys.exit(1)
    print(json.dumps(res, separators=(',', ':')))


if __name__ == '__main__':
    main()
