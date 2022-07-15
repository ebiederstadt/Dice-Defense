local anim8 = require 'libraries/anim8'

-- Checks to see if rectangles are overlapping with each other
-- first_rect are tables that have x, y, width, and height defined
function rect_collide(first_rect, second_rect)
  return first_rect.x + first_rect.width > second_rect.x and first_rect.x < second_rect.x + second_rect.width and
         first_rect.y + first_rect.height > second_rect.y and first_rect.y < second_rect.y + second_rect.y
end

function love.load()
  love.graphics.setDefaultFilter('nearest', 'nearest')

  areaWidth = 800
  arenaHeight = 600
  -- TODO: Eventually, we will create this randomly
  ship = {
    speed_x = 0,
    speed_y = 0,

    -- Hurt box
    x = 0,
    y = arenaHeight / 2 - 5,
    width = 64,
    height = 64,
    
    sprite_sheet = love.graphics.newImage('sprites/ship.png')
  }

  -- These properties will be set according to the dice roll we get at the start
  player_properties = {
    max_speed = 0,
    acceleration = 0,
    shooting_speed = 0,
    projectile_size = 0
  }

  -- TODO: Set this randomly
  bullet_timer_limit = 0.5
  bullet_timer = bullet_timer_limit
  bullets = {}

  -- TODO: This can be one of the things that I set randomly
  enemy_timer_limit = 1.0
  enemy_timer = 0
  enemies = {{
      x = areaWidth,
      y = love.math.random(arenaHeight),
      width = 64,
      height = 64
    }}

  -- Images and sprites
  math.randomseed(os.time()) -- Make our numbers actually random

  dice_timer_limit = 0.2
  dice_timer = dice_timer_limit
  dice_scene_timer_max = 3.0
  dice_scene_timer = 0.0
  sprite_sheet = love.graphics.newImage('sprites/dice.png')
  local grid = anim8.newGrid(32, 32, sprite_sheet:getWidth(), sprite_sheet:getHeight())
  player_animation_speed = anim8.newAnimation(grid('1-6', 1), 0.5)
  player_animation_acceleration = anim8.newAnimation(grid('1-6', 1), 0.5)
  player_animation_shooting_speed = anim8.newAnimation(grid('1-6', 1), 0.5)
  player_animation_projectile_size = anim8.newAnimation(grid('1-6', 1), 0.5)
end

function love.update(dt)
  -- TODO: This will be set randomly
  local shipSpeed = 100
  -- TODO: It could be nice to let the users choose their controls (advanced feature)
  -- Move the player
  if love.keyboard.isDown('w') then
    ship.speed_y = ship.speed_y - shipSpeed * dt
  end
  if love.keyboard.isDown('s') then
    ship.speed_y = ship.speed_y + shipSpeed * dt
  end
  if love.keyboard.isDown('a') then
    ship.speed_x = ship.speed_x - shipSpeed * dt
  end
  if love.keyboard.isDown('d') then
    ship.speed_x = ship.speed_x + shipSpeed * dt
  end

  -- Shoot bullets
  bullet_timer = bullet_timer + dt

  if love.keyboard.isDown('space') then
    if bullet_timer >= bullet_timer_limit then
      bullet_timer = 0
      table.insert(bullets, {
        x = ship.x + ship.width / 2,
        y = ship.y + ship.height / 2,
        width = 8,
        height = 8
      })
    end
  end

  -- Move the ship and limit it to the arena bounds
  -- TODO: needs to be polished
  ship.x = ship.x + ship.speed_x * dt
  ship.y = ship.y + ship.speed_y * dt
  if ship.x + ship.width > areaWidth then
    ship.x = areaWidth - ship.width
    ship.speed_x = 0
  end
  if ship.x < 0 then
    ship.x = 0
    ship.speed_x = 0
  end
  if ship.y + ship.height > arenaHeight then
    ship.y = arenaHeight - ship.height
    ship.speed_y = 0
  end
  if ship.y < 0 then
    ship.y = 0
    ship.speed_y = 0
  end

  -- Move the bullets, and remove them after the reach the edge of the screen
  -- TODO: Movement speed could be something that we randomize
  local bullet_speed = 500
  for bullet_index = #bullets, 1, -1 do
    local bullet = bullets[bullet_index]
    bullet.x = bullet.x + bullet_speed * dt
    if bullet.x + bullet.width > areaWidth then
      table.remove(bullets, bullet_index)
    end
  end

  -- Add new enemies
  enemy_timer = enemy_timer + dt
  if enemy_timer >= enemy_timer_limit then
    table.insert(enemies, {
      x = areaWidth,
      y = love.math.random(arenaHeight),
      width = 64,
      height = 64
    })
    enemy_timer = 0
  end

  -- Move the enemies and check to see if they collided with the player or the bullets
  -- TODO: Set this randomly
  local enemy_speed = 200
  for enemy_index = #enemies, 1, -1 do
    local enemy = enemies[enemy_index]
    enemy.x = enemy.x - enemy_speed * dt
    if enemy.x < 0 then
      table.remove(enemies, enemy_index)
    end
    if rect_collide(enemy, ship) then
      -- TODO: Display a screen to indicate that the player lost the game, instead of jfust quitting
      love.event.quit(0)
    end

    for bullet_index = #bullets, 1, -1 do
      local bullet = bullets[bullet_index]
      if rect_collide(bullet, enemy) then
        table.remove(bullets, bullet_index)
        table.remove(enemies, enemy_index)
      end
    end
  end

  -- Animate the dice (we want to go to a random frame each time)
  dice_timer = dice_timer + dt
  dice_scene_timer = dice_scene_timer + dt

  -- Prevent any overflows (no idea if this would actually be an issue)
  if dice_scene_timer >= dice_scene_timer_max then
    dice_scene_timer = dice_scene_timer_max
  end
  if dice_timer >= dice_timer_limit then
    player_properties.max_speed = math.random(1, 6)
    player_properties.acceleration = math.random(1, 6)
    player_properties.shooting_speed = math.random(1, 6)
    player_properties.projectile_size = math.random(1, 6)

    player_animation_speed:gotoFrame(player_properties.max_speed)
    player_animation_acceleration:gotoFrame(player_properties.acceleration)
    player_animation_shooting_speed:gotoFrame(player_properties.shooting_speed)
    player_animation_projectile_size:gotoFrame(player_properties.projectile_size)
    dice_timer = 0
  end
end

function love.draw()
  -- Draw the ship
  -- TODO: In the future, only draw the sprite
  love.graphics.setColor(0, 0, 1)
  local ship_scale_factor = 2
  love.graphics.rectangle('line', ship.x, ship.y, ship.width, ship.height)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(ship.sprite_sheet, ship.x, ship.y, 0, ship_scale_factor, ship_scale_factor)

  -- Draw the bullets
  for bullet_index, bullet in ipairs(bullets) do
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle('fill', bullet.x, bullet.y, bullet.width, bullet.height)
  end

  -- Draw the enemies
  for enemy_index, enemy in ipairs(enemies) do
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle('fill', enemy.x, enemy.y, enemy.width, enemy.height)
  end

  -- Draw the dice if we are in the 
  if dice_scene_timer < dice_scene_timer_max then
    love.graphics.setColor(1, 1, 1)
    local scale_factor = 2
    local half_single_sprite = sprite_sheet:getWidth() / 12
    player_animation_speed:draw(sprite_sheet, (areaWidth / 5) - half_single_sprite * scale_factor, 50, 0, scale_factor, scale_factor)
    player_animation_acceleration:draw(sprite_sheet, (areaWidth * 2 / 5) - half_single_sprite * scale_factor, 50, 0, scale_factor, scale_factor)
    player_animation_shooting_speed:draw(sprite_sheet, (areaWidth * 3 / 5) - half_single_sprite * scale_factor, 50, 0, scale_factor, scale_factor)
    player_animation_projectile_size:draw(sprite_sheet, (areaWidth * 4 / 5) - half_single_sprite * scale_factor, 50, 0, scale_factor, scale_factor)
  end
end
