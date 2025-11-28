--========================================================--
--===================== AIMGPT UI ========================--
--========================================================--

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 260)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

-- UI Toggle (RightControl)
local UIS = game:GetService("UserInputService")
local uiVisible = true

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		uiVisible = not uiVisible
		frame.Visible = uiVisible
	end
end)

-- Title Label
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "AimGPT"
title.TextColor3 = Color3.fromRGB(255, 0, 0)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Font = Enum.Font.Fantasy
title.Parent = frame

--========================================================--
--==================== SCROLLING BUTTON AREA =============--
--========================================================--

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 0, 180)
scroll.Position = UDim2.new(0, 0, 0, 40)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 1
scroll.Parent = frame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 8)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.Parent = scroll

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingBottom = UDim.new(0, 40)
UIPadding.PaddingTop = UDim.new(0, 10)
UIPadding.Parent = scroll

local function updateCanvas()
	scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
end
UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

--========================================================--
--===================== BUTTON UI ========================--
--========================================================--

local function createButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 50)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btn.TextColor3 = Color3.fromRGB(80, 0, 0)
	btn.TextSize = 20
	btn.Font = Enum.Font.FredokaOne
	btn.Text = text
	btn.Parent = scroll

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn

	return btn
end

local fovBtn = createButton("Toggle FOV")
local modeBtn = createButton("direct mode")
local aimLocBtn = createButton("aim: head")

-- Press Visuals
local function pressVisual(btn)
	btn.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
	btn.TextColor3 = Color3.fromRGB(120, 0, 0)
end

local function releaseVisual(btn, normalText)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btn.TextColor3 = Color3.fromRGB(80, 0, 0)
	btn.Text = normalText
end

--========================================================--
--=================== FOV TOGGLE LOGIC ===================--
--========================================================--

local RunService = game:GetService("RunService")
local cam = workspace.CurrentCamera

local DEFAULT_FOV = cam.FieldOfView
local FOVEnabled = false
local FOVLoop = nil

fovBtn.MouseButton1Down:Connect(function()
	pressVisual(fovBtn)
end)

fovBtn.MouseButton1Up:Connect(function()
	releaseVisual(fovBtn, "Toggle FOV")

	FOVEnabled = not FOVEnabled

	if FOVEnabled then
		FOVLoop = RunService.RenderStepped:Connect(function()
			cam.FieldOfView = 120
		end)
	else
		if FOVLoop then
			FOVLoop:Disconnect()
			FOVLoop = nil
		end
		cam.FieldOfView = DEFAULT_FOV
	end
end)

--========================================================--
--============== HOVER / NEAREST MODE LOGIC ==============--
--========================================================--

local modeIndex = 1
local modeList = {
	"direct mode",
	"nearest mode(cursor)",
	"nearest mode"
}

modeBtn.MouseButton1Down:Connect(function()
	pressVisual(modeBtn)
end)

modeBtn.MouseButton1Up:Connect(function()
	modeIndex += 1
	if modeIndex > #modeList then modeIndex = 1 end
	releaseVisual(modeBtn, modeList[modeIndex])
end)

--========================================================--
--============== AIM LOCATION: HEAD / CENTER =============--
--========================================================--

local aimHead = true

aimLocBtn.MouseButton1Down:Connect(function()
	pressVisual(aimLocBtn)
end)

aimLocBtn.MouseButton1Up:Connect(function()
	aimHead = not aimHead
	releaseVisual(aimLocBtn, aimHead and "aim: head" or "aim: center")
end)

--========================================================--
--==================== LOCK-ON WITH T =====================--
--========================================================--

local Mouse = player:GetMouse()
local LockEnabled = false
local LockedTarget = nil

local function getAimPosition(char)
	if aimHead and char:FindFirstChild("Head") then
		return char.Head.Position
	end
	if char:FindFirstChild("HumanoidRootPart") then
		return char.HumanoidRootPart.Position
	end
end

local function findDirectTarget()
	local target = Mouse.Target
	if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then
		return target.Parent
	end
end

local function findNearestToCursor()
	local mousePos = Mouse.Hit.Position
	local closest, dist = nil, 9999

	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Humanoid")
			and m.Parent ~= player.Character
			and m.Parent:FindFirstChild("HumanoidRootPart") then

			local hrp = m.Parent.HumanoidRootPart
			local d = (hrp.Position - mousePos).Magnitude

			if d < dist then
				dist = d
				closest = m.Parent
			end
		end
	end
	return closest
end

local function findNearestToPlayer()
	local me = player.Character
	if not me or not me:FindFirstChild("HumanoidRootPart") then return end

	local myPos = me.HumanoidRootPart.Position
	local closest, dist = nil, 9999

	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Humanoid")
			and m.Parent ~= me
			and m.Parent:FindFirstChild("HumanoidRootPart") then

			local hrp = m.Parent.HumanoidRootPart
			local d = (hrp.Position - myPos).Magnitude

			if d < dist then
				dist = d
				closest = m.Parent
			end
		end
	end
	return closest
end

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.T then
		LockedTarget = nil
		LockEnabled = not LockEnabled

		if not LockEnabled then return end

		if modeIndex == 1 then
			LockedTarget = findDirectTarget()
		elseif modeIndex == 2 then
			LockedTarget = findNearestToCursor()
		else
			LockedTarget = findNearestToPlayer()
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if LockEnabled and LockedTarget then
		local aimPos = getAimPosition(LockedTarget)
		if aimPos then
			cam.CFrame = CFrame.new(cam.CFrame.Position, aimPos)
		end
	end
end)

--========================================================--
--==================== RAINBOW VERSION ====================--
--========================================================--

local ver = Instance.new("TextLabel")
ver.Size = UDim2.new(1, 0, 0, 20)
ver.Position = UDim2.new(0, 0, 1, -20)
ver.Text = "v1.0.2"
ver.TextScaled = true
ver.BackgroundTransparency = 1
ver.Font = Enum.Font.Arcade
ver.Parent = frame

local hue = 0
RunService.RenderStepped:Connect(function()
	hue = (hue + 0.005) % 1
	ver.TextColor3 = Color3.fromHSV(hue, 1, 1)
end)