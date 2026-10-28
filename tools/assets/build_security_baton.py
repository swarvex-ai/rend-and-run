import bpy, math, json, os
from pathlib import Path
out=Path(os.environ['BATON_OUTPUT']);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
def mat(name,color,metal,rough):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
rubber=mat('Graphite_grip',(.023,.03,.037),.1,.65)
steel=mat('Satin_security_alloy',(.27,.32,.35),.8,.3)
white=mat('Ceramic_service_collar',(.58,.61,.63),.15,.28)
copper=mat('Amber_contact_alloy',(.68,.30,.055),.65,.32)
def finish(o,name,m,bevel=.004):
 o.name=name;o.data.materials.append(m);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Manufactured_edges','BEVEL');mod.width=bevel;mod.segments=1;bpy.ops.object.modifier_apply(modifier=mod.name)
 mod=o.modifiers.new('Weighted_normals','WEIGHTED_NORMAL');mod.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def cyl(name,y,r,h,m,n=12):
 bpy.ops.mesh.primitive_cylinder_add(vertices=n,radius=r,depth=h,location=(0,0,y));return finish(bpy.context.object,name,m)
def box(name,p,size,m):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(p[0],-p[2],p[1]));o=bpy.context.object;o.scale=(size[0],size[2],size[1]);return finish(o,name,m,.002)
cyl('Grip_core',-.004,.043,.24,rubber)
cyl('Pommel',-.132,.049,.024,steel)
for i in range(7):cyl('Grip_rib',-.098+i*.031,.047,.008,rubber)
cyl('Hand_stop',.125,.07,.025,steel)
cyl('Service_collar',.19,.058,.10,white)
cyl('Collar_seal',.245,.06,.012,rubber)
cyl('Impact_shaft',.555,.038,.608,steel)
cyl('Head_isolator',.86,.05,.045,rubber)
cyl('Contact_core',.935,.042,.12,white)
cyl('Protective_tip',1.003,.054,.024,steel)
for x,z in [(.047,0),(-.047,0),(0,.047),(0,-.047)]:
 box('Electrode_rail',(x,.936,z),(.017,.10,.017),copper)
box('Status_recess',(0,.194,.058),(.033,.056,.008),rubber)
box('Status_inset',(0,.20,.063),(.009,.032,.004),copper)
for m in [rubber,steel,white,copper]:
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials[0]==m]
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name='Baton_'+m.name
tri=sum(len(p.vertices)-2 for o in bpy.context.scene.objects for p in o.data.polygons)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'security_baton.blend'))
bpy.ops.export_scene.gltf(filepath=str(out/'model.glb'),export_format='GLB',export_yup=True,export_animations=False)
(out/'build-report.json').write_text(json.dumps({'license':'CC0-1.0','source':'original local Blender','triangles':tri,'materials':4,'axis':'+Y','origin':'grip midpoint','runtime_scale':.58,'new_gameplay':False},indent=2))
print('TRIANGLES',tri)
