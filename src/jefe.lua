local eventos = require("lib.eventos")

local Jefe = {}

function Jefe:init(x, y, sprite)
    self.x, self.y = x, y
    self.ancho, self.alto = 100, 100 -- Más chico
    self.velocidad = 25 
    self.hp = 150 -- Menos vida
    self.hp_maximo = 150
    self.activo = true
    self.tiempo_invocacion = 0
    self.sprite = sprite 
end

function Jefe:update(dt, jugador)
    if not self.activo or not jugador then return end

    local dx = jugador.x - (self.x + self.ancho/2)
    local dy = jugador.y - (self.y + self.alto/2)
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 0 then
        self.x = self.x + (dx / dist) * self.velocidad * dt
        self.y = self.y + (dy / dist) * self.velocidad * dt
    end

    self.tiempo_invocacion = self.tiempo_invocacion + dt
    if self.tiempo_invocacion >= 3 then
        self.tiempo_invocacion = 0
        eventos.emitir("jefe_invoca_zombie", { x = self.x + self.ancho/2, y = self.y + self.alto/2 })
    end
end

function Jefe:recibirDano(cantidad)
    if not self.activo then return end
    self.hp = math.max(0, self.hp - cantidad)
    eventos.emitir("jefe_recibe_dano", { hp = self.hp, hp_max = self.hp_maximo })
    
    if self.hp <= 0 then
        self.activo = false
        eventos.emitir("jefe_derrotado", {})
    end
end

function Jefe:draw()
    if not self.activo then return end

    if self.hp > 75 then love.graphics.setColor(1, 1, 1)
    else love.graphics.setColor(1, 0.5, 0.5) end 

    if self.sprite then
        local sw, sh = self.sprite:getWidth(), self.sprite:getHeight()
        local escala = self.alto / sh
        love.graphics.draw(self.sprite, self.x + self.ancho/2, self.y + self.alto/2, 0, escala * 2, escala * 2, sw/2, sh/2)
    else
        love.graphics.rectangle("fill", self.x, self.y, self.ancho, self.alto)
    end
end

return function(x, y, sprite)
    local instancia = setmetatable({}, { __index = Jefe })
    instancia:init(x, y, sprite)
    return instancia
end