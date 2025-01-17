--[[
    Ultimate "Pass the Bomb" Script
    ====================================
    Features:
    1. Enhanced Auto Pass Bomb logic with nearest player targeting and locking.
    2. Comprehensive UI with OrionLib.
    3. Detailed logs and console for debugging.
--]]

--========================--
--     INITIAL SETUP      --
--========================--

-- Create a ScreenGui for Mobile
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileScreenGui"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Toggle Button to Open/Close Menu
local Toggle = Instance.new("ImageButton")
Toggle.Name = "Toggle"
Toggle.Parent = ScreenGui
Toggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red background
Toggle.Position = UDim2.new(0.5, -30, 0, 50) -- Positioned near the top center
Toggle.Size = UDim2.new(0, 60, 0, 60) -- 60x60 pixels
Toggle.Image = "rbxassetid://18594014746" -- Replace with your desired image asset ID
Toggle.ScaleType = Enum.ScaleType.Fit

-- Make the Toggle Button Circular
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.5, 0)
Corner.Parent = Toggle

-- Load OrionLib for UI
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/Library-Ui/main/Orion%20Lib%20Transparent%20%20.lua"))()

--========================--
--  MAIN WINDOW CREATION  --
--========================--

local Window = OrionLib:MakeWindow({
    Name = "Yon Menu - Ultimate",
    HidePremium = false,
    IntroEnabled = true,
    IntroText = "Yon Menu",
    SaveConfig = true,
    ConfigFolder = "YonMenu_Ultimate",
    IntroIcon = "rbxassetid://9876543210",  -- Replace with your desired intro icon ID
    Icon = "rbxassetid://9876543210",       -- Replace with your desired window icon ID
})

--========================--
--   GLOBAL VARIABLES     --
--========================--

local autoPassEnabled = true
local TargetPlayer = nil  -- Variable to store the target player
local PreferredTargets = {"PlayerName1"}  -- Replace with player names you want to prioritize

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local logs = {}

--========================--
--   PERFORMANCE SETTINGS --
--========================--

-- No spin settings needed

--========================--
--       CONSOLE TAB      --
--========================--

local ConsoleTab = Window:MakeTab({
    Name = "Console",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local logDisplay = nil

local function refreshLogDisplay()
    if logDisplay then
        local combined = table.concat(logs, "\n")
        logDisplay:Set(combined)
    end
end

local function logMessage(msg)
    table.insert(logs, "[" .. os.date("%X") .. "] " .. tostring(msg))
    refreshLogDisplay()
end

logDisplay = ConsoleTab:AddParagraph("Execution Logs", "")
refreshLogDisplay()

--========================--
--   AUTO PASS BOMB LOGIC --
--========================--

local function autoPassBomb()
    if not autoPassEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local closestPlayer, closestDistance = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (humanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if distance < closestDistance and not player.Character:FindFirstChild("Bomb") then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end

    if closestPlayer then
        print("Passing bomb to: " .. closestPlayer.Name)
        -- Simulate passing the bomb
    end
end

--========================--
--       AUTOMATED TAB    --
--========================--

local AutomatedTab = Window:MakeTab({
    Name = "Automated",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

AutomatedTab:AddToggle({
    Name = "Auto Pass Bomb",
    Default = autoPassEnabled,
    Callback = function(bool)
        autoPassEnabled = bool
    end
})

--========================--
--       OTHERS TAB       --
--========================--

local OtherTab = Window:MakeTab({
    Name = "Others",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

OtherTab:AddToggle({
    Name = "Secure Spin",
    Default = false,
    Callback = function(bool)
        SecureSpinEnabled = bool

        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

        if SecureSpinEnabled then
            spawn(function()
                while SecureSpinEnabled do
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                        end
                    end
                    wait(0.1)
                end
            end)
        else
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 0.5)
                end
            end
        end
    end
})

OtherTab:AddSlider({
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

OtherTab:AddToggle({
    Name = "Anti Slippery",
    Default = false,
    Callback = function(bool)
        AntiSlipperyEnabled = bool

        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

        if AntiSlipperyEnabled then
            spawn(function()
                while AntiSlipperyEnabled do
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                        end
                    end
                    wait(0.1)
                end
            end)
        else
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 0.5)
                end
            end
        end
    end
})

OtherTab:AddToggle({
    Name = "Remove Hitbox",
    Default = false,
    Callback = function(bool)
        RemoveHitboxEnabled = bool

        if RemoveHitboxEnabled then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

            local function removeCollisionPart(character)
                for _ = 1, 100 do
                    wait()
                    pcall(function()
                        local collisionPart = character:FindFirstChild("CollisionPart")
                        if collisionPart then
                            collisionPart:Destroy()
                        end
                    end)
                end
            end
            removeCollisionPart(char)

            LocalPlayer.CharacterAdded:Connect(function(character)
                removeCollisionPart(character)
            end)
        end
    end
})

--========================--
--   TOGGLE MENU BUTTON   --
--========================--

Toggle.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
end)
RunService.Heartbeat:Connect(function()
    autoPassBomb()
    end)
-- Initialize OrionLib UI
OrionLib:Init()
