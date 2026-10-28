import bpy, math, os, json
from mathutils import Vector
OUT=os.environ['CELL_OUTPUT']
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def material(name,color,metal=0,rough=.4,emission=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if emission:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
 return m
shell=material('Ceramic_white_enamel',(.66,.69,.70),.25,.3)
dark=material('Graphite_powdercoat',(.032,.042,.052),.5,.43)
steel=material('Machined_steel',(.32,.38,.42),.85,.24)
rubber=material('Cable_rubber',(.012,.016,.021),.02,.72)
bronze=material('Safety_ochre',(.62,.29,.055),.55,.3)
light=material('Cool_diffuser',(.63,.83,1),.05,.28,3)
amber=material('Amber_status', (1,.36,.045),.05,.3,2)
def P(p):return Vector((p[0],-p[2],p[1]))
def finish(o,name,m,bevel=0):
 o.name=name;o.data.materials.append(m)
 if bevel:
  mod=o.modifiers.new('Manufactured_edge_radius','BEVEL');mod.width=bevel;mod.segments=3
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 mod=o.modifiers.new('Panel_normals','WEIGHTED_NORMAL');mod.keep_sharp=True
 bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def box(name,p,d,m,b=.015):
 bpy.ops.mesh.primitive_cube_add(size=1,location=P(p));o=bpy.context.object;o.dimensions=(d[0],d[2],d[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return finish(o,name,m,min(b,min(d)*.2))
def rod(name,a,b,r,m,verts=16):
 va,vb=P(a),P(b);delta=vb-va
 bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=delta.length,location=(va+vb)*.5);o=bpy.context.object;o.rotation_euler=delta.to_track_quat('Z','Y').to_euler()
 return finish(o,name,m,.008)
def cable(name,points,r=.018,m=rubber):
 data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.bevel_depth=r;data.bevel_resolution=2;data.resolution_u=12
 s=data.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
 for v,p in zip(s.bezier_points,points):v.co=P(p);v.handle_left_type='AUTO';v.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);data.materials.append(m)
 bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False)
 return o
def ring(name,x,y,z,r,m,minor=.045):
 bpy.ops.mesh.primitive_torus_add(major_segments=64,minor_segments=8,location=P((x,y,z)),major_radius=r,minor_radius=minor)
 o=bpy.context.object;o.data.materials.append(m);o.name=name
 for poly in o.data.polygons:poly.use_smooth=True
 return o
# One metre-true bay: 5.2 wide, 3.1 tall, 2.65 deep. Front faces Godot +Z.
# Chamfered rectangular frame, extruded profile, open centre.
def frame():
 outer=[(-2.6,.20),(-2.4,0),(2.4,0),(2.6,.20),(2.6,2.9),(2.4,3.1),(-2.4,3.1),(-2.6,2.9)]
 inner=[(-2.39,.27),(-2.27,.16),(2.27,.16),(2.39,.27),(2.39,2.79),(2.27,2.94),(-2.27,2.94),(-2.39,2.79)]
 verts=[P((x,y,z)) for z in [.035,-.20] for shape in [outer,inner] for x,y in shape];faces=[]
 for i in range(8):
  j=(i+1)%8
  faces += [(i,j,8+j,8+i),(16+i,24+i,24+j,16+j),(i,16+i,16+j,j),(8+i,8+j,24+j,24+i)]
 mesh=bpy.data.meshes.new('Window_extruded_profile');mesh.from_pydata(verts,[],faces);mesh.update()
 o=bpy.data.objects.new('Deep_chamfered_window_frame',mesh);bpy.context.collection.objects.link(o)
 bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT');finish(o,o.name,steel,.016)
frame()
box('Rear_bulkhead',(0,1.55,-2.62),(5.1,3.0,.1),dark)
box('Floor_pan',(0,.005,-1.35),(5.05,.12,2.5),dark)
for x in [-2.5,2.5]:
 box('Side_reveal',(x,1.55,-1.4),(.12,2.9,2.45),shell)
for x in [-1.8,-.9,0,.9,1.8]:
 box('Rear_service_panel',(x,1.5,-2.55),(.86,2.6,.07),shell)
 for y in [.3,2.7]:
  for dx in [-.36,.36]:rod('Captive_fastener',(x+dx,y,-2.50),(x+dx,y,-2.475),.023,steel,8)
for x in [-2.1,2.1]:
 box('Light_recess',(x,1.6,-2.48),(.20,2.3,.10),dark)
 box('Vertical_diffuser',(x,1.6,-2.40),(.055,2.12,.025),light,.006)
# Upper service gantry and panelled, broad light source.
box('Ceiling_housing',(0,2.94,-.9),(4.75,.18,1.42),dark)
for x in [-1.57,0,1.57]:box('Ceiling_diffuser',(x,2.835,-.85),(1.47,.035,1.12),light,.008)
for x in [-1.38,1.38]:
 box('Rear_linear_rail',(x,1.55,-1.95),(.14,2.7,.18),steel)
 box('Rail_inlay',(x,1.55,-1.84),(.065,2.65,.04),dark,.006)
 box('Rail_carriage',(x,1.27,-1.80),(.27,.42,.27),bronze)
 box('Carriage_face',(x,1.27,-1.64),(.18,.24,.04),dark)
 for y in [1.12,1.42]:rod('Carriage_bolt',(x,y,-1.63),(x,y,-1.60),.026,steel,8)
box('Gantry_bridge',(0,2.57,-1.95),(3.05,.19,.24),steel)
# Open horizontal calibration ring around the head, with jaw actuators.
ring('Calibration_outer_band',0,2.25,-1.45,.83,steel,.075)
ring('Calibration_lower_band',0,2.12,-1.45,.83,dark,.06)
for i in range(8):
 a=i*math.tau/8;x=.83*math.cos(a);z=-1.45+.83*math.sin(a)
 rod('Ring_spacer',(x,2.12,z),(x,2.25,z),.037,bronze,12)
for x in [-.75,.75]:
 rod('Ring_suspension',(x,2.28,-1.84),(x,2.57,-1.84),.038,steel)
box('Inspection_head',(0,2.23,-.55),(.22,.25,.16),bronze)
box('Inspection_lens',(0,2.22,-.455),(.10,.055,.04),light,.008)
# Layered platform, fixture spine and symmetrical clamps.
box('Plinth_base',(0,.12,-1.48),(1.7,.15,1.38),dark,.04)
box('Plinth_top',(0,.22,-1.48),(1.58,.055,1.30),steel)
box('Fixture_spine',(0,1.22,-1.9),(.14,1.9,.14),dark)
for y in [.66,1.31]:
 box('Fixture_yoke',(0,y,-1.82),(.76,.085,.2),steel)
 for side in [-1,1]:
  box('Padded_fixture',(side*.34,y,-1.61),(.10,.17,.23),bronze)
  box('Rubber_jaw',(side*.27,y,-1.53),(.04,.13,.16),rubber)
# Articulated service manipulators, joints, actuator sleeves and end grippers.
for side in [-1,1]:
 a=(side*1.42,.48,-1.35);b=(side*1.64,1.15,-1.3);c=(side*.85,1.47,-1.22)
 box('Manipulator_base',(a[0],.28,a[2]),(.38,.3,.4),dark)
 rod('Manipulator_upper',a,b,.105,shell,24);rod('Manipulator_lower',b,c,.072,steel,24)
 for p in [a,b,c]:rod('Pivot_hub',(p[0],p[1],p[2]-.13),(p[0],p[1],p[2]+.13),.115,dark,24);rod('Pivot_cap',(p[0],p[1],p[2]+.13),(p[0],p[1],p[2]+.15),.07,bronze,16)
 for offset in [-.065,.065]:box('Gripper_finger',(c[0]-side*.12,c[1]+offset,c[2]),(.22,.035,.06),steel,.005)
 cable('Manipulator_hose',[(side*1.42,.4,-1.52),(side*1.85,.82,-1.52),(side*1.66,1.34,-1.46),(side*.92,1.57,-1.35)])
 cable('Hanging_service_loop',[(side*.90,2.8,-1.48),(side*1.17,2.36,-1.48),(side*1.32,1.96,-1.6),(side*1.10,1.70,-1.8),(side*.95,2.47,-1.95)],.025)
# Lateral control units, sockets and restrained readouts.
for x in [-1.93,1.93]:
 box('Control_enclosure',(x,.65,-2.18),(.48,1.0,.43),dark,.04)
 box('Control_face',(x,.69,-1.948),(.40,.86,.045),steel)
 box('Control_screen',(x,.88,-1.918),(.26,.21,.012),rubber,.006)
 for row in range(3):box('Display_line',(x,.93-row*.055,-1.905),(.15 if row==1 else .21,.012,.008),light,.002)
 for dx in [-.10,.1]:rod('Status_socket',(x+dx,.50,-1.915),(x+dx,.50,-1.895),.023,amber,12)
 for y in [.31,.36,.41]:box('Vent_slot',(x,y,-1.912),(.25,.012,.012),rubber,.002)
# Consolidate by material for predictable draw calls; UVs retained/generated.
for o in list(bpy.context.scene.objects):
 if o.type=='MESH':
  bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
  if not o.data.uv_layers:
   bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
for m in [shell,dark,steel,rubber,bronze,light,amber]:
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==m]
 if not obs:continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();bpy.context.object.name='Cell_'+m.name
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/calibration_cell.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/calibration_cell.glb',export_format='GLB',export_yup=True,export_apply=True,export_animations=False)
tri=sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons)
json.dump({'triangles':tri,'mesh_objects':len(bpy.context.scene.objects),'license':'CC0-1.0','source':'Original local Blender construction; no external assets or paid generation','size_godot_m':[5.2,3.1,2.7]},open(OUT+'/build_report.json','w'),indent=2)
