local queue = require('riff.queue')
local playback = require('riff.playback')
local log = require('riff.log').log

local M = {}

function M.show()
  local existing_buf = nil
  local existing_win = nil

  -- Find existing buffer / window
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name == "Riff Queue" then
        existing_buf = buf
        for _, w in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(w) == buf then
            existing_win = w
            break
          end
        end
        break
      end
    end
  end

  local buf, win
  if existing_buf and existing_win then
    buf = existing_buf
    win = existing_win
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, {8, 0})
    M.update_display(buf)
    return buf, win
  elseif existing_buf then
    -- Reuse existing buffer, create a new window
    buf = existing_buf
    win = M.create_window_for_buffer(buf)
  else
    -- Create a new buffer and window
    local found_buf = vim.fn.bufnr("Riff Queue")
    if found_buf ~= -1 then
      buf = found_buf
    else
      buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(buf, "Riff Queue")
    end
    win = M.create_window_for_buffer(buf)
  end

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'riff-queue')
  vim.api.nvim_buf_set_option(buf, 'number', false)
  vim.api.nvim_buf_set_option(buf, 'relativenumber', false)
  vim.api.nvim_buf_set_option(buf, 'cursorline', true)
  vim.api.nvim_buf_set_option(buf, 'wrap', true)

  local opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set('n', 'q', '<Cmd>lua require("riff.queue_buffer").close()<CR>', opts)
  vim.keymap.set('n', '<CR>', '<Cmd>lua require("riff.queue_buffer").play_selected()<CR>', opts)
  vim.keymap.set('n', 'd', '<Cmd>lua require("riff.queue_buffer").remove_selected()<CR>', opts)
  vim.keymap.set('n', 'c', '<Cmd>lua require("riff.queue_buffer").clear_queue()<CR>', opts)
  vim.keymap.set('n', 's', '<Cmd>lua require("riff.queue_buffer").shuffle_queue()<CR>', opts)
  vim.keymap.set('n', 'h', '<Cmd>lua require("riff.queue_buffer").show_help()<CR>', opts)

  M.update_display(buf)
  return buf, win
end

function M.create_window_for_buffer(buf)
  local width = math.min(100, vim.o.columns - 6)
  local height = math.min(30, vim.o.lines - 6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded"
  })

  return win
end

function M.close()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_win_close(win, true)
  end
end

function M.update_display(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end

  local lines = {}
  local status = queue.get_status()
  local all_songs = queue.get_all()

  -- Header
  table.insert(lines, "Riff Queue")
  table.insert(lines, string.format("%d songs • Now: %d",
    status.total, status.current + 1))
  table.insert(lines, "Queue is persistent between sessions")
  table.insert(lines, "")
  table.insert(lines, string.rep("-", 80))
  table.insert(lines, "")

  if #all_songs == 0 then
    table.insert(lines, "Queue is empty")
    table.insert(lines, "")
    table.insert(lines, "Use `:Riff <query>` to search")
    table.insert(lines, "Shift+Enter adds songs to queue")
  else
    for i, song in ipairs(all_songs) do
      local prefix = "   "
      local status_icon = ""

      if i + 1 == status.current then
        prefix = ">"
        status_icon = " [NOW PLAYING]"
      elseif i + 2 == status.current + 1 then
        prefix = ">>"
        status_icon = " [NEXT]"
      end

      local title = song.title
      if #title > 50 then
        title = title:sub(1, 47) .. "..."
      end

      local artist = song.artist or "Unknown"
      if #artist > 25 then
        artist = artist:sub(1, 22) .. "..."
      end

      local line = string.format("%s %d. %s — %s [%s]%s",
        prefix, i, title, artist, song.duration, status_icon)
      table.insert(lines, line)
    end
  end

  table.insert(lines, "")
  table.insert(lines, "Controls:")
  table.insert(lines, "   Enter Play • d Remove • c Clear • s Shuffle")
  table.insert(lines, "   h/? Help • q/<Esc> Close")

  M.set_buffer_lines(buf, lines)

  if status.current > 0 then
    local cursor_line = 7 + status.current
    if cursor_line <= #lines then
      vim.api.nvim_win_set_cursor(0, {cursor_line, 0})
    end
  end
end

function M.play_selected()
  local buf = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1]

  local all_songs = queue.get_all()
  local song_index = nil

  -- Header is 6 lines, divider is 1 line, so songs start at line 8
  local song_line_start = 7
  for i, _ in ipairs(all_songs) do
    if line == (song_line_start + i - 1) then
      song_index = i
      break
    end
  end

  if song_index then
    queue.set_playing(true)
    vim.api.nvim_win_close(0, true)
    local song = all_songs[song_index]
    log({ song_msg = song})
    playback.play(song.video_id, song.title)
  else
    vim.notify("No song selected", vim.log.levels.WARN)
  end
end

function M.remove_selected()
  local buf = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1]

  local all_songs = queue.get_all()
  local song_index = nil

  local song_line_start = 8
  for i, song in ipairs(all_songs) do
    if line == (song_line_start + i - 1) then
      song_index = i
      break
    end
  end

  if song_index then
    local song = all_songs[song_index]
    queue.remove_from_queue(song_index)
    vim.notify("Removed: " .. song.title, vim.log.levels.INFO)
    M.update_display(buf)
  else
    vim.notify("No song selected", vim.log.levels.WARN)
  end
end

function M.clear_queue()
  queue.clear()
  local buf = vim.api.nvim_get_current_buf()
  vim.notify("Queue cleared", vim.log.levels.INFO)
  M.update_display(buf)
end

function M.shuffle_queue()
  queue.shuffle()
  local buf = vim.api.nvim_get_current_buf()
  vim.notify("Queue shuffled", vim.log.levels.INFO)
  M.update_display(buf)
end

function M.set_buffer_lines(buf, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

function M.show_help()
  local help_text = {
    "Riff Queue Help",
    "",
    "Controls:",
    "   Enter - Play selected song",
    "   d - Remove song",
    "   c - Clear queue",
    "   s - Shuffle queue",
    "   h - Show this help",
    "   q - Close window",
    "",
    "Tips:",
    "   • Songs auto-play in order",
    "   • Queue persists across sessions",
    "   • Use :Riff <query> to add songs",
    "   • Shift+Enter adds songs to queue"
  }
  vim.notify(table.concat(help_text, "\n"), vim.log.levels.INFO)
end

return M

