// Blox Fruits Script
// Bu script Roblox Blox Fruits için ESP, Aimbot, Auto Farm, Stat Hack gibi özellikler içerir.
// NOT: Roblox exploit/apex environment gerektirir ve eğitim amaçlıdır.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = Workspace.CurrentCamera

local menuGui = nil
local toggles = {
    ESP = false,
    Aimbot = false,
    AutoFarm = false,
    StatHack = false,
    AutoStoreFruit = false
}
local espConnections = {}
local aimbotConn = nil
local farmConn = nil

local function createMenu()
    if menuGui then pcall(function() menuGui:Destroy() end) end

    menuGui = Instance.new("ScreenGui")
    menuGui.Name = "BFScriptMenu"
    menuGui.Parent = game.CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 330, 0, 410)
    frame.Position = UDim2.new(0, 40, 0, 100)
    frame.BackgroundColor3 = Color3.fromRGB(27,27,27)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = menuGui

    local title = Instance.new("TextLabel")
    title.Text = "Blox Fruits Pro Menu"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1,1,1)
    title.TextScaled = true
    title.Size = UDim2.new(1,0,0,40)
    title.BackgroundTransparency = 1
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "X"
    closeBtn.Size = UDim2.new(0,36,0,36)
    closeBtn.Position = UDim2.new(1,-40,0,4)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.new(1, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = frame
    closeBtn.MouseButton1Click:Connect(function()
        menuGui:Destroy()
        menuGui = nil
    end)

    local y = 50
    local function addBtn(name, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.92, 0, 0, 40)
        btn.Position = UDim2.new(0.04, 0, 0, y)
        btn.Text = name
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = Color3.new(1,1,1)
        btn.BackgroundColor3 = Color3.fromRGB(37,37,37)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = true
        btn.Parent = frame
        btn.MouseButton1Click:Connect(callback)
        y = y + 46
    end

    addBtn((toggles.ESP and "✔️ " or "❌ ").."ESP Aç/Kapat", function()
        toggles.ESP = not toggles.ESP
        setESP(toggles.ESP)
        createMenu()
    end)

    addBtn((toggles.Aimbot and "✔️ " or "❌ ").."Aimbot Aç/Kapat", function()
        toggles.Aimbot = not toggles.Aimbot
        setAimbot(toggles.Aimbot)
        createMenu()
    end)

    addBtn((toggles.AutoFarm and "✔️ " or "❌ ").."Auto Farm Aç/Kapat", function()
        toggles.AutoFarm = not toggles.AutoFarm
        setAutoFarm(toggles.AutoFarm)
        createMenu()
    end)

    addBtn("Max Statlar (Stat Hack)", function()
        statHack()
    end)

    addBtn("Meyveyi Otomatik Stashla", function()
        autoStoreFruit()
    end)
end

function getEnemies()
    local enemies = {}
    for _, mob in ipairs(Workspace.Enemies:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            table.insert(enemies, mob)
        end
    end
    return enemies
end

function setESP(state)
    for _,c in ipairs(espConnections) do
        pcall(function()
            if c.Gui then c.Gui:Destroy() end
            if c.Conn then c.Conn:Disconnect() end
        end)
    end
    espConnections = {}

    if state then
        for _,mob in ipairs(getEnemies()) do
            local bill = Instance.new("BillboardGui")
            bill.Adornee = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")
            bill.Size = UDim2.new(0,100,0,32)
            bill.AlwaysOnTop = true
            bill.Name = "ESP_LABEL"
            bill.Parent = menuGui

            local label = Instance.new("TextLabel")
            label.Parent = bill
            label.Size = UDim2.new(1,0,1,0)
            label.BackgroundTransparency = 1
            label.Text = mob.Name
            label.TextColor3 = Color3.new(1,1,0)
            label.TextStrokeTransparency = 0.5
            label.Font = Enum.Font.GothamBold
            label.TextScaled = true

            table.insert(espConnections, {Gui = bill, Mob = mob})
        end

        -- Her yeni spawnlanan mobu dinle
        local conn = Workspace.Enemies.ChildAdded:Connect(function(mob)
            RunService.Heartbeat:Wait()
            if mob and mob:FindFirstChild("Humanoid") then
                local bill = Instance.new("BillboardGui")
                bill.Adornee = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")
                bill.Size = UDim2.new(0,100,0,32)
                bill.AlwaysOnTop = true
                bill.Name = "ESP_LABEL"
                bill.Parent = menuGui

                local label = Instance.new("TextLabel")
                label.Parent = bill
                label.Size = UDim2.new(1,0,1,0)
                label.BackgroundTransparency = 1
                label.Text = mob.Name
                label.TextColor3 = Color3.new(1,1,0)
                label.TextStrokeTransparency = 0.5
                label.Font = Enum.Font.GothamBold
                label.TextScaled = true

                table.insert(espConnections, {Gui=bill, Mob=mob})
            end
        end)
        table.insert(espConnections, {Conn=conn})
    end
end

function getClosestEnemy()
    local minDist, closest = math.huge, nil
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart.Position
    for _,mob in ipairs(getEnemies()) do
        if mob:FindFirstChild("HumanoidRootPart") then
            local dist = (hrp - mob.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = mob
            end
        end
    end
    return closest
end

function setAimbot(state)
    if aimbotConn then pcall(function() aimbotConn:Disconnect() end) end
    aimbotConn = nil
    if state then
        aimbotConn = RunService.RenderStepped:Connect(function()
            local mob = getClosestEnemy()
            if mob and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, mob.HumanoidRootPart.Position)
            end
        end)
    end
end

function setAutoFarm(state)
    if farmConn then pcall(function() farmConn:Disconnect() end) end
    farmConn = nil
    if state then
        farmConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local mob = getClosestEnemy()
            if char and mob and char:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("HumanoidRootPart") then
                -- Teleport to mob
                char.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                -- Saldırı
                for _,v in pairs(char:GetChildren()) do
                    if v:IsA("Tool") then
                        v:Activate()
                        break
                    end
                end
            end
        end)
    end
end

function statHack()
    -- Hile ile max statları ver
    local events = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
    local addPoint = events:FindFirstChild("addPointRemote") or events:FindFirstChild("CommF_")
    if addPoint then
        for _,stat in ipairs({"Melee","Defense","Sword","Gun","Devil Fruit"}) do
            for i=1,50 do
                pcall(function()
                    addPoint:InvokeServer("AddPoint", stat, 1)
                end)
            end
        end
    end
    game.StarterGui:SetCore("SendNotification", {
        Title = "Stat Hack",
        Text = "Bütün statlar maks seviyeye gönderildi!",
        Duration = 4
    })
end

function autoStoreFruit()
    local Backpack = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer.Backpack
    local inv = {}
    for _,v in pairs(Backpack:GetChildren()) do
        if string.find(v.Name, "Fruit") then
            table.insert(inv,v)
        end
    end
    for _,fruit in ipairs(inv) do
        pcall(function()
            ReplicatedStorage.Remotes:FindFirstChild("StoreFruit"):InvokeServer(fruit.Name)
        end)
    end
    game.StarterGui:SetCore("SendNotification", {
        Title = "Fruit Stored",
        Text = "Bütün meyveler depoya aktarıldı!",
        Duration = 4
    })
end

-- Hotkey ile menüyü aç/kapat
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and (input.KeyCode == Enum.KeyCode.F4 or input.KeyCode == Enum.KeyCode.RightControl) then
        if menuGui and menuGui.Parent then
            menuGui:Destroy()
            menuGui = nil
        else
            createMenu()
        end
    end
end)

createMenu() -- Script açılır açılmaz menüyü göster
