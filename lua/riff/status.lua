local M = {}
local config = require('riff.config').get

local current_song = nil

local function show_song_status()
  if current_song then
    local status_text = "🎵 " .. current_song .. " ▶"
    vim.api.nvim_echo({{status_text}}, false, {})
  end
end

local function update_status_line()
  vim.defer_fn(show_song_status, config().status_echo_delay_ms or 10)
end

function M.set_current_song(title)
  current_song = title
  update_status_line()
end

function M.clear()
  current_song = nil
  update_status_line()
end

return M


