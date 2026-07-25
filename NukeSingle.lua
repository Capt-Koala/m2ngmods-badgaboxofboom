-- NukeBurst.lua (Ess v0.3.0 Optimized)
Loader.Printf("[NUKE] Script executed")

if not _G.Ess then
  Loader.Printf("[NUKE] Ess framework not loaded")
  return
end

local uChar = Ess.Player.character(0)
if not uChar then
  Ess.Easy.Toast("No player character found")
  return
end

-- v0.3.0: Use viewYaw for actual camera direction
local px, py, pz = Ess.Object.pos(uChar)
local pYaw = Ess.Player.viewYaw(0) or Ess.Object.yaw(uChar)

-- v0.3.0: Ess.Math handles M2's (+sin, +cos) yaw convention natively
local tx, tz = Ess.Math.pointAhead(px, pz, pYaw, 120)
local ty = py + 80

Loader.Printf("[NUKE] Target coords: " .. tostring(tx) .. ", " .. tostring(ty) .. ", " .. tostring(tz))

-- Safe spawn wrapper
local ok, res = Ess.Safe.call(function()
  Airstrike.SpawnOrdnance("Nuclear Bunker Buster Projectile", tx, ty, tz, 0, -90, 0, "distance", 100)
end)

if ok then
  Ess.Easy.Toast("Nuke dropped (120m)")
  Loader.Printf("[NUKE] ✅ Spawn succeeded")

  -- Particle sync loop
  local loopId = "NukeSync_" .. tostring(math.random(10000, 99999))
  local ticks = 4 -- ~0.8s matches travel time to detonation altitude
  
  Ess.Loop.start(loopId, 0.2, function()
    ticks = ticks - 1
    if ticks <= 0 then
      local detY = ty - 65
      Ess.Easy.Spawn.fx("global_particle_airstrike_tactnuke", tx, detY, tz)
      Ess.Easy.Spawn.fx("global_particle_exp_shockwave_ground_tactnuke", tx, detY - 15, tz)
      return false -- Stop loop after firing
    end
    return true
  end)
else
  Ess.Easy.Toast("Spawn failed: " .. tostring(res))
  Loader.Printf("[NUKE] ❌ Spawn failed: " .. tostring(res))
end
