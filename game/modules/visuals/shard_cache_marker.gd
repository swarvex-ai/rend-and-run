extends Node3D
## One reusable world marker; ledger and interaction remain route-owned.
var _label: Label3D
func _init() -> void:
 name="LostShardCache"
 var amber:=StandardMaterial3D.new()
 amber.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 amber.albedo_color=Color(0.95,0.62,0.18)
 for upper in [true,false]:
  var mesh:=CylinderMesh.new()
  mesh.top_radius=0.0 if upper else .12
  mesh.bottom_radius=.12 if upper else 0.0
  mesh.height=.18;mesh.radial_segments=4;mesh.rings=1
  var visual:=MeshInstance3D.new();visual.mesh=mesh;visual.material_override=amber
  visual.position.y=.55 if upper else .37
  visual.position.z=.5
  visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(visual)
 _label=Label3D.new();_label.position=Vector3(0,.85,.65)
 _label.font_size=24;_label.pixel_size=.004
 _label.modulate=Color(1,.8,.4);_label.outline_size=6
 add_child(_label)
 visible=false
func show_amount(value:int) -> void:
 _label.text="%d SPLITTER"%value
 visible=value>0
