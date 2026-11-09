extends Node
const SAVE_PATH:="user://rendrun_route_v12.json"
const UI_TEXT = preload("res://data/ui_texts.gd")
var menu:Control
var options_menu:Control
var notice:Label
var _starting:=false
var _has_save:=false
func _ready()->void:
	get_tree().paused=false
	Engine.time_scale=1.0
	for flag in ["V12_TEST","V13_TEST","V14_TEST","V15_TEST","H16_TEST","V17_TEST","H19_TEST","V24_TEST","V26_TEST","V28_TEST","V30_TEST","V31_TEST","V33_TEST","V35_TEST","V41_TEST","V44_TEST","V45_TEST","V46_TEST","V47_TEST","V48_TEST","V49_TEST","V50_TEST"]:
		if flag=="V30_TEST" and get_tree().root.has_meta("complete_test_started"):continue
		if OS.get_environment(flag)=="1":
			_enter_game.call_deferred();return
	var layer:=CanvasLayer.new();add_child(layer)
	var background:=ColorRect.new();background.color=Color(0.035,0.045,0.06)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layer.add_child(background)
	menu=preload("res://modules/ui/start_menu.gd").new();layer.add_child(menu)
	options_menu=preload("res://modules/ui/options_menu.gd").new();layer.add_child(options_menu)
	notice=Label.new();notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	notice.offset_left=-400;notice.offset_right=400;notice.offset_top=-70;notice.offset_bottom=-20
	notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_color_override("font_color",Color(1,0.65,0.35));notice.add_theme_font_size_override("font_size",18);layer.add_child(notice)
	menu.continue_requested.connect(_continue_game)
	menu.new_run_requested.connect(_new_run)
	menu.quit_requested.connect(FX.quit_game)
	menu.options_requested.connect(_open_options)
	options_menu.back_requested.connect(_close_options)
	_refresh()
	if OS.get_environment("V29_TEST")=="1" and not get_tree().root.has_meta("start_test_started"):
		get_tree().root.set_meta("start_test_started",true)
		var runner:=preload("res://tests/start_integration_test.gd").new();add_child(runner);runner.call_deferred("run")
func _valid_save()->bool:
	if not FileAccess.file_exists(SAVE_PATH):return false
	var parser:=JSON.new()
	return parser.parse(FileAccess.get_file_as_string(SAVE_PATH))==OK and parser.data is Dictionary and parser.data.get("version")==12
func _refresh()->void:
	var exists:=FileAccess.file_exists(SAVE_PATH)
	_has_save=exists
	menu.open_menu(exists)
	if exists and not _valid_save():
		menu.set_row_enabled("continue",false)
		notice.text=UI_TEXT.t("start_save_unreadable")
func _open_options()->void:
	menu.close_menu()
	options_menu.open_screen()
func _close_options()->void:
	await options_menu.close_screen()
	menu.open_menu(_has_save,"options")
func _continue_game()->void:
	if not _valid_save():_refresh();return
	_enter_game()
func _new_run()->void:
	if _starting:return
	if FileAccess.file_exists(SAVE_PATH):
		if DirAccess.copy_absolute(SAVE_PATH,SAVE_PATH+".previous")!=OK:
			notice.text=UI_TEXT.t("start_backup_failed");return
	if preload("res://modules/persistence/atomic_json_writer.gd").write_json(SAVE_PATH,{"version":12,"economy_revision":1})!=OK:
		notice.text=UI_TEXT.t("start_new_run_save_failed");return
	_enter_game()
func _enter_game()->void:
	if _starting:return
	_starting=true
	for action in preload("res://pause_controller.gd").GAME_ACTIONS:
		if InputMap.has_action(action):Input.action_release(action)
	var error:=get_tree().change_scene_to_file("res://main.tscn")
	if error!=OK:
		_starting=false
		if notice:notice.text=UI_TEXT.t("start_world_load_failed")
