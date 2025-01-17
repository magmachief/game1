--[[
    Pass the Bomb - Revised Example
    ====================================
    Key Fixes/Changes:
    1) Auto Pass Bomb:
       - Continuously checks if you have the bomb and passes it to a valid target.
    2) Removed Bomb Timer and Collect Coins related code.
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

local PlayerDodgeDistance = 15
local AutoDodgePlayersEnabled = true

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
--    PLAYER CONNECTIONS  --
--========================--

-- Called each time someone's character is added
local function onCharacterAdded(player, character)
    character.ChildAdded:Connect(function(child)
        if child.Name == "Bomb" then
            task.wait(0.3)
            logMessage(player.Name .. " obtained the bomb!")
        end
    end)
    
    character.ChildRemoved:Connect(function(child)
        if child.Name == "Bomb" then
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
            logMessage(p.Name .. " already has the bomb!")
        end
    end
end
Players.PlayerAdded:Connect(onPlayerAdded)

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
    
    -- Dodge bomb carriers
    autoDodgePlayers()
end)

logMessage("Pass the Bomb (Revised) script loaded successfully.")
