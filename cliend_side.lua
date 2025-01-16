-- Load and execute the server-side bomb script from GitHub
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/game1/main/serverside_bomb.lua"))()
end)

if not success then
    warn("Failed to load bomb script: " .. tostring(result))
end

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- UI Setup
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "BombTrackerGui"

local InfoLabel = Instance.new("TextLabel", ScreenGui)
InfoLabel.Size = UDim2.new(0.4, 0, 0.1, 0)
InfoLabel.Position = UDim2.new(0.3, 0, 0.05, 0)
InfoLabel.BackgroundTransparency = 0.5
InfoLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoLabel.Font = Enum.Font.SourceSansBold
InfoLabel.TextScaled = true
InfoLabel.Text = "No Bomb Detected"

-- Listen for Bomb Info Updates
local BombInfoEvent = ReplicatedStorage:WaitForChild("BombInfoEvent")
BombInfoEvent.OnClientEvent:Connect(function(bombHolder, timerValue)
    if bombHolder then
        if bombHolder == Players.LocalPlayer then
            InfoLabel.Text = "You have the bomb! Time left: " .. timerValue .. "s"
        else
            InfoLabel.Text = bombHolder.Name .. " has the bomb: " .. timerValue .. "s"
        end
    else
        InfoLabel.Text = "No Bomb Detected"
    end
end)
