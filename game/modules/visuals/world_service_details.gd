extends Node3D
# Static reusable background kit. No processing, collision, lights or gameplay.
const VENT = preload("res://assets3d/env/vent_v1/model.glb")
const TRAY = preload("res://assets3d/env/cable_tray_v1/model.glb")
const FRAME = preload("res://assets3d/env/door_frame_cutaway_v1/model.glb")
func _ready() -> void:
 for x in [17.7,19.0,20.3,35.7,37.0,38.3,77.7,79.0,80.3]:_place(VENT,"Vent%d"%int(x*10),Vector3(x,2.3,-1.72))
 for x in [12,15,18,21]:_place(TRAY,"UpperTray%d"%x,Vector3(x,3.65,-1.65))
 for x in [30,33,36,39,42,45,48,51,54,57,60,63,66,69,72]:_place(TRAY,"ServiceTray%d"%x,Vector3(x,3.65,-1.65))
 _place(FRAME,"SecurityDoorFrame",Vector3(77,0,0))
func _place(scene:PackedScene,label:String,at:Vector3) -> void:
 var model=scene.instantiate();model.name=label;model.position=at;add_child(model)
