-- Linoria UI Roblox Script
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = Workspace.CurrentCamera

-- Linoria Library Load
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Toggles = Library.Toggles
local Options = Library.Options

-- Window
local Window = Library:CreateWindow({
    Title = 'Naberius',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Tabs
local MainTab     = Window:AddTab('Main')
local VisualsTab  = Window:AddTab('Visuals')
local AvatarTab   = Window:AddTab('Avatar')
local SettingsTab = Window:AddTab('Settings')

-- ─────────────────────────────────────────
-- MAIN TAB
-- ─────────────────────────────────────────
local AntiAfkBox = MainTab:AddLeftGroupbox('Anti AFK')

-- ── ANTI AFK ──────────────────────────────
local antiAfkJumpConn

AntiAfkBox:AddToggle('AntiAfkJump', {
    Text = 'ANTI AFK (JUMP)',
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
                    if char then
                        local hum = char:FindFirstChildOfClass('Humanoid')
                        if hum then hum.Jump = true end
                    end
                end
            end)
        end
    end
})

local antiAfkKeyConn

AntiAfkBox:AddToggle('AntiAfkKey', {
    Text = 'KEYBOARD ANTI AFK (1)',
    Default = false,
    Tooltip = '키보드 1번 키를 연속으로 눌러 AFK를 방지합니다.',
    Callback = function(val)
        if antiAfkKeyConn then antiAfkKeyConn:Disconnect(); antiAfkKeyConn = nil end
        if val then
            local lastPress = 0
            antiAfkKeyConn = RunService.Heartbeat:Connect(function()
                if tick() - lastPress >= 0.5 then
                    lastPress = tick()
                    pcall(function()
                        game:GetService('VirtualInputManager'):SendKeyEvent(true,  Enum.KeyCode.One, false, game)
                        game:GetService('VirtualInputManager'):SendKeyEvent(false, Enum.KeyCode.One, false, game)
                    end)
                end
            end)
        end
    end
})

-- ── FPS BOOST ─────────────────────────────
local FpsBox = MainTab:AddLeftGroupbox('FPS Boost')

FpsBox:AddToggle('FpsBoost', {
    Text = 'FPS Boost',
    Default = false,
    Tooltip = '그래픽 품질을 최소화하고 FPS를 최대한 끌어올립니다.',
    Callback = function(val)
        if val then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            pcall(function() Workspace.StreamingEnabled = false end)
            pcall(function()
                for _, v in pairs(Lighting:GetChildren()) do
                    if v:IsA('BlurEffect') or v:IsA('DepthOfFieldEffect')
                    or v:IsA('SunRaysEffect') or v:IsA('BloomEffect')
                    or v:IsA('ColorCorrectionEffect') then
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
                    if v:IsA('BlurEffect') or v:IsA('DepthOfFieldEffect')
                    or v:IsA('SunRaysEffect') or v:IsA('BloomEffect')
                    or v:IsA('ColorCorrectionEffect') then
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
    Default = 60,
    Min = 30,
    Max = 240,
    Rounding = 0,
    Tooltip = 'FPS 상한선을 설정합니다.',
    Callback = function(val)
        pcall(function()
            setfpscap(val)
        end)
    end
})

-- ── TELEPORT ──────────────────────────────
local TpBox = MainTab:AddRightGroupbox('Teleport')

TpBox:AddToggle('CtrlClickTp', {
    Text = 'Enable Ctrl + Click TP',
    Default = false,
    Tooltip = 'Ctrl 키를 누른 채 마우스 클릭 위치로 순간이동합니다.',
    Callback = function(val) end
})

Mouse.Button1Down:Connect(function()
    if not Toggles['CtrlClickTp'].Value then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
    and not UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then return end
    local char = Player.Character
    if not char then return end
    local root = char:FindFirstChild('HumanoidRootPart')
    if not root then return end
    local hit = Mouse.Hit
    if hit then
        root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
    end
end)

-- ── MOVEMENT ──────────────────────────────
local MoveBox = MainTab:AddRightGroupbox('Movement')

local noclipConn

MoveBox:AddToggle('Noclip', {
    Text = 'Enable Noclip',
    Default = false,
    Tooltip = '노클립 모드: 벽과 바닥을 통과할 수 있습니다.',
    Callback = function(val)
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        if val then
            noclipConn = RunService.Stepped:Connect(function()
                local char = Player.Character
                if not char then return end
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA('BasePart') and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end)
        else
            local char = Player.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA('BasePart') then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

-- ── GOD MODE ──────────────────────────────
local godConn

MoveBox:AddToggle('GodMode', {
    Text = 'God Mode (무적)',
    Default = false,
    Tooltip = '체력을 지속적으로 최대로 채워 사실상 무적 상태를 유지합니다.',
    Callback = function(val)
        if godConn then godConn:Disconnect(); godConn = nil end
        if val then
            godConn = RunService.Heartbeat:Connect(function()
                local char = Player.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass('Humanoid')
                if hum then
                    hum.Health = hum.MaxHealth
                end
            end)
        end
    end
})

-- ─────────────────────────────────────────
-- VISUALS TAB
-- ─────────────────────────────────────────
local VisLeft  = VisualsTab:AddLeftGroupbox('Player ESP')
local VisRight = VisualsTab:AddRightGroupbox('X-Ray & Object ESP')
local VisFree  = VisualsTab:AddLeftGroupbox('Freecam')

-- ── PLAYER ESP ────────────────────────────
local espObjects = {}

local function removeESP()
    for _, t in pairs(espObjects) do
        pcall(function()
            if t.Disconnect then t:Disconnect()
            else t:Destroy() end
        end)
    end
    espObjects = {}
end

local function createESP(target)
    if target == Player then return end
    local char = target.Character
    if not char then return end
    local root = char:FindFirstChild('HumanoidRootPart')
    if not root then return end

    local bb = Instance.new('BillboardGui')
    bb.Name = 'ESP_' .. target.Name
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 100, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.Adornee = root
    bb.Parent = CoreGui

    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextColor3 = Color3.fromRGB(255, 80, 80)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = bb

    local conn = RunService.RenderStepped:Connect(function()
        if not Toggles['PlayerESP'].Value or not char or not char.Parent then
            bb:Destroy()
            conn:Disconnect()
            return
        end
        local localChar = Player.Character
        local localRoot = localChar and localChar:FindFirstChild('HumanoidRootPart')
        local dist = localRoot and math.floor((localRoot.Position - root.Position).Magnitude) or 0
        local hum = char:FindFirstChildOfClass('Humanoid')
        local hp = hum and math.floor(hum.Health) or 0
        label.Text = target.Name .. '\n❤ ' .. hp .. '  📏 ' .. dist .. 'm'
    end)

    table.insert(espObjects, bb)
    table.insert(espObjects, { Disconnect = function() conn:Disconnect() end })
end

VisLeft:AddToggle('PlayerESP', {
    Text = 'Enable ESP',
    Default = false,
    Tooltip = '다른 플레이어의 위치, 체력, 거리를 화면에 표시합니다.',
    Callback = function(val)
        removeESP()
        if val then
            for _, p in pairs(Players:GetPlayers()) do
                createESP(p)
            end
        end
    end
})

Players.PlayerAdded:Connect(function(p)
    if Toggles['PlayerESP'].Value then
        p.CharacterAdded:Connect(function()
            task.wait(1)
            createESP(p)
        end)
    end
end)

-- ── X-RAY ─────────────────────────────────
local xrayOriginals = {}

local function applyXray()
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA('BasePart') then
            local plrChar = false
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and part:IsDescendantOf(p.Character) then
                    plrChar = true; break
                end
            end
            if not plrChar then
                xrayOriginals[part] = {
                    Transparency = part.Transparency,
                    Material = part.Material
                }
                part.Transparency = 0.6
                part.Material = Enum.Material.ForceField
            end
        end
    end
end

local function removeXray()
    for part, data in pairs(xrayOriginals) do
        pcall(function()
            part.Transparency = data.Transparency
            part.Material = data.Material
        end)
    end
    xrayOriginals = {}
end

VisRight:AddToggle('XRay', {
    Text = 'Enable X-Ray',
    Default = false,
    Tooltip = '맵의 모든 오브젝트를 반투명하게 만들어 벽 너머를 볼 수 있습니다.',
    Callback = function(val)
        if val then applyXray() else removeXray() end
    end
})

-- ── OBJECT ESP ────────────────────────────
local objEspObjects = {}
local objEspLastScan = 0
local OBJ_ESP_INTERVAL = 15

local function removeObjectESP()
    for _, v in pairs(objEspObjects) do
        pcall(function() v:Destroy() end)
    end
    objEspObjects = {}
end

local function scanObjectESP()
    removeObjectESP()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA('ProximityPrompt') then
            local parent = obj.Parent
            if not parent then continue end
            local adornPart = parent:IsA('BasePart') and parent
                or parent:FindFirstChildWhichIsA('BasePart')
            if not adornPart then continue end

            local bb = Instance.new('BillboardGui')
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0, 160, 0, 50)
            bb.StudsOffset = Vector3.new(0, 2, 0)
            bb.Adornee = adornPart
            bb.Parent = CoreGui

            local frame = Instance.new('Frame')
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            frame.BackgroundTransparency = 0.3
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.Parent = bb

            local label = Instance.new('TextLabel')
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 0.6, 0)
            label.Position = UDim2.new(0, 0, 0, 0)
            label.TextColor3 = Color3.fromRGB(255, 220, 50)
            label.TextStrokeTransparency = 0
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Text = '[E] ' .. (obj.ActionText ~= '' and obj.ActionText or parent.Name)
            label.Parent = frame

            local sublabel = Instance.new('TextLabel')
            sublabel.BackgroundTransparency = 1
            sublabel.Size = UDim2.new(1, 0, 0.4, 0)
            sublabel.Position = UDim2.new(0, 0, 0.6, 0)
            sublabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            sublabel.TextStrokeTransparency = 0
            sublabel.TextScaled = true
            sublabel.Font = Enum.Font.Gotham
            sublabel.Text = obj.ObjectText ~= '' and obj.ObjectText or parent.Name
            sublabel.Parent = frame

            table.insert(objEspObjects, bb)
        end
    end
end

VisRight:AddToggle('ObjectESP', {
    Text = 'Enable Object ESP',
    Default = false,
    Tooltip = 'E키로 상호작용 가능한 오브젝트를 15초 주기로 감지하여 ESP를 표시합니다.',
    Callback = function(val)
        if val then
            scanObjectESP()
        else
            removeObjectESP()
        end
    end
})

RunService.Heartbeat:Connect(function()
    if Toggles['ObjectESP'].Value then
        local now = tick()
        if now - objEspLastScan >= OBJ_ESP_INTERVAL then
            objEspLastScan = now
            scanObjectESP()
        end
    end
end)

-- ── FREECAM ───────────────────────────────
local freecamPart
local freecamConn
local FREECAM_SPEED = 30

VisFree:AddToggle('Freecam', {
    Text = 'Enable Freecam',
    Default = false,
    Tooltip = '캐릭터는 고정된 채 카메라만 자유롭게 이동합니다. WASD + Q/E로 이동.',
    Callback = function(val)
        if val then
            Camera.CameraType = Enum.CameraType.Scriptable

            freecamPart = Instance.new('Part')
            freecamPart.Anchored = true
            freecamPart.CanCollide = false
            freecamPart.Transparency = 1
            freecamPart.Size = Vector3.new(1, 1, 1)
            freecamPart.CFrame = Camera.CFrame
            freecamPart.Parent = Workspace

            Camera.CameraSubject = freecamPart

            freecamConn = RunService.RenderStepped:Connect(function(dt)
                local cf = Camera.CFrame
                local moveVec = Vector3.new(0, 0, 0)
                local spd = FREECAM_SPEED * dt

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cf.LookVector * spd end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cf.LookVector * spd end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cf.RightVector * spd end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cf.RightVector * spd end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVec = moveVec + Vector3.new(0, spd, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVec = moveVec - Vector3.new(0, spd, 0) end

                freecamPart.CFrame = CFrame.new(freecamPart.Position + moveVec)
                Camera.CFrame = CFrame.new(freecamPart.Position + moveVec, (freecamPart.Position + moveVec) + cf.LookVector)
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
    Default = 30,
    Min = 5,
    Max = 200,
    Rounding = 0,
    Tooltip = '프리캠 이동 속도를 조절합니다.',
    Callback = function(val)
        FREECAM_SPEED = val
    end
})

-- ─────────────────────────────────────────
-- AVATAR TAB
-- ─────────────────────────────────────────
local AvLeft  = AvatarTab:AddLeftGroupbox('Avatar Changer')
local AvRight = AvatarTab:AddRightGroupbox('Misc')

local function applyKorbloxHeadless(useKorblox, useHeadless)
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass('Humanoid')
    if not hum then return end

    local desc = hum:GetAppliedDescription()

    if useKorblox then
        desc.RightLeg = 139607718
    else
        desc.RightLeg = 0
    end

    if useHeadless then
        desc.Head = 15093053680
        pcall(function()
            local head = char:FindFirstChild('Head')
            if head then
                for _, v in pairs(head:GetChildren()) do
                    if v:IsA('SpecialMesh') then v.Scale = Vector3.new(0,0,0) end
                end
            end
        end)
    end

    pcall(function() hum:ApplyDescription(desc) end)
end

local korbloxOn = false
local headlessOn = false

AvLeft:AddToggle('Korblox', {
    Text = 'Korblox (오른쪽 다리)',
    Default = false,
    Tooltip = '코블록스 오른쪽 다리 (ID: 139607718)를 클라이언트 측으로 적용합니다.',
    Callback = function(val)
        korbloxOn = val
        applyKorbloxHeadless(korbloxOn, headlessOn)
    end
})

AvLeft:AddToggle('Headless', {
    Text = 'Headless (머리 제거)',
    Default = false,
    Tooltip = '헤드리스 머리 (ID: 15093053680)를 클라이언트 측으로 적용합니다.',
    Callback = function(val)
        headlessOn = val
        applyKorbloxHeadless(korbloxOn, headlessOn)
    end
})

AvLeft:AddInput('CopyAvatarId', {
    Default = '',
    Numeric = true,
    Finished = false,
    Text = 'User ID로 아바타 복사',
    Tooltip = '복사할 플레이어의 User ID(숫자)를 입력하세요.',
    Placeholder = '예: 123456789',
    Callback = function(val) end
})

AvLeft:AddButton({
    Text = '아바타 적용',
    Tooltip = '입력한 User ID의 아바타를 내 캐릭터에 클라이언트 측으로 적용합니다.',
    Callback = function()
        local idStr = Options['CopyAvatarId'].Value or ''
        local userId = tonumber(idStr)
        if not userId then
            Library:Notify('유효한 User ID를 입력하세요!', 3)
            return
        end
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass('Humanoid')
        if not hum then return end

        local ok, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(userId)
        end)
        if ok and desc then
            pcall(function() hum:ApplyDescription(desc) end)
            Library:Notify('아바타 적용 완료!', 3)
        else
            Library:Notify('아바타를 불러오지 못했습니다. ID를 확인하세요.', 3)
        end
    end
})

-- ── INVISIBILITY ──────────────────────────
local invisConn

AvRight:AddToggle('Invisibility', {
    Text = 'Enable Invisibility',
    Default = false,
    Tooltip = '자신을 투명하게 만듭니다.',
    Callback = function(val)
        local char = Player.Character
        if not char then return end

        if val then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA('BasePart') or part:IsA('Decal') then
                    part.Transparency = 1
                end
            end
            local root = char:FindFirstChild('HumanoidRootPart')
            if root then root.Transparency = 1 end

            if invisConn then invisConn:Disconnect() end
            invisConn = Player.CharacterAdded:Connect(function(newChar)
                task.wait(0.5)
                for _, part in pairs(newChar:GetDescendants()) do
                    if part:IsA('BasePart') or part:IsA('Decal') then
                        part.Transparency = 1
                    end
                end
            end)
        else
            if invisConn then invisConn:Disconnect(); invisConn = nil end
            local hum = char:FindFirstChildOfClass('Humanoid')
            if hum then
                local ok, desc = pcall(function()
                    return Players:GetHumanoidDescriptionFromUserId(Player.UserId)
                end)
                if ok then pcall(function() hum:ApplyDescription(desc) end) end
            end
        end
    end
})

-- ─────────────────────────────────────────
-- SETTINGS TAB
-- ─────────────────────────────────────────
local SetLeft  = SettingsTab:AddLeftGroupbox('Keybinds')
local SetRight = SettingsTab:AddRightGroupbox('Config')

SetLeft:AddLabel('UI 토글 키바인드')
SetLeft:AddKeybind('ToggleUI', {
    Text = 'Toggle UI',
    Default = Enum.KeyCode.RightShift,
    Tooltip = '이 키를 누르면 UI를 열고 닫습니다.',
    NoUI = false,
    Callback = function()
        Library:ToggleWindowState()
    end
})

SetLeft:AddKeybind('NoclipBind', {
    Text = 'Noclip 토글',
    Default = Enum.KeyCode.N,
    Tooltip = '이 키를 누르면 노클립을 켜고 끕니다.',
    Callback = function()
        Toggles['Noclip']:SetValue(not Toggles['Noclip'].Value)
    end
})

SetLeft:AddKeybind('FreecamBind', {
    Text = 'Freecam 토글',
    Default = Enum.KeyCode.F,
    Tooltip = '이 키를 누르면 프리캠을 켜고 끕니다.',
    Callback = function()
        Toggles['Freecam']:SetValue(not Toggles['Freecam'].Value)
    end
})

SetLeft:AddKeybind('ESPBind', {
    Text = 'ESP 토글',
    Default = Enum.KeyCode.Insert,
    Tooltip = '이 키를 누르면 ESP를 켜고 끕니다.',
    Callback = function()
        Toggles['PlayerESP']:SetValue(not Toggles['PlayerESP'].Value)
    end
})

-- ── CONFIG ────────────────────────────────
SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreList({ 'ToggleUI', 'NoclipBind', 'FreecamBind', 'ESPBind' })

SaveManager:BuildConfigSection(SetRight)
ThemeManager:BuildThemeSection(SetRight)

SaveManager:LoadAutoloadConfig()
Library:Notify('스크립트 로드 완료!', 3)
