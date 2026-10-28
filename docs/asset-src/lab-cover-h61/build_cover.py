# H61 - Original authored laboratory cover crate (Hermie production)
# Authored DIRECTLY in final Y-up delivery space (Godot +Y up, camera +Z):
#   X[-0.80,0.80], Y(height)[0,1.25], Z[-0.25,0.25] metres. No rotation step.
# H60 lesson applied: recesses are REAL visible stepped geometry. Dark panel
# faces sit at |z|=0.19 behind the proud frame plane |z|=0.25 (camera-facing),
# and the recessed grip pocket floors at |x|=0.66 sit 8 cm behind the proud
# grip ring front |x|=0.74 (run sides). Exposed dark faces are checked on the
# joined mesh AND re-verified from the real GLB bytes. Any violation raises
# -> blender exits 1 via --python-exit-code 1.
import bpy, bmesh, sys, math, struct, json

TRI_LIMIT = 1800
EPS = 1e-5
HW, H, HD = 0.80, 1.25, 0.25     # envelope half-X, height, half-Z
PANEL = 0.19                     # recessed panel floor plane (camera-facing)
FRAME = 0.25                     # proud frame plane (camera-facing)
GFLO  = 0.66                     # grip pocket floor (dark, exposed)
GRING = 0.74                     # grip ring front plane (proud)
PL, CAP = 0.09, 1.17             # plinth height / cap underside

def get_mat(name, rgb, rough, metal):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    for key in ("Emission Color", "Emission"):
        if key in bsdf.inputs:
            bsdf.inputs[key].default_value = (0.0, 0.0, 0.0, 1.0)
    if "Emission Strength" in bsdf.inputs:
        bsdf.inputs["Emission Strength"].default_value = 0.0
    return m

MAT_BODY  = get_mat("painted_body", (0.42, 0.455, 0.50), 0.55, 0.25)  # cool gray
MAT_DARK  = get_mat("recess_dark",  (0.075, 0.085, 0.10), 0.80, 0.10)
MAT_AMBER = get_mat("safety_amber", (0.85, 0.38, 0.045), 0.45, 0.0)   # non-emissive

for ob in list(bpy.data.objects):
    bpy.data.objects.remove(ob, do_unlink=True)

parts = []
def box(name, xr, yr, zr, mat):
    (x0, x1), (y0, y1), (z0, z1) = xr, yr, zr
    assert x0 < x1 and y0 < y1 and z0 < z1, f"degenerate box {name}"
    assert -HW-EPS <= x0 and x1 <= HW+EPS, f"{name} exceeds X envelope"
    assert -EPS <= y0 and y1 <= H+EPS, f"{name} exceeds height envelope"
    assert -HD-EPS <= z0 and z1 <= HD+EPS, f"{name} exceeds Z envelope"
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x = x0 if v.co.x < 0 else x1
        v.co.y = y0 if v.co.y < 0 else y1
        v.co.z = z0 if v.co.z < 0 else z1
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    me.materials.append(mat)
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    parts.append(ob)
    return ob

# --- core: beveled armored vertical corners; broad +/-Z and +/-X faces dark --
me = bpy.data.meshes.new("cover_crate")
bm = bmesh.new()
bmesh.ops.create_cube(bm, size=1.0)
for v in bm.verts:
    v.co.x *= 2*0.66; v.co.z *= 2*PANEL; v.co.y = v.co.y*H + H/2.0
vedges = [e for e in bm.edges
          if abs(e.verts[0].co.x - e.verts[1].co.x) < EPS
          and abs(e.verts[0].co.z - e.verts[1].co.z) < EPS
          and abs(abs(e.verts[0].co.x) - 0.66) < EPS
          and abs(abs(e.verts[0].co.z) - PANEL) < EPS]
assert len(vedges) == 4, f"corner edges: {len(vedges)}"
bmesh.ops.bevel(bm, geom=vedges, offset=0.06, segments=2, profile=0.5,
                affect='EDGES')
bmesh.ops.triangulate(bm, faces=bm.faces)
bm.to_mesh(me); bm.free()
me.materials.append(MAT_BODY)   # slot 0
me.materials.append(MAT_DARK)   # slot 1
for p in me.polygons:           # broad side faces dark; caps/bevels stay body
    n = p.normal
    if (abs(n.x) > 0.95 or abs(n.z) > 0.95) and abs(n.y) < 0.1:
        p.material_index = 1
core = bpy.data.objects.new("cover_crate", me)
bpy.context.collection.objects.link(core)
parts.append(core)

# --- grounded plinth + armor cap (body) ---------------------------------------
box("plinth", (-HW, HW), (0.0, PL), (-HD, HD), MAT_BODY)
box("cap",    (-HW, HW), (CAP, H), (-HD, HD), MAT_BODY)

# --- 4 armored corner columns proud to the full envelope ----------------------
for sx in (-1, 1):
    for sz in (-1, 1):
        xr = (0.66, HW) if sx > 0 else (-HW, -0.66)
        zr = (PANEL, FRAME) if sz > 0 else (-FRAME, -PANEL)
        box(f"col_{sx}_{sz}", xr, (PL, CAP), zr, MAT_BODY)

# --- center stile on +/-Z faces: splits broad panels left/right ---------------
box("stile_zp", (-0.05, 0.05), (PL, CAP), ( PANEL, FRAME), MAT_BODY)
box("stile_zn", (-0.05, 0.05), (PL, CAP), (-FRAME, -PANEL), MAT_BODY)

# --- two recessed lifting grips on +/-X (run sides) ---------------------------
# Open stepped ring in painted_body at front plane |x|=0.74; inside the ring
# the exposed dark core face at |x|=0.66 is visible 8 cm behind it.
for sx in (-1, 1):
    xr = (0.66, GRING) if sx > 0 else (-GRING, -0.66)
    box(f"grip_{sx}_lo", xr, (0.51, 0.55), (-0.16, 0.16), MAT_BODY)
    box(f"grip_{sx}_hi", xr, (0.72, 0.76), (-0.16, 0.16), MAT_BODY)
    box(f"grip_{sx}_la", xr, (0.55, 0.72), (-0.16, -0.12), MAT_BODY)
    box(f"grip_{sx}_ra", xr, (0.55, 0.72), ( 0.12, 0.16), MAT_BODY)

# --- subtle warm amber top-edge locator (non-emissive), 4 sides ---------------
for xa, xb in ((-0.62, -0.07), (0.07, 0.62)):
    box(f"amber_zp_{xa}", (xa, xb), (1.13, CAP), ( PANEL, FRAME), MAT_AMBER)
    box(f"amber_zn_{xa}", (xa, xb), (1.13, CAP), (-FRAME, -PANEL), MAT_AMBER)
box("amber_xp", (0.66, 0.685), (1.13, CAP), (-PANEL, PANEL), MAT_AMBER)
box("amber_xn", (-0.685, -0.66), (1.13, CAP), (-PANEL, PANEL), MAT_AMBER)

# --- dark inset seam band above the plinth ------------------------------------
box("seam_zp", (-0.64, 0.64), (PL, 0.13), (0.235, FRAME), MAT_DARK)
box("seam_zn", (-0.64, 0.64), (PL, 0.13), (-FRAME, -0.235), MAT_DARK)
box("seam_xp", (0.785, HW), (PL, 0.13), (-PANEL, PANEL), MAT_DARK)
box("seam_xn", (-HW, -0.785), (PL, 0.13), (-PANEL, PANEL), MAT_DARK)

# --- join into ONE mesh --------------------------------------------------------
for ob in parts:
    ob.select_set(True)
bpy.context.view_layer.objects.active = core
bpy.ops.object.join()
bpy.ops.object.select_all(action='DESELECT')
core.select_set(True)
bpy.context.view_layer.objects.active = core

me = core.data
errors = []

# == CHECK 1: transforms identity + exact envelope ==
assert core.location.length < 1e-6
assert max(abs(a) for a in core.rotation_euler) < 1e-6
assert tuple(round(s, 6) for s in core.scale) == (1.0, 1.0, 1.0)
bmin = (min(v.co.x for v in me.vertices), min(v.co.y for v in me.vertices), min(v.co.z for v in me.vertices))
bmax = (max(v.co.x for v in me.vertices), max(v.co.y for v in me.vertices), max(v.co.z for v in me.vertices))
print(f"BOUNDS min={tuple(round(c,4) for c in bmin)} max={tuple(round(c,4) for c in bmax)}")
tgt = ((-HW, HW), (0.0, H), (-HD, HD))
for i, (lo, hi) in enumerate(zip(bmin, bmax)):
    if abs(lo - tgt[i][0]) > 2e-3: errors.append(f"axis {i} min {lo:.4f} != {tgt[i][0]}")
    if abs(hi - tgt[i][1]) > 2e-3: errors.append(f"axis {i} max {hi:.4f} != {tgt[i][1]}")

# == CHECK 2: real visible stepped recess on the joined mesh (H60 lesson) ==
def open_recess(axis, sign, floor_plane, proud_plane, min_area):
    """Exposed dark floor faces at floor_plane with proud frame faces at
    proud_plane in front (different planes -> true visible step, and no solid
    surface covers the dark floor from outside)."""
    n = [0.0, 0.0, 0.0]; n[axis] = float(sign)
    dark = [p for p in me.polygons if p.material_index == 1
            and p.normal.dot(n) > 0.99
            and abs(abs(p.center[axis]) - floor_plane) < 0.004]
    proud = [p for p in me.polygons if p.normal.dot(n) > 0.99
             and abs(abs(p.center[axis]) - proud_plane) < 0.004]
    area = sum(p.area for p in dark)
    tag = f"{'+' if sign > 0 else '-'}{'XYZ'[axis]}"
    step = proud_plane - floor_plane
    print(f"RECESS {tag}: dark floor faces={len(dark)} area={area:.3f}m2 "
          f"proud frame faces={len(proud)} step={step:.3f}m")
    if len(dark) < 2 or area < min_area:
        errors.append(f"{tag}: no exposed dark recess floor")
    if len(proud) < 2:
        errors.append(f"{tag}: no proud frame ahead of recess")
    if step < 0.04:
        errors.append(f"{tag}: step too small ({step:.3f})")

for sz in (1, -1):   # camera-facing broad side panels
    open_recess(2, sz, PANEL, FRAME, 0.30)
for sx in (1, -1):   # grip pockets on run sides
    open_recess(0, sx, GFLO, GRING, 0.05)

# == CHECK 3: topology / materials ==
tris = sum(len(p.vertices) - 2 for p in me.polygons)
n_objs = len([o for o in bpy.data.objects if o.type == 'MESH'])
mats = sorted(m.name for m in me.materials)
print(f"MESH verts={len(me.vertices)} tris={tris} objects={n_objs} materials={mats}")
if tris > TRI_LIMIT: errors.append(f"tris {tris} > {TRI_LIMIT}")
if n_objs != 1: errors.append(f"{n_objs} mesh objects")
if mats != ["painted_body", "recess_dark", "safety_amber"]:
    errors.append(f"materials: {mats}")
if me.uv_layers: errors.append("unexpected UV layers")
for m in me.materials:
    b = m.node_tree.nodes.get("Principled BSDF")
    if b and b.inputs.get("Emission Strength") and b.inputs["Emission Strength"].default_value > 0:
        errors.append(f"{m.name} emissive")
top_faces = [p for p in me.polygons if p.normal.y > 0.99 and abs(p.center.y - H) < 2e-3]
top_area = sum(p.area for p in top_faces)
print(f"TOP flat area at y=1.25: {top_area:.3f} m2 ({len(top_faces)} faces)")
if top_area < 0.4: errors.append("top not flat/broad at 1.25 m")

if errors:
    print("FAIL:", *errors, sep="\n  ")
    raise SystemExit(1)
print("BLENDER_CHECKS_OK")

# == export (authored Y-up already -> export_yup=False) ==
argv = sys.argv
out_glb, out_blend = argv[argv.index("--") + 1], argv[argv.index("--") + 2]
exp_kwargs = dict(filepath=out_glb, use_selection=True,
                  export_format='GLB', export_yup=False,
                  export_cameras=False, export_lights=False,
                  export_apply=True, export_materials='EXPORT')
try:
    bpy.ops.export_scene.gltf(export_image_format='NONE', **exp_kwargs)
except TypeError:
    # no textures exist; older/newer key name fallback
    bpy.ops.export_scene.gltf(**exp_kwargs)

# == verify the REAL GLB bytes (bounds + recess from actual vertex data) ==
with open(out_glb, "rb") as f:
    data = f.read()
assert data[:4] == b"glTF" and int.from_bytes(data[4:8], "little") == 2
jlen = int.from_bytes(data[12:16], "little")
gltf = json.loads(data[20:20 + jlen])
if len(gltf["meshes"]) != 1: errors.append(f"glb meshes: {len(gltf['meshes'])}")
modes = {p.get("mode", 4) for m in gltf["meshes"] for p in m["primitives"]}
if modes != {4}: errors.append(f"non-triangle modes: {modes}")
pos_accs = [gltf["accessors"][p["attributes"]["POSITION"]]
            for m in gltf["meshes"] for p in m["primitives"]]
nverts = sum(a["count"] for a in pos_accs)

def read_positions(a):
    bv = gltf["bufferViews"][a["bufferView"]]
    # bin chunk data starts at 12 (fixed header) + 8 (JSON chunk header) +
    # jlen + 8 (bin chunk header)
    off = 12 + 8 + jlen + 8 + bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    return struct.unpack(f"<{a['count']*3}f", data[off:off + a['count']*12])

allpos = []
for a in pos_accs:
    allpos += read_positions(a)
vx, vy, vz = allpos[0::3], allpos[1::3], allpos[2::3]
gmin = (min(vx), min(vy), min(vz)); gmax = (max(vx), max(vy), max(vz))
print(f"GLB verts={nverts} min={tuple(round(c,4) for c in gmin)} max={tuple(round(c,4) for c in gmax)}")
tgt = ((-HW, 0.0, -HD), (HW, H, HD))
for i in range(3):
    if abs(gmin[i] - tgt[0][i]) > 2e-3 or abs(gmax[i] - tgt[1][i]) > 2e-3:
        errors.append(f"GLB axis {i} bounds {gmin[i]:.4f}..{gmax[i]:.4f} outside {tgt}")
# stepped-recess proof from REAL GLB vertex planes (frame vs floor coexist)
z_frame = sum(1 for z in vz if abs(abs(z) - FRAME) < 5e-3)
z_floor = sum(1 for z in vz if abs(abs(z) - PANEL) < 5e-3)
x_ring  = sum(1 for x in vx if abs(abs(x) - GRING) < 5e-3)
x_floor = sum(1 for x in vx if abs(abs(x) - GFLO) < 5e-3)
print(f"GLB recess verts: frameZ={z_frame} panelZ={z_floor} ringX={x_ring} gripFloorX={x_floor}")
if min(z_frame, z_floor, x_ring, x_floor) < 4:
    errors.append("GLB lacks stepped recess vertex planes")
if "KHR_materials_emissive_strength" in json.dumps(gltf.get("materials", [])):
    errors.append("emissive material extension present")
if errors:
    print("FAIL(glb):", *errors, sep="\n  ")
    raise SystemExit(1)
print("GLB_VERIFY_OK")

bpy.ops.wm.save_as_mainfile(filepath=out_blend)
print(f"WROTE {out_glb}")
print(f"WROTE {out_blend}")
