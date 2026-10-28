# H41 — Industrial steel floor tile for first combat room (Rend&Run)
# Reproducible Blender 4.5 procedural generator. Original locally authored
# procedural geometry, no external samples.
#
# Usage:
#   blender -b --factory-startup --python generate_h41_floor.py -- --out DIR
#
# Produces in DIR: H41_floor_tile.blend, H41_floor_tile.glb,
#                  H41_preview_sidecam.png, H41_preview_topdown.png, H41_stats.json
#
# Coordinate convention (built Blender Z-up, exported glTF Y-up for Godot):
#   Blender X = 3.0 m  -> Godot X
#   Blender Y = 3.8 m  -> Godot Z (depth); FRONT faces Blender -Y => Godot +Z
#   Blender Z = thickness: TOP at Z=0, solid body at Z -0.12..0
#   -> Godot: top at Y=0, all solid below floor. Origin center of top surface.
#   Side camera MUST sit on the -Y side (Godot +Z, real visible front).

import bpy
import json
import math
import sys
import mathutils

MAX_TRIS = 2500

def argv_after_dashes():
    args = sys.argv
    if "--" in args:
        return args[args.index("--") + 1:]
    return []

_a = argv_after_dashes()
OUT = _a[_a.index("--out") + 1] if "--out" in _a else "."

# ---------------------------------------------------------------- scene reset
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()
for block_list in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                   bpy.data.cameras, bpy.data.images):
    for b in list(block_list):
        if b.users == 0:
            block_list.remove(b)

# ---------------------------------------------------------------- materials (3)
def pbr(name, base, metallic, rough):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = rough
    return m

# Matte dark steel family (palette from lab_dressing.gd, no emission).
STEEL = pbr("M1_floor_steel", (0.045, 0.055, 0.068), 0.6, 0.85)
TREAD = pbr("M2_tread_dark", (0.028, 0.033, 0.042), 0.5, 0.95)
EDGE = pbr("M3_bright_wear", (0.24, 0.27, 0.30), 0.75, 0.6)

# ---------------------------------------------------------------- helpers
made = []

def box(name, cx, cy, cz, sx, sy, sz, mat, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    o.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(scale=True)
    if bevel > 0.0:
        md = o.modifiers.new("Bevel", 'BEVEL')
        md.width = bevel
        md.segments = 1
        md.limit_method = 'ANGLE'
        md.angle_limit = math.radians(40)
    o.data.materials.append(mat)
    made.append(o)
    return o

def cyl(name, cx, cy, cz, r, h, mat, verts=10):
    # vertical bolt head (Z axis), top flush-ish with floor surface
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h,
                                        location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat)
    made.append(o)
    return o

# ---------------------------------------------------------------- assembly
# Envelope (Blender): X -1.5..1.5, Y -1.9..1.9, Z -0.12..0 (top = play surface).

# Main slab: slightly inset on top so recessed strips sit below Y=0 plane.
slab = box("Slab", 0.0, 0.0, -0.06, 3.0, 3.8, 0.12, STEEL, bevel=0.012)

# Two broad recessed tread strips (darker, inset 8 mm below the top surface).
# Recess = thin darker plate set slightly below top; reads as shadow groove,
# not a bright stripe; solid geometry everywhere (no open grating).
box("TreadStripA", 0.0, -0.72, -0.014, 2.6, 0.55, 0.012, TREAD)
box("TreadStripB", 0.0, 0.72, -0.014, 2.6, 0.55, 0.012, TREAD)
# Groove lips: thin brighter edges framing each recess (restrained edge wear).
box("GrooveLipA_f", 0.0, -0.435, -0.012, 2.6, 0.03, 0.016, EDGE)
box("GrooveLipA_b", 0.0, -1.005, -0.012, 2.6, 0.03, 0.016, EDGE)
box("GrooveLipB_f", 0.0, 0.435, -0.012, 2.6, 0.03, 0.016, EDGE)
box("GrooveLipB_b", 0.0, 1.005, -0.012, 2.6, 0.03, 0.016, EDGE)

# Restrained edge wear: brighter chamfer strips on the two long side edges
# (visible to the side camera as a subtle thickness read).
box("EdgeWearL", -1.455, 0.0, -0.055, 0.05, 3.6, 0.11, EDGE)
box("EdgeWearR", 1.455, 0.0, -0.055, 0.05, 3.6, 0.11, EDGE)

# Bolts in the four corner pads + mid-edge pads (heads at Z=-0.004, 4 mm
# below the top plane => no trip hazard, no protrusion above Y=0).
bolt_spots = [(-1.28, -1.68), (1.28, -1.68), (-1.28, 1.68), (1.28, 1.68),
              (-1.28, 0.0), (1.28, 0.0)]
for i, (bx, by) in enumerate(bolt_spots):
    box("BoltPad%d" % i, bx, by, -0.045, 0.16, 0.16, 0.09, STEEL)
    # head spans -0.054..-0.004 (cz=-0.029, h=0.05): stays below top plane.
    cyl("Bolt%d" % i, bx, by, -0.029, 0.032, 0.05, EDGE)

# Front-edge lifting lip at -Y (Godot +Z): thin brighter band on the front
# face so the side camera reads the plate edge; stays inside envelope.
box("FrontEdgeBand", 0.0, -1.888, -0.06, 2.9, 0.024, 0.09, EDGE)

# Lead correction: cut actual recesses; embedded geometry was invisible.
bpy.context.view_layer.objects.active = slab
for md in list(slab.modifiers):
    bpy.ops.object.modifier_apply(modifier=md.name)
def recess_cut(name, cx, cy, sx, sy, bottom):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(cx,cy,(0.04+bottom)/2))
    cutter=bpy.context.object; cutter.scale=(sx,sy,0.04-bottom)
    bpy.ops.object.transform_apply(scale=True)
    bpy.context.view_layer.objects.active=slab
    md=slab.modifiers.new(name,'BOOLEAN'); md.operation='DIFFERENCE'; md.solver='EXACT'; md.object=cutter
    bpy.ops.object.modifier_apply(modifier=md.name)
    bpy.data.objects.remove(cutter,do_unlink=True)
for cy in [-0.72,0.72]:recess_cut('TreadRecess',0,cy,2.64,0.62,-0.03)
for i,(bx,by) in enumerate(bolt_spots):
    pad=bpy.data.objects.get('BoltPad%d'%i); made.remove(pad); bpy.data.objects.remove(pad,do_unlink=True)
    recess_cut('BoltPocket',bx,by,0.105,0.105,-0.06)
# Front-facing band must sit on the visible face, inside the envelope.
band=bpy.data.objects['FrontEdgeBand']
# Reduce draw calls to three material surfaces instead of 22 separate objects.
bpy.ops.object.select_all(action='DESELECT')
for o in made:o.select_set(True)
bpy.context.view_layer.objects.active=slab
bpy.ops.object.join(); slab.name='FloorTileMesh'; made=[slab]

# ---------------------------------------------------------------- hierarchy
root = bpy.data.objects.new("H41_FirstRoomFloorTile", None)
bpy.context.scene.collection.objects.link(root)
for o in made:
    o.parent = root

# ---------------------------------------------------------------- preview rig
def look_at(obj, loc, target):
    obj.location = loc
    d = mathutils.Vector(target) - mathutils.Vector(loc)
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = d.to_track_quat('-Z', 'Y')

# SIDE camera: Godot-equivalent view from +Z => Blender -Y quadrant, low eye.
# (H40 lesson: front faces -Y, camera must be on -Y side to see the FRONT.)
cam_data = bpy.data.cameras.new("SideCam")
cam_data.lens = 50.0
sidecam = bpy.data.objects.new("SideCam", cam_data)
bpy.context.scene.collection.objects.link(sidecam)
look_at(sidecam, (3.2, -5.4, 0.35), (0.0, 0.0, -0.03))

# TOP camera: straight overhead for the tread pattern thumbnail.
top_data = bpy.data.cameras.new("TopCam")
top_data.type = "ORTHO"
top_data.ortho_scale = 4.3
topcam = bpy.data.objects.new("TopCam", top_data)
bpy.context.scene.collection.objects.link(topcam)
look_at(topcam, (0.0, 0.0, 5.2), (0.0, 0.0, 0.0))

def sun(name, euler_deg, energy, tint=(1.0, 0.97, 0.92)):
    ld = bpy.data.lights.new(name, 'SUN')
    ld.energy = energy
    ld.color = tint
    lo = bpy.data.objects.new(name, ld)
    bpy.context.scene.collection.objects.link(lo)
    lo.rotation_euler = tuple(math.radians(e) for e in euler_deg)
    return lo

sun("KeySun", (55, 0, 35), 3.5)
sun("FillSun", (60, 0, -135), 0.7, (0.75, 0.85, 1.0))

world = bpy.data.worlds.get("World") or bpy.data.worlds.new("World")
bpy.context.scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.012, 0.014, 0.018, 1.0)

scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.image_settings.file_format = 'PNG'

# ---------------------------------------------------------------- stats
depsgraph = bpy.context.evaluated_depsgraph_get()
total_tris = 0
per_mat = {}
mins = [1e9] * 3
maxs = [-1e9] * 3
for o in made:
    ev = o.evaluated_get(depsgraph)
    me = ev.to_mesh()
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    total_tris += tris
    for p in me.polygons:
        mname = o.data.materials[p.material_index].name if o.data.materials else "none"
        per_mat.setdefault(mname, 0)
        per_mat[mname] += len(p.vertices) - 2
    for corner in o.bound_box:
        w = ev.matrix_world @ mathutils.Vector(corner)
        for i in range(3):
            mins[i] = min(mins[i], w[i])
            maxs[i] = max(maxs[i], w[i])

# Godot Y-up envelope: X=blender X, Y=blender Z (top Z=0 -> Y=0, solid below),
# Z=|blender Y| depth.
godot_dims = [maxs[0] - mins[0], maxs[2] - mins[2], maxs[1] - mins[1]]
stats = {
    "asset": "H41_FirstRoomFloorTile",
    "objects": len(made),
    "triangles_total": total_tris,
    "triangles_per_material": per_mat,
    "triangle_budget": MAX_TRIS,
    "bounds_blender_xyz": {"min": [round(v, 4) for v in mins],
                           "max": [round(v, 4) for v in maxs]},
    "godot_dimensions_x_y_z": [round(v, 4) for v in godot_dims],
    "godot_top_y_max": round(maxs[2], 4),
    "materials": sorted(per_mat.keys()),
    "provenance": "original locally authored procedural geometry, no external samples",
}
with open(OUT + "/H41_stats.json", "w") as f:
    json.dump(stats, f, indent=2)
print("H41_STATS " + json.dumps(stats))

# Gates: triangle budget, envelope, and the H40 lesson:
# everything must be at or below the top plane (godot Y <= 0 within epsilon),
# and the front features must face -Y (they do by construction; bounds check
# proves no geometry pokes above Z=0+eps).
fail = []
if total_tris > MAX_TRIS:
    fail.append("tris=%d" % total_tris)
if abs(godot_dims[0] - 3.0) > 0.05 or abs(godot_dims[2] - 3.8) > 0.05 or abs(godot_dims[1] - 0.12) > 0.02:
    fail.append("dims=%s" % godot_dims)
if mins[2] < -0.12 - 1e-4 or maxs[2] > 1e-4:
    fail.append("topplane_z=[%.4f,%.4f] must be [-0.12,0]" % (mins[2], maxs[2]))
if stats["objects"] == 0:
    fail.append("no_objects")
if fail:
    print("H41_FAIL " + "; ".join(fail))
    sys.exit(2)

# ---------------------------------------------------------------- export
bpy.ops.object.select_all(action='DESELECT')
for o in made:
    o.select_set(True)
root.select_set(True)
bpy.context.view_layer.objects.active = root
bpy.ops.export_scene.gltf(filepath=OUT + "/H41_floor_tile.glb",
                          export_format='GLB',
                          use_selection=True,
                          export_apply=True,
                          export_cameras=False,
                          export_lights=False,
                          export_yup=True,
                          export_materials='EXPORT')

# Renders: side first (front verification), then overhead thumbnail.
scene.camera = sidecam
scene.render.resolution_x = 1280
scene.render.resolution_y = 720
scene.render.filepath = OUT + "/H41_preview_sidecam.png"
bpy.ops.render.render(write_still=True)

scene.camera = topcam
scene.render.resolution_x = 640
scene.render.resolution_y = 810   # ~3.8:3.0 aspect of the tile
scene.render.filepath = OUT + "/H41_preview_topdown.png"
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=OUT + "/H41_floor_tile.blend")
print("H41_DONE tris=%d files=%s" % (total_tris, OUT))
