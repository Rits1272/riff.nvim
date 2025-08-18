local log = require('riff.log').log
local process = require('riff.process')
local status = require('riff.status')

local M = {}

local mpv_socket = "/tmp/nvim-mpv.sock"
local mpv_job_id = nil

function M.stop()
  if #process.get_mpv_pids() > 0 then
    process.kill_all_mpv()
  end
  if mpv_job_id then
    vim.fn.jobstop(mpv_job_id)
    mpv_job_id = nil
  end
  status.clear()
end

function M.play(video_id, title)
  M.stop()
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

  status.set_current_song(title)
  
  vim.notify("▶️ Now playing: " .. title, vim.log.levels.INFO)
  log("Started playing: " .. title)
end

return M


