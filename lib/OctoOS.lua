require("lib.Monitor")
require("lib.Printer")
require("lib.Turtle")

OctoOS = {
  _os = {
    name = "OctoOS",
    version = "0.2.1",
    author = "Octoturge",
    type = nil,
    peripherals = {},
    turtle = nil
  },
  commands = {
    write = function(self, side, ...)
      if self._os["peripherals"][side] == nil or self._os["peripherals"][side].type ~= "monitor" then
        error("Peripheral not found or not a monitor. Side: " .. side)
      end

      self._os["peripherals"][side]:write(...)
    end,
    print = function(self, side, title, lines)
      if self._os["peripherals"][side] == nil or self._os["peripherals"][side].type ~= "printer" then
        error("Peripheral not found or not a printer. Side: " .. side)
      end

      self._os["peripherals"][side]:newPage()
      self._os["peripherals"][side]:setTitle(title)

      for _, line in ipairs(lines) do
        self._os["peripherals"][side]:writeLine(line)
      end

      self._os["peripherals"][side]:print()
    end,
    go = function(self, direction, distance)
      if self._os.type ~= "turtle" then
        error("This is not a turtle.")
      end

      self._os["turtle"]:go(direction, distance)
    end,
  }
}

function OctoOS:new(o)
  o = o or {}

  setmetatable(o, self)
  self.__index = self

  self._os["type"] = turtle and "turtle" or "computer"
  self._os["peripherals"] = {
    top = {},
    bottom = {},
    front = {},
    back = {},
    left = {},
    right = {}
  }

  for side, _ in pairs(self._os["peripherals"]) do
    local t = peripheral.getType(side)

    if t == nil then
      self._os["peripherals"][side] = nil
      goto continue
    end

    if t == "monitor" then
      self._os["peripherals"][side] = Monitor:new(nil, side)
    elseif t == "printer" then
      self._os["peripherals"][side] = Printer:new(nil, side)
    end

    ::continue::
  end

  if self._os.type == "turtle" then
    self._os["turtle"] = Turtle:new(nil)
  end

  return o
end

function OctoOS:start()
  print("OctoOS " .. self._os["version"] .. " loaded.")
  print("Author: " .. self._os["author"])
  print("Type: " .. self._os["type"])
  print()
end

function OctoOS:peripheral(side)
  return self._os["peripherals"][side]
end

function OctoOS:turtle()
  return self._os["turtle"]
end

function OctoOS:run(command, ...)
  local func = self.commands[command]

  if func then
    func(self, ...)
  else
    error("Command not found.")
  end
end

function OctoOS:loop()
  if self._os["type"] == "turtle" then
    self:turtleloop()
  elseif self._os["type"] == "computer" then
    self:computerloop()
  else
    error("Unknown OS type.")
  end
end

function OctoOS:turtleloop()
  if self._os["type"] ~= "turtle" then
    error("This is not a turtle.")
  end

  while true do
    local availableConfigs = self._os["turtle"]:getConfigs()

    print("Select an option:")
    print("0. Create new config")

    for i, config in ipairs(availableConfigs) do
      print(i .. ". Run " .. config)
    end

    print("99. Exit")
    local option = tonumber(io.read())

    if option == 0 then
      print("Creating new config.")
      self._os["turtle"]:newConfig()
    elseif option ~= nil and option <= #availableConfigs then
      self._os["turtle"]:loadConfig(availableConfigs[option])
      self._os["turtle"]:runConfig()
    elseif option == 99 then
      print()
      print("Exiting.")
      print("Thank you for using OctoOS " .. self._os["version"] .. " for " .. self._os["type"] .. ".")
      break
    else
      print("Invalid option.")
      print()
    end
  end
end

function OctoOS:computerloop()
  if self._os["type"] ~= "computer" then
    error("This is not a computer.")
  end

  while true do end
end
