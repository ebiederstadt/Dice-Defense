local anim8 = require 'libraries/anim8'
local button = require 'button'
require 'utils'

local dice = {}


-- Called once to initalize the state
local function init(f)
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
  dice_stage_complete = false
  dice_font = create_font(32)
  start_button = button.newButton("Start", f)
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

local function draw(main_font)
  love.graphics.setFont(dice_font)
  love.graphics.setColor(1, 1, 1)
  local scale_factor = 2
  local half_single_sprite = sprite_sheet:getWidth() / 12
  local stats = {
    "Speed",
    "Acceleration",
    "Shooting Speed",
    "Projectile Size"
  }
  for i, animation in ipairs(animations) do
    animation:draw(sprite_sheet, (arenaWidth * i / 5) - half_single_sprite * scale_factor, 75, 0, scale_factor, scale_factor)
  end

  if playing then
    draw_centered_text(0, 0, arenaWidth, 50, "Rolling The Dice...")
  else
    draw_centered_text(0, 0, arenaWidth, 50, "Your Stats")
    local rect_width = 0.75 * arenaWidth
    love.graphics.setColor(unpack(ui_color))
    local rect = {
      x = (arenaWidth / 2) - (rect_width / 2),
      y = 150
    }
    local padding = 10
    local dy = 80
    love.graphics.rectangle('fill', rect.x, rect.y, rect_width, 325, 15, 15)
    love.graphics.setColor(1, 1, 1)
    for i, stat in ipairs(stats) do
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(stat, rect.x + padding, rect.y + padding + (dy * (i - 1)))
      love.graphics.setColor(unpack(highlight_color))
      love.graphics.rectangle('fill', rect.x + padding, rect.y + padding + 40 + (dy  * (i - 1)), rect_width - padding * 2, 20, 5, 5)
      love.graphics.setColor(1, 1, 1, 0.8)
      local one_bar_portion = (rect_width - padding * 2) / 6
      love.graphics.rectangle('fill', rect.x + padding, rect.y + padding + 40 + (dy  * (i - 1)), one_bar_portion * random_values[i], 20, 5, 5)
    end
    button.draw_button_custom_pos(start_button, (arenaWidth * 0.66), 490)
  end
  
  love.graphics.setFont(main_font)
end

local function draw_enemy(default_font)
  love.graphics.setFont(dice_font)
  love.graphics.setColor(1, 1, 1)

  local half_single_sprite = sprite_sheet:getWidth() / 12
  local scale_factor = 2

  if playing then
    draw_centered_text(0, 0, arenaWidth, 50, "Rolling The Dice...")
  end
  for i, animation in ipairs(animations) do
    -- We only care about the first two animations
    if i > 2 then
      break
    end
    animation:draw(sprite_sheet, (arenaWidth * i / 3) - half_single_sprite * scale_factor, 75, 0, scale_factor, scale_factor)
  end
end

dice.init = init
dice.start = start
dice.update = update
dice.draw = draw
dice.draw_enemy = draw_enemy

return dice
