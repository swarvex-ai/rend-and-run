extends SceneTree
const RUN=preload("res://modules/loot/servo_run_ledger.gd")
var failures:=0
var checks:=0
func check(label:String,ok:bool):
	checks+=1
	if not ok:failures+=1;print("SERVO RUN FAIL ",label)
func _initialize():
	var ledger=RUN.new()
	check("fresh start",ledger.begin(714) and ledger.run_id==1)
	check("no reset to farm",not ledger.begin(888))
	check("early specialist refused",not ledger.defeat(1,4))
	check("unearned cache refused",ledger.collect(1,5).is_empty())
	ledger.defeat(1,0)
	check("duplicate death refused",not ledger.defeat(1,0))
	var restored=RUN.new();restored.import_state(JSON.parse_string(JSON.stringify(ledger.export_state())))
	check("pending survives real JSON types",restored.pending(1,0)=={"shards":2,"servo":0})
	restored.collect(1,0)
	check("duplicate pickup refused",restored.collect(1,0).is_empty())
	check("old event refused",not restored.defeat(0,1))
	var all:=RUN.new();all.begin(71)
	var total_shards:=0;var total_servo:=0;var longest_misses:=0
	for n in 2000:
		var id:int=all.run_id
		for i in 5:
			check("one defeat",all.defeat(id,i))
			var before=all.export_state()
			var copy=RUN.new();check("reload",copy.import_state(JSON.parse_string(JSON.stringify(before))))
			check("no bonus reroll",copy.export_state()==before)
			all=copy
		check("must collect before restart",not all.begin(0))
		var shards:=0;var servo:=0
		for i in 6:
			var reward=all.collect(id,i);shards+=int(reward.shards);servo+=int(reward.servo)
			check("duplicate group",all.collect(id,i).is_empty())
		check("guaranteed budget",shards==12 and servo in [1,2])
		total_shards+=shards;total_servo+=servo
		longest_misses=maxi(longest_misses,all.bonus_misses)
		check("bonus guarantee",all.bonus_misses<=3)
		check("next run",all.begin(12345) and all.seed==71 and all.run_id==id+1)
		check("stale callback after restart",all.collect(id,4).is_empty() and not all.defeat(id,0))
	check("2000 runs currency",total_shards==24000 and total_servo>=2000)
	var broken=all.export_state();broken.collected_mask=4
	check("unearned receipts rejected",not restored.import_state(broken))
	broken=all.export_state();broken.run_id=0.5
	check("fractional epoch rejected",not restored.import_state(broken))
	broken=all.export_state();broken.defeated_mask=32
	check("cache without specialist rejected",not restored.import_state(broken))
	print("SERVO RUN SUMMARY checks=%d failures=%d total_servo=%d longest_misses=%d"%[checks,failures,total_servo,longest_misses]);quit(1 if failures else 0)
