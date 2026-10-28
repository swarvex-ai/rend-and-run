extends RefCounted
## Bounded repeatable-route reward state. No spawning, wallet or file side effects.
## Current run only: a new run requires all six reward groups to be collected.
const ENEMIES := 5
const COMPLETE_MASK := 63 # five enemies + completion cache
var run_id: int = 0
var seed: int = 0
var initialized := false
var defeated_mask: int = 0
var collected_mask: int = 0
var bonus_misses: int = 0
var specialist_servo: int = 0
var servo_collected := false
var servo_position := Vector3(6.2,.28,0)

func reset() -> void:
	run_id=0;seed=0;initialized=false;defeated_mask=0;collected_mask=0;bonus_misses=0;specialist_servo=0;servo_collected=false;servo_position=Vector3(6.2,.28,0)

func can_begin() -> bool:
	return run_id == 0 or (defeated_mask == COMPLETE_MASK and collected_mask == COMPLETE_MASK)

func begin(initial_seed: int) -> bool:
	if not can_begin() or run_id >= 2147483646 or initial_seed < 0 or initial_seed > 2147483646: return false
	if not initialized: seed=initial_seed;initialized=true
	run_id+=1;defeated_mask=0;collected_mask=0;specialist_servo=0;servo_collected=false;servo_position=Vector3(6.2,.28,0)
	return true

func defeat(expected_run: int, enemy_index: int) -> bool:
	if run_id == 0 or expected_run != run_id or enemy_index < 0 or enemy_index >= ENEMIES: return false
	var bit := 1 << enemy_index
	if defeated_mask & bit: return false
	# Specialist is last; avoids advancing the bonus counter out of sequence.
	if enemy_index == 4 and (defeated_mask & 15) != 15: return false
	defeated_mask |= bit
	if enemy_index == 4:
		_roll_servo()
		defeated_mask |= 32 # completion cache now available, never paid twice
	return true

func _roll_servo() -> void:
	if specialist_servo>0:return
	var digest := (str(seed)+":"+str(run_id)+":servo").sha256_buffer()
	var bonus: bool = bonus_misses>=3 or digest[0]<64
	specialist_servo=2 if bonus else 1
	bonus_misses=0 if bonus else bonus_misses+1

func expose_servo(expected_run:int, at:Vector3) -> bool:
	if run_id==0 or expected_run!=run_id or (defeated_mask & 15)!=15:return false
	if not _valid_position(at):return false
	if specialist_servo>0:return true # same event/retry never rerolls
	servo_position=at
	_roll_servo()
	return true

static func _valid_position(at:Vector3) -> bool:
	return is_finite(at.x) and is_finite(at.y) and is_finite(at.z) and at.x>=-3 and at.x<=83 and at.y>=0 and at.y<=6 and absf(at.z)<.1

func defeated_count() -> int:
	var count:=0
	for index in 5:
		if defeated_mask & (1<<index):count+=1
	return count

func reward_position(group:int) -> Vector3:
	return servo_position if group==4 else Vector3(3.0+group*.8,.28,0)

func pending(expected_run: int, group: int) -> Dictionary:
	if expected_run != run_id or run_id == 0 or group < 0 or group > 5: return {}
	var bit := 1 << group
	if group==4 and specialist_servo>0 and not servo_collected:
		return {"shards":2 if defeated_mask & bit else 0,"servo":specialist_servo}
	if not defeated_mask & bit or collected_mask & bit: return {}
	return {"shards":2,"servo":0}

func collect(expected_run: int, group: int) -> Dictionary:
	# Caller verifies wallet capacity, then commits reward and this receipt together.
	var reward := pending(expected_run, group)
	if reward.is_empty(): return {}
	if int(reward.shards)>0:collected_mask |= 1 << group
	if group==4 and int(reward.servo)>0:servo_collected=true
	return reward

func export_state() -> Dictionary:
	return {"version":2,"servo_collected":servo_collected,"servo_position":[servo_position.x,servo_position.y,servo_position.z],"run_id":run_id,"seed":seed,"initialized":initialized,
		"defeated_mask":defeated_mask,"collected_mask":collected_mask,
		"bonus_misses":bonus_misses,"specialist_servo":specialist_servo}

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floorf(float(value)) and value>=minimum and value<=maximum

func import_state(data: Variant) -> bool:
	reset()
	if not data is Dictionary or data.is_empty(): return false
	for field in ["run_id","seed","defeated_mask","collected_mask","bonus_misses","specialist_servo"]:
		var upper: int = 2147483646 if field in ["run_id","seed"] else 63 if field in ["defeated_mask","collected_mask"] else 3 if field=="bonus_misses" else 2
		if not _integer(data.get(field),0,upper):return false
	if (data.get("version")!=1 and data.get("version")!=2) or not data.get("initialized") is bool:return false
	var d := int(data.defeated_mask);var c := int(data.collected_mask);var servo_count := int(data.specialist_servo)
	if (c & d) != c:return false
	if d & 16:
		if d != COMPLETE_MASK or servo_count < 1:return false
	elif d & 32 or (servo_count>0 and (d!=15 or data.get("version")==1)):return false
	var paid:bool=(c & 16)!=0
	var position_value:=Vector3(6.2,.28,0)
	if data.get("version")==2:
		if not data.get("servo_collected") is bool:return false
		paid=data.servo_collected
		var raw:Variant=data.get("servo_position")
		if not raw is Array or raw.size()!=3:return false
		for component in raw:
			if not (component is float or component is int) or not is_finite(float(component)):return false
		position_value=Vector3(raw[0],raw[1],raw[2])
		if not _valid_position(position_value):return false
	if paid and servo_count==0:return false
	if (c & 16)!=0 and not paid:return false
	if int(data.run_id)==0 and (d!=0 or c!=0 or data.initialized):return false
	if int(data.run_id)>0 and not data.initialized:return false
	run_id=int(data.run_id);seed=int(data.seed);initialized=data.initialized
	defeated_mask=d;collected_mask=c;bonus_misses=int(data.bonus_misses);specialist_servo=servo_count;servo_collected=paid;servo_position=position_value
	return true
