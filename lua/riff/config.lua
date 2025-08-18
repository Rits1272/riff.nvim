local M = {}

local defaults = {
  mpv_socket = "/tmp/nvim-mpv.sock",
  ytdlp_cmd = "yt-dlp",
  status_echo_delay_ms = 10,
}

local user = {}

function M.setup(opts)
  if type(opts) ~= "table" then
    opts = {}
  end
  user = vim.tbl_deep_extend("force", defaults, opts)
end

function M.get()
  if next(user) == nil then
    return defaults
  end
  return user
end

return M


