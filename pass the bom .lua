--[[
    Ultimate "Pass the Bomb" Script
    ====================================
    Features:
    1. Enhanced Auto Pass Bomb logic with nearest player targeting.
    2. Comprehensive UI with OrionLib.
--]]

--========================--
--     INITIAL SETUP      --
--========================--

-- Create a ScreenGui for Mobile
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileScreenGui"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Toggle Button to Open/Close Menu
local Toggle = Instance.new("ImageButton")
Toggle.Name = "Toggle"
Toggle.Parent = ScreenGui
Toggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Toggle.Position = UDim2.new(0.5, -30, 0, 50)
Toggle.Size = UDim2.new(0, 60, 0, 60)
Toggle.Image = "rbxassetid://18594014746"
Toggle.ScaleType = Enum.ScaleType.Fit

-- Make the Toggle Button Circular
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.5, 0)
Corner.Parent = Toggle

-- Load OrionLib for UI
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/Library-Ui/main/Orion%20Lib%20Transparent%20%20.lua"))()

--========================--
--  MAIN WINDOW CREATION  --
--========================--

local Window = OrionLib:MakeWindow({
    Name = "Yon Menu - Ultimate",
    HidePremium = false,
    IntroEnabled = true,
    IntroText = "Yon Menu",
    SaveConfig = true,
    ConfigFolder = "YonMenu_Ultimate",
    IntroIcon = "rbxassetid://9876543210",
    Icon = "rbxassetid://9876543210",
})

--========================--
--   GLOBAL VARIABLES     --
--========================--

local AutoPassEnabled = true
local PreferredTargets = {"PlayerName1"}  -- Replace with player names you want to prioritize
local CheckInterval = 0.5  -- Time in seconds between each check

local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--========================--
--   AUTO PASS BOMB LOGIC --
--========================--

local function getNearestPlayer()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local nearestPlayer
    local shortestDistance = math.huge
    local localPos = char.HumanoidRootPart.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and not player.Character:FindFirstChild("Bomb") then
            local distance = (localPos - player.Character.HumanoidRootPart.Position).magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestPlayer = player
            end
        end
    end

    return nearestPlayer
end

local function moveToTarget(targetPosition, callback)
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentMaxSlope = 45,
    })

    path:ComputeAsync(char.HumanoidRootPart.Position, targetPosition)
    local waypoints = path:GetWaypoints()
    
    local function moveToWaypoints(index)
        if index > #waypoints then
            if callback then callback() end
            return
        end
        
        humanoid:MoveTo(waypoints[index].Position)
        humanoid.MoveToFinished:Connect(function(reached)
            if reached then
                moveToWaypoints(index + 1)
            else
                if callback then callback() end
            end
        end)
    end
    
    moveToWaypoints(1)
end

local function passBombIfNeeded()
    local char = LocalPlayer.Character
    if not char then return end

    local bomb = char:FindFirstChild("Bomb")
    if not bomb then return end

    local BombEvent = bomb:FindFirstChild("RemoteEvent")
    if not BombEvent then return end

    local nearestPlayer = getNearestPlayer()
    if nearestPlayer and nearestPlayer.Character and nearestPlayer.Character:FindFirstChild("CollisionPart") then
        moveToTarget(nearestPlayer.Character.HumanoidRootPart.Position, function()
            BombEvent:FireServer(nearestPlayer.Character, nearestPlayer.Character.CollisionPart)
        end)
    end
end

--========================--
--       AUTOMATED TAB    --
--========================--

local AutomatedTab = Window:MakeTab({
    Name = "Automated",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

AutomatedTab:AddToggle({
    Name = "Auto Pass Bomb",
    Default = AutoPassEnabled,
    Callback = function(bool)
        AutoPassEnabled = bool
    end
})

--========================--
--       OTHERS TAB       --
--========================--

local OtherTab = Window:MakeTab({
    Name = "Others",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

OtherTab:AddToggle({
    Name = "Secure Spin",
    Default = false,
    Callback = function(bool)
        SecureSpinEnabled = bool

        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

        if SecureSpinEnabled then
            spawn(function()
                while SecureSpinEnabled do
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                        end
                    end
                    wait(0.1)
                end
            end)
        else
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 0.5)
                end
            end
        end
    end
})

OtherTab:AddSlider({
    Name = "Secure Spin Distance",
    Min = 1,
    Max = 20,
    Default = 5,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 1,
    ValueName = "studs",
    Callback = function(value)
        SecureSpinDistance = value
    end
})

OtherTab:AddToggle({
    Name = "Anti Slippery",
    Default = false,
    Callback = function(bool)
        AntiSlipperyEnabled = bool

        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

        if AntiSlipperyEnabled then
            spawn(function()
                while AntiSlipperyEnabled do
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                        end
                    end
                    wait(0.1)
                end
            end)
        else
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 0.5)
                end
            end
        end
    end
})

OtherTab:AddToggle({
    Name = "Remove Hitbox",
    Default = false,
    Callback = function(bool)
        RemoveHitboxEnabled = bool

        if RemoveHitboxEnabled then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

            local function removeCollisionPart(character)
                for _ = 1, 100 do
                    wait()
                    pcall(function()
                        local collisionPart = character:FindFirstChild("CollisionPart")
                        if collisionPart then
                            collisionPart:Destroy()
                        end
                    end)
                end
            end
            removeCollisionPart(char)

            LocalPlayer.CharacterAdded:Connect(function(character)
                removeCollisionPart(character)
            end)
        end
    end
})

--========================--
--    MAIN GAME LOOP      --
--========================--

local lastCheckTime = 0
RunService.Heartbeat:Connect(function()
    if AutoPassEnabled and tick() - lastCheckTime >= CheckInterval then
        passBombIfNeeded()
        lastCheckTime = tick()
    end
end)

--========================--
--   TOGGLE MENU BUTTON   --
--========================--

Toggle.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
end)

-- Initialize OrionLib UI
OrionLib:Init()
