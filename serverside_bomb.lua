-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for sending bomb info to clients
local BombInfoEvent = Instance.new("RemoteEvent")
BombInfoEvent.Name = "BombInfoEvent"
BombInfoEvent.Parent = ReplicatedStorage

-- Variables
local bomb = nil
local bombHolder = nil
local bombTimer = 0

-- Function to find the bomb in the workspace or on a player
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

-- Function to track bomb and update timer
local function trackBomb()
    bomb, bombHolder = findBomb()
    if bomb then
        if bomb:FindFirstChild("Timer") then
            bombTimer = bomb.Timer.Value -- Use the game's timer if it exists
        else
            bombTimer = 10 -- Fallback to a default timer
        end
    else
        bombHolder = nil
        bombTimer = 0
    end
end

-- Main loop to update bomb information
while true do
    trackBomb()
    if bombHolder then
        BombInfoEvent:FireAllClients(bombHolder, bombTimer)
    else
        BombInfoEvent:FireAllClients(nil, 0) -- No bomb detected
    end
    wait(1) -- Update every second
    if bombTimer > 0 then
        bombTimer = bombTimer - 1
    end
end
