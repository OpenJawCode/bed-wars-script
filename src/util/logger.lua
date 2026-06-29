-- src/util/logger.lua
-- Lightweight logger with level filtering + executor console output.
-- WHY: features need to log without spamming. We centralize so the user can
-- silence everything from one place.
local Logger = {
  level = 3,  -- 1=error, 2=warn, 3=info, 4=debug
  prefix = "[bw-script]",
}

local function fmt(level, msg)
  return string.format("%s [%s] %s", Logger.prefix, level, tostring(msg))
end

function Logger.error(msg)
  if Logger.level >= 1 then
    warn(fmt("ERROR", msg))
  end
end

function Logger.warn(msg)
  if Logger.level >= 2 then
    warn(fmt("WARN", msg))
  end
end

function Logger.info(msg)
  if Logger.level >= 3 then
    print(fmt("INFO", msg))
  end
end

function Logger.debug(msg)
  if Logger.level >= 4 then
    print(fmt("DEBUG", msg))
  end
end

-- Wrap a function in pcall + log on error. Returns the same signature.
-- WHY: every feature loop should be pcall-armored so one bad feature never
-- crashes the whole script. This is the helper.
function Logger.guard(fn, label)
  label = label or "anonymous"
  return function(...)
    local results = table.pack(pcall(fn, ...))
    if not results[1] then
      Logger.error(label .. ": " .. tostring(results[2]))
      return nil
    end
    return table.unpack(results, 2, results.n)
  end
end

return Logger
