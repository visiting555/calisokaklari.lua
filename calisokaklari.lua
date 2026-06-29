-- Cali Sokaklari - Sadece Para ve Gerçek Tüm Item Hilesi (Minimal Menü)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
pcall(function() StarterGui:SetCore("SendNotification", {Title="Script"; Text="Cali Sokaklari Money/Item Hilesi Aktif!"; Duration=3;}) end)

local function roundify(gui, rad)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, rad or 14)
    corner.Parent = gui
end

local function destroyMenu()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("CSK_PRO_HileMenu")
    if gui then gui:Destroy() end
end

-- Gerçek itemları bulmak için marketplace ve ReplicatedStorage taraması
local function getTrueGameItemList()
    local itemNames = {}
    for _, folderName in ipairs({"Items", "Itemler", "Envanter", "Shop", "Market"}) do
        local itemsFolder = ReplicatedStorage:FindFirstChild(folderName)
        if itemsFolder and itemsFolder:IsA("Folder") then
            for _, v in ipairs(itemsFolder:GetChildren()) do
                if (v:IsA("Tool") or v:IsA("Model") or v:IsA("Folder")) and not itemNames[v.Name] then
                    itemNames[v.Name] = true
                end
            end
        end
    end
    -- Alternatif: Sık bilinen item adları (override eder)
    local known = {
        "Lockpick","Anahtar","Drill","Telefon","Canta","Mask","Bandaj","Armor",
        "Cigarette","Cekic","Tablet","Painkiller","EnergyDrink","Pistol","DesertEagle",
        "MP5","M4A1","AK47","Tec9","Sniper","Uzi","Shotgun","Knife"
    }
    for _,v in ipairs(known) do itemNames[v]=true end
    local out = {}
    for k in pairs(itemNames) do table.insert(out, k) end
    return out
end

local function findRemote(keywords)
    local found = {}
    local function scan(obj)
        for _, v in ipairs(obj:GetDescendants()) do
            for _, w in ipairs(keywords) do
                if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name:lower():find(w:lower()) then
                    table.insert(found, v)
                end
            end
        end
    end
    pcall(function() scan(ReplicatedStorage) end)
    pcall(function() scan(workspace) end)
    return found
end

local function realGiveMoney(amount)
    local remotes = findRemote({"para","money","bakiye","give","add"})
    for _, r in ipairs(remotes) do
        -- Sadece parametre olarak sayı isteyenlere
        local ok = pcall(function()
            r:FireServer(amount)
        end)
        if ok then break end
    end
    -- Veya leaderstats doğrudan varsa
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _,v in ipairs({"Money","money","Para","para","Bakiye"}) do
            local m = ls:FindFirstChild(v)
            if m and type(m.Value)=="number" then m.Value = m.Value + amount end
        end
    end
end

local function realGiveAllItems()
    local itemList = getTrueGameItemList()
    local remotes = findRemote({"item","give","ver","add"})
    for _, item in ipairs(itemList) do
        for _, r in ipairs(remotes) do
            pcall(function() r:FireServer(item) end)
        end
    end
end

local function makeMenu()
    destroyMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CSK_PRO_HileMenu"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = LocalPlayer.PlayerGui
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0,390,0,180)
    main.Position = UDim2.new(0.5, -195, 0.45, -90)
    main.BackgroundColor3 = Color3.fromRGB(33,33,44)
    main.BorderSizePixel = 0
    main.Parent = gui
    roundify(main, 20)
    local title = Instance.new("TextLabel")
    title.Parent = main
    title.Size = UDim2.new(1,0,0,45)
    title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1
    title.Text = "Cali Sokaklari | Hile Menüsü"
    title.TextColor3 = Color3.fromRGB(255,208,61)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 26

    local closeB = Instance.new("TextButton")
    closeB.Parent = main
    closeB.Size = UDim2.new(0,33,0,32)
    closeB.Position = UDim2.new(1,-36,0,7)
    closeB.Text = "X"
    closeB.Font = Enum.Font.GothamBold
    closeB.TextSize = 18
    closeB.BackgroundColor3 = Color3.fromRGB(191,48,57)
    closeB.TextColor3 = Color3.fromRGB(255,255,255)
    roundify(closeB,8)
    closeB.MouseButton1Click:Connect(function() destroyMenu() end)

    local status = Instance.new("TextLabel")
    status.Parent = main
    status.Position = UDim2.new(0,0,1,-32)
    status.Size = UDim2.new(1,0,0,26)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(186,232,159)
    status.Font = Enum.Font.Gotham
    status.Text = "Hazır."
    status.TextSize = 16
    status.Name = "Status"

    local function addBtn(txt, cb, ypos, clr)
        local btn = Instance.new("TextButton")
        btn.Parent = main
        btn.Size = UDim2.new(0.92,0,0,38)
        btn.Position = UDim2.new(0.04,0,0,ypos)
        btn.BackgroundColor3 = clr or Color3.fromRGB(41,48,54)
        btn.TextColor3 = Color3.fromRGB(230,230,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 18
        btn.Text = txt
        btn.AutoButtonColor = true
        roundify(btn,11)
        btn.MouseButton1Down:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(70,70,90) end)
        btn.MouseButton1Up:Connect(function() btn.BackgroundColor3 = clr or Color3.fromRGB(41,48,54) end)
        btn.MouseButton1Click:Connect(function() pcall(cb) end)
        return btn
    end

    local Y = 52
    addBtn("1.000.000 Para Ver", function()
        realGiveMoney(1000000)
        status.Text = "1 milyon para verildi!"
    end, Y)
    Y = Y + 45
    addBtn("Tüm Eşyaları Ver", function()
        realGiveAllItems()
        status.Text = "Tüm oyun itemleri alındı, envanterine bak!"
    end, Y)
    Y = Y + 45
    addBtn("Menüyü Kapat", function()
        destroyMenu()
    end, Y, Color3.fromRGB(191,48,57))
end

local function showMenuIfNotThere()
    if not LocalPlayer.PlayerGui:FindFirstChild("CSK_PRO_HileMenu") then
        pcall(makeMenu)
    end
end

spawn(function()
    for i=1,20 do
        wait(0.5)
        showMenuIfNotThere()
    end
end)

local function menuHotkey()
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed then
            if input.KeyCode == Enum.KeyCode.F4 or input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightControl then
                if LocalPlayer.PlayerGui:FindFirstChild("CSK_PRO_HileMenu") then
                    destroyMenu()
                else
                    showMenuIfNotThere()
                end
            end
        end
    end)
end

menuHotkey()
