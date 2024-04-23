Monitor = { type = "monitor", monitor = nil, side = nil }

function Monitor:new(o, side)
  side = side or "right"
  o = o or {}

  setmetatable(o, self)
  self.__index = self

  self.side = side

  self.monitor = peripheral.wrap(side)
  self.monitor.setBackgroundColor(colors.black)
  self.monitor.clear()
  self.monitor.setCursorPos(1, 1)

  return o
end

function Monitor:get()
  return self.monitor
end

function Monitor:clear()
  self.monitor.clear()
end

function Monitor:drawPixel(x, y, c)
  self.monitor.setCursorPos(x, y)
  self.monitor.setBackgroundColor(c)
  self.monitor.write(" ")
end

function Monitor:drawLine(x, y, l, c)
  for i = 0, l - 1 do
    self:drawPixel(x + i, y, c)
  end
end

function Monitor:write(s)
  self.monitor.write(s)
end
