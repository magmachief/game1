--[[
    EnhancedMenuSystem.lua
    Purpose: Revamps the existing Roblox menu by removing old icons and components
             and introducing a new, modular, and optimized menu system.
             
    Author: GitHub Copilot
    Date: 2025-01-17
--]]

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")

-- Variables to hold character references
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Update character references when the player respawns
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- Remove existing ScreenGuis to prevent duplicates
for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and (gui.Name == "EnhancedMenuGui" or gui.Name == "OldMenuGui") then
        gui:Destroy()
    end
end

-- Create a new ScreenGui for the enhanced menu
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EnhancedMenuGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 100 -- Ensures the menu appears above other UI elements

-- Create the main Menu Frame
local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuFrame"
MenuFrame.Parent = ScreenGui
MenuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MenuFrame.BorderSizePixel = 0
MenuFrame.Position = UDim2.new(0.05, 0, 0.2, 0) -- 5% from left, 20% from top
MenuFrame.Size = UDim2.new(0, 80, 0, 300) -- Width:80px, Height:300px
MenuFrame.AnchorPoint = Vector2.new(0, 0)

-- Add a Title to the Menu
local Title = Instance.new("TextLabel")
Title.Parent = MenuFrame
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 50) -- Full width, 50px height
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Title.BackgroundTransparency = 0.2
Title.Text = "Enhanced Menu"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextWrapped = true

-- Create a Separator Line below the Title
local Separator = Instance.new("Frame")
Separator.Parent = MenuFrame
Separator.Name = "Separator"
Separator.Size = UDim2.new(1, 0, 0, 2) -- Full width, 2px height
Separator.Position = UDim2.new(0, 0, 0.166, 0) -- Positioned below the title
Separator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
Separator.BorderSizePixel = 0

-- Toggle Buttons Data
local ToggleButtonsData = {
    {
        Name = "AutoDodgeToggle",
        Icon = "rbxassetid://YourAutoDodgeIconID", -- Replace with your actual image ID
        Tooltip = "Auto Dodge Players",
        Default = true,
        Function = "toggleAutoDodge",
    },
    {
        Name = "CollectCoinsToggle",
        Icon = "rbxassetid://YourCollectCoinsIconID", -- Replace with your actual image ID
        Tooltip = "Collect Coins Automatically",
        Default = true,
        Function = "toggleCollectCoins",
    },
    {
        Name = "AutoPassBombToggle",
        Icon = "rbxassetid://YourAutoPassBombIconID", -- Replace with your actual image ID
        Tooltip = "Auto Pass Bomb to Players",
        Default = false,
        Function = "toggleAutoPassBomb",
    },
    {
        Name = "ExtraFeatureToggle",
        Icon = "rbxassetid://YourExtraFeatureIconID", -- Replace with your actual image ID
        Tooltip = "Extra Feature",
        Default = false,
        Function = "toggleExtraFeature",
    },
}

-- Feature Toggles State
local featureStates = {
    AutoDodgeEnabled = ToggleButtonsData[1].Default,
    CollectCoinsEnabled = ToggleButtonsData[2].Default,
    AutoPassBombEnabled = ToggleButtonsData[3].Default,
    ExtraFeatureEnabled = ToggleButtonsData[4].Default,
}

-- Create a Frame to hold all toggle buttons
local ToggleFrame = Instance.new("Frame")
ToggleFrame.Name = "ToggleFrame"
ToggleFrame.Parent = MenuFrame
ToggleFrame.BackgroundTransparency = 1
ToggleFrame.Position = UDim2.new(0, 0, 0.166, 0) -- Below the separator
ToggleFrame.Size = UDim2.new(1, 0, 0.834, 0) -- Remaining height
ToggleFrame.AutomaticSize = Enum.AutomaticSize.Y

-- Function to create toggle buttons
local function createToggleButton(data, index)
    local button = Instance.new("ImageButton")
    button.Name = data.Name
    button.Parent = ToggleFrame
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.Size = UDim2.new(1, -20, 0, 50) -- Width minus padding, 50px height
    button.Position = UDim2.new(0, 10, 0, (index - 1) * 60 + 10) -- Staggered vertically
    button.Image = data.Icon
    button.ImageColor3 = data.Default and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    button.ScaleType = Enum.ScaleType.Fit
    button.ImageTransparency = 0.1
    button.BorderSizePixel = 0
    button.Active = true
    button.AutoButtonColor = false

    -- Make the button rounded
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0.5, 0)
    UICorner.Parent = button

    -- Tooltip Setup
    local Tooltip = Instance.new("TextLabel")
    Tooltip.Parent = button
    Tooltip.Name = "Tooltip"
    Tooltip.Size = UDim2.new(1, 0, 0.3, 0)
    Tooltip.Position = UDim2.new(0, 0, -0.35, 0)
    Tooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Tooltip.BackgroundTransparency = 0.7
    Tooltip.Text = data.Tooltip
    Tooltip.Font = Enum.Font.GothamBold
    Tooltip.TextSize = 14
    Tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tooltip.TextWrapped = true
    Tooltip.Visible = false

    -- Hover Effects
    button.MouseEnter:Connect(function()
        Tooltip.Visible = true
        button.ImageTransparency = 0.2
    end)

    button.MouseLeave:Connect(function()
        Tooltip.Visible = false
        button.ImageTransparency = 0.1
    end)

    -- Click Event to Toggle Feature
    button.MouseButton1Click:Connect(function()
        -- Toggle the feature state
        featureStates[data.Function == "toggleAutoDodge" and "AutoDodgeEnabled" or 
                      data.Function == "toggleCollectCoins" and "CollectCoinsEnabled" or
                      data.Function == "toggleAutoPassBomb" and "AutoPassBombEnabled" or
                      data.Function == "toggleExtraFeatureEnabled"] = not featureStates[data.Function == "toggleAutoDodge" and "AutoDodgeEnabled" or 
                                                                                       data.Function == "toggleCollectCoins" and "CollectCoinsEnabled" or
                                                                                       data.Function == "toggleAutoPassBomb" and "AutoPassBombEnabled" or
                                                                                       "ExtraFeatureEnabled"]
        
        -- Update button color based on new state
        button.ImageColor3 = featureStates[data.Function == "toggleAutoDodge" and "AutoDodgeEnabled" or 
                                         data.Function == "toggleCollectCoins" and "CollectCoinsEnabled" or
                                         data.Function == "toggleAutoPassBomb" and "AutoPassBombEnabled" or
                                         "ExtraFeatureEnabled"]
        print(data.Tooltip .. " Enabled: " .. tostring(featureStates[data.Function == "toggleAutoDodge" and "AutoDodgeEnabled" or 
                                                                      data.Function == "toggleCollectCoins" and "CollectCoinsEnabled" or
                                                                      data.Function == "toggleAutoPassBomb" and "AutoPassBombEnabled" or
                                                                      "ExtraFeatureEnabled"]))
    end)

    return button
end

-- Create all toggle buttons within the ToggleFrame
for index, data in ipairs(ToggleButtonsData) do
    createToggleButton(data, index)
end

-- Bomb Timer Setup
local playerBombTimers = {}

-- Function to create Bomb Timer GUI for a player
local function createBombTimerGui(player)
    local character = player.Character
    if not character or not character:FindFirstChild("Head") then return end

    -- Check if the player has a Bomb
    local bomb = character:FindFirstChild("Bomb")
    if not bomb then return end

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

-- Function to update Bomb Timer GUI for a player
local function updatePlayerBombTimer(player, timeLeft)
    local timerLabel = playerBombTimers[player]
    if timerLabel then
        timerLabel.Text = "Bomb Timer: " .. tostring(timeLeft) .. "s"
    end
end

-- Function to remove Bomb Timer GUI for a player
local function removeBombTimerGui(player)
    if playerBombTimers[player] then
        playerBombTimers[player]:Destroy()
        playerBombTimers[player] = nil
    end
end

-- Listen for players joining the game
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Wait for the character to fully load
        createBombTimerGui(player)
    end)
end)

-- Listen for players leaving the game
Players.PlayerRemoving:Connect(function(player)
    removeBombTimerGui(player)
end)

-- Initialize Bomb Timer GUI for existing players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        if player.Character and player.Character:FindFirstChild("Bomb") then
            createBombTimerGui(player)
        end
        player.CharacterAdded:Connect(function(character)
            wait(1)
            createBombTimerGui(player)
        end)
    end
end

-- Automated Features Implementation

-- Auto Dodge Function
local function dodgePlayers()
    if not featureStates.AutoDodgeEnabled then return end

    if not Character or not HumanoidRootPart then
        print("Character or HumanoidRootPart not found.")
        return
    end

    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Bomb") then
            local targetCharacter = player.Character
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                local distance = (HumanoidRootPart.Position - targetCharacter.HumanoidRootPart.Position).magnitude
                if distance < closestDistance and distance <= 15 then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    if closestPlayer then
        local targetCharacter = closestPlayer.Character
        if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
            local dodgeDirection = (HumanoidRootPart.Position - targetCharacter.HumanoidRootPart.Position).unit
            local targetPosition = HumanoidRootPart.Position + dodgeDirection * 15

            -- Use Pathfinding to navigate to the target position
            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true,
                AgentMaxSlope = 45,
            })
            path:ComputeAsync(HumanoidRootPart.Position, targetPosition)

            if path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()
                for _, waypoint in ipairs(waypoints) do
                    Humanoid:MoveTo(waypoint.Position)
                    Humanoid.MoveToFinished:Wait()
                end
                print("Dodged player with bomb:", closestPlayer.Name)
            else
                print("Pathfinding failed to find a path for dodging.")
            end
        end
    end
end

-- Collect Coins Function
local function collectCoins()
    if not featureStates.CollectCoinsEnabled then return end

    if not Character or not HumanoidRootPart then
        print("Character or HumanoidRootPart not found.")
        return
    end

    local closestCoin = nil
    local closestDistance = math.huge
    local rootPos = HumanoidRootPart.Position

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
        -- Use Pathfinding to navigate to the coin
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentMaxSlope = 45,
        })
        path:ComputeAsync(HumanoidRootPart.Position, closestCoin.Position)

        if path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            for _, waypoint in ipairs(waypoints) do
                Humanoid:MoveTo(waypoint.Position)
                Humanoid.MoveToFinished:Wait()
            end
            print("Collecting coin at:", closestCoin.Position)
        else
            print("Pathfinding failed to find a path to the coin.")
        end
    end
end

-- Auto Pass Bomb Function
local function passBombIfNeeded()
    if not featureStates.AutoPassBombEnabled then return end

    if not Character then return end

    local bomb = Character:FindFirstChild("Bomb")
    if not bomb then return end

    local bombTimeLeft = bomb:FindFirstChild("BombTimeLeft")
    if not bombTimeLeft then return end

    if bombTimeLeft.Value <= 5 then
        local targetPlayer = nil
        local minDistance = math.huge

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and not player.Character:FindFirstChild("Bomb") then
                local targetCharacter = player.Character
                if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                    local distance = (HumanoidRootPart.Position - targetCharacter.HumanoidRootPart.Position).magnitude
                    if distance < minDistance and distance <= 25 then
                        minDistance = distance
                        targetPlayer = player
                    end
                end
            end
        end

        if targetPlayer then
            local passRemote = bomb:FindFirstChild("PassBombRemote")
            if passRemote then
                passRemote:FireServer(targetPlayer)
                print("Passed bomb to:", targetPlayer.Name)
            else
                print("PassBombRemote not found in Bomb object.")
            end
        else
            print("No suitable target player to pass the bomb.")
        end
    end
end

-- Extra Feature Function (Placeholder)
local function extraFeature()
    if not featureStates.ExtraFeatureEnabled then return end

    -- Implement your extra feature logic here
    print("Extra Feature is enabled and running.")
end

-- Main Loop for Automated Features
RunService.RenderStepped:Connect(function()
    dodgePlayers()
    collectCoins()
    passBombIfNeeded()
    extraFeature()

    -- Update Bomb Timers
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local bomb = char:FindFirstChild("Bomb")
                if bomb and bomb:FindFirstChild("BombTimeLeft") then
                    local timeLeft = bomb.BombTimeLeft.Value
                    updatePlayerBombTimer(player, timeLeft)
                else
                    updatePlayerBombTimer(player, "N/A")
                end
            end
        end
    end
end)
