extends RefCounted
## H54 — eigenstaendiges Feedback-Prioritaetsmodell (RefCounted, keine Szene/UI).
## Zweck: Routine-Hinweise duerfen wichtigere Kampf-/Speicher-Rueckmeldungen
## nicht verdraengen. Eine aktive Meldung; gleich/hoeher ersetzt voll und
## erneuert die Zeit; niedriger wird verworfen (keine Queue, spaeteres
## Wiederauftauchen gibt es nicht). Keine Timer, Nodes, Input, Datei-IO,
## Signale — der Lead haengt das Modell ans HUD.

const PRIORITY_MIN := 0
const PRIORITY_MAX := 3

var _text: String = ""
var _priority: int = -1
var _remaining: float = 0.0


## Nimmt eine Meldung an, wenn gueltig und nicht von einer hoeheren aktiv
## verdeckt. True = angenommen (Text/Dauer ersetzt, Zeit neu gestartet).
func offer(text: String, priority: int, duration: float) -> bool:
	if text == "":
		return false
	if priority < PRIORITY_MIN or priority > PRIORITY_MAX:
		return false
	if not is_finite(duration) or duration <= 0.0:
		return false
	if is_active() and priority < _priority:
		return false
	_text = text
	_priority = priority
	_remaining = duration
	return true


## Nur endliche, positive Deltas zaehlen; Ablauf loescht Text und Prioritaet.
func tick(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	if not is_active():
		return
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining <= 0.0:
		clear()


func current_text() -> String:
	return _text


func remaining() -> float:
	return _remaining


func clear() -> void:
	_text = ""
	_priority = -1
	_remaining = 0.0


func is_active() -> bool:
	return _remaining > 0.0
