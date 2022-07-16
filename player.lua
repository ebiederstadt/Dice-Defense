-- Create a new player for the first time
local function new_player()
  return {
    speed_x = 0,
    speed_y = 0,

    -- Hurt box
    x = 0,
    y = arenaHeight / 2 - 5,
    width = 100,
    height = 64,
    
    sprite_sheet = love.graphics.newImage('sprites/ship.png')
  }
end

-- Reset the player
local function reset_player(ship)
  ship.speed_x = 0
  ship.speed_y = 0
  ship.x = 0
  ship.y = arenaHeight / 2 - 5
end

local player = {
  new_player = new_player,
  reset_player = reset_player
}

return player
