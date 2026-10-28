extends Node
var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1
	print("V26 %s %s"%["PASS" if ok else "FAIL",label])
func wait(t:float)->void:await get_tree().create_timer(t).timeout
func capture(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png(OS.get_environment("V26_OUTPUT")+"/"+name+".png")
func run()->void:
	var route=get_parent();var brute:CharacterBody3D
	for e in route.enemies:
		e.set_physics_process(false)
		if e.role==2:brute=e
	await wait(0.2)
	var blade:Node3D=brute._weapon_pivot.get_node("WeaponBlade")
	check("brute has cleaver",blade.get_script()==preload("res://modules/visuals/brute_cleaver_visual.gd"))
	check("same hand scale",blade.scale.is_equal_approx(Vector3.ONE*0.58))
	check("other roles retain sword",route.enemies[0]._weapon_pivot.get_node("WeaponBlade").get_script()!=blade.get_script())
	route.player.global_position=Vector3(46,0.01,0);route.player.velocity=Vector3.ZERO
	brute.global_position=Vector3(48,0.01,0)
	await wait(0.7)
	capture("brute-idle")
	brute._enter(brute.SWING);brute._state_t=0.10;brute._update_weapon_pose(0)
	await wait(0.02);capture("brute-strike")
	var count:=blade.get_child_count()
	brute._drop_weapon(Vector3(4,0,0))
	await wait(0.05)
	var drops=get_tree().get_nodes_in_group("dropped_weapons")
	check("one detached weapon",drops.size()==1)
	if drops.size()==1:
		var copy=drops[0].find_child("WeaponBlade",true,false)
		check("drop does not duplicate geometry",copy!=null and copy.get_child_count()==count)
		check("held weapon hidden",not brute._weapon_pivot.visible)
		await wait(0.8);capture("brute-drop")
	await wait(4.4)
	check("dropped weapon retired",get_tree().get_nodes_in_group("dropped_weapons").is_empty())
	print("V26 SUMMARY checks=%d failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)
