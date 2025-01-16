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

-- Load the OrionLib UI Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/Library-Ui/main/Orion%20Lib%20Transparent%20%20.lua"))()

-- Create a window using OrionLib
local Window = OrionLib:MakeWindow({Name = "Yon Menu", HidePremium = false, IntroText = "Yon Menu", SaveConfig = true, ConfigFolder = "YonMenu"})

-- Define variables for toggles
local AutoDodgeEnabled = false
local DodgeDistance = 10 -- Default distance to dodge
local AntiSlipperyEnabled = false
local RemoveHitboxEnabled = false
local AutoPassEnabled = false
local SecureSpinEnabled = false
local SecureSpinDistance = 5 -- Default secure spin distance
local AutoDodgePlayersEnabled = false
local PlayerDodgeDistance = 15 -- Default distance to dodge players
local CollectCoinsEnabled = false
local SafeArea = {MinX = -100, MaxX = 100, MinZ = -100, MaxZ = 100} -- Define a safe area boundary

-- Create tabs for different categories
local VisualTab = Window:MakeTab({Name = "Visual", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local AutomatedTab = Window:MakeTab({Name = "Automated", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local OtherTab = Window:MakeTab({Name = "Others", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- Automated Features

-- Add a toggle for Auto Dodge Meteors
AutomatedTab:AddToggle({
    Name = "Auto Dodge Meteors",
    Default = false,
    Callback = function(bool)
        AutoDodgeEnabled = bool
    end
})

-- Add a slider for Dodge Distance
AutomatedTab:AddSlider({
    Name = "Dodge Distance",
    Min = 5,
    Max = 20,
    Default = 10,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 1,
    ValueName = "studs",
    Callback = function(value)
        DodgeDistance = value
    end
})

-- Add a toggle for Auto Dodge Players
AutomatedTab:AddToggle({
    Name = "Auto Dodge Players",
    Default = false,
    Callback = function(bool)
        AutoDodgePlayersEnabled = bool
    end
})

-- Add a slider for Player Dodge Distance
AutomatedTab:AddSlider({
    Name = "Player Dodge Distance",
    Min = 10,
    Max = 30,
    Default = 15,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 1,
    ValueName = "studs",
    Callback = function(value)
        PlayerDodgeDistance = value
    end
})

-- Add a toggle for Collecting Coins
AutomatedTab:AddToggle({
    Name = "Collect Coins",
    Default = false,
    Callback = function(bool)
        CollectCoinsEnabled = bool
    end
})

-- Add a toggle for Auto Pass Closest Player
AutomatedTab:AddToggle({
    Name = "Auto Pass Closest Player",
    Default = false,
    Callback = function(bool)
        AutoPassEnabled = bool
        if AutoPassEnabled then
            local PathfindingService = game:GetService("PathfindingService")
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

                        -- Find the closest player without a bomb
                        local closestPlayer = nil
                        local closestDistance = math.huge

                        for _, Player in next, game.Players:GetPlayers() do
                            if Player ~= LocalPlayer and Player.Character and Player.Character.Parent == workspace and not Player.Character:FindFirstChild("Bomb") then
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
                            
                            -- Move towards the closest player using pathfinding
                            local targetPosition = closestPlayer.Character.HumanoidRootPart.Position
                            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                            
                            if humanoid then
                                local path = PathfindingService:CreatePath({
                                    AgentRadius = 2,
                                    AgentHeight = 5,
                                    AgentCanJump = true,
                                    AgentJumpHeight = 10,
                                    AgentMaxSlope = 45,
                                    AgentCanClimb = false,
                                    AgentCanSwim = false
                                })
                                path:ComputeAsync(LocalPlayer.Character.HumanoidRootPart.Position, targetPosition)
                                local waypoints = path:GetWaypoints()

                                for _, waypoint in ipairs(waypoints) do
                                    if not AutoPassEnabled then break end
                                    humanoid:MoveTo(waypoint.Position)
                                    humanoid.MoveToFinished:Wait()
                                end
                            end

                            -- Spin when very close to the player
                            local function spinCharacter()
                                local spinTime = 0
                                while (LocalPlayer.Character.HumanoidRootPart.Position - targetPosition).magnitude <= SecureSpinDistance do
                                    if not AutoPassEnabled then break end
                                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(5), 0) -- Less intense spin
                                    wait(0.2) -- Slower spin to seem legit
                                    spinTime = spinTime + 0.2
                                    if spinTime >= 1 then -- Spin for 1 second and then pause
                                        break
                                    end
                                end
                                wait(0.5) -- Wait for 0.5 seconds before resuming spin
                            end

                            -- Check if within range to pass the bomb
                            if (LocalPlayer.Character.HumanoidRootPart.Position - targetPosition).magnitude <= SecureSpinDistance then
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
AutomatedTab:AddToggle({
    Name = "Secure Spin",
    Default = false,
    Callback = function(bool)
        SecureSpinEnabled = bool
    end
})

-- Add a slider for Secure Spin Distance
AutomatedTab:AddSlider({
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

-- Other Features

-- Add a toggle for Anti Slippery
OtherTab:AddToggle({
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
OtherTab:AddToggle({
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

-- Function to dodge meteors
local function dodgeMeteor(meteor)
    local LocalPlayer = game.Players.LocalPlayer
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = Character.HumanoidRootPart
        local dodgeDirection = (humanoidRootPart.Position - meteor.Position).unit * DodgeDistance
        local targetPosition = humanoidRootPart.Position + dodgeDirection

        -- Ensure the target position is within the safe area
        if targetPosition.X >= SafeArea.MinX and targetPosition.X <= SafeArea.MaxX and targetPosition.Z >= SafeArea.MinZ and targetPosition.Z <= SafeArea.MaxZ then
            humanoidRootPart.Parent:FindFirstChild("Humanoid"):MoveTo(targetPosition)
        end
    end
end

-- Detect meteors and dodge them
game.Workspace.ChildAdded:Connect(function(child)
    if not AutoDodgeEnabled then return end
    if child:IsA("Part") and child.Name == "Meteor" then
        child.Touched:Connect(function(hit)
            if hit.Parent == game.Players.LocalPlayer.Character then
                dodgeMeteor(child)
            end
        end)
    end
end)

-- Function to collect coins
local function collectCoins()
    local LocalPlayer = game.Players.LocalPlayer
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local humanoid = Character:FindFirstChild("Humanoid")
        local closestCoin = nil
        local closestDistance = math.huge

        for _, coin in pairs(workspace:GetChildren()) do
            if coin:IsA("Part") and coin.Name == "Coin" then
                local distance = (Character.HumanoidRootPart.Position - coin.Position).magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestCoin = coin
                end
            end
        end

        if closestCoin then
            humanoid:MoveTo(closestCoin.Position)
        end
    end
end

-- Function to dodge players with the bomb
local function dodgePlayer(player)
    local LocalPlayer = game.Players.LocalPlayer
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = Character.HumanoidRootPart
        local dodgeDirection = (humanoidRootPart.Position - player.Character.HumanoidRootPart.Position).unit * PlayerDodgeDistance
        local targetPosition = humanoidRootPart.Position + dodgeDirection

        -- Ensure the target position is within the safe area
        if targetPosition.X >= SafeArea.MinX and targetPosition.X <= SafeArea.MaxX and targetPosition.Z >= SafeArea.MinZ and targetPosition.Z <= SafeArea.MaxZ then
            humanoidRootPart.Parent:FindFirstChild("Humanoid"):MoveTo(targetPosition)
        end
    end
end

-- Detect players with the bomb and dodge them
game:GetService("RunService").Stepped:Connect(function()
    if not AutoDodgePlayersEnabled then return end
    local LocalPlayer = game.Players.LocalPlayer
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        for _, Player in next, game.Players:GetPlayers() do
            if Player ~= LocalPlayer and Player.Character and Player.Character.Parent == workspace then
                if Player.Character:FindFirstChild("Bomb") then
                    local distance = (Character.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).magnitude
                    if distance <= PlayerDodgeDistance then
                        dodgePlayer(Player)
                    end
                end
            end
        end
    end
end)

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
UpdateTab:AddLabel("- Added Auto Dodge Meteors feature")
UpdateTab:AddLabel("Version 1.5.0:")
UpdateTab:AddLabel("- Added Auto Dodge Players feature")
UpdateTab:AddLabel("Version 1.6.0:")
UpdateTab:AddLabel("- Organized features into Visual, Automated, and Others categories")

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

            if closestPlayer and closestDistance <= SecureSpinDistance then
                -- Spin when very close to the player
                local spinTime = 0
                while (LocalPlayer.Character.HumanoidRootPart.Position - closestPlayer.Character.HumanoidRootPart.Position).magnitude <= SecureSpinDistance do
                    if not SecureSpinEnabled then break end
                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(5), 0) -- Less intense spin
                    wait(0.2) -- Slower spin to seem legit
                    spinTime = spinTime + 0.2
                    if spinTime >= 1 then -- Spin for 1 second and then pause
                        break
                    end
                end
                wait(0.5) -- Wait for 0.5 seconds before resuming spin
            end
        end
    end
end)

-- Coin Collection Functionality
game:GetService("RunService").Stepped:Connect(function()
    if CollectCoinsEnabled then
        collectCoins()
    end
end)
