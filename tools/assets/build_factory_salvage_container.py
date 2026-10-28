"""Original clean-factory component case, intact and collapsed; no paid assets."""
import bpy, os, json, math
from pathlib import Path
from mathutils import Vector

OUT=Path(os.environ['CONTAINER_OUTPUT']);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
def P(p):return Vector((p[0],-p[2],p[1]))
def material(name,color,metal,rough):
 m=bpy.data.materials.new(name);m.use_nodes=True
 p=m.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=(*color,1)
 p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 return m
paint=material('Ceramic_enamel',(.53,.57,.59),.12,.29)
dark=material('Graphite_isolator',(.023,.032,.041),.22,.48)
steel=material('Satin_alloy',(.24,.29,.32),.85,.26)
amber=material('Amber_latch',(.66,.28,.045),.48,.32)
materials=[paint,dark,steel,amber]
state=None
def finish(o,name,mat,bevel=0):
 o.name=name;o.data.materials.append(mat);o.parent=state
 if bevel:
  mod=o.modifiers.new('Manufactured_edge','BEVEL');mod.width=bevel;mod.segments=1
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 mod=o.modifiers.new('Face_weighted_normals','WEIGHTED_NORMAL');mod.keep_sharp=True
 bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def box(name,p,size,mat,bevel=.008):
 bpy.ops.mesh.primitive_cube_add(size=1,location=P(p));o=bpy.context.object
 o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return finish(o,name,mat,min(bevel,min(size)*.2))
def screw(p,axis='front'):
 bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.011,depth=.006,location=P(p))
 o=bpy.context.object
 if axis=='front':o.rotation_euler.x=math.pi/2
 return finish(o,'Captive_fastener',steel)
def group(name):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);return o

state=group('IntactVisual')
box('Lower_alloy_tray',(0,.084,0),(.80,.12,.66),steel,.014)
box('Main_enamel_shell',(0,.366,0),(.742,.49,.618),paint,.018)
for x in [-.365,.365]:
 for z in [-.279,.279]:
  box('Isolated_corner',(x,.34,z),(.085,.55,.092),dark,.012)
  box('Rubber_foot',(x,.024,z),(.10,.048,.105),dark,.007)
box('Lid_gasket',(0,.626,0),(.812,.027,.677),dark,.004)
box('Service_lid',(0,.675,0),(.824,.070,.692),paint,.013)
for z in [-.19,0,.19]:box('Lid_stiffener',(0,.715,z),(.54,.010,.025),steel,.003)
# The front is a layered, closed access panel, not a black void.
box('Recessed_front_frame',(0,.367,.317),(.651,.365,.025),dark,.008)
box('Front_access_panel',(0,.367,.333),(.590,.310,.018),paint,.006)
box('Panel_lower_reveal',(0,.206,.342),(.55,.008,.004),steel,.001)
for x in [-.25,.25]:
 box('Latch_mount',(x,.555,.343),(.064,.112,.036),steel,.008)
 box('Compression_latch',(x,.55,.365),(.034,.071,.011),amber,.003)
 for y in [.25,.47]:screw((x,y,.346))
box('Status_recess',(.19,.284,.345),(.065,.036,.004),dark,.001)
box('Status_inset',(.19,.284,.348),(.038,.009,.004),amber,.001)
for x in [-.17,-.135,-.10]:box('Embossed_component_mark',(x,.338,.345),(.014,.07 if x==-.135 else .045,.004),dark,.001)
for x in [-.41,.41]:
 box('Recessed_handle_bar',(x,.445,0),(.020,.035,.188),steel,.004)
 for z in [-.080,.080]:box('Handle_anchor',(x*.965,.420,z),(.031,.076,.032),dark,.004)

state=group('BrokenVisual')
box('Collapsed_lower_tray',(0,.043,0),(.78,.086,.63),dark,.010)
box('Exposed_tray_floor',(0,.091,0),(.70,.010,.54),steel,.002)
lid=box('Released_lid',(-.015,.117,.008),(.68,.026,.48),paint,.006)
lid.rotation_euler.y=-math.radians(8)
for x in [-.33,.33]:box('Collapsed_corner',(x,.035,-.245),(.11,.05,.11),dark,.006)
box('Released_latch',(.28,.035,.24),(.055,.018,.08),amber,.003)
box('Folded_front_plate',(-.22,.020,.265),(.29,.028,.06),paint,.004)

# Consolidate each state by material: exactly four shared materials, <=8 meshes.
for parent in [o for o in bpy.context.scene.objects if o.type=='EMPTY']:
 for mat in materials:
  obs=[o for o in list(parent.children) if o.type=='MESH' and o.data.materials[0]==mat]
  if not obs:continue
  bpy.ops.object.select_all(action='DESELECT')
  for o in obs:o.select_set(True)
  bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join()
  o=bpy.context.object;o.name=parent.name+'_'+mat.name
  bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
triangles=sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons)
assert triangles<=2500,triangles
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'factory_salvage_container.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'model.glb'),export_format='GLB',export_yup=True,export_apply=True,export_animations=False)
(OUT/'build-report.json').write_text(json.dumps({'license':'CC0-1.0','source':'Original local Blender construction, no provider assets','triangles':triangles,'materials':4,'mesh_objects':sum(o.type=='MESH' for o in bpy.context.scene.objects),'states':['IntactVisual','BrokenVisual'],'front':'+Z','origin':'base center Y0','collision':False},indent=2))
