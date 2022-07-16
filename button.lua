BUTTON_HEIGHT = 64

local button = {}

local function newButton(text, fn)
  return {
    text = text,
    fn = fn,
    current_state = nil,
    previous_state = nil
  }
end

local function draw_buttons(buttons)
  local button_width = 0.66 * arenaWidth
  local margin = 16
  local total_height = (BUTTON_HEIGHT + margin) * #buttons
  local cursor_y = 0
  local mouse_x, mouse_y = love.mouse.getPosition()
  for button_index, button in ipairs(buttons) do
    button.previous_state = button.current_state

    local button_x = (arenaWidth / 2) - (button_width / 2)
    local button_y = (arenaHeight / 2) - (total_height / 2) + cursor_y

    local color = { 0.4, 0.4, 0.8, 0.8 };
    local hovered = mouse_x > button_x and mouse_x < button_x + button_width and
                    mouse_y > button_y and mouse_y < button_y + BUTTON_HEIGHT
    if hovered then
      color = { 0.8, 0.4, 1.0, 0.8 };
    end

    button.current_state = love.mouse.isDown(1)
    if button.current_state and not button.previous_state and hovered then
      button.fn()
    end
    
    love.graphics.setColor(unpack(color))
    love.graphics.rectangle('fill', button_x, button_y, button_width, BUTTON_HEIGHT, 15, 15)
    love.graphics.setColor(1, 1, 1)
    draw_centered_text(button_x, button_y, button_width, BUTTON_HEIGHT, button.text)

    cursor_y = cursor_y + (BUTTON_HEIGHT + margin)
  end
end

button.newButton = newButton
button.draw_buttons =draw_buttons

return button
