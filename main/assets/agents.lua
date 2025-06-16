-- Логика агентов: создание, обновление, размножение

local config = require("assets.config")
local physics = require("physics")
local display, native, Runtime = display, native, Runtime

local agents = {}
local agentsGroup = display.newGroup()

local constant = config.constant
local db = config.db
local pt = config.pt
local time = config.time
local tf = config.tf
local colors_rgb = config.colors_rgb

local function main() --> #ревизия 15.06.2025

    physics.start()

    local function createAgent(x, y, genes) 
        local agent = display.newCircle(x, y, constant.agent_size)
        if not genes then
            genes = {
                r = math.random(),
                g = math.random(),
                b = math.random(),
                speedFactor = 0.5 + math.random()
            }
        end
        -- agent.fill.effect = "filter.pixelate"
        -- agent.fill.effect.numPixels = 8
        agent:setFillColor(genes.r, genes.g, genes.b)
        physics.addBody(agent, "dynamic", {radius=constant.agent_size, bounce=0.8})
        agent.isFixedRotation = true
        agent.speedX = (math.random() * 2 - 1) * constant.max_speed * genes.speedFactor
        agent.speedY = (math.random() * 2 - 1) * constant.max_speed * genes.speedFactor
        agent.genes = genes
        agent.age = 0
        agent.reproductionCooldown = 0
        agent.energy = constant.max_energy

        agent.energyText = display.newText({
            text = tostring(math.floor(agent.energy)),
            x = agent.x,
            y = agent.y - constant.agent_size,
            font = tf.f,
            fontSize = tf.s
        })

        agent.energyText:setFillColor(pt.color(colors_rgb.green3))

        agentsGroup:insert(agent)
        agentsGroup:insert(agent.energyText)

        return agent
    end

    for _ = 1, constant.num_agents do
        local x = math.random(constant.agent_size, db.W - constant.agent_size)
        local y = math.random(constant.agent_size, db.H - constant.agent_size)
        local agent = createAgent(x, y)
        agents[#agents + 1] = agent
    end

    local function updateAgent(agent)
        agent.x = agent.x + agent.speedX * time.timeScale
        agent.y = agent.y + agent.speedY * time.timeScale

        if time.boundaryMode == "bounce" then
            if agent.x < constant.agent_size then
                agent.x = constant.agent_size
                agent.speedX = -agent.speedX
            elseif agent.x > db.W - constant.agent_size then
                agent.x = db.W - constant.agent_size
                agent.speedX = -agent.speedX
            end

            if agent.y < constant.agent_size then
                agent.y = constant.agent_size
                agent.speedY = -agent.speedY
            elseif agent.y > db.H - constant.agent_size then
                agent.y = db.H - constant.agent_size
                agent.speedY = -agent.speedY
            end
        elseif time.boundaryMode == "wrap" then
            if agent.x < 0 then
                agent.x = db.W
            elseif agent.x > db.W then
                agent.x = 0
            end

            if agent.y < 0 then
                agent.y = db.H
            elseif agent.y > db.H then
                agent.y = 0
            end
        elseif time.boundaryMode == "stop" then
            if agent.x < constant.agent_size then
                agent.x = constant.agent_size
                agent.speedX = 0
            elseif agent.x > db.W - constant.agent_size then
                agent.x = db.W - constant.agent_size
                agent.speedX = 0
            end

            if agent.y < constant.agent_size then
                agent.y = constant.agent_size
                agent.speedY = 0
            elseif agent.y > db.H - constant.agent_size then
                agent.y = db.H - constant.agent_size
                agent.speedY = 0
            end
        end
    end

    local function crossoverGenes(genes1, genes2)
        local function mutate(value)
            if math.random() < 0.1 then
                return math.min(math.max(value + (math.random() - 0.5) * 0.2, 0), 1)
            else
                return value
            end
        end

        local childGenes = {
            r = mutate((genes1.r + genes2.r) / 2),
            g = mutate((genes1.g + genes2.g) / 2),
            b = mutate((genes1.b + genes2.b) / 2),
            speedFactor = math.min(math.max((genes1.speedFactor + genes2.speedFactor) / 2 + (math.random() - 0.5) * 0.1, 0.1), 2)
        }
        return childGenes
    end

    local function reproduce(parent1, parent2)
        if #agents >= constant.max_agents then
            return
        end
        local x = (parent1.x + parent2.x) / 2 + math.random(-10, 10)
        local y = (parent1.y + parent2.y) / 2 + math.random(-10, 10)
        local childGenes = crossoverGenes(parent1.genes, parent2.genes)
        local child = createAgent(x, y, childGenes)
        agents[#agents + 1] = child
    end

    local function gameLoop(event)
        for i = #agents, 1, -1 do
            local agent = agents[i]
            agent.age = agent.age + time.timeScale
            agent.reproductionCooldown = math.max(agent.reproductionCooldown - time.timeScale, 0)

            if time.timeScale > 0 and math.random() < constant.mortality_rate then
                agent.energy = 0
            else
                agent.energy = agent.energy - constant.energy_loss_per_frame * time.timeScale
            end

            if agent.energy <= 0 then
                agent:removeSelf()
                agent.energyText:removeSelf()
                table.remove(agents, i)
            else
                agent.energyText.text = tostring(math.floor(agent.energy))
                agent.energyText.x = agent.x
                agent.energyText.y = agent.y - constant.agent_size - 10

                if math.random() < 0.05 then
                    agent.speedX = (math.random() * 2 - 1) * constant.max_speed * agent.genes.speedFactor
                    agent.speedY = (math.random() * 2 - 1) * constant.max_speed * agent.genes.speedFactor
                end

                updateAgent(agent)

                if agent.reproductionCooldown == 0 then
                    for j = 1, #agents do
                        if i ~= j then
                            local other = agents[j]
                            local dx = agent.x - other.x
                            local dy = agent.y - other.y
                            local dist = math.sqrt(dx*dx + dy*dy)
                            if dist < constant.agent_size * 2 then
                                reproduce(agent, other)
                                agent.reproductionCooldown = 300
                                other.reproductionCooldown = 300
                                break
                            end
                        end
                    end
                end

                if agent.age > 2000 then
                    agent:removeSelf()
                    agent.energyText:removeSelf()
                    table.remove(agents, i)
                end
            end
        end
    end

    Runtime:addEventListener("enterFrame", gameLoop)

    return {
    agents = agents,
    agentsGroup = agentsGroup,
    createAgent = createAgent,
    updateAgent = updateAgent,
    crossoverGenes = crossoverGenes,
    reproduce = reproduce,
    gameLoop = gameLoop
}
end

return main()