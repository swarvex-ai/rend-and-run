extends Control
## Ammo readout, bottom right, while a firearm is drawn: gun name and mods, rounds in the
## magazine over the reserve, one pip per round, a reload bar. Low magazine pulses amber,
## an empty one red with the reload key. Palette as combat_hud.gd (off-white / pale cyan).

const OFF_WHITE := Color(0.93, 0.95, 0.96)
const CYAN := Color(0.62, 0.86, 0.92)
const AMBER := Color(1.0, 0.62, 0.2)
const RED := Color(1.0, 0.25, 0.18)
const WIDTH := 300.0
const HEIGHT := 112.0

var player: Node
var _t := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player) or not is_instance_valid(player.gun):return
	var gun: Node = player.gun
	var font := ThemeDB.fallback_font
	var origin := Vector2(size.x - WIDTH - 28.0, size.y - HEIGHT - 150.0)
	draw_rect(Rect2(origin, Vector2(WIDTH, HEIGHT)), Color(0.03, 0.05, 0.06, 0.72))
	draw_rect(Rect2(origin, Vector2(4, HEIGHT)), CYAN)
	var mods: Array = gun.mods.map(func(m): return gun.mod_label(m))
	draw_string(font, origin + Vector2(16, 24), gun.label().to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, CYAN)
	if not mods.is_empty():
		draw_string(font, origin + Vector2(16, 42), " · ".join(mods), HORIZONTAL_ALIGNMENT_LEFT, WIDTH - 24, 11, Color(CYAN, 0.7))
	var mag: int = gun.mag_size()
	var colour := OFF_WHITE
	var pulse := 0.6 + 0.4 * sin(_t * 9.0)
	if gun.ammo == 0:colour = Color(RED, pulse)
	elif gun.ammo <= maxi(1, mag / 4):colour = Color(AMBER, pulse)
	var count := "%d" % gun.ammo
	draw_string(font, origin + Vector2(16, 92), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, colour)
	var count_w := font.get_string_size(count, HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x
	draw_string(font, origin + Vector2(22 + count_w, 92), "/ %d" % gun.reserve, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(OFF_WHITE, 0.6) if gun.reserve > 0 else RED)
	# Pips: one per round, two rows for big magazines.
	var pips_x := origin.x + 150.0
	var per_row := mini(mag, 23)
	var pip_w := minf(6.0, (WIDTH - 162.0) / per_row - 1.5)
	for i in mag:
		var row := i / per_row
		var col := i % per_row
		var at := Vector2(pips_x + col * (pip_w + 1.5), origin.y + 62 + row * 14)
		draw_rect(Rect2(at, Vector2(pip_w, 11)), OFF_WHITE if i < gun.ammo else Color(OFF_WHITE, 0.15))
	if gun.is_reloading():
		var bar := Rect2(origin + Vector2(16, HEIGHT - 12), Vector2(WIDTH - 32, 4))
		draw_rect(bar, Color(CYAN, 0.2))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * gun.reload_progress(), bar.size.y)), CYAN)
		draw_string(font, origin + Vector2(WIDTH - 120, 24), "NACHLADEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CYAN)
	elif gun.ammo == 0 and gun.reserve > 0:
		draw_string(font, origin + Vector2(WIDTH - 120, 24), "R — LADEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(RED, pulse))
	elif gun.ammo < mag and gun.reserve > 0:
		draw_string(font, origin + Vector2(WIDTH - 60, 24), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(OFF_WHITE, 0.45))
