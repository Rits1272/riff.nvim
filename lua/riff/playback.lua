local log = require('riff.log').log
local process = require('riff.process')
local status = require('riff.status')
local queue = require('riff.queue')
local config = require('riff.config').get

local M = {}

local function mpv_socket()
  return config().mpv_socket
end

local mpv_job_id = nil

function M.stop()
  if #process.get_mpv_pids() > 0 then
    process.kill_all_mpv()
  end
  if mpv_job_id then
    vim.fn.jobstop(mpv_job_id)
    mpv_job_id = nil
  end

  queue.set_playing(false)
  status.clear()
end

function M.play(video_id, title)
  M.stop()
  queue.set_playing(true)

  local stream_url = vim.fn.system(
    "yt-dlp -q -f bestaudio --no-playlist --get-url 'https://youtube.com/watch?v=" .. video_id .. "'"
  ):gsub("\n","")

  log(stream_url)

  if stream_url == "" or stream_url:match("ERROR") then
    vim.notify("Failed to fetch stream URL for " .. title, vim.log.levels.ERROR)
    return
  end

  if mpv_job_id then
    vim.fn.jobstop(mpv_job_id)
    mpv_job_id = nil
  end

  -- Build MPV command
  local mpv_cmd = {
    "mpv",
    "--no-video",
    "--ytdl=no",
    "--input-ipc-server=" .. mpv_socket(),
    stream_url
  }

  mpv_job_id = vim.fn.jobstart(mpv_cmd, { detach = true, pty = false })

  status.set_current_song(title)
  vim.notify("Now playing: " .. title, vim.log.levels.INFO)
  log("Started playing: " .. title .. " " .. stream_url)
end

function M.play_next_from_queue()
  local next_song = queue.peek_next()
  if next_song then
    queue.get_next()
    M.play(next_song.video_id, next_song.title)
  else
    queue.set_playing(false)
    status.clear()
    vim.notify("Queue finished", vim.log.levels.INFO)
  end
end

return M

