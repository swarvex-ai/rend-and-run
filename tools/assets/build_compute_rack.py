from pathlib import Path
exec(Path(__file__).with_name('build_calibration_cell.py').read_text().split('# One metre-true bay:')[0])
case=material('Charcoal_anodised',(.035,.041,.049),.55,.34)
face=material('Server_satin_alloy',(.20,.235,.25),.72,.32)
led=material('Network_link_green',(.045,.58,.36),.05,.3,2.3)
# One rack, .8m wide, .9m deep, 2.7m high; floor origin and front+Z.
box('Cabinet_inner',(0,1.36,-.09),(.70,2.58,.70),case,.025)
for x in [-.375,.375]:
 box('Side_panel',(x,1.36,-.02),(.055,2.55,.83),case,.018)
 box('Front_extruded_upright',(x,1.36,.425),(.055,2.55,.075),steel,.014)
box('Base_plinth',(0,.075,0),(.81,.15,.90),dark,.025)
box('Top_cap',(0,2.66,0),(.81,.08,.90),case,.018)
# Storage drawers with hot-swap bays, handles and restrained status lights.
for y in [.31,.60]:
 box('Storage_server',(0,y,.405),(.69,.245,.08),face,.009)
 for col in range(6):
  x=-.285+col*.114
  box('Drive_carrier_recess',(x,y,.450),(.101,.18,.009),rubber,.002)
  box('Drive_pull',(x,y+.035,.464),(.080,.029,.017),steel,.004)
  box('Drive_led',(x-.028,y-.06,.461),(.009,.015,.009),led if col%3 else amber,0)
# Compute blade field. Real recessed vents (dark backing + machined bridges).
for row in range(10):
 y=.855+row*.143
 box('Compute_blade',(0,y,.405),(.69,.125,.08),face,.006)
 box('Vent_recess',(-.005,y,.448),(.44,.063,.008),rubber,.001)
 for k in range(18):box('Vent_bridge',(-.214+k*.024,y,.455),(.006,.063,.009),face,0)
 for x in [-.292,.292]:
  box('Pull_recess',(x,y,.45),(.033,.062,.014),rubber,.003)
  rod('Rack_screw',(x,y+.042,.448),(x,y+.042,.454),.009,steel,8)
 box('Status_pair',(.245,y+.018,.458),(.012,.018,.012),led,0)
 if row%3==0:box('Attention_led',(.245,y-.018,.458),(.012,.012,.012),amber,0)
# Top switch and patch panel, exposed cable loops at the cabinet shoulder.
box('Switch_face',(0,2.38,.413),(.69,.21,.075),face,.007)
for row in range(2):
 for col in range(10):
  x=-.27+col*.048;y=2.34+row*.068
  box('Network_socket',(x,y,.456),(.033,.029,.009),rubber,0)
  if col%2==0:box('Link_LED',(x+.018,y+.018,.460),(.005,.009,.006),led,0)
box('Switch_indicator',(.285,2.38,.457),(.024,.052,.012),amber,.002)
for i in range(3):
 x=-.20+i*.16
 cable('Patch_loop',[(x,2.34,.474),(x,2.29,.52),(x+.06,2.25,.55),(x+.10,2.31,.50),(x+.10,2.408,.474)],.009,rubber)
# Hinged rails and latch imply a serviceable cabinet without a glass overlay.
for y in [.28,1.36,2.46]:box('Door_hinge',(-.405,y,.32),(.035,.095,.11),steel,.006)
box('Cabinet_number_plate',(0,2.565,.457),(.24,.055,.012),dark,.004)
for x in [-.065,-.025,.025,.065]:box('Serial_stroke',(x,2.565,.465),(.01,.023,.002),steel,0)
for m in [case,face,steel,rubber,dark,led,amber]:
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==m]
 if not obs:continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();bpy.context.object.name='Rack_'+m.name
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/compute_rack.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/compute_rack.glb',export_format='GLB',export_yup=True,export_apply=True,export_animations=False)
json.dump({'triangles':sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons),'material_meshes':len(bpy.context.scene.objects),'license':'CC0-1.0','size_m':[.85,2.70,1.0],'bottom_y':0,'front':'+Z','collision':False},open(OUT+'/build_report.json','w'),indent=2)
