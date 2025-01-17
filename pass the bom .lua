-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Remove existing ScreenGui if necessary
for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name == "OldMenuGui" then
        gui:Destroy()
    end
end

-- Create a new ScreenGui for the old menu
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OldMenuGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Create the main Menu Frame
local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuFrame"
MenuFrame.Parent = ScreenGui
MenuFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MenuFrame.Position = UDim2.new(0.1, 0, 0.2, 0) -- 10% from left, 20% from top
MenuFrame.Size = UDim2.new(0, 200, 0, 300) -- Width:200px, Height:300px

-- Add a Title to the Menu
local Title = Instance.new("TextLabel")
Title.Parent = MenuFrame
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 50) -- Full width, 50px height
Title.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
Title.Text = "Game Console"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 24
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextWrapped = true

-- Create a Separator Line below the Title
local Separator = Instance.new("Frame")
Separator.Parent = MenuFrame
Separator.Name = "Separator"
Separator.Size = UDim2.new(1, 0, 0, 2) -- Full width, 2px height
Separator.Position = UDim2.new(0, 0, 0.166, 0) -- Positioned below the title
Separator.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
Separator.BorderSizePixel = 0

-- Create the Console Output Area
local ConsoleOutput = Instance.new("TextBox")
ConsoleOutput.Parent = MenuFrame
ConsoleOutput.Name = "ConsoleOutput"
ConsoleOutput.Position = UDim2.new(0, 10, 0.2, 10) -- 10px padding
ConsoleOutput.Size = UDim2.new(1, -20, 0.6, -20) -- Width minus padding, 60% height
ConsoleOutput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ConsoleOutput.TextColor3 = Color3.fromRGB(255, 255, 255)
ConsoleOutput.Font = Enum.Font.Code
ConsoleOutput.TextSize = 14
ConsoleOutput.TextWrapped = true
ConsoleOutput.MultiLine = true
ConsoleOutput.ReadOnly = true
ConsoleOutput.ClearTextOnFocus = false

-- Create the Input Box for Commands
local CommandInput = Instance.new("TextBox")
CommandInput.Parent = MenuFrame
CommandInput.Name = "CommandInput"
CommandInput.Position = UDim2.new(0, 10, 0.8, -40) -- 10px padding, near bottom
CommandInput.Size = UDim2.new(1, -20, 0, 30) -- Width minus padding, 30px height
CommandInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CommandInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CommandInput.Font = Enum.Font.Code
CommandInput.TextSize = 14
CommandInput.PlaceholderText = "Enter command..."
CommandInput.ClearTextOnFocus = false

-- Function to handle command execution
local function executeCommand(command)
    -- For demonstration, we'll just print the command to the console output
    ConsoleOutput.Text = ConsoleOutput.Text .. "\n> " .. command
    print("Executed command:", command)
    
    -- Add your command handling logic here
end

-- Listen for the Enter key to execute commands
CommandInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local command = CommandInput.Text
        if command ~= "" then
            executeCommand(command)
            CommandInput.Text = ""
        end
    end
end)

-- Automated Features Implementation

-- Feature Toggles State
local AutoDodgeEnabled = false
local CollectCoinsEnabled = false
local AutoPassBombEnabled = false
local ExtraFeatureEnabled = false

-- Function to handle Auto Dodge Toggle
local function toggleAutoDodge()
    AutoDodgeEnabled = not AutoDodgeEnabled
    ConsoleOutput.Text = ConsoleOutput.Text .. "\nAuto Dodge " .. (AutoDodgeEnabled and "Enabled" or "Disabled")
    print("Auto Dodge Enabled:", AutoDodgeEnabled)
end

-- Function to handle Collect Coins Toggle
local function toggleCollectCoins()
    CollectCoinsEnabled = not CollectCoinsEnabled
    ConsoleOutput.Text = ConsoleOutput.Text .. "\nCollect Coins " .. (CollectCoinsEnabled and "Enabled" or "Disabled")
    print("Collect Coins Enabled:", CollectCoinsEnabled)
end

-- Function to handle Auto Pass Bomb Toggle
local function toggleAutoPassBomb()
    AutoPassBombEnabled = not AutoPassBombEnabled
    ConsoleOutput.Text = ConsoleOutput.Text .. "\nAuto Pass Bomb " .. (AutoPassBombEnabled and "Enabled" or "Disabled")
    print("Auto Pass Bomb Enabled:", AutoPassBombEnabled)
end

-- Function to handle Extra Feature Toggle
local function toggleExtraFeature()
    ExtraFeatureEnabled = not ExtraFeatureEnabled
    ConsoleOutput.Text = ConsoleOutput.Text .. "\nExtra Feature " .. (ExtraFeatureEnabled and "Enabled" or "Disabled")
    print("Extra Feature Enabled:", ExtraFeatureEnabled)
end

-- Example Commands Handling
local commands = {
    ["autododge on"] = toggleAutoDodge,
    ["autododge off"] = toggleAutoDodge,
    ["collectcoins on"] = toggleCollectCoins,
    ["collectcoins off"] = toggleCollectCoins,
    ["autopassbomb on"] = toggleAutoPassBomb,
    ["autopassbomb off"] = toggleAutoPassBomb,
    ["extrafeature on"] = toggleExtraFeature,
    ["extrafeature off"] = toggleExtraFeature,
}

-- Modify the executeCommand function to handle commands
local function executeCommand(command)
    -- Log the command
    ConsoleOutput.Text = ConsoleOutput.Text .. "\n> " .. command
    print("Executed command:", command)
    
    -- Handle the command
    local func = commands[command:lower()]
    if func then
        func()
    else
        ConsoleOutput.Text = ConsoleOutput.Text .. "\nUnknown command: " .. command
        print("Unknown command:", command)
    end
end

-- Automated Features Implementation

-- Auto Dodge Function
local function dodgePlayers()
    if not AutoDodgeEnabled then return end

    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Bomb") then
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).magnitude
            if distance < closestDistance and distance <= 15 then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end

    if closestPlayer then
        local dodgeDirection = (LocalPlayer.Character.HumanoidRootPart.Position - closestPlayer.Character.HumanoidRootPart.Position).unit
        local targetPosition = LocalPlayer.Character.HumanoidRootPart.Position + dodgeDirection * 15

        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:MoveTo(targetPosition)
            ConsoleOutput.Text = ConsoleOutput.Text .. "\nDodged player with bomb: " .. closestPlayer.Name
            print("Dodged player with bomb:", closestPlayer.Name)
        end
    end
end

-- Collect Coins Function
local function collectCoins()
    if not CollectCoinsEnabled then return end

    local closestCoin = nil
    local closestDistance = math.huge
    local rootPos = LocalPlayer.Character.HumanoidRootPart.Position

    for _, item in pairs(workspace:GetDescendants()) do
        if (item:IsA("Part") or item:IsA("MeshPart")) and item.Name == "Coin" then
            local distance = (rootPos - item.Position).magnitude
            if distance < closestDistance and distance <= 20 then
                closestDistance = distance
                closestCoin = item
            end
        end
    end

    if closestCoin then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:MoveTo(closestCoin.Position)
            ConsoleOutput.Text = ConsoleOutput.Text .. "\nCollecting coin at: " .. tostring(closestCoin.Position)
            print("Collecting coin at:", closestCoin.Position)
        end
    end
end

-- Auto Pass Bomb Function
local function passBombIfNeeded()
    if not AutoPassBombEnabled then return end

    local bomb = LocalPlayer.Character:FindFirstChild("Bomb")
    if not bomb then return end

    local bombTimeLeft = bomb:FindFirstChild("BombTimeLeft")
    if not bombTimeLeft then return end

    if bombTimeLeft.Value <= 5 then
        local targetPlayer = nil
        local minDistance = math.huge

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and not player.Character:FindFirstChild("Bomb") then
                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).magnitude
                if distance < minDistance and distance <= 25 then
                    minDistance = distance
                    targetPlayer = player
                end
            end
        end

        if targetPlayer then
            local passRemote = bomb:FindFirstChild("PassBombRemote")
            if passRemote then
                passRemote:FireServer(targetPlayer)
                ConsoleOutput.Text = ConsoleOutput.Text .. "\nPassed bomb to: " .. targetPlayer.Name
                print("Passed bomb to:", targetPlayer.Name)
            end
        end
    end
end

-- Main Loop for Automated Features
RunService.RenderStepped:Connect(function()
    dodgePlayers()
    collectCoins()
    passBombIfNeeded()
end)

-- Bomb Timer Setup
local playerBombTimers = {}

local function createBombTimerGui(player)
    local character = player.Character
    if not character or not character:FindFirstChild("Head") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BombTimerGui"
    billboard.Parent = character.Head
    billboard.Adornee = character.Head
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true

    local timerLabel = Instance.new("TextLabel")
    timerLabel.Parent = billboard
    timerLabel.Size = UDim2.new(1, 0, 1, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.SourceSansBold
    timerLabel.Text = "Bomb Timer: N/A"

    playerBombTimers[player] = timerLabel
end

local function updatePlayerBombTimer(player, timeLeft)
    local timerLabel = playerBombTimers[player]
    if timerLabel then
        timerLabel.Text = "Bomb Timer: " .. tostring(timeLeft) .. "s"
    end
end

local function removeBombTimerGui(player)
    if playerBombTimers[player] then
        playerBombTimers[player]:Destroy()
        playerBombTimers[player] = nil
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(1)
        createBombTimerGui(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeBombTimerGui(player)
end)

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        if player.Character then
            createBombTimerGui(player)
        end
        player.CharacterAdded:Connect(function(character)
            wait(1)
            createBombTimerGui(player)
        end)
    end
end
