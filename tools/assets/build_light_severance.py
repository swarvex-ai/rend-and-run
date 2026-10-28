"""Local repair of the accepted Meshy rig; no provider jobs or source overwrite.
Split only the left shoulder/arm skin region at a plane. Preserve source UVs,
weights and all rest bones. Close the joint with an authored mechanical socket;
never interpret glTF UV/normal splits as thousands of holes to cap.
"""
import bpy, bmesh, os, json, hashlib, math
from pathlib import Path
from collections import Counter
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'game/assets3d/characters/light_humanoid_v1/model.glb'
OUT=Path(os.environ['ARM_OUTPUT']);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SRC))
source=bpy.data.objects['char1']; rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
rest={b.name:list(sum((list(row) for row in b.matrix_local),[])) for b in rig.data.bones}
world=source.matrix_world.copy(); names={g.index:g.name for g in source.vertex_groups}
regions={'LeftShoulder','LeftArm','LeftForeArm','LeftHand'}
transform=world.inverted()@rig.matrix_world
point=transform@rig.data.bones['LeftArm'].head_local
# Lateral joint plane avoids the downward arm axis cutting through chest armour.
normal=Vector((1,0,0))
point+=normal*2.0 # two centimetres distal to shoulder pivot, inside upper-arm shell
bm=bmesh.new();bm.from_mesh(source.data)
region=bm.faces.layers.int.new('left_region'); deform=bm.verts.layers.deform.active
for f in bm.faces:
 c=Counter()
 for v in f.verts:
  for i,w in v[deform].items():c[names[i]]+=w
 f[region]=int(bool(c) and c.most_common(1)[0][0] in regions)
region_faces=[f for f in bm.faces if f[region]]
region_edges={e for f in region_faces for e in f.edges}
region_verts={v for f in region_faces for v in f.verts}
bmesh.ops.bisect_plane(bm,geom=list(region_verts)+list(region_edges)+region_faces,dist=1e-5,plane_co=point,plane_no=normal)
# Only left-region intersections form the physical shoulder joint.
cutpoints=[v.co.copy() for v in bm.verts if abs((v.co-point).dot(normal))<.0001 and any(f[region] for f in v.link_faces)]
assert len(cutpoints)>8
u=normal.cross(Vector((0,0,1))).normalized();v=normal.cross(u).normalized()
# Convex mechanical plate covers the irregular original shell aperture. Source
# geometry remains untouched except the cut; inset plate is a separate skinned mesh.
coords=sorted(set((round((p-point).dot(u),5),round((p-point).dot(v),5)) for p in cutpoints))
def cross(o,a,b):return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
lo=[];hi=[]
for p in coords:
 while len(lo)>=2 and cross(lo[-2],lo[-1],p)<=0:lo.pop()
 lo.append(p)
for p in reversed(coords):
 while len(hi)>=2 and cross(hi[-2],hi[-1],p)<=0:hi.pop()
 hi.append(p)
hull=lo[:-1]+hi[:-1]
center=point+u*(sum(p[0] for p in hull)/len(hull))+v*(sum(p[1] for p in hull)/len(hull))
def skin_object(name,mesh):
 ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob)
 for g in source.vertex_groups:ob.vertex_groups.new(name=g.name)
 ob.parent=rig;ob.matrix_world=world
 mod=ob.modifiers.new('Armature','ARMATURE');mod.object=rig
 return ob
parts=[]
for name,want_arm in [('char1',False),('arm_left_severable',True)]:
 copy=bm.copy();layer=copy.faces.layers.int['left_region']
 remove=[f for f in copy.faces if bool(f[layer] and (f.calc_center_median()-point).dot(normal)>.00001)!=want_arm]
 bmesh.ops.delete(copy,geom=remove,context='FACES')
 bmesh.ops.delete(copy,geom=[q for q in copy.verts if not q.link_faces],context='VERTS')
 mesh=bpy.data.meshes.new(name);copy.to_mesh(mesh);copy.free()
 ob=skin_object(name,mesh);mesh.materials.append(source.data.materials[0]);parts.append(ob)
bm.free()
def material(name,color,metal,rough):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes['Principled BSDF']
 p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 return m
steel=material('joint_brushed_steel',(.17,.19,.21),.8,.34)
dark=material('joint_recess',(.025,.033,.037),.65,.44)
copper=material('joint_copper_contacts',(.31,.13,.035),.8,.32)
def cap(name,bone,side):
 verts=[];faces=[];mats=[];n=len(hull)
 # sleeve extends into its own side; lip and recessed central connector face.
 for scale,depth in [(1.006,side*1.0),(1.006,0),(.82,0),(.82,side*.55)]:
  for x,y in hull:
   p=point+u*x+v*y;p=center+(p-center)*scale+normal*depth;verts.append(p)
 for row in range(3):
  for i in range(n):faces.append((row*n+i,row*n+(i+1)%n,(row+1)*n+(i+1)%n,(row+1)*n+i));mats.append(0 if row<2 else 1)
 verts.append(center+normal*side*.55);ci=len(verts)-1
 for i in range(n):faces.append((3*n+i,3*n+(i+1)%n,ci));mats.append(1)
 # Small copper terminal ring, integral geometry with no floating wires.
 start=len(verts)
 for radius in [1.15,.68]:
  for i in range(16):verts.append(center+normal*side*.50+(u*math.cos(i*math.tau/16)+v*math.sin(i*math.tau/16))*radius)
 for i in range(16):faces.append((start+i,start+(i+1)%16,start+16+(i+1)%16,start+16+i));mats.append(2)
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
 uv=mesh.uv_layers.new(name='JointUV')
 for loop in mesh.loops:
  offset=mesh.vertices[loop.vertex_index].co-center
  uv.data[loop.index].uv=(.5+offset.dot(u)/40,.5+offset.dot(v)/40)
 ob=skin_object(name,mesh)
 for m in [steel,dark,copper]:mesh.materials.append(m)
 for p,mi in zip(mesh.polygons,mats):p.material_index=mi
 ob.vertex_groups[bone].add(list(range(len(verts))),1,'REPLACE')
 # Recalculate normals without changing source UV seams or weights.
 b=bmesh.new();b.from_mesh(mesh);bmesh.ops.recalc_face_normals(b,faces=list(b.faces));b.to_mesh(mesh);b.free()
 return ob
stump=cap('cap_shoulder_left','LeftShoulder',-1)
armcap=cap('arm_joint_inner','LeftArm',1)
# Join the arm-side socket into arm_left_severable so one visibility switch suffices.
bpy.ops.object.select_all(action='DESELECT');parts[1].select_set(True);armcap.select_set(True);bpy.context.view_layer.objects.active=parts[1];bpy.ops.object.join()
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT');socket=rig.data.edit_bones.new('sev_arm_left');socket.head=transform.inverted()@center;socket.tail=socket.head+transform.inverted().to_3x3()@normal*5;socket.parent=rig.data.edit_bones['LeftShoulder'];socket.use_deform=False;bpy.ops.object.mode_set(mode='OBJECT')
assert all(max(abs(a-b) for a,b in zip(rest[n],sum((list(row) for row in rig.data.bones[n].matrix_local),[])))<1e-5 for n in rest)
# Static model vertices are baked to metres relative to the shoulder socket.
static=bpy.data.objects.new('severed_robot_arm',parts[1].data.copy());bpy.context.collection.objects.link(static)
for vert in static.data.vertices:vert.co=world.to_3x3()@(vert.co-center)
source.name='source_reference';parts[0].name='char1'
bpy.ops.object.select_all(action='DESELECT')
for ob in [rig,*parts,stump]:ob.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(OUT/'model.glb'),use_selection=True,export_format='GLB',export_animations=True,export_yup=True,export_tangents=True,export_skins=True)
bpy.ops.object.select_all(action='DESELECT');static.select_set(True);bpy.context.view_layer.objects.active=static
bpy.ops.export_scene.gltf(filepath=str(OUT/'severed_arm.glb'),use_selection=True,export_format='GLB',export_animations=False,export_yup=True,export_tangents=True,export_skins=False)
report={'source_sha256':hashlib.sha256(SRC.read_bytes()).hexdigest(),'original_bones_preserved':list(rest),'socket':list(center),'socket_world_blender':list(world@center),'cut_hull_points':len(hull),'cut_intersections':len(cutpoints),'original_source_triangles':len(source.data.polygons),'parts':{ob.name:{'triangles':sum(len(p.vertices)-2 for p in ob.data.polygons),'uv_layers':len(ob.data.uv_layers),'materials':[m.name for m in ob.data.materials]} for ob in [*parts,stump]},'static_dimensions_m':list(static.dimensions),'credits':0}
(OUT/'build-report.json').write_text(json.dumps(report,indent=2)+'\n')
# Authoring source retains the original mesh hidden for reproducible comparison.
source.hide_render=True;source.hide_viewport=True;static.hide_render=True;static.hide_viewport=True
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'light_severance.blend'))
print('SEVERANCE_BUILD',json.dumps(report))
