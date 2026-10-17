local Class = require("lib.hump").class
local eventos = require("lib.eventos")

local Jugador = Class{}

function Jugador:init(x, y)
    self.x, self.y = x, y
    self.ancho, self.alto = 32, 48
    self.velocidad = 200
    self.vida, self.vida_max = 3, 3
    self.derrotados = 0
    self.objetivo = 5
    self.invulnerable = 0
    self.sprite = nil
end

function Jugador:update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("a", "left")  then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end
    if love.keyboard.isDown("w", "up")    then dy = dy - 1 end
    if love.keyboard.isDown("s", "down")  then dy = dy + 1 end

    if dx ~= 0 and dy ~= 0 then
        local inv = 1 / math.sqrt(2)
        dx, dy = dx * inv, dy * inv
    end
    self.x = self.x + dx * self.velocidad * dt
    self.y = self.y + dy * self.velocidad * dt

    self.x = math.max(self.ancho/2, math.min(love.graphics.getWidth() - self.ancho/2, self.x))
    self.y = math.max(self.alto/2, math.min(love.graphics.getHeight() - self.alto/2, self.y))

    if self.invulnerable > 0 then self.invulnerable = self.invulnerable - dt end
end

function Jugador:recibirDano(cantidad)
    if self.invulnerable > 0 then return end
    self.vida = self.vida - cantidad
    self.invulnerable = 1.0
    eventos.emitir("vida_cambiada", { vidas = self.vida })
    if self.vida <= 0 then eventos.emitir("jugador_muerto", {}) end
end

function Jugador:atacar(enemigos, jefe)
    local rango = 80
    for i = #enemigos, 1, -1 do
        local e = enemigos[i]
        if math.abs(e.x - self.x) < rango and math.abs(e.y - self.y) < rango then
            e:recibirDano(1)
            if not e.activo then
                table.remove(enemigos, i)
                self.derrotados = self.derrotados + 1
                eventos.emitir("puntos_cambiados", { puntos = self.derrotados, objetivo = self.objetivo })
            end
        end
    end

    if jefe and jefe.activo then
        if math.abs(jefe.x - self.x) < rango + 32 and math.abs(jefe.y - self.y) < rango + 32 then
            jefe:recibirDano(5)
        end
    end
end

function Jugador:draw()
    if self.invulnerable > 0 and math.floor(self.invulnerable * 10) % 2 == 0 then return end
    if self.sprite then
        love.graphics.draw(self.sprite, self.x, self.y, 0, 1, 1, self.ancho/2, self.alto/2)
    else
        love.graphics.setColor(0.2, 0.8, 1.0)
        love.graphics.rectangle("fill", self.x - self.ancho/2, self.y - self.alto/2, self.ancho, self.alto)
        love.graphics.setColor(1, 1, 1)
    end
end

return Jugador