extends Node3D
## Salvaged clamps and external braces make the earned upgrade readable.
## Cosmetic only: no collision, lights, animation or attack-range changes.
func _ready() -> void:
	name = "SalvagedReinforcement"
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(.24,.29,.32);steel.metallic=.8;steel.roughness=.32
	var copper := StandardMaterial3D.new()
	copper.albedo_color = Color(.82,.39,.12);copper.metallic=.65;copper.roughness=.36
	for y in [.055,.205]:
		var clamp := MeshInstance3D.new();var ring := TorusMesh.new()
		ring.inner_radius=.053;ring.outer_radius=.068;ring.rings=16;ring.ring_segments=8
		clamp.mesh=ring;clamp.material_override=steel;clamp.position.y=y;add_child(clamp)
	for side in [-1.0,1.0]:
		plate(Vector3(side*.058,.13,0),Vector3(.020,.18,.06),steel)
		plate(Vector3(side*.070,.13,.01),Vector3(.006,.115,.028),copper)
		for y in [.055,.205]:
			plate(Vector3(side*.068,y,0),Vector3(.018,.022,.026),copper)
func plate(p: Vector3, size: Vector3, mat: Material) -> void:
	var node := MeshInstance3D.new();var mesh := BoxMesh.new();mesh.size=size
	node.mesh=mesh;node.material_override=mat;node.position=p;add_child(node)
