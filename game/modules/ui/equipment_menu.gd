extends Control
signal close_requested
signal selection_requested(slot: String, id: String)
const ITEMS=preload("res://modules/equipment/item_catalog.gd")
const UI_TEXT=preload("res://data/ui_texts.gd")
var buttons:Array[Button]=[]
var rows:Dictionary={}
var status:Label
var balance:Label
var _state:Dictionary={}
var _scroll:ScrollContainer
func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS;visible=false
	var backdrop:=ColorRect.new();backdrop.color=Color(0,0,0,.8);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	var panel:=PanelContainer.new();panel.name="Panel";add_child(panel)
	var style:=StyleBoxFlat.new();style.bg_color=Color(.06,.10,.12);style.set_content_margin_all(16);style.set_border_width_all(1);style.border_color=Color(.4,.65,.67);panel.add_theme_stylebox_override("panel",style)
	var frame:=VBoxContainer.new();frame.add_theme_constant_override("separation",10);panel.add_child(frame)
	var scroll:=ScrollContainer.new();_scroll=scroll;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.follow_focus=true;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;frame.add_child(scroll)
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",8);scroll.add_child(column)
	balance=Label.new();balance.add_theme_font_size_override("font_size",22);frame.add_child(balance);frame.move_child(balance,0)
	for id in ITEMS.ITEMS:
		var button:=Button.new();button.name=id;button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.custom_minimum_size.y=72
		button.icon=load(ITEMS.ITEMS[id].icon_path)
		button.add_theme_constant_override("h_separation",14)
		button.add_theme_font_size_override("font_size",14);column.add_child(button);rows[id]=button;buttons.append(button)
		button.pressed.connect(_select.bind(id))
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.custom_minimum_size.y=44;frame.add_child(status)
	var close:=Button.new();close.text=UI_TEXT.t("equipment_back");frame.add_child(close);buttons.append(close);close.pressed.connect(func():close_requested.emit())
	get_viewport().size_changed.connect(_layout);_layout()
func _layout():
	size=get_viewport_rect().size
	var panel:Control=get_node("Panel");panel.size=Vector2(minf(640,size.x-24),minf(500,size.y-24));panel.position=(size-panel.size)*.5
	call_deferred("_reveal_focus")
func open_menu(state:Dictionary):
	visible=true;update_state(state);move_selection(1)
func close_menu():visible=false
func update_state(state:Dictionary):
	_state=state
	balance.text=UI_TEXT.t("equipment_balance")%int(state.get("shards",0))
	var owned:Array=state.get("owned",[])
	for id in rows:
		var item:Dictionary=ITEMS.ITEMS[id]
		var equipped:bool=state.get("equipped",{}).get(item.slot,"")==id
		var action:=UI_TEXT.t("equipment_not_found") if item.acquisition=="world" else UI_TEXT.t("equipment_workbench_cost")%int(item.cost)
		if id in owned:action=UI_TEXT.t("equipment_equipped") if equipped else UI_TEXT.t("equipment_equip")
		if equipped and item.slot!="weapon":action=UI_TEXT.t("equipment_equipped_remove")
		var slot_name:String={"weapon":UI_TEXT.t("equipment_slot_weapon"),"armor":UI_TEXT.t("equipment_slot_armor"),"shield":UI_TEXT.t("equipment_slot_shield")}[item.slot]
		rows[id].text="%s · %s\n%s\n%s"%[ITEMS.label(id),slot_name,ITEMS.summary(id),action]
		_style_row(rows[id],equipped,id in owned)
		rows[id].disabled=not id in owned or (equipped and item.slot=="weapon")
	status.text=state.get("feedback",UI_TEXT.t("equipment_hint"))
func _select(id:String):
	var item:Dictionary=ITEMS.ITEMS[id]
	var selected:String="" if item.slot!="weapon" and _state.get("equipped",{}).get(item.slot,"")==id else id
	selection_requested.emit(item.slot,selected)
	move_selection(0)
func move_selection(direction:int):
	var enabled:Array[Button]=[]
	for b in buttons:
		if not b.disabled:enabled.append(b)
	var idx:=enabled.find(get_viewport().gui_get_focus_owner())
	enabled[posmod((idx if idx>=0 else -1)+direction,enabled.size())].grab_focus()

func _reveal_focus():
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():return
	var focused=get_viewport().gui_get_focus_owner()
	if focused and _scroll.is_ancestor_of(focused):_scroll.ensure_control_visible(focused)

func _style_row(button:Button,equipped:bool,owned:bool):
	var panel:=StyleBoxFlat.new()
	panel.bg_color=Color(.085,.18,.19) if equipped else Color(.07,.12,.145)
	panel.border_color=Color(.35,.78,.77) if equipped else Color(.22,.32,.36)
	panel.set_border_width_all(1);panel.set_corner_radius_all(5);panel.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal",panel)
	button.add_theme_stylebox_override("disabled",panel)
	var hover:StyleBoxFlat=panel.duplicate();hover.bg_color=Color(.12,.23,.25)
	button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",hover)
	var focus:=StyleBoxFlat.new();focus.bg_color=Color(0,0,0,0);focus.border_color=Color(.95,.69,.37);focus.set_border_width_all(2);focus.set_corner_radius_all(5)
	button.add_theme_stylebox_override("focus",focus)
	button.add_theme_color_override("font_color",Color(.91,.94,.94))
	button.add_theme_color_override("font_disabled_color",Color(.78,.88,.87) if owned else Color(.59,.67,.70))
