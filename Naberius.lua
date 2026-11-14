-- Naberius Hub (Ultimate Visual & ESP Fixed Version)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Linoria 라이브러리 로드
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Toggles = Library.Toggles
local Options = Library.Options

-- CoreGui 보호 및 안전 부모 설정 함수 (ESP가 안 뜨던 원인 원천 차단)
local function getGuiParent()
    local ok, parent = pcall(function()
        if gethui then return gethui() end
        if syn and syn.protect_gui then return CoreGui end
        return CoreGui
    end)
    return (ok and parent) or LocalPlayer:WaitForChild("PlayerGui")
end

-- 창 생성
local Window = Library:CreateWindow({
    Title = 'Naberius',
    Center = true,
    AutoShow = true,
})

-- 탭 생성
local Tabs = {
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'),
    Avatar = Window:AddTab('Avatar'),
    Settings = Window:AddTab('Settings')
}

-- 서비스 및 변수
local isRunning = false
local afkCoroutine = nil
local useAntiCheatBypass = false
local customName = "" 
local isClickTpEnabled = false
local isEspRunning = false
local isXrayRunning = false
local isObjectEspRunning = false
local originalTransparencies = {}
local objectEspContainer = {}
local espData = {}

-- 효과 관련 저장용 변수
local customBloomEffect = nil
local customColorCorrEffect = nil
local neonAtmosphere = nil
local originalLightingSettings = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

-- 키보드 1번 연타 AFK 관련 변수
local isKeyAfkRunning = false
local keyAfkCoroutine = nil

-- FPS Boost 상태 및 원래 설정을 저장하기 위한 테이블
local fpsBoostConnection = nil
local originalFpsSettings = {}

-- 노클립 상태 관리를 위한 변수
local noclipConnection = nil
local originalCollisions = {}

-- 프리캠 상태 관리를 위한 변수
local isFreecamRunning = false
local freecamConnection = nil
local camPosition = Vector3.new()
local targetPosition = Vector3.new()
local cameraYaw = 0
local cameraPitch = 0
local targetYaw = 0
local targetPitch = 0
local freecamFov = 70
local targetFov = 70

-- 캐릭터의 오리지널 충돌 상태를 기록하는 함수
local function saveOriginalCollisions(character)
    if not character then return end
    originalCollisions = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollisions[part] = part.CanCollide
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    saveOriginalCollisions(char)
end)
if LocalPlayer.Character then saveOriginalCollisions(LocalPlayer.Character) end

-- 점프 및 우회 AFK 방지 함수
local function forceJump()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            if useAntiCheatBypass then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                hum.Jump = true
                task.wait(math.random(1, 3) / 10)
                hum.Jump = false
            else
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                hum.Jump = true
                task.wait(0.1)
                hum.Jump = false
            end
        end
    end
end

-- 1번 키 인식 오류 해결을 위한 고성능 입력 메커니즘
local function pressOneKey()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)

        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(1, 1))
        task.wait(0.01)
        VirtualUser:Button1Up(Vector2.new(1, 1))
    end)
end

---------------------------------------------------------
-- [Main 탭]
---------------------------------------------------------
local GroupBox = Tabs.Main:AddLeftGroupbox('ANTI AFK')
local FpsBox = Tabs.Main:AddLeftGroupbox('FPS Boost')
local TpBox = Tabs.Main:AddLeftGroupbox('TELEPORT')
local MovementBox = Tabs.Main:AddRightGroupbox('Movement')

GroupBox:AddToggle('AntiAfkToggle', {
    Text = 'ANTI AFK(JUMP)',
    Default = false,
    Tooltip = '활성화 시 10초마다 자동으로 점프하여 AFK 방지',
    Callback = function(Value)
        isRunning = Value
        if isRunning then
            afkCoroutine = task.spawn(function()
                while isRunning do
                    forceJump()
                    task.wait(10)
                end
            end)
        else
            if afkCoroutine then task.cancel(afkCoroutine) end
        end
    end
})

GroupBox:AddToggle('KeyAntiAfkToggle', {
    Text = 'KEYBOARD ANTI AFK (1)',
    Default = false,
    Tooltip = '활성화 시 인식이 누락되지 않도록 다중 교차 방식으로 1번 키를 빠르게 입력합니다.',
    Callback = function(Value)
        isKeyAfkRunning = Value
        if isKeyAfkRunning then
            keyAfkCoroutine = task.spawn(function()
                while isKeyAfkRunning do
                    pressOneKey()
                    task.wait(0.06 + (math.random() * 0.08))
                end
            end)
        else
            if keyAfkCoroutine then task.cancel(keyAfkCoroutine) end
        end
    end
})

GroupBox:AddToggle('BypassToggle', {
    Text = 'ANTI-CHEAT BYPASS',
    Default = false,
    Tooltip = '안티치트가 오작동하여 핵 감지 및 튕기는 현상을 우회하고 방지합니다.',
    Callback = function(Value) useAntiCheatBypass = Value end
})

FpsBox:AddToggle('FpsBoostToggle', {
    Text = 'FPS Boost (Unlock)',
    Default = false,
    Tooltip = '로블록스의 프레임 제한을 풀고 맵 그래픽 요소와 이펙트를 최적화하여 프레임을 대폭 올려줍니다.',
    Callback = function(Value)
        if Value then
            if setfpscap then setfpscap(999) elseif typeof(set_fps_cap) == "function" then set_fps_cap(999) end
            originalFpsSettings.GlobalShadows = Lighting.GlobalShadows
            originalFpsSettings.OutdoorAmbient = Lighting.OutdoorAmbient
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            if Terrain then
                originalFpsSettings.WaterWaveSize = Terrain.WaterWaveSize
                originalFpsSettings.WaterWaveSpeed = Terrain.WaterWaveSpeed
                originalFpsSettings.WaterReflectance = Terrain.WaterReflectance
                originalFpsSettings.WaterTransparency = Terrain.WaterTransparency
                Terrain.WaterWaveSize = 0; Terrain.WaterWaveSpeed = 0; Terrain.WaterReflectance = 0; Terrain.WaterTransparency = 0
            end
            fpsBoostConnection = Workspace.DescendantAdded:Connect(function(desc)
                task.wait()
                if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Smoke") or desc:IsA("Fire") or desc:IsA("Sparkles") then
                    desc.Enabled = false
                elseif desc:IsA("Explosion") then
                    desc.Visible = false
                elseif desc:IsA("Texture") or desc:IsA("Decal") then
                    desc.Texture = ""
                elseif desc:IsA("MeshPart") or (desc:IsA("BasePart") and not desc.Parent:FindFirstChildOfClass("Humanoid")) then
                    desc.Material = Enum.Material.SmoothPlastic
                    desc.Reflectance = 0
                end
            end)
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Smoke") or desc:IsA("Fire") or desc:IsA("Sparkles") then
                    desc.Enabled = false
                elseif desc:IsA("Explosion") then
                    desc.Visible = false
                elseif desc:IsA("Texture") or desc:IsA("Decal") then
                    desc.Texture = ""
                elseif desc:IsA("MeshPart") or (desc:IsA("BasePart") and not desc.Parent:FindFirstChildOfClass("Humanoid")) then
                    desc.Material = Enum.Material.SmoothPlastic
                    desc.Reflectance = 0
                end
            end
        else
            if setfpscap then setfpscap(60) elseif typeof(set_fps_cap) == "function" then set_fps_cap(60) end
            if fpsBoostConnection then fpsBoostConnection:Disconnect(); fpsBoostConnection = nil end
            if originalFpsSettings.GlobalShadows ~= nil then Lighting.GlobalShadows = originalFpsSettings.GlobalShadows end
            if originalFpsSettings.OutdoorAmbient ~= nil then Lighting.OutdoorAmbient = originalFpsSettings.OutdoorAmbient end
            if Terrain and originalFpsSettings.WaterWaveSize then
                Terrain.WaterWaveSize = originalFpsSettings.WaterWaveSize
                Terrain.WaterWaveSpeed = originalFpsSettings.WaterWaveSpeed
                Terrain.WaterReflectance = originalFpsSettings.WaterReflectance
                Terrain.WaterTransparency = originalFpsSettings.WaterTransparency
            end
        end
    end
})

TpBox:AddToggle('ClickTpToggle', {
    Text = 'Enable Ctrl + Click TP',
    Default = false,
    Tooltip = 'Ctrl 누른 채 마우스 클릭 시 해당 위치로 이동합니다.',
    Callback = function(Value) isClickTpEnabled = Value end
})

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and isClickTpEnabled then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            local mouse = LocalPlayer:GetMouse()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild('HumanoidRootPart')
            if root and mouse.Hit then
                root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end
    end
end)

MovementBox:AddToggle('NoclipToggle', {
    Text = 'Enable Noclip',
    Default = false,
    Tooltip = '벽과 바닥을 통과합니다.',
    Callback = function(Value)
        if Value then
            saveOriginalCollisions(LocalPlayer.Character)
            noclipConnection = RunService.Stepped:Connect(function()
                if LocalPlayer.Character then
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        else
            if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = originalCollisions[part] ~= nil and originalCollisions[part] or true
                    end
                end
            end
        end
    end
})

---------------------------------------------------------
-- [Visuals 탭] (완벽 수정된 ESP & 낭만적인 쉐이더 및 강도/색상 조절)
---------------------------------------------------------
local EspBox = Tabs.Visuals:AddLeftGroupbox('Player ESP')
local XrayBox = Tabs.Visuals:AddRightGroupbox('X-Ray & Object ESP')
local FreecamBox = Tabs.Visuals:AddRightGroupbox('Freecam')
local NameBox = Tabs.Visuals:AddLeftGroupbox('Custom UI Name Changer')
local VisualsEffectsBox = Tabs.Visuals:AddLeftGroupbox('Visuals & Shaders')

local function removeESPForPlayer(name)
    if espData[name] then
        pcall(function() espData[name].conn:Disconnect() end)
        pcall(function() espData[name].highlight:Destroy() end)
        pcall(function() espData[name].billboard:Destroy() end)
        espData[name] = nil
    end
end

local function removeAllESP()
    for name, _ in pairs(espData) do
        removeESPForPlayer(name)
    end
end

local function startESP(player)
    if player == LocalPlayer then return end
    removeESPForPlayer(player.Name)

    local function setupCharacterESP(char)
        if not char then return end
        local root = char:WaitForChild('HumanoidRootPart', 5)
        local hum = char:WaitForChild('Humanoid', 5)
        local head = char:WaitForChild('Head', 5)
        if not root or not hum or not head then return end

        removeESPForPlayer(player.Name)

        -- 1. 캐릭터 3D 외곽선 (Highlight) - Adornee를 캐릭터 모델 전체로 지정하여 정확하게 감쌈
        local highlight = Instance.new('Highlight')
        highlight.Name = 'Naberius_Highlight'
        highlight.Adornee = char
        highlight.FillTransparency = 0.75
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = getGuiParent()

        -- 2. 머리 위 이름 & 옆면 체력바 (BillboardGui) - Adornee를 HumanoidRootPart로 지정
        local billboard = Instance.new('BillboardGui')
        billboard.Name = 'Naberius_Billboard'
        billboard.Adornee = root
        billboard.Size = UDim2.new(4, 0, 5.5, 0)
        billboard.StudsOffset = Vector3.new(0, 0.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = getGuiParent()

        -- 머리 위 이름 레이블
        local nameLabel = Instance.new('TextLabel')
        nameLabel.Name = 'NameLabel'
        nameLabel.Size = UDim2.new(1.5, 0, 0.2, 0)
        nameLabel.Position = UDim2.new(-0.25, 0, -0.22, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.DisplayName .. ' (@' .. player.Name .. ')'
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.Parent = billboard

        -- 왼쪽 옆면 체력바 배경
        local hpBg = Instance.new('Frame')
        hpBg.Name = 'HpBg'
        hpBg.Size = UDim2.new(0.08, 0, 0.9, 0)
        hpBg.Position = UDim2.new(-0.15, 0, 0.05, 0)
        hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        hpBg.BorderSizePixel = 0
        hpBg.Parent = billboard

        -- 실시간 체력바 게이지
        local hpBar = Instance.new('Frame')
        hpBar.Name = 'HpBar'
        hpBar.Size = UDim2.new(1, 0, 1, 0)
        hpBar.Position = UDim2.new(0, 0, 1, 0)
        hpBar.AnchorPoint = Vector2.new(0, 1)
        hpBar.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        hpBar.BorderSizePixel = 0
        hpBar.Parent = hpBg

        -- 실시간 렌더링 동기화 루프 (색상 및 체력바 실시간 반영)
        local conn = RunService.RenderStepped:Connect(function()
            if not isEspRunning or not char.Parent or hum.Health <= 0 then
                highlight.Enabled = false
                billboard.Enabled = false
                return
            end

            highlight.Enabled = true
            billboard.Enabled = true

            local col = Options['ESPColor'] and Options['ESPColor'].Value or Color3.fromRGB(255, 0, 0)
            highlight.FillColor = col
            highlight.OutlineColor = col

            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            hpBar.Size = UDim2.new(1, 0, pct, 0)
            hpBar.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - pct)), math.floor(255 * pct), 50)
        end)

        espData[player.Name] = {
            highlight = highlight,
            billboard = billboard,
            conn = conn
        }
    end

    if player.Character then
        task.spawn(setupCharacterESP, player.Character)
    end

    player.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        if isEspRunning then
            setupCharacterESP(newChar)
        end
    end)
end

EspBox:AddToggle('EspToggle', {
    Text = 'Enable ESP',
    Default = false,
    Tooltip = '플레이어의 3D 외곽선 테두리, 이름, 체력바를 투시합니다.',
    Callback = function(Value)
        isEspRunning = Value
        if Value then
            for _, player in ipairs(Players:GetPlayers()) do
                startESP(player)
            end
        else
            removeAllESP()
        end
    end
}):AddColorPicker('ESPColor', {
    Title = 'ESP Outline Color',
    Default = Color3.fromRGB(255, 0, 0),
})

Players.PlayerAdded:Connect(function(player)
    startESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESPForPlayer(player.Name)
end)

XrayBox:AddToggle('XrayToggle', {
    Text = 'Enable X-Ray',
    Default = false,
    Tooltip = '맵의 벽을 투명하게 만듭니다.',
    Callback = function(Value)
        isXrayRunning = Value
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("BasePart") and not desc.Parent:FindFirstChildOfClass("Humanoid") then
                if Value then
                    if not originalTransparencies[desc] then originalTransparencies[desc] = desc.Transparency end
                    desc.Transparency = 0.6
                else
                    if originalTransparencies[desc] then desc.Transparency = originalTransparencies[desc] end
                end
            end
        end
    end
})

XrayBox:AddToggle('ObjectEspToggle', {
    Text = 'Enable Object ESP',
    Default = false,
    Tooltip = 'E키 상호작용 오브젝트 투시',
    Callback = function(Value)
        isObjectEspRunning = Value
        if not Value then
            for _, item in ipairs(objectEspContainer) do if item then item:Destroy() end end
            objectEspContainer = {}
        else
            task.spawn(function()
                while isObjectEspRunning do
                    for _, item in ipairs(objectEspContainer) do if item then item:Destroy() end end
                    objectEspContainer = {}
                    
                    for _, desc in ipairs(Workspace:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") then
                            local part = desc.Parent
                            if part and (part:IsA("BasePart") or part:IsA("Model")) then
                                local targetPart = part:IsA("Model") and (part.PrimaryPart or part:FindFirstChildWhichIsA("BasePart")) or part
                                if targetPart then
                                    local h = Instance.new("Highlight")
                                    h.FillColor = Color3.fromRGB(0, 255, 180)
                                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                                    h.FillTransparency = 0.5
                                    h.OutlineTransparency = 0
                                    h.Adornee = part
                                    h.Parent = targetPart
                                    
                                    local bg = Instance.new("BillboardGui")
                                    bg.AlwaysOnTop = true
                                    bg.Size = UDim2.new(0, 200, 0, 60)
                                    bg.StudsOffset = Vector3.new(0, 2.5, 0)
                                    bg.Adornee = targetPart
                                    bg.Parent = targetPart
                                    
                                    local tl = Instance.new("TextLabel", bg)
                                    tl.Size = UDim2.new(1, 0, 1, 0)
                                    tl.BackgroundTransparency = 1
                                    tl.TextColor3 = Color3.fromRGB(0, 255, 255)
                                    tl.TextStrokeTransparency = 0
                                    tl.TextStrokeColor3 = Color3.new(0, 0, 0)
                                    tl.Font = Enum.Font.SourceSansBold
                                    tl.TextSize = 14
                                    tl.Text = string.format("[%s] %s\n(%s)", desc.KeyboardKeyCode.Name or "E", desc.ObjectText ~= "" and desc.ObjectText or part.Name, desc.ActionText ~= "" and desc.ActionText or "상호작용")
                                    
                                    table.insert(objectEspContainer, h)
                                    table.insert(objectEspContainer, bg)
                                end
                            end
                        end
                    end
                    task.wait(5)
                end
            end)
        end
    end
})

FreecamBox:AddToggle('FreecamToggle', {
    Text = 'Enable Freecam',
    Default = false,
    Tooltip = '자유 카메라 이동',
    Callback = function(Value)
        isFreecamRunning = Value
        local camera = Workspace.CurrentCamera
        if Value then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Anchored = true
            end
            camera.CameraType = Enum.CameraType.Scriptable
            camPosition = camera.CFrame.Position
            targetPosition = camPosition
            local yaw, pitch, _ = camera.CFrame:ToEulerAnglesYXZ()
            cameraYaw, cameraPitch, targetYaw, targetPitch = yaw, pitch, yaw, pitch
            freecamFov, targetFov = 70, 70
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            
            freecamConnection = RunService.RenderStepped:Connect(function(dt)
                local delta = UserInputService:GetMouseDelta()
                targetYaw = targetYaw - (delta.X * 0.002)
                targetPitch = math.clamp(targetPitch - (delta.Y * 0.002), math.rad(-88), math.rad(88))
                local lerpFactor = math.clamp(1 - math.exp(-15 * dt), 0, 1)
                cameraYaw = cameraYaw + (targetYaw - cameraYaw) * lerpFactor
                cameraPitch = cameraPitch + (targetPitch - cameraPitch) * lerpFactor
                local currentRotCFrame = CFrame.Angles(0, cameraYaw, 0) * CFrame.Angles(cameraPitch, 0, 0)
                local moveVector = Vector3.new(0, 0, 0)
                local speed = 75 * dt
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + currentRotCFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - currentRotCFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - currentRotCFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + currentRotCFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, 1, 0) end
                if moveVector.Magnitude > 0 then targetPosition = targetPosition + (moveVector.Unit * speed) end
                camPosition = camPosition:Lerp(targetPosition, lerpFactor)
                freecamFov = freecamFov + (targetFov - freecamFov) * lerpFactor
                camera.CFrame = CFrame.new(camPosition) * currentRotCFrame
                camera.FieldOfView = freecamFov
            end)
        else
            if freecamConnection then freecamConnection:Disconnect(); freecamConnection = nil end
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
            end
            camera.CameraType = Enum.CameraType.Custom
            camera.FieldOfView = 70
        end
    end
})

UserInputService.InputChanged:Connect(function(input)
    if not isFreecamRunning then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        targetFov = math.clamp(targetFov + (input.Position.Z > 0 and -6 or 6), 10, 120)
    end
end)

NameBox:AddInput('NameChangeInput', {
    Text = 'Client Fake Nickname',
    Default = '',
    Finished = true,
    Tooltip = '머리 위 닉네임 변조',
    Callback = function(Value) customName = Value end
})

RunService.RenderStepped:Connect(function()
    if customName ~= "" and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if (v:IsA("TextLabel") or v:IsA("TextBox")) and v.Text ~= customName then
                v.Text = customName
            end
        end
    end
end)

-- 낭만적이고 선명한 고품질 시네마틱 쉐이더
VisualsEffectsBox:AddToggle('ShaderToggle', {
    Text = 'Custom Shader (낭만 시네마틱)',
    Default = false,
    Tooltip = '화면을 감성적이고 선명한 고품질 쉐이더 색감으로 보정합니다.',
    Callback = function(val)
        if val then
            customColorCorrEffect = Instance.new("ColorCorrectionEffect")
            customColorCorrEffect.Brightness = 0.08
            customColorCorrEffect.Contrast = 0.25
            customColorCorrEffect.Saturation = 0.2
            customColorCorrEffect.TintColor = Color3.fromRGB(255, 240, 220)
            customColorCorrEffect.Parent = Lighting
        else
            if customColorCorrEffect then customColorCorrEffect:Destroy(); customColorCorrEffect = nil end
        end
    end
})

-- 광채(Bloom) 효과 (강도 1~10 및 색상 조절 추가)
VisualsEffectsBox:AddToggle('BloomToggle', {
    Text = 'Custom Bloom (광채 효과)',
    Default = false,
    Tooltip = '화면의 밝은 부분에 낭만적인 광채 효과를 부여합니다.',
    Callback = function(val)
        if val then
            customBloomEffect = Instance.new("BloomEffect")
            local intensityVal = Options['BloomIntensity'] and Options['BloomIntensity'].Value or 5
            customBloomEffect.Intensity = (intensityVal / 10) * 1.2
            customBloomEffect.Size = 32
            customBloomEffect.Threshold = 0.6
            customBloomEffect.Parent = Lighting
        else
            if customBloomEffect then customBloomEffect:Destroy(); customBloomEffect = nil end
        end
    end
}):AddColorPicker('BloomColor', {
    Title = 'Bloom Color',
    Default = Color3.fromRGB(255, 255, 255),
})

VisualsEffectsBox:AddSlider('BloomIntensity', {
    Text = 'Bloom Intensity (강도)',
    Default = 5, Min = 1, Max = 10, Rounding = 0,
    Tooltip = '광채 효과의 세기를 1부터 10까지 조절합니다.',
    Callback = function(val)
        if customBloomEffect then
            customBloomEffect.Intensity = (val / 10) * 1.2
        end
    end
})

-- 네온 조명 효과 (강도 1~10 및 색상 조절 추가)
VisualsEffectsBox:AddToggle('NeonLightingToggle', {
    Text = 'Neon Environment (네온 조명)',
    Default = false,
    Tooltip = '맵 전체에 화려하고 낭만적인 네온 색감을 적용합니다.',
    Callback = function(val)
        if val then
            originalLightingSettings.Ambient = Lighting.Ambient
            originalLightingSettings.OutdoorAmbient = Lighting.OutdoorAmbient
            local neonCol = Options['NeonColor'] and Options['NeonColor'].Value or Color3.fromRGB(120, 60, 200)
            local neonInt = Options['NeonIntensity'] and Options['NeonIntensity'].Value or 5
            local mult = (neonInt / 10) * 0.8
            Lighting.Ambient = Color3.new(neonCol.R * mult, neonCol.G * mult, neonCol.B * mult)
            Lighting.OutdoorAmbient = Lighting.Ambient
        else
            Lighting.Ambient = originalLightingSettings.Ambient
            Lighting.OutdoorAmbient = originalLightingSettings.OutdoorAmbient
        end
    end
}):AddColorPicker('NeonColor', {
    Title = 'Neon Color',
    Default = Color3.fromRGB(120, 60, 200),
})

VisualsEffectsBox:AddSlider('NeonIntensity', {
    Text = 'Neon Intensity (강도)',
    Default = 5, Min = 1, Max = 10, Rounding = 0,
    Tooltip = '네온 조명의 세기를 1부터 10까지 조절합니다.',
    Callback = function(val)
        if Toggles['NeonLightingToggle'] and Toggles['NeonLightingToggle'].Value then
            local neonCol = Options['NeonColor'] and Options['NeonColor'].Value or Color3.fromRGB(120, 60, 200)
            local mult = (val / 10) * 0.8
            Lighting.Ambient = Color3.new(neonCol.R * mult, neonCol.G * mult, neonCol.B * mult)
            Lighting.OutdoorAmbient = Lighting.Ambient
        end
    end
})

-- 실시간 네온 컬러 피커 연동
Options['NeonColor']:OnChanged(function()
    if Toggles['NeonLightingToggle'] and Toggles['NeonLightingToggle'].Value then
        local neonCol = Options['NeonColor'].Value
        local neonInt = Options['NeonIntensity'] and Options['NeonIntensity'].Value or 5
        local mult = (neonInt / 10) * 0.8
        Lighting.Ambient = Color3.new(neonCol.R * mult, neonCol.G * mult, neonCol.B * mult)
        Lighting.OutdoorAmbient = Lighting.Ambient
    end
end)

---------------------------------------------------------
-- [Avatar 탭]
---------------------------------------------------------
local AvatarBox = Tabs.Avatar:AddLeftGroupbox('Avatar & Customizer')

AvatarBox:AddButton('Apply Korblox', function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.RigType == Enum.HumanoidRigType.R15 then
        local desc = hum:GetAppliedDescription()
        desc.RightLeg = 139607718
        hum:ApplyDescription(desc)
        Library:Notify('코블록스 다리 적용 완료!')
    else
        Library:Notify('R15 캐릭터에서만 지원됩니다.')
    end
end)

AvatarBox:AddButton('Apply Headless', function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.RigType == Enum.HumanoidRigType.R15 then
        local desc = hum:GetAppliedDescription()
        desc.Head = 15093053680
        hum:ApplyDescription(desc)
        Library:Notify('헤드리스 적용 완료!')
    else
        if char:FindFirstChild("Head") then
            char.Head.Transparency = 1
            if char.Head:FindFirstChild("face") then char.Head.face:Destroy() end
        end
        Library:Notify('R6 헤드리스(투명화) 완료!')
    end
end)

AvatarBox:AddInput('CustomItemIdInput', {
    Text = 'Custom Item Asset ID',
    Default = '',
    Numeric = true,
    Finished = false,
    Tooltip = '장착할 아이템 고유 숫자 ID 입력',
    Placeholder = '예: 6299298580',
    Callback = function() end
})

AvatarBox:AddButton('Apply Custom Item ID', function()
    local id = tonumber(Options['CustomItemIdInput'] and Options['CustomItemIdInput'].Value or '')
    if not id then Library:Notify('유효한 아이템 ID를 입력하세요!'); return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function()
        local desc = hum:GetAppliedDescription()
        local accessories = desc:GetAccessories(true)
        table.insert(accessories, { AssetId = id, AccessoryType = Enum.AccessoryType.Hat, IsLayered = false })
        desc:SetAccessories(accessories, true)
        hum:ApplyDescription(desc)
        Library:Notify('아이템 ID ' .. id .. ' 장착 완료!')
    end)
end)

AvatarBox:AddInput('CopyUserIdInput', {
    Text = 'Target User ID (아바타 복사)',
    Default = '',
    Numeric = true,
    Finished = false,
    Tooltip = '복사할 플레이어의 User ID 입력',
    Placeholder = '예: 123456789',
    Callback = function() end
})

AvatarBox:AddButton('Copy Player Avatar', function()
    local targetId = tonumber(Options['CopyUserIdInput'] and Options['CopyUserIdInput'].Value or '')
    if not targetId then Library:Notify('유효한 User ID를 입력하세요!'); return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(targetId) end)
    if ok and desc then
        pcall(function() hum:ApplyDescription(desc) end)
        Library:Notify('플레이어 아바타 복사 완료!')
    else
        Library:Notify('아바타 정보를 불러오지 못했습니다.')
    end
end)

---------------------------------------------------------
-- [Settings 탭]
---------------------------------------------------------
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

local SettingsGroupBox = Tabs.Settings:AddLeftGroupbox('Menu Settings')

SettingsGroupBox:AddKeybind('MenuKeybind', { 
    Default = 'RightShift', 
    Mode = 'Toggle', 
    NoUI = true, 
    Text = 'Menu Toggle' 
})

SettingsGroupBox:AddButton('Unload Script', function() Library:Unload() end)
SaveManager:LoadAutoloadConfig()
Library:Notify('Naberius 로드 완료!')
