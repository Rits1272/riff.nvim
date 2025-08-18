local log = require('riff.log').log
local fetch = require('riff.fetch')

local M = {}

function M.search_ytmusic(query, callback)
  local ok, results_or_err = pcall(fetch.search_youtube, query, 10)
  if ok and type(results_or_err) == 'table' then
    callback(results_or_err)
  else
    log({ search_error = results_or_err })
    callback({})
  end
end

return M


