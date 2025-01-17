-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Remove existing ScreenGui if necessary
for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name == "MobileScreenGui" then
        gui:Destroy()
    end
end

-- Create a new ScreenGui for the enhanced menu
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EnhancedMenuGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Toggle Buttons Data
local ToggleButtonsData = {
    {
        Name = "AutoDodgeToggle",
        Image = "rbxassetid://YourToggleImageID1",
        Tooltip = "Auto Dodge Players",
        Default = true,
    },
    {
        Name = "CollectCoinsToggle",
        Image = "rbxassetid://YourToggleImageID2",
        Tooltip = "Collect Coins",
        Default = true,
    },
    {
        Name = "AutoPassBombToggle",
        Image = "rbxassetid://YourToggleImageID3",
        Tooltip = "Auto Pass Bomb",
        Default = false,
    },
    {
        Name = "ExtraFeatureToggle",
        Image = "rbxassetid://YourToggleImageID4",
        Tooltip = "Extra Feature",
        Default = false,
    },
}

-- Define positions for toggle buttons
local ToggleButtonPositions = {
    UDim2.new(0, 5, 0, 0),
    UDim2.new(0, 5, 0, 70),
    UDim2.new(0, 5, 0, 140),
    UDim2.new(0, 5, 0, 210),
}

-- Function to create enhanced toggle buttons
local function createEnhancedToggleButton(data, position)
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

    -- Make the Toggle Button Circular
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0.5, 0)
    Corner.Parent = Toggle

    -- Tooltip
    local Tooltip = Instance.new("TextLabel")
    Tooltip.Name = "Tooltip"
    Tooltip.Parent = Toggle
    Tooltip.Size = UDim2.new(1, 0, 0.3, 0)
    Tooltip.Position = UDim2.new(0, 0, -0.35, 0)
    Tooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Tooltip.BackgroundTransparency = 0.7
    Tooltip.Text = data.Tooltip
    Tooltip.Font = Enum.Font.GothamBold
    Tooltip.TextSize = 14
    Tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tooltip.TextWrapped = true
    Tooltip.Visible = false

    -- Hover Effects
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

-- Create a Frame to hold all toggle buttons
local ToggleFrame = Instance.new("Frame")
ToggleFrame.Name = "ToggleFrame"
ToggleFrame.Parent = ScreenGui
ToggleFrame.BackgroundTransparency = 1
ToggleFrame.Position = UDim2.new(0.05, 0, 0.25, 0) -- 5% from left, 25% from top
ToggleFrame.Size = UDim2.new(0, 70, 0, #ToggleButtonsData * 70) -- Adjust size based on number of buttons

-- Create all toggle buttons within the ToggleFrame
local ToggleButtons = {}
for i, data in ipairs(ToggleButtonsData) do
    ToggleButtons[i] = createEnhancedToggleButton(data, ToggleButtonPositions[i])
end

-- Create Option Panels
local function createOptionPanel(name)
    local OptionsFrame = Instance.new("Frame")
    OptionsFrame.Name = name .. "Options"
    OptionsFrame.Parent = ToggleFrame
    OptionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    OptionsFrame.Position = UDim2.new(1.2, 0, 0, 0) -- Positioned to the right of the toggle button
    OptionsFrame.Size = UDim2.new(0, 200, 0, 100) -- Adjust size as needed
    OptionsFrame.Visible = false -- Hidden by default

    -- Example Option Element (CheckBox)
    local OptionCheckBox = Instance.new("TextButton")
    OptionCheckBox.Name = "OptionCheckBox"
    OptionCheckBox.Parent = OptionsFrame
    OptionCheckBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    OptionCheckBox.Position = UDim2.new(0.1, 0, 0.3, 0)
    OptionCheckBox.Size = UDim2.new(0, 100, 0, 40)
    OptionCheckBox.Text = "Enable Feature"
    OptionCheckBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    OptionCheckBox.Font = Enum.Font.Gotham
    OptionCheckBox.TextSize = 14

    -- Toggle Functionality for CheckBox
    local isEnabled = false
    OptionCheckBox.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        OptionCheckBox.Text = isEnabled and "Disable Feature" or "Enable Feature"
        print(name .. " Feature Enabled:", isEnabled)
        -- Add your feature toggle logic here
    end)

    return OptionsFrame
end

-- Create option panels for each toggle
local AutoDodgeOptions = createOptionPanel("AutoDodge")
local CollectCoinsOptions = createOptionPanel("CollectCoins")
local AutoPassBombOptions = createOptionPanel("AutoPassBomb")
local ExtraFeatureOptions = createOptionPanel("ExtraFeature")
