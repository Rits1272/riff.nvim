local M = {}

function M.log(msg)
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

return M


