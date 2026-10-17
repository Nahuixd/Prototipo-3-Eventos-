local eventos = require("lib.eventos")
local niveles = require("src.niveles")
local UI = require("src.ui")
local Jefe = require("src.jefe")
local Jugador = require("src.jugador")
local Zombie = require("src.zombie")
local Item = require("src.item") -- IMPORTAMOS EL NUEVO MÓDULO

local function cargarImagen(ruta, r, g, b, w, h)
    if love.filesystem.getInfo(ruta) then return love.graphics.newImage(ruta) end
    w, h = w or 32, h or 32
    local canvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    return canvas
end

local function cargarSonido(ruta, tipo)
    tipo = tipo or "static"
    if love.filesystem.getInfo(ruta) then
        local ok, source = pcall(love.audio.newSource, ruta, tipo)
        if ok then return source end
    end
    return nil
end

local imgJugador = cargarImagen("assets/jugador.png", 0.2, 0.8, 1.0, 32, 48)
local imgZombie  = cargarImagen("assets/zombie.png", 0.2, 0.8, 0.2, 32, 48)

local sfxDisparo = cargarSonido("Explosion.wav") 
local sfxEspada  = cargarSonido("espada.wav")
local sfxVictoria = cargarSonido("Efecto de sonido de trompetas HD.wav")
local sfxDerrota = cargarSonido("Explosion.wav") 

local juego = {
    ui = UI(),
    jugador = nil,
    enemigos = {},
    items = {},
    jefe = nil,
    nivelActual = 1
}

eventos.suscribirse("jefe_invoca_zombie", function(datos)
    if juego.jugador then
        local z = Zombie(datos.x, datos.y, { velocidad = 40, sprite = imgZombie })
        table.insert(juego.enemigos, z)
    end
end)

function juego:iniciarNivel(num)
    self.nivelActual = num
    local config = niveles[num]
    
    self.jugador = Jugador(love.graphics.getWidth()/2, love.graphics.getHeight() - 100)
    self.jugador.objetivo = config.objetivo
    self.jugador.vida = config.vidaJugador
    self.jugador.vida_max = config.vidaJugador
    self.jugador.sprite = imgJugador
    
    self.enemigos = {}
    self.items = {}
    
    self.spawnTimer = 0
    self.spawnInterval = 1 
    self.extraEnemiesSpawned = 0
    self.maxExtra = config.maxExtra
    self.velEnemigo = config.velEnemigo
    
    if config.jefe then
        self.jefe = Jefe(love.graphics.getWidth()/2 - 50, 50, imgZombie)
        self.jugador.objetivo = 0
    else
        self.jefe = nil
        for i = 1, 5 do self:crearEnemigo() end
    end
    
    -- Hacemos aparecer 3 botiquines random al empezar
    for i = 1, 3 do self:crearItem() end
    
    eventos.emitir("puntos_cambiados", { puntos = 0, objetivo = self.jugador.objetivo })
    eventos.emitir("vida_cambiada", { vidas = self.jugador.vida })
end

function juego:reiniciar()
    eventos.limpiar()
    self.jugador = nil
    self.enemigos = {}
    self.items = {}
    self.jefe = nil
    self.ui.pantalla = "menu"
end

function juego:crearEnemigo(x, y)
    x = x or math.random(50, love.graphics.getWidth() - 50)
    y = y or math.random(50, love.graphics.getHeight() - 200)
    local z = Zombie(x, y, { velocidad = self.velEnemigo, sprite = imgZombie })
    table.insert(self.enemigos, z)
end

-- NUEVO: Función para crear botiquines
function juego:crearItem()
    local x = math.random(50, love.graphics.getWidth() - 50)
    local y = math.random(50, love.graphics.getHeight() - 100)
    table.insert(self.items, Item(x, y))
end

function juego:update(dt)
    self.ui:update(dt)
    if self.ui.pantalla ~= "juego" then return end
    
    if self.jugador then self.jugador:update(dt) end
    
    -- Colisiones de balas
    if self.jugador then
        for i = #self.jugador.balas, 1, -1 do
            local b = self.jugador.balas[i]
            local bala_borrada = false
            for j = #self.enemigos, 1, -1 do
                local e = self.enemigos[j]
                local dist = math.sqrt((e.x - b.x)^2 + (e.y - b.y)^2)
                if dist < 20 + b.radio then
                    table.remove(self.enemigos, j)
                    table.remove(self.jugador.balas, i)
                    self.jugador.derrotados = self.jugador.derrotados + 1
                    eventos.emitir("puntos_cambiados", { puntos = self.jugador.derrotados, objetivo = self.jugador.objetivo })
                    if sfxDisparo then sfxDisparo:clone():play() end
                    bala_borrada = true
                    break
                end
            end
            if not bala_borrada and self.jefe and self.jefe.activo then
                local dist = math.sqrt((self.jefe.x + 50 - b.x)^2 + (self.jefe.y + 50 - b.y)^2)
                if dist < 50 + b.radio then
                    self.jefe:recibirDano(5)
                    table.remove(self.jugador.balas, i)
                    if sfxDisparo then sfxDisparo:clone():play() end
                end
            end
        end
    end
    
    -- Actualizar Enemigos
    for i = #self.enemigos, 1, -1 do
        local e = self.enemigos[i]
        e:update(dt, self.jugador)
        if self.jugador and e.activo then
            local dist = math.sqrt((e.x - self.jugador.x)^2 + (e.y - self.jugador.y)^2)
            if dist < (e.ancho/2 + self.jugador.ancho/2) then
                self.jugador:recibirDano(1)
                table.remove(self.enemigos, i)
            end
        end
    end
    
    -- Actualizar Items (y recoger)
    for i = #self.items, 1, -1 do
        local it = self.items[i]
        it:update(dt)
        if self.jugador then
            local dist = math.sqrt((it.x - self.jugador.x)^2 + (it.y - self.jugador.y)^2)
            if dist < 30 then
                -- Recoger vida
                self.jugador.vida = math.min(self.jugador.vida + 1, self.jugador.vida_max)
                eventos.emitir("vida_cambiada", { vidas = self.jugador.vida })
                table.remove(self.items, i)
            end
        end
    end
    
    -- Actualizar Jefe
    if self.jefe then 
        self.jefe:update(dt, self.jugador) 
        if self.jefe.activo and self.jugador then
            local dist = math.sqrt((self.jefe.x + 50 - self.jugador.x)^2 + (self.jefe.y + 50 - self.jugador.y)^2)
            if dist < 50 then
                self.jugador:recibirDano(2) 
            end
        end
    end
    
    -- Spawner
    if self.nivelActual < 5 then
        if self.extraEnemiesSpawned < self.maxExtra then
            self.spawnTimer = self.spawnTimer + dt
            if self.spawnTimer >= self.spawnInterval then
                self.spawnTimer = 0
                self:crearEnemigo()
                self.extraEnemiesSpawned = self.extraEnemiesSpawned + 1
                
                -- 20% de probabilidad de que aparezca un botiquín mientras spawnean zombies
                if math.random() < 0.2 then
                    self:crearItem()
                end
            end
        end
    end
    
    if self.jugador and self.jugador.vida <= 0 then
        self.ui.pantalla = "derrota"
        if sfxDerrota then sfxDerrota:clone():play() end
    end

    if self.nivelActual < 5 and self.jugador and self.jugador.objetivo > 0 and self.jugador.derrotados >= self.jugador.objetivo then
        self.ui.pantalla = "victoria"
        if sfxVictoria then sfxVictoria:clone():play() end
    end
end

function juego:draw()
    love.graphics.clear(0.08, 0.08, 0.12)
    
    if self.ui.pantalla == "juego" then
        for _, it in ipairs(self.items) do it:draw() end
        if self.jugador then self.jugador:draw() end
        for _, e in ipairs(self.enemigos) do e:draw() end
        if self.jefe then self.jefe:draw() end
    end
    
    self.ui:draw()
end

function love.load()
    love.graphics.setBackgroundColor(0.08, 0.08, 0.12)
    love.graphics.setFont(love.graphics.newFont(20))
    love.math.setRandomSeed(os.time())
end

function love.update(dt) juego:update(dt) end
function love.draw() juego:draw() end

function love.keypressed(key)
    if key == "escape" then
        if juego.ui.pantalla == "juego" or juego.ui.pantalla == "derrota" or juego.ui.pantalla == "victoria" then
            juego:reiniciar() 
            return
        end
    end

    if juego.ui.pantalla == "juego" then
        if key == "e" and juego.jugador then
            juego.jugador:dispararFuego()
        end
        if key == "q" and juego.jugador then
            juego.jugador:espadazo(juego.enemigos, juego.jefe)
            if sfxEspada then sfxEspada:clone():play() end
        end
    end
    juego.ui:keypressed(key, juego)
end