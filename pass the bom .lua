--[[
    Ultimate "Pass the Bomb" Script
    ====================================
    Features:
    1. Enhanced Auto Pass Bomb logic with optional randomization and preferred targets.
    2. Advanced Auto Dodge mechanism.
    3. Comprehensive UI with OrionLib.
    4. Detailed logs and console for debugging.
    5. Modular and optimized code structure.
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

local AutoDodgePlayersEnabled = true
local PlayerDodgeDistance = 15
local AutoPassEnabled = true
local UseRandomPassing = false
local PreferredTargets = {"PlayerName1"}  -- Replace with player names you want to prioritize

local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local logs = {}

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

local function getValidPlayers(bombTimeLeft)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return {}, {}
    end

    local validPreferred = {}
    local fallbackList = {}
    local localPos = char.HumanoidRootPart.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") and not character:FindFirstChild("Bomb") then
                local dist = (localPos - character.HumanoidRootPart.Position).magnitude
                if dist <= 25 then
                    if bombTimeLeft > 5 then
                        if table.find(PreferredTargets, player.Name) then
                            table.insert(validPreferred, player)
                        else
                            table.insert(fallbackList, player)
                        end
                    else
                        table.insert(fallbackList, player)
                    end
                end
            end
        end
    end

    return validPreferred, fallbackList
end

local function passBombIfNeeded()
    local char = LocalPlayer.Character
    if not char then return end

    local bomb = char:FindFirstChild("Bomb")
    if not bomb then return end

    local bombTimeValue = bomb:FindFirstChild("BombTimeLeft")
    local bombTimeLeft = bombTimeValue and bombTimeValue.Value or 9999

    local BombEvent = bomb:FindFirstChild("RemoteEvent")
    if not BombEvent then return end

    local validPreferred, fallbackList = getValidPlayers(bombTimeLeft)

    if #validPreferred > 0 then
        local chosen
        if UseRandomPassing then
            chosen = validPreferred[math.random(#validPreferred)]
        else
            chosen = validPreferred[1]
        end

        if chosen.Character and chosen.Character:FindFirstChild("CollisionPart") then
            BombEvent:FireServer(chosen.Character, chosen.Character.CollisionPart)
            logMessage("Bomb passed to preferred target: " .. chosen.Name)
            return
        end
    end

    if #fallbackList > 0 then
        local fallback
        if UseRandomPassing then
            fallback = fallbackList[math.random(#fallbackList)]
        else
            fallback = fallbackList[1]
        end

        if fallback.Character and fallback.Character:FindFirstChild("CollisionPart") then
            BombEvent:FireServer(fallback.Character, fallback.Character.CollisionPart)
            logMessage("Bomb passed to fallback: " .. fallback.Name)
        end
    end
end

--========================--
--    AUTO DODGE LOGIC    --
--========================--

local function autoDodgePlayers()
    if not AutoDodgePlayersEnabled then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Bomb") then
            local distance = (char.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).magnitude
            if distance < closestDistance and distance <= PlayerDodgeDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end

    if closestPlayer then
        local dodgeDirection = (char.HumanoidRootPart.Position - closestPlayer.Character.HumanoidRootPart.Position).unit
        local targetPosition = char.HumanoidRootPart.Position + dodgeDirection * PlayerDodgeDistance
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentMaxSlope = 45,
        })

        path:ComputeAsync(char.HumanoidRootPart.Position, targetPosition)

        local waypoints = path:GetWaypoints()
        for _, waypoint in ipairs(waypoints) do
            char.Humanoid:MoveTo(waypoint.Position)
            char.Humanoid.MoveToFinished:Wait()
        end

        logMessage("Dodged player with bomb: " .. closestPlayer.Name)
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
    Name = "Auto Dodge Players",
    Default = AutoDodgePlayersEnabled,
    Callback = function(bool)
        AutoDodgePlayersEnabled = bool
        logMessage("AutoDodgePlayersEnabled set to " .. tostring(bool))
    end
})

AutomatedTab:AddSlider({
    Name = "Player Dodge Distance",
    Min = 10,
    Max = 50,
    Default = 15,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 1,
    ValueName = "studs",
    Callback = function(value)
        PlayerDodgeDistance = value
        logMessage("PlayerDodgeDistance set to " .. tostring(value))
    end
})

AutomatedTab:AddToggle({
    Name = "Auto Pass Bomb",
    Default = AutoPassEnabled,
    Callback = function(bool)
        AutoPassEnabled = bool
        logMessage("AutoPassEnabled set to " .. tostring(bool))
    end
})

AutomatedTab:AddToggle({
    Name = "Use Random Passing",
    Default = UseRandomPassing,
    Callback = function(bool)
        UseRandomPassing = bool
        logMessage("UseRandomPassing set to " .. tostring(bool))
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
        logMessage("SecureSpinEnabled set to " .. tostring(bool))

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
        logMessage("SecureSpinDistance set to " .. tostring(value))
    end
})

OtherTab:AddToggle({
    Name = "Anti Slippery",
    Default = false,
    Callback = function(bool)
        AntiSlipperyEnabled = bool
        logMessage("AntiSlipperyEnabled set to " .. tostring(bool))

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
        logMessage("RemoveHitboxEnabled set to " .. tostring(bool))

        if RemoveHitboxEnabled then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

            local function removeCollisionPart(character)
                for _ = 1, 100 do
                    wait()
                    pcall(function()
                        local collisionPart = character:FindFirstChild("CollisionPart")
                        if collisionPart then
                            collisionPart:Destroy()
                            logMessage("CollisionPart destroyed for " .. character.Name)
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

RunService.Heartbeat:Connect(function()
    if AutoPassEnabled then
        passBombIfNeeded()
    end

    if AutoDodgePlayersEnabled then
        autoDodgePlayers()
    end
end)

--========================--
--   TOGGLE MENU BUTTON   --
--========================--

Toggle.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
    logMessage("Menu toggled - Now: " .. (ScreenGui.Enabled and "Visible" or "Hidden"))
end)

-- Initialize OrionLib UI
OrionLib:Init()
logMessage("Yon Menu - Ultimate version initialized successfully!")
