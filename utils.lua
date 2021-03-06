arenaWidth = 800
arenaHeight = 600

win_condition = 30

ui_color = { 0.4, 0.4, 0.8, 0.8 }
highlight_color = { 0.8, 0.4, 1.0, 0.8 }

function draw_centered_text(rectX, rectY, rectWidth, rectHeight, text)
	local font = love.graphics.getFont()
	local textWidth = font:getWidth(text)
	local textHeight = font:getHeight()
	love.graphics.print(text, rectX+rectWidth/2, rectY+rectHeight/2, 0, 1, 1, textWidth/2, textHeight/2)
end

function create_font(size, set_font)
  return love.graphics.newFont('fonts/VCR_OSD_MONO_1.001.ttf', size)
end
