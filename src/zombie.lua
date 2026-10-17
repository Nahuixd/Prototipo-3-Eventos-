-- zombie.lua: Enemigo concreto que hereda de Enemigo (SOLID - LSP)
local Enemigo = require("src.enemigo")
local eventos = require("lib.eventos")

local Zombie = Enemigo:extend()

function Zombie:init(x, y, config)
    Enemigo.init(self, x, y, {
        ancho      = 32,
        alto       = 48,
        velocidad  = config.velocidad or 30,
        vida       = 1,
        sprite     = config.sprite,
        origen_x   = 16,
        origen_y   = 24,
    })
    self.tipo = "zombie"
end

function Zombie:update(dt, jugador)
    if not self.activo or not jugador then return end

    -- Movimiento hacia el jugador
    local dx = jugador.x - self.x
    local dy = jugador.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 0 then
        self.x = self.x + (dx / dist) * self.velocidad * dt
        self.y = self.y + (dy / dist) * self.velocidad * dt
    end
end

return Zombie