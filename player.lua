-- Create a new player for the first time
local function new_player()
  return {
    speed_x = 0,
    speed_y = 0,

    -- Hurt box
    x = 0,
    y = arenaHeight / 2 - 5,
    width = 50,
    height = 58,
    
    sprite_sheet = love.graphics.newImage('sprites/ship.png'),

    should_draw = true
  }
end

local function reset_player(ship)
  ship.speed_x = 0
  ship.speed_y = 0
  ship.x = 0
  ship.y = arenaHeight / 2 - 5
  ship.should_draw = true
end

local function setup_properties_from_dice(dice_roles)
  return {
    max_speed = 300 + (dice_roles[1] - 1) * 120, -- 300 - 900
    acceleration = 300 + (dice_roles[2] - 1) * 140, -- 300- 1000
    max_shooting_speed = 0.3 + (dice_roles[3] - 1) * 0.02, -- 0.3 t0 0.4,
    health = dice_roles[4],
    kills = 0
  }
end

local player = {
  new_player = new_player,
  reset_player = reset_player,
  setup_properties_from_dice = setup_properties_from_dice
}

return player
