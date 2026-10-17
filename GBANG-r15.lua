-- SUS-r15.lua
-- CoreGui UI with draggable header, minimize, status feedback and cleanup.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local GUI_NAME = "SUS_R15"
local oldGui = CoreGui:FindFirstChild(GUI_NAME)
if oldGui then oldGui:Destroy() end

local following, targetPlayer = false, nil
local activeAnimation, movementToken = nil, 0
local animationId = "10714360343"
local activeTween
local connections = {}
local destroyed = false

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties) do object[property] = value end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function stroke(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color, Transparency = transparency or 0, Thickness = thickness or 1
    }, parent)
end

local ScreenGui = make("ScreenGui", {
    Name = GUI_NAME, ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999
}, CoreGui)

local MainFrame = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(340, 224),
    Position = UDim2.new(0.5, -170, 0.5, -112),
    BackgroundColor3 = Color3.fromRGB(22, 24, 31), BorderSizePixel = 0
}, ScreenGui)
corner(MainFrame, 14)
stroke(MainFrame, Color3.fromRGB(75, 82, 105), 0.35, 1)

local TopBar = make("Frame", {
    Name = "TitleBar", Active = true,
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = Color3.fromRGB(31, 34, 45), BorderSizePixel = 0
}, MainFrame)
corner(TopBar, 14)
local TopBarFill = make("Frame", {
    Name = "CornerFill",
    Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = TopBar.BackgroundColor3, BorderSizePixel = 0
}, TopBar)
make("Frame", {
    Size = UDim2.fromOffset(4, 22), Position = UDim2.fromOffset(16, 11),
    BackgroundColor3 = Color3.fromRGB(108, 142, 255), BorderSizePixel = 0
}, TopBar)

make("TextLabel", {
    Size = UDim2.new(1, -115, 1, 0), Position = UDim2.fromOffset(29, 0),
    BackgroundTransparency = 1, Text = "SUS R15", Font = Enum.Font.GothamBold,
    TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(242, 244, 255)
}, TopBar)

local Status = make("TextLabel", {
    Name = "Status",
    -- Keep the status label clear of the minimize and close buttons.
    Size = UDim2.fromOffset(76, 20), Position = UDim2.new(1, -152, 0, 12),
    BackgroundTransparency = 1, Text = "IDLE", Font = Enum.Font.GothamMedium,
    TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right,
    TextColor3 = Color3.fromRGB(150, 157, 175)
}, TopBar)

local CloseButton = make("TextButton", {
    Name = "Close",
    Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -38, 0, 6),
    BackgroundColor3 = Color3.fromRGB(188, 64, 79), Text = "×",
    Font = Enum.Font.GothamBold, TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255), AutoButtonColor = false
}, TopBar)
corner(CloseButton, 9)

local MinimizeButton = make("TextButton", {
    Name = "Minimize",
    Size = UDim2.fromOffset(28, 32), Position = UDim2.new(1, -70, 0, 6),
    BackgroundTransparency = 1, Text = "−", Font = Enum.Font.GothamBold,
    TextSize = 20, TextColor3 = Color3.fromRGB(205, 210, 225)
}, TopBar)

local Content = make("Frame", {
    Name = "Content",
    Size = UDim2.new(1, -32, 1, -60), Position = UDim2.fromOffset(16, 54),
    BackgroundTransparency = 1
}, MainFrame)

make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
    Text = "TARGET PLAYER", Font = Enum.Font.GothamBold, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(145, 153, 176)
}, Content)

local TargetTextBox = make("TextBox", {
    Name = "Target",
    Size = UDim2.new(1, 0, 0, 38), Position = UDim2.fromOffset(0, 25),
    BackgroundColor3 = Color3.fromRGB(30, 33, 43), BorderSizePixel = 0,
    PlaceholderText = "Username or display name...",
    PlaceholderColor3 = Color3.fromRGB(105, 112, 132), Text = "",
    TextColor3 = Color3.fromRGB(238, 241, 250), TextSize = 13,
    Font = Enum.Font.Gotham, ClearTextOnFocus = false
}, Content)
corner(TargetTextBox, 9)
stroke(TargetTextBox, Color3.fromRGB(74, 81, 103), 0.45, 1)
make("UIPadding", {
    PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)
}, TargetTextBox)

local ToggleButton = make("TextButton", {
    Name = "Toggle",
    Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 78),
    BackgroundColor3 = Color3.fromRGB(83, 116, 225), BorderSizePixel = 0,
    Text = "START", Font = Enum.Font.GothamBold, TextSize = 13,
    TextColor3 = Color3.fromRGB(255, 255, 255), AutoButtonColor = false
}, Content)
corner(ToggleButton, 9)

local Hint = make("TextLabel", {
    Name = "Hint",
    Size = UDim2.new(1, 0, 0, 25), Position = UDim2.fromOffset(0, 126),
    BackgroundTransparency = 1,
    Text = "Enter a partial username, then press Start.",
    Font = Enum.Font.Gotham, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(115, 122, 143)
}, Content)

local minimized, fullSize, miniSize = false, UDim2.fromOffset(340, 224), UDim2.fromOffset(340, 44)
local dragging, dragStart, startPosition = false, nil, nil

local function setStatus(text, color)
    Status.Text, Status.TextColor3 = text, color
end

local function stopFollowing()
    following = false
    movementToken += 1
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end
    if activeAnimation then
        activeAnimation:Stop()
        activeAnimation:Destroy()
        activeAnimation = nil
    end
end

local function setMinimized(value)
    minimized = value
    -- The fill squares off the title bar in full mode; hide it when minimized.
    TopBarFill.Visible = not value
    TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Size = value and miniSize or fullSize
    }):Play()
    Content.Visible = not value
end

connect(TopBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPosition = true, input.Position, MainFrame.Position
        -- InputEnded below releases mouse/touch dragging without per-drag connections.
    end
end)

connect(UserInputService.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

ScreenGui.Destroying:Connect(function()
    destroyed = true
    stopFollowing()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(connections)
end)

MinimizeButton.Activated:Connect(function() setMinimized(not minimized) end)
CloseButton.Activated:Connect(function()
    stopFollowing()
    ScreenGui:Destroy()
end)

local function findTarget(query)
    query = query:lower():gsub("^%s*(.-)%s*$", "%1")
    if query == "" then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and (
            player.Name:lower():find(query, 1, true)
            or player.DisplayName:lower():find(query, 1, true)
        ) then
            return player
        end
    end
end

local function playAnimation()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. animationId
    activeAnimation = humanoid:LoadAnimation(animation)
    activeAnimation:Play()
    animation:Destroy()
end

local function toggleFollowing()
    if destroyed then return end
    if following then
        stopFollowing()
        ToggleButton.Text = "START"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(83, 116, 225)
        setStatus("IDLE", Color3.fromRGB(150, 157, 175))
        Hint.Text = "Movement stopped."
        return
    end

    targetPlayer = findTarget(TargetTextBox.Text)
    if not targetPlayer or not targetPlayer.Character then
        setStatus("NOT FOUND", Color3.fromRGB(255, 166, 102))
        Hint.Text = "No matching player was found."
        return
    end

    following, movementToken = true, movementToken + 1
    local token = movementToken
    ToggleButton.Text = "STOP"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(190, 70, 87)
    setStatus("ACTIVE", Color3.fromRGB(111, 224, 157))
    Hint.Text = "Following " .. targetPlayer.DisplayName .. "."
    playAnimation()

    task.spawn(function()
        while following and token == movementToken do
            local targetCharacter, localCharacter = targetPlayer.Character, LocalPlayer.Character
            local targetHRP = targetCharacter and targetCharacter.PrimaryPart
            local localHRP = localCharacter and localCharacter.PrimaryPart
            if not targetHRP or not localHRP then break end

            for _, offset in ipairs({-1.5, -1.1}) do
                if not following or token ~= movementToken then break end
                local tween = TweenService:Create(localHRP, TweenInfo.new(0.15, Enum.EasingStyle.Linear), {
                    CFrame = targetHRP.CFrame * CFrame.new(0, 0, offset)
                })
                activeTween = tween
                tween:Play()
                tween.Completed:Wait()
                if activeTween == tween then activeTween = nil end
            end
        end

        if token == movementToken and following then
            stopFollowing()
            ToggleButton.Text = "START"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(83, 116, 225)
            setStatus("IDLE", Color3.fromRGB(150, 157, 175))
            Hint.Text = "Target became unavailable."
        end
    end)
end

ToggleButton.Activated:Connect(toggleFollowing)
TargetTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then toggleFollowing() end
end)
