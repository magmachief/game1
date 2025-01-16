-- Server-Side Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvent for bomb timer
local BombTimerEvent = Instance.new("RemoteEvent")
BombTimerEvent.Name = "BombTimerEvent"
BombTimerEvent.Parent = ReplicatedStorage

-- Function to handle bomb explosion
local function handleBombExplosion(player)
    -- Create a bomb and set its timer
    local bomb = Instance.new("Part")
    bomb.Name = "Bomb"
    bomb.Parent = player.Character
    local timer = Instance.new("IntValue")
    timer.Name = "Timer"
    timer.Value = 10  -- Set initial timer value (e.g., 10 seconds)
    timer.Parent = bomb
    
    -- Start countdown
    while timer.Value > 0 do
        BombTimerEvent:FireClient(player, timer.Value)  -- Send timer value to client
        wait(1)
        timer.Value = timer.Value - 1
    end
    
    -- Bomb explodes
    BombTimerEvent:FireClient(player, 0)  -- Send final timer value to client
    bomb:Destroy()  -- Destroy the bomb (or handle explosion logic)
end

-- Simulate a player receiving the bomb and starting the timer
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        handleBombExplosion(player)
    end)
end)
