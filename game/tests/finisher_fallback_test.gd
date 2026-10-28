extends Node
var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1
	print("V31 %s %s"%["PASS" if ok else "FAIL",label])
func wait(t:float)->void:await get_tree().create_timer(t).timeout
func pieces()->int:
	return get_tree().current_scene.get_children().filter(func(n):return str(n.name).begins_with("FinisherPiece")).size()
func run()->void:
	var main=get_parent();var route=main.route
	for e in route.enemies:e.set_physics_process(false)
	await wait(0.3)
	var normal=route.enemies[0]
	normal.take_melee_hit(99,Vector3(5,4,0));await wait(0.05)
	check("finisher still records actual defeat",normal._dead and "first" in route.cleared)
	if DisplayServer.get_name()=="headless":
		check("headless retains original body",normal._body_mesh.visible and pieces()==0)
	else:
		check("renderer creates two sections",pieces()==2)
		check("successful split hides original",not normal._body_mesh.visible)
	var before:=pieces()
	var fallback=route.enemies[1]
	fallback._body_mesh.skin=null
	fallback.take_melee_hit(99,Vector3(5,4,0));await wait(0.05)
	check("missing skin creates no phantom fragments",pieces()==before)
	check("failed split retains visible body",fallback._body_mesh.visible)
	check("fallback still completes combat death",fallback._dead and "duelist" in route.cleared and fallback.death_squash)
	print("V31 SUMMARY checks=%d failures=%d"%[checks,failures])
	reparent(get_tree().root);main.queue_free();main=null;route=null;normal=null;fallback=null
	await wait(0.3)
	get_tree().quit(1 if failures else 0)
