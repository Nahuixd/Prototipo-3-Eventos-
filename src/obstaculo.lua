local Obstaculo = {}

function Obstaculo:init(x, y, ancho, alto, color)
    self.x, self.y = x, y
    self.ancho, self.alto = ancho, alto
    self.color = color or {0.4, 0.4, 0.4} -- Gris por defecto
end

function Obstaculo:draw()
    -- Sombra
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", self.x + 5, self.y + 5, self.ancho, self.alto)
    -- Cuerpo del obstáculo
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.ancho, self.alto)
    -- Borde para que se vea bonito
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("line", self.x, self.y, self.ancho, self.alto)
end

return function(x, y, ancho, alto, color)
    local instancia = setmetatable({}, { __index = Obstaculo })
    instancia:init(x, y, ancho, alto, color)
    return instancia
end