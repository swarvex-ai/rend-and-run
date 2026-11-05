extends RefCounted
## Where the route places its props, pickups, benches, checkpoints, drones and PA cues.
## lab_route.gd reads everything from here; a new prop is a data change, not a code change.
## Encounters (robots) and the arena live in res://modules/world/notstrom_layout.gd.
## Units: metres along the route (x), height (y), depth into the scene (z, negative = back).

# Pickups and benches
const ARM_PICKUP_POS := Vector3(1.8, 0.05, -0.55)          # robot arm on the storage table
const FIRST_SALVAGE_POS := Vector3(8.5, 0.28, 0)           # default spot of the first guard's shards
const SHIELD_POS := Vector3(24, 0, 0)                      # salvage shield on the main path
const CACHE_POS := Vector3(18, 0, 0)                       # lab armour plinth
const ENTRY_WORKBENCH_POS := Vector3(8.9, 0, 0)            # workbench in the first room
const WORKBENCH_POS := Vector3(28.5, 0, 0)                 # lab workbench (reinforced arm)
const GUN_BENCH_POS := Vector3(51.5, 0, 0)                 # weapon bench: gun mods for shards

# Checkpoints and the shortcut
const CHECKPOINT_POS := Vector3(26, 0.05, 0)               # respawn point of the first checkpoint
const CHECKPOINT_CONSOLE_POS := Vector3(26, 0, -0.85)
const RELAY_CHECKPOINT_POS := Vector3(58, 0.05, 0)         # respawn point of the relay checkpoint
const RELAY_CONSOLE_POS := Vector3(58, 0, -0.85)
const SHORTCUT_POS := Vector3(16.5, 0, 0)                  # maintenance door back toward the start

# Breakable and movable props
const CRATE_POSITIONS := {"entry_supply": Vector3(4, 0, 0), "maintenance_supply": Vector3(21.5, 0, 0), "exit_supply": Vector3(67, 0, 0), "freight_supply": Vector3(54, 0, 0)}
# Loose supply cases Rend can shove, lift and throw, against the back of the floor strip:
# [x, stack height]. One stands in the first room to learn it on.
const THROWABLE_STACKS := [[3.0, 1], [20.6, 2], [25.9, 1], [37.4, 2], [44.1, 1], [49.3, 2], [60.8, 1], [66.4, 2], [73.6, 1]]
const COOLANT_CANISTER_POS := Vector3(37.1, 0, 0)
const SECURITY_COVER_POS := Vector3(40.8, 0, 0)
const FREIGHT_COVER_XS := [46.0, 60.0]                     # sightline breaks in the freight rooms

# Lights and dressing with a fixed place on the route
const SERVICE_LAMP_XS := [3.0, 26.0, 39.0, 50.0, 63.0, 78.0]
const DAMAGED_CABLE_POS := Vector3(4.65, 2.85, -1.35)

# Robots outside the mission count
const AWAKENING_X := 37.2                                  # half-built humanoid that drops off its hook
# Kamikaze drones over the security wing and the relay corridor (the night shift has its
# own pair in power_sector.gd). They wake when Rend comes within reach.
const WING_DRONES := [Vector3(45.5, 2.2, 0), Vector3(62.0, 2.5, 0)]
# When an encounter's robot first engages Rend, these run in from off screen on the far
# side of him. encounter id -> [[role, gun, shield], ...]
const REINFORCEMENTS := {
	"duelist": [[0, "", false]],
	"guard": [[0, "", false]],
	"freight_raider": [[1, "", true]],
	"relay_guard": [[0, "", false], [1, "", false]],
}
const REINFORCE_DISTANCE := 10.0

# PA announcements as Rend reaches each part of the plant: [x, voice key]
const PA_CUES := [[16.8, "lockdown"], [30.5, "assembly"], [44.5, "intact"], [57.5, "capture"], [69.0, "airlock"]]
