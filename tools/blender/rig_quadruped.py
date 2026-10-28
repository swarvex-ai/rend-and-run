"""Rig and animate a Unitree-style robot dog for Godot.

blender --background --python tools/blender/rig_quadruped.py -- <in.glb> <out.glb> [preview_prefix]

Meshy only rigs bipeds. This script measures the four legs (feet = lowest points per
quadrant, knee = rearmost point of the mid band, hip = body corner), builds a skeleton
(Body, per leg thigh/calf) and binds every vertex rigidly to its nearest segment, which
suits a machine of rigid parts. It then keys procedural actions and exports them:
  idle, trot, run (diagonal-pair gaits), lunge (crouch + pounce bite),
  hit (body jolt), death (legs give way, body drops on its side).
The model's head points along Blender -Y (glTF +Z) and its feet rest at z = 0.
"""
import math
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
src, dst = args[0], args[1]
preview = args[2] if len(args) > 2 else ""
FPS = 30
LEG_COLUMN = 0.185  # |x| beyond the torso width (measured 0.17 m) belongs to a leg

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps = FPS
bpy.ops.import_scene.gltf(filepath=src)
mesh = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
mesh.data.transform(mesh.matrix_world)
mesh.matrix_world.identity()
verts = [v.co.copy() for v in mesh.data.vertices]
lo = Vector((min(v.x for v in verts), min(v.y for v in verts), min(v.z for v in verts)))
hi = Vector((max(v.x for v in verts), max(v.y for v in verts), max(v.z for v in verts)))
height = hi.z - lo.z
center = (lo + hi) / 2
underside = min(v.z for v in verts if abs(v.x - center.x) < 0.08 and abs(v.y - center.y) < 0.2)

legs = {}
for name, sx, sy in [("FL", 1, -1), ("FR", -1, -1), ("BL", 1, 1), ("BR", -1, 1)]:
    quad = [v for v in verts if (v.x - center.x) * sx > 0.02 and (v.y - center.y) * sy > 0.02]
    feet = [v for v in quad if v.z < lo.z + 0.04 * height]
    foot = sum(feet, Vector()) / len(feet)
    band = [v for v in quad if lo.z + 0.3 * height < v.z < lo.z + 0.55 * height]
    knee = max(band, key=lambda v: v.y)  # Unitree knees point backwards (+Y) on all legs
    knee = Vector((foot.x, knee.y - 0.03, knee.z))
    # Hip pivot: centre of the leg column's upper motor block.
    upper = [v for v in quad if abs(v.x - center.x) > LEG_COLUMN and v.z > underside + 0.03]
    hip = sum(upper, Vector()) / len(upper)
    hip = Vector((foot.x, hip.y, hip.z))
    legs[name] = {"hip": hip, "knee": knee, "foot": Vector((foot.x, foot.y, lo.z)), "side": sx, "end": sy}
    print("LEG", name, [round(c, 3) for c in hip], [round(c, 3) for c in knee], [round(c, 3) for c in foot])

arm_data = bpy.data.armatures.new("DogRig")
rig = bpy.data.objects.new("DogRig", arm_data)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
body = arm_data.edit_bones.new("Body")
body.head = Vector((center.x, center.y, underside + 0.08))
body.tail = Vector((center.x, center.y - 0.25, underside + 0.08))  # points to the head
for name, leg in legs.items():
    thigh = arm_data.edit_bones.new("thigh_" + name)
    thigh.head, thigh.tail, thigh.parent = leg["hip"], leg["knee"], body
    calf = arm_data.edit_bones.new("calf_" + name)
    calf.head, calf.tail, calf.parent = leg["knee"], leg["foot"], thigh
    calf.use_connect = True
    for bone in (thigh, calf):
        bone.roll = 0.0
bpy.ops.object.mode_set(mode="OBJECT")


def seg_distance(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (a + ab * t - p).length


groups = {n: mesh.vertex_groups.new(name=n) for n in ["Body"] + [f"{k}_{n}" for n in legs for k in ("thigh", "calf")]}
for i, v in enumerate(verts):
    best, best_d = "Body", None
    # Torso, head and belly plates stay rigid; everything in a leg column follows its leg.
    if abs(v.x - center.x) > LEG_COLUMN or v.z < underside - 0.05:
        for name, leg in legs.items():
            if (v.x - center.x) * leg["side"] <= 0.0 or (v.y - center.y) * leg["end"] <= 0.0:
                continue
            for part, a, b in (("thigh", leg["hip"] + Vector((0, 0, 0.15)), leg["knee"]), ("calf", leg["knee"], leg["foot"])):
                d = seg_distance(v, a, b)
                if best_d is None or d < best_d:
                    best, best_d = f"{part}_{name}", d
    groups[best].add([i], 1.0, "REPLACE")
mesh.parent = rig
mod = mesh.modifiers.new("Armature", "ARMATURE")
mod.object = rig

pose = rig.pose.bones
for pb in pose:
    pb.rotation_mode = "XYZ"


def key(frame, values):
    """values: {bone: (rx_deg, location_z, location_y, ry_deg)} applied at frame."""
    for pb in pose:
        rx, lz, ly, ry = values.get(pb.name, (0, 0, 0, 0))
        pb.rotation_euler = (math.radians(rx), math.radians(ry), 0)
        pb.location = (0, ly, lz) if pb.name == "Body" else (0, 0, 0)
        pb.keyframe_insert("rotation_euler", frame=frame)
        pb.keyframe_insert("location", frame=frame)


def make_action(name, frames, pose_at, cyclic=False):
    rig.animation_data_create()
    action = bpy.data.actions.new(name)
    rig.animation_data.action = action
    for f in range(frames + 1):
        key(f, pose_at(f / frames))
    if cyclic:
        for fc in action.fcurves if hasattr(action, "fcurves") else []:
            fc.modifiers.new("CYCLES")
    track = rig.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 0, action)
    rig.animation_data.action = None


def gait(t, swing, lift, bob):
    out = {"Body": (0, -abs(math.sin(t * 2 * math.pi)) * bob, 0, 0)}
    for name in legs:
        phase = t + (0.0 if name in ("FL", "BR") else 0.5)
        s = math.sin(phase * 2 * math.pi)
        up = max(0.0, math.sin(phase * 2 * math.pi + math.pi / 2))
        # Thigh swings fore/aft; the calf folds while the foot travels forward.
        out["thigh_" + name] = (s * swing, 0, 0, 0)
        out["calf_" + name] = (-up * lift, 0, 0, 0)
    return out


make_action("idle", 60, lambda t: {"Body": (math.sin(t * 2 * math.pi) * 1.2, math.sin(t * 2 * math.pi) * 0.008, 0, 0)}, True)
make_action("trot", 16, lambda t: gait(t, 22, 28, 0.015), True)
make_action("run", 10, lambda t: gait(t, 34, 40, 0.03), True)


def lunge(t):
    # 0-0.35 crouch (load), 0.35-0.55 pounce forward and bite, 0.55-1 recover.
    if t < 0.35:
        k = t / 0.35
        return {"Body": (-6 * k, -0.08 * k, 0, 0), **{f"thigh_{n}": (-14 * k if n[0] == "F" else 16 * k, 0, 0, 0) for n in legs},
                **{f"calf_{n}": (24 * k, 0, 0, 0) for n in legs}}
    if t < 0.55:
        k = (t - 0.35) / 0.2
        return {"Body": (-6 + 18 * k, -0.08 + 0.16 * k, -0.35 * k, 0), **{f"thigh_{n}": ((-14 + 40 * k) if n[0] == "F" else (16 - 46 * k), 0, 0, 0) for n in legs},
                **{f"calf_{n}": (24 - 30 * k, 0, 0, 0) for n in legs}}
    k = (t - 0.55) / 0.45
    return {"Body": (12 * (1 - k), 0.08 * (1 - k), -0.35 * (1 - k), 0), **{f"thigh_{n}": ((26 if n[0] == "F" else -30) * (1 - k), 0, 0, 0) for n in legs},
            **{f"calf_{n}": (-6 * (1 - k), 0, 0, 0) for n in legs}}


make_action("lunge", 21, lunge)
make_action("hit", 12, lambda t: {"Body": (8 * math.sin(t * math.pi) , -0.04 * math.sin(t * math.pi), 0.06 * math.sin(t * math.pi), 10 * math.sin(t * 2 * math.pi) * (1 - t)),
                                  **{f"calf_{n}": (14 * math.sin(t * math.pi), 0, 0, 0) for n in legs}})


def death(t):
    k = min(1.0, t / 0.6)
    e = k * k
    return {"Body": (10 * e, -(underside - 0.12) * e, 0, 78 * min(1.0, max(0.0, (t - 0.2) / 0.6))),
            **{f"thigh_{n}": ((30 if n[0] == "F" else -35) * e, 0, 0, 0) for n in legs},
            **{f"calf_{n}": (-55 * e, 0, 0, 0) for n in legs}}


make_action("death", 36, death)

bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
rig.select_set(True)
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", use_selection=True, export_animations=True,
                          export_animation_mode="NLA_TRACKS", export_force_sampling=True)
print("RIGGED", dst, "bones", len(arm_data.bones), "groups", {g.name: 0 for g in mesh.vertex_groups})

if preview:
    scene = bpy.context.scene
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 1.6
    cam.location = (2.5, center.y, 0.4)
    cam.rotation_euler = (math.radians(90), 0, math.radians(90))
    scene.camera = cam
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    scene.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(50), 0, math.radians(60))
    sun.data.energy = 4
    world = bpy.data.worlds.new("w")
    world.color = (0.25, 0.27, 0.3)
    scene.world = world
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = scene.render.resolution_y = 320
    for track in rig.animation_data.nla_tracks:
        track.mute = True
    for track in rig.animation_data.nla_tracks:
        track.mute = False
        strip = track.strips[0]
        for i, frac in enumerate((0.0, 0.25, 0.5, 0.75)):
            scene.frame_set(int(strip.frame_start + frac * (strip.frame_end - strip.frame_start)))
            scene.render.filepath = f"{preview}_{track.name}_{i}.png"
            bpy.ops.render.render(write_still=True)
        track.mute = True
