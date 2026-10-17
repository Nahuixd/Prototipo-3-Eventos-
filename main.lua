local eventos = require("lib.eventos")
local niveles = require("src.niveles")
local UI = require("src.ui")
local Jefe = require("src.jefe")
local Jugador = require("src.jugador")
local Zombie = require("src.zombie")

local juego = {
    ui = UI(), -- Ahora UI() ES una función, va a andar perfecto
    jugador = nil,
    enemigos = {},
    jefe = nil,
    nivelActual = 1
}

function juego:iniciarNivel(num)
    self.nivelActual = num
    local config = niveles[num]
    self.jugador = Jugador(love.graphics.getWidth()/2, love.graphics.getHeight() - 100)
    self.jugador.objetivo = config.objetivo
    self.jugador.vida = config.vidaJugador
    self.jugador.vida_max = config.vidaJugador
    
    self.enemigos = {}
    self.spawnTimer = 0
    self.spawnInterval = 2
    self.extraEnemiesSpawned = 0
    self.maxExtra = config.maxExtra
    self.velEnemigo = config.velEnemigo
    
    if config.jefe then
        self.jefe = Jefe(400, 100)
        self.jugador.objetivo = 0
    else
        self.jefe = nil
    end
    
    eventos.emitir("puntos_cambiados", { puntos = 0, objetivo = self.jugador.objetivo })
    eventos.emitir("vida_cambiada", { vidas = self.jugador.vida })
end

function juego:reiniciar()
    eventos.limpiar()
    self.jugador = nil
    self.enemigos = {}
    self.jefe = nil
    self.ui.pantalla = "menu"
end

function juego:update(dt)
    self.ui:update(dt)
    if self.ui.pantalla ~= "juego" then return end
    
    if self.jugador then self.jugador:update(dt) end
    
    for i = #self.enemigos, 1, -1 do
        local e = self.enemigos[i]
        e:update(dt, self.jugador)
        if self.jugador and e.activo then
            local hb = e:getHitbox()
            local dx = e.x - self.jugador.x
            local dy = e.y - self.jugador.y
            if math.abs(dx) < (hb.ancho/2 + self.jugador.ancho/2) and math.abs(dy) < (hb.alto/2 + self.jugador.alto/2) then
                self.jugador:recibirDano(1)
                table.remove(self.enemigos, i)
            end
        end
    end
    
    if self.jefe then self.jefe:update(dt) end
    
    if self.extraEnemiesSpawned < self.maxExtra then
        self.spawnTimer = self.spawnTimer + dt
        if self.spawnTimer >= self.spawnInterval then
            self.spawnTimer = 0
            local zombie = Zombie(math.random(50, love.graphics.getWidth() - 50), math.random(50, love.graphics.getHeight() - 200), { velocidad = self.velEnemigo })
            table.insert(self.enemigos, zombie)
            self.extraEnemiesSpawned = self.extraEnemiesSpawned + 1
        end
    end
    
    if self.jugador and self.jugador.objetivo > 0 and self.jugador.derrotados >= self.jugador.objetivo then
        self.ui.pantalla = "victoria"
    end
end

function juego:draw()
    love.graphics.clear(0.1, 0.1, 0.15)
    if self.ui.pantalla == "juego" then
        if self.jugador then self.jugador:draw() end
        for _, e in ipairs(self.enemigos) do e:draw() end
        if self.jefe then self.jefe:draw() end
    end
    self.ui:draw()
end

function love.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
    love.graphics.setFont(love.graphics.newFont(20))
    love.math.setRandomSeed(os.time())
end

function love.update(dt) juego:update(dt) end
function love.draw() juego:draw() end
function love.keypressed(key)
    if juego.ui.pantalla == "juego" then
        if key == "space" and juego.jugador then
            juego.jugador:atacar(juego.enemigos, juego.jefe)
        end
    end
    juego.ui:keypressed(key, juego)
end