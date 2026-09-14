📦 Badga's Box of Boom (Ess v0.3.0+)
A synchronized airstrike & ordnance spawning system for *Mercenaries 2*

Adds a comprehensive, FX-synced(mostly) ordnance drop system featuring tactical nukes, fuel-air bombs, cluster munitions, cruise missiles, artillery, and more. All detonations are mathematically timed and vertically locked to the projectile's actual impact point for cinematic accuracy(except nukes those are near instant and still have issues to fix).

---

⚙️ Requirements
- **Essential Mod (Ess) Framework v0.3.0+**
- *Mercenaries 2: World in Flames*
- Ferdi's AIO Menu (optional, recommended for GUI access)

---

📥 Implementation Methods

Three distinct versions are provided to match your preferred modding workflow. Choose the one that fits your setup:

🔹 Method 1: Ferdi's AIO Menu (Drop-in Script)
**File:** `SpawnOrdnance.lua`  
**Best for:** Users who want a ready-made GUI menu with zero configuration.

1. Paste the contents of SpawnOrdnance.lua into Ferdi's menu
2. Launch the game, open Ferdi's menu, and navigate to **Ordnance Drops**.
3. All functions are wrapped as `local`, making this a self-contained, drop-and-play script.

🔹 Method 2: ESS OnLoad Framework (Global API)
**File:** `SpawnOrdnanceFunctions.lua`  
**Best for:** Developers or advanced users who want to call ordnance functions from other scripts or custom menus.

1. Place `SpawnOrdnanceFunctions.lua` in your Ess `mods/` or `OnLoad/` directory.
2. Functions are intentionally **not prefixed with `local`**, exposing them to the global `_G` namespace.
3. Other scripts can now call them directly. Example:
   ```lua
   -- Called from another script or custom menu
   spawnNuke(tx, tz, ty, 100)
   dropOrdnance(ctx, "Cluster Bomb Projectile", 70, 90, "distance", 90, -90, "CLUSTER", -2)
   ```

🔹 Method 3: ESS OnKey Bindings (Quick Spawn)
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

🎮 How to Use [DEPRECATED ORIGINAL EDITION]
1. Trigger your chosen implementation (menu selection, custom script call, or keybind).
2. The projectile will spawn **safely ahead** of your current position, accounting for terrain and blast radius.
3. Visual effects (shockwaves, fireballs, submunitions) are dynamically timed and vertically locked to the projectile's actual detonation point.
4. A toast notification confirms successful deployment.

🎮 How to Use
Open Ordnance Drops.
Select an ordnance entry.
Wait for the Laser ready toast.
Paint your desired target.
The selected ordnance spawns above the painted point.
FX are timed to the ordnance fall distance.
The designator clears automatically afterward.
If the designator gets stuck or you want to force-clear it, use:

`Clear Designator`



---
📝 Changelog
Native Designator Overhaul

- Added:
Native laser designator flow.
Session token to prevent stale designator callbacks.
Input/UI suppression around designator equip and clear.
Explicit FX routing:
DEFAULT
CLUSTER
FAB
NUKE
Fall-time FX timing.
Clear Designator menu entry.
Cleaner failure handling for missing APIs.
Maintenance pass helpers:
apiCall
safe
after
impactY
fallTime

- Changed:
Replaced old custom player-relative aim flow with native Airstrike.EquipDesignator.
Ordnance now spawns from the painted target position.
FX are no longer based on hardcoded guessed timings.
Heavy Artillery now uses the normal designator entry.
FAB cloud orientation locked to:
Copy
lua
FAB_CLOUD_ROLL_DEG = 0
FAB cloud height locked to:
Copy
lua
FAB_HEIGHT_OFFSET = returned to 0
Code organized into tuning, helpers, FX, ordnance table, strike system, designator system, and menu builder.

- Fixed:
Stale designator callbacks.
Duplicate spawn risk.
Repeat-use designator weirdness.
Menu/control conflicts during repeated artillery use. (workarounds mentioned but best unbind arrow keys from the game's .ini)
Wrong FX firing on the wrong ordnance.
FAB cloud appearing at the wrong orientation.
FAB cloud being too deep underground.
Nuke FX and shockwave timing.
Cluster FX routing.
Default shockwave presence.
Duplicate helper clutter.
Old experimental targeting logic
- Removed:
Old resolveAim / fallback targeting logic.
Custom player-relative aim stack.
Stale callback risk from old designator equips.
Hardcoded close (but not close enough) FX timings.
Duplicate helper clutter.
Alt-name fallback clutter.
Scattered experimental logic.

✨ FX Routing
FX are now explicitly routed by ordnance type.

DEFAULT
Used by most shells, bombs, missiles, and artillery.

Effects:

Explosion
Ground shockwave
CLUSTER
Used by Cluster Bomb.

Effects:

Multiple sub-explosions around the impact point
Ground shockwave
FAB
Used by Fuel Air Bomb.

Effects:

Raised FAB cloud
Fuel/debris staging
Flash
Shockwave
Sound cue
Directed FAB cloud spawn
Final FAB tuning:

FAB_HEIGHT_OFFSET = 5
FAB_CLOUD_ROLL_DEG = 0
The FAB cloud orientation is locked to 12 o’clock.

NUKE
Used by Tactical Nuke.

Effects:

Nuke cloud
Delayed nuke ground shockwave

🛠️ Customization (Advanced) [ORIGINAL RELEASE ONLY, DEPRECATED]
You can tweak spawn behavior by editing the `dropOrdnance` parameters. The function signature is:
```lua
dropOrdnance(ctx, name, radius, height, triggerType, triggerVal, velocity, fxType, fxAlt)
```


[ORIGINAL]

🔧 Tuning Values

Parameter: Purpose
`name` Internal projectile template string (e.g., `"Smart Bomb Projectile"`)
`radius` Safe spawn distance ahead of player (meters)
`height` Initial drop altitude relative to player Y
`triggerType` `"distance"` or `"impact"` (controls detonation trigger)
`triggerVal` Distance/time threshold before detonation
`velocity` Downward drop speed (negative values simulate gravity)
`fxType` `"IMPACT"`, `"CLUSTER"`, or `"FAB"` (routes to correct FX handler)
`fxAlt` Minimum height buffer to prevent underground FX

[OVERHAUL]

🛠️ Customization
The current system is table-driven. Add or modify entries in the ORDNANCE table.

Example:

lua
{
    label = "Custom Bomb",
    proto = "Custom Bomb Projectile",
    height = 80,
    vel = -90,
    dist = 90,
    fx = "DEFAULT",
}
Fields
Field	Description
label	Menu entry name shown to the user
proto	Internal projectile/template string used by Airstrike.SpawnOrdnance
height	Spawn altitude above the painted target
vel	Downward velocity used for fall-time calculation
dist	Distance trigger value / fall distance used for FX timing
fx	FX route: DEFAULT, CLUSTER, FAB, or NUKE
FX Timing
Fall time is calculated as:

lua
fallTime = dist / abs(vel)
FX fire after that calculated delay.

Impact altitude is derived from the painted target position, spawn height, velocity, and fall distance, then clamped to avoid extremely deep underground FX.


🔧 Tuning Values

Value:	Purpose
INPUT_SETTLE_TIME:	Small input settle delay after input flush
CLEAR_SETTLE_TIME:	Designator clear settle delay
DESIGNATOR_SETTLE_TIME:	Delay before equipping the designator
FAB_HEIGHT_OFFSET	FAB: cloud height offset above impact
FAB_CLOUD_ROLL_DEG:	FAB cloud roll/orientation



**Example:** Adding a custom quick-spawn keybind:
```lua
Ess.Input.bind("F5", function()
  dropOrdnance(nil, "MOAB Projectile", 150, 120, "distance", 130, -65, "IMPACT", 0)
end)
```

---

⚠️ Troubleshooting

[ORIGINAL]

| Issue | Solution |
|-------|----------|
| Menu doesn't appear | Ensure Ess v0.3.0+ is loaded and Ferdi's scanner is enabled. Check `ess.log` for load errors. |
| FX spawn underground | The mod uses a safety buffer (`fxAlt`). If terrain is highly uneven, increase `fxAlt` to `2` or `5` in the menu entry. |
| Projectile doesn't detonate | Some ordnance use `"distance"` triggers. Ensure you're not standing too close during the fall phase. |
| Missing dependencies | This mod relies on `Ess.Safe.call`, `Ess.Loop`, and `Airstrike.SpawnOrdnance`. Older Ess versions will fail to load. |
| `ctx` vs `ba` mismatch | Ferdi's menu uses category aliases for organization. Ensure your callback passes the correct context variable. |

[OVERHAUL]

WILL BE UPDATED WHEN I GET A DECENT TROUBLESHOOTING PROCEDURE TOGETHER, FOR NOW MESSAGE ME WITH ISSUES AND I'LL DO MY BEST.

---

🙏 Credits & Disclaimer
- Built for the **Essential Mod (Ess) v0.3.0** framework
- Native laser designator integration for Mercs 2 ordnance flow
- FX synchronization & detonation timing tuned for cinematic accuracy
- Huge thanks to Wally, Ferdi, Cos, and the M2/menace.pro modding community for their time and contributions

Disclaimer: This mod is for single-player/freeplay use only, not intended for competitive or networked play do so at your own risk. May cause unexpected behavior in heavily modded environments. Use irresponsibly and enjoy the firepower.
