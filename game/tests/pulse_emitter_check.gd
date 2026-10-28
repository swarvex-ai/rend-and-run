extends SceneTree
## H60: actual imported surfaces, muzzle and independent charge on live/drop copies.
var failures := 0
func check(label: String, ok: bool) -> void:
	print("H60 %s %s" % ["PASS" if ok else "FAIL", label])
	if not ok: failures += 1
func energy(v: Node3D) -> float:
	return v._charge_mat.emission_energy_multiplier
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var script = load("res://modules/visuals/pulse_emitter_visual.gd")
	var a: Node3D = script.new();a.set_charge(0.75);root.add_child(a)
	var b: Node3D = script.new();root.add_child(b)
	check("pending charge applied", is_equal_approx(energy(a), lerpf(0.15,2.2,0.75)))
	check("initial dim", is_equal_approx(energy(b),0.15))
	var meshes = a.find_children("*","MeshInstance3D",true,false)
	check("one imported mesh", meshes.size()==1)
	var box: AABB = meshes[0].get_aabb()
	check("contract bounds", box.position.x>=-0.12 and box.end.x<=0.12 and absf(box.position.y+0.1)<0.001 and absf(box.end.y-0.7)<0.001 and box.position.z>=-0.06 and box.end.z<=0.06)
	var triangles := 0
	for i in meshes[0].mesh.get_surface_count():triangles += meshes[0].mesh.surface_get_arrays(i)[Mesh.ARRAY_INDEX].size()/3
	check("actual triangle budget",triangles>0 and triangles<=1800)
	check("four material surfaces",meshes[0].mesh.get_surface_count()==4)
	var marker: Marker3D = a.get_node("Muzzle")
	check("muzzle endpoint and forward", marker.position.is_equal_approx(Vector3(0,.7,0)) and marker.basis.y.is_equal_approx(Vector3.UP))
	a.set_charge(5);check("upper clamp",is_equal_approx(energy(a),2.2))
	b.set_charge(-2);check("lower clamp",is_equal_approx(energy(b),.15))
	check("instances independent",a._charge_mat!=b._charge_mat and energy(a)>energy(b))
	var copy: Node3D = a.duplicate();root.add_child(copy)
	check("copy preserves charged state",is_equal_approx(energy(copy),2.2))
	check("copy has one model and one muzzle",copy.find_children("*","MeshInstance3D",true,false).size()==1 and copy.find_children("Muzzle","Marker3D",true,false).size()==1)
	copy.set_charge(0);check("copy does not dim source",is_equal_approx(energy(copy),.15) and is_equal_approx(energy(a),2.2))
	a.queue_free();await process_frame
	copy.set_charge(.5);check("copy survives source deletion",is_equal_approx(energy(copy),lerpf(.15,2.2,.5)))
	b.queue_free();copy.queue_free();await process_frame
	print("H60 RESULT failures=", failures);quit(1 if failures else 0)
