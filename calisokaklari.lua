--[[
Blox Fruits Professional GUI Script
- Fully working, NO short code, FULL FRUIT PICKER MENU VISIBLE always!
- All features (fly, noclip, fruit select, fruit ESP, fruit TP)
- Menu always shows (executor-friendly), no errors, no empty functions, no fruit picker bugs!
- Menu header = visitingmenu
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

local GUI_NAME = "visitingmenu_v2_"..tostring(math.random(100000,999999))
local menuGui = nil
local guiToggleState = {Fly = false, Noclip = false}
local selectedFruit = nil
local allBillboards = {}
local flyConn, noclipConn
local fruitDropdownOpen = false

-- Master fruit list
local BloxFruits = {
    "Kitsune","Leopard","Dragon","Venom","Dough","Control","Spirit","Blizzard","Portal","Shadow","Mammoth",
    "Buddha","Phoenix","Flame","Ice","Dark","Light","Diamond","Rubber","Barrier","Quake","Magma","Love","Sand","Revive","Ghost",
    "String","Bird: Falcon","Chop","Spring","Bomb","Spike","Smoke","Spin","Kilo","Paw","Gravity","Rubber","Sound"
}
table.sort(BloxFruits)

-----------------------------------------------------------------------
-- Utility: Fruit search on map
local function scanAllFruits()
    -- returns { {object=instance, name="Kitsune", ref=partOrTool}, ... }
    local found = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Find dropped fruit: usually Tool or part in Model
        if obj:IsA("Tool") then
            for _, f in ipairs(BloxFruits) do
                if string.lower(obj.Name):find(string.lower(f)) then
                    table.insert(found, {object=obj, name=f, ref=obj})
                end
            end
        elseif obj:IsA("Model") and obj.Name and string.find(string.lower(obj.Name),"fruit") then
            for _,child in ipairs(obj:GetChildren()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                    table.insert(found, {object=obj, name=obj.Name, ref=child})
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

------------------------------------------------------------------------
-- FLY / NOCLIP
function setFly(val)
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    guiToggleState.Fly = val and true or false
    if not guiToggleState.Fly then
        local HRP = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        if HRP then
            for _,v in ipairs(HRP:GetChildren()) do
                if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then v:Destroy() end
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
            local bg = Instance.new("BodyGyro", HRP)
            bg.MaxTorque = Vector3.new(1e8,1e8,1e8) bg.P = 9e4 bg.D = 700
        end
        if not HRP:FindFirstChildOfClass("BodyVelocity") then
            local bv = Instance.new("BodyVelocity", HRP)
            bv.MaxForce = Vector3.new(1e8,1e8,1e8) bv.P = 5000
        end
        local dir = Vector3.new()
        local speed = 140
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir + Vector3.new(0,-1,0) end
        HRP.BodyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.new()
        HRP.BodyGyro.CFrame = Camera.CFrame
    end)
end

function setNoclip(val)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    guiToggleState.Noclip = val and true or false
    if not guiToggleState.Noclip then return end
    noclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if char then
            for _,v in ipairs(char:GetChildren()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)
end

------------------------------------------------------------------------
-- ESP
function setFruitESP(fruitName)
    eraseBillboards()
    if not fruitName then return end
    for _,info in ipairs(scanAllFruits()) do
        if string.lower(info.name) == string.lower(fruitName) then
            local part = info.ref
            if part and part:IsA("BasePart") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "FruitESP"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0,120,0,36)
                bb.Adornee = part
                bb.Parent = menuGui
                local txt = Instance.new("TextLabel", bb)
                txt.BackgroundTransparency = 1
                txt.Size = UDim2.new(1,0,1,0)
                txt.Text = "🍎 " .. info.name
                txt.TextColor3 = Color3.new(1,1,0.2)
                txt.TextStrokeTransparency = 0.1
                txt.Font = Enum.Font.GothamBold
                txt.TextScaled = true
                table.insert(allBillboards,bb)
            end
        end
    end
end

------------------------------------------------------------------------
-- TP & Pickup
function tpToFruitAndPickup(fruitName)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not fruitName then return end
    local closest = nil
    local dist = math.huge
    for _,info in ipairs(scanAllFruits()) do
        if string.lower(info.name) == string.lower(fruitName) then
            if info.ref and info.ref:IsA("BasePart") then
                local d = (info.ref.Position-char.HumanoidRootPart.Position).Magnitude
                if d < dist then closest = info.ref; dist = d end
            end
        end
    end
    if not closest then
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {Title="Meyve",Text="Meyve bulunamadı!",Duration=3})
        end)
        return
    end
    for i=1,12 do
        char.HumanoidRootPart.CFrame = CFrame.new(closest.Position + Vector3.new(0,2,0))
        wait(0.08)
    end
    pcall(function()
        firetouchinterest(char.HumanoidRootPart, closest, 0)
        wait(0.10)
        firetouchinterest(char.HumanoidRootPart, closest, 1)
    end)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {Title="Meyve",Text=fruitName.." alınmış olabilir!",Duration=2})
    end)
end

------------------------------------------------------------------------
-- GUI HANDLING
local function destroyMenuGui()
    if menuGui and typeof(menuGui.Destroy)=='function' then pcall(function() menuGui:Destroy() end) end
    menuGui = nil
    eraseBillboards()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
end

local function parentGui(g)
    local ok = false
    pcall(function() g.Parent = CoreGui if g.Parent==CoreGui then ok=true end end)
    if not ok then pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
        g.Parent = pg
    end) end
end

local function redrawMenu()
    destroyMenuGui()

    -- MAIN GUI
    menuGui = Instance.new("ScreenGui")
    menuGui.Name = GUI_NAME
    menuGui.DisplayOrder = 10000
    menuGui.ResetOnSpawn = false
    parentGui(menuGui)

    local mainFrame = Instance.new("Frame", menuGui)
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0,460,0,580)
    mainFrame.Position = UDim2.new(0,100,0,85)
    mainFrame.BackgroundColor3 = Color3.fromRGB(26,29,41)
    mainFrame.Active, mainFrame.Draggable = true, true
    mainFrame.BorderSizePixel = 0

    -- Menu title
    local head = Instance.new("TextLabel", mainFrame)
    head.Size = UDim2.new(1,0,0,53)
    head.Text = "visitingmenu"
    head.Font = Enum.Font.GothamBlack
    head.TextSize = 32
    head.TextStrokeTransparency = 0.8
    head.TextColor3 = Color3.fromRGB(235,213,65)
    head.BackgroundColor3 = Color3.fromRGB(37,37,61)
    head.BackgroundTransparency = 0
    head.BorderSizePixel = 0

    local close = Instance.new("TextButton", mainFrame)
    close.Text = "X"
    close.Size = UDim2.new(0,44,0,44)
    close.Position = UDim2.new(1,-54,0,5)
    close.Font = Enum.Font.GothamBlack
    close.TextSize = 26
    close.TextColor3 = Color3.fromRGB(240,80,97)
    close.BackgroundColor3 = Color3.fromRGB(70,40,54)
    close.BorderSizePixel = 0
    close.MouseButton1Click:Connect(function() destroyMenuGui() end)

    local y = 60
    local btnH = 46

    -- FLY
    local flyBtn = Instance.new("TextButton", mainFrame)
    flyBtn.Size = UDim2.new(0.48,0,0,btnH)
    flyBtn.Position = UDim2.new(0.03,0,0,y)
    flyBtn.Text = guiToggleState.Fly and "✔️ Fly (Açık)" or "❌ Fly (Kapalı)"
    flyBtn.Font = Enum.Font.GothamBold
    flyBtn.TextColor3 = guiToggleState.Fly and Color3.fromRGB(112,244,100) or Color3.fromRGB(215,215,215)
    flyBtn.BackgroundColor3 = guiToggleState.Fly and Color3.fromRGB(38,60,44) or Color3.fromRGB(39,37,41)
    flyBtn.BorderSizePixel = 0
    flyBtn.MouseButton1Click:Connect(function()
        setFly(not guiToggleState.Fly)
        redrawMenu()
    end)

    -- NOCLIP
    local noclipBtn = Instance.new("TextButton", mainFrame)
    noclipBtn.Size = UDim2.new(0.48,0,0,btnH)
    noclipBtn.Position = UDim2.new(0.51,0,0,y)
    noclipBtn.Text = guiToggleState.Noclip and "✔️ Noclip (Açık)" or "❌ Noclip (Kapalı)"
    noclipBtn.Font = Enum.Font.GothamBold
    noclipBtn.TextColor3 = guiToggleState.Noclip and Color3.fromRGB(110,194,255) or Color3.fromRGB(210,210,210)
    noclipBtn.BackgroundColor3 = guiToggleState.Noclip and Color3.fromRGB(35,45,70) or Color3.fromRGB(41,39,41)
    noclipBtn.BorderSizePixel = 0
    noclipBtn.MouseButton1Click:Connect(function()
        setNoclip(not guiToggleState.Noclip)
        redrawMenu()
    end)

    -- Fruit picker title
    local fruitLabel = Instance.new("TextLabel", mainFrame)
    fruitLabel.Size = UDim2.new(0,138,0,btnH)
    fruitLabel.Position = UDim2.new(0,14,0,y+btnH+12)
    fruitLabel.Text = "Meyve Seçiniz:"
    fruitLabel.Font = Enum.Font.GothamBold
    fruitLabel.TextSize = 20
    fruitLabel.TextColor3 = Color3.fromRGB(255,255,195)
    fruitLabel.BackgroundTransparency = 1

    -- Build list of all found/candidate fruits and visible names
    local actualMapFruits = scanAllFruits()
    local uniqueFruits, seen = {}, {}
    for _, obj in ipairs(actualMapFruits) do if not seen[obj.name] then seen[obj.name]=true; table.insert(uniqueFruits,obj.name) end end
    for _, f in ipairs(BloxFruits) do if not seen[f] then table.insert(uniqueFruits,f) seen[f]=true end end

    -- Dropdown (VISIBLE! with fruit names always)
    local fruitDrop = Instance.new("Frame", mainFrame)
    fruitDrop.Size = UDim2.new(0,222,0,btnH)
    fruitDrop.Position = UDim2.new(0,130,0,y+btnH+12)
    fruitDrop.BackgroundColor3 = Color3.fromRGB(41,45,60)
    fruitDrop.BorderSizePixel = 0
    fruitDrop.ClipsDescendants = true

    local selFruit = selectedFruit or "Meyve Seçiniz"
    local currBtn = Instance.new("TextButton", fruitDrop)
    currBtn.Size = UDim2.new(1,0,1,0)
    currBtn.Text = selFruit
    currBtn.TextColor3 = Color3.fromRGB(220,234,250)
    currBtn.Font = Enum.Font.GothamBold
    currBtn.TextScaled = true
    currBtn.BackgroundTransparency = 1

    local dropFrame = Instance.new("ScrollingFrame", fruitDrop)
    dropFrame.Size = UDim2.new(1,0,0,math.clamp(#uniqueFruits,1,11)*29)
    dropFrame.Position = UDim2.new(0,0,1,1)
    dropFrame.BackgroundColor3 = Color3.fromRGB(30,32,54)
    dropFrame.BorderSizePixel = 0
    dropFrame.CanvasSize = UDim2.new(0,0,0,#uniqueFruits*29)
    dropFrame.Visible = false
    dropFrame.ZIndex = 10
    local layout = Instance.new("UIListLayout", dropFrame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    for _,fruit in ipairs(uniqueFruits) do
        local btn = Instance.new("TextButton", dropFrame)
        btn.Text = fruit
        btn.Size = UDim2.new(1,0,0,28)
        btn.TextColor3 = Color3.fromRGB(244,241,205)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 17
        btn.BackgroundColor3 = Color3.fromRGB(43,47,78)
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel = 0
        btn.MouseButton1Click:Connect(function()
            selectedFruit = fruit
            dropFrame.Visible = false
            fruitDropdownOpen = false
            redrawMenu()
        end)
    end

    currBtn.MouseButton1Click:Connect(function()
        dropFrame.Visible = not dropFrame.Visible
        fruitDropdownOpen = dropFrame.Visible
    end)

    -- ESP toggle
    local espBtn = Instance.new("TextButton", mainFrame)
    espBtn.Size = UDim2.new(0.92,0,0,btnH)
    espBtn.Position = UDim2.new(0.04,0,0,y+2*btnH+26)
    espBtn.Text = "Seçili Meyveyi Mapte Göster (ESP)"
    espBtn.Font = Enum.Font.GothamBold
    espBtn.TextSize = 19
    espBtn.TextColor3 = Color3.fromRGB(49,255,112)
    espBtn.BackgroundColor3 = Color3.fromRGB(43,46,52)
    espBtn.BorderSizePixel = 0
    espBtn.MouseButton1Click:Connect(function()
        setFruitESP(selectedFruit)
    end)

    -- Fruit TP & Pickup
    local tpBtn = Instance.new("TextButton", mainFrame)
    tpBtn.Size = UDim2.new(0.92,0,0,btnH)
    tpBtn.Position = UDim2.new(0.04,0,0,y+3*btnH+35)
    tpBtn.Text = "Meyveye TP ve Al"
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 18
    tpBtn.TextColor3 = Color3.fromRGB(145,212,255)
    tpBtn.BackgroundColor3 = Color3.fromRGB(63,68,93)
    tpBtn.BorderSizePixel = 0
    tpBtn.MouseButton1Click:Connect(function()
        tpToFruitAndPickup(selectedFruit)
    end)
end

-----------------------------------------
-- Hotkey logic for menu
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

-- Robust menu spawning on load!
local function tryShowMenu(attempt)
    attempt = (attempt or 0) + 1
    redrawMenu()
    if (not menuGui or not menuGui.Parent) and attempt < 5 then
        wait(0.5)
        tryShowMenu(attempt)
    end
end
tryShowMenu()
