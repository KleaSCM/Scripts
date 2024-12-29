local evdev = require("evdev")
local posix = require("posix")

-- Map key combinations to actions
local key_actions = {
    ["ctrl+win+1"] = "~/scripts/setup_go_project.sh",
    ["ctrl+win+2"] = "~/scripts/setup_python_project.sh",
    ["ctrl+win+3"] = "~/scripts/setup_flask_project.sh",
    ["ctrl+win+4"] = "~/scripts/setup_cpp_project.sh",
    ["ctrl+win+5"] = "~/scripts/setup_sqlite_db.sh",
}

-- Modifier key states
local key_state = {
    ctrl = false,
    win = false,
    num = nil
}

-- Keycode mapping (may vary by device)
local keymap = {
    [29] = "ctrl",   -- Left Ctrl
    [125] = "win",   -- Left Win (Super key)
    [2] = "1",       -- Number 1
    [3] = "2",       -- Number 2
    [4] = "3",       -- Number 3
    [5] = "4",       -- Number 4
    [6] = "5"        -- Number 5
}

-- Function to execute a script
local function run_action(action)
    if action then
        print("Executing: " .. action)
        posix.system("bash " .. action)
    else
        print("No action mapped to this combination.")
    end
end

-- Monitor key events
local function monitor_keys(device_path)
    print("Keybind manager is running. Listening for key combinations...")

    local device = evdev.Device(device_path)

    for event in device:events() do
        if event.type == evdev.EV_KEY then
            local key = keymap[event.code]

            if key then
                if event.value == 1 then -- Key press
                    if key == "ctrl" then key_state.ctrl = true end
                    if key == "win" then key_state.win = true end
                    if key:match("%d") then key_state.num = key end
                elseif event.value == 0 then -- Key release
                    if key == "ctrl" then key_state.ctrl = false end
                    if key == "win" then key_state.win = false end
                    if key:match("%d") then key_state.num = nil end
                end

                -- Check for key combination
                if key_state.ctrl and key_state.win and key_state.num then
                    local combination = "ctrl+win+" .. key_state.num
                    run_action(key_actions[combination])
                end
            end
        end
    end
end

-- Main
local device_path = "/dev/input/event0" -- Replace with your keyboard's device path

-- Check if the device exists
if not posix.stat(device_path) then
    print("Error: Device not found at " .. device_path)
    os.exit(1)
end

-- Start monitoring
monitor_keys(device_path)
