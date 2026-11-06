extends "res://modules/ui/menu_screen.gd"
## Main menu (E11.4a): the style guide's Main screen on the shared MenuScreen base.
## Rows Continue, New run, Options, Credits, Quit. Continue is disabled without a
## save; New run (with a save) and Quit confirm on the same screen. B / Esc cancels
## a confirmation and does nothing on the main list. The owner (start.gd) wires the
## signals to scene changes and the Options screen; this module never does I/O.

signal continue_requested
signal new_run_requested
signal quit_requested
signal options_requested
signal credits_requested

const MAIN_ROWS := [
	["continue", "Continue"],
	["new_run", "New run"],
	["options", "Options"],
	["credits", "Credits"],
	["quit", "Quit"],
]

var _has_save := false
var _confirm := ""
var _btn_continue: Button
var _btn_new_run: Button
var _btn_back: Button
var _btn_confirm_new: Button

func _init() -> void:
	super._init()
	name = "StartMenu"
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	title = "REND&RUN"
	_build()

func _build() -> void:
	_add_main_rows()
	set_row_enabled("continue", _has_save)
	row_activated.connect(_on_row_activated)
	back_requested.connect(_on_back)

## Opens the main list. focus_id lets the owner return to a row, e.g. Options.
func open_menu(has_save: bool, focus_id := "") -> void:
	_has_save = has_save
	if focus_id == "":
		focus_id = "continue" if has_save else "new_run"
	_show_main(focus_id)
	open_screen()

func close_menu() -> void:
	visible = false

## Detach old rows immediately so rebuilt rows keep their names (no sibling clashes).
func clear_rows() -> void:
	for row in rows:
		var node: Node = row.node
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
	super.clear_rows()

func _add_main_rows() -> void:
	for row in MAIN_ROWS:
		add_button(row[0], row[1])
	rows[0].node.name = "BtnContinue"
	rows[1].node.name = "BtnNewRun"
	rows[2].node.name = "BtnOptions"
	rows[3].node.name = "BtnCredits"
	rows[4].node.name = "BtnQuit"
	_btn_continue = rows[0].node
	_btn_new_run = rows[1].node

func _show_main(focus_id: String) -> void:
	_confirm = ""
	clear_rows()
	_add_main_rows()
	set_row_enabled("continue", _has_save)
	set_title("REND&RUN")
	show_rows(focus_id)

func _ask(action: String) -> void:
	_confirm = action
	clear_rows()
	set_title("Start new run?" if action == "new_run" else "Quit?")
	add_button("cancel", "Cancel")
	rows[0].node.name = "BtnBack"
	_btn_back = rows[0].node
	if action == "new_run":
		add_button("confirm_new_run", "Start new run")
		rows[1].node.name = "BtnConfirmNewRun"
		_btn_confirm_new = rows[1].node
	else:
		add_button("confirm_quit", "Quit")
		rows[1].node.name = "BtnConfirmQuit"
	show_rows(rows[1].id)

func _on_row_activated(id: String) -> void:
	match id:
		"continue":
			continue_requested.emit()
		"new_run":
			if _has_save:
				_ask("new_run")
			else:
				new_run_requested.emit()
		"options":
			options_requested.emit()
		"credits":
			credits_requested.emit()
		"quit":
			_ask("quit")
		"cancel":
			_show_main(_confirm)
		"confirm_new_run":
			new_run_requested.emit()
		"confirm_quit":
			quit_requested.emit()

func _on_back() -> void:
	if _confirm != "":
		_show_main(_confirm)
