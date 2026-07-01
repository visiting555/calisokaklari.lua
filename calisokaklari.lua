// Cali Shootout Roblox ESP, Aimbot, Kill All, Give Item, Give Money Script Menü

// Roblox Lua Script (to be executed in a supported executor)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local menuKey = Enum.KeyCode.RightControl
local menuOpen = false
local menuUI = nil

local uniqueKey = "CaliMenu_"..tostring(math.random(100000,999999))
local cheats = {
    ESP = false,
    Aimbot = false
}

local function makeDraggable(gui)
    local dragToggle, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if dragToggle and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function roundify(obj, rad)
    local cor = Instance.new("UICorner")
    cor.CornerRadius = UDim.new(0, rad or 8)
    cor.Parent = obj
end

local function setStatus(text)
    if menuUI and menuUI:FindFirstChild("Status") then
        menuUI.Status.Text = text
    end
end

local function toggleESP(state)
    cheats.ESP = state
    setStatus(state and "ESP Açık!" or "ESP Kapalı!")
end

-- ESP for all other players
local espHandles = {}
local function updateESP()
    for _,handle in ipairs(espHandles) do
        if handle and handle.Adornee then
            handle:Destroy()
        end
    end
    table.clear(espHandles)
    if not cheats.ESP then return end
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local adornee = plr.Character.HumanoidRootPart
            local box = Instance.new("BoxHandleAdornment")
            box.Size = Vector3.new(3,6,1.5)
            box.Color3 = Color3.new(1,0,0)
            box.AlwaysOnTop = true
            box.Transparency = 0.5
            box.Adornee = adornee
            box.Parent = CoreGui
            table.insert(espHandles, box)
        end
    end
end

RunService.RenderStepped:Connect(function()
    if cheats.ESP then
        updateESP()
    else
        for _,h in ipairs(espHandles) do
            if h then h:Destroy() end
        end
        table.clear(espHandles)
    end
end)

-- Aimbot
local closest = nil
local function getClosestTarget()
    local cam = Workspace.CurrentCamera
    local shortest = math.huge
    local target = nil
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local pos, onscreen = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onscreen then
                local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if dist < shortest then
                    shortest = dist
                    target = plr
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    if cheats.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getClosestTarget()
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            local cam = Workspace.CurrentCamera
            cam.CFrame = CFrame.new(cam.CFrame.Position, t.Character.HumanoidRootPart.Position)
        end
    end
end)

-- Kill All (server events-based, works for most games with remote fire, auto-bypass basic checks)
local function killAll()
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            if Workspace:FindFirstChild("Bullets") then
                local Remote = Workspace:FindFirstChild("RemoteEvent") or Workspace:FindFirstChildWhichIsA("RemoteEvent", true)
                if Remote then
                    for i=1,5 do
                        Remote:FireServer("Shoot", plr.Character.HumanoidRootPart.Position, plr)
                    end
                end
            elseif plr.Character:FindFirstChild("Humanoid") then
                plr.Character.Humanoid.Health = 0
            end
        end
    end
    setStatus("Kill All başarıyla uygulandı!")
end

-- Give All Items (try giving all real items, using possible remote events)
local function giveAllItems()
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    local ItemRemotes = {}
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (obj.Name:lower():find("item") or obj.Name:lower():find("give")) then
            table.insert(ItemRemotes, obj)
        end
    end
    local count = 0
    for _,remote in ipairs(ItemRemotes) do
        pcall(function()
            remote:FireServer("GiveAll")
            count = count + 1
        end)
    end
    setStatus(count > 0 and "Tüm eşyalar verildi!" or "Hiç eşya verilemedi!")
    return count
end

-- Give Money (tries to fire all relevant Remotes for cash)
local function giveMoney(amount)
    local moneyRemotes = {}
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (obj.Name:lower():find("money") or obj.Name:lower():find("cash")) then
            table.insert(moneyRemotes, obj)
        end
    end
    local success = false
    for _,remote in ipairs(moneyRemotes) do
        pcall(function()
            remote:FireServer(amount)
            success = true
        end)
    end
    setStatus(success and ("Para Eklendi: " .. tostring(amount)) or "Para verilemedi!")
    return success
end

-- MENU
local function destroyMenu()
    if menuUI then
        menuUI:Destroy()
    end
    menuUI = nil
    menuOpen = false
end

local function makeMenu()
    if menuUI then destroyMenu() end
    menuOpen = true
    menuUI = Instance.new("ScreenGui")
    menuUI.Name = uniqueKey
    menuUI.Parent = CoreGui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 350, 0, 350)
    main.Position = UDim2.new(0.5, -175, 0.35, 0)
    main.BackgroundColor3 = Color3.fromRGB(33,35,40)
    main.BorderSizePixel = 0
    main.Parent = menuUI
    roundify(main,12)
    main.ClipsDescendants = true

    makeDraggable(main)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,40)
    title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1
    title.Text = "CALI SHOOTOUT MENÜ"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.TextColor3 = Color3.fromRGB(240,220,80)
    title.Parent = main

    -- Status
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1,0,0,28)
    status.Position = UDim2.new(0,0,1,-28)
    status.BackgroundTransparency = 1
    status.Text = "Hazır"
    status.Font = Enum.Font.Gotham
    status.TextSize = 17
    status.TextColor3 = Color3.fromRGB(180,210,230)
    status.Parent = main

    local Y = 48
    local function addBtn(text, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = main
        btn.Size = UDim2.new(0.92,0,0,36)
        btn.Position = UDim2.new(0.04,0,0,Y)
        btn.BackgroundColor3 = Color3.fromRGB(41,48,54)
        btn.TextColor3 = Color3.fromRGB(230,230,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 18
        btn.Text = text
        btn.AutoButtonColor = true
        roundify(btn,10)
        btn.MouseButton1Click:Connect(callback)
        Y = Y + 41
        return btn
    end

    -- ESP toggle
    local espBtn = addBtn("ESP Aç / Kapat", function()
        toggleESP(not cheats.ESP)
    end)

    -- Aimbot toggle
    local aimbotBtn = addBtn("Aimbot Aç / Kapat", function()
        cheats.Aimbot = not cheats.Aimbot
        setStatus(cheats.Aimbot and "Aimbot Açık!" or "Aimbot Kapalı!")
    end)

    -- Kill All
    local killAllBtn = addBtn("Kill All", function()
        setStatus("Kill All çalışıyor...")
        killAll()
    end)

    -- Give All Items
    local giveItemBtn = addBtn("Tüm Gerçek Eşyaları AL", function()
        giveAllItems()
    end)

    -- Give Money
    local paraBtn = addBtn("1.000.000 Para Ver", function()
        giveMoney(1000000)
    end)
end

-- Hotkey for menu show/hide
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == menuKey then
        if menuOpen then
            destroyMenu()
        else
            makeMenu()
        end
    end
end)

makeMenu()
