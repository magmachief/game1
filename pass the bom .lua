-- Create a new ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileScreenGui"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Toggle Button to Open/Close Menu
local Toggle = Instance.new("ImageButton")
Toggle.Name = "Toggle"
Toggle.Parent = ScreenGui
Toggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Start with red (off)
Toggle.Position = UDim2.new(0, 50, 0, 50) -- Adjust for mobile screen
Toggle.Size = UDim2.new(0, 60, 0, 60) -- Larger for touch input
Toggle.Image = "rbxassetid://18594014746" -- Your asset ID
Toggle.ScaleType = Enum.ScaleType.Fit

-- Make the button circular
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.5, 0)
Corner.Parent = Toggle

-- Load OrionLib for UI
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/Library-Ui/main/Orion%20Lib%20Transparent%20%20.lua"))()

-- Create a Window for Mobile
local Window = OrionLib:MakeWindow({
    Name = "Yon Menu",
    HidePremium = false,
    IntroText = "Yon Menu",
    SaveConfig = true,
    ConfigFolder = "YonMenu"
})

-- Variables for Toggles and Configurations
local AutoDodgePlayersEnabled = true
local PlayerDodgeDistance = 15
local CollectCoinsEnabled = true
local SafeArea = {MinX = -100, MaxX = 100, MinZ = -100, MaxZ = 100}
local AntiSlipperyEnabled = false
local RemoveHitboxEnabled = false

-- Create Tabs in the Menu
local AutomatedTab = Window:MakeTab({Name = "Automated", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local OtherTab = Window:MakeTab({Name = "Others", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- AUTOMATED FEATURES

-- Toggle for Auto Dodge Players
AutomatedTab:AddToggle({
    Name = "Auto Dodge Players",
    Default = true,
    Callback = function(bool)
        AutoDodgePlayersEnabled = bool
    end
})

-- Slider for Player Dodge Distance
AutomatedTab:AddSlider({
    Name = "Player Dodge Distance",
    Min = 10,
    Max = 30,
    Default = 15,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 1,
    ValueName = "studs",
    Callback = function(value)
        PlayerDodgeDistance = value
    end
})

-- Toggle for Auto Collect Coins
AutomatedTab:AddToggle({
    Name = "Collect Coins",
    Default = true,
    Callback = function(bool)
        CollectCoinsEnabled = bool
    end
})

-- OTHER FEATURES

-- Toggle for Anti Slippery
OtherTab:AddToggle({
    Name = "Anti Slippery",
    Default = false,
    Callback = function(bool)
        AntiSlipperyEnabled = bool
        if AntiSlipperyEnabled then
            spawn(function()
                local player = game.Players.LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                while AntiSlipperyEnabled do
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5) -- Higher friction values
                        end
                    end
                    wait(0.1) -- Adjust the wait time as needed
                end
            end)
        else
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 0.5) -- Default friction values
                end
            end
        end
    end
})

-- Toggle for Remove Hitbox
OtherTab:AddToggle({
    Name = "Remove Hitbox",
    Default = false,
    Callback = function(bool)
        RemoveHitboxEnabled = bool
        if RemoveHitboxEnabled then
            local LocalPlayer = game.Players.LocalPlayer
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local function removeCollisionPart(character)
                for destructionIteration = 1, 100 do
                    wait()
                    pcall(function()
                        character:WaitForChild("CollisionPart"):Destroy()
                        print("No More Hitbox")
                    end)
                end
            end
            removeCollisionPart(Character)
            LocalPlayer.CharacterAdded:Connect(function(character)
                removeCollisionPart(character)
            end)
        end
    end
})

-- PATHFINDING AND MOVEMENT LOGIC

local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Helper Function: Check if a position is within the Safe Area
local function isWithinSafeArea(position)
    return position.X >= SafeArea.MinX and position.X <= SafeArea.MaxX
        and position.Z >= SafeArea.MinZ and position.Z <= SafeArea.MaxZ
end

-- Helper Function: Move to a Target Position
local function moveToTarget(targetPosition)
    local humanoid = Character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 10,
        AgentMaxSlope = 45,
    })

    local success, err = pcall(function()
        path:ComputeAsync(Character.HumanoidRootPart.Position, targetPosition)
    end)
    if not success then
        warn("Pathfinding failed: " .. err)
        return
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if CollectCoinsEnabled or AutoDodgePlayersEnabled then
            humanoid:MoveTo(waypoint.Position)
            humanoid.MoveToFinished:Wait()
        else
            break
        end
    end
end

-- Dodge Players with the Bomb
local function dodgePlayers()
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Bomb") then
            local distance = (Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).magnitude
            if distance < closestDistance and distance <= PlayerDodgeDistance then
                closestPlayer = player
                closestDistance = distance
            end
        end
    end

    if closestPlayer then
        local dodgeDirection = (Character.HumanoidRootPart.Position - closestPlayer.Character.HumanoidRootPart.Position).unit * PlayerDodgeDistance
        local targetPosition = Character.HumanoidRootPart.Position + dodgeDirection
        if isWithinSafeArea(targetPosition) then
            moveToTarget(targetPosition)
        end
    end
end

-- Collect Coins Around the Map
local function collectCoins()
    local closestCoin = nil
    local closestDistance = math.huge

    for _, coin in pairs(workspace:GetChildren()) do
        if coin:IsA("Part") and coin.Name == "Coin" then
            local distance = (Character.HumanoidRootPart.Position - coin.Position).magnitude
            if distance < closestDistance and isWithinSafeArea(coin.Position) then
                closestDistance = distance
                closestCoin = coin
            end
        end
    end

    if closestCoin then
        moveToTarget(closestCoin.Position)
    end
end

-- Main Update Loop
RunService.Stepped:Connect(function()
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        if AutoDodgePlayersEnabled then
            pcall(dodgePlayers) -- Safe execution with pcall
        end

        if CollectCoinsEnabled then
            pcall(collectCoins) -- Safe execution with pcall
        end
    end
end)

-- Toggle Visibility of the Menu
Toggle.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
end)

-- Destroy Script on UI Destruction
ScreenGui.Destroying:Connect(function()
    script:Destroy()
end)

-- Initialize OrionLib UI
OrionLib:Init()
