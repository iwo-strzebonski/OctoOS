require("lib.Helpers")

Turtle = { type = "turtle", _config = {}, minfuel = 200 }

function Turtle:new(o, side)
  side = side or "right"
  o = o or {}

  setmetatable(o, self)
  self.__index = self

  fs.makeDir("turtle")
  fs.makeDir("turtle/config")

  return o
end

function Turtle:getConfigs()
  return fs.list("turtle/config")
end

function Turtle:loadConfig(name)
  local file = fs.open("turtle/config/" .. name, "r")
  local config = textutils.unserialize(file.readAll())
  file.close()

  self._config = config

  return config
end

function Turtle:saveConfig(name)
  --- @diagnostic disable-next-line: param-type-mismatch
  name = name or os.time(os.date('!*t'))

  local file = fs.open("turtle/config/" .. name .. ".cfg", "w")
  file.write(textutils.serialize(self._config))
  file.close()
end

function Turtle:newConfig()
  self._config = {}
  local newConfigFinished = false

  while not newConfigFinished do
    newConfigFinished = self:getCommand()
  end
  self:saveConfig()
end

function Turtle:runConfig()
  self:fuel()

  for _, command in ipairs(self._config) do
    if command["command"] == "go" then
      self:go(command["arg1"], command["arg2"])
    elseif command["command"] == "dig" then
      self:dig(command["arg1"], command["arg2"])
    elseif command["command"] == "tunnel" then
      self:tunnel(command["arg1"], command["arg2"])
    elseif command["command"] == "home" then
      -- TODO: Implement this
    elseif command["command"] == "end" then
      break
    end
  end

  print("Finished running config")
  self._config = {}
end

function Turtle:tryParseConfigLine(line)
  local lineData = {}

  local allowedCommands = { "go", "dig", "tunnel", "home", "end" }
  local multiargument = { "go", "dig", "tunnel" }
  local zeroargument = { "home", "end" }

  for token in string.gmatch(line, "[^%s]+") do
    table.insert(lineData, token)
  end

  if lineData[1] == nil then
    error("Invalid config line: " .. line .. " (missing command)")
  end

  if not Helpers.contains(allowedCommands, lineData[1]) then
    error("Invalid config line: " .. line .. " (invalid command)")
  end
  lineData[1] = string.lower(lineData[1])

  if not Helpers.contains(zeroargument, lineData[1]) then
    if lineData[2] == nil then
      error("Invalid config line: " .. line .. " (missing value)")
    end

    if tonumber(lineData[2]) == nil and not Helpers.contains(multiargument, lineData[1]) then
      error("Invalid config line: " .. line .. " (value is not a number)")
    end

    if not Helpers.contains(multiargument, lineData[1]) and lineData[3] ~= nil then
      error("Invalid config line: " .. line .. " (too many arguments)")
    else
      if lineData[3] == nil or tonumber(lineData[3]) == nil or tonumber(lineData[3]) < 0 then
        error("Invalid config line: " .. line .. " (missing value or value is not a number)")
      else
        lineData[3] = tonumber(lineData[3])
      end
    end

    if lineData[1] == "go" then
      local directions = { "forward", "back", "up", "down", "left", "right" }

      if not Helpers.contains(directions, lineData[2]) then
        error("Invalid config line: " .. line .. " (invalid direction)")
      end
    elseif lineData[1] == "dig" then
      local directions = { "forward", "up", "down" }

      if not Helpers.contains(directions, lineData[2]) then
        error("Invalid config line: " .. line .. " (invalid direction)")
      end
    elseif lineData[1] == "tunnel" then
      if tonumber(lineData[2]) == nil or tonumber(lineData[2]) < 0 then
        error("Invalid config line: " .. line .. " (invalid distance)")
      end

      if tonumber(lineData[3]) == nil or tonumber(lineData[3]) < 0 then
        error("Invalid config line: " .. line .. " (invalid size)")
      end

      lineData[2] = tonumber(lineData[2])
    end

    if not Helpers.contains(multiargument, lineData[1]) then
      lineData[2] = tonumber(lineData[2])
    end
  end

  local commandLine = {
    ["command"] = lineData[1],
    ["arg1"] = lineData[2],
    ["arg2"] = lineData[3],
    ["arg3"] = lineData[4]
  }

  return commandLine
end

function Turtle:getCommand()
  print("Enter a command:")
  local command = io.read()

  local commandLine = self:tryParseConfigLine(command)

  if commandLine["command"] == "end" then
    return true
  end

  table.insert(self._config, commandLine)

  return false
end

function Turtle:go(direction, distance)
  distance = distance or 0

  if direction == "forward" then
    goto continue
  elseif direction == "back" then
    turtle.turnLeft()
    turtle.turnLeft()
  elseif direction == "up" then
    for _ = 1, distance do
      turtle.up()
    end

    return
  elseif direction == "down" then
    for _ = 1, distance do
      turtle.down()
    end

    return
  elseif direction == "left" then
    turtle.turnLeft()
  elseif direction == "right" then
    turtle.turnRight()
  else
    error("Invalid direction: " .. direction)
  end

  ::continue::

  for _ = 1, distance do
    assert(turtle.forward())
  end
end

function Turtle:dig(direction, distance)
  direction = direction or "forward"
  distance = distance or 1

  local allowedDirections = { "forward", "up", "down" }

  if not Helpers.contains(allowedDirections, direction) then
    error("Invalid direction: " .. direction)
  end

  distance = distance or 1

  for _ = 1, distance do
    if direction == "forward" then
      turtle.dig()
    elseif direction == "up" then
      turtle.digUp()
    elseif direction == "down" then
      turtle.digDown()
    end

    Turtle:go(direction, 1)
  end
end

function Turtle:tunnel(distance, size)
  print("Tunneling " .. distance .. " blocks with a size of " .. size .. " blocks")
  for _ = 1, distance do
    self:dig()

    local r = 1

    if (size > 1) then
      self:go("right")
    end

    while r < size do
      self:dig()

      self:dig("down", 2 * r - 1)

      self:go("back")
      self:dig(nil, 2 * r)

      self:dig("up", 2 * r)

      self:go("back")
      self:dig(nil, 2 * r)

      r = r + 1
    end

    if (size > 1) then
      self:go("back", size - 1)
      self:go("down", size - 1)
      self:go("right")
    end
  end
end

function Turtle:fuel()
  ok, err = turtle.refuel()

  if not ok and self:fuellevel() <= self.minfuel then
    error(err)
  end
end

function Turtle:fuellevel()
  return turtle.getFuelLevel()
end

function Turtle:log(msg)
  --- @diagnostic disable-next-line: param-type-mismatch
  local file = fs.open("turtle/log", "w")
  file.write(os.time(os.date('!*t')) .. ": " .. msg)
  file.close()
end
