--[[
    Full "Pass the Bomb" script with new features:
    1. Enhanced Auto Pass Bomb logic with optional randomization and preferred targets
    2. Bomb Timer display
    3. Updates Log in the menu
    4. Console tab to show execution logs
    5. Retains original functionalities (Auto Dodge, Collect Coins, etc.)
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
Toggle.Position = UDim2.new(0, 50, 0, 50)
Toggle.Size = UDim2.new(0, 60, 0, 60)
Toggle.Image = "rbxassetid://18594014746"
Toggle.ScaleType = Enum.ScaleType.Fit

-- Make the toggle button circular
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.5, 0)
Corner.Parent = Toggle

-- Load OrionLib for UI
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/Library-Ui/main/Orion%20Lib%20Transparent%20%20.lua"))()

--========================--
--  MAIN WINDOW CREATION  --
--========================--

local Window = OrionLib:MakeWindow({
    Name = "Yon Menu - Advanced",
    HidePremium = false,
    IntroEnabled = true,
    IntroText = "Yon Menu",
    SaveConfig = true,
    ConfigFolder = "YonMenu_Advanced",
    IntroIcon = "rbxassetid://9876543210",  -- Example icon ID (replace if desired)
    Icon = "rbxassetid://9876543210",       -- Example icon ID (replace if desired)
})

--========================--
--   GLOBAL VARIABLES     --
--========================--

local AutoDodgePlayersEnabled = true
local PlayerDodgeDistance = 15
local CollectCoinsEnabled = true
local AntiSlipperyEnabled = false
local RemoveHitboxEnabled = false
local AutoPassEnabled = false
local UseRandomPassing = false            -- Determines whether to pick a random target or first in list
local PreferredTargets = {"PlayerName1"}  -- List of players you want to target first, if in range
local SecureSpinEnabled = false
local SecureSpinDistance = 5
local DodgeDistance = 10
local SafeArea = {MinX = -100, MaxX = 100, MinZ = -100, MaxZ = 100}

-- Bomb passing range and short fuse threshold
local BombPassRange = 25
local ShortFuseThreshold = 5

-- Services
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

--========================--
--   UPDATE / CHANGELOG   --
--========================--

local UpdateLogTab = Window:MakeTab({
    Name = "Updates Log",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- You can list your version notes or updates here
UpdateLogTab:AddParagraph("Changelog", [[
1. Added random/targeted auto pass logic.
2. Implemented bomb timer display.
3. Introduced a console tab for execution logs.
4. Enhanced user interface with OrionLib advanced features.
]])

--========================--
--       CONSOLE TAB      --
--========================--

local ConsoleTab = Window:MakeTab({
    Name = "Console",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local logs = {}
local logDisplay

-- Helper function to refresh log display
local function refreshLogDisplay()
    if logDisplay then
        -- Rebuild the text from the logs table
        local combined = table.concat(logs, "\n")
        logDisplay:Set(combined)
    end
end

-- Function to log a message to the console
local function logMessage(msg)
    table.insert(logs, "[" .. os.date("%X") .. "] " .. tostring(msg))
    refreshLogDisplay()
end

-- Create a Paragraph for console output
logDisplay = ConsoleTab:AddParagraph("Execution Logs", "")
refreshLogDisplay()

--========================--
--     BOMB TIMER UI      --
--========================--

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Name = "BombTimerLabel"
TimerLabel.Parent = ScreenGui
TimerLabel.Size = UDim2.new(0, 200, 0, 50)
TimerLabel.Position = UDim2.new(0.5, -100, 0, 10)
TimerLabel.BackgroundTransparency = 0.4
TimerLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.TextScaled = true
TimerLabel.Text = "Bomb Timer: N/A"

-- Updates the bomb timer label if a bomb with 'BombTimeLeft' is found
local function updateBombTimer()
    local char = LocalPlayer.Character
    if not char then
        TimerLabel.Text = "Bomb Timer: N/A"
        return
    end
    local Bomb = char:FindFirstChild("Bomb")
    if Bomb and Bomb:FindFirstChild("BombTimeLeft") then
        local timeLeft = Bomb.BombTimeLeft.Value
        TimerLabel.Text = "Bomb Timer: " .. tostring(timeLeft) .. "s"
    else
        TimerLabel.Text = "Bomb Timer: N/A"
    end
end

--========================--
--   AUTO PASS BOMB LOGIC --
--========================--

-- Returns two lists: valid preferred targets, plus fallback players within range
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
                if dist <= BombPassRange then
                    -- If there's plenty of time, prefer specific targets
                    if bombTimeLeft > ShortFuseThreshold then
                        if table.find(PreferredTargets, player.Name) then
                            table.insert(validPreferred, player)
                        else
                            table.insert(fallbackList, player)
                        end
                    else
                        -- If time is short, treat everyone as fallback
                        table.insert(fallbackList, player)
                    end
                end
            end
        end
    end

    return validPreferred, fallbackList
end

local isSpinning = false -- A flag to manage spinning state

local function passBombIfNeeded()
    local char = LocalPlayer.Character
    if not char then return end

    local bomb = char:FindFirstChild("Bomb")
    if not bomb then return end

    -- Bomb RemoteEvent
    local BombEvent = bomb:FindFirstChild("RemoteEvent")
    if not BombEvent then return end

    local validPreferred, fallbackList = getValidPlayers()
    local target = nil

    -- Decide target based on preference or fallback
    if #validPreferred > 0 then
        if UseRandomPassing then
            target = validPreferred[math.random(#validPreferred)]
        else
            target = validPreferred[1]
        end
    elseif #fallbackList > 0 then
        if UseRandomPassing then
            target = fallbackList[math.random(#fallbackList)]
        else
            target = fallbackList[1]
        end
    end

    -- Spin logic: Spin only if a target is nearby and the bomb is held
    local function startSpinning()
        if isSpinning then return end -- Prevent multiple spin loops
        isSpinning = true
        spawn(function()
            while isSpinning and char and bomb and target do
                local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
                local targetPart = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart and targetPart then
                    -- Slightly adjust the facing direction towards the target while allowing movement
                    local lookVector = (targetPart.Position - humanoidRootPart.Position).unit
                    humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(
                        CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + lookVector),
                        0.2 -- Adjust this value for smoother or quicker turning
                    )
                    -- Add a spin for effect
                    humanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(10), 0) -- Adjust spin speed here
                end
                wait(0.05) -- Frequency of the spin
            end
        end)
    end

    -- Stop spinning function
    local function stopSpinning()
        isSpinning = false -- This will stop the spin loop
    end

    -- Pass the bomb if a valid target is found
    if target and target.Character and target.Character:FindFirstChild("CollisionPart") then
        startSpinning() -- Start spinning when near a valid target and bomb is held

        -- Fire the server event to pass the bomb
        BombEvent:FireServer(target.Character, target.Character.CollisionPart)
        logMessage("Bomb passed to: " .. target.Name)

        stopSpinning() -- Stop spinning after passing the bomb
    else
        logMessage("No valid target found to pass the bomb.")
        stopSpinning() -- Ensure spinning stops if no valid target is found
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

-- Auto Dodge Players
AutomatedTab:AddToggle({
    Name = "Auto Dodge Players",
    Default = AutoDodgePlayersEnabled,
    Callback = function(bool)
        AutoDodgePlayersEnabled = bool
        logMessage("AutoDodgePlayersEnabled set to " .. tostring(bool))
    end
})

-- Slider for Distance
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
        logMessage("PlayerDodgeDistance set to " .. tostring(value))
    end
})

-- Collect Coins
AutomatedTab:AddToggle({
    Name = "Collect Coins",
    Default = CollectCoinsEnabled,
    Callback = function(bool)
        CollectCoinsEnabled = bool
        logMessage("CollectCoinsEnabled set to " .. tostring(bool))
    end
})

-- Auto Pass Bomb
AutomatedTab:AddToggle({
    Name = "Auto Pass Bomb",
    Default = AutoPassEnabled,
    Callback = function(bool)
        AutoPassEnabled = bool
        logMessage("AutoPassEnabled set to " .. tostring(bool))
    end
})

-- Random / Preferred Passing Toggle
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

-- Secure Spin
OtherTab:AddToggle({
    Name = "Secure Spin",
    Default = SecureSpinEnabled,
    Callback = function(bool)
        SecureSpinEnabled = bool
        logMessage("SecureSpinEnabled set to " .. tostring(bool))
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

-- Anti Slippery
OtherTab:AddToggle({
    Name = "Anti Slippery",
    Default = false,
    Callback = function(bool)
        AntiSlipperyEnabled = bool
        logMessage("AntiSlipperyEnabled set to " .. tostring(bool))

        local player = LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()

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

-- Remove Hitbox
OtherTab:AddToggle({
    Name = "Remove Hitbox",
    Default = false,
    Callback = function(bool)
        RemoveHitboxEnabled = bool
        logMessage("RemoveHitboxEnabled set to " .. tostring(bool))

        if RemoveHitboxEnabled then
            local player = LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            
            local function removeCollisionPart(character)
                for _ = 1, 100 do
                    wait()
                    pcall(function()
                        character:WaitForChild("CollisionPart"):Destroy()
                    end)
                end
            end
            removeCollisionPart(char)
            
            player.CharacterAdded:Connect(function(character)
                removeCollisionPart(character)
            end)
        end
    end
})

--========================--
--     HELPER FUNCTIONS   --
--========================--

-- Check if a position is within the Safe Area
local function isWithinSafeArea(position)
    return position.X >= SafeArea.MinX and position.X <= SafeArea.MaxX
       and position.Z >= SafeArea.MinZ and position.Z <= SafeArea.MaxZ
end

-- Move to Target via Pathfinding
local function moveToTarget(targetPosition)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 10,
        AgentMaxSlope = 45,
    })

    local success, err = pcall(function()
        path:ComputeAsync(char.HumanoidRootPart.Position, targetPosition)
    end)
    if not success then
        warn("Pathfinding failed: " .. err)
        logMessage("Pathfinding Error: " .. tostring(err))
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

-- Dodge players with the bomb
local function dodgePlayers()
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
        -- Move in the opposite direction
        local dodgeDirection = (char.HumanoidRootPart.Position - closestPlayer.Character.HumanoidRootPart.Position).unit
        local targetPosition = char.HumanoidRootPart.Position + dodgeDirection * PlayerDodgeDistance
        if isWithinSafeArea(targetPosition) then
            moveToTarget(targetPosition)
            logMessage("Dodged player with bomb: " .. closestPlayer.Name)
        end
    end
end

-- Collect coins
local function collectCoins()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local closestCoin = nil
    local closestDistance = math.huge

    for _, coin in pairs(workspace:GetChildren()) do
        if coin:IsA("Part") and coin.Name == "Coin" then
            local distance = (char.HumanoidRootPart.Position - coin.Position).magnitude
            if distance < closestDistance and isWithinSafeArea(coin.Position) then
                closestDistance = distance
                closestCoin = coin
            end
        end
    end

    if closestCoin then
        moveToTarget(closestCoin.Position)
        logMessage("Moved to collect coin at distance: " .. math.floor(closestDistance))
    end
end

--========================--
--       MAIN LOOP        --
--========================--

RunService.Stepped:Connect(function()
    -- Update Bomb Timer every frame
    updateBombTimer()

    if Character and Character:FindFirstChild("HumanoidRootPart") then
        -- Auto Dodge
        if AutoDodgePlayersEnabled then
            pcall(dodgePlayers)
        end

        -- Collect Coins
        if CollectCoinsEnabled then
            pcall(collectCoins)
        end

        -- Auto Pass Bomb
        if AutoPassEnabled then
            pcall(passBombIfNeeded)
        end
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
logMessage("Yon Menu Initialized Successfully")
