-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Variables
local autoDodgeEnabled = true
local dodgeDistance = 20 -- Distance to maintain from bomb holders
local mapBounds = {MinX = -100, MaxX = 100, MinZ = -100, MaxZ = 100} -- Replace with your map's actual bounds

-- Helper Functions
local function isWithinBounds(position)
    return position.X >= mapBounds.MinX and position.X <= mapBounds.MaxX
        and position.Z >= mapBounds.MinZ and position.Z <= mapBounds.MaxZ
end

local function moveToSafePosition(targetPosition)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 10,
        AgentMaxSlope = 45,
    })

    local success, err = pcall(function()
        path:ComputeAsync(LocalPlayer.Character.HumanoidRootPart.Position, targetPosition)
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

-- Auto Dodge Players with Bombs
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

        local safePosition = LocalPlayer.Character.HumanoidRootPart.Position + safeDirection
        if isWithinBounds(safePosition) then
            moveToSafePosition(safePosition)
        else
            -- Adjust position to stay within bounds
            safePosition = Vector3.new(
                math.clamp(safePosition.X, mapBounds.MinX, mapBounds.MaxX),
                safePosition.Y,
                math.clamp(safePosition.Z, mapBounds.MinZ, mapBounds.MaxZ)
            )
            moveToSafePosition(safePosition)
        end
    end
end

-- Bomb Timer Detection
local function findBomb()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Bomb") then
            return player.Character:FindFirstChild("Bomb"), player
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name == "Bomb" then
            return obj, nil
        end
    end
    return nil, nil
end

local function monitorBombTimer()
    while true do
        local bomb, bombHolder = findBomb()
        if bomb and bomb:FindFirstChild("Timer") then
            print("Bomb Timer: " .. bomb.Timer.Value .. " seconds")
        elseif bombHolder then
            print(bombHolder.Name .. " is holding the bomb, but no timer detected!")
        else
            print("No bomb detected!")
        end
        task.wait(1)
    end
end

-- Main Update Loop
RunService.Heartbeat:Connect(function()
    dodgePlayersWithBomb()
end)

-- Start Bomb Timer Monitoring
monitorBombTimer()
