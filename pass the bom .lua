--[[
    Ultimate "Pass the Bomb" Script
    ====================================
    Features:
    1. Enhanced Auto Pass Bomb logic with nearest player targeting and locking.
    2. Comprehensive UI with OrionLib.
    3. Detailed logs and console for debugging.
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
Toggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red background
Toggle.Position = UDim2.new(0.5, -30, 0, 50) -- Positioned near the top center
Toggle.Size = UDim2.new(0, 60, 0, 60) -- 60x60 pixels
Toggle.Image = "rbxassetid://18594014746" -- Replace with your desired image asset ID
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
    IntroIcon = "rbxassetid://9876543210",  -- Replace with your desired intro icon ID
    Icon = "rbxassetid://9876543210",       -- Replace with your desired window icon ID
})

--========================--
--   GLOBAL VARIABLES     --
--========================--

local AutoPassEnabled = true
local TargetPlayer = nil  -- Variable to store the target player
local PreferredTargets = {"PlayerName1"}  -- Replace with player names you want to prioritize

local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local logs = {}

--========================--
--   PERFORMANCE SETTINGS --
--========================--

local SPIN_RADIUS = 10 -- Radius to detect enemies for spinning
local SPIN_SPEED = 360 -- Rotation speed in degrees per second
local spinning = false -- Flag to control spinning
local AutoPassEnabled = true -- Ensure autopass works when enabled

--========================--
--       CONSOLE TAB      --
--========================--

local ConsoleTab = Window:MakeTab({
    Name = "Console",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local logDisplay

local function refreshLogDisplay()
    if logDisplay then
        local combined = table.concat(logs, "\n")
        logDisplay:Set(combined)
    end
end

local function logMessage(msg)
    table.insert(logs, "[" .. os.date("%X") .. "] " .. tostring(msg))
    refreshLogDisplay()
end

logDisplay = ConsoleTab:AddParagraph("Execution Logs", "")
refreshLogDisplay()

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

    if not TargetPlayer or not TargetPlayer.Character or not TargetPlayer.Character:FindFirstChild("HumanoidRootPart") or TargetPlayer.Character:FindFirstChild("Bomb") then
        TargetPlayer = getNearestPlayer()
    end

    if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("CollisionPart") then
        moveToTarget(TargetPlayer.Character.HumanoidRootPart.Position, function()
            BombEvent:FireServer(TargetPlayer.Character, TargetPlayer.Character.CollisionPart)
            TargetPlayer = nil  -- Reset the target player after passing the bomb
        end)
    end
end

--========================--
--       SPIN LOGIC       --
--========================--

local function areEnemiesNearby()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return false
    end

    local localPos = char.HumanoidRootPart.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and not player.Character:FindFirstChild("Bomb") then
            local distance = (localPos - player.Character.HumanoidRootPart.Position).magnitude
            if distance <= SPIN_RADIUS then
                return true
            end
        end
    end

    return false
end

local function spinCharacter()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local rootPart = char.HumanoidRootPart
    spinning = true

    while spinning do
        rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(SPIN_SPEED * RunService.Heartbeat:Wait()), 0)
    end
end

local function stopSpinning()
    spinning = false
end

--========================--
--      EVENT HANDLERS    --
--========================--

local function onCharacterAdded(character)
    character.ChildAdded:Connect(function(child)
        -- Trigger auto-pass logic and spin when the bomb is added
        if child.Name == "Bomb" and AutoPassEnabled then
            -- Start spinning if enemies are nearby
            if areEnemiesNearby() and not spinning then
                spinCharacter()
            end
            -- Keep passing the bomb while spinning
            while child.Parent == character do
                handleBomb()
                wait(0.1) -- Control loop frequency to avoid lag
            end
            stopSpinning() -- Stop spinning once the bomb is gone
        end
    end)
end

--========================--
--    INITIALIZATION      --
--========================--

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

--========================--
--  GAME LOOP (Optional)  --
--========================--

RunService.Heartbeat:Connect(function()
    if AutoPassEnabled then
        -- Continuously validate bomb passing logic for better responsiveness
        pcall(handleBomb)
    end
end)

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

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

--========================--
--   TOGGLE MENU BUTTON   --
--========================--

Toggle.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
end)

-- Initialize OrionLib UI
OrionLib:Init()
