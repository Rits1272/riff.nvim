local playback = require('riff.playback')

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
    prompt_title = "Riff 🎶",
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

      map("i", "<CR>", run_selection)
      map("n", "<CR>", run_selection)
      return true
    end,
  }):find()
end

return M


