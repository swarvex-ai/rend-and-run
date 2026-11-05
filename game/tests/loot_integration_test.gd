extends Node
var failures:=0
var checks:=0
func check(label: String, ok: bool) -> void:
	checks+=1
	if not ok:failures+=1
	print("H13 %s %s"%["PASS" if ok else "FAIL",label])
func wait(t: float) -> void:await get_tree().create_timer(t).timeout
func run() -> void:
	var route: Node3D=get_parent()
	var p: CharacterBody3D=route.player
	for e in route.enemies:e.set_physics_process(false)
	await wait(0.3)
	route.main.pause_controller.resume()
	check("every authored supply crate placed",route.supply_crates.size()==route.CRATE_POSITIONS.size())
	if route.supply_crates.size()!=route.CRATE_POSITIONS.size():
		get_tree().quit(1);return
	var crate: StaticBody3D=route.supply_crates[0]
	# The route starts unarmed and hands out the robot arm at its x=1.8 pickup (lab_route.gd:107-110,1222).
	route.equipment.grant("robot_arm");route.equipment.equip_weapon("robot_arm");p.equip_weapon("robot_arm")
	var guards_before:=get_tree().get_nodes_in_group("enemies").size()
	p.global_position=Vector3(2.9,0.01,0);p.facing=1;p.velocity=Vector3.ZERO
	Input.action_press("crouch");await wait(0.25)
	var metal_before:=FX.metal_contacts
	p._start_attack(1);await wait(0.65)
	check("real first sword hit leaves crate intact",not crate.is_broken() and crate._hp==1 and route.shards==0)
	check("real crate hit emits one metal contact",FX.metal_contacts==metal_before+1)
	p.global_position=Vector3(2.9,0.01,0);p.velocity=Vector3.ZERO
	p._start_attack(1);await wait(0.65)
	check("breaking reveals uncollected loot",crate.is_broken() and route.shards==0 and route.pending_shards.get("entry_supply")==3)
	Input.action_release("crouch");p.global_position=Vector3(4,0.01,0);await wait(.8)
	check("nearby pickup yields three shards",route.shards==3 and route.pending_shards.is_empty())
	# supply_crate_visual.gd:34 toggles the meshes under IntactVisual/BrokenVisual; the old Shell/CollapsedShell nodes are gone.
	var visual=crate.get_node("CrateVisual")
	var broken_root=visual.find_child("BrokenVisual",true,false)
	var intact_root=visual.find_child("IntactVisual",true,false)
	var broken_meshes:=broken_root.find_children("*","MeshInstance3D",true,false)
	var intact_meshes:=intact_root.find_children("*","MeshInstance3D",true,false)
	check("broken shell remains as low debris",not broken_meshes.is_empty() and broken_meshes.all(func(m):return m.visible) and intact_meshes.all(func(m):return not m.visible))
	crate.take_melee_hit(20,Vector3.ZERO)
	route._on_supply_broken("entry_supply",3,Vector3.ZERO)
	check("repeated break cannot duplicate loot",route.shards==3)
	# The route spawns MISSION.ENCOUNTERS plus optional foes (lab_route.gd:152,678), not a fixed four.
	check("crates never count as defeated guards",route.cleared.is_empty() and get_tree().get_nodes_in_group("enemies").size()==guards_before and not crate.is_in_group("enemies"))
	var saved=JSON.parse_string(FileAccess.get_file_as_string("user://rendrun_route_v12_test.json"))
	check("reward and broken state saved together",saved is Dictionary and saved.shards==3 and "entry_supply" in saved.broken_crates)
	var before: int=route.shards
	route.supply_crates[1].restore_broken(true)
	await wait(0.1)
	check("restore emits no reward",route.shards==before)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("V13_OUTPUT")+"/supply_loot.png")
	print("H13 SUMMARY checks=%d failures=%d"%[checks,failures])
	var result:=1 if failures else 0
	var scene:=get_tree().current_scene
	reparent(get_tree().root);scene.queue_free();route=null;p=null;crate=null
	await wait(0.2);get_tree().quit(result)
