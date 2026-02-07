local key = KEYS[1]
local delta = tonumber(ARGV[1])
if not delta then
  return redis.error_reply('delta required')
end
return redis.call('INCRBY', key, delta)
