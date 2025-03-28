-- Open rednet modem
rednet.open("left")
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

function returnNumOrientation(face)
    local dir = {
        north = 1,
        east = 2,
        south = 3,
        west = 4
    }

    if dir[face] then
        print("Value is:", dir[face])  --> Value is: 1
        facing = dir[face]
    else
        print("Direction not found!")
        return nil
    end
end

function refuelIfNeeded()
    if turtle.getFuelLevel() == 0 then 
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(1) then
                print("Refueled from slot", slot)
                return true
            end
        end
        print("No fuel available!")
        return false
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
function moveTo(targetX, targetY, targetZ)
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
end

function returnTo(x, y, z)
    moveTo(x, y, z)
    print("Returned to starting point.")
end

function mineTo(x, y, z)
    moveTo(x, y, z)
    if pos.y > y then
        turtle.digDown()
    end
end

function mineArea(startPoint, endPoint, turtleStart)
    pos = { x = turtleStart[1], y = turtleStart[2], z = turtleStart[3] }

    local minX = math.min(startPoint[1], endPoint[1])
    local maxX = math.max(startPoint[1], endPoint[1])
    local minY = math.min(startPoint[2], endPoint[2])
    local maxY = math.max(startPoint[2], endPoint[2])
    local minZ = math.min(startPoint[3], endPoint[3])
    local maxZ = math.max(startPoint[3], endPoint[3])

    for y = maxY, minY, -1 do
        for z = minZ, maxZ do
            if (z - minZ) % 2 == 0 then
                for x = minX, maxX do
                    mineTo(x, y, z)
                end
            else
                for x = maxX, minX, -1 do
                    mineTo(x, y, z)
                end
            end
        end
    end

    -- Return to original position
    returnTo(turtleStart[1], turtleStart[2], turtleStart[3])
end

-- Message listening loop
while true do
    sleep(0.1)
    refuelIfNeeded()
    local senderId, message = rednet.receive()

    if type(message) == "table" and message.command and message.data and message.orientation then
        if message.command == "mine" and #message.data == 3 then
            returnNumOrientation(message.orientation)
            print(facing)
            mineArea(message.data[1], message.data[2], message.data[3])
        else
            print("Error: Invalid mine data format.")
        end
    else
        print("Error: Received an invalid message")
    end
end
