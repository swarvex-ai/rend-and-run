"""Original Blender foreground service deck; extends existing floor without collision."""
import bpy,os,json,math
from pathlib import Path
exec(Path(__file__).with_name('build_calibration_cell.py').read_text().split('# One metre-true bay:')[0])
plate=material('Foreground_satin_steel',(.23,.265,.29),.78,.3)
edge=material('Brushed_fascia',(.13,.17,.19),.8,.27)
# Continue the floor toward the camera, leaving its original drains visible.
for x in [-.75,.75]:
 box('Access_plate',(x,-.032,2.40),(1.472,.064,.96),plate,.010)
 for dx in [-.63,.63]:
  for z in [2.04,2.75]:rod('Countersunk_screw',(x+dx,-.004,z),(x+dx,-.001,z),.022,dark,8)
box('Front_beveled_lip',(0,-.05,2.94),(2.98,.105,.10),edge,.012)
box('Service_cavity_back',(0,-.37,2.73),(2.98,.57,.05),dark)
box('Lower_frame',(0,-.69,2.93),(2.98,.08,.12),edge,.012)
for x in [-1.43,1.43]:
 box('Vertical_service_rib',(x,-.37,2.93),(.11,.56,.12),edge,.012)
 for y in [-.16,-.58]:rod('Fascia_bolt',(x,y,2.991),(x,y,3.009),.026,steel,8)
# Recessed amber guide behind a chamfered aperture, not a floating neon strip.
box('Light_pocket',(0,-.19,2.86),(1.65,.13,.09),dark,.008)
box('Guide_diffuser',(0,-.19,3.025),(1.48,.027,.018),amber,.004)
for y in [-.145,-.235]:box('Light_hood',(0,y,2.97),(1.66,.035,.13),edge,.008)
for x in [-1.02,1.02]:
 for y in [-.32,-.39,-.46,-.53]:box('Cooling_louver',(x,y,2.895),(.54,.025,.08),steel,.006)
box('Service_access_panel',(0,-.47,2.90),(1.08,.28,.06),edge,.016)
for x in [-.43,.43]:
 for y in [-.39,-.55]:rod('Captive_panel_screw',(x,y,2.935),(x,y,2.949),.018,dark,8)
box('Access_latch',(0,-.45,2.95),(.16,.032,.016),dark,.003)
for m in [shell,dark,steel,rubber,bronze,light,amber,plate,edge]:
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==m]
 if not obs:continue
 bpy.ops.object.select_all(action='DESELECT')
 for ob in obs:ob.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();bpy.context.object.name='Foreground_'+m.name
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/foreground_deck.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/foreground_deck.glb',export_format='GLB',export_yup=True,export_apply=True,export_animations=False)
Path(OUT+'/build_report.json').write_text(json.dumps({'license':'CC0-1.0','triangles':sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons),'width_m':3,'floor_y':0,'front_z':3.01,'collision':False},indent=2))
