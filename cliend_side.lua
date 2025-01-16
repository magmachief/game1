-- Load and execute the server-side bomb script from GitHub
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/game1/main/serverside_bomb.lua"))()
end)

if not success then
    warn("Failed to load bomb script: " .. tostring(result))
end

-- Client-Side Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Get the RemoteEvent
local BombTimerEvent = ReplicatedStorage:WaitForChild("BombTimerEvent")

-- Create a UI to display the bomb timer
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BombTimerGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Name = "TimerLabel"
TimerLabel.Parent = ScreenGui
TimerLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TimerLabel.BackgroundTransparency = 0.5
TimerLabel.Position = UDim2.new(0.5, -50, 0, 50)
TimerLabel.Size = UDim2.new(0, 100, 0, 50)
TimerLabel.Font = Enum.Font.SourceSans
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.TextSize = 24
TimerLabel.Text = "Time: 0s"

-- Function to update the timer label
local function updateTimerLabel(timeLeft)
    TimerLabel.Text = "Time: " .. tostring(timeLeft) .. "s"
end

-- Listen for the bomb timer event
BombTimerEvent.OnClientEvent:Connect(function(timeLeft)
    updateTimerLabel(timeLeft)
end)
