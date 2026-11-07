extends Node
var failures := 0
func check(label: String, ok: bool) -> void:
 print("V46 %s %s" % ["PASS" if ok else "FAIL", label])
 if not ok:failures += 1
func run() -> void:
 var main = get_parent();var route = main.route;var player = main.player
 main.set_process(false);route.set_process(false);player.set_physics_process(false)
 for foe in route.enemies:foe.set_physics_process(false)
 main.pause_controller.set_process_input(false);main.pause_controller.resume()
 get_viewport().size = Vector2i(960, 540)
 await get_tree().physics_frame
 var cam: Camera3D = main.get_node("Camera3D")
 var foe = route.enemies[2]
 foe._state = foe.WINDUP;foe._ranged_attack = true;foe._attack_front = -1;foe._state_t = 0.2
 var edge: float = foe._west_edge()
 foe.global_position = Vector3(edge+6,0,0)
 player.global_position = Vector3(edge+1,0,0);cam.global_position = Vector3(edge+1,1.2,5.8)
 var left = route.edge_warnings[0];var right = route.edge_warnings[1]
 route._update_edge_warnings()
 check("offscreen charging guard warns right",right.visible and not left.visible and not right.is_locked())
 foe._state_t = 0.6;route._update_edge_warnings()
 check("committed guard turns edge white",right.is_locked())
 if DisplayServer.get_name() != "headless":
  await get_tree().process_frame
  RenderingServer.force_draw(false)
  get_viewport().get_texture().get_image().save_png(OS.get_environment("V46_OUTPUT")+"/right_locked.png")
 foe._stun = 0.2;route._update_edge_warnings()
 check("interrupt removes threat",not right.visible)
 foe._stun = 0;foe._dead = true;route._update_edge_warnings()
 check("dead attacker never warns",not right.visible)
 foe._dead = false;foe._state = foe.RECOVERY;route._update_edge_warnings()
 check("finished charge clears warning",not right.visible)
 foe._state = foe.WINDUP;foe.global_position.x = edge+1;route._update_edge_warnings()
 check("visible attacker uses world cue only",not right.visible and not left.visible)
 foe.global_position.x = edge-8;foe._attack_front = 1;route._update_edge_warnings()
 check("left offscreen direction is correct",left.visible and not right.visible)
 foe._attack_front = -1;route._update_edge_warnings()
 check("attacker facing away does not warn",not left.visible)
 foe._attack_front = 1;player._dying = true;route._update_edge_warnings()
 check("player death clears warning",not left.visible)
 player._dying = false
 # Put the same charging guard across the real solid cover, beyond the camera.
 var cover_x: float = route.get_node("SecurityCover").global_position.x
 player.global_position.x = cover_x-1.8;cam.global_position.x = cover_x-1.8;foe.global_position.x = cover_x+5.2;foe._attack_front = -1
 await get_tree().physics_frame
 route._update_edge_warnings()
 check("solid cover suppresses blocked charge",not right.visible and not left.visible)
 player.global_position.x = edge+1;cam.global_position.x = edge+1;foe.global_position.x = edge+6
 route._update_edge_warnings();check("clear lane restores warning",right.visible)
 get_tree().paused = true
 check("pause notification clears warning",not right.visible)
 get_tree().paused = false;route._update_edge_warnings()
 route.completed = true;route._update_edge_warnings()
 check("completed sector clears warning",not right.visible)
 print("V46 SUMMARY failures=",failures);get_tree().quit(1 if failures else 0)
