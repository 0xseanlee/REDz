local webhook_url = "https://discord.com/api/webhooks/1468906393732911158/DJ-MJe9W8gNe0lj9QyRdZ-TV6wCT43Z43Qo_Nze77PoyGhuC5J4wjK78adrw1fFt9bW4"
local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function autoPickSide()
    pcall(function()
        if not player:FindFirstChild("DataLoaded") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
        end
    end)
end

local function sendWebhook(title, description, color)
    local request_func = syn and syn.request or http_request or request or (http and http.request)
    if not request_func then return end

    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 16711680,
            ["footer"] = {["text"] = "Time: " .. os.date("%X")},
            ["fields"] = {
                {["name"] = "JobId", ["value"] = "```" .. game.JobId .. "```", ["inline"] = false},
                {["name"] = "Players", ["value"] = #game.Players:GetChildren() .. "/" .. game.Players.MaxPlayers, ["inline"] = true}
            }
        }}
    }

    pcall(function()
        request_func({
            Url = webhook_url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

local function ServerHop()
    local PlaceID = game.PlaceId
    pcall(function()
        local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, s in pairs(Servers.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(PlaceID, s.id, player)
                break
            end
        end
    end)
end

local function teleport(targetCFrame)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local dist = (char.HumanoidRootPart.Position - targetCFrame.Position).Magnitude
    local tween = TweenService:Create(char.HumanoidRootPart, TweenInfo.new(dist/300, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    tween:Play()
    return tween
end

task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(2)
    autoPickSide()
    
    repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    task.wait(3) 
    
    local fruits = {}
    for _, obj in pairs(game.Workspace:GetChildren()) do
        if obj:IsA("Tool") and (obj.Name:find("Fruit") or obj:FindFirstChild("Handle")) then
            table.insert(fruits, obj)
        end
    end
    
    if #fruits > 0 then
        sendWebhook("🌟 Fruit Found!", "Found **" .. #fruits .. "** fruit(s). Starting collection...", 65280)
        
        for _, fruit in pairs(fruits) do
            local handle = fruit:FindFirstChild("Handle") or fruit:FindFirstChildOfClass("Part")
            if handle then
                local tw = teleport(handle.CFrame)
                if tw then tw.Completed:Wait() end
                
                task.wait(1.5)
                
                local fruitName = fruit.Name
                pcall(function()
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruitName, player.Character:FindFirstChild(fruitName))
                end)
                
                sendWebhook("🍎 Stored", "Successfully stored: **" .. fruitName .. "**", 16776960)
                task.wait(1)
            end
        end
    else
        sendWebhook("🔍 Scan Finished", "No fruits found. Hopping server...", 16711680)
    end
    
    task.wait(3)
    ServerHop()
end)
