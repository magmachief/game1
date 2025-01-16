-- Example: Enhanced OrionLib Menu Setup

-- Load OrionLib
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/magmachief/Library-Ui/main/Orion%20Lib%20Transparent%20%20.lua"))()

-- Create an advanced-looking Window with extra customization
local Window = OrionLib:MakeWindow({
    Name = "Yon Menu - Advanced",
    HidePremium = false,
    IntroEnabled = true,          -- Enables the intro animation
    IntroText = "Welcome to Yon Menu",
    SaveConfig = true,            -- Allows saving configurations
    ConfigFolder = "YonAdvanced", -- Folder name for configs
    IntroIcon = "rbxassetid://9876543210",  -- Example icon ID for the intro
    Icon = "rbxassetid://9876543210",       -- Example icon ID for the window top-left corner
    CloseCallback = function()
        print("Yon Menu Closed")
    end
})

-- Optional: Customize color themes (if supported by your OrionLib version)
Window:MakeNotification({
    Name = "Customization",
    Content = "Customize colors under the 'Settings' tab!",
    Image = "rbxassetid://4483345998",
    Time = 5
})

-- Example Tab: Enhanced UI Features
local UiTab = Window:MakeTab({
    Name = "UI Enhancements",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

UiTab:AddParagraph("Tips", "Use this tab to adjust advanced styling if your version of OrionLib supports it.")

-- Insert the rest of your menu or feature toggles as you normally would.
-- For example:
UiTab:AddButton({
    Name = "Example Feature",
    Callback = function()
        print("Example Feature Clicked")
    end
})

-- Example: Add a color picker if your version allows it
local selectedColor = Color3.fromRGB(255, 0, 0)
UiTab:AddColorpicker({
    Name = "Menu Accent Color",
    Default = selectedColor,
    Callback = function(value)
        selectedColor = value
        -- Some OrionLib versions may allow dynamic UI color changes
        print("Selected color:", value)
    end
})

-- Finish initializing
OrionLib:Init()
