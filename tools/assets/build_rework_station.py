"""Original repair station for the first earned upgrade; no third-party/provider assets."""
from pathlib import Path
exec(Path(__file__).with_name('build_calibration_cell.py').read_text().split('# One metre-true bay:')[0])
enamel=material('Station_enamel',(.46,.49,.50),.2,.34)
satin=material('Station_satin_alloy',(.32,.36,.39),.82,.3)
screen=material('Diagnostic_glass',(.017,.037,.045),.15,.19)
readout=material('Diagnostic_readout',(.08,.55,.59),.08,.36,.8)
# 1.4 m footprint, top at 1.04 m; front +Z. Cabinet is behind the playable lane.
for x in [-.62,.62]:
 for z in [-.36,.36]:
  box('Adjustable_rubber_foot',(x,.035,z),(.15,.07,.15),rubber,.018)
  rod('Foot_thread',(x,.07,z),(x,.145,z),.037,satin,16)
  box('Corner_upright',(x,.55,z),(.095,.84,.095),satin,.01)
for y in [.16,.88]:
 for z in [-.36,.36]:box('Welded_cross_member',(0,y,z),(1.25,.065,.055),dark,.009)
box('Inset_lower_shelf',(0,.175,0),(1.20,.035,.70),satin,.005)
# Folded worktop, rounded edge and recessed replaceable working pad.
box('Folded_worktop',(0,.983,0),(1.40,.085,.90),satin,.016)
box('Replaceable_work_pad',(-.07,1.03,.025),(1.03,.018,.58),rubber,.006)
for x in [-.665,.665]:box('Impact_corner_guard',(x,.99,0),(.065,.09,.88),dark,.012)
box('Front_safety_inlay',(0,.984,.458),(.66,.018,.007),bronze,.002)
# Powder-coated drawer cabinet with shadow gaps and finger recesses.
box('Drawer_carcass',(-.25,.557,.055),(.68,.72,.65),dark,.014)
for y in [.35,.54,.73]:
 box('Drawer_face',(-.25,y,.39),(.641,.172,.035),enamel,.008)
 box('Handle_recess',(-.25,y+.035,.411),(.40,.039,.012),dark,.005)
 box('Pull_lip',(-.25,y+.045,.425),(.34,.012,.026),satin,.003)
 for x in [-.53,.03]:rod('Drawer_captive_screw',(x,y-.045,.408),(x,y-.045,.414),.009,satin,10)
# Service/power unit, real slats rather than a painted black rectangle.
box('Power_unit',(.335,.41,.02),(.32,.43,.51),dark,.022)
for y in [.30,.34,.38,.42,.46]:box('Cooling_fin',(.335,y,.283),(.24,.016,.012),satin,.003)
rod('Power_status',(.435,.54,.278),(.435,.54,.292),.012,amber,12)
# A compact alignment clamp tells the player what is repaired here.
box('Clamp_mount',(-.35,1.06,-.16),(.34,.04,.24),satin,.01)
for x in [-.46,-.26]:
 box('Clamp_jaw',(x,1.13,-.16),(.055,.12,.19),satin,.008)
 box('Clamp_pad',(x+(.03 if x<-.3 else -.03),1.135,-.16),(.008,.075,.13),rubber,.002)
rod('Clamp_spindle',(-.54,1.105,-.16),(-.18,1.105,-.16),.014,bronze,16)
rod('Clamp_handle',(-.55,1.04,-.16),(-.55,1.17,-.16),.012,dark,12)
# Low diagnostics tablet, discreet graphics; no giant floating interface.
box('Diagnostic_mount',(.40,1.08,-.22),(.22,.1,.16),dark,.012)
box('Diagnostic_console',(.40,1.185,-.225),(.31,.23,.07),satin,.013)
box('Diagnostic_screen',(.40,1.19,-.182),(.265,.182,.014),screen,.008)
for i,w in enumerate([.17,.11,.19]):box('Readout_trace',(.39,1.23-i*.036,-.172),(w,.009,.003),readout,.001)
for x in [.325,.38,.435]:rod('Console_key',(x,1.113,-.181),(x,1.113,-.164),.01,bronze,12)
# Contained consumable tray and reusable loose actuator part.
box('Parts_tray',(.24,1.055,.20),(.35,.025,.20),satin,.008)
for z in [.102,.298]:box('Tray_fold',(.24,1.073,z),(.35,.035,.012),satin,.002)
rod('Service_actuator',(.13,1.093,.20),(.33,1.093,.20),.035,dark,20)
for x in [.16,.29]:rod('Actuator_band',(x-.014,1.093,.20),(x+.014,1.093,.20),.039,satin,20)
cable('Diagnostic_lead',[(.43,1.16,-.26),(.57,1.07,-.34),(.54,.72,-.40),(.37,.54,-.27)],.013)
# Consolidate predictable material batches while retaining manufactured bevels.
for m in [enamel,satin,screen,readout,dark,rubber,bronze,amber]:
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==m]
 if not obs:continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();bpy.context.object.name='Rework_'+m.name
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/rework_station.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/rework_station.glb',export_format='GLB',export_yup=True,export_apply=True,export_animations=False)
json.dump({'triangles':sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons),'material_meshes':len(bpy.context.scene.objects),'license':'CC0-1.0','footprint_m':[1.4,.9],'worktop_y':1.039,'collision':False,'front':'+Z'},open(OUT+'/build_report.json','w'),indent=2)
