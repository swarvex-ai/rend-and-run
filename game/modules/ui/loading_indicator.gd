extends CanvasLayer
## Full-screen loading indicator for scene transitions and checkpoint reloads.
## Shows dark ColorRect background and animated "LOADING..." label in Inter font.

const UI_TEXT = preload("res://data/ui_texts.gd")
const FONT_INTER_PATH := "res://assets/fonts/inter/Inter-Variable.ttf"
const FONT_AXIS_WEIGHT := 0x77676874

var _base_text := ""
var _dots_timer := 0.0
var _dots_count := 0
var _label: Label
var _bg: ColorRect

func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_bg = ColorRect.new()
	_bg.name = "Background"
	_bg.color = Color(0.035, 0.045, 0.06)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	_label = Label.new()
	_label.name = "LoadingLabel"
	_base_text = UI_TEXT.t("loading")
	_label.text = _base_text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_font_size_override("font_size", 36)
	_label.add_theme_color_override("font_color", Color("CAD5CF"))

	var inter: FontFile = load(FONT_INTER_PATH) as FontFile
	if inter != null:
		var font := FontVariation.new()
		font.base_font = inter
		font.variation_opentype = {FONT_AXIS_WEIGHT: 600}
		_label.add_theme_font_override("font", font)

	add_child(_label)

func _process(delta: float) -> void:
	_dots_timer += delta
	if _dots_timer >= 0.35:
		_dots_timer -= 0.35
		_dots_count = (_dots_count + 1) % 4
		_label.text = _base_text + ".".repeat(_dots_count)

static func show_on(host: Node) -> Node:
	var indicator = new()
	host.add_child(indicator)
	return indicator

func hide_now() -> void:
	queue_free()
