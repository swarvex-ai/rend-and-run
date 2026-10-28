from pathlib import Path
exec(Path(__file__).with_name('build_calibration_cell.py').read_text().split('# One metre-true bay:')[0])
box('Platform_core',(0,-.17,0),(1.97,.26,2.38),dark,.026)
for z in [-.58,.58]:box('Deck_panel',(0,-.023,z),(1.94,.046,1.13),steel,.008)
for x in [-.985,.985]:box('Deck_edge',(x,-.055,0),(.035,.11,2.4),shell,.008)
for z in [-1.19,1.19]:
 box('Structural_rail',(0,-.18,z),(2.02,.19,.10),steel,.012)
 box('Recessed_fascia',(0,-.18,z*1.025),(1.80,.12,.022),dark,.006)
 for x in [-.86,.86]:
  box('End_cap',(x,-.18,z*1.035),(.13,.15,.035),shell,.013)
  box('Safety_marker',(x,-.18,z*1.055),(.045,.09,.012),bronze,.004)
for x in [-.82,.82]:
 for z in [-1.0,0,1.0]:rod('Inset_bolt',(x,-.008,z),(x,-.001,z),.025,dark,8)
for x in [-.6,0,.6]:box('Underfloor_rib',(x,-.25,0),(.08,.14,2.25),dark,.01)
for m in [shell,dark,steel,bronze]:
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==m]
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();bpy.context.object.name='Deck_'+m.name
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/maintenance_deck.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/maintenance_deck.glb',export_format='GLB',export_yup=True,export_apply=True,export_animations=False)
json.dump({'triangles':sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons),'width':2,'depth':2.4,'top_y':0,'license':'CC0-1.0'},open(OUT+'/build_report.json','w'),indent=2)
