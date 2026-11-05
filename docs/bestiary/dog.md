# Dog
The **dog** is the four-legged robot of the first route: a fast chaser that attacks in a fixed bite-arm-bite rhythm and announces both blows with pose and amber light.

## Role in milestone 1
The dog is the hound encounter at x = 43.5 m (game/modules/world/notstrom_layout.gd:13). It is the route's fast low pressure robot: 5.2 m/s (game/modules/combat/enemy_dog.gd:29), 2 HP (game/enemy.gd:17), forcing Rend to jump or dodge depending on the committed attack. As a robot it breaks apart, never bleeds.

## Behaviour
The dog notices Rend within 10.0 m horizontally and 2.5 m in depth (game/enemy.gd:48, game/enemy.gd:49), then waits 0.25 s in ALERT before chasing (game/enemy.gd:50). It closes at 5.2 m/s (game/modules/combat/enemy_dog.gd:29), starts an attack when it is within 2.1 m (game/enemy.gd:324) and within 0.6 m in depth (game/modules/combat/enemy_dog.gd:85). The order is bite, arm swipe, bite, and the first attack is the bite (game/modules/combat/enemy_dog.gd:75); without its arm it only bites (game/modules/combat/enemy_dog.gd:77). Each attack runs WINDUP, a 0.2 s SWING (game/enemy.gd:52) with one hit check 0.075–0.15 s into that swing (game/enemy.gd:408), then a 0.55 s recovery (game/modules/combat/enemy_dog.gd:91). The bite pounces with 2.3 m reach; the arm swipe reaches 1.7 m (game/modules/combat/enemy_dog.gd:81). A hit gives the dog a nose-up pitch and roll flinch that springs back (game/modules/combat/enemy_dog.gd:96-104). On death it breaks apart: the body becomes a ragdoll with folded legs and the arm tears off (game/modules/combat/enemy_dog.gd:169-205).

## Attacks and tells
| attack | tell (what the player sees/hears) | tell duration (s) | hit window (s) | counter |
|---|---|---|---|---|
| bite (pounce) | Dog crouches into the lunge clip and a low amber chevron appears in front of it (game/modules/combat/enemy_dog.gd:155, game/modules/vfx/enemy_attack_cue.gd:25). | 0.5 (game/modules/combat/enemy_dog.gd:88) | 0.075–0.15 into the following swing (game/enemy.gd:408) | jump or dodge |
| arm swipe | Dog plants its feet while the back arm cocks; the claw sensor flares amber and a high amber chevron appears (game/modules/combat/enemy_dog.gd:135-136, game/modules/combat/enemy_dog.gd:143-149, game/modules/vfx/enemy_attack_cue.gd:25). | 0.48 (game/modules/combat/enemy_dog.gd:88) | 0.075–0.15 into the following swing (game/enemy.gd:408) | duck or dodge |

The windup itself makes no sound: the only attack sound is the `swing` effect played when SWING is entered (game/enemy.gd:497).

## How Rend beats it
The bite's hit band is 0.05–0.55 m above the dog's soles (game/enemy.gd:610, game/enemy.gd:611). Standing Rend is 1.65 m tall and crouched Rend is 1.05 m tall (game/player.gd:211), so both overlap that band: ducking does not avoid the bite, which `hound_test.gd` confirms (game/tests/hound_test.gd:42). Jumping lifts Rend's feet above 0.55 m and clears it (game/tests/hound_test.gd:50). The arm swipe uses the `slash` band at 1.10–1.55 m (game/enemy.gd:72); crouched Rend's top at 1.05 m is below the 1.10 m lower edge (game/player.gd:211, game/enemy.gd:72), so ducking works, while standing Rend is hit. Both attacks can be dodged: a dodge grants 0.14 s of invulnerability (game/player.gd:246), and `take_damage` ignores damage while that timer runs (game/player.gd:898).

## Drops
The dog carries no gun and no shield: it overrides weapon attachment with an empty function (game/modules/combat/enemy_dog.gd:72-73), so the inherited weapon drop returns without a pickup (game/enemy.gd:904). Clearing the hound encounter adds 3 shards through the route's non-first-encounter branch (game/lab_route.gd:434); unlike the first guard's salvage it is not spawned as a collectable pickup (game/lab_route.gd:430). The torn-off arm becomes non-pickable physics debris for 9.0 s (game/modules/combat/enemy_dog.gd:205), and the mechanical body is removed after 6.0 s (game/enemy.gd:885).

## Sound and voice
The dog uses the shared robot voice: its first CHASE says a taunt (game/enemy.gd:494), and at 1 HP it says "Damage critical" (game/enemy.gd:743). The swing has a whoosh on SWING entry (game/enemy.gd:497); a landed hit plays the hit sound and adds shake (game/enemy.gd:618, game/enemy.gd:619). Death plays a sound and metal contact (game/enemy.gd:872, game/enemy.gd:876), and tearing off the arm emits metal contact (game/modules/combat/enemy_dog.gd:203). It has no dog-specific voice lines.

## Where it appears
A single dog is authored for the route: encounter `hound`, x = 43.5 m, territory minimum x = 38.0 m (game/modules/world/notstrom_layout.gd:13). The route creates it from that spec (game/lab_route.gd:155). Once engaged it may pursue 4 m past its territory line (game/lab_route.gd:162), but stops 2 m short of a checkpoint (game/lab_route.gd:161). No other encounter lists the dog script.

## Gaps against the brief
The arm swipe is the only attack whose windup/tell is shorter than 0.5 s: 0.48 s (game/modules/combat/enemy_dog.gd:88) against the bite's 0.5 s (game/modules/combat/enemy_dog.gd:88). It still cannot hit during that windup, because the first hit check is 0.075 s into the following swing (game/enemy.gd:408); measured from the start of the tell to the first possible hit, both attacks leave more than the required lead. If the milestone rule is meant to cover the windup animation itself, the arm swipe is the one gap. No other gap against the readable-danger pillar was found in the code; both tells are visual only.

## Open questions for neVs
1. Should the arm swipe's 0.48 s windup be raised to 0.5 s (game/modules/combat/enemy_dog.gd:88), or is the later 0.075 s hit-check delay (game/enemy.gd:408) enough for the milestone rule?
2. Should the dog make a windup sound before the swing, or are the chevron and claw flare sufficient?
3. Should the torn-off arm stay debris for 9.0 s (game/modules/combat/enemy_dog.gd:205), or become something Rend can pick up?
4. Should the dog appear only once at x = 43.5 m (game/modules/world/notstrom_layout.gd:13), or also return as a reinforcement?
5. Is the 3-shard reward (game/lab_route.gd:434) intended for the hound encounter, and should it be a pickup instead of a direct credit?