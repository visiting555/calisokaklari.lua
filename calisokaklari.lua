-- Cali Sokaklari - Gelişmiş Hile Scripti v4 (Menü Garantili, Full Fonksiyonel ve Stabil)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = nil
pcall(function() StarterGui:SetCore("SendNotification", {Title="Script"; Text="Cali Sokaklari Hile v4 Aktif!"; Duration=3;}) end)

local function roundify(gui, rad)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, rad or 14)
    corner.Parent = gui
end

local function destroyMenu()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("CSK_PRO_HileMenu")
    if gui then gui:Destroy() end
end

local function makeDrag(gui)
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
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    gui.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
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

local function giveMoney(amount)
    local remotes = findRemote({"money", "para", "bakiye", "add", "give"})
    local limit = 50000
    for _ = 1, math.floor(amount/limit) do
        for _, r in ipairs(remotes) do
            pcall(function() r:FireServer(limit) end)
        end
    end
    for _, r in ipairs(remotes) do
        local kalan = amount % limit
        if kalan > 0 then
            pcall(function() r:FireServer(kalan) end)
        end
    end
    if LocalPlayer:FindFirstChild("leaderstats") then
        local cash = LocalPlayer.leaderstats:FindFirstChild("Money") or LocalPlayer.leaderstats:FindFirstChild("money") or LocalPlayer.leaderstats:FindFirstChild("Bakiye")
        if cash then
            cash.Value = cash.Value + amount
        end
    end
end

local function giveAllGuns()
    local gunList = {"M4A1","AK47","DesertEagle","Shotgun","Tec9","Uzi","MP5","Sniper","Pistol","Knife"}
    for _, gun in ipairs(gunList) do
        if not LocalPlayer.Backpack:FindFirstChild(gun) then
            local tool = Instance.new("Tool")
            tool.RequiresHandle = false
            tool.Name = gun
            tool.Parent = LocalPlayer.Backpack
        end
        for _, r in ipairs(findRemote({gun, "weapon", "give"})) do
            pcall(function() r:FireServer(gun) end)
        end
    end
end

local function giveAllItems()
    local items = {"Lockpick","Anahtar","Drill","Telefon","Canta","Mask","Bandaj","Armor","Cigarette"}
    for _, item in ipairs(items) do
        if not LocalPlayer.Backpack:FindFirstChild(item) then
            local tool = Instance.new("Tool")
            tool.RequiresHandle = false
            tool.Name = item
            tool.Parent = LocalPlayer.Backpack
        end
        for _, r in ipairs(findRemote({item, "item", "give"})) do
            pcall(function() r:FireServer(item) end)
        end
    end
end

local function setGodMode()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        h.MaxHealth = math.huge
        h.Health = math.huge
    end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Armor") then
        LocalPlayer.Character.Armor.Value = 999999
    end
end

local function teleportWhere(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
    end
end

local function teleportRandom()
    teleportWhere(CFrame.new(math.random(-210,210), 10, math.random(-210,210)))
end

local function teleportSecret()
    teleportWhere(CFrame.new(-103,9,143))
end

local function speedHack(mult)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 * mult
    end
end

local function jumpHack(mult)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50 * mult
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
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
            plr.Character:FindFirstChildOfClass("Humanoid").Health = 0
        end
    end
end

local function trollAll()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = CFrame.new(math.random(-250,250),80,math.random(-250,250))
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
    if not VirtualUser then
        pcall(function() VirtualUser = game:GetService("VirtualUser") end)
    end
    pcall(function()
        local cns = (getconnections or (syn and syn.getconnections)) and ((getconnections or (syn and syn.getconnections))(LocalPlayer.Idled)) or nil
        if cns then
            for _,v in ipairs(cns) do
                pcall(function() v:Disable() end)
            end
        else
            LocalPlayer.Idled:Connect(function()
                if VirtualUser then
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end
            end)
        end
    end)
end

local function noclip(state)
    local con = _G.CSKPRO_NoclipCon
    if state then
        if not con then
            _G.CSKPRO_Noclip = true
            _G.CSKPRO_NoclipCon = RunService.Stepped:Connect(function()
                if _G.CSKPRO_Noclip and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        _G.CSKPRO_Noclip = false
        if con then
            con:Disconnect()
            _G.CSKPRO_NoclipCon = nil
        end
    end
end

local function flyMode(state)
    local flyCon = _G.CSKPRO_FlyCon
    if state then
        _G.CSKPRO_Fly = true
        local speed = 3
        local bodyVel
        local function startFly()
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    bodyVel = root:FindFirstChild("__CSKPRO_flyvel") or Instance.new("BodyVelocity")
                    bodyVel.Name = "__CSKPRO_flyvel"
                    bodyVel.Parent = root
                    bodyVel.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
                    bodyVel.Velocity = Vector3.new()
                    if _G.CSKPRO_FlyCon then _G.CSKPRO_FlyCon:Disconnect() end
                    _G.CSKPRO_FlyCon = RunService.Heartbeat:Connect(function()
                        if not _G.CSKPRO_Fly then bodyVel.Velocity = Vector3.new(); return end
                        local dir = Vector3.new()
                        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + workspace.CurrentCamera.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - workspace.CurrentCamera.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - workspace.CurrentCamera.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + workspace.CurrentCamera.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + workspace.CurrentCamera.CFrame.UpVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - workspace.CurrentCamera.CFrame.UpVector end
                        bodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * speed * 22 or Vector3.new()
                    end)
                end
            end)
        end
        startFly()
        if _G.CSKPRO_FlyCharAdded then _G.CSKPRO_FlyCharAdded:Disconnect() end
        _G.CSKPRO_FlyCharAdded = LocalPlayer.CharacterAdded:Connect(function()
            wait(1)
            startFly()
        end)
    else
        _G.CSKPRO_Fly = false
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local root = LocalPlayer.Character.HumanoidRootPart
            local bv = root:FindFirstChild("__CSKPRO_flyvel")
            if bv then bv:Destroy() end
        end
        if _G.CSKPRO_FlyCon then _G.CSKPRO_FlyCon:Disconnect() _G.CSKPRO_FlyCon = nil end
        if _G.CSKPRO_FlyCharAdded then _G.CSKPRO_FlyCharAdded:Disconnect() _G.CSKPRO_FlyCharAdded = nil end
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
    main.Size = UDim2.new(0,420,0,590)
    main.Position = UDim2.new(0.5, -210, 0.45, -295)
    main.BackgroundColor3 = Color3.fromRGB(33,33,44)
    main.BorderSizePixel = 0
    main.Parent = gui
    roundify(main, 24)
    makeDrag(main)
    local title = Instance.new("TextLabel")
    title.Parent = main
    title.Size = UDim2.new(1,0,0,52)
    title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1
    title.Text = "Cali Sokaklari | PRO Hile Menüsü"
    title.TextColor3 = Color3.fromRGB(255,208,61)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 30

    local closeB = Instance.new("TextButton")
    closeB.Parent = main
    closeB.Size = UDim2.new(0,40,0,42)
    closeB.Position = UDim2.new(1,-43,0,6)
    closeB.Text = "X"
    closeB.Font = Enum.Font.GothamBold
    closeB.TextSize = 23
    closeB.BackgroundColor3 = Color3.fromRGB(191,48,57)
    closeB.TextColor3 = Color3.fromRGB(255,255,255)
    roundify(closeB,10)
    closeB.MouseButton1Click:Connect(function()
        destroyMenu()
    end)

    local status = Instance.new("TextLabel")
    status.Parent = main
    status.Position = UDim2.new(0,0,1,-34)
    status.Size = UDim2.new(1,0,0,28)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(186,232,159)
    status.Font = Enum.Font.Gotham
    status.Text = "Hazır."
    status.TextSize = 18
    status.Name = "Status"

    local function addBtn(txt, cb, ypos, clr)
        local btn = Instance.new("TextButton")
        btn.Parent = main
        btn.Size = UDim2.new(0.92,0,0,39)
        btn.Position = UDim2.new(0.04,0,0,ypos)
        btn.BackgroundColor3 = clr or Color3.fromRGB(41,48,54)
        btn.TextColor3 = Color3.fromRGB(230,230,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 19
        btn.Text = txt
        btn.AutoButtonColor = true
        roundify(btn,11)
        btn.MouseButton1Down:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(70,70,90) end)
        btn.MouseButton1Up:Connect(function() btn.BackgroundColor3 = clr or Color3.fromRGB(41,48,54) end)
        btn.MouseButton1Click:Connect(function() pcall(cb) end)
        return btn
    end

    local Y = 57
    addBtn("1.000.000 Para Ver", function()
        giveMoney(1000000)
        status.Text = "1 milyon para verildi!"
    end, Y)
    Y = Y + 46
    addBtn("Tüm Silahları Al", function()
        giveAllGuns()
        status.Text = "Tüm silahlar verildi!"
    end, Y)
    Y = Y + 46
    addBtn("Tüm Eşyaları Al", function()
        giveAllItems()
        status.Text = "Tüm itemler alındı."
    end, Y)
    Y = Y + 46
    addBtn("God Mod (Ölümsüzlük)", function()
        setGodMode()
        status.Text = "God mode aktifleştirildi!"
    end, Y)
    Y = Y + 46
    addBtn("Rastgele Teleport", function()
        teleportRandom()
        status.Text = "Rastgele yere ışınlandın!"
    end, Y)
    Y = Y + 46
    addBtn("Gizli Odaya Git", function()
        teleportSecret()
        status.Text = "Gizli odaya ışınlandın!"
    end, Y)
    Y = Y + 46
    addBtn("Hız Hilesi x2", function()
        speedHack(2)
        status.Text = "Hız x2 oldu!"
    end, Y)
    Y = Y + 46
    addBtn("Hızı Sıfırla", function()
        speedHack(1)
        status.Text = "Yürüyüş hızı sıfırlandı."
    end, Y)
    Y = Y + 46
    addBtn("Zıplama Gücünü x2 Yap", function()
        jumpHack(2)
        status.Text = "Zıplama x2 oldu!"
    end, Y)
    Y = Y + 46
    addBtn("Zıplama Sıfırla", function()
        jumpHack(1)
        status.Text = "Zıplama sıfırlandı."
    end, Y)
    Y = Y + 46
    addBtn("Tümünü Full Doldur", function()
        fillEverything()
        status.Text = "Tüm her şey doldu."
    end, Y)
    Y = Y + 46
    addBtn("Tüm Oyuncuları Öldür", function()
        killAllPlayers()
        status.Text = "Tüm oyuncular öldürüldü!"
    end, Y)
    Y = Y + 46
    addBtn("Trol Teleport (Herkes)", function()
        trollAll()
        status.Text = "Herkes rastgele yere ışınlandı!"
    end, Y)
    Y = Y + 46
    addBtn("Anti-AFK", function()
        antiAfk()
        status.Text = "AFK atma açıldı!"
    end, Y)
    Y = Y + 46
    addBtn("Noclip Aç/Kapat", function()
        if _G.CSKPRO_Noclip then
            noclip(false)
            status.Text = "Noclip kapatıldı."
        else
            noclip(true)
            status.Text = "Noclip aktif!"
        end
    end, Y)
    Y = Y + 46
    addBtn("Fly Modu Aç/Kapat", function()
        if _G.CSKPRO_Fly then
            flyMode(false)
            status.Text = "Fly Kapalı."
        else
            flyMode(true)
            status.Text = "Fly Açık!"
        end
    end, Y)

    local searchBox = Instance.new("TextBox")
    searchBox.Parent = main
    searchBox.Size = UDim2.new(0.59,0,0,35)
    searchBox.Position = UDim2.new(0.04,0,0,Y)
    searchBox.Text = ""
    searchBox.PlaceholderText = "Oyuncu Ara & Yanına Git"
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 16
    searchBox.BackgroundColor3 = Color3.fromRGB(30,33,39)
    searchBox.TextColor3 = Color3.fromRGB(188,232,255)
    roundify(searchBox,8)

    local tpBtn = Instance.new("TextButton")
    tpBtn.Parent = main
    tpBtn.Size = UDim2.new(0.35,0,0,35)
    tpBtn.Position = UDim2.new(0.63,0,0,Y)
    tpBtn.Text = "Git"
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 17
    tpBtn.BackgroundColor3 = Color3.fromRGB(15,167,80)
    tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
    roundify(tpBtn,8)
    tpBtn.MouseButton1Click:Connect(function()
        if #searchBox.Text > 0 then
            tpToPlayer(searchBox.Text)
            status.Text = searchBox.Text.." adlı oyuncuya gittin."
        end
    end)

    Y = Y + 47
    addBtn("Menüyü Kapat", function()
        destroyMenu()
    end, Y, Color3.fromRGB(191,48,57))
end

local function showMenuIfNotThere()
    if not LocalPlayer.PlayerGui:FindFirstChild("CSK_PRO_HileMenu") then
        pcall(makeMenu)
    end
end

-- Menü Açılışını Garanti Altına Al (İstemci hazır olduktan sonra sürekli dener)
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
