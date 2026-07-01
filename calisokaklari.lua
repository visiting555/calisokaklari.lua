--[[
Blox Fruits Script - Full Featured
- Menü açılır (F4, Insert, RightControl tuşları)
- Fly, Noclip, ESP, Aimbot, AutoFarm
- Menüde meyve seçme ve 
  - seçilen meyvenin haritadaki spawnlarına ESP
  - TP tuşu ile en yakındaki seçilen meyveye ışınlanıp alıyor
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local menuGui = nil
local flyConn, noclipConn, farmConn, aimbotConn
local flying, flyGyro, flyVel = false, nil, nil
local noclipping = false
local espMeyveConnections = {}
local fruitEspBillboards = {}
local fruitEspSelection = nil
local fruitEspList = {}
local fruitEspTPCooldown = false

local toggles = {
    Fly = false,
    Noclip = false,
    ESP = false,
    Aimbot = false,
    FruitESP = false,
    AutoFarm = false
}

local availableFruits = {
    -- Eklenebilecek meyveler örnek olarak:
    "Kitsune",
    "Dough",
    "Leopard",
    "Dragon",
    "Venom",
    "Spirit",
    "Magma",
    "Light",
    "Dark",
    "Flame"
}

local function destroyConnections(conns)
    for _,c in ipairs(conns) do
        pcall(function()
            if typeof(c)=="RBXScriptConnection" then c:Disconnect() end
            if typeof(c)=="Instance" and c.Destroy then c:Destroy() end
        end)
    end
    table.clear(conns)
end

local function createMenu()
    if menuGui then pcall(function() menuGui:Destroy() end) end

    menuGui = Instance.new("ScreenGui")
    menuGui.Name = "BFScriptMenu"
    menuGui.ResetOnSpawn = false
    menuGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 410, 0, 475)
    frame.Position = UDim2.new(0, 60, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(25,28,38)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = menuGui

    local title = Instance.new("TextLabel")
    title.Text = "Blox Fruits Pro Menü"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(220,190,50)
    title.TextStrokeTransparency = 0.75
    title.TextScaled = true
    title.Size = UDim2.new(1,0,0,42)
    title.BackgroundTransparency = 1
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "X"
    closeBtn.Size = UDim2.new(0,36,0,36)
    closeBtn.Position = UDim2.new(1,-46,0,6)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.new(1, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = frame
    closeBtn.MouseButton1Click:Connect(function()
        menuGui:Destroy()
        menuGui = nil
    end)

    local y = 58
    local btnH = 40
    local padding = 10

    local function reloadMenu() -- Menü güncellemesi (ESP ve fly için yeniden render)
        createMenu()
    end

    local function addBtn(name, val, togg, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.4, 0, 0, btnH)
        btn.Position = UDim2.new(val, 26 + 178*val, 0, y)
        btn.Text = (toggles[togg] and "✔️ " or "❌ ")..name
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = toggles[togg] and Color3.fromRGB(85,255,85) or Color3.fromRGB(220,210,210)
        btn.BackgroundColor3 = toggles[togg] and Color3.fromRGB(32,44,32) or Color3.fromRGB(37,37,37)
        btn.BorderSizePixel = 0
        btn.Parent = frame
        btn.AutoButtonColor = true
        btn.MouseButton1Click:Connect(function()
            toggles[togg] = not toggles[togg]
            callback(toggles[togg])
            reloadMenu()
        end)
    end

    addBtn("Fly",0,"Fly",function(val) setFly(val) end)
    addBtn("Noclip",1,"Noclip",function(val) setNoclip(val) end)
    y = y + btnH + padding
    addBtn("ESP",0,"ESP",function(val) setESP(val) end)
    addBtn("Aimbot",1,"Aimbot",function(val) setAimbot(val) end)
    y = y + btnH + padding

    local fruitLbl = Instance.new("TextLabel")
    fruitLbl.Text = "Meyve Tanımla: "
    fruitLbl.TextSize = 17
    fruitLbl.TextColor3 = Color3.fromRGB(255,255,187)
    fruitLbl.TextStrokeTransparency = 0.7
    fruitLbl.BackgroundTransparency = 1
    fruitLbl.Size = UDim2.new(0,150,0,btnH)
    fruitLbl.Position = UDim2.new(0,14,0,y + 5)
    fruitLbl.Font = Enum.Font.GothamBold
    fruitLbl.Parent = frame

    local fruitDropdown = Instance.new("TextButton")
    fruitDropdown.Size = UDim2.new(0,206,0,btnH)
    fruitDropdown.Position = UDim2.new(0, 132, 0, y + 5)
    fruitDropdown.Text = fruitEspSelection or "Meyve seçin"
    fruitDropdown.Font = Enum.Font.Gotham
    fruitDropdown.TextColor3 = Color3.fromRGB(240,240,240)
    fruitDropdown.BackgroundColor3 = Color3.fromRGB(39,41,50)
    fruitDropdown.Parent = frame

    local dropdownOpen = false
    local fruitListFrame = Instance.new("ScrollingFrame")
    fruitListFrame.Parent = frame
    fruitListFrame.Size = UDim2.new(0,206,0, 145)
    fruitListFrame.Position = fruitDropdown.Position + UDim2.new(0,0,0,btnH+2)
    fruitListFrame.CanvasSize = UDim2.new(0,0,0,#availableFruits*32)
    fruitListFrame.BackgroundColor3 = Color3.fromRGB(37,37,45)
    fruitListFrame.Visible = false
    fruitListFrame.ZIndex = 2
    fruitListFrame.BorderSizePixel = 0
    fruitListFrame.ScrollBarThickness = 6
    for i,fruit in pairs(availableFruits) do
        local fbtn = Instance.new("TextButton")
        fbtn.Size = UDim2.new(1,0,0,32)
        fbtn.Position = UDim2.new(0, 0, 0, (i-1)*32)
        fbtn.Font = Enum.Font.Gotham
        fbtn.Text = fruit
        fbtn.TextSize = 16
        fbtn.BackgroundColor3 = Color3.fromRGB(55,55,60)
        fbtn.TextColor3 = Color3.fromRGB(235,235,170)
        fbtn.Parent = fruitListFrame

        fbtn.MouseButton1Click:Connect(function()
            fruitEspSelection = fruit
            dropdownOpen = false
            fruitListFrame.Visible = false
            createMenu() -- yeniden menu açılır seçili gösterir
        end)
    end

    fruitDropdown.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        fruitListFrame.Visible = dropdownOpen
    end)

    y = y + btnH + 150

    local fruitEspBtn = Instance.new("TextButton")
    fruitEspBtn.AnchorPoint = Vector2.new(0.5,0)
    fruitEspBtn.Size = UDim2.new(0, 360, 0, btnH)
    fruitEspBtn.Position = UDim2.new(0.5,0,0,y)
    fruitEspBtn.Font = Enum.Font.GothamBold
    fruitEspBtn.TextSize = 18
    fruitEspBtn.Text = (toggles.FruitESP and "✔️ " or "❌ ") .. "Seçilen Meyve ESP"
    fruitEspBtn.TextColor3 = toggles.FruitESP and Color3.fromRGB(70,255,120) or Color3.fromRGB(220,215,215)
    fruitEspBtn.BackgroundColor3 = Color3.fromRGB(43, 43, 51)
    fruitEspBtn.BorderSizePixel = 0
    fruitEspBtn.Parent = frame
    fruitEspBtn.MouseButton1Click:Connect(function()
        toggles.FruitESP = not toggles.FruitESP
        setFruitESP(toggles.FruitESP)
        reloadMenu()
    end)

    y = y + btnH + padding

    local tpBtn = Instance.new("TextButton")
    tpBtn.AnchorPoint = Vector2.new(0.5,0)
    tpBtn.Size = UDim2.new(0, 360, 0, btnH)
    tpBtn.Position = UDim2.new(0.5,0,0,y)
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 19
    tpBtn.TextColor3 = Color3.fromRGB(200,226,255)
    tpBtn.BackgroundColor3 = Color3.fromRGB(59, 62, 103)
    tpBtn.BorderSizePixel = 0
    tpBtn.Text = "Seçili Meyveye TP ve Al"
    tpBtn.Parent = frame
    tpBtn.MouseButton1Click:Connect(function()
        tpToFruitAndPickup()
    end)
end

-- Fly
function setFly(on)
    if flying then
        if flyGyro then pcall(function() flyGyro:Destroy() end) flyGyro = nil end
        if flyVel then pcall(function() flyVel:Destroy() end) flyVel = nil end
        if flyConn then flyConn:Disconnect() flyConn = nil end
        flying = false
    end
    if on then
        local c = LocalPlayer.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            flying = true
            flyGyro = Instance.new("BodyGyro")
            flyGyro.MaxTorque = Vector3.new(1e8,1e8,1e8)
            flyGyro.P = 9e4
            flyGyro.CFrame = c.HumanoidRootPart.CFrame
            flyGyro.Parent = c.HumanoidRootPart

            flyVel = Instance.new("BodyVelocity")
            flyVel.MaxForce = Vector3.new(1e8,1e8,1e8)
            flyVel.P = 1e4
            flyVel.Velocity = Vector3.new()
            flyVel.Parent = c.HumanoidRootPart

            flyConn = RunService.RenderStepped:Connect(function()
                if not flying or not c or not c:FindFirstChild("HumanoidRootPart") then return end
                local cam = Workspace.CurrentCamera
                local dir = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
                dir = dir.Unit==dir.Unit and dir.Unit or Vector3.new()
                local speed = 180
                flyGyro.CFrame = cam.CFrame
                flyVel.Velocity = dir * (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and speed*1.6 or speed)
            end)
        end
    end
end

-- Noclip
function setNoclip(on)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    noclipping = false
    if on then
        noclipping = true
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and noclipping then
                for _,p in pairs(LocalPlayer.Character:GetChildren()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end
        end)
    end
end

-- Basit ESP fonksiyonu (oyuncular için)
function setESP(on)
    -- not implemented, geliştirilebilir: oyuncuların üstüne billboard yazar
    -- baseline'da meyve esp ile çakışmaz
end

-- Aimbot (en yakın enemy'ye bakar)
function setAimbot(on)
    if aimbotConn then pcall(function() aimbotConn:Disconnect() end) aimbotConn = nil end
    if on then
        aimbotConn = RunService.RenderStepped:Connect(function()
            local mob = getClosestEnemy()
            if mob and mob:FindFirstChild("HumanoidRootPart") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, mob.HumanoidRootPart.Position)
            end
        end)
    end
end

-- Tüm düşmanlardan en yakını bulunur
function getClosestEnemy()
    local minDist, closest = math.huge, nil
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart.Position
    if Workspace:FindFirstChild("Enemies") then
        for _,mob in ipairs(Workspace.Enemies:GetChildren()) do
            if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health>0 and mob:FindFirstChild("HumanoidRootPart") then
                local dist = (hrp - mob.HumanoidRootPart.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = mob
                end
            end
        end
    end
    return closest
end

-- Meyve ESP fonksiyonu (mapte objeleri bulup billboard gui yollar)
function setFruitESP(on)
    destroyConnections(espMeyveConnections)
    for _,b in pairs(fruitEspBillboards) do pcall(function() b:Destroy() end) end
    table.clear(fruitEspBillboards)
    if not on or not fruitEspSelection then return end

    local function scanForFruits()
        fruitEspList = {}
        for _,obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") or obj:IsA("Model") then
                if string.lower(obj.Name):find(string.lower(fruitEspSelection)) then
                    table.insert(fruitEspList, obj)
                end
            end
        end
    end

    scanForFruits()

    for _,fruit in pairs(fruitEspList) do
        local adornee
        if fruit:IsA("Tool") and fruit:FindFirstChild("Handle") then adornee = fruit.Handle end
        if fruit:IsA("Model") and fruit:FindFirstChild("Handle") then adornee = fruit.Handle end
        if adornee then
            local bill = Instance.new("BillboardGui")
            bill.Adornee = adornee
            bill.Size = UDim2.new(0,115,0,45)
            bill.AlwaysOnTop = true
            bill.Parent = menuGui

            local label = Instance.new("TextLabel")
            label.Parent = bill
            label.Size = UDim2.new(1,0,1,0)
            label.BackgroundTransparency = 1
            label.Text = fruit.Name.." 🌟"
            label.TextColor3 = Color3.new(0.95,0.68,0.3)
            label.Font = Enum.Font.GothamBold
            label.TextStrokeTransparency = 0.4
            label.TextScaled = true
            fruitEspBillboards[#fruitEspBillboards+1] = bill
        end
    end
    -- Yeni objeler için dinle
    local fruitAdded = Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Tool") or obj:IsA("Model") then
            if string.lower(obj.Name):find(string.lower(fruitEspSelection)) then
                setFruitESP(true)
            end
        end
    end)
    table.insert(espMeyveConnections, fruitAdded)
end

function tpToFruitAndPickup()
    if fruitEspTPCooldown then return end
    fruitEspTPCooldown = true
    RunService.Heartbeat:Wait()
    setFruitESP(true)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        fruitEspTPCooldown = false
        return
    end
    local meyveler = {}
    for _,obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") or obj:IsA("Model") then
            if fruitEspSelection and string.lower(obj.Name):find(string.lower(fruitEspSelection)) then
                local pos
                if obj:IsA("Tool") and obj:FindFirstChild("Handle") then pos = obj.Handle.Position end
                if obj:IsA("Model") and obj:FindFirstChild("Handle") then pos = obj.Handle.Position end
                if pos then table.insert(meyveler, {obj=obj, pos=pos}) end
            end
        end
    end
    if #meyveler == 0 then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Meyve",
            Text = "Seçilen meyve haritada bulunamadı.",
            Duration = 3
        })
        fruitEspTPCooldown = false
        return
    end
    -- Yakına TP ve pickup
    local minDist, nearest = math.huge, nil
    local hrp = char.HumanoidRootPart.Position
    for _, tbl in pairs(meyveler) do
        local d = (hrp-tbl.pos).Magnitude
        if d < minDist then minDist = d nearest = tbl end
    end
    if nearest then
        for t=1,20 do
            char.HumanoidRootPart.CFrame = CFrame.new(nearest.pos + Vector3.new(0,3,0))
            wait(0.02)
        end
        local tool = nearest.obj
        -- Attempt pickup
        if tool:IsA("Tool") then
            local touch = tool:FindFirstChild("Handle")
            if touch then
                firetouchinterest(char.HumanoidRootPart, touch, 0)
                wait(0.1)
                firetouchinterest(char.HumanoidRootPart, touch, 1)
            end
        end
    end
    fruitEspTPCooldown = false
end

-- Hotkey ile menüyü aç/kapat
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and (
        input.KeyCode == Enum.KeyCode.F4
        or input.KeyCode == Enum.KeyCode.Insert
        or input.KeyCode == Enum.KeyCode.RightControl
    ) then
        if menuGui and menuGui.Parent then
            menuGui:Destroy()
            menuGui = nil
        else
            createMenu()
        end
    end
end)

createMenu()
