rednet.open("right") -- Open modem
local turtleID = turtle id put here -- Find Turtle

if turtleID then
    local message = {
        command = "mine",
        data = {
            {x, y, z}, -- first location
            {x, y, z}, -- second location
            {x, y, z} -- turtle location
        },
        orientation = "put the current turtle facing",
        chestLocation = {x, y, z} -- put here the location of one block before the chest
    }
    rednet.send(turtleID, message) 
   
else
    print("Error: No minion found!")
end
