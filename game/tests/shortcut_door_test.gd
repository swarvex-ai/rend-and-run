extends SceneTree
# H16 — Headless-Test fuer shortcut_door.gd (Standalone Node3D).
# Aufruf: godot --headless --path <isolierter-scratch> --script res://tests/shortcut_door_test.gd
# Exit-Code 0 = alle Checks PASS, 1 = mindestens ein FAIL.

const DOOR_SCRIPT := preload("res://modules/world/shortcut_door.gd")

var checks := 0
var failures := 0

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("H16 %s %s" % ["PASS" if ok else "FAIL", label])

func fresh_door(reversed_side: bool = false) -> Node3D:
	var d: Node3D = DOOR_SCRIPT.new()
	d.unlock_from_positive_x = not reversed_side
	root.add_child(d)
	return d

func door_with_events(events: Array) -> Node3D:
	var d: Node3D = fresh_door()
	d.opened.connect(func(id: String) -> void: events.append(id))
	return d

# Kollision: Body-global AABB-Unterkante (Fuss der Tafel) in Welt-Y.
func body_bottom_y(d: Node3D) -> float:
	var body: Node = d.get_body()
	var shape := body.get_child(0) as CollisionShape3D
	return shape.global_transform.origin.y - 1.4

func _initialize() -> void:
	# Im SceneTree-Skriptmodus werden Kinder erst ab Frame 1 'inside tree'
	# (wie H13): erst await, dann Nodes anlegen und prüfen.
	await process_frame

	# --- 1) Defaultzustand ------------------------------------------------------
	var d := fresh_door()
	check("defaults closed, no movement, body solid",
		not d.is_open() and is_zero_approx(d.panel_offset_y())
		and d.get_body().collision_layer == 1 and d.get_body().collision_mask == 4)

	# --- 2) Falsche Seite blockiert, ohne alles zu veraendern --------------------
	var events: Array[String] = []
	d = door_with_events(events)
	check("wrong side (-X bei positiver Freigabe) -> false ohne Oeffnung",
		not d.try_open(Vector3(-0.5, 1.0, 0.0)) and not d.is_open()
		and events.is_empty() and is_zero_approx(d.panel_offset_y())
		and d.get_body().collision_layer == 1)

	# --- 3) Richtige Seite oeffnet einmalig mit Signal ---------------------------
	check("right side -> true, opened(shortcut) genau einmal",
		d.try_open(Vector3(0.5, 1.0, 0.0)) and d.is_open()
		and events == ["shortcut"])
	# --- 4) Wiederholte Aufrufe solange offen: true, kein weiteres Event ---------
	check("repeat while open -> true ohne neues Event",
		d.try_open(Vector3(0.5, 1.0, 0.0)) and events.size() == 1)
	# auch von der verbotenen Seite: Vorbedingung erfuellt nicht -> false, offen bleibt offen
	check("wrong side while open -> false ohne Aenderung (Vorbedingung zuerst)",
		not d.try_open(Vector3(-0.5, 1.0, 0.0)) and d.is_open() and events.size() == 1)

	# --- 5) Zonen-Grenzen X (Seite + Nahzone), je drin/draussen ------------------
	d = fresh_door()
	check("X=0.29 zu nah an der Ebene -> false", not d.try_open(Vector3(0.29, 1.0, 0.0)))
	check("X=0.3 exakte Toleranz -> true", d.try_open(Vector3(0.3, 1.0, 0.0)))
	d = fresh_door()
	check("X=1.6 ausserste Tiefe -> true", d.try_open(Vector3(1.6, 1.0, 0.0)))
	d = fresh_door()
	check("X=1.61 zu weit -> false, bleibt zu",
		not d.try_open(Vector3(1.61, 1.0, 0.0)) and not d.is_open()
		and d.get_body().collision_layer == 1)

	# --- 6) Höhen- und Breiten-Grenzen ------------------------------------------
	d = fresh_door()
	check("Y=1.0 noch drin -> true", d.try_open(Vector3(0.5, 1.0, 0.0)))
	d = fresh_door()
	check("Y=1.01 zu hoch -> false", not d.try_open(Vector3(0.5, 1.01, 0.0)))
	d = fresh_door()
	check("Z=0.8 noch drin -> true", d.try_open(Vector3(0.5, 1.0, 0.8)))
	d = fresh_door()
	check("Z=-0.8 exakte andere Seite drin -> true", d.try_open(Vector3(0.5, 1.0, -0.8)))
	d = fresh_door()
	check("Z=0.81 zu breit -> false", not d.try_open(Vector3(0.5, 1.0, 0.81)))

	# --- 7) Umgekehrte Freigaberichtung ------------------------------------------
	d = fresh_door(true)
	check("reversed: +X-Seite abgewiesen", not d.try_open(Vector3(0.5, 1.0, 0.0)))
	check("reversed: -X-Seite oeffnet", d.try_open(Vector3(-0.5, 1.0, 0.0)) and d.is_open())

	# --- 8) Kollision wird deferred deaktiviert -----------------------------------
	d = fresh_door()
	d.try_open(Vector3(0.5, 1.0, 0.0))
	check("Kollision im selben Frame noch aktiv (deferred)",
		d.get_body().collision_layer == 1)
	await process_frame
	check("nach 1 Frame: Kollisionslayer deaktiviert",
		d.get_body().collision_layer == 0)

	# --- 9) Tafel faehrt hoch und raeumt die Tuerebene -----------------------------
	check("während des Tweens: Tafel zwischen 0 und 3 m",
		d.panel_offset_y() > 0.001 and d.panel_offset_y() < 2.999)
	await create_timer(0.4, true).timeout
	check("nach 0.4s: Hub 3.0 m erreicht", absf(d.panel_offset_y() - 3.0) < 0.001)
	check("Tafel-Body-AABB-Unterkante ueber Tuerhoehe 2.8 m (Tordurchgang frei)",
		body_bottom_y(d) > 2.8)

	# --- 10) restore_open(true) VOR Ready: Pose/Zustand sofort, kein Event ---------
	events = []
	var cold: Node3D = DOOR_SCRIPT.new()
	cold.opened.connect(func(id: String) -> void: events.append(id))
	cold.restore_open(true)
	check("restore(true) vor ready: offen, Pose 3.0, Layer 0, kein Event",
		cold.is_open() and absf(cold.panel_offset_y() - 3.0) < 0.001
		and cold.get_body().collision_layer == 0 and events.is_empty())
	root.add_child(cold)
	await process_frame
	check("restore(true) haelt nach Tree-Entry (kein Reset)",
		cold.is_open() and absf(cold.panel_offset_y() - 3.0) < 0.001
		and cold.get_body().collision_layer == 0 and events.is_empty())
	check("restore(true) unterdrueckt kuenftiges opened bei try_open",
		cold.try_open(Vector3(0.5, 1.0, 0.0)) and events.is_empty())

	# --- 11) restore_open(true) NACH Oeffnung: kein Event, offen bleibt offen ------
	events = []
	d = door_with_events(events)
	d.try_open(Vector3(0.5, 1.0, 0.0))
	d.restore_open(true)
	check("restore(true) nach Oeffnung: kein zweites Event",
		events == ["shortcut"] and d.is_open())

	# --- 12) restore_open(false) setzt zurueck und erlaubt frische Oeffnung --------
	d.restore_open(false)
	check("restore(false): zu, Pose 0, Layer 1 sofort",
		not d.is_open() and is_zero_approx(d.panel_offset_y())
		and d.get_body().collision_layer == 1)
	check("frische Oeffnung nach restore(false) mit erneutem Event",
		d.try_open(Vector3(0.5, 1.0, 0.0)) and d.is_open()
		and events == ["shortcut", "shortcut"])

	# --- 13) restore_open WAHREND des Tweens kappt den Tween -----------------------
	d = fresh_door()
	d.try_open(Vector3(0.5, 1.0, 0.0))
	await process_frame
	d.restore_open(false)
	var mid_y: float = d.panel_offset_y()
	await create_timer(0.4, true).timeout
	check("restore(false) im Tween: Tween tot, Pose bleibt 0",
		is_zero_approx(mid_y) and is_zero_approx(d.panel_offset_y()))
	d = fresh_door()
	d.try_open(Vector3(0.5, 1.0, 0.0))
	await process_frame
	d.restore_open(true)
	check("restore(true) im Tween: sofort 3.0", absf(d.panel_offset_y() - 3.0) < 0.001)
	await create_timer(0.4, true).timeout
	check("nach Tween-Ablauf (gekappt): Pose haelt 3.0",
		absf(d.panel_offset_y() - 3.0) < 0.001)

	# --- 14) Übersetzter Root: try_open arbeitet in lokalen Koordinaten ------------
	var moved: Node3D = DOOR_SCRIPT.new()
	moved.position = Vector3(10.0, 0.0, 5.0)
	root.add_child(moved)
	check("verschobener Root: Welt(+0.5 relativ) oeffnet",
		moved.try_open(Vector3(10.5, 1.0, 5.0)) and moved.is_open())
	var moved2: Node3D = DOOR_SCRIPT.new()
	moved2.position = Vector3(10.0, 0.0, 5.0)
	root.add_child(moved2)
	check("verschobener Root: Welt(-0.5 relativ) bleibt falsche Seite",
		not moved2.try_open(Vector3(9.5, 1.0, 5.0)) and not moved2.is_open())

	# --- 15) Rotierter Root (90° um Y): lokale Achse folgt der Rotation ------------
	var rot: Node3D = DOOR_SCRIPT.new()
	rot.position = Vector3(4.0, 0.0, 2.0)
	rot.rotation.y = deg_to_rad(90.0)
	root.add_child(rot)
	# RotY(90°): lokal +X zeigt nach Welt -Z. Akteur 0.5 m in Welt -Z relativ.
	check("rotierter Root: 0.5 m entlang Welt -Z oeffnet",
		rot.try_open(Vector3(4.0, 1.0, 1.5)) and rot.is_open())
	var rot2: Node3D = DOOR_SCRIPT.new()
	rot2.position = Vector3(4.0, 0.0, 2.0)
	rot2.rotation.y = deg_to_rad(90.0)
	root.add_child(rot2)
	check("rotierter Root: 0.5 m entlang Welt +Z ist falsche Seite",
		not rot2.try_open(Vector3(4.0, 1.0, 2.5)) and not rot2.is_open())

	# --- 16) Riegel kameraseitig +Z (Codex-Korrektur) ----------------------------
	d = fresh_door()
	var latch: Node3D = d.get_panel().get_child(3)
	check("Riegel sitzt kameraseitig +Z (z nahe 1.0, nicht Mittig z=0)",
		latch.global_position.z > 0.85 and absf(latch.global_position.x) < 0.001)

	# --- 17) Instanzunabhaengigkeit + eigene Ressourcen ----------------------------
	var a := fresh_door()
	var b := fresh_door()
	a.try_open(Vector3(0.5, 1.0, 0.0))
	check("zweite Instanz bleibt zu und fest",
		not b.is_open() and is_zero_approx(b.panel_offset_y())
		and b.get_body().collision_layer == 1)
	check("eigene Kollisions-Ressource pro Instanz",
		a.get_body().get_child(0).shape != b.get_body().get_child(0).shape)
	var a_panel: Node = a.get_panel()
	var b_panel: Node = b.get_panel()
	# Panel-Reihenfolge: child0 = StaticBody3D, child1 = Stahltafel.
	check("eigene Mesh-/Material-Ressourcen pro Instanz",
		a_panel.get_child(1).mesh != b_panel.get_child(1).mesh
		and a_panel.get_child(1).material_override != b_panel.get_child(1).material_override)

	print("H16 SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
