# H59 — deterministischer Generator des Pulsraechen-Moduls (Hermie, 2026-10-07).
# Original-Hard-Surface-Zubehor, keine Koerperfigur. Achsen gem. Vertrag:
# Front +X, Oben +Y, Kamera +Z; Mount-Flache eben bei X=0, Rucksack in
# X[-0.20,0], Y[-0.25,0.25], Z[-0.18,0.18] Meter.
# Blender: blender -b -P build_pack.py
import bpy, bmesh, math, random, json

random.seed(20261007)  # Determinismus-Anker (keine Zufallsgeometrie genutzt)

OUT_GLB = "pulse_guard_pack.glb"
OUT_BLEND = "pulse_guard_pack.blend"

# --- Materialen (3, geteilt, PBR, keine Texturen) ---
def mk_mat(name, rgb, metallic, rough, emis=None, emis_strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = rough
    if emis is not None:
        bsdf.inputs["Emission Color"].default_value = (*emis, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emis_strength
    return m

MAT_TITAN = mk_mat("pack_titanium", (0.155, 0.170, 0.190), 0.85, 0.42)
MAT_CYAN = mk_mat("pack_cyan_strip", (0.0, 0.72, 0.85), 0.1, 0.3, (0.0, 0.9, 1.0), 1.2)
MAT_COPPER = mk_mat("pack_copper_latch", (0.62, 0.33, 0.16), 1.0, 0.35)

# --- Bmesh-Helfer ---
def box(name, x0, x1, y0, y1, z0, z1, mat, bevel=0.008, seg=2):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    vs = bm.verts
    for v in vs:
        v.co.x = x0 if v.co.x < 0 else x1
        v.co.y = y0 if v.co.y < 0 else y1
        v.co.z = z0 if v.co.z < 0 else z1
    if bevel > 0.0:
        bmesh.ops.bevel(bm, geom=list(bm.edges),
                        offset=bevel, segments=seg, affect='EDGES')
    to_mesh(name, bm, mat)

def cyl(name, cx, cz, r, y0, y1, mat, segs=16):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs,
                          radius1=r, radius2=r, depth=(y1 - y0))
    for v in bm.verts:  # create_cone achse = Z -> auf Y drehen
        x, y, z = v.co
        v.co = (x, z, y)
    for v in bm.verts:
        v.co.x += cx
        v.co.z += cz
        v.co.y = y0 if v.co.y < 0 else y1  # exakte Y-Grenzen
    to_mesh(name, bm, mat)

def to_mesh(name, bm, mat):
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(ob)
    return ob

# --- Szene leer ---
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()
for m in list(bpy.data.meshes):  # nur Meshes purgen; Material-Purge wirde
    if m.users == 0:             # die frischen mk_mat-Materialien loschen!
        bpy.data.meshes.remove(m)
mats_scene = bpy.context.scene.collection

# --- Geometrie (alle X <= 0) ---
# 1) Mount-Platte: ebene Montageflaeche exakt bei X=0
box("mount_plate", -0.02, 0.0, -0.20, 0.20, -0.14, 0.14, MAT_TITAN)
# 2) Rueckenplatte
box("back_plate", -0.20, -0.17, -0.24, 0.24, -0.17, 0.17, MAT_TITAN)
# 3) zwei Streben
box("strut_a", -0.17, -0.02, -0.18, -0.14, -0.02, 0.02, MAT_TITAN)
box("strut_b", -0.17, -0.02, 0.14, 0.18, -0.02, 0.02, MAT_TITAN)
# 4) zwei vertikale Kondensatorzellen
cyl("cell_a", -0.10, -0.085, 0.06, -0.18, 0.18, MAT_TITAN)
cyl("cell_b", -0.10, 0.085, 0.06, -0.18, 0.18, MAT_TITAN)
# 5) geschuetzte Top-Kappen (kupferfarben abgesetzt) + Schutzbruecke
cyl("cap_a", -0.10, -0.085, 0.035, 0.18, 0.215, MAT_COPPER, segs=12)
cyl("cap_b", -0.10, 0.085, 0.035, 0.18, 0.215, MAT_COPPER, segs=12)
box("guard_bridge", -0.135, -0.065, 0.222, 0.246, -0.145, 0.145, MAT_TITAN)
# 6) EIN schmaler cyan Streifen, von +Z lesbar (vor den Zellen)
box("cyan_strip", -0.165, -0.145, -0.19, 0.19, 0.152, 0.175, MAT_CYAN, bevel=0.004, seg=1)
# 7) kleiner Kupfer-Riegel unten an der Rueckseite
box("copper_latch", -0.19, -0.15, -0.24, -0.20, -0.05, 0.05, MAT_COPPER, bevel=0.005, seg=1)

# --- Join, Transforms anwenden, Pruefung ---
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active = bpy.data.objects["mount_plate"]
bpy.ops.object.join()
pack = bpy.context.view_layer.objects.active
pack.name = "PulseGuardPack"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

me = pack.data
tris = len(me.loop_triangles) if hasattr(me, "loop_triangles") and me.loop_triangles else None
me.calc_loop_triangles()
tris = len(me.loop_triangles)
xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]; zs = [v.co.z for v in me.vertices]
bounds = {"x": [min(xs), max(xs)], "y": [min(ys), max(ys)], "z": [min(zs), max(zs)]}

# --- Export ---
bpy.ops.object.select_all(action='DESELECT')
pack.select_set(True)
bpy.context.view_layer.objects.active = pack
bpy.ops.export_scene.gltf(filepath=OUT_GLB, export_format='GLB',
                          use_selection=True, export_apply=True,
                          export_yup=False, export_animations=False,
                          export_skins=False, export_lights=False,
                          export_materials='EXPORT', export_image_format='NONE')
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)

report = {
    "triangles": tris,
    "max_triangles": 1600,
    "materials": [m.name for m in me.materials],
    "bounds_m": bounds,
    "front_protrusion_beyond_0": max(xs) > 1e-9,
    "objects": [o.name for o in bpy.context.scene.objects],
    "lights": [o.name for o in bpy.context.scene.objects if o.type == 'LIGHT'],
    "animations": len(bpy.data.actions),
}
print("H59_REPORT " + json.dumps(report, sort_keys=True))
