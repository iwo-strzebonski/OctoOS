Printer = { type = "printer", printer = nil, x = 1, y = 1 }

function Printer:new(o, side)
  side = side or "right"
  o = o or {}

  setmetatable(o, self)
  self.__index = self

  self.printer = peripheral.wrap(side)

  return o
end

function Printer:setTitle(t)
  self.printer.setPageTitle(t)
end

function Printer:writeLine(s, x, y)
  x = x or self.x
  y = y or self.y

  self.printer.setCursorPos(x, y)
  self.printer.write(s)

  self.y = y + 1
end

function Printer:newPage()
  if not self.printer.newPage() then
    error("Cannot start a new page. Do you have ink and paper?")
  end
end

function Printer:print()
  if not self.printer.endPage() then
    error("Cannot end the page. Is there enough space?")
  end
end
