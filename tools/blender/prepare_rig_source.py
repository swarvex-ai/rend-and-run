"""Prepare a character GLB for Meshy auto-rigging.

blender --background --python tools/blender/prepare_rig_source.py -- <in.glb> <out.glb> <preview.png> [yaw_degrees]

Imports the GLB, drops armatures and animations (mesh stays in its rest pose),
rotates it by yaw_degrees about the up axis so the face points to glTF +Z,
puts the feet at the origin, exports a single textured GLB and renders a
front-view preview (camera on +Z) to check the orientation.
"""
import math
import sys

import bpy
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index("--") + 1:]
src, dst, preview = args[0], args[1], args[2]
yaw = float(args[3]) if len(args) > 3 else 0.0

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
for obj in meshes:
    for mod in list(obj.modifiers):
        if mod.type == "ARMATURE":
            obj.modifiers.remove(mod)
for obj in list(bpy.context.scene.objects):
    if obj.type == "MESH":
        world = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = world
        obj.vertex_groups.clear()
for obj in list(bpy.context.scene.objects):
    # Helper spheres are rig markers, not body geometry.
    if obj.type != "MESH" or obj.name.startswith("Icosphere"):
        bpy.data.objects.remove(obj, do_unlink=True)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
for obj in meshes:
    # Transforms cannot be applied to meshes with shape keys; Meshy ignores them anyway.
    if obj.data.shape_keys:
        bpy.context.view_layer.objects.active = obj
        obj.shape_key_clear()
# Bake every object transform into its mesh data (works for multi-user and
# shape-key meshes, where transform_apply silently does nothing), then join.
for obj in meshes:
    if obj.data.users > 1:
        obj.data = obj.data.copy()
    obj.data.transform(obj.matrix_world)
    obj.matrix_world = Matrix.Identity(4)
bpy.ops.object.select_all(action="DESELECT")
for obj in meshes:
    obj.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
body = bpy.context.view_layer.objects.active
# Blender is Z-up; glTF +Z (forward) is Blender -Y.
body.data.transform(Matrix.Rotation(math.radians(yaw), 4, "Z"))
print("PREPARED yaw=%.1f" % yaw)
xs = [v.co.x for v in body.data.vertices]; ys = [v.co.y for v in body.data.vertices]; zs = [v.co.z for v in body.data.vertices]
body.data.transform(Matrix.Translation(Vector((-(min(xs) + max(xs)) / 2, -(min(ys) + max(ys)) / 2, -min(zs)))))
body.data.update()
height = max(v.co.z for v in body.data.vertices)
print("PREPARED height=%.3f tris=%d" % (height, sum(len(p.vertices) - 2 for p in body.data.polygons)))
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_animations=False, export_skins=False)

scene = bpy.context.scene
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
scene.collection.objects.link(cam)
cam.location = (0, -4.0, height * 0.55)  # Blender -Y == glTF +Z (front)
cam.rotation_euler = (math.radians(90), 0, 0)
cam.data.lens = 50
scene.camera = cam
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
scene.collection.objects.link(sun)
sun.rotation_euler = (math.radians(60), 0, math.radians(20))
sun.data.energy = 3
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x, scene.render.resolution_y = 480, 640
scene.render.filepath = preview
bpy.ops.render.render(write_still=True)
