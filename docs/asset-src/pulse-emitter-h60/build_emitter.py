# H60 — deterministischer Generator des Puls-Emitteur-Gehaeuses (Hermie, 07.10.).
# Original-Hard-Surface-Waffe passend zu H59. Koordinaten gem. Vertrag:
# Ursprung = Griff, Lauf vor +Y, breite Silhouette in XY, Seitenkamera +Z.
# Bounds X[-0.12,0.12], Y[-0.10,0.70], Z[-0.06,0.06] m (vor Feind-Skalierung
# 0.58). Muendung (0,0.700,0), Griffmitte nahe (0,-0.01,0).
# Aufruf: blender -b --python-exit-code 1 -P build_emitter.py
import bpy, bmesh, json

_ = 20261007  # Determinismus-Anker (keine Zufallsgeometrie)

OUT_GLB = "model.glb"
OUT_BLEND = "model.blend"

# --- Materialen zuerst, KEIN Material-Purge (H59-Lektion) ---
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

MAT_TITAN = mk_mat("body_titanium", (0.155, 0.170, 0.190), 0.85, 0.42)
MAT_DARK = mk_mat("recess_dark", (0.021, 0.024, 0.030), 0.30, 0.65)
MAT_COPPER = mk_mat("cell_copper", (0.62, 0.33, 0.16), 1.0, 0.35)
MAT_CYAN = mk_mat("charge_cyan", (0.0, 0.72, 0.85), 0.1, 0.30, (0.0, 0.9, 1.0), 1.0)

# --- Szene leer (nur Meshes/Objekte purgen) ---
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()
for m in list(bpy.data.meshes):
    if m.users == 0:
        bpy.data.meshes.remove(m)

def box(name, x0, x1, y0, y1, z0, z1, mat, bevel=0.006, seg=2):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x = x0 if v.co.x < 0 else x1
        v.co.y = y0 if v.co.y < 0 else y1
        v.co.z = z0 if v.co.z < 0 else z1
    if bevel > 0.0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=seg, affect='EDGES')
    to_mesh(name, bm, mat)

def cyl_y(name, cx, cz, r, y0, y1, mat, segs=16):
    # create_cone Achse=Z; vor dem Tausch Normalen rechnen, da der
    # (y<->z)-Austausch die Haendigkeit spiegelt (H59-Lektion).
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r, radius2=r, depth=(y1 - y0))
    for v in bm.verts:
        x, y, z = v.co
        v.co = (x + cx, z, y)          # Achse Z -> Y, Mittelpunkt Ursprung
    for v in bm.verts:                  # Mitte auf (y0+y1)/2 schieben
        v.co.y += (y0 + y1) / 2.0
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    to_mesh(name, bm, mat)

def tube_y(name, outer, inner, y0, y1, mat, segments=16):
    import math
    bm = bmesh.new()
    rings = []
    for radius, y in [(outer,y0),(outer,y1),(inner,y0),(inner,y1)]:
        rings.append([bm.verts.new((radius*math.cos(2*math.pi*i/segments),y,radius*math.sin(2*math.pi*i/segments))) for i in range(segments)])
    for i in range(segments):
        j=(i+1)%segments
        for a,b in [(0,1),(1,3),(3,2),(2,0)]:
            bm.faces.new((rings[a][i],rings[a][j],rings[b][j],rings[b][i]))
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    to_mesh(name,bm,mat)

def to_mesh(name, bm, mat):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(ob)
    return ob

# --- Geometrie: grosse Faechen, nutzbare Freiraeume ---
# Empfaenger (Receiver) — abgesetzter Titan-Kern
box("receiver", -0.060, 0.060, -0.020, 0.420, -0.052, 0.052, MAT_TITAN, bevel=0.008, seg=2)
# Lauf — reaching bis Muendung Y=0.700 (Spitze exakt 0.700)
tube_y("barrel", 0.045, 0.030, 0.300, 0.700, MAT_TITAN)
# Muendungsrand — dunner Ring-Block, um die Mulde zu rahmen
tube_y("muzzle_rim", 0.050, 0.030, 0.660, 0.700, MAT_TITAN)
# Versenkte dunkle Apertur: dunkler Kern endet 1 cm HINTER der Muendung
cyl_y("aperture", 0.0, 0.0, 0.030, 0.560, 0.670, MAT_DARK, segs=12)
# Zwei grosse, lesbare Lueschungsschlitze (je einer pro Seite, dunkel)
box("vent_left", -0.066, -0.054, 0.080, 0.260, -0.024, 0.024, MAT_DARK, bevel=0.003, seg=1)
box("vent_right", 0.054, 0.066, 0.080, 0.260, -0.024, 0.024, MAT_DARK, bevel=0.003, seg=1)
# Kupfer-Energiezelle — Rueckgrat oberhalb (+X-Seite), gross und klar
box("power_cell", 0.038, 0.088, -0.050, 0.170, -0.040, 0.040, MAT_COPPER, bevel=0.006, seg=2)
# Duennes cyan Ladungsinsert — entlang des Laufs (Lade-Animation vom Lead)
box("charge_insert", -0.012, 0.012, 0.440, 0.650, 0.043, 0.050, MAT_CYAN, bevel=0.002, seg=1)
# Griff — Mitte nahe (0,-0.01,0), bis Y=-0.10
box("grip", -0.030, 0.030, -0.100, 0.060, -0.044, 0.044, MAT_TITAN, bevel=0.007, seg=2)

# --- Join, Transforms anwenden, Messungen ---
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active = bpy.data.objects["receiver"]
bpy.ops.object.join()
prop = bpy.context.view_layer.objects.active
prop.name = "PulseEmitter"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

me = prop.data
me.calc_loop_triangles()
tris = len(me.loop_triangles)
xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]; zs = [v.co.z for v in me.vertices]
muzzle = min((v.co.y for v in me.vertices if abs(v.co.x) < 1e-6 and abs(v.co.z) < 1e-6), default=None)

bpy.ops.object.select_all(action='DESELECT')
prop.select_set(True)
bpy.context.view_layer.objects.active = prop
bpy.ops.export_scene.gltf(filepath=OUT_GLB, export_format='GLB', use_selection=True,
                          export_apply=True, export_yup=False,
                          export_animations=False, export_skins=False,
                          export_lights=False, export_materials='EXPORT',
                          export_image_format='NONE')
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)

report = {
    "triangles": tris, "max_triangles": 1800,
    "materials": sorted(m.name for m in me.materials),
    "bounds_m": {"x": [min(xs), max(xs)], "y": [min(ys), max(ys)], "z": [min(zs), max(zs)]},
    "muzzle_vertex_y": muzzle,
    "lights": [o.name for o in bpy.context.scene.objects if o.type == 'LIGHT'],
    "actions": len(bpy.data.actions),
    "objects": [o.name for o in bpy.context.scene.objects],
}
print("H60_REPORT " + json.dumps(report, sort_keys=True))
