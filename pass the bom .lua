-- Create a new ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScreenGui"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Toggle button to open/close the menu
local Toggle = Instance.new("ImageButton")
Toggle.Name = "Toggle"
Toggle.Parent = ScreenGui
Toggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Start with red (off)
Toggle.Position = UDim2.new(0, 120, 0, 30)
Toggle.Size = UDim2.new(0, 50, 0, 50) -- Smaller size for a compact circular button
Toggle.Image = "rbxassetid://18594014746" -- Your asset ID
Toggle.ScaleType = Enum.ScaleType.Fit

-- Make the button circular
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.5, 0)
Corner.Parent = Toggle

-- Create a TextLabel for the timer
local TimerLabel = Instance.new("TextLabel")
TimerLabel.Name = "TimerLabel"
TimerLabel.Parent = ScreenGui
TimerLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TimerLabel.BorderSizePixel = 0
TimerLabel.Position = UDim2.new(0.5, -50, 0.1, 0)
TimerLabel.Size = UDim2.new(0, 100, 0, 50)
TimerLabel.Font = Enum.Font.SourceSansBold
TimerLabel.TextSize = 24
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.Text = "Time: 0s"

-- Load the OrionLib UI Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/Library-Ui/main/Orion%20Lib%20Transparent%20%20.lua"))()

-- Create a window using OrionLib
local Window = OrionLib:MakeWindow({Name = "Yon Menu", HidePremium = false, IntroText = "Yon Menu", SaveConfig = true, ConfigFolder = "YonMenu"})

-- Define variables for toggles
local AntiSlipperyEnabled = false
local RemoveHitboxEnabled = false
local AutoPassEnabled = false
local SecureSpinEnabled = false
local AutoEmoteEnabled = false
local EmoteSlot = 1 -- Default emote slot
local BombTimer = 30 -- Default bomb timer duration
local SecureSpinDistance = 5 -- Default secure spin distance

-- Create a tab for the main features
local Tab = Window:MakeTab({Name = "Main", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- Add a toggle for Anti Slippery
Tab:AddToggle({
    Name = "Anti Slippery",
    Default = false,
    Callback = function(bool)
        AntiSlipperyEnabled = bool
        if AntiSlipperyEnabled then
            spawn(function()
                local player = game.Players.LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                while AntiSlipperyEnabled do
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5) -- Higher friction values
                        end
                    end
                    wait(0.1) -- Adjust the wait time as needed
                end
            end)
        else
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 0.5) -- Default friction values
                end
            end
        end
    end
})

-- Add a toggle for Remove Hitbox
Tab:AddToggle({
    Name = "Remove Hitbox",
    Default = false,
    Callback = function(bool)
        RemoveHitboxEnabled = bool
        if RemoveHitboxEnabled then
            local LocalPlayer = game.Players.LocalPlayer
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local function removeCollisionPart(character)
                for destructionIteration = 1, 100 do
                    wait()
                    pcall(function()
                        character:WaitForChild("CollisionPart"):Destroy()
                        print("No More Hitbox")
                    end)
                end
            end
            removeCollisionPart(Character)
            LocalPlayer.CharacterAdded:Connect(function(character)
                removeCollisionPart(character)
            end)
        end
    end
})

-- Add a toggle for Auto Pass Closest Player
Tab:AddToggle({
    Name = "Auto Pass Closest Player",
    Default = false,
    Callback = function(bool)
        AutoPassEnabled = bool
        if AutoPassEnabled then
            local LocalPlayer = game.Players.LocalPlayer
            local Character = LocalPlayer.Character

            game:GetService("RunService").Stepped:Connect(function()
                if not AutoPassEnabled then return end
                pcall(function()
                    if LocalPlayer.Backpack:FindFirstChild("Bomb") then
                        LocalPlayer.Backpack:FindFirstChild("Bomb").Parent = Character
                    end

                    if LocalPlayer.Character:FindFirstChild("Bomb") then
                        local BombEvent = LocalPlayer.Character:FindFirstChild("Bomb"):FindFirstChild("RemoteEvent")

                        -- Find the closest player
                        local closestPlayer = nil
                        local closestDistance = math.huge

                        for _, Player in next, game.Players:GetPlayers() do
                            if Player ~= LocalPlayer and Player.Character and Player.Character.Parent == workspace then
                                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).magnitude
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestPlayer = Player
                                end
                            end
                        end

                        -- Auto-pass the closest player by moving towards them and spinning when very close
                        if closestPlayer then
                            warn("Hitting " .. closestPlayer.Name)
                            
                            -- Move towards the closest player
                            local targetPosition = closestPlayer.Character.HumanoidRootPart.Position
                            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                            
                            if humanoid then
                                humanoid:MoveTo(targetPosition)
                            end

                            -- Spin when very close to the player
                            local function spinCharacter()
                                while (LocalPlayer.Character.HumanoidRootPart.Position - targetPosition).magnitude <= 5 do
                                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(5), 0) -- Less intense spin
                                    wait(0.2) -- Slower spin to seem legit
                                end
                            end

                            -- Check if within range to pass the bomb
                            if (LocalPlayer.Character.HumanoidRootPart.Position - targetPosition).magnitude <= 5 then
                                spinCharacter()
                                -- Fire the bomb event
                                BombEvent:FireServer(closestPlayer.Character, closestPlayer.Character:FindFirstChild("CollisionPart"))
                            end
                        else
                            print("No closest player found")
                        end
                    end
                end)
            end)
        end
    end
})

-- Add a toggle for Secure Spin
Tab:AddToggle({
    Name = "Secure Spin",
    Default = false,
    Callback = function(bool)
        SecureSpinEnabled = bool
    end
})

-- Add a slider for Secure Spin Distance
Tab:AddSlider({
    Name = "Secure Spin Distance",
    Min = 1,
    Max = 20,
    Default = 5,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 1,
    ValueName = "studs",
    Callback = function(value)
        SecureSpinDistance = value
    end
})

-- Add a toggle for Auto Emote on Kill
Tab:AddToggle({
    Name = "Auto Emote on Kill",
    Default = false,
    Callback = function(bool)
        AutoEmoteEnabled = bool
    end
})

-- Add a dropdown to select an emote slot
Tab:AddDropdown({
    Name = "Select Emote Slot",
    Default = "1",
    Options = {"1", "2", "3", "4", "5", "6", "7", "8", "9"},
    Callback = function(option)
        EmoteSlot = tonumber(option)
    end
})

-- Function to start the bomb timer
local function startBombTimer(duration)
    local timeLeft = duration
    TimerLabel.Text = "Time: " .. timeLeft .. "s"

    while timeLeft > 0 do
        wait(1)
        timeLeft = timeLeft - 1
        TimerLabel.Text = "Time: " .. timeLeft .. "s"
        
        if timeLeft <= 0 then
            TimerLabel.Text = "Boom!"
            -- Add explosion logic here if needed
        end
    end
end

-- Function to update the timer when the player receives the bomb
local function onBombReceived(timeLeft)
    BombTimer = timeLeft
    startBombTimer(BombTimer)
end

-- Simulate receiving the bomb with a RemoteEvent
local BombReceivedEvent = Instance.new("RemoteEvent", game.ReplicatedStorage)
BombReceivedEvent.Name = "BombReceivedEvent"

-- Connect the event to the function
BombReceivedEvent.OnClientEvent:Connect(onBombReceived)

-- Example usage: Simulate receiving the bomb with 20 seconds left
BombReceivedEvent:FireClient(game.Players.LocalPlayer, 20)

-- Create an update tab
local UpdateTab = Window:MakeTab({Name = "Update", Icon = "rbxassetid://4483345998", PremiumOnly = false})

UpdateTab:AddLabel("Update Logs")
UpdateTab:AddLabel("Version 1.1.0:")
UpdateTab:AddLabel("- Added Auto Emote feature")
UpdateTab:AddLabel("- Improved Secure Spin functionality")
UpdateTab:AddLabel("- Removed bomb color picker")
UpdateTab:AddLabel("- Removed vxghmod button")
UpdateTab:AddLabel("Version 1.2.0:")
UpdateTab:AddLabel("- Separated Secure Spin from Auto Pass Bomb")
UpdateTab:AddLabel("- Added emote slot selection for Auto Emote on Kill")
UpdateTab:AddLabel("- Increased spinning distance in Secure Spin")
UpdateTab:AddLabel("Version 1.3.0:")
UpdateTab:AddLabel("- Added slider for Secure Spin Distance")
UpdateTab:AddLabel("Version 1.4.0:")
UpdateTab:AddLabel("- Added visual timer for bomb")

-- Toggle the visibility of the menu
Toggle.MouseButton1Click:Connect(function() 
    ScreenGui.Enabled = not ScreenGui.Enabled
end)

-- Destroy script when UI is destroyed 
ScreenGui.Destroying:Connect(function() 
    script:Destroy() 
end)

-- Initialize the OrionLib UI
OrionLib:Init()

-- Secure Spin Functionality
game:GetService("RunService").Stepped:Connect(function()
    if SecureSpinEnabled then
        local LocalPlayer = game.Players.LocalPlayer
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

        if Character:FindFirstChild("Bomb") then
            local closestPlayer = nil
            local closestDistance = math.huge

            for _, Player in next, game.Players:GetPlayers() do
                if Player ~= LocalPlayer and Player.Character and Player.Character.Parent == workspace then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = Player
                    end
                end
            end

            if closestPlayer and closestDistance <= SecureSpinDistance then -- Use the selected spin distance
                -- Spin when very close to the player
                while (LocalPlayer.Character.HumanoidRootPart.Position - closestPlayer.Character.HumanoidRootPart.Position).magnitude <= SecureSpinDistance do -- Use the selected spin distance
                    if not SecureSpinEnabled then break end
                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(5), 0) -- Less intense spin
                    wait(0.2) -- Slower spin to seem legit
                end
            end
        end
    end
end)

-- Auto Emote on Kill Functionality
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            if AutoEmoteEnabled and character == game.Players.LocalPlayer.Character then
                -- Trigger selected emote slot
                local EmoteEvent = game.ReplicatedStorage:WaitForChild("PerformEmote")
                EmoteEvent:FireServer(EmoteSlot)
            end
        end)
    end)
end

game.Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(game.Players:GetPlayers()) do
    onPlayerAdded(player)
end
