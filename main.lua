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

function create_enemy(x, y)
  return {
    x = x,
    y = y,
    speed_x = 0,
    speed_y = 0,
    width = 72,
    height = 64,
    health = enemy_properties.health,
    should_draw = true,
    hurtbox = {
      invincible = false,
      timer = 0
    }
  }
end

function update_enemy_properties(dice, properties)
    properties.max_speed = 400 + (dice[1] - 1) * 40 -- 400 - 600
    properties.acceleration = 200 + (dice[2] - 1) * 40 -- 200 - 600
    properties.health = dice[3] + 1
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
      player_hurt_box.timer = 0
      player_hurt_box.invincible = false
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

  ship = player.new_player()

  player_properties = {}
  enemy_properties = {
    previous_max_speed = 3,
    previous_acceleration = 3,
    previous_health = 3
  }
  update_enemy_properties({3, 3, 3}, enemy_properties)

  bullet_timer = 0
  bullets = {}
  bullet_sprite = love.graphics.newImage('sprites/blaster_shot.png')

  -- TODO: This can be one of the things that I set randomly
  enemy_timer_limit = 0.6
  enemy_timer = 0
  enemies = { create_enemy(arenaWidth, love.math.random(arenaHeight)) }
  enemy_sprite = love.graphics.newImage('sprites/ufo.png')
  enemy_hurtbox_limit = 0.2

  finished_dice = false
  dice.init(
    function()
      finished_dice = true
      sounds.enter_main_game:play()
    end
  )
  dice_result = {}
  heart_sprite = love.graphics.newImage('sprites/heart.png')
  player_hurt_box = {
    timer = 0.0,
    max_time = 1.0,
    invincible = false -- The player was recently hurt but has a few invincibility frames now
  }

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
    health_restored = love.audio.newSource('sounds/health.ogg', 'static'),
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
      if player_properties.health == 2 then
        -- Give a 50/50 shot at getting more health
        if love.math.random() >= 0.5 then
          player_properties.health = player_properties.health + 1
          sounds.health_restored:play()
        end
      elseif player_properties.health == 1 then
        player_properties.health = player_properties.health + 1
        sounds.health_restored:play()
      end
      randomize_enemy_timer = 0
      notified = false
      rolling_enemy_dice = true
      dice.start(2, 0.2)
    end
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
    dice_result = dice.update(dt)
    if dice_result then
      player_properties = player.setup_properties_from_dice(dice_result)
      bullet_timer = player_properties.max_shooting_speed
    end
  end

  if rolling_enemy_dice then
    enemy_dice_result = dice.update(dt)
    if enemy_dice_result then
      rolling_enemy_dice = false
      finished_roll_but_not_finished_showing_result = true
      -- Update the enemy properties
      update_enemy_properties(enemy_dice_result, enemy_properties)
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

  -- TODO: It could be nice to let the users rebind their controls (advanced feature)
  -- Move the player
  if love.keyboard.isDown('w') then
    ship.speed_y = ship.speed_y - player_properties.acceleration * dt
  end
  if love.keyboard.isDown('s') then
    ship.speed_y = ship.speed_y + player_properties.acceleration * dt
  end
  if love.keyboard.isDown('a') then
    ship.speed_x = ship.speed_x - player_properties.acceleration * dt
  end
  if love.keyboard.isDown('d') then
    ship.speed_x = ship.speed_x + player_properties.acceleration * dt
  end

  if math.abs(ship.speed_x) > player_properties.max_speed then
    print("You reached max speed!")
    if ship.speed_x < 0 then
      ship.speed_x = -player_properties.max_speed
    else
      ship.speed_x = player_properties.max_speed
    end
  end
  if math.abs(ship.speed_y) > player_properties.max_speed then
    print("You reached max speed!")
    if ship.speed_y < 0 then
      ship.speed_y = -player_properties.max_speed
    else
      ship.speed_y = player_properties.max_speed
    end
  end

  -- Shoot bullets
  bullet_timer = bullet_timer + dt

  if love.keyboard.isDown('space') then
    if bullet_timer >= player_properties.max_shooting_speed then
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

  -- Check to see if the player has won the game
  if player_properties.kills >= win_condition then
    win_state.won = true
    sounds.main_theme:stop()
    sounds.win_theme:play()
  end

  -- Move the bullets, and remove them after the reach the edge of the screen
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
    table.insert(enemies, create_enemy(arenaWidth, love.math.random(arenaHeight)))
    enemy_timer = 0
  end

  if player_hurt_box.invincible then
    player_hurt_box.timer = player_hurt_box.timer + dt
    ship.should_draw = not ship.should_draw
    if player_hurt_box.timer >= player_hurt_box.max_time then
      player_hurt_box.invincible = false
      player_hurt_box.timer = 0
      ship.should_draw = true
    end
  end

  -- Move the enemies and check to see if they collided with the player or the bullets
  -- TODO: Set this randomly
  for enemy_index = #enemies, 1, -1 do
    local enemy = enemies[enemy_index]
    -- Enemies have invincibility frames after they get hit
    if enemy.hurtbox.invincible then
      enemy.hurtbox.timer = enemy.hurtbox.timer + dt
      enemy.should_draw = not enemy.should_draw
      if enemy.hurtbox.timer >= enemy_hurtbox_limit then
        enemy.hurtbox.invincible = false
        enemy.hurtbox.timer = 0
        enemy.should_draw = true
      end
    end

    -- First third: can adjust x and y position and accelerate
    if enemy.x >= arenaWidth / 2 then
      enemy.speed_x = enemy.speed_x - enemy_properties.acceleration * dt
      if ship.y < enemy.y then
        enemy.speed_y = enemy.speed_y - enemy_properties.acceleration * dt
      else
        enemy.speed_y = enemy.speed_y + enemy_properties.acceleration * dt
      end
    else
      enemy.speed_y = 0
    end
    enemy.x = enemy.x + enemy.speed_x * dt
    enemy.y = enemy.y + enemy.speed_y * dt

    if math.abs(enemy.speed_x) > enemy_properties.max_speed then
      if enemy.speed_x < 0 then
        enemy.speed_x = -enemy_properties.max_speed
      else
        enemy.speed_x = enemy_properties.max_speed
      end
    end
    if math.abs(enemy.speed_y) > enemy_properties.max_speed then
      if enemy.speed_y < 0 then
        enemy.speed_y = -enemy_properties.max_speed
      else
        enemy.speed_y = enemy_properties.max_speed
      end
    end
    
    if enemy.x + enemy.width < 0 then
      table.remove(enemies, enemy_index)
    end
    if rect_collide(enemy, ship) then
      if not player_hurt_box.invincible then
        player_hurt_box.invincible = true
        player_hurt_box.timer = 0
        player_properties.health = player_properties.health - 1
        sounds.player_explosion:play()

        if player_properties.health <= 0 then
          win_state.lost = true
          sounds.main_theme:stop()
          sounds.lose_theme:play()
        end
      end
    end

    for bullet_index = #bullets, 1, -1 do
      local bullet = bullets[bullet_index]
      if rect_collide(bullet, enemy) then
        if not enemy.hurtbox.invincible then
          table.remove(bullets, bullet_index)

          enemy.hurtbox.invincible = true
          enemy.hurtbox.timer = 0
          enemy.health = enemy.health - 1
          sounds.enemy_explosion:play()
          if enemy.health <= 0 then
            player_properties.kills = player_properties.kills + 1
            table.remove(enemies, enemy_index)
          end
        end
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
    draw_centered_text(0, 100, arenaWidth, 0, "Dice Defense")

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
  if ship.should_draw then
    local ship_scale_factor = 0.4
    love.graphics.draw(ship.sprite_sheet, ship.x, ship.y, 0, ship_scale_factor, ship_scale_factor)
  end

  -- Draw the bullets
  local bullet_scale_factor = 0.5
  for bullet_index, bullet in ipairs(bullets) do
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(bullet_sprite, bullet.x, bullet.y, 0, bullet_scale_factor, bullet_scale_factor)
  end

  -- Draw the enemies
  local enemy_scale_factor = 0.3
  for enemy_index, enemy in ipairs(enemies) do
    if enemy.should_draw then
      love.graphics.draw(enemy_sprite, enemy.x - 30, enemy.y, 0, enemy_scale_factor, enemy_scale_factor)
    end
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

  -- Player kill count
  local kill_scale_factor = 0.18
  local kill_edge = arenaWidth - 350
  love.graphics.draw(enemy_sprite, kill_edge, 10, 0, kill_scale_factor, kill_scale_factor)
  love.graphics.setFont(secondary_font)
  love.graphics.print(player_properties.kills, kill_edge - 30, 10)
  love.graphics.print("/ "..win_condition, kill_edge + 100, 10)
  love.graphics.setFont(main_font)

  -- Player health
  for i = 1, player_properties.health do
    love.graphics.draw(heart_sprite, (i * 32) + 5, 0)
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
