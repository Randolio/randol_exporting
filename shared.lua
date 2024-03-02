lib.locale()

return {
    Debug = false,
    PedModel = `csb_isldj_03`,
    PedCoords = vec4(-512.79, -1733.28, 18.08, 240.01),
    VehicleSpawn = vec4(-510.75, -1736.25, 19.17, 324.87),
    BlipInfo = {
        String = "Drop Off",
        Sprite = 430,
        Scale = 0.75,
        Colour = 5,
        Alpha = 200,
        Radius_Alpha = 120,
        Radius_Colour = 5,
    },
    Fuel = {
        enable = false, -- I use ox_fuel so I set this to false and use statebag to set the fuel
        script = 'LegacyFuel',
    },
    UseTarget = true, 
    -- if true, it will use a qb-target export that ox target handles conversion for (ESX). 
    -- if you're using qb-target with QB, you'll be fine.
    -- if false, it'll use ox lib points and [E] key press.
}