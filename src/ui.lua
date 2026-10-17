local eventos = require("lib.eventos")
local niveles = require("src.niveles")

local function cargarImagenSegura(ruta)
    if love.filesystem.getInfo(ruta) then
        local exito, imagen = pcall(love.graphics.newImage, ruta)
        if exito then return imagen end
    end
    return nil
end

local imgVictoria = cargarImagenSegura("assets/victory.png")
local imgDerrota  = cargarImagenSegura("assets/derrota.png")

local UI = {}

function UI:init()
    self.pantalla = "menu"
    self.menuOpcion = 1 -- 1: Jugar, 2: Instrucciones, 3: Salir
    self.nivelSeleccionado = 1
    self.vidas = 3
    self.puntos = 0
    self.objetivo = 5
    self.hpJefe = 150
    self.hpJefeMax = 150
    self.tiempo = 0

    eventos.suscribirse("vida_cambiada", function(d) self.vidas = d.vidas end)
    eventos.suscribirse("puntos_cambiados", function(d) self.puntos = d.puntos; self.objetivo = d.objetivo end)
    eventos.suscribirse("jefe_recibe_dano", function(d) self.hpJefe = d.hp; self.hpJefeMax = d.hp_max end)
    eventos.suscribirse("jefe_derrotado", function() self.pantalla = "victoria" end)
end

function UI:update(dt) self.tiempo = self.tiempo + dt end

function UI:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    if self.pantalla == "menu" then
        local pulso = 0.8 + 0.2 * math.sin(self.tiempo * 3)
        love.graphics.setColor(1, pulso, 0.2)
        love.graphics.printf("GUERRERO VS ZOMBIES", 0, 100, w, "center")
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Jugar", 0, 250, w, "center")
        love.graphics.printf("Instrucciones", 0, 290, w, "center")
        love.graphics.printf("Salir", 0, 330, w, "center")

        -- Flechita indicadora
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.printf(">", w/2 - 100, 250 + (self.menuOpcion - 1) * 40, w, "center")

    elseif self.pantalla == "instrucciones" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("INSTRUCCIONES", 0, 80, w, "center")
        love.graphics.print("Moverse: W, A, S, D o Flechas", 100, 200)
        love.graphics.print("Espadazo (Q): Ataque en área", 100, 240)
        love.graphics.print("Bola de fuego (E): Disparo a distancia", 100, 280)
        love.graphics.print("Botiquines (Rojo): Recupera 1 vida", 100, 320)
        love.graphics.print("ESC: Volver al menú en cualquier momento", 100, 360)
        love.graphics.printf("Presiona ESC o ENTER para volver", 0, h - 100, w, "center")

    elseif self.pantalla == "seleccion_nivel" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("SELECCIONA UN NIVEL", 0, 80, w, "center")
        for i, n in ipairs(niveles) do
            if i == self.nivelSeleccionado then love.graphics.setColor(1, 0.85, 0.2) else love.graphics.setColor(1, 1, 1) end
            love.graphics.printf(n.nombre, 0, 180 + (i * 40), w, "center")
        end
        
    elseif self.pantalla == "juego" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Vidas: " .. self.vidas, 20, 20)
        love.graphics.print("Derrotados: " .. self.puntos .. "/" .. self.objetivo, 20, 50)
        
        if self.objetivo == 0 then
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", w/2 - 150, 30, 300, 20)
            love.graphics.setColor(0.8, 0.2, 0.2)
            love.graphics.rectangle("fill", w/2 - 150, 30, (self.hpJefe / self.hpJefeMax) * 300, 20)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", w/2 - 150, 30, 300, 20)
            love.graphics.printf("JEFE FINAL", 0, 10, w, "center")
        end
        
    elseif self.pantalla == "derrota" then
        if imgDerrota then
            local iw, ih = imgDerrota:getDimensions()
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(imgDerrota, w/2 - iw/2, h/2 - ih/2 - 50)
        else
            love.graphics.setColor(0.8, 0.1, 0.1)
            love.graphics.printf("¡HAS SIDO DEVORADO!", 0, h/2 - 50, w, "center")
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Presiona R para reintentar o ESC para el Menú", 0, h/2 + 100, w, "center")
        
    elseif self.pantalla == "victoria" then
        if imgVictoria then
            local iw, ih = imgVictoria:getDimensions()
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(imgVictoria, w/2 - iw/2, h/2 - ih/2 - 70)
        else
            love.graphics.setColor(0.2, 1, 0.2)
            love.graphics.printf("¡NIVEL COMPLETADO!", 0, h/2 - 50, w, "center")
        end
        love.graphics.setColor(1, 1, 1)
        
        -- Opciones de Victoria
        if self.nivelSeleccionado < #niveles then
            love.graphics.printf("Presiona ENTER para ir al SIGUIENTE NIVEL", 0, h/2 + 50, w, "center")
        else
            love.graphics.printf("¡FELICIDADES! Completaste el juego", 0, h/2 + 50, w, "center")
        end
        love.graphics.printf("Presiona R para reintentar o ESC para el Menú", 0, h/2 + 80, w, "center")
    end
end

function UI:keypressed(key, juego)
    if self.pantalla == "menu" then
        if key == "up" then self.menuOpcion = math.max(1, self.menuOpcion - 1)
        elseif key == "down" then self.menuOpcion = math.min(3, self.menuOpcion + 1)
        elseif key == "return" then 
            if self.menuOpcion == 1 then self.pantalla = "seleccion_nivel"
            elseif self.menuOpcion == 2 then self.pantalla = "instrucciones"
            elseif self.menuOpcion == 3 then love.event.quit() end
        end
        
    elseif self.pantalla == "instrucciones" then
        if key == "return" or key == "escape" then self.pantalla = "menu" end

    elseif self.pantalla == "seleccion_nivel" then
        if key == "up" then self.nivelSeleccionado = math.max(1, self.nivelSeleccionado - 1)
        elseif key == "down" then self.nivelSeleccionado = math.min(#niveles, self.nivelSeleccionado + 1)
        elseif key == "return" then 
            self.pantalla = "juego"
            self.hpJefe = 150
            juego:iniciarNivel(self.nivelSeleccionado)
        elseif key == "escape" then self.pantalla = "menu" end
        
    elseif self.pantalla == "derrota" then
        if key == "r" then 
            self.pantalla = "juego"
            juego:iniciarNivel(juego.nivelActual) 
        end

    elseif self.pantalla == "victoria" then
        if key == "r" then 
            self.pantalla = "juego"
            juego:iniciarNivel(juego.nivelActual) 
        elseif key == "return" then
            -- Ir al siguiente nivel
            if self.nivelSeleccionado < #niveles then
                self.nivelSeleccionado = self.nivelSeleccionado + 1
                self.pantalla = "juego"
                self.hpJefe = 150
                juego:iniciarNivel(self.nivelSeleccionado)
            else
                self.pantalla = "menu"
            end
        end
    end
end

return function()
    local instancia = setmetatable({}, { __index = UI })
    instancia:init()
    return instancia
end