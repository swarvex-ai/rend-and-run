"""Builds a wall-mounted security camera for Rend&Run and exports a GLB.

Run: blender -b -P tools/blender/build_security_camera.py -- <out.glb> [preview.png]
Nodes: CamMount (wall bracket) > CamPan (yaw about Y) > CamTilt (pitch about X) > CamLens.
The lens looks along -Y in Blender (glTF: +Z towards the room after export? no: Blender -Y
becomes glTF +Z). Godot turns CamPan/CamTilt to follow Rend; CamLed glows red when it sees him.
"""
import bpy, math, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "/tmp/security_camera.glb"
PREVIEW = argv[1] if len(argv) > 1 else ""
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

def material(name, color, metal, rough, emit=None, strength=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1); b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1); b.inputs["Emission Strength"].default_value = strength
    return m
ENAMEL = material("Enamel", (0.82, 0.83, 0.84), 0.1, 0.25)
GRAPHITE = material("Graphite", (0.03, 0.035, 0.04), 0.6, 0.35)
GLASS = material("Lens", (0.01, 0.015, 0.03), 0.0, 0.05)
LED = material("CamLed", (1.0, 0.08, 0.05), 0.0, 0.3, (1.0, 0.06, 0.03), 4.0)

def finish(o, mat, bevel):
    o.data.materials.append(mat)
    if bevel:
        m = o.modifiers.new("Bevel", "BEVEL"); m.width = bevel; m.segments = 3; m.limit_method = "ANGLE"
    for p in o.data.polygons: p.use_smooth = True
    return o
def par(c, p):
    bpy.context.view_layer.update()  # matrix_world is stale until the depsgraph updates
    m = c.matrix_world.copy(); c.parent = p; c.matrix_world = m
def cube(n, s, l, mat, b, p):
    bpy.ops.mesh.primitive_cube_add(size=1, location=l); o = bpy.context.active_object; o.name = n; o.scale = s
    bpy.ops.object.transform_apply(scale=True); finish(o, mat, b); par(o, p); return o
def cyl(n, r, d, l, mat, b, p, axis="Y", r2=None):
    if r2 is None: bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=r, depth=d, location=l)
    else: bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=r, radius2=r2, depth=d, location=l)
    o = bpy.context.active_object; o.name = n
    if axis == "Y": o.rotation_euler = (math.radians(90), 0, 0)
    elif axis == "X": o.rotation_euler = (0, math.radians(90), 0)
    bpy.ops.object.transform_apply(rotation=True); finish(o, mat, b); par(o, p); return o
def pivot(n, l, p=None):
    o = bpy.data.objects.new(n, None); scene.collection.objects.link(o); o.location = l
    if p: par(o, p)
    return o

mount = pivot("CamMount", (0, 0, 0))
cube("WallPlate", (0.16, 0.03, 0.22), (0, 0.0, 0), GRAPHITE, 0.01, mount)
cube("Arm", (0.05, 0.22, 0.05), (0, -0.12, 0.0), ENAMEL, 0.012, mount)
pan = pivot("CamPan", (0, -0.24, 0.0), mount)
cyl("PanJoint", 0.04, 0.08, (0, -0.24, -0.02), GRAPHITE, 0.006, pan, axis="Z")
tilt = pivot("CamTilt", (0, -0.24, -0.07), pan)
cube("Housing", (0.11, 0.26, 0.11), (0, -0.30, -0.08), ENAMEL, 0.03, tilt)
cube("Visor", (0.13, 0.20, 0.02), (0, -0.33, -0.015), GRAPHITE, 0.006, tilt)
cyl("LensBarrel", 0.045, 0.05, (0, -0.445, -0.08), GRAPHITE, 0.004, tilt)
lens = cyl("CamLens", 0.035, 0.012, (0, -0.473, -0.08), GLASS, 0.0, tilt)
cyl("CamLed", 0.009, 0.01, (0.04, -0.432, -0.035), LED, 0.0, tilt)
for o in list(scene.objects):
    if o.type == "MESH" and o.modifiers:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_apply=True, export_yup=True)
print("EXPORTED", OUT)
if PREVIEW:
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); scene.collection.objects.link(cam)
    cam.location = (0.6, -1.1, 0.2); cam.rotation_euler = (math.radians(84), 0, math.radians(28)); scene.camera = cam
    for loc, e in [((1, -2, 2), 150), ((-1, -1, 1), 60)]:
        L = bpy.data.objects.new("L", bpy.data.lights.new("L", "AREA")); L.data.energy = e; L.location = loc
        L.rotation_euler = Vector((0, 0, 1)).rotation_difference(-Vector(loc)).to_euler(); scene.collection.objects.link(L)
    world = bpy.data.worlds.new("w"); world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.06, 0.07, 1); scene.world = world
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
    scene.render.resolution_x = 600; scene.render.resolution_y = 600; scene.render.filepath = PREVIEW
    bpy.ops.render.render(write_still=True); print("PREVIEW", PREVIEW)
