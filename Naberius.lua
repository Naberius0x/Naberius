-- Naberius Script
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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
local antiAfkJumpConn
local antiAfkKeyConn

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
                    if char then
                        local hum = char:FindFirstChildOfClass('Humanoid')
                        if hum then hum.Jump = true end
                    end
                end
            end)
        end
    end
})

AntiAfkBox:AddToggle('AntiAfkKey', {
    Text = 'Anti AFK (Key)',
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
                        game:GetService('VirtualInputManager'):SendKeyEvent(true, Enum.KeyCode.One, false, game)
                        game:GetService('VirtualInputManager'):SendKeyEvent(false, Enum.KeyCode.One, false, game)
                    end)
                end
            end)
        end
    end
})

-- FPS Boost
local FpsBox = MainTab:AddLeftGroupbox('FPS Boost')

FpsBox:AddToggle('FpsBoost', {
    Text = 'FPS Boost',
    Default = false,
    Callback = function(val)
        if val then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            pcall(function() Workspace.StreamingEnabled = false end)
            pcall(function()
                for _, v in pairs(Lighting:GetChildren()) do
                    if v:IsA('BlurEffect') or v:IsA('DepthOfFieldEffect')
                    or v:IsA('SunRaysEffect') or v:IsA('BloomEffect')
                    or v:IsA('ColorCorrectionEffect') then v.Enabled = false end
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
                    or v:IsA('ColorCorrectionEffect') then v.Enabled = true end
                end
                Lighting.GlobalShadows = true
            end)
        end
    end
})

FpsBox:AddSlider('FpsCap', {
    Text = 'FPS Cap',
    Default = 60, Min = 30, Max = 240, Rounding = 0,
    Callback = function(val)
        pcall(function() setfpscap(val) end)
    end
})

-- Teleport
local TpBox = MainTab:AddRightGroupbox('Teleport')

TpBox:AddToggle('CtrlClickTp', {
    Text = 'Ctrl + Click TP',
    Default = false,
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
    if hit then root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) end
end)

-- Movement
local MoveBox = MainTab:AddRightGroupbox('Movement')
local noclipConn
local godConn

MoveBox:AddToggle('Noclip', {
    Text = 'Noclip',
    Default = false,
    Callback = function(val)
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        if val then
            noclipConn = RunService.Stepped:Connect(function()
                local char = Player.Character
                if not char then return end
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA('BasePart') then part.CanCollide = false end
                end
            end)
        else
            local char = Player.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA('BasePart') then part.CanCollide = true end
                end
            end
        end
    end
})

MoveBox:AddToggle('GodMode', {
    Text = 'God Mode',
    Default = false,
    Callback = function(val)
        if godConn then godConn:Disconnect(); godConn = nil end
        if val then
            godConn = RunService.Heartbeat:Connect(function()
                local char = Player.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass('Humanoid')
                if hum then hum.Health = hum.MaxHealth end
            end)
        end
    end
})

-- ─────────────────────────────────────────
-- VISUALS TAB
-- ─────────────────────────────────────────
local VisLeft  = VisualsTab:AddLeftGroupbox('Player ESP')
local VisRight = VisualsTab:AddRightGroupbox('Object ESP')
local VisFree  = VisualsTab:AddLeftGroupbox('Freecam')

-- ── PLAYER ESP (박스 + 체력바 + 이름) ──────
local espFolder = Instance.new('Folder')
espFolder.Name = 'NaberiusESP'
espFolder.Parent = CoreGui

local espConnections = {}
local ESP_COLOR = Color3.fromRGB(255, 50, 50)

local function removeAllESP()
    for _, c in pairs(espConnections) do pcall(function() c:Disconnect() end) end
    espConnections = {}
    for _, v in pairs(espFolder:GetChildren()) do v:Destroy() end
end

local function getScreenPos(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), screenPos.Z, onScreen
end

local function drawBox(player)
    if player == Player then return end

    local conn = RunService.RenderStepped:Connect(function()
        if not Toggles['PlayerESP'] or not Toggles['PlayerESP'].Value then return end

        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild('HumanoidRootPart')
        local hum = char:FindFirstChildOfClass('Humanoid')
        if not root or not hum or hum.Health <= 0 then return end

        -- 박스 계산
        local topPos = root.Position + Vector3.new(0, 2.8, 0)
        local botPos = root.Position - Vector3.new(0, 3.2, 0)

        local top, topDist, topOn = getScreenPos(topPos)
        local bot, botDist, botOn = getScreenPos(botPos)

        if not topOn and not botOn then
            -- 화면 밖이면 GUI 숨기기
            local gui = espFolder:FindFirstChild('ESP_' .. player.Name)
            if gui then gui.Enabled = false end
            return
        end

        local height = math.abs(bot.Y - top.Y)
        local width = height * 0.5

        local centerX = (top.X + bot.X) / 2
        local centerY = (top.Y + bot.Y) / 2

        -- GUI 생성 or 가져오기
        local gui = espFolder:FindFirstChild('ESP_' .. player.Name)
        if not gui then
            gui = Instance.new('ScreenGui')
            gui.Name = 'ESP_' .. player.Name
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            gui.Parent = espFolder

            -- 박스 (4개 선)
            for i = 1, 4 do
                local line = Instance.new('Frame')
                line.Name = 'Line' .. i
                line.BackgroundColor3 = ESP_COLOR
                line.BorderSizePixel = 0
                line.Parent = gui
            end

            -- 이름 라벨
            local nameLabel = Instance.new('TextLabel')
            nameLabel.Name = 'NameLabel'
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextStrokeTransparency = 0
            nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 13
            nameLabel.Text = player.Name
            nameLabel.Size = UDim2.new(0, 100, 0, 16)
            nameLabel.Parent = gui

            -- 체력바 배경
            local hpBg = Instance.new('Frame')
            hpBg.Name = 'HpBg'
            hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            hpBg.BorderSizePixel = 0
            hpBg.Parent = gui

            -- 체력바
            local hpBar = Instance.new('Frame')
            hpBar.Name = 'HpBar'
            hpBar.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
            hpBar.BorderSizePixel = 0
            hpBar.Parent = hpBg
        end

        gui.Enabled = true

        -- 박스 색상 업데이트
        local color = Options['ESPColor'] and Options['ESPColor'].Value or ESP_COLOR
        for i = 1, 4 do
            local line = gui:FindFirstChild('Line' .. i)
            if line then line.BackgroundColor3 = color end
        end

        local thick = 1.5
        local left   = centerX - width / 2
        local right  = centerX + width / 2
        local topY   = centerY - height / 2
        local botY   = centerY + height / 2

        -- Top
        local l1 = gui:FindFirstChild('Line1')
        if l1 then
            l1.Position = UDim2.new(0, left, 0, topY)
            l1.Size = UDim2.new(0, width, 0, thick)
        end
        -- Bottom
        local l2 = gui:FindFirstChild('Line2')
        if l2 then
            l2.Position = UDim2.new(0, left, 0, botY)
            l2.Size = UDim2.new(0, width, 0, thick)
        end
        -- Left
        local l3 = gui:FindFirstChild('Line3')
        if l3 then
            l3.Position = UDim2.new(0, left, 0, topY)
            l3.Size = UDim2.new(0, thick, 0, height)
        end
        -- Right
        local l4 = gui:FindFirstChild('Line4')
        if l4 then
            l4.Position = UDim2.new(0, right, 0, topY)
            l4.Size = UDim2.new(0, thick, 0, height)
        end

        -- 이름 라벨 위치
        local nameLabel = gui:FindFirstChild('NameLabel')
        if nameLabel then
            nameLabel.Position = UDim2.new(0, centerX - 50, 0, topY - 18)
        end

        -- 체력바
        local hpBg = gui:FindFirstChild('HpBg')
        local hpBar = hpBg and hpBg:FindFirstChild('HpBar')
        if hpBg and hpBar then
            local barW = 4
            hpBg.Position = UDim2.new(0, left - barW - 2, 0, topY)
            hpBg.Size = UDim2.new(0, barW, 0, height)

            local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local r = math.floor(255 * (1 - hpPct))
            local g = math.floor(255 * hpPct)
            hpBar.BackgroundColor3 = Color3.fromRGB(r, g, 0)
            hpBar.Size = UDim2.new(1, 0, hpPct, 0)
            hpBar.Position = UDim2.new(0, 0, 1 - hpPct, 0)
        end
    end)

    table.insert(espConnections, conn)

    -- 플레이어 나가면 ESP 제거
    player.AncestryChanged:Connect(function()
        local gui = espFolder:FindFirstChild('ESP_' .. player.Name)
        if gui then gui:Destroy() end
    end)
end

VisLeft:AddToggle('PlayerESP', {
    Text = 'Enable Player ESP',
    Default = false,
    Callback = function(val)
        if val then
            for _, p in pairs(Players:GetPlayers()) do
                drawBox(p)
            end
        else
            removeAllESP()
        end
    end
})

VisLeft:AddColorpicker('ESPColor', {
    Title = 'ESP Box Color',
    Default = Color3.fromRGB(255, 50, 50),
})

Players.PlayerAdded:Connect(function(p)
    if Toggles['PlayerESP'] and Toggles['PlayerESP'].Value then
        p.CharacterAdded:Connect(function()
            task.wait(1)
            drawBox(p)
        end)
    end
end)

-- ── OBJECT ESP (박스 테두리 + 이름 + 설명) ──
local objEspFolder = Instance.new('Folder')
objEspFolder.Name = 'NaberiusObjESP'
objEspFolder.Parent = CoreGui

local objEspLastScan = 0
local OBJ_ESP_INTERVAL = 15
local objEspConns = {}

local function removeObjectESP()
    for _, c in pairs(objEspConns) do pcall(function() c:Disconnect() end) end
    objEspConns = {}
    for _, v in pairs(objEspFolder:GetChildren()) do v:Destroy() end
end

local function createObjESP(adornPart, actionText, objectText)
    local gui = Instance.new('ScreenGui')
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = objEspFolder

    -- 박스 4선
    for i = 1, 4 do
        local line = Instance.new('Frame')
        line.Name = 'Line' .. i
        line.BackgroundColor3 = Color3.fromRGB(255, 220, 50)
        line.BorderSizePixel = 0
        line.Parent = gui
    end

    -- 이름 라벨
    local nameLabel = Instance.new('TextLabel')
    nameLabel.Name = 'NameLabel'
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Text = actionText
    nameLabel.Size = UDim2.new(0, 160, 0, 16)
    nameLabel.Parent = gui

    -- 설명 라벨
    local descLabel = Instance.new('TextLabel')
    descLabel.Name = 'DescLabel'
    descLabel.BackgroundTransparency = 1
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextStrokeTransparency = 0
    descLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 11
    descLabel.Text = objectText
    descLabel.Size = UDim2.new(0, 160, 0, 14)
    descLabel.Parent = gui

    local conn = RunService.RenderStepped:Connect(function()
        if not Toggles['ObjectESP'] or not Toggles['ObjectESP'].Value then return end
        if not adornPart or not adornPart.Parent then
            gui:Destroy()
            return
        end

        local size = adornPart.Size
        local cf = adornPart.CFrame

        -- 8 코너 계산 → 스크린 최소/최대 XY
        local corners = {
            cf * CFrame.new( size.X/2,  size.Y/2,  size.Z/2),
            cf * CFrame.new(-size.X/2,  size.Y/2,  size.Z/2),
            cf * CFrame.new( size.X/2, -size.Y/2,  size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2,  size.Z/2),
            cf * CFrame.new( size.X/2,  size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2,  size.Y/2, -size.Z/2),
            cf * CFrame.new( size.X/2, -size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
        }

        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local anyOnScreen = false

        for _, c in pairs(corners) do
            local sp, depth, onScreen = Camera:WorldToViewportPoint(c.Position)
            if depth > 0 then
                anyOnScreen = true
                if sp.X < minX then minX = sp.X end
                if sp.Y < minY then minY = sp.Y end
                if sp.X > maxX then maxX = sp.X end
                if sp.Y > maxY then maxY = sp.Y end
            end
        end

        if not anyOnScreen then
            gui.Enabled = false
            return
        end

        gui.Enabled = true

        local thick = 1.5
        local w = maxX - minX
        local h = maxY - minY

        -- Top
        local l1 = gui:FindFirstChild('Line1')
        if l1 then l1.Position = UDim2.new(0, minX, 0, minY); l1.Size = UDim2.new(0, w, 0, thick) end
        -- Bottom
        local l2 = gui:FindFirstChild('Line2')
        if l2 then l2.Position = UDim2.new(0, minX, 0, maxY); l2.Size = UDim2.new(0, w, 0, thick) end
        -- Left
        local l3 = gui:FindFirstChild('Line3')
        if l3 then l3.Position = UDim2.new(0, minX, 0, minY); l3.Size = UDim2.new(0, thick, 0, h) end
        -- Right
        local l4 = gui:FindFirstChild('Line4')
        if l4 then l4.Position = UDim2.new(0, maxX, 0, minY); l4.Size = UDim2.new(0, thick, 0, h) end

        -- 라벨 위치
        local nl = gui:FindFirstChild('NameLabel')
        if nl then nl.Position = UDim2.new(0, minX, 0, minY - 20) end
        local dl = gui:FindFirstChild('DescLabel')
        if dl then dl.Position = UDim2.new(0, minX, 0, minY - 34) end
    end)

    table.insert(objEspConns, conn)
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

            local actionText = obj.ActionText ~= '' and ('[E] ' .. obj.ActionText) or ('[E] ' .. parent.Name)
            local objectText = obj.ObjectText ~= '' and obj.ObjectText or parent.Name

            createObjESP(adornPart, actionText, objectText)
        end
    end
end

VisRight:AddToggle('ObjectESP', {
    Text = 'Enable Object ESP',
    Default = false,
    Callback = function(val)
        if val then scanObjectESP() else removeObjectESP() end
    end
})

RunService.Heartbeat:Connect(function()
    if Toggles['ObjectESP'] and Toggles['ObjectESP'].Value then
        local now = tick()
        if now - objEspLastScan >= OBJ_ESP_INTERVAL then
            objEspLastScan = now
            scanObjectESP()
        end
    end
end)

-- ── X-RAY ─────────────────────────────────
local xrayOriginals = {}

local function applyXray()
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA('BasePart') then
            local plrChar = false
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and part:IsDescendantOf(p.Character) then plrChar = true; break end
            end
            if not plrChar then
                xrayOriginals[part] = { Transparency = part.Transparency, Material = part.Material }
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
    Callback = function(val)
        if val then applyXray() else removeXray() end
    end
})

-- ── FREECAM ───────────────────────────────
local freecamPart
local freecamConn
local FREECAM_SPEED = 30

VisFree:AddToggle('Freecam', {
    Text = 'Enable Freecam',
    Default = false,
    Tooltip = 'WASD + Q/E로 카메라 자유 이동',
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
    Default = 30, Min = 5, Max = 200, Rounding = 0,
    Callback = function(val) FREECAM_SPEED = val end
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
    if useKorblox then desc.RightLeg = 139607718 else desc.RightLeg = 0 end
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
    Text = 'Korblox',
    Default = false,
    Callback = function(val) korbloxOn = val; applyKorbloxHeadless(korbloxOn, headlessOn) end
})

AvLeft:AddToggle('Headless', {
    Text = 'Headless',
    Default = false,
    Callback = function(val) headlessOn = val; applyKorbloxHeadless(korbloxOn, headlessOn) end
})

AvLeft:AddInput('CopyAvatarId', {
    Default = '', Numeric = true, Finished = false,
    Text = 'User ID로 아바타 복사',
    Placeholder = '예: 123456789',
    Callback = function(val) end
})

AvLeft:AddButton({
    Text = '아바타 적용',
    Callback = function()
        local idStr = Options['CopyAvatarId'] and Options['CopyAvatarId'].Value or ''
        local userId = tonumber(idStr)
        if not userId then Library:Notify('유효한 User ID를 입력하세요!', 3); return end
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass('Humanoid')
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
    Callback = function(val)
        local char = Player.Character
        if not char then return end
        if val then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA('BasePart') or part:IsA('Decal') then part.Transparency = 1 end
            end
            if invisConn then invisConn:Disconnect() end
            invisConn = Player.CharacterAdded:Connect(function(newChar)
                task.wait(0.5)
                for _, part in pairs(newChar:GetDescendants()) do
                    if part:IsA('BasePart') or part:IsA('Decal') then part.Transparency = 1 end
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

-- ─────────────────────────────────────────
-- SETTINGS TAB
-- ─────────────────────────────────────────
local SetLeft  = SettingsTab:AddLeftGroupbox('Keybinds')
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
