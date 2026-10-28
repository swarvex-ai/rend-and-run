extends RefCounted
# H65 — Lokaler Angriffs-Takt-Puffer (Lesbarkeits-Kandidat, keine KI-Entscheidung).
# Vertrag: outputs/worker_contracts/H65-attack-cadence.txt (Codex, 07.10.2026).
# - Reine, deterministische Datenlogik; Simulationzeit ausschliesslich aus
#   advance(delta), keine Systemuhr, keine Knoten, keine Rueckrufe.
# - try_claim(origin_x): erfolgreiche Beanspruchung sperrt alle Urspruenge mit
#   abs(x - zuvor_x) < 8.0 fuer 0.12 s; genau 8.0 ist unabhaengig.
# - Abgelehnte Beanspruchung verlaengert KEINE Sperre und fuegt nichts hinzu.
# - advance() ignoriert negative und nicht-endliche Delta; reset() leert alles.
# - Max 32 Eintraege; wenn voll, Ablehnung bis zum naechsten Ablauf — es wird
#   NIE ein lebender Eintrag verdraengt, um einen sonst gesperrten Angriff
#   durchzulassen.
# - Ablauf bei 0.12 s mit kleiner Toleranz (1e-6) gegen Delta-Akkumulationsdrift.
# - Aufrufer besitzt Einsatzzeitpunkt und das Maximum von 2 gleichzeitigen
#   Angriffen; dieses Modul entscheidet keinen KI-Zustand.

const BLOCK_DISTANCE := 8.0
const BLOCK_DURATION := 0.12
const MAX_RECORDS := 32
const TIME_EPS := 1e-6

var _time := 0.0
var _records: Array = []  # [{x: float, expiry: float}]

# Verbraucht nicht-negativem Simulationsdelta; negative/NAN werden ignoriert.
func advance(delta: float) -> void:
	if not is_finite(delta) or delta < 0.0:
		return
	_time += delta
	_purge_expired()

# true = WINDUP darf beginnen; false = Takt-Fenster blockiert oder Kapazitaet voll.
func try_claim(origin_x: float) -> bool:
	if not is_finite(origin_x):
		return false
	_purge_expired()
	if _records.size() >= MAX_RECORDS:
		return false
	for r in _records:
		if absf(origin_x - r["x"]) < BLOCK_DISTANCE:
			return false
	_records.append({"x": origin_x, "expiry": _time + BLOCK_DURATION})
	return true

# Leert alle Sperren und setzt die Simulationszeit zurueck.
func reset() -> void:
	_records.clear()
	_time = 0.0

func active_count() -> int:
	_purge_expired()
	return _records.size()

func _purge_expired() -> void:
	var i := _records.size() - 1
	while i >= 0:
		var exp: float = _records[i]["expiry"]
		if _time >= exp - TIME_EPS:
			_records.remove_at(i)
		i -= 1
