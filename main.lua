local anim8 = require 'libraries/anim8'
local button = require 'button'

local player = require 'player'


-- Checks to see if rectangles are overlapping with each other
-- first_rect are tables that have x, y, width, and height defined
function rect_collide(first_rect, second_rect)
  return first_rect.x + first_rect.width > second_rect.x and first_rect.x < second_rect.x + second_rect.width and
         first_rect.y + first_rect.height > second_rect.y and first_rect.y < second_rect.y + second_rect.width
end

function draw_centered_text(rectX, rectY, rectWidth, rectHeight, text)
	local font = love.graphics.getFont()
	local textWidth = font:getWidth(text)
	local textHeight = font:getHeight()
	love.graphics.print(text, rectX+rectWidth/2, rectY+rectHeight/2, 0, 1, 1, textWidth/2, textHeight/2)
end

function love.load()
  love.graphics.setDefaultFilter('nearest', 'nearest')

  button.setup()

  -- Pause menu
  is_paused = false
  pause_buttons = {}
  table.insert(pause_buttons, button.newButton(
    "Continue",
    function()
      is_paused = false
    end
  ))
  table.insert(pause_buttons, button.newButton(
    "Quit",
    function()
      love.event.quit(0)
    end
  ))
 
  -- Main menu
  is_started = false
  main_buttons = {}
  table.insert(main_buttons, button.newButton(
    "Start",
    function()
      is_started = true
      sounds.start_game:play()
      sounds.main_theme:play()
    end
  ))
  table.insert(main_buttons , button.newButton(
    "How to Play",
    function()
      print('TODO: implement the how to play screen')
    end
  ))
  table.insert(main_buttons, button.newButton(
    "Quit",
    function()
      love.event.quit(0)
    end
  ))

  -- Win/ Loss screens
  win_state = {
    won = false,
    lost = false,
  }
  end_buttons = {}
  table.insert(end_buttons, button.newButton(
    "Play Again?",
    function()
      win_state.won = false
      win_state.lost = false
      is_paused = false
      is_started = false
      for i, v in ipairs(enemies) do
        table.remove(enemies, i)
      end
      for i, v in ipairs(bullets) do
        table.remove(bullets, i)
      end
      player.reset_player(ship)
    end
  ))
  table.insert(end_buttons, button.newButton(
    "Quit",
    function()
      love.event.quit(0)
    end
  ))

  arenaWidth = 800
  arenaHeight = 600
  -- TODO: Eventually, we will create this randomly
  ship = player.new_player()

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
  bullet_sprite = love.graphics.newImage('sprites/blaster_shot.png')

  -- TODO: This can be one of the things that I set randomly
  enemy_timer_limit = 1.0
  enemy_timer = 0
  enemies = {{
      x = arenaWidth,
      y = love.math.random(arenaHeight),
      width = 120,
      height = 64
    }}
  enemy_sprite = love.graphics.newImage('sprites/destroyer.png')

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

  background = love.graphics.newImage("sprites/background.png")
  background:setWrap("repeat", "repeat")
  background_quad = love.graphics.newQuad(0, 0, background:getWidth(), background:getHeight(), background:getWidth(), background:getHeight())  
  background_pos = 0

  -- Fonts
  local font_path = 'fonts/VCR_OSD_MONO_1.001.ttf'
  if love.filesystem.exists(font_path) then
    local font = love.graphics.newFont(font_path, 64)
    love.graphics.setFont(font)
  end

  -- Sounds
  sounds = {
    laser = love.audio.newSource('sounds/laserSmall.ogg', 'static'),
    enemy_explosion = love.audio.newSource('sounds/explosionCrunch.ogg', 'static'),
    player_explosion = love.audio.newSource('sounds/explosionCrunch_003.ogg', 'static'),
    start_game = love.audio.newSource('sounds/doorOpen_002.ogg', 'static'),
    main_theme = love.audio.newSource('sounds/VoxelRevolution.ogg', 'stream'),
    win_theme = love.audio.newSource('sounds/GettingitDone.ogg', 'stream'),
    lose_theme = love.audio.newSource('sounds/OneSlyMove.ogg', 'stream')
  }

end

function love.keypressed(key)
  if key == "escape" then
    is_paused = not is_paused
  end
  -- TODO: remove me, just for testing for now
  if key == 'p' then
    win_state.won = true
    sounds.main_theme:stop()
    sounds.win_theme:play()
  end
end

function love.update(dt)
  if is_paused then
    return
  end

  if not is_started then
    return
  end

  if win_state.won or win_state.lost then
    return
  end

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
        x = ship.x + ship.width,
        y = ship.y + ship.height / 2,
        width = 8,
        height = 8
      })
      sounds.laser:play()
    end
  end

  -- Move the ship and limit it to the arena bounds
  -- TODO: needs to be polished
  ship.x = ship.x + ship.speed_x * dt
  ship.y = ship.y + ship.speed_y * dt
  if ship.x + ship.width > arenaWidth then
    ship.x = arenaWidth - ship.width
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
    if bullet.x + bullet.width > arenaWidth then
      table.remove(bullets, bullet_index)
    end
  end

  -- Add new enemies
  enemy_timer = enemy_timer + dt
  if enemy_timer >= enemy_timer_limit then
    table.insert(enemies, {
      x = arenaWidth,
      y = love.math.random(arenaHeight),
      width = 120,
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
      win_state.lost = true
      sounds.player_explosion:play()
      sounds.main_theme:stop()
      sounds.lose_theme:play()
    end

    for bullet_index = #bullets, 1, -1 do
      local bullet = bullets[bullet_index]
      if rect_collide(bullet, enemy) then
        table.remove(bullets, bullet_index)
        table.remove(enemies, enemy_index)
        sounds.enemy_explosion:play()
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
  love.graphics.setColor(1, 1, 1)
  background_quad:setViewport(background_pos, 0, background:getWidth(), background:getHeight())
  love.graphics.draw(background, background_quad, 0, 0, 0)

  if not is_started then
    love.graphics.setColor(0.008, 0.051, 0.122)
    love.graphics.rectangle('fill', arenaWidth / 2 - 150, 50, 300, 100, 10, 10)
    love.graphics.setColor(1, 1, 1)
    draw_centered_text(0, 100, arenaWidth, 0, "Rolling Racer") -- TODO: need a better name

    button.draw_buttons(main_buttons)
    return
  end
  
  if win_state.won then
    love.graphics.setColor(0.008, 0.051, 0.122)
    love.graphics.rectangle('fill', arenaWidth / 2 - 150, 100, 300, 100, 10, 10)
    love.graphics.setColor(1, 1, 1)
    draw_centered_text(0, 100, arenaWidth, 0, "You Won! Well Done")

    button.draw_buttons(end_buttons)
    return
  end
  if win_state.lost then
    love.graphics.setColor(1, 1, 1)
    draw_centered_text(0, 100, arenaWidth, 0, "You Lost.")

    button.draw_buttons(end_buttons)
    return
  end

  background_pos = background_pos + 0.5
  if background_pos > background:getWidth() then
    background_pos = 0
  end
  
  -- Draw the ship
  -- TODO: In the future, only draw the sprite
  love.graphics.setColor(0, 0, 1)
  local ship_scale_factor = 0.4
  love.graphics.rectangle('line', ship.x, ship.y, ship.width, ship.height)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(ship.sprite_sheet, ship.x, ship.y, 0, ship_scale_factor, ship_scale_factor)

  -- Draw the bullets
  local bullet_scale_factor = 0.5
  for bullet_index, bullet in ipairs(bullets) do
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(bullet_sprite, bullet.x, bullet.y, 0, bullet_scale_factor, bullet_scale_factor)
  end

  -- Draw the enemies
  local enemy_scale_factor = 0.3
  for enemy_index, enemy in ipairs(enemies) do
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle('line', enemy.x, enemy.y, enemy.width, enemy.height) -- Hitbox
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(enemy_sprite, enemy.x, enemy.y - 15, 0, enemy_scale_factor, enemy_scale_factor)
  end

  if dice_scene_timer < dice_scene_timer_max then
    love.graphics.setColor(1, 1, 1)
    local scale_factor = 2
    local half_single_sprite = sprite_sheet:getWidth() / 12
    player_animation_speed:draw(sprite_sheet, (arenaWidth / 5) - half_single_sprite * scale_factor, 50, 0, scale_factor, scale_factor)
    player_animation_acceleration:draw(sprite_sheet, (arenaWidth * 2 / 5) - half_single_sprite * scale_factor, 50, 0, scale_factor, scale_factor)
    player_animation_shooting_speed:draw(sprite_sheet, (arenaWidth * 3 / 5) - half_single_sprite * scale_factor, 50, 0, scale_factor, scale_factor)
    player_animation_projectile_size:draw(sprite_sheet, (arenaWidth * 4 / 5) - half_single_sprite * scale_factor, 50, 0, scale_factor, scale_factor)
  end

  if is_paused then
    love.graphics.setColor(0.008, 0.051, 0.122)
    love.graphics.rectangle('fill', arenaWidth / 2 - 150, 50, 300, 100, 10, 10)
    love.graphics.setColor(1, 1, 1)
    draw_centered_text(0, 100, arenaWidth, 0, "Paused")

    button.draw_buttons(pause_buttons)
  end
end
