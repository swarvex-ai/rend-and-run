extends Node3D
## Dystopian mood for the hall (after "Inside" / "Deadlight"): narrow light shafts falling
## steeply from the ceiling through a thin haze over the walkway, so the plant reads as a
## cold, watched place. A light grade is applied by lab_route to the shared environment.

const SHAFTS := [3.5, 12.5, 23.0, 35.5, 47.0, 58.5, 71.0]

func build(from_x: float, to_x: float) -> void:
	var haze := FogVolume.new();haze.name = "WalkwayHaze"
	haze.size = Vector3(to_x - from_x, 4.6, 3.2);haze.position = Vector3((from_x + to_x) * 0.5, 2.3, 0.2)
	var fog := FogMaterial.new();fog.density = 0.018;fog.albedo = Color(.7, .76, .84);fog.edge_fade = 0.4
	haze.material = fog;add_child(haze)
	for x in SHAFTS:
		if x < from_x or x > to_x:continue
		var shaft := SpotLight3D.new();shaft.name = "LightShaft"
		shaft.position = Vector3(x, 4.45, -0.6);shaft.rotation_degrees = Vector3(-72, 0, randf_range(-6, 6))
		shaft.light_color = Color(.78, .86, 1.0);shaft.light_energy = 2.2
		shaft.spot_range = 7.0;shaft.spot_angle = 11.0;shaft.spot_attenuation = 0.6
		shaft.light_volumetric_fog_energy = 9.0;shaft.shadow_enabled = false
		add_child(shaft)
