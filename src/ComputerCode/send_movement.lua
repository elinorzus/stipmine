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
        orientation = "north"
    }
    rednet.send(turtleID, message) 
   
else
    print("Error: No minion found!")
end
