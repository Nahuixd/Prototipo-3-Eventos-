-- ui.lua: Interfaz gráfica con eventos (SOLID - SRP)
local Class = require("lib.hump").class
local eventos = require("lib.eventos")
local niveles = require("src.niveles")

local UI = Class{}

function UI:init()
    self.pantalla = "menu"
    self.nivelSeleccionado = 1
    self.vidas = 3
    self.puntos = 0
    self.objetivo = 5
    self.hpJefe = 100
    self.hpJefeMax = 100
    self.tiempo = 0
    self.nivelDesbloqueado = 1

    -- Suscripciones a eventos
    eventos.suscribirse("vida_cambiada", function(d)
        self.vidas = d.vidas
    end)
    eventos.suscribirse("puntos_cambiados", function(d)
        self.puntos = d.puntos
        self.objetivo = d.objetivo
    end)
    eventos.suscribirse("jefe_recibe_dano", function(d)
        self.hpJefe = d.hp
        self.hpJefeMax = d.hp_max
    end)
    eventos.suscribirse("jefe_derrotado", function()
        self.pantalla = "victoria"
    end)
    eventos.suscribirse("jugador_muerto", function()
        self.pantalla = "gameover"
    end)
end

function UI:update(dt)
    self.tiempo = self.tiempo + dt
end

function UI:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    if self.pantalla == "menu" then
        local pulso = 0.8 + 0.2 * math.sin(self.tiempo * 3)
        love.graphics.setColor(1, pulso, 0.2)
        love.graphics.printf("GUERRERO VS ZOMBIES", 0, 100, w, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Presiona ENTER para jugar", 0, 300, w, "center")
        love.graphics.printf("Presiona ESC para salir", 0, 340, w, "center")

    elseif self.pantalla == "seleccion_nivel" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("SELECCIONA UN NIVEL", 0, 80, w, "center")
        for i, n in ipairs(niveles) do
            if i == self.nivelSeleccionado then
                love.graphics.setColor(1, 0.85, 0.2)
            else
                love.graphics.setColor(1, 1, 1)
            end
            love.graphics.printf(n.nombre, 0, 180 + (i * 40), w, "center")
        end
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("↑↓ para mover · ENTER para jugar · ESC para volver",
            0, h - 60, w, "center")

    elseif self.pantalla == "juego" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Vidas: " .. self.vidas, 10, 10)
        love.graphics.print("Derrotados: " .. self.puntos .. "/" .. self.objetivo, 10, 40)
        if self.objetivo == 0 and self.hpJefe > 0 then
            love.graphics.setColor(0.8, 0.2, 0.2)
            love.graphics.rectangle("fill", w/2 - 150, 20,
                (self.hpJefe / self.hpJefeMax) * 300, 15)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("JEFE FINAL", 0, 5, w, "center")
        end

    elseif self.pantalla == "gameover" then
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf("GAME OVER", 0, h/2 - 50, w, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Presiona R para reiniciar", 0, h/2 + 10, w, "center")

    elseif self.pantalla == "victoria" then
        love.graphics.setColor(0.2, 1, 0.2)
        love.graphics.printf("¡VICTORIA!", 0, h/2 - 50, w, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Presiona R para reiniciar", 0, h/2 + 10, w, "center")
    end
end

function UI:keypressed(key, juego)
    if self.pantalla == "menu" then
        if key == "return" then
            self.pantalla = "seleccion_nivel"
        elseif key == "escape" then
            love.event.quit()
        end

    elseif self.pantalla == "seleccion_nivel" then
        if key == "up" then
            self.nivelSeleccionado = self.nivelSeleccionado - 1
            if self.nivelSeleccionado < 1 then self.nivelSeleccionado = #niveles end
        elseif key == "down" then
            self.nivelSeleccionado = self.nivelSeleccionado + 1
            if self.nivelSeleccionado > #niveles then self.nivelSeleccionado = 1 end
        elseif key == "return" then
            self.pantalla = "juego"
            juego:iniciarNivel(self.nivelSeleccionado)
        elseif key == "escape" then
            self.pantalla = "menu"
        end

    elseif self.pantalla == "juego" then
        if key == "escape" then
            self.pantalla = "menu"
            juego:reiniciar()
        end

    elseif self.pantalla == "gameover" or self.pantalla == "victoria" then
        if key == "r" then
            self.pantalla = "menu"
            juego:reiniciar()
        end
    end
end

return UI