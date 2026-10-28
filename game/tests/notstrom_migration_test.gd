extends SceneTree
var failures:=0
func check(label:String,ok:bool):
 if not ok:failures+=1
 print("MIGRATION ","PASS " if ok else "FAIL ",label)
func _initialize():
 var m=load("res://modules/persistence/notstrom_save_migration.gd")
 var old={"version":12,"shards":9,"economy_revision":1,"cleared":["first","duelist","guard","brute"],"completed":true,"death_cache":{"amount":3,"position":[52,0,0]},"equipment":{"owned":["starter_sword","vibroblade"]}}
 var mapped=m.migrate(old)
 check("completed run stays cleared without bonus currency",mapped.cleared.size()==preload("res://modules/world/notstrom_layout.gd").ENCOUNTERS.size() and mapped.shards==9)
 check("old east cache moves with room",mapped.death_cache.position==[76.0,0.0,0.0])
 check("migration is idempotent",m.migrate(mapped)==mapped)
 check("input and ownership preserved",old.death_cache.position[0]==52 and mapped.equipment==old.equipment)
 old.completed=false
 check("partial boss victory does not skip new content",m.migrate(old).cleared.size()==4)
 old.death_cache.position=[26,0,0]
 check("checkpoint cache stays put",m.migrate(old).death_cache.position==[26,0,0])
 old.completed=true;old.erase("economy_revision")
 check("legacy economy credits only original victories",m.migrate(old).shards==21)
 old.death_cache={"amount":2,"position":[62,0,0]}
 check("invalid old bounds cannot become valid via expansion",m.migrate(old).death_cache.amount==0)
 old.death_cache={"amount":2,"position":["bad",0,0]}
 check("malformed cache not coerced",m.migrate(old).death_cache==old.death_cache)
 print("MIGRATION SUMMARY failures=",failures);quit(1 if failures else 0)
