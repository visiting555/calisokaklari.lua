local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local uniqueKey = "CaliMenu_"..tostring(math.random(100000, 999999))
local cheats = {ESP=false,Aimbot=false}
local menuUI = nil
local open = false
local espHandles = {}
local espConnections = {}

function destroyMenu()
    if menuUI then
        pcall(function() menuUI:Destroy() end)
    end
    menuUI = nil
    open = false
    setESP(false)
    setAimbot(false)
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
        if v and v.Parent then pcall(function() v:Destroy() end) end
    end
    espHandles = {}
    for _,v in ipairs(espConnections) do
        pcall(function() if v then v:Disconnect() end end)
    end
    espConnections = {}
end

function espPlayer(plr)
    if plr == LocalPlayer then return end
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(3,6,1.5)
    box.Color3 = Color3.fromRGB(255,0,0)
    box.Adornee = plr.Character.HumanoidRootPart
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Transparency = 0.5
    box.Parent = Workspace.CurrentCamera
    table.insert(espHandles, box)
    local c1 = plr.CharacterRemoving:Connect(function()
        if box.Parent then pcall(function() box:Destroy() end) end
    end)
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
                local closest=nil
                local cam = Workspace.CurrentCamera
                local shortest=math.huge
                for _,plr in ipairs(Players:GetPlayers()) do
                    if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health>0 then
                        local pos,vis = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                        if vis then
                            local mouse = UserInputService:GetMouseLocation()
                            local dist = (Vector2.new(pos.X,pos.Y)-Vector2.new(mouse.X,mouse.Y)).Magnitude
                            if dist<shortest then
                                shortest=dist
                                closest=plr
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
                for i=1,7 do
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
    main.Size = UDim2.new(0, 360, 0, 340)
    main.Position = UDim2.new(0.5, -180, 0.43, -170)
    main.BackgroundColor3 = Color3.fromRGB(32,33,38)
    main.BorderSizePixel = 0
    main.Parent = menuUI
    roundify(main,12)
    main.ClipsDescendants = true
    makeDraggable(main)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,42)
    title.BackgroundTransparency = 1
    title.Text = "CALI SHOOTOUT MENÜ"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 23
    title.TextColor3 = Color3.fromRGB(255,235,80)
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
        btn.BackgroundColor3 = Color3.fromRGB(42,48,57)
        btn.TextColor3 = Color3.fromRGB(225,234,255)
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
        setAimbot(not cheats.Aimbot)
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

local function allowFirstMenu()
    for i=1,10 do
        makeMenu()
        wait(0.13)
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
