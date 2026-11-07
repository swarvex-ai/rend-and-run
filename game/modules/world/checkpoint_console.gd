extends Node3D
## H38 — Wiederverwendbare Checkpoint-Konsole (rein visuell).
## Ersetzt die statische Box+Teal-Screen-Darstellung des Checkpoints durch ein
## Modul mit deutlichem gespeichert/ungespeichert/Fehler-Feedback.
##
## Vertrag (H38):
## - Origin Fussohlen, Masse ca. 0.75 x 1.3 x 0.45 m, Front +Z.
## - Keine Physik, keine Lichter, kein Save-/Gameplay-Code, keine Eingaben.
## - set_saved(bool) funktioniert VOR und NACH dem Eintritt in den Baum.
## - flash_result(success) = kurzer <=0.7s Bildschirm-Puls, danach Rueckkehr zum
##   aktuellen Saved-Zustand; wiederholte Aufrufe ersetzen den laufenden Puls;
##   free-safe. Fehler ROT und niemals falschlich als gespeichert gezeigt.
## - Genau 1 Label3D mit Kurzlabel aus der Text-Tabelle (checkpoint_ready/_saved/_error).
## - Im Leerlauf keine Per-Frame-Updates (kein _process): Puls traegt ein
##   OneShot-Timer-Kind und endet von selbst.
## - <=16 Mesh-Surfaces, geteilte Materialien.
##
## Der Speichерstatus ist DATENGETRIEBEN: Codex ruft set_saved() nach dem
## echten Speichern; das Modul liest/schreibt keine Saetze und feuert keine
## Gameplay-Kommandos.

var UI_TEXT = load("res://data/ui_texts.gd")

const W := 0.75
const H := 1.3
const D := 0.45
const PULSE_S := 0.6  # <= 0.7 s Vertragsfenster

const C_BODY := Color(0.12, 0.20, 0.23)
const C_SCREEN_DARK := Color(0.06, 0.13, 0.15)
const C_TEAL := Color(0.25, 0.90, 0.85)
const C_AMBER := Color(1.00, 0.62, 0.10)
const C_RED := Color(0.95, 0.18, 0.14)

var saved: bool = false

var _screen_mat: StandardMaterial3D
var _body_mat: StandardMaterial3D
var _amber_mat: StandardMaterial3D
var _teal_mat: StandardMaterial3D

var _screen: MeshInstance3D
var _dot: MeshInstance3D        # amber, ungespeichert
var _check_a: MeshInstance3D    # teal-Haarken, gespeichert
var _check_b: MeshInstance3D
var _label: Label3D
var _pulse_timer: Timer
var _pulse: String = ""         # "" | "ok" | "fail"
var _pulse_gen: int = 0


func _init() -> void:
	_body_mat = _mat(C_BODY, Color(0, 0, 0))
	_screen_mat = _mat(C_SCREEN_DARK, C_SCREEN_DARK * 0.35)
	_amber_mat = _mat(C_AMBER, C_AMBER * 0.7)
	_teal_mat = _mat(C_TEAL, C_TEAL * 0.7)

	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(W, H, D)
	body.mesh = bm
	body.material_override = _body_mat
	body.position = Vector3(0, H * 0.5, 0)   # Ursprung = Fussohlen
	add_child(body)

	# Pultkante als Wiedererkennungsmerkmal (nutzt Koenper-Material erneut).
	var lip := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(W, 0.06, D + 0.04)
	lip.mesh = lm
	lip.material_override = _body_mat
	lip.position = Vector3(0, H * 0.72, 0.02)
	add_child(lip)

	_screen = MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.62, 0.38, 0.02)
	_screen.mesh = sm
	_screen.material_override = _screen_mat
	_screen.position = Vector3(0, H * 0.8, D * 0.5 + 0.005)  # Front +Z
	add_child(_screen)

	# Ungespeichert: AMBER-Punkt (Form: Kreis/Kugel).
	_dot = MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 0.045
	dm.height = 0.09
	_dot.mesh = dm
	_dot.material_override = _amber_mat
	_dot.position = Vector3(0, H * 0.8, D * 0.5 + 0.03)
	add_child(_dot)

	# Gespeichert: TEAL-Haaken aus zwei Duennen Balken (Form unterscheidet
	# auch ohne Farbe fuer farbfehlsichtige Lesbarkeit des Indicatorenbilds).
	_check_a = _check_bar(0.17, -40.0)
	_check_a.position+=Vector3(-0.065,-0.035,0)
	_check_b = _check_bar(0.27, 54.0)
	_check_b.position+=Vector3(0.08,0.02,0)

	_label = Label3D.new()
	_label.text = UI_TEXT.t("checkpoint_ready")
	_label.font_size = 32
	_label.pixel_size = 0.0038
	_label.outline_size = 8
	_label.position = Vector3(0, H + 0.55, 0.0)
	_label.visible = false  # no floating world text; the console lights show its state
	add_child(_label)

	_apply_base()


func _check_bar(bar_len: float, rot_deg: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(bar_len, 0.045, 0.045)
	m.mesh = bm
	m.material_override = _teal_mat
	m.position = Vector3(0, H * 0.8, D * 0.5 + 0.03)
	m.rotation_degrees = Vector3(0, 0, rot_deg)
	add_child(m)
	return m


func _mat(albedo: Color, emission: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.emission_enabled = true
	m.emission = emission
	m.roughness = 0.6
	return m


## Datengetriebener Zustand: true = Checkpunkt ist gespeichert.
## Vor und nach _ready aufrufbar (Aufbau geschieht in _init).
func set_saved(value: bool) -> void:
	saved = value
	if _pulse == "":
		_apply_base()


## Kurzer Feedback-Puls (<=0.7s): success = heller Teal-Puls, Fehler = ROT.
## Danach Rueckkehr zum aktuellen Saved-Zustand. Wiederholte Aufrufe ersetzen
## den laufenden Puls. Ein Erfolgspuls speichert NICHT (Saved bleibt
## Daten-getrieben via set_saved).
func flash_result(success: bool) -> void:
	_pulse_gen += 1
	_apply_base()
	if success:
		_pulse = "ok"
		_set_screen(C_TEAL, C_TEAL)
	else:
		_pulse = "fail"
		_set_screen(C_RED, C_RED * 0.9)
		_label.text = UI_TEXT.t("checkpoint_error")
		_label.modulate = C_RED
	if _pulse_timer == null:
		_pulse_timer = Timer.new()
		_pulse_timer.one_shot = true
		_pulse_timer.timeout.connect(_on_pulse_done)
		add_child(_pulse_timer)
	_pulse_timer.stop()
	_pulse_timer.wait_time = PULSE_S
	_pulse_timer.start()


func _on_pulse_done() -> void:
	# Stale-Pulse ignorieren (wurde durch neuen Aufruf ersetzt).
	if _pulse_gen == 0:
		return
	_pulse = ""
	_apply_base()


func _apply_base() -> void:
	if saved:
		_dot.visible = false
		_check_a.visible = true
		_check_b.visible = true
		_label.text = UI_TEXT.t("checkpoint_saved")
		_set_screen(C_SCREEN_DARK, C_TEAL * 0.25)
	else:
		_dot.visible = true
		_check_a.visible = false
		_check_b.visible = false
		_label.text = UI_TEXT.t("checkpoint_ready")
		_set_screen(C_SCREEN_DARK, C_SCREEN_DARK * 0.35)
	_label.modulate = Color(1, 1, 1)


func _set_screen(albedo: Color, emission: Color) -> void:
	_screen_mat.albedo_color = albedo
	_screen_mat.emission = emission


## Nur-Lese-Helfer fuer Vorherschaue- und State-Checks; keine Aktion.
func get_state_snapshot() -> Dictionary:
	return {"saved": saved, "pulse": _pulse, "label": _label.text,
		"pulse_window_s": PULSE_S}


func _exit_tree() -> void:
	if _pulse_timer != null:
		_pulse_timer.stop()
