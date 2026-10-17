local Item = {}

function Item:init(x, y)
    self.x, self.y = x, y
    self.ancho, self.alto = 20, 20
    self.activo = true
    self.tiempo = 0
end

function Item:update(dt)
    self.tiempo = self.tiempo + dt * 5
end

function Item:draw()
    if not self.activo then return end
    -- Un cuadradito rojo con una cruz blanca (simulando un botiquín)
    local flote = math.sin(self.tiempo) * 5
    love.graphics.setColor(0.8, 0.1, 0.1)
    love.graphics.rectangle("fill", self.x - 10, self.y - 10 + flote, 20, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x - 2, self.y - 6 + flote, 4, 12)
    love.graphics.rectangle("fill", self.x - 6, self.y - 2 + flote, 12, 4)
end

return function(x, y)
    local instancia = setmetatable({}, { __index = Item })
    instancia:init(x, y)
    return instancia
end