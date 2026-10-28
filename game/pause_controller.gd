extends Node
var menu:Control
var summary:Control
var shop:Control
var equipment_menu:Control
var _leaving:=false
var _resume_pending:=false
const GAME_ACTIONS:=["move_left","move_right","move_up","move_down","jump","attack","dash","dodge","crouch","guard","interact","restart"]
func _ready()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var layer:=CanvasLayer.new();layer.layer=20;add_child(layer)
	menu=preload("res://modules/ui/pause_menu.gd").new();layer.add_child(menu)
	shop=preload("res://modules/ui/workbench_menu.gd").new();layer.add_child(shop)
	equipment_menu=preload("res://modules/ui/equipment_menu.gd").new();layer.add_child(equipment_menu)
	equipment_menu.close_requested.connect(resume)
	equipment_menu.selection_requested.connect(_equipment_action)
	shop.close_requested.connect(resume)
	shop.action_requested.connect(_shop_action)
	summary=preload("res://modules/ui/sector_complete.gd").new();layer.add_child(summary)
	summary.explore_requested.connect(resume)
	summary.title_requested.connect(return_title)
	menu.resume_requested.connect(resume)
	menu.restart_requested.connect(restart)
	menu.quit_requested.connect(quit_game)
func _input(event:InputEvent)->void:
	var active_panel:Control=equipment_menu if equipment_menu.visible else shop
	if active_panel.visible:
		var cancel:bool=(event is InputEventKey and event.physical_keycode==KEY_ESCAPE and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_B,JOY_BUTTON_START] and event.pressed)
		if cancel:
			resume()
			get_viewport().set_input_as_handled()
		elif event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN] and event.pressed:
			active_panel.move_selection(-1 if event.button_index==JOY_BUTTON_DPAD_UP else 1)
			get_viewport().set_input_as_handled()
		elif event is InputEventJoypadButton and event.button_index==JOY_BUTTON_A and event.pressed:
			var focused:=get_viewport().gui_get_focus_owner()
			if focused is Button and active_panel.is_ancestor_of(focused) and not focused.disabled:
				focused.pressed.emit()
			get_viewport().set_input_as_handled()
		return
	var inventory:bool=(event is InputEventKey and event.physical_keycode==KEY_I and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.button_index==JOY_BUTTON_BACK and event.pressed)
	if inventory:
		open_equipment();get_viewport().set_input_as_handled();return
	var toggle:bool=(event is InputEventKey and event.physical_keycode==KEY_ESCAPE and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.button_index==JOY_BUTTON_START and event.pressed)
	if toggle:
		if menu.visible or summary.visible:resume()
		else:open_menu()
		get_viewport().set_input_as_handled()
func _release_inputs()->void:
	for action in GAME_ACTIONS:
		if InputMap.has_action(action):Input.action_release(action)
func open_menu()->void:
	if _leaving or _resume_pending:return
	_release_inputs()
	shop.close_menu()
	equipment_menu.close_menu()
	get_tree().paused=true
	menu.open_menu()
func resume()->void:
	if _leaving or _resume_pending:return
	var was_shop_open:bool=shop.visible or equipment_menu.visible
	_release_inputs()
	menu.close_menu()
	shop.close_menu()
	equipment_menu.close_menu()
	summary.close_summary()
	var focused:=get_viewport().gui_get_focus_owner()
	if focused:focused.release_focus()
	if was_shop_open:
		_resume_pending=true
		# Let the cancel/accept edge expire in the physics input clock before the
		# player's is_action_just_pressed can interpret B as dodge or A as jump.
		await get_tree().physics_frame
		await get_tree().physics_frame
		_release_inputs()
		# Unpause after the physics-frame notification has finished dispatching.
		# Re-registering newly equipped visuals inside it can double-add engine lists.
		call_deferred("_finish_shop_resume")
		return
	get_tree().paused=false

func _finish_shop_resume()->void:
	_resume_pending=false
	if not _leaving:get_tree().paused=false
func request_restart()->void:
	open_menu()
	menu._on_restart()
func restart()->void:
	if _leaving:return
	_leaving=true
	_release_inputs();get_tree().paused=false
	Engine.time_scale=1.0
	get_tree().reload_current_scene()
func quit_game()->void:
	if _leaving:return
	_leaving=true
	_release_inputs();get_tree().paused=false
	FX.quit_game()

func show_completion(state:Dictionary)->void:
	if _leaving:return
	_release_inputs();menu.close_menu()
	get_tree().paused=true
	summary.show_summary(state)
func return_title()->void:
	if _leaving:return
	_leaving=true
	_release_inputs();get_tree().paused=false;Engine.time_scale=1.0
	get_tree().change_scene_to_file("res://start.tscn")

func open_shop(state:Dictionary)->void:
	if _leaving or _resume_pending or menu.visible or summary.visible:return
	_release_inputs()
	get_tree().paused=true
	shop.open_menu(state)

func _shop_action(id:String)->void:
	if _leaving or not shop.visible:return
	get_parent().route.apply_workbench_action(id)

func open_equipment()->void:
	if _leaving or _resume_pending or menu.visible or summary.visible or shop.visible:return
	var p=get_parent().player
	if p._dying or p._attack_phase>0 or p._dash_left>0 or p.guard.is_guarding():return
	_release_inputs();get_tree().paused=true
	equipment_menu.open_menu(get_parent().route.equipment_state())

func _equipment_action(slot:String,id:String)->void:
	if _leaving or not equipment_menu.visible:return
	var route=get_parent().route
	var ok:bool=route.apply_equipment_selection(slot,id)
	var message:="Ausrüstung aktualisiert." if ok else "Diese Auswahl ist gerade nicht möglich."
	if ok and route.save_error:message="Speichern fehlgeschlagen. Auswahl gilt nur für diese Sitzung."
	equipment_menu.update_state(route.equipment_state(message))
