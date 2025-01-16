-- bomb_timer.lua
-- This script runs on the client side to display the remaining time before the bomb explodes

-- Variables
local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local BombName = "Bomb"  -- The name of the bomb part
local TimerLabel = nil  -- Label to display the timer

-- Function to create a UI label to display the timer
local function createTimerLabel()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BombTimerGui"
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    TimerLabel = Instance.new("TextLabel")
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
end

-- Function to update the timer label
local function updateTimerLabel(timeLeft)
    if TimerLabel then
        TimerLabel.Text = "Time: " .. tostring(math.floor(timeLeft)) .. "s"
    end
end

-- Function to track the bomb's timer
local function trackBombTimer(bomb)
    local timerValue = bomb:FindFirstChild("Timer")  -- Assuming the bomb has a Timer value

    if timerValue then
        while timerValue.Value > 0 do
            updateTimerLabel(timerValue.Value)
            wait(1)
        end
        updateTimerLabel(0)
    end
end

-- Listen for the bomb being added to the character
Character.ChildAdded:Connect(function(child)
    if child.Name == BombName then
        trackBombTimer(child)
    end
end)

-- Create the timer label when the script starts
createTimerLabel()

-- Initial check if the bomb is already in the character's hands
if Character:FindFirstChild(BombName) then
    trackBombTimer(Character:FindFirstChild(BombName))
end
