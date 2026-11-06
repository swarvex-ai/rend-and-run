extends "res://modules/ui/menu_screen.gd"
## Pause screen built on MenuScreen (E11.5a). Rows follow the style guide and
## docs/decisions/0002-menu-style-guide.md (Quit to desktop added).
## The module never quits, reloads or pauses the tree itself; it only emits
## resume_requested / options_requested / restart_requested / main_menu_requested /
## quit_requested. The last three rows confirm on the same screen; B / Esc returns
## to the list, B / Esc on the list resumes. The owner wires the actions.

signal resume_requested
signal restart_requested
signal quit_requested
signal options_requested
signal main_menu_requested

const TITLE := "Paused"
const ROWS := [
	["resume", "Resume"],
	["options", "Options"],
	["restart", "To checkpoint"],
	["main_menu", "Quit to main menu"],
	["quit", "Quit to desktop"],
]
const CONFIRMATIONS := {
	"restart": ["Restart from checkpoint?", "To checkpoint"],
	"main_menu": ["Quit to main menu?", "Quit to main menu"],
	"quit": ["Quit to desktop?", "Quit to desktop"],
}

var confirm_id := ""
var _btn_resume: Button
var _btn_restart: Button
var _btn_quit: Button
var _btn_back: Button
var _btn_reload: Button

func _init() -> void:
	super._init()
	name = "PauseMenu"
	title = TITLE
	_panel.custom_minimum_size.x = 640.0
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_build()

func _build() -> void:
	for row in ROWS: _add(row[0], row[1], _list_node_name(row[0]))
	row_activated.connect(_on_row_activated)
	back_requested.connect(_on_back_requested)

func open_menu() -> void:
	if confirm_id != "" or (not rows.is_empty() and rows[0].id != "resume"):
		_show_list()
	open_screen()

func close_menu() -> void:
	visible = false
	if confirm_id != "" or (not rows.is_empty() and rows[0].id != "resume"):
		_show_list()

func is_confirming() -> bool:
	return confirm_id != ""

## Keeps the old entry point used when the gameplay restart action opens the menu.
func _on_restart() -> void:
	if not visible: open_menu()
	_show_confirm("restart")

func _on_row_activated(id: String) -> void:
	match id:
		"resume": resume_requested.emit()
		"options": options_requested.emit()
		"restart", "main_menu", "quit": _show_confirm(id)
		"cancel": _cancel_confirm()
		"confirm": _confirm_action()

func _on_back_requested() -> void:
	if confirm_id != "": _cancel_confirm()
	else: resume_requested.emit()

func _confirm_action() -> void:
	match confirm_id:
		"restart": restart_requested.emit()
		"main_menu": main_menu_requested.emit()
		"quit": quit_requested.emit()

func _cancel_confirm() -> void:
	_show_list(confirm_id)

func _show_list(focus_id := "resume") -> void:
	clear_rows()
	_build_list()
	show_rows(focus_id)

func _build_list() -> void:
	confirm_id = ""
	set_title(TITLE)
	for row in ROWS: _add(row[0], row[1], _list_node_name(row[0]))

func _show_confirm(id: String) -> void:
	confirm_id = id
	var texts: Array = CONFIRMATIONS[id]
	clear_rows()
	set_title(texts[0])
	_add("cancel", "Cancel", "BtnBack")
	var action := _add("confirm", texts[1], "BtnReload" if id == "restart" else "BtnConfirm")
	if id == "restart": _btn_reload = action
	show_rows("confirm")

func _add(id: String, text: String, node_name: String) -> Button:
	add_button(id, text)
	var node: Button = rows.back().node
	node.name = node_name
	match id:
		"resume": _btn_resume = node
		"restart": _btn_restart = node
		"quit": _btn_quit = node
		"cancel": _btn_back = node
	return node

func _list_node_name(id: String) -> String:
	match id:
		"resume": return "BtnResume"
		"options": return "BtnOptions"
		"restart": return "BtnRestart"
		"main_menu": return "BtnMainMenu"
		_: return "BtnQuit"

## Keep real focus in step with the base's marker so keyboard/gamepad focus is
## visible to the rest of the game while navigation stays inside MenuScreen.
func _show_focus(animate: bool) -> void:
	super._show_focus(animate)
	if focus_index >= 0 and visible and is_inside_tree():
		var node: Button = rows[focus_index].node
		node.focus_mode = Control.FOCUS_ALL
		node.grab_focus()

