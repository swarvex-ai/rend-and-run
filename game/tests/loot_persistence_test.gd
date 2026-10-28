extends SceneTree
var checks:=0
var failures:=0
func check(label: String,ok: bool) -> void:
	checks+=1
	if not ok:failures+=1
	print("H13-LEDGER %s %s"%["PASS" if ok else "FAIL",label])
func _initialize() -> void:call_deferred("run")
func run() -> void:
	if OS.get_environment("H13_LEDGER_TEST")!="1":
		push_error("Requires isolated XDG_DATA_HOME and H13_LEDGER_TEST=1")
		quit(2);return
	var script: Script=load("res://lab_route.gd")
	var a: Node3D=script.new()
	a.armor=true;a.checkpoint=true;a.cleared=["first"]
	a.equipment.grant("lab_armor");a.equipment.equip("armor","lab_armor")
	a._on_supply_broken("entry_supply",3,Vector3.ZERO)
	check("break stores pending reward",a.shards==0 and a.pending_shards.get("entry_supply")==3 and a.broken_crates==["entry_supply"])
	var pending: Node3D=script.new();pending._load_progress()
	check("reload before pickup keeps pending reward",pending.shards==0 and pending.pending_shards.get("entry_supply")==3)
	pending.free()
	a._collect_shard_pickup("entry_supply")
	a._collect_shard_pickup("entry_supply")
	check("pickup credited exactly once",a.shards==3 and a.pending_shards.is_empty())
	a._on_supply_broken("entry_supply",3,Vector3.ZERO)
	check("duplicate signal ignored",a.shards==3)
	a._on_supply_broken("unknown",99,Vector3.ZERO)
	check("unknown id ignored",a.shards==3 and a.broken_crates.size()==1)
	var b: Node3D=script.new();b._load_progress()
	check("fresh instance restores shards and crate",b.shards==3 and "entry_supply" in b.broken_crates)
	check("existing equipment and checkpoint preserved",b.armor and b.checkpoint and b.cleared==["first"])
	b._on_supply_broken("entry_supply",3,Vector3.ZERO)
	check("reload cannot farm same crate",b.shards==3)
	b._on_supply_broken("exit_supply",-20,Vector3.ZERO)
	check("negative reward cannot subtract balance",b.shards==3)
	var f:=FileAccess.open("user://rendrun_route_v12.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"version":12,"armor":true,"checkpoint":true,"cleared":["first"]}));f.close()
	var legacy: Node3D=script.new();legacy._load_progress()
	check("V12 save credits prior guard defeat once",legacy.armor and legacy.checkpoint and legacy.shards==3 and legacy.broken_crates.is_empty())
	legacy._save_progress()
	var migrated: Node3D=script.new();migrated._load_progress()
	check("migration reward cannot be repeated",migrated.shards==3 and not migrated._economy_migrated)
	migrated.free()
	a.free();b.free();legacy.free()
	print("H13-LEDGER SUMMARY checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
