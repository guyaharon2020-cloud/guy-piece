# Water Creature — Roblox game

You play a water creature swimming an open sea, ramming rafts loaded with
humans. Each raft you destroy pays out **$1 and 10 XP per human** that was
riding it — bigger rafts are worth more. XP levels you up, which makes your
creature faster and bigger.

## How it works

- `src/ReplicatedStorage/Modules/GameConfig.lua` — every tunable number
  (spawn rate, raft size range, money/XP per human, leveling curve)
- `src/ServerScriptService/WorldSetup.server.lua` — fills the Terrain with a
  water volume + sandy floor on first run, so the place needs zero manual
  Studio setup
- `src/ServerScriptService/RaftSpawner.server.lua` — spawns rafts (each
  carrying 2–6 humans) at random points around the map on a timer
- `src/ServerScriptService/RaftDestruction.server.lua` — server-side touch
  detection: when a player's character touches a raft, the raft and its
  humans are destroyed and the player is paid
- `src/ServerScriptService/Modules/PlayerProgress.lua` — leaderstats
  (`Level`, `Money`, `XP`), the level-up formula, and applying level-based
  stats (swim speed, size) to the player's character
- `src/ServerScriptService/GameManager.server.lua` — wires player join/leave
  and character respawn into `PlayerProgress`
- `src/StarterPlayer/StarterPlayerScripts/CreatureHud.client.lua` — pop-up
  feedback ("+$4 • +40 XP (4 humans)", level-up banner)

Swimming itself needs no custom script — Roblox's default character
controller automatically swims whenever the character is inside Terrain
water, which `WorldSetup` generates for you.

## Running it in Roblox Studio

1. Install the [Rojo](https://rojo.space/) plugin in Studio (and the Rojo
   CLI, e.g. `cargo install rojo` or via [Aftman](https://github.com/LPGhatguy/aftman)).
2. From this folder, start the server:
   ```bash
   rojo serve
   ```
3. In Studio, open (or create) a place, open the Rojo plugin panel, and
   click **Connect**.
4. Press **Play**. The sea and rafts generate automatically; swim into a
   raft to destroy it and watch your `Money`/`Level`/`XP` update in the
   player list (top right).

If you don't want to install Rojo, you can recreate the same instance tree
by hand in Studio (Script/LocalScript/ModuleScript per the file names
below) and paste each file's contents in.

## Customizing

All gameplay tuning lives in `GameConfig.lua`:

| Setting | Effect |
|---|---|
| `RaftSpawnInterval`, `MaxRafts` | how often/how many rafts are on the water |
| `HumansPerRaftMin/Max` | humans per raft (this is also the payout size) |
| `MoneyPerHuman`, `XPPerHuman` | payout per human destroyed |
| `BaseWalkSpeed`, `WalkSpeedPerLevel`, `SizePerLevel` | how leveling changes your creature |
| `Config.XPForLevel(level)` | the XP curve between levels |

## Notes

- This ships with the default Roblox avatar as your "creature" — the
  mechanics (swim, ram rafts, earn money, level up) work as-is. To make it
  *look* like a sea creature, give players a shark/sea-monster avatar or
  bundle (via `Players.PlayerAdded` + `humanoidDescription`, or a free
  community model from the Studio Toolbox) — that step needs the Studio
  asset browser, which isn't available outside of Studio.
- Money currently only accumulates as a leaderstat; there's no shop yet.
  Add one by spending `player.leaderstats.Money.Value` wherever you like.
