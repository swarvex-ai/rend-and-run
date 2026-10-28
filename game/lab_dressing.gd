extends Node3D
## Visual-only dressing. All geometry stays behind the playable plane.
## Shared materials; no lights, physics or per-frame processing.
var mats := {}
func material(key:String,color:Color,metal:=0.0,emission:=false)->StandardMaterial3D:
 if mats.has(key):return mats[key]
 var m:=StandardMaterial3D.new()
 m.albedo_color=color;m.metallic=metal;m.roughness=0.7
 if emission:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=1.1
 mats[key]=m
 return m
func box(label:String,pos:Vector3,size:Vector3,mat:Material)->MeshInstance3D:
 var n:=MeshInstance3D.new();n.name=label
 var mesh:=BoxMesh.new();mesh.size=size;n.mesh=mesh;n.material_override=mat
 n.position=pos;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(n)
 return n
func _ready():
 var edge=material("edge",Color(0.32,0.36,0.39),0.6)
 var factory=preload("res://modules/world/clean_factory.gd").new()
 factory.name="CleanFactorySector";add_child(factory)
 # The first-room architecture continues bay by bay through the rest of the route.
 var corridor=preload("res://modules/world/factory_corridor.gd").new()
 corridor.name="FactoryCorridor";add_child(corridor)
 # Ground edge rivets and short amber maintenance markings, kept below actor feet.
 for x in range(-2,83,2):
  box("FloorFastener",Vector3(x,0.005,1.78),Vector3(0.06,0.012,0.13),edge)
