-- Savegame selection screen, displayed after the title screen.

local savegame_menu = {}

function savegame_menu:new()
  local object = {}
  setmetatable(object, self)
  self.__index = self
  return object
end

function savegame_menu:on_started()

  self.surface = sol.surface.create(320, 240)
  self.background_color = { 104, 144, 240 }
  self.background_img = sol.surface.create("menus/selection_menu_background.png")
  self.save_container_img = sol.surface.create("menus/selection_menu_save_container.png")
  self.option_container_img = sol.surface.create("menus/selection_menu_option_container.png")
  self.option1_text = sol.text_surface.create()
  self.option2_text = sol.text_surface.create()
  self.title_text = sol.text_surface.create{
    horizontal_alignment = "center",
    font = "fixed"
  }
  self.cursor_position = 1
  self.cursor_sprite = sol.sprite.create("menus/selection_menu_cursor")
  self.allow_cursor_move = true
  self.finished = false
  self.phase = nil
  self:read_savegames()
  sol.audio.play_music("game_over")

  self:init_phase_select_file()
end

function savegame_menu:on_key_pressed(key)

  if key == "escape" then
    -- stop the program
    sol.main.exit()
  elseif not self.finished then

    -- Phase-specific direction_pressed method.
    local method_name = "key_pressed_phase_" .. self.phase
    self[method_name](self, key)
  end
end

function savegame_menu:on_joypad_button_pressed(button)

  if not self.finished then
    -- Phase-specific joypad_button_pressed method.
    local method_name = "joypad_button_pressed_phase_" .. self.phase
    self[method_name](self, button)
  end
end

function savegame_menu:on_direction_pressed(direction8)

  if self.allow_cursor_move and not self.finished then

    -- The cursor moves too much when using a joypad axis.
    self.allow_cursor_move = false
    self:start_timer(100, function()
      self.allow_cursor_move = true
    end)

    -- Phase-specific direction_pressed method.
    local method_name = "direction_pressed_phase_" .. self.phase
    self[method_name](self, direction8)
  end
end

function savegame_menu:on_display(dst_surface)

  -- Background color.
  self.surface:fill_color(self.background_color)

  -- Clouds.
  -- TODO

  -- Savegames container.
  self.surface:draw(self.background_img, 37, 38)
  self.surface:draw(self.title_text, 160, 54)

  -- Phase-specific display method.
  local method_name = "display_phase_" .. self.phase
  self[method_name](self)

  -- The menu makes 320*240 pixels, but dst_surface may be larger.
  local width, height = dst_surface:get_size()
  dst_surface:draw(self.surface, width / 2 - 160, height / 2 - 120)
end

function savegame_menu:display_savegame(slot_index)

  local slot = self.slots[slot_index]
  self.surface:draw(self.save_container_img, 57, 48 + slot_index * 27)
  self.surface:draw(slot.player_name_text, 87, 61 + slot_index * 27)
  
  if slot.hearts_view ~= nil then
    slot.hearts_view:display(self.surface, 168, 51 + slot_index * 27)
  end
end

function savegame_menu:display_savegame_cursor()

  local x, y
  if self.cursor_position == 5 then
    x = 166
  else
    x = 58
  end
  if self.cursor_position < 4 then
    y = 49 + self.cursor_position * 27
  else
    y = 159
  end
  self.surface:draw(self.cursor_sprite, x, y)
end

function savegame_menu:display_savegame_number(slot_index)

  local slot = self.slots[slot_index]
  self.surface:draw(slot.number_img, 62, 53 + slot_index * 27)
end

function savegame_menu:display_bottom_options()

  local x
  local y = 158
  if self.option1_text:get_text():len() > 0 then
    x = 57
    self.surface:draw(self.option_container_img, x, y)
    self.surface:draw(self.option1_text, 90, 172)
  end
  if self.option2_text:get_text():len() > 0 then
    x = 165
    self.surface:draw(self.option_container_img, x, y)
    self.surface:draw(self.option2_text, 198, 172)
  end
end

function savegame_menu:read_savegames()

  self.slots = {}
  for i = 1, 3 do
    local slot = {}
    slot.file_name = "save" .. i .. ".dat"
    slot.savegame = sol.game.load(slot.file_name)
    slot.number_img = sol.surface.create("menus/selection_menu_save" .. i .. ".png")
    
    slot.player_name_text = sol.text_surface.create()
    if sol.game.exists(slot.file_name) then
      -- Existing file.
      slot.player_name_text:set_text(slot.savegame:get_player_name())

      -- Hearts.
      local hearts_class = require("hud/hearts")
      slot.hearts_view = hearts_class:new(slot.savegame)
    else
      -- New file.
      slot.player_name_text:set_text_key("selection_menu.empty")
    end

    self.slots[i] = slot
  end
end

function savegame_menu:set_bottom_options(key1, key2)

  self.option1_text:set_text_key(key1)
  self.option2_text:set_text_key(key2)
end

function savegame_menu:move_cursor_up()

  sol.audio.play_sound("cursor")
  local cursor_position = self.cursor_position - 1
  if cursor_position == 0 then
    cursor_position = 4
  elseif cursor_position == 4 then
    cursor_position = 3
  end
  self:set_cursor_position(cursor_position)
end

function savegame_menu:move_cursor_down()

  sol.audio.play_sound("cursor")
  local cursor_position = self.cursor_position + 1
  if cursor_position >= 5 then
    cursor_position = 1
  end
  self:set_cursor_position(cursor_position)
end

function savegame_menu:move_cursor_left_or_right()

  if self.cursor_position == 4 then
    sol.audio.play_sound("cursor")
    self:set_cursor_position(5)
  elseif self.cursor_position == 5 then
    sol.audio.play_sound("cursor")
    self:set_cursor_position(4)
  end
end

function savegame_menu:set_cursor_position(cursor_position)

  self.cursor_position = cursor_position
  self.cursor_sprite:set_frame(0)  -- Restart the animation.
end

---------------------------
-- Phase "select a file" --
---------------------------
function savegame_menu:init_phase_select_file()

  self.phase = "select_file"
  self.title_text:set_text_key("selection_menu.phase.select_file")
  self:set_bottom_options("selection_menu.erase", "selection_menu.options")
  self.cursor_sprite:set_animation("blue")
end

function savegame_menu:key_pressed_phase_select_file(key)

  if key == "space" or key == "return" then
    sol.audio.play_sound("ok")
    if self.cursor_position == 5 then
      -- The user chooses "Options".
      -- TODO
    elseif self.cursor_position == 4 then
      -- The user chooses "Erase".
      self:init_phase_erase_file()
    else
      -- The user chooses a savegame: run it after a fade-out effect.
      self.finished = true
      self.surface:fade_out(function()
        local slot = self.slots[self.cursor_position]
        slot.savegame:start()
      end)
    end
  end
end

function savegame_menu:joypad_button_pressed_phase_select_file(button)

  self:key_pressed_phase_select_file("space")
end

function savegame_menu:direction_pressed_phase_select_file(direction8)

  if direction8 == 6 then  -- Down.
    self:move_cursor_down()
  elseif direction8 == 2 then  -- Up.
    self:move_cursor_up()
  elseif direction8 == 0 or direction8 == 4 then  -- Right or Left.
    self:move_cursor_left_or_right()
  end
end

function savegame_menu:display_phase_select_file()

  -- Savegame slots.
  for i = 1, 3 do
    self:display_savegame(i)
  end

  -- Options.
  self:display_bottom_options()

  -- Cursor
  self:display_savegame_cursor()

  -- Save numbers.
  for i = 1, 3 do
    self:display_savegame_number(i)
  end
end

--------------------------
-- Phase "erase a file" --
--------------------------
function savegame_menu:init_phase_erase_file()

  self.phase = "erase_file"
  self.title_text:set_text_key("selection_menu.phase.erase_file")
  self:set_bottom_options("selection_menu.cancel", "")
  self.cursor_sprite():set_animation("red")
end

function savegame_menu:key_pressed_phase_erase_file(key)

  if self.cursor_position == 4 then
    -- The user chose "Cancel".
    sol.audio.play_sound("ok")
    self:init_phase_select_file()
  elseif self.cursor_position > 0 and self.cursor_position <= 3 then
    -- The user chose a savegame to delete.
    local slot = self.slots[self.cursor_position]
    if not sol.game.exists(slot.file_name) then
      -- The savegame doesn't exist: error sound
      sol.audio.play_sound("wrong")
    end
  end
end

function savegame_menu:joypad_button_pressed_phase_select_file(button)

  self:key_pressed_phase_erase_file("space")
end

function savegame_menu:direction_pressed_phase_erase_file(direction8)

end

function savegame_menu:display_phase_erase_file()

end

return savegame_menu
