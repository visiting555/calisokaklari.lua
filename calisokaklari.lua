--[[
Blox Fruits Script v3.1
- Menü başlığı "visitingmenu"
- Fly, Noclip, meyve seç/Tp/ESP
- Meyve listesi her zaman dolu ve güncel! 
]]

-- SERVİSLER ve DEĞİŞKENLER
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera

local guiName = "BFPRO_" .. tostring(math.random(10000000, 99999999))
local menuGui = nil
local toggles = {Fly=false, Noclip=false, FruitESP=false}
local fruitEspSelection = nil
local fruitEspBillboards = {}
local flyConn, noclipConn = nil, nil
local flying, noclipping = false, false

------------------------------------------------
-- STATİK ve DİNAMİK ENTEGRE MEYVE LİSTESİ
local function knownFruits()
    -- Statik olarak ekli en popüler Blox Fruits meyveleri:
    return {
        "Kitsune", "Dragon", "Leopard", "Venom", "Dough", "Spirit", "Magma", "Light", "Dark", "Flame",
        "Quake", "Human: Buddha", "Ice", "Phoenix", "Mammoth", "Love", "Spider", "Portal", "Barrier",
        "Rubber", "Sand", "Diamond", "Ghost", "Sound", "Falcon", "Spin", "Bomb", "Spring", "Chop", "Revive", "Smoke", "Spike", "Kilo"
    }
end

local function getFruitsOnMap()
    local found = {}
    local already = {}
    -- Workspace'teki meyveleri searchle
    for _,obj in ipairs(Workspace:GetDescendants()) do
        local n = tostring(obj.Name)
        if (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart")) and n:lower():find("fruit") then
            if not already[n] then table.insert(found, n) already[n] = true end
        end
    end
    -- Statik meyveleri ekle (listede yoksa)
    for _,fruit in ipairs(knownFruits()) do
        if not already[fruit] then table.insert(found, fruit) already[fruit] = true end
    end
    table.sort(found)
    return found
end

-- DEVAMLI GUI SİLME KONTROLÜ (CoreGui ve PlayerGui için!)
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

-- FORCE PARENT (başarısızsa PlayerGui'ya dener)
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

-- GUI OLUŞTURMA (Her zaman açılır/fallback ile)
local function createMenu()
    if menuGui then pcall(function() menuGui:Destroy() end) end

    menuGui = Instance.new("ScreenGui")
    menuGui.ResetOnSpawn = false
    menuGui.DisplayOrder = 9e6
    menuGui.Name = guiName

    robustParent(menuGui)

    if not menuGui.Parent then
        warn("[BFPRO] Menü yüklenemedi! CoreGui ve PlayerGui başarısız.")
        return
    end

    -- Menü frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 415, 0, 480)
    frame.Position = UDim2.new(0, 60, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(25,28,38)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = menuGui

    -- Başlık GÜNCELLENDİ
    local title = Instance.new("TextLabel")
    title.Text = "visitingmenu"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(220,190,50)
    title.TextScaled = true
    title.Size = UDim2.new(1,0,0,42)
    title.BackgroundTransparency = 1
    title.Parent = frame

    -- Kapat tuşu
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

    local y = 54
    local btnH = 40
    local padding = 10

    -- Toggle aracı
    local function addToggle(name, key, ypos, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 175, 0, btnH)
        btn.Position = UDim2.new(0, 18 + (key~="Fly" and 200 or 0), 0, ypos)
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

    addToggle("Fly", "Fly", y, function(val) setFly(val) end)
    addToggle("Noclip", "Noclip", y, function(val) setNoclip(val) end)
    y = y + btnH + padding

    -- MEYVE LİSTESİ HER ZAMAN VAR
    local dynamicFruits = getFruitsOnMap()

    -- Meyve seçme:
    local fruitLbl = Instance.new("TextLabel")
    fruitLbl.Text = "Meyve Seç: "
    fruitLbl.TextSize = 17
    fruitLbl.TextColor3 = Color3.fromRGB(255,255,187)
    fruitLbl.BackgroundTransparency = 1
    fruitLbl.Size = UDim2.new(0,100,0,btnH)
    fruitLbl.Position = UDim2.new(0,14,0,y)
    fruitLbl.Font = Enum.Font.GothamBold
    fruitLbl.Parent = frame

    local fruitDropdown = Instance.new("TextButton")
    fruitDropdown.Size = UDim2.new(0,220,0,btnH)
    fruitDropdown.Position = UDim2.new(0,98,0,y)
    fruitDropdown.Text = fruitEspSelection or (dynamicFruits[1] or "Meyve yok")
    fruitDropdown.Font = Enum.Font.Gotham
    fruitDropdown.TextColor3 = Color3.fromRGB(240,240,240)
    fruitDropdown.BackgroundColor3 = Color3.fromRGB(39,41,50)
    fruitDropdown.Parent = frame

    local dropdownOpen = false
    local fruitListFrame = Instance.new("ScrollingFrame")
    fruitListFrame.Parent = frame
    fruitListFrame.Size = UDim2.new(0,220,0, math.min(#dynamicFruits,7)*32+2)
    fruitListFrame.Position = fruitDropdown.Position + UDim2.new(0,0,0,btnH+2)
    fruitListFrame.CanvasSize = UDim2.new(0,0,0,#dynamicFruits*32)
    fruitListFrame.BackgroundColor3 = Color3.fromRGB(34,34,48)
    fruitListFrame.Visible = false
    fruitListFrame.ZIndex = 2
    fruitListFrame.BorderSizePixel = 0
    fruitListFrame.ScrollBarThickness = 6

    -- Dinamik, HER ZAMAN LİSTEYİ OLUŞTUR
    for i,fruit in ipairs(dynamicFruits) do
        local fbtn = Instance.new("TextButton")
        fbtn.Size = UDim2.new(1,0,0,32)
        fbtn.Position = UDim2.new(0, 0, 0, (i-1)*32)
        fbtn.Font = Enum.Font.Gotham
        fbtn.Text = fruit
        fbtn.TextSize = 16
        fbtn.BackgroundColor3 = Color3.fromRGB(55,55,60)
        fbtn.TextColor3 = Color3.fromRGB(235,235,170)
        fbtn.Parent = fruitListFrame
        fbtn.AutoButtonColor = true
        fbtn.MouseButton1Click:Connect(function()
            fruitEspSelection = fruit
            dropdownOpen = false
            fruitListFrame.Visible = false
            createMenu()
        end)
    end

    fruitDropdown.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        fruitListFrame.Visible = dropdownOpen
    end)

    y = y + btnH + (#dynamicFruits > 7 and 220 or 150)

    -- ESP Butonu
    local fruitEspBtn = Instance.new("TextButton")
    fruitEspBtn.AnchorPoint = Vector2.new(0.5,0)
    fruitEspBtn.Size = UDim2.new(0, 360, 0, btnH)
    fruitEspBtn.Position = UDim2.new(0.5,0,0,y)
    fruitEspBtn.Font = Enum.Font.GothamBold
    fruitEspBtn.TextSize = 18
    fruitEspBtn.Text = (toggles.FruitESP and "✔️ " or "❌ ") .. "Seçili Meyve ESP"
    fruitEspBtn.TextColor3 = toggles.FruitESP and Color3.fromRGB(70,255,120) or Color3.fromRGB(210,210,210)
    fruitEspBtn.BackgroundColor3 = Color3.fromRGB(44,44,52)
    fruitEspBtn.BorderSizePixel = 0
    fruitEspBtn.Parent = frame
    fruitEspBtn.MouseButton1Click:Connect(function()
        toggles.FruitESP = not toggles.FruitESP
        setFruitESP(toggles.FruitESP)
        createMenu()
    end)

    y = y + btnH + padding

    -- TP Butonu
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
        tpToFruitAndPickup()
    end)
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

function setFruitESP(on)
    destroyTable(fruitEspBillboards)
    if not on or not fruitEspSelection then return end
    for _,obj in pairs(Workspace:GetDescendants()) do
        local name = tostring(obj.Name or "")
        if string.lower(name) == string.lower(fruitEspSelection) then
            local handle = obj:FindFirstChild("Handle") or (obj:IsA("Tool") and obj:FindFirstChildOfClass("Part"))
            if handle then
                local bill = Instance.new("BillboardGui", menuGui)
                bill.AlwaysOnTop = true
                bill.Size = UDim2.new(0,120,0,44)
                bill.Adornee = handle
                local lbl = Instance.new("TextLabel", bill)
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.Text = obj.Name.." 🌟"
                lbl.TextColor3 = Color3.fromRGB(255,235,60)
                lbl.Font = Enum.Font.GothamBold
                lbl.TextScaled = true
                fruitEspBillboards[#fruitEspBillboards+1] = bill
            end
        end
    end
    if not setFruitESP._connAdded then
        setFruitESP._connAdded = true
        Workspace.DescendantAdded:Connect(function(_)
            if toggles.FruitESP then setFruitESP(true) end
        end)
        Workspace.DescendantRemoving:Connect(function(_)
            if toggles.FruitESP then setFruitESP(true) end
        end)
    end
end

function tpToFruitAndPickup()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local pos, target = nil, nil
    for _,obj in pairs(Workspace:GetDescendants()) do
        local name = tostring(obj.Name or "")
        if fruitEspSelection and string.lower(name) == string.lower(fruitEspSelection) then
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
            Text=fruitEspSelection.." alındı (veya çok yakında olabilir)!",
            Duration=2
        })
    end)
end

-- HOTKEY, Gelişmiş fallback! Önce menü parent check eder, yoksa yeniden açar!
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

-- Otomatik başlatıcı/fallback loop: Menü açılmazsa 3 kez daha dener!
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
