extends SceneTree
# H14 — Headless-Test fuer guard_state.gd (reines RefCounted, keine Hauptszene).
# Aufruf: godot --headless --path <projekt> --script res://game/tests/guard_state_test.gd
# Exit-Code 0 = alle Checks PASS, 1 = mindestens ein FAIL.

const GUARD_SCRIPT := preload("res://modules/combat/guard_state.gd")

var checks := 0
var failures := 0

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("H14 %s %s" % ["PASS" if ok else "FAIL", label])

func fresh() -> RefCounted:
	return GUARD_SCRIPT.new()

func _initialize() -> void:
	# --- 1) reset / Anfangszustand / Instanzunabhaengigkeit -------------------
	var g := fresh()
	check("initial: stamina 100, guard down, no break",
		g.stamina == 100.0 and not g.is_guarding() and g.break_remaining() == 0.0)
	var h := fresh()
	g.set_guard(true)
	g.resolve_hit(5, true)
	check("instances independent", not h.is_guarding() and h.stamina == 100.0)
	g.reset()
	check("reset clears guard/stamina/timers",
		g.stamina == 100.0 and not g.is_guarding() and g.break_remaining() == 0.0)

	# --- 2) Druck hebt Schild sofort; wiederholtes true ohne neue Flanke ------
	g = fresh()
	g.set_guard(true)
	check("rising edge raises immediately", g.is_guarding())
	g.resolve_hit(4, true)   # Parry #1 (Fenster [0,0.14))
	var st_after_parry: float = g.stamina
	g.set_guard(true)        # wiederholtes true: kein neues Fenster
	var r: Dictionary = g.resolve_hit(4, true)
	check("repeated true does not restart parry window",
		r["outcome"] == "block" and st_after_parry - g.stamina == 25.0)

	# --- 3) Parrierfenster-Grenze (0.1 s drin, 0.15 s draussen) ---------------
	g = fresh()
	g.set_guard(true)
	g.tick(0.1)
	check("parry inside window: damage 0, cost 10",
		g.resolve_hit(7, true)["outcome"] == "parry" and g.stamina == 90.0)
	g.reset()
	g.set_guard(true)
	g.tick(0.15)
	r = g.resolve_hit(7, true)
	check("past window falls back to block cost 25",
		r["outcome"] == "block" and g.stamina == 75.0)

	# --- 4) Parry-Cooldown 0.35 s ----------------------------------------------
	g = fresh()
	g.set_guard(true)
	g.resolve_hit(1, true)          # Parry, Cooldown startet
	g.set_guard(false)
	g.set_guard(true)               # frischer Druck, frisches Fenster
	g.tick(0.3)                     # Cooldown noch aktiv
	r = g.resolve_hit(1, true)
	check("new press within cooldown blocks (no parry)", r["outcome"] == "block")
	g.set_guard(false)
	g.set_guard(true)
	g.tick(0.1)                     # insgesamt 0.4 s > 0.35 s
	check("parry again after cooldown", g.resolve_hit(1, true)["outcome"] == "parry")

	# --- 5) Block mit genau 25 moeglich, danach Break --------------------------
	g = fresh()
	g.stamina = 25.0
	g.set_guard(true)
	g.tick(0.2)                    # Parierfenster ablaufen lassen -> Block Pfad
	r = g.resolve_hit(8, true)
	check("exactly 25 blocks", r["outcome"] == "block" and g.stamina == 0.0)
	r = g.resolve_hit(8, true)
	check("below 25 breaks with full damage",
		r["outcome"] == "break" and r["damage"] == 8 and g.stamina == 0.0
		and g.break_remaining() > 0.6 and not g.is_guarding())

	# --- 6) Ruecken-/unblockable-/ungeschuetzte Treffer ------------------------
	g = fresh()
	g.set_guard(true)
	r = g.resolve_hit(6, false, true)     # von hinten
	check("back hit full damage, no stamina cost",
		r["outcome"] == "hit" and r["damage"] == 6 and g.stamina == 100.0)
	r = g.resolve_hit(6, true, false)     # unblockable
	check("unblockable hit full damage", r["outcome"] == "hit" and g.stamina == 100.0)
	r = g.resolve_hit(6, true, true)      # Fenster noch unverbraucht
	check("window not consumed by back/unblockable hits", r["outcome"] == "parry")
	g.reset()
	r = g.resolve_hit(6, true, true)      # gar kein Schild
	check("unguarded hit takes full damage", r["outcome"] == "hit" and r["damage"] == 6)

	# --- 7) ignored: Schaden <= 0 veraendert nichts -----------------------------
	g = fresh()
	g.set_guard(true)
	r = g.resolve_hit(0, true)
	var r2: Dictionary = g.resolve_hit(-5, true)
	check("zero/negative damage ignored without state change",
		r["outcome"] == "ignored" and r["damage"] == 0
		and r2["outcome"] == "ignored" and g.stamina == 100.0 and g.is_guarding())

	# --- 8) Break: Halten hebt nicht wieder; Loslassen + neuer Druck noetig ----
	g = fresh()
	g.set_guard(true)
	g.resolve_hit(1, true)         # Parry verbraucht das Fenster
	g.stamina = 5.0                # Block waere zu teuer -> naechster Treffer bricht
	r = g.resolve_hit(3, true)
	check("forced break drops guard", r["outcome"] == "break" and not g.is_guarding())
	g.tick(0.7)                    # Break abgelaufen, Eingabe wird weiter gehalten
	g.set_guard(true)              # gehalten = keine neue Flanke
	check("holding through break does not auto-raise", not g.is_guarding())
	g.set_guard(false)
	g.set_guard(true)
	check("release + fresh press after recovery raises guard", g.is_guarding())

	# --- 9) Regeneration: erst nach 0.5 s Sperre, nur bei gesenktem Schild -----
	g = fresh()
	g.stamina = 40.0
	g.set_guard(true)
	g.resolve_hit(1, true)         # Parry (cost 10) -> Sperre startet, stamina 30
	g.tick(0.5)                    # genau die Sperre, noch keine Regeneration
	check("no regen during 0.5 s delay", g.stamina == 30.0)
	g.set_guard(false)             # Schild senken
	g.tick(1.0)                    # 30/s -> +30
	check("regen 30/s with guard down", absf(g.stamina - 60.0) < 0.001)
	g.set_guard(true)              # halten: keine Regeneration
	g.tick(1.0)
	check("holding prevents regen", absf(g.stamina - 60.0) < 0.001)
	# Tick, der die Sperre ueberquert: nur den Anteil nach der Sperre zaehlen
	g.reset()
	g.stamina = 50.0
	g.set_guard(true)
	g.resolve_hit(1, true, false)  # hit = keine Ausgabe... -> Ausgabe per Block:
	g.set_guard(true)
	g.stamina = 50.0
	g.resolve_hit(1, true)         # Parry: Ausgabe, Sperre 0.5 s, stamina 40
	g.set_guard(false)
	g.tick(0.7)                    # 0.5 Sperre + 0.2 regen -> +6
	check("tick crossing regen delay counts only remaining portion",
		absf(g.stamina - 46.0) < 0.001)
	# Obergrenze 100
	g.tick(10.0)
	check("regen clamps at 100", g.stamina == 100.0)

	# --- 10) Break-Anteil eines Ticks regeneriert nicht ------------------------
	g = fresh()
	g.stamina = 0.0
	g._break_t = 0.3               # Break mitten im kommenden Tick
	g.tick(0.5)                    # 0.3 s gebrochen, nur 0.2 s Regeneration
	check("broken portion of a tick does not regen",
		absf(g.stamina - 6.0) < 0.001 and g.break_remaining() == 0.0)

	# --- 11) negativer Delta wird auf 0 geklemmt --------------------------------
	g = fresh()
	g.set_guard(true)
	g.tick(-1.0)
	check("negative delta clamped to 0", g.is_guarding() and g.stamina == 100.0)

	# --- 11) Parierfenster: exakte Grenze 0.14 ---------------------------------
	g = fresh()
	g.set_guard(true)
	g.tick(0.14)
	r = g.resolve_hit(2, true)
	check("hit at exactly 0.14 is outside window (block, not parry)",
		r["outcome"] == "block")
	g.reset()
	g.set_guard(true)
	g.tick(0.13999)
	check("hit just below 0.14 still parries", g.resolve_hit(2, true)["outcome"] == "parry")

	# --- 12) Regression Codex: Ausdauer-Sperre und Break laufen parallel ------
	# Repro: new; set_guard(true); tick(0.15); 5x resolve_hit(1,true)
	# (4 Blocks, 5. Break); set_guard(false); tick(0.8)
	# Erwartet: 0.8 - max(0.5, 0.65) = 0.15 s Regeneration -> Stamina 4.5.
	g = fresh()
	g.set_guard(true)
	g.tick(0.15)
	for i in 5:
		r = g.resolve_hit(1, true)
	check("repro: four blocks then break",
		r["outcome"] == "break" and g.stamina == 0.0 and not g.is_guarding())
	g.set_guard(false)
	g.tick(0.8)
	check("parallel spend-delay and break: regen 0.8-max(0.5,0.65)=4.5",
		absf(g.stamina - 4.5) < 0.001)

	# --- 13) Split-Tick-Aequivalenz: 0.8 in einem Tick = 8x0.1 ----------------
	var single := fresh()
	single.set_guard(true)
	single.tick(0.15)
	for i in 5:
		single.resolve_hit(1, true)
	single.set_guard(false)
	single.tick(0.8)
	var split := fresh()
	split.set_guard(true)
	split.tick(0.15)
	for i in 5:
		split.resolve_hit(1, true)
	split.set_guard(false)
	for i in 8:
		split.tick(0.1)
	check("split-tick equivalence (0.8 == 8x0.1)",
		absf(single.stamina - split.stamina) < 0.001 and split.stamina > 4.49)

	print("H14 SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
