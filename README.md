# 📦 Badga's Box of Boom (Ess v0.3.0)
**A synchronized airstrike & ordnance spawning system for *Mercenaries 2 / Black Ops***

Adds a comprehensive, FX-synced(mostly) ordnance drop system featuring tactical nukes, fuel-air bombs, cluster munitions, cruise missiles, artillery, and more. All detonations are mathematically timed and vertically locked to the projectile's actual impact point for cinematic accuracy(except nukes those are near instant and still have issues to fix).

---

## ⚙️ Requirements
- **Essential Mod (Ess) Framework v0.3.0+**
- *Mercenaries 2: World in Flames* or *Black Ops*
- Ferdi's AIO Menu (optional, recommended for GUI access)

---

## 📥 Implementation Methods

Three distinct versions are provided to match your preferred modding workflow. Choose the one that fits your setup:

### 🔹 Method 1: Ferdi's AIO Menu (Drop-in Script)
**File:** `SpawnOrdinance.lua`  
**Best for:** Users who want a ready-made GUI menu with zero configuration.

1. Place `SpawnOrdinance.lua` in your Ferdi's menu `mods/` or `scripts/` directory.
2. Ensure Ferdi's loader is set to auto-scan for `menu:category` definitions (default behavior).
3. Launch the game, open Ferdi's menu, and navigate to **Ordnance Drops**.
4. All functions are wrapped as `local`, making this a self-contained, drop-and-play script.

### 🔹 Method 2: ESS OnLoad Framework (Global API)
**File:** `SpawnOrdinanceFunctions.lua`  
**Best for:** Developers or advanced users who want to call ordnance functions from other scripts or custom menus.

1. Place `SpawnOrdinanceFunctions.lua` in your Ess `mods/` or `OnLoad/` directory.
2. Functions are intentionally **not prefixed with `local`**, exposing them to the global `_G` namespace.
3. Other scripts can now call them directly. Example:
   ```lua
   -- Called from another script or custom menu
   spawnNuke(tx, tz, ty, 100)
   dropOrdnance(ctx, "Cluster Bomb Projectile", 70, 90, "distance", 90, -90, "CLUSTER", -2)
   ```

### 🔹 Method 3: ESS OnKey Bindings (Quick Spawn)
**Files:** `NukeSingle.lua` & `NukeBurst.lua`  
**Best for:** Players who want instant keybind triggers for tactical nukes without a menu.

1. Place both files in your Ess `OnKey/` directory.
2. Open `ess_loader.ini` and add keybind entries:
   ```ini
   [Keybinds]
   NukeSingle=NukeSingle.lua
   NukeBurst=NukeBurst.lua
   ```
3. Assign your preferred keys in Ess's keybind configuration or directly in `ess_loader.ini`.
4. Pressing the bound key will immediately spawn a single nuke or an 8-warhead ring, with FX automatically synced.

---

## 🎮 How to Use
1. Trigger your chosen implementation (menu selection, custom script call, or keybind).
2. The projectile will spawn **safely ahead** of your current position, accounting for terrain and blast radius.
3. Visual effects (shockwaves, fireballs, submunitions) are dynamically timed and vertically locked to the projectile's actual detonation point.
4. A toast notification confirms successful deployment.

---

## 🛠️ Customization (Advanced)
You can tweak spawn behavior by editing the `dropOrdnance` parameters. The function signature is:
```lua
dropOrdnance(ctx, name, radius, height, triggerType, triggerVal, velocity, fxType, fxAlt)
```

| Parameter | Description |
|-----------|-------------|
| `name` | Internal projectile template string (e.g., `"Smart Bomb Projectile"`) |
| `radius` | Safe spawn distance ahead of player (meters) |
| `height` | Initial drop altitude relative to player Y |
| `triggerType` | `"distance"` or `"impact"` (controls detonation trigger) |
| `triggerVal` | Distance/time threshold before detonation |
| `velocity` | Downward drop speed (negative values simulate gravity) |
| `fxType` | `"IMPACT"`, `"CLUSTER"`, or `"FAB"` (routes to correct FX handler) |
| `fxAlt` | Minimum height buffer to prevent underground FX |

**Example:** Adding a custom quick-spawn keybind:
```lua
Ess.Input.bind("F5", function()
  dropOrdnance(nil, "MOAB Projectile", 150, 120, "distance", 130, -65, "IMPACT", 0)
end)
```

---

## ⚠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| Menu doesn't appear | Ensure Ess v0.3.0+ is loaded and Ferdi's scanner is enabled. Check `ess.log` for load errors. |
| FX spawn underground | The mod uses a safety buffer (`fxAlt`). If terrain is highly uneven, increase `fxAlt` to `2` or `5` in the menu entry. |
| Projectile doesn't detonate | Some ordnance use `"distance"` triggers. Ensure you're not standing too close during the fall phase. |
| Missing dependencies | This mod relies on `Ess.Safe.call`, `Ess.Loop`, and `Airstrike.SpawnOrdnance`. Older Ess versions will fail to load. |
| `ctx` vs `ba` mismatch | Ferdi's menu uses category aliases for organization. Ensure your callback passes the correct context variable. |

---

## 🙏 Credits & Disclaimer
- Built for the **Essential Mod (Ess) v0.3.0** framework
- FX synchronization & detonation timing tuned for cinematic accuracy
- Huge thanks to Wally, Ferdi, Cos, and the M2/BO modding community for their time and contributions
- **Disclaimer:** This mod is for single-player/freeplay use only, not intended for competitive or networked play do so at your own risk. May cause unexpected behavior in heavily modded environments. Use irresponsibly and enjoy the firepower.