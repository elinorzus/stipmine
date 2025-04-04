local webhook = "add your webhook url here"

local message = {}

-- Function to receive info from mineArea
function message.receive(info)
    print(textutils.serialize(info))

    -- Immediately send to Discord
    local payload = textutils.serializeJSON({
        username = "TurtleBot",
        content = type(info) == "table" and textutils.serialize(info) or tostring(info)
    })

    local response = http.post(webhook, payload, {
        ["Content-Type"] = "application/json"
    })

    if response then
        print("Sent to Discord:", payload)
    else
        print("Failed to send message")
    end
end

return message