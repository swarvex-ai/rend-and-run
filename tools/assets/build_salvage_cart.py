from pathlib import Path
exec(Path(__file__).with_name('build_calibration_cell.py').read_text().split('# One metre-true bay:')[0])
enamel=material('Pearl_enamel',(.48,.50,.505),.18,.32)
alloy=material('Satin_stainless',(.38,.41,.43),.8,.26)
# Mobile parts tray. Metres, front +Z, wheels on Y0, tray topY.82.
for x in [-.37,.37]:
 for z in [-.21,.21]:
  rod('Rubber_caster',(x,.055,z-.022),(x,.055,z+.022),.055,rubber,20)
  rod('Caster_hub',(x,.055,z-.025),(x,.055,z+.025),.025,alloy,12)
  for dz in [-.034,.034]:box('Caster_fork',(x,.094,z+dz),(.065,.085,.018),alloy,.006)
  box('Square_tube_leg',(x,.46,z),(.038,.65,.038),alloy,.005)
for y in [.235,.785]:
 box('Tray_folded_pan',(0,y,0),(.95,.035,.58),alloy,.012)
 box('Tray_rubber_inlay',(0,y+.021,0),(.86,.009,.49),rubber,.004)
 for z in [-.283,.283]:box('Folded_tray_lip',(0,y+.032,z),(.95,.057,.018),alloy,.006)
 for x in [-.466,.466]:box('Folded_tray_end',(x,y+.032,0),(.018,.057,.55),alloy,.006)
# Small closed storage drawer under work surface, readable as a tool cart.
box('Drawer_gasket',(0,.682,.015),(.79,.14,.43),dark,.012)
box('Drawer_front',(0,.68,.244),(.772,.122,.035),enamel,.009)
box('Recessed_pull',(0,.692,.265),(.28,.025,.010),dark,.004)
for x in [-.31,.31]:rod('Drawer_captive_fastener',(x,.68,.261),(x,.68,.269),.009,alloy,8)
box('ID_plate',(-.245,.69,.267),(.07,.035,.006),bronze,.003)
# Push handle joined to right tube legs. Round rails visibly connect to supports.
for z in [-.21,.21]:rod('Handle_riser',(.37,.77,z),(.49,.94,z),.016,alloy,12)
rod('Push_bar',(.49,.94,-.21),(.49,.94,.21),.020,alloy,16)
rod('Rubber_handle_grip',(.49,.94,-.135),(.49,.94,.135),.025,rubber,16)
for m in [enamel,alloy,dark,rubber,bronze]:
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==m]
 if not obs:continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();bpy.context.object.name='Cart_'+m.name
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/salvage_cart.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/salvage_cart.glb',export_format='GLB',export_yup=True,export_apply=True,export_animations=False)
json.dump({'triangles':sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons),'material_meshes':len(bpy.context.scene.objects),'license':'CC0-1.0','size_m':[1,.965,.58],'tray_surface_y':.81,'bottom_y':0,'collision':False},open(OUT+'/build_report.json','w'),indent=2)
