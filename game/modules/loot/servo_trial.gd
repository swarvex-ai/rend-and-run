extends Node
## Optional first-room recovery trial; reuses the accepted mechanical guard.
var route: Node3D
var foe: CharacterBody3D
var pickups: Dictionary = {}
var waiting_defeat := -1
var waiting_arm := false
var arm_position := Vector3.ZERO
var carrier_module: Node3D
var _epoch := 0
var _retry := 0.0
var _spawn_delay := 1.0

func _process(delta: float) -> void:
	if not is_instance_valid(route) or not is_instance_valid(route.player):return
	if route.player._dying:return
	var ledger=route.servo_run
	if ledger.run_id==0:return
	if _epoch!=ledger.run_id:
		for pickup in pickups.values():
			if is_instance_valid(pickup):pickup.queue_free()
		pickups.clear();_epoch=ledger.run_id;_spawn_delay=1.0;waiting_arm=false;waiting_defeat=-1;_retry=0.0
	for index in pickups.keys():
		if ledger.pending(ledger.run_id,index).is_empty():
			if is_instance_valid(pickups[index]):pickups[index].queue_free()
			pickups.erase(index)
		elif is_instance_valid(pickups[index]):
			for child in pickups[index].get_children():
				if child is Label3D:
					child.visible=absf(route.player.global_position.x-pickups[index].global_position.x)<1.6
					child.text=_reward_label(ledger.pending(ledger.run_id,index))
	_retry=maxf(0.0,_retry-delta)
	if waiting_arm:
		if _retry>0:return
		if route.record_servo_arm(ledger.run_id,arm_position):waiting_arm=false
		else:_retry=1.0;return
	if waiting_defeat>=0:
		if _retry>0:return
		if route.record_servo_defeat(ledger.run_id,waiting_defeat):
			waiting_defeat=-1;_spawn_delay=1.4
		else:_retry=1.0
		return
	for index in 6:
		if not ledger.pending(ledger.run_id,index).is_empty() and not pickups.has(index):_spawn_pickup(index)
	if ledger.defeated_mask==63 or is_instance_valid(foe) and not foe._dead:return
	_spawn_delay=maxf(0.0,_spawn_delay-delta)
	if _spawn_delay>0 or route.player.global_position.x< -1 or route.player.global_position.x>11:return
	var next:=0
	while next<5 and ledger.defeated_mask & (1<<next):next+=1
	if next>=5:return
	foe=route.main._make_enemy(1.0 if route.player.global_position.x>5.5 else 10.5,0)
	foe.name="ServoTrial_%d_%d"%[ledger.run_id,next]
	foe.encounter_id="servo_trial_%d_%d"%[ledger.run_id,next]
	foe.territory_min_x=-1.0
	# One accepted chassis, no paid variant; specialist survives a two-hit combo so the servo can be harvested early.
	foe.hp=5 if next==4 else 2
	if foe.has_node("RoleLabel"):
		var label=foe.get_node("RoleLabel")
		label.text="SERVOTRÄGER" if next==4 else "RÜCKGEWINNUNG %d / 5"%[next+1]
		label.modulate=Color(.9,.65,.3);label.font_size=24;label.pixel_size=.003;label.visible=next==4
	foe.defeated.connect(_defeated.bind(ledger.run_id,next))
	if next==4:
		_attach_carrier_module()
		foe.arm_severed.connect(_arm_severed.bind(ledger.run_id))
		if ledger.specialist_servo>0:
			foe._severed=true;foe._arm_mesh.hide();foe._cap_mesh.show();carrier_module.hide()

func _attach_carrier_module() -> void:
	var socket:=BoneAttachment3D.new();socket.bone_name="LeftArm"
	foe._skeleton.add_child(socket)
	carrier_module=preload("res://assets3d/weapons/arm_servo_v1/model.glb").instantiate()
	carrier_module.name="HarvestableServo";socket.add_child(carrier_module)
	# Meshy rig in centimetres; place at mid-upper-arm in that bone's local frame.
	var lower:int=foe._skeleton.find_bone("LeftForeArm")
	carrier_module.position=foe._skeleton.get_bone_rest(lower).origin*.45
	carrier_module.scale=Vector3.ONE*100.0

func _arm_severed(at:Vector3,epoch:int) -> void:
	if epoch!=route.servo_run.run_id:return
	if is_instance_valid(carrier_module):carrier_module.hide()
	arm_position=at;waiting_arm=true

func _defeated(_enemy: CharacterBody3D, epoch:int, index:int) -> void:
	if epoch!=route.servo_run.run_id:return
	waiting_defeat=index

func _spawn_pickup(index:int) -> void:
	var epoch:int=route.servo_run.run_id
	var reward:Dictionary=route.servo_run.pending(epoch,index)
	var pickup=preload("res://modules/loot/shard_pickup.gd").new()
	pickup.name="ServoSalvage_%d_%d"%[epoch,index]
	pickup.crate_id=str(index);pickup.player=route.player;pickup.amount=2
	# Fixed recovery lane gives pending rewards stable, safe positions on reload.
	pickup.position=route.servo_run.reward_position(index)
	pickup.reached.connect(_collect.bind(epoch,index))
	pickups[index]=pickup;route.add_child(pickup)
	if int(reward.servo)>0:
		for old in pickup._visual.get_children():old.queue_free()
		var component=preload("res://assets3d/weapons/arm_servo_v1/model.glb").instantiate()
		component.scale=Vector3.ONE*1.4;pickup._visual.add_child(component)
	for child in pickup.get_children():
		if child is Label3D:
			child.visible=false
			child.text=_reward_label(reward)

func _reward_label(reward:Dictionary) -> String:
	var parts:PackedStringArray=[]
	if int(reward.get("shards",0))>0:parts.append("%d SPLITTER"%int(reward.shards))
	if int(reward.get("servo",0))>0:parts.append("%d SERVO"%int(reward.servo))
	return " + ".join(parts)

func _collect(_id:String, epoch:int, index:int) -> void:
	pickups.erase(index)
	route.collect_servo_reward(epoch,index)
	# A failed save leaves the receipt pending; _process recreates the pickup.

func _exit_tree() -> void:
	if is_instance_valid(foe):foe.queue_free()
	for pickup in pickups.values():
		if is_instance_valid(pickup):pickup.queue_free()
