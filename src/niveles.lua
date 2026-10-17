-- niveles.lua: Configuración de los 5 niveles
local niveles = {
    {
        nombre      = "Nivel 1: El Bosque",
        objetivo    = 5,
        maxExtra    = 3,
        velEnemigo  = 30,
        vidaJugador = 3,
        jefe        = false,
    },
    {
        nombre      = "Nivel 2: El Cementerio",
        objetivo    = 10,
        maxExtra    = 5,
        velEnemigo  = 40,
        vidaJugador = 3,
        jefe        = false,
    },
    {
        nombre      = "Nivel 3: La Ciudad",
        objetivo    = 15,
        maxExtra    = 7,
        velEnemigo  = 50,
        vidaJugador = 4,
        jefe        = false,
    },
    {
        nombre      = "Nivel 4: El Laboratorio",
        objetivo    = 20,
        maxExtra    = 10,
        velEnemigo  = 60,
        vidaJugador = 4,
        jefe        = false,
    },
    {
        nombre      = "Nivel 5: El Jefe Final",
        objetivo    = 0,
        maxExtra    = 0,
        velEnemigo  = 0,
        vidaJugador = 5,
        jefe        = true,
    },
}

return niveles