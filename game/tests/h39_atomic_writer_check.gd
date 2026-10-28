extends SceneTree
## H39 — fokussierte Tests fuer atomic_json_writer.gd.
## Aufruf (Scratch-Baum):
##   godot --headless --path . --script res://tests/h39_atomic_writer_check.gd
## Nachweis: Exit 0 + "SUMMARY checks=N failures=0". Isoliertes user://-Unterverzeichnis.

const MODULE := "res://modules/persistence/atomic_json_writer.gd"

var checks := 0
var failures := 0


func _chk(name: String, ok: bool, detail := "") -> void:
	checks += 1
	if ok:
		print("PASS %s" % name)
	else:
		failures += 1
		print("FAIL %s %s" % [name, detail])


func _read(path: String) -> String:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return "<kein File>"
	var s: String = f.get_as_text()
	f.close()
	return s


func _initialize() -> void:
	await process_frame
	var script: Script = load(MODULE)
	_chk("modul_laedt", script != null)
	if script == null:
		print("SUMMARY checks=%d failures=%d" % [checks, failures])
		quit(1)
		return

	var src: String = ""
	var fs: FileAccess = FileAccess.open(MODULE, FileAccess.READ)
	if fs != null:
		src = fs.get_as_text()
		fs.close()

	var dir := "user://h39_test"
	var da := DirAccess.open("user://")
	if da.dir_exists(dir):
		da.make_dir_recursive(dir + "/_stale")  # existiert -> keine Seitenwirkung
	else:
		da.make_dir_recursive(dir)

	# --- Flush-Reihenfolge im Quelltext (Review-Reihenfolge ist Vertrag) ---
	var i_flush := src.find("flush()")
	var i_err := src.find("get_error()",i_flush)
	var i_close := src.find("close()")
	var i_store := src.find("store_string")
	var i_rename := src.find("rename_absolute")
	_chk("Reihenfolge_store_flush_geterror_close_rename",
		i_store >= 0 and i_store < i_flush and i_flush < i_err
		and i_err < i_close and i_close < i_rename,
		"store=%d flush=%d err=%d close=%d rename=%d"
		% [i_store, i_flush, i_err, i_close, i_rename])
	_chk("kein_Serialisieren_nach_open",
		src.find("JSON.stringify") < src.find("FileAccess.open"))
	_chk("kein_Sleep_und_keine_Backupkette",
		not src.contains("OS.delay") and not src.contains("bak"))

	# --- 1. Gueltiger Ersatz einer vorhandenen Datei ---
	var target := dir + "/save.json"
	var f1: FileAccess = FileAccess.open(target, FileAccess.WRITE)
	f1.store_string("{alt")  # absichtlich kaputter Vorlaeufer
	f1.close()
	var err: Error = script.write_json(target, {"v": 12, "checkpoint": true})
	var content := _read(target)
	var parsed: Variant = JSON.parse_string(content)
	_chk("Ersatz_gibt_OK", err == OK, "err=%d" % err)
	_chk("Ersatz_valider_kompletter_JSON",
		parsed != null and int(parsed["v"]) == 12, content)
	_chk("Ersatz_ohne_tmp_Ueberrest", not FileAccess.file_exists(target + ".tmp"))

	# --- 2. .tmp-VERZEICHNIS blockiert das Oeffnen; Original bleibt, Verzeichnis bleibt ---
	var tdir := dir + "/dirblocked"
	da.make_dir_recursive(tdir)
	var save_b := tdir + "/save.json"
	var good := "{\"v\":1,\"text\":\"ursprung\"}"
	var fb: FileAccess = FileAccess.open(save_b, FileAccess.WRITE)
	fb.store_string(good)
	fb.close()
	da.make_dir_recursive(save_b + ".tmp")  # .tmp ist ein Verzeichnis
	err = script.write_json(save_b, {"v": 2})
	_chk("tmp_Verzeichnis_liefert_Fehler", err != OK, "err=%d" % err)
	_chk("tmp_Verzeichnis_Original_byte_identisch", _read(save_b) == good)
	_chk("tmp_Verzeichnis_nicht_geloescht", DirAccess.dir_exists_absolute(save_b + ".tmp"))

	# --- 3. Rename-Fehler: Ziel + unrelated Sentinel bleiben ---
	var rdir := "user://h39_ro"
	if da.dir_exists(rdir):
		da.remove(rdir)
	da.make_dir_recursive(rdir)
	var save_r := rdir + "/save.json"
	var sentinel := rdir + "/sentinel.txt"
	var good_r := "{\"v\":3,\"note\":\"sentinel-rettet\"}"
	var fr: FileAccess = FileAccess.open(save_r, FileAccess.WRITE)
	fr.store_string(good_r)
	fr.close()
	var fse: FileAccess = FileAccess.open(sentinel, FileAccess.WRITE)
	fse.store_string("unveraenderlich")
	fse.close()
	# Verzeichnis schreibschuetzen (nicht-root): rename der .tmp auf Ziel scheitert.
	var rc := OS.execute("chmod", ["500", ProjectSettings.globalize_path(rdir)])
	var err_r: Error = script.write_json(save_r, {"v": 4})
	var still := _read(save_r)
	var sent := _read(sentinel)
	OS.execute("chmod", ["700", ProjectSettings.globalize_path(rdir)])
	_chk("rename_Fehler_wird_echter_Error",
		rc == 0 and err_r != OK, "chmod=%d err=%d" % [rc, err_r])
	_chk("rename_Fehler_Ziel_byte_identisch", still == good_r, still)
	_chk("rename_Fehler_Sentinel_unangetastet", sent == "unveraenderlich")
	_chk("rename_Fehler_eigene_tmp_wegrational",
		not FileAccess.file_exists(save_r + ".tmp"))

	# --- 4. Echter Write-Fehler: /dev/full (Schreiben scheitert, open gelingt) ---
	if FileAccess.file_exists("/dev/full"):
		var err_full: Error = script.write_json("/dev/full", {"x": 1})
		_chk("dev_full_Write_Fehler_undefixt",
			err_full != OK, "err=%d" % err_full)
	else:
		print("INFO /dev/full nicht vorhanden — Write-Fehlerpfad nur Quelltext-review")

	# --- 5. Parametervisier: leerer Pfad / Pfad auf Verzeichnisebene ---
	_chk("leerer_Pfad_abgelehnt",
		script.write_json("", {"a": 1}) == ERR_INVALID_PARAMETER)
	_chk("Pfad_auf_Verzeichnisebene_abgelehnt",
		script.write_json(dir + "/nope/", {"a": 1}) == ERR_INVALID_PARAMETER)

	# --- 6. Kein mkdir-Seiteneffekt in fremdem Pfad ---
	var missing_parent := dir + "/notcreated"
	err = script.write_json(missing_parent + "/save.json", {"a": 1})
	_chk("fehlendes_Verzeichnis_kein_mkdir",
		err != OK and not DirAccess.dir_exists_absolute(missing_parent),
		"err=%d" % err)

	# --- 7. Aufruf gegen Ziel-VERZEICHNIS: Ziel bleibt, keine Backupketten ---
	da.make_dir_recursive(dir + "/ist_dir")
	err = script.write_json(dir + "/ist_dir", {"a": 1})
	_chk("Ziel_Verzeichnis_Fehler_ohne_Zerstoerung",
		err != OK and DirAccess.dir_exists_absolute(dir + "/ist_dir"),
		"err=%d" % err)

	print("SUMMARY checks=%d failures=%d" % [checks, failures])
	# Aufraeumen VOR quit (nur eigene Testverzeichnisse, chmod rueckgaengig).
	OS.execute("chmod", ["700", ProjectSettings.globalize_path("user://h39_ro")])
	_rmtree(ProjectSettings.globalize_path(dir))
	_rmtree(ProjectSettings.globalize_path("user://h39_ro"))
	quit(1 if failures > 0 else 0)


func _rmtree(gp: String) -> void:
	# Rekursiver Loeschhelper ueber OS; Aufrufer uebergeben ausschliesslich
	# die eigenen user://-Testpfade (kein rm auf fremde Ziele).
	OS.execute("rm", ["-r", "-f", gp])
