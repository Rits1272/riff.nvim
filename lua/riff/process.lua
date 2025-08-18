local log = require('riff.log').log

local M = {}

function M.get_mpv_pids()
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

function M.kill_all_mpv()
  local pids = M.get_mpv_pids()
  if #pids > 0 then
    for _, pid in ipairs(pids) do
      local kill_cmd = "kill -9 " .. pid
      vim.fn.system(kill_cmd)
      log("Killed mpv process with PID: " .. pid)
    end
    return true
  end
  return false
end

return M


