-- Anti cheat bypass is in the main script, do not run this else you will get banned without having a anti cheat bypass!

shared.CG_FLY_CONNECTIONS = shared.CG_FLY_CONNECTIONS or {}
shared.CG_FLY_ANIMATION_TRACKS = shared.CG_FLY_ANIMATION_TRACKS or {}

for _, Track in pairs(shared.CG_FLY_ANIMATION_TRACKS) do
    pcall(Track.Stop, Track)
end

for _, Connection in pairs(shared.CG_FLY_CONNECTIONS) do
    pcall(Connection.Disconnect, Connection)
end

table.clear(shared.CG_FLY_CONNECTIONS)
table.clear(shared.CG_FLY_ANIMATION_TRACKS)

if shared.CG_FLY_BODYPOS then
    pcall(shared.CG_FLY_BODYPOS.Destroy, shared.CG_FLY_BODYPOS)
    shared.CG_FLY_BODYPOS = nil
end

local isAntiCheatBypassedFunc = nil
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Camera = workspace.CurrentCamera
local Character = Player.Character or Player.CharacterAdded:Wait()
local playerBodyPosition = nil

local isFlyEnabled = false
local flySpeed = 5
local flyValues = {
    Forward = false,
    Backward = false,
    Left = false,
    Right = false,
    Up = false
}

local flyAnimationIds = {
    ["Moving"] = "rbxassetid://13850657882",
    ["Idle"] = "rbxassetid://13850660986"
}

local LoadedMovingAnimation = nil
local LoadedIdleAnimation = nil

local function loadFlyAnimations()
    if not Character then return end
    
    local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
    local Animator = Humanoid and Humanoid:FindFirstChildWhichIsA("Animator")
    if not Animator then return end

    local TempAnimationInstance = Instance.new("Animation")
    TempAnimationInstance.Parent = nil

    TempAnimationInstance.AnimationId = flyAnimationIds.Idle
    LoadedIdleAnimation = Animator:LoadAnimation(TempAnimationInstance)

    TempAnimationInstance.AnimationId = flyAnimationIds.Moving
    LoadedMovingAnimation = Animator:LoadAnimation(TempAnimationInstance)

    table.insert(shared.CG_FLY_ANIMATION_TRACKS, LoadedIdleAnimation)
    table.insert(shared.CG_FLY_ANIMATION_TRACKS, LoadedMovingAnimation)
end

loadFlyAnimations()

table.insert(shared.CG_FLY_CONNECTIONS, Player.CharacterAdded:Connect(function(newCharacter)
    shared.CG_isAntiCheatBypassed = false

    Character = newCharacter

    if playerBodyPosition then
        pcall(playerBodyPosition.Destroy, playerBodyPosition)
    end

    repeat
        bypassAntiCheat()
        task.wait()
    until shared.CG_isAntiCheatBypassed

    playerBodyPosition = nil

    loadFlyAnimations()
end))

repeat
    bypassAntiCheat()
    task.wait()
until shared.CG_isAntiCheatBypassed

table.insert(shared.CG_FLY_CONNECTIONS, UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.W then
            flyValues.Forward = true
        elseif input.KeyCode == Enum.KeyCode.S then
            flyValues.Backward = true
        elseif input.KeyCode == Enum.KeyCode.A then
            flyValues.Left = true
        elseif input.KeyCode == Enum.KeyCode.D then
            flyValues.Right = true
        elseif input.KeyCode == Enum.KeyCode.Space then
            flyValues.Up = true
        end
    end
end))

table.insert(shared.CG_FLY_CONNECTIONS, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.W then
            flyValues.Forward = false
        elseif input.KeyCode == Enum.KeyCode.S then
            flyValues.Backward = false
        elseif input.KeyCode == Enum.KeyCode.A then
            flyValues.Left = false
        elseif input.KeyCode == Enum.KeyCode.D then
            flyValues.Right = false
        elseif input.KeyCode == Enum.KeyCode.Space then
            flyValues.Up = false
        end
    end
end))

table.insert(shared.CG_FLY_CONNECTIONS, RunService.Heartbeat:Connect(function()
    if not isFlyEnabled then
        LoadedIdleAnimation:Stop()
        LoadedMovingAnimation:Stop()

        if playerBodyPosition then
            pcall(playerBodyPosition.Destroy, playerBodyPosition)
        end

        playerBodyPosition = nil

        return
    end

    if not isAntiCheatBypassedFunc then return end
    if not isAntiCheatBypassedFunc() then return end
    local Character = Player.Character
    if not Character then return end

    local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
    if not Humanoid then return end

    if Humanoid.MoveDirection == Vector3.new() then
        LoadedMovingAnimation:Stop()

        if not LoadedIdleAnimation.IsPlaying then
            LoadedIdleAnimation:Play()
        end
    else
        LoadedIdleAnimation:Stop()

        if not LoadedMovingAnimation.IsPlaying then
            LoadedMovingAnimation:Play()
        end
    end
    
    if not playerBodyPosition then
        playerBodyPosition = Instance.new("BodyPosition")
        playerBodyPosition.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        playerBodyPosition.D = 650
        playerBodyPosition.Position = Character.PrimaryPart.Position

        playerBodyPosition.Parent = Character.PrimaryPart

        shared.CG_FLY_BODYPOS = playerBodyPosition
    end

    local direction = Vector3.new()

    if flyValues.Up then
        direction = direction + Camera.CFrame.UpVector
    end

    if flyValues.Forward then
        direction = direction + Camera.CFrame.LookVector
    end

    if flyValues.Backward then
        direction = direction - Camera.CFrame.LookVector
    end

    if flyValues.Left then
        direction = direction - Camera.CFrame.RightVector
    end

    if flyValues.Right then
        direction = direction + Camera.CFrame.RightVector
    end

    playerBodyPosition.Position = playerBodyPosition.Position + direction * flySpeed
end))

return {
    EnableAndDisableFly = function()
        isFlyEnabled = not isFlyEnabled
    end,
    
    SetFlySpeed = function(value)
        if type(value) ~= "number" then return end

        value = math.clamp(value, 1, 100)

        flySpeed = value
    end,

    SetAntiCheatBypassedFunction = function(func)
        isAntiCheatBypassedFunc = func
    end
}