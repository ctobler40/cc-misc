-- Our Passcode
local code = { "6", "5", "4", "0" }
local input = {}

-- Setup
peripheral.find("modem", rednet.open)
local monitor = peripheral.find("monitor")

if not monitor then
    print("No monitor found!")
    return
end

monitor.setTextScale(0.85)
monitor.clear()

-- Constants
local defaultBg = colors.black
local highlightBg = colors.green
local errorBg = colors.red
local textColor = colors.white

-- Helper function to Draw divider lines on monitor
local function drawGridLines()
    monitor.setBackgroundColor(defaultBg)
    monitor.setTextColor(colors.gray)

    -- Horizontal lines
    for _, y in ipairs({6, 11, 16}) do
        monitor.setCursorPos(1, y)
        monitor.write(string.rep("─", 29)) -- Full width divider
    end

    -- Vertical lines at approx. x=10 and x=19
    for y = 2, 20 do
        monitor.setCursorPos(10, y)
        monitor.write("│")
        monitor.setCursorPos(19, y)
        monitor.write("│")
    end
end
drawGridLines()

-- Helper function for displaying buttons
local function drawInputDisplay()
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(colors.gray)
    monitor.setTextColor(colors.white)
    monitor.clearLine()
    monitor.write("Code: ")
    for i = 1, 4 do
        if input[i] then
            monitor.write(input[i])
        else
            monitor.write("_")
        end
    end
end

-- Helper function for error display
local function flashInputError()
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(errorBg)
    monitor.setTextColor(colors.white)
    monitor.clearLine()
    monitor.write("Incorrect!")
    sleep(0.5)
    drawInputDisplay()
end

-- Grid button positions
local grid = {
    { x = 5,  y = 3,  label = "1" },
    { x = 14, y = 3,  label = "2" },
    { x = 23, y = 3,  label = "3" },
    { x = 5,  y = 8,  label = "4" },
    { x = 14, y = 8,  label = "5" },
    { x = 23, y = 8,  label = "6" },
    { x = 5,  y = 13, label = "7" },
    { x = 14, y = 13, label = "8" },
    { x = 23, y = 13, label = "9" },
    { x = 14, y = 18, label = "0" },
    { x = 23, y = 18, label = ">" }, -- "Enter" button
}

-- Draw initial grid
local function drawButton(cell, bg)
    monitor.setBackgroundColor(bg or defaultBg)
    monitor.setTextColor(textColor)
    monitor.setCursorPos(cell.x, cell.y)
    monitor.write(cell.label)
end

for _, cell in ipairs(grid) do
    drawButton(cell)
end

-- Get button index from touch
local function getGridButton(x, y)
    for i, cell in ipairs(grid) do
        local cellX, cellY = cell.x, cell.y
        if math.abs(x - cellX) <= 1 and math.abs(y - cellY) <= 1 then
            return i
        end
    end
    return nil
end

-- Function to reset input
local function resetInput()
    input = {}
    drawInputDisplay()
end

-- Function to compare input with code
local function inputMatchesCode()
    if #input ~= #code then return false end
    for i = 1, #code do
        if input[i] ~= code[i] then return false end
    end
    return true
end

-- Handle touch events
local lastTouch = 0
local cooldown = 0.1

while true do
    local event, side, x, y = os.pullEvent("monitor_touch")
    local now = os.clock()

    if now - lastTouch > cooldown then
        lastTouch = now
        local index = getGridButton(x, y)
        if index then
            local cell = grid[index]
            local label = cell.label
            print("Pressed:", label)

            -- Highlight the pressed button
            drawButton(cell, highlightBg)
            sleep(0.3)
            drawButton(cell)

            if label == ">" then
                if inputMatchesCode() then
                    print("Correct code!")
                    redstone.setAnalogOutput("right", 5)
                else
                    flashInputError()
                    for _, c in ipairs(grid) do
                        drawButton(c)
                    end
                end
                resetInput()
            elseif #input < 4 and tonumber(label) ~= nil then
                table.insert(input, label)
                drawInputDisplay()
            else
                if #input >= 4 then
                    flashInputError()
                    for _, c in ipairs(grid) do
                        drawButton(c)
                    end
                end
            end
        end
    end
end
