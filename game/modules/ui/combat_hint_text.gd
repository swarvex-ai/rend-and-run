extends RefCounted
## H43 — Standalone contextual defence hints (German, short).
## Pure data module: no UI/scene integration, no per-frame allocations beyond
## the returned text. Unknown role or attack_kind return "" (caller rate-limits
## and shows nothing). Bands referenced read-only from enemy.gd:
## Duelist high band 1.10..1.55 -> duck/parry; low band 0.05..0.55 -> jump or
## side-step clears it. Brute keeps its committed windup after 0.34 s and
## nonlethal hits; only early attacks and parries interrupt -> dodge then
## counter. PulseGuard charges before the bolt -> duck or find cover.
## Roles match enemy.gd @export_enum: 0 Raider, 1 Duelist, 2 Brute, 3 PulseGuard.
const UI_TEXT = preload("res://data/ui_texts.gd")

static func text_for(role: int, attack_kind: String, has_shield := true) -> String:
	match role:
		0:
			if attack_kind == "high":return UI_TEXT.t("hint_high") if has_shield else UI_TEXT.t("hint_high_no_shield")
		1:  # Duelist
			match attack_kind:
				"high":
					return UI_TEXT.t("hint_high") if has_shield else UI_TEXT.t("hint_high_no_shield")
				"low":
					return UI_TEXT.t("hint_low")
		2:  # Boss uses actual high/low band; regular Brute retains dodge hint.
			if attack_kind == "high":return UI_TEXT.t("hint_overseer_high") if has_shield else UI_TEXT.t("hint_overseer_high_no_shield")
			if attack_kind == "low":return UI_TEXT.t("hint_overseer_low")
			if attack_kind == "dodge":
				return UI_TEXT.t("hint_heavy")
		3:  # PulseGuard (charged shot)
			if attack_kind == "crouch":
				return UI_TEXT.t("hint_pulse_guard")
	return ""
