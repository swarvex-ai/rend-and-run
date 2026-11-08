extends Node3D
## A firearm (Meshy models, asset_library/meshy/2026-10-23_weapons). Robots carry one and
## drop it when they fall; Rend picks it up, fires the magazine (`ammo`), reloads from his
## reserve and tosses the gun once both are spent. The node is the visual held at a hand;
## fire() spawns swept bullets (energy_bolt.gd) and resolves their hits itself.
## Convention (as the pulse emitter): local +Y is the barrel, +X the top.
## Mods (bought at the weapon bench, MODS): laser sight, extended magazine, quick-load grip,
## armour piercer - each changes the numbers and adds a small part to the gun.

signal emptied     # magazine and reserve both spent
signal reloaded

const UI_TEXT = preload("res://data/ui_texts.gd")

const MODS := {
	"laser": {"cost": 4},
	"extmag": {"cost": 5},
	"quickload": {"cost": 4},
	"piercer": {"cost": 6},
}

const SPECS := {
	"pistol": {"model": "res://assets3d/weapons/pistol_v1/model.glb",
		"damage": 1, "interval": 0.32, "ammo": 12, "speed": 30.0, "spread": 1.5, "pellets": 1, "life": 1.0,
		"burst": 2, "color": Color(1.0, 0.75, 0.35), "length": 0.24, "reload": 1.1},
	"smg": {"model": "res://assets3d/weapons/smg_v1/model.glb",
		"damage": 1, "interval": 0.09, "ammo": 30, "speed": 32.0, "spread": 4.0, "pellets": 1, "life": 0.9,
		"burst": 4, "color": Color(1.0, 0.8, 0.4), "length": 0.5, "reload": 1.6},
	"scattergun": {"model": "res://assets3d/weapons/scattergun_v1/model.glb",
		"damage": 1, "interval": 0.75, "ammo": 6, "speed": 24.0, "spread": 13.0, "pellets": 5, "life": 0.3,
		"burst": 1, "color": Color(1.0, 0.6, 0.25), "length": 0.62, "reload": 2.1},
	"energy_rifle": {"model": "res://assets3d/weapons/energy_rifle_v1/model.glb",
		"damage": 1, "interval": 0.11, "ammo": 32, "speed": 44.0, "spread": 1.6, "pellets": 1, "life": 1.5,
		"burst": 5, "color": Color(0.3, 0.95, 1.0), "length": 0.75, "reload": 1.8},  # full auto
}

static func label_of(kind: String) -> String:
	match kind:
		"pistol": return UI_TEXT.t("gun_pistol")
		"smg": return UI_TEXT.t("gun_smg")
		"scattergun": return UI_TEXT.t("gun_scattergun")
		"energy_rifle": return UI_TEXT.t("gun_energy_rifle")
	return ""

static func mod_label(id: String) -> String:
	match id:
		"laser": return UI_TEXT.t("gun_mod_laser")
		"extmag": return UI_TEXT.t("gun_mod_extmag")
		"quickload": return UI_TEXT.t("gun_mod_quickload")
		"piercer": return UI_TEXT.t("gun_mod_piercer")
	return ""

static func mod_info(id: String) -> String:
	match id:
		"laser": return UI_TEXT.t("gun_mod_laser_info")
		"extmag": return UI_TEXT.t("gun_mod_extmag_info")
		"quickload": return UI_TEXT.t("gun_mod_quickload_info")
		"piercer": return UI_TEXT.t("gun_mod_piercer_info")
	return ""

var kind := "pistol"
var ammo := 0                 # rounds in the magazine
var reserve := 0              # spare rounds
var mods: Array = []          # MODS keys fitted to this gun
var reload_left := 0.0        # > 0 while reloading
var _cooldown := 0.0
var _muzzle: Node3D
var _laser: MeshInstance3D
var _laser_dot: MeshInstance3D

func has_mod(m: String) -> bool:
	return m in mods

func mag_size() -> int:
	return int(ceil(spec().ammo * (1.5 if has_mod("extmag") else 1.0)))

func reload_time() -> float:
	return spec().reload * (0.6 if has_mod("quickload") else 1.0)

func is_reloading() -> bool:
	return reload_left > 0.0

## Starts a reload if there is something to load. Returns true if it started.
func reload() -> bool:
	if is_reloading() or reserve <= 0 or ammo >= mag_size():return false
	reload_left = reload_time()
	FX.play("block", 0.7, -10.0)
	# The spent magazine drops out of the well.
	if is_inside_tree():
		preload("res://modules/vfx/debris.gd").magazine(get_tree().current_scene, mag_well(), -global_basis.x * 1.2 + Vector3(0, -0.5, 0))
	return true

var _spare: MeshInstance3D
## The fresh magazine in his left hand during a reload (placed by gun_hold_pose).
func show_spare_mag(on: bool, at: Vector3) -> void:
	if _spare == null:
		_spare = MeshInstance3D.new();var b := BoxMesh.new();b.size = Vector3(.035, .13, .07);_spare.mesh = b
		var m := StandardMaterial3D.new();m.albedo_color = Color(.05, .055, .06);m.metallic = .65;m.roughness = .35
		_spare.material_override = m;_spare.top_level = true;add_child(_spare)
	_spare.visible = on
	if on:_spare.global_transform = Transform3D(global_basis.orthonormalized(), at)

## 0 when the reload starts .. 1 when the new magazine is seated.
func reload_progress() -> float:
	return 1.0 - reload_left / reload_time() if is_reloading() else 1.0

## World point of the magazine well (under the gun, in the grip for the pistol).
func mag_well() -> Vector3:
	var along: float = 0.85 if kind == "pistol" else 0.6
	return to_global(Vector3(-0.08, _muzzle.position.y - spec().length * along, 0))

static func make(gun_kind: String) -> Node3D:
	var gun: Node3D = (load("res://modules/combat/gun.gd") as GDScript).new()
	gun.kind = gun_kind;gun.ammo = SPECS[gun_kind].ammo;gun.name = "Gun_" + gun_kind
	return gun

func spec() -> Dictionary:
	return SPECS[kind]

func label() -> String:
	return label_of(kind)

func _ready() -> void:
	var model := (load(spec().model) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	# Meshy weapons come centred, ~1.9 m long along X with the barrel at -X and the grip
	# down; scale to the real length and turn the barrel onto +Y.
	var box := AABB();var first := true
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = m.transform * m.get_aabb()
		box = b if first else box.merge(b);first = false
	var s: float = spec().length / maxf(box.size.x, 0.001)
	var turn := Node3D.new();turn.name = "Turn";turn.rotation.z = -PI / 2;add_child(turn)
	turn.add_child(model)
	model.scale = Vector3.ONE * s
	model.position = -box.get_center() * s
	_muzzle = Node3D.new();_muzzle.name = "Muzzle";add_child(_muzzle)
	_muzzle.position = turn.transform * (model.transform * _barrel_end(model, box))
	_fit_mod_parts()

# Small visible parts for the fitted mods, in gun space (+Y barrel, +X top).
func _fit_mod_parts() -> void:
	var length: float = spec().length
	var dark := StandardMaterial3D.new();dark.albedo_color = Color(.06, .065, .07);dark.metallic = .7;dark.roughness = .35
	var glow := func(c: Color) -> StandardMaterial3D:
		var m := StandardMaterial3D.new();m.albedo_color = c;m.emission_enabled = true;m.emission = c;m.emission_energy_multiplier = 4.0;return m
	var muzzle_y: float = _muzzle.position.y
	if has_mod("laser"):
		_part(Vector3(-0.045, muzzle_y - length * 0.18, 0), Vector3(0.03, 0.08, 0.03), dark)
		_part(Vector3(-0.045, muzzle_y - length * 0.18 + 0.042, 0), Vector3(0.016, 0.004, 0.016), glow.call(Color(1, .1, .05)))
		_laser = MeshInstance3D.new();var beam := CylinderMesh.new();beam.top_radius = .003;beam.bottom_radius = .003;beam.height = 1.0
		_laser.mesh = beam;_laser.material_override = glow.call(Color(1, .08, .04));_laser.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_laser.top_level = true;add_child(_laser)
		_laser_dot = MeshInstance3D.new();var dot := SphereMesh.new();dot.radius = .018;dot.height = .036
		_laser_dot.mesh = dot;_laser_dot.material_override = glow.call(Color(1, .15, .1));_laser_dot.top_level = true;add_child(_laser_dot)
	if has_mod("extmag"):
		_part(Vector3(-0.11, muzzle_y - length * 0.62, 0), Vector3(0.12, 0.05, 0.035), dark)
	if has_mod("quickload"):
		_part(Vector3(-0.06, muzzle_y - length * 0.78, 0.02), Vector3(0.05, 0.02, 0.012), glow.call(Color(1, .45, .08)))
	if has_mod("piercer"):
		_part(Vector3(0, muzzle_y - 0.02, 0), Vector3(0.05, 0.02, 0.05), glow.call(Color(1, .5, .1)))

func _part(at: Vector3, size: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new();var b := BoxMesh.new();b.size = size;m.mesh = b;m.material_override = mat
	m.position = at;add_child(m)

# Centre of the barrel's mouth in model space: the vertices within 2 % of the model's length
# from its -X end (the muzzle side of every Meshy weapon here), averaged.
static var _mouths := {}
func _barrel_end(model: Node3D, box: AABB) -> Vector3:
	if _mouths.has(kind):return _mouths[kind]
	var limit := box.position.x + box.size.x * 0.02
	var sum := Vector3.ZERO;var count := 0
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = m.mesh
		for surface in mesh.get_surface_count():
			for v in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var p: Vector3 = m.transform * v
				if p.x <= limit:sum += p;count += 1
	var mouth := sum / count if count > 0 else Vector3(box.position.x, box.get_center().y, box.get_center().z)
	_mouths[kind] = mouth
	return mouth

func set_charge(_level: float) -> void:
	pass  # robots call this like the pulse emitter; a gun needs no charge glow

func muzzle() -> Vector3:
	return _muzzle.global_position if _muzzle else global_position

func can_fire() -> bool:
	return ammo > 0 and _cooldown <= 0.0 and not is_reloading()

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if reload_left > 0.0:
		reload_left -= delta
		if reload_left <= 0.0:
			var take := mini(mag_size() - ammo, reserve)
			ammo += take;reserve -= take
			FX.play("block", 1.3, -8.0)
			reloaded.emit()
	_update_laser()

# The laser runs from the muzzle along the barrel to the first thing it meets.
func _update_laser() -> void:
	if _laser == null or not is_inside_tree():return
	var from := muzzle();var dir := global_basis.y.normalized()
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 16.0, 1 | 2)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var to: Vector3 = hit.position if not hit.is_empty() else from + dir * 16.0
	var length := from.distance_to(to)
	_laser.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)).scaled(Vector3(1, length, 1)), (from + to) * 0.5)
	_laser_dot.visible = not hit.is_empty();_laser_dot.global_position = to

## Fires one shot (all pellets) toward `direction`. mask: what bullets hit.
## Returns false when empty or cooling down.
func fire(direction: Vector3, mask: int, shooter: Node, exclude: Array = []) -> bool:
	if not can_fire():return false
	var s := spec()
	_cooldown = s.interval;ammo -= 1
	var origin := muzzle()
	for i in int(s.pellets):
		var cone: float = s.spread * (0.35 if has_mod("laser") else 1.0)
		var spread := deg_to_rad(randf_range(-cone, cone))
		var dir := direction.normalized().rotated(Vector3.BACK, spread)
		var bolt = preload("res://modules/combat/energy_bolt.gd").new()
		get_tree().current_scene.add_child(bolt)
		bolt.lifetime = s.life
		_tint(bolt, s.color, dir)
		var impact := Node.new()
		impact.name = "Impact"
		impact.set_meta("damage", s.damage)
		impact.set_meta("direction", dir)
		impact.set_meta("piercing", has_mod("piercer"))
		impact.set_meta("shooter", weakref(shooter))
		bolt.add_child(impact)
		bolt.impacted.connect(Callable(get_script(), "_resolve_impact").bind(bolt))
		var skip: Array[RID] = [];skip.assign(exclude)
		bolt.launch(origin, dir * s.speed, mask, skip)
		get_tree().create_timer(s.life + 0.1, false).timeout.connect(bolt.queue_free)
	FX.play("hit", 1.9 if kind == "energy_rifle" else 2.4, -8.0)
	FX.impact_light(origin, s.color, 1.8, 0.05, 2.0)
	var scene := get_tree().current_scene
	preload("res://modules/vfx/gun_fx.gd").muzzle_flash(scene, origin, s.color, 0.32 if kind == "scattergun" else 0.22)
	if kind != "energy_rifle":preload("res://modules/vfx/gun_fx.gd").casing(scene, global_position, signf(direction.x))
	if ammo <= 0:
		if reserve > 0:reload()  # dry: straight into a reload
		else:emptied.emit()
	return true

func _tint(bolt: Node3D, color: Color, dir: Vector3) -> void:
	var visual := bolt.get_node_or_null("BoltVisual") as MeshInstance3D
	if visual == null:return
	var mat := visual.material_override.duplicate() as StandardMaterial3D
	mat.albedo_color = color;mat.emission = color;mat.emission_energy_multiplier = 5.0
	visual.material_override = mat
	# A stretched tracer along its flight instead of a ball.
	var streak := CapsuleMesh.new();streak.radius = 0.014;streak.height = 0.5;visual.mesh = streak
	visual.basis = Basis(Quaternion(Vector3.UP, dir.normalized()))

## Projectile-owned: the bolt's handler child carries the shot data and a weak reference to the
## shooter, while this static resolver stays valid after the gun and shooter are freed.
static func _resolve_impact(collider: Object, point: Vector3, normal: Vector3, bolt: Node3D) -> void:
	var impact: Node = bolt.get_node_or_null("Impact") if is_instance_valid(bolt) else null
	if impact == null:
		if is_instance_valid(bolt):bolt.queue_free()
		return
	var scene: Node = bolt.get_tree().current_scene if bolt.is_inside_tree() else null
	var source: WeakRef = impact.get_meta("shooter") as WeakRef
	var shooter: Node = source.get_ref() as Node if source != null else null
	var damage: int = impact.get_meta("damage")
	var direction: Vector3 = impact.get_meta("direction")
	var piercing: bool = impact.get_meta("piercing")
	if is_instance_valid(bolt):bolt.queue_free()
	if collider == null or collider == shooter:return
	if collider.has_method("take_damage"):
		collider.take_damage(damage, point - direction, shooter)  # Rend
	elif collider.has_method("take_melee_hit"):
		collider.take_melee_hit(damage, Vector3(signf(direction.x) * 2.5, 3.0 if piercing else 0.6, 0))  # robots, drones; a piercer hits like a heavy blow
	else:
		FX.metal_contact(point, -direction)
		preload("res://modules/vfx/gun_fx.gd").bullet_hole(scene, point, normal)
