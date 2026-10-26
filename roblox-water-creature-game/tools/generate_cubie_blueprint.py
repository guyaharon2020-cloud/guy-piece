"""Builds src/ServerScriptService/Modules/CubieFishBlueprint.lua from the
Cubie Fish .blend, so the game can rebuild the fish out of plain Parts — no
mesh import needed.

    python tools/generate_cubie_blueprint.py -- assets/source/CubieFish_source.blend src/ServerScriptService/Modules/CubieFishBlueprint.lua

Ray-casts a grid onto each face of the cube body, reads the texture color
under every hit, clusters the colors into a small palette, and records every
non-base-color cell (stripes, eye, teeth...) as a thin "pixel" plate, merged
into rectangles. Fin sizes/positions come from the mesh vertices that stick
out past the cube. Output is in Roblox axes (X right, Y up, face toward -Z),
centered on the cube and scaled so the whole fish is 1 unit long.
"""

import sys

import bpy  # must come first: it makes mathutils importable
import numpy as np
from mathutils import Vector
from mathutils.geometry import barycentric_transform

args = sys.argv[sys.argv.index("--") + 1:]
blend_path, out_path = args[0], args[1]
DEBUG = "--debug" in args
GRID_STEP = 0.045  # texture "pixel" size in Blender units
DEPTH_TOLERANCE = 0.06

bpy.ops.wm.open_mainfile(filepath=blend_path)
obj = bpy.data.objects["Mesh_0"]
mesh = obj.data
uv_layer = mesh.uv_layers.active.data

mat = mesh.materials[0]
bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
color_img = next(l.from_node for l in mat.node_tree.links
                 if l.to_node == bsdf and l.to_socket.name == "Base Color").image
W, H = color_img.size
pixels = np.empty(W * H * 4, dtype=np.float32)
color_img.pixels.foreach_get(pixels)
pixels = pixels.reshape(H, W, 4)

verts = np.array([v.co[:] for v in mesh.vertices])


def sample(origin, direction):
    hit, loc, _normal, face_index = obj.ray_cast(Vector(origin), Vector(direction))
    if not hit:
        return None, None
    poly = mesh.polygons[face_index]
    loops = list(poly.loop_indices)[:3]
    tri = [mesh.vertices[mesh.loops[i].vertex_index].co for i in loops]
    uvs = [Vector((*uv_layer[i].uv, 0)) for i in loops]
    uv = barycentric_transform(loc, tri[0], tri[1], tri[2], uvs[0], uvs[1], uvs[2])
    px = min(W - 1, max(0, int((uv.x % 1) * W)))
    py = min(H - 1, max(0, int((uv.y % 1) * H)))
    return loc, pixels[py, px, :3]


def first_hit(origin, direction):
    loc, _ = sample(origin, direction)
    return loc


# Cube core bounds, from rays that avoid the fins/tail/mouth.
def extent(axis, sign, offsets):
    hits = []
    for a, b in offsets:
        origin = [0.0, 0.0, 0.0]
        direction = [0.0, 0.0, 0.0]
        others = [i for i in range(3) if i != axis]
        origin[others[0]], origin[others[1]] = a, b
        origin[axis] = sign * 5
        direction[axis] = -sign
        loc = first_hit(origin, direction)
        if loc:
            hits.append(loc[axis])
    return float(np.median(hits))


cy = 0.25  # body center is forward of the model center (tail is behind)
x_max = extent(0, 1, [(cy, 0.0), (cy + 0.2, 0.1), (cy - 0.2, 0.1)])
x_min = extent(0, -1, [(cy, 0.0), (cy + 0.2, 0.1), (cy - 0.2, 0.1)])
y_max = extent(1, 1, [(0.0, 0.0), (0.2, 0.1), (-0.2, 0.1)])
z_max = extent(2, 1, [(0.3, cy), (-0.3, cy + 0.2), (0.3, cy - 0.2)])
z_min = extent(2, -1, [(0.3, cy + 0.3), (-0.3, cy + 0.3), (0.3, cy + 0.1)])
y_min = extent(1, -1, [(0.3, 0.2), (-0.3, 0.2), (0.3, -0.1)])
lo = np.array([x_min, y_min, z_min])
hi = np.array([x_max, y_max, z_max])
print("CUBE lo", lo.round(3), "hi", hi.round(3))

# Each face: (axis, sign, u-axis, v-axis)
faces = [(0, 1, 1, 2), (0, -1, 1, 2), (1, 1, 0, 2), (1, -1, 0, 2), (2, 1, 0, 1), (2, -1, 0, 1)]
cells = []  # (axis, sign, u0, u1, v0, v1, rgb)
for axis, sign, ua, va in faces:
    plane = hi[axis] if sign > 0 else lo[axis]
    nu = max(1, int(round((hi[ua] - lo[ua]) / GRID_STEP)))
    nv = max(1, int(round((hi[va] - lo[va]) / GRID_STEP)))
    du, dv = (hi[ua] - lo[ua]) / nu, (hi[va] - lo[va]) / nv
    for i in range(nu):
        for j in range(nv):
            origin = [0.0, 0.0, 0.0]
            origin[ua] = lo[ua] + (i + 0.5) * du
            origin[va] = lo[va] + (j + 0.5) * dv
            origin[axis] = plane + sign * 2
            direction = [0.0, 0.0, 0.0]
            direction[axis] = -sign
            loc, rgb = sample(origin, direction)
            if loc is None or abs(loc[axis] - plane) > DEPTH_TOLERANCE:
                rgb = None  # blocked by a fin, or off the rounded edge
            cells.append((axis, sign, i, j, nu, nv, du, dv, rgb))

# Cluster colors into a small palette (k-means).
samples = np.array([c[8] for c in cells if c[8] is not None])
k = 6
rng = np.random.default_rng(1)
centers = samples[rng.choice(len(samples), k, replace=False)]
for _ in range(40):
    labels = np.argmin(((samples[:, None] - centers[None]) ** 2).sum(-1), axis=1)
    centers = np.array([samples[labels == c].mean(0) if np.any(labels == c) else centers[c] for c in range(k)])
# Merge near-identical clusters.
merged = []
for c in centers:
    if all(np.abs(c - m).sum() > 0.2 for m in merged):
        merged.append(c)
palette = np.array(merged)
counts = np.zeros(len(palette), dtype=int)
assigned = []
for cell in cells:
    if cell[8] is None:
        assigned.append(None)
        continue
    idx = int(np.argmin(((palette - cell[8]) ** 2).sum(-1)))
    counts[idx] += 1
    assigned.append(idx)
base = int(np.argmax(counts))
print("PALETTE", [(tuple((p * 255).round().astype(int)), int(n)) for p, n in zip(palette, counts)], "base", base)

# Greedy rectangle merge of non-base cells per face.
plates = []
for axis, sign, ua, va in faces:
    face_cells = [(c, a) for c, a in zip(cells, assigned) if c[0] == axis and c[1] == sign]
    nu, nv, du, dv = face_cells[0][0][4], face_cells[0][0][5], face_cells[0][0][6], face_cells[0][0][7]
    grid = np.full((nu, nv), -1)
    for c, a in face_cells:
        if a is not None and a != base:
            grid[c[2], c[3]] = a
    if DEBUG:
        print("FACE", axis, sign)
        for j in reversed(range(nv)):
            print("".join("." if grid[i, j] < 0 else str(grid[i, j]) for i in range(nu)))
    used = np.zeros_like(grid, dtype=bool)
    for j in range(nv):
        for i in range(nu):
            color = grid[i, j]
            if color < 0 or used[i, j]:
                continue
            i1 = i
            while i1 + 1 < nu and grid[i1 + 1, j] == color and not used[i1 + 1, j]:
                i1 += 1
            j1 = j
            while j1 + 1 < nv and all(grid[x, j1 + 1] == color and not used[x, j1 + 1] for x in range(i, i1 + 1)):
                j1 += 1
            used[i:i1 + 1, j:j1 + 1] = True
            center = [0.0, 0.0, 0.0]
            size = [0.0, 0.0, 0.0]
            center[ua] = lo[ua] + (i + i1 + 1) / 2 * du
            center[va] = lo[va] + (j + j1 + 1) / 2 * dv
            center[axis] = hi[axis] if sign > 0 else lo[axis]
            size[ua] = (i1 - i + 1) * du
            size[va] = (j1 - j + 1) * dv
            plates.append((center, size, axis, int(color)))
print("PLATES", len(plates))

# Fins/tail: mesh vertices sticking out past the cube.
margin = 0.02
cube_center = (lo + hi) / 2


def bounds(mask):
    pts = verts[mask]
    return pts.min(0), pts.max(0)


dorsal = bounds(verts[:, 2] > hi[2] + margin)
pec_left = bounds((verts[:, 0] < lo[0] - margin) & (verts[:, 2] < cube_center[2]))
pec_right = bounds((verts[:, 0] > hi[0] + margin) & (verts[:, 2] < cube_center[2]))
tail = bounds(verts[:, 1] < lo[1] - margin)
for name, (a, b) in [("dorsal", dorsal), ("pecL", pec_left), ("pecR", pec_right), ("tail", tail)]:
    print("FIN", name, a.round(3), b.round(3))

fin_loc, fin_rgb = sample((0.3, -0.75, cube_center[2] + 0.1), (-1, 0, 0))
fin_rgb = fin_rgb if fin_rgb is not None else palette[base]

# Blender (x, y, z) -> Roblox (x, z, -y): face (+Y) becomes -Z.
total_length = verts[:, 1].max() - verts[:, 1].min()


def to_roblox(p):
    p = (np.asarray(p) - cube_center) / total_length
    return (p[0], p[2], -p[1])


def size_to_roblox(s):
    s = np.asarray(s) / total_length
    return (s[0], s[2], s[1])


def v3(t):
    return "Vector3.new(%.4f, %.4f, %.4f)" % tuple(t)


def c3(rgb):
    r, g, b = (np.clip(np.asarray(rgb), 0, 1) * 255).round().astype(int)
    return "Color3.fromRGB(%d, %d, %d)" % (r, g, b)


normal_of = {0: "X", 1: "Z", 2: "Y"}  # Blender axis -> Roblox axis
lines = [
    "-- GENERATED by tools/generate_cubie_blueprint.py from",
    "-- assets/source/CubieFish_source.blend — don't edit by hand.",
    "-- Roblox axes (X right, Y up, face toward -Z), centered on the cube body,",
    "-- scaled so the whole fish (snout to tail tip) is 1 unit long.",
    "return {",
    "\tBodySize = %s," % v3(size_to_roblox(hi - lo)),
    "\tBaseColor = %s," % c3(palette[base]),
    "\tFinColor = %s," % c3(fin_rgb),
    "\tPalette = {",
]
lines += ["\t\t%s," % c3(p) for p in palette]
lines.append("\t},")
lines.append("\t-- { center, size (0 on the face's normal axis), normal axis, palette index }")
lines.append("\tPixels = {")
for center, size, axis, color in plates:
    lines.append('\t\t{ %s, %s, "%s", %d },' % (v3(to_roblox(center)), v3(size_to_roblox(size)), normal_of[axis], color + 1))
lines.append("\t},")
d_lo, d_hi = dorsal
lines.append("\tDorsalFin = { Center = %s, Size = %s }," % (
    v3(to_roblox((d_lo + d_hi) / 2)), v3(size_to_roblox(d_hi - d_lo))))
for name, (p_lo, p_hi) in [("LeftFin", pec_left), ("RightFin", pec_right)]:
    lines.append("\t%s = { Center = %s, Size = %s }," % (
        name, v3(to_roblox((p_lo + p_hi) / 2)), v3(size_to_roblox(p_hi - p_lo))))
t_lo, t_hi = tail
lines.append("\tTail = { Joint = %s, Size = %s }," % (
    v3(to_roblox((cube_center[0], lo[1], (t_lo[2] + t_hi[2]) / 2))), v3(size_to_roblox(t_hi - t_lo))))
lines.append("}")

with open(out_path, "w") as f:
    f.write("\n".join(lines) + "\n")
print("Wrote", out_path)
