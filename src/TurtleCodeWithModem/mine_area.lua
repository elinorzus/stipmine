-- Open rednet modem
rednet.open("change to where your modem is placed has to be left, right, ect..")
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
local CHEST_LOCATION = {x = 0, y = 0, z = 0}
local send_info = dofile("send_information.lua")

function isInventoryFull()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            return false -- There's still room
        end
    end
    return true -- No empty slots
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
        return nil
    end
end

function setPos(x, y, z, dirName)
    pos = { x = x, y = y, z = z }

    local dirMap = {
        north = 1,
        east = 2,
        south = 3,
        west = 4
    }

    if dirMap[dirName] then
        facing = dirMap[dirName]
        returnNumOrientation(dirName) -- optional: rotate turtle physically too
    else
        print("Invalid direction:", dirName)
    end
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


-- Movement with tracking
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
    end
end

function moveForward()
    refuelIfNeeded()
    while not turtle.forward() do
        turtle.dig()
        sleep(0.2)
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
    end
    pos.y = pos.y + 1
end

function goDown()
    refuelIfNeeded()
    while not turtle.down() do
        turtle.digDown()
        sleep(0.2)
    end
    pos.y = pos.y - 1
end

-- Navigation
function moveTo(targetX, targetY, targetZ, save)
    while pos.y < targetY do goUp() end
    while pos.y > targetY do goDown() end

    if pos.z ~= targetZ then
        faceDirection(pos.z < targetZ and 3 or 1)
        while pos.z ~= targetZ do moveForward() end
    end

    if pos.x ~= targetX then
        faceDirection(pos.x < targetX and 2 or 4)
        while pos.x ~= targetX do moveForward() end
    end

    if save then
        saveData(targetX,targetY,targetZ)
    end
end

function returnTo(x, y, z)
    moveTo(x, y, z, false)
end

function mineTo(x, y, z)
    moveTo(x, y, z, true)
    if pos.y > y then
        turtle.digDown()
    end
end

local function locationExists(mined, x, y, z)
    for _, pos in ipairs(mined) do
        if pos[1] == x and pos[2] == y and pos[3] == z then
            return true
        end
    end
    return false
end

function saveData(x, y, z)
    -- Load existing data
    local saveData = {
        location = {},
        mined = {}
    }

    if fs.exists("progress.txt") then
        local file = fs.open("progress.txt", "r")
        local content = file.readAll()
        file.close()

        saveData = textutils.unserialize(content) or saveData
    end

    -- Update current location
    --print(facing)
    saveData.location = {
        x = x,
        y = y,
        z = z,
        facing = facing
    }

    -- Only insert if the location is new
    if not locationExists(saveData.mined, x, y, z) then
        table.insert(saveData.mined, {x, y, z})
    end

    -- Save back to file
    local file = fs.open("progress.txt", "w")
    file.write(textutils.serialize(saveData))
    file.close()
end


function loadCoords()
    if fs.exists("progress.txt") then
        local file = fs.open("progress.txt", "r")
        local data = file.readAll()
        file.close()
        return textutils.unserialize(data)
    end
    return nil
end


function smartUnload(fuelWhitelist)
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            if not fuelWhitelist[item.name] then
                turtle.drop()
            end
        end
    end
    turtle.select(1)
end

-- Usage
local fuelItems = {
    ["minecraft:coal"] = true,
    ["minecraft:charcoal"] = true,
    ["minecraft:lava_bucket"] = true
}

function mineArea(startPoint, endPoint)
    allBlocks = {}
    minedBlocks = {}

    -- Load previous save
    local saveData = loadCoords()

    -- Restore turtle position and facing
    if saveData and saveData.location then
        local turtleLocation = saveData.location

        moveTo(turtleLocation.x, turtleLocation.y, turtleLocation.z, true)

        pos.x = turtleLocation.x
        pos.y = turtleLocation.y
        pos.z = turtleLocation.z

        local oldFacing = facing
        local newFacing = turtleLocation.facing

        while oldFacing ~= newFacing do
            turtle.turnRight()
            oldFacing = (oldFacing % 4) + 1
        end
        facing = newFacing
 
    end

    -- Determine bounds
    local minX = math.min(startPoint[1], endPoint[1])
    local maxX = math.max(startPoint[1], endPoint[1])
    local minY = math.min(startPoint[2], endPoint[2])
    local maxY = math.max(startPoint[2], endPoint[2])
    local minZ = math.min(startPoint[3], endPoint[3])
    local maxZ = math.max(startPoint[3], endPoint[3])

    -- Generate all block positions
    for y = maxY, minY, -1 do
        for z = minZ, maxZ do
            for x = minX, maxX do
                table.insert(allBlocks, {x, y, z})
            end
        end
    end

    -- Remove already mined blocks
    if saveData and saveData.mined then
        local newAllBlocks = {}

        for _, block in ipairs(allBlocks) do
            local x, y, z = block[1], block[2], block[3]
            if not locationExists(saveData.mined, x, y, z) then
                table.insert(newAllBlocks, block)
            end
        end

        allBlocks = newAllBlocks
    end

    -- Loop through all remaining blocks
    for i = #allBlocks, 1, -1 do
        local x, y, z = table.unpack(allBlocks[i])
        local lastPlace = {pos.x, pos.y, pos.z}

        if isInventoryFull() then
            -- Save current location
            local returnPos = {x = pos.x, y = pos.y, z = pos.z}
        
            -- Go to chest
            returnTo(CHEST_LOCATION.x, CHEST_LOCATION.y, CHEST_LOCATION.z)
        
            -- Unload non-fuel items
            smartUnload(fuelItems)
        
            -- Go back to where we were
            returnTo(returnPos.x, returnPos.y, returnPos.z)
        end
        

        moveTo(x, y, z, true)

        -- Only dig if y > 0 and not on lowest layer
        if y > minY then
            local success, _ = turtle.inspectDown()
            if success then turtle.digDown() end
        end

        -- Save that block as mined
        saveData = saveData or { mined = {}, location = {} }
        if not locationExists(saveData.mined, x, y, z) then
            table.insert(saveData.mined, {x, y, z})
        end

        -- Update current location and facing
        saveData.location = { x = x, y = y, z = z, facing = facing }

        -- Save progress
        local file = fs.open("progress.txt", "w")
        file.write(textutils.serialize(saveData))
        file.close()

        -- Remove from block list
        table.remove(allBlocks, i)
    end
    
    returnTo(startPoint[1], startPoint[2], startPoint[3])

    if fs.exists("progress.txt") then
        fs.delete("progress.txt")
    else
        print("No progress file to delete.")
    end    
end


-- Message listening loop
while true do
    sleep(0.1)
    refuelIfNeeded()
    local senderId, message = rednet.receive()

    if type(message) == "table" and message.command and message.data and message.orientation and message.chestLocation then
        if message.command == "mine" and #message.data == 3 then
            returnNumOrientation(message.orientation)
            pos.x = message.data[3][1]
            pos.y = message.data[3][2]
            pos.z = message.data[3][3]
            CHEST_LOCATION = {x = message.chestLocation[1], y = message.chestLocation[2], z = message.chestLocation[3]}
            mineArea(message.data[1], message.data[2])

        else
            print("Error: Invalid mine data format.")
        end
    else
        print("Error: Received an invalid message")
    end
end
