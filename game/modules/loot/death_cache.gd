extends RefCounted
# Legacy-cache compatibility only: new farming deaths retain the wallet.
# H67 — Todes-Splitter-Tagebuch fuer P39 (kanonischer Pfad, reine Daten).
# Vertrag: outputs/worker_contracts/H67-death-cache.txt (Codex, 07.10.2026).
# GDD P39: Tod laesst aktuelle Splitter fallen; EIN rueckholbarer Depot-Posten;
# spaeterer Tod ERSETZT ihn. Ausruestung/Faehigkeiten bleiben (nicht hier).
# - Keine class_name, keine statics, keine Knoten, keine IO, keine Systemuhr.
# - replace(amount, at): lehnt negativ / >999999 / nicht-endliche Position
#   ohne jede Zustandsaenderung ab; gueltiger Betrag ERSETZT das alte Depot;
#   Betrag 0 entfernt das alte Depot (aktiv -> inaktiv, kanonischer Nullpunkt).
# - take(): liefert den Betrag genau EINMAL, danach geleert.
# - export/import: JSON-sicher {amount:int, position:[x,y,z]}; kein Vector3 in
#   serialisierten Werten; import prueft Dictionary, ganzzahligen Betrag
#   (JSON-Float nur endlich/ganzzahlig/inrange) und genau 3 endliche
#   Zahlenkoordinaten; Ablehnung ohne Zustandsaenderung; Betrag 0 kanonisiert
#   die Position auf [0,0,0].
# - Kein Geldboersen-Rechenwerk, kein Auto-Aufsammeln, kein Radius, keine
#   Todesregeln, kein Speichern — das besitzt der Lead (Einbau, Persistenz,
#   Rueckwaertskompatibilitaet Version 12, Todes-Signal).

const MAX_AMOUNT := 999999

var _amount := 0
var _pos := Vector3.ZERO
var _active := false

# Ersetzt das Depot. false = abgelehnt, alter Zustand bleibt unangetastet.
# Gueltiger Betrag 0 = altes Depot wird entfernt (gilt als Erfolg).
func replace(amount: int, at: Vector3) -> bool:
	if amount < 0 or amount > MAX_AMOUNT:
		return false
	if not (is_finite(at.x) and is_finite(at.y) and is_finite(at.z)):
		return false
	if amount == 0:
		_amount = 0
		_pos = Vector3.ZERO
		_active = false
		return true
	_amount = amount
	_pos = at
	_active = true
	return true

func amount() -> int:
	return _amount

func position() -> Vector3:
	return _pos

func is_active() -> bool:
	return _active

# Betrag genau einmal abholen; danach (und wenn inaktiv) 0.
func take() -> int:
	if not _active:
		return 0
	var got := _amount
	_amount = 0
	_pos = Vector3.ZERO
	_active = false
	return got

func reset() -> void:
	_amount = 0
	_pos = Vector3.ZERO
	_active = false

# JSON-sicher: amount:int, position:Array[float] (kein Vector3-Wert).
func export_state() -> Dictionary:
	var p := _pos if _active else Vector3.ZERO
	return {
		"amount": _amount,
		"position": [p.x, p.y, p.z],
	}

# Prueft erst vollstaendig in Lokalvariablen, schreibt NUR bei Erfolg.
func import_state(data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var d: Dictionary = data
	if not d.has("amount") or not d.has("position"):
		return false
	var a: Variant = d["amount"]
	var amt := 0
	if typeof(a) == TYPE_INT:
		amt = a
	elif typeof(a) == TYPE_FLOAT and is_finite(a) and a >= 0 and a <= MAX_AMOUNT and floorf(a) == a:
		amt = int(a)  # JSON-Zahlen als Float — nur ganzzahlig akzeptiert
	else:
		return false
	if amt < 0 or amt > MAX_AMOUNT:
		return false
	var posv: Variant = d["position"]
	if not (posv is Array) or (posv as Array).size() != 3:
		return false
	var cx := 0.0
	var cy := 0.0
	var cz := 0.0
	for i in 3:
		var e: Variant = (posv as Array)[i]
		if not (e is int or e is float):
			return false
		var f := float(e)
		if not is_finite(f):
			return false
		if i == 0:
			cx = f
		elif i == 1:
			cy = f
		else:
			cz = f
	var coords := Vector3(cx, cy, cz)
	if not coords.is_finite():return false
	# Alles gueltig — jetzt mutieren. Betrag 0 kanonisiert die Position.
	if amt == 0:
		_amount = 0
		_pos = Vector3.ZERO
		_active = false
	else:
		_amount = amt
		_pos = coords
		_active = true
	return true
