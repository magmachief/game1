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

-- Apply settings at the start of each round
local function applySettings()
    -- Add logic to enable/disable features based on the saved settings
    if AutoDodgeEnabled then
        -- Enable auto dodge meteors
    end
    if AutoDodgePlayersEnabled then
        -- Enable auto dodge players
    end
    if CollectCoinsEnabled then
        -- Enable collect coins
    end
    if AutoPassEnabled then
        -- Enable auto pass closest player
    end
    if SecureSpinEnabled then
        -- Enable secure spin
    end
    if AntiSlipperyEnabled then
        -- Enable anti slippery
    end
    if RemoveHitboxEnabled then
        -- Enable remove hitbox
    end
end

-- Listen for new rounds to apply settings
game.Players.LocalPlayer.CharacterAdded:Connect(function()
    wait(1) -- Give some time for the character to load
    applySettings()
end)

-- Load settings on script start
loadSettings()
applySettings()
