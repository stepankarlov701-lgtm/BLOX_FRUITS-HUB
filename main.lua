--[[
    BF HUB
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("BFHub") then
    playerGui.BFHub:Destroy()
end

local farmEnabled = false
local noclipEnabled = false
local flySpeed = 200
local antiAFKEnabled = true
local hitboxSize = 1
local showHitboxes = false
local hitboxParts = {}
local flying = false
local flyTarget = nil
local flyConnection = nil
local farmConnection = nil
local noclipConnection = nil
local safeZonePart = nil
local safeZonePos = nil
local infJumpEnabled = false
local walkSpeed = 16
local jumpPower = 50
local waterWalkPart = nil
local autoSafeEnabled = false
local autoSafeConnection = nil
local openedUIs = {}
local espEnabled = false
local espObjects = {}
local aimbotEnabled = false
local aimbotPart = "Head"
local aimbotSmoothness = 0.3
local aimbotFOV = 100
local auraEnabled = false
local auraRange = 3
local playerHitboxEnabled = false
local playerHitboxSize = 2
local playerHitboxTransparent = true
local chestList = {}
local lastChestScan = 0
local farmRange = 5000

local ISLANDS = {
    {name = "Tiki Outpost", search = {"tiki", "outpost"}},
    {name = "Peanut Island", search = {"peanut"}},
    {name = "Port", search = {"port"}},
    {name = "Turtle", search = {"turtle"}},
    {name = "Chocolate", search = {"chocolate"}},
    {name = "Boat Castle", search = {"boat", "castle"}},
    {name = "Hydra Island", search = {"hydra"}},
    {name = "Ice Cream Island", search = {"ice", "cream"}},
}

local UI_MENUS = {
    {name = "Premium Gacha", uiName = "PremiumGacha"},
    {name = "Main Gacha UI", uiName = "MainGachaUI"},
    {name = "Holiday Gacha 25", uiName = "HolidayGacha25"},
    {name = "Easter Gift 26", uiName = "EasterGift26"},
    {name = "Fruit Shop And Dealer", uiName = "FruitShopAndDealer"},
    {name = "Valentines Gacha 26", uiName = "ValentinesGacha26"},
    {name = "Shop", uiName = "Shop"},
}

local function flyToFlower(flowerName)
    local flowersFolder = workspace:FindFirstChild("Flowers")
    if flowersFolder then
        for _, flower in pairs(flowersFolder:GetChildren()) do
            if flower.Name == flowerName or flower.Name:lower() == flowerName:lower() then
                local pos = nil
                if flower:IsA("BasePart") then
                    pos = flower.Position
                elseif flower:IsA("Model") then
                    if flower.PrimaryPart then
                        pos = flower.PrimaryPart.Position
                    else
                        local part = flower:FindFirstChildOfClass("BasePart")
                        if part then pos = part.Position end
                    end
                end
                if pos then
                    flyToPosition(pos + Vector3.new(0, 3, 0))
                    return
                end
            end
        end
    end
end

local function flyToPlayer(targetPlayer)
    if not targetPlayer then return end
    local char = targetPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    flyToPosition(root.Position + Vector3.new(0, 3, 0))
end

local function hopServer()
    pcall(function()
        TeleportService:Teleport(2753915549, player)
    end)
end

local function openUI(uiName)
    for _, gui in pairs(playerGui:GetChildren()) do
        pcall(function()
            local function search(parent)
                for _, child in pairs(parent:GetChildren()) do
                    if child.Name == uiName then
                        child.Visible = true
                        if child.Parent and child.Parent.Enabled == false then child.Parent.Enabled = true end
                        table.insert(openedUIs, child)
                        return true
                    end
                    if search(child) then return true end
                end
                return false
            end
            search(gui)
        end)
    end
end

local function closeAllUIs()
    for _, ui in pairs(openedUIs) do
        pcall(function() if ui and ui.Parent then ui.Visible = false end end)
    end
    openedUIs = {}
end

local function makeSafeZone()
    if safeZonePart then safeZonePart:Destroy() end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local basePos = root and root.Position or Vector3.new(0, 0, 0)
    safeZonePart = Instance.new("Part")
    safeZonePart.Name = "SafeZone"
    safeZonePart.Size = Vector3.new(200, 2, 200)
    safeZonePart.Position = basePos + Vector3.new(0, 500, 0)
    safeZonePart.Anchored = true
    safeZonePart.CanCollide = true
    safeZonePart.Material = Enum.Material.Neon
    safeZonePart.Color = Color3.fromRGB(0, 255, 100)
    safeZonePart.Transparency = 0
    safeZonePart.Parent = workspace
    safeZonePos = safeZonePart.Position + Vector3.new(0, 5, 0)
end

local function flyToPosition(targetPos)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if flyConnection then flyConnection:Disconnect() end
    flying = true
    flyTarget = targetPos
    noclipEnabled = true
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if noclipEnabled and player.Character then
            for _, p in pairs(player.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
    flyConnection = RunService.Heartbeat:Connect(function(dt)
        if not flying then return end
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local dist = (flyTarget - root.Position).Magnitude
        if dist < 3 then
            flying = false
            flyConnection:Disconnect()
            flyConnection = nil
            root.CFrame = CFrame.new(flyTarget)
            toggleNoclip(false)
        else
            local direction = (flyTarget - root.Position).Unit
            root.CFrame = CFrame.new(root.Position + direction * flySpeed * dt * 2)
        end
    end)
end

local function stopFlying()
    flying = false
    flyTarget = nil
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
end

local function toggleNoclip(on)
    noclipEnabled = on
    if on then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if noclipEnabled and player.Character then
                for _, p in pairs(player.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
        if player.Character then
            for _, p in pairs(player.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = walkSpeed
            humanoid.JumpPower = jumpPower
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if infJumpEnabled and player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then humanoid.Jump = true end
    end
end)

local function createWaterWalk()
    if waterWalkPart then waterWalkPart:Destroy() end
    waterWalkPart = Instance.new("Part")
    waterWalkPart.Name = "WaterWalk"
    waterWalkPart.Size = Vector3.new(100000, 1, 100000)
    waterWalkPart.Position = Vector3.new(-9504, -5, -8447)
    waterWalkPart.Anchored = true
    waterWalkPart.CanCollide = true
    waterWalkPart.Transparency = 0.5
    waterWalkPart.Color = Color3.fromRGB(0, 150, 255)
    waterWalkPart.Material = Enum.Material.Ice
    waterWalkPart.Parent = workspace
end

local function removeWaterWalk()
    if waterWalkPart then waterWalkPart:Destroy(); waterWalkPart = nil end
end

local function scanChests()
    chestList = {}
    local chestModels = workspace:FindFirstChild("ChestModels")
    if chestModels then
        for _, chest in pairs(chestModels:GetChildren()) do
            if chest:IsA("Model") then
                local primary = chest.PrimaryPart or chest:FindFirstChildOfClass("BasePart")
                if primary then
                    table.insert(chestList, primary)
                end
            elseif chest:IsA("BasePart") then
                table.insert(chestList, chest)
            end
        end
    end
end

local function startFarm()
    if farmConnection then farmConnection:Disconnect() end
    scanChests()
    farmConnection = RunService.Heartbeat:Connect(function()
        if not farmEnabled then return end
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if noclipEnabled then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
        
        if tick() - lastChestScan > 0.5 then
            scanChests()
            lastChestScan = tick()
        end
        
        if #chestList == 0 then return end
        
        local nearest = nil
        local nearestDist = math.huge
        
        for _, chest in pairs(chestList) do
            if chest and chest.Parent then
                local dist = (chest.Position - root.Position).Magnitude
                if dist < nearestDist and dist < farmRange then
                    nearestDist = dist
                    nearest = chest
                end
            end
        end
        
        if nearest then
            root.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 3, 0))
        end
    end)
end

local function stopFarmFarm()
    if farmConnection then farmConnection:Disconnect(); farmConnection = nil end
end

local function findIsland(island)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            for _, term in pairs(island.search) do
                if n:find(term:lower()) then
                    if obj:IsA("BasePart") then return obj.Position
                    elseif obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart.Position end
                end
            end
        end
    end
    return nil
end

local function updateESP()
    for _, obj in pairs(espObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    espObjects = {}
    if not espEnabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 100, 0, 25)
            bb.StudsOffset = Vector3.new(0, 2, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = head
            bb.Parent = head
            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            bg.BackgroundTransparency = 0.5
            bg.Parent = bb
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = plr.Name
            label.TextColor3 = Color3.fromRGB(255, 0, 0)
            label.TextSize = 10
            label.Font = Enum.Font.GothamBold
            label.Parent = bg
            table.insert(espObjects, bb)
        end
    end
end

spawn(function()
    while true do
        updateESP()
        wait(2)
    end
end)

local function findAimbotTarget()
    local nearest = nil
    local nearestDist = aimbotFOV
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local targetPart = plr.Character:FindFirstChild(aimbotPart)
            if targetPart then
                local screenPos, onScreen = camera:WorldToScreenPoint(targetPart.Position)
                if onScreen then
                    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                    local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if distFromCenter < aimbotFOV and distFromCenter < nearestDist then
                        nearestDist = distFromCenter
                        nearest = targetPart
                    end
                end
            end
        end
    end
    return nearest
end

RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = findAimbotTarget()
        if target then
            local targetCFrame = CFrame.new(camera.CFrame.Position, target.Position)
            camera.CFrame = camera.CFrame:Lerp(targetCFrame, aimbotSmoothness)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if auraEnabled and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                local partName = part.Name:lower()
                if partName:find("hand") or partName:find("arm") then
                    part.Size = Vector3.new(auraRange, auraRange, auraRange)
                end
            end
        end
    end
end)

local playerHitboxPart = nil
RunService.Heartbeat:Connect(function()
    if playerHitboxEnabled and player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            if playerHitboxPart then playerHitboxPart:Destroy() end
            playerHitboxPart = Instance.new("Part")
            playerHitboxPart.Size = Vector3.new(playerHitboxSize, playerHitboxSize, playerHitboxSize)
            playerHitboxPart.Position = root.Position
            playerHitboxPart.Anchored = false
            playerHitboxPart.CanCollide = not playerHitboxTransparent
            playerHitboxPart.Transparency = 0.7
            playerHitboxPart.Color = Color3.fromRGB(0, 255, 255)
            playerHitboxPart.Material = Enum.Material.Neon
            playerHitboxPart.Parent = workspace
            local weld = Instance.new("Weld")
            weld.Part0 = root
            weld.Part1 = playerHitboxPart
            weld.Parent = playerHitboxPart
        end
    else
        if playerHitboxPart then
            playerHitboxPart:Destroy()
            playerHitboxPart = nil
        end
    end
end)

-- GUI
local sg = Instance.new("ScreenGui")
sg.Name = "BFHub"
sg.ResetOnSpawn = false
sg.Parent = playerGui

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 100, 0, 100)
openBtn.Position = UDim2.new(0, 10, 0, 10)
openBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
openBtn.Text = "BF"
openBtn.TextColor3 = Color3.new(1,1,1)
openBtn.TextSize = 30
openBtn.Font = Enum.Font.GothamBold
openBtn.Parent = sg
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 25)

local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 350, 0, 450)
menu.Position = UDim2.new(0.5, -175, 0.5, -225)
menu.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
menu.Active = true
menu.Draggable = true
menu.Visible = false
menu.Parent = sg
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 12)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(255, 100, 30)
header.Parent = menu
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local headerText = Instance.new("TextLabel")
headerText.Size = UDim2.new(0.6, 0, 1, 0)
headerText.Position = UDim2.new(0, 15, 0, 0)
headerText.BackgroundTransparency = 1
headerText.Text = "BF HUB"
headerText.TextColor3 = Color3.new(1,1,1)
headerText.TextSize = 17
headerText.Font = Enum.Font.GothamBold
headerText.TextXAlignment = Enum.TextXAlignment.Left
headerText.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0, 9)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)

local tabs = {}
local contents = {}
local tabNames = {"Farm", "Safe", "Islands", "UI", "Misc", "Player", "PVP", "Unload"}

for i, name in ipairs(tabNames) do
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0.125, -2, 0, 30)
    tab.Position = UDim2.new((i-1) * 0.125, 1, 0, 50)
    tab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    tab.Text = name
    tab.TextColor3 = Color3.new(1,1,1)
    tab.TextSize = 8
    tab.Font = Enum.Font.GothamBold
    tab.Parent = menu
    Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 4)
    
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -20, 1, -100)
    content.Position = UDim2.new(0, 10, 0, 85)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 30)
    content.Visible = (i == 1)
    content.Parent = menu
    
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.Parent = content
    
    tabs[i] = tab
    contents[i] = content
    
    tab.MouseButton1Click:Connect(function()
        for j = 1, #tabs do
            contents[j].Visible = false
            tabs[j].BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        end
        content.Visible = true
        tab.BackgroundColor3 = Color3.fromRGB(255, 100, 30)
    end)
end

local function makeToggle(parent, text, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 38)
    f.BackgroundTransparency = 1
    f.Parent = parent
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.65, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.new(1,1,1)
    l.TextSize = 12
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local t = Instance.new("TextButton")
    t.Size = UDim2.new(0, 50, 0, 22)
    t.Position = UDim2.new(0.85, 0, 0.5, -11)
    t.BackgroundColor3 = def and Color3.fromRGB(50,200,50) or Color3.fromRGB(100,100,100)
    t.Text = def and "ON" or "OFF"
    t.TextColor3 = Color3.new(1,1,1)
    t.TextSize = 10
    t.Font = Enum.Font.GothamBold
    t.Parent = f
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 11)
    
    local on = def
    t.MouseButton1Click:Connect(function()
        on = not on
        t.BackgroundColor3 = on and Color3.fromRGB(50,200,50) or Color3.fromRGB(100,100,100)
        t.Text = on and "ON" or "OFF"
        if cb then cb(on) end
    end)
end

local function makeSlider(parent, text, min, max, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 48)
    f.BackgroundTransparency = 1
    f.Parent = parent
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = text .. ": " .. def
    l.TextColor3 = Color3.new(1,1,1)
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local bg2 = Instance.new("Frame")
    bg2.Size = UDim2.new(1, 0, 0, 7)
    bg2.Position = UDim2.new(0, 0, 0, 25)
    bg2.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bg2.Parent = f
    Instance.new("UICorner", bg2).CornerRadius = UDim.new(0, 4)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 100, 30)
    fill.Parent = bg2
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
    
    local dragging = false
    bg2.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    bg2.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local pos = bg2.AbsolutePosition
            local size = bg2.AbsoluteSize
            local percent = math.clamp((mousePos.X - pos.X) / size.X, 0, 1)
            local val = math.floor(min + (max - min) * percent)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            l.Text = text .. ": " .. val
            if cb then cb(val) end
        end
    end)
end

local function makeButton(parent, text, cb, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 33)
    btn.BackgroundColor3 = color or Color3.fromRGB(255, 100, 30)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
end

-- FARM
makeToggle(contents[1], "Auto Farm Chest", false, function(v)
    farmEnabled = v
    if v then toggleNoclip(true); startFarm() else stopFarmFarm() end
end)

makeButton(contents[1], "🌸 Flower1", function()
    flyToFlower("Flower1")
end, Color3.fromRGB(255, 150, 200))

makeButton(contents[1], "🌸 Flower2", function()
    flyToFlower("Flower2")
end, Color3.fromRGB(255, 180, 200))

makeToggle(contents[1], "Noclip", false, function(v) toggleNoclip(v) end)
makeToggle(contents[1], "Anti AFK", true, function(v) antiAFKEnabled = v end)
makeSlider(contents[1], "Speed", 50, 500, 200, function(v) flySpeed = v end)
makeSlider(contents[1], "Farm Range", 100, 10000, 5000, function(v) farmRange = v end)
contents[1].CanvasSize = UDim2.new(0, 0, 0, 450)

-- SAFE
makeToggle(contents[2], "Auto Safe", false, function(v)
    autoSafeEnabled = v
    if v then
        if autoSafeConnection then autoSafeConnection:Disconnect() end
        autoSafeConnection = RunService.Heartbeat:Connect(function()
            if not autoSafeEnabled then return end
            local char = player.Character
            if not char then return end
            local humanoid = char:FindFirstChild("Humanoid")
            if not humanoid then return end
            if humanoid.Health < humanoid.MaxHealth * 0.5 then
                if not flying then
                    if not safeZonePos then makeSafeZone() end
                    flyToPosition(safeZonePos)
                end
            end
        end)
    else
        if autoSafeConnection then autoSafeConnection:Disconnect(); autoSafeConnection = nil end
    end
end)

makeButton(contents[2], "Fly to Safe", function()
    if not safeZonePos then makeSafeZone() end
    flyToPosition(safeZonePos)
end, Color3.fromRGB(50, 150, 255))
makeButton(contents[2], "Create Safe", function() makeSafeZone() end, Color3.fromRGB(50, 200, 50))
makeButton(contents[2], "Stop", function() stopFlying() end, Color3.fromRGB(255, 100, 100))
makeSlider(contents[2], "Speed", 50, 500, 200, function(v) flySpeed = v end)
contents[2].CanvasSize = UDim2.new(0, 0, 0, 300)

-- ISLANDS
for _, island in pairs(ISLANDS) do
    makeButton(contents[3], "✈️ " .. island.name, function()
        local pos = findIsland(island)
        if pos then flyToPosition(pos + Vector3.new(0, 30, 0)) end
    end, Color3.fromRGB(50, 120, 200))
end

makeButton(contents[3], "Stop", function() stopFlying() end, Color3.fromRGB(255, 100, 100))

local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, 0, 0, 200)
playerListFrame.BackgroundTransparency = 1
playerListFrame.Parent = contents[3]
local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Padding = UDim.new(0, 3)
playerListLayout.Parent = playerListFrame

spawn(function()
    while true do
        for _, child in pairs(playerListFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 25)
                btn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
                btn.Text = "✈️ " .. plr.Name
                btn.TextColor3 = Color3.new(1,1,1)
                btn.TextSize = 10
                btn.Font = Enum.Font.GothamBold
                btn.Parent = playerListFrame
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
                btn.MouseButton1Click:Connect(function()
                    flyToPlayer(plr)
                end)
            end
        end
        wait(3)
    end
end)

makeSlider(contents[3], "Speed", 50, 500, 200, function(v) flySpeed = v end)
contents[3].CanvasSize = UDim2.new(0, 0, 0, #ISLANDS * 45 + 300)

-- UI
for _, uiData in pairs(UI_MENUS) do
    makeButton(contents[4], "📋 " .. uiData.name, function()
        openUI(uiData.uiName)
    end, Color3.fromRGB(150, 100, 255))
end
makeButton(contents[4], "Close All", function() closeAllUIs() end, Color3.fromRGB(255, 50, 50))
contents[4].CanvasSize = UDim2.new(0, 0, 0, #UI_MENUS * 45 + 60)

-- MISC
makeButton(contents[5], "Hop", function() hopServer() end, Color3.fromRGB(100, 100, 255))
makeToggle(contents[5], "No Fog", false, function(v)
    if v then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 99999
    end
end)
makeToggle(contents[5], "Full Bright", false, function(v)
    if v then
        Lighting.Brightness = 5
        Lighting.ClockTime = 12
    else
        Lighting.Brightness = 2
    end
end)
makeToggle(contents[5], "ESP", false, function(v)
    espEnabled = v
    if not v then
        for _, obj in pairs(espObjects) do
            if obj and obj.Parent then obj:Destroy() end
        end
        espObjects = {}
    end
end)
contents[5].CanvasSize = UDim2.new(0, 0, 0, 250)

-- PLAYER
makeSlider(contents[6], "Walk Speed", 16, 500, 16, function(v) walkSpeed = v end)
makeSlider(contents[6], "Jump Power", 50, 500, 50, function(v) jumpPower = v end)
makeToggle(contents[6], "Inf Jump", false, function(v) infJumpEnabled = v end)
makeToggle(contents[6], "Water Walk", false, function(v)
    if v then createWaterWalk() else removeWaterWalk() end
end)
contents[6].CanvasSize = UDim2.new(0, 0, 0, 250)

-- PVP
makeToggle(contents[7], "Aimbot", false, function(v) aimbotEnabled = v end)
makeButton(contents[7], "Target: Head", function() aimbotPart = "Head" end, Color3.fromRGB(255, 100, 100))
makeButton(contents[7], "Target: Body", function() aimbotPart = "HumanoidRootPart" end, Color3.fromRGB(100, 100, 255))
makeSlider(contents[7], "Smooth", 0.1, 1, 0.3, function(v) aimbotSmoothness = v end)
makeToggle(contents[7], "Aura", false, function(v) auraEnabled = v end)
makeSlider(contents[7], "Aura Range", 1, 10, 3, function(v) auraRange = v end)
makeToggle(contents[7], "Hitbox", false, function(v) playerHitboxEnabled = v end)
makeSlider(contents[7], "Hitbox Size", 1, 60, 2, function(v) playerHitboxSize = v end)
makeToggle(contents[7], "Transparent", true, function(v) playerHitboxTransparent = v end)
contents[7].CanvasSize = UDim2.new(0, 0, 0, 500)

-- UNLOAD
local unload = Instance.new("TextButton")
unload.Size = UDim2.new(1, 0, 0, 45)
unload.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
unload.Text = "UNLOAD"
unload.TextColor3 = Color3.new(1,1,1)
unload.TextSize = 14
unload.Font = Enum.Font.GothamBold
unload.Parent = contents[8]
Instance.new("UICorner", unload).CornerRadius = UDim.new(0, 8)

unload.MouseButton1Click:Connect(function()
    farmEnabled = false
    flying = false
    infJumpEnabled = false
    autoSafeEnabled = false
    espEnabled = false
    aimbotEnabled = false
    auraEnabled = false
    playerHitboxEnabled = false
    if autoSafeConnection then autoSafeConnection:Disconnect() end
    stopFarmFarm()
    stopFlying()
    toggleNoclip(false)
    removeWaterWalk()
    closeAllUIs()
    if safeZonePart then safeZonePart:Destroy() end
    sg:Destroy()
end)

contents[8].CanvasSize = UDim2.new(0, 0, 0, 100)

-- AFK
spawn(function()
    while true do
        if antiAFKEnabled then
            pcall(function() camera.CFrame = camera.CFrame * CFrame.Angles(0, 0.01, 0) end)
        end
        wait(20)
    end
end)

-- OPEN
openBtn.MouseButton1Click:Connect(function() menu.Visible = true end)
closeBtn.MouseButton1Click:Connect(function() menu.Visible = false end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        menu.Visible = not menu.Visible
    end
end)

spawn(function() wait(3) makeSafeZone() end)
player.CharacterAdded:Connect(function() wait(1) makeSafeZone() end)
