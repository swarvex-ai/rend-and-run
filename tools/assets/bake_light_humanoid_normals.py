import bpy, json, hashlib, time, os
from pathlib import Path
root=Path(os.environ.get('REND_WORKSPACE', str(Path(__file__).resolve().parents[4])))
out=root/'outputs/humanoid_normal_bake_codex_v01'
bpy.ops.wm.read_factory_settings(use_empty=True)
sources={}
for label,rel in [('high','humanoids_v01/enemy_humanoid_light_chassis.glb'),('low','humanoids_v02/enemy_humanoid_light_chassis_opt.glb')]:
 path=root/'outputs/asset_library/incoming'/rel
 before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(path))
 meshes=[o for o in bpy.data.objects if o not in before and o.type=='MESH'];assert len(meshes)==1
 obj=meshes[0];obj.name=label;sources[label]={'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'object':obj.name}
low=bpy.data.objects['low'];high=bpy.data.objects['high']
# Isolate destination nodes; original high shader/normal details are retained.
image=bpy.data.images.new('light_humanoid_baked_normal',width=2048,height=2048,alpha=False,float_buffer=False)
image.colorspace_settings.name='Non-Color';image.generated_color=(.5,.5,1,1)
for slot in low.material_slots:
 slot.material=slot.material.copy();nodes=slot.material.node_tree.nodes
 for node in nodes:node.select=False
 target=nodes.new('ShaderNodeTexImage');target.image=image;target.select=True;nodes.active=target
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=16
scene.render.bake.use_selected_to_active=True;scene.render.bake.use_clear=True
scene.render.bake.cage_extrusion=.025;scene.render.bake.max_ray_distance=.05
scene.render.bake.margin=12;scene.render.bake.normal_space='TANGENT'
scene.render.bake.normal_r='POS_X';scene.render.bake.normal_g='POS_Y';scene.render.bake.normal_b='POS_Z'
bpy.ops.object.select_all(action='DESELECT');high.select_set(True);low.select_set(True);bpy.context.view_layer.objects.active=low
start=time.time();bpy.ops.object.bake(type='NORMAL')
image.filepath_raw=str(out/'light_humanoid_baked_normal.png');image.file_format='PNG';image.save()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'normal_bake.blend'))
(out/'bake-report.json').write_text(json.dumps({'sources':sources,'normal_png_sha256':hashlib.sha256((out/'light_humanoid_baked_normal.png').read_bytes()).hexdigest(),'elapsed_seconds':time.time()-start,'size':2048,'normal_space':'tangent OpenGL +Y','cage_extrusion_m':.025,'max_ray_distance_m':.05,'margin_px':12,'high_source_material_normals_retained':True,'license':'LicenseRef-Meshy-Paid','status':'candidate; not approved or integrated'},indent=2))
