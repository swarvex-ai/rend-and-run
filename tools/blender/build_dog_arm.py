"""Builds the manipulator arm on the robot dog's back for Rend&Run and exports a GLB.

Run: blender -b -P tools/blender/build_dog_arm.py -- <out.glb> [preview.png]
A compact scorpion-style arm on a back plate with a weapon rail (later dogs carry guns
there: empty "WeaponMount"). Every joint is its own object whose origin sits on the joint
axis, parented in chain: DogArmMount > DogArmTurret (yaw, Z) > DogArmShoulder (pitch, X)
> DogArmElbow (pitch, X) > DogArmClaw (pitch, X) > DogArmFingerL / DogArmFingerR (X).
At rest the arm stands straight up (Blender +Z); it reaches toward -Y, the dog's front.
Godot (enemy_dog.gd) folds and swings these nodes directly.
Palette as the dog and the factory arms: white enamel, graphite joints, amber accents.
"""
import bpy, math, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "/tmp/dog_arm.glb"
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

def finish(obj, mat, bevel=0.006, segments=3):
    obj.data.materials.append(mat)
    if bevel > 0:
        mod = obj.modifiers.new("Bevel", "BEVEL"); mod.width = bevel; mod.segments = segments
        mod.limit_method = "ANGLE"
    for p in obj.data.polygons: p.use_smooth = True
    return obj

def _parent(child, parent):
    bpy.context.view_layer.update()  # matrix_world is stale until the depsgraph updates
    m = child.matrix_world.copy(); child.parent = parent; child.matrix_world = m

def cube(name, size, loc, mat, bevel=0.006, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object; o.name = name; o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    finish(o, mat, bevel)
    if parent: _parent(o, parent)
    return o

def cyl(name, r, depth, loc, mat, axis="Z", verts=32, bevel=0.004, parent=None, r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=depth, location=loc)
    o = bpy.context.active_object; o.name = name
    if axis == "X": o.rotation_euler = (0, math.radians(90), 0)
    elif axis == "Y": o.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    finish(o, mat, bevel)
    if parent: _parent(o, parent)
    return o

def pivot(name, loc, parent=None):
    o = bpy.data.objects.new(name, None); scene.collection.objects.link(o)
    o.location = loc; o.empty_display_size = 0.05
    if parent: _parent(o, parent)
    return o

# Back plate with a ribbed weapon rail behind the arm.
mount = pivot("DogArmMount", (0, 0, 0))
cube("BackPlate", (0.24, 0.40, 0.035), (0, 0.02, 0.0175), GRAPHITE, 0.008, mount)
cube("BackShell", (0.20, 0.30, 0.02), (0, 0.04, 0.045), ENAMEL, 0.008, mount)
cube("RailBase", (0.05, 0.20, 0.022), (0, 0.13, 0.066), STEEL, 0.003, mount)
for i in range(7):
    cube("RailRib%d" % i, (0.06, 0.012, 0.012), (0, 0.04 + i * 0.03, 0.082), STEEL, 0.002, mount)
cube("RailLamp", (0.03, 0.008, 0.01), (0.07, 0.20, 0.06), AMBER, 0.0, mount)
pivot("WeaponMount", (0, 0.13, 0.09), mount)
for x in (-0.1, 0.1):
    for y in (-0.15, 0.2):
        cyl("PlateBolt", 0.009, 0.012, (x, y, 0.041), STEEL, verts=10, parent=mount)

turret = pivot("DogArmTurret", (0, -0.09, 0.035), mount)
cyl("TurretRing", 0.07, 0.03, (0, -0.09, 0.05), GRAPHITE, parent=turret)
cyl("TurretBody", 0.058, 0.06, (0, -0.09, 0.095), ENAMEL, parent=turret)
cube("TurretCheekL", (0.022, 0.07, 0.07), (-0.058, -0.09, 0.14), ENAMEL, 0.006, turret)
cube("TurretCheekR", (0.022, 0.07, 0.07), (0.058, -0.09, 0.14), ENAMEL, 0.006, turret)

shoulder = pivot("DogArmShoulder", (0, -0.09, 0.15), turret)
cyl("ShoulderHub", 0.042, 0.10, (0, -0.09, 0.15), GRAPHITE, axis="X", parent=shoulder)
cyl("ShoulderCap", 0.03, 0.135, (0, -0.09, 0.15), STEEL, axis="X", parent=shoulder)
cube("UpperArm", (0.065, 0.06, 0.34), (0, -0.09, 0.32), ENAMEL, 0.012, shoulder)
cube("UpperGroove", (0.068, 0.02, 0.22), (0, -0.12, 0.32), GRAPHITE, 0.003, shoulder)
cube("UpperStripe", (0.069, 0.006, 0.12), (0, -0.121, 0.36), AMBER, 0.0, shoulder)
cyl("UpperPiston", 0.012, 0.26, (0, -0.045, 0.31), STEEL, parent=shoulder)

elbow = pivot("DogArmElbow", (0, -0.09, 0.49), shoulder)
cyl("ElbowHub", 0.036, 0.09, (0, -0.09, 0.49), GRAPHITE, axis="X", parent=elbow)
cube("Forearm", (0.05, 0.05, 0.30), (0, -0.09, 0.64), ENAMEL, 0.01, elbow)
cube("ForearmPanel", (0.052, 0.03, 0.16), (0, -0.09, 0.64), GRAPHITE, 0.003, elbow)

claw = pivot("DogArmClaw", (0, -0.09, 0.80), elbow)
cyl("WristHub", 0.03, 0.08, (0, -0.09, 0.80), GRAPHITE, axis="X", parent=claw)
cyl("ClawPalm", 0.04, 0.05, (0, -0.09, 0.845), STEEL, parent=claw)
cube("ClawSensor", (0.02, 0.012, 0.012), (0, -0.13, 0.85), AMBER, 0.0, claw)
for side, x in (("L", -0.026), ("R", 0.026)):
    finger = pivot("DogArmFinger" + side, (x, -0.09, 0.87), claw)
    cube("Finger%sBase" % side, (0.016, 0.03, 0.08), (x, -0.09, 0.91), GRAPHITE, 0.004, finger)
    cube("Finger%sTip" % side, (0.014, 0.024, 0.05), (x * 0.6, -0.09, 0.97), STEEL, 0.004, finger)

# Cable loop from the turret along the upper arm.
curve = bpy.data.curves.new("ArmCable", "CURVE"); curve.dimensions = "3D"
spline = curve.splines.new("BEZIER"); pts = [(0.05, -0.04, 0.09), (0.06, -0.03, 0.22), (0.05, -0.05, 0.40), (0.04, -0.08, 0.50)]
spline.bezier_points.add(len(pts) - 1)
for bp, p in zip(spline.bezier_points, pts):
    bp.co = p; bp.handle_left_type = bp.handle_right_type = "AUTO"
curve.bevel_depth = 0.008; curve.bevel_resolution = 3
cable = bpy.data.objects.new("ArmCable", curve); scene.collection.objects.link(cable)
cable.data.materials.append(RUBBER); _parent(cable, shoulder)
bpy.context.view_layer.objects.active = cable; cable.select_set(True)
bpy.ops.object.convert(target="MESH")

for o in list(scene.objects):
    if o.type == "MESH" and o.modifiers:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_apply=True, export_yup=True)
print("EXPORTED", OUT)

if PREVIEW:
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); scene.collection.objects.link(cam)
    cam.location = (1.1, -1.2, 0.9); cam.rotation_euler = (math.radians(70), 0, math.radians(43)); scene.camera = cam
    for loc, e in [((2, -2, 3), 300), ((-2, -1, 2), 150), ((0, 2, 2), 120)]:
        L = bpy.data.objects.new("L", bpy.data.lights.new("L", "AREA")); L.data.energy = e; L.data.size = 1.5
        L.location = loc; L.rotation_euler = (Vector((0, 0, 1)).rotation_difference(Vector(loc) - Vector((0, 0, 0.4))).to_euler())
        scene.collection.objects.link(L)
    world = bpy.data.worlds.new("w"); world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.06, 0.07, 1); scene.world = world
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
    scene.render.resolution_x = 700; scene.render.resolution_y = 700; scene.render.filepath = PREVIEW
    bpy.ops.render.render(write_still=True)
    print("PREVIEW", PREVIEW)
