# Water Creature — Roblox game

You play a fish, swimming an open sea, destroying rafts and ships loaded
with humans. Every human aboard something you destroy pays out Money and
XP (scaled by your shop upgrades). XP levels you up; every **12 levels**
your fish **evolves** into a tougher-looking, faster tier — and your Level
resets to 1 so you level up again within the new tier. Money buys permanent
upgrades in an in-game shop, and Robux buys real-money "super powers".

## Getting into the water

You don't spawn directly in the ocean. Every join (and every respawn) drops
you inside a translucent glass cube floating high in the sky above the map:
an invisible, walkable floor (`Transparency = 1`, `CanCollide = true`, so
you can stand on it while seeing straight through it to the ocean far
below, edges outlined by a thin glow) enclosed by glass walls/ceiling and
four glowing corner pillars. A ring portal — an outer metal frame, a
spinning inner glow ring, and a glowing center disc, all facing back toward
the platform so it reads face-on rather than edge-on — sits in the middle
of the cube. Touching it opens a **species-choice panel**; pick a creature
and the server teleports you down to the water surface as that species.
Every respawn goes through this same flow, so you can switch species any
time you die and come back through the portal.

## Species: what you can be

Two free starters, chosen right at the portal:

| Species | Body style | Look |
|---|---|---|
| **Fish** | streamlined (elongated body, pointed snout, forked tail) | blue → gray shark progression |
| **Sea Horse** | serpentine (upright body, forward snout, coronet, curled tail) | tan → purple → green → teal |

A third, **Dolphin** (also streamlined, gray → orca-black progression), is
locked until bought in the shop's **Creatures** tab (600 Money) — see
`Config.Species` in `GameConfig.lua` to add more.

Each species has its own 6-tier look, built entirely from primitive Parts
(`CreatureAppearance.lua`) — no custom mesh upload was available from here,
so this is the closest a script alone can get to "looks like a fish/sea
horse/dolphin." The default avatar's own parts (head, torso, arms, legs)
are made fully invisible but stay physically in place — movement,
swimming, and collision are completely untouched — and a separate model,
welded to the (now invisible) torso, is what's actually rendered. The
tail (streamlined species) or dorsal fin (Sea Horse) gently wags via a
Motor6D-driven sine wave for a swimming animation — everything else on the
body uses simpler static WeldConstraints. It works on both R6 and R15
avatars (the body welds to whichever torso the rig has); on a rig where
`Model:ScaleTo` doesn't apply cleanly to the (invisible, physical) collision
size, the body still shows at full size, only the *collision hitbox*
growth is skipped for that player (logged as a warning, not an error).

Your **evolution tier** (0–5) is shared across every species — switching
species is a pure reskin, never a progress reset. Size, shape, color, and
(on the final tier) a soft glow all change with tier:

| Evolution tier | Level range | Fish body | Attack |
|---|---|---|---|
| 0 | 1–11 | small, stubby | Nibble (melee) |
| 1 | 1–11 (after reset) | long and sleek | Lunge Strike (dash) |
| 2 | 1–11 | broader, shark-shaped | Spin Bite (AOE) |
| 3 | 1–11 | bigger shark | Crushing Jaws (melee) |
| 4 | 1–11 | huge, toothy | Tidal Slam (AOE) |
| 5 | 1–50 (final, no more resets) | biggest, spiked, glowing | Abyssal Roar (AOE) |

The body is rebuilt (and resized) on every level-up, shop purchase, and
respawn — not just at evolution — so growth is smooth throughout, not just
a jump at each evolution boundary.

Evolving happens on the level-up that would otherwise take you to level
`LevelsPerEvolution` (12 by default) — using the same normal per-level XP
cost as any other level-up, not an extra chunk on top. An earlier version
required a full *additional* level's worth of XP (the single largest chunk
in the whole curve) after already reaching level 12 before evolving, with
zero visible feedback in between — it looked completely stuck. Progress
toward your next level/evolution is now always visible via the XP bar in
the HUD (bottom-left).

Each evolution keeps your Money, all shop upgrade tiers, and every species
you've unlocked — only Level and XP reset, and each tier's base speed/size
is higher than the last, so it's a "prestige," not a punishment.

## PvP: evolution-based attacks

Press **F** to attack. Every evolution tier grants a different attack
(`Config.TierProgression[i].Attack`, shared by every species — see the
table above), and evolving swaps yours immediately — `PlayerCombat.server.lua`
always reads your *current* tier live, there's no separate "equip" step.

Fully server-authoritative (the client only requests an attack — cooldown,
targets, and damage are all decided server-side) and damage is reduced by
the target's **Scales** upgrade / Golden Scales, same as ship combat. An
expanding colored ring shows where an attack landed. The sky spawn platform
is a safe zone — nothing up there can attack or be attacked, so you can't
get spawn-killed before reaching the portal. Your own health bar (and
current attack name) show bottom-left.

## Targets: rafts vs. ships

- **Rafts** — small, one touch destroys them, carry 2–6 humans. Safe,
  low-risk income.
- **Ships** — five types, each a different size and color, with a Health
  bar shown above the hull:
  - **Sloop** (brown, 8–12 humans) — no cannon, just tougher than a raft.
  - **Brigantine** (olive, 10–15 humans) — no cannon, a step up from Sloop.
  - **Frigate** (dark gray, 12–18 humans) — has cannons.
  - **Galleon** (red/gold, 18–26 humans) — has cannons, lots of humans/Health.
  - **Man-of-War** (dark brown, 26–36 humans) — the biggest and toughest,
    heaviest cannons, rarest spawn.

  Every ram hit you land also lands one back on you (contact damage), and
  cannon-equipped types additionally fire a short-range cannonball at
  whichever player is nearest (only within their `CannonRange`, ~55-75
  studs, on a cooldown) — visible cannon barrels stick out both sides of
  their hull. Upgrading **Bite Power** lowers how many hits a ship takes to
  sink; **Scales** cuts damage from both ramming and cannon fire.
  - Every type has a pointed bow, a two-level cabin, deck railings, a
    bowsprit, portholes, and 1–3 masts with square sails (scaling with ship
    size) each flying a flag on the main mast — plus a foam wake trail at
    the bow. They slowly patrol in a small circle around where they spawned
    (`ShipMovement.server.lua`) instead of sitting still — `Model:PivotTo()`
    moves the whole ship (hull, cabin, masts, cannons, humans, health bar,
    wake) as one rigid group each tick, no physics needed. Every decoration
    is built in one pcall-wrapped pass, so a mistake in any single piece
    can't stop a ship from spawning with its working hitbox/health/humans
    intact.

## The world

- **Corals** — ~150 small decorative clusters (branch coral, brain coral,
  sea rods) plus 15 big centerpiece formations (coral towers, fan corals,
  giant clams with a glowing pearl) scattered across the seabed, all
  non-collidable so they never block swimming (`CoralGarden.server.lua`).
- **Islands** — 6 small rock/sand/grass islands ringing the outer play area
  (`GraphicsPolish.server.lua`).
- **Map barrier** — a hollow sand wall filled right at the edge of the water
  block (`WorldSetup.server.lua`), so you can't swim past the play area.
  50 jagged rock bumps are scattered along its inner face at varied sizes
  and heights (`GraphicsPolish.server.lua`) so it reads as a rocky
  coastline instead of one flat block.

## The shop

Click the **🛒 Shop** button (bottom-right) — a panel with three tabs, a
live Money readout in the header, color-accented cards, and hover states.

### Upgrades (Money)

Six stat upgrades, 9 tiers each, rising Money cost:

| Upgrade | Effect |
|---|---|
| ⚔️ **Bite Power** | More damage per hit against ships (fewer hits to sink one) |
| ❤️ **Vitality** | More max health |
| 🛡️ **Scales** | % damage reduction from ships, cannon fire, and PvP |
| 🐟 **Fins** | Extra swim speed, stacking with evolution/level speed |
| 💰 **Greed** | % more Money per human destroyed |
| ✨ **Wisdom** | % more XP per human destroyed |

Purchases are server-validated (the client only *requests* a purchase; the
server checks your Money and applies the tier) and persist across
respawns, evolutions, **and** species switches.

### Creatures (Money)

Buy permanent access to non-starter species — currently just **Dolphin**
(600 Money). Buying doesn't select it; walk through the portal afterward to
actually choose it. Add more by adding entries to `Config.Species` with
`ShopCost > 0`.

### Robux Shop

The **Robux Shop** tab lists four real-money "super powers":

| Power | Effect |
|---|---|
| 2x Money (30 min) | Doubles Money earned for 30 minutes |
| 2x XP (30 min) | Doubles XP earned for 30 minutes |
| Depth Charge | Instantly sinks the next ship you touch, any Health |
| Golden Scales | Permanent +25% damage reduction, forever, plus a gold look |

**This needs one manual setup step before it can actually be bought.**
Every entry in `Config.RobuxProducts` (in `GameConfig.lua`) has
`ProductId = 0` — a placeholder. Real Developer Product IDs can only be
created from inside Studio's **Monetization** tab, which requires the place
to be published to a Roblox account (something outside what a script here
can do for you). Once you:

1. Publish the place,
2. Create a Developer Product for each entry (Monetization tab → Create),
3. Paste each real product's ID into the matching `ProductId` field,

...purchases work immediately — clicking Buy calls
`MarketplaceService:PromptProductPurchase`, and `ProcessReceipt` (in
`RobuxShop.lua`) grants the effect.

**Also note:** this project has no save/DataStore system yet, for *anything*
(Level, Money, upgrades, or Robux perks) — progress lives only for the
current server session. Add DataStore-backed saving (and record processed
receipts in it) before shipping this with real purchases, so a purchased
perk — or a receipt retried after a crash — is never lost or double-granted.

## Graphics

`WorldSetup.server.lua` tunes Terrain water (color, transparency,
reflectance, wave size/speed) and Lighting (time of day, ambient, fog,
an `Atmosphere` instance) for a proper ocean look, no assets required.

`GraphicsPolish.server.lua` layers on more, entirely separately (see below
for why): post-processing (bloom, color grading, subtle sun rays), 6 small
rock/sand/grass islands ringing the outer play area for visual variety, and
ambient rising bubbles underwater (using the engine's own built-in particle
texture, not an uploaded one).

**A hard ceiling worth being upfront about:** true "Blox Fruits" fidelity —
custom-sculpted islands, custom character/fruit/weapon 3D models, custom
skybox art, custom sound — comes from uploaded meshes, textures, and audio
made in external 3D/art tools, then imported via Studio. That's not
something a script (or this environment) can produce; everything above is
built purely from Roblox's primitives and built-in effects. It's a real
step up from flat/default, not a ceiling-hitting match for a game with a
professional art team.

## How it works

- `src/ReplicatedStorage/Modules/GameConfig.lua` — every tunable number
  (spawn rates, ship types, payouts, evolution tiers, upgrade costs, Robux
  products)
- `src/ServerScriptService/WorldSetup.server.lua` — water/Terrain + Lighting
  + sand map barrier, once, on first run
- `src/ServerScriptService/CoralGarden.server.lua` — scatters decorative
  coral across the seabed, once, on first run
- `src/ServerScriptService/GraphicsPolish.server.lua` — post-processing,
  small islands, and ambient bubbles, once, on first run (independent of
  WorldSetup, so a mistake here can't take down the core water generation)
- `src/ServerScriptService/SkySpawn.server.lua` — the sky spawn area: a
  translucent glass cube (walls + ceiling + glowing corner pillars) with a
  double-ring glowing portal inside; touching it prompts species choice,
  then teleports down to the water
- `src/ServerScriptService/Modules/PlayerSpecies.lua` — each player's owned
  species (a replicated `Species` folder of BoolValues) and their currently
  selected species (a `SelectedSpecies` attribute); validates
  selection/purchase server-side
- `src/ServerScriptService/RaftSpawner.server.lua` / `RaftDestruction.server.lua`
  — spawns rafts and destroys them (+ pays out) on touch
- `src/ServerScriptService/ShipSpawner.server.lua` — spawns ships (5 types:
  Sloop, Brigantine, Frigate, Galleon, Man-of-War — random weighted pick,
  hull/cabin/mast/cannon barrels/flag/railings/bowsprit, health-bar
  billboard)
- `src/ServerScriptService/ShipMovement.server.lua` — slow circular patrol
  drift for every ship
- `src/ServerScriptService/ShipCombat.server.lua` — ramming combat, Depth
  Charge consumption, sinking + payout
- `src/ServerScriptService/ShipCannons.server.lua` — short-range cannon fire
  from Frigates/Galleons at the nearest player
- `src/ServerScriptService/PlayerCombat.server.lua` — PvP: validates attack
  requests, reads the attacker's current evolution tier live, applies
  damage to targets in range
- `src/ServerScriptService/Modules/PlayerProgress.lua` — leaderstats
  (`Level`, `Money`, `XP`, `Evolution`), leveling + evolution math, applying
  combined stats to the character
- `src/ServerScriptService/Modules/PlayerUpgrades.lua` — each player's
  upgrade tiers, purchase logic, damage-reduction/multiplier math
- `src/ServerScriptService/Modules/RobuxShop.lua` — Developer Product
  catalog handling, `ProcessReceipt`, granting super powers
- `src/ServerScriptService/Modules/CreatureAppearance.lua` — hides the
  default avatar and builds a distinct fish body model per species +
  evolution tier (streamlined body for Fish/Dolphin, serpentine curled-tail
  body for Sea Horse); wires up Motor6D "SwimMotor" joints on the tail/fin
  parts for the client-side swim animation
- `src/ServerScriptService/ShopHandler.server.lua` — validates/applies all
  three shop categories' purchase requests from the client (Upgrades,
  Creatures, Robux)
- `src/ServerScriptService/GameManager.server.lua` — wires player join/leave
  and character respawn into all of the above
- `src/StarterPlayer/StarterPlayerScripts/CreatureHud.client.lua` — pop-up
  feedback, evolution banner, Depth Charge counter, health bar, current
  attack name
- `src/StarterPlayer/StarterPlayerScripts/AttackController.client.lua` —
  attack input (F key) and the expanding-ring attack visual effect
- `src/StarterPlayer/StarterPlayerScripts/UpgradeShop.client.lua` — the
  three-tab shop panel UI (Upgrades / Creatures / Robux), with a live Money
  readout and styled cards
- `src/StarterPlayer/StarterPlayerScripts/SpeciesSelect.client.lua` — the
  species-choice panel shown when touching the sky-spawn portal
- `src/StarterPlayer/StarterPlayerScripts/CreatureAnimator.client.lua` —
  drives the swim wag animation on every player's fish body each frame

Swimming itself needs no custom script — Roblox's default character
controller automatically swims whenever the character is inside Terrain
water, which `WorldSetup` generates for you.

## Just open it

**`WaterCreatureGame.rbxlx`** is a single, self-contained Roblox place file
with everything already built in — no Rojo, no manual setup:

1. Open Roblox Studio.
2. **File → Open From File...** and pick `WaterCreatureGame.rbxlx`.
3. Press **Play**. Ram a raft or ship to destroy it; click **Shop** to spend
   Money on upgrades or (once real Developer Product IDs are set, see
   above) Robux on super powers.

To publish it as a real game, once it's open: **File → Publish to Roblox...**

## Developing with Rojo (optional)

The `src/` folder holds the same scripts as loose files if you'd rather
edit them in a normal text editor and sync live into Studio:

1. Install the [Rojo](https://rojo.space/) plugin in Studio (and the Rojo
   CLI, e.g. `cargo install rojo` or via [Aftman](https://github.com/LPGhatguy/aftman)).
2. From this folder, start the server:
   ```bash
   rojo serve
   ```
3. In Studio, open (or create) a place, open the Rojo plugin panel, and
   click **Connect**.

If you edit `src/`, regenerate the single-file place with:

```bash
python3 tools/generate_rbxlx.py
```

This rebuilds `WaterCreatureGame.rbxlx` from whatever is currently in
`src/`, so the two never drift apart.

## Customizing

All gameplay tuning lives in `GameConfig.lua`:

| Setting | Effect |
|---|---|
| `RaftSpawnInterval`, `MaxRafts`, `ShipSpawnInterval`, `MaxShips` | how often/how many targets are on the water |
| `HumansPerRaftMin/Max`, `ShipTypes[i].HumansMin/Max` | humans per target (also the payout size) |
| `MoneyPerHuman`, `XPPerHuman` | base payout per human destroyed |
| `ShipTypes` | add/edit ship types — size, color, human count, cannon stats |
| `ShipContactDamage`, `ShipTouchCooldown` | ram danger and hit pacing |
| `ShipDriftRadiusMin/Max`, `ShipDriftDegreesPerSecondMin/Max` | how far/fast ships patrol |
| `LevelsPerEvolution` | when the fish evolves (every N levels) |
| `Config.XPForLevel(level)` | the XP curve between levels |
| `Config.Upgrades` (6 entries) | shop tier count, cost curve, per-tier effect |
| `Config.RobuxProducts` | the Robux shop catalog and each power's effect |
| `CoralCount`, `GiantCoralCount` | how many small/big decorative coral pieces to scatter |
| `IslandCount` | how many small islands ring the play area |
| `BarrierThickness`, `BarrierHeight` | the sand wall around the play area |
| `SkySpawnHeight`, `SkySpawnPlatformSize`, `SkySpawnPortalOffset` | the sky spawn platform + portal |
| `SkySpawnCubeHeight`, `SkySpawnPortalRadius` | the glass cube enclosing spawn + the ring portal's size |
| `Config.TierProgression[i].Attack` | each tier's attack — type, range, damage, cooldown (shared by every species) |
| `Config.TierProgression[i].SpeedBonus/.SizeBonus` | each tier's stat bonuses (shared by every species) |
| `Config.Species[key].Tiers[i].Body` | each species' per-tier fish body shape — length/width/height/snout, teeth/spikes/spines |
| `Config.Species[key].ShopCost` | Money cost to unlock a species (`0` = free starter) |
| `Config.SpeciesOrder`, `Config.StarterSpecies` | which species exist, and which are free from the start |
| `PvPSafeZoneY` | how high up the sky-spawn safe zone extends |
| `ShipTypes[i].MastCount`, `.SailColor` | how many masts/sails each ship type gets |

## Notes

- If a ship sinks from hits landed by more than one player, the final hit
  gets full credit for the reward (no split-credit system yet).
- The fish body welds to `UpperTorso` (R15) or falls back to `Torso` (R6),
  so it works on both rig types. There's no scripted way to force everyone
  onto R15 — that's a place-level setting only, in Studio's Game Settings →
  Avatar tab (Home → Game Settings), not something a Script can set. Not
  needed for the game to work (the fish model itself always shows at full
  size regardless of rig type), but if you want every player's underlying
  *collision hitbox* to scale identically too, set it there once, in
  Studio, on the published place.
- The map barrier is a square sand frame matching the water block's own
  footprint (not a circle), so there are no corner gaps to sneak through.
- `Workspace.FallenPartsDestroyHeight` isn't set anymore — writing it threw
  "lacking capability Plugin" (current Roblox security model restricts that
  property to Plugin-level code, not regular Scripts). It was only ever a
  minor debris-cleanup safety net; the sand barrier already keeps players
  contained, so nothing depended on it.
- There's no split-damage credit in PvP either (same as ship kills) — this
  is a free-for-all, no teams, so anyone can attack anyone once past the
  sky-spawn safe zone.
- Cannon barrels on Frigates/Galleons/Man-of-Wars originally pointed
  straight up instead of out through the hull — fixed by rotating them
  about the Y axis (`CFrame.Angles(0, math.rad(90), 0)`) instead of Z; Z
  sends a cylinder's length to world-vertical, Y sends it to world-Z
  (sideways), which is what a barrel poking out of a hull's side needs.
- The swim animation uses Motor6D joints (named `SwimMotor`), not the
  WeldConstraints the rest of the fish body uses — a WeldConstraint bakes
  in a fixed relative transform and fights any script that tries to move
  the part afterward, while Motor6D is built for exactly this kind of live,
  per-frame `C0` update. Only the tail/fin parts that actually wag use it;
  everything else stays on the simpler static weld.
- The portal's disc and touch-trigger are both Cylinders, whose flat face
  is *not* the default forward-facing direction — without an explicit
  `CFrame.Angles(0, math.rad(90), 0)` they'd render edge-on to an
  approaching player (nearly invisible) instead of face-on.
