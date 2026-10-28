extends Control
## H51 — edge_threat_indicator.gd
## Eigenstaendiges Control: kleiner Warnhinweis an Bildschirmraendern fuer eine
## ausserhalb des Bilds ladende Impulswache. NUR DRAW — keine Texturen, keine
## Datei-IO, kein Audio, keine Lichter, keine Spielersuche, keine Timer,
## keine Nodes pro Update (keine Kinder, kein _process).
## API: set_threat(side:int, locked:bool), clear().
##   side -1 = linker Rand, +1 = rechter Rand, 0/ungueltig = verstecken.
## Integration/Offscreen-Erkennung macht der Lead; dieses Modul weiss nichts
## ueber Spieler oder Welt.
## Geometrie: schlichtes nach INNEN gerichtetes Dreieck, 12 px Randabstand,
## 18 x 22 px, auf 45 % der Control-Hoehe. Cyan normal, Weiss wenn locked.
## Keine Blinkanimation. Eigene Groesse/Resize beachten — nichts hart auf
## 960x540 kodiert; alle Positionen leiten sich aus self.size ab.

const EDGE_MARGIN := 12.0     # Abstand Aussenrand -> Fuss des Dreiecks (px)
const TRI_W := 18.0           # Breite in X-Richtung (px)
const TRI_H := 22.0           # Hoehe in Y-Richtung (px)
const HEIGHT_FRAC := 0.45     # Dreieckmittelpunkt auf 45 % der Control-Hoehe

var _side := 0                # 0 versteckt, -1 links, +1 rechts
var _locked := false

func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false   # [H51 Smoke-Test] Control-Default ist visible=true:
	                  # ohne dies waere ein frischer Indikator sichtbar (leer).

func set_threat(side: int, locked: bool) -> void:
	if side != -1 and side != 1:
		clear()                 # 0/ungueltig: verstecken, Zustand zurueck
		return
	_side = side
	_locked = locked
	visible = true
	queue_redraw()

func clear() -> void:
	_side = 0
	_locked = false
	visible = false

func is_showing() -> bool:
	# Diagnose fuer Smoke-Test/Lead; kein Gameplay-Zugriff.
	return _side != 0

func threat_side() -> int:
	return _side

func is_locked() -> bool:
	return _locked

func triangle_color() -> Color:
	# Reine Rechenhilfe (auch fuer Smoke-Test): Farbe des aktuellen Dreiecks.
	return Color(1.0, 1.0, 1.0) if _locked else Color(0.0, 1.0, 1.0)

func triangle_points() -> PackedVector2Array:
	# Reine Geometrie-Herleitung aus self.size (resize-faehig, kein hartes
	# 960x540). Nach innen gerichtet: Spitze zeigt zur Bildschirmmitte.
	if _side == 0:
		return PackedVector2Array()
	var cy := size.y * HEIGHT_FRAC
	if _side < 0:
		var x0 := EDGE_MARGIN
		return PackedVector2Array([
			Vector2(x0, cy - TRI_H * 0.5),
			Vector2(x0, cy + TRI_H * 0.5),
			Vector2(x0 + TRI_W, cy),
		])
	var x1 := size.x - EDGE_MARGIN
	return PackedVector2Array([
		Vector2(x1, cy - TRI_H * 0.5),
		Vector2(x1, cy + TRI_H * 0.5),
		Vector2(x1 - TRI_W, cy),
	])

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		# Resize verschiebt den Randabstand — neu zeichnen, keine Nodes noetig.
		if _side != 0:
			queue_redraw()

func _draw() -> void:
	if _side == 0:
		return
	draw_polygon(triangle_points(), PackedColorArray([triangle_color()]))
