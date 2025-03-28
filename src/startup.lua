local owner = "add your username here"

if not os.getComputerLabel() then
    os.setComputerLabel(owner)
end

if os.getComputerLabel() ~= owner then
    term.clear()
    term.setCursorPos(1,1)
    print("Access denied.")
    sleep(2)
    os.shutdown()
    return
end

-- Owner menu
term.clear()
term.setCursorPos(1,1)
print("Welcome, " .. owner)
print("1. Run main.lua")
print("2. Open shell")
print("3. Edit file")
write("Select option (1-3): ")
local choice = read()

if choice == "1" then
    if fs.exists("main.lua") then
        shell.run("main.lua")
    else
        print("main.lua not found.")
    end
elseif choice == "2" then
    shell.run("shell")
elseif choice == "3" then
    write("File to edit: ")
    local filename = read()
    shell.run("edit " .. filename)
else
    print("Invalid choice.")
end
