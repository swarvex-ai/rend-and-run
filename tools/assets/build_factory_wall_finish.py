from pathlib import Path
exec(Path(__file__).with_name('build_calibration_cell.py').read_text().split('# One metre-true bay:')[0])
# Original cladding module: local centre aligned to a calibration bay, front +Z.
enamel=material('Pearl_powdercoat',(.48,.50,.505),.18,.32)
alloy=material('Satin_aluminium',(.34,.36,.37),.78,.30)
# Recessed substrate; discrete broad panels avoid a monolithic flat facade.
box('Sill_shadow_recess',(0,.43,-.15),(5.22,.64,.32),dark,.02)
for x in [-1.745,0,1.745]:
 box('Sill_enamel_panel',(x,.43,.027),(1.725,.592,.054),enamel,.009)
 for dx in [-.78,.78]:
  for y in [.19,.66]:
   rod('Recessed_torx_head',(x+dx,y,.049),(x+dx,y,.055),.014,alloy,12)
   box('Fastener_slot',(x+dx,y,.057),(.012,.003,.002),dark,.0005)
box('Sill_upper_cap',(0,.744,-.065),(5.22,.038,.28),alloy,.009)
box('Kickplate',(0,.094,.003),(5.2,.083,.045),dark,.009)
# Restrained service access hatch on one panel, with recessed handle and serial strokes.
box('Access_gasket',(-1.75,.415,.058),(.80,.31,.007),dark,.003)
box('Access_panel',(-1.75,.415,.064),(.778,.288,.008),enamel,.003)
box('Flush_handle',(-1.47,.425,.070),(.035,.105,.005),dark,.001)
for x in [-2.03,-1.98,-1.92]:box('Identification_stroke',(x,.37,.071),(.014,.04,.002),alloy,.001)
# Right-hand pier; assembled panels preserve narrow engineered seams.
box('Pier_substructure',(2.95,2.15,-.18),(.65,4.3,.32),dark,.025)
for lo,hi in [(.10,1.445),(1.465,3.79),(3.81,4.29)]:
 box('Pier_enamel_panel',(2.95,(lo+hi)/2,.018),(.618,hi-lo,.070),enamel,.011)
 for x in [2.71,3.19]:
  for y in [lo+.085,hi-.085]:rod('Pier_captive_bolt',(x,y,.046),(x,y,.055),.016,alloy,12)
box('Pier_base_plinth',(2.95,.07,.025),(.67,.14,.13),dark,.018)
box('Pier_status_socket',(2.95,.285,.063),(.06,.225,.025),dark,.008)
box('Pier_amber_status',(2.95,.285,.08),(.022,.16,.013),amber,.003)
box('Upper_transom',(0,4.015,-.09),(5.23,.12,.27),dark,.015)
box('Transom_trim',(0,3.967,.049),(5.14,.023,.021),alloy,.004)
for m in [enamel,alloy,dark,amber]:
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==m]
 if not obs:continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();bpy.context.object.name='Wall_finish_'+m.name
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/factory_wall_finish.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/factory_wall_finish.glb',export_format='GLB',export_yup=True,export_apply=True,export_animations=False)
json.dump({'triangles':sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons),'material_meshes':len(bpy.context.scene.objects),'license':'CC0-1.0','bay_width_m':5.9,'height_m':4.3,'front':'+Z','collision':False},open(OUT+'/build_report.json','w'),indent=2)
