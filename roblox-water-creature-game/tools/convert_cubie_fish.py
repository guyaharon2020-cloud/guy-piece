"""Converts assets/source/CubieFish_source.blend into assets/CubieFish.fbx.

Run with the `bpy` module (pip install bpy) — no Blender install needed:

    python tools/convert_cubie_fish.py -- assets/source/CubieFish_source.blend assets

Decimates under Roblox's 20k-triangles-per-mesh import limit, splits the tail
fin into its own mesh (CubieTail) so the game can wag it, re-centers the fish
on the origin, and exports an FBX with the base-color texture (1024x1024,
Roblox's image cap) embedded.
"""

import sys

import bpy  # must come first: it makes bmesh/mathutils importable
import bmesh
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index("--") + 1:]
blend_path, out_dir = args[0], args[1]
TAIL_SPLIT_Y = -0.40  # just behind the cube body's back face
TARGET_FACES = 16000

bpy.ops.wm.open_mainfile(filepath=blend_path)
obj = bpy.data.objects["Mesh_0"]
bpy.context.view_layer.objects.active = obj
obj.select_set(True)

mod = obj.modifiers.new("Decimate", "DECIMATE")
mod.ratio = TARGET_FACES / len(obj.data.polygons)
mod.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=mod.name)

bpy.ops.object.mode_set(mode="EDIT")
bm = bmesh.from_edit_mesh(obj.data)
bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
                       plane_co=(0, TAIL_SPLIT_Y, 0), plane_no=(0, 1, 0))
for face in bm.faces:
    face.select = face.calc_center_median().y < TAIL_SPLIT_Y
bmesh.update_edit_mesh(obj.data)
bpy.ops.mesh.separate(type="SELECTED")
bpy.ops.object.mode_set(mode="OBJECT")

parts = [o for o in bpy.data.objects if o.type == "MESH"]
for o in parts:
    is_tail = max(v.co.y for v in o.data.vertices) <= TAIL_SPLIT_Y + 1e-4
    o.name = o.data.name = "CubieTail" if is_tail else "CubieBody"
    print(o.name, "triangles", len(o.data.polygons))

coords = [o.matrix_world @ v.co for o in parts for v in o.data.vertices]
lo = Vector((min(c.x for c in coords), min(c.y for c in coords), min(c.z for c in coords)))
hi = Vector((max(c.x for c in coords), max(c.y for c in coords), max(c.z for c in coords)))
for o in parts:
    o.data.transform(Matrix.Translation(-(lo + hi) / 2))
    o.location = (0, 0, 0)

# Keep only the base-color texture; Roblox's importer picks it up as the
# MeshPart texture.
mat = bpy.data.materials["Material_0"]
mat.name = "CubieFishMaterial"
nodes = mat.node_tree.nodes
bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
color_node = next(l.from_node for l in mat.node_tree.links
                  if l.to_node == bsdf and l.to_socket.name == "Base Color")
for n in list(nodes):
    if n.type in ("TEX_IMAGE", "SEPARATE_COLOR", "NORMAL_MAP") and n != color_node:
        nodes.remove(n)
img = color_node.image
img.scale(1024, 1024)
tex_path = f"{out_dir}/CubieFish_texture.png"
img.filepath_raw = tex_path
img.file_format = "PNG"
img.save()
if img.packed_file:
    img.unpack(method="REMOVE")
img.filepath = tex_path
img.name = "CubieFish_texture"

# The fish's face points Blender +Y; forward=-Z/up=Y maps that to file -Z,
# Roblox's forward (LookVector) direction.
bpy.ops.object.select_all(action="DESELECT")
for o in parts:
    o.select_set(True)
bpy.ops.export_scene.fbx(
    filepath=f"{out_dir}/CubieFish.fbx",
    use_selection=True,
    object_types={"MESH"},
    axis_forward="-Z",
    axis_up="Y",
    apply_scale_options="FBX_SCALE_ALL",
    path_mode="COPY",
    embed_textures=True,
    mesh_smooth_type="FACE",
)
print("Wrote", f"{out_dir}/CubieFish.fbx")
