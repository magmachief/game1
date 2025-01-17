--[[
    Pass the Bomb - Revised Example
    ====================================
    Key Fixes/Changes:
    1) Coin Collector:
       - Logs only once when a new coin is found (prevents console spam).
       - Improved pathfinding so it doesn’t “drag” the character.
    2) Auto Pass Bomb:
       - Continuously checks if you have the bomb and passes it to a valid target.
    3) Bomb Timer:
       - Correctly retrieves BombTimeLeft and updates the display (no longer "N/A").
--]]

--========================--
--      INITIAL SETUP     --
--========================--

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Settings
local AutoPassEnabled = true
local BombPassRange = 25
local ShortFuseThreshold = 5  -- If bomb timer < 5, pass to any valid target
local UseRandomPassing = false

local CollectCoinsEnabled = true
local PlayerDodgeDistance = 15
local AutoDodgePlayersEnabled = true

-- For coin logging
local coinLogTable = {}  -- Table to track which coins were logged

-- For bomb timer UI
local playerBombTimers = {}

--========================--
--     HELPER FUNCTIONS   --
--========================--

-- Console logging
local function logMessage(msg)
    print("[PassTheBomb] " .. msg)
end

-- Basic pathfinding move function
local function moveToTarget(destination)
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
    
    local success, errorMsg = pcall(function()
        path:ComputeAsync(char.HumanoidRootPart.Position, destination)
    end)
    if not success then
        logMessage("Pathfinding Error: " .. tostring(errorMsg))
        return
    end
    
    local waypoints = path:GetWaypoints()
    for _, waypoint in ipairs(waypoints) do
        humanoid:MoveTo(waypoint.Position)
        local reached = humanoid.MoveToFinished:Wait()
        if not reached then
            logMessage("Could not reach waypoint: " .. tostring(waypoint.Position))
            return
        end
    end
end

--========================--
--    BOMB TIMER LOGIC    --
--========================--

-- Updates the TextLabel with the current bomb time
local function updatePlayerBombTimer(player, timeValue)
    local timerLabel = playerBombTimers[player]
    if timerLabel then
        if typeof(timeValue) == "number" then
            timerLabel.Text = string.format("Bomb Timer: %ds", math.floor(timeValue))
        else
            timerLabel.Text = "Bomb Timer: N/A"
        end
    end
end

-- Removes the billboard GUI for a player
local function removeBombTimerGui(player)
    if playerBombTimers[player] then
        playerBombTimers[player]:Destroy()
        playerBombTimers[player] = nil
        logMessage("Removed Bomb Timer for " .. player.Name)
    end
end

-- Creates a billboard GUI over the player's head if they have a bomb
local function createBombTimerGui(player)
    local character = player.Character
    if not (character and character:FindFirstChild("Head")) then
        return
    end
    local bomb = character:FindFirstChild("Bomb")
    if not bomb then
        return
    end
    
    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BombTimerGui"
    billboard.Parent = character.Head
    billboard.Adornee = character.Head
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    
    -- Label
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Parent = billboard
    timerLabel.Size = UDim2.new(1, 0, 1, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Font = Enum.Font.SourceSansBold
    timerLabel.Text = "Bomb Timer: N/A"
    timerLabel.TextColor3 = Color3.new(1, 0, 0) -- Red
    timerLabel.TextScaled = true
    
    playerBombTimers[player] = timerLabel
    
    -- Listen for changes in bomb's timer
    local bombTimeValue = bomb:FindFirstChild("BombTimeLeft")
    if bombTimeValue then
        -- Immediate display
        updatePlayerBombTimer(player, bombTimeValue.Value)
        
        bombTimeValue.Changed:Connect(function(newValue)
            updatePlayerBombTimer(player, newValue)
            if newValue <= 0 then
                removeBombTimerGui(player)
                logMessage("Bomb Exploded for " .. player.Name)
            end
        end)
    end
end

--========================--
--    PLAYER CONNECTIONS  --
--========================--

-- Called each time someone's character is added
local function onCharacterAdded(player, character)
    character.ChildAdded:Connect(function(child)
        if child.Name == "Bomb" then
            task.wait(0.3)
            createBombTimerGui(player)
            logMessage(player.Name .. " obtained the bomb!")
        end
    end)
    
    character.ChildRemoved:Connect(function(child)
        if child.Name == "Bomb" then
            removeBombTimerGui(player)
            logMessage(player.Name .. " no longer has the bomb!")
        end
    end)
end

-- For new players
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)
end

-- Hook existing and new players
for _, p in pairs(Players:GetPlayers()) do
    onPlayerAdded(p)
    if p.Character then
        onCharacterAdded(p, p.Character)
        if p.Character:FindFirstChild("Bomb") then
            createBombTimerGui(p)
        end
    end
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(p)
    removeBombTimerGui(p)
end)

--========================--
--   AUTO PASS THE BOMB   --
--========================--

-- Returns a list of valid players for passing
local function getPossibleTargets(bombTimeValue)
    local char = LocalPlayer.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then return {} end
    
    local validTargets = {}
    local myPos = char.HumanoidRootPart.Position
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and not plr.Character:FindFirstChild("Bomb") then
            local dist = (myPos - plr.Character.HumanoidRootPart.Position).Magnitude
            if dist <= BombPassRange then
                table.insert(validTargets, plr)
            end
        end
    end
    
    -- If we are close to explosion (bombTimeValue < ShortFuseThreshold), we don’t filter; pass to anyone
    -- otherwise, you could add your "preferred targets" logic here if desired.
    return validTargets
end

local function autoPassBomb()
    if not AutoPassEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local bomb = char:FindFirstChild("Bomb")
    if not bomb then return end
    
    local bombTimeValue = bomb:FindFirstChild("BombTimeLeft")
    local remaining = bombTimeValue and bombTimeValue.Value or 99
    
    -- If bomb has a remote event
    local bombRemote = bomb:FindFirstChild("RemoteEvent")
    if not bombRemote then return end
    
    local targets = getPossibleTargets(remaining)
    if #targets > 0 then
        local targetPlayer
        if UseRandomPassing then
            targetPlayer = targets[math.random(#targets)]
        else
            targetPlayer = targets[1]  -- or your logic for selection
        end
        
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("CollisionPart") then
            bombRemote:FireServer(targetPlayer.Character, targetPlayer.Character.CollisionPart)
            logMessage("Auto-passed bomb to " .. targetPlayer.Name)
        end
    end
end

--========================--
--      COIN COLLECTOR    --
--========================--

local function collectCoins()
    if not CollectCoinsEnabled then return end
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local closestCoin
    local closestDist = math.huge
    
    -- Search for coins
    for _, item in pairs(workspace:GetDescendants()) do
        if (item:IsA("Part") or item:IsA("MeshPart") or item:IsA("UnionOperation")) and item.Name == "Coin" then
            local distance = (root.Position - item.Position).Magnitude
            if distance < closestDist then
                closestDist = distance
                closestCoin = item
            end
        end
    end
    
    if closestCoin then
        -- Log the coin once if we haven't seen it before
        if not coinLogTable[closestCoin] then
            coinLogTable[closestCoin] = true
            logMessage("Found a coin: " .. closestCoin.Name .. " at distance: " .. math.floor(closestDist))
        end
        
        -- Move to the coin
        moveToTarget(closestCoin.Position)
        -- Brief pause to allow pickup
        task.wait(0.25)
    end
end

--========================--
--   AUTO DODGE (OPTION)  --
--========================--

local function autoDodgePlayers()
    if not AutoDodgePlayersEnabled then return end
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Bomb") then
            local theirRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot then
                local distance = (root.Position - theirRoot.Position).Magnitude
                if distance <= PlayerDodgeDistance then
                    logMessage("Dodge triggered! " .. plr.Name .. " is too close with the bomb.")
                    -- Move away from bomb holder
                    local dirAway = (root.Position - theirRoot.Position).Unit
                    local newPos = root.Position + dirAway * PlayerDodgeDistance
                    moveToTarget(newPos)
                    return
                end
            end
        end
    end
end

--========================--
--    MAIN GAME LOOP      --
--========================--

RunService.Heartbeat:Connect(function()
    -- Continuously check for bomb passing
    autoPassBomb()
    
    -- Find & collect coins
    collectCoins()
    
    -- Dodge bomb carriers
    autoDodgePlayers()
end)

logMessage("Pass the Bomb (Revised) script loaded successfully.")
