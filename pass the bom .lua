-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Variables
local autoDodgeEnabled = true
local collectCoinsEnabled = true
local autoPassEnabled = true
local dodgeDistance = 20
local mapBounds = {MinX = -100, MaxX = 100, MinZ = -100, MaxZ = 100}
local stuckCheckInterval = 1
local stuckThreshold = 5
local lastPosition = nil
local stuckTime = 0

-- Helper Functions
local function isWithinBounds(position)
    return position.X >= mapBounds.MinX and position.X <= mapBounds.MaxX
        and position.Z >= mapBounds.MinZ and position.Z <= mapBounds.MaxZ
end

local function moveToSafePosition(targetPosition)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not humanoidRootPart then
        return
    end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 10,
        AgentMaxSlope = 45,
    })

    local success, err = pcall(function()
        path:ComputeAsync(humanoidRootPart.Position, targetPosition)
    end)
    if not success then
        warn("Pathfinding failed: " .. err)
        return
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        humanoid:MoveTo(waypoint.Position)
        humanoid.MoveToFinished:Wait()
    end
end

-- Auto Dodge Bomb Holders
local function dodgePlayersWithBomb()
    if not autoDodgeEnabled then return end

    local bombHolders = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Bomb") then
            table.insert(bombHolders, player)
        end
    end

    if #bombHolders > 0 then
        local safeDirection = Vector3.new(0, 0, 0)
        for _, bombHolder in ipairs(bombHolders) do
            local bombHolderRoot = bombHolder.Character and bombHolder.Character:FindFirstChild("HumanoidRootPart")
            local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if bombHolderRoot and localRoot then
                local direction = (localRoot.Position - bombHolderRoot.Position).Unit * dodgeDistance
                safeDirection = safeDirection + direction
            end
        end

        local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end

        local safePosition = humanoidRootPart.Position + safeDirection
        if isWithinBounds(safePosition) then
            moveToSafePosition(safePosition)
        else
            -- Adjust position to stay within bounds
            safePosition = Vector3.new(
                math.clamp(safePosition.X, mapBounds.MinX, mapBounds.MaxX),
                humanoidRootPart.Position.Y,
                math.clamp(safePosition.Z, mapBounds.MinZ, mapBounds.MaxZ)
            )
            moveToSafePosition(safePosition)
        end
    end
end

-- Anti-Stuck Mechanism
local function unstickPlayer()
    local character = LocalPlayer.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    if lastPosition and humanoidRootPart.Position == lastPosition then
        stuckTime = stuckTime + stuckCheckInterval
        if stuckTime >= stuckThreshold then
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + Vector3.new(0, 10, 0)
            print("Unsticking player...")
            stuckTime = 0
        end
    else
        stuckTime = 0
    end
    lastPosition = humanoidRootPart.Position
end

-- Auto Pass Bomb
local function autoPassBomb()
    if not autoPassEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local closestPlayer, closestDistance = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (humanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if distance < closestDistance and not player.Character:FindFirstChild("Bomb") then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end

    if closestPlayer then
        print("Passing bomb to: " .. closestPlayer.Name)
        -- Simulate passing the bomb
    end
end

-- Coin Collector
local function collectCoins()
    if not collectCoinsEnabled then return end

    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        for _, part in ipairs(workspace:GetChildren()) do
            if part:IsA("Part") and part.Name == "Coin" then
                humanoid:MoveTo(part.Position)
                task.wait(1)
            end
        end
    end
end

-- Main Update Loop
RunService.Heartbeat:Connect(function()
    dodgePlayersWithBomb()
    autoPassBomb()
    unstickPlayer()
    collectCoins()
end)
