"""Local authored shoulder armor; no generated/provider assets or external licenses."""
import bpy,sys,math
from pathlib import Path
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,color,metal):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.38
 return m
shell=mat('Burnished steel',(.12,.17,.20),.7)
edge=mat('Copper ceramic edge',(.46,.19,.065),.5)
fastener=mat('Black fasteners',(.025,.03,.035),.5)
# Blender Z maps to Godot Y. Shoulder cap has bevelled layered plates, not spherical balls.
def block(name,loc,dims,material,bevel=.014):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=dims
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(material)
 mod=o.modifiers.new('Machined bevel','BEVEL');mod.width=bevel;mod.segments=2
 bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
block('Shoulder shell',(0,0,0),(.22,.19,.22),shell)
block('Copper rim',(0,0,-.08),(.234,.205,.035),edge,.007)
block('Upper ridge',(0,0,.106),(.15,.16,.028),edge,.006)
for x in [-.084,.084]:
 for z in [-.06,.07]:
  block('Recessed bolt',(x,-.1,z),(.022,.015,.022),fastener,.003)
bpy.ops.object.select_all(action='SELECT')
out=Path(sys.argv[sys.argv.index('--')+1]);out.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=True,export_materials='EXPORT')
print('ARMOR_EXPORTED',out)
