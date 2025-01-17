local scriptContent = [=[
-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

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

-- Remove existing ScreenGui if necessary
for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name == "EnhancedMenuGui" then
        gui:Destroy()
    end
end

-- Create a new ScreenGui for the enhanced menu
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EnhancedMenuGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Toggle Buttons Data
local ToggleButtonsData = {
    {
        Name = "AutoDodgeToggle",
        Image = "rbxassetid://YourToggleImageID1", -- Replace with your actual image ID
        Tooltip = "Auto Dodge Players",
        Default = true,
    },
    {
        Name = "CollectCoinsToggle",
        Image = "rbxassetid://YourToggleImageID2", -- Replace with your actual image ID
        Tooltip = "Collect Coins",
        Default = true,
    },
    {
        Name = "AutoPassBombToggle",
        Image = "rbxassetid://YourToggleImageID3", -- Replace with your actual image ID
        Tooltip = "Auto Pass Bomb",
        Default = false,
    },
    {
        Name = "ExtraFeatureToggle",
        Image = "rbxassetid://YourToggleImageID4", -- Replace with your actual image ID
        Tooltip = "Extra Feature",
        Default = false,
    },
}

-- Create a Frame to hold all toggle buttons
local ToggleFrame = Instance.new("Frame")
ToggleFrame.Name = "ToggleFrame"
ToggleFrame.Parent = ScreenGui
ToggleFrame.BackgroundTransparency = 1
ToggleFrame.Position = UDim2.new(0.05, 0, 0.25, 0) -- 5% from left, 25% from top
ToggleFrame.Size = UDim2.new(0, 70, 0, #ToggleButtonsData * 70) -- Adjust size based on number of buttons

-- Function to create enhanced toggle buttons
local function createEnhancedToggleButton(data, position)
    local Toggle = Instance.new("ImageButton")
    Toggle.Name = data.Name
    Toggle.Parent = ToggleFrame -- Parent to ToggleFrame instead of ScreenGui
    Toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Toggle.Position = position
    Toggle.Size = UDim2.new(0, 60, 0, 60) -- 60x60 pixels
    Toggle.Image = data.Image
    Toggle.ImageColor3 = data.Default and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    Toggle.ScaleType = Enum.ScaleType.Fit
    Toggle.ImageTransparency = 0.5

    -- Make the Toggle Button Circular
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0.5, 0)
    Corner.Parent = Toggle

    -- Tooltip
    local Tooltip = Instance.new("TextLabel")
    Tooltip.Name = "Tooltip"
    Tooltip.Parent = Toggle
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
    Toggle.MouseEnter:Connect(function()
        Tooltip.Visible = true
        Toggle.ImageTransparency = 0.2
    end)

    Toggle.MouseLeave:Connect(function()
        Tooltip.Visible = false
        Toggle.ImageTransparency = 0.5
    end)

    return Toggle
end

-- Create all toggle buttons within the ToggleFrame
local ToggleButtons = {}
for i, data in ipairs(ToggleButtonsData) do
    ToggleButtons[i] = createEnhancedToggleButton(data, UDim2.new(0, 5, 0, (i-1) * 70))
end

-- Feature Toggles State
local AutoDodgeEnabled = ToggleButtonsData[1].Default
local CollectCoinsEnabled = ToggleButtonsData[2].Default
local AutoPassBombEnabled = ToggleButtonsData[3].Default
local ExtraFeatureEnabled = ToggleButtonsData[4].Default

-- References to Toggle Buttons
local AutoDodgeToggle = ToggleButtons[1]
local CollectCoinsToggle = ToggleButtons[2]
local AutoPassBombToggle = ToggleButtons[3]
local ExtraFeatureToggle = ToggleButtons[4]

-- Function to update the toggle button's color based on its state
local function updateToggleButtonColor(toggleButton, isEnabled)
    toggleButton.ImageColor3 = isEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end

-- Function to handle Auto Dodge Toggle
AutoDodgeToggle.MouseButton1Click:Connect(function()
    AutoDodgeEnabled = not AutoDodgeEnabled
    -- Update button color
    updateToggleButtonColor(AutoDodgeToggle, AutoDodgeEnabled)
    print("Auto Dodge Enabled:", AutoDodgeEnabled)
end)

-- Function to handle Collect Coins Toggle
CollectCoinsToggle.MouseButton1Click:Connect(function()
    CollectCoinsEnabled = not CollectCoinsEnabled
    -- Update button color
    updateToggleButtonColor(CollectCoinsToggle, CollectCoinsEnabled)
    print("Collect Coins Enabled:", CollectCoinsEnabled)
end)

-- Function to handle Auto Pass Bomb Toggle
AutoPassBombToggle.MouseButton1Click:Connect(function()
    AutoPassBombEnabled = not AutoPassBombEnabled
    -- Update button color
    updateToggleButtonColor(AutoPassBombToggle, AutoPassBombEnabled)
    print("Auto Pass Bomb Enabled:", AutoPassBombEnabled)
end)

-- Function to handle Extra Feature Toggle
ExtraFeatureToggle.MouseButton1Click:Connect(function()
    ExtraFeatureEnabled = not ExtraFeatureEnabled
    -- Update button color
    updateToggleButtonColor(ExtraFeatureToggle, ExtraFeatureEnabled)
    print("Extra Feature Enabled:", ExtraFeatureEnabled)
end)

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
    if not AutoDodgeEnabled then return end

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
    if not CollectCoinsEnabled then return end

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
    if not AutoPassBombEnabled then return end

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

-- Main Loop for Automated Features
RunService.RenderStepped:Connect(function()
    dodgePlayers()
    collectCoins()
    passBombIfNeeded()

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
]=]

loadstring(scriptContent)()
