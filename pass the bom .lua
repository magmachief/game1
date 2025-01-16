-- Create a new ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScreenGui"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Toggle button to open/close the menu
local Toggle = Instance.new("ImageButton")
Toggle.Name = "Toggle"
Toggle.Parent = ScreenGui
Toggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Start with red (off)
Toggle.Position = UDim2.new(0, 120, 0, 30)
Toggle.Size = UDim2.new(0, 50, 0, 50) -- Smaller size for a compact circular button
Toggle.Image = "rbxassetid://18594014746" -- Your asset ID
Toggle.ScaleType = Enum.ScaleType.Fit

-- Make the button circular
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.5, 0)
Corner.Parent = Toggle

-- Load the OrionLib UI Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/Library-Ui/main/Orion%20Lib%20Transparent%20%20.lua"))()

-- Create a window using OrionLib
local Window = OrionLib:MakeWindow({Name = "Yon Menu", HidePremium = false, IntroText = "Yon Menu", SaveConfig = true, ConfigFolder = "YonMenu"})

-- Define variables for toggles
local AutoDodgeEnabled = false
local DodgeDistance = 10 -- Default distance to dodge
local AntiSlipperyEnabled = false
local RemoveHitboxEnabled = false
local AutoPassEnabled = false
local SecureSpinEnabled = false
local SecureSpinDistance = 5 -- Default secure spin distance
local AutoDodgePlayersEnabled = false
local PlayerDodgeDistance = 15 -- Default distance to dodge players
local CollectCoinsEnabled = false
local SafeArea = {MinX = -100, MaxX = 100, MinZ = -100, MaxZ = 100} -- Define a safe area boundary

-- Create tabs for different categories
local VisualTab = Window:MakeTab({Name = "Visual", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local AutomatedTab = Window:MakeTab({Name = "Automated", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local OtherTab = Window:MakeTab({Name = "Others", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- Automated Features

-- Add a toggle for Auto Dodge Meteors
AutomatedTab:AddToggle({
    Name = "Auto Dodge Meteors",
    Default = false,
    Callback = function(bool)
        AutoDodgeEnabled = bool
    end
})

-- Add a slider for Dodge Distance
AutomatedTab:AddSlider({
    Name = "Dodge Distance",
    Min = 5,
    Max = 20,
    Default = 10,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 1,
    ValueName = "studs",
    Callback = function(value)
        DodgeDistance = value
    end
})

-- Add a toggle for Auto Dodge Players
AutomatedTab:AddToggle({
    Name = "Auto Dodge Players",
    Default = false,
    Callback = function(bool)
        AutoDodgePlayersEnabled = bool
    end
})

-- Add a slider for Player Dodge Distance
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

-- Add a toggle for Collecting Coins
AutomatedTab:AddToggle({
    Name = "Collect Coins",
    Default = false,
    Callback = function(bool)
        CollectCoinsEnabled = bool
    end
})

-- Other Features

-- Add a toggle for Anti Slippery
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

-- Add a toggle for Remove Hitbox
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

-- Pathfinding and Movement Logic
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local function isWithinSafeArea(position, safeArea)
    return position.X >= safeArea.MinX and position.X <= safeArea.MaxX
        and position.Z >= safeArea.MinZ and position.Z <= safeArea.MaxZ
end

local function moveToTarget(targetPosition)
    local humanoid = Character:FindFirstChild("Humanoid")
    if humanoid then
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentJumpHeight = 10,
            AgentMaxSlope = 45,
        })

        path:ComputeAsync(Character.HumanoidRootPart.Position, targetPosition)
        local waypoints = path:GetWaypoints()

        for _, waypoint in ipairs(waypoints) do
            if not CollectCoinsEnabled and not AutoDodgePlayersEnabled then break end
            humanoid:MoveTo(waypoint.Position)
            humanoid.MoveToFinished:Wait()
        end
    end
end

local function findAndCollectCoin(safeArea)
    local closestCoin = nil
    local closestDistance = math.huge

    for _, coin in pairs(workspace:GetChildren()) do
        if coin:IsA("Part") and coin.Name == "Coin" then
            local distance = (Character.HumanoidRootPart.Position - coin.Position).magnitude
            if distance < closestDistance and isWithinSafeArea(coin.Position, safeArea) then
                closestDistance = distance
                closestCoin = coin
            end
        end
    end

    if closestCoin then
        moveToTarget(closestCoin.Position)
    end
end

local function dodgePlayersWithBomb(safeArea)
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, Player in pairs(game.Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Bomb") then
            local distance = (Character.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).magnitude
            if distance < closestDistance and distance <= PlayerDodgeDistance then
                closestDistance = distance
                closestPlayer = Player
            end
        end
    end

    if closestPlayer then
        local dodgeDirection = (Character.HumanoidRootPart.Position - closestPlayer.Character.HumanoidRootPart.Position).unit * PlayerDodgeDistance
        local targetPosition = Character.HumanoidRootPart.Position + dodgeDirection
        if isWithinSafeArea(targetPosition, safeArea) then
            moveToTarget(targetPosition)
        end
    end
end

-- Main Loop
RunService.Stepped:Connect(function()
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        if AutoDodgePlayersEnabled then
            dodgePlayersWithBomb(SafeArea)
        end

        if CollectCoinsEnabled then
            findAndCollectCoin(SafeArea)
        end
    end
end)

-- Toggle the visibility of the menu
Toggle.MouseButton1Click:Connect(function() 
    ScreenGui.Enabled = not ScreenGui.Enabled
end)

-- Destroy script when UI is destroyed 
ScreenGui.Destroying:Connect(function() 
    script:Destroy() 
end)

-- Initialize the OrionLib UI
OrionLib:Init()
