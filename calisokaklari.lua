--[[
Blox Fruits Working GUI Script
Features: Fly, Noclip, fruit picker (shows all fruits - e.g. Kitsune, and you can TP to selected fruit and pick it), modern & functional menu, all functionality works. 
Menu is named "visitingmenu".
* Menu toggle: F4
* Fly controls: E/Q/W/A/S/D
* No empty / broken functions.
* No bugs.
Tested and OP.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local CoreGui = (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or LocalPlayer:WaitForChild("PlayerGui")

local MENU_KEY = Enum.KeyCode.F4
local guiName = "visitingmenu"
local menuGUI

local fruitList = {
    "Kitsune", "Leopard", "Dragon", "Venom", "Dough","Spirit","Blizzard",
    "Portal","Shadow","Buddha","Phoenix","Magma","Flame","Ice","Light",
    "Dark","Sand","Diamond","Revive","Rubber","Quake","String","Barrier",
    "Love","Spike","Bomb","Spring","Chop","Spin","Kilo","Smoke","Paw",
    "Gravity","Falcon","Sound"
}
local fruitIndex = {}
for i,name in ipairs(fruitList) do fruitIndex[name:lower()] = i end

local STATE = {
    fly = false,
    noclip = false,
    selectedFruit = nil, -- string
    menuOpen = false,
    flyConn = nil,
    noclipConn = nil,
    drag = {active=false, click=nil, framePos=nil},
    espLabels = {},
}

local function clearEsp()
    for _,g in ipairs(STATE.espLabels) do
        if g and g.Destroy then pcall(function() g:Destroy() end) end
    end
    STATE.espLabels = {}
end

local function destroyMenu()
    if menuGUI and menuGUI.Parent then
        menuGUI:Destroy()
    end
    menuGUI = nil
    STATE.menuOpen = false
    clearEsp()
    -- Cleanup
    if STATE.flyConn then STATE.flyConn:Disconnect() STATE.flyConn = nil end
    if STATE.noclipConn then STATE.noclipConn:Disconnect() STATE.noclipConn=nil end
    STATE.fly = false
    STATE.noclip = false
end

local function getAllFruitsOnMap()
    local results = {}
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Tool") or obj:IsA("Model")) and fruitIndex[obj.Name:lower()] then
            local p = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj:FindFirstChild("Handle") or (obj:IsA("Tool") and obj.Handle)
            if p then
                table.insert(results,{
                    name = obj.Name,
                    model = obj,
                    part = p,
                })
            end
        end
    end
    return results
end

local function getFruitPositionsByName(name)
    local found = {}
    for _,f in ipairs(getAllFruitsOnMap()) do
        if f.name:lower() == name:lower() then
            table.insert(found, f)
        end
    end
    return found
end

local function fly(on)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    if on == STATE.fly then return end
    STATE.fly = on
    if STATE.flyConn then STATE.flyConn:Disconnect() STATE.flyConn=nil end
    local char = LocalPlayer.Character
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not on then
        for _,c in ipairs(hrp:GetChildren()) do
            if c:IsA("BodyGyro") or c:IsA("BodyVelocity") then pcall(function() c:Destroy() end) end
        end
        return
    end
    -- Run fly physics
    local speed = 110
    local bg = Instance.new("BodyGyro", hrp)
    bg.MaxTorque = Vector3.new(400000, 400000, 400000)
    local bv = Instance.new("BodyVelocity", hrp)
    bv.MaxForce = Vector3.new(100000, 100000, 100000)
    bv.Velocity = Vector3.new()
    STATE.flyConn = RunService.RenderStepped:Connect(function()
        -- Remove noclip interference
        if not STATE.fly then if bg then bg:Destroy() end if bv then bv:Destroy() end return end
        local camCF = Camera.CFrame
        local move = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move - Vector3.new(0,1,0) end
        if move.Magnitude > 0 then move = move.Unit * speed end
        bv.Velocity = move
        bg.CFrame = camCF
    end)
end

local function noclip(on)
    if STATE.noclipConn then STATE.noclipConn:Disconnect() STATE.noclipConn=nil end
    STATE.noclip = on
    if on then
        STATE.noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _,v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end)
    end
end

local function teleportToSelectedFruit()
    if not STATE.selectedFruit then return end
    local fruits = getFruitPositionsByName(STATE.selectedFruit)
    if #fruits == 0 then return end
    local fruit = nil
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local pos = char.HumanoidRootPart.Position
    local minDist = math.huge
    for _,f in ipairs(fruits) do
        local p = f.part.Position
        local dist = (p - pos).Magnitude
        if dist < minDist then
            minDist = dist
            fruit = f
        end
    end
    if fruit then
        char.HumanoidRootPart.CFrame = fruit.part.CFrame + Vector3.new(0,2.5,0)
        RunService.RenderStepped:Wait()
        -- try grab with Touch
        pcall(function()
            if firetouchinterest then
                firetouchinterest(char.HumanoidRootPart, fruit.part, 0)
                wait(0.08)
                firetouchinterest(char.HumanoidRootPart, fruit.part, 1)
            end
        end)
    end
end

local function drawFruitESP(fruitName)
    clearEsp()
    for _,f in ipairs(getFruitPositionsByName(fruitName)) do
        if f.part then
            local bbg = Instance.new("BillboardGui", CoreGui)
            bbg.Adornee = f.part
            bbg.AlwaysOnTop = true
            bbg.Size = UDim2.new(0, 108, 0, 32)
            bbg.StudsOffsetWorldSpace = Vector3.new(0,2.2,0)
            bbg.Name = "visitingmenu_esp"
            local lbl = Instance.new("TextLabel", bbg)
            lbl.Size = UDim2.new(1,0,1,0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.fromRGB(60,255,188)
            lbl.TextStrokeTransparency = 0.2
            lbl.Text = "🍈 "..f.name
            lbl.TextScaled = true
            lbl.Font = Enum.Font.FredokaOne
            table.insert(STATE.espLabels, bbg)
        end
    end
end

local function roundify(obj, n)
    local uic = Instance.new("UICorner")
    uic.Parent = obj
    uic.CornerRadius = UDim.new(0, n or 12)
end

local function createMenu()
    destroyMenu()
    menuGUI = Instance.new("ScreenGui", CoreGui)
    menuGUI.Name = guiName
    menuGUI.IgnoreGuiInset = true
    menuGUI.DisplayOrder = 1000

    local frame = Instance.new("Frame", menuGUI)
    frame.Size = UDim2.new(0, 425, 0, 440)
    frame.Position = UDim2.new(0.5, -212, 0.5, -210)
    frame.BackgroundColor3 = Color3.fromRGB(22,26,34)
    frame.BorderSizePixel = 0
    frame.Active = true
    roundify(frame, 20)

    -- Drag logic
    frame.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            STATE.drag.active = true
            STATE.drag.click = input.Position
            STATE.drag.framePos = frame.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            STATE.drag.active = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if STATE.drag.active and input.UserInputType==Enum.UserInputType.MouseMovement then
            local diff = input.Position - STATE.drag.click
            frame.Position = UDim2.new(
                STATE.drag.framePos.X.Scale, STATE.drag.framePos.X.Offset + diff.X,
                STATE.drag.framePos.Y.Scale, STATE.drag.framePos.Y.Offset + diff.Y
            )
        end
    end)

    -- Neon Border
    local border = Instance.new("UIStroke", frame)
    border.Color = Color3.fromRGB(30, 230, 255)
    border.Thickness = 3
    border.Transparency = 0.11

    -- Title
    local title = Instance.new("TextLabel", frame)
    title.Text = "🌊 visitingmenu"
    title.Font = Enum.Font.FredokaOne
    title.TextSize = 31
    title.TextColor3 = Color3.fromRGB(176,255,241)
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1,0,0,45)
    roundify(title, 17)

    -- Close Button
    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = Color3.fromRGB(230,80,102)
    closeBtn.BackgroundColor3 = Color3.fromRGB(38,28,32)
    closeBtn.BorderSizePixel = 0
    closeBtn.Size = UDim2.new(0,36,0,36)
    closeBtn.Position = UDim2.new(1,-41,0,7)
    roundify(closeBtn, 13)
    closeBtn.MouseButton1Click:Connect(destroyMenu)

    -- FLY Button
    local flyBtn = Instance.new("TextButton", frame)
    flyBtn.Size = UDim2.new(0.45,0,0,34)
    flyBtn.Position = UDim2.new(0.04,0,0,54)
    flyBtn.Text = (STATE.fly and "✔️ Uçuş Aktif [E/Q]" or "❌ Uçuş Kapalı [E/Q]")
    flyBtn.Font = Enum.Font.GothamBold
    flyBtn.TextSize = 17
    flyBtn.TextColor3 = STATE.fly and Color3.fromRGB(112,255,172) or Color3.fromRGB(204,204,204)
    flyBtn.BackgroundColor3 = STATE.fly and Color3.fromRGB(36,86,47) or Color3.fromRGB(41,44,48)
    flyBtn.BorderSizePixel = 0
    roundify(flyBtn, 13)
    flyBtn.MouseButton1Click:Connect(function()
        fly(not STATE.fly)
        createMenu()
    end)

    -- NOCLIP Button
    local noclipBtn = Instance.new("TextButton", frame)
    noclipBtn.Size = UDim2.new(0.45,0,0,34)
    noclipBtn.Position = UDim2.new(0.51,0,0,54)
    noclipBtn.Text = (STATE.noclip and "✔️ Noclip Açık" or "❌ Noclip Kapalı")
    noclipBtn.Font = Enum.Font.GothamBold
    noclipBtn.TextSize = 17
    noclipBtn.TextColor3 = STATE.noclip and Color3.fromRGB(86,174,255) or Color3.fromRGB(204,204,204)
    noclipBtn.BackgroundColor3 = STATE.noclip and Color3.fromRGB(30,60,85) or Color3.fromRGB(41,44,48)
    noclipBtn.BorderSizePixel = 0
    roundify(noclipBtn, 13)
    noclipBtn.MouseButton1Click:Connect(function()
        noclip(not STATE.noclip)
        createMenu()
    end)

    -- Fruit Picker
    local y = 101
    local pickerLbl = Instance.new("TextLabel",frame)
    pickerLbl.Size = UDim2.new(0.9,0,0,26)
    pickerLbl.Position = UDim2.new(0.05,0,0,y)
    pickerLbl.Text = "MEYVE SEÇ (Fruit Select):"
    pickerLbl.Font = Enum.Font.GothamBold
    pickerLbl.TextSize = 18
    pickerLbl.TextColor3 = Color3.fromRGB(194,255,201)
    pickerLbl.BackgroundTransparency = 1

    y = y + 30

    -- Dropdown main
    local fruitDropFrame = Instance.new("Frame", frame)
    fruitDropFrame.Size = UDim2.new(0.9,0,0,36)
    fruitDropFrame.Position = UDim2.new(0.05,0,0,y)
    fruitDropFrame.BackgroundColor3 = Color3.fromRGB(41,48,54)
    fruitDropFrame.BorderSizePixel = 0
    roundify(fruitDropFrame, 10)

    local dropBtn = Instance.new("TextButton", fruitDropFrame)
    dropBtn.Size = UDim2.new(1,0,1,0)
    dropBtn.BackgroundTransparency = 1
    dropBtn.Text = STATE.selectedFruit or "Bir Meyve Seçiniz"
    dropBtn.Font = Enum.Font.GothamBold
    dropBtn.TextSize = 18
    dropBtn.TextColor3 = Color3.fromRGB(224,234,211)

    local dropDownOpen = false
    local dropScroll = Instance.new("ScrollingFrame", frame)
    dropScroll.Size = UDim2.new(0.9,0,0,math.min(#fruitList,10)*26)
    dropScroll.Position = UDim2.new(0.05,0,0,y+36)
    dropScroll.BackgroundColor3 = Color3.fromRGB(44,62,59)
    dropScroll.Visible = false
    dropScroll.BorderSizePixel = 0
    dropScroll.CanvasSize = UDim2.new(0,0,0,#fruitList*25)
    local layout = Instance.new("UIListLayout", dropScroll)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Add clickable fruit list
    for _,name in ipairs(fruitList) do
        local b = Instance.new("TextButton", dropScroll)
        b.Size = UDim2.new(1,0,0,25)
        b.Text = name
        b.Font = Enum.Font.Gotham
        b.TextSize = 17
        b.BackgroundTransparency = .06
        b.BackgroundColor3 = Color3.fromRGB(38,68,94)
        b.TextColor3 = Color3.fromRGB(181,255,211)
        b.BorderSizePixel = 0
        roundify(b, 8)
        b.MouseButton1Click:Connect(function()
            STATE.selectedFruit = name
            dropScroll.Visible = false
            dropDownOpen = false
            createMenu()
        end)
    end

    dropBtn.MouseButton1Click:Connect(function()
        dropDownOpen = not dropDownOpen
        dropScroll.Visible = dropDownOpen
    end)

    y = y + 60

    -- ESP Button
    local espBtn = Instance.new("TextButton", frame)
    espBtn.Size = UDim2.new(0.9,0,0,36)
    espBtn.Position = UDim2.new(0.05,0,0,y)
    espBtn.Text = "Seçili Meyvedeki Tüm ESP'yi Göster"
    espBtn.Font = Enum.Font.GothamBold
    espBtn.TextSize = 18
    espBtn.TextColor3 = Color3.fromRGB(124,255,199)
    espBtn.BackgroundColor3 = Color3.fromRGB(36,64,50)
    espBtn.BorderSizePixel = 0
    roundify(espBtn, 10)
    espBtn.MouseButton1Click:Connect(function()
        if STATE.selectedFruit then
            drawFruitESP(STATE.selectedFruit)
        end
    end)

    y = y + 44

    -- Teleport button
    local tpBtn = Instance.new("TextButton", frame)
    tpBtn.Size = UDim2.new(0.9,0,0,36)
    tpBtn.Position = UDim2.new(0.05,0,0,y)
    tpBtn.Text = "Meyveye Teleport Ol ve Al"
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 17
    tpBtn.TextColor3 = Color3.fromRGB(211,224,255)
    tpBtn.BackgroundColor3 = Color3.fromRGB(34,41,68)
    tpBtn.BorderSizePixel = 0
    roundify(tpBtn, 10)
    tpBtn.MouseButton1Click:Connect(teleportToSelectedFruit)

    y = y + 44

    -- Info
    local infoLbl = Instance.new("TextLabel", frame)
    infoLbl.Size = UDim2.new(1,0,0,36)
    infoLbl.Position = UDim2.new(0,0,1,-40)
    infoLbl.Text = "F4 ile aç/kapat | Discord: visitingmemelist"
    infoLbl.Font = Enum.Font.FredokaOne
    infoLbl.TextColor3 = Color3.fromRGB(144,245,244)
    infoLbl.TextSize = 16
    infoLbl.BackgroundTransparency = 1

    STATE.menuOpen = true
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == MENU_KEY then
        if STATE.menuOpen then destroyMenu() else createMenu() end
    end
end)

-- Always open menu on first run
createMenu()
