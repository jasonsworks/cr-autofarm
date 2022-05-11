--// Services
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")
local runService = game:GetService("RunService")

--// Player
local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character.HumanoidRootPart
local playerGui = player.PlayerGui
local camera = workspace.Camera

--// Map
local map = workspace.Map
local dealer = map.NPCs.BankDealerNPC
local jewelryStore = map.Buildings.Jewelry
local alarm = jewelryStore.Rob["alarm_box"]
local sellingPoint = map.Buildings.Bank.Rob.Sell

--// Tweening
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)

--// Teleporting
queueonteleport = syn.queue_on_teleport or queue_on_teleport
player.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started then
        queueonteleport([[
            repeat wait() until game.Players.LocalPlayer and game.Players.LocalPlayer.PlayerGui
            loadstring(game:HttpGet('https://raw.githubusercontent.com/jasonsworks/cr-autofarm/main/main.lua'))()
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
    serverHop()
end)

humanoid.Seated:Connect(function() --Stops the player getting stuck in seat while teleporting
    humanoid.Sit = false
end)

local function clickButton(path) --Fire button events
    local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
    for _,v in pairs(events) do
        for _,v in pairs(getconnections(path[v])) do
            v:Fire()
        end
    end 
end

if alarm.Sound.IsPlaying then --Checks if the jewelry store is currently being robbed, we want this to be happening so no money has to be spent on a gun
    if playerGui:FindFirstChild("Intro") then
        local playButton = playerGui.Intro.container.buttons.play.hitbox
        clickButton(playButton)
        camera.CameraType = Enum.CameraType.Custom
    elseif game:IsLoaded() and player.Character then end

    tweenService:Create(rootPart, tweenInfo, {CFrame = dealer.HumanoidRootPart.CFrame}):Play() --Teleport to the dealer
    task.wait(1.8)
    fireproximityprompt(dealer.HumanoidRootPart.PromptAttachment.ProximityPrompt) --Opens the shop gui
    local purchaseBag = playerGui:WaitForChild("Shop").Shop.list["Duffel Bag (x5 Capacity)"]["purchase_button"] --Find the button to purchase the duffle bag
    clickButton(purchaseBag)

    for _,v in next, jewelryStore.Rob.stealable:GetDescendants() do
        if v:IsA("Part") then
            local parentGlass = v.Parent.parent_glass.Value --Find out what glass box is related to the boxes, this is important to see what boxes can be robbed
            for _,k in next, jewelryStore.Rob.glass:GetChildren() do
                if parentGlass.CanCollide == false and v.Parent.Union.Transparency == 0 then --Has the glass been destroyed?
                    task.wait(1)
                    local bagSplit = string.split(character:WaitForChild("Duffel Bag").Handle.AmountDisplay.container["jewelry_container"].amount.Text, "/") --How much jewels do we have?
                    local bagAmount = tonumber(bagSplit[1])
                    local bagMax = tonumber(bagSplit[2])
                    if bagAmount == bagMax then
                        tweenService:Create(rootPart, tweenInfo, {CFrame = sellingPoint.PrimaryPart.CFrame}):Play() --If we've reached the maximum bag capacity then we can sell the jewels
                        task.wait(.5)
                        task.wait(.5)
                        fireclickdetector(sellingPoint.ClickDetector)
                        serverHop()
                    else --If we haven't reached the maximum capacity then continue stealing
                        tweenService:Create(rootPart, tweenInfo, {CFrame = v.CFrame}):Play()
                        task.wait(.5)
                        fireclickdetector(v.Parent.ClickDetector)
                    end
                end
            end
        end
    end

    tweenService:Create(rootPart, tweenInfo, {CFrame = sellingPoint.PrimaryPart.CFrame}):Play() --Regardless of if we've not got the maximum jewels, teleport and sell to stop the player getting stuck
    task.wait(.5)
    task.wait(.5)
    fireclickdetector(sellingPoint.ClickDetector)
    serverHop()

else --If the store isn't being robbed
    serverHop()
end