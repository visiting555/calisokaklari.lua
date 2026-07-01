--[[
Blox Fruits Script v3.3
- Profesyonel uçan/noclip + MEYVE özellikleri (kesinlikle görünüyor)
- Menü başlığı "visitingmenu"
- Meyve seçme, ESP, TP ayrı net, menüde kesinlikle görünüyor
]]

-- SERVİSLER/DEĞİŞKENLER
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera

local guiName = "BFPRO_" .. tostring(math.random(10000000, 99999999))
local menuGui = nil
local toggles = {Fly=false, Noclip=false}
local fruitEspSelection = nil
local fruitEspBillboards = {}
local flyConn, noclipConn = nil, nil
local flying, noclipping = false, false

------------------------------------------------
-- MEYVE LİSTESİ (Statik + dynamic)
local function knownFruits()
    return {
        "Kitsune", "Dragon", "Leopard", "Venom", "Dough", "Spirit", "Magma", "Light", "Dark", "Flame",
        "Quake", "Human: Buddha", "Ice", "Phoenix", "Mammoth", "Love", "Spider", "Portal", "Barrier",
        "Rubber", "Sand", "Diamond", "Ghost", "Sound", "Falcon", "Spin", "Bomb", "Spring", "Chop", "Revive", "Smoke", "Spike", "Kilo"
    }
end

local function getFruitsOnMap()
    local found = {}
    local already = {}
    for _,obj in ipairs(Workspace:GetDescendants()) do
        local n = tostring(obj.Name)
        if (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart")) and (n:lower():find("fruit") or table.find(knownFruits(), n)) then
            if not already[n] then table.insert(found, n) already[n] = true end
        end
    end
    for _,fruit in ipairs(knownFruits()) do
        if not already[fruit] then table.insert(found, fruit) already[fruit] = true end
    end
    table.sort(found)
    return found
end

-- MEVCUT GUI'leri temizle
pcall(function()
    for _,v in ipairs(CoreGui:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name:find("BFPRO_") then v:Destroy() end
    end
end)
pcall(function()
    for _,v in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name:find("BFPRO_") then v:Destroy() end
    end
end)

-- Menü parent fallback
local function robustParent(gui)
    local done = false
    pcall(function()
        gui.Parent = CoreGui
        done = gui.Parent == CoreGui
    end)
    if not done then
        pcall(function()
            gui.Parent = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
        end)
    end
end

local function destroyTable(tb)
    for _,v in pairs(tb) do pcall(function() v:Destroy() end) end
    table.clear(tb)
end

function setFly(on)
    if flying then
        if flyConn then flyConn:Disconnect() flyConn = nil end
        local c = LocalPlayer.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            for _,obj in ipairs(c.HumanoidRootPart:GetChildren()) do
                if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then obj:Destroy() end
            end
        end
        flying = false
    end
    if on then
        local c = LocalPlayer.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            flying = true
            local hrp = c.HumanoidRootPart
            local gyro = Instance.new("BodyGyro", hrp)
            gyro.MaxTorque = Vector3.new(1e8,1e8,1e8)
            gyro.P = 9e4
            local vel = Instance.new("BodyVelocity", hrp)
            vel.MaxForce = Vector3.new(1e8,1e8,1e8)
            vel.P = 1e4
            vel.Velocity = Vector3.new()
            flyConn = RunService.RenderStepped:Connect(function()
                if not flying or not hrp then return end
                local cam = Camera
                local dir = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
                dir = (dir.Magnitude>0 and dir.Unit) or Vector3.new()
                local spd = 160
                gyro.CFrame = cam.CFrame
                vel.Velocity = dir*spd
            end)
        end
    end
end

function setNoclip(on)
    if noclipConn then noclipConn:Disconnect() noclipConn=nil end
    noclipping = false
    if on then
        noclipping = true
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and noclipping then
                for _,p in pairs(LocalPlayer.Character:GetChildren()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end

function setFruitESP(fruitName)
    destroyTable(fruitEspBillboards)
    if not fruitName then return end
    for _,obj in pairs(Workspace:GetDescendants()) do
        local name = tostring(obj.Name or "")
        if string.lower(name) == string.lower(fruitName) then
            local handle = obj:FindFirstChild("Handle") or (obj:IsA("Tool") and obj:FindFirstChildOfClass("Part"))
            if handle then
                local bill = Instance.new("BillboardGui", menuGui)
                bill.AlwaysOnTop = true
                bill.Size = UDim2.new(0,120,0,44)
                bill.Adornee = handle
                local lbl = Instance.new("TextLabel", bill)
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.Text = fruitName.." 🌟"
                lbl.TextColor3 = Color3.fromRGB(255,235,60)
                lbl.Font = Enum.Font.GothamBold
                lbl.TextScaled = true
                fruitEspBillboards[#fruitEspBillboards+1] = bill
            end
        end
    end
end

function tpToFruitAndPickup(fruitName)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local pos, target = nil, nil
    for _,obj in pairs(Workspace:GetDescendants()) do
        local name = tostring(obj.Name or "")
        if fruitName and string.lower(name) == string.lower(fruitName) then
            local h = obj:FindFirstChild("Handle") or (obj:IsA("Tool") and obj:FindFirstChildOfClass("Part"))
            if h then
                local dist = (char.HumanoidRootPart.Position-h.Position).Magnitude
                if not pos or dist < pos then
                    pos = dist
                    target = h
                end
            end
        end
    end
    if not target then
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {
                Title="Meyve",
                Text="Meyve bulunamadı!",
                Duration=3
            })
        end)
        return
    end
    for _=1,15 do
        char.HumanoidRootPart.CFrame = target.CFrame+Vector3.new(0,3,0)
        wait(0.07)
    end
    pcall(function()
        firetouchinterest(char.HumanoidRootPart, target, 0)
        wait(0.1)
        firetouchinterest(char.HumanoidRootPart, target, 1)
    end)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title="Meyve",
            Text=fruitName.." alındı (veya çok yakında olabilir)!",
            Duration=2
        })
    end)
end

-- MENU GUI
local function createMenu()
    if menuGui then pcall(function() menuGui:Destroy() end) end

    menuGui = Instance.new("ScreenGui")
    menuGui.ResetOnSpawn = false
    menuGui.DisplayOrder = 9e6
    menuGui.Name = guiName

    robustParent(menuGui)
    if not menuGui.Parent then return end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 410, 0, 500)
    frame.Position = UDim2.new(0, 65, 0, 90)
    frame.BackgroundColor3 = Color3.fromRGB(25,28,38)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = menuGui

    local title = Instance.new("TextLabel")
    title.Text = "visitingmenu"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(220,190,50)
    title.TextScaled = true
    title.Size = UDim2.new(1,0,0,40)
    title.BackgroundTransparency = 1
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "X"
    closeBtn.Size = UDim2.new(0,36,0,36)
    closeBtn.Position = UDim2.new(1,-46,0,6)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.new(1,0,0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = frame
    closeBtn.MouseButton1Click:Connect(function()
        if menuGui then menuGui:Destroy() menuGui = nil end
    end)

    local y = 50
    local btnH = 40
    local padding = 12

    -- Fly&Noclip
    local function addToggle(name, key, ypos, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.44, 0, 0, btnH)
        btn.Position = UDim2.new(key=="Fly" and 0.04 or 0.52, 0, 0, ypos)
        btn.Text = (toggles[key] and "✔️ " or "❌ ")..name
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = toggles[key] and Color3.fromRGB(85,255,85) or Color3.fromRGB(210,210,210)
        btn.BackgroundColor3 = toggles[key] and Color3.fromRGB(32,44,32) or Color3.fromRGB(38,38,38)
        btn.BorderSizePixel = 0
        btn.Parent = frame
        btn.AutoButtonColor = true
        btn.MouseButton1Click:Connect(function()
            toggles[key] = not toggles[key]
            callback(toggles[key])
            createMenu()
        end)
    end

    addToggle("Fly", "Fly", y, setFly)
    addToggle("Noclip", "Noclip", y, setNoclip)
    y = y + btnH + padding

    -- Meyve Seçmeyi Hazırla - GÖRÜNÜR ve net!
    local fruits = getFruitsOnMap()
    if #fruits == 0 then fruits = knownFruits() end

    local fruitLbl = Instance.new("TextLabel")
    fruitLbl.Text = "Meyve Seç:"
    fruitLbl.TextSize = 19
    fruitLbl.TextColor3 = Color3.fromRGB(255,255,187)
    fruitLbl.BackgroundTransparency = 1
    fruitLbl.Size = UDim2.new(0,100,0,btnH)
    fruitLbl.Position = UDim2.new(0,14,0,y)
    fruitLbl.Font = Enum.Font.GothamBold
    fruitLbl.Parent = frame

    -- Dropdown (her zaman SEÇİLEBİLİR ve net görünür)
    local fruitDropdown = Instance.new("Frame")
    fruitDropdown.Size = UDim2.new(0,220,0,btnH)
    fruitDropdown.Position = UDim2.new(0,110,0,y)
    fruitDropdown.BackgroundColor3 = Color3.fromRGB(41,44,59)
    fruitDropdown.BorderSizePixel = 0
    fruitDropdown.Parent = frame
    fruitDropdown.ClipsDescendants = true

    local currentFruitBtn = Instance.new("TextButton")
    currentFruitBtn.Size = UDim2.new(1,0,1,0)
    currentFruitBtn.Position = UDim2.new(0,0,0,0)
    currentFruitBtn.BackgroundTransparency = 1
    currentFruitBtn.Font = Enum.Font.GothamBold
    currentFruitBtn.Text = fruitEspSelection or (fruits[1] or "MeyveSeçiniz")
    currentFruitBtn.TextColor3 = Color3.fromRGB(200,236,255)
    currentFruitBtn.TextScaled = true
    currentFruitBtn.Parent = fruitDropdown

    -- Açılır Panel
    local dropFrame = Instance.new("Frame")
    dropFrame.BackgroundColor3 = Color3.fromRGB(29,30,50)
    dropFrame.BorderSizePixel = 0
    dropFrame.Position = UDim2.new(0,0,1,2)
    local showCount = math.min(10,#fruits)
    dropFrame.Size = UDim2.new(1,0,0,showCount*30)
    dropFrame.Visible = false
    dropFrame.Parent = fruitDropdown
    dropFrame.ZIndex = 20
    dropFrame.Active = true

    local fruitLayout = Instance.new("UIListLayout", dropFrame)
    fruitLayout.Padding = UDim.new(0,0)
    fruitLayout.SortOrder = Enum.SortOrder.LayoutOrder
    fruitLayout.FillDirection = Enum.FillDirection.Vertical

    -- Her meyve için net label buton - GÖRÜNÜR
    for i,fruit in ipairs(fruits) do
        local b = Instance.new("TextButton")
        b.Text = tostring(fruit)
        b.Size = UDim2.new(1,0,0,29)
        b.Font = Enum.Font.Gotham
        b.TextColor3 = Color3.fromRGB(235,235,160)
        b.TextSize = 16
        b.BackgroundTransparency = 0
        b.BackgroundColor3 = Color3.fromRGB(45,49,71)
        b.BorderSizePixel = 0
        b.Parent = dropFrame
        b.ZIndex = 22
        b.MouseButton1Click:Connect(function()
            fruitEspSelection = fruit
            dropFrame.Visible = false
            createMenu()
        end)
    end

    currentFruitBtn.MouseButton1Click:Connect(function()
        dropFrame.Visible = not dropFrame.Visible
    end)

    y = y + btnH + padding

    -- MEYVE ESP (seçili için)
    local fruitEspBtn = Instance.new("TextButton")
    fruitEspBtn.AnchorPoint = Vector2.new(0.5,0)
    fruitEspBtn.Size = UDim2.new(0, 360, 0, btnH)
    fruitEspBtn.Position = UDim2.new(0.5,0,0,y)
    fruitEspBtn.Font = Enum.Font.GothamBold
    fruitEspBtn.TextSize = 18
    fruitEspBtn.Text = "Seçili Meyveyi Mapte Göster (ESP)"
    fruitEspBtn.TextColor3 = Color3.fromRGB(38, 255, 100)
    fruitEspBtn.BackgroundColor3 = Color3.fromRGB(44,44,52)
    fruitEspBtn.BorderSizePixel = 0
    fruitEspBtn.Parent = frame
    fruitEspBtn.MouseButton1Click:Connect(function()
        setFruitESP(fruitEspSelection)
    end)

    y = y + btnH + padding

    -- MEYVE TP
    local tpBtn = Instance.new("TextButton")
    tpBtn.AnchorPoint = Vector2.new(0.5,0)
    tpBtn.Size = UDim2.new(0, 360, 0, btnH)
    tpBtn.Position = UDim2.new(0.5,0,0,y)
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 19
    tpBtn.TextColor3 = Color3.fromRGB(200,240,255)
    tpBtn.BackgroundColor3 = Color3.fromRGB(59, 62, 103)
    tpBtn.BorderSizePixel = 0
    tpBtn.Text = "Seçili Meyveye TP ve Al"
    tpBtn.Parent = frame
    tpBtn.MouseButton1Click:Connect(function()
        tpToFruitAndPickup(fruitEspSelection)
    end)
end

-- Hotkey
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and (
        input.KeyCode == Enum.KeyCode.F4 or
        input.KeyCode == Enum.KeyCode.Insert or
        input.KeyCode == Enum.KeyCode.RightControl
    ) then
        if menuGui and menuGui.Parent then
            menuGui:Destroy()
            menuGui = nil
        else
            createMenu()
        end
    end
end)

local tries = 0
local function safeCreate()
    if menuGui and menuGui.Parent then return end
    tries = tries + 1
    createMenu()
    if (not menuGui or not menuGui.Parent) and tries < 4 then
        task.wait(0.7)
        safeCreate()
    end
end
safeCreate()
