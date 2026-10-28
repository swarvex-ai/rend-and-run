extends SceneTree
var errors: Array = []
func check(ok: bool, message: String):
 if not ok: errors.append(message)
func _initialize():
 call_deferred("run_checks")
func run_checks():
 var args = OS.get_cmdline_user_args()
 if args.size() != 3:
  printerr("Expected GLB CONTRACT REPORT"); quit(2); return
 var contract = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
 if not contract is Dictionary:
  printerr("Invalid contract"); quit(2); return
 var doc = GLTFDocument.new()
 var state = GLTFState.new()
 if doc.append_from_file(args[0],state) != OK:
  printerr("GLB load failed"); quit(1); return
 var model = doc.generate_scene(state)
 if model == null:
  quit(1); return
 root.add_child(model)
 await process_frame
 var meshes = model.find_children("*","MeshInstance3D",true,false)
 var skeletons = model.find_children("*","Skeleton3D",true,false)
 var players = model.find_children("*","AnimationPlayer",true,false)
 var report = {"engine":Engine.get_version_info().string,"meshes":[],"clips":[],"bones":[],"errors":errors}
 check(not meshes.is_empty(),"No mesh")
 for mesh in meshes:
  report.meshes.append(str(mesh.name))
  check(mesh.mesh != null,"Missing mesh resource: "+str(mesh.name))
  if mesh.mesh == null: continue
  check(mesh.mesh.get_surface_count() <= contract.get("max_materials_per_mesh",1),"Material budget: "+str(mesh.name))
  for s in mesh.mesh.get_surface_count():
   check(mesh.get_active_material(s) != null,"Missing material: "+str(mesh.name))
 for name in contract.get("required_meshes",[]):
  check(name in report.meshes,"Missing mesh: "+name)
 for name in contract.get("skinned_meshes",[]):
  var m = model.find_child(name,true,false)
  check(m is MeshInstance3D and m.skin != null,"Missing skin: "+name)
 check(model.find_children("*","CollisionObject3D",true,false).is_empty(),"Unexpected DCC collision object")
 var sk = skeletons[0] if not skeletons.is_empty() else null
 if contract.get("humanoid",false):
  check(sk != null,"Missing skeleton")
 if sk != null:
  for i in sk.get_bone_count(): report.bones.append(sk.get_bone_name(i))
  if contract.get("humanoid",false):
   var profile = SkeletonProfileHumanoid.new()
   var mapping = contract.get("bone_map",{})
   for i in profile.bone_size:
    if profile.is_required(i):
     var key = str(profile.get_bone_name(i))
     check(key in mapping and sk.find_bone(mapping.get(key,"")) >= 0,"Humanoid bone: "+key)
  for socket in contract.get("sockets",[]):
   var id = sk.find_bone(socket)
   check(id >= 0,"Missing socket: "+socket)
   if id >= 0:
    check((sk.global_transform*sk.get_bone_global_rest(id)).basis.get_scale().distance_to(Vector3.ONE)<0.001,"Socket scale: "+socket)
  if contract.has("front_bones"):
   var ids = contract.front_bones.map(func(n): return sk.find_bone(n))
   check(ids.size()==2 and ids[0]>=0 and ids[1]>=0,"Missing front markers")
   if ids.size()==2 and ids[0]>=0 and ids[1]>=0:
    var direction = (sk.global_transform.basis*(sk.get_bone_global_rest(ids[1]).origin-sk.get_bone_global_rest(ids[0]).origin)).normalized()
    check(direction.x>0.99,"Front must point +X")
    report.front = [direction.x,direction.y,direction.z]
 if contract.has("bounds_mesh"):
  var mesh = model.find_child(contract.bounds_mesh,true,false)
  check(mesh is MeshInstance3D,"Missing bounds mesh")
  if mesh is MeshInstance3D:
   var bb = rest_bounds(mesh)
   report.height_m = bb.size.y
   report.soles_y = bb.position.y
   check(abs(bb.size.y-contract.height_m)<contract.get("tolerance_m",0.01),"Height out of tolerance")
   check(abs(bb.position.y)<contract.get("tolerance_m",0.01),"Feet not on Y=0")
 for player in players:
  for name in player.get_animation_list():
   var animation = player.get_animation(name)
   report.clips.append(str(name))
   check(animation.length>0,"Empty animation: "+name)
   for track in animation.get_track_count():
    var path = animation.track_get_path(track)
    check(player.get_node(player.root_node).get_node_or_null(NodePath(path.get_concatenated_names())) != null,"Broken animation node: "+str(path))
 for name in contract.get("clips",[]): check(name in report.clips,"Missing clip: "+name)
 for name in contract.get("clip_lengths",{}):
  var found = false
  for player in players:
   if player.has_animation(name):
    found = true
    check(abs(player.get_animation(name).length-contract.clip_lengths[name])<0.002,"Clip duration: "+name)
  check(found,"Missing timed clip: "+name)
 report.result = "PASS" if errors.is_empty() else "FAIL"
 report.manual_review = ["Art quality and motion feel", "Caps/severance in gameplay", "Front direction for assets without front markers"]
 var out = FileAccess.open(args[2],FileAccess.WRITE)
 if out == null:
  printerr("Cannot write report"); quit(2); return
 out.store_string(JSON.stringify(report,"  ")); out.close()
 print(JSON.stringify(report))
 model.queue_free()
 quit(0 if errors.is_empty() else 1)
func rest_bounds(mesh: MeshInstance3D) -> AABB:
 var bb = AABB()
 var first = true
 var sk = mesh.get_node_or_null(mesh.skeleton)
 for surface in mesh.mesh.get_surface_count():
  var a = mesh.mesh.surface_get_arrays(surface)
  var vertices = a[Mesh.ARRAY_VERTEX]
  var bones = a[Mesh.ARRAY_BONES]
  var weights = a[Mesh.ARRAY_WEIGHTS]
  for i in vertices.size():
   var p = mesh.global_transform*vertices[i]
   if mesh.skin != null and sk is Skeleton3D and bones != null and bones.size()>0:
    p = Vector3.ZERO
    var influences = bones.size()/vertices.size()
    for j in int(influences):
     var bind = bones[i*int(influences)+j]
     var name = mesh.skin.get_bind_name(bind)
     var id = sk.find_bone(name) if name != "" else mesh.skin.get_bind_bone(bind)
     if id<0:
      check(false,"Invalid skin binding"); continue
     p += (sk.global_transform*sk.get_bone_global_rest(id)*mesh.skin.get_bind_pose(bind)*vertices[i])*weights[i*int(influences)+j]
   if first:
    bb = AABB(p,Vector3.ZERO); first=false
   else: bb=bb.expand(p)
 return bb
