local config = {}

local display = display

config.colors_hex = {
    "#140c1c",
    "#442434",
    "#30346d",
    "#4e4a4e",
    "#854c30",
    "#346524",
    "#d04648",
    "#757161",
    "#597dce",
    "#d27d2c",
    "#8595a1",
    "#6daa2c",
    "#d2aa99",
    "#6dc2ca",
    "#dad45e",
    "#deeed6"
}

config.colors_name = {
    "black",
    "brown1",
    "blue1",
    "gray1",
    "brown2",
    "green1",
    "red",
    "gray2",
    "blue2",
    "orange",
    "white",
    "green2",
    "pink",
    "blue3",
    "yellow",
    "green3"
}

config.colors_rgb = {}

config.l = {}
config.l.split = string.gmatch
config.l.match = string.match
config.l.coolf = string.format
config.l.int = tonumber
config.l.str = tostring
config.l.sub = string.sub
config.l.w2w = string.gsub

config.bd = {}
config.bd.date = os.date()

for word in string.gmatch(config.bd.date, "%S+") do
    table.insert(config.bd, word)
end

config.t = {}
config.t.d1 = config.bd[1]
config.t.m = config.bd[2]
config.t.d2 = config.bd[3]
config.t.t = config.bd[4]
config.t.y = config.bd[5]

config.db = {}
config.db.zoom = math.pi / math.exp(1)
config.db.W = display.contentWidth
config.db.H = display.contentHeight

config.tf = {}
config.tf.f = "assets/font/mf.ttf"
config.tf.s = 16 * config.db.zoom

config.tt = {}
config.tt.o = {text = "", x = config.tf.s, y = config.tf.s, width = config.tf.s * 16 * config.db.zoom, font = config.tf.f, fontSize = config.tf.s}
config.tt.s = ""
config.tt.t = display.newText(config.tt.o)
config.tt.c = ""

config.pt = {}
config.pt.x = 0
config.pt.y = 0
config.pt.sx = 32
config.pt.sy = 32

function config.pt.h2n(hex)
    hex = hex:gsub("#", "")
    local r, g, b = config.l.int(hex:sub(1, 2), 16), config.l.int(hex:sub(3, 4), 16), config.l.int(hex:sub(5, 6), 16)
    return {r, g, b}
end

for i, v in pairs(config.colors_hex) do
    config.colors_rgb[config.colors_name[i]] = config.pt.h2n(v)
end

function config.pt.n1(t)
    return t[1], t[2], t[3]
end

function config.pt.n2(t)
    return {t[1] / 256, t[2] / 256, t[3] / 256}
end

function config.pt.color(t)
    return config.pt.n1(config.pt.n2(t))
end

function config.pt.t(text)
    config.tt.c = config.colors_rgb.red
    config.tt.t:setFillColor(config.pt.color(config.tt.c))
    config.tt.t.anchorY = 0
    config.tt.t.anchorX = 0
    config.tt.s = l.coolf("%s \n%s", text, config.tt.s)
    config.tt.t.text = config.tt.s
end

function config.pt.p()
    for i, v in ipairs(config.colors_name) do
        local r = display.newRect(config.pt.x, config.pt.y, config.pt.sx, config.pt.sy)
        r:setFillColor(config.pt.color(config.colors_rgb[v]))
        r.anchorX = 0
        r.anchorY = 0
        config.pt.x = config.pt.x + config.pt.sx
    end
end

display.setDefault("fillColor", config.pt.color(config.colors_rgb.red))
display.setDefault("background", config.pt.color(config.colors_rgb.black))

config.constant = {
    num_agents = 20,
    max_agents = 50,
    mortality_rate = 0.001,
    agent_size = 15,
    max_speed = 2,
    max_energy = 100,
    energy_loss_per_frame = 0.05
}

config.time = {}
config.time.timeScale = 0
config.time.gravityY = 0
config.time.gravityX = 0
config.time.boundaryMode = "wrap"

return config