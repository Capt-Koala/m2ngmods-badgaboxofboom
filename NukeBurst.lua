-- NukeBurst.lua (Ess v0.3.0 Optimized)
-- Spawns 8 nuclear warheads in a 360° ring around the player.
Loader.Printf("[NUKE] Script executed")

if not _G.Ess then
  Loader.Printf("[NUKE] Ess v0.3.0 not loaded")
  return
end

local uChar = Ess.Player.character(0)
if not uChar then
  Ess.Easy.Toast("No player character found")
  return
end

-- Configuration
local radius      = 120               -- Horizontal distance from player
local height      = 80                -- Spawn altitude ABOVE PLAYER (not terrain)
local velocity    = -90               -- Downward drop velocity
local burstDist   = 100               -- Units traveled before detonation
local ordnance    = "Nuclear Bunker Buster Projectile"
local count       = 8

Ess.Easy.Toast("Nuclear Ring Drop (8x)")
Loader.Printf("[NUKE] Spawning %d warheads at %dm radius...", count, radius)

local px, py, pz = Ess.Object.pos(uChar)

for i = 1, count do
  -- Evenly space around 360° (M2 engine convention: forward is +sin, +cos)
  local angle = (i - 1) * (2 * math.pi / count)
  local tx = px + math.sin(angle) * radius
  local tz = pz + math.cos(angle) * radius
  local ty = py + height  -- ⚠️ Relative to player Y, not absolute map height

  local ok, res = Ess.Safe.call(function()
    Airstrike.SpawnOrdnance(ordnance, tx, ty, tz, 0, velocity, 0, "distance", burstDist)
  end)

  if ok then
    -- Unique loop ID per warhead to prevent sync collisions
    local loopId = "NukeSync_" .. i
    local ticks = 4  -- ~0.8s delay matches travel time to detonation altitude

    Ess.Loop.start(loopId, 0.2, function()
      ticks = ticks - 1
      if ticks <= 0 then
        local detY = ty - (burstDist * 0.65)
        Ess.Easy.Spawn.fx("global_particle_airstrike_tactnuke", tx, detY, tz)
        Ess.Easy.Spawn.fx("global_particle_exp_shockwave_ground_tactnuke", tx, detY - 15, tz)
        return false  -- Explicitly stop loop (v0.3.0 best practice)
      end
      return true
    end)
  else
    Loader.Printf("[NUKE] ❌ Spawn failed for #" .. i .. ": " .. tostring(res))
  end
end
