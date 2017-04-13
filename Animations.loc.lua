local Freya = _G.Freya
local Intents = Freya:GetComponent "Intents"

local LiveAnimations = {}
local AnimationQueue = {}

local function newAnimation(animFun, duration, params)
  assert(animFun, "Argument #1 expects animator function")

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

  table.insert(AnimationQueue, proxy)

  return proxy
end

