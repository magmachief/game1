--[[
    Enhanced Roblox Game Script with Multiple Features
    Author: GitHub Copilot
    Date: 2025-01-17
    Description:
        - Creates an interactive in-game menu with toggleable features.
        - Features Included:
            1. Auto Dodge
            2. Collect Coins
            3. Auto Pass Bomb
            4. Safe Spin
            5. Remove Hitbox
            6. Anti Slipped
        - Displays a bomb timer above players who possess the bomb.
        - Ensures that menu options are interactive and functional.
--]]

-- === Services ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- === Local Player ===
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- === Remove Existing Menu (If Any) ===
for _, gui in ipairs(PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name == "EnhancedMenuGui" then
        gui:Destroy()
    end
end

-- === Create Enhanced Menu ScreenGui ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EnhancedMenuGui"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10 -- Ensure it's on top

-- === Create ToggleFrame to Hold Menu Buttons ===
local ToggleFrame = Instance.new("Frame")
ToggleFrame.Name = "ToggleFrame"
ToggleFrame.Parent = ScreenGui
ToggleFrame.BackgroundTransparency = 1
ToggleFrame.Position = UDim2.new(0.05, 0, 0.25, 0) -- 5% from left, 25% from top
ToggleFrame.Size = UDim2.new(0, 100, 0, 700) -- Adjust size to accommodate more buttons
ToggleFrame.ZIndex = 2

-- === Feature States ===
local featuresEnabled = {
    AutoDodge = true,        -- Enabled by default
    CollectCoins = true,     -- Enabled by default
    AutoPassBomb = false,    -- Disabled by default
    SafeSpin = false,        -- Disabled by default
    RemoveHitbox = false,    -- Disabled by default
    AntiSlipped = false,     -- Disabled by default
    ExtraFeature = false,    -- Disabled by default
}

-- === Define Toggle Buttons Data ===
local ToggleButtonsData = {
    {
        Name = "AutoDodge",
        Image = "rbxassetid://YourToggleImageID1", -- Replace with actual image ID
        Tooltip = "Automatically dodge players",
        Default = featuresEnabled.AutoDodge,
    },
    {
        Name = "CollectCoins",
        Image = "rbxassetid://YourToggleImageID2", -- Replace with actual image ID
        Tooltip = "Automatically collect coins",
        Default = featuresEnabled.CollectCoins,
    },
    {
        Name = "AutoPassBomb",
        Image = "rbxassetid://YourToggleImageID3", -- Replace with actual image ID
        Tooltip = "Automatically pass the bomb",
        Default = featuresEnabled.AutoPassBomb,
    },
    {
        Name = "SafeSpin",
        Image = "rbxassetid://YourToggleImageID4", -- Replace with actual image ID
        Tooltip = "Enable safe spinning",
        Default = featuresEnabled.SafeSpin,
    },
    {
        Name = "RemoveHitbox",
        Image = "rbxassetid://YourToggleImageID5", -- Replace with actual image ID
        Tooltip = "Remove your hitbox",
        Default = featuresEnabled.RemoveHitbox,
    },
    {
        Name = "AntiSlipped",
        Image = "rbxassetid://YourToggleImageID6", -- Replace with actual image ID
        Tooltip = "Prevent slipping on surfaces",
        Default = featuresEnabled.AntiSlipped,
    },
    {
        Name = "ExtraFeature",
        Image = "rbxassetid://YourToggleImageID7", -- Replace with actual image ID
        Tooltip = "Extra Feature",
        Default = featuresEnabled.ExtraFeature,
    },
}

-- === Function to Create Toggle Buttons ===
local function createToggleButton(data, position)
    -- Create the toggle button
    local Toggle = Instance.new("ImageButton")
    Toggle.Name = data.Name .. "Toggle"
    Toggle.Parent = ToggleFrame
    Toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Toggle.Position = position
    Toggle.Size = UDim2.new(0, 60, 0, 60) -- 60x60 pixels
    Toggle.Image = data.Image
    Toggle.ImageColor3 = data.Default and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    Toggle.ScaleType = Enum.ScaleType.Fit
    Toggle.ImageTransparency = 0.5
    Toggle.ZIndex = 2

    -- Make the Toggle Button Circular
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0.5, 0)
    Corner.Parent = Toggle

    -- Create Tooltip
    local Tooltip = Instance.new("TextLabel")
    Tooltip.Name = "Tooltip"
    Tooltip.Parent = Toggle
    Tooltip.Size = UDim2.new(1, 0, 0.3, 0)
    Tooltip.Position = UDim2.new(0, 0, -0.4, 0)
    Tooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Tooltip.BackgroundTransparency = 0.7
    Tooltip.Text = data.Tooltip
    Tooltip.Font = Enum.Font.GothamBold
    Tooltip.TextSize = 14
    Tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tooltip.TextWrapped = true
    Tooltip.Visible = false
    Tooltip.ZIndex = 3

    -- Hover Effects for Tooltip
    Toggle.MouseEnter:Connect(function()
        Tooltip.Visible = true
        Toggle.ImageTransparency = 0.2
    end)

    Toggle.MouseLeave:Connect(function()
        Tooltip.Visible = false
        Toggle.ImageTransparency = 0.5
    end)

    return Toggle
end

-- === Create All Toggle Buttons ===
local ToggleButtons = {}
for i, data in ipairs(ToggleButtonsData) do
    local pos = UDim2.new(0, 20, 0, (i - 1) * 70) -- Space buttons vertically
    ToggleButtons[i] = createToggleButton(data, pos)
end

-- === Function to Create Option Panels ===
local function createOptionPanel(name)
    local OptionsFrame = Instance.new("Frame")
    OptionsFrame.Name = name .. "Options"
    OptionsFrame.Parent = ToggleFrame
    OptionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    OptionsFrame.Position = UDim2.new(1.2, 0, 0, 0) -- Positioned to the right of the toggle button
    OptionsFrame.Size = UDim2.new(0, 200, 0, 100) -- Adjust size as needed
    OptionsFrame.Visible = false -- Hidden by default
    OptionsFrame.ZIndex = 2

    -- Example Option Element: CheckBox
    local OptionCheckBox = Instance.new("TextButton")
    OptionCheckBox.Name = "OptionCheckBox"
    OptionCheckBox.Parent = OptionsFrame
    OptionCheckBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    OptionCheckBox.Position = UDim2.new(0.1, 0, 0.3, 0)
    OptionCheckBox.Size = UDim2.new(0, 150, 0, 40)
    OptionCheckBox.Text = featuresEnabled[name] and "Disable " .. name or "Enable " .. name
    OptionCheckBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    OptionCheckBox.Font = Enum.Font.Gotham
    OptionCheckBox.TextSize = 14
    OptionCheckBox.ZIndex = 2

    -- Toggle Functionality for CheckBox
    OptionCheckBox.MouseButton1Click:Connect(function()
        featuresEnabled[name] = not featuresEnabled[name]
        OptionCheckBox.Text = featuresEnabled[name] and "Disable " .. name or "Enable " .. name
        print(name .. " Feature Enabled:", featuresEnabled[name])
        -- Implement feature toggle logic here
    end)

    return OptionsFrame
end

-- === Create Option Panels for Each Toggle Button ===
local AutoDodgeOptions = createOptionPanel("AutoDodge")
local CollectCoinsOptions = createOptionPanel("CollectCoins")
local AutoPassBombOptions = createOptionPanel("AutoPassBomb")
local SafeSpinOptions = createOptionPanel("SafeSpin")
local RemoveHitboxOptions = createOptionPanel("RemoveHitbox")
local AntiSlippedOptions = createOptionPanel("AntiSlipped")
local ExtraFeatureOptions = createOptionPanel("ExtraFeature")

-- === Function to Toggle Option Panel Visibility ===
local function toggleOptions(optionsFrame)
    if optionsFrame then
        optionsFrame.Visible = not optionsFrame.Visible
    end
end

-- === Connect Toggle Buttons to Their Option Panels ===
ToggleButtons[1].MouseButton1Click:Connect(function()
    toggleOptions(AutoDodgeOptions)
end)

ToggleButtons[2].MouseButton1Click:Connect(function()
    toggleOptions(CollectCoinsOptions)
end)

ToggleButtons[3].MouseButton1Click:Connect(function()
    toggleOptions(AutoPassBombOptions)
end)

ToggleButtons[4].MouseButton1Click:Connect(function()
    toggleOptions(SafeSpinOptions)
end)

ToggleButtons[5].MouseButton1Click:Connect(function()
    toggleOptions(RemoveHitboxOptions)
end)

ToggleButtons[6].MouseButton1Click:Connect(function()
    toggleOptions(AntiSlippedOptions)
end)

ToggleButtons[7].MouseButton1Click:Connect(function()
    toggleOptions(ExtraFeatureOptions)
end)

-- === Bomb Timer Functionality ===

-- Table to store player timer GUIs
local playerBombTimers = {}

-- Function to create a BillboardGui above a player's head to display the bomb timer
local function createBombTimerGui(player)
    -- Ensure the player has a character and a head
    local character = player.Character
    if not character or not character:FindFirstChild("Head") then return end

    -- Check if the player has a Bomb
    local bomb = character:FindFirstChild("Bomb")
    if not bomb then return end

    -- Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BombTimerGui"
    billboard.Parent = character.Head
    billboard.Adornee = character.Head
    billboard.Size = UDim2.new(0, 100, 0, 50) -- Width: 100, Height: 50
    billboard.StudsOffset = Vector3.new(0, 2, 0) -- Position above the head
    billboard.AlwaysOnTop = true
    billboard.Enabled = false -- Initially disabled; enabled when bomb is active

    -- Create TextLabel for the timer
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Parent = billboard
    timerLabel.Size = UDim2.new(1, 0, 1, 0) -- Fill the BillboardGui
    timerLabel.BackgroundTransparency = 1 -- Transparent background
    timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.SourceSansBold
    timerLabel.Text = "Bomb Timer: N/A"
    timerLabel.Name = "TimerLabel"

    -- Store the GUI in the table
    playerBombTimers[player] = timerLabel
end

-- Function to update the bomb timer for a specific player
local function updatePlayerBombTimer(player, timeLeft)
    local timerLabel = playerBombTimers[player]
    if timerLabel then
        if timeLeft and timeLeft.Value > 0 then
            timerLabel.Text = "Bomb Timer: " .. tostring(math.floor(timeLeft.Value)) .. "s"
            timerLabel.Parent.Enabled = true -- Show the timer
        else
            timerLabel.Text = "Bomb Timer: N/A"
            timerLabel.Parent.Enabled = false -- Hide the timer
        end
    end
end

-- Function to remove the Bomb Timer GUI when a player leaves or loses the bomb
local function removeBombTimerGui(player)
    if playerBombTimers[player] then
        local billboard = playerBombTimers[player].Parent
        if billboard then
            billboard:Destroy()
        end
        playerBombTimers[player] = nil
    end
end

-- Function to handle bomb countdown (Assuming bombs are handled client-side)
local function handleBombCountdown()
    for player, timerLabel in pairs(playerBombTimers) do
        local character = player.Character
        if character then
            local bomb = character:FindFirstChild("Bomb")
            if bomb then
                local bombTimeLeft = bomb:FindFirstChild("BombTimeLeft")
                if bombTimeLeft and bombTimeLeft.Value > 0 then
                    -- Decrement the bomb timer
                    bombTimeLeft.Value = bombTimeLeft.Value - RunService.Heartbeat:Wait()
                    -- Update the timer label
                    updatePlayerBombTimer(player, bombTimeLeft)
                elseif bombTimeLeft then
                    bombTimeLeft.Value = 0
                    updatePlayerBombTimer(player, bombTimeLeft)
                end
            else
                -- If bomb is removed, ensure timer is hidden
                updatePlayerBombTimer(player, nil)
            end
        end
    end
end

-- === Auto Pass Bomb Feature Implementation ===

-- Table to keep track of pass cooldowns for each player
local passCooldowns = {}

-- Function to find a random player to pass the bomb to
local function getRandomPlayer(excludePlayer)
    local players = Players:GetPlayers()
    local availablePlayers = {}

    for _, player in ipairs(players) do
        if player ~= excludePlayer and player.Character and player.Character:FindFirstChild("Bomb") == nil then
            table.insert(availablePlayers, player)
        end
    end

    if #availablePlayers == 0 then
        return nil -- No available players to pass the bomb to
    end

    local randomIndex = math.random(1, #availablePlayers)
    return availablePlayers[randomIndex]
end

-- Function to pass the bomb to another player
local function passBomb(currentPlayer)
    local character = currentPlayer.Character
    if not character then return end

    local bomb = character:FindFirstChild("Bomb")
    if not bomb then return end

    -- Check if pass cooldown is active
    if passCooldowns[currentPlayer] and os.time() < passCooldowns[currentPlayer] then
        return -- Still in cooldown period
    end

    local targetPlayer = getRandomPlayer(currentPlayer)
    if not targetPlayer then
        print("No available players to pass the bomb to.")
        return
    end

    local targetCharacter = targetPlayer.Character
    if not targetCharacter then return end

    -- Move the bomb to the target player's character
    bomb.Parent = targetCharacter
    print(currentPlayer.Name .. " passed the bomb to " .. targetPlayer.Name)

    -- Set cooldown (e.g., 30 seconds)
    passCooldowns[currentPlayer] = os.time() + 30
end

-- Function to handle Auto Pass Bomb logic
local function handleAutoPassBomb()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local bomb = character:FindFirstChild("Bomb")
            if bomb then
                -- Example condition: Pass the bomb every 30 seconds
                -- You can customize the condition as needed
                if not passCooldowns[player] or os.time() >= passCooldowns[player] then
                    passBomb(player)
                end
            end
        end
    end
end

-- === Implementing Safe Spin ===

-- Variable to control spinning
local isSpinning = false

-- Function to handle Safe Spin
local function performSafeSpin()
    if isSpinning then
        return -- Already spinning
    end

    isSpinning = true
    print("Safe Spin Activated")

    -- Disable player's movement and other mechanics for safe spinning
    Humanoid.WalkSpeed = 0
    Humanoid.JumpPower = 0

    -- Perform spinning
    for i = 1, 360 do
        if not featuresEnabled.SafeSpin then
            break -- Stop spinning if feature is turned off
        end
        Character:SetPrimaryPartCFrame(Character.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(1), 0))
        RunService.RenderStepped:Wait()
    end

    -- Re-enable player's movement and mechanics
    Humanoid.WalkSpeed = 16
    Humanoid.JumpPower = 50
    isSpinning = false
    print("Safe Spin Deactivated")
end

-- === Implementing Remove Hitbox ===

-- Function to remove the player's hitbox
local function removeHitbox()
    local character = LocalPlayer.Character
    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            -- Remove collision by setting CanCollide to false
            part.CanCollide = false
        end
    end

    print("Hitboxes Removed")
end

-- Function to restore the player's hitboxes
local function restoreHitbox()
    local character = LocalPlayer.Character
    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            -- Restore collision by setting CanCollide to true
            part.CanCollide = true
        end
    end

    print("Hitboxes Restored")
end

-- === Implementing Anti Slipped ===

-- Variable to store original friction
local originalFriction = 0.3

-- Function to enable Anti Slipped
local function enableAntiSlipped()
    local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(
            originalFriction, -- Density
            0.3,               -- Elasticity
            0.5,               -- Friction
            0.3                -- FrictionWeight
        )
        print("Anti Slipped Enabled")
    end
end

-- Function to disable Anti Slipped
local function disableAntiSlipped()
    local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(
            originalFriction, -- Density
            0.3,               -- Elasticity
            0.3,               -- Friction
            0.3                -- FrictionWeight
        )
        print("Anti Slipped Disabled")
    end
end

-- === Implementing Auto Dodge ===

-- Placeholder for Auto Dodge Logic
local function handleAutoDodge()
    if featuresEnabled.AutoDodge then
        -- Example: Automatically move the player away from nearby threats
        -- Implementation can vary based on game mechanics
        local threatRange = 10 -- Define the range to detect threats
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).magnitude
                if distance <= threatRange then
                    -- Move the player in the opposite direction
                    local direction = (Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).unit
                    Character:TranslateBy(direction * 5) -- Adjust speed as needed
                    print("Auto Dodge Activated: Dodged from " .. player.Name)
                end
            end
        end
    end
end

-- === Implementing Collect Coins ===

-- Placeholder for Collect Coins Logic
local function handleCollectCoins()
    if featuresEnabled.CollectCoins then
        -- Example: Automatically collect coins within a certain radius
        local collectRange = 15 -- Define the range to collect coins
        for _, coin in ipairs(workspace:GetChildren()) do
            if coin:IsA("Part") and coin.Name == "Coin" then
                local distance = (Character.HumanoidRootPart.Position - coin.Position).magnitude
                if distance <= collectRange then
                    -- Simulate collecting the coin
                    coin:Destroy() -- Remove the coin from the game
                    print("Collected a coin!")
                    -- Optionally, update the player's coin count
                end
            end
        end
    end
end

-- === Connect Feature Toggles to Their Functionalities ===

-- Safe Spin Logic
RunService.RenderStepped:Connect(function()
    if featuresEnabled.SafeSpin then
        performSafeSpin()
    end
end)

-- Remove Hitbox Logic
RunService.RenderStepped:Connect(function()
    if featuresEnabled.RemoveHitbox then
        removeHitbox()
    else
        restoreHitbox()
    end
end)

-- Anti Slipped Logic
RunService.RenderStepped:Connect(function()
    if featuresEnabled.AntiSlipped then
        enableAntiSlipped()
    else
        disableAntiSlipped()
    end
end)

-- === Bomb Timer and Auto Pass Bomb Integration ===

-- Connect to player events to manage bomb timers
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Small delay to ensure character parts are loaded
        createBombTimerGui(player)

        -- Listen for Bomb object addition/removal
        local bomb = character:FindFirstChild("Bomb")
        if bomb then
            -- Update timer initially
            updatePlayerBombTimer(player, bomb:FindFirstChild("BombTimeLeft"))

            -- Connect to BombTimeLeft changes
            local bombTimeLeft = bomb:FindFirstChild("BombTimeLeft")
            if bombTimeLeft then
                bombTimeLeft.Changed:Connect(function()
                    updatePlayerBombTimer(player, bombTimeLeft)
                end)
            end

            -- Listen for Bomb removal
            bomb.AncestryChanged:Connect(function(child, parent)
                if not parent then
                    removeBombTimerGui(player)
                end
            end)
        end

        -- Monitor for Bomb being added after character load
        character.ChildAdded:Connect(function(child)
            if child.Name == "Bomb" then
                createBombTimerGui(player)
                updatePlayerBombTimer(player, child:FindFirstChild("BombTimeLeft"))

                local bombTimeLeft = child:FindFirstChild("BombTimeLeft")
                if bombTimeLeft then
                    bombTimeLeft.Changed:Connect(function()
                        updatePlayerBombTimer(player, bombTimeLeft)
                    end)
                end

                child.AncestryChanged:Connect(function(child, parent)
                    if not parent then
                        removeBombTimerGui(player)
                    end
                end)
            end
        end)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeBombTimerGui(player)
end)

-- Initialize Bomb Timers for Existing Players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then -- Exclude local player if needed
        if player.Character then
            createBombTimerGui(player)
            local bomb = player.Character:FindFirstChild("Bomb")
            if bomb then
                updatePlayerBombTimer(player, bomb:FindFirstChild("BombTimeLeft"))

                local bombTimeLeft = bomb:FindFirstChild("BombTimeLeft")
                if bombTimeLeft then
                    bombTimeLeft.Changed:Connect(function()
                        updatePlayerBombTimer(player, bombTimeLeft)
                    end)
                end

                bomb.AncestryChanged:Connect(function(child, parent)
                    if not parent then
                        removeBombTimerGui(player)
                    end
                end)
            end
        end
        player.CharacterAdded:Connect(function(character)
            wait(1) -- Small delay to ensure character parts are loaded
            createBombTimerGui(player)
            local bomb = character:FindFirstChild("Bomb")
            if bomb then
                updatePlayerBombTimer(player, bomb:FindFirstChild("BombTimeLeft"))

                local bombTimeLeft = bomb:FindFirstChild("BombTimeLeft")
                if bombTimeLeft then
                    bombTimeLeft.Changed:Connect(function()
                        updatePlayerBombTimer(player, bombTimeLeft)
                    end)
                end

                bomb.AncestryChanged:Connect(function(child, parent)
                    if not parent then
                        removeBombTimerGui(player)
                    end
                end)
            end
        end)
    end
end

-- === Main Loop for Automated Features ===
RunService.RenderStepped:Connect(function()
    -- Handle Bomb Countdown
    handleBombCountdown()

    -- Implement Automated Features Here
    if featuresEnabled.AutoDodge then
        handleAutoDodge()
    end

    if featuresEnabled.CollectCoins then
        handleCollectCoins()
    end

    if featuresEnabled.AutoPassBomb then
        handleAutoPassBomb() -- Call the Auto Pass Bomb function
    end

    -- Safe Spin is handled in its own connection above
    -- Remove Hitbox and Anti Slipped are handled in their own connections above
    -- Add more features as needed
end)
