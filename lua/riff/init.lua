local mpv_socket = "/tmp/nvim-mpv.sock"
local mpv_job_id = nil
local current_song = nil

-- ===== Logging =====
local function log(msg)
  local file_path = "/tmp/riff_debug.log"
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  if type(msg) ~= "string" then
    msg = vim.inspect(msg)
  end
  local f = io.open(file_path, "a")
  if f then
    f:write(string.format("[%s] %s\n", timestamp, msg))
    f:close()
  else
    vim.notify("❌ Failed to open log file: " .. file_path, vim.log.levels.ERROR)
  end
end

-- Function to check if mpv is running and get PIDs
local function get_mpv_pids()
  local cmd = "ps aux | grep mpv | grep -v grep | awk '{print $2}'"
  local result = vim.fn.system(cmd)
  if result and result ~= "" then
    local pids = {}
    for pid in result:gmatch("%d+") do
      table.insert(pids, tonumber(pid))
    end
    return pids
  end
  return {}
end

-- Function to kill all mpv processes
local function kill_all_mpv()
  local pids = get_mpv_pids()
  if #pids > 0 then
    for _, pid in ipairs(pids) do
      local kill_cmd = "kill -9 " .. pid
      vim.fn.system(kill_cmd)
    end
    return true
  end
  return false
end

-- Check for orphaned mpv processes at startup
local function cleanup_orphaned_mpv()
  if #get_mpv_pids() > 0 then
    kill_all_mpv()
  end
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

-- ===== Search via Python helper =====
local function search_ytmusic(query, callback)
  local script_path = "/Users/ritikjain/projects/riff.nvim/plugins/music.py"
  vim.fn.jobstart({ "python3", script_path, query }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data or #data == 0 then
        callback({})
        return
      end
      local filtered = {}
      for _, line in ipairs(data) do
        if line ~= "" then table.insert(filtered, line) end
      end
      local ok, parsed = pcall(vim.fn.json_decode, table.concat(filtered))
      if ok and parsed then
        callback(parsed)
      else
        vim.notify("❌ Failed to parse JSON from Python helper", vim.log.levels.ERROR)
        log({ data = data })
        callback({})
      end
    end,
    on_stderr = function(_, err)
      if err then
        vim.notify("Python helper error: " .. table.concat(err, "\n"), vim.log.levels.ERROR)
        log({ stderr = err })
      end
    end,
  })
end

-- ===== Status display =====
local function show_song_status()
  if current_song then
    local status_text = "🎵 " .. current_song .. " ▶"
  
    local ok = pcall(function()
      -- Use Normal highlight group which is guaranteed to exist
      vim.api.nvim_echo({{status_text, "Normal"}}, false, {})
    end)
    
    -- Method 2: If that fails, show without highlighting (still visible)
    if not ok then
      vim.api.nvim_echo({{status_text}}, false, {})
    end
  end
end

-- Function to update status display (called when song changes)
local function update_status_line()
  -- Use a timer to show the status briefly without blocking
  vim.defer_fn(show_song_status, 10)
end

local function stop_playback()
  local stopped = false

  current_song = nil
  update_status_line()
  
  if stopped then
    vim.notify("⏹️ Stopped playback", vim.log.levels.INFO)
  else
    vim.notify("⚠️ No song running", vim.log.levels.WARN)
  end
end

-- ===== MPV playback =====
local function play_youtube(video_id, title)
  cleanup_orphaned_mpv()
  local stream_url = vim.fn.system(
    "yt-dlp -q -f bestaudio --no-playlist --get-url 'https://youtube.com/watch?v=" .. video_id .. "'"
  ):gsub("\n","")

  if stream_url == "" then
    vim.notify("❌ Failed to fetch stream URL for " .. title, vim.log.levels.ERROR)
    log("Failed to fetch stream URL for " .. title)
    return
  end

  if mpv_job_id then
    vim.fn.jobstop(mpv_job_id)
    mpv_job_id = nil
  end

  mpv_job_id = vim.fn.jobstart({
    "mpv",
    "--no-video",
    "--input-ipc-server=" .. mpv_socket,
    stream_url
  }, { detach = true, pty = false })

  -- Update current song and status
  current_song = title
  update_status_line()
  
  vim.notify("▶️ Now playing: " .. title, vim.log.levels.INFO)
  log("Started playing: " .. title)
end
-- ===== Telescope picker =====
local function riff_picker(query)
  search_ytmusic(query, function(results)
    if #results == 0 then
      vim.notify("❌ No results found for: " .. query, vim.log.levels.WARN)
      return
    end
    
    -- Debug: log the first result structure
    log("First result structure: " .. vim.inspect(results[1]))

    local display_opts = entry_display.create({
      separator = " ",
      items = { { width = 50 }, { width = 20 } }
    })

    local make_display = function(entry)
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
          local result = {
            value = entry,
            display = function(e) return make_display(e) end,
            ordinal = tostring(entry.title or "Unknown")
          }
          log("Entry maker result: " .. vim.inspect(result))
          return result
        end
      }),
      sorter = conf.generic_sorter({}),
      default_selection_index = 1,
      attach_mappings = function(_, map)
        map("i", "<CR>", function(prompt_bufnr)
          local selection = action_state.get_selected_entry(prompt_bufnr)
          actions.close(prompt_bufnr)
          if selection and selection.value then
            local val = selection.value
            log("Selection value: " .. vim.inspect(val))
            -- Handle both direct value and nested value structures
            if type(val) == "table" and val.video_id and val.title then
              play_youtube(val.video_id, val.title)
            elseif type(val) == "table" and val.value and val.value.video_id and val.value.title then
              play_youtube(val.value.video_id, val.value.title)
            end
          end
        end)
        return true
      end,
    }):find()
  end)
end

-- ===== Commands =====
vim.api.nvim_create_user_command("Riff", function(opts)
  local query = table.concat(opts.fargs, " ")
  riff_picker(query)
end, { nargs = "+" })

vim.api.nvim_create_user_command("RiffStop", stop_playback, {})
vim.api.nvim_create_user_command("RiffStatus", function()
  if current_song then
    vim.notify("🎵 Currently playing: " .. current_song, vim.log.levels.INFO)
  else
    vim.notify("⏸️ No song currently playing", vim.log.levels.INFO)
  end
end, {})



