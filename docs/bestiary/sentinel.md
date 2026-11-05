# Sentinel
The sentinel is an optional role 1 robot (game/modules/combat/sentinel.gd:27) that sleeps in a wall alcove, wakes when Rend runs past or comes close, steps out and fights unarmed with a punch and an elbow.

## Role in milestone 1
The sentinel is an optional route robot outside the mission count (game/lab_route.gd:665-666). Its script sets `role = 1` (game/modules/combat/sentinel.gd:27), `hp = 4` and `speed = 4.3` (game/modules/combat/sentinel.gd:29), and attaches no weapon (game/modules/combat/sentinel.gd:65-66). Once AWAKE, movement, spacing and the attack state machine are as guard (game/enemy.gd:282-467); only the wake-up, head ring, 4 HP (game/modules/combat/sentinel.gd:29) and unarmed strikes differ.

## Behaviour
Each sentinel spawns asleep at z = -2.3 m (game/lab_route.gd:672) with ring level 0.0 (game/modules/combat/sentinel.gd:133). It compares dx = |player.x - sentinel.x| and XZ floor distance (game/modules/combat/sentinel.gd:135-136). It wakes when Rend runs faster than 3.6 m/s within 2.6 m in x (game/modules/combat/sentinel.gd:9-10), or comes within 1.6 m on the floor (game/modules/combat/sentinel.gd:14); a dying Rend is ignored (game/modules/combat/sentinel.gd:134). `provoke()` calls `wake()` (game/modules/combat/sentinel.gd:105-108); a melee hit before AWAKE goes straight to STEPPING (game/modules/combat/sentinel.gd:118-122).

Waking plays `combat/alert` and the wake line/sound (game/modules/combat/sentinel.gd:112-116). For 0.5 s the ring flickers on while climbing from level 0.2 to 1.0 (game/modules/combat/sentinel.gd:141-142). After ALERT_TIME 1.1 s (game/modules/combat/sentinel.gd:11) it enters STEPPING (game/modules/combat/sentinel.gd:144-146).

Stepping holds the ring at level 1.0 (game/modules/combat/sentinel.gd:148), moves toward +Z at 1.6 m/s (game/modules/combat/sentinel.gd:12,150) and joins the strip at z at least -0.7 m (game/modules/combat/sentinel.gd:13,154). Then it is AWAKE and enters CHASE (game/modules/combat/sentinel.gd:155-156); afterwards the ring is level 1.0, red in WINDUP and SWING and otherwise idle cyan (game/modules/combat/sentinel.gd:125-128).

## Attacks and tells
The sentinel uses only the unarmed `punch` and `elbow`, alternating (game/modules/combat/sentinel.gd:97-103). WINDUP starts the chevron for its duration (game/enemy.gd:489-491) and turns the ring red (game/modules/combat/sentinel.gd:127), while the body holds the strike pose (game/enemy.gd:507-510). Its windup is 0.40 s (game/enemy.gd:1146), swing 0.2 s (game/enemy.gd:52), the single hit check 0.075-0.15 s (game/enemy.gd:408), and recovery 0.32 s (game/enemy.gd:1149). Every second attack is the role-1 low variant (game/enemy.gd:1102-1103): crouched, legs from 0.05 m to 0.55 m (game/enemy.gd:610-611), with the low cue (game/enemy.gd:1106).

| attack | tell (what the player sees/hears) | tell duration (s) | hit window (s) | counter |
|---|---|---|---|---|
| `punch`, head 1.10-1.75 m (game/enemy.gd:78) | red ring, high chevron, wound-up pose (game/modules/combat/sentinel.gd:127; game/enemy.gd:490-491,507-510) | 0.40 (game/enemy.gd:1146) | 0.20 swing (game/enemy.gd:52); check 0.075-0.15 (game/enemy.gd:408) | leave 1.45 m reach (game/enemy.gd:55) or 0.55 m depth (game/enemy.gd:78); interrupt for 0.28 s stun (game/enemy.gd:724) |
| `elbow`, torso 0.90-1.60 m (game/enemy.gd:79) | red ring, high chevron, elbow pose (game/modules/combat/sentinel.gd:127; game/enemy.gd:490-491,507-510) | 0.40 (game/enemy.gd:1146) | 0.20 swing (game/enemy.gd:52); check 0.075-0.15 (game/enemy.gd:408) | leave 1.45 m reach (game/enemy.gd:55) or 0.50 m depth (game/enemy.gd:79); punish 0.32 s recovery (game/enemy.gd:1149) |

## How Rend beats it
Its 4 HP (game/modules/combat/sentinel.gd:29) fall to 1 damage per hit, or 2 with the reinforced arm (game/player.gd:887). No shield (game/enemy.gd:34) and no gun mean frontal hits land. It cannot start an attack outside 1.45 m reach (game/enemy.gd:55) and 0.35 m strike depth (game/enemy.gd:57); its blows connect only within 0.55 m or 0.50 m depth (game/enemy.gd:78-79). A hit in windup or swing cancels it into RECOVERY and stuns 0.28 s, or 0.50 s after 2 damage (game/enemy.gd:713,724-725); role 1 has no attack momentum (game/enemy.gd:1160-1161). Punish the 0.32 s recovery (game/enemy.gd:1149). A hit while ASLEEP goes straight to STEPPING (game/modules/combat/sentinel.gd:118-122); blows can be parried (game/player.gd:900-909).

## Drops
The sentinel has no weapon (game/modules/combat/sentinel.gd:65-66), no shield (game/enemy.gd:34) and no gun, so `_drop_weapon()` and `_drop_shield()` do nothing (game/enemy.gd:846-847,903-904,966). Its `defeated` signal goes only to `_last_of_the_fight` (game/lab_route.gd:675), slow motion (game/lab_route.gd:411-415), not to `_enemy_defeated` (game/lab_route.gd:163), which credits 3 shards to other encounters (game/lab_route.gd:434). It is destroyed and breaks into plating, servos and cable (game/enemy.gd:848-860).

## Sound and voice
Waking forces "intruder" (game/modules/combat/sentinel.gd:114-115), subtitled "Intruder detected." (game/modules/audio/robot_voice.gd:13), plus a block sound (game/modules/combat/sentinel.gd:116). First CHASE tries a taunt (game/enemy.gd:493-494); the shared 3.2 s quiet (game/modules/audio/robot_voice.gd:23) can suppress non-forced lines (game/modules/audio/robot_voice.gd:40). When badly damaged it says "damage", "Damage critical." (game/enemy.gd:743; game/modules/audio/robot_voice.gd:12). SWING starts "swing" (game/enemy.gd:495-497); contact plays "hit" and 0.25 shake (game/enemy.gd:618-619); destruction plays "die" and metal contact (game/enemy.gd:872,876).

## Where it appears
The route places a sentinel per open alcove (game/lab_route.gd:668-676); the bay list has two (game/modules/world/factory_corridor.gd:10). Their x positions are 45.85 m and 63.55 m (computed by `alcove_xs()` at game/modules/world/factory_corridor.gd:156-159 from FIRST_BAY_X 16.35 m (game/modules/world/factory_corridor.gd:7), BAY_PITCH 5.9 m (game/modules/world/factory_corridor.gd:6) and indices 5 and 8 (game/modules/world/factory_corridor.gd:10)). They spawn at z = -2.3 m (game/lab_route.gd:672).

## Gaps against the brief
Pillar 2 requires every attack to announce itself (docs/project-brief.md:51), but no repository file gives a minimum time; the milestone-1 half-second rule is from the task, not a repo file. Every attack, including the low variant, has a 0.40 s windup (game/enemy.gd:1146) and first contact 0.075 s into the 0.2 s swing (game/enemy.gd:408,52), so all fall short. The only pre-hit light is the ring and chevron; the swing sound starts at SWING (game/enemy.gd:495-497).

The nearby WINDUP_S 0.5 s (game/enemy.gd:51), RECOVERY_S 0.8 s (game/enemy.gd:54) and SWING_CONTACT 0.12 s (game/enemy.gd:53) are unused; actual values are 0.40 s (game/enemy.gd:1146), 0.32 s (game/enemy.gd:1149) and 0.075-0.15 s (game/enemy.gd:408).

## Open questions for neVs
1. Raise the tell to the half-second minimum, or keep the ring and chevron?
2. Should hitting the sleeping sentinel skip WAKING, or grant the full alert and voice?
3. Should the low variant stay, or only punch and elbow at normal height?
4. Should destroying a sentinel award shards, or stay reward-free?
5. Should sentinels count toward mission totals, or remain optional?
