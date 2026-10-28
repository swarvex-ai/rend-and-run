extends RefCounted
# H14 — Deterministisches Schild-/Parierzustandsmodul (Rend&Run).
# Reines RefCounted: keine Szene, kein Input, kein FX, kein Save, keine
# Hauptszenen-/Player-Abhaengigkeit, kein class_name. Codex besitzt
# Integration, Inputs, Animation, Feedback und Tuning.
# Vertrag: outputs/worker_contracts/H14-guard.txt (Baseline V12 652eecd).
# Ziel-Ressourcenpfad im Projekt: res://modules/combat/guard_state.gd

# --- Tuning (Initialvertrag; spaetere Anpassung durch Codex) ---------------
const MAX_STAMINA := 100.0
const PARRY_WINDOW := 0.14        # Parierfenster ab Druck: [0, 0.14) s
const PARRY_COST := 10.0
const PARRY_COOLDOWN := 0.35      # fruehestens alle 0.35 s ein weiterer Parry
const BLOCK_COST := 25.0
var block_cost := BLOCK_COST       # a riot shield spreads the blow: cheaper blocks
const BREAK_TIME := 0.65          # Guard Break: 0.65 s bestrafbar
const REGEN_RATE := 30.0          # 30 Ausdauer/Sekunde
const REGEN_DELAY := 0.5          # erst 0.5 s nach letzter Ausgabe

var stamina: float = MAX_STAMINA

var _guarding := false            # Schild gehoben
var _input_held := false          # roher Eingabezustand (Flankenerkennung)
var _parry_t := 0.0               # Sekunden seit Druck (nur while guarding)
var _parry_used := false          # Fenster pro Druck Verbraucht
var _parry_cd := 0.0              # Cooldown nach erfolgreichem Parry
var _break_t := 0.0               # verbleibende Break-Zeit
var _spend_delay := 0.0           # Regenerations-Sperre nach Ausgabe


func reset() -> void:
	stamina = MAX_STAMINA
	_guarding = false
	_input_held = false
	_parry_t = 0.0
	_parry_used = false
	_parry_cd = 0.0
	_break_t = 0.0
	_spend_delay = 0.0


func set_guard(held: bool) -> void:
	# Steigende Flanke auf frischem Druck, nicht waehrend Break: Schild sofort.
	if held and not _input_held and _break_t <= 0.0:
		_guarding = true
		_parry_t = 0.0
		_parry_used = false
	_input_held = held
	# Halten durch einen Break hebt NICHT wieder an: erst Loslassen + neuer
	# Druck nach der Erholung. Gesenkt werden kann jederzeit.
	if not held:
		_guarding = false


func tick(delta: float) -> void:
	var dt := maxf(0.0, delta)  # negativer Delta wird auf 0 geklemmt
	if _guarding:
		_parry_t += dt
	# Ausgabe-Sperre und Break laufen GLEICHZEITIG: der regenerationsfreie
	# Anteil eines Ticks ist max(alte Sperre, altes Break), nicht deren Summe.
	# Ueberquert ein Tick beide, zaehlt nur die Zeit nach dem spaeteren Ende.
	var regen_time := maxf(0.0, dt - maxf(_spend_delay, _break_t))
	_parry_cd = maxf(0.0, _parry_cd - dt)
	_spend_delay = maxf(0.0, _spend_delay - dt)
	_break_t = maxf(0.0, _break_t - dt)
	if _guarding:
		regen_time = 0.0  # Halten kostet nichts, verhindert aber Regeneration
	if regen_time > 0.0:
		stamina = minf(MAX_STAMINA, stamina + regen_time * REGEN_RATE)


func resolve_hit(damage: int, from_front: bool, blockable: bool = true) -> Dictionary:
	if damage <= 0:
		return {"outcome": "ignored", "damage": 0}
	if not _guarding or not from_front or not blockable:
		# Ruecken-/unblockable-/ungeschuetzte Treffer: voller Schaden,
		# verbrauchen weder Ausdauer noch Parierfenster.
		return {"outcome": "hit", "damage": damage}
	# Frontaler blockbarer Treffer hinter erhobenem Schild.
	if _parry_window_eligible():
		_parry_used = true
		_parry_cd = PARRY_COOLDOWN
		_spend(stamina - PARRY_COST)
		return {"outcome": "parry", "damage": 0}
	if stamina >= block_cost:
		_spend(stamina - block_cost)
		return {"outcome": "block", "damage": 0}
	# Zu wenig Ausdauer: Break mit vollem/originalen Schaden.
	stamina = 0.0
	_break_t = BREAK_TIME
	_guarding = false
	return {"outcome": "break", "damage": damage}


func _parry_window_eligible() -> bool:
	return (not _parry_used) and _parry_t < PARRY_WINDOW \
		and _parry_cd <= 0.0 and stamina >= PARRY_COST


func _spend(new_stamina: float) -> void:
	stamina = new_stamina
	_spend_delay = REGEN_DELAY


func is_guarding() -> bool:
	return _guarding


func break_remaining() -> float:
	return _break_t
