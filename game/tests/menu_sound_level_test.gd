extends SceneTree
## Checks that the menu sounds play at the style-guide peak targets: the file-peak
## table matches the raw 16-bit PCM WAV sources, each event's volume is target minus
## file peak, and back resolves to menu_back.wav instead of the block.wav fallback.
const MENU = preload("res://modules/ui/menu_screen.gd")
const FILES := ["res://audio/radio_chirp.wav", "res://audio/block.wav", "res://audio/menu_back.wav"]
const EVENT_FILE := {
	"focus": "res://audio/radio_chirp.wav",
	"confirm": "res://audio/block.wav",
	"back": "res://audio/menu_back.wav",
}
var failures := 0

func check(label: String, ok: bool) -> void:
	print("MENU_SOUND ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

## Peak of the raw WAV's data chunk in dBFS; the imported stream is QOA-compressed.
func wav_peak_db(path: String) -> float:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return NAN
	if file.get_buffer(4).get_string_from_ascii() != "RIFF": return NAN
	file.get_buffer(4)
	if file.get_buffer(4).get_string_from_ascii() != "WAVE": return NAN
	while file.get_position() + 8 <= file.get_length():
		var id := file.get_buffer(4).get_string_from_ascii()
		var size := file.get_buffer(4).decode_u32(0)
		if id == "data":
			var data := file.get_buffer(size)
			var peak := 0
			for i in range(0, data.size() - 1, 2):
				var value := absi(data.decode_s16(i))
				if value > peak: peak = value
			return linear_to_db(float(peak) / 32768.0)
		file.seek(file.get_position() + size + (size % 2))
	return NAN

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	for path in FILES:
		var measured := wav_peak_db(path)
		var stored: float = MENU.SOUND_FILE_PEAK_DB[path]
		check("file peak table matches raw WAV %s (%.2f vs %.1f dBFS)" % [path.get_file(), measured, stored], absf(measured - stored) <= 0.1)
	var menu = MENU.new()
	for event in EVENT_FILE:
		var expected: float = MENU.SOUND_PEAK_DB[event] - MENU.SOUND_FILE_PEAK_DB[EVENT_FILE[event]]
		check("%s volume is target minus file peak (%.2f vs %.2f dB)" % [event, menu.sound_volume_db(event), expected], absf(menu.sound_volume_db(event) - expected) <= 0.1)
	check("back resolves to menu_back.wav", menu._back_sound() != menu.SND_CONFIRM and menu._back_sound().resource_path == MENU.SND_BACK_PATH)
	menu.free()
	print("MENU_SOUND SUMMARY failures=", failures)
	quit(1 if failures else 0)

func _initialize() -> void:
	call_deferred("run")
