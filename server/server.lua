--[[
    ██╗     ██╗  ██╗██████╗        ██████╗ ██████╗ ██████╗ ███████╗
    ██║     ╚██╗██╔╝██╔══██╗      ██╔════╝██╔═══██╗██╔══██╗██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗██║     ██║   ██║██████╔╝█████╗  
    ██║      ██╔██╗ ██╔══██╗╚════╝██║     ██║   ██║██╔══██╗██╔══╝  
    ███████╗██╔╝ ██╗██║  ██║      ╚██████╗╚██████╔╝██║  ██║███████╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

    🐺 LXR Core - Art Heist System | SERVER
    © 2026 iBoss21 / The Lux Empire | wolves.land
]]

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SERVER LOGIC ██████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

local stolenObjects = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Register usable lockpick item across all supported frameworks
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(500) -- wait for framework to initialise
    RegisterItem(Config.RequiredItem, function(data)
        local src = data.source or data
        TriggerClientEvent("lxr-artheist:lockpick", src)
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Mark a prop as stolen (synced to all clients)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent("artheist:markStolen", function(netId)
    if netId then
        stolenObjects[netId] = true
        TriggerClientEvent("artheist:updateStolenObjects", -1, stolenObjects)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Pay player after successful art delivery
-- ─────────────────────────────────────────────────────────────────────────────

-- Compute the maximum possible offer across all delivery locations
local function GetMaxOfferPrice()
    local maxPrice = 0
    for _, loc in pairs(Config.DeliveryLocations) do
        if loc.offers then
            for _, offer in pairs(loc.offers) do
                if offer.maxPrice and offer.maxPrice > maxPrice then
                    maxPrice = offer.maxPrice
                end
            end
        end
    end
    return maxPrice
end

-- Track recent payouts per player to prevent rapid-fire exploits
local recentPayouts = {}
local PAYOUT_COOLDOWN = 5 -- seconds

RegisterNetEvent("artheist:pay", function(price, locationIndex, modelHash, durability)
    local src <const> = source
    if not price or type(price) ~= "number" or price <= 0 then return end

    -- Validate price does not exceed the maximum configured offer
    local maxAllowed = GetMaxOfferPrice()
    if price > maxAllowed then
        print(('[lxr-artheist] BLOCKED: Player %d tried to claim $%d (max allowed $%d)'):format(src, price, maxAllowed))
        return
    end

    -- Cooldown check
    local now = os.time()
    if recentPayouts[src] and (now - recentPayouts[src]) < PAYOUT_COOLDOWN then
        print(('[lxr-artheist] BLOCKED: Player %d payout too fast (cooldown)'):format(src))
        return
    end
    recentPayouts[src] = now

    AddMoney(src, price)
    SendArtHeistLog(src, price, locationIndex, durability)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Debug: give lockpick to a player (server console only)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterCommand("addlockpick", function(source)
    local src <const> = source
    AddItem(src, Config.RequiredItem, 1)
end, true)

-- ─────────────────────────────────────────────────────────────────────────────
-- Callback: check if player has a lockpick (and optionally consume it)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterCallback("lxr-artheist:server:HasLockpick?", function(source, cb)
    local src <const> = source
    local hasItem = GetItem(src, Config.RequiredItem)
    if hasItem then
        local randomChance = math.random(0, 100) / 100
        if randomChance <= Config.DeleteLockPickChance then
            RemoveItem(src, Config.RequiredItem, 1)
            NotifyPlayer(src, _L("lockpickBroken"))
        end
        return true
    else
        return false
    end
end)

