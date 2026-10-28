extends Node3D
# Reusable, bounded background effect: one emitter/light, no timers or combat bodies.
var sparks: CPUParticles3D
var flash: OmniLight3D
var socket: Node3D
var burst_count := 0
var countdown := 0.7
var _rng := RandomNumberGenerator.new()
var _followup := false

func _ready() -> void:
 _rng.seed = 701
 var model = preload("res://assets3d/env/damaged_cable_v1/model.glb").instantiate()
 add_child(model)
 socket = model.find_child("spark_origin", true, false)
 assert(socket != null, "Cable model requires spark_origin")
 sparks = CPUParticles3D.new()
 sparks.name = "ElectricalSparks"
 sparks.emitting = false
 sparks.one_shot = true
 sparks.amount = 14
 sparks.lifetime = 0.48
 sparks.explosiveness = 1.0
 sparks.local_coords = false
 sparks.direction = Vector3(0.65, -0.3, 0.0)
 sparks.spread = 42.0
 sparks.initial_velocity_min = 0.65
 sparks.initial_velocity_max = 1.8
 sparks.gravity = Vector3(0,-4.8,0)
 sparks.particle_flag_align_y = true
 var mesh := BoxMesh.new()
 mesh.size = Vector3(0.008,0.038,0.008)
 var mat := StandardMaterial3D.new()
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.vertex_color_use_as_albedo = true
 mat.emission_enabled = true
 mat.emission = Color(1.0,0.55,0.16)
 mat.emission_energy_multiplier = 1.4
 mesh.material = mat
 sparks.mesh = mesh
 var ramp := Gradient.new()
 ramp.offsets = PackedFloat32Array([0.0,0.25,1.0])
 ramp.colors = PackedColorArray([Color(1,.92,.65),Color(1,.55,.16),Color(.7,.18,.03,0)])
 sparks.color_ramp = ramp
 socket.add_child(sparks)
 flash = OmniLight3D.new()
 flash.name = "LocalArcGlow"
 flash.light_color = Color(1.0,0.65,0.3)
 flash.omni_range = 0.75
 flash.light_energy = 0.0
 flash.shadow_enabled = false
 socket.add_child(flash)

func _process(delta: float) -> void:
 flash.light_energy = move_toward(flash.light_energy,0.0,delta*5.0)
 var camera := get_viewport().get_camera_3d()
 if camera and abs(camera.global_position.x-global_position.x)>12.0:
  sparks.emitting = false
  flash.light_energy = 0.0
  countdown = maxf(countdown,0.35)
  return
 countdown -= delta
 if countdown > 0.0:return
 sparks.restart()
 flash.light_energy = 0.45
 burst_count += 1
 # Occasional second spit, with time for the previous particles to expire.
 if not _followup and _rng.randf()<0.4:
  _followup = true
  countdown = 0.58
 else:
  _followup = false
  countdown = _rng.randf_range(1.4,3.2)
