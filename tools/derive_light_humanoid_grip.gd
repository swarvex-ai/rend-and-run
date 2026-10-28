extends SceneTree
func _initialize():call_deferred("run")
func run():
	var source=load("res://assets3d/releases/chaser_v01/enemy_chaser.glb").instantiate();root.add_child(source)
	var target=load("res://assets3d/characters/light_humanoid_v1/model.glb").instantiate();root.add_child(target);target.rotation.y=PI/2
	var a=source.find_child("Skeleton3D",true,false);var b=target.find_child("Skeleton3D",true,false)
	var sa=a.global_transform*a.get_bone_global_rest(a.find_bone("mixamorig_RightHand"))
	var tb=b.global_transform*b.get_bone_global_rest(b.find_bone("RightHand"))
	var old=Transform3D(Basis(Vector3(0.070036,-0.990803,0.115778),Vector3(0.990228,0.055022,-0.128142),Vector3(0.120593,0.123621,0.984975)),Vector3(-0.001929,0.079955,0.019426)*0.5)
	var basis=tb.basis.orthonormalized().inverse()*sa.basis.orthonormalized()*old.basis
	var pos=tb.basis.inverse()*sa.basis*old.origin*(1.75/.9)
	print("GRIP ",Transform3D(basis*100,pos))
	source.free();target.free();quit()
