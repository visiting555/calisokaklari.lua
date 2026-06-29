// Roblox'un Lua tabanlı LocalScript örneğidir. Bu script, oyun içinde GUI menüsü ile para ve item hilesi yapılmasını simüle eder. 
// Her şeyin çalışabilmesi için exploit ortamı (ör. Synapse X) gerekebilir. YASAL UYARI: Hile kullanımı hesabınızı kalıcı olarak engeller! 
// Script, Roblox "Cali Sokaklari" tarzı oyunlara uyarlanabilir. Kendi sorumluluğunuzda.

// Kullanıcı menüsü, para, item, silah verme ve teleport fonksiyonları içerir.

local player = game.Players.LocalPlayer
local plrGui = player:WaitForChild("PlayerGui")

function createMainMenu()
    if plrGui:FindFirstChild("HileMenu") ~= nil then
        plrGui:FindFirstChild("HileMenu"):Destroy()
    end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HileMenu"
    screenGui.Parent = plrGui

    local mainFrame = Instance.new("Frame")
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.Size = UDim2.new(0, 350, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -175, 0.4, -210)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local y = 15

    local function makeButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -30, 0, 36)
        btn.Position = UDim2.new(0, 15, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        btn.TextColor3 = Color3.fromRGB(248,248,248)
        btn.Text = text
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        btn.Parent = mainFrame
        btn.MouseButton1Click:Connect(callback)
        y = y + 45
        return btn
    end

    makeButton("Give 1.000.000 Money", function()
        giveMoney(1000000)
    end)

    makeButton("Give All Guns", function()
        giveAllGuns()
    end)

    makeButton("Give GodMode (Armor/Health)", function()
        giveGodMode()
    end)

    makeButton("Give All Items", function()
        giveAllItems()
    end)
    
    makeButton("Teleport Random Location", function()
        teleportRandomLocation()
    end)

    makeButton("Teleport To Safehouse", function()
        teleportSafehouse()
    end)

    makeButton("Destroy Menu", function()
        screenGui:Destroy()
    end)
end

function giveMoney(amount)
    local remotes = findRemotes({"Money", "cash", "addmoney", "GiveMoney"})
    for _, remote in ipairs(remotes) do
        for i=1, math.ceil(amount/100000) do
            pcall(function() remote:FireServer(100000) end)
        end
    end
    -- Alternatif yollar
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and player:FindFirstChild("leaderstats") then
        local cash = player.leaderstats:FindFirstChild("Money") or player.leaderstats:FindFirstChild("cash")
        if cash then
            cash.Value = cash.Value + amount
        end
    end
end

function giveAllGuns()
    local possibleGuns = {"M4A1", "AK47", "Shotgun", "Sniper", "Pistol", "Tec9", "Uzi", "MP5", "Knife"}
    for _, gun in ipairs(possibleGuns) do
        giveItem(gun)
    end
end

function giveAllItems()
    local items = {"Key", "Lockpick", "Drill", "Phone", "Cigarette", "Mask", "Backpack", "Armor", "Bandage", "Radio"}
    for _, item in ipairs(items) do
        giveItem(item)
    end
end

function giveItem(itemName)
    local remotes = findRemotes({"Give"..itemName, itemName, "AddItem", "Item"})
    for _, remote in ipairs(remotes) do
        pcall(function() remote:FireServer(itemName) end)
    end
    -- Alternatif Backpack yoluyla
    if player.Backpack then
        local tool = Instance.new("Tool")
        tool.Name = itemName
        tool.RequiresHandle = false
        tool.Parent = player.Backpack
    end
end

function findRemotes(keywords)
    local found = {}
    local function search(obj)
        for _,v in ipairs(obj:GetChildren()) do
            for _,kw in ipairs(keywords) do
                if string.find(string.lower(v.Name), string.lower(kw)) ~= nil then
                    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                        table.insert(found,v)
                    end
                end
            end
            search(v)
        end
    end
    pcall(function() search(game:GetService("ReplicatedStorage")) end)
    pcall(function() search(game:GetService("Workspace")) end)
    return found
end

function giveGodMode()
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        hum.MaxHealth = 1e6
        hum.Health = 1e6
    end
    -- Armor için klasik Armor objesi arayabilir
    if player.Character:FindFirstChild("Armor") then
        player.Character.Armor.Value = 99999
    end
end

function teleportRandomLocation()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local x, y, z = math.random(-300,300), 6, math.random(-300,300)
        player.Character.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
    end
end

function teleportSafehouse()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(125, 5, -180)
    end
end

createMainMenu()

-- Otomatik olarak menüyü tekrar açmak için "Z" tuşuna bağlan
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, g)
    if not g and input.KeyCode == Enum.KeyCode.Z then
        createMainMenu()
    end
end)
