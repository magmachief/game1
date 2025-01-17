-- Server Script (placed in ServerScriptService)
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local bomb = character:FindFirstChild("Bomb")
        if bomb then
            local passRemote = bomb:FindFirstChild("PassBombRemote") or Instance.new("RemoteEvent", bomb)
            passRemote.Name = "PassBombRemote"

            passRemote.OnServerEvent:Connect(function(sender, targetPlayer)
                if targetPlayer and targetPlayer.Character then
                    bomb.Parent = targetPlayer.Character
                    print(sender.Name .. " passed the bomb to " .. targetPlayer.Name)
                else
                    print("Invalid target player for bomb pass.")
                end
            end)
        end
    end)
end)
