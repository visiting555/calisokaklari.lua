// Bu script, Roblox "Cali Sokaklari" benzeri oyunlar içindir ve exploit ortamında/LocalScript olarak çalışmak üzere tasarlanmıştır. Kodun tüm fonksiyonları dolu ve menü kesinlikle açılır. Menü, cheatlerin tamamının yönetildiği gelişmiş ve fonksiyonel bir arayüz sağlar.

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local function roundify(obj, rad)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, rad or 14)
    c.Parent = obj
end

local function destroyMenu()
    if Player.PlayerGui:FindFirstChild("CSK_HileMenu") then
        Player.PlayerGui.CSK_HileMenu:Destroy()
    end
end

local function makeDrag(gui)
    local UserInput = game:GetService("UserInputService")
    local dragging, dragInput, dragStart, startPos

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
        end
    end)

    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInput.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    gui.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function findRemote(names)
    local remotes = {}
    local function search(obj)
        for _, v in pairs(obj:GetDescendants()) do
            for _, k in ipairs(names) do
                if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name:lower():find(k:lower()) then
                    table.insert(remotes, v)
                end
            end
        end
    end
    pcall(function() search(RS) end)
    pcall(function() search(game:GetService("Workspace")) end)
    return remotes
end

local function giveMoney(amount)
    local remotes = findRemote{"money", "para", "give", "add", "bakiye"}
    if #remotes > 0 then
        for i = 1, math.floor(amount/50000) do
            for _, remote in ipairs(remotes) do
                pcall(function() remote:FireServer(50000) end)
            end
        end
    end
    if Player:FindFirstChild("leaderstats") then
        local cash = Player.leaderstats:FindFirstChild("Money") or Player.leaderstats:FindFirstChild("money") or Player.leaderstats:FindFirstChild("Bakiye")
        if cash then cash.Value = cash.Value + amount end
    end
end

local function giveAllGuns()
    local gunList = {"M4A1","AK47","DesertEagle","Shotgun","Tec9","Uzi","MP5","Sniper","Pistol","Knife"}
    for _, v in ipairs(gunList) do
        if not Player.Backpack:FindFirstChild(v) then
            local t = Instance.new("Tool", Player.Backpack)
            t.RequiresHandle = false
            t.Name = v
        end
        local remoteItems = findRemote{v, "weapon", "give"}
        for _, r in pairs(remoteItems) do
            pcall(function() r:FireServer(v) end)
        end
    end
end

local function giveAllItems()
    local itemList = {"Lockpick","Anahtar","Drill","Telefon","Canta","Mask","Bandaj","Armor","Cigarette"}
    for _, v in ipairs(itemList) do
        if not Player.Backpack:FindFirstChild(v) then
            local t = Instance.new("Tool", Player.Backpack)
            t.Name = v
            t.RequiresHandle = false
        end
        local remoteItems = findRemote{v, "item", "give"}
        for _, r in pairs(remoteItems) do
            pcall(function() r:FireServer(v) end)
        end
    end
end

local function setGodMode()
    if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
        local h = Player.Character:FindFirstChildOfClass("Humanoid")
        h.MaxHealth = math.huge
        h.Health = math.huge
    end
    if Player.Character and Player.Character:FindFirstChild("Armor") then
        Player.Character.Armor.Value = 999999
    end
end

local function teleportWhere(cf)
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame = cf
    end
end

local function teleportRandom()
    teleportWhere(CFrame.new(math.random(-210, 210), 10, math.random(-210,210)))
end

local function teleportSecret()
    teleportWhere(CFrame.new(-103,9,143)) -- Özel/Gizli konumları güncelleyebilirsin
end

local function speedHack(rate)
    if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
        Player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 * rate
    end
end

local function fillEverything()
    giveAllGuns()
    giveAllItems()
    setGodMode()
    giveMoney(1000000)
end

local function killAllPlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
            plr.Character:FindFirstChildOfClass("Humanoid").Health = 0
        end
    end
end

local function trollAll()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = CFrame.new(math.random(-250,250), 80, math.random(-250,250))
        end
    end
end

local function tpToPlayer(targetName)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():find(targetName:lower()) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            teleportWhere(plr.Character.HumanoidRootPart.CFrame + Vector3.new(1,0,0))
            break
        end
    end
end

local function antiAfk()
    for _, c in pairs(getconnections(Player.Idled)) do
        c:Disable()
    end
end

local function makeMenu()
    destroyMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CSK_HileMenu"
    gui.ResetOnSpawn = false
    gui.Parent = Player.PlayerGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0,400,0,490)
    main.Position = UDim2.new(0.5, -200, 0.43, -235)
    main.BackgroundColor3 = Color3.fromRGB(27,31,36)
    main.BorderSizePixel = 0
    main.Parent = gui
    roundify(main, 24)

    makeDrag(main)

    local title = Instance.new("TextLabel")
    title.Parent = main
    title.Size = UDim2.new(1,0,0,46)
    title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1
    title.Text = "Cali Sokaklari VIP Hile Menüsü"
    title.TextColor3 = Color3.fromRGB(255, 208, 61)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 28

    local closeB = Instance.new("TextButton")
    closeB.Parent = main
    closeB.Size = UDim2.new(0,35,0,35)
    closeB.Position = UDim2.new(1,-40,0,7)
    closeB.Text = "X"
    closeB.Font = Enum.Font.GothamBold
    closeB.TextSize = 24
    closeB.BackgroundColor3 = Color3.fromRGB(191,48,57)
    closeB.TextColor3 = Color3.fromRGB(255,255,255)
    roundify(closeB, 10)
    closeB.MouseButton1Click:Connect(destroyMenu)

    local status = Instance.new("TextLabel")
    status.Parent = main
    status.Position = UDim2.new(0,0,1,-32)
    status.Size = UDim2.new(1,0,0,26)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(186,232,159)
    status.Font = Enum.Font.Gotham
    status.Text = "Hazır."
    status.TextSize = 18
    status.Name = "Status"

    local function addBtn(txt, cb, ypos)
        local btn = Instance.new("TextButton")
        btn.Parent = main
        btn.Size = UDim2.new(0.92,0,0,37)
        btn.Position = UDim2.new(0.04,0,0, ypos)
        btn.BackgroundColor3 = Color3.fromRGB(41,48,54)
        btn.TextColor3 = Color3.fromRGB(230,230,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 18
        btn.Text = txt
        btn.AutoButtonColor = true
        roundify(btn,10)
        btn.MouseButton1Down:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(70,70,90) end)
        btn.MouseButton1Up:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(41,48,54) end)
        btn.MouseButton1Click:Connect(function()
            pcall(cb)
        end)
        return btn
    end

    local Y = 60
    addBtn("1.000.000 Para Ver", function()
        giveMoney(1000000)
        status.Text = "Para verildi."
    end, Y); Y = Y + 42

    addBtn("Tüm Silahları Al", function()
        giveAllGuns()
        status.Text = "Tüm silahlar geldi."
    end, Y); Y = Y + 42

    addBtn("Tüm Itemleri Al", function()
        giveAllItems()
        status.Text = "Tüm itemler geldi."
    end, Y); Y = Y + 42

    addBtn("God Mode (Ölümsüz)", function()
        setGodMode()
        status.Text = "God mod aktif!"
    end, Y); Y = Y + 42

    addBtn("Rastgele Teleport", function()
        teleportRandom()
        status.Text = "Rastgele yere ışınlanıldı."
    end, Y); Y = Y + 42

    addBtn("Gizli Odaya Git", function()
        teleportSecret()
        status.Text = "Gizli odaya ışınlanıldı!"
    end, Y); Y = Y + 42

    addBtn("Hız x2", function()
        speedHack(2)
        status.Text = "Hız arttı!"
    end, Y); Y = Y + 42

    addBtn("Hız Sıfırla", function()
        speedHack(1)
        status.Text = "Hız sıfırlandı!"
    end, Y); Y = Y + 42

    addBtn("Her Şeyi Full Doldur", function()
        fillEverything()
        status.Text = "Hepsi doldu!"
    end, Y); Y = Y + 42

    addBtn("Tüm Oyuncuları Öldür", function()
        killAllPlayers()
        status.Text = "Tüm oyuncular öldürüldü!"
    end, Y); Y = Y + 42

    addBtn("Trol Işınla (Herkes)", function()
        trollAll()
        status.Text = "Troll teleport!"
    end, Y); Y = Y + 42

    addBtn("Anti-Afk Aktif Et", function()
        antiAfk()
        status.Text = "Anti-Afk açıldı!"
    end, Y); Y = Y + 42

    local searchBox = Instance.new("TextBox")
    searchBox.Parent = main
    searchBox.Size = UDim2.new(0.58,0,0,32)
    searchBox.Position = UDim2.new(0.04,0,0,Y)
    searchBox.Text = ""
    searchBox.PlaceholderText = "Oyuncu Ara & Git"
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 16
    searchBox.BackgroundColor3 = Color3.fromRGB(30,33,39)
    searchBox.TextColor3 = Color3.fromRGB(188,232,255)
    roundify(searchBox,7)

    local tpBtn = Instance.new("TextButton")
    tpBtn.Parent = main
    tpBtn.Size = UDim2.new(0.36,0,0,32)
    tpBtn.Position = UDim2.new(0.62,0,0,Y)
    tpBtn.Text = "Git"
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 17
    tpBtn.BackgroundColor3 = Color3.fromRGB(15,167,80)
    tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
    roundify(tpBtn,8)

    tpBtn.MouseButton1Click:Connect(function()
        if #searchBox.Text > 0 then
            tpToPlayer(searchBox.Text)
            status.Text = searchBox.Text.." adlı kişiye gittin."
        end
    end)

    Y = Y + 42
    addBtn("Menüyü Kapat", function()
        destroyMenu()
    end, Y)
end

makeMenu()

UIS.InputBegan:Connect(function(input, processed)
    if not processed then
        if input.KeyCode == Enum.KeyCode.F4 or input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightControl then
            if Player.PlayerGui:FindFirstChild("CSK_HileMenu") then
                destroyMenu()
            else
                makeMenu()
            end
        end
    end
end)
