// BU SCRIPT, CAli Sokaklari benzeri ROBLOX oyunları içindir, bir exploit ile/LocalScript olarak çalışır. Hile MENÜSÜ profesyonelce GUI ile gelir ve her cheat menülerden tek tık ile aktif edilir.

// Gelişmiş ayarlarla menü tamamen özelleştirildi, düğmeler animasyonlu, istediğin kadar fonksiyon eklenebilir, bug fixler dahil. Her seçenek GUI'dan kontrol edilir.

local player = game:GetService("Players").LocalPlayer
local plrGui = player:WaitForChild("PlayerGui")
local UIS = game:GetService("UserInputService")

local function roundify(obj, rad)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, rad or 16)
    c.Parent = obj
    return c
end

local function makeDrag(frame)
    local dragtoggle = false
    local dragInput, mousePos, framePos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragtoggle = true
            mousePos = input.Position
            framePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragtoggle = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragtoggle then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

local function destroyMenu()
    if plrGui:FindFirstChild("CaliHileMenu") then
        plrGui.CaliHileMenu:Destroy()
    end
end

local function makeMenu()
    destroyMenu()
    local menu = Instance.new("ScreenGui")
    menu.Name = "CaliHileMenu"
    menu.Parent = plrGui
    menu.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.BackgroundColor3 = Color3.fromRGB(30,30,40)
    main.BorderSizePixel = 0
    main.Size = UDim2.new(0,360,0,440)
    main.Position = UDim2.new(0.5,-180,0.45,-220)
    main.Visible = true
    main.Parent = menu
    roundify(main, 18)
    makeDrag(main)

    local title = Instance.new("TextLabel")
    title.Parent = main
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1,0,0,42)
    title.Position = UDim2.new(0,0,0,0)
    title.Text = "Cali Sokaklari VIP Menu"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 25
    title.TextColor3 = Color3.fromRGB(255, 212, 49)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = main
    closeBtn.Size = UDim2.new(0,40,0,40)
    closeBtn.Position = UDim2.new(1,-45,0,5)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 22
    closeBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
    closeBtn.TextColor3 = Color3.fromRGB(250,250,250)
    roundify(closeBtn,8)
    closeBtn.MouseButton1Click:Connect(destroyMenu)

    local function makeBtn(text, cb, ypad)
        local btn = Instance.new("TextButton")
        btn.Parent = main
        btn.Size = UDim2.new(0.9,0,0,38)
        btn.Position = UDim2.new(0.05,0,0,ypad)
        btn.BackgroundColor3 = Color3.fromRGB(40,48,55)
        btn.TextColor3 = Color3.fromRGB(211,243,211)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 19
        btn.Text = text
        btn.AutoButtonColor = true
        roundify(btn,11)
        btn.MouseButton1Down:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(95, 101, 117)
        end)
        btn.MouseButton1Up:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(40,48,55)
        end)
        btn.MouseButton1Click:Connect(
            function() pcall(cb) end
        )
        return btn
    end

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = main
    statusLabel.BackgroundTransparency = 1
    statusLabel.Size = UDim2.new(1,0,0,26)
    statusLabel.Position = UDim2.new(0,0,1,-26)
    statusLabel.Text = "Beklemede - Hazır"
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 17
    statusLabel.TextColor3 = Color3.fromRGB(183,236,120)
    statusLabel.Name = "StatusLabel"

    local list = {
        {"1.000.000 Para Ver", function()
            giveMoney(1000000)
            statusLabel.Text = "Para hilesi uygulandı!"
        end},
        {"Tüm Silahları Al", function()
            giveAllGuns()
            statusLabel.Text = "Tüm silahlar eklendi!"
        end},
        {"Godmode (Ölümsüzlük)", function()
            godMode()
            statusLabel.Text = "Godmode aktif!"
        end},
        {"Tüm Itemleri Al", function()
            giveAllItems()
            statusLabel.Text = "Itemler Backpacke geldi!"
        end},
        {"Rastgele Teleport (Map)", function()
            teleportRandom()
            statusLabel.Text = "Teleport olundu!"
        end},
        {"Gizli Odaya Işınlan", function()
            teleportSecret()
            statusLabel.Text = "Gizli odaya ışınlandın!"
        end},
        {"Hız Hilesi (Speed x2)", function()
            speedHack(2)
            statusLabel.Text = "Hız hilesi aktif!"
        end},
        {"Normal Hız", function()
            speedHack(1)
            statusLabel.Text = "Hız sıfırlandı!"
        end},
        {"Tüm Eşyaları Doldur", function()
            allFill()
            statusLabel.Text = "Full depolandı!"
        end},
        {"Menüyü Kapat", function()
            destroyMenu()
        end},
    }
    local yval = 55
    for _,v in ipairs(list) do
        makeBtn(v[1], v[2], yval)
        yval = yval + 41
    end
end

function getRemotes(keys)
    local found = {}
    local function search(cont)
        for _,v in pairs(cont:GetChildren()) do
            for _,k in pairs(keys) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    if v.Name:match(k) then table.insert(found, v) end
                end
            end
            search(v)
        end
    end
    pcall(function() search(game:GetService("ReplicatedStorage")) end)
    pcall(function() search(game:GetService("Workspace")) end)
    return found
end

function giveMoney(amount)
    local remotes = getRemotes({"Money","money","AddMoney","addmoney","GiveMoney","Bakiye"})
    for _,r in pairs(remotes) do
        for i = 1, math.floor(amount/50000) do
            pcall(function() r:FireServer(50000) end)
        end
    end
    if player:FindFirstChild("leaderstats") then
        local cash = player.leaderstats:FindFirstChild("Money") or player.leaderstats:FindFirstChild("cash")
        if cash then cash.Value = cash.Value + amount end
    end
end

function giveAllGuns()
    local gunList = {"M4A1","DesertEagle","AK47","Shotgun","Tec9","Uzi","MP5","Sniper","Pistol","Knife"}
    for _,name in pairs(gunList) do
        giveItem(name)
    end
end

function godMode()
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        local h = player.Character:FindFirstChildOfClass("Humanoid")
        h.MaxHealth = 1e7
        h.Health = 9e6
    end
    if player.Character:FindFirstChild("Armor") then
        player.Character.Armor.Value = 999999
    end
end

function allFill()
    giveAllGuns()
    giveAllItems()
    godMode()
    giveMoney(1000000)
end

function giveAllItems()
    local otherItems = {"Anahtar","Lockpick","Drill","Telefon","Mask","Bandaj","Canta","Armor","Cigarette"}
    for _,name in pairs(otherItems) do
        giveItem(name)
    end
end

function giveItem(itemName)
    if player.Backpack:FindFirstChild(itemName) == nil then
        local tool = Instance.new("Tool")
        tool.Name = itemName
        tool.RequiresHandle = false
        tool.Parent = player.Backpack
    end
    local remotes = getRemotes({"Give"..itemName,itemName,"AddItem","Item"})
    for _,remote in ipairs(remotes) do
        pcall(function() remote:FireServer(itemName) end)
    end
end

function teleportRandom()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(math.random(-250,250), 10, math.random(-250,250))
    end
end

function teleportSecret()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-111,7,135) -- Bu koordinatı oyunun saklı yerlerine göre değiştir!
    end
end

function speedHack(mult)
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 * mult
    end
end

makeMenu()

UIS.InputBegan:Connect(function(input,gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightControl then
            if plrGui:FindFirstChild("CaliHileMenu") then
                destroyMenu()
            else
                makeMenu()
            end
        end
        if input.KeyCode == Enum.KeyCode.F4 then
            makeMenu()
        end
    end
end)
