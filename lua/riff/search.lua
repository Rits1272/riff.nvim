local log = require('riff.log').log
local config = require('riff.config').get

local M = {}

local function resolve_music_helper_path()
  -- Try to locate the helper via runtimepath (best for published plugins)
  local matches = vim.api.nvim_get_runtime_file('plugins/music.py', false)
  if matches and #matches > 0 then
    return matches[1]
  end
  -- Fallback: derive relative to this module (../../plugins/music.py)
  local here = debug.getinfo(1, 'S').source:match('@?(.*/)') or ''
  return here .. '../../plugins/music.py'
end

function M.search_ytmusic(query, callback)
  local script_path = resolve_music_helper_path()

  vim.fn.jobstart({ config().python_cmd, script_path, query }, {
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
        log({ data = data })
        callback({})
      end
    end,
    on_stderr = function(_, err)
      if err then
        log({ stderr = err })
      end
    end,
  })
end

return M


