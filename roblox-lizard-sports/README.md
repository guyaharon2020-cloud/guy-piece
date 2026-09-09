# Lizard Sports Legend

A Roblox game: you're a lizard trying to become the best athlete in the
arena. Recolor and gear up your lizard in the shop, then compete in three
sports events — **Sprint Dash**, **Climb Tower**, and **Bug Hunt** — using
abilities based on real lizard biology.

Everything here is Luau source code meant to be synced into Roblox Studio
with [Rojo](https://rojo.space/). There is no Studio project file included
(a `.rbxl`/`.rbxlx`) — Rojo builds the place from this source every time,
which is the standard way to keep a Roblox game in git.

## Real-lizard mechanics

- **Basking (stamina regen):** lizards are ectothermic — standing in a
  glowing `SunSpot` recharges your stamina several times faster than
  standing in the shade.
- **Sprinting:** hold Shift for a burst of speed; it drains your stamina,
  so you have to bask to recover before your next sprint.
- **Wall climbing:** hold Space near a `Climbable` wall and steer with
  WASD — geckos climb sheer surfaces, so can you.
- **Tongue catch:** press F to fire your tongue in a straight line (like a
  chameleon); hit something tagged `Catchable` (bugs, during Bug Hunt) to
  catch it.
- **Camouflage:** press C to fade toward transparent for a few seconds,
  on a cooldown.
- **Tail autotomy:** touch a `Predator` hazard and your tail drops off and
  tumbles away — you get a knockback escape boost and a few coins for the
  close call, but climbing/sprinting are weaker until it regrows.

## Shop

The shop kiosk (in the hub, near spawn) opens with a `[E]` proximity
prompt. **Skins** are cosmetic and mutually exclusive (equip one at a
time); **Gear** is cumulative — every piece you own adds its bonus
permanently (faster climbing, more stamina, a shorter tail-regrow time,
and so on). See `src/ReplicatedStorage/Shared/ShopData.lua` for the full,
easy-to-edit catalog and prices.

## Project layout

```
default.project.json          Rojo project file
src/ReplicatedStorage/Shared/  Data both client and server read (Constants, ShopData)
src/ServerScriptService/       All server logic (data, shop, character/lizard rig,
                                abilities, sport events, procedural map)
src/StarterPlayer/             Client input, HUD, and shop UI
```

The world (spawn hub, shop kiosk, sprint track, climbing tower, bug hunt
arena) is **built procedurally by `MapBuilder.lua`** the first time the
server starts — you don't need to build anything by hand in Studio to get
a playable game.

## Design note: how the lizard looks

Rather than replacing the whole character with a custom quadruped rig
(which would mean writing custom walk/run/jump/climb animations from
scratch, with no way to test them outside Studio), the lizard is the
standard R15/R6 avatar **recolored**, with a snout, eyes, a spine ridge,
and a wagging tail welded on. This keeps every built-in Roblox animation
working for free while still reading clearly as "a lizard" — think
stylized sports mascot rather than a photorealistic crawling reptile.

## Setup: syncing into Roblox Studio

1. **Install Rojo:**
   - Studio plugin: in Roblox Studio, go to the Toolbox / Plugins tab and
     install "Rojo" from the plugin marketplace (or build/install it from
     [rojo.space](https://rojo.space/docs/v7/getting-started/installation/)).
   - CLI: `cargo install rojo`, or `aftman add rojo-rbx/rojo`, or download
     a release from the [Rojo GitHub releases page](https://github.com/rojo-rbx/rojo/releases).
2. **Create a new place** in Studio (an empty/baseplate template is fine —
   if it comes with a default `Baseplate` part, delete it so it doesn't
   overlap the generated ground).
3. From this folder, run:
   ```bash
   rojo serve
   ```
4. In Studio, open the Rojo plugin panel and click **Connect**. Your
   Explorer should immediately fill in with `ReplicatedStorage.Shared`,
   `ReplicatedStorage.Remotes`, `ServerScriptService`, and
   `StarterPlayer.StarterPlayerScripts`.
5. Click **Play** (or Play Solo). The map builds itself, you spawn as a
   lizard, and the shop/events are live.

### DataStore note

Coins/owned items/equipped skin persist via `DataStoreService`. In Studio
you need **Game Settings → Security → Enable Studio Access to API
Services** for saves to work while testing; once published, this works
automatically. If it's off, the game still runs fine — saves just fail
silently (logged as a warning) and every session starts fresh.

## Controls

| Key          | Action                                   |
|--------------|-------------------------------------------|
| WASD         | Move                                      |
| Shift (hold) | Sprint (costs stamina)                    |
| Space + WASD | Climb (only works on a `Climbable` wall)  |
| F            | Fire tongue (catch things in front of you)|
| C            | Toggle camouflage                         |
| E            | Interact (open the shop at the kiosk)     |
