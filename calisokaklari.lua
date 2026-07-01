local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local uniqueKey = "CaliMenu_"..tostring(math.random(1e5, 1e6-1))
local cheats = {ESP=false, Aimbot=false, SilentAim=false, KillAll=false, GiveItems=false, GiveMoney=false, Fly=false, Noclip=false}
local menuUI = nil
local open = false
local espHandles = {}
local espConnections = {}

local flyConn, noclipConn
local flyOn = false
local noclipOn = false
local flySpeed = 3

function destroyMenu()
    if menuUI then
        pcall(function() menuUI:Destroy() end)
    end
    menuUI = nil
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
    local dragging,dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            dragStart=input.Position
            startPos=gui.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then
                    dragging=false
                end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            local delta=input.Position-dragStart
            gui.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
        end
    end)
end

function setStatus(text)
    if menuUI and menuUI:FindFirstChild("Status") then
        menuUI.Status.Text = text
    end
end

function clearESP()
    for _,v in ipairs(espHandles) do
        pcall(function() if v and v.Parent then v:Destroy() end end)
    end
    espHandles = {}
    for _,v in ipairs(espConnections) do
        pcall(function() if v then v:Disconnect() end end)
    end
    espConnections = {}
end

function modernESPCharacter(char, plr)
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChildOfClass("Humanoid") then return end
    local root = char.HumanoidRootPart

    -- Main box
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(3.5, 6.1, 2.2)
    box.Adornee = root
    box.ZIndex = 10
    box.AlwaysOnTop = true
    box.Transparency = 0
    box.Color3 = Color3.fromRGB(255,255,255)
    box.Parent = Workspace.CurrentCamera
    table.insert(espHandles, box)

    -- Head
    local head = char:FindFirstChild("Head")
    if head then
        local headEsp = Instance.new("SphereHandleAdornment")
        headEsp.Radius = 0.65
        headEsp.Adornee = head
        headEsp.Color3 = Color3.fromRGB(255,255,255)
        headEsp.Transparency = 0
        headEsp.AlwaysOnTop = true
        headEsp.ZIndex = 10
        headEsp.Parent = Workspace.CurrentCamera
        table.insert(espHandles, headEsp)
    end
    -- Body skeleton lines (head->torso, L/R arms, L/R legs)
    local function makeLine(part0, part1)
        if part0 and part1 then
            local beam = Instance.new("Attachment",part0)
            local beam2 = Instance.new("Attachment",part1)
            local line = Instance.new("Beam")
            line.Attachment0 = beam
            line.Attachment1 = beam2
            line.Width0 = 0.17
            line.Width1 = 0.17
            line.Color = ColorSequence.new(Color3.fromRGB(255,255,255))
            line.FaceCamera = true
            line.Parent = Workspace.CurrentCamera
            table.insert(espHandles, beam)
            table.insert(espHandles, beam2)
            table.insert(espHandles, line)
        end
    end

    if char:FindFirstChild("Head") and char:FindFirstChild("UpperTorso") then
        makeLine(char.Head, char.UpperTorso)
    elseif char:FindFirstChild("Head") and char:FindFirstChild("Torso") then
        makeLine(char.Head, char.Torso)
    end
    local upper = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if upper then
        makeLine(upper, char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"))
        makeLine(upper, char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"))
        makeLine(upper, char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"))
        makeLine(upper, char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg"))
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local c = char.ChildAdded:Connect(function(obj)
            RunService.RenderStepped:Wait()
            pcall(function() modernESPCharacter(char, plr) end)
        end)
        table.insert(espConnections, c)
    end
end

function espPlayer(plr)
    if plr == LocalPlayer then return end
    local function hookChar(char)
        modernESPCharacter(char,plr)
    end
    if plr.Character then
        pcall(function() hookChar(plr.Character) end)
    end
    local c1 = plr.CharacterAdded:Connect(function(char)
        wait(0.27)
        pcall(function() hookChar(char) end)
    end)
    table.insert(espConnections, c1)
end

function setESP(state)
    cheats.ESP = state
    clearESP()
    if state then
        for _,plr in ipairs(Players:GetPlayers()) do pcall(function() espPlayer(plr) end) end
        local conn = Players.PlayerAdded:Connect(function(plr) pcall(function() espPlayer(plr) end) end)
        table.insert(espConnections, conn)
    end
end

local aimbotConn
function setAimbot(state)
    cheats.Aimbot = state
    if aimbotConn then pcall(function() aimbotConn:Disconnect() end) end
    if state then
        aimbotConn = RunService.RenderStepped:Connect(function()
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local closest, shortest = nil, math.huge
                local cam = Workspace.CurrentCamera
                for _,plr in ipairs(Players:GetPlayers()) do
                    if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health>0 then
                        local pos,vis = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                        if vis then
                            local mouse = UserInputService:GetMouseLocation()
                            local dist = (Vector2.new(pos.X,pos.Y)-Vector2.new(mouse.X,mouse.Y)).Magnitude
                            if dist<shortest then
                                shortest=dist; closest=plr
                            end
                        end
                    end
                end
                if closest and closest.Character and closest.Character:FindFirstChild("HumanoidRootPart") then
                    cam.CFrame = CFrame.new(cam.CFrame.Position,closest.Character.HumanoidRootPart.Position)
                end
            end
        end)
    end
end

local silentAimData = {Target=nil}
local silentAimConn
function setSilentAim(state)
    cheats.SilentAim = state
    if silentAimConn then pcall(function() silentAimConn:Disconnect() end) end
    silentAimData.Target = nil
    if state then
        silentAimConn = RunService.Heartbeat:Connect(function()
            local closest, shortest = nil, math.huge
            local cam = Workspace.CurrentCamera
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health>0 then
                    local pos,vis = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                    if vis then
                        local mouse = UserInputService:GetMouseLocation()
                        local dist = (Vector2.new(pos.X,pos.Y)-Vector2.new(mouse.X,mouse.Y)).Magnitude
                        if dist<shortest then
                            shortest=dist; closest=plr
                        end
                    end
                end
            end
            silentAimData.Target = (closest and closest.Character and closest.Character:FindFirstChild("Head")) and closest.Character.Head or nil
        end)
        -- Hooker
        for _,mt in ipairs(getgc(true)) do
            if typeof(mt)=="table" then
                for k,v in pairs(mt) do
                    if tostring(k):lower():find("raycast") and type(v)=="function" then
                        hookfunction(v, function(...)
                            if cheats.SilentAim and silentAimData.Target then
                                local args = {...}
                                args[2] = (silentAimData.Target.Position - Workspace.CurrentCamera.CFrame.Position).Unit
                                return v(unpack(args))
                            end
                            return v(...)
                        end)
                    end
                end
            end
        end
    end
end

function killAll()
    local remotes = {}
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name:lower():find("damage") or v.Name:lower():find("shoot") or v.Name:lower():find("kill")) then
            table.insert(remotes,v)
        end
    end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            for _,remote in ipairs(remotes) do
                for i=1,10 do
                    pcall(function() remote:FireServer(plr.Character.HumanoidRootPart.Position,plr) end)
                end
            end
        end
    end
    setStatus("Kill All tamamlandı!")
end

function giveAllItems()
    local added=0
    local remotes = {}
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (obj.Name:lower():find("item") or obj.Name:lower():find("give") or obj.Name:lower():find("reward")) then
            table.insert(remotes,obj)
        end
    end
    for _,remote in ipairs(remotes) do
        pcall(function()
            remote:FireServer("GiveAll")
            added=added+1
        end)
    end
    setStatus(added>0 and "Tüm eşyalar verildi!" or "Hiç eşya verilemedi!")
    return added
end

function giveMoney(amount)
    local succ=false
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (obj.Name:lower():find("money") or obj.Name:lower():find("cash") or obj.Name:lower():find("bank")) then
            pcall(function()
                obj:FireServer(amount)
                succ=true
            end)
        end
    end
    setStatus(succ and ("Para verildi: "..amount) or "Para verilemedi!")
    return succ
end

local flying = false
local flyMove, flyGyro
function setFly(state)
    cheats.Fly = state
    if flyConn then pcall(function() flyConn:Disconnect() end) end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = LocalPlayer.Character.HumanoidRootPart
    if state then
        flying = true
        if not flyGyro then
            flyGyro = Instance.new("BodyGyro")
            flyGyro.P = 9e4
            flyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
            flyGyro.CFrame = root.CFrame
            flyGyro.Parent = root
        end
        if not flyMove then
            flyMove = Instance.new("BodyVelocity")
            flyMove.Velocity = Vector3.new()
            flyMove.MaxForce = Vector3.new(9e9,9e9,9e9)
            flyMove.Parent = root
        end
        flyConn = RunService.RenderStepped:Connect(function()
            if not flying or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
            local move = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
            flyMove.Velocity = move.Unit * (move.Magnitude>0 and flySpeed*20 or 0)
            flyGyro.CFrame = Workspace.CurrentCamera.CFrame
        end)
    else
        flying = false
        if flyGyro then pcall(function() flyGyro:Destroy() end) flyGyro=nil end
        if flyMove then pcall(function() flyMove:Destroy() end) flyMove=nil end
    end
end

function setNoclip(state)
    cheats.Noclip = state
    if noclipConn then pcall(function() noclipConn:Disconnect() end) end
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _,v in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        end)
    end
end

function waitForGuiParent()
    for i=1,100 do
        if syn and syn.protect_gui then break end
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
    menuUI = Instance.new("ScreenGui")
    menuUI.Name = uniqueKey
    menuUI.ResetOnSpawn=false

    local success = false
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(menuUI)
            menuUI.Parent = CoreGui
            success = true
        end
    end)
    if not success then
        local passed = false
        pcall(function()
            menuUI.Parent = CoreGui
            passed = (menuUI.Parent == CoreGui)
        end)
        if not passed then
            menuUI.Parent = waitForGuiParent()
        end
    end

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 390, 0, 475)
    main.Position = UDim2.new(0.5, -195, 0.47, -225)
    main.BackgroundColor3 = Color3.fromRGB(32,33,38)
    main.BorderSizePixel = 0
    main.Parent = menuUI
    roundify(main,14)
    main.ClipsDescendants = true
    makeDraggable(main)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,44)
    title.BackgroundTransparency = 1
    title.Text = "CALI SHOOTOUT BYPASS MENÜ"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Parent = main

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1,0,0,27)
    status.Position = UDim2.new(0,0,1,-27)
    status.BackgroundTransparency = 1
    status.Text = "Hazır"
    status.Font = Enum.Font.Gotham
    status.TextSize = 16
    status.TextColor3 = Color3.fromRGB(171,224,242)
    status.Parent = main

    local Y=50
    local function addBtn(text,callback)
        local btn = Instance.new("TextButton")
        btn.Parent = main
        btn.Size = UDim2.new(0.92,0,0,36)
        btn.Position = UDim2.new(0.04,0,0,Y)
        btn.BackgroundColor3 = Color3.fromRGB(44,44,44)
        btn.TextColor3 = Color3.fromRGB(232,232,232)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 19
        btn.Text = text
        btn.AutoButtonColor = true
        roundify(btn,12)
        btn.MouseButton1Click:Connect(callback)
        Y = Y + 45
        return btn
    end

    addBtn("ESP Aç/Kapat (Modern)", function()
        setESP(not cheats.ESP)
        setStatus(cheats.ESP and "ESP Açıldı!" or "ESP Kapatıldı!")
    end)
    addBtn("Aimbot Aç/Kapat", function()
        setAimbot(not cheats.Aimbot)
        setStatus(cheats.Aimbot and "Aimbot Açık!" or "Aimbot Kapalı!")
    end)
    addBtn("SilentAim Aç/Kapat", function()
        setSilentAim(not cheats.SilentAim)
        setStatus(cheats.SilentAim and "SilentAim Açık!" or "SilentAim Kapalı!")
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
    addBtn("Fly Aç/Kapat", function()
        setFly(not cheats.Fly)
        setStatus(cheats.Fly and "Fly Açık!" or "Fly Kapalı!")
    end)
    addBtn("Noclip Aç/Kapat", function()
        setNoclip(not cheats.Noclip)
        setStatus(cheats.Noclip and "Noclip Açık!" or "Noclip Kapalı!")
    end)
end

local function allowFirstMenu()
    for i=1,10 do
        makeMenu()
        wait(0.12)
        if menuUI and menuUI.Parent and menuUI.Parent:IsA("ScreenGui")==false then break end
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.F4) then
        if open then
            destroyMenu()
        else
            makeMenu()
        end
    end
end)

allowFirstMenu()
