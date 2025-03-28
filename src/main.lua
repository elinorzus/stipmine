rednet.open("right") -- Replace "right" with the side your modem is on

-- Optional: detect players nearby
local detector = peripheral.find("playerDetector")
local lastPlayers = {}
local announced = {
    joined = {},
    left = {}
}

function comparePlayers(old, new)
    -- fallback if nil
    old = old or {}
    new = new or {}

    local left, joined = {}, {}

    local oldMap = {}
    for _, name in pairs(old) do oldMap[name] = true end

    local newMap = {}
    for _, name in pairs(new) do newMap[name] = true end

    for _, name in pairs(old) do
        if not newMap[name] then table.insert(left, name) end
    end

    for _, name in pairs(new) do
        if not oldMap[name] then table.insert(joined, name) end
    end

    return joined, left
end

function detectPlayers()
    if not detector then
        print("No player detector found")
        return {}
    end

    local messages = {}
    local players = detector.getPlayersInRange(64) or {}
    local joined, left = comparePlayers(lastPlayers, players)

    for _, name in pairs(joined) do
        if not announced.joined[name] then
            table.insert(messages, "Joined: " .. name)
            announced.joined[name] = true
            announced.left[name] = nil
        end
    end

    for _, name in pairs(left) do
        if not announced.left[name] then
            table.insert(messages, "Left: " .. name)
            announced.left[name] = true
            announced.joined[name] = nil
        end
    end

    lastPlayers = players
    return messages
end

-- Replace with your webhook URL:
local webhook = "add your behook url here"

while true do
    sleep(1)
    local messages = detectPlayers()

    for _, message in pairs(messages) do
        local payload = textutils.serializeJSON({
            username = "TurtleBot",
            content = message
        })

        local response = http.post(webhook, payload, {
            ["Content-Type"] = "application/json"
        })

        if response then
            print("Sent to Discord:", message)
        else
            print("Failed to send:", message)
        end
    end
end
