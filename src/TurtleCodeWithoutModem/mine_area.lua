-- offline_miner.lua - No rednet required

-- === USER CONFIGURATION (SET THESE FIRST) ===
-- Set manually before running (edit these values)
local START_POS = {x = 0, y = 64, z = 0, facing = "change to you turtle current facing"} -- Turtle's current position and direction
CHEST_LOCATION = {x = 0, y = 64, z = -1} -- Location just before the chest
local MINE_FROM = {0, 64, 0} -- Start corner of the mine
local MINE_TO   = {5, 64, 5} -- End corner of the mine
local send_info = dofile("send_information.lua")

-- Constants
local directions = { "north", "east", "south", "west" }
local directionVectors = {
    north = { x = 0, z = -1 },
    east =  { x = 1, z = 0 },
    south = { x = 0, z = 1 },
    west =  { x = -1, z = 0 }
}

-- State
local facing = 1 -- north
local pos = { x = 0, y = 0, z = 0 }

local yieldCounter = 0
function forceYieldEvery(n)
    yieldCounter = yieldCounter + 1
    if yieldCounter >= n then
        yieldCounter = 0
        os.queueEvent("yield")
        os.pullEvent()
    end
end

function isInventoryFull()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            return false
        end
    end
    return true
end

function returnNumOrientation(face)
    local dir = {
        north = 1,
        east = 2,
        south = 3,
        west = 4
    }
    if dir[face] then
        facing = dir[face]
    else
        print("Direction not found!")
    end
end

function setPos(x, y, z, dirName)
    pos = { x = x, y = y, z = z }
    returnNumOrientation(dirName)
end

function refuelIfNeeded()
    local warned = false

    while turtle.getFuelLevel() == 0 do 
        sleep(0.1)
        if not warned then
            print("No fuel available!")
            send_info.receive("No fuel available!")
            warned = true
        end

        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(1) then
                print("Refueled!")
                return true
            end
        end
    end
    return true
end

function turnLeft()
    turtle.turnLeft()
    facing = (facing - 2) % 4 + 1
end

function turnRight()
    turtle.turnRight()
    facing = (facing % 4) + 1
end

function faceDirection(target)
    while facing ~= target do
        turnRight()
        forceYieldEvery(10)
    end
end

function moveForward()
    refuelIfNeeded()
    while not turtle.forward() do
        turtle.dig()
        sleep(0.2)
        forceYieldEvery(5)
    end
    local dir = directionVectors[directions[facing]]
    pos.x = pos.x + dir.x
    pos.z = pos.z + dir.z
end

function goUp()
    refuelIfNeeded()
    while not turtle.up() do
        turtle.digUp()
        sleep(0.2)
        forceYieldEvery(5)
    end
    pos.y = pos.y + 1
end

function goDown()
    refuelIfNeeded()
    while not turtle.down() do
        turtle.digDown()
        sleep(0.2)
        forceYieldEvery(5)
    end
    pos.y = pos.y - 1
end

function moveTo(targetX, targetY, targetZ, save)
    while pos.y < targetY do goUp(); forceYieldEvery(5) end
    while pos.y > targetY do goDown(); forceYieldEvery(5) end
    if pos.z ~= targetZ then
        faceDirection(pos.z < targetZ and 3 or 1)
        while pos.z ~= targetZ do moveForward(); forceYieldEvery(5) end
    end
    if pos.x ~= targetX then
        faceDirection(pos.x < targetX and 2 or 4)
        while pos.x ~= targetX do moveForward(); forceYieldEvery(5) end
    end
    if save then saveData(targetX, targetY, targetZ) end
end

function saveData(x, y, z)
    local saveData = { location = {}, mined = {} }
    if fs.exists("progress.txt") then
        local file = fs.open("progress.txt", "r")
        local content = file.readAll()
        file.close()
        saveData = textutils.unserialize(content) or saveData
    end
    saveData.location = { x = x, y = y, z = z, facing = facing }
    if not locationExists(saveData.mined, x, y, z) then
        table.insert(saveData.mined, {x, y, z})
    end
    local file = fs.open("progress.txt", "w")
    file.write(textutils.serialize(saveData))
    file.close()
end

function locationExists(mined, x, y, z)
    for i, pos in ipairs(mined) do
        if pos[1] == x and pos[2] == y and pos[3] == z then
            return true
        end
        if i % 50 == 0 then os.queueEvent("yield"); os.pullEvent() end
    end
    return false
end

function smartUnload(fuelWhitelist)
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and not fuelWhitelist[item.name] then
            turtle.drop()
        end
    end
    turtle.select(1)
end

local fuelItems = {
    ["minecraft:coal"] = true,
    ["minecraft:charcoal"] = true,
    ["minecraft:lava_bucket"] = true
}

function loadCoords()
    if fs.exists("progress.txt") then
        local file = fs.open("progress.txt", "r")
        local data = file.readAll()
        file.close()
        return textutils.unserialize(data)
    end
    return nil
end

function mineArea(startPoint, endPoint)
    local allBlocks = {}
    local saveData = loadCoords()
    if saveData and saveData.location then
        local loc = saveData.location
        moveTo(loc.x, loc.y, loc.z, true)
        pos.x, pos.y, pos.z = loc.x, loc.y, loc.z
        while facing ~= loc.facing do
            turnRight()
            forceYieldEvery(5)
        end
    end
    for y = math.max(startPoint[2], endPoint[2]), math.min(startPoint[2], endPoint[2]), -1 do
        for z = math.min(startPoint[3], endPoint[3]), math.max(startPoint[3], endPoint[3]) do
            for x = math.min(startPoint[1], endPoint[1]), math.max(startPoint[1], endPoint[1]) do
                table.insert(allBlocks, {x, y, z})
            end
        end
    end
    if saveData and saveData.mined then
        local filtered = {}
        for _, b in ipairs(allBlocks) do
            if not locationExists(saveData.mined, b[1], b[2], b[3]) then
                table.insert(filtered, b)
            end
        end
        allBlocks = filtered
    end
    for i = #allBlocks, 1, -1 do
        local x, y, z = table.unpack(allBlocks[i])
        if isInventoryFull() then
            local returnPos = {x = pos.x, y = pos.y, z = pos.z}
            moveTo(CHEST_LOCATION.x, CHEST_LOCATION.y, CHEST_LOCATION.z, false)
            smartUnload(fuelItems)
            moveTo(returnPos.x, returnPos.y, returnPos.z, false)
        end
        
        moveTo(x, y, z, true)
        if y > math.min(startPoint[2], endPoint[2]) then
            local success = turtle.inspectDown()
            if success then turtle.digDown() end
        end

        saveData = saveData or { mined = {}, location = {} }
        if not locationExists(saveData.mined, x, y, z) then
            table.insert(saveData.mined, {x, y, z})
        end
        saveData.location = { x = x, y = y, z = z, facing = facing }
        local file = fs.open("progress.txt", "w")
        file.write(textutils.serialize(saveData))
        file.close()
        table.remove(allBlocks, i)
        forceYieldEvery(5)
    end
    moveTo(startPoint[1], startPoint[2], startPoint[3], false)
    if fs.exists("progress.txt") then fs.delete("progress.txt") end
end

-- === RUN SETUP AND START ===
setPos(START_POS.x, START_POS.y, START_POS.z, START_POS.facing)
mineArea(MINE_FROM, MINE_TO)
