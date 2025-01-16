-- Create a new ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileScreenGui"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Toggle Button to Open/Close Menu
local Toggle = Instance.new("ImageButton")
Toggle.Name = "Toggle"
Toggle.Parent = ScreenGui
Toggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Toggle.Position = UDim2.new(0, 50, 0, 50)
Toggle.Size = UDim2.new(0, 60, 0, 60)
Toggle.Image = "rbxassetid://18594014746"
Toggle.ScaleType = Enum.ScaleType.Fit

-- Make the button circular
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.5, 0)
Corner.Parent = Toggle

-- Load OrionLib for UI
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/Library-Ui/main/Orion%20Lib%20Transparent%20%20.lua"))()

-- Create a Window for Mobile
local Window = OrionLib:MakeWindow({
    Name = "Yon Menu",
    HidePremium = false,
    IntroText = "Yon Menu",
    SaveConfig = true,
    ConfigFolder = "YonMenu"
})

-- Variables for Toggles and Configurations
local AutoDodgePlayersEnabled = true
local PlayerDodgeDistance = 15
local CollectCoinsEnabled = true
local AntiSlipperyEnabled = false
local RemoveHitboxEnabled = false
local AutoPassEnabled = false
local SecureSpinEnabled = false
local SecureSpinDistance = 5
local DodgeDistance = 10
local SafeArea = {MinX = -100, MaxX = 100, MinZ = -100, MaxZ = 100}

-- Create Tabs in the Menu
local AutomatedTab = Window:MakeTab({Name = "Automated", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local OtherTab = Window:MakeTab({Name = "Others", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local UpdateTab = Window:MakeTab({Name = "Update", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- AUTOMATED FEATURES

-- Section: Auto Dodge
AutomatedTab:AddLabel("Auto Dodge Features"):SetTextColor(Color3.fromRGB(0, 255, 127))
AutomatedTab:AddToggle({
    Name = "Auto Dodge Players",
    Default = true,
    Callback = function(bool)
        AutoDodgePlayersEnabled = bool
    end
})
AutomatedTab:AddSlider({
    Name = "Player Dodge Distance",
    Min = 10,
    Max = 30,
    Default = 15,
    Color = Color3.fromRGB(0, 255, 127),
    Increment = 1,
    ValueName = "studs",
    Callback = function(value)
        PlayerDodgeDistance = value
    end
})

-- Section: Collect Coins
AutomatedTab:AddLabel("Coin Collection"):SetTextColor(Color3.fromRGB(255, 223, 0))
AutomatedTab:AddToggle({
    Name = "Collect Coins",
    Default = true,
    Callback = function(bool)
        CollectCoinsEnabled = bool
    end
})

-- Section: Bomb Handling
AutomatedTab:AddLabel("Bomb Handling"):SetTextColor(Color3.fromRGB(255, 69, 0))
AutomatedTab:AddToggle({
    Name = "Auto Pass Bomb",
    Default = false,
    Callback = function(bool)
        AutoPassEnabled = bool
        if AutoPassEnabled then
            local LocalPlayer = game.Players.LocalPlayer
            local PathfindingService = game:GetService("PathfindingService")
            game:GetService("RunService").Stepped:Connect(function()
                if not AutoPassEnabled then return end
                pcall(function()
                    if LocalPlayer.Backpack:FindFirstChild("Bomb") then
                        LocalPlayer.Backpack:FindFirstChild("Bomb").Parent = LocalPlayer.Character
                    end

                    local Bomb = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Bomb")
                    if Bomb then
                        local BombEvent = Bomb:FindFirstChild("RemoteEvent")
                        local closestPlayer = nil
                        local closestDistance = math.huge

                        for _, player in pairs(game.Players:GetPlayers()) do
                            if player ~= LocalPlayer and player.Character and not player.Character:FindFirstChild("Bomb") then
                                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).magnitude
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestPlayer = player
                                end
                            end
                        end

                        if closestPlayer and closestPlayer.Character then
                            local targetPosition = closestPlayer.Character.HumanoidRootPart.Position
                            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                            if humanoid then
                                local path = PathfindingService:CreatePath({
                                    AgentRadius = 2,
                                    AgentHeight = 5,
                                    AgentCanJump = true,
                                    AgentJumpHeight = 10,
                                    AgentMaxSlope = 45,
                                })
                                path:ComputeAsync(LocalPlayer.Character.HumanoidRootPart.Position, targetPosition)
                                for _, waypoint in ipairs(path:GetWaypoints()) do
                                    humanoid:MoveTo(waypoint.Position)
                                    humanoid.MoveToFinished:Wait()
                                end
                            end
                            BombEvent:FireServer(closestPlayer.Character, closestPlayer.Character:FindFirstChild("CollisionPart"))
                        end
                    end
                end)
            end)
        end
    end
})
AutomatedTab:AddToggle({
    Name = "Secure Spin",
    Default = false,
    Callback = function(bool)
        SecureSpinEnabled = bool
    end
})
AutomatedTab:AddSlider({
    Name = "Secure Spin Distance",
    Min = 1,
    Max = 20,
    Default = 5,
    Color = Color3.fromRGB(255, 69, 0),
    Increment = 1,
    ValueName = "studs",
    Callback = function(value)
        SecureSpinDistance = value
    end
})

-- Section: Miscellaneous
AutomatedTab:AddLabel("Miscellaneous"):SetTextColor(Color3.fromRGB(127, 255, 127))
AutomatedTab:AddToggle({
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

-- OTHER FEATURES

-- Toggle for Anti Slippery
OtherTab:AddLabel("Other Features"):SetTextColor(Color3.fromRGB(0, 191, 255))
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
                            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                        end
                    end
                    wait(0.1)
                end
            end)
        else
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 0.5)
                end
            end
        end
    end
})

-- PATHFINDING AND MOVEMENT LOGIC

local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Helper Function: Check if a position is within the Safe Area
local function isWithinSafeArea(position)
    return position.X >= SafeArea.MinX and position.X <= SafeArea.MaxX
        and position.Z >= SafeArea.MinZ and position.Z <= SafeArea.MaxZ
end

-- Helper Function: Move to a Target Position
local function moveToTarget(targetPosition)
    local humanoid = Character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 10,
        AgentMaxSlope = 45,
    })

    local success, err = pcall(function()
        path:ComputeAsync(Character.HumanoidRootPart.Position, targetPosition)
    end)
    if not success then
        warn("Pathfinding failed: " .. err)
        return
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if CollectCoinsEnabled or AutoDodgePlayersEnabled then
            humanoid:MoveTo(waypoint.Position)
            humanoid.MoveToFinished:Wait()
        else
            break
        end
    end
end

-- Dodge Players with the Bomb
local function dodgePlayers()
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Bomb") then
            local distance = (Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).magnitude
            if distance < closestDistance and distance <= PlayerDodgeDistance then
                closestPlayer = player
                closestDistance = distance
            end
        end
    end

    if closestPlayer then
        local dodgeDirection = (Character.HumanoidRootPart.Position - closestPlayer.Character.HumanoidRootPart.Position).unit * PlayerDodgeDistance
        local targetPosition = Character.HumanoidRootPart.Position + dodgeDirection
        if isWithinSafeArea(targetPosition) then
            moveToTarget(targetPosition)
        end
    end
end

-- Collect Coins Around the Map
local function collectCoins()
    local closestCoin = nil
    local closestDistance = math.huge

    for _, coin in pairs(workspace:GetChildren()) do
        if coin:IsA("Part") and coin.Name == "Coin" then
            local distance = (Character.HumanoidRootPart.Position - coin.Position).magnitude
            if distance < closestDistance and isWithinSafeArea(coin.Position) then
                closestDistance = distance
                closestCoin = coin
            end
        end
    end

    if closestCoin then
        moveToTarget(closestCoin.Position)
    end
end

-- MAIN UPDATE LOOP

RunService.Stepped:Connect(function()
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        if AutoDodgePlayersEnabled then
            pcall(dodgePlayers) -- Safe execution with pcall
        end

        if CollectCoinsEnabled then
            pcall(collectCoins) -- Safe execution with pcall
        end
    end
end)

-- TOGGLE MENU VISIBILITY

Toggle.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
end)

-- Initialize OrionLib UI
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

-- Update Logs
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
UpdateTab:AddLabel("Version 1.7.0:")
UpdateTab:AddLabel("- Added Remove Hitbox feature")
