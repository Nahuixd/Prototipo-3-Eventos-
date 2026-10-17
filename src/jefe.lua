local Class = require("lib.hump").class
local eventos = require("lib.eventos")

local Jefe = Class{}

local function wait(segundos)
    local tiempo = 0
    while tiempo < segundos do
        local dt = coroutine.yield()
        tiempo = tiempo + dt
    end
end

function Jefe:init(x, y)
    self.x, self.y = x, y
    self.ancho, self.alto = 64, 64
    self.hp = 100
    self.hp_maximo = 100
    self.estado = "Apareciendo..."
    self.activo = true

    self.rutina = coroutine.create(function()
        wait(2)
        while self.hp > 0 do
            if self.hp > 50 then
                self.estado = "Cargando rayo..."
                wait(1.5)
                self.estado = "¡Pew pew pew!"
                wait(0.5)
                self.estado = "Vulnerable"
                wait(2.0)
            else
                self.estado = "¡Fase 2! Saltando..."
                self.y = self.y - 100
                wait(0.5)
                self.estado = "Aterrizando..."
                self.y = self.y + 100
                wait(0.2)
                self.estado = "Recuperando aliento"
                wait(1.5)
            end
        end
        self.estado = "Derrotado"
        self.activo = false
        eventos.emitir("jefe_derrotado", {})
    end)
end

function Jefe:update(dt)
    if self.activo and coroutine.status(self.rutina) ~= "dead" then
        coroutine.resume(self.rutina, dt)
    end
end

function Jefe:recibirDano(cantidad)
    if not self.activo then return end
    self.hp = math.max(0, self.hp - cantidad)
    eventos.emitir("jefe_recibe_dano", { hp = self.hp, hp_max = self.hp_maximo })
end

function Jefe:draw()
    if self.hp > 50 then love.graphics.setColor(0.2, 0.5, 0.8)
    elseif self.hp > 0 then love.graphics.setColor(0.8, 0.2, 0.2)
    else love.graphics.setColor(0.3, 0.3, 0.3) end
    
    love.graphics.rectangle("fill", self.x, self.y, self.ancho, self.alto)
    
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x, self.y - 20, (self.hp / self.hp_maximo) * self.ancho, 5)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.estado, self.x - 20, self.y - 40)
end

return Jefe