--[[
    "Pass the Bomb" Script - Revised
    ====================================
    Key Fixes & Enhancements:
    
    1) Auto Pass Bomb Reliability:
       - Improved the logic to consistently check and pass the bomb 
         using a continuous loop (RunService) rather than relying on 
         events that might occasionally not fire.
       
    2) Coin Collector Navigation:
       - Ensured that the coin collector uses PathfindingService to
         properly move towards coins.
       
    3) Reworked Auto Dodge:
       - Added a more robust checking method for players with the bomb.
       - Uses Pathfinding to navigate away from bomb carriers when they 
         enter a configured “danger” range.

    Retains:
       - Timer display above the head of the bomb holder in red.
       - Logging system for debugging.
       - UI features with OrionLib (menu toggling, tabs, etc.).

    Usage:
       - Insert this script into a local script environment (e.g.,
         StarterPlayerScripts) or a similar client-side location.
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
Toggle.Image = "rbxassetid://18594014746" -- Replace with your image asset ID
Toggle.ScaleType = Enum.ScaleType.Fit

-- Make the Toggle Button Circular
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.5, 0)
Corner.Parent = Toggle

-- Load OrionLib for UI
local OrionLib = loadstring(
    game:HttpGet("https://raw.githubusercontent.com/magmachief/Library-Ui/main/Orion%20Lib%20Transparent%20%20.lua")
)()

--========================--
--  MAIN WINDOW CREATION  --
--========================--

local Window = OrionLib:MakeWindow({
    Name = "Yon Menu - Revised",
    HidePremium = false,
    IntroEnabled = true,
    IntroText = "Yon Menu",
    SaveConfig = true,
    ConfigFolder = "YonMenu_Advanced",
    IntroIcon = "rbxassetid://9876543210",  -- Change if desired
    Icon = "rbxassetid://9876543210",       -- Change if desired
})

--========================--
--   GLOBAL VARIABLES     --
--========================--

-- Feature Toggles (Configure their defaults here)
local AutoDodgePlayersEnabled = true
local PlayerDodgeDistance = 15
local CollectCoinsEnabled = true
local AutoPassEnabled = true
local UseRandomPassing = false  -- Determines whether to pick a random target or first in list

-- Additional toggles
local PreferredTargets = {"PlayerName1"}  -- Replace with players you want to prioritize
local AntiSlipperyEnabled = false
local RemoveHitboxEnabled = false
local SecureSpinEnabled = false
local SecureSpinDistance = 5

-- Bomb parameters
local BombPassRange = 25
local ShortFuseThreshold = 5 -- If the timer is below this, pass to any player in range

-- Safe area boundaries (optional)
local SafeArea = {
    MinX = -100,
    MaxX = 100,
    MinZ = -100,
    MaxZ = 100
}

-- Roblox Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

-- Track references
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local logs = {}  -- For console logging
local playerBombTimers = {}

--========================--
--   UPDATE / CHANGELOG   --
--========================--

local UpdateLogTab = Window:MakeTab({
    Name = "Updates Log",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

UpdateLogTab:AddParagraph("Latest Changes", [[
1) Improved Auto Pass Bomb reliability with continuous checks.
2) Coin Collector now navigates properly to coins using pathfinding.
3) Enhanced Auto Dodge logic using pathfinding away from bomb carriers.
]])

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
--     BOMB TIMER UI      --
--========================--

local function updatePlayerBombTimer(player, timeLeft)
    local timerLabel = playerBombTimers[player]
    if timerLabel then
        if typeof(timeLeft) == "number" then
            timerLabel.Text = "Bomb Timer: " .. tostring(math.floor(timeLeft)) .. "s"
        else
            timerLabel.Text = "Bomb Timer: N/A"
        end
    end
end

local function removeBombTimerGui(player)
    if playerBombTimers[player] then
        playerBombTimers[player]:Destroy()
        playerBombTimers[player] = nil
        logMessage("Removed Bomb Timer GUI for " .. player.Name)
    end
end

local function createBombTimerGui(player)
    -- Check if the player has a character and a head
    local character = player.Character
    if not (character and character:FindFirstChild("Head")) then
        return
    end

    -- Check if player actually has the bomb
    local bomb = character:FindFirstChild("Bomb")
    if not bomb then
        return
    end

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
    timerLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red text to stand out
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.SourceSansBold
    timerLabel.Text = "Bomb Timer: N/A"

    playerBombTimers[player] = timerLabel

    -- Hook up changes to the bomb's time
    local bombTimeValue = bomb:FindFirstChild("BombTimeLeft")
    if bombTimeValue then
        updatePlayerBombTimer(player, bombTimeValue.Value)
        bombTimeValue.Changed:Connect(function(newTime)
            updatePlayerBombTimer(player, newTime)
            if newTime <= 0 then
                removeBombTimerGui(player)
                logMessage("Bomb timer reached zero for " .. player.Name)
            end
        end)
    end
end

-- Set up event listeners for players
local function onPlayerCharacterAdded(player, character)
    -- Listen for bomb addition
    character.ChildAdded:Connect(function(child)
        if child.Name == "Bomb" then
            task.wait(0.3) -- small delay for bomb properties to load
            createBombTimerGui(player)
            logMessage(player.Name .. " received the bomb!")
        end
    end)

    -- Listen for bomb removal
    character.ChildRemoved:Connect(function(child)
        if child.Name == "Bomb" then
            removeBombTimerGui(player)
            logMessage(player.Name .. " no longer has the bomb!")
        end
    end)
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        onPlayerCharacterAdded(player, character)
    end)
end

-- Connect existing players
for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
    if player.Character then
        onPlayerCharacterAdded(player, player.Character)
        -- If they already have a bomb
        if player.Character:FindFirstChild("Bomb") then
            createBombTimerGui(player)
        end
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
    removeBombTimerGui(player)
end)

--========================--
--   AUTO PASS BOMB LOGIC --
--========================--

-- Utility to find valid targets for bomb passing
local function getValidPlayers(bombTimeLeft)
    local char = LocalPlayer.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then
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
                if dist <= BombPassRange then
                    -- If there's enough time left, consider preferred targets first
                    if bombTimeLeft > ShortFuseThreshold then
                        if table.find(PreferredTargets, player.Name) then
                            table.insert(validPreferred, player)
                        else
                            table.insert(fallbackList, player)
                        end
                    else
                        -- Time is short, pass to anyone
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

    -- Check if local player has the bomb
    local bomb = char:FindFirstChild("Bomb")
    if not bomb then return end

    local bombTimeValue = bomb:FindFirstChild("BombTimeLeft")
    local timeLeft = (bombTimeValue and bombTimeValue.Value) or 9999

    local BombEvent = bomb:FindFirstChild("RemoteEvent")
    if not BombEvent then return end

    local preferred, fallback = getValidPlayers(timeLeft)
    local targetPlayer

    -- If we have valid preferred targets and time left, pass to them
    if #preferred > 0 then
        if UseRandomPassing then
            targetPlayer = preferred[math.random(#preferred)]
        else
            targetPlayer = preferred[1]
        end
    elseif #fallback > 0 then
        if UseRandomPassing then
            targetPlayer = fallback[math.random(#fallback)]
        else
            targetPlayer = fallback[1]
        end
    end

    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("CollisionPart") then
        BombEvent:FireServer(targetPlayer.Character, targetPlayer.Character.CollisionPart)
        logMessage("Passed bomb to " .. targetPlayer.Name)
    end
end

--========================--
--       MOVEMENT UTILS   --
--========================--

local function isWithinSafeArea(position)
    return position.X >= SafeArea.MinX and position.X <= SafeArea.MaxX
       and position.Z >= SafeArea.MinZ and position.Z <= SafeArea.MaxZ
end

-- Pathfinding based MoveTo
local function moveToTarget(destination, callbackOnDone)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    local path = PathfindingService:CreatePath()
    local success, err = pcall(function()
        path:ComputeAsync(char.HumanoidRootPart.Position, destination)
    end)
    if not success then
        logMessage("Pathfinding error: " .. tostring(err))
        return
    end

    local waypoints = path:GetWaypoints()
    for _, waypoint in ipairs(waypoints) do
        humanoid:MoveTo(waypoint.Position)
        local reached = humanoid.MoveToFinished:Wait()
        if not reached then
            logMessage("Failed to reach a waypoint: " .. tostring(waypoint.Position))
            return
        end
    end

    if callbackOnDone then
        callbackOnDone()
    end
end

--========================--
--    REWORKED AUTO DODGE --
--========================--

-- This approach searches for the closest bomb holder and uses pathfinding 
-- to move away from them if they get too close.

local function autoDodgePlayers()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return
    end

    local closestDistance = math.huge
    local bombHolder = nil
    local localPos = char.HumanoidRootPart.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Bomb") then
            local holderRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if holderRoot then
                local dist = (localPos - holderRoot.Position).magnitude
                if dist < closestDistance then
                    closestDistance = dist
                    bombHolder = player
                end
            end
        end
    end

    -- If the bomb holder is within our dodge range, move away
    if bombHolder and closestDistance <= PlayerDodgeDistance then
        logMessage("Dodge triggered! " .. bombHolder.Name .. " is too close.")
        local directionAway = (localPos - bombHolder.Character.HumanoidRootPart.Position).Unit
        local desiredPos = localPos + directionAway * PlayerDodgeDistance

        -- Check if desiredPos is within the safe area; if not, just move anyway or clamp
        if not isWithinSafeArea(desiredPos) then
            -- Optional: clamp the X, Z to safe boundaries
            desiredPos = Vector3.new(
                math.clamp(desiredPos.X, SafeArea.MinX, SafeArea.MaxX),
                desiredPos.Y,
                math.clamp(desiredPos.Z, SafeArea.MinZ, SafeArea.MaxZ)
            )
        end

        moveToTarget(desiredPos)
    end
end

--========================--
--     COIN COLLECTOR     --
--========================--

local function collectCoins()
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local closestCoin
    local minDist = math.huge
    local myPos = rootPart.Position

    for _, item in pairs(workspace:GetDescendants()) do
        if item:IsA("Part") or item:IsA("MeshPart") or item:IsA("UnionOperation") then
            -- If coins have a specific name or tag
            if item.Name == "Coin" then
                local dist = (myPos - item.Position).magnitude
                if dist < minDist then
                    minDist = dist
                    closestCoin = item
                end
            end
        end
    end

    if closestCoin then
        logMessage("Coin found at distance: " .. math.floor(minDist) .. " studs")
        moveToTarget(closestCoin.Position, function()
            -- Small wait to allow for coin pickup
            task.wait(0.25)
            logMessage("Attempted to collect the coin at " .. closestCoin.Name)
        end)
    else
        logMessage("No coins found at the moment.")
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
        logMessage("AutoDodgePlayersEnabled: " .. tostring(bool))
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
        logMessage("PlayerDodgeDistance: " .. tostring(value))
    end
})

AutomatedTab:AddToggle({
    Name = "Collect Coins",
    Default = CollectCoinsEnabled,
    Callback = function(bool)
        CollectCoinsEnabled = bool
        logMessage("CollectCoinsEnabled: " .. tostring(bool))
    end
})

AutomatedTab:AddToggle({
    Name = "Auto Pass Bomb",
    Default = AutoPassEnabled,
    Callback = function(bool)
        AutoPassEnabled = bool
        logMessage("AutoPassEnabled: " .. tostring(bool))
    end
})

AutomatedTab:AddToggle({
    Name = "Use Random Passing",
    Default = UseRandomPassing,
    Callback = function(bool)
        UseRandomPassing = bool
        logMessage("UseRandomPassing: " .. tostring(bool))
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
    Default = SecureSpinEnabled,
    Callback = function(bool)
        SecureSpinEnabled = bool
        logMessage("SecureSpinEnabled: " .. tostring(bool))

        local player = LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()

        if SecureSpinEnabled then
            task.spawn(function()
                while SecureSpinEnabled do
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                        end
                    end
                    task.wait(0.1)
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
        logMessage("SecureSpinDistance: " .. tostring(value))
    end
})

OtherTab:AddToggle({
    Name = "Anti Slippery",
    Default = false,
    Callback = function(bool)
        AntiSlipperyEnabled = bool
        logMessage("AntiSlipperyEnabled: " .. tostring(bool))

        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        if AntiSlipperyEnabled then
            task.spawn(function()
                while AntiSlipperyEnabled do
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                        end
                    end
                    task.wait(0.1)
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
        logMessage("RemoveHitboxEnabled: " .. tostring(bool))

        if RemoveHitboxEnabled then
            local player = LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()

            local function removeCollisionPart(character)
                for _=1, 100 do
                    task.wait()
                    pcall(function()
                        local collisionPart = character:FindFirstChild("CollisionPart")
                        if collisionPart then
                            collisionPart:Destroy()
                            logMessage("Removed CollisionPart for " .. character.Name)
                        end
                    end)
                end
            end

            removeCollisionPart(char)
            player.CharacterAdded:Connect(function(newChar)
                removeCollisionPart(newChar)
            end)
        end
    end
})

--========================--
--   MAIN GAME LOOP       --
--========================--

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    -- 1) Auto Pass Bomb
    if AutoPassEnabled then
        passBombIfNeeded()
    end

    -- 2) Collect Coins
    if CollectCoinsEnabled then
        collectCoins()
    end

    -- 3) Auto Dodge
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
logMessage("Yon Menu - Revised version initialized successfully!")
