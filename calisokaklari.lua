local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera

local uniqueKey = "CaliMenu_"..math.floor(tick()*100000)
local cheatState = {
    ESP = false,
    Aimbot = false,
    SilentAim = false,
    KillAll = false,
    GiveItems = false,
    GiveMoney = false,
    Fly = false,
    Noclip = false
}
local menuGUI = nil
local open = false
local espDrawings = {}
local espTrackingConnections = {}
local aimbotConn
local silentAimConn
local flyConn
local noclipConn
local flyBodyGyro
local flyBodyVel
local flying = false

function destroyMenu()
    if menuGUI then pcall(function() menuGUI:Destroy() end) end
    menuGUI = nil
    open = false
    setESP(false)
    setAimbot(false)
    setSilentAim(false)
    setFly(false)
    setNoclip(false)
end

function roundify(obj, rad)
    local cor = Instance.new("UICorner")
    cor.CornerRadius = UDim.new(0, rad or 8)
    cor.Parent = obj
end

function makeDraggable(gui)
    local dragToggle, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragToggle = false end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if dragToggle and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
        end
    end)
end

function setStatus(text)
    if menuGUI and menuGUI:FindFirstChild("Status") then
        menuGUI.Status.Text = text
    end
end

function clearESP()
    for _,obj in ipairs(espDrawings) do pcall(function() obj:Remove(); obj = nil end) end
    espDrawings = {}
    for _,conn in ipairs(espTrackingConnections) do pcall(function() conn:Disconnect() end) end
    espTrackingConnections = {}
end

function worldToScreen(pos)
    local s,c = Camera:WorldToViewportPoint(pos)
    return Vector2.new(s.X, s.Y), c
end

function drawLine(from, to, thickness)
    local line = Drawing.new("Line")
    line.Visible = true
    line.From = from
    line.To = to
    line.Color = Color3.new(1,1,1)
    line.Thickness = thickness or 2
    line.Transparency = 1
    line.ZIndex = 2
    table.insert(espDrawings, line)
    return line
end

function drawBox(points)
    for i = 1, 4 do
        drawLine(points[i], points[i%4+1], 2)
    end
end

function skeletonESP(char)
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not head or not root then return end

    local parts = {
        head = head,
        root = root,
        luarm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"),
        ruarm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"),
        lhand = char:FindFirstChild("LeftHand"),
        rhand = char:FindFirstChild("RightHand"),
        llu = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"),
        rlu = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg"),
        lfoot = char:FindFirstChild("LeftFoot"),
        rfoot = char:FindFirstChild("RightFoot"),
        lla = char:FindFirstChild("LeftLowerArm"),
        rla = char:FindFirstChild("RightLowerArm"),
        lll = char:FindFirstChild("LeftLowerLeg"),
        rll = char:FindFirstChild("RightLowerLeg")
    }

    local screens = {}
    for k,v in pairs(parts) do if v then
        local vec,onscreen = worldToScreen(v.Position)
        if not onscreen then return end
        screens[k] = vec
    end end

    -- Box
    local pMin = Vector2.new(1e5,1e5)
    local pMax = Vector2.new(-1e5,-1e5)
    for k,v in pairs(screens) do
        if v.X < pMin.X then pMin = Vector2.new(v.X, pMin.Y) end
        if v.Y < pMin.Y then pMin = Vector2.new(pMin.X, v.Y) end
        if v.X > pMax.X then pMax = Vector2.new(v.X, pMax.Y) end
        if v.Y > pMax.Y then pMax = Vector2.new(pMax.X, v.Y) end
    end
    local boxPoints = {pMin, Vector2.new(pMax.X,pMin.Y), pMax, Vector2.new(pMin.X,pMax.Y)}
    drawBox(boxPoints)

    -- Skeleton lines (kafa - vücut, vücut - kollar, bacaklar)
    if screens.head and screens.root then drawLine(screens.head, screens.root, 2) end
    if screens.root and screens.luarm then drawLine(screens.root, screens.luarm, 2) end
    if screens.luarm and screens.lla then drawLine(screens.luarm, screens.lla, 2) end
    if screens.lla and screens.lhand then drawLine(screens.lla, screens.lhand, 2) end
    if screens.root and screens.ruarm then drawLine(screens.root, screens.ruarm, 2) end
    if screens.ruarm and screens.rla then drawLine(screens.ruarm, screens.rla, 2) end
    if screens.rla and screens.rhand then drawLine(screens.rla, screens.rhand, 2) end
    if screens.root and screens.llu then drawLine(screens.root, screens.llu, 2) end
    if screens.llu and screens.lll then drawLine(screens.llu, screens.lll, 2) end
    if screens.lll and screens.lfoot then drawLine(screens.lll, screens.lfoot, 2) end
    if screens.root and screens.rlu then drawLine(screens.root, screens.rlu, 2) end
    if screens.rlu and screens.rll then drawLine(screens.rlu, screens.rll, 2) end
    if screens.rll and screens.rfoot then drawLine(screens.rll, screens.rfoot, 2) end
    if screens.luarm and screens.ruarm then drawLine(screens.luarm, screens.ruarm, 2) end
    if screens.llu and screens.rlu then drawLine(screens.llu, screens.rlu, 2) end

    local headPos = head.Position
    local headScreen, hOn = worldToScreen(headPos)
    local r = 20
    local headCircle = Drawing.new("Circle")
    headCircle.Visible = true
    headCircle.Radius = r
    headCircle.Thickness = 2
    headCircle.Position = headScreen
    headCircle.Color = Color3.new(1,1,1)
    headCircle.Transparency = 1
    table.insert(espDrawings, headCircle)
end

function setESP(on)
    cheatState.ESP = on
    clearESP()
    if on then
        local function drawAll()
            clearESP()
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                    skeletonESP(plr.Character)
                end
            end
        end
        local conn1 = RunService.RenderStepped:Connect(drawAll)
        table.insert(espTrackingConnections, conn1)
        for _,plr in ipairs(Players:GetPlayers()) do
            local c = plr.CharacterAdded:Connect(drawAll)
            table.insert(espTrackingConnections, c)
        end
        local c2 = Players.PlayerAdded:Connect(function(plr)
            local cc = plr.CharacterAdded:Connect(drawAll)
            table.insert(espTrackingConnections, cc)
        end)
        table.insert(espTrackingConnections, c2)
        drawAll()
    end
end

function getClosestPlayerToCursor()
    local closest, closestDist = nil, math.huge
    local mouse = UserInputService:GetMouseLocation()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

function setAimbot(on)
    cheatState.Aimbot = on
    if aimbotConn then pcall(function() aimbotConn:Disconnect() end) end
    if on then
        aimbotConn = RunService.RenderStepped:Connect(function()
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local target = getClosestPlayerToCursor()
                if target and target.Character and target.Character:FindFirstChild("Head") then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
                end
            end
        end)
    end
end

local silentAimData = {Target=nil}
function setSilentAim(on)
    cheatState.SilentAim = on
    if silentAimConn then pcall(function() silentAimConn:Disconnect() end) end
    silentAimData.Target = nil
    if on then
        silentAimConn = RunService.Heartbeat:Connect(function()
            local t = getClosestPlayerToCursor()
            if t and t.Character and t.Character:FindFirstChild("Head") then
                silentAimData.Target = t.Character.Head.Position
            else
                silentAimData.Target = nil
            end
        end)
        for _,v in pairs(getgc and getgc(true) or {}) do
            if typeof(v) == "function" and islclosure and islclosure(v) and debug.getinfo(v).name:lower():find("ray") then
                pcall(function()
                    hookfunction(v, function(...)
                        if cheatState.SilentAim and silentAimData.Target then
                            local args = {...}
                            args[2] = (silentAimData.Target-Camera.CFrame.Position).Unit
                            return v(unpack(args))
                        end
                        return v(...)
                    end)
                end)
            end
        end
    end
end

function killAll()
    local remotes = {}
    for _,obj in ipairs(getgc and getgc(true) or {}) do
        if typeof(obj) == "table" and rawget(obj,"FireServer") then
            local n = obj.Name and tostring(obj.Name):lower() or ""
            if n:find("shoot") or n:find("kill") or n:find("damage") or n:find("hit") then
                table.insert(remotes,obj)
            end
        end
    end
    for _,target in ipairs(Players:GetPlayers()) do
        if target~=LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local pos = target.Character.HumanoidRootPart.Position
            for _,r in ipairs(remotes) do
                for i=1,5 do
                    pcall(function() r:FireServer(pos, target) end)
                end
            end
        end
    end
    setStatus("Kill All çalıştı")
end

function giveAllItems()
    local count = 0
    for _,obj in ipairs(getgc and getgc(true) or {}) do
        if typeof(obj) == "table" and rawget(obj,"FireServer") then
            local n = obj.Name and tostring(obj.Name):lower() or ""
            if n:find("item") or n:find("give") or n:find("reward") then
                pcall(function()
                    obj:FireServer("GiveAll")
                    count = count + 1
                end)
            end
        end
    end
    setStatus(count>0 and "Tüm itemler verildi!" or "Item verilemedi!")
    return count
end

function giveMoney(amount)
    local ok = false
    for _,obj in ipairs(getgc and getgc(true) or {}) do
        if typeof(obj) == "table" and rawget(obj,"FireServer") then
            local n = obj.Name and tostring(obj.Name):lower() or ""
            if n:find("money") or n:find("cash") or n:find("para") then
                pcall(function()
                    obj:FireServer(amount)
                    ok = true
                end)
            end
        end
    end
    setStatus(ok and ("Para verildi: "..amount) or "Para verilemedi!")
    return ok
end

function setFly(state)
    cheatState.Fly = state
    if flyConn then pcall(function() flyConn:Disconnect() end) flyConn = nil end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    if state then
        flying = true
        if not flyBodyGyro then
            flyBodyGyro = Instance.new("BodyGyro", hrp)
            flyBodyGyro.P = 9e4
            flyBodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
            flyBodyGyro.CFrame = hrp.CFrame
        end
        if not flyBodyVel then
            flyBodyVel = Instance.new("BodyVelocity", hrp)
            flyBodyVel.MaxForce = Vector3.new(9e9,9e9,9e9)
        end
        flyConn = RunService.RenderStepped:Connect(function()
            if not flying or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                setFly(false)
                return
            end
            local move = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,2,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,2,0) end
            flyBodyVel.Velocity = move.Unit * (move.Magnitude > 0 and 60 or 0)
            flyBodyGyro.CFrame = Camera.CFrame
        end)
    else
        flying = false
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
    end
end

function setNoclip(on)
    cheatState.Noclip = on
    if noclipConn then pcall(function() noclipConn:Disconnect() end) end
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _,v in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
    end
end

function waitForGuiParent()
    for i=1,60 do
        if syn and syn.protect_gui then return CoreGui end
        local guiParent = nil
        pcall(function()
            if CoreGui then guiParent = CoreGui end
        end)
        if guiParent then return guiParent end
        wait(0.05)
    end
    return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end

function makeMenu()
    destroyMenu()
    open = true
    menuGUI = Instance.new("ScreenGui")
    menuGUI.Name = uniqueKey
    menuGUI.ResetOnSpawn = false
    local success = false
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(menuGUI)
            menuGUI.Parent = CoreGui
            success = true
        end
    end)
    if not success then
        local ok = false
        pcall(function()
            menuGUI.Parent = CoreGui
            ok = menuGUI.Parent == CoreGui
        end)
        if not ok then
            menuGUI.Parent = waitForGuiParent()
        end
    end

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 420, 0, 530)
    main.Position = UDim2.new(0.5, -210, 0.48, -265)
    main.BackgroundColor3 = Color3.fromRGB(35,36,44)
    main.BorderSizePixel = 0
    main.Parent = menuGUI
    main.Name = "Main"
    roundify(main,16)
    main.ClipsDescendants = true
    makeDraggable(main)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,48)
    title.BackgroundTransparency = 1
    title.Text = "CALI SHOOTOUT FULL PRO MENU"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 27
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Parent = main

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.AnchorPoint = Vector2.new(0,1)
    status.Position = UDim2.new(0,0,1,0)
    status.Size = UDim2.new(1,0,0,32)
    status.BackgroundTransparency = 1
    status.Text = "Hazır"
    status.Font = Enum.Font.Gotham
    status.TextSize = 17
    status.TextColor3 = Color3.fromRGB(181,221,251)
    status.Parent = main

    local Y=60
    local function addBtn(text,callback)
        local btn = Instance.new("TextButton")
        btn.Parent = main
        btn.Size = UDim2.new(0.91,0,0,38)
        btn.Position = UDim2.new(0.045,0,0,Y)
        btn.BackgroundColor3 = Color3.fromRGB(41,48,63)
        btn.TextColor3 = Color3.fromRGB(244,244,244)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 20
        btn.Text = text
        btn.AutoButtonColor = true
        roundify(btn,12)
        btn.MouseButton1Click:Connect(callback)
        Y = Y + 42
    end

    addBtn("ESP (Yeni Modern Beyaz) Aç/Kapat", function()
        setESP(not cheatState.ESP)
        setStatus("ESP " .. (cheatState.ESP and "Açık!" or "Kapalı!"))
    end)
    addBtn("Aimbot Aç/Kapat", function()
        setAimbot(not cheatState.Aimbot)
        setStatus("Aimbot " .. (cheatState.Aimbot and "Açık!" or "Kapalı!"))
    end)
    addBtn("Silent Aim Aç/Kapat", function()
        setSilentAim(not cheatState.SilentAim)
        setStatus("Silent Aim " .. (cheatState.SilentAim and "Açık!" or "Kapalı!"))
    end)
    addBtn("Fly (Uçuş) Aç/Kapat", function()
        setFly(not cheatState.Fly)
        setStatus("Fly " .. (cheatState.Fly and "Açık!" or "Kapalı!"))
    end)
    addBtn("Noclip Aç/Kapat", function()
        setNoclip(not cheatState.Noclip)
        setStatus("Noclip " .. (cheatState.Noclip and "Açık!" or "Kapalı!"))
    end)
    addBtn("Kill All", function()
        setStatus("Kill All aktif...")
        killAll()
    end)
    addBtn("Tüm Eşyaları AL", function()
        giveAllItems()
    end)
    addBtn("1.000.000 Para Ver", function()
        giveMoney(1000000)
    end)
end

local function allowFirstMenu()
    for _=1,12 do
        makeMenu()
        wait(0.09)
        if menuGUI and menuGUI.Parent then break end
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.F4) then
        if open then destroyMenu() else makeMenu() end
    end
end)

allowFirstMenu()
