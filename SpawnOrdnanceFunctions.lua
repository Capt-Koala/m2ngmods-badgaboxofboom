local ORDD_TOKEN = 0


local INPUT_SETTLE_TIME = 0.08
local CLEAR_SETTLE_TIME = 0.12
local DESIGNATOR_SETTLE_TIME = 0.25


local FAB_HEIGHT_OFFSET = 5
local FAB_CLOUD_ROLL_DEG = 0


local scheduleSeq = 0


-- ============================================================
-- BASICS
-- ============================================================


local function log(msg)
  pcall(function()
    if Loader and Loader.Printf then
      Loader.Printf(msg)
    end
  end)
end


local function toast(msg)
  local ok = pcall(function()
    if Ess and Ess.Easy and Ess.Easy.Toast then
      Ess.Easy.Toast(msg)
    end
  end)

  if not ok then
    log(msg)
  end
end


local function lastError(label)
  pcall(function()
    if Ess and Ess.lastError then
      local e = Ess.lastError()
      if e and e.msg then
        log("[ORDNANCE] " .. tostring(label) .. " lastError=" .. tostring(e.msg))
      end
    end
  end)
end


local function safe(fn, ...)
  if type(fn) ~= "function" then
    return false, "function missing"
  end

  if Ess and Ess.Safe and type(Ess.Safe.call) == "function" then
    return Ess.Safe.call(fn, ...)
  end

  local ok, res = pcall(fn, ...)
  return ok, res
end


local function apiCall(tbl, method, ...)
  local fn = type(tbl) == "table" and tbl[method] or nil

  if type(fn) ~= "function" then
    return false, "missing " .. tostring(method)
  end

  return safe(fn, ...)
end


local function after(seconds, fn)
  local function run()
    pcall(fn)
  end

  local ok = pcall(function()
    if Ess and Ess.Loop and type(Ess.Loop.start) == "function" then
      scheduleSeq = scheduleSeq + 1
      local id = "Ordnance_" .. scheduleSeq

      Ess.Loop.start(id, seconds, function()
        run()
        return false
      end)

      return true
    end

    return false
  end)

  if not ok then
    run()
  end
end


local function localPlayer()
  local ok, p = pcall(function()
    if Player and type(Player.GetLocalPlayer) == "function" then
      return Player.GetLocalPlayer()
    end
    return nil
  end)

  if ok and p then
    return p
  end

  ok, p = pcall(function()
    if Ess and Ess.Player and type(Ess.Player.character) == "function" then
      return Ess.Player.character(0)
    end
    return nil
  end)

  if ok and p then
    return p
  end

  return nil
end


local function flushInput()
  pcall(function()
    if Ess and Ess.Input and type(Ess.Input.clear) == "function" then
      Ess.Input.clear()
    end
  end)
end


local function inputBurst()
  pcall(function()
    if Ess and Ess.Player and type(Ess.Player.setInputEnabled) == "function" then
      Ess.Player.setInputEnabled(false, 0)
    end
  end)

  flushInput()

  after(INPUT_SETTLE_TIME, function()
    pcall(function()
      if Ess and Ess.Player and type(Ess.Player.setInputEnabled) == "function" then
        Ess.Player.setInputEnabled(true, 0)
      end
    end)

    flushInput()
  end)
end


local function closeUI()
  pcall(function()
    if Player and type(Player.SetPDAMapMode) == "function" then
      Player.SetPDAMapMode(false)
    end
  end)

  pcall(function()
    if Hud and Hud.SupportMenu and type(Hud.SupportMenu.Close) == "function" then
      Hud.SupportMenu.Close()
    end
  end)

  pcall(function()
    if Hud and Hud.PdaMenu and type(Hud.PdaMenu.Close) == "function" then
      Hud.PdaMenu.Close()
    end
  end)

  flushInput()
end


local function clearDesignatorOnce()
  local p = localPlayer()
  if not p then
    return
  end

  apiCall(Airstrike, "CancelDesignator", p)
  apiCall(Airstrike, "UnequipDesignator", p)

  flushInput()
end


local function clearDesignator(token)
  clearDesignatorOnce()

  after(0.05, function()
    if ORDD_TOKEN == token then
      clearDesignatorOnce()
    end
  end)

  after(CLEAR_SETTLE_TIME, function()
    if ORDD_TOKEN == token then
      flushInput()
    end
  end)
end


local function preloadLaser()
  pcall(function()
    if Pg and type(Pg.LoadAsset) == "function" then
      Pg.LoadAsset("global_weapon_laserrangefinder", "model")
    end
  end)
end


local function getViewYaw()
  local ok, y = pcall(function()
    if Ess and Ess.Player and type(Ess.Player.viewYaw) == "function" then
      return Ess.Player.viewYaw(0)
    end
    return nil
  end)

  if ok and y then
    return y
  end

  local p = localPlayer()
  if p then
    ok, y = pcall(function()
      if Object and type(Object.GetYaw) == "function" then
        return Object.GetYaw(p)
      end
      return nil
    end)

    if ok and y then
      return y
    end
  end

  return 0
end


-- ============================================================
-- FX
-- ============================================================


local function fx(proto, x, y, z)
  if Ess and Ess.Easy and Ess.Easy.Spawn and type(Ess.Easy.Spawn.fx) == "function" then
    local ok = pcall(function()
      return Ess.Easy.Spawn.fx(proto, x, y, z)
    end)

    if ok then
      return true
    end
  end

  local ok = pcall(function()
    if Pg and type(Pg.Spawn) == "function" then
      return Pg.Spawn(proto, x, y, z)
    end
    return false
  end)

  if not ok then
    log("[ORDNANCE] FX spawn failed: " .. tostring(proto))
  end

  return ok
end


local function spawnFABCloud(x, y, z)
  local dx, dy, dz

  if FAB_CLOUD_ROLL_DEG == 0 then
    -- Locked 12 o'clock orientation.
    dx, dy, dz = 0, -1, 0
  else
    local yawRad = math.rad(getViewYaw())
    local rollRad = math.rad(FAB_CLOUD_ROLL_DEG)

    local rightX = math.cos(yawRad)
    local rightZ = -math.sin(yawRad)

    dx = rightX * math.sin(rollRad)
    dy = -math.cos(rollRad)
    dz = rightZ * math.sin(rollRad)

    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len > 0 then
      dx = dx / len
      dy = dy / len
      dz = dz / len
    end
  end

  local ok, res = apiCall(
    Airstrike,
    "SpawnDirectedObject",
    "global_particle_airstrike_fuelairbomb",
    x,
    y,
    z,
    dx,
    dy,
    dz
  )

  if ok and res ~= false then
    log("[ORDNANCE] FAB cloud spawned, roll=" .. tostring(FAB_CLOUD_ROLL_DEG))
    return true
  end

  lastError("FAB directed spawn")
  log("[ORDNANCE] FAB directed spawn failed, using fallback FX spawn")
  return fx("global_particle_airstrike_fuelairbomb", x, y, z)
end


local function fallTime(ord)
  return (ord.dist or 80) / math.max(1, math.abs(ord.vel or -90))
end


local function impactY(ord, groundY)
  local spawnY = groundY + (ord.height or 80)
  local detY = spawnY + (ord.vel or -90) * fallTime(ord)

  return math.max(detY, groundY - 2)
end


local function playFX(ord, bx, detY, bz)
  local fxType = ord.fx or "DEFAULT"


  local function defaultBlast()
    fx("Explosion (Bombing Run)", bx, detY, bz)
    fx("global_particle_exp_shockwave_ground", bx, detY, bz)
  end


  if fxType == "NUKE" then
    fx("global_particle_airstrike_tactnuke", bx, detY, bz)

    after(1.0, function()
      fx("global_particle_exp_shockwave_ground_tactnuke", bx, math.max(0, detY), bz)
    end)


  elseif fxType == "FAB" then
    local fabY = detY + FAB_HEIGHT_OFFSET

    spawnFABCloud(bx, fabY, bz)

    after(1.6, function()
      fx("Light_airstrike_fuelairbomb_sml", bx, fabY, bz)
      fx("global_particle_exp_falling_debris_airstrike", bx, fabY, bz)

      pcall(function()
        if Sound and type(Sound.CueSound) == "function" then
          Sound.CueSound(0, "exp_oiltrucker")
        end
      end)
    end)

    after(1.75, function()
      fx("Explosion (Fuel Air Bomb)", bx, fabY, bz)
      fx("Light_airstrike_fuelairbomb_lrg_flash", bx, fabY, bz)
      fx("global_particle_exp_shockwave_ground", bx, fabY, bz)
    end)


  elseif fxType == "CLUSTER" then
    for i = 1, 6 do
      local a = (i - 1) * (2 * math.pi / 6)
      local cx = bx + math.sin(a) * 12
      local cz = bz + math.cos(a) * 12
      fx("Explosion (Bombing Run)", cx, detY, cz)
    end

    fx("global_particle_exp_shockwave_ground", bx, detY, bz)


  else
    defaultBlast()
  end
end


-- ============================================================
-- ORDNANCE LIST
-- ============================================================


local ORDNANCE = {
  {
    label = "Gunship Shell",
    proto = "Gunship Shell",
    height = 30,
    vel = -90,
    dist = 40,
    fx = "DEFAULT",
  },

  {
    label = "Heavy Artillery",
    proto = "Artillery Shell",
    height = 40,
    vel = -90,
    dist = 50,
    fx = "DEFAULT",
  },

  {
    label = "Rocket Artillery",
    proto = "Rocket Artillery Projectile",
    height = 80,
    vel = -90,
    dist = 90,
    fx = "DEFAULT",
  },

  {
    label = "Cluster Bomb",
    proto = "Cluster Bomb Projectile",
    height = 90,
    vel = -90,
    dist = 90,
    fx = "CLUSTER",
  },

  {
    label = "Laser Guided Bomb",
    proto = "Laser Guided Bomb Projectile",
    height = 60,
    vel = -100,
    dist = 65,
    fx = "DEFAULT",
  },

  {
    label = "Fuel Air Bomb",
    proto = "Fuel Air Bomb Projectile",
    height = 90,
    vel = -90,
    dist = 105,
    fx = "FAB",
  },

  {
    label = "Smart Bomb",
    proto = "Smart Bomb Projectile",
    height = 70,
    vel = -95,
    dist = 75,
    fx = "DEFAULT",
  },

  {
    label = "Daisy Cutter",
    proto = "Daisy Cutter Projectile",
    height = 100,
    vel = -75,
    dist = 110,
    fx = "DEFAULT",
  },

  {
    label = "Cruise Missile",
    proto = "Cruise Missile Projectile",
    height = 70,
    vel = -85,
    dist = 80,
    fx = "DEFAULT",
  },

  {
    label = "MOAB",
    proto = "MOAB Projectile",
    height = 120,
    vel = -65,
    dist = 130,
    fx = "DEFAULT",
  },

  {
    label = "Tactical Nuke",
    proto = "Nuclear Bunker Buster Projectile",
    height = 80,
    vel = -90,
    dist = 100,
    fx = "NUKE",
  },
}


-- ============================================================
-- STRIKE
-- ============================================================


local function strikeAt(ord, bx, by, bz, token)
  local ty = by + (ord.height or 80)

  local ok, res = apiCall(
    Airstrike,
    "SpawnOrdnance",
    ord.proto,
    bx,
    ty,
    bz,
    0,
    ord.vel or -90,
    0,
    "distance",
    ord.dist or 80
  )

  if not ok or res == false then
    log("[ORDNANCE] spawn failed: " .. tostring(ord.proto))
    lastError("spawn ordnance")
    toast("Spawn failed: " .. tostring(ord.label))
    return false
  end

  log("[ORDNANCE] spawn ok: " .. tostring(ord.proto))
  toast("Dropped: " .. tostring(ord.label))

  local detY = impactY(ord, by)
  local ft = fallTime(ord)

  after(ft, function()
    playFX(ord, bx, detY, bz)
  end)

  after(0.2, function()
    if ORDD_TOKEN == token then
      clearDesignator(token)
      inputBurst()
    end
  end)

  return true
end


local function spawnAtTarget(ord, uTarget, token)
  local ok, x, y, z = pcall(function()
    if Object and type(Object.GetPosition) == "function" then
      return Object.GetPosition(uTarget)
    end
    return nil, nil, nil
  end)

  if not ok or not x then
    log("[ORDNANCE] failed to get painted target position")
    toast("Painted target position failed")
    return false
  end

  log("[ORDNANCE] painted target = " .. tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z))

  return strikeAt(ord, x, y, z, token)
end


-- ============================================================
-- DESIGNATOR
-- ============================================================


local function equipDesignator(ord)
  ORDD_TOKEN = ORDD_TOKEN + 1
  local token = ORDD_TOKEN

  closeUI()
  clearDesignator(token)
  flushInput()

  after(DESIGNATOR_SETTLE_TIME, function()
    if ORDD_TOKEN ~= token then
      return
    end

    local pNow = localPlayer()
    if not pNow then
      toast("No local player found")
      log("[ORDNANCE] no local player after delay")
      return
    end

    closeUI()
    clearDesignatorOnce()
    flushInput()
    preloadLaser()

    if type(Airstrike) ~= "table" or type(Airstrike.EquipDesignator) ~= "function" then
      log("[ORDNANCE] Airstrike.EquipDesignator missing")
      toast("Airstrike.EquipDesignator missing")
      ORDD_TOKEN = ORDD_TOKEN + 1
      return
    end

    local fired = false

    local function onPaint(sTag, uTarget)
      if ORDD_TOKEN ~= token or fired then
        return
      end

      fired = true

      if not uTarget then
        toast("No painted target")
        clearDesignator(token)
        inputBurst()
        return
      end

      local ok = spawnAtTarget(ord, uTarget, token)
      if not ok then
        clearDesignator(token)
        inputBurst()
      end
    end

    local ok, res = apiCall(
      Airstrike,
      "EquipDesignator",
      pNow,
      "Laser Designator",
      onPaint,
      { "ORDNANCE" },
      false
    )

    if ok and res ~= false then
      log("[ORDNANCE] designator equipped: " .. tostring(ord.label))
      toast("Laser ready: " .. tostring(ord.label))
      inputBurst()
    else
      log("[ORDNANCE] designator equip failed: " .. tostring(res))
      lastError("equip designator")
      toast("Designator equip failed")
      ORDD_TOKEN = ORDD_TOKEN + 1
    end
  end)
end


-- ============================================================
-- MENU
-- ============================================================


if menu and type(menu.category) == "function" then
  menu:category("Ordnance Drops", function(cnt)
    cnt:entry("Clear Designator", function()
      ORDD_TOKEN = ORDD_TOKEN + 1
      clearDesignator(ORDD_TOKEN)
      inputBurst()
      toast("Designator cleared")
    end)

    for i = 1, #ORDNANCE do
      local ord = ORDNANCE[i]
      cnt:entry(ord.label, function()
        equipDesignator(ord)
      end)
    end
  end)
end