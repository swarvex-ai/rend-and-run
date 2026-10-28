extends Node3D
const TOP := 5.0
@export var lift_x := 56.0
@export var return_start_x := 1.5
var lift:AnimatableBody3D
var target_y:=0.0
var unlocked:=false
var steel:StandardMaterial3D
func _slab(body:PhysicsBody3D,size:Vector3,custom_visual:PackedScene=null):
 var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;c.shape=shape;c.position.y=-size.y*.5;body.add_child(c)
 if custom_visual:
  body.add_child(custom_visual.instantiate())
 else:
  var visual:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;visual.mesh=mesh;visual.material_override=steel;visual.position=c.position;body.add_child(visual)
 body.collision_layer=1;body.collision_mask=0;add_child(body)
func _ready():
 steel=StandardMaterial3D.new();steel.albedo_color=Color(.12,.19,.20);steel.metallic=.6;steel.roughness=.6
 lift=AnimatableBody3D.new();lift.name="ServiceLift";lift.sync_to_physics=false
 _slab(lift,Vector3(2.4,.2,2.0),preload("res://assets3d/env/service_lift_v1/model.glb"));lift.position=Vector3(lift_x,0,0)
 var walk:=StaticBody3D.new();walk.name="ReturnCatwalk"
 _slab(walk,Vector3(lift_x-1.2-return_start_x,.2,2.0));walk.position=Vector3((return_start_x+lift_x-1.2)*.5,TOP,0)
 # Match the visible ceiling so jumps cannot pass through it from the return level.
 var roof:=StaticBody3D.new();roof.name="ReturnCeiling"
 _slab(roof,Vector3(lift_x+1.2-return_start_x,.3,2.0));roof.position=Vector3((return_start_x+lift_x+1.2)*.5,7.15,0)
 for x in [return_start_x+1.5,lerpf(return_start_x,lift_x,.28),lerpf(return_start_x,lift_x,.54),lerpf(return_start_x,lift_x,.8),lift_x-2]:
  var label:=Label3D.new();label.text="← RÜCKWEG / KALTSTART";label.position=Vector3(x,5.7,-1.1);label.font_size=26;label.pixel_size=.004;label.modulate=Color(.28,.65,.65);add_child(label)
func _physics_process(delta:float):
 lift.position.y=move_toward(lift.position.y,target_y,delta*1.6)
func _station(at:Vector3)->float:
 if absf(at.x-lift_x)>1.6 or absf(at.z)>.8:return -1
 if absf(at.y)<.3:return 0
 if absf(at.y-TOP)<.3:return TOP
 return -1
func prompt(at:Vector3)->String:
 var station:=_station(at)
 if station<0:return ""
 if not unlocked:return "SERVICEAUFZUG — Sicherheitssperre"
 if absf(lift.position.y-target_y)>.02:return "SERVICEAUFZUG — fährt"
 if absf(station-lift.position.y)>.25:return "E / Y — Aufzug rufen"
 if absf(at.x-lift_x)>1.0:return "Auf die Liftplattform treten"
 return "E / Y — Aufzug abwärts" if station>2 else "E / Y — Rückweg zum Kaltstart"
func interact(at:Vector3)->bool:
 var station:=_station(at)
 if not unlocked or station<0 or absf(lift.position.y-target_y)>.02:return false
 if absf(station-lift.position.y)>.25:target_y=station
 elif absf(at.x-lift_x)<=1.0:target_y=0 if station>2 else TOP
 else:return false
 return true
