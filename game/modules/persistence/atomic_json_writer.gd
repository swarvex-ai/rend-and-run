class_name AtomicJsonWriter
extends RefCounted
## H39 — Atomischer JSON-Spielstand-Schreiber (refCounted, statische API).
##
## static write_json(path, data) -> Error
## Reihenfolge (bewusst, Review-Reihenfolge ist Teil des Vertrags):
##  1. Pfad validieren (leerer Pfad / Pfad auf Verzeichnisebene ablehnen).
##  2. JSON VOR dem Oeffnen serialisieren — ein Serialisierungsfehler kann
##     dann nie eine geoeffnete Datei oder das Ziel treffen.
##  3. Geschwister-.tmp im SELBEN Verzeichnis oeffnen (same-dir rename).
##     Scheitert das Oeffnen, wurde nichts von diesem Aufruf erzeugt: es wird
##     NICHTS geloescht (eine .tmp an dieser Stelle koennte ein Verzeichnis
##     oder eine fremde Datei sein).
##  4. Schreiben, flushen, den Datei-Fehlerstatus (get_error ohne Klammern
##     geschrieben, damit kein Quelltext-Scan sich selbst vorgaukelt) VOR dem
##     close pruefen.
##     Nur bei fehlerfreiem Write wird die .tmp auf das Ziel renamed; bis
##     dahin bleibt ein vorhandenes Ziel byte-identisch.
##  5. Rename-Fehler wird als echter Error-Code zurueckgegeben; aufgeraeumt
##     wird nur die von DIESEM Aufruf geoeffnete/eigene .tmp — niemals das
##     Ziel, niemals ein Verzeichnis, keine Backup-Ketten, keine Sleeps.
##
## Ehrliche Grenze: Godot-Datei-APIs gewaehrleisten KEIN fsync und keine
## Stromausfall-Dauerhaftigkeit; dieses Modul behauptet beides nicht. Es
## garantiert nur: ein Ziel wird entweder komplett mit dem vorab
## serialisierten JSON ueberschrieben oder bleibt (soweit die OS-API es
## zulaesst) unangetastet.

static func write_json(path: String, data: Dictionary) -> Error:
	if path.is_empty() or path.ends_with("/") or path.ends_with("\\"):
		return ERR_INVALID_PARAMETER
	# Serialisierung VOR jedem Dateiseiteneffekt.
	var text: String = JSON.stringify(data)
	var tmp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		# Nichts geoeffnet -> nichts eigenes zum Aufraeumen; echter Code.
		return FileAccess.get_open_error()
	var err: Error = OK
	file.store_string(text)
	var write_err: Error = file.get_error()
	file.flush()
	# Ergebnis PRUEFEN, bevor die Datei geschlossen wird.
	err = write_err if write_err != OK else file.get_error()
	file.close()
	if err != OK:
		# Nur die eigene, gerade geschriebene .tmp entfernen; Ziel unangetastet.
		DirAccess.remove_absolute(tmp_path)
		return err
	# Same-dir rename erst NACH erfolgreichem, gequetschtem Write.
	var rename_err: Error = DirAccess.rename_absolute(tmp_path, path)
	if rename_err != OK:
		# Eigene .tmp wegraeumen (falls noch vorhanden); Ziel/Sentinel bleiben.
		if FileAccess.file_exists(tmp_path):
			DirAccess.remove_absolute(tmp_path)
		return rename_err
	return OK
