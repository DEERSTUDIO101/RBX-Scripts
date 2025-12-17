local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Dynamic OMA",
    Icon = 11914981726,
    LoadingTitle = "Universal",
    LoadingSubtitle = "Von BACKFISCH",
    Theme = "Ocean",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
       Enabled = true,
       FolderName = Vanith_Hub,
       FileName = "Dynamic_Night"
    },
    Discord = {
       Enabled = true,
       Invite = "AzkrU7J5Bs",
       RememberJoins = true
    },
    KeySystem = false,
 })
 -------------------------------------------------------
 local Updatev = 1.8
--------------------------------------------------------

 local fTab = Window:CreateTab("Main", 7212066690)
 local fSection = fTab:CreateSection("Info")
 local fLabel = fTab:CreateLabel("This is just a script for random ass shieet :)", 7733975185, Color3.fromRGB(70, 31, 120), false)
 local fLabel = fTab:CreateLabel("Updated, Added 2 More Games", 7733975185, Color3.fromRGB(70, 31, 120), false)
 local fDropdown = fTab:CreateDropdown({
    Name = "Update",
    Options = {"Hide the body" , "Tower of Zombies"},
    CurrentOption = {Updatev},
    MultipleOptions = false,
    Flag = "VUpdates",
    Callback = function(Options)
    end,
 })
 

 local dTab = Window:CreateTab("Random stuff", 5009915795) -- Title, Image
 local dSection = dTab:CreateSection("😃")
 -- Speed Slider
local speedSlider = dTab:CreateSlider({
    Name = "Speed 🦿",
    Range = {15, 400},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = 15,
    Flag = "Speed1",
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end,
})

-- JumpPower Slider
local jumpSlider = dTab:CreateSlider({
    Name = "High Jump 🦿",
    Range = {50, 4000},
    Increment = 10,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "Jump1",
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
    end,
})

-- Reset Button
local resetButton = dTab:CreateButton({
    Name = "Reset Speed & Jump",
    Callback = function()
        local humanoid = game.Players.LocalPlayer.Character.Humanoid
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end,
})

--// ESP Variablen
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ESPColor = Color3.fromRGB(255, 0, 0)
local ESPEnabled = false
local EnemiesOnly = false
local BoxEnabled = false
local NameTagsEnabled = false
local HealthBarsEnabled = false
local NameTagSize = 1
local HealthBarSize = 1
local NameTagColor = Color3.fromRGB(255, 255, 255)
local BoxESPColor = Color3.fromRGB(255, 255, 0) -- Eigene Farbe für BoxESP
local RainbowName = false
local FlyEnabled = false
local FlySpeed = 5
local FlyBodyGyro
local FlyBodyVelocity
local ESPList = {}

-- Rainbow Funktion
local function RainbowColor()
    local hue = tick() % 5 / 5
    return Color3.fromHSV(hue, 1, 1)
end

local function IsEnemy(player)
    if player.Team ~= nil and LocalPlayer.Team ~= nil then
        return player.Team ~= LocalPlayer.Team
    end
    return true
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPList[player] then return end
    if EnemiesOnly and not IsEnemy(player) then return end

    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "Vanith_Highlight"
        highlight.Adornee = char
        highlight.FillColor = ESPColor
        highlight.OutlineColor = Color3.new(0, 0, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = game.CoreGui

        ESPList[player] = {Highlight = highlight}

        if BoxEnabled then
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "Vanith_Box"
            box.Adornee = char:FindFirstChild("HumanoidRootPart")
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.Size = Vector3.new(4, 6, 2)
            box.Color3 = BoxESPColor
            box.Transparency = 0.25
            box.Parent = game.CoreGui
            ESPList[player].Box = box
        end
    end
end

local function AddExtraESP(player)
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if NameTagsEnabled and head then
        local tag = Instance.new("BillboardGui")
        tag.Name = "Vanith_NameTag"
        tag.Adornee = head
        tag.Size = UDim2.new(0, 200 * NameTagSize, 0, 50 * NameTagSize)
        tag.StudsOffset = Vector3.new(0, 2, 0)
        tag.AlwaysOnTop = true

        local label = Instance.new("TextLabel", tag)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.Name
        label.TextColor3 = NameTagColor
        label.TextStrokeTransparency = 0.5
        label.TextScaled = true
        label.Name = "namet2"

        tag.Parent = game.CoreGui
        ESPList[player].NameTag = tag

        if RainbowName then
            task.spawn(function()
                while RainbowName and tag and label do
                    label.TextColor3 = RainbowColor()
                    task.wait(0.1)
                end
                if label then
                    label.TextColor3 = NameTagColor
                end
            end)
        end
    end

    if HealthBarsEnabled and head and humanoid then
        local bar = Instance.new("BillboardGui")
        bar.Name = "Vanith_HPBar"
        bar.Adornee = head
        bar.Size = UDim2.new(3 * HealthBarSize, 0, 0.2 * HealthBarSize, 0)
        bar.StudsOffset = Vector3.new(0, 3, 0)
        bar.AlwaysOnTop = true

        local frame = Instance.new("Frame", bar)
        frame.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        frame.BorderSizePixel = 0
        frame.Name = "HealthFrame"

        bar.Parent = game.CoreGui
        ESPList[player].HPBar = bar

        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if frame and frame.Parent then
                frame.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
            end
        end)
    end
end

-- Update CreateESP Funktion:
local oldCreateESP = CreateESP
CreateESP = function(player)
    oldCreateESP(player)
    if ESPList[player] then
        AddExtraESP(player)
    end
end

local function RemoveESP(player)
    if ESPList[player] then
        if ESPList[player].Highlight then ESPList[player].Highlight:Destroy() end
        if ESPList[player].Box then ESPList[player].Box:Destroy() end
        if ESPList[player].NameTag then ESPList[player].NameTag:Destroy() end
        if ESPList[player].HPBar then ESPList[player].HPBar:Destroy() end
        ESPList[player] = nil
    end
end

local function RefreshESP()
    for _, player in pairs(Players:GetPlayers()) do
        RemoveESP(player)
    end
    if ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            CreateESP(player)
        end
    end
end

local function UpdateESPColor(color)
    for _, v in pairs(ESPList) do
        if v.Highlight then v.Highlight.FillColor = color end
        if v.Box then v.Box.Color3 = color end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if ESPEnabled then
            CreateESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(RemoveESP)--// Noclip
local NoclipEnabled = false

local Toggle = dTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        NoclipEnabled = Value
    end
})

--// Noclip Loop
game:GetService("RunService").Stepped:Connect(function()
    if NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide == true then
                    v.CanCollide = false
                end
            end
        end
    end
end)

--// Fly
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Direction = {
    Forward = false,
    Back = false,
    Left = false,
    Right = false,
    Up = false,
    Down = false
}

local Toggle = dTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value)
        FlyEnabled = Value

        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local root = character:WaitForChild("HumanoidRootPart")

        if Value then
            FlyBodyVelocity = Instance.new("BodyVelocity")
            FlyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            FlyBodyVelocity.P = 1250
            FlyBodyVelocity.Velocity = Vector3.zero
            FlyBodyVelocity.Parent = root

            FlyBodyGyro = Instance.new("BodyGyro")
            FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            FlyBodyGyro.P = 3000
            FlyBodyGyro.CFrame = workspace.CurrentCamera.CFrame
            FlyBodyGyro.Parent = root
        else
            if FlyBodyVelocity then FlyBodyVelocity:Destroy() FlyBodyVelocity = nil end
            if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
        end
    end
})

local Toggle = dTab:CreateSlider({
    Name = "Fly Speed",
    Range = {50, 900},
    Increment = 10,
    Suffix = "Speed",
    CurrentValue = 50,
    Callback = function(fspeed)
        FlySpeed = fspeed
    end,
})

--// Key Input
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then Direction.Forward = true end
    if input.KeyCode == Enum.KeyCode.S then Direction.Back = true end
    if input.KeyCode == Enum.KeyCode.A then Direction.Left = true end
    if input.KeyCode == Enum.KeyCode.D then Direction.Right = true end
    if input.KeyCode == Enum.KeyCode.E then Direction.Up = true end
    if input.KeyCode == Enum.KeyCode.Q then Direction.Down = true end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then Direction.Forward = false end
    if input.KeyCode == Enum.KeyCode.S then Direction.Back = false end
    if input.KeyCode == Enum.KeyCode.A then Direction.Left = false end
    if input.KeyCode == Enum.KeyCode.D then Direction.Right = false end
    if input.KeyCode == Enum.KeyCode.E then Direction.Up = false end
    if input.KeyCode == Enum.KeyCode.Q then Direction.Down = false end
end)

--// Bewegungsloop
RunService.RenderStepped:Connect(function()
    if FlyEnabled and FlyBodyVelocity and FlyBodyGyro then
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera

        if root and cam then
            local moveVec = Vector3.zero

            -- Verarbeitet die Bewegungseingaben für Fly.
            if Direction.Forward then moveVec += cam.CFrame.LookVector end
            if Direction.Back then moveVec -= cam.CFrame.LookVector end
            if Direction.Left then moveVec -= cam.CFrame.RightVector end
            if Direction.Right then moveVec += cam.CFrame.RightVector end
            if Direction.Up then moveVec += Vector3.new(0, 1, 0) end
            if Direction.Down then moveVec -= Vector3.new(0, 1, 0) end

            -- Setzt die Geschwindigkeit basierend auf den Eingaben
            if moveVec.Magnitude > 0 then
                moveVec = moveVec.Unit * FlySpeed
            end

            FlyBodyVelocity.Velocity = moveVec
            FlyBodyGyro.CFrame = cam.CFrame
        end
    end
end)

dTab:CreateButton({
    Name = "Rejoin",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
    end
})

local sLabel = dTab:CreateLabel("Esp stuff", 7733774602, Color3.fromRGB(175,0,255), false) -- Title, Icon, Color, IgnoreTheme
local Toggle = dTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Callback = function(Ece)
        ESPEnabled = Ece
        RefreshESP()
    end
})

local Toggle = dTab:CreateToggle({
    Name = "Box Esp",
    CurrentValue = false,
    Callback = function(Value)
        BoxEnabled = Value
        RefreshESP()
    end
})

local Toggle = dTab:CreateToggle({
    Name = "Enemy only",
    CurrentValue = false,
    Callback = function(Value)
        EnemiesOnly = Value
        RefreshESP()
    end
})

dTab:CreateToggle({
    Name = "ESP Healthbars",
    CurrentValue = false,
    Callback = function(Value)
        HealthBarsEnabled = Value
        RefreshESP()
    end
})

dTab:CreateToggle({
    Name = "ESP Nametags",
    CurrentValue = false,
    Callback = function(Value)
        NameTagsEnabled = Value
        RefreshESP()
    end
})
--Color shit
local Toggle = dTab:CreateColorPicker({
    Name = "ESP color",
    Color = ESPColor,
    Callback = function(Color)
        ESPColor = Color
        UpdateESPColor(Color)
    end
})

dTab:CreateColorPicker({
    Name = "Box ESP Color",
    Color = BoxESPColor,
    Callback = function(Color)
        BoxESPColor = Color
        for _, v in pairs(ESPList) do
            if v.Box then
                v.Box.Color3 = Color
            end
        end
    end
})

dTab:CreateSlider({
    Name = "Nametag Height",
    Range = {0.5, 2},
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(Value)
        NameTagSize = Value
        RefreshESP()
    end
})

dTab:CreateColorPicker({
    Name = "Nametag color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        NameTagColor = Value
        RefreshESP()
    end
})

dTab:CreateSlider({
    Name = "Health Bar Größe",
    Range = {0.5, 2},
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(Value)
        HealthBarSize = Value
        RefreshESP()
    end
})

--------------------------- [ This is the new script section under this :) ] ----------------------------------

local sTab = Window:CreateTab("Scripts", 8425069718)
local sSection = sTab:CreateSection("Scripts")
local Button = sTab:CreateButton({
    Name = "Simple Spy",
    Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
    end,
 })
 local Button = sTab:CreateButton({
    Name = "Infinite Yield",
    Callback = function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end,
 })
 local Button = sTab:CreateButton({
    Name = "FrostHub by Vanith",
    Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Snipez-Dev/Synap-Src/refs/heads/main/FrostHub"))()
    end,
 })
 local Button = sTab:CreateButton({
    Name = "Universal Hack by Homohack",
    Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/dementiaenjoyer/homohack/main/loader.lua"))()
    end,
 })
 local Button = sTab:CreateButton({
    Name = "Cords Checker",
    Callback = function()
    loadstring(game:HttpGet("https://pastefy.app/5i0dxiYd/raw"))()
    end,
 })
 if game.PlaceId == 4924922222 then 
    local Button = sTab:CreateLabel("Brookhaven", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "Mango Hub",
    Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/rogelioajax/lua/main/MangoHub", true))()
    end,
 })
 local Button = sTab:CreateButton({
    Name = "Ice Hub new style (Orbit)",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Waza80/scripts-new/main/IceHubBrookhaven.lua"))()
    end,
 })
 local Button = sTab:CreateButton({
    Name = "Salvatore",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RFR-R1CH4RD/Loader/main/Salvatore.lua"))()
    end,
 })

elseif game.PlaceId == 12673840215 then
    local Button = sTab:CreateLabel("Realistic hood test", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "Realistic hood with Universal hitbox expander?",
    Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/YellowGregs/Loadstring/refs/heads/main/rhtestesting.lua"))()
    end,
 })
elseif game.PlaceId == 12355337193 then
    local Button = sTab:CreateLabel("Realistic hood test", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "Realistic hood with Universal hitbox expander?",
    Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/YellowGregs/Loadstring/refs/heads/main/rhtestesting.lua"))()
    end,
 })
elseif game.PlaceId == 13864661000 then
    local Button = sTab:CreateLabel("Break In 2", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "Break In 2 Starry",
    Callback = function()
        loadstring(game:HttpGet("https://luau.tech/build"))();
    end,
 })
elseif game.PlaceId == 3851622790 then
local Button = sTab:CreateButton({
    Name = "Break In DP Hub",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/COOLXPLO/DP-HUB-coolxplo/refs/heads/main/BreakInStory.lua"))()
    end,
 })
elseif game.PlaceId == 116495829188952 then
    local Button = sTab:CreateLabel("Dead Rails", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "Airflow",
    Callback = function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/255ac567ced3dcb9e69aa7e44c423f19.lua"))()
    end,
 })
 local Button = sTab:CreateButton({
    Name = "Kiciahook",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kiciahook/kiciahook/refs/heads/main/loader.lua"))()
    end,
 })
elseif game.PlaceId == 6516141723 then
    local Button = sTab:CreateLabel("Doors", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "Orbit by Waza80",
    Callback = function()
        loadstring(game:HttpGet("https://orbitsc.net/doors"))()
    end,
 })
elseif game.PlaceId == 79546208627805 then
    local Button = sTab:CreateButton({
    Name = "Vape Voidware",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VWExtra/main/NightsInTheForest.lua", true))()
        Rayfield:Notify({
    Title = "Vape Voidware",
    Content = "works also in other games",
    Duration = 4.5,
    Image = 4483362458,
})
    end,
 })

    local Button = sTab:CreateLabel("99 nights in the Forest", 7743871480, Color3.fromRGB(70, 31, 120), false)
 local Button = sTab:CreateButton({
    Name = "H4xScripts",
    Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/H4xScripts/Loader/refs/heads/main/loader.lua", true))()
Rayfield:Notify({
    Title = "H4xScripts",
    Content = "Consider Joining their discord, they do also nice stuff",
    Duration = 4.5,
    Image = 4483362458,
})
    end,
 })
elseif game.PlaceId == 8073154099 then
    local Button = sTab:CreateLabel("The Intruder", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "Unnamed Script",
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/FGjjwm6W"))()
    end,
 })
elseif game.PlaceId == 14494334042 then
    local Button = sTab:CreateLabel("Get Fat and Roll Race", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "Ln Hub",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/No6No6No7yt/Lumin-Hub/main/FatRace.lua'))();
    end,
 })

elseif game.PlaceId == 72966375942583 then
    local Button = sTab:CreateLabel("+1 SkillPoint Every Second", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "Dynamic OMA",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DEERSTUDIO101/-1-SkillPoint-Every-Second/refs/heads/main/1spes.lua",true))() 
    end,
 })
elseif game.PlaceId == 606849621 then
    local Button = sTab:CreateLabel("Jailbreak - Project Auto", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "Auto Rob Crime",
    Callback = function()
        loadstring(game:HttpGet('https://scripts.projectauto.xyz/AutoRobV6'))()
    end,
 })
 local Button = sTab:CreateButton({
    Name = "Auto Arrest Cops",
    Callback = function()
        loadstring(game:HttpGet('https://scripts.projectauto.xyz/AutoArrestV4'))()
    end,
 })
elseif game.PlaceId == 98629859043211 then
    local Button = sTab:CreateLabel("M-E-G-Endless-Reality", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "MEG HUB",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/YegozovutSemyon/MEGHUB/refs/heads/main/source'))()
    end,
 })
elseif game.PlaceId == 16154918775 then
    local Button = sTab:CreateLabel("Buckshot", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "BUCKSHOT",
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/uRdcjnhJ"))()
    end,
 })
elseif game.PlaceId == 920587237 then
    local Button = sTab:CreateLabel("Adopt me", 7743871480, Color3.fromRGB(70, 31, 120), false) -- Title, Icon, Color, IgnoreTheme
    local Button = sTab:CreateButton({
    Name = "Prodigy X",
    Callback = function()
        loadstring(game:HttpGet('https://gitfront.io/r/ReQiuYTPL/wFUydaK74uGx/hub/raw/ReQiuYTPLHub.lua'))()
    end,
 })
elseif game.PlaceId == 135880624242201 then
    local Button = sTab:CreateLabel("Cut trees", 7743871480, Color3.fromRGB(70, 31, 120), false)
    local Button = sTab:CreateButton({
    Name = "kasumi Hub",
    Callback = function()
        script_key = cuttreesadded
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kasumichwan/scripts/refs/heads/main/kasumi-hub.lua"))()
    end,
 })
elseif game.PlaceId == 292439477 then
    local Button = sTab:CreateLabel("Phantom Forces - Homohack", 7743871480, Color3.fromRGB(70, 31, 120), false)
    local Button = sTab:CreateButton({
    Name = "PF - Homohack",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/dementiaenjoyer/homohack/main/pf_lite.lua"))()
    end,
 })
elseif game.PlaceId == 99122501338948 then
    local Button = sTab:CreateLabel("Tower of Zombies", 7743871480, Color3.fromRGB(70, 31, 120), false)
    local Button = sTab:CreateButton({
    Name = "ToZ - Tora is me",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/TowerofZombies"))()
    end,
 })
elseif game.PlaceId == 81239378558719 then
    local Button = sTab:CreateLabel("Hide the body", 7743871480, Color3.fromRGB(70, 31, 120), false)
    local Button = sTab:CreateButton({
    Name = "Hide the body",
    Callback = function()
        script_key = E4A53
        loadstring(game:HttpGet("https://pastefy.app/ULaWpxKm/raw"))()
    end,
 })
end
