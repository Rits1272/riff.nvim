local log = require('riff.log').log

local M = {}

-- URL encode a string
local function urlencode(str)
  str = str:gsub("([^%w ])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
  return str:gsub(" ", "+")
end

-- Simple GET using curl
local function http_get(url)
  local out = vim.fn.system({ 'curl', '-sL', url })
  if out == nil or out == '' then
    return nil, 'empty response'
  end
  return out, 200
end

-- Simple POST using curl
local function http_post(url, payload)
  local data = vim.fn.json_encode(payload)
  local out = vim.fn.system({
    'curl', '-sL', url,
    '-H', 'Content-Type: application/json',
    '-X', 'POST',
    '-d', data
  })

  if out == nil or out == '' then
    return nil, 'empty response'
  end
  return out, 200
end

-- Search YouTube (parse HTML JSON blob)
function M.search_youtube(keyword, max_results)
  max_results = max_results or 10
  local url = "https://www.youtube.com/results?search_query=" .. urlencode(keyword)
  local body, code = http_get(url)

  if code ~= 200 then
    return nil, "HTTP error: " .. tostring(code)
  end

  -- Extract ytInitialData JSON
  local json_data = body:match("ytInitialData%s*=%s*(.-);</script>")
  if not json_data then
    return nil, "Failed to extract ytInitialData"
  end

  local ok, data = pcall(vim.fn.json_decode, json_data)
  if not ok or not data then
    return nil, "JSON decode error"
  end

  local contents = data.contents
    and data.contents.twoColumnSearchResultsRenderer
    and data.contents.twoColumnSearchResultsRenderer.primaryContents
    and data.contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer
    and data.contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[1]
    and data.contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[1].itemSectionRenderer
    and data.contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[1].itemSectionRenderer.contents

  if not contents then
    return nil, "Could not find search results"
  end

  local results = {}
  for _, item in ipairs(contents) do
    if item.videoRenderer then
      local video = item.videoRenderer
      local title = video.title.runs[1].text
      local videoId = video.videoId
      local duration = video.lengthText and video.lengthText.simpleText or "LIVE/Unknown"
      local artist = video.ownerText and video.ownerText.runs[1].text or "Unknown"

      table.insert(results, {
        title = title,
        video_id = videoId,
        duration = duration,
        artist = artist
      })

      if #results >= max_results then
        break
      end
    end
  end

  return results
end

-- Get autoplay video ID from watch page
function M.get_autoplay_video_id(video_id)
  local url = "https://www.youtube.com/youtubei/v1/next?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"

  local body = {
    context = {
      client = {
        clientName = "WEB",
        clientVersion = "2.20240821.06.00",
      },
    },
    videoId = video_id,
  }

  local res, status = http_post(url, body)

  if status ~= 200 then
    return nil, "HTTP error: " .. tostring(status)
  end

  local ok, data = pcall(vim.fn.json_decode, res)
  if not ok or not data then
    return nil, "JSON decode error"
  end

  local autoplay = data
    and data.contents
    and data.contents.twoColumnWatchNextResults
    and data.contents.twoColumnWatchNextResults.autoplay
    and data.contents.twoColumnWatchNextResults.autoplay.autoplay
    and data.contents.twoColumnWatchNextResults.autoplay.autoplay.sets
    and data.contents.twoColumnWatchNextResults.autoplay.autoplay.sets[1]

  if not autoplay or not autoplay.autoplayVideo then
    return nil, "No autoplay video found"
  end

  return autoplay.autoplayVideo.watchEndpoint.videoId
end

function M.get_video_metadata(video_id)
  local cmd = string.format(
    "yt-dlp -J --no-warnings 'https://www.youtube.com/watch?v=%s'",
    video_id
  )
  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 or out == nil or out == "" then
    return nil, "yt-dlp failed"
  end

  local ok, data = pcall(vim.fn.json_decode, out)
  if not ok then
    return nil, "failed to parse yt-dlp output"
  end

  return {
    video_id = data.id,
    title = data.title,
    artist = data.artist or data.uploader,
    duration = data.duration_string,
  }
end
 
function M.autoplay_next_song(video_id)
  local next_video_id = M.get_autoplay_video_id(video_id)
  return M.get_video_metadata(next_video_id)
end

return M

