BUTTON_HEIGHT = 64

local button = {}

local sounds = {}
local function setup()
  sounds.enter = love.audio.newSource('sounds/forceField_001.ogg', 'static')
  sounds.leave = love.audio.newSource('sounds/forceField_000.ogg', 'static')
end

local function newButton(text, fn)
  return {
    text = text,
    fn = fn,
    current_state = {
      hovered = false,
      clicked = false
    },
    previous_state = {
      hovered = false,
      clicked = false
    }
  }
end

local function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in next, orig, nil do
          copy[deepcopy(orig_key)] = deepcopy(orig_value)
      end
      setmetatable(copy, deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end

local function draw_buttons(buttons)
  local button_width = 0.66 * arenaWidth
  local margin = 16
  local total_height = (BUTTON_HEIGHT + margin) * #buttons
  local cursor_y = 0
  local mouse_x, mouse_y = love.mouse.getPosition()
  for button_index, button in ipairs(buttons) do
    button.previous_state = deepcopy(button.current_state)

    local button_x = (arenaWidth / 2) - (button_width / 2)
    local button_y = (arenaHeight / 2) - (total_height / 2) + cursor_y

    local color = { 0.4, 0.4, 0.8, 0.8 };
    button.current_state.hovered = mouse_x > button_x and mouse_x < button_x + button_width and
                                   mouse_y > button_y and mouse_y < button_y + BUTTON_HEIGHT
    if button.current_state.hovered then
      color = { 0.8, 0.4, 1.0, 0.8 };
    end

    -- Enter event
    if button.current_state.hovered and not button.previous_state.hovered then
      sounds.enter:play();
    end
    -- Leave event
    if not button.current_state.hovered and button.previous_state.hovered then
      sounds.leave:play()
    end

    button.current_state.clicked = love.mouse.isDown(1)
    if button.current_state.clicked and not button.previous_state.clicked and button.current_state.hovered then
      button.fn()
    end
    
    love.graphics.setColor(unpack(color))
    love.graphics.rectangle('fill', button_x, button_y, button_width, BUTTON_HEIGHT, 15, 15)
    love.graphics.setColor(1, 1, 1)
    draw_centered_text(button_x, button_y, button_width, BUTTON_HEIGHT, button.text)

    cursor_y = cursor_y + (BUTTON_HEIGHT + margin)
  end
end

button.setup = setup
button.newButton = newButton
button.draw_buttons =draw_buttons

return button
