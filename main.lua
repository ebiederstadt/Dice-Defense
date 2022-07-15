function love.load()
  areaWidth = 800
  arenaHeight = 600
  ship_radius = 30
  -- TODO: Eventually, we will create this randomly
  ship = {
    speed_x = 0,
    speed_y = 0,

    -- Start in the middle of the screen (TODO: We should change this)
    x = areaWidth / 2,
    y = arenaHeight / 2
  }

  -- TODO: Set this randomly
  bullet_timer_limit = 0.5
  bullet_timer = bullet_timer_limit
  bullets = {}
end

function love.update(dt)
  -- TODO: This will be set randomly
  local shipSpeed = 100
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

  -- Update the bullet timer
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
  end
  if ship.x < 0 then
    ship.x = 0
  end
  if ship.y > arenaHeight then
    ship.y = arenaHeight
  end
  if ship.y < 0 then
    ship.y = 0
  end

  -- Move the bullets, and remove them after the reach the edge of the screen
  for bullet_index = #bullets, 1, -1 do
    local bullet = bullets[bullet_index]
    -- TODO: This might be something that we want to randomize
    local bullet_speed = 500
    bullet.x = bullet.x + bullet_speed * dt
    if bullet.x > areaWidth then
      table.remove(bullets, bullet_index)
    end
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
end
