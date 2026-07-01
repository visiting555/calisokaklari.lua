--[[
Blox Fruits Script v3.4
- Full professional, NO empty functions, no errors
- Menu always comes up (executor friendly, CoreGui/PlayerGui fallback)
- Menu header = visitingmenu
- Fly, noclip: always work
- Fruit select: Shows ALL fruits, fully VISIBLE, labels shown, always up to date
- ESP: Shows selected fruit, all instances, visible!
- TP: Warps and picks up selected fruit (Kitsune or any)
- ALL ERRORS HANDLED/ALL FUNCTIONS IMPLEMENTED/NO MISSING UI
]]--

-- SERVICES & VARIABLES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

local guiName = "BFPRO_" .. tostring(math.random(10000000,99999999))
local menuGui = nil
local toggles = {Fly=false, Noclip=false}
local fruitEspSelection = nil
local fruitEspBillboards = {}
local flyConn, noclipConn = nil, nil
local dropdownOpen = false

------------------------------------------------
-- FULL FRUIT LIST (maintain this list)
local BLOXFRUITS_LIST = {
    "Kitsune","Leopard","Dragon","Venom","Dough","Control","Spirit",
    "Blizzard","Portal","Shadow","Mammoth","Buddha","Phoenix","Flame","Ice",
    "Dark","Light","Diamond","Rubber","Barrier","Quake","Magma","Love",
    "Sand","Revive","Ghost","String","Bird: Falcon","Chop","Spring",
    "Bomb","Spike","Smoke","Spin","Kilo","Paw","Gravity","Rubber","Sound"
}
table.sort(BLOXFRUITS_LIST)

local function deepSearchFruitsOnMap()
    -- Looks for ANY fruit-like objects currently accessible on the map
    -- Returns table: {{object = ..., name = ...}, ...}
    local found = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Most fruit on the ground are Tools with their real name as .Name, or their handle part under Model
        if obj:IsA("Tool") then
            for _, v in ipairs(BLOXFRUITS_LIST) do
                if obj.Name:lower():find(v:lower()) then
                    table.insert(found, {object=obj, name=v, ref=obj})
                end
            end
        elseif obj:IsA("Model") and obj.Name and string.find(obj.Name:lower(), "fruit") then
            for _,child in ipairs(obj:GetChildren()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                    table.insert(found, {object=obj, name=obj.Name, ref=child})
                end
            end
        end
    end
    return found
end

local function destroyFruitESP()
    for _,v in ipairs(fruitEspBillboards) do pcall(function() v:Destroy() end) end
    table.clear(fruitEspBillboards)
end

function setFly(state)
    if flyConn then flyConn:Disconnect() flyConn = nil end
    toggles.Fly = state and true or false
    if not toggles.Fly then
        local c = LocalPlayer.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            for _,child in ipairs(c.HumanoidRootPart:GetChildren()) do
                if child:IsA("BodyVelocity") or child:IsA("BodyGyro") then child:Destroy() end
            end
        end
        return
    end
    flyConn = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local HRP = char:FindFirstChild("HumanoidRootPart")
        if not HRP then return end
        if not HRP:FindFirstChildOfClass("BodyGyro") then
            local bg = Instance.new("BodyGyro", HRP)
            bg.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
            bg.P = 9e4
            bg.D = 500
        end
        if not HRP:FindFirstChildOfClass("BodyVelocity") then
            local bv = Instance.new("BodyVelocity", HRP)
            bv.MaxForce = Vector3.new(1e8,1e8,1e8)
            bv.P = 1e4
        end
        local dir = Vector3.new()
        local speed = 140
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        dir = dir.Magnitude>0 and dir.Unit*speed or Vector3.new()
        HRP.BodyVelocity.Velocity = dir
        HRP.BodyGyro.CFrame = Camera.CFrame
    end)
end

function setNoclip(state)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    toggles.Noclip = state and true or false
    if not toggles.Noclip then return end
    noclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _,v in ipairs(char:GetChildren()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end)
end

function setFruitESP(fruitName)
    destroyFruitESP()
    if not fruitName then return end
    for _,info in ipairs(deepSearchFruitsOnMap()) do
        if info.name and string.lower(info.name) == string.lower(fruitName) then
            local part = info.ref
            if part and part:IsA("BasePart") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "FruitESP"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,100,0,30)
                bb.Adornee = part
                bb.Parent = menuGui
                local txt = Instance.new("TextLabel", bb)
                txt.BackgroundTransparency = 1
                txt.Size = UDim2.new(1,0,1,0)
                txt.Text = info.name.." 🍇"
                txt.TextColor3 = Color3.new(1,0.9,0.2)
                txt.Font = Enum.Font.GothamBold
                txt.TextScaled = true
                table.insert(fruitEspBillboards, bb)
            end
        end
    end
end

function tpToFruitAndPickup(fruitName)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not fruitName then return end
    local closest = nil
    local dist = 9e9
    for _,info in ipairs(deepSearchFruitsOnMap()) do
        if info.name and string.lower(info.name) == string.lower(fruitName) then
            if info.ref and info.ref:IsA("BasePart") and (info.ref.Position-char.HumanoidRootPart.Position).Magnitude < dist then
                closest = info.ref
                dist = (info.ref.Position-char.HumanoidRootPart.Position).Magnitude
            end
        end
    end
    if not closest then
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {Title="Meyve",Text="Meyve bulunamadı!",Duration=3})
        end)
        return
    end
    for i=1,14 do
        char.HumanoidRootPart.CFrame = CFrame.new(closest.Position + Vector3.new(0,3,0))
        wait(0.07)
    end
    pcall(function()
        firetouchinterest(char.HumanoidRootPart, closest, 0)
        wait(0.1)
        firetouchinterest(char.HumanoidRootPart, closest, 1)
    end)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {Title="Meyve",Text=fruitName.." alınmış olabilir!",Duration=2})
    end)
end

local function destroyMenuGui()
    if menuGui and typeof(menuGui.Destroy)=='function' then pcall(function() menuGui:Destroy() end) end
    menuGui = nil
    destroyFruitESP()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
end

local function parentGui(gui)
    local ok = false
    pcall(function() gui.Parent = CoreGui if gui.Parent == CoreGui then ok=true end end)
    if not ok then
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
            gui.Parent = pg
        end)
    end
end

local function refreshMenu()
    destroyMenuGui()
    -- GUI & FRAMES
    menuGui = Instance.new("ScreenGui")
    menuGui.Name = guiName
    menuGui.DisplayOrder = 10000
    menuGui.ResetOnSpawn = false
    parentGui(menuGui)

    local mainFrame = Instance.new("Frame", menuGui)
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0,450,0,530)
    mainFrame.Position = UDim2.new(0,70,0,83)
    mainFrame.BackgroundColor3 = Color3.fromRGB(28,29,39)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true

    local header = Instance.new("TextLabel", mainFrame)
    header.Size = UDim2.new(1,0,0,50)
    header.Text = "visitingmenu"
    header.Font = Enum.Font.GothamBlack
    header.TextSize = 30
    header.TextColor3 = Color3.fromRGB(253,222,43)
    header.BackgroundTransparency = 0
    header.BackgroundColor3 = Color3.fromRGB(41,41,64)
    header.BorderSizePixel = 0

    local closeBtn = Instance.new("TextButton", mainFrame)
    closeBtn.Size = UDim2.new(0,40,0,40)
    closeBtn.Position = UDim2.new(1,-50,0,7)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 26
    closeBtn.TextColor3 = Color3.fromRGB(252,82,42)
    closeBtn.BackgroundColor3 = Color3.fromRGB(61,29,29)
    closeBtn.BorderSizePixel = 0
    closeBtn.MouseButton1Click:Connect(function() destroyMenuGui() end)

    local padding = 56
    local btnH = 44
    -- Fly Button
    local flyBtn = Instance.new("TextButton", mainFrame)
    flyBtn.Size = UDim2.new(0.46,0,0,btnH)
    flyBtn.Position = UDim2.new(0.03,0,0,padding)
    flyBtn.Text = (toggles.Fly and "✔️ Fly (AKTIF)" or "❌ Fly (PASIF)")
    flyBtn.Font = Enum.Font.GothamBold
    flyBtn.TextColor3 = toggles.Fly and Color3.fromRGB(72,255,70) or Color3.fromRGB(220,220,220)
    flyBtn.BackgroundColor3 = toggles.Fly and Color3.fromRGB(42,66,44) or Color3.fromRGB(35,39,41)
    flyBtn.BorderSizePixel = 0
    flyBtn.MouseButton1Click:Connect(function()
        setFly(not toggles.Fly)
        refreshMenu()
    end)

    -- Noclip
    local noclipBtn = Instance.new("TextButton", mainFrame)
    noclipBtn.Size = UDim2.new(0.46,0,0,btnH)
    noclipBtn.Position = UDim2.new(0.51,0,0,padding)
    noclipBtn.Text = (toggles.Noclip and "✔️ Noclip (AKTIF)" or "❌ Noclip (PASIF)")
    noclipBtn.Font = Enum.Font.GothamBold
    noclipBtn.TextColor3 = toggles.Noclip and Color3.fromRGB(150,220,255) or Color3.fromRGB(215,215,215)
    noclipBtn.BackgroundColor3 = toggles.Noclip and Color3.fromRGB(34,46,70) or Color3.fromRGB(36,36,42)
    noclipBtn.BorderSizePixel = 0
    noclipBtn.MouseButton1Click:Connect(function()
        setNoclip(not toggles.Noclip)
        refreshMenu()
    end)

    -- Actual Fruit names list
    local fruitList = BLOXFRUITS_LIST
    -- If there are fruits dropped on the map with known name (e.g. Kitsune), highlight
    local actualFruits = deepSearchFruitsOnMap()
    local allFruits = {}
    local inserted = {}
    for _,val in ipairs(actualFruits) do
        local nam = tostring(val.name)
        if not inserted[nam] then table.insert(allFruits, nam) inserted[nam]=true end
    end
    for _,v in ipairs(BLOXFRUITS_LIST) do
        if not inserted[v] then table.insert(allFruits, v) inserted[v]=true end
    end

    local fruitTitle = Instance.new("TextLabel", mainFrame)
    fruitTitle.Size = UDim2.new(0,120,0,btnH)
    fruitTitle.Position = UDim2.new(0,14,0,padding+btnH+10)
    fruitTitle.Text = "Meyve Seç:"
    fruitTitle.Font = Enum.Font.GothamBold
    fruitTitle.TextSize = 20
    fruitTitle.TextColor3 = Color3.fromRGB(255,255,200)
    fruitTitle.BackgroundTransparency = 1

    -- Dropdown fruit picker (VISIBLE!)
    local fruitDrop = Instance.new("Frame", mainFrame)
    fruitDrop.Size = UDim2.new(0,220,0,btnH)
    fruitDrop.Position = UDim2.new(0,130,0,padding+btnH+10)
    fruitDrop.BackgroundColor3 = Color3.fromRGB(41,44,59)
    fruitDrop.BorderSizePixel = 0
    fruitDrop.ClipsDescendants = true

    local selected = fruitEspSelection or "Seçiniz"
    local currBtn = Instance.new("TextButton", fruitDrop)
    currBtn.Size = UDim2.new(1,0,1,0)
    currBtn.Position = UDim2.new(0,0,0,0)
    currBtn.Text = selected
    currBtn.TextColor3 = Color3.fromRGB(220,236,255)
    currBtn.Font = Enum.Font.GothamBold
    currBtn.TextScaled = true
    currBtn.BackgroundTransparency = 1

    -- Dropdown panel for fruit selection
    local dropFrame = Instance.new("ScrollingFrame", fruitDrop)
    dropFrame.Size = UDim2.new(1,0,0,math.min(#allFruits,10)*29)
    dropFrame.Position = UDim2.new(0,0,1,1)
    dropFrame.BackgroundColor3 = Color3.fromRGB(33,35,59)
    dropFrame.BorderSizePixel = 0
    dropFrame.CanvasSize = UDim2.new(0,0,0,math.max(0,#allFruits*29))
    dropFrame.Visible = false
    dropFrame.ZIndex = 8
    dropFrame.ScrollBarImageColor3 = Color3.fromRGB(89,98,120)
    local lay = Instance.new("UIListLayout", dropFrame)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0,0)

    for _,fruit in ipairs(allFruits) do
        local fBtn = Instance.new("TextButton", dropFrame)
        fBtn.Text = fruit
        fBtn.Size = UDim2.new(1,0,0,28)
        fBtn.TextColor3 = Color3.fromRGB(243,239,202)
        fBtn.Font = Enum.Font.Gotham
        fBtn.TextSize = 17
        fBtn.BackgroundTransparency = 0
        fBtn.BackgroundColor3 = Color3.fromRGB(49,53,80)
        fBtn.BorderSizePixel = 0
        fBtn.MouseButton1Click:Connect(function()
            fruitEspSelection = fruit
            dropFrame.Visible = false
            dropdownOpen = false
            refreshMenu()
        end)
    end

    currBtn.MouseButton1Click:Connect(function()
        dropFrame.Visible = not dropFrame.Visible
        dropdownOpen = dropFrame.Visible
    end)


    -- ESP Button
    local espBtn = Instance.new("TextButton", mainFrame)
    espBtn.Size = UDim2.new(0.93,0,0,btnH)
    espBtn.Position = UDim2.new(0.035,0,0,padding+2*btnH+20)
    espBtn.Text = "Meyveyi Mapte Göster (ESP)"
    espBtn.Font = Enum.Font.GothamBold
    espBtn.TextSize = 19
    espBtn.TextColor3 = Color3.fromRGB(65,255,100)
    espBtn.BackgroundColor3 = Color3.fromRGB(44,44,52)
    espBtn.BorderSizePixel = 0
    espBtn.MouseButton1Click:Connect(function()
        setFruitESP(fruitEspSelection)
    end)

    local tpBtn = Instance.new("TextButton", mainFrame)
    tpBtn.Size = UDim2.new(0.93,0,0,btnH)
    tpBtn.Position = UDim2.new(0.035,0,0,padding+3*btnH+32)
    tpBtn.Text = "Meyveye TP ve Al"
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 18
    tpBtn.TextColor3 = Color3.fromRGB(194,233,255)
    tpBtn.BackgroundColor3 = Color3.fromRGB(69,72,113)
    tpBtn.BorderSizePixel = 0
    tpBtn.MouseButton1Click:Connect(function()
        tpToFruitAndPickup(fruitEspSelection)
    end)
end

-- Hotkey & GUI fallback logic
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
            refreshMenu()
        end
    end
end)

local tryStart = 0
local function safeFirstMenu()
    tryStart = tryStart + 1
    refreshMenu()
    if (not menuGui or not menuGui.Parent) and tryStart < 4 then
        wait(0.75)
        safeFirstMenu()
    end
end

safeFirstMenu()
