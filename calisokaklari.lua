-- Cali Sokaklari - Sadece Para ve Gerçek Tüm Item Hilesi (Fixli Tam Menü)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
pcall(function() StarterGui:SetCore("SendNotification", {Title="Script"; Text="Cali Sokaklari Hile Menüsü Aktif!"; Duration=3;}) end)

local LastStatus = ""

local function roundify(gui, rad)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, rad or 14)
    corner.Parent = gui
end

local function destroyMenu()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("CSK_PRO_HileMenu")
    if gui then gui:Destroy() end
end

local function getRealItemList()
    local backpack = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer.Backpack
    local found = {}
    local tested = {}
    local containers = {}

    for _, folderName in ipairs({"Items", "Itemler", "Envanter", "Shop", "Market"}) do
        local f = ReplicatedStorage:FindFirstChild(folderName)
        if f and (f:IsA("Folder") or f:IsA("Model") or f:IsA("Configuration")) then
            table.insert(containers, f)
        end
    end

    local ids = {}
    for _,container in ipairs(containers) do
        for _,v in ipairs(container:GetDescendants()) do
            if (v:IsA("Tool") or v:IsA("Model")) and not ids[v.Name] then
                ids[v.Name]=true
                table.insert(found, v.Name)
            end
        end
    end

    local common_items = {
        "Lockpick","Anahtar","Drill","Telefon","Canta","Mask","Bandaj","Armor",
        "Cigarette","Cekic","Tablet","Painkiller","EnergyDrink","Pistol","DesertEagle",
        "MP5","M4A1","AK47","Tec9","Sniper","Uzi","Shotgun","Knife"
    }
    for _,it in ipairs(common_items) do
        if not ids[it] then
            ids[it]=true
            table.insert(found,it)
        end
    end

    -- Envanterinizdeki itemleri ekle
    if backpack then
        for _,item in ipairs(backpack:GetChildren()) do
            if (item:IsA("Tool") or item:IsA("Model")) and not ids[item.Name] then
                ids[item.Name]=true
                table.insert(found,item.Name)
            end
        end
    end

    return found
end

local function findRemote(keywords, kind)
    local found = {}
    local function scan(obj)
        for _, v in ipairs(obj:GetDescendants()) do
            if kind and not v:IsA(kind) then continue end
            for _, w in ipairs(keywords) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    if v.Name:lower():find(w:lower()) then
                        table.insert(found, v)
                    end
                end
            end
        end
    end
    pcall(function() scan(ReplicatedStorage) end)
    return found
end

local function tryGiveMoney(amount)
    local remotes = findRemote({"para", "money", "bakiye", "add", "ver"})
    -- Deneme: remotelere farklı parametre kombinasyonlarını dener
    local success = false
    for _,remote in ipairs(remotes) do
        for _,param in ipairs({amount, tostring(amount), {amount}, {tostring(amount)}, {LocalPlayer, amount}, {amount,LocalPlayer}}) do
            if type(param)=="table" then
                local ok = pcall(function() remote:FireServer(unpack(param)) end)
                success = success or ok
            else
                local ok = pcall(function() remote:FireServer(param) end)
                success = success or ok
            end
        end
    end
    -- Doğrudan leaderstats güncelleme
    local statsList = {"Money","money","Para","para","Bakiye","bakiye"}
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _,s in ipairs(statsList) do
            local m = ls:FindFirstChild(s)
            if m and type(m.Value)=="number" then
                m.Value = m.Value + amount
                success = true
            end
        end
    end
    return success
end

local function tryGiveRealAllItems()
    local given = 0
    local itemList = getRealItemList()
    local remotes = findRemote({"item", "ver", "give", "add"})
    local blacklist = {
        "PasPas","Pas pas","Paspas","TestItem","Test","TestArac","Fake","Yok","Empty"
    }
    for _,item in ipairs(itemList) do
        local skip = false
        for _,blk in ipairs(blacklist) do
            if item:lower():find(blk:lower()) then skip = true break end
        end
        if not skip then
            for _,remote in ipairs(remotes) do
                local ok,err = pcall(function()
                    remote:FireServer(item)
                end)
                if ok then given = given + 1 end
            end
        end
    end
    -- 2. yol: İnventory'e scriptli kopya
    local Backpack = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer.Backpack
    if Backpack then
        for _,item in ipairs(itemList) do
            local at = ReplicatedStorage:FindFirstChild(item, true)
            if at and at:IsA("Tool") then
                local ok,cloned = pcall(function() return at:Clone() end)
                if ok and cloned then
                    pcall(function() cloned.Parent = Backpack end)
                end
            end
        end
    end
    return given
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

    local function setStatus(txt)
        status.Text = txt
        LastStatus = txt
    end

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
        local running = false
        btn.MouseButton1Down:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(70,70,90) end)
        btn.MouseButton1Up:Connect(function() btn.BackgroundColor3 = clr or Color3.fromRGB(41,48,54) end)
        btn.MouseButton1Click:Connect(function()
            if running then return end
            running = true
            setStatus("Lütfen bekleyin...")
            pcall(cb)
            running = false
        end)
        return btn
    end

    local Y = 52
    addBtn("1.000.000 Para Ver", function()
        local ok = tryGiveMoney(1000000)
        if ok then
            setStatus("1 milyon para verildi!")
        else
            setStatus("Para verilemedi, oyun bypassı engelliyor olabilir.")
        end
    end, Y)
    Y = Y + 45
    addBtn("Tüm Oyun Eşyalarını Al", function()
        local given = tryGiveRealAllItems()
        if given > 0 then
            setStatus("Tüm oyun itemleri envanterine eklendi!")
        else
            setStatus("Eşyalar alınamadı! Anti-hile veya farklı sistem olabilir.")
        end
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
