class_name ComicPlayer extends Control
## ComicPlayer: plays the intro comic, one panel at a time, full-frame 16:9.
## Panels and their texts come from res://data/comic_intro.gd. While the real
## art is missing each panel shows a flat #11151E plate with its number and
## caption, so the flow can be tested today. Real art is picked up automatically
## as soon as the image files exist. Not skippable by default; set skippable =
## true to allow Esc, Enter, Space or gamepad A to skip to the end.
## The widget owns its timing (delta based, never frame counts) and emits
## finished exactly once after the last panel.

signal finished

const BG_COLOR := Color("11151E")
const BOX_FILL := Color("CAD5CF")
const BOX_BORDER := Color("11151E")
const TEXT_COLOR := Color("11151E")
const FONT_PATH := "res://assets/fonts/inter/Inter-Variable.ttf"
const FONT_AXIS_WEIGHT := 0x77676874
const FONT_SIZE := 28
const BORDER_PX := 4
const PADDING_PX := 24
const MARGIN_PX := 48

var skippable := false

var _art: TextureRect
var _backdrop: ColorRect
var _captions: VBoxContainer
var _comic_intro
var _font: Font
var _panel_index := -1
var _panel_timer := 0.0
var _finished := false

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.color = BG_COLOR
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)

	_art = TextureRect.new()
	_art.name = "Art"
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)

	_captions = VBoxContainer.new()
	_captions.name = "Captions"
	_captions.add_theme_constant_override("separation", 6)
	add_child(_captions)

	var inter: FontFile = load(FONT_PATH) as FontFile
	if inter != null:
		_font = FontVariation.new()
		_font.base_font = inter
		_font.variation_opentype = {FONT_AXIS_WEIGHT: FONT_AXIS_WEIGHT}

func start() -> void:
	var comic := load("res://data/comic_intro.gd")
	if comic == null:
		push_warning("ComicPlayer: could not load res://data/comic_intro.gd")
		_finished = true
		finished.emit()
		return
	_comic_intro = comic
	var panels: Array = _comic_intro.PANELS
	if panels.is_empty():
		push_warning("ComicPlayer: comic_intro.gd has no panels")
		_finished = true
		finished.emit()
		return
	_finished = false
	_panel_index = 0
	_panel_timer = 0.0
	visible = true
	set_process(true)
	_show_panel(0)

func current_panel() -> int:
	return _panel_index

func _show_panel(index: int) -> void:
	var panels: Array = _comic_intro.PANELS
	var panel: Dictionary = panels[index]
	var tex: Texture2D = _load_art(panel["art"])
	_art.texture = tex
	var lines: Array[String] = []
	if tex == null:
		lines.append("Panel %d" % [index + 1])
	var caption: String = panel["caption"]
	if caption != "":
		lines.append(caption)
	var pa: String = panel["pa"]
	if pa != "":
		lines.append(pa)
	var children := _captions.get_children().duplicate()
	for child in children:
		child.queue_free()
	var w := size.x - MARGIN_PX * 2.0
	if w < 0.0:
		w = 0.0
	for line in lines:
		var box: PanelContainer = _caption_box(line)
		box.custom_minimum_size.x = w
		_captions.add_child(box)
	call_deferred("_layout")

func _load_art(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is Texture2D:
		return res
	if res is Image:
		return ImageTexture.create_from_image(res)
	return null

func _caption_box(text: String) -> PanelContainer:
	var box: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = BOX_FILL
	style.border_color = BOX_BORDER
	style.set_border_width_all(BORDER_PX)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(PADDING_PX)
	box.add_theme_stylebox_override("panel", style)
	var label: Label = Label.new()
	label.text = text
	label.name = "CaptionLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	if _font != null:
		label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	box.add_child(label)
	return box

func _layout() -> void:
	var margin := float(MARGIN_PX)
	var stack_h := _captions.size.y
	var y := size.y - margin - stack_h
	if y < margin:
		y = margin
	_captions.position = Vector2(margin, y)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		var w := size.x - MARGIN_PX * 2.0
		if w < 0.0:
			w = 0.0
		for child in _captions.get_children():
			child.custom_minimum_size.x = w
		call_deferred("_layout")

func _process(delta: float) -> void:
	if _finished or _panel_index < 0:
		return
	var panels: Array = _comic_intro.PANELS
	_panel_timer += delta
	var dur: float = panels[_panel_index]["duration_s"]
	if _panel_timer < dur:
		return
	_panel_timer = 0.0
	if _panel_index >= panels.size() - 1:
		_finished = true
		set_process(false)
		finished.emit()
	else:
		_panel_index += 1
		_show_panel(_panel_index)

func _finish() -> void:
	if _finished:
		return
	var panels: Array = _comic_intro.PANELS
	if panels.is_empty():
		return
	_finished = true
	set_process(false)
	_panel_index = panels.size() - 1
	_show_panel(_panel_index)
	finished.emit()

func _input(event: InputEvent) -> void:
	if not skippable or _finished:
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed:
			match key.keycode:
				KEY_ESCAPE:
					_finish()
				KEY_ENTER:
					_finish()
				KEY_SPACE:
					_finish()
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.pressed:
			_finish()
	elif event is InputEventJoypadButton:
		var pad: InputEventJoypadButton = event as InputEventJoypadButton
		if pad.pressed and pad.button_index == JOY_BUTTON_A:
			_finish()
