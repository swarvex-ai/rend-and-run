extends SceneTree
const GUARD=preload("res://modules/persistence/equipment_save_guard.gd")
var failures:=0
var checks:=0
func check(label:String, ok:bool):
	checks+=1
	if not ok:failures+=1
	print("SAVE GUARD ","PASS " if ok else "FAIL ",label)
func write(path:String, text:String):
	var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(text);f.close()
func _initialize():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var path="user://guard-test.json"
	var old="{\n  \"equipment\": {\"loadout_version\":2}, \"shards\":19\n}\n"
	var updated={"equipment":{"loadout_version":3},"shards":7}
	write(path,old)
	check("migrate existing save",GUARD.write_json(path,updated)==OK)
	var backup=path+".before-prefix-v3.bak"
	check("backup preserves exact original bytes",FileAccess.get_file_as_string(backup)==old)
	check("new save written",JSON.parse_string(FileAccess.get_file_as_string(path)).shards==7)
	updated.shards=9
	check("ordinary subsequent write succeeds",GUARD.write_json(path,updated)==OK and FileAccess.get_file_as_string(backup)==old)
	write(path,old)
	check("retry same migration reuses backup",GUARD.write_json(path,updated)==OK)
	write(path,"{\"equipment\":{\"loadout_version\":2},\"shards\":99}")
	var before=FileAccess.get_file_as_bytes(path)
	check("conflicting old backup prevents destructive migration",GUARD.write_json(path,updated)==ERR_ALREADY_EXISTS and before==FileAccess.get_file_as_bytes(path))
	write(path,"broken json")
	check("malformed save retained",GUARD.write_json(path,updated)==ERR_FILE_CORRUPT and FileAccess.get_file_as_string(path)=="broken json")
	write(path,"{\"equipment\":{\"loadout_version\":4}}")
	check("future version not downgraded",GUARD.write_json(path,updated)==ERR_UNAVAILABLE)
	write(path,JSON.stringify(updated))
	DirAccess.make_dir_absolute(path+".tmp")
	before=FileAccess.get_file_as_bytes(path)
	check("failed atomic write preserves current save",GUARD.write_json(path,updated)!=OK and before==FileAccess.get_file_as_bytes(path))
	DirAccess.remove_absolute(path+".tmp")
	check("new profile no legacy backup",GUARD.write_json("user://new-profile.json",updated)==OK and not FileAccess.file_exists("user://new-profile.json.before-prefix-v3.bak"))
	print("SAVE GUARD SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
