extends Node3D
var player: AnimationPlayer
var model: Node3D
var camera: Camera3D
var label: Label
var clips: OptionButton
func _ready():
 camera=Camera3D.new(); camera.position=Vector3(0,0.85,4); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=2.5; add_child(camera)
 var light=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-35,-25,0); light.light_energy=2.0; add_child(light)
 var ambient=WorldEnvironment.new(); ambient.environment=Environment.new(); ambient.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; ambient.environment.ambient_light_color=Color.WHITE; ambient.environment.ambient_light_energy=0.5; add_child(ambient)
 for i in range(-5,6):
  line(Vector3(i*0.5,0,-2.5),Vector3(i*0.5,0,2.5),Color(0.25,0.25,0.3))
  line(Vector3(-2.5,0,i*0.5),Vector3(2.5,0,i*0.5),Color(0.25,0.25,0.3))
 line(Vector3.ZERO,Vector3(2,0,0),Color.RED); line(Vector3.ZERO,Vector3(0,2,0),Color.GREEN); line(Vector3.ZERO,Vector3(0,0,2),Color.BLUE)
 var ui=CanvasLayer.new(); add_child(ui)
 var box=VBoxContainer.new(); box.position=Vector2(18,18); ui.add_child(box)
 label=Label.new(); label.text="Rend&Run Asset QA | X rot · Y grün · Z blau | Raster 0,5 m\nDatei öffnen; Clips laufen unverändert mit 1× Geschwindigkeit."; box.add_child(label)
 var open=Button.new(); open.text="GLB öffnen"; box.add_child(open)
 var dialog=FileDialog.new(); dialog.access=FileDialog.ACCESS_FILESYSTEM; dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE; dialog.filters=PackedStringArray(["*.glb ; GLB"]); add_child(dialog)
 open.pressed.connect(func(): dialog.popup_centered_ratio(0.7)); dialog.file_selected.connect(load_asset)
 clips=OptionButton.new(); box.add_child(clips); clips.item_selected.connect(func(index):
  if player: player.play(clips.get_item_text(index)))
 var sever=Button.new(); sever.text="Arm / Schulter-Cap umschalten"; box.add_child(sever); sever.pressed.connect(func():
  if model:
   var arm=model.find_child("arm_left_severable",true,false); var cap=model.find_child("cap_shoulder_left",true,false)
   if arm and cap: arm.visible=not arm.visible; cap.visible=not arm.visible)
 var side=Button.new(); side.text="Seitenansicht / schräg"; box.add_child(side); side.pressed.connect(func():
  camera.position=Vector3(3,1.8,3) if camera.position.x==0 else Vector3(0,0.85,4); camera.look_at(Vector3(0,0.85,0)))
 var args=OS.get_cmdline_user_args()
 if not args.is_empty(): load_asset(args[0])
func load_asset(path):
 var doc=GLTFDocument.new(); var state=GLTFState.new()
 if doc.append_from_file(path,state)!=OK:
  label.text="GLB konnte nicht geladen werden: "+path; return
 if model: model.queue_free()
 model=doc.generate_scene(state); add_child(model)
 var players=model.find_children("*","AnimationPlayer",true,false); player=players[0] if not players.is_empty() else null
 clips.clear()
 if player:
  player.speed_scale=1.0
  for clip in player.get_animation_list(): clips.add_item(clip)
 var cap=model.find_child("cap_shoulder_left",true,false)
 if cap: cap.visible=false
 label.text="Rend&Run QA | X rot · Y grün · Z blau | Raster 0,5 m\n"+path.get_file()+" | 1× | Cap wird hier initial versteckt (Integrationsregel)."
func line(a,b,color):
 var mesh=ImmediateMesh.new(); var mat=StandardMaterial3D.new(); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_color=color
 mesh.surface_begin(Mesh.PRIMITIVE_LINES,mat); mesh.surface_add_vertex(a); mesh.surface_add_vertex(b); mesh.surface_end()
 var node=MeshInstance3D.new(); node.mesh=mesh; add_child(node)
