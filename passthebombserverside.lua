local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Function to create a BillboardGui and attach it to a player's head
local function createTimerGui(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:WaitForChild("Head")

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "TimerGui"
    billboardGui.Parent = head
    billboardGui.Adornee = head
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.AlwaysOnTop = true

    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, 0, 1, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.TextColor3 = Color3.new(1, 1, 1)
    timerLabel.Font = Enum.Font.SourceSans
    timerLabel.TextSize = 24
    timerLabel.Text = "Time Remaining: 0"
    timerLabel.Parent = billboardGui

    return timerLabel
end

-- Function to update the timer label
local function updateTimer(bomb, timerLabel)
    local timer = bomb:WaitForChild("Timer", 10)
    if not timer then return end

    while timer.Value > 0 do
        timerLabel.Text = "Time Remaining: " .. math.floor(timer.Value)
        RunService.RenderStepped:Wait()
    end

    timerLabel.Text = "Bomb Exploded!"
end

-- Attach the TimerGui to all players
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local timerLabel = createTimerGui(player)

        player.Backpack.ChildAdded:Connect(function(child)
            if child.Name == "Bomb" then
                updateTimer(child, timerLabel)
            end
        end)

        character.ChildAdded:Connect(function(child)
            if child.Name == "Bomb" then
                updateTimer(child, timerLabel)
            end
        end)
    end)
end)

-- Also attach the TimerGui to players already in the game
for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        local timerLabel = createTimerGui(player)

        player.Backpack.ChildAdded:Connect(function(child)
            if child.Name == "Bomb" then
                updateTimer(child, timerLabel)
            end
        end)

        player.Character.ChildAdded:Connect(function(child)
            if child.Name == "Bomb" then
                updateTimer(child, timerLabel)
            end
        end)
    end
end

-- Load the main script
local mainScriptUrl = "https://raw.githubusercontent.com/magmachief/game1/main/pass%20the%20bom%20.lua"
local mainScript = game:HttpGet(mainScriptUrl)
loadstring(mainScript)()
