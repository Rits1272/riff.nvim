local M = {}

local function urlencode(str)
  str = str:gsub("([^%w ])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
  return str:gsub(" ", "+")
end

local function http_get(url)
  local out = vim.fn.system({ 'curl', '-sL', url })
  if out == nil or out == '' then
    return nil, 'empty response'
  end
  return out, 200
end

function M.search_youtube(keyword, max_results)
  max_results = max_results or 10
  local url = "https://www.youtube.com/results?search_query=" .. urlencode(keyword)
  local body, code = http_get(url)

  if code ~= 200 then
    return nil, "HTTP error: " .. tostring(code)
  end

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

return M
