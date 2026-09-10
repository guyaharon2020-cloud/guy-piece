# Build a Weird Pet

A Roblox simulator game: collect random creature parts (Head, Body, Legs,
Eyes, Special, Ability), combine them into a pet, and see what weird thing
comes out. Built with [Rojo](https://rojo.space/) so the whole game lives
as readable Lua source instead of a binary `.rbxl` file.

## Getting it into Roblox Studio

**Quickest path:** open `BuildAWeirdPet.rbxlx` directly in Roblox Studio
(double-click it, or File → Open in Studio). It's a prebuilt place file with
every script already in place — no extra tooling required. If you edit the
Lua source under `src/`, regenerate it with the same tree-walking approach
`rojo build -o BuildAWeirdPet.rbxlx` would use (or install Rojo — see below
— and run that command yourself).

Either way, once it's open in Studio:
1. Go to **Game Settings → Security** and enable **Studio Access to API
   Services** — the game uses `DataStoreService` to save profiles, which is
   off by default in Studio.
2. Press **Play**.

**Source-of-truth path (for ongoing development):** install
[Rojo](https://rojo.space/docs/v7/getting-started/installation/) (the VS
Code extension is the easiest path, or `aftman`/`foreman` for the CLI + the
matching Studio plugin), run `rojo serve` from this folder, then connect to
it from the Rojo plugin in Studio. This live-syncs `src/` into the DataModel
described by `default.project.json`, so edits in your editor show up in
Studio immediately — better for iterating than re-opening the `.rbxlx` each
time.

## How a session actually plays

1. You spawn next to the **Laboratory** hub.
2. Hold `E` (or tap, on mobile) at the **Part Generator** station to spend
   DNA and roll one random part per slot from your current world's part
   pool.
3. Roll again if you want, or hit **Create Pet!** to combine your six
   rolled parts into a pet — every part has a rarity, and a pet's overall
   rarity (and stats) is driven by the rarest part in it. There's also a
   small chance of a bonus **mutation** (Giant, Rainbow, Glitched, etc.)
   that reskins and buffs the pet further.
4. Equip pets at the **Pet Inventory** station; equipped pets physically
   follow you around in a fanned-out trail.
5. Compete in the five challenge pads scattered near the lab (Race, Jump,
   Obstacle, Strength, Weirdness) — each scores off your best equipped
   pet's relevant stat and pays out Coins + DNA.
6. Spend Coins at the **Lab Upgrades** station (better generator, storage,
   luck, pet slots, and Coin/DNA multipliers) and at the **World portals**
   to unlock Laboratory → Alien Planet → Volcano → Glitch World, each with
   its own part pool and noticeably stronger parts.
7. Check the **Collection Book** for how many unique combinations you've
   discovered, milestone rewards at 10/25/50/100, and hunt for the five
   curated **secret pets** (The Error, Void Frog, Mega Chicken, Unknown,
   ???) — discovering one announces to the whole server.
8. Spend Coins/DNA/Mutations at the **Shop** on cosmetic trails, name
   colors and emotes. Nothing in the shop is required to progress.

## Project structure

```
src/
  ReplicatedStorage/Shared/     -- pure-data modules, safe to require from
                                    both server and client
    Rarity.lua                  -- 7 rarity tiers, weighted random picking
    Mutations.lua                -- Giant/Rainbow/Glitched/etc. roll table
    Worlds.lua                   -- 5 worlds x 6 slots x parts-with-rarity
    SecretPets.lua                -- curated 6-part combos with special names
    PetStats.lua                  -- slot list + stat computation
    PetBuilder.lua                 -- assembles a Model from primitive parts
    UpgradeDefs.lua / ShopItems.lua -- catalog data shared with the UI
    Remotes.lua                    -- single source of truth for all Remotes

  ServerScriptService/
    Main.server.lua               -- boot: builds the map, inits services
    World/LabBuilder.lua           -- procedurally builds the hub + stations
    Services/
      DataService.lua              -- DataStore load/save/autosave
      PetGenerationService.lua      -- roll parts, combine into a pet
      InventoryService.lua           -- equip/unequip/release, capacity
      PetFollowService.lua            -- spawns/moves the physical pet models
      UpgradeService.lua               -- lab upgrade purchases
      WorldService.lua                  -- world unlock/travel
      ShopService.lua                    -- cosmetic purchases
      ChallengeService.lua                -- minigame scoring & payouts
      CollectionService.lua                -- discoveries, milestones, secrets

  StarterPlayer/StarterPlayerScripts/Client/
    Main.client.lua                -- boot: HUD, panels, station wiring
    CosmeticsController.lua         -- renders equipped Trail/NameColor
    UI/
      Theme.lua, PanelBase.lua, Toast.lua      -- shared widgets/style
      HUD.lua                                    -- currency bar + nav
      GeneratorPanel.lua, InventoryPanel.lua,
      CollectionPanel.lua, ShopPanel.lua,
      UpgradesPanel.lua                            -- one file per screen
```

Every interactive object in the world (the 5 stations, 5 challenge pads, 5
world portals) is a plain `Part` with a `ProximityPrompt` and an attribute
(`UIPanel`, `ChallengeId`, or `WorldId`). One listener in `Main.client.lua`
reads that attribute and does the right thing — no bespoke script per
station.

## Design notes / where this is intentionally a starting point

- **Pet visuals** are assembled from primitive parts (balls, blocks,
  cylinders, wedges) rather than custom meshes, so every one of the
  thousands of combinations is actually distinct without needing an art
  pipeline. Swap `PetBuilder.lua` for a mesh-based rig whenever real art
  exists — nothing else needs to change.
- **Challenges** (Race/Jump/Obstacle/Strength/Weirdness) are implemented as
  a server-authoritative scoring/reward economy (stat + randomness →
  Coins/DNA, with a cooldown), not physical minigame courses with
  checkpoints. `ChallengeService.lua` is where a real course's finish-line
  script would hand off into the same scoring path.
- **DataService** uses a single `UpdateAsync`/`GetAsync` call with retries,
  which is enough for a prototype. For a shipped game with real
  cross-server concurrency risk, swap it for a session-locking library like
  ProfileService/ProfileStore — every other service only calls the small
  `Load/Get/WaitFor/Save` API, so the swap is isolated to one file.
- **The laboratory hub is shared**, not per-player instanced, so upgrade
  levels affect your own stats/economy but don't remodel the shared room.
  A per-player "island" system (grid of instanced plots swapped in on
  join) is the natural next step if you want the lab itself to visibly
  evolve per player.

## Currencies

- **Coins** — lab upgrades, world unlocks, most shop items
- **DNA** — rolling parts at the Part Generator
- **Mutations** — extremely rare; earned only when a pet rolls a mutation,
  spent on the rarest shop cosmetics

Nothing requires Robux to progress.
