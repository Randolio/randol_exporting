return {
    DeleteVehicleTimer = 2, -- minutes before the vehicle gets cleaned up after explosion.
    Vehicles = {
        S = {
            threshold = 10000,
            timer = 120, -- seconds,
            payout = {min = 1350, max = 1750},
            list = {
                'furia',
                'tursimor',
                'khamelion',
                'zentorno',
                'massacro',
                'tempesta',
                'raiden',
                'vagner',
                'drafter',
                'ruston',
                'adder',
                'italigto',
                'vacca',
                'reaper',
            },
            locations = { -- drop off locations for this tier. Picks one at random
                vec3(1001.42, -1533.23, 29.76),
                vec3(1169.54, -2973.29, 5.9),
            },
            xp = { min = 3, max = 5 }
        },
        A = {
            threshold = 7000,
            timer = 180, -- seconds,
            payout = {min = 825, max = 925},
            list = {
                'bullet',
                'jester',
                'kuruma',
                'ninef',
                'comet',
                'elegy2',
                'voltic',
                'coquette',
                'banshee',
                'elegy',
                'buffalo2',
            },
            locations = { -- drop off locations for this tier. Picks one at random
                vec3(1001.42, -1533.23, 29.76),
                vec3(1169.54, -2973.29, 5.9),
                vec3(175.74, 1245.55, 223.58),
            },
            xp = { min = 3, max = 5 }
        },
        B = {
            threshold = 5500,
            timer = 180, -- seconds,
            payout = {min = 600, max = 675},
            list = {
                'sultan',
                'sentinel',
                'monroe',
                'buffalo',
                'sultan2',
                'rapidgt',
                'revolter',
                'dominator3',
                'cheetah2',
                'schafter3',
            },
            locations = { -- drop off locations for this tier. Picks one at random
                vec3(1001.42, -1533.23, 29.76),
                vec3(1357.9, -2095.89, 52.0),
            },
            xp = { min = 3, max = 5 }
        },
        C = {
            threshold = 1000,
            timer = 180, -- seconds,
            payout = {min = 450, max = 500},
            list = {
                'rebla',
                'baller',
                'exemplar',
                'vigero',
                'fugitive',
                'seminole2',
                'felon',
                'dominator',
                'orcale',
            },
            locations = { -- drop off locations for this tier. Picks one at random
                vec3(749.34, -1059.6, 21.85),
                vec3(1169.54, -2973.29, 5.9),
            },
            xp = { min = 3, max = 5}
        },
        D = {
            threshold = 0,
            timer = 180, -- seconds,
            payout = {min = 320, max = 375},
            list = {
                'panto',
                'cavalcade',
                'jackal',
                'asea',
                'alpha',
                'issi2',
                'tornado',
                'ellie',
                'chino',
                'bison',
                'fusilade',
            },
            locations = { -- drop off locations for this tier. Picks one at random
                vec3(1130.14, -1302.51, 34.74),
                vec3(500.93, -97.95, 61.82),
                vec3(720.45, -767.12, 24.95),
            },
            xp = { min = 2, max = 3}
        },
    },
    MissionRewards = function(Player, payout)
        if not Player then return end
        -- add any additional rewards in here using Player which corresponds to your framework.
        AddMoney(Player, 'cash', payout)
    end
}