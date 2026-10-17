local eventos = require("lib.eventos")

local Jugador = {}

function Jugador:init(x, y)
    self.x, self.y = x, y
    self.ancho, self.alto = 32, 48
    self.velocidad = 250
    self.vida, self.vida_max = 3, 3
    self.derrotados = 0
    self.objetivo = 5
    self.invulnerable = 0
    self.sprite = nil
    
    -- Habilidades
    self.balas = {}
    self.cooldown_disparo = 0
    self.cooldown_espada = 0
    self.espada_activa = 0 -- Temporizador para dibujar el espadazo
    self.escala = 1.5 -- Escala del jugador
end

function Jugador:update(dt)
    -- Cooldowns
    if self.cooldown_disparo > 0 then self.cooldown_disparo = self.cooldown_disparo - dt end
    if self.cooldown_espada > 0 then self.cooldown_espada = self.cooldown_espada - dt end
    if self.espada_activa > 0 then self.espada_activa = self.espada_activa - dt end

    -- Movimiento
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

    -- Limitar a la pantalla
    self.x = math.max(self.ancho/2, math.min(love.graphics.getWidth() - self.ancho/2, self.x))
    self.y = math.max(self.alto/2, math.min(love.graphics.getHeight() - self.alto/2, self.y))

    if self.invulnerable > 0 then self.invulnerable = self.invulnerable - dt end

    -- Actualizar balas
    for i = #self.balas, 1, -1 do
        local b = self.balas[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.vida = b.vida - dt
        -- Si sale de pantalla o se acaba el tiempo, se borra
        if b.x < 0 or b.x > love.graphics.getWidth() or b.y < 0 or b.y > love.graphics.getHeight() or b.vida <= 0 then
            table.remove(self.balas, i)
        end
    end
end

-- Habilidad E: Disparar Fuego
function Jugador:dispararFuego()
    if self.cooldown_disparo > 0 then return end
    self.cooldown_disparo = 0.4 -- Medio segundo de espera
    
    local dirX, dirY = 0, -1 -- Por defecto dispara hacia arriba (si no se mueve)
    -- Si se está moviendo, disparamos hacia donde camina
    if love.keyboard.isDown("a", "left") then dirX = -1; dirY = 0 end
    if love.keyboard.isDown("d", "right") then dirX = 1; dirY = 0 end
    if love.keyboard.isDown("w", "up") then dirX = 0; dirY = -1 end
    if love.keyboard.isDown("s", "down") then dirX = 0; dirY = 1 end

    table.insert(self.balas, {
        x = self.x,
        y = self.y,
        vx = dirX * 500, -- Velocidad de la bala
        vy = dirY * 500,
        vida = 1.5,
        radio = 8
    })
end

-- Habilidad Q: Espadazo (Daño en área)
function Jugador:espadazo(enemigos, jefe)
    if self.cooldown_espada > 0 then return end
    self.cooldown_espada = 0.8
    self.espada_activa = 0.2 -- Duración del efecto visual
    
    local rango = 100 -- Rango del espadazo
    for i = #enemigos, 1, -1 do
        local e = enemigos[i]
        local dist = math.sqrt((e.x - self.x)^2 + (e.y - self.y)^2)
        if dist < rango then
            e:recibirDano(1) -- El espadazo hace 1 de daño
            if not e.activo then
                table.remove(enemigos, i)
                self.derrotados = self.derrotados + 1
                eventos.emitir("puntos_cambiados", { puntos = self.derrotados, objetivo = self.objetivo })
            end
        end
    end

    if jefe and jefe.activo then
        local dist = math.sqrt((jefe.x - self.x)^2 + (jefe.y - self.y)^2)
        if dist < rango + 32 then
            jefe:recibirDano(10) -- El espadazo hace más daño al jefe
        end
    end
end

function Jugador:recibirDano(cantidad)
    if self.invulnerable > 0 then return end
    self.vida = self.vida - cantidad
    self.invulnerable = 1.0
    eventos.emitir("vida_cambiada", { vidas = self.vida })
    if self.vida <= 0 then eventos.emitir("jugador_muerto", {}) end
end

function Jugador:draw()
    -- Efecto de invulnerabilidad (parpadeo)
    if self.invulnerable > 0 and math.floor(self.invulnerable * 10) % 2 == 0 then return end

    -- Dibujar Jugador (con escala)
    if self.sprite then
        local sw, sh = self.sprite:getWidth(), self.sprite:getHeight()
        -- Escala para que quepa en el hitbox
        local escala = self.alto / sh 
        love.graphics.draw(self.sprite, self.x, self.y, 0, escala, escala, sw/2, sh/2)
    else
        love.graphics.setColor(0.2, 0.8, 1.0)
        love.graphics.rectangle("fill", self.x - self.ancho/2, self.y - self.alto/2, self.ancho, self.alto)
        love.graphics.setColor(1, 1, 1)
    end

    -- Dibujar Efecto de Espadazo
    if self.espada_activa > 0 then
        love.graphics.setColor(1, 1, 0, self.espada_activa * 5) -- Amarillo transparente
        love.graphics.circle("line", self.x, self.y, 100)
        love.graphics.setColor(1, 1, 1)
    end

    -- Dibujar Balas de Fuego
    for _, b in ipairs(self.balas) do
        love.graphics.setColor(1, 0.4, 0) -- Naranja
        love.graphics.circle("fill", b.x, b.y, b.radio)
        love.graphics.setColor(1, 1, 0) -- Núcleo amarillo
        love.graphics.circle("fill", b.x, b.y, b.radio * 0.5)
    end
    love.graphics.setColor(1, 1, 1)
end

return function(x, y)
    local instancia = setmetatable({}, { __index = Jugador })
    instancia:init(x, y)
    return instancia
end