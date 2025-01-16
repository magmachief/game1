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

                        -- Auto-pass the closest player by moving towards them and spinning
                        if closestPlayer then
                            warn("Hitting " .. closestPlayer.Name)
                            
                            -- Move towards the closest player
                            local targetPosition = closestPlayer.Character.HumanoidRootPart.Position
                            local function moveToTarget()
                                while (LocalPlayer.Character.HumanoidRootPart.Position - targetPosition).magnitude > 5 do
                                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, targetPosition)
                                    LocalPlayer.Character:MoveTo(targetPosition)
                                    wait(0.1)
                                end
                            end

                            -- Spin when close to the player
                            local function spinCharacter()
                                while (LocalPlayer.Character.HumanoidRootPart.Position - targetPosition).magnitude <= 5 do
                                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(30), 0)
                                    wait(0.1)
                                end
                            end

                            -- Move to the target and then spin
                            moveToTarget()
                            spinCharacter()

                            -- Fire the bomb event
                            BombEvent:FireServer(closestPlayer.Character, closestPlayer.Character:FindFirstChild("CollisionPart"))
                        else
                            print("No closest player found")
                        end
                    end
                end)
            end)
        end
    end
})

Toggle.MouseButton1Click:Connect(function() 
    ScreenGui.Enabled = not ScreenGui.Enabled -- Toggle the visibility of the menu
end)

-- Destroy script when UI is destroyed 
ScreenGui.Destroying:Connect(function() 
    script:Destroy() 
end)

OrionLib:Init()
