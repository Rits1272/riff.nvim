local config = require('riff.config')
local search = require('riff.search')
local picker = require('riff.picker')
local playback = require('riff.playback')
local queue = require('riff.queue')
local queue_buffer = require('riff.queue_buffer')

queue.init()

local function riff_picker(query)
  search.search_ytmusic(query, function(results)
    if #results == 0 then
      vim.notify("❌ No results found for: " .. query, vim.log.levels.WARN)
      return
    end
    picker.open(results)
  end)
end

vim.api.nvim_create_user_command("Riff", function(opts)
  local query = table.concat(opts.fargs, " ")
  riff_picker(query)
end, { nargs = "+" })

vim.api.nvim_create_user_command("RiffPause", playback.pause, {})
vim.api.nvim_create_user_command("RiffResume", playback.resume, {})
vim.api.nvim_create_user_command("RiffStop", playback.stop, {})
vim.api.nvim_create_user_command("RiffQueue", queue_buffer.show, {})
vim.api.nvim_create_user_command("RiffQueueNext", playback.play_next_from_queue, {})
vim.api.nvim_create_user_command("RiffQueueClear", queue.clear, {})
vim.api.nvim_create_user_command("RiffQueueShuffle", queue.shuffle, {})

return {
  setup = function(opts)
    config.setup(opts)
  end,
}

