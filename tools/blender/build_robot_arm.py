"""Builds a six-axis industrial robot arm (welding cell) for Rend&Run and exports a GLB.

Run: blender -b -P tools/blender/build_robot_arm.py -- <out.glb> [preview.png]
Every joint is its own object whose origin sits on the joint axis, parented in chain:
ArmBase > ArmTurret (yaw, Y) > ArmLower (pitch, X at shoulder) > ArmUpper (pitch, X at elbow)
> ArmWrist (pitch) > ArmTool (roll). Godot animates these nodes directly.
Palette: white enamel shells, graphite joints, amber accents, steel tool (factory art bible).
"""
import bpy, bmesh, math, sys
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "/tmp/robot_arm.glb"
PREVIEW = argv[1] if len(argv) > 1 else ""

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

def material(name, color, metal, rough, emit=None, strength=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    if "Coat Weight" in b.inputs: b.inputs["Coat Weight"].default_value = 0.35 if metal < 0.5 else 0.0
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = strength
    return m

ENAMEL = material("Enamel", (0.80, 0.81, 0.82), 0.15, 0.22)
GRAPHITE = material("Graphite", (0.035, 0.04, 0.045), 0.6, 0.38)
STEEL = material("Steel", (0.62, 0.64, 0.66), 1.0, 0.22)
AMBER = material("Amber", (1.0, 0.45, 0.08), 0.1, 0.35, (1.0, 0.42, 0.06), 6.0)
RUBBER = material("Rubber", (0.02, 0.02, 0.022), 0.0, 0.7)

def finish(obj, mat, bevel=0.012, segments=3):
    obj.data.materials.append(mat)
    if bevel > 0:
        mod = obj.modifiers.new("Bevel", "BEVEL"); mod.width = bevel; mod.segments = segments
        mod.limit_method = "ANGLE"
    for p in obj.data.polygons: p.use_smooth = True
    return obj

def cube(name, size, loc, mat, bevel=0.015, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object; o.name = name; o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    finish(o, mat, bevel)
    if parent: _parent(o, parent)
    return o

def cyl(name, r, depth, loc, mat, axis="Y", verts=40, bevel=0.008, parent=None, r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=depth, location=loc)
    o = bpy.context.active_object; o.name = name
    if axis == "X": o.rotation_euler = (0, math.radians(90), 0)
    elif axis == "Z": o.rotation_euler = (math.radians(90), 0, 0)  # Blender Y (depth) axis
    bpy.ops.object.transform_apply(rotation=True)
    finish(o, mat, bevel)
    if parent: _parent(o, parent)
    return o

def _parent(child, parent):
    bpy.context.view_layer.update()  # matrix_world is stale until the depsgraph updates
    m = child.matrix_world.copy(); child.parent = parent; child.matrix_world = m

def pivot(name, loc, parent=None):
    o = bpy.data.objects.new(name, None); scene.collection.objects.link(o)
    o.location = loc; o.empty_display_size = 0.1
    if parent: _parent(o, parent)
    return o

# Blender Z is up; glTF export converts to Y-up. The arm reaches along -Y (towards camera = front).
base = pivot("ArmBase", (0, 0, 0))
cyl("BasePlinth", 0.36, 0.10, (0, 0, 0.05), GRAPHITE, axis="Y", parent=base)
cyl("BaseRing", 0.30, 0.10, (0, 0, 0.15), ENAMEL, axis="Y", parent=base)
for i in range(8):
    a = i * math.tau / 8
    cyl("Bolt%d" % i, 0.018, 0.03, (math.cos(a) * 0.32, math.sin(a) * 0.32, 0.11), STEEL, verts=12, parent=base)

turret = pivot("ArmTurret", (0, 0, 0.2), base)
cube("TurretBody", (0.42, 0.40, 0.30), (0, 0, 0.36), ENAMEL, 0.05, turret)
cyl("TurretMotor", 0.12, 0.20, (0.25, 0.04, 0.36), GRAPHITE, axis="X", parent=turret)
cube("TurretPlate", (0.30, 0.012, 0.12), (0, -0.206, 0.36), GRAPHITE, 0.004, turret)
cube("TurretLamp", (0.06, 0.01, 0.03), (0.09, -0.214, 0.36), AMBER, 0.0, turret)

shoulder = pivot("ArmLower", (0, 0, 0.62), turret)
cyl("ShoulderHub", 0.16, 0.46, (0, 0, 0.62), GRAPHITE, axis="X", parent=shoulder)
cyl("ShoulderCap", 0.12, 0.48, (0, 0, 0.62), STEEL, axis="X", verts=32, parent=shoulder)
cube("LowerArm", (0.26, 0.22, 0.95), (0, 0, 1.08), ENAMEL, 0.06, shoulder)
cube("LowerPanel", (0.27, 0.16, 0.55), (0, 0, 1.08), GRAPHITE, 0.01, shoulder)
cube("LowerStripe", (0.272, 0.02, 0.40), (0, -0.09, 1.08), AMBER, 0.0, shoulder)

elbow = pivot("ArmUpper", (0, 0, 1.55), shoulder)
cyl("ElbowHub", 0.13, 0.38, (0, 0, 1.55), GRAPHITE, axis="X", parent=elbow)
cyl("ElbowMotor", 0.10, 0.22, (0, 0.20, 1.55), ENAMEL, axis="Z", parent=elbow)
cube("UpperArm", (0.18, 0.80, 0.18), (0, -0.40, 1.60), ENAMEL, 0.05, elbow)
cube("UpperGroove", (0.185, 0.50, 0.03), (0, -0.40, 1.67), GRAPHITE, 0.005, elbow)

wrist = pivot("ArmWrist", (0, -0.82, 1.60), elbow)
cyl("WristHub", 0.08, 0.22, (0, -0.82, 1.60), GRAPHITE, axis="X", parent=wrist)
cyl("WristBody", 0.07, 0.16, (0, -0.94, 1.60), STEEL, axis="Z", parent=wrist)

tool = pivot("ArmTool", (0, -1.02, 1.60), wrist)
cyl("ToolFlange", 0.075, 0.03, (0, -1.03, 1.60), GRAPHITE, axis="Z", parent=tool)
cyl("TorchNeck", 0.035, 0.22, (0, -1.15, 1.56), STEEL, axis="Z", parent=tool)
cyl("TorchNozzle", 0.03, 0.12, (0, -1.29, 1.50), RUBBER, axis="Z", verts=24, parent=tool, r2=0.012)
tip = pivot("ArmTip", (0, -1.36, 1.46), tool)

# Cable bundle running along the arm: a bevelled curve parented to the lower arm.
curve = bpy.data.curves.new("CableBundle", "CURVE"); curve.dimensions = "3D"
spline = curve.splines.new("BEZIER"); pts = [(0.15, 0.12, 0.45), (0.17, 0.12, 0.95), (0.16, 0.10, 1.40), (0.10, -0.05, 1.70)]
spline.bezier_points.add(len(pts) - 1)
for bp, p in zip(spline.bezier_points, pts):
    bp.co = p; bp.handle_left_type = bp.handle_right_type = "AUTO"
curve.bevel_depth = 0.025; curve.bevel_resolution = 4
cable = bpy.data.objects.new("CableBundle", curve); scene.collection.objects.link(cable)
cable.data.materials.append(RUBBER); _parent(cable, shoulder)
bpy.context.view_layer.objects.active = cable; cable.select_set(True)
bpy.ops.object.convert(target="MESH")

# Apply modifiers so the GLB carries the bevels.
for o in list(scene.objects):
    if o.type == "MESH" and o.modifiers:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_apply=True, export_yup=True)
print("EXPORTED", OUT)

if PREVIEW:
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); scene.collection.objects.link(cam)
    cam.location = (2.4, -2.6, 1.6); cam.rotation_euler = (math.radians(72), 0, math.radians(43)); scene.camera = cam
    for loc, e in [((3, -3, 4), 900), ((-3, -1, 3), 400), ((0, 3, 3), 300)]:
        L = bpy.data.objects.new("L", bpy.data.lights.new("L", "AREA")); L.data.energy = e; L.data.size = 2
        L.location = loc; L.rotation_euler = (Vector((0, 0, 1)).rotation_difference(Vector(loc) - Vector((0, 0, 1))).to_euler())
        scene.collection.objects.link(L)
    world = bpy.data.worlds.new("w"); world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.06, 0.07, 1); scene.world = world
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
    scene.render.resolution_x = 900; scene.render.resolution_y = 900; scene.render.filepath = PREVIEW
    bpy.ops.render.render(write_still=True)
    print("PREVIEW", PREVIEW)
