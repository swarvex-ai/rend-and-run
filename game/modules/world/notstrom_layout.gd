extends RefCounted
## Authored mission beats; stable encounter IDs preserve existing route saves.
const REVISION := 2
const BOSS_X := 73.0
const BOSS_ENTRY_X := 70.0
const EXIT_X := 79.0
const EAST_X := 83.0
const NEW_IDS := ["freight_raider","freight_duelist","relay_guard","hound"]
const ENCOUNTERS := [
 {"id":"first", "x":8.5, "role":0, "min_x":-3.0},
 {"id":"duelist", "x":32.5, "role":1, "min_x":29.5, "shield":true},
 {"id":"guard", "x":40.0, "role":3, "min_x":37.0, "gun":"smg"},
 {"id":"hound", "x":43.5, "role":0, "min_x":38.0, "script":"res://modules/combat/enemy_dog.gd"},
 {"id":"freight_raider", "x":48.0, "role":3, "min_x":44.0, "gun":"pistol"},
 {"id":"freight_duelist", "x":56.0, "role":1, "min_x":55.3, "shield":true},
 {"id":"relay_guard", "x":64.0, "role":3, "min_x":59.0, "gun":"energy_rifle"},
 {"id":"brute", "x":BOSS_X, "role":2, "min_x":BOSS_ENTRY_X}
]

static func encounter_ids() -> Array[String]:
 var result:Array[String]=[]
 for spec in ENCOUNTERS:result.append(spec.id)
 return result

static func all_cleared(cleared:Array) -> bool:
 for spec in ENCOUNTERS:
  if not spec.id in cleared:return false
 return true

static func cleared_count(cleared:Array) -> int:
 var result:=0
 for spec in ENCOUNTERS:
  if spec.id in cleared:result+=1
 return result

static func zone(x:float) -> String:
 if x<11:return "01 / ANKUNFT"
 if x<24:return "02 / WARTUNG"
 if x<29.5:return "03 / VERSORGUNG"
 if x<BOSS_ENTRY_X:return "04 / SICHERUNG"
 return "05 / SCHLEUSE"
