local playback = require('riff.playback')
local queue = require('riff.queue')

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local M = {}

function M.open(results)
  local display_opts = entry_display.create({
    separator = " ",
    items = { { width = 50 }, { width = 20 } }
  })

  local function make_display(entry)
    local artist = entry.value.artist or "Unknown"
    local duration = entry.value.duration or "?"
    local title = entry.value.title or "Unknown"
    return display_opts({ title .. " — " .. artist, "[" .. duration .. "]" })
  end

  pickers.new({}, {
            prompt_title = "Riff 🎶 (Enter: Play | Shift+Enter/Right: Add to Queue & Auto-Play)",
    default_selection_index = 1,
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        return {
          value = entry,
          display = function(e) return make_display(e) end,
          ordinal = tostring(entry.title or "")
        }
      end
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      local run_selection = function(prompt_bufnr)
        local selection = action_state.get_selected_entry(prompt_bufnr)
        actions.close(prompt_bufnr)
        if selection and selection.value then
          local val = selection.value
          if type(val) == "table" and val.video_id and val.title then
            playback.play(val.video_id, val.title)
          elseif type(val) == "table" and val.value and val.value.video_id and val.value.title then
            playback.play(val.value.video_id, val.value.title)
          end
        end
      end

      local add_to_queue = function(prompt_bufnr)
        local selection = action_state.get_selected_entry(prompt_bufnr)
        if selection and selection.value then
          local val = selection.value
          local song_data = nil
          local song_title = ""
          
          if type(val) == "table" and val.video_id and val.title then
            song_data = val
            song_title = val.title
          elseif type(val) == "table" and val.value and val.value.video_id and val.value.title then
            song_data = val.value
            song_title = val.value.title
          else
            vim.notify("Invalid song data for queue", vim.log.levels.ERROR)
            return
          end
          
          actions.close(prompt_bufnr)
          
          -- Handle queue operations in background
          vim.defer_fn(function()
            -- Add to queue
            queue.add_to_queue(song_data)
            
            -- Show success message
            vim.notify("Added to queue: " .. song_title, vim.log.levels.SUCCESS, {})
            
            -- Update any open queue buffers
            M.update_open_queue_buffers()
            
            -- If nothing is currently playing, start playing this song
            if not queue.is_playing() then
              vim.defer_fn(function()
                playback.play(song_data.video_id, song_data.title)
              end, 100)
            end
          end, 100)
        else
          vim.notify("❌ No selection found", vim.log.levels.ERROR)
        end
      end

      map("i", "<CR>", run_selection)
      map("n", "<CR>", run_selection)
      map("i", "<S-CR>", add_to_queue)
      map("n", "<S-CR>", add_to_queue)
      -- Alternative mapping for Shift+Enter in case terminal doesn't support it
      map("i", "<C-S-CR>", add_to_queue)
      map("n", "<C-S-CR>", add_to_queue)
      -- Also try Right arrow as alternative
      map("i", "<Right>", add_to_queue)
      map("n", "<Right>", add_to_queue)
      return true
    end,
  }):find()
end

function M.update_open_queue_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match("Riff Queue") then
        -- Find the window for this buffer
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == buf then
            -- Update the display
            require('riff.queue_buffer').update_display(buf)
            break
          end
        end
      end
    end
  end
end

return M


