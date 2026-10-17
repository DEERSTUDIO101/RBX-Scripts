-- Suck-modern-5918726674.lua
-- GUI adaptation of the supplied script.
-- CoreGui UI with draggable header, minimize, status feedback and cleanup.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local GUI_NAME = "GetSuckedGUI"
local oldGui = CoreGui:FindFirstChild(GUI_NAME)
if oldGui then oldGui:Destroy() end

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
    BackgroundTransparency = 1, Text = "SUCK", Font = Enum.Font.GothamBold,
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


local UsernameBox = TargetTextBox
local destroyed = false
local connections = {}
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

-- GUI Logic
local minimized = false
local running = false
local originalGravity
local attachmentLoop
local animTrack
local targetPlayer


local function updateStatus()
    ToggleButton.BackgroundColor3 = running and Color3.fromRGB(190, 70, 87) or Color3.fromRGB(83, 116, 225)
    Status.Text = running and "ACTIVE" or "IDLE"
    Status.TextColor3 = running and Color3.fromRGB(111, 224, 157) or Color3.fromRGB(150, 157, 175)
    Hint.Text = running and ("Target: " .. UsernameBox.Text) or "Enter a partial username, then press Start."
end

local function stopSession()
    -- Stop the process and everything running
    ToggleButton.Text = "START"
    running = false

    -- Restore gravity
    if originalGravity ~= nil then
        workspace.Gravity = originalGravity
        originalGravity = nil
    end

    -- Disconnect loops and stop animations
    if attachmentLoop then
        attachmentLoop:Disconnect() -- Disconnect the attachment loop
        attachmentLoop = nil -- Clear the loop variable to prevent accidental access
    end
    if animTrack then
        animTrack:Stop() -- Stop the animation
        animTrack:Destroy()
        animTrack = nil -- Clear the animation variable
    end

    updateStatus()
end

local sizeTween
MinimizeButton.Activated:Connect(function()
    minimized = not minimized
    if sizeTween then sizeTween:Cancel() end
    TopBarFill.Visible = not minimized
    Content.Visible = not minimized
    sizeTween = TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Size = UDim2.fromOffset(340, minimized and 44 or 224)
    })
    sizeTween:Play()
end)

local dragging, dragStart, startPosition
connect(TopBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPosition = true, input.Position, MainFrame.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

ScreenGui.Destroying:Connect(function()
    destroyed = true
    if sizeTween then sizeTween:Cancel() end
    stopSession()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(connections)
end)
CloseButton.Activated:Connect(function() ScreenGui:Destroy() end)

local function toggleSession()
    if destroyed then return end
    if not running then
        ToggleButton.Text = "STOP"
        running = true
        updateStatus()

        local victim = UsernameBox.Text:lower():gsub("^%s*(.-)%s*$", "%1")
        targetPlayer = nil
        if victim == "" then
            stopSession()
            Status.Text = "NOT FOUND"
            Status.TextColor3 = Color3.fromRGB(255, 166, 102)
            Hint.Text = "Enter a username or display name."
            return
        end

        -- Find target player by matching either username or display name
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and (string.find(player.Name:lower(), victim, 1, true) or string.find(player.DisplayName:lower(), victim, 1, true)) then
                targetPlayer = player
                break
            end
        end

        if targetPlayer and targetPlayer.Character and game.Players.LocalPlayer.Character then
            local localPlayer = game.Players.LocalPlayer
            local humanoidRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")

            -- Find the target's torso or lower body part (Pelvis area)
            local targetTorso = targetPlayer.Character:FindFirstChild("LowerTorso") or targetPlayer.Character:FindFirstChild("UpperTorso")

            if humanoidRootPart and targetRootPart and targetTorso then
                originalGravity = workspace.Gravity
                workspace.Gravity = 0 -- Set gravity to 0 to keep the character floating

                -- Play animation
                local animationId = "rbxassetid://5918726674" -- Replace with valid animation ID
                local animation = Instance.new('Animation')
                animation.AnimationId = animationId

                local humanoid = localPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    animTrack = humanoid:LoadAnimation(animation)
                    animTrack:Play()
                    animTrack:AdjustSpeed(1)
                end

                -- Attach the local player character to the target character's torso (this does not loop)
                attachmentLoop = game:GetService("RunService").Heartbeat:Connect(function()
                    if running then
                        -- Update the local player's position to be in front of the target's torso
                        humanoidRootPart.CFrame = targetTorso.CFrame * CFrame.new(0, -2.3, -1.0) * CFrame.Angles(0, math.pi, 0)
                    end
                end)
            else
                stopSession()
                Status.Text = "UNAVAILABLE"
                Status.TextColor3 = Color3.fromRGB(255, 166, 102)
                Hint.Text = "Character parts are unavailable."
            end
        else
            stopSession()
            Status.Text = "NOT FOUND"
            Status.TextColor3 = Color3.fromRGB(255, 166, 102)
            Hint.Text = "No matching player was found."
        end
    else
        stopSession()
    end
end

ToggleButton.Activated:Connect(toggleSession)
TargetTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then toggleSession() end
end)
