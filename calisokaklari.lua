local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = (game:GetService("StarterGui"):SetCore("TopbarEnabled", true) and game:GetService("Players").LocalPlayer.PlayerGui) or game:GetService("CoreGui")

local menuKey = Enum.KeyCode.RightControl
local menuOpen = false
local menuUI = nil

local uniqueKey = "CaliMenu_"..tostring(math.random(100000, 999999))
local cheats = {
    ESP = false,
    Aimbot = false
}

local espConnections = {}
local espHandles = {}

function clearESP()
    for _,v in ipairs(espHandles) do
        if v and v.Parent then v:Destroy() end
    end
    table.clear(espHandles)
    for _,v in pairs(espConnections) do
        if v then v:Disconnect() end
    end
    table.clear(espConnections)
end

function espPlayer(plr)
    if plr == LocalPlayer then return end
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(3,6,1.5)
    box.Color3 = Color3.new(1,0,0)
    box.AlwaysOnTop = true
    box.Transparency = 0.5
    box.Adornee = plr.Character.HumanoidRootPart
    box.ZIndex = 10
    box.Parent = CoreGui
    table.insert(espHandles, box)
    local function charConn()
        if box.Parent then box:Destroy() end
    end
    local c1 = plr.CharacterRemoving:Connect(charConn)
    local c2 = plr.CharacterAdded:Connect(function()
        wait(0.5)
        espPlayer(plr)
    end)
    table.insert(espConnections, c1)
    table.insert(espConnections, c2)
end

function setESP(state)
    cheats.ESP = state
    clearESP()
    if state then
        for _,plr in pairs(Players:GetPlayers()) do
            espPlayer(plr)
        end
        local conn = Players.PlayerAdded:Connect(function(plr)
            espPlayer(plr)
        end)
        table.insert(espConnections, conn)
    end
end

function setStatus(text)
    if menuUI and menuUI:FindFirstChild("Status") then
        menuUI.Status.Text = text
    end
end

function setAimbot(state)
    cheats.Aimbot = state
end

function getClosestTarget()
    local cam = Workspace.CurrentCamera
    local minDist = math.huge
    local closest = nil
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local pos, vis = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if vis then
                local mouse = UserInputService:GetMouseLocation()
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

local aimbotConn
function toggleAimbot(state)
    setAimbot(state)
    if aimbotConn then aimbotConn:Disconnect() end
    if state then
        aimbotConn = RunService.RenderStepped:Connect(function()
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local target = getClosestTarget()
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    local cam = Workspace.CurrentCamera
                    cam.CFrame = CFrame.new(cam.CFrame.Position, target.Character.HumanoidRootPart.Position)
                end
            end
        end)
    end
end

function killAll()
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local remotes = {}
            for _,v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("damage") or v.Name:lower():find("shoot")) then
                    table.insert(remotes, v)
                end
            end
            for _,remote in ipairs(remotes) do
                for i=1,7 do
                    pcall(function()
                        remote:FireServer(plr.Character.HumanoidRootPart.Position, plr)
                    end)
                end
            end
        end
    end
    setStatus("Kill All tamamlandı!")
end

function giveAllItems()
    local count = 0
    local itemRemotes = {}
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (obj.Name:lower():find("item") or obj.Name:lower():find("give")) then
            table.insert(itemRemotes, obj)
        end
    end
    for _,remote in ipairs(itemRemotes) do
        pcall(function()
            remote:FireServer("GiveAll")
            count = count + 1
        end)
    end
    setStatus(count > 0 and "Tüm eşyalar verildi!" or "Hiç eşya verilemedi!")
    return count
end

function giveMoney(amount)
    local success = false
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (obj.Name:lower():find("money") or obj.Name:lower():find("cash")) then
            pcall(function()
                obj:FireServer(amount)
                success = true
            end)
        end
    end
    setStatus(success and ("Para verildi: " .. tostring(amount)) or "Para verilemedi!")
    return success
end

function destroyMenu()
    if menuUI then
        menuUI:Destroy()
    end
    menuUI = nil
    menuOpen = false
    setESP(false)
    toggleAimbot(false)
end

function roundify(obj, rad)
    local cor = Instance.new("UICorner")
    cor.CornerRadius = UDim.new(0, rad or 8)
    cor.Parent = obj
end

function makeDraggable(gui)
    local UserInputService = game:GetService("UserInputService")
    local dragging, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function makeMenu()
    destroyMenu()
    menuOpen = true
    menuUI = Instance.new("ScreenGui")
    menuUI.Name = uniqueKey
    menuUI.Parent = CoreGui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 370, 0, 370)
    main.Position = UDim2.new(0.48, 0, 0.38, 0)
    main.BackgroundColor3 = Color3.fromRGB(33,35,40)
    main.BorderSizePixel = 0
    main.Parent = menuUI
    roundify(main,12)
    main.ClipsDescendants = true
    makeDraggable(main)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,40)
    title.BackgroundTransparency = 1
    title.Text = "CALI SHOOTOUT MENÜ"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.TextColor3 = Color3.fromRGB(240,220,80)
    title.Parent = main

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

    addBtn("ESP Aç/Kapat", function()
        setESP(not cheats.ESP)
        setStatus(cheats.ESP and "ESP Açıldı!" or "ESP Kapatıldı!")
    end)

    addBtn("Aimbot Aç/Kapat", function()
        toggleAimbot(not cheats.Aimbot)
        setStatus(cheats.Aimbot and "Aimbot Açık!" or "Aimbot Kapalı!")
    end)

    addBtn("Kill All", function()
        setStatus("Kill All uygulanıyor...")
        killAll()
    end)

    addBtn("Tüm Gerçek Eşyaları AL", function()
        giveAllItems()
    end)

    addBtn("1.000.000 Para Ver", function()
        giveMoney(1000000)
    end)
end

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
