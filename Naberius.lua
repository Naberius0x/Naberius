-- Naberius Script (Fully Fixed & Restructured)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = Workspace.CurrentCamera

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Toggles = Library.Toggles
local Options = Library.Options

local Window = Library:CreateWindow({
Title = 'Naberius',
Center = true,
AutoShow = true,
TabPadding = 8,
MenuFadeTime = 0.2
})

local MainTab = Window:AddTab('Main')
local VisualsTab = Window:AddTab('Visuals')
local AvatarTab = Window:AddTab('Avatar')
local SettingsTab = Window:AddTab('Settings')

-- ─── MAIN TAB ────────────────────────────
local AntiAfkBox = MainTab:AddLeftGroupbox('Anti AFK')
local antiAfkJumpConn, antiAfkKeyConn

AntiAfkBox:AddToggle('AntiAfkJump', {
Text = 'Anti AFK (Jump)',
Default = false,
Tooltip = '10초마다 자동으로 점프하여 AFK 감지를 방지합니다.',
Callback = function(val)
if antiAfkJumpConn then antiAfkJumpConn:Disconnect(); antiAfkJumpConn = nil end
if val then
local lastJump = tick()
antiAfkJumpConn = RunService.Heartbeat:Connect(function()
if tick() - lastJump >= 10 then
lastJump = tick()
local char = Player.Character
local hum = char and char:FindFirstChildOfClass('Humanoid')
if hum then hum.Jump = true end
end
end)
end
end
})

AntiAfkBox:AddToggle('AntiAfkKey', {
Text = 'Anti AFK (Key)',
Default = false,
Tooltip = '키보드 1번 키를 0.5초마다 눌러 AFK를 방지합니다.',
Callback = function(val)
if antiAfkKeyConn then antiAfkKeyConn:Disconnect(); antiAfkKeyConn = nil end
if val then
local lastPress = tick()
antiAfkKeyConn = RunService.Heartbeat:Connect(function()
if tick() - lastPress >= 0.5 then
lastPress = tick()
pcall(function()
VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
end)
end
end)
end
end
})

local FpsBox = MainTab:AddLeftGroupbox('FPS Boost')

FpsBox:AddToggle('FpsBoost', {
Text = 'FPS Boost',
Default = false,
Tooltip = '그래픽 품질을 최소화하여 FPS를 올립니다.',
Callback = function(val)
if val then
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
pcall(function() Workspace.StreamingEnabled = false end)
pcall(function()
for _, v in pairs(Lighting:GetChildren()) do
if v:IsA('BlurEffect') or v:IsA('DepthOfFieldEffect') or v:IsA('SunRaysEffect') or v:IsA('BloomEffect') or v:IsA('ColorCorrectionEffect') then
v.Enabled = false
end
end
Lighting.GlobalShadows = false
Lighting.FogEnd = 100000
Lighting.FogStart = 99999
end)
else
settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
pcall(function()
for _, v in pairs(Lighting:GetChildren()) do
if v:IsA('BlurEffect') or v:IsA('DepthOfFieldEffect') or v:IsA('SunRaysEffect') or v:IsA('BloomEffect') or v:IsA('ColorCorrectionEffect') then
v.Enabled = true
end
end
Lighting.GlobalShadows = true
end)
end
end
})

FpsBox:AddSlider('FpsCap', {
Text = 'FPS Cap',
Default = 60, Min = 30, Max = 240, Rounding = 0,
Tooltip = 'FPS 상한선을 설정합니다.',
Callback = function(val)
pcall(function() setfpscap(val) end)
end
})

local TpBox = MainTab:AddRightGroupbox('Teleport')

TpBox:AddToggle('CtrlClickTp', {
Text = 'Ctrl + Click TP',
Default = false,
Tooltip = 'Ctrl 누른 채 클릭하면 그 위치로 순간이동합니다.',
Callback = function() end
})

Mouse.Button1Down:Connect(function()
if not Toggles['CtrlClickTp'] or not Toggles['CtrlClickTp'].Value then return end
if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and not UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then return end
local char = Player.Character
local root = char and char:FindFirstChild('HumanoidRootPart')
if root and Mouse.Hit then
root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
end
end)

local MoveBox = MainTab:AddRightGroupbox('Movement')
local noclipConn, godConn

MoveBox:AddToggle('Noclip', {
Text = 'Noclip',
Default = false,
Tooltip = '벽과 바닥을 통과할 수 있습니다.',
Callback = function(val)
if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
if val then
noclipConn = RunService.Stepped:Connect(function()
local char = Player.Character
if not char then return end
for _, p in pairs(char:GetDescendants()) do
if p:IsA('BasePart') then p.CanCollide = false end
end
end)
else
local char = Player.Character
if char then
for _, p in pairs(char:GetDescendants()) do
if p:IsA('BasePart') then p.CanCollide = true end
end
end
end
end
})

MoveBox:AddToggle('GodMode', {
Text = 'God Mode',
Default = false,
Tooltip = '체력을 계속 최대로 유지합니다.',
Callback = function(val)
if godConn then godConn:Disconnect(); godConn = nil end
if val then
godConn = RunService.Heartbeat:Connect(function()
local char = Player.Character
local hum = char and char:FindFirstChildOfClass('Humanoid')
if hum then hum.Health = hum.MaxHealth end
end)
end
end
})

-- ─── VISUALS TAB ─────────────────────────
local VisLeft = VisualsTab:AddLeftGroupbox('Player ESP')
local VisRight = VisualsTab:AddRightGroupbox('Object ESP & X-Ray')
local VisFree = VisualsTab:AddLeftGroupbox('Freecam')

local espData = {}

local function removeESPForPlayer(name)
if espData[name] then
pcall(function() espData[name].conn:Disconnect() end)
pcall(function() espData[name].gui:Destroy() end)
espData[name] = nil
end
end

local function removeAllESP()
for name, _ in pairs(espData) do
removeESPForPlayer(name)
end
end

local function makeESPGui(player)
local gui = Instance.new('ScreenGui')
gui.Name = 'ESP_' .. player.Name
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
if syn and syn.protect_gui then
syn.protect_gui(gui)
gui.Parent = CoreGui
elseif gethui then
gui.Parent = gethui()
else
gui.Parent = CoreGui
end
end)
if not gui.Parent then gui.Parent = CoreGui end

for i = 1, 4 do
 local line = Instance.new('Frame')
 line.Name = 'Line' .. i
 line.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
 line.BorderSizePixel = 0
 line.ZIndex = 10
 line.Parent = gui
 end

local nameLabel = Instance.new('TextLabel')
 nameLabel.Name = 'NameLabel'
 nameLabel.BackgroundTransparency = 1
 nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
 nameLabel.TextStrokeTransparency = 0
 nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
 nameLabel.Font = Enum.Font.GothamBold
 nameLabel.TextSize = 12
 nameLabel.Text = player.Name
 nameLabel.Size = UDim2.new(0, 200, 0, 16)
 nameLabel.ZIndex = 10
 nameLabel.Parent = gui

local hpBg = Instance.new('Frame')
 hpBg.Name = 'HpBg'
 hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
 hpBg.BorderSizePixel = 0
 hpBg.ZIndex = 10
 hpBg.Parent = gui

local hpBar = Instance.new('Frame')
 hpBar.Name = 'HpBar'
 hpBar.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
 hpBar.BorderSizePixel = 0
 hpBar.AnchorPoint = Vector2.new(0, 1)
 hpBar.ZIndex = 11
 hpBar.Parent = hpBg

return gui
end

local function startESP(player)
if player == Player then return end
removeESPForPlayer(player.Name)

local gui = makeESPGui(player)

local conn = RunService.RenderStepped:Connect(function()
 if not Toggles['PlayerESP'] or not Toggles['PlayerESP'].Value then
 gui.Enabled = false
 return
 end

local char = player.Character
 local root = char and char:FindFirstChild('HumanoidRootPart')
 local hum = char and char:FindFirstChildOfClass('Humanoid')

if not root or not hum or hum.Health <= 0 then
 gui.Enabled = false
 return
 end

local topVP = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.2, 0))
 local botVP = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))

if topVP.Z <= 0 then
 gui.Enabled = false
 return
 end

gui.Enabled = true

local topX, topY = topVP.X, topVP.Y
 local botX, botY = botVP.X, botVP.Y

local h = math.abs(botY - topY)
 local w = h * 0.55
 local cx = (topX + botX) / 2

local L = cx - w / 2
 local R = cx + w / 2
 local T = topY
 local B = botY
 local thick = 1.5

local color = Options['ESPColor'] and Options['ESPColor'].Value or Color3.fromRGB(255, 50, 50)

local l1 = gui:FindFirstChild('Line1')
 local l2 = gui:FindFirstChild('Line2')
 local l3 = gui:FindFirstChild('Line3')
 local l4 = gui:FindFirstChild('Line4')

if l1 then l1.BackgroundColor3 = color; l1.Position = UDim2.new(0, L, 0, T); l1.Size = UDim2.new(0, w, 0, thick) end
 if l2 then l2.BackgroundColor3 = color; l2.Position = UDim2.new(0, L, 0, B); l2.Size = UDim2.new(0, w, 0, thick) end
 if l3 then l3.BackgroundColor3 = color; l3.Position = UDim2.new(0, L, 0, T); l3.Size = UDim2.new(0, thick, 0, h) end
 if l4 then l4.BackgroundColor3 = color; l4.Position = UDim2.new(0, R, 0, T); l4.Size = UDim2.new(0, thick, 0, h) end

local nl = gui:FindFirstChild('NameLabel')
 if nl then
 nl.Position = UDim2.new(0, L, 0, T - 17)
 nl.Size = UDim2.new(0, w, 0, 16)
 nl.TextXAlignment = Enum.TextXAlignment.Center
 end

local hpBg = gui:FindFirstChild('HpBg')
 local hpBar = hpBg and hpBg:FindFirstChild('HpBar')
 if hpBg and hpBar then
 local bw = 4
 hpBg.Position = UDim2.new(0, L - bw - 2, 0, T)
 hpBg.Size = UDim2.new(0, bw, 0, h)

local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
 hpBar.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-pct)), math.floor(255*pct), 0)
 hpBar.Size = UDim2.new(1, 0, pct, 0)
 hpBar.Position = UDim2.new(0, 0, 1, 0)
 end
 end)

espData[player.Name] = { gui = gui, conn = conn }
end

VisLeft:AddToggle('PlayerESP', {
Text = 'Enable Player ESP',
Default = false,
Tooltip = '다른 플레이어에게 박스, 이름, 체력바를 표시합니다.',
Callback = function(val)
if val then
for _, p in pairs(Players:GetPlayers()) do startESP(p) end
else
removeAllESP()
end
end
})

VisLeft:AddColorPicker('ESPColor', {
Title = 'ESP Box Color',
Default = Color3.fromRGB(255, 50, 50),
})

Players.PlayerAdded:Connect(function(p)
p.CharacterAdded:Connect(function()
task.wait(1)
if Toggles['PlayerESP'] and Toggles['PlayerESP'].Value then
startESP(p)
end
end)
end)

Players.PlayerRemoving:Connect(function(p)
removeESPForPlayer(p.Name)
end)

-- Object ESP
local objEspConns = {}
local objEspGuis = {}
local objEspLastScan = 0
local OBJ_INTERVAL = 15

local function removeObjectESP()
for _, c in pairs(objEspConns) do pcall(function() c:Disconnect() end) end
for _, g in pairs(objEspGuis) do pcall(function() g:Destroy() end) end
objEspConns = {}
objEspGuis = {}
end

local function createObjESP(adornPart, actionText, objectText)
local gui = Instance.new('ScreenGui')
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
if syn and syn.protect_gui then
syn.protect_gui(gui)
gui.Parent = CoreGui
elseif gethui then
gui.Parent = gethui()
else
gui.Parent = CoreGui
end
end)
if not gui.Parent then gui.Parent = CoreGui end

for i = 1, 4 do
 local line = Instance.new('Frame')
 line.Name = 'Line' .. i
 line.BackgroundColor3 = Color3.fromRGB(255, 220, 50)
 line.BorderSizePixel = 0
 line.ZIndex = 10
 line.Parent = gui
 end

local nameLabel = Instance.new('TextLabel')
 nameLabel.Name = 'NameLabel'
 nameLabel.BackgroundTransparency = 1
 nameLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
 nameLabel.TextStrokeTransparency = 0
 nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
 nameLabel.Font = Enum.Font.GothamBold
 nameLabel.TextSize = 12
 nameLabel.Text = actionText
 nameLabel.Size = UDim2.new(0, 200, 0, 16)
 nameLabel.ZIndex = 10
 nameLabel.Parent = gui

local descLabel = Instance.new('TextLabel')
 descLabel.Name = 'DescLabel'
 descLabel.BackgroundTransparency = 1
 descLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
 descLabel.TextStrokeTransparency = 0
 descLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
 descLabel.Font = Enum.Font.Gotham
 descLabel.TextSize = 11
 descLabel.Text = objectText
 descLabel.Size = UDim2.new(0, 200, 0, 14)
 descLabel.ZIndex = 10
 descLabel.Parent = gui

local conn = RunService.RenderStepped:Connect(function()
 if not Toggles['ObjectESP'] or not Toggles['ObjectESP'].Value then
 gui.Enabled = false
 return
 end
 if not adornPart or not adornPart.Parent then
 gui:Destroy()
 return
 end

local size = adornPart.Size
 local cf = adornPart.CFrame
 local offsets = {
 Vector3.new( size.X/2, size.Y/2, size.Z/2),
 Vector3.new(-size.X/2, size.Y/2, size.Z/2),
 Vector3.new( size.X/2, -size.Y/2, size.Z/2),
 Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
 Vector3.new( size.X/2, size.Y/2, -size.Z/2),
 Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
 Vector3.new( size.X/2, -size.Y/2, -size.Z/2),
 Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
 }

local minX, minY = math.huge, math.huge
 local maxX, maxY = -math.huge, -math.huge
 local visible = false

for _, offset in ipairs(offsets) do
 local wp = (cf * CFrame.new(offset)).Position
 local vp = Camera:WorldToViewportPoint(wp)
 if vp.Z > 0 then
 visible = true
 if vp.X < minX then minX = vp.X end
 if vp.Y < minY then minY = vp.Y end
 if vp.X > maxX then maxX = vp.X end
 if vp.Y > maxY then maxY = vp.Y end
 end
 end

if not visible then gui.Enabled = false; return end
 gui.Enabled = true

local w = maxX - minX
 local h = maxY - minY
 local thick = 1.5

local l1 = gui:FindFirstChild('Line1')
 local l2 = gui:FindFirstChild('Line2')
 local l3 = gui:FindFirstChild('Line3')
 local l4 = gui:FindFirstChild('Line4')

if l1 then l1.Position = UDim2.new(0, minX, 0, minY); l1.Size = UDim2.new(0, w, 0, thick) end
 if l2 then l2.Position = UDim2.new(0, minX, 0, maxY); l2.Size = UDim2.new(0, w, 0, thick) end
 if l3 then l3.Position = UDim2.new(0, minX, 0, minY); l3.Size = UDim2.new(0, thick, 0, h) end
 if l4 then l4.Position = UDim2.new(0, maxX, 0, minY); l4.Size = UDim2.new(0, thick, 0, h) end

local nl = gui:FindFirstChild('NameLabel')
 local dl = gui:FindFirstChild('DescLabel')
 if nl then nl.Position = UDim2.new(0, minX, 0, minY - 18) end
 if dl then dl.Position = UDim2.new(0, minX, 0, minY - 32) end
 end)

table.insert(objEspConns, conn)
 table.insert(objEspGuis, gui)
end

local function scanObjectESP()
removeObjectESP()
for _, obj in pairs(Workspace:GetDescendants()) do
if obj:IsA('ProximityPrompt') then
local parent = obj.Parent
if not parent then continue end
local adornPart = parent:IsA('BasePart') and parent or parent:FindFirstChildWhichIsA('BasePart')
if not adornPart then continue end
local actionText = '[E] ' .. (obj.ActionText ~= '' and obj.ActionText or parent.Name)
local objectText = obj.ObjectText ~= '' and obj.ObjectText or parent.Name
createObjESP(adornPart, actionText, objectText)
end
end
end

VisRight:AddToggle('ObjectESP', {
Text = 'Enable Object ESP',
Default = false,
Tooltip = '상호작용 가능한 오브젝트에 박스와 이름을 표시합니다.',
Callback = function(val)
if val then scanObjectESP() else removeObjectESP() end
end
})

RunService.Heartbeat:Connect(function()
if Toggles['ObjectESP'] and Toggles['ObjectESP'].Value then
if tick() - objEspLastScan >= OBJ_INTERVAL then
objEspLastScan = tick()
scanObjectESP()
end
end
end)

-- X-Ray
local xrayOriginals = {}

VisRight:AddToggle('XRay', {
Text = 'Enable X-Ray',
Default = false,
Tooltip = '맵 오브젝트를 반투명하게 만들어 벽 너머를 볼 수 있습니다.',
Callback = function(val)
if val then
for _, part in pairs(Workspace:GetDescendants()) do
if part:IsA('BasePart') and not part:IsA('Terrain') then
local isChar = false
for _, p in pairs(Players:GetPlayers()) do
if p.Character and part:IsDescendantOf(p.Character) then isChar = true; break end
end
if not isChar then
xrayOriginals[part] = { T = part.Transparency, M = part.Material }
part.Transparency = 0.6
part.Material = Enum.Material.ForceField
end
end
end
else
for part, data in pairs(xrayOriginals) do
pcall(function() part.Transparency = data.T; part.Material = data.M end)
end
xrayOriginals = {}
end
end
})

-- Freecam
local freecamPart, freecamConn
local FREECAM_SPEED = 30

VisFree:AddToggle('Freecam', {
Text = 'Enable Freecam',
Default = false,
Tooltip = 'WASD + Q/E로 카메라를 자유롭게 이동합니다.',
Callback = function(val)
if val then
Camera.CameraType = Enum.CameraType.Scriptable
freecamPart = Instance.new('Part')
freecamPart.Anchored = true
freecamPart.CanCollide = false
freecamPart.Transparency = 1
freecamPart.Size = Vector3.new(1,1,1)
freecamPart.CFrame = Camera.CFrame
freecamPart.Parent = Workspace
Camera.CameraSubject = freecamPart

freecamConn = RunService.RenderStepped:Connect(function(dt)
local cf = Camera.CFrame
local mv = Vector3.new(0,0,0)
local spd = FREECAM_SPEED * dt
if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cf.LookVector * spd end
if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cf.LookVector * spd end
if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cf.RightVector * spd end
if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cf.RightVector * spd end
if UserInputService:IsKeyDown(Enum.KeyCode.E) then mv = mv + Vector3.new(0,spd,0) end
if UserInputService:IsKeyDown(Enum.KeyCode.Q) then mv = mv - Vector3.new(0,spd,0) end
local newPos = freecamPart.Position + mv
freecamPart.CFrame = CFrame.new(newPos)
Camera.CFrame = CFrame.new(newPos, newPos + cf.LookVector)
end)
else
if freecamConn then freecamConn:Disconnect(); freecamConn = nil end
if freecamPart then freecamPart:Destroy(); freecamPart = nil end
Camera.CameraType = Enum.CameraType.Custom
local char = Player.Character
local hum = char and char:FindFirstChildOfClass('Humanoid')
if hum then Camera.CameraSubject = hum end
end
end
})

VisFree:AddSlider('FreecamSpeed', {
Text = 'Freecam Speed',
Default = 30, Min = 5, Max = 200, Rounding = 0,
Tooltip = '프리캠 이동 속도를 조절합니다.',
Callback = function(val) FREECAM_SPEED = val end
})

-- ─── AVATAR TAB ──────────────────────────
local AvLeft = AvatarTab:AddLeftGroupbox('Avatar Changer')
local AvRight = AvatarTab:AddRightGroupbox('Misc')

local korbloxOn, headlessOn = false, false

local function applyKorbloxHeadless(k, h)
local char = Player.Character
if not char then return end
local hum = char:FindFirstChildOfClass('Humanoid')
if not hum then return end

pcall(function()
local desc = hum:GetAppliedDescription()
desc.RightLeg = k and 139607718 or 0
if h then
desc.Head = 0
end
hum:ApplyDescription(desc)
end)

if h then
task.defer(function()
local head = char:FindFirstChild('Head')
if head then
for _, v in pairs(head:GetChildren()) do
if v:IsA('SpecialMesh') then v.Scale = Vector3.new(0, 0, 0) end
end
head.Transparency = 1
local face = head:FindFirstChild('face')
if face then face.Transparency = 1 end
end
end)
end
end

AvLeft:AddToggle('Korblox', {
Text = 'Korblox',
Default = false,
Tooltip = '코블록스 오른쪽 다리를 클라이언트 측으로 적용합니다.',
Callback = function(val)
korbloxOn = val
applyKorbloxHeadless(korbloxOn, headlessOn)
end
})

AvLeft:AddToggle('Headless', {
Text = 'Headless',
Default = false,
Tooltip = '헤드리스를 클라이언트 측으로 적용합니다.',
Callback = function(val)
headlessOn = val
applyKorbloxHeadless(korbloxOn, headlessOn)
end
})

Player.CharacterAdded:Connect(function()
task.wait(1.5)
if korbloxOn or headlessOn then
applyKorbloxHeadless(korbloxOn, headlessOn)
end
end)

AvLeft:AddInput('CopyAvatarId', {
Default = '', Numeric = true, Finished = false,
Text = 'User ID로 아바타 복사',
Tooltip = '복사할 플레이어의 User ID를 입력하세요.',
Placeholder = '예: 123456789',
Callback = function() end
})

AvLeft:AddButton({
Text = '아바타 적용',
Tooltip = '입력한 User ID의 아바타를 적용합니다.',
Callback = function()
local rawVal = Options['CopyAvatarId'].Value
local userId = tonumber(rawVal)
if not userId or userId <= 0 then
Library:Notify('유효한 User ID를 입력하세요!', 3)
return
end
local char = Player.Character
local hum = char and char:FindFirstChildOfClass('Humanoid')
if not hum then return end
local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
if ok and desc then
pcall(function() hum:ApplyDescription(desc) end)
Library:Notify('아바타 적용 완료!', 3)
else
Library:Notify('아바타를 불러오지 못했습니다.', 3)
end
end
})

local invisConn

AvRight:AddToggle('Invisibility', {
Text = 'Invisibility',
Default = false,
Tooltip = '자신의 캐릭터를 투명하게 만듭니다.',
Callback = function(val)
local char = Player.Character
if not char then return end
if val then
for _, p in pairs(char:GetDescendants()) do
if p:IsA('BasePart') or p:IsA('Decal') then p.Transparency = 1 end
end
if invisConn then invisConn:Disconnect() end
invisConn = Player.CharacterAdded:Connect(function(newChar)
task.wait(0.5)
for _, p in pairs(newChar:GetDescendants()) do
if p:IsA('BasePart') or p:IsA('Decal') then p.Transparency = 1 end
end
end)
else
if invisConn then invisConn:Disconnect(); invisConn = nil end
local hum = char:FindFirstChildOfClass('Humanoid')
if hum then
local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(Player.UserId) end)
if ok then pcall(function() hum:ApplyDescription(desc) end) end
end
end
end
})

-- ─── SETTINGS TAB ────────────────────────
local SetLeft = SettingsTab:AddLeftGroupbox('Keybinds')
local SetRight = SettingsTab:AddRightGroupbox('Config')

SetLeft:AddKeybind('ToggleUI', {
Text = 'Toggle UI',
Default = Enum.KeyCode.RightShift,
NoUI = false,
Callback = function() Library:ToggleWindowState() end
})

SetLeft:AddKeybind('NoclipBind', {
Text = 'Noclip 토글',
Default = Enum.KeyCode.N,
Callback = function() Toggles['Noclip']:SetValue(not Toggles['Noclip'].Value) end
})

SetLeft:AddKeybind('FreecamBind', {
Text = 'Freecam 토글',
Default = Enum.KeyCode.F,
Callback = function() Toggles['Freecam']:SetValue(not Toggles['Freecam'].Value) end
})

SetLeft:AddKeybind('ESPBind', {
Text = 'ESP 토글',
Default = Enum.KeyCode.Insert,
Callback = function() Toggles['PlayerESP']:SetValue(not Toggles['PlayerESP'].Value) end
})

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreList({ 'ToggleUI', 'NoclipBind', 'FreecamBind', 'ESPBind' })
SaveManager:BuildConfigSection(SetRight)
ThemeManager:BuildThemeSection(SetRight)
SaveManager:LoadAutoloadConfig()

Library:Notify('Naberius 로드 완료!', 3)
