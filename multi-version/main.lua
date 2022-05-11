--// Init
if not isfile('farm.lua') then
    writefile('farm.lua', game:HttpGet("https://raw.githubusercontent.com/jasonsworks/cr-autofarm/master/multi-version/main.lua"))
    print("written")
end

--// Services
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")
local replicatedStorage = game:GetService("ReplicatedStorage")

--// Player
local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character.HumanoidRootPart
local playerGui = player.PlayerGui
local cash = player.Data.Stats.Cash.Value
local notifications = playerGui.Main.notification_container
local camera = workspace.Camera

--// Map
local map = workspace.Map
local dealer = map.NPCs.BankDealerNPC
local jewelryStore = map.Buildings.Jewelry
local alarm = jewelryStore.Rob["alarm_box"]
local sellingPoint = map.Buildings.Bank.Rob.Sell

--// Remotes
local purchase = replicatedStorage._network.purchase

--// Tweening
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

--// Teleporting
queueonteleport = syn.queue_on_teleport or queue_on_teleport
player.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started then
        queueonteleport([[
            repeat wait() until game.Players.LocalPlayer and game.Players.LocalPlayer.PlayerGui:WaitForChild("Main")
            loadfile('farm.lua')
        ]])
    end
 end)

--// Servers
--Credit to ProtonDev on v3rmillion.net, my brain was fried and i just wanted this to work
local OtherServers = httpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
local function joinNew()
    if not isfile('servers.json') then 
        writefile('servers.json',httpService:JSONEncode({}))
    end
    local dontJoin = readfile('servers.json') 
    dontJoin = httpService:JSONDecode(dontJoin)

    for _, Server in next, OtherServers["data"] do
        if Server ~= game.JobId then
            local j = true
            for a,c in pairs(dontJoin) do 
               if c == Server.id then 
                   j = false 
               end
            end
            if j then
                table.insert(dontJoin,Server["id"])
                writefile("servers.json",httpService:JSONEncode(dontJoin))
                task.wait()
                return Server['id']
            end
        end
    end
end

--// Script
local server = joinNew()
local function serverHop()
    if not server then 
        writefile("servers.json",httpService:JSONEncode({}))
        local server = joinNew()
        teleportService:TeleportToPlaceInstance(game.PlaceId, server)
    else
        teleportService:TeleportToPlaceInstance(game.PlaceId, server)
    end
end

humanoid.Died:Connect(function() --If the player dies then teleport, this is needed because with noclip being enabled the player can fall under the map and be kicked
    print(player.Name .. " was killed! Changing server..")
    serverHop()
end)

if alarm.Sound.IsPlaying then --Checks if the jewelry store is currently being robbed, we want this to be happening so no money has to be spent on a gun
    print(player.Name .. " Started farming with " .. tostring(cash))
    if playerGui:FindFirstChild("Intro") then
        local playButton = playerGui.Intro.container.buttons.play.hitbox
        local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
        for _,v in pairs(events) do
            for _,v in pairs(getconnections(playButton[v])) do
                v:Fire()
            end
        end 
        camera.CameraType = Enum.CameraType.Custom
    elseif game:IsLoaded() and player.Character then end

    tweenService:Create(rootPart, tweenInfo, {CFrame = dealer.HumanoidRootPart.CFrame}):Play() --Teleport to the dealer
    task.wait(2)
    fireproximityprompt(dealer.HumanoidRootPart.PromptAttachment.ProximityPrompt) --Opens the shop gui
    task.wait(.5)
    purchase:InvokeServer("bank_dealer", "Duffel Bag")
    
    task.wait(.5)
    local bagSplit = string.split(character:WaitForChild("Duffel Bag").Handle.AmountDisplay.container["jewelry_container"].amount.Text, "/")
    local bagAmount = tonumber(bagSplit[1])
    local bagMax = tonumber(bagSplit[2])

    for _,v in next, jewelryStore.Rob.stealable:GetDescendants() do
        if v:IsA("Part") then
            local parentGlass = v.Parent.parent_glass.Value --Find out what glass box is related to the boxes, this is important to see what boxes can be robbed
            for _,k in next, jewelryStore.Rob.glass:GetChildren() do
                if parentGlass.CanCollide == false and v.Parent.Union.Transparency == 0 then --Has the glass been destroyed?
                    task.wait(1)
                    bagSplit = string.split(character:WaitForChild("Duffel Bag").Handle.AmountDisplay.container["jewelry_container"].amount.Text, "/") --How much jewels do we have?
                    bagAmount = tonumber(bagSplit[1])
                    bagMax = tonumber(bagSplit[2])
                    if bagAmount == bagMax then
                        tweenService:Create(rootPart, tweenInfo, {CFrame = sellingPoint.PrimaryPart.CFrame}):Play() --If we've reached the maximum bag capacity then we can sell the jewels
                        task.wait(1)
                        task.wait(1)
                        notifications.ChildAdded:Connect(function(child)
                            print(player.Name .. " has sold " .. bagAmount .. " bags for " .. child.Text)
                        end)
                        fireclickdetector(sellingPoint.ClickDetector)
                        print(player.Name .. " is changing server, new cash value: " .. player.Data.Stats.Cash.Value)
                        task.wait(1.5)
                        serverHop()
                    else --If we haven't reached the maximum capacity then continue stealing
                        task.wait(.5)
                        if parentGlass.CFrame.X == 616 then
                            tweenService:Create(rootPart, tweenInfo, {CFrame = sellingPoint.PrimaryPart.CFrame}):Play()
                            task.wait(1)
                            task.wait(1)
                            fireclickdetector(sellingPoint.ClickDetector)
                            print(player.Name .. " possibly stuck, changing server...")
                            serverHop()
                        end
                        tweenService:Create(rootPart, tweenInfo, {CFrame = v.CFrame}):Play()
                        fireclickdetector(v.Parent.ClickDetector)
                    end
                end
            end
        end
    end

    tweenService:Create(rootPart, tweenInfo, {CFrame = sellingPoint.PrimaryPart.CFrame}):Play() --Regardless of if we've not got the maximum jewels, teleport and sell to stop the player getting stuck
    task.wait(1)
    task.wait(1)
    notifications.ChildAdded:Connect(function(child)
        print(player.Name .. " has sold " .. bagAmount .. " bags for " .. child.Text)
    end)
    fireclickdetector(sellingPoint.ClickDetector)
    print(player.Name .. " is changing server, new cash value: " .. player.Data.Stats.Cash.Value)
    task.wait(1.5)
    serverHop()

else --If the store isn't being robbed
    print(player.Name .. " is changing server, store not being robbed ")
    serverHop()
end