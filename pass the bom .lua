--========================--
--      INITIAL SETUP     --
--========================--

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Settings
local AutoPassEnabled = true
local BombPassRange = 25
local ShortFuseThreshold = 5 -- If bomb timer < 5, pass to any valid target
local UseRandomPassing = false

local PlayerDodgeDistance = 15
local AutoDodgePlayersEnabled = true

--========================--
--     HELPER FUNCTIONS   --
--========================--

local function logMessage(msg)
    print("[PassTheBomb] " .. tostring(msg))
end

local function moveToTarget(destination)
    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentMaxSlope = 45,
    })

    local success, errorMsg = pcall(function()
        path:ComputeAsync(root.Position, destination)
    end)
    if not success then
        logMessage("Pathfinding Error: " .. tostring(errorMsg))
        return
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        humanoid:MoveTo(waypoint.Position)
        local reached = humanoid.MoveToFinished:Wait()
        if not reached then
            logMessage("Failed to reach waypoint: " .. tostring(waypoint.Position))
            return
        end
    end
end

--========================--
--   AUTO PASS THE BOMB   --
--========================--

local function getPossibleTargets(bombTimeLeft)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return {} end

    local validTargets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local playerRoot = player.Character.HumanoidRootPart
            local distance = (root.Position - playerRoot.Position).Magnitude
            if distance <= BombPassRange and not player.Character:FindFirstChild("Bomb") then
                table.insert(validTargets, player)
            end
        end
    end

    return validTargets
end

local function autoPassBomb()
    if not AutoPassEnabled then return end

    local character = LocalPlayer.Character
    local bomb = character and character:FindFirstChild("Bomb")
    if not bomb then return end

    local bombRemote = bomb:FindFirstChild("RemoteEvent")
    if not bombRemote then
        logMessage("No RemoteEvent found on the bomb!")
        return
    end

    local bombTimeLeft = bomb:FindFirstChild("BombTimeLeft")
    local remainingTime = bombTimeLeft and bombTimeLeft.Value or 99

    local targets = getPossibleTargets(remainingTime)
    if #targets > 0 then
        local targetPlayer
        if UseRandomPassing then
            targetPlayer = targets[math.random(#targets)]
        else
            targetPlayer = targets[1]
        end

        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            bombRemote:FireServer(targetPlayer.Character, targetPlayer.Character.HumanoidRootPart)
            logMessage("Passed bomb to " .. targetPlayer.Name)
        end
    else
        logMessage("No valid targets for bomb passing!")
    end
end

--========================--
--   AUTO DODGE PLAYERS   --
--========================--

local function autoDodgePlayers()
    if not AutoDodgePlayersEnabled then return end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Bomb") then
            local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if playerRoot then
                local distance = (root.Position - playerRoot.Position).Magnitude
                if distance <= PlayerDodgeDistance then
                    logMessage("Dodging " .. player.Name .. " with bomb!")
                    local dodgeDirection = (root.Position - playerRoot.Position).Unit
                    local dodgePosition = root.Position + dodgeDirection * PlayerDodgeDistance
                    moveToTarget(dodgePosition)
                    return
                end
            end
        end
    end
end

--========================--
--      MAIN LOGIC        --
--========================--

RunService.Heartbeat:Connect(function()
    autoPassBomb()
    autoDodgePlayers()
end)

logMessage("Pass the Bomb script loaded successfully.")
