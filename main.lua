local button = require 'button'

local player = require 'player'
local dice = require 'dice'

require 'utils'

-- Checks to see if rectangles are overlapping with each other
-- first_rect are tables that have x, y, width, and height defined
function rect_collide(first_rect, second_rect)
  return first_rect.x + first_rect.width > second_rect.x and first_rect.x < second_rect.x + second_rect.width and
         first_rect.y + first_rect.height > second_rect.y and first_rect.y < second_rect.y + second_rect.width
end

function love.load()
  love.graphics.setDefaultFilter('nearest', 'nearest')
  math.randomseed(os.time())

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
      dice.start(3, 0.2)
      sounds.start_game:play()
      sounds.main_theme:play()
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
    "Play Again",
    function()
      win_state.won = false
      win_state.lost = false
      is_paused = false
      is_started = false
      finished_dice = false
      rolling_enemy_dice = false
      randomize_enemy_timer = 0
      sounds.win_theme:stop()
      sounds.lose_theme:stop()
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

  -- TODO: Eventually, we will create this randomly
  ship = player.new_player()

  -- These properties will be set according to the dice roll we get at the start
  player_properties = {
    max_speed = 0,
    acceleration = 0,
    shooting_speed = 0,
    projectile_size = 0
  }
  enemy_properties = {
    max_speed = 3,
    previous_max_speed = 3,
    acceleration = 3,
    previous_acceleration = 3,
    health = 3,
    previous_health = 3
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

  finished_dice = false
  dice.init(
    function()
      finished_dice = true
      sounds.enter_main_game:play()
    end
  )
  dice_result = {}

  background = love.graphics.newImage("sprites/background.png")
  background:setWrap("repeat", "repeat")
  background_quad = love.graphics.newQuad(0, 0, background:getWidth(), background:getHeight(), background:getWidth(), background:getHeight())  
  background_pos = 0

  -- Fonts
  main_font = create_font(64)
  secondary_font = create_font(32)
  third_font = create_font(16)
  if main_font then
    love.graphics.setFont(main_font)
  end

  -- Sounds
  sounds = {
    laser = love.audio.newSource('sounds/laserSmall.ogg', 'static'),
    enemy_explosion = love.audio.newSource('sounds/explosionCrunch.ogg', 'static'),
    player_explosion = love.audio.newSource('sounds/explosionCrunch_003.ogg', 'static'),
    start_game = love.audio.newSource('sounds/doorOpen_002.ogg', 'static'),
    can_randomize = love.audio.newSource('sounds/computerNoise_000.ogg', 'static'),
    enter_main_game = love.audio.newSource('sounds/doorOpen_000.ogg', 'static'),
    main_theme = love.audio.newSource('sounds/VoxelRevolution.ogg', 'stream'),
    win_theme = love.audio.newSource('sounds/GettingitDone.ogg', 'stream'),
    lose_theme = love.audio.newSource('sounds/OneSlyMove.ogg', 'stream')
  }
  love.audio.setVolume(0.5)

  -- Some of the sounds should loop
  sounds.win_theme:setLooping(true)
  sounds.lose_theme:setLooping(true)

  sounds.can_randomize:setVolume(1.0)

  -- Randomizing enemies
  dice_indcators = {
    normal = love.graphics.newImage('sprites/dice_normal.png'),
    modified = love.graphics.newImage('sprites/dice_modified.png')
  }
  randomize_enemy_limit = 7
  randomize_enemy_timer = 0
  notified = false
  rolling_enemy_dice = false
  finished_roll_but_not_finished_showing_result = false
  enemy_dice_result = {}
  time_to_show_dice = 2
  dice_result_timer = 0
end

function love.keypressed(key)
  if key == "escape" then
    if is_started and finished_dice then
      is_paused = not is_paused
      if is_paused then
        sounds.main_theme:setVolume(0.8)
      else
        sounds.main_theme:setVolume(1.0)
      end
    end
  end
  -- Enter will allow the user to randomize the enemy stats
  if key == 'return' then
    if randomize_enemy_timer >= randomize_enemy_limit and not rolling_enemy_dice then
      randomize_enemy_timer = 0
      notified = false
      rolling_enemy_dice = true
      dice.start(2, 0.2)
    end
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

  -- Only update this if we are actually in the dice scene
  if not finished_dice then
    -- TODO: Store the dice result and use it for the player properties
    dice_result = dice.update(dt)
  end

  if rolling_enemy_dice then
    enemy_dice_result = dice.update(dt)
    if enemy_dice_result then
      print("Test!")
      rolling_enemy_dice = false
      finished_roll_but_not_finished_showing_result = true
      -- Update the enemy properties
      enemy_properties.max_speed = enemy_dice_result[1]
      enemy_properties.acceleration = enemy_dice_result[2]
      enemy_properties.health = enemy_dice_result[3]
    end
  end

  if finished_roll_but_not_finished_showing_result then
    dice_result_timer = dice_result_timer + dt
    if dice_result_timer >= time_to_show_dice then
      -- Reset the state
      finished_roll_but_not_finished_showing_result = false
      enemy_properties.previous_max_speed = enemy_properties.max_speed
      enemy_properties.previous_acceleration = enemy_properties.acceleration
      enemy_properties.previous_health = enemy_properties.health
      dice_result_timer = 0
    end
  end

  -- Only perform the main simulation if we are not rolling the dice
  if not finished_dice then
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
    if enemy.x + enemy.width < 0 then
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

  -- Update the dice timer
  randomize_enemy_timer = randomize_enemy_timer + dt
  if randomize_enemy_timer >= randomize_enemy_limit and not notified then
    sounds.can_randomize:play()
    notified = true
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

  if not finished_dice then
    dice.draw(secondary_font)
    love.graphics.setFont(main_font)
    return
  end
  
  if win_state.won then
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

  if is_paused then
    love.graphics.setColor(0.008, 0.051, 0.122)
    love.graphics.rectangle('fill', arenaWidth / 2 - 150, 50, 300, 100, 10, 10)
    love.graphics.setColor(1, 1, 1)
    draw_centered_text(0, 100, arenaWidth, 0, "Paused")

    button.draw_buttons(pause_buttons)
  end

  -- Enemy dice
  local dice_scale_factor = 0.1
  if randomize_enemy_timer >= randomize_enemy_limit then
    love.graphics.draw(dice_indcators.modified, arenaWidth - 100, 0, 0, dice_scale_factor)
  else
    love.graphics.draw(dice_indcators.normal, arenaWidth - 100, 0, 0, dice_scale_factor)
  end

  if rolling_enemy_dice or finished_roll_but_not_finished_showing_result then
    dice.draw_enemy(secondary_font)
  end
  if finished_roll_but_not_finished_showing_result then
    love.graphics.setFont(third_font)
    local bad_color = { 0.839, 0.188, 0.192 };
    local good_color = { 0.18, 0.835, 0.451 };
    if enemy_properties.max_speed > enemy_properties.previous_max_speed then
      love.graphics.setColor(unpack(bad_color))
      love.graphics.print("Speed++", arenaWidth / 4 - 50, 300)
    end
    if enemy_properties.max_speed <= enemy_properties.previous_max_speed then
      love.graphics.setColor(unpack(good_color))
      love.graphics.print("Speed--", arenaWidth / 4 - 50, 300)
    end
    if enemy_properties.acceleration > enemy_properties.previous_acceleration then
      love.graphics.setColor(unpack(bad_color))
      love.graphics.print("Acceleration++", arenaWidth / 2 - 100, 300)
    end
    if enemy_properties.acceleration <= enemy_properties.previous_acceleration then
      love.graphics.setColor(unpack(good_color))
      love.graphics.print("Acceleration--", arenaWidth / 2 - 100, 300)
    end
    if enemy_properties.health > enemy_properties.previous_health then
      love.graphics.setColor(unpack(bad_color))
      love.graphics.print("Health++", arenaWidth * 3 / 4 - 50, 300)
    end
    if enemy_properties.health <= enemy_properties.previous_health then
      love.graphics.setColor(unpack(good_color))
      love.graphics.print("Health--", arenaWidth * 3/4 - 50, 300)
    end

    love.graphics.setFont(main_font)
    love.graphics.setColor(1, 1, 1, 1)
  end
end
