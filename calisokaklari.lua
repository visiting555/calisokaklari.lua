-- Cali Sokaklari - Gelişmiş Hile Scripti v2 (Eksiksiz ve Profesyonel, Menü Garantili)
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local mouse = Player:GetMouse()

local function roundify(gui, rad)
	local r = Instance.new("UICorner")
	r.CornerRadius = UDim.new(0, rad or 14)
	r.Parent = gui
end

local function destroyMenu()
	local gui = Player.PlayerGui:FindFirstChild("CSK_PRO_HileMenu")
	if gui then
		gui:Destroy()
	end
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
	UIS.InputChanged:Connect(function(input)
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

local function findRemote(keywords)
	local found = {}
	local function scan(obj)
		for _, v in pairs(obj:GetDescendants()) do
			for _, word in ipairs(keywords) do
				if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name:lower():find(word:lower()) then
					table.insert(found, v)
				end
			end
		end
	end
	pcall(function() scan(RS) end)
	pcall(function() scan(workspace) end)
	return found
end

local function giveMoney(amount)
	local remotes = findRemote({"money", "para", "bakiye", "add", "give"})
	for i=1, math.floor(amount/50000) do
		for _, r in ipairs(remotes) do
			pcall(function() r:FireServer(50000) end)
		end
	end
	if Player:FindFirstChild("leaderstats") then
		local cash = Player.leaderstats:FindFirstChild("Money") or Player.leaderstats:FindFirstChild("money") or Player.leaderstats:FindFirstChild("Bakiye")
		if cash then
			cash.Value = cash.Value + amount
		end
	end
end

local function giveAllGuns()
	local gunList = {"M4A1", "AK47", "DesertEagle", "Shotgun", "Tec9", "Uzi", "MP5", "Sniper", "Pistol", "Knife"}
	for _, gun in ipairs(gunList) do
		if not Player.Backpack:FindFirstChild(gun) then
			local tool = Instance.new("Tool")
			tool.Name = gun
			tool.RequiresHandle = false
			tool.Parent = Player.Backpack
		end
		for _, r in ipairs(findRemote({gun, "weapon", "give"})) do
			pcall(function() r:FireServer(gun) end)
		end
	end
end

local function giveAllItems()
	local items = {"Lockpick", "Anahtar", "Drill", "Telefon", "Canta", "Mask", "Bandaj", "Armor", "Cigarette"}
	for _, it in ipairs(items) do
		if not Player.Backpack:FindFirstChild(it) then
			local tool = Instance.new("Tool")
			tool.Name = it
			tool.RequiresHandle = false
			tool.Parent = Player.Backpack
		end
		for _, r in ipairs(findRemote({it, "item", "give"})) do
			pcall(function() r:FireServer(it) end)
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
	teleportWhere(CFrame.new(math.random(-210,210), 10, math.random(-210,210)))
end

local function teleportSecret()
	teleportWhere(CFrame.new(-103,9,143))
end

local function speedHack(mult)
	if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
		Player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 * mult
	end
end

local function jumpHack(mult)
	if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
		Player.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50 * mult
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
	local cns = getconnections or (syn and syn.getconnections)
	if cns then
		for _,v in ipairs(cns(Player.Idled)) do
			v:Disable()
		end
	else
		Player.Idled:Connect(function()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end

local function noclip(state)
	if not workspace:FindFirstChild(Player.Name.."_HileNoclip") and state then
		local con
		con = game:GetService("RunService").Stepped:Connect(function()
			if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and state then
				for _, part in ipairs(Player.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
			if not state and con then
				con:Disconnect()
			end
		end)
		con.Name = Player.Name.."_HileNoclip"
	end
end

local function flyMode(state)
	local flying = false
	local speed = 3
	local root = nil
	if state then
		local bf = Instance.new("BodyVelocity")
		bf.Name = "___flyvel"
		local cfConn
		local HB = game:GetService("RunService").Heartbeat
		function startFly()
			root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
			if root and not root:FindFirstChild("___flyvel") then
				bf.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
				bf.Velocity = Vector3.new()
				bf.Parent = root
				flying = true
				cfConn = HB:Connect(function()
					local dir = Vector3.new()
					if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + workspace.CurrentCamera.CFrame.LookVector end
					if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - workspace.CurrentCamera.CFrame.LookVector end
					if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - workspace.CurrentCamera.CFrame.RightVector end
					if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + workspace.CurrentCamera.CFrame.RightVector end
					if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + workspace.CurrentCamera.CFrame.UpVector end
					if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - workspace.CurrentCamera.CFrame.UpVector end
					bf.Velocity = dir.Unit * (dir.Magnitude > 0 and speed*22 or 0)
				end)
			end
		end
		startFly()
		local dcon = Player.CharacterAdded:Connect(function()
			wait(1)
			startFly()
		end)
		bf.AncestryChanged:Connect(function()
			if cfConn then cfConn:Disconnect() end
			dcon:Disconnect()
			flying = false
		end)
	else
		if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
			local root = Player.Character.HumanoidRootPart
			if root:FindFirstChild("___flyvel") then
				root:FindFirstChild("___flyvel"):Destroy()
			end
		end
	end
end

local function makeMenu()
	destroyMenu()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CSK_PRO_HileMenu"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Player.PlayerGui

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
	title.TextColor3 = Color3.fromRGB(255, 208, 61)
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
	roundify(closeB, 10)
	closeB.MouseButton1Click:Connect(destroyMenu)

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
		btn.MouseButton1Click:Connect(function()
			pcall(cb)
		end)
		return btn
	end

	local Y = 57
	addBtn("1.000.000 Para Ver", function()
		giveMoney(1000000)
		status.Text = "1 milyon para verildi!"
	end, Y)
	Y=Y+46
	addBtn("Tüm Silahları Al", function()
		giveAllGuns()
		status.Text = "Tüm silahlar verildi!"
	end, Y)
	Y=Y+46
	addBtn("Tüm Eşyaları Al", function()
		giveAllItems()
		status.Text = "Tüm itemler alındı."
	end, Y)
	Y=Y+46
	addBtn("God Mod (Ölümsüzlük)", function()
		setGodMode()
		status.Text = "God mode aktifleştirildi!"
	end, Y)
	Y=Y+46
	addBtn("Rastgele Teleport", function()
		teleportRandom()
		status.Text = "Rastgele yere ışınlandın!"
	end, Y)
	Y=Y+46
	addBtn("Gizli Odaya Git", function()
		teleportSecret()
		status.Text = "Gizli odaya ışınlandın!"
	end, Y)
	Y=Y+46
	addBtn("Hız Hilesi x2", function()
		speedHack(2)
		status.Text = "Hız x2 oldu!"
	end, Y)
	Y=Y+46
	addBtn("Hızı Sıfırla", function()
		speedHack(1)
		status.Text = "Yürüyüş hızı sıfırlandı."
	end, Y)
	Y=Y+46
	addBtn("Zıplama Gücünü x2 Yap", function()
		jumpHack(2)
		status.Text = "Zıplama x2 oldu!"
	end, Y)
	Y=Y+46
	addBtn("Zıplama Sıfırla", function()
		jumpHack(1)
		status.Text = "Zıplama sıfırlandı."
	end, Y)
	Y=Y+46
	addBtn("Tümünü Full Doldur", function()
		fillEverything()
		status.Text = "Tüm her şey doldu."
	end, Y)
	Y=Y+46
	addBtn("Tüm Oyuncuları Öldür", function()
		killAllPlayers()
		status.Text = "Tüm oyuncular öldürüldü!"
	end, Y)
	Y=Y+46
	addBtn("Trol Teleport (Herkes)", function()
		trollAll()
		status.Text = "Herkes rastgele yere ışınlandı!"
	end, Y)
	Y=Y+46
	addBtn("Anti-AFK", function()
		antiAfk()
		status.Text = "AFK atma açıldı!"
	end, Y)
	Y=Y+46
	addBtn("Noclip Aç/Kapat", function()
		if _G.noclipEnabled then
			_G.noclipEnabled = false
			status.Text = "Noclip kapatıldı."
		else
			_G.noclipEnabled = true
			noclip(true)
			status.Text = "Noclip aktif!"
		end
	end, Y)
	Y=Y+46
	addBtn("Fly Modu Aç/Kapat", function()
		if _G.flyEnabled then
			_G.flyEnabled = false
			flyMode(false)
			status.Text = "Fly Kapalı."
		else
			_G.flyEnabled = true
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
		if #searchBox.Text>0 then
			tpToPlayer(searchBox.Text)
			status.Text = searchBox.Text.." adlı oyuncuya gittin."
		end
	end)

	Y = Y + 47
	addBtn("Menüyü Kapat", destroyMenu, Y, Color3.fromRGB(191,48,57))
end

makeMenu()

UIS.InputBegan:Connect(function(input, processed)
	if not processed then
		if input.KeyCode == Enum.KeyCode.F4 or input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightControl then
			if Player.PlayerGui:FindFirstChild("CSK_PRO_HileMenu") then
				destroyMenu()
			else
				makeMenu()
			end
		end
	end
end)
