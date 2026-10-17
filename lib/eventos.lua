-- eventos.lua: Patrón Observer (SOLID - SRP)
local eventos = {}
local listeners = {}

function eventos.suscribirse(nombre, funcion)
    if not listeners[nombre] then listeners[nombre] = {} end
    table.insert(listeners[nombre], funcion)
end

function eventos.emitir(nombre, datos)
    if listeners[nombre] then
        for _, f in ipairs(listeners[nombre]) do
            f(datos or {})
        end
    end
end

function eventos.describir(nombre, funcion)
    if not listeners[nombre] then return end
    for i, f in ipairs(listeners[nombre]) do
        if f == funcion then
            table.remove(listeners[nombre], i)
            return
        end
    end
end

function eventos.limpiar()
    listeners = {}
end

return eventos