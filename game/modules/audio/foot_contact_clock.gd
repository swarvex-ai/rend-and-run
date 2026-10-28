extends RefCounted
# H37 contact-band entries, checked against Godot-imported toe heights (<2mm error).
# Walk/run approximate stance onset; crouch contacts follow procedural gait.
const CONTACTS := {"crouch":[0.0,0.5],"walk":[0.2769,0.7692],"run":[0.2927,0.7805]}
var _clip: String = ""
var _phase := 0.0
func reset()->void:_clip=""
func advance(clip: String, phase: float)->Array[int]:
 var hits:Array[int]=[]
 if not CONTACTS.has(clip):
  reset();return hits
 phase=fposmod(phase,1.0)
 if _clip!=clip:
  _clip=clip;_phase=phase;return hits
 for side in 2:
  var contact:float=CONTACTS[clip][side]
  if (contact>_phase and contact<=phase) if phase>=_phase else (contact>_phase or contact<=phase):hits.append(side)
 _phase=phase
 return hits
