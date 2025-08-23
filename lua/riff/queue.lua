local M = {}

local queue = {}
local current_index = 0
local is_playing = false

-- Queue persistence file path
local queue_file = vim.fn.stdpath("data") .. "/riff_queue.json"

local function create_queue_item(song_data)
  return {
    title = song_data.title,
    artist = song_data.artist,
    video_id = song_data.video_id,
    duration = song_data.duration,
    added_at = os.time()
  }
end

function M.add_to_queue(song_data)
  local item = create_queue_item(song_data)
  table.insert(queue, item)
  vim.notify("➕ Added to queue: " .. item.title, vim.log.levels.INFO)
  M.save_queue() -- Auto-save
  return #queue
end

function M.remove_from_queue(index)
  if index < 1 or index > #queue then
    return false, "Invalid index"
  end
  
  local removed = table.remove(queue, index)
  if removed then
    vim.notify("➖ Removed from queue: " .. removed.title, vim.log.levels.INFO)
    if current_index >= index then
      current_index = math.max(0, current_index - 1)
    end
    M.save_queue() -- Auto-save
    return true
  end
  return false, "Failed to remove"
end

function M.get_next()
  if #queue == 0 then
    return nil
  end
  
  current_index = current_index + 1
  if current_index > #queue then
    current_index = 1  -- Loop back to first
  end
  
  return queue[current_index]
end

-- Get next song without changing current index
function M.peek_next()
  if #queue == 0 then
    return nil
  end
  
  local next_index = current_index + 1
  if next_index > #queue then
    next_index = 1  -- Loop back to first
  end
  
  return queue[next_index], next_index
end

function M.get_current()
  if current_index < 1 or current_index > #queue then
    return nil
  end
  return queue[current_index]
end

function M.get_status()
  return {
    total = #queue,
    current = current_index,
    is_playing = is_playing,
    has_next = #queue > 0
  }
end

function M.clear()
  local count = #queue
  queue = {}
  current_index = 0
  is_playing = false
  vim.notify("🗑️ Cleared queue (" .. count .. " songs)", vim.log.levels.INFO)
  M.save_queue() -- Auto-save
end

function M.set_playing(playing)
  is_playing = playing
end

-- Check if queue is currently playing
function M.is_playing()
  return is_playing
end

function M.get_all()
  return queue
end



function M.shuffle()
  for i = #queue, 2, -1 do
    local j = math.random(i)
    queue[i], queue[j] = queue[j], queue[i]
  end
  vim.notify("🔀 Queue shuffled", vim.log.levels.INFO)
  M.save_queue() -- Auto-save
end

-- Save queue to file
function M.save_queue()
  local data = {
    queue = queue,
    current_index = current_index
  }
  
  local json = vim.fn.json_encode(data)
  local file = io.open(queue_file, "w")
  if file then
    file:write(json)
    file:close()
  end
  
  -- Update any open queue buffers
  M.update_open_queue_buffers()
end

-- Load queue from file
function M.load_queue()
  local file = io.open(queue_file, "r")
  if file then
    local content = file:read("*all")
    file:close()
    
    local ok, data = pcall(vim.fn.json_decode, content)
    if ok and data then
      queue = data.queue or {}
      current_index = data.current_index or 0
      
      -- Validate queue items
      for i, item in ipairs(queue) do
        if not item.video_id or not item.title then
          -- Remove invalid items
          table.remove(queue, i)
          if current_index >= i then
            current_index = math.max(0, current_index - 1)
          end
        end
      end
      
      return true
    end
  end
  return false
end

-- Initialize queue (load from file if exists)
function M.init()
  M.load_queue()
end

-- Get queue file path
function M.get_queue_file_path()
  return queue_file
end

-- Show queue file info
function M.show_queue_info()
  local path = M.get_queue_file_path()
  local exists = vim.fn.filereadable(path) == 1
  local size = 0
  
  if exists then
    local file = io.open(path, "r")
    if file then
      file:seek("end")
      size = file:tell()
      file:close()
    end
  end
  
  vim.notify(string.format("📁 Queue file: %s\n📊 Status: %s\n💾 Size: %d bytes", 
    path, exists and "Found" or "Not found", size), vim.log.levels.INFO)
end

-- Update any open queue buffers
function M.update_open_queue_buffers()
  -- Check if any queue buffers are open and update them
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
