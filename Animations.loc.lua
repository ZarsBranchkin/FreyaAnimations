local Freya = _G.Freya
local Intents = Freya:GetComponent "Intents"

local pop = table.remove
local tick = tick
local lastTick = tick()

local liveAnimations = {}
local animationQueue = {} -- Required for syncronizing animations with update thread

local function newAnimation(animFun, duration, params)
  assert(animFun, "newAnimation argument #1: Function expected")

  local animation = {}

  animation.t = 0
  animation.duration = duration or 1
  animation.dead = false
  animation.parameters = params or {}
  animation.update = animFun

  local proxy = newproxy(true)
  local mt = getmetatable(proxy)
  mt.__index = animation
  mt.__tostring = "Freya animation object"
  mt.__metatable = "Locked Metatable: Freya"
  mt.__newindex = function(t, i, v)
    assert(rawget(animation, i), ("Animation: Property %s doesn't exist"):format(tostring(i)))
    rawset(animation, i, v)
  end

  table.insert(animationQueue, proxy)

  return proxy
end

-- API
function AnimateProperty(isLocal, object, property, to, from, duration)
  assert(object and typeof(object) == "Instance", "Animations.AnimateProperty intent argument #1: Instance expected")
  assert(typeof(property) == "String" and object[property], "Animations.AnimateProperty intent argument #2: Valid property expected")
  assert(to, "Animations.AnimateProperty intent argument #3: Variable expected")

  from = from or object[property]
  duration = duration or 1

  local propType = typeof(to)

  assert(typeof(from) == propType, "Animations.AnimateProperty: From and to types does not match")

  local animator

  if propType == "number" then
    animator = function(alpha)
      object[property] = from + (to - from)*alpha
    end
  elseif propType == "Vector3" or propType == "CFrame" or propType == "Color3" then
    animator = function(alpha)
      object[property] = from:lerp(to, alpha)
    end
  else
    error(("Animations.AnimateProperty: Unsupported property type %s"):format(propType))
  end

  newAnimation(animator, duration)
end
Intents:Register("Animations.AnimateProperty", ClientAnimateProperty)

-- Update loop
local function updateAnimations()
  local currentTick = tick()
  local dt = currentTick - lastTick
  lastTick = currentTick

  -- Activate queued animations
  while #animationQueue > 0 do
    liveAnimations[#liveAnimations] = pop(animationQueue)
  end

  for i=1,#liveAnimations do
    local anim = liveAnimations[i]
    anim.t = anim.t + dt

    if animt.t >= anim.duration then
      anim.t = anim.duration
      anim.dead = true
    end

    anim:update(anim.t/anim.duration, dt)
  end

  -- Destroy dead animations
  local offset = 0
  for i=1,#liveAnimations do
    if liveAnimations[i-offset].dead then
      pop(liveAnimations, i-offset)
      offset = offset + 1
    end
  end
end
game:GetService("RunService"):BindToRenderStep("FreyaAnimations", Enum.RenderPriority.Camera.Value + 1, updateAnimations)
