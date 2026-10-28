import bpy, math, json, os
from pathlib import Path
out=Path(os.environ['SERVO_OUTPUT']);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0
def material(name,c,metal,rough):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
steel=material('Satin_housing',(.27,.33,.36),.85,.28)
black=material('Graphite_seals',(.022,.032,.039),.15,.58)
copper=material('Copper_windings',(.66,.27,.075),.8,.27)
white=material('Ceramic_service_caps',(.68,.72,.73),.12,.28)
def finish(o,name,m,bevel=.001):
 o.name=name;o.data.materials.append(m);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Manufactured_edges','BEVEL');mod.width=bevel;mod.segments=1;bpy.ops.object.modifier_apply(modifier=mod.name)
 mod=o.modifiers.new('Weighted_normals','WEIGHTED_NORMAL');mod.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def box(name,xyz,size,mat):
 x,y,z=xyz;bpy.ops.mesh.primitive_cube_add(size=1,location=(x,-z,y));o=bpy.context.object;o.scale=(size[0],size[2],size[1]);return finish(o,name,mat)
def cylinder(name,x,y,z,r,h,mat):
 bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r,depth=h,location=(x,-z,y));return finish(bpy.context.object,name,mat)
# Local origin is the clamp centre. Godot +Y follows the held arm, units metres.
for side in [-1,1]:
 x=side*.079
 cylinder('Actuator_seal',x,0,0,.024,.142,black)
 cylinder('Actuator_housing',x,0,0,.021,.114,steel)
 for y in [-.065,.065]:cylinder('Service_cap',x,y,0,.025,.015,white)
 for y in [-.038,-.019,0,.019,.038]:cylinder('Copper_stator',x,y,0,.0225,.006,copper)
 for y in [-.072,.072]:box('Clamp_link',(side*.058,y,0),(.063,.012,.028),steel)
 box('Protective_rail',(x,0,.024),(.028,.094,.008),steel)
 box('Service_inset',(x,.015,.029),(.012,.03,.003),black)
 box('Indicator',(x,.023,.032),(.008,.009,.002),copper)
box('Service_bridge',(0,0,.062),(.104,.045,.018),black)
box('Controller_cover',(0,0,.074),(.078,.033,.012),white)
box('Controller_stripe',(0,.008,.081),(.05,.006,.003),copper)
for mat in [steel,black,copper,white]:
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials[0]==mat]
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name='Servo_'+mat.name
tri=sum(len(p.vertices)-2 for o in bpy.context.scene.objects for p in o.data.polygons)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'arm_servo.blend'))
bpy.ops.export_scene.gltf(filepath=str(out/'model.glb'),export_format='GLB',export_yup=True,export_animations=False)
(out/'build-report.json').write_text(json.dumps({'asset_id':'rr_mod_arm_servo','license':'CC0-1.0','source':'Original local Blender geometry; no provider jobs','triangles':tri,'materials':4,'origin':'clamp centre; attach at arm local(0,.13,0)','axis':'+Y','reusable':'same mesh for installed module and servo component pickup'},indent=2))
print('TRIANGLES',tri)
