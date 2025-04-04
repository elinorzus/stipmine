-- offline_miner.lua - Smart position-saving based on actual movement vs dig

-- === USER CONFIGURATION (SET THESE FIRST) ===
-- Try to load START_POS from progress.txt if it exists
CHEST_LOCATION = {x = 0, y = 0, z = 0}
local MINE_FROM = {0, 0, 0}
local MINE_TO  = {0, 0, 0}
local ORIGINAL_START_POS = {x = 0, y = 0, z = 0, facing = "change to your facing"}

local START_POS
local directions = { "north", "east", "south", "west" }
local directionVectors = {
    north = { x = 0, z = -1 },
    east  = { x = 1, z = 0 },
    south = { x = 0, z = 1 },
    west  = { x = -1, z = 0 }
}
local facing = 1
local pos = { x = 0, y = 0, z = 0 }

if fs.exists("progress.txt") then
    local file = fs.open("progress.txt", "r")
    local data = file.readAll()
    file.close()

    local parsed = textutils.unserialize(data)
    if parsed and parsed.location then
        local facingIndex = parsed.location.facing or 1
        local facingName = (type(facingIndex) == "number") and directions[facingIndex] or parsed.location.facing
        START_POS = {
            x = parsed.location.x,
            y = parsed.location.y,
            z = parsed.location.z,
            facing = facingName
        }
    else
        error("Invalid progress.txt format.")
    end
else
    -- Fallback/default START_POS if no progress file exists
    START_POS = ORIGINAL_START_POS
end

local yieldCounter = 0
function forceYieldEvery(n)
    yieldCounter = yieldCounter + 1
    if yieldCounter >= n then
        yieldCounter = 0
        os.queueEvent("yield")
        os.pullEvent("yield")
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
    local dir = { north = 1, east = 2, south = 3, west = 4 }
    if dir[face] then facing = dir[face] else print("Invalid facing!") end
end

function setPos(x, y, z, dirName)
    pos = { x = x, y = y, z = z }
    returnNumOrientation(dirName)
end

function refuelIfNeeded()
    while turtle.getFuelLevel() == 0 do
        print("Refueling...")
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(1) then print("Refueled!") return true end
        end
        sleep(0.1)
    end
    return true
end

function turnLeft()
    turtle.turnLeft()
    facing = (facing - 2) % 4 + 1
    saveProgress(nil, {x = pos.x, y = pos.y, z = pos.z, facing = facing})
end

function turnRight()
    turtle.turnRight()
    facing = (facing % 4) + 1
    saveProgress(nil, {x = pos.x, y = pos.y, z = pos.z, facing = facing})
end

function faceDirection(target)
    while facing ~= target do
        turnRight()
        forceYieldEvery(10)
    end
end

function saveProgress(minedList, location)
    local currentData = loadCoords() or { mined = {} }
    local saveData = {
        location = location or currentData.location,
        mined = minedList or currentData.mined
    }
    local file = fs.open("progress.txt", "w")
    file.write(textutils.serialize(saveData))
    file.close()
end

function moveForward()
    refuelIfNeeded()
    local dir = directionVectors[directions[facing]]
    local futurePos = {
        x = pos.x + dir.x,
        y = pos.y,
        z = pos.z + dir.z,
        facing = facing
    }

    -- Preemptively save where we're about to go
    saveProgress(nil, futurePos)

    while not turtle.forward() do
        turtle.dig()
        sleep(0.2)
        forceYieldEvery(5)
    end

    -- Now actually update position
    pos.x = futurePos.x
    pos.z = futurePos.z
end

function goUp()
    refuelIfNeeded()
    local futurePos = {x = pos.x, y = pos.y + 1, z = pos.z, facing = facing}
    saveProgress(nil, futurePos)

    while not turtle.up() do
        turtle.digUp()
        sleep(0.2)
        forceYieldEvery(5)
    end

    pos.y = futurePos.y
end

function goDown()
    refuelIfNeeded()
    local futurePos = {x = pos.x, y = pos.y - 1, z = pos.z, facing = facing}
    saveProgress(nil, futurePos)

    while not turtle.down() do
        turtle.digDown()
        sleep(0.2)
        forceYieldEvery(5)
    end

    pos.y = futurePos.y
end


function moveTo(targetX, targetY, targetZ)
    while pos.y < targetY do goUp() forceYieldEvery(5) end
    while pos.y > targetY do goDown() forceYieldEvery(5) end
    if pos.z ~= targetZ then faceDirection(pos.z < targetZ and 3 or 1)
        while pos.z ~= targetZ do moveForward() forceYieldEvery(5) end
    end
    if pos.x ~= targetX then faceDirection(pos.x < targetX and 2 or 4)
        while pos.x ~= targetX do moveForward() forceYieldEvery(5) end
    end
end

function locationExists(mined, x, y, z)
    for i, pos in ipairs(mined) do
        if pos[1] == x and pos[2] == y and pos[3] == z then return true end
        if i % 50 == 0 then os.queueEvent("yield") os.pullEvent("yield") end
    end
    return false
end

function smartUnload(fuelWhitelist)
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and not fuelWhitelist[item.name] then turtle.drop() end
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
    local mined = {}
    local resumePos = nil

    -- Load progress if available
    if saveData then
        mined = saveData.mined or {}
        resumePos = saveData.location
    end

    -- If resuming, move to last known position
    if resumePos then
        moveTo(resumePos.x, resumePos.y, resumePos.z)
        pos.x, pos.y, pos.z = resumePos.x, resumePos.y, resumePos.z
        while facing ~= resumePos.facing do
            turnRight()
            forceYieldEvery(5)
        end
    end

    -- Generate list of all blocks in Y-X-Z order
    for y = math.max(startPoint[2], endPoint[2]), math.min(startPoint[2], endPoint[2]), -1 do
        for z = math.min(startPoint[3], endPoint[3]), math.max(startPoint[3], endPoint[3]) do
            for x = math.min(startPoint[1], endPoint[1]), math.max(startPoint[1], endPoint[1]) do
                table.insert(allBlocks, {x, y, z})
            end
        end
    end

    -- Filter only unmined blocks
    local unminedBlocks = {}
    for _, block in ipairs(allBlocks) do
        if not locationExists(mined, block[1], block[2], block[3]) then
            table.insert(unminedBlocks, block)
        end
    end

    -- Start mining loop
    for _, block in ipairs(unminedBlocks) do
        local x, y, z = block[1], block[2], block[3]

        -- Handle full inventory
        if isInventoryFull() then
            local returnPos = {x = pos.x, y = pos.y, z = pos.z, facing = facing}
            print("Inventory full. Going to chest...")
            moveTo(CHEST_LOCATION.x, CHEST_LOCATION.y, CHEST_LOCATION.z)
            smartUnload(fuelItems)
            moveTo(returnPos.x, returnPos.y, returnPos.z)
            faceDirection(returnPos.facing)
        end

        -- Move to the block
        moveTo(x, y, z)

        -- Save position immediately after moving
        local currentPos = {x = pos.x, y = pos.y, z = pos.z, facing = facing}
        saveProgress(mined, currentPos)

        -- Optional: dig block underneath if not lowest layer
        if y > math.min(startPoint[2], endPoint[2]) then
            local success = turtle.inspectDown()
            if success then turtle.digDown() end
        end

        -- Mark as mined and save again
        table.insert(mined, { currentPos.x, currentPos.y, currentPos.z })
        saveProgress(mined, currentPos)

        -- Log progress
        print("Mined:", currentPos.x, currentPos.y, currentPos.z)

        forceYieldEvery(5)
    end

    -- Finish: return to start and delete progress file
    print("✅ Finished mining area. Returning to start...")
    moveTo(startPoint[1], startPoint[2], startPoint[3])
    if fs.exists("progress.txt") then fs.delete("progress.txt") end
end

-- === START ===
setPos(START_POS.x, START_POS.y, START_POS.z, START_POS.facing)
mineArea(MINE_FROM, MINE_TO)
