extends Node
## FX — Autoload: Hit-Stop, Screenshake, Blood, Blut-Pfützen, Sound. Das Metzel-Öl.

var shake := 0.0
var shake_dir := Vector3(1, 0.35, 0)   # V85: Hauptrichtung des Traumas (x dominant)
var _players: Array = []
var _sfx := {}
var audio_events: Dictionary = {}

## [t_bb2ba447] Abnahme-Zaehler: zaehlt NUR tatsaechlich ausgeloesste Effekte,
## damit der Harness Feedback (Hitstop/Blut/Pfuetze) maschinell belegen kann.
var fx_stats := {"hitstop": 0, "blood": 0, "pool": 0}
var _quitting := false

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)  # closing the window goes through quit_game()
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "Combat"
		add_child(p)
		_players.append(p)
	for n in ["swing", "hit", "die", "ow", "block", "parry", "guard_break", "footstep_metal_a", "footstep_metal_b", "land_metal", "radio_chirp"]:
		var path := "res://audio/%s.wav" % n
		if ResourceLoader.exists(path):
			_sfx[n] = load(path)
	# Numbered variants per group (audio/voice/<group>_NN.wav, see LICENSE.md there).
	for group in ["rend_hurt_light", "rend_hurt_heavy", "rend_death"]:
		var takes: Array = []
		for i in range(1, 13):
			var path := "res://audio/voice/%s_%02d.wav" % [group, i]
			if ResourceLoader.exists(path):takes.append(load(path))
		if not takes.is_empty():_voices[group] = takes

## Brief slow motion (real seconds), e.g. as the last robot of a fight goes down.
var slowmos := 0
func slowmo(duration := 0.5, scale := 0.3) -> void:
	if Engine.time_scale != 1.0:return
	slowmos += 1
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

## Red pulse at the screen edges when Rend is hurt.
var _vignette: TextureRect
func damage_flash(strength := 1.0) -> void:
	if not is_instance_valid(_vignette):
		var layer := CanvasLayer.new();layer.layer = 40;add_child(layer)
		_vignette = TextureRect.new();_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
		_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE;_vignette.stretch_mode = TextureRect.STRETCH_SCALE
		var g := Gradient.new();g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([Color(.6, 0, 0, 0), Color(.6, 0, 0, 0), Color(.7, 0, 0, .75)])
		var tex := GradientTexture2D.new();tex.gradient = g;tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(.5, .5);tex.fill_to = Vector2(1.05, .5);tex.width = 256;tex.height = 256
		_vignette.texture = tex;_vignette.modulate.a = 0.0;layer.add_child(_vignette)
	_vignette.modulate.a = clampf(0.55 * strength, 0.0, 0.8)
	var tw := _vignette.create_tween().set_ignore_time_scale(true)
	tw.tween_property(_vignette, "modulate:a", 0.0, 0.45)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:quit_game()

## Quit without leaking audio: stop every player first and let the mixer retire the
## playbacks; quitting while loops still play leaks their streams at exit.
## (The remaining "7 RIDs of type Texture" warning comes from any ReflectionProbe in
## Godot 4.7.2 itself and is harmless.)
func quit_game() -> void:
	if _quitting:return
	_quitting = true
	for node in get_tree().root.find_children("*", "AudioStreamPlayer", true, false) + get_tree().root.find_children("*", "AudioStreamPlayer3D", true, false):
		node.stop()
	await get_tree().create_timer(0.15, true, false, true).timeout
	get_tree().quit()

func _process(delta: float) -> void:
	shake = maxf(0.0, shake - delta * 2.2)

func add_shake(v: float, direction := Vector3.ZERO) -> void:
	shake = minf(1.0, shake + v)
	if direction != Vector3.ZERO:
		shake_dir = direction.normalized()

func play(sfx_name: String, pitch := 1.0, vol_db := -2.0) -> void:
	if not _sfx.has(sfx_name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _sfx[sfx_name]
			p.pitch_scale = clampf(pitch * randf_range(0.93, 1.08), 0.4, 2.2)
			p.volume_db = vol_db
			p.play()
			audio_events[sfx_name] = int(audio_events.get(sfx_name,0))+1
			return

## One voice line from a variant group; never the same take twice in a row.
var _voices := {}
var _last_voice := {}
var _voice_player: AudioStreamPlayer
func voice(group: String, vol_db := -4.0) -> void:
	if not _voices.has(group):return
	var takes: Array = _voices[group]
	var pick := randi() % takes.size()
	if takes.size() > 1 and pick == _last_voice.get(group, -1):pick = (pick + 1) % takes.size()
	_last_voice[group] = pick
	if _voice_player == null:
		preload("res://modules/persistence/settings_store.gd").bus_index("Voice")
		_voice_player = AudioStreamPlayer.new();_voice_player.bus = "Voice";add_child(_voice_player)
	# One mouth: a new cry cuts the previous one instead of stacking.
	_voice_player.stream = takes[pick]
	_voice_player.pitch_scale = randf_range(0.97, 1.03)
	_voice_player.volume_db = vol_db
	_voice_player.play()
	audio_events[group] = int(audio_events.get(group, 0)) + 1

func hitstop(duration := 0.06, scale := 0.04, glide := 0.0) -> void:
	if Engine.time_scale != 1.0:
		return
	fx_stats["hitstop"] += 1
	Engine.time_scale = scale
	# ignore_time_scale=true: der Timer läuft in REALZEIT weiter
	await get_tree().create_timer(duration, true, false, true).timeout
	if glide > 0.0:
		# V85 Nachklang: kurz leicht gezeitlupt weiter statt harter Sprung auf 1.0
		Engine.time_scale = glide
		await get_tree().create_timer(0.05, true, false, true).timeout
	Engine.time_scale = 1.0

# Scene-owned emitter: reloads discard active effects automatically.
var _blood_spray: Node3D
func blood(pos: Vector3, amount := 24, spread := 4.5, direction := Vector3.UP) -> void:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene): return
	fx_stats["blood"] += 1
	if not is_instance_valid(_blood_spray) or _blood_spray.get_parent() != scene:
		if is_instance_valid(_blood_spray): _blood_spray.queue_free()
		_blood_spray = preload("res://modules/vfx/blood_spray.gd").new()
		_blood_spray.name = "CombatBloodSpray"
		scene.add_child(_blood_spray)
	var strength := clampf((float(amount) / 26.0 + spread / 4.5) * 0.5, 0.4, 1.4)
	_blood_spray.emit_burst(pos, direction, strength)

## Dauerhafte Blutpfütze — bleibt liegen und erzählt: hier ist jemand gestorben.
func pool(pos: Vector3) -> void:
	fx_stats["pool"] += 1
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var r := randf_range(0.3, 0.55)
	cyl.top_radius = r
	cyl.bottom_radius = r * 0.85
	cyl.height = 0.02
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.01, 0.03, 0.95)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.mesh = cyl
	mi.material_override = m
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos + Vector3(0, 0.02, 0)
	var tw := mi.create_tween()
	tw.tween_interval(12.0)
	tw.tween_property(m, "albedo_color:a", 0.0, 3.0)
	tw.tween_callback(mi.queue_free)

func cut_flash(pos: Vector3, facing: float, finisher: bool) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.35 if finisher else 0.95, 0.035, 0.035)
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0,0.65,0.3) if finisher else Color(0.5,1.0,1.0)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(mi)
	mi.global_position = pos + Vector3(0,0,0.45)
	mi.rotation.z = facing * (-0.55 if finisher else 0.55)
	var tw := mi.create_tween()
	tw.tween_property(mi,"scale",Vector3(1.7,0.01,0.01),0.12)
	tw.tween_callback(mi.queue_free)

var _dash_streaks: Node3D
func dash_flash(pos: Vector3, direction := Vector3.RIGHT) -> void:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene): return
	if not is_instance_valid(_dash_streaks) or _dash_streaks.get_parent() != scene:
		if is_instance_valid(_dash_streaks): _dash_streaks.queue_free()
		_dash_streaks = preload("res://modules/vfx/dash_streaks.gd").new()
		_dash_streaks.name = "DashStreaks"
		scene.add_child(_dash_streaks)
	_dash_streaks.emit_dash(pos + Vector3(0, 0.5, 0), direction)

func attack_warning(pos: Vector3, low: bool, heavy: bool) -> void:
	var label := Label3D.new()
	label.text = "TIEF" if low else "SCHWER" if heavy else "!"
	label.font_size = 48
	label.pixel_size = 0.007
	label.modulate = Color(1,0.28,0.18) if heavy else Color(1,0.8,0.25)
	get_tree().current_scene.add_child(label)
	label.global_position = pos + Vector3(0,2.05,0.1)
	get_tree().create_timer(0.5, false).timeout.connect(label.queue_free)

# A scene-owned emitter prevents effects surviving respawn/reload.
var _landing_dust: Node3D
var landing_events := 0
func landing_dust(pos: Vector3, impact_speed: float) -> void:
	if impact_speed < 4.0: return
	var scene := get_tree().current_scene
	if not is_instance_valid(scene): return
	if not is_instance_valid(_landing_dust) or _landing_dust.get_parent() != scene:
		if is_instance_valid(_landing_dust): _landing_dust.queue_free()
		_landing_dust = preload("res://modules/vfx/landing_dust.gd").new()
		_landing_dust.name = "LandingDust"
		scene.add_child(_landing_dust)
	landing_events += 1
	_landing_dust.emit_landing(pos, impact_speed)

var _metal_sparks: Node3D
var metal_contacts := 0
var parry_contacts := 0
func metal_contact(pos:Vector3,direction:Vector3,parry:=false)->void:
	var scene:=get_tree().current_scene
	if not is_instance_valid(scene):return
	if not is_instance_valid(_metal_sparks) or _metal_sparks.get_parent()!=scene:
		if is_instance_valid(_metal_sparks):_metal_sparks.queue_free()
		_metal_sparks=preload("res://modules/vfx/metal_sparks.gd").new()
		_metal_sparks.name="MetalSparks";scene.add_child(_metal_sparks)
	metal_contacts+=1
	if parry:parry_contacts+=1
	_metal_sparks.emit_contact(pos,direction,parry)
	impact_light(pos,Color(1.0,.62,.28),2.2 if parry else 1.4,.09)

## A blow landing on a robot: spark shower, white-hot flash, falling chips, light pulse.
var robot_impacts := 0
func robot_impact(pos: Vector3, direction: Vector3, heavy := false) -> void:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene):return
	robot_impacts += 1
	preload("res://modules/vfx/impact_sparks.gd").burst(scene, pos, direction, heavy)
	preload("res://modules/vfx/debris.gd").chips(scene, pos, direction, 6 if heavy else 3)
	impact_light(pos, Color(1.0, .62, .28), 4.0 if heavy else 3.0, .12, 3.4)

## Short real light pulse at an impact: sparks light up the actor and nearby floor.
## Pooled per scene; a new pulse restarts the nearest free light.
var _impact_lights: Array[OmniLight3D] = []
var impact_lights := 0
func impact_light(pos: Vector3, color: Color, energy := 1.6, duration := 0.1, light_range := 2.6) -> void:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene): return
	_impact_lights = _impact_lights.filter(func(l): return is_instance_valid(l) and l.get_parent() == scene)
	var light: OmniLight3D = null
	for candidate in _impact_lights:
		if candidate.light_energy <= 0.01:
			light = candidate;break
	if light == null:
		if _impact_lights.size() >= 4:
			light = _impact_lights[0]
		else:
			light = OmniLight3D.new();light.name = "ImpactLight";light.shadow_enabled = false
			scene.add_child(light);_impact_lights.append(light)
	impact_lights += 1
	light.global_position = pos;light.light_color = color;light.omni_range = light_range
	light.light_energy = energy
	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

## Electrical failure on a robot: blue-white arc flashes and a spark burst.
func shock(pos: Vector3, direction: Vector3) -> void:
	metal_contact(pos, direction, true)
	impact_light(pos + Vector3(0, .2, .3), Color(.55, .8, 1.0), 3.2, .18, 3.4)
	var tw := create_tween()
	for i in 3:
		tw.tween_interval(randf_range(.05, .12))
		tw.tween_callback(func(): impact_light(pos + Vector3(randf_range(-.25, .25), randf_range(-.2, .4), .3), Color(.6, .85, 1.0), 2.0, .07, 2.6))
