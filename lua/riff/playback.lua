local log = require('riff.log').log
local process = require('riff.process')
local status = require('riff.status')
local queue = require('riff.queue')
local config = require('riff.config').get
local autoplay_next_song = require('riff.fetch').autoplay_next_song

local M = {}

local function mpv_socket()
  return config().mpv_socket
end

local function mpv_command(cmd)
  local socket = mpv_socket()
  if not socket or socket == "" then
    vim.notify("No mpv socket configured", vim.log.levels.ERROR)
    return
  end

  local payload = vim.fn.json_encode({ command = cmd })
  local full_cmd = string.format("echo '%s' | socat - %s", payload, socket)
  vim.fn.system(full_cmd)
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

function M.pause()
  mpv_command({ "set_property", "pause", true })
end

function M.resume()
  mpv_command({ "set_property", "pause", false })
end

function M.play(video_id, title)
  M.stop()
  queue.set_playing(true)

  local stream_url = vim.fn.system(
    "yt-dlp -q -f bestaudio --no-playlist --get-url 'https://youtube.com/watch?v=" .. video_id .. "'"
  ):gsub("\n","")

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
    local current_song = queue.get_current()

    if not current_song then
      queue.set_playing(false)
      return
    end

    status.clear()
    vim.notify("finding recommended song...")
    next_song = autoplay_next_song(current_song.video_id)
    M.play(next_song.video_id, next_song.title)
    current_song = next_song
  end
end

return M

