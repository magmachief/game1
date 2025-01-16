local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local head = character:WaitForChild("Head")

-- Create a BillboardGui for the timer
local billboardGui = Instance.new("BillboardGui")
billboardGui.Name = "TimerGui"
billboardGui.Parent = head
billboardGui.Adornee = head
billboardGui.Size = UDim2.new(0, 200, 0, 50)
billboardGui.StudsOffset = Vector3.new(0, 2, 0)
billboardGui.AlwaysOnTop = true

-- Create a TextLabel for the timer
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, 0, 1, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3 = Color3.new(1, 1, 1)
timerLabel.Font = Enum.Font.SourceSans
timerLabel.TextSize = 24
timerLabel.Text = "Time Remaining: 0"
timerLabel.Parent = billboardGui

-- Function to update the timer label
local function updateTimer(bomb)
    local timer = bomb:WaitForChild("Timer", 10) -- Adjust the timeout as needed
    if not timer then return end

    while timer.Value > 0 do
        -- Update the TextLabel with the remaining time
        timerLabel.Text = "Time Remaining: " .. math.floor(timer.Value)
        -- Wait for the next update
        RunService.RenderStepped:Wait()
    end

    -- When the timer reaches zero, display a message
    timerLabel.Text = "Bomb Exploded!"
end

-- Listen for the player receiving the bomb
player.Backpack.ChildAdded:Connect(function(child)
    if child.Name == "Bomb" then
        updateTimer(child)
    end
end)

player.Character.ChildAdded:Connect(function(child)
    if child.Name == "Bomb" then
        updateTimer(child)
    end
end)

-- Listen for character respawn to reattach the BillboardGui
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    head = character:WaitForChild("Head")
    billboardGui.Parent = head
    billboardGui.Adornee = head
end)

-- Create the main GUI
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

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.5, 0) -- Make the button circular
Corner.Parent = Toggle

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/Library-Ui/main/Orion%20Lib%20Transparent%20%20.lua"))()

local Window = OrionLib:MakeWindow({Name = "Yon Menu", HidePremium = false, IntroText = "Yon Menu", SaveConfig = true, ConfigFolder = "YonMenu"})

local AntiSlipperyEnabled = false
local RemoveHitboxEnabled = false
local AutoPassEnabled = false
local SecureSpinEnabled = false
local AutoEmoteEnabled = false
local OwnedEmotes = {}
local SelectedEmote = "/e dance" -- Default emote

local Tab = Window:MakeTab({Name = "Main", Icon = "rbxassetid://4483345998", PremiumOnly = false})

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

Tab:AddToggle({
    Name = "Secure Spin",
    Default = false,
    Callback = function(bool)
        SecureSpinEnabled = bool
    end
})

Tab:AddToggle({
    Name = "Auto Emote on Kill",
    Default = false,
    Callback = function(bool)
        AutoEmoteEnabled = bool
    end
})

Tab:AddDropdown({
    Name = "Select Emote",
    Default = "Dance",
    Options = {"Dance", "Cheer", "Laugh", "Wave"},
    Callback = function(option)
        if option == "Dance" then
            SelectedEmote = "/e dance"
        elseif option == "Cheer" then
            SelectedEmote = "/e cheer"
        elseif option == "Laugh" then
            SelectedEmote = "/e laugh"
        elseif option == "Wave" then
            SelectedEmote = "/e wave"
        end
    end
})

local UpdateTab = Window:MakeTab({Name = "Update", Icon = "rbxassetid://4483345998", PremiumOnly = false})

UpdateTab:AddLabel("Update Logs")
UpdateTab:AddLabel("Version 1.1.0:")
UpdateTab:AddLabel("- Added Auto Emote feature")
UpdateTab:AddLabel("- Improved Secure Spin functionality")
UpdateTab:AddLabel("- Removed bomb color picker")
UpdateTab:AddLabel("- Removed vxghmod button")

Toggle.MouseButton1Click:Connect(function() 
    ScreenGui.Enabled = not ScreenGui.Enabled -- Toggle the visibility of the menu
end)

-- Destroy script when UI is destroyed 
ScreenGui.Destroying:Connect(function() 
    script:Destroy() 
end)

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

            if closestPlayer and closestDistance <= 5 then
                -- Spin when very close to the player
                while (LocalPlayer.Character.HumanoidRootPart.Position - closestPlayer.Character.HumanoidRootPart.Position).magnitude <= 5 do
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
            if AutoEmoteEnabled and player == game.Players.LocalPlayer then
                -- Trigger selected emote
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(SelectedEmote, "All")
            end
        end)
    end)
end

game.Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(game.Players:GetPlayers()) do
    onPlayerAdded(player)
end
