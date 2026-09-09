# Water Creature — Roblox game

You play a water creature swimming an open sea, destroying rafts and ships
loaded with humans. Every human aboard something you destroy pays out
**$1 and 10 XP** — bigger vessels are worth more. XP levels you up, making
your creature faster and bigger. Money is spent in an in-game shop to
permanently upgrade your creature.

## Targets: rafts vs. ships

- **Rafts** — small, one touch destroys them, carry 2–6 humans. Safe,
  low-risk income.
- **Ships** — big, carry 8–15 humans (a much bigger payout), and have a
  Health pool shown as a bar above the hull: destroying one takes several
  hits. Every hit you land also lands one back on you (contact damage), so
  ramming an unupgraded ship is risky. Upgrading **Bite Power** lowers how
  many hits a ship takes to sink; **Armor** raises your max health and cuts
  the damage you take per hit.

## The upgrade shop

Click the **Shop** button (bottom-right) to open a panel with three
upgrades, each with 9 tiers and a rising Money cost:

| Upgrade | Effect |
|---|---|
| **Bite Power** | More damage per hit against ships (fewer hits to sink one) |
| **Armor** | More max health + less damage taken from ships |
| **Fins** | Extra swim speed, stacking with the speed you get from leveling |

Purchases are server-validated (the client only *requests* a purchase; the
server checks your Money and applies the tier), and persist for your
character across respawns via a per-player `Upgrades` folder.

## How it works

- `src/ReplicatedStorage/Modules/GameConfig.lua` — every tunable number
  (spawn rates, raft/ship size, payouts, leveling curve, upgrade costs)
- `src/ServerScriptService/WorldSetup.server.lua` — fills the Terrain with a
  water volume + sandy floor on first run, so the place needs zero manual
  Studio setup
- `src/ServerScriptService/RaftSpawner.server.lua` / `RaftDestruction.server.lua`
  — spawns rafts and destroys them (+ pays out) on touch
- `src/ServerScriptService/ShipSpawner.server.lua` — spawns ships (hull +
  cabin + mast + a Health attribute) with a floating health-bar billboard
- `src/ServerScriptService/ShipCombat.server.lua` — ramming combat: each hit
  reduces the ship's Health by the attacker's Bite Power and deals contact
  damage back to the attacker (reduced by Armor); sinks and pays out at 0 HP
- `src/ServerScriptService/Modules/PlayerProgress.lua` — leaderstats
  (`Level`, `Money`, `XP`), the level-up formula, and applying combined
  level + upgrade stats (swim speed, max health, size) to the character
- `src/ServerScriptService/Modules/PlayerUpgrades.lua` — each player's
  upgrade tiers and the purchase logic (server-authoritative)
- `src/ServerScriptService/ShopHandler.server.lua` — validates and applies
  shop purchase requests from the client
- `src/ServerScriptService/GameManager.server.lua` — wires player join/leave
  and character respawn into `PlayerProgress` / `PlayerUpgrades`
- `src/StarterPlayer/StarterPlayerScripts/CreatureHud.client.lua` — pop-up
  feedback ("+$4 • +40 XP (4 humans)", level-up banner)
- `src/StarterPlayer/StarterPlayerScripts/UpgradeShop.client.lua` — the shop
  panel UI

Swimming itself needs no custom script — Roblox's default character
controller automatically swims whenever the character is inside Terrain
water, which `WorldSetup` generates for you.

## Just open it

**`WaterCreatureGame.rbxlx`** is a single, self-contained Roblox place file
with everything already built in — no Rojo, no manual setup:

1. Open Roblox Studio.
2. **File → Open From File...** and pick `WaterCreatureGame.rbxlx`.
3. Press **Play**. The sea, rafts, and ships generate automatically; ram a
   raft or ship to destroy it and watch your `Money`/`Level`/`XP` update in
   the player list (top right). Click **Shop** to spend Money on upgrades.

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
| `HumansPerRaftMin/Max`, `HumansPerShipMin/Max` | humans per target (also the payout size) |
| `MoneyPerHuman`, `XPPerHuman` | payout per human destroyed |
| `ShipContactDamage`, `ShipTouchCooldown` | how dangerous ships are and how fast you can hit them |
| `BaseWalkSpeed`, `WalkSpeedPerLevel`, `SizePerLevel` | how leveling changes your creature |
| `Config.XPForLevel(level)` | the XP curve between levels |
| `Config.Upgrades` (`AttackPower`/`Armor`/`SwimSpeed`) | shop tier count, cost curve, and per-tier effect |

## Notes

- This ships with the default Roblox avatar as your "creature" — the
  mechanics (swim, ram rafts/ships, earn money, level up, buy upgrades)
  work as-is. To make it *look* like a sea creature, give players a
  shark/sea-monster avatar or bundle (via `Players.PlayerAdded` +
  `humanoidDescription`, or a free community model from the Studio
  Toolbox) — that step needs the Studio asset browser, which isn't
  available outside of Studio.
- If a ship sinks from hits landed by more than one player, the final hit
  gets full credit for the reward (no split-credit system yet).
