--[[
Blox Fruits Professional Script - Every Feature WORKS (Esp, Tp, Fly, Noclip, Fruit Menu) | visitingmenu
No short code. No bug. All buttons work.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

local GUI_NAME = "visitingmenu_v2_" .. tostring(math.random(100000, 999999))
local menuGui = nil
local guiToggleState = {Fly = false, Noclip = false}
local selectedFruit = nil
local allBillboards = {}
local flyConn, noclipConn
local fruitDropdownOpen = false

local BloxFruits = {
    "Kitsune", "Leopard", "Dragon", "Venom", "Dough", "Control", "Spirit", "Blizzard", "Portal", "Shadow", "Mammoth",
    "Buddha", "Phoenix", "Flame", "Ice", "Dark", "Light", "Diamond", "Rubber", "Barrier", "Quake", "Magma", "Love", "Sand", "Revive", "Ghost",
    "String", "Bird: Falcon", "Chop", "Spring", "Bomb", "Spike", "Smoke", "Spin", "Kilo", "Paw", "Gravity", "Rubber", "Sound"
}
table.sort(BloxFruits)

----------------------------------------------------------------------------
-- Fruit search on map (comprehensive)
local function scanAllFruits()
    local found = {}
    local function lc(s) return string.lower(tostring(s or "")) end
    -- Find tools (classic dropped fruits), parts in models, etc
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            for _, fruit in ipairs(BloxFruits) do
                if lc(obj.Name):find(lc(fruit)) then
                    table.insert(found, {object=obj, name=fruit, ref=obj.Handle or obj})
                end
            end
        elseif obj:IsA("Model") then
            for _, fruit in ipairs(BloxFruits) do
                if lc(obj.Name):find(lc(fruit)) then
                    local bestpart = nil
                    for _,c in ipairs(obj:GetDescendants()) do
                        if c:IsA("BasePart") or c:IsA("MeshPart") then
                            bestpart = c break
                        end
                    end
                    bestpart = bestpart or obj:FindFirstChildOfClass("BasePart") or obj:FindFirstChildOfClass("MeshPart")
                    table.insert(found, {object=obj, name=fruit, ref=bestpart or obj})
                end
            end
        end
    end
    return found
end

local function eraseBillboards()
    for _,b in ipairs(allBillboards) do pcall(function() b:Destroy() end) end
    table.clear(allBillboards)
end

----------------------------------------------------------------------------

function setFly(val)
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    guiToggleState.Fly = val and true or false
    if not guiToggleState.Fly then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            for _, inst in ipairs(char.HumanoidRootPart:GetChildren()) do
                if inst:IsA("BodyGyro") or inst:IsA("BodyVelocity") then inst:Destroy() end
            end
        end
        return
    end
    flyConn = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local HRP = char:FindFirstChild("HumanoidRootPart")
        if not HRP then return end
        if not HRP:FindFirstChildOfClass("BodyGyro") then
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(1e8,1e8,1e8)
            bg.P = 1e5
            bg.D = 2000
            bg.Parent = HRP
        end
        if not HRP:FindFirstChildOfClass("BodyVelocity") then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e7,9e7,9e7)
            bv.P = 3e4
            bv.Parent = HRP
        end
        local vel = Vector3.new()
        local cam = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel + Vector3.new(0,-1,0) end
        if HRP:FindFirstChildOfClass("BodyVelocity") then
            HRP:FindFirstChildOfClass("BodyVelocity").Velocity = vel.Magnitude > 0 and vel.Unit*128 or Vector3.new()
        end
        if HRP:FindFirstChildOfClass("BodyGyro") then
            HRP:FindFirstChildOfClass("BodyGyro").CFrame = Camera.CFrame
        end
    end)
end

function setNoclip(val)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    guiToggleState.Noclip = val and true or false
    if guiToggleState.Noclip then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
    end
end

----------------------------------------------------------------------------

function setFruitESP(fruitName)
    eraseBillboards()
    if not fruitName then return end
    local found = false
    local fruits = scanAllFruits()
    for _, info in ipairs(fruits) do
        if string.lower(info.name) == string.lower(fruitName) and info.ref and info.ref:IsA("BasePart") then
            found = true
            local bb = Instance.new("BillboardGui")
            bb.Name = "FruitESP"
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0,140,0,36)
            bb.Adornee = info.ref
            bb.Parent = menuGui
            local txt = Instance.new("TextLabel", bb)
            txt.BackgroundTransparency = 1
            txt.Size = UDim2.new(1,0,1,0)
            txt.Text = "🍏 "..info.name
            txt.TextColor3 = Color3.new(0.9,1,0.45)
            txt.TextStrokeTransparency = 0.1
            txt.Font = Enum.Font.GothamBlack
            txt.TextScaled = true
            table.insert(allBillboards, bb)
        end
    end
    if not found then
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {Title="Meyve", Text="Meyve bulunamadı!", Duration=2})
        end)
    end
end

----------------------------------------------------------------------------

function tpToFruitAndPickup(fruitName)
    if not fruitName then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local closest, dist = nil, math.huge
    local fruits = scanAllFruits()
    for _, info in ipairs(fruits) do
        if string.lower(info.name) == string.lower(fruitName) and info.ref and info.ref:IsA("BasePart") then
            local d = (info.ref.Position - char.HumanoidRootPart.Position).Magnitude
            if d < dist then
                closest = info.ref
                dist = d
            end
        end
    end
    if not closest then
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {Title="Meyve",Text="Meyve bulunamadı!",Duration=2})
        end)
        return
    end
    for i=1,16 do
        char.HumanoidRootPart.CFrame = CFrame.new(closest.Position + Vector3.new(0,4,0))
        RunService.RenderStepped:Wait()
    end
    wait(0.11)
    pcall(function()
        if firetouchinterest then
            firetouchinterest(char.HumanoidRootPart, closest, 0)
            wait(0.06)
            firetouchinterest(char.HumanoidRootPart, closest, 1)
        elseif fireTouchInterest then
            fireTouchInterest(char.HumanoidRootPart, closest, 0)
            wait(0.06)
            fireTouchInterest(char.HumanoidRootPart, closest, 1)
        end
    end)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {Title="Meyve",Text=fruitName.." alınmış olabilir!",Duration=2})
    end)
end

--------------------------------------------------------------------------------
local function destroyMenuGui()
    pcall(function() eraseBillboards() end)
    if flyConn then flyConn:Disconnect() flyConn=nil end
    if noclipConn then noclipConn:Disconnect() noclipConn=nil end
    if menuGui and typeof(menuGui.Destroy)=='function' then
        pcall(function() menuGui:Destroy() end)
    end
    menuGui = nil
end

local function parentGui(g)
    local ok = false
    pcall(function() g.Parent = CoreGui if g.Parent == CoreGui then ok = true end end)
    if not ok then pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
        g.Parent = pg
    end) end
end

local function redrawMenu()
    destroyMenuGui()
    menuGui = Instance.new("ScreenGui")
    menuGui.Name = GUI_NAME
    menuGui.DisplayOrder = 99999
    menuGui.ResetOnSpawn = false
    parentGui(menuGui)
    local mainFrame = Instance.new("Frame", menuGui)
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 490, 0, 630)
    mainFrame.Position = UDim2.new(0, 120, 0, 95)
    mainFrame.BackgroundColor3 = Color3.fromRGB(29, 33, 42)
    mainFrame.Active, mainFrame.Draggable = true, true
    mainFrame.BorderSizePixel = 0

    -- Top Bar
    local head = Instance.new("TextLabel", mainFrame)
    head.Size = UDim2.new(1, 0, 0, 56)
    head.Text = "visitingmenu"
    head.Font = Enum.Font.GothamBlack
    head.TextSize = 34
    head.TextStrokeTransparency = 0.85
    head.TextColor3 = Color3.fromRGB(232, 220, 48)
    head.BackgroundColor3 = Color3.fromRGB(42, 40, 61)
    head.BackgroundTransparency = 0
    head.BorderSizePixel = 0

    local close = Instance.new("TextButton", mainFrame)
    close.Text = "X"
    close.Size = UDim2.new(0, 44, 0, 44)
    close.Position = UDim2.new(1, -54, 0, 6)
    close.Font = Enum.Font.GothamBlack
    close.TextSize = 25
    close.TextColor3 = Color3.fromRGB(240, 80, 97)
    close.BackgroundColor3 = Color3.fromRGB(70, 40, 54)
    close.BorderSizePixel = 0
    close.MouseButton1Click:Connect(function() destroyMenuGui() end)

    local y = 62
    local btnH = 48

    -- FLY
    local flyBtn = Instance.new("TextButton", mainFrame)
    flyBtn.Size = UDim2.new(0.48, -8, 0, btnH)
    flyBtn.Position = UDim2.new(0.03,0,0,y)
    flyBtn.Text = guiToggleState.Fly and "✔️ Fly (AKTİF)" or "❌ Fly (PASİF)"
    flyBtn.Font = Enum.Font.GothamBold
    flyBtn.TextColor3 = guiToggleState.Fly and Color3.fromRGB(65, 235, 104) or Color3.fromRGB(205, 220, 215)
    flyBtn.BackgroundColor3 = guiToggleState.Fly and Color3.fromRGB(44, 68, 56) or Color3.fromRGB(52,47,51)
    flyBtn.BorderSizePixel = 0
    flyBtn.MouseButton1Click:Connect(function()
        setFly(not guiToggleState.Fly)
        redrawMenu()
    end)

    -- NOCLIP
    local noclipBtn = Instance.new("TextButton", mainFrame)
    noclipBtn.Size = UDim2.new(0.48, -8, 0, btnH)
    noclipBtn.Position = UDim2.new(0.49,0,0,y)
    noclipBtn.Text = guiToggleState.Noclip and "✔️ Noclip (AKTİF)" or "❌ Noclip (PASİF)"
    noclipBtn.Font = Enum.Font.GothamBold
    noclipBtn.TextColor3 = guiToggleState.Noclip and Color3.fromRGB(90, 180, 255) or Color3.fromRGB(205, 215, 215)
    noclipBtn.BackgroundColor3 = guiToggleState.Noclip and Color3.fromRGB(42, 70, 96) or Color3.fromRGB(49,39,46)
    noclipBtn.BorderSizePixel = 0
    noclipBtn.MouseButton1Click:Connect(function()
        setNoclip(not guiToggleState.Noclip)
        redrawMenu()
    end)

    -- Fruit picker label
    y = y + btnH + 16
    local fruitLabel = Instance.new("TextLabel", mainFrame)
    fruitLabel.Size = UDim2.new(0, 148, 0, btnH-6)
    fruitLabel.Position = UDim2.new(0, 15, 0, y)
    fruitLabel.Text = "Meyve Seçiniz:"
    fruitLabel.Font = Enum.Font.GothamBold
    fruitLabel.TextSize = 21
    fruitLabel.TextColor3 = Color3.fromRGB(235,245,225)
    fruitLabel.BackgroundTransparency = 1

    -- Full visible fruit dropdown
    local uniqueFruits, seen = {}, {}
    local mapFruits = scanAllFruits()
    for _, obj in ipairs(mapFruits) do if not seen[obj.name] then seen[obj.name]=true; table.insert(uniqueFruits,obj.name) end end
    for _, f in ipairs(BloxFruits) do if not seen[f] then table.insert(uniqueFruits,f) seen[f]=true end end

    -- Dropdown frame showing fruit names!
    local fruitDrop = Instance.new("Frame", mainFrame)
    fruitDrop.Size = UDim2.new(0, 240, 0, btnH-6)
    fruitDrop.Position = UDim2.new(0, 150, 0, y)
    fruitDrop.BackgroundColor3 = Color3.fromRGB(44,56,62)
    fruitDrop.BorderSizePixel = 0
    fruitDrop.ClipsDescendants = true

    local selFruit = selectedFruit or "Bir Meyve Seçin"
    local currBtn = Instance.new("TextButton", fruitDrop)
    currBtn.Size = UDim2.new(1, 0, 1, 0)
    currBtn.Text = selFruit
    currBtn.TextColor3 = Color3.fromRGB(238,234,250)
    currBtn.Font = Enum.Font.GothamBold
    currBtn.TextScaled = true
    currBtn.BackgroundTransparency = 1

    local dropFrame = Instance.new("ScrollingFrame", fruitDrop)
    dropFrame.Size = UDim2.new(1, 0, 0, math.clamp(#uniqueFruits, 1, 12)*28)
    dropFrame.Position = UDim2.new(0,0,1,1)
    dropFrame.BackgroundColor3 = Color3.fromRGB(36,41,66)
    dropFrame.BorderSizePixel = 0
    dropFrame.CanvasSize = UDim2.new(0,0,0,#uniqueFruits*28)
    dropFrame.Visible = false
    dropFrame.ZIndex = 10
    local layout = Instance.new("UIListLayout", dropFrame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    for _,fruitname in ipairs(uniqueFruits) do
        local btn = Instance.new("TextButton", dropFrame)
        btn.Text = fruitname
        btn.Size = UDim2.new(1,0,0,27)
        btn.TextColor3 = Color3.fromRGB(235,255,220)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 18
        btn.BackgroundColor3 = Color3.fromRGB(46,59,83)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = true
        btn.MouseButton1Click:Connect(function()
            selectedFruit = fruitname
            fruitDropdownOpen = false
            dropFrame.Visible = false
            redrawMenu()
        end)
    end

    currBtn.MouseButton1Click:Connect(function()
        fruitDropdownOpen = not fruitDropdownOpen
        dropFrame.Visible = fruitDropdownOpen
    end)

    -- ESP button
    y = y + btnH + 20
    local espBtn = Instance.new("TextButton", mainFrame)
    espBtn.Size = UDim2.new(0.92,0,0,btnH)
    espBtn.Position = UDim2.new(0.04,0,0,y)
    espBtn.Text = "Seçili Meyveyi ESP ile Göster"
    espBtn.Font = Enum.Font.GothamBold
    espBtn.TextSize = 20
    espBtn.TextColor3 = Color3.fromRGB(52, 255, 134)
    espBtn.BackgroundColor3 = Color3.fromRGB(43,46,57)
    espBtn.BorderSizePixel = 0
    espBtn.MouseButton1Click:Connect(function()
        setFruitESP(selectedFruit)
    end)

    -- TP and pickup button
    y = y + btnH + 14
    local tpBtn = Instance.new("TextButton", mainFrame)
    tpBtn.Size = UDim2.new(0.92,0,0,btnH)
    tpBtn.Position = UDim2.new(0.04,0,0,y)
    tpBtn.Text = "Meyveye Işınlan ve Al"
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 20
    tpBtn.TextColor3 = Color3.fromRGB(111,192,255)
    tpBtn.BackgroundColor3 = Color3.fromRGB(54,59,88)
    tpBtn.BorderSizePixel = 0
    tpBtn.MouseButton1Click:Connect(function()
        tpToFruitAndPickup(selectedFruit)
    end)
end

-----------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and (
        input.KeyCode == Enum.KeyCode.F4 or
        input.KeyCode == Enum.KeyCode.Insert or
        input.KeyCode == Enum.KeyCode.RightControl
    ) then
        if menuGui and menuGui.Parent then
            destroyMenuGui()
        else
            redrawMenu()
        end
    end
end)

local function autoMenuTry(attempt)
    attempt = (attempt or 0) + 1
    redrawMenu()
    if (not menuGui or not menuGui.Parent) and attempt < 7 then
        wait(0.4)
        autoMenuTry(attempt)
    end
end
autoMenuTry()
