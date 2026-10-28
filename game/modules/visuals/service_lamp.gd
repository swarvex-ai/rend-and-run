extends Node3D
# Shared authored fixture. One shadowless light per instance; no processing/timers.
const MODEL = preload("res://assets3d/env/service_lamp_v1/model.glb")
var tint := Color(.75,.80,1.0)
func _ready() -> void:
 var model=MODEL.instantiate();model.name="Housing";add_child(model)
 for node in model.find_children("*","MeshInstance3D",true,false):
  for surface in node.mesh.get_surface_count():
   var material=node.mesh.surface_get_material(surface)
   if material is StandardMaterial3D and material.emission_enabled:
    var diffuser=material.duplicate()
    diffuser.emission=tint;diffuser.emission_energy_multiplier=1.8
    node.set_surface_override_material(surface,diffuser)
 var light:=OmniLight3D.new();light.name="PoolLight";light.position=Vector3(0,-.22,.35)
 light.light_color=tint;light.light_energy=1.7;light.omni_range=7.0
 light.shadow_enabled=false;add_child(light)
