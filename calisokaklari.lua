local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local uniqueKey = "CaliMenu_"..tostring(math.random(1e5, 1e6-1))
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
local espObjects = {}
local espConnections = {}
local aimbotConn
local silentAimConn
local flyConn
local noclipConn
local flyBodyGyro, flyBodyVel
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
    for _,obj in ipairs(espObjects) do pcall(function() obj:Destroy() end) end
    espObjects = {}
    for _,conn in ipairs(espConnections) do pcall(function() conn:Disconnect() end) end
    espConnections = {}
end

function modernSkeletonESP(char, plr)
    local camera = Workspace.CurrentCamera
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not head or not torso then return end

    local function drawLine(obj1, obj2)
        if obj1 and obj2 then
            local b = Instance.new("Beam")
            local att1 = Instance.new("Attachment"); att1.Parent = obj1
            local att2 = Instance.new("Attachment"); att2.Parent = obj2
            b.Attachment0 = att1
            b.Attachment1 = att2
            b.Color = ColorSequence.new(Color3.new(1,1,1))
            b.Width0 = 0.16
            b.Width1 = 0.16
            b.Transparency = NumberSequence.new(0.04)
            b.Segments = 1
            b.FaceCamera = true
            b.Parent = camera
            table.insert(espObjects, att1)
            table.insert(espObjects, att2)
            table.insert(espObjects, b)
        end
    end

    local function drawBox(part)
        local box = Instance.new("BoxHandleAdornment")
        box.Size = part.Size + Vector3.new(0.5,0.5,0.5)
        box.Adornee = part
        box.Color3 = Color3.new(1,1,1)
        box.AlwaysOnTop = true
        box.ZIndex = 10
        box.Transparency = 0.12
        box.Parent = camera
        table.insert(espObjects, box)
    end

    drawBox(torso)
    local headBall = Instance.new("SphereHandleAdornment")
    headBall.Radius = head.Size.X/2 + 0.13
    headBall.Adornee = head
    headBall.Color3 = Color3.new(1,1,1)
    headBall.AlwaysOnTop = true
    headBall.ZIndex = 11
    headBall.Transparency = 0.04
    headBall.Parent = camera
    table.insert(espObjects, headBall)

    -- Skeleton
    local function partExists(name) return char:FindFirstChild(name) end
    drawLine(head, torso)
    if partExists("LeftUpperArm") and partExists("LeftLowerArm") then
        drawLine(torso, char.LeftUpperArm)
        drawLine(char.LeftUpperArm, char.LeftLowerArm)
        if partExists("LeftHand") then drawLine(char.LeftLowerArm, char.LeftHand) end
    elseif partExists("Left Arm") then
        drawLine(torso, char["Left Arm"])
    end
    if partExists("RightUpperArm") and partExists("RightLowerArm") then
        drawLine(torso, char.RightUpperArm)
        drawLine(char.RightUpperArm, char.RightLowerArm)
        if partExists("RightHand") then drawLine(char.RightLowerArm, char.RightHand) end
    elseif partExists("Right Arm") then
        drawLine(torso, char["Right Arm"])
    end
    if partExists("LeftUpperLeg") and partExists("LeftLowerLeg") then
        drawLine(torso, char.LeftUpperLeg)
        drawLine(char.LeftUpperLeg, char.LeftLowerLeg)
        if partExists("LeftFoot") then drawLine(char.LeftLowerLeg, char.LeftFoot) end
    elseif partExists("Left Leg") then
        drawLine(torso, char["Left Leg"])
    end
    if partExists("RightUpperLeg") and partExists("RightLowerLeg") then
        drawLine(torso, char.RightUpperLeg)
        drawLine(char.RightUpperLeg, char.RightLowerLeg)
        if partExists("RightFoot") then drawLine(char.RightLowerLeg, char.RightFoot) end
    elseif partExists("Right Leg") then
        drawLine(torso, char["Right Leg"])
    end
end

function trackModernESP(plr)
    if plr == LocalPlayer then return end
    local function refreshESP(chr)
        if not chr then return end
        local h = chr:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then modernSkeletonESP(chr, plr) end
    end
    if plr.Character then refreshESP(plr.Character) end
    local c1 = plr.CharacterAdded:Connect(function(chr)
        wait(0.13)
        refreshESP(chr)
    end)
    table.insert(espConnections, c1)
end

function setESP(on)
    cheatState.ESP = on
    clearESP()
    if on then
        for _,plr in ipairs(Players:GetPlayers()) do pcall(function() trackModernESP(plr) end) end
        local conn = Players.PlayerAdded:Connect(function(p) trackModernESP(p) end)
        table.insert(espConnections, conn)
        RunService.RenderStepped:Connect(function()
            if not cheatState.ESP then return end
            clearESP()
            for _,plr in ipairs(Players:GetPlayers()) do pcall(function() if plr ~= LocalPlayer and plr.Character then modernSkeletonESP(plr.Character, plr) end end) end
        end)
    end
end

function getClosestPlayerToCursor()
    local closest, closestDist = nil, math.huge
    local cam = Workspace.CurrentCamera
    local mouse = UserInputService:GetMouseLocation()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local pos, onScreen = cam:WorldToViewportPoint(plr.Character.Head.Position)
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
                local c = getClosestPlayerToCursor()
                if c and c.Character and c.Character:FindFirstChild("Head") then
                    Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, c.Character.Head.Position)
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
            silentAimData.Target = nil
            local t = getClosestPlayerToCursor()
            if t and t.Character and t.Character:FindFirstChild("Head") then
                silentAimData.Target = t.Character.Head.Position
            end
        end)
        if identifyexecutor and (identifyexecutor() == "Krnl" or identifyexecutor():find("ScriptWare") or identifyexecutor():find("Synapse")) then
            for _,v in pairs(getgc(true)) do
                if typeof(v) == "function" and islclosure(v) and debug.getinfo(v).name:lower():find("ray") then
                    hookfunction(v, function(...)
                        if cheatState.SilentAim and silentAimData.Target then
                            local args = {...}
                            args[2] = (silentAimData.Target-Workspace.CurrentCamera.CFrame.Position).Unit
                            return v(unpack(args))
                        end
                        return v(...)
                    end)
                end
            end
        end
    end
end

function killAll()
    local remotes = {}
    for _,obj in ipairs(getgc(true)) do
        if typeof(obj) == "table" and rawget(obj,"FireServer") then
            local n = obj.Name and tostring(obj.Name):lower() or ""
            if n:find("shoot") or n:find("kill") or n:find("damage") then
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
    setStatus("Kill All uygulandı")
end

function giveAllItems()
    local count = 0
    for _,obj in ipairs(getgc(true)) do
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
    for _,obj in ipairs(getgc(true)) do
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
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,2,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,2,0) end
            flyBodyVel.Velocity = move.Unit * (move.Magnitude > 0 and 60 or 0)
            flyBodyGyro.CFrame = Workspace.CurrentCamera.CFrame
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
    for i=1,50 do
        if syn and syn.protect_gui then return CoreGui end
        local guiParent = nil
        pcall(function()
            if CoreGui then guiParent = CoreGui end
        end)
        if guiParent then return guiParent end
        wait(0.07)
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
    main.Size = UDim2.new(0, 410, 0, 530)
    main.Position = UDim2.new(0.5, -205, 0.47, -265)
    main.BackgroundColor3 = Color3.fromRGB(30,30,36)
    main.BorderSizePixel = 0
    main.Parent = menuGUI
    main.Name = "Main"
    roundify(main,16)
    main.ClipsDescendants = true
    makeDraggable(main)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,48)
    title.BackgroundTransparency = 1
    title.Text = "CALI SHOOTOUT MODERN MENÜ"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 27
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Parent = main

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.AnchorPoint = Vector2.new(0,1)
    status.Position = UDim2.new(0,0,1,0)
    status.Size = UDim2.new(1,0,0,30)
    status.BackgroundTransparency = 1
    status.Text = "Hazır"
    status.Font = Enum.Font.Gotham
    status.TextSize = 16
    status.TextColor3 = Color3.fromRGB(185,221,241)
    status.Parent = main

    local Y=55
    local function addBtn(text,callback)
        local btn = Instance.new("TextButton")
        btn.Parent = main
        btn.Size = UDim2.new(0.9,0,0,38)
        btn.Position = UDim2.new(0.05,0,0,Y)
        btn.BackgroundColor3 = Color3.fromRGB(44,44,54)
        btn.TextColor3 = Color3.fromRGB(244,244,244)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 20
        btn.Text = text
        btn.AutoButtonColor = true
        roundify(btn,13)
        btn.MouseButton1Click:Connect(callback)
        Y = Y + 43
    end

    addBtn("ESP (Modern, Beyaz, Kutu & İskelet) Aç/Kapat", function()
        setESP(not cheatState.ESP)
        setStatus("ESP " .. (cheatState.ESP and "Açık!" or "Kapalı!"))
    end)
    addBtn("Aimbot Aç/Kapat", function()
        setAimbot(not cheatState.Aimbot)
        setStatus("Aimbot " .. (cheatState.Aimbot and "Açık!" or "Kapalı!"))
    end)
    addBtn("SilentAim Aç/Kapat", function()
        setSilentAim(not cheatState.SilentAim)
        setStatus("SilentAim " .. (cheatState.SilentAim and "Açık!" or "Kapalı!"))
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
    addBtn("Fly (Uçuş) Aç/Kapat", function()
        setFly(not cheatState.Fly)
        setStatus("Fly " .. (cheatState.Fly and "Açık!" or "Kapalı!"))
    end)
    addBtn("Noclip Aç/Kapat", function()
        setNoclip(not cheatState.Noclip)
        setStatus("Noclip " .. (cheatState.Noclip and "Açık!" or "Kapalı!"))
    end)
end

local function allowFirstMenu()
    for _=1,10 do
        makeMenu()
        wait(0.11)
        if menuGUI and menuGUI.Parent then break end
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.F4) then
        if open then destroyMenu() else makeMenu() end
    end
end)

allowFirstMenu()
