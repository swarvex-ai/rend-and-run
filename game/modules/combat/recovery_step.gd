extends RefCounted
## H48 — recovery_step: kurzer, FEST gerichteter Rueckschritt eines Duellanten
## nach verfehltem Angriff. Reines RefCounted-Rechenmodul: keine Nodes, keine
## Ressourcen, kein Audio, keine Datei-IO, kein Zugriff auf player.gd/enemy.gd,
## kein Homing. Integration/Trigger und Kollisions-/Abgrundpruefung beim Lead.
##
## API:
##   start(front, speed = 2.8, duration = 0.18) -> bool
##     Committet die Richtung ENTGEHEN front (front=+1 -> Rueckschritt nach -X).
##     front==0 oder nichtfinite/ungueltige Werte werden abgelehnt (Rueckgabe
##     false, Zustand unveraendert). Ein gueltiger Start ERSETZT jeden
##     laufenden Zustand komplett (Richtung, Tempo, Dauer, Takt).
##   advance(delta) -> float
##     Gewuenschte X-Geschwindigkeit fuer diesen Schritt (Vorzeichen =
##     Rueckwaerts relativ zu front). delta<=0 und nichtfinite delta sind
##     harmless (Rueckgabe 0.0, Takt bleibt stehen). Der letzte Schritt wird
##     zeitanteilig gekuerzt: ueber alle frames integriert ergibt die
##     Strecke EXACT speed*duration und ueberschreitet sie nie — auch nicht
##     mit einem einzigen advance(grosser_delta).
##   cancel(): beendet sofort (naechstes advance liefert 0.0).
##   is_active(): true zwischen gueltigem start() und Ablauf/cancel().
##
## Der Aufrufer bleibt Herr ueber Bewegung und Prufungen: Das Modul sagt nur,
## welche X-Geschwindigkeit es moechte; wandern darf nur, was der Lead zulaesst.

const DEFAULT_SPEED := 2.8
const DEFAULT_DURATION := 0.18

var _dir := 0.0        # fixierte X-Richtung des Rueckschritts (-sign(front))
var _speed := 0.0
var _duration := 0.0
var _elapsed := 0.0
var _active := false


## Committet einen Rueckschritt entgegen front. true bei gueltigem Start.
func start(front: float, speed: float = DEFAULT_SPEED, duration: float = DEFAULT_DURATION) -> bool:
	if not is_finite(front) or not is_finite(speed) or not is_finite(duration):
		return false
	if absf(front) < 1e-9 or speed <= 0.0 or duration <= 0.0:
		return false
	# Gueltiger Start ersetzt jeden alten Zustand komplett.
	_dir = -signf(front)
	_speed = speed
	_duration = duration
	_elapsed = 0.0
	_active = true
	return true


## Gewuenschte X-Geschwindigkeit fuer diesen delta-Schritt; 0.0 ausserhalb.
## Letzter Teilframe zeitanteilig: integrierte Strecke <= speed*duration, immer.
func advance(delta: float) -> float:
	if not _active or not is_finite(delta) or delta <= 0.0:
		return 0.0
	var remaining: float = _duration - _elapsed
	if remaining <= 0.0:
		_active = false
		return 0.0
	var step: float = minf(delta, remaining)
	_elapsed += step
	if _elapsed >= _duration - 1e-12:
		_active = false
	# Zeitanteil dieses Schritts auf das echte delta verteilt:
	# pos += (antwort)*delta integriert exakt _dir*_speed*step.
	var frac: float = step / delta
	return _dir * _speed * frac


## Bricht sofort ab; naechstes advance() liefert 0.0.
func cancel() -> void:
	_active = false


func is_active() -> bool:
	return _active


## Bereits zurueckgelegte Strecke (Betrag, m) — Diagnose fuer Test/Lead.
func distance_traveled() -> float:
	return _speed * _elapsed
