extends Node3D
# Physical encounter boundary. Entry clearance prevents closing through the player.
const CLOSE_X := 46.5 # legacy layout reference
@export var entry_x := 45.65
var close_x:float:
 get:return entry_x+.85
var locked := false
var body:StaticBody3D
var collider:CollisionShape3D
func _ready():
 position=Vector3(entry_x,0,0)
 body=StaticBody3D.new();body.collision_layer=0;body.collision_mask=0;add_child(body)
 collider=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.22,6.0,3.8);collider.shape=shape;collider.position.y=3;body.add_child(collider)
 var material:=StandardMaterial3D.new();material.albedo_color=Color(.18,.23,.25);material.metallic=.65;material.roughness=.6
 for z in [-1.7,0,1.7]:
  var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.22,6,.08);mesh.mesh=box;mesh.position=Vector3(0,3,z);mesh.material_override=material;body.add_child(mesh)
 for y in [.1,1.5,3.0,4.5,5.9]:
  var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.22,.08,3.5);mesh.mesh=box;mesh.position=Vector3(0,y,0);mesh.material_override=material;body.add_child(mesh)
 body.hide()
func update_encounter(player_x:float,player_dead:bool,boss_alive:bool,boss_active:bool):
 if player_dead or not boss_alive or not boss_active:
  release()
 elif not locked and player_x>=close_x:
  locked=true;body.collision_layer=1;body.show()
func release():
 locked=false
 if is_instance_valid(body):body.collision_layer=0;body.hide()
