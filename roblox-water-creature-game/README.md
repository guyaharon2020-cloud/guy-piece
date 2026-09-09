# Water Creature — Roblox game

You play a fish, swimming an open sea, destroying rafts and ships loaded
with humans. Every human aboard something you destroy pays out Money and
XP (scaled by your shop upgrades). XP levels you up; every **12 levels**
your fish **evolves** into a tougher-looking, faster tier — and your Level
resets to 1 so you level up again within the new tier. Money buys permanent
upgrades in an in-game shop, and Robux buys real-money "super powers".

## Getting into the water

You don't spawn directly in the ocean. Every join (and every respawn) drops
you on an invisible platform floating high in the sky above the map —
`Transparency = 1` with `CanCollide = true`, so you can stand on it and walk
around while seeing straight through it to the ocean far below (a thin glow
outlines its edges so you can still tell where it ends). A glowing blue
portal disc a short walk away teleports you down to the water surface the
moment you touch it.

## Your fish

The default Roblox avatar is recolored (countershaded — darker on top,
lighter belly, like a real fish) and given a forked tail, dorsal fin, two
side fins, and small eyes, all built from primitive Parts — no custom mesh
upload was available from here, so this is the closest a script alone can
get to "looks like a fish." **The place forces every player to the R15
avatar type** (`StarterPlayer.AvatarType`, set in `WorldSetup.server.lua`):
without that, an account defaulting to R6 would silently fail to scale on
evolution/level-up (R6 doesn't support the scaling API used here) and the
fins would sit at odd proportions — R15 makes both reliable. Color, fin
size, and (at the final tier) a soft glow all change with your evolution
tier:

| Evolution tier | Level range | Look |
|---|---|---|
| 0 — Minnow | 1–12 | light blue, small fins |
| 1 — Barracuda | 1–12 (after reset) | deeper blue, bigger fins, +speed |
| 2 — Reef Shark | 1–12 | gray, bigger still |
| 3 — Great White | 1–12 | pale gray, bigger |
| 4 — Megalodon | 1–12 | near-black, huge |
| 5 — Leviathan | 1–50 (final tier, no more resets) | teal/gold shimmer, biggest and fastest |

Each evolution keeps your Money and all shop upgrade tiers — only Level and
XP reset, and each tier's base speed/size is higher than the last, so it's
a "prestige," not a punishment.

## Targets: rafts vs. ships

- **Rafts** — small, one touch destroys them, carry 2–6 humans. Safe,
  low-risk income.
- **Ships** — three types, each a different size and color, with a Health
  bar shown above the hull:
  - **Sloop** (brown, 8–12 humans) — no cannon, just tougher than a raft.
  - **Frigate** (dark gray, 12–18 humans) — has cannons.
  - **Galleon** (red/gold, 18–26 humans) — has cannons, most humans, most
    Health.

  Every ram hit you land also lands one back on you (contact damage), and
  Frigates/Galleons additionally fire a short-range cannonball at whichever
  player is nearest (only within their `CannonRange`, ~55-65 studs, on a
  cooldown) — visible cannon barrels stick out both sides of their hull.
  Upgrading **Bite Power** lowers how many hits a ship takes to sink;
  **Scales** cuts damage from both ramming and cannon fire.
  - All three types now also have a flag, deck railings, and a bowsprit for
    a more detailed silhouette, and slowly patrol in a small circle around
    where they spawned (`ShipMovement.server.lua`) instead of sitting still
    — `Model:PivotTo()` moves the whole ship (hull, cabin, mast, cannons,
    humans, health bar) as one rigid group each tick, no physics needed.

## The world

- **Corals** — ~150 decorative coral clusters (branch coral, brain coral,
  sea rods) scattered across the seabed, non-collidable so they never block
  swimming (`CoralGarden.server.lua`).
- **Map barrier** — a hollow sand wall filled right at the edge of the water
  block (`WorldSetup.server.lua`), so you can't swim past the play area.

## The upgrade shop (Money)

Click the **Shop** button (bottom-right), **Upgrades** tab. Six upgrades,
9 tiers each, rising Money cost:

| Upgrade | Effect |
|---|---|
| **Bite Power** | More damage per hit against ships (fewer hits to sink one) |
| **Vitality** | More max health |
| **Scales** | % damage reduction from ships and cannon fire |
| **Fins** | Extra swim speed, stacking with evolution/level speed |
| **Greed** | % more Money per human destroyed |
| **Wisdom** | % more XP per human destroyed |

Purchases are server-validated (the client only *requests* a purchase; the
server checks your Money and applies the tier) and persist across
respawns **and** evolutions.

## The Robux shop (super powers)

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

## How it works

- `src/ReplicatedStorage/Modules/GameConfig.lua` — every tunable number
  (spawn rates, ship types, payouts, evolution tiers, upgrade costs, Robux
  products)
- `src/ServerScriptService/WorldSetup.server.lua` — water/Terrain + Lighting
  + sand map barrier, once, on first run; also forces R15 avatars
- `src/ServerScriptService/CoralGarden.server.lua` — scatters decorative
  coral across the seabed, once, on first run
- `src/ServerScriptService/SkySpawn.server.lua` — the sky spawn platform and
  its teleport portal down to the water
- `src/ServerScriptService/RaftSpawner.server.lua` / `RaftDestruction.server.lua`
  — spawns rafts and destroys them (+ pays out) on touch
- `src/ServerScriptService/ShipSpawner.server.lua` — spawns ships (random
  type, hull/cabin/mast/cannon barrels/flag/railings/bowsprit, health-bar
  billboard)
- `src/ServerScriptService/ShipMovement.server.lua` — slow circular patrol
  drift for every ship
- `src/ServerScriptService/ShipCombat.server.lua` — ramming combat, Depth
  Charge consumption, sinking + payout
- `src/ServerScriptService/ShipCannons.server.lua` — short-range cannon fire
  from Frigates/Galleons at the nearest player
- `src/ServerScriptService/Modules/PlayerProgress.lua` — leaderstats
  (`Level`, `Money`, `XP`, `Evolution`), leveling + evolution math, applying
  combined stats to the character
- `src/ServerScriptService/Modules/PlayerUpgrades.lua` — each player's
  upgrade tiers, purchase logic, damage-reduction/multiplier math
- `src/ServerScriptService/Modules/RobuxShop.lua` — Developer Product
  catalog handling, `ProcessReceipt`, granting super powers
- `src/ServerScriptService/Modules/CreatureAppearance.lua` — builds the fish
  look (recolor + welded fins) per evolution tier
- `src/ServerScriptService/ShopHandler.server.lua` — validates/applies both
  shops' purchase requests from the client
- `src/ServerScriptService/GameManager.server.lua` — wires player join/leave
  and character respawn into all of the above
- `src/StarterPlayer/StarterPlayerScripts/CreatureHud.client.lua` — pop-up
  feedback, evolution banner, Depth Charge counter
- `src/StarterPlayer/StarterPlayerScripts/UpgradeShop.client.lua` — the
  two-tab shop panel UI

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
| `LevelsPerEvolution`, `EvolutionTiers` | when/how the fish evolves |
| `Config.XPForLevel(level)` | the XP curve between levels |
| `Config.Upgrades` (6 entries) | shop tier count, cost curve, per-tier effect |
| `Config.RobuxProducts` | the Robux shop catalog and each power's effect |
| `CoralCount` | how many decorative coral clusters to scatter |
| `BarrierThickness`, `BarrierHeight` | the sand wall around the play area |
| `SkySpawnHeight`, `SkySpawnPlatformSize`, `SkySpawnPortalOffset` | the sky spawn platform + portal |

## Notes

- If a ship sinks from hits landed by more than one player, the final hit
  gets full credit for the reward (no split-credit system yet).
- Fin/eye placement assumes a standard R15 avatar (finds `UpperTorso` and
  `Head`); `WorldSetup.server.lua` forces R15 for exactly this reason.
- The map barrier is a square sand frame matching the water block's own
  footprint (not a circle), so there are no corner gaps to sneak through.
