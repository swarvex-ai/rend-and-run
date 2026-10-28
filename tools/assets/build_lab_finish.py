import os, math, random, json, bpy
from pathlib import Path
# Reuse our authored metre-to-Blender geometry/material helpers, not its scene.
exec(Path(__file__).with_name('build_calibration_cell.py').read_text().split('# One metre-true bay:')[0])
OUT=os.environ['CELL_OUTPUT']
# Packed-exportable roughness texture: restrained directional machining variation.
random.seed(34);n=256
im=bpy.data.images.new('Satin_directional_roughness',width=n,height=n,alpha=False)
im.colorspace_settings.name='Non-Color';pixels=[]
rows=[random.uniform(-.035,.035) for _ in range(n)]
for y in range(n):
 for x in range(n):
  v=max(.16,min(.37,.255+rows[y]+random.uniform(-.012,.012)+.015*math.sin(x*.035)))
  pixels.extend((v,v,v,1))
im.pixels=pixels;im.filepath_raw=OUT+'/satin_roughness.png';im.file_format='PNG';im.save();im.pack()
floor=material('Satin_machined_floor',(.25,.28,.30),.72,.26)
node=floor.node_tree.nodes.new('ShaderNodeTexImage');node.image=im;floor.node_tree.links.new(node.outputs['Color'],floor.node_tree.nodes.get('Principled BSDF').inputs['Roughness'])
# Top surface exactly at Y=0. All channels are below the unchanged collision plane.
box('Deck_underpan',(0,-.10,0),(3,.10,3.8),dark)
for x in [-.75,.75]:
 for z in [-.82,.82]:
  box('Satin_floor_panel',(x,-.03,z),(1.474,.06,1.58),floor,.009)
  # Captive mounting heads are inset, not ankle-high protrusions.
  for dx in [-.65,.65]:
   for dz in [-.69,.69]:
    rod('Recessed_fastener',(x+dx,-.005,z+dz),(x+dx,-.001,z+dz),.026,dark,8)
for z in [-1.73,0,1.73]:
 box('Recessed_service_channel',(0,-.022,z),(2.98,.025,.13),dark,.003)
 for i in range(30):box('Drain_bridge',(-1.45+i*.10,-.01,z),(.027,.02,.11),steel,.003)
box('Front_recess',(0,-.145,1.86),(3,.23,.08),dark)
box('Front_edge',(0,-.033,1.86),(2.98,.055,.08),steel,.008)
box('Amber_inset',(0,-.17,1.91),(.40,.018,.012),amber,.003)
# Overhead service layer: slender rails and conduits; leave the broad cell lights visible.
for z in [-1.14,-.55]:
 box('Ceiling_longitudinal_rail',(0,4.12,z),(2.985,.14,.12),dark)
 box('Rail_machined_lip',(0,4.02,z),(2.96,.025,.14),steel,.005)
for x in [-1.3,1.3]:
 box('Suspension_web',(x,4.30,-.87),(.085,.44,.80),dark)
 for z in [-1.1,-.62]:rod('Suspension_bolt',(x,4.08,z+.035),(x,4.08,z+.065),.025,bronze,8)
for y,z in [(4.28,-.8),(4.39,-.8),(4.30,-1.3)]:rod('Utility_conduit',(-1.5,y,z),(1.5,y,z),.038,steel,16)
for x in [-1.25,0,1.25]:
 box('Conduit_saddle',(x,4.335,-.8),(.05,.22,.17),dark,.007)
box('Service_number_plate',(.85,4.095,-.45),(.38,.16,.025),bronze,.01)
for x in [.74,.79,.9]:box('Panel_mark',(x,4.095,-.43),(.012,.07,.008),dark,.002)
# UVs on standard primitives are retained; consolidate by material.
for m in [shell,dark,steel,rubber,bronze,light,amber,floor]:
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==m]
 if not obs:continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();bpy.context.object.name='Finish_'+m.name
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/lab_finish.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/lab_finish.glb',export_format='GLB',export_yup=True,export_apply=True,export_animations=False)
json.dump({'triangles':sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons),'material_meshes':len(bpy.context.scene.objects),'license':'CC0-1.0','floor_top_y':0,'module_width':3},open(OUT+'/build_report.json','w'),indent=2)
