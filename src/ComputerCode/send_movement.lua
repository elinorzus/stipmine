rednet.open("right") -- Open modem
local turtleID1 = 15-- Find Turtle
local turtleID2 = 16-- Find Turtle

if turtleID1 and turtleID2 then
    local message1 = {
        command = "mine",
        -- data = {
        --     {799, 64, 1110}, -- first location
        --     {802, 65, 1113}, -- second location
        --     {802, 65, 1113} -- turtle location
        -- }

        -- data = {
        --     {795, 65, 1115}, -- first location
        --     {791, 64, 1111}, -- second location
        --     {791, 64, 1111} -- turtle location
        -- }

        -- data = {
        --     {809, 65, 1124}, -- first location
        --     {812, 64, 1121}, -- second location
        --     {812, 64, 1121} -- turtle location
        -- }
        -- data = {
        --     {796, 65, 1126}, -- first location
        --     {7793, 64, 1129}, -- second location
        --     {796, 65, 1126} -- turtle location
        -- }
        data = {
            {795,66,1120}, -- first location
            {794, 64, 1124}, -- second location
            {795,66,1120} -- turtle location
        },
        orientation = "west"
    }
    local message2 = {
        command = "mine",
        -- data = {
        --     {799, 64, 1110}, -- first location
        --     {802, 65, 1113}, -- second location
        --     {802, 65, 1113} -- turtle location
        -- }

        -- data = {
        --     {795, 65, 1115}, -- first location
        --     {791, 64, 1111}, -- second location
        --     {791, 64, 1111} -- turtle location
        -- }

        -- data = {
        --     {809, 65, 1124}, -- first location
        --     {812, 64, 1121}, -- second location
        --     {812, 64, 1121} -- turtle location
        -- }
        -- data = {
        --     {796, 65, 1126}, -- first location
        --     {7793, 64, 1129}, -- second location
        --     {796, 65, 1126} -- turtle location
        -- }
        data = {
            {795,66,1120}, -- first location
            {794, 64, 1124}, -- second location
            {794, 64, 1124} -- turtle location
        },
        orientation = "east"
    }
    rednet.send(turtleID2, message2) 
    rednet.send(turtleID1, message1) 
   
else
    print("Error: No minion found!")
end
