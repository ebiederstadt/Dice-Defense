local anim8 = require 'libraries/anim8'
require 'constants'

local dice = {}


-- Called once to initalize the state
local function init()
  math.randomseed(os.time())

  sound_effect = love.audio.newSource('sounds/dieShuffle3.ogg', 'static')
  sound_effect:setLooping(true)
  sprite_sheet = love.graphics.newImage('sprites/dice.png')
  grid = anim8.newGrid(32, 32, sprite_sheet:getWidth(), sprite_sheet:getHeight())
  animations = {
    anim8.newAnimation(grid('1-6', 1), 0.5),
    anim8.newAnimation(grid('1-6', 1), 0.5),
    anim8.newAnimation(grid('1-6', 1), 0.5),
    anim8.newAnimation(grid('1-6', 1), 0.5)
  }
  random_values = {}
  playing = false
end

state = {}

-- Start rolling the dice
local function start(time_limit, switch_limit)
  -- How long the overall animation should play for
  state.time_limit = time_limit
  timer = 0

  -- How long before showing a new roll
  state.switch_limit = switch_limit
  switch_timer = 0

  sound_effect:play()

  playing = true
end

-- Update the dice. Returns nil when time remains, and the four dice values when finished
local function update(dt)
  if not playing then
    return
  end

  timer = timer + dt
  switch_timer = switch_timer + dt

  -- After a certian amount of time we produce a new dice result
  if switch_timer >= state.switch_limit then
    for i, animation in ipairs(animations) do
      random_values[i] = math.random(1, 6)
      animation:gotoFrame(random_values[i])
    end
  end

  if timer >= state.time_limit then
    sound_effect:stop()
    playing = false
    return random_values
  else
    return nil
  end
end

local function draw()
  love.graphics.setColor(1, 1, 1)
  local scale_factor = 2
  local half_single_sprite = sprite_sheet:getWidth() / 12
  for i, animation in ipairs(animations) do
    animation:draw(sprite_sheet, (arenaWidth * i / 5) - half_single_sprite * scale_factor, 50, 0, scale_factor, scale_factor)
  end
end

dice.init = init
dice.start = start
dice.update = update
dice.draw = draw

return dice
