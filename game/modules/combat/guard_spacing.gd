extends RefCounted
## H57 — guard_spacing: gebundenes Abstandnahme-Entscheidungsmodell fuer die
## Impulswache. RefCounted, reins Rechenmodul: keine Nodes, Timer, Szenen,
## Audio, Datei-IO, keine Actor-Lesungen/-Schreibens, keine direkte Bewegung.
## Wiederverwendet recovery_step (H48) als EIGENE Instanz — Helper unveraendert.
##
## Zweck: GENAU EIN kurzer Rueckschritt je Annaeherung des Spielers, kein
## Dauerkiten. Richtung wird beim Commit festgelegt und waehrend des aktiven
## Schritts NICHT nachgefuehrt.
##
## API:
##   advance(distance, front, eligible, delta) -> float
##     Gewuenschte X-Geschwindigkeit fuer diesen Schritt (0.0 wenn inaktiv).
##   reset() — bewaffneter, inaktiver Ausgangszustand.
##   is_active() — wahr waehrend eines-committed Rueckschritts.
##
## Regeln (Vertrag H57):
## - Nach reset(): armed=true, inaktiv.
## - Commit wenn armed und eligible und 1.55 < distance <= 2.8: Rueckschritt
##   ENTGEGEN front ueber recovery_step (speed 2.8, duration 0.25 => max
##   0.7m), dann disarm.
## - Wiederbewaffnung erst, wenn eine gueltige Messung distance >= 4.0 zeigt —
##   und erst NACHDEM der Schritt inaktiv ist (kein Rearm waehrend aktiv).
## - eligible=false: aktiver Schritt wird cancelt, bleibt aber disarmiert bis
##   Separation (>=4m) oder reset().
## - Ungueltige Eingaben (nicht-endliche Distanz, negatives distance,
##   front==0/nicht-endlich, delta<=0/nicht-endlich) starten, bewaffnen oder
##   verbrauchen NICHTS.
##
## advance() gibt nur die Gewuenschte Geschwindigkeit zurueck; ob und wohin
## sich bewegt, entscheidet der Lead (CHASE, freier Boden, kein Stun usw.
## liefert er als eligible).

const TRIGGER_MIN := 1.55   # exklusiv: darueber darf ein Schritt beginnen
const TRIGGER_MAX := 2.8    # inklusiv
const REARM_DISTANCE := 4.0 # erst ab hier (gueltige Messung) neu bewaffnen
const STEP_SPEED := 2.8
const STEP_DURATION := 0.25 # * speed = max 0.7 m

var _step: RefCounted
var _armed := true


func _init() -> void:
	_step = preload("res://modules/combat/recovery_step.gd").new()
	reset()


## Bewaffneter, inaktiver Ausgangszustand.
func reset() -> void:
	_step.cancel()
	_armed = true


## Liefert die gewuenschte X-Geschwindigkeit (Vorzeichen: rueckwaerts relativ
## zu front). Startet genau EINEN Schritt pro Bewaffnung.
func advance(distance: float, front: float, eligible: bool, delta: float) -> float:
	# Ungueltige Eingaben: kein Start, kein Rearm, kein Verbrauch.
	if not is_finite(distance) or distance < 0.0:
		return _step.advance(0.0) # immer 0.0, aber bewusst kein Rearm
	if not is_finite(front) or absf(front) < 1e-9:
		return _step.advance(0.0)
	if not is_finite(delta) or delta <= 0.0:
		# Gueltige Richt-/Distanzinfo, aber kein Takt: Rearm-Logik waere zwar
		# moeglich, der Vertrag will aber keine Zustandsverbrauche durch
		# ungueltige Deltas — Zustand bleibt, nur der Schritt-tick faellt aus.
		return 0.0
	if not _step.is_active():
		# Rearm nur ausserhalb der Kampfnaehe, nie waehrend eines Schritts.
		if not _armed and distance >= REARM_DISTANCE:
			_armed = true
		if eligible and _armed and distance > TRIGGER_MIN and distance <= TRIGGER_MAX:
			_step.start(front, STEP_SPEED, STEP_DURATION)
			_armed = false
		return 0.0
	# Aktiver Schritt: Richtung fix (recover_step haelt _dir), kein Rearm.
	if not eligible:
		_step.cancel()
		return 0.0
	return _step.advance(delta)


## Wahrend eines committed Rueckschritts.
func is_active() -> bool:
	return _step.is_active()


## Diagnosen fur den Lead (lesbar, keine Logik).
func is_armed() -> bool:
	return _armed


func distance_traveled() -> float:
	return _step.distance_traveled()
