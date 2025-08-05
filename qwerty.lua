-- TWEEN TO BASE WITH WEB SLINGER INTEGRATION BY WALVY v2 FINAL
-- Walvy Comunity - STEAL A BRAINROT

(function()

if getgenv().TweenToBaseCleanup then
    getgenv().TweenToBaseCleanup()
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local player = LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local function buyItem(itemName)
    pcall(function()
        ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")
        :WaitForChild("RF/CoinsShopService/RequestBuy"):InvokeServer(itemName)
    end)
end

local function toggleSpeedCoilEquip()
    local backpack = player:WaitForChild("Backpack")
    local char = player.Character or player.CharacterAdded:Wait()
    local equipped = char:FindFirstChild("Speed Coil")
    if equipped then
        equipped.Parent = backpack
    else
        local coil = backpack:FindFirstChild("Speed Coil")
        if coil then
            coil.Parent = char
        end
    end
end

local function buyAndEquipSpeedCoil()
    buyItem("Speed Coil")
    task.wait(1)
    toggleSpeedCoilEquip()
end

buyAndEquipSpeedCoil()

player.CharacterAdded:Connect(function(c)
    character = c
    hrp = c:WaitForChild("HumanoidRootPart")
    humanoid = c:WaitForChild("Humanoid")
end)

local healthConn
local function applyAntiDeath(state)
    if humanoid then
        for _, s in ipairs({
            Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.PlatformStanding,
            Enum.HumanoidStateType.Seated
        }) do
            humanoid:SetStateEnabled(s, not not state)
        end
        if state then
            humanoid.Health = humanoid.MaxHealth
            if healthConn then healthConn:Disconnect() end
            healthConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if humanoid.Health <= 0 then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
        else
            if healthConn then healthConn:Disconnect() end
        end
    end
end

local float = Instance.new("BodyVelocity")
float.MaxForce = Vector3.new(1e6, 1e6, 1e6)
float.Velocity = Vector3.new(0, 0, 0)

local lastStandingPosition = nil
local lastStandingCFrame = nil

-- Simpan posisi saat karakter masih berdiri normal
RunService.Heartbeat:Connect(function()
    if character and humanoid and hrp then
        local state = humanoid:GetState()
        if state ~= Enum.HumanoidStateType.FallingDown
            and state ~= Enum.HumanoidStateType.Ragdoll
            and state ~= Enum.HumanoidStateType.PlatformStanding
            and state ~= Enum.HumanoidStateType.Seated then
            lastStandingPosition = hrp.Position
            lastStandingCFrame = hrp.CFrame
        end
    end
end)

-- Recovery otomatis jika terjatuh
humanoid.StateChanged:Connect(function(old, new)
    if new == Enum.HumanoidStateType.FallingDown
    or new == Enum.HumanoidStateType.Ragdoll
    or new == Enum.HumanoidStateType.PlatformStanding then
        task.wait(0.3)
        if character and humanoid and hrp then
            humanoid.PlatformStand = false
            if lastStandingCFrame then
                hrp.CFrame = lastStandingCFrame + Vector3.new(0, 3, 0)
            end
            task.delay(0.2, function()
                executeWebSlinger()
            end)
        end
    end
end)

local itemID = "Web Slinger"
local webSlingerActive = false
local webSlingerThread

local function hasTool()
    local Backpack = LocalPlayer:WaitForChild("Backpack")
    return Backpack:FindFirstChild(itemID)
        or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(itemID))
end

local function getRemote()
    return ReplicatedStorage:FindFirstChild("Packages")
        and ReplicatedStorage.Packages:FindFirstChild("Net")
        and ReplicatedStorage.Packages.Net:FindFirstChild("RE/UseItem")
end

local function createDummyBehind()
    local char = LocalPlayer.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then return nil end

    char.Archivable = true
    local clone = char:Clone()
    clone.Name = "DummyClone"
    clone.Parent = workspace

    local root = clone:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 4, 5)
        for _, p in ipairs(clone:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Anchored = false
                p.CanCollide = false
                p.Transparency = 1
            elseif p:IsA("Decal") then
                p.Transparency = 1
            end
        end
    end
    local hum = clone:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end

    return root
end

local function fireWebSlinger()
    local tool = hasTool()
    if not tool then return end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and tool.Parent ~= character then
        humanoid:EquipTool(tool)
        task.wait(0.3)
    end

    local remote = getRemote()
    if not remote then return end

    local handle = tool:FindFirstChildWhichIsA("BasePart")
    if not handle then return end

    local dummy = createDummyBehind()
    if not dummy then return end

    remote:FireServer(dummy.Position, handle, dummy)
    task.wait(0.2)
    dummy.Parent:Destroy()
end

local function executeWebSlinger()
    if not hasTool() then
        buyItem(itemID)
        task.wait(1.5)
    end

    if hasTool() then
        fireWebSlinger()
    end
end

local gui = player:WaitForChild("PlayerGui"):FindFirstChild("WalvyWalkGui")
if gui then gui:Destroy() end

gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "WalvyWalkGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 180)
frame.Position = UDim2.new(0.5, -120, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.AnchorPoint = Vector2.new(0.5, 0.5)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", frame)
title.Text = "Walvy Comunity"
title.Size = UDim2.new(1, 0, 0, 20)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local tweenButton = Instance.new("TextButton", frame)
tweenButton.Text = "▶ START TWEEN TO BASE"
tweenButton.Size = UDim2.new(0.8, 0, 0, 40)
tweenButton.Position = UDim2.new(0.1, 0, 0.25, 0)
tweenButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tweenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
tweenButton.Font = Enum.Font.GothamBold
tweenButton.TextSize = 16
Instance.new("UICorner", tweenButton).CornerRadius = UDim.new(0, 8)

local webSlingerButton = Instance.new("TextButton", frame)
webSlingerButton.Text = "▶ START ANTI HIT"
webSlingerButton.Size = UDim2.new(0.8, 0, 0, 40)
webSlingerButton.Position = UDim2.new(0.1, 0, 0.5, 0)
webSlingerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
webSlingerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
webSlingerButton.Font = Enum.Font.GothamBold
webSlingerButton.TextSize = 16
Instance.new("UICorner", webSlingerButton).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel", frame)
status.Text = "Status: Idle"
status.Size = UDim2.new(1, 0, 0, 30)
status.Position = UDim2.new(0, 0, 0.75, 0)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 14

-- Sistem drag support Android dan PC (tanpa duplikat)
local dragging, dragInput, dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement 
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

local active = false
local currentTween
local walkThread
local tweenSpeed = 80

local function getBasePosition()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        local base = plot:FindFirstChild("DeliveryHitbox")
        if sign and base and sign:FindFirstChild("YourBase") and sign.YourBase.Enabled then
            return base.Position
        end
    end
    return nil
end

local function tweenTo(pos)
    if not hrp then return end
    if currentTween then currentTween:Cancel() end
    local dist = (hrp.Position - pos).Magnitude
    local duration = dist / tweenSpeed
    currentTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    currentTween:Play()
    currentTween.Completed:Wait()
end

local function walkToBase()
    while active do
        local target = getBasePosition()
        if target then
            status.Text = "Calculating Path..."
            local path = PathfindingService:CreatePath()
            path:ComputeAsync(hrp.Position, target)

            if path.Status == Enum.PathStatus.Success then
                status.Text = "Following Path"
                for _, wp in ipairs(path:GetWaypoints()) do
                    if not active then return end
                    tweenTo(wp.Position + Vector3.new(0, 6, 0))
                end
            else
                status.Text = "Path Failed, Direct Walk"
                tweenTo(target + Vector3.new(0, 6, 0))
            end

            status.Text = "Arrived"
            task.wait(1.5)
        else
            status.Text = "Base Not Found, retrying..."
            task.wait(1)
        end
    end
end

tweenButton.MouseButton1Click:Connect(function()
    if not active then
        active = true
        applyAntiDeath(true)
        humanoid.WalkSpeed = 0
        float.Parent = hrp
        status.Text = "Starting Tween..."
        tweenButton.Text = "■ STOP TWEEN TO BASE"
        tweenButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        walkThread = task.spawn(function()
            while active do
                walkToBase()
                task.wait(1)
            end
        end)
    else
        active = false
        if walkThread then task.cancel(walkThread) end
        if currentTween then currentTween:Cancel() end
        float.Parent = nil
        applyAntiDeath(false)
        humanoid.WalkSpeed = 16
        status.Text = "Status: Idle"
        tweenButton.Text = "▶ START TWEEN TO BASE"
        tweenButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)

webSlingerButton.MouseButton1Click:Connect(function()
    if not webSlingerActive then
        webSlingerActive = true
        status.Text = "Starting ANTI HIT..."
        webSlingerButton.Text = "■ STOP ANTI HIT"
        webSlingerButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        webSlingerThread = task.spawn(function()
            while webSlingerActive do
                executeWebSlinger()
                task.wait(12)
            end
        end)
    else
        webSlingerActive = false
        if webSlingerThread then task.cancel(webSlingerThread) end
        status.Text = "Status: Idle"
        webSlingerButton.Text = "▶ START ANTI HIT"
        webSlingerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)

local keyConnT = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        tweenButton:Activate()
    elseif input.KeyCode == Enum.KeyCode.K then
        toggleSpeedCoilEquip()
    elseif input.KeyCode == Enum.KeyCode.L then
        webSlingerButton:Activate()
    end
end)

getgenv().TweenToBaseCleanup = function()
    if keyConnT then keyConnT:Disconnect() end
    if healthConn then healthConn:Disconnect() end
    if walkThread then task.cancel(walkThread) end
    if webSlingerThread then task.cancel(webSlingerThread) end
    if currentTween then currentTween:Cancel() end
    float.Parent = nil
    if gui then gui:Destroy() end
    getgenv().TweenToBaseCleanup = nil
end

end)()
