extends SceneTree
# H66 Layout-Probe — echte Control-Geometrie nach Container-Layout bei
# 640x360 und 960x540. SceneTree-Modus: kein get_tree(); await vor Messung.

const TEXT = preload("res://data/route_texts.gd")

var checks := 0
var failures := 0

func _chk(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS " + label)
	else:
		failures += 1
		print("FAIL " + label)

func _count_controls(n: Node) -> int:
	var c := 0
	if n is Control:
		c += 1
	for ch: Node in n.get_children():
		c += _count_controls(ch)
	return c

func _mouse_leaks(n: Node) -> int:
	var bad := 0
	if n is Control and (n as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
		bad += 1
	for ch: Node in n.get_children():
		bad += _mouse_leaks(ch)
	return bad

func _rect(n: Node) -> Rect2:
	return (n as Control).get_global_rect()

# Longest route text whose key starts with prefix (format strings skipped).
func _longest_text(prefix: String) -> String:
	var best := ""
	for k: String in TEXT.keys():
		if not k.begins_with(prefix):
			continue
		var v: String = TEXT.t(k)
		if "%" not in v and v.length() > best.length():
			best = v
	return best

func _initialize() -> void:
	call_deferred("_run_all")

func _run_all() -> void:
	await process_frame
	var hud_script: GDScript = load("res://modules/ui/combat_hud.gd")

	var longest: String = TEXT.t("msg_checkpoint_save_failed")
	var toast := _longest_text("msg_")
	var prompt_probe := _longest_text("prompt_")

	for size_v in [Vector2i(640, 360), Vector2i(960, 540), Vector2i(1280,720)]:
		var sz: Vector2i = size_v
		var tag := "%dx%d" % [sz.x, sz.y]
		root.size = sz
		var hud: Control = hud_script.new()
		root.add_child(hud)
		await process_frame
		await process_frame

		var fb: Label = hud.find_child("FeedbackLabel", true, false) as Label
		_chk(fb != null, tag + ": feedback_label_exists")
		if fb == null:
			hud.queue_free(); continue
		# langster existing combat_hint + initialer Toast
		fb.text = longest
		fb.visible = true
		await process_frame
		var r_fb := _rect(fb)
		print("MEASURE %s fb=%.1f,%.1f %.1fx%.1f" % [tag, r_fb.position.x, r_fb.position.y, r_fb.size.x, r_fb.size.y])
		_chk(is_equal_approx(r_fb.position.y,20.0 if sz.x>=960 else 116.0), tag + ": adaptive_feedback_lane")
		_chk(r_fb.end.x <= float(sz.x) - 4.0 and r_fb.position.x >= 4.0, tag + ": fb_inside_viewport_x")
		_chk(r_fb.position.y >= 0.0 and r_fb.end.y <= float(sz.y) - 4.0, tag + ": fb_inside_viewport_y")
		_chk(r_fb.end.y < float(sz.y)*0.55, tag + ": feedback_avoids_combat_lane")

		# keine Ueberlappung mit StatusPanel (HP/Gear) und Zonen-Zaehler
		var sp: Node = hud.find_child("StatusPanel", true, false)
		var zr: Node = hud.find_child("ZoneLabel", true, false)
		if sp != null:
			var r_sp := _rect(sp)
			_chk(not r_fb.intersects(r_sp.grow(1.0)), tag + ": fb_no_overlap_status")
			# StatusPanel endet unter der Feedback-Spur (H25-Budget 115px)
			_chk(r_sp.end.y <= 116.0 + 1.0, tag + ": statuspanel_ends_by_116")
		if zr != null:
			var r_zr := _rect(zr)
			_chk(not r_fb.intersects(r_zr.grow(1.0)), tag + ": fb_no_overlap_zone")

		# Toast-Laenge passt ohne Trunkierung (Label zeigt vollen Text)
		fb.text = toast
		await process_frame
		_chk(fb.text == toast, tag + ": toast_text_not_truncated")
		var r_to := _rect(fb)
		_chk(r_to.end.x <= float(sz.x) - 4.0 and r_to.position.y >= 0.0, tag + ": toast_in_lane")

		# Prompt bleibt im unteren Container (y > Mitte), Feedback nicht mehr dort
		var pr: Label = hud.find_child("PromptLabel", true, false) as Label
		_chk(pr != null, tag + ": prompt_exists")
		if pr != null:
			pr.text = prompt_probe
			pr.visible = true
			await process_frame
			var r_pr := _rect(pr)
			_chk(r_pr.position.y > float(sz.y) * 0.5, tag + ": prompt_stays_lower")
			_chk(not r_fb.intersects(r_pr.grow(1.0)), tag + ": fb_no_overlap_prompt")
			pr.visible = false

		# Update-Aufruf laeuft unveraendert und ohne Knotenwachstum
		var before := _count_controls(hud)
		hud.call("update_state", {"hp": 2, "max_hp": 3, "feedback": longest, "prompt": "E"})
		await process_frame
		_chk(_count_controls(hud) == before, tag + ": no_node_growth_updates")

		var footer=hud.find_child("HelpFooter",true,false) as Control
		_chk(footer!=null and Rect2(Vector2.ZERO,Vector2(sz)).encloses(footer.get_global_rect()),tag+": footer_inside_viewport")
		var objective=hud.find_child("ObjectiveLabel",true,false) as Control
		_chk(not footer.get_global_rect().intersects(objective.get_global_rect()),tag+": footer_separate_from_objective")

		# mouse IGNORE auf allen Controls
		_chk(_mouse_leaks(hud) == 0, tag + ": all_mouse_ignore")
		hud.queue_free()
		await process_frame

	print("SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)
