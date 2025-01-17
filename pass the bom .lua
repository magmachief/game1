--[[
    Enhanced Roblox Menu and Bomb Timer Script
    Author: GitHub Copilot
    Date: YYYY-MM-DD
    Description:
        - Creates an enhanced in-game menu with toggleable features.
        - Displays a bomb timer above players who possess a bomb.
        - Ensures that menu options are interactive and functional.
--]]

-- === Services ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- === Local Player ===
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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
ToggleFrame.Size = UDim2.new(0, 100, 0, 300) -- Adjust size as needed
ToggleFrame.ZIndex = 2

-- === Define Toggle Buttons Data ===
local ToggleButtonsData = {
    {
        Name = "AutoDodgeToggle",
        Image = "rbxassetid://YourToggleImageID1", -- Replace with actual image ID
        Tooltip = "Auto Dodge Players",
        Default = true,
    },
    {
        Name = "CollectCoinsToggle",
        Image = "rbxassetid://YourToggleImageID2", -- Replace with actual image ID
        Tooltip = "Collect Coins",
        Default = true,
    },
    {
        Name = "AutoPassBombToggle",
        Image = "rbxassetid://YourToggleImageID3", -- Replace with actual image ID
        Tooltip = "Auto Pass Bomb",
        Default = false,
    },
    {
        Name = "ExtraFeatureToggle",
        Image = "rbxassetid://YourToggleImageID4", -- Replace with actual image ID
        Tooltip = "Extra Feature",
        Default = false,
    },
}

-- === Function to Create Toggle Buttons ===
local function createToggleButton(data, position)
    -- Create the toggle button
    local Toggle = Instance.new("ImageButton")
    Toggle.Name = data.Name
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
    OptionCheckBox.Text = "Enable Feature"
    OptionCheckBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    OptionCheckBox.Font = Enum.Font.Gotham
    OptionCheckBox.TextSize = 14
    OptionCheckBox.ZIndex = 2

    -- Toggle Functionality for CheckBox
    local isEnabled = data.Default
    OptionCheckBox.Text = isEnabled and "Disable Feature" or "Enable Feature"

    OptionCheckBox.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        OptionCheckBox.Text = isEnabled and "Disable Feature" or "Enable Feature"
        print(name .. " Feature Enabled:", isEnabled)
        -- Implement feature toggle logic here
    end)

    return OptionsFrame
end

-- === Create Option Panels for Each Toggle Button ===
local AutoDodgeOptions = createOptionPanel("AutoDodge")
local CollectCoinsOptions = createOptionPanel("CollectCoins")
local AutoPassBombOptions = createOptionPanel("AutoPassBomb")
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

-- === Connect Functions to Player Events ===

-- When a new player joins
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

-- When a player leaves
Players.PlayerRemoving:Connect(function(player)
    removeBombTimerGui(player)
end)

-- === Initialize Bomb Timers for Existing Players ===
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
    -- Example: Auto Dodge
    --[[
    if AutoDodgeEnabled then
        -- Your Auto Dodge Logic
    end

    if CollectCoinsEnabled then
        -- Your Collect Coins Logic
    end

    if AutoPassBombEnabled then
        -- Your Auto Pass Bomb Logic
    end
    --]]
end)
