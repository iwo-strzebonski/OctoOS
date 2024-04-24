Turtle = { type = "turtle", _config = {} }

function Turtle:new(o, side)
  side = side or "right"
  o = o or {}

  setmetatable(o, self)
  self.__index = self

  fs.makeDir("turtle")
  fs.makeDir("turtle/config")
  fs.makeDir("turtle/logs")

  self:loadConfigs()

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

  local file = fs.open("turtle/config/" .. name, "w")
  file.write(textutils.serialize(self._config))
  file.close()
end

function Turtle:newConfig()
  self._config = {}
  local newConfigFinished = false

  while newConfigFinished do
    newConfigFinished = self._os["turtle"]:getCommand()
  end
end

function Turtle:runConfig()
  -- TODO: Implement this

  for _, command in ipairs(self._config) do
    if command[1] == "go" then
      self:go(command[2], command[3])
    elseif command[1] == "dig" then
      self:dig(command[2], command[3])
    elseif command[1] == "tunnel" then
      self:tunnel(command[2], command[3])
    elseif command[1] == "home" then
      -- TODO: Implement this
    elseif command[1] == "end" then
      break
    end
  end

  self._config = {}
end

function Turtle:tryParseConfigLine(line)
  lineData = {}

  local allowedCommands = { "go", "dig", "tunnel", "home", "end" }
  local multiargument = { "go", "dig" }
  local zeroargument = { "home", "end" }

  for token in string.gmatch(line, "[^%s]+") do
    table.insert(lineData, token)
  end

  if lineData[1] == nil then
    error("Invalid config line: " .. line .. " (missing command)")
  end

  lineData[1] = string.lower(lineData[1])

  if not zeroargument[lineData[1]] then
    if lineData[2] == nil then
      error("Invalid config line: " .. line .. " (missing value)")
    end

    if tonumber(lineData[2]) == nil and lineData[1] ~= "go" then
      error("Invalid config line: " .. line .. " (value is not a number)")
    end

    if lineData[3] ~= nil and not multiargument[lineData[1]] then
      error("Invalid config line: " .. line .. " (too many arguments)")
    end

    if lineData[1] == "go" then
      local directions = { "forward", "back", "up", "down", "left", "right" }

      if not directions[lineData[1]] then
        error("Invalid config line: " .. line .. " (invalid direction)")
      end
    elseif lineData[1] == "dig" then
      if lineData[3] == nil then
        lineData[3] = 1
      elseif tonumber(lineData[3]) == nil then
        error("Invalid config line: " .. line .. " (size is not a number)")
      end
    end

    lineData[2] = tonumber(lineData[2])
  end

  return lineData
end

function Turtle:getCommand()
  print("Enter a command:")
  local command = io.read()

  local commandData = self:tryParseConfigLine(command)

  if commandData[1] == "end" then
    self:saveConfig()
    return true
  end

  table.insert(self._config, commandData)

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
    for i = 1, distance do
      turtle.up()
    end

    return
  elseif direction == "down" then
    for i = 1, distance do
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

  if not allowedDirections[direction] then
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
  for _ = 1, distance do
    self:dig()

    local r = 1

    while r <= size do
      self:go("right")
      self:dig()

      self:dig("down", 2 * r - 1)

      self:go("back")
      self:dig(nil, 2 * r)

      self:dig("up", 2 * r - 1)

      self:go("back")
      self:dig(nil, 2 * r)

      r = r + 1
    end

    self:go("back", size)
    self:go("down", size)
    self:go("right")
  end
end
