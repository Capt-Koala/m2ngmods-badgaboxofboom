-- ==========================================
-- ORDNANCE DROPS CATEGORY (Ess v0.3.0)
-- FX Altitude tuned to 2-10m above player level
-- ==========================================

-- Nuke-specific spawner (UNCHANGED)
function spawnNuke(tx, tz, ty, burstDist)
  local ok = Ess.Safe.call(function()
    Airstrike.SpawnOrdnance("Nuclear Bunker Buster Projectile", tx, ty, tz, 0, -90, 0, "distance", burstDist)
  end)
  if not ok then return false end

  local loopId = "NukeSeq_" .. tostring(math.random(1000,9999))
  Ess.Loop.start(loopId, 0.2, function()
    local detY = math.max(0, ty - burstDist)
    Ess.Safe.call(function() Pg.Spawn("global_particle_airstrike_tactnuke", tx, detY, tz) end)
    return false
  end)
  
  local =shockId = "NukeShock_" .. tostring(math.random(1000,9999))
  Ess.Loop.start(shockId, 1.0, function()
    local detY = math.max(0, ty - burstDist)
    Ess.Safe.call(function() Pg.Spawn("global_particle_exp_shockwave_ground_tactnuke", tx, detY, tz) end)
    return false
  end)
  return true
end

function dropNukes(ctx, ringMode)
  local uChar = Ess.Player.character(0)
  if not uChar then Ess.Easy.Toast("No player found"); return end
  
  local px, py, pz = Ess.Object.pos(uChar)
  local pYaw = Ess.Player.viewYaw(0) or Ess.Object.yaw(uChar)
  local radius = 120
  local height = 60
  local burstDist = 100
  
  if ringMode then
    local success = true
    for i = 1, 8 do
      local angle = (i - 1) * (2 * math.pi / 8)
      local tx = px + math.sin(pYaw + angle) * radius
      local tz = pz + math.cos(pYaw + angle) * radius
      if not spawnNuke(tx, tz, py + height, burstDist) then success = false end
    end
    if success then Ess.Easy.Toast("Nuke Ring Armed (8x)") end
  else
    local tx, tz = Ess.Math.pointAhead(px, pz, pYaw, radius)
    if spawnNuke(tx, tz, py + height, burstDist) then Ess.Easy.Toast("Nuke Dropped") end
  end
end

-- Generic ordnance spawner with ground-locked FX
function dropOrdnance(ctx, name, radius, height, triggerType, triggerVal, velocity, fxType, fxAlt)
  fxAlt = fxAlt or -2 -- Changed to negative to act as a ground-proximity buffer
  local uChar = Ess.Player.character(0)
  if not uChar then Ess.Easy.Toast("No player found"); return end
  
  local px, py, pz = Ess.Object.pos(uChar)
  local pYaw = Ess.Player.viewYaw(0) or Ess.Object.yaw(uChar)
  local tx, tz = Ess.Math.pointAhead(px, pz, pYaw, radius)
  local ty = py + height
  
  local ok = Ess.Safe.call(function()
    Airstrike.SpawnOrdnance(name, tx, ty, tz, 0, velocity, 0, triggerType, triggerVal)
  end)
  
  if not ok then Ess.Easy.Toast("Spawn failed: " .. name); return end
  
  -- Detonation timing based on travel
  local detTime = triggerVal / math.abs(velocity)
  
  -- ✅ FIXED: Calculate actual detonation Y based on projectile fall distance
  local detY = ty + (velocity * detTime)
  -- Clamp to a safe minimum to prevent underground spawns, without overriding the fall calculation
  detY = math.max(detY, py + fxAlt)
  
  local seqId = "OrdSeq_" .. tostring(math.random(10000,99999))
  Ess.Loop.start(seqId, detTime, function()
    if fxType == "FAB" then
      Ess.Safe.call(function() Airstrike.SpawnDirectedObject("global_particle_airstrike_fuelairbomb", tx, detY, tz, 0, -1, 0) end)
      
      local ignId = "FABIgn_" .. tostring(math.random(1000,9999))
      Ess.Loop.start(ignId, 1.6, function()
        Ess.Safe.call(function() Pg.Spawn("Light_airstrike_fuelairbomb_sml", tx, detY, tz) end)
        Ess.Safe.call(function() Pg.Spawn("global_particle_exp_falling_debris_airstrike", tx, detY, tz) end)
        Sound.CueSound(0, "exp_oiltrucker")
        return false
      end)
      
      local fireId = "FABFire_" .. tostring(math.random(1000,9999))
      Ess.Loop.start(fireId, 1.75, function()
        Ess.Safe.call(function() Pg.Spawn("Explosion (Fuel Air Bomb)", tx, detY, tz) end)
        Ess.Safe.call(function() Pg.Spawn("Light_airstrike_fuelairbomb_lrg_flash", tx, detY, tz) end)
        Ess.Safe.call(function() Pg.Spawn("global_particle_exp_shockwave_ground", tx, detY, tz) end)
        return false
      end)
    elseif fxType == "CLUSTER" then
      for i = 1, 6 do
        local a = (i - 1) * (2 * math.pi / 6)
        local cx = tx + math.sin(a) * 12
        local cz = tz + math.cos(a) * 12
        Ess.Safe.call(function() Pg.Spawn("Explosion (Bombing Run)", cx, detY, cz) end)
      end
      Ess.Safe.call(function() Pg.Spawn("global_particle_exp_shockwave_ground", tx, detY, tz) end)
    else
      Ess.Safe.call(function() Pg.Spawn("Explosion (Bombing Run)", tx, detY, tz) end)
      Ess.Safe.call(function() Pg.Spawn("global_particle_exp_shockwave_ground", tx, detY, tz) end)
    end
    return false
  end)
  Ess.Easy.Toast("Dropped: " .. name)
end



-- ==========================================
-- MENU CATEGORY
-- ==========================================
menu:category("Ordnance Drops", function(ctx)
-- Ordered from estimated smallest blast to largest
  ctx:entry("Gunship Shell",          function() dropOrdnance(ctx, "Gunship Shell", 40, 30, "distance", 40, -90, "IMPACT", 2) end)
  ctx:entry("Heavy Artillery",        function() dropOrdnance(ctx, "Artillery Shell", 50, 40, "distance", 50, -90, "IMPACT", 2) end)
  ctx:entry("Rocket Artillery",       function() dropOrdnance(ctx, "Rocket Artillery Projectile", 80, 80, "distance", 90, -90, "IMPACT", 2) end)
  ctx:entry("Cluster Bomb",           function() dropOrdnance(ctx, "Cluster Bomb Projectile", 70, 90, "distance", 90, -90, "CLUSTER", -10) end)
  ctx:entry("Laser Guided Bomb",      function() dropOrdnance(ctx, "Laser Guided Bomb Projectile", 50, 60, "distance", 65, -100, "IMPACT", 2) end)
  ctx:entry("Fuel Air Bomb",          function() dropOrdnance(ctx, "Fuel Air Bomb Projectile", 60, 95, "distance", 105, -90, "FAB", 0) end)
  ctx:entry("Smart Bomb",             function() dropOrdnance(ctx, "Smart Bomb Projectile", 60, 70, "distance", 75, -95, "IMPACT", 2) end)
  ctx:entry("Daisy Cutter",           function() dropOrdnance(ctx, "Daisy Cutter Projectile", 120, 100, "distance", 110, -75, "IMPACT", 0) end)
  ctx:entry("Cruise Missile",         function() dropOrdnance(ctx, "Cruise Missile Projectile", 100, 70, "distance", 80, -85, "IMPACT", 2) end)
  ctx:entry("MOAB",                   function() dropOrdnance(ctx, "MOAB Projectile", 150, 120, "distance", 130, -65, "IMPACT", 0) end)
  ctx:entry("Tactical Nuke (Single)", function() dropNukes(ctx, false) end)
  ctx:entry("Tactical Nuke (Ring 8x)", function() dropNukes(ctx, true) end)
end)
