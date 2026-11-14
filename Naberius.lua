-- Naberius Script (Fixed ESP, TP, Object ESP Optimization, Settings Tab)
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

local function getGuiParent()
local ok, parent = pcall(function()
if gethui then return gethui() end
return CoreGui
end)
return (ok and parent) or Player:WaitForChild("PlayerGui")
end

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
local lastJump = 0
antiAfkJumpConn = RunService.Heartbeat:Connect(function()
if tick() - lastJump >= 10 then
lastJump = tick()
local char = Player.Character
local hum = char and char:FindFirstChildOfClass('Humanoid')
if hum then
hum.Jump = true
hum:ChangeState(Enum.HumanoidStateType.Jumping)
end
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
local lastPress = 0
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
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
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
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
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

UserInputService.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
if Toggles['CtrlClickTp'] and Toggles['CtrlClickTp'].Value then
if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
local char = Player.Character
local root = char and char:FindFirstChild('HumanoidRootPart')
if root and Mouse.Hit then
root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
end
end
end
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

-- Player ESP
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
gui.Parent = getGuiParent()

local box = Instance.new('Frame')
box.Name = 'Box'
box.BackgroundTransparency = 1
box.BorderSizePixel = 0
box.ZIndex = 10
box.Parent = gui

local stroke = Instance.new('UIStroke')
stroke.Name = 'BoxStroke'
stroke.Thickness = 1.5
stroke.Color = Color3.fromRGB(255, 50, 50)
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = box

local nameLabel = Instance.new('TextLabel')
nameLabel.Name = 'NameLabel'
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextStrokeTransparency = 0
nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 12
nameLabel.Text = player.Name
nameLabel.TextXAlignment = Enum.TextXAlignment.Center
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

local topVP, topOn = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.2, 0))
local botVP, botOn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))

if topVP.Z <= 0 or botVP.Z <= 0 or (not topOn and not botOn) then
gui.Enabled = false
return
end

gui.Enabled = true

local h = math.max(math.abs(botVP.Y - topVP.Y), 10)
local w = h * 0.55
local cx = (topVP.X + botVP.X) / 2
local L = math.floor(cx - w / 2)
local T = math.floor(math.min(topVP.Y, botVP.Y))

local color = (Options['ESPColor'] and Options['ESPColor'].Value) or Color3.fromRGB(255, 50, 50)

local box = gui:FindFirstChild('Box')
if box then
box.Position = UDim2.fromOffset(L, T)
box.Size = UDim2.fromOffset(math.floor(w), math.floor(h))
local stroke = box:FindFirstChild('BoxStroke')
if stroke then stroke.Color = color end
end

local nl = gui:FindFirstChild('NameLabel')
if nl then
nl.Position = UDim2.fromOffset(math.floor(cx - 100), T - 18)
nl.Size = UDim2.fromOffset(200, 16)
end

local hpBg = gui:FindFirstChild('HpBg')
local hpBar = hpBg and hpBg:FindFirstChild('HpBar')
if hpBg and hpBar then
local bw = 4
hpBg.Position = UDim2.fromOffset(L - bw - 3, T)
hpBg.Size = UDim2.fromOffset(bw, math.floor(h))

local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
hpBar.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - pct)), math.floor(255 * pct), 0)
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
}):AddColorPicker('ESPColor', {
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

-- Object ESP (10초 주기 스캔 + 초경량 렌더링)
local objEspFolder = nil
local objEspItems = {}
local objEspRenderConn = nil
local objEspLastScan = 0
local OBJ_INTERVAL = 10

local function removeObjectESP()
if objEspRenderConn then
pcall(function() objEspRenderConn:Disconnect() end)
objEspRenderConn = nil
end
if objEspFolder then
pcall(function() objEspFolder:Destroy() end)
objEspFolder = nil
end
objEspItems = {}
end

local function scanObjectESP()
if objEspFolder then
pcall(function() objEspFolder:Destroy() end)
end
objEspItems = {}

local gui = Instance.new('ScreenGui')
gui.Name = 'Naberius_ObjESP'
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = getGuiParent()
objEspFolder = gui

for _, obj in ipairs(Workspace:GetDescendants()) do
if obj:IsA('ProximityPrompt') and obj.Enabled then
local parent = obj.Parent
if not parent then continue end
local adornPart = parent:IsA('BasePart') and parent or parent:FindFirstChildWhichIsA('BasePart')
if not adornPart then continue end

local actionText = '[E] ' .. (obj.ActionText ~= '' and obj.ActionText or parent.Name)
local objectText = obj.ObjectText ~= '' and obj.ObjectText or parent.Name

local holder = Instance.new('Frame')
holder.BackgroundTransparency = 1
holder.Size = UDim2.fromOffset(160, 32)
holder.AnchorPoint = Vector2.new(0.5, 0.5)
holder.Visible = false
holder.Parent = gui

local box = Instance.new('Frame')
box.BackgroundTransparency = 1
box.Size = UDim2.fromOffset(14, 14)
box.Position = UDim2.new(0.5, -7, 0.5, 4)
box.Parent = holder

local stroke = Instance.new('UIStroke')
stroke.Thickness = 1.5
stroke.Color = Color3.fromRGB(255, 220, 50)
stroke.Parent = box

local nameLabel = Instance.new('TextLabel')
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
nameLabel.TextStrokeTransparency = 0
nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 11
nameLabel.Text = actionText .. ' (' .. objectText .. ')'
nameLabel.Size = UDim2.new(1, 0, 0, 14)
nameLabel.Position = UDim2.fromOffset(0, -2)
nameLabel.Parent = holder

table.insert(objEspItems, { part = adornPart, holder = holder })
end
end

if not objEspRenderConn then
objEspRenderConn = RunService.RenderStepped:Connect(function()
if not Toggles['ObjectESP'] or not Toggles['ObjectESP'].Value then
if objEspFolder then objEspFolder.Enabled = false end
return
end
if objEspFolder then objEspFolder.Enabled = true end

local camPos = Camera.CFrame.Position
for i = #objEspItems, 1, -1 do
local item = objEspItems[i]
local part = item.part
local holder = item.holder
if not part or not part.Parent or not holder or not holder.Parent then
if holder then holder:Destroy() end
table.remove(objEspItems, i)
else
if (part.Position - camPos).Magnitude > 1000 then
holder.Visible = false
else
local vp, onScreen = Camera:WorldToViewportPoint(part.Position)
if onScreen and vp.Z > 0 then
holder.Visible = true
holder.Position = UDim2.fromOffset(math.floor(vp.X), math.floor(vp.Y))
else
holder.Visible = false
end
end
end
end
end)
end
end

VisRight:AddToggle('ObjectESP', {
Text = 'Enable Object ESP',
Default = false,
Tooltip = '10초마다 주변 상호작용 오브젝트를 감지해 표시합니다 (렉 방지).',
Callback = function(val)
if val then
objEspLastScan = tick()
scanObjectESP()
else
removeObjectESP()
end
end
})

task.spawn(function()
while task.wait(1) do
if Toggles['ObjectESP'] and Toggles['ObjectESP'].Value then
if tick() - objEspLastScan >= OBJ_INTERVAL then
objEspLastScan = tick()
scanObjectESP()
end
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
local hum = char and char:FindFirstChildOfClass('Humanoid')
if not hum then return end

pcall(function()
local desc = hum:GetAppliedDescription()
desc.RightLeg = k and 139607718 or 0
if h then
desc.Head = 15093053680
end
hum:ApplyDescription(desc)
end)

task.defer(function()
local head = char:FindFirstChild('Head')
if head then
head.Transparency = h and 1 or 0
for _, v in pairs(head:GetChildren()) do
if v:IsA('SpecialMesh') then
v.Scale = h and Vector3.new(0, 0, 0) or Vector3.new(1.25, 1.25, 1.25)
elseif v:IsA('Decal') then
v.Transparency = h and 1 or 0
end
end
end

local rLower = char:FindFirstChild('RightLowerLeg')
local rFoot = char:FindFirstChild('RightFoot')
if rLower and rFoot then
rLower.Transparency = k and 1 or 0
rFoot.Transparency = k and 1 or 0
end
end)
end

AvLeft:AddToggle('Korblox', {
Text = 'Korblox',
Default = false,
Tooltip = '코블록스 오른쪽 다리를 클라이언트 측으로 적용합니다.',
Callback = function(val) korbloxOn = val; applyKorbloxHeadless(korbloxOn, headlessOn) end
})

AvLeft:AddToggle('Headless', {
Text = 'Headless',
Default = false,
Tooltip = '헤드리스를 클라이언트 측으로 적용합니다.',
Callback = function(val) headlessOn = val; applyKorbloxHeadless(korbloxOn, headlessOn) end
})

Player.CharacterAdded:Connect(function()
task.wait(1)
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
local userId = tonumber(Options['CopyAvatarId'] and Options['CopyAvatarId'].Value or '')
if not userId then Library:Notify('유효한 User ID를 입력하세요!', 3); return end
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
for _, p in pairs(char:GetDescendants()) do
if (p:IsA('BasePart') or p:IsA('Decal')) and p.Name ~= 'HumanoidRootPart' then
p.Transparency = 0
end
end
end
end
})

-- ─── SETTINGS TAB ────────────────────────
local SetLeft = SettingsTab:AddLeftGroupbox('Keybinds')
local SetRight = SettingsTab:AddRightGroupbox('Config')

SetLeft:AddLabel('Toggle UI'):AddKeyPicker('ToggleUI', {
Default = 'RightShift',
NoUI = true,
Text = 'Toggle UI'
})
Library.ToggleKeybind = Options['ToggleUI']

SetLeft:AddLabel('Noclip 토글'):AddKeyPicker('NoclipBind', {
Default = 'N',
Text = 'Noclip 토글',
Callback = function()
if Toggles['Noclip'] then Toggles['Noclip']:SetValue(not Toggles['Noclip'].Value) end
end
})

SetLeft:AddLabel('Freecam 토글'):AddKeyPicker('FreecamBind', {
Default = 'F',
Text = 'Freecam 토글',
Callback = function()
if Toggles['Freecam'] then Toggles['Freecam']:SetValue(not Toggles['Freecam'].Value) end
end
})

SetLeft:AddLabel('ESP 토글'):AddKeyPicker('ESPBind', {
Default = 'Insert',
Text = 'ESP 토글',
Callback = function()
if Toggles['PlayerESP'] then Toggles['PlayerESP']:SetValue(not Toggles['PlayerESP'].Value) end
end
})

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreList({ 'ToggleUI', 'NoclipBind', 'FreecamBind', 'ESPBind' })
SaveManager:SetFolder('Naberius')
ThemeManager:SetFolder('Naberius')
SaveManager:BuildConfigSection(SetRight)
ThemeManager:BuildThemeSection(SetRight)
pcall(function() SaveManager:LoadAutoloadConfig() end)

Library:Notify('Naberius 로드 완료!', 3)
