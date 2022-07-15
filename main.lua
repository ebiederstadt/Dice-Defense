local anim8 = require 'libraries/anim8'

function love.load()
  areaWidth = 800
  arenaHeight = 600
  ship_radius = 30
  -- TODO: Eventually, we will create this randomly
  ship = {
    speed_x = 0,
    speed_y = 0,

    -- Start in the middle of the screen
    x = 0,
    y = arenaHeight / 2
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
      y = love.math.random(arenaHeight)
    }}

  -- Images and sprites
  love.graphics.setDefaultFilter('nearest', 'nearest')
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
        x = ship.x + ship_radius,
        y = ship.y
      })
    end
  end

  -- Move the ship and limit it to the arena bounds
  -- TODO: needs to be polished
  ship.x = ship.x + ship.speed_x * dt
  ship.y = ship.y + ship.speed_y * dt
  if ship.x > areaWidth then
    ship.x = areaWidth
    ship.speed_x = 0
  end
  if ship.x < 0 then
    ship.x = 0
    ship.speed_x = 0
  end
  if ship.y > arenaHeight then
    ship.y = arenaHeight
    ship.speed_y = 0
  end
  if ship.y < 0 then
    ship.y = 0
    ship.speed_y = 0
  end

  -- Move the bullets, and remove them after the reach the edge of the screen
  -- TODO: This might be something that we want to randomize
  local bullet_speed = 500
  for bullet_index = #bullets, 1, -1 do
    local bullet = bullets[bullet_index]
    bullet.x = bullet.x + bullet_speed * dt
    if bullet.x > areaWidth then
      table.remove(bullets, bullet_index)
    end
  end

  -- Add new enemies
  enemy_timer = enemy_timer + dt
  if enemy_timer >= enemy_timer_limit then
    table.insert(enemies, {
      x = areaWidth,
      y = love.math.random(arenaHeight)
    })
    enemy_timer = 0
  end

  -- Move the enemies
  -- TODO: Set this randomly
  local enemy_speed = 200
  for enemy_index = #enemies, 1, -1 do
    local enemy = enemies[enemy_index]
    enemy.x = enemy.x - enemy_speed * dt
    if enemy.x < 0 then
      table.remove(enemies, enemy_index)
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
  love.graphics.setColor(0, 0, 1)
  love.graphics.circle('fill', ship.x, ship.y, ship_radius)

  -- Draw the bullets
  for bullet_index, bullet in ipairs(bullets) do
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle('fill', bullet.x, bullet.y, 5)
  end

  -- Draw the enemies
  for enemy_index, enemy in ipairs(enemies) do
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle('fill', enemy.x, enemy.y, 40)
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
