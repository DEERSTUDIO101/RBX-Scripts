local LIBRARY_URL = "https://raw.githubusercontent.com/Snipez-Dev/Vantix/refs/heads/main/VantixUI6"
local vantixConnections = {}
local vantixStopped = false
local function connectVantix(signal, callback)
    local connection = signal:Connect(callback)
    if vantixStopped then connection:Disconnect() else table.insert(vantixConnections, connection) end
    return connection
end
local function disconnectVantix()
    vantixStopped = true
    for _, connection in ipairs(vantixConnections) do pcall(function() connection:Disconnect() end) end
    table.clear(vantixConnections)
end
local loaded, VantixUI = pcall(function()
    local source = game:HttpGet(LIBRARY_URL)
    -- Capture actual connections created by this copy of the library. Input
    -- listeners belong to services, so destroying their GUI does not remove them.
    for _, event in ipairs({ "InputBegan", "InputChanged", "InputEnded" }) do
        source = source:gsub("UIS%." .. event .. ":Connect%(", "connectVantix(UIS." .. event .. ", ")
    end
    source = source:gsub("RunService%.Heartbeat:Connect%(", "connectVantix(RunService.Heartbeat, ")
    source = "local connectVantix = ...\n" .. source
    local chunk, failure = loadstring(source)
    if not chunk then error(failure) end
    return chunk(connectVantix)
end)
if not loaded or type(VantixUI) ~= "table" or type(VantixUI.CreateWindow) ~= "function" then
    disconnectVantix()
    warn("BRM5 PvE: failed to load VantixUI6: " .. tostring(VantixUI))
    return
end

-- BRM5 custom actor support: Player.Character is normally nil in this game.
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local Env = getgenv and getgenv() or _G
local previous = Env.OceanBRM5Highlights
local savedSettings = previous and previous.Settings and table.clone(previous.Settings)
if savedSettings then
    for key, value in pairs(savedSettings) do
        if type(value) == "table" then savedSettings[key] = table.clone(value) end
    end
end
if previous and previous.Destroy then pcall(previous.Destroy) end

local S = {
    Version = 2,
    Enabled = true, Enemies = true, NPCs = true, Players = true,
    ThroughWalls = true, Markers = true, Names = true,
    MaxDistance = 12000, Fill = 0.65, Outline = 0,
    Colors = { Enemies = Color3.fromRGB(255, 65, 65),
        NPCs = Color3.fromRGB(75, 230, 130), Players = Color3.fromRGB(75, 165, 255) },
    Aim = { Enabled = false, Key = "Right Mouse Button", Mode = "BRM5 Camera",
        Part = "Head", VisibleCheck = true, Radius = 160, Distance = 1800,
        Smoothing = 75, ShowCircle = true, UseFOV = true, StickToTarget = true,
        Prediction = 0, TeamCheck = true, TargetPlayers = false, TargetNPCs = true,
        FOVColor = Color3.fromRGB(255, 80, 80) },
    Silent = { Enabled = false, RequireHold = false, HitChance = 100, CompensateDrop = true,
        Part = "Head", VisibleCheck = true, UseFOV = true, Distance = 1800,
        TeamCheck = true, TargetPlayers = false, TargetNPCs = true, Prediction = 0,
        ShowLine = false, LineColor = Color3.fromRGB(255, 255, 255) },
    Player = { Fly = false, FlySpeed = 200, WalkSpeed = false, SpeedMultiplier = 1.5,
        SprintMultiplier = 2, InfiniteStamina = false, NoJumpCooldown = false,
        JumpPower = false, JumpVelocity = 35, NoProneDelay = false },
    Vehicle = { Fly = false, FlySpeed = 150 },
    Gun = { NoRecoil = false, NoSpread = false, NoADS = false, NoSway = false,
        FireModeOverride = false, FireMode = "Auto", FastFireRate = false,
        RateMultiplier = 2, NoShootDelay = false, InstantEquip = false,
        AutoShoot = false, AutoShootVisibleCheck = true },
    Crosshair = { Enabled = false, Position = "Center", Size = 10, Gap = 4,
        Thickness = 1, Color = Color3.fromRGB(255, 255, 255), CenterDot = false },
    World = { Daytime = false, NoLeaves = false, NoShadows = false, NoClouds = false, NoLighting = false },
    Performance = { ESPInterval = 500, HighlightFPS = 30, HighlightOnly = true, MaxMarkers = 48, MaxHighlights = 48, ViewportFilter = true, CacheTTL = 120, MaxCachedEntities = 512 },
    NoFallDamage = false,
}
S.Keybinds = { ["UI.Toggle"] = "RightShift" }
for group, value in pairs(S) do
    if type(value) == "boolean" then S.Keybinds[group] = "Unknown"
    elseif type(value) == "table" and group ~= "Keybinds" then
        for key, setting in pairs(value) do
            if type(setting) == "boolean" then S.Keybinds[group .. "." .. key] = "Unknown" end
        end
    end
end
S.Keybinds["Player.Fly"] = "H"
S.Keybinds["Vehicle.Fly"] = "J"
if savedSettings then
    for key, default in pairs(S) do
        local value = savedSettings[key]
        if type(default) == "table" and type(value) == "table" then
            for field, fieldDefault in pairs(default) do
                if typeof(value[field]) == typeof(fieldDefault) then default[field] = value[field] end
            end
        elseif typeof(value) == typeof(default) then S[key] = value end
    end
end
if savedSettings and savedSettings.Version ~= 2 then S.Aim.Mode = "BRM5 Camera" end
if S.Aim.Part == "Upper Body" then S.Aim.Part = "Upper Torso" end
-- The lightweight ESP profile intentionally replaces the old marker overlay.
S.Performance.HighlightOnly, S.Performance.HighlightFPS = true, 30
S.Markers, S.Names = false, false
local API = { Settings = S, Running = true, Stats = {}, LastError = nil }
API.Performance = { RefreshMs = 0, WorstRefreshMs = 0, MarkerCount = 0, FPS = 0, WorstFrameMs = 0 }
local connections, records, rigs = {}, {}, {}
local highlightPool, markerPool = {}, {}
local lastCacheSweep = 0
API.CacheMetrics = { Entities = 0, HighlightsCreated = 0, MarkersCreated = 0, Reuses = 0 }
local registry, statusLabel, ui, Window
local gameplayStatus
local classes, patches = {}, {}
local aimStatus, aimCircle, aimGui, aimTarget
local aimVisual = {}
local aimBinding = "OceanBRM5Aim_" .. tostring(os.clock())
local aimBound = false
local mouseRemainder = Vector2.zero
local lastAimScan = 0
local folder = Instance.new("Folder")
folder.Name = "Ocean_BRM5_Highlights"
folder.Parent = workspace
local markers = Instance.new("ScreenGui")
markers.Name = "Ocean_BRM5_Markers"
markers.ResetOnSpawn = false
markers.Parent = CoreGui
Env.OceanBRM5Highlights = API

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end

local function discard(key)
    local r = records[key]
    if not r then return end
    if r.highlightSlot then r.highlightSlot.object.Enabled = false; r.highlightSlot.owner = nil end
    if r.markerSlot then r.markerSlot.object.Visible = false; r.markerSlot.owner = nil end
    records[key] = nil
    API.CacheMetrics.Entities = API.CacheMetrics.Entities - 1
end

function API.Destroy()
    if not API.Running then return end
    API.Running = false
    if API.StopFeatures then pcall(API.StopFeatures) end
    for _, patch in pairs(patches) do
        if rawget(patch.class, patch.method) == patch.wrapper then
            pcall(function() patch.class[patch.method] = patch.original end)
        end
    end
    table.clear(patches)
    if aimBound then RunService:UnbindFromRenderStep(aimBinding); aimBound = false end
    aimTarget, API.AimTarget = nil, nil
    for _, c in ipairs(connections) do c:Disconnect() end
    table.clear(connections)
    disconnectVantix()
    for key in pairs(records) do discard(key) end
    folder:Destroy()
    markers:Destroy()
    if aimGui then aimGui:Destroy() end
    if Window then pcall(function() Window:Destroy() end) end
    if Env.OceanBRM5Highlights == API then Env.OceanBRM5Highlights = nil end
    registry = nil
    table.clear(rigs)
end

local function isActor(t)
    return type(t) == "table" and type(rawget(t, "UID")) == "string"
        and typeof(rawget(t, "Character")) == "Instance"
        and typeof(rawget(t, "RootPart")) == "Instance"
end

-- Find the live UID dictionary once; never scan getgc on each frame.
local function discoverRegistry()
    if not getgc then return false end
    local ok, gc = pcall(getgc, true)
    if not ok then return false end
    local best, bestCount = nil, 0
    for _, t in ipairs(gc) do
        if type(t) == "table" then
            local muzzle, update, info = rawget(t, "GetMuzzleCFrame"), rawget(t, "Update"), rawget(t, "GetInfo")
            if type(muzzle) == "function" and debug.info(muzzle, "s") == "ReplicatedFirst.Flux/client.Services.InventoryService.FirearmInventory" then
                classes.Firearm = t
            end
            if type(update) == "function" and debug.info(update, "s") == "ReplicatedFirst.Flux/client.Services.ControllerService.CharacterController" then
                classes.Controller = t
            end
            if type(info) == "function" and debug.info(info, "s") == "ReplicatedStorage.Shared.Services.BulletService" then
                classes.Bullet = t
            end
            if API.DiscoverFeatureTable then API.DiscoverFeatureTable(t) end
            -- Actor dictionaries contain UID -> actor entries. Avoid walking
            -- every field of every unrelated UI/config table in the Lua heap.
            local firstKey, firstValue = next(t)
            if type(firstKey) == "string" and isActor(firstValue) and rawget(firstValue, "UID") == firstKey then
                local count = 0
                for k, v in next, t do
                    if type(k) == "string" and isActor(v) and rawget(v, "UID") == k then count = count + 1 end
                end
                if count > bestCount then best, bestCount = t, count end
            end
        end
    end
    registry = best
    return registry ~= nil
end

local function consider(inst)
    if inst:IsDescendantOf(folder) then return end
    local model = inst:IsA("Model") and inst or inst:FindFirstAncestorOfClass("Model")
    if model and (model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")) then
        rigs[model] = true
    end
end

connect(workspace.DescendantAdded, consider)
for _, inst in ipairs(workspace:GetDescendants()) do
    if inst:IsA("Model") then consider(inst) end
end

local function getRoot(model)
    return model:FindFirstChild("Root") or model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
end

local function playerOwner(actor)
    local owner = rawget(actor, "Owner")
    if typeof(owner) == "Instance" and owner:IsA("Player") then return owner end
    local name = rawget(actor, "OwnerName")
    return type(name) == "string" and Players:FindFirstChild(name) or nil
end

-- Only actors positively identified as BRM5's hostile AI (OwnerName == ???).
-- Static NPC props and any player-owned actor cannot enter the aim candidate list.
function API.IsEnemyActor(actor)
    if not isActor(actor) or playerOwner(actor) or rawget(actor, "Owner") ~= nil
        or rawget(actor, "OwnerName") ~= "???" or rawget(actor, "IsLocalPlayer") == true
        or rawget(actor, "Alive") == false then return false end
    local health = rawget(actor, "Health")
    if type(health) == "number" and health <= 0 then return false end
    local model = rawget(actor, "Character")
    if not model:IsA("Model") or not model:IsDescendantOf(workspace)
        or Players:GetPlayerFromCharacter(model) then return false end
    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    return not humanoid or humanoid.Health > 0
end

local boneCache = setmetatable({}, { __mode = "k" })
local visibilityCache = setmetatable({}, { __mode = "k" })
local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude
local sightCamera, sightCharacter
local function aimPart(actor, settings)
    local model = rawget(actor, "Character")
    local selected = (settings or S.Aim).Part
    local cached = boneCache[actor]
    if cached and cached.model == model and cached.selected == selected and cached.part.Parent then return cached.part end
    local names = selected == "Head" and { "FakeHead", "Head", "UpperTorso", "Torso" }
        or selected == "Lower Torso" and { "LowerTorso", "Torso", "UpperTorso", "Root" }
        or { "UpperTorso", "Torso", "Head" }
    for _, name in ipairs(names) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            boneCache[actor] = { model = model, selected = selected, part = part }
            return part
        end
    end
    local root = rawget(actor, "RootPart")
    return root and root:IsA("BasePart") and root or nil
end

local function visibleTarget(camera, part, model, settings)
    if not (settings or S.Aim).VisibleCheck then return true end
    local now, origin, target = os.clock(), camera.CFrame.Position, part.Position
    local cached = visibilityCache[part]
    if cached and now - cached.time < 0.1 and cached.model == model
        and (origin - cached.origin).Magnitude < 3 and (target - cached.target).Magnitude < 3 then return cached.clear end
    if sightCamera ~= camera or sightCharacter ~= API.LocalCharacter then
        local exclude = { folder, camera }
        if API.LocalCharacter then table.insert(exclude, API.LocalCharacter) end
        sightParams.FilterDescendantsInstances = exclude
        sightCamera, sightCharacter = camera, API.LocalCharacter
    end
    local hit = workspace:Raycast(origin, target - origin, sightParams)
    local clear = not hit or hit.Instance:IsDescendantOf(model)
    visibilityCache[part] = { time = now, origin = origin, target = target, model = model, clear = clear }
    return clear
end

-- Optional source makes target-selection diagnostics possible without changing
-- the game's live actor registry. Normal operation always uses its UID dictionary.
function API.FindAimTarget(source, settings)
    settings = settings or S.Aim
    local camera = workspace.CurrentCamera
    if not camera or not (source or registry) then return nil end
    local center = camera.ViewportSize / 2
    local best, bestScore = nil, math.huge
    for _, actor in next, source or API.AimActors or registry do
        if API.IsTargetActor and API.IsTargetActor(actor, settings) or not API.IsTargetActor and API.IsEnemyActor(actor) then
            local part = aimPart(actor, settings)
            if part then
                local distance = (part.Position - camera.CFrame.Position).Magnitude
                local screen, onScreen = camera:WorldToViewportPoint(part.Position)
                local score = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                if onScreen and screen.Z > 0 and distance <= (settings.Distance or S.Aim.Distance)
                    and (not settings.UseFOV or score <= (settings.Radius or S.Aim.Radius)) and score < bestScore
                    and visibleTarget(camera, part, rawget(actor, "Character"), settings) then
                    best, bestScore = actor, score
                end
            end
        end
    end
    return best
end

local function aimHeld()
    if UIS:GetFocusedTextBox() then return false end
    if type(isrbxactive) == "function" and not isrbxactive() then return false end
    if S.Aim.Key == "Right Mouse Button" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if S.Aim.Key == "Left Mouse Button" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    local key = Enum.KeyCode[S.Aim.Key]
    return key and UIS:IsKeyDown(key) or false
end

local function isLocalActor(actor)
    return type(actor) == "table" and (playerOwner(actor) == LP or rawget(actor, "IsLocalPlayer") == true)
end

-- Return a corrected shot frame; the camera and other weapons are untouched.
-- GetMuzzleCFrame is called before both local projectile creation and replication.
function API.GetSilentFrame(frame, target, inventory)
    if typeof(frame) ~= "CFrame" or not (API.IsTargetActor and API.IsTargetActor(target, S.Silent) or not API.IsTargetActor and API.IsEnemyActor(target)) then return frame end
    local part = aimPart(target, S.Silent)
    if not part then return frame end
    local origin, goal = frame.Position, API.GetTargetPosition and API.GetTargetPosition(target, S.Silent) or part.Position
    if (goal - origin).Magnitude < 0.001 then return frame end
    local aimFrame = CFrame.lookAt(origin, goal)
    if S.Silent.CompensateDrop and classes.Bullet and type(inventory) == "table" then
        local firearm = rawget(inventory, "_firearm")
        local tune = type(firearm) == "table" and firearm.Tune
        if type(tune) == "table" and tune.Caliber and tune.Barrel then
            local ok, speed = pcall(classes.Bullet.GetInfo, classes.Bullet, tune.Caliber, tune.Barrel)
            if ok and type(speed) == "number" and speed > 0 then
                -- BRM5's BulletClass uses 32.2 for projectile gravity.
                local offset = goal - origin
                local horizontal = Vector2.new(offset.X, offset.Z).Magnitude
                local speed2, gravity = speed * speed, 32.2
                local discriminant = speed2 * speed2 - gravity * (gravity * horizontal * horizontal + 2 * offset.Y * speed2)
                if horizontal > 0.001 and discriminant >= 0 then
                    -- Equivalent to the low-angle solution without cancellation.
                    local tangent = (gravity * horizontal * horizontal + 2 * offset.Y * speed2)
                        / (horizontal * (speed2 + math.sqrt(discriminant)))
                    local lift = horizontal * tangent - offset.Y
                    aimFrame = CFrame.lookAt(origin, goal + Vector3.new(0, lift, 0))
                end
                -- Discharge adds the configured sight zero after GetMuzzleCFrame.
                local actor = rawget(inventory, "_actor")
                local view = type(actor) == "table" and rawget(actor, "ViewModel")
                local zero = type(view) == "table" and view.Zero
                if type(actor) == "table" and rawget(actor, "ADS") and zero then
                    if type(zero) == "table" then zero = zero[4] end
                    if type(zero) == "number" then
                        local zeroAngle = math.asin(math.clamp(zero * gravity / speed2, -1, 1)) * 0.5
                        aimFrame = aimFrame * CFrame.Angles(-zeroAngle, 0, 0)
                    end
                end
            end
        end
    end
    return aimFrame
end

function API.ClampFallVelocity(controller)
    if not S.NoFallDamage or type(controller) ~= "table" or not isLocalActor(rawget(controller, "_localActor")) then return end
    local velocity = rawget(controller, "VelocityGravity")
    if type(velocity) == "number" and velocity < -12 then controller.VelocityGravity = -12 end
end

local function patchMethod(key, class, method, makeWrapper)
    if patches[key] then return true end
    local original = class and rawget(class, method)
    if type(original) ~= "function" then return false, "BRM5 " .. method .. " was not found." end
    local wrapper = makeWrapper(original)
    local ok, failure = pcall(function() class[method] = wrapper end)
    if not ok then return false, tostring(failure) end
    patches[key] = { class = class, method = method, original = original, wrapper = wrapper }
    return true
end

function API.SetSilentEnabled(enabled)
    if enabled then
        if not classes.Firearm then discoverRegistry() end
        local ok, failure = patchMethod("Silent", classes.Firearm, "GetMuzzleCFrame", function(original)
            return function(inventory, castCheck, ...)
                if not API.Running or not S.Silent.Enabled or castCheck == true
                    or rawget(inventory, "_shooting") ~= true
                    or not isLocalActor(rawget(inventory, "_actor")) then
                    return original(inventory, castCheck, ...)
                end
                local result = table.pack(original(inventory, castCheck, ...))
                if API.Running and S.Silent.Enabled and castCheck ~= true and rawget(inventory, "_shooting") == true
                    and isLocalActor(rawget(inventory, "_actor")) and typeof(result[1]) == "CFrame"
                    and (not S.Silent.RequireHold or aimHeld())
                    and math.random(1, 100) <= S.Silent.HitChance then
                    local success, target = pcall(API.FindAimTarget, nil, S.Silent)
                    if success and target then
                        local corrected, frame = pcall(API.GetSilentFrame, result[1], target, inventory)
                        if corrected then
                            result[1] = frame
                            API.SilentTarget = rawget(target, "UID")
                            API.SilentRedirects = (API.SilentRedirects or 0) + 1
                            API.SilentError = nil
                        else API.SilentError = tostring(frame) end
                    elseif not success then API.SilentError = tostring(target) end
                end
                return table.unpack(result, 1, result.n)
            end
        end)
        if not ok then S.Silent.Enabled = false; API.SilentError = failure; return false, failure end
    end
    S.Silent.Enabled = enabled
    API.SilentTarget, API.SilentError = nil, nil
    return true
end

function API.SetNoFallDamage(enabled)
    if enabled then
        if not classes.Controller then discoverRegistry() end
        local ok, failure = patchMethod("Fall", classes.Controller, "Update", function(original)
            return function(controller, ...)
                API.ClampFallVelocity(controller)
                local result = table.pack(original(controller, ...))
                API.ClampFallVelocity(controller)
                return table.unpack(result, 1, result.n)
            end
        end)
        if not ok then S.NoFallDamage = false; API.FallError = failure; return false, failure end
    end
    S.NoFallDamage, API.FallError = enabled, nil
    return true
end

function API.GetGameplayStatus()
    return { FirearmFound = classes.Firearm ~= nil, ControllerFound = classes.Controller ~= nil,
        BallisticsFound = classes.Bullet ~= nil, SilentPatched = patches.Silent ~= nil,
        FallPatched = patches.Fall ~= nil or patches.Movement ~= nil, ACBypass = false }
end
function API.NeedsDiscovery()
    return registry == nil or classes.Controller == nil or classes.Firearm == nil
end

local function aimStep(dt)
    if API.FeatureStep then API.FeatureStep(dt) end
    local camera = workspace.CurrentCamera
    if not camera or not API.Running then return end
    if aimCircle then
        local visible = (S.Aim.Enabled or S.Silent.Enabled) and S.Aim.ShowCircle
        if aimVisual.visible ~= visible then aimCircle.Visible = visible; aimVisual.visible = visible end
        if visible then
            if aimVisual.viewport ~= camera.ViewportSize then
                aimCircle.Position = UDim2.fromOffset(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                aimVisual.viewport = camera.ViewportSize
            end
            if aimVisual.radius ~= S.Aim.Radius then aimCircle.Size = UDim2.fromOffset(S.Aim.Radius * 2, S.Aim.Radius * 2); aimVisual.radius = S.Aim.Radius end
            if aimVisual.color ~= S.Aim.FOVColor then
                local stroke = aimCircle:FindFirstChildWhichIsA("UIStroke")
                if stroke then stroke.Color = S.Aim.FOVColor end
                aimVisual.color = S.Aim.FOVColor
            end
        end
    end
    if S.Aim.Mode == "BRM5 Camera" then return end
    if not S.Aim.Enabled or not aimHeld() then
        aimTarget, API.AimTarget = nil, nil
        mouseRemainder = Vector2.zero
        lastAimScan = 0
        return
    end
    if os.clock() - lastAimScan >= 0.08 then
        if not S.Aim.StickToTarget or not aimTarget or not API.IsTargetActor(aimTarget, S.Aim) then aimTarget = API.FindAimTarget() end
        lastAimScan = os.clock()
    end
    if not aimTarget or not API.IsTargetActor(aimTarget, S.Aim) then aimTarget, API.AimTarget = nil, nil; return end
    local part = aimPart(aimTarget)
    if not part then aimTarget, API.AimTarget = nil, nil; return end
    local goal = API.GetTargetPosition and API.GetTargetPosition(aimTarget, S.Aim) or part.Position
    local screen, onScreen = camera:WorldToViewportPoint(goal)
    local delta = Vector2.new(screen.X, screen.Y) - camera.ViewportSize / 2
    if not onScreen or S.Aim.UseFOV and delta.Magnitude > S.Aim.Radius
        or (part.Position - camera.CFrame.Position).Magnitude > S.Aim.Distance
        or not visibleTarget(camera, part, rawget(aimTarget, "Character")) then
        aimTarget, API.AimTarget = nil, nil; return
    end
    API.AimTarget = rawget(aimTarget, "UID")
    local blend = S.Aim.Smoothing == 0 and 1
        or 1 - math.exp(-((100 - S.Aim.Smoothing) * 0.6 + 4) * math.min(dt, 0.05))
    if S.Aim.Mode == "Mouse" then
        if type(mousemoverel) ~= "function" then
            API.AimError = "mousemoverel is unavailable; select Camera mode."
            return
        end
        local move = delta * blend + mouseRemainder
        local x, y = math.round(math.clamp(move.X, -60, 60)), math.round(math.clamp(move.Y, -60, 60))
        mouseRemainder = Vector2.new(move.X - x, move.Y - y)
        mousemoverel(x, y)
    else
        camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, goal), blend)
    end
    API.AimError = nil
end

local function makeRecord(key)
    local r = records[key]
    if not r then
        r = { lastSeen = os.clock(), lastShown = 0 }
        records[key] = r
        API.CacheMetrics.Entities = API.CacheMetrics.Entities + 1
    end
    return r
end

local function hideOutline(r)
    if r.outlineShowing and r.highlightSlot then r.highlightSlot.object.Enabled = false end
    r.outlineShowing = false
end
local function hideMarker(r)
    if r.markerShowing and r.markerSlot then r.markerSlot.object.Visible = false end
    r.markerShowing, r.markerVisible = false, false
end

local function acquireSlot(pool, r, marker)
    local field = marker and "markerSlot" or "highlightSlot"
    if r[field] then return r[field].object end
    local slot
    for _, entry in ipairs(pool) do
        if not entry.owner or not (marker and entry.owner.markerShowing or not marker and entry.owner.outlineShowing) then slot = entry; break end
    end
    if not slot then
        local limit = marker and S.Performance.MaxMarkers or S.Performance.MaxHighlights
        if #pool >= limit then return nil end
        local obj = Instance.new(marker and "TextLabel" or "Highlight")
        obj.Name = marker and "BRM5_Marker" or "BRM5_Highlight"
        if marker then
            obj.Size = UDim2.fromOffset(200, 38)
            obj.AnchorPoint = Vector2.new(0.5, 1)
            obj.BackgroundTransparency = 1
            obj.Font = Enum.Font.GothamBold
            obj.TextSize, obj.TextStrokeTransparency = 12, 0.25
            obj.Visible, obj.Parent = false, markers
            API.CacheMetrics.MarkersCreated = API.CacheMetrics.MarkersCreated + 1
        else
            obj.Enabled, obj.Parent = false, folder
            API.CacheMetrics.HighlightsCreated = API.CacheMetrics.HighlightsCreated + 1
        end
        slot = { object = obj }
        table.insert(pool, slot)
    else API.CacheMetrics.Reuses = API.CacheMetrics.Reuses + 1 end
    if slot.owner then slot.owner[field] = nil end
    slot.owner, r[field] = r, slot
    if marker then r.lastText, r.lastMarkerColor, r.lastPosition, r.markerVisible = nil, nil, nil, false
    else r.lastModel, r.lastColor, r.lastFill, r.lastOutline, r.lastDepth = nil, nil, nil, nil, nil end
    return slot.object
end

local function updateVisual(c, allowOutline, allowMarker)
    local r = makeRecord(c.key)
    local color = S.Colors[c.kind]
    local depth = S.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop
        or Enum.HighlightDepthMode.Occluded
    r.lastShown, r.lastSeen = os.clock(), os.clock()
    r.actor, r.root, r.worldPosition = c.actor, c.root, c.position
    if c.rendered and allowOutline then
        local h = acquireSlot(highlightPool, r, false)
        if h then
            if r.lastModel ~= c.model then h.Adornee = c.model; r.lastModel = c.model end
            if r.lastColor ~= color then h.FillColor, h.OutlineColor = color, color; r.lastColor = color end
            if r.lastFill ~= S.Fill then h.FillTransparency = S.Fill; r.lastFill = S.Fill end
            if r.lastOutline ~= S.Outline then h.OutlineTransparency = S.Outline; r.lastOutline = S.Outline end
            if r.lastDepth ~= depth then h.DepthMode = depth; r.lastDepth = depth end
            if not r.outlineShowing then h.Enabled = true; r.outlineShowing = true end
        end
    else hideOutline(r) end
    if allowMarker then
        local clear = true
        if not S.ThroughWalls then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local excluded = { workspace.CurrentCamera, folder }
            if API.LocalCharacter then table.insert(excluded, API.LocalCharacter) end
            params.FilterDescendantsInstances = excluded
            local origin = workspace.CurrentCamera.CFrame.Position
            local hit = workspace:Raycast(origin, c.position - origin, params)
            clear = not hit or c.model and hit.Instance:IsDescendantOf(c.model)
        end
        local label = clear and acquireSlot(markerPool, r, true)
        if label then
            local position = UDim2.fromOffset(math.floor(c.screen.X + 0.5), math.floor(c.screen.Y + 0.5))
            local text = S.Names and (c.name .. " | " .. math.floor(c.distance) .. " studs") or "[+]"
            if r.lastText ~= text then label.Text = text; r.lastText = text end
            if r.lastMarkerColor ~= color then label.TextColor3 = color; r.lastMarkerColor = color end
            if r.lastPosition ~= position then label.Position = position; r.lastPosition = position end
            local visible = c.screen.Z > 0 and (not S.Performance.ViewportFilter or c.onScreen)
            if r.markerVisible ~= visible then label.Visible = visible; r.markerVisible = visible end
            r.markerShowing = true
        else hideMarker(r) end
    else hideMarker(r) end
    r.kind = c.kind
end

function API.ProjectCachedMarkers()
    local camera = workspace.CurrentCamera
    if not camera then return end
    for _, slot in ipairs(markerPool) do
        local r = slot.owner
        if r and r.markerShowing then
            local position = r.worldPosition
            local actor = r.actor
            if actor then
                if rawget(actor, "Alive") == false or type(rawget(actor, "Health")) == "number" and rawget(actor, "Health") <= 0 then
                    hideMarker(r); hideOutline(r)
                    continue
                end
                local model, root = rawget(actor, "Character"), rawget(actor, "RootPart")
                if model and root and model:IsDescendantOf(workspace) then position = root.Position else position = rawget(actor, "Position") end
            elseif r.root and r.root.Parent then position = r.root.Position end
            if typeof(position) == "Vector3" then
                local p, onScreen = camera:WorldToViewportPoint(position + Vector3.new(0, 4, 0))
                local visible = p.Z > 0 and (not S.Performance.ViewportFilter or onScreen)
                if r.markerVisible ~= visible then slot.object.Visible = visible; r.markerVisible = visible end
                if visible then
                    local pixels = UDim2.fromOffset(math.floor(p.X + 0.5), math.floor(p.Y + 0.5))
                    if r.lastPosition ~= pixels then slot.object.Position = pixels; r.lastPosition = pixels end
                end
            end
        end
    end
end

local function sweepCache(present, now)
    for key, r in pairs(records) do
        if present[key] then r.lastSeen = now end
    end
    if now - lastCacheSweep < 3 then return end
    lastCacheSweep = now
    local dormant = {}
    for key, r in pairs(records) do
        if not r.outlineShowing and not r.markerShowing then
            if not present[key] and now - r.lastSeen > S.Performance.CacheTTL then discard(key)
            else table.insert(dormant, {key = key, time = r.lastShown}) end
        end
    end
    if API.CacheMetrics.Entities > S.Performance.MaxCachedEntities then
        table.sort(dormant, function(a, b) return a.time < b.time end)
        for _, entry in ipairs(dormant) do
            if API.CacheMetrics.Entities <= S.Performance.MaxCachedEntities then break end
            discard(entry.key)
        end
    end
end

function API.HighlightStep()
    if not API.Running or not S.Performance.HighlightOnly then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local wanted, selected, count = {}, {}, 0
    if S.Enabled then
        for _, entry in ipairs(API.RenderedESPActors or {}) do
            local model, root = entry.model, entry.root
            if entry.actor then model, root = rawget(entry.actor, "Character"), rawget(entry.actor, "RootPart") end
            local alive = not entry.actor or rawget(entry.actor, "Alive") ~= false
                and (type(rawget(entry.actor, "Health")) ~= "number" or rawget(entry.actor, "Health") > 0)
            if alive and S[entry.kind] and model and root and model:IsDescendantOf(workspace)
                and (root.Position - camera.CFrame.Position).Magnitude <= S.MaxDistance then
                if count >= S.Performance.MaxHighlights then break end
                count = count + 1
                wanted[entry.key] = true
                entry.model, entry.root = model, root
                table.insert(selected, entry)
            end
        end
    end
    for key, r in pairs(records) do
        if not wanted[key] then hideOutline(r) end
        if r.markerShowing then hideMarker(r) end
    end
    for _, entry in ipairs(selected) do updateVisual(entry, true, false) end
    API.Performance.MarkerCount = 0
    API.ActiveHighlightCount = count
end

function API.Refresh()
    if not API.Running then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local refreshStart = os.clock()
    local origin = camera.CFrame.Position
    local candidates, linked, localModel, present = {}, {}, LP.Character, {}
    local totals = { Enemies = 0, NPCs = 0, Players = 0 }
    local renderedActors = {}
    local espActors = {}
    local function add(key, kind, model, root, pos, name, actor)
        totals[kind] = totals[kind] + 1
        if not S.Enabled or not S[kind] or typeof(pos) ~= "Vector3" then return end
        local distance = (pos - origin).Magnitude
        if distance > S.MaxDistance then return end
        local screen, onScreen = camera:WorldToViewportPoint(pos + Vector3.new(0, 4, 0))
        local rendered = model and model:IsDescendantOf(workspace) or false
        if not rendered and S.Performance.ViewportFilter and not onScreen then return end
        table.insert(candidates, { key = key, kind = kind, model = model,
            root = root, position = pos, name = name, distance = distance,
            rendered = rendered, screen = screen, onScreen = onScreen, actor = actor })
    end
    if registry then
        for uid, actor in next, registry do
            if type(uid) == "string" and isActor(actor) and rawget(actor, "UID") == uid then
                local model, root = rawget(actor, "Character"), rawget(actor, "RootPart")
                if rawget(actor, "Alive") ~= false and (type(rawget(actor, "Health")) ~= "number" or rawget(actor, "Health") > 0) then present[uid] = true end
                if model:IsDescendantOf(workspace) then table.insert(renderedActors, actor) end
                linked[model] = true
                local owner = playerOwner(actor)
                if owner == LP or rawget(actor, "IsLocalPlayer") == true then
                    localModel = model
                    API.LocalActor = actor
                elseif rawget(actor, "Alive") ~= false
                    and (type(rawget(actor, "Health")) ~= "number" or rawget(actor, "Health") > 0) then
                    local rendered = model:IsDescendantOf(workspace)
                    local pos = rendered and root:IsA("BasePart") and root.Position or rawget(actor, "Position")
                    if rendered then table.insert(espActors, { key = uid, actor = actor, kind = owner and "Players" or "Enemies", model = model, root = root, rendered = true }) end
                    add(uid, owner and "Players" or "Enemies", model, root, pos,
                        owner and owner.DisplayName or "Enemy", actor)
                end
            end
        end
    end
    API.LocalCharacter = localModel
    API.AimActors = renderedActors
    for model in pairs(rigs) do
        if not model:IsDescendantOf(workspace) then rigs[model] = nil
        elseif model ~= localModel and not linked[model] then
            local root = getRoot(model)
            local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
            if root and root:IsA("BasePart") and torso then
                local owner = Players:GetPlayerFromCharacter(model)
                local humanoid = model:FindFirstChildWhichIsA("Humanoid")
                -- ActorUID rigs are dynamic actors; wait for the registry rather
                -- than temporarily calling a player or enemy a passive NPC.
                if owner ~= LP and not root:GetAttribute("ActorUID")
                    and (not humanoid or humanoid.Health > 0) then
                    present[model] = true
                    table.insert(espActors, { key = model, kind = owner and "Players" or "NPCs", model = model, root = root, rendered = true })
                    add(model, owner and "Players" or "NPCs", model, root, root.Position,
                        owner and owner.DisplayName or "Passive NPC")
                end
            end
        end
    end
    table.sort(espActors, function(a, b) return (a.root.Position - origin).Magnitude < (b.root.Position - origin).Magnitude end)
    API.RenderedESPActors = espActors
    table.sort(candidates, function(a, b) return a.distance < b.distance end)
    local keep, selected, shown, outlineCount, markerCount = {}, {}, { Enemies = 0, NPCs = 0, Players = 0 }, 0, 0
    for i, c in ipairs(candidates) do
        local outlineWanted = c.rendered and outlineCount < S.Performance.MaxHighlights
        local markerWanted = not S.Performance.HighlightOnly and (S.Markers or S.Names and c.rendered)
            and c.screen.Z > 0 and (not S.Performance.ViewportFilter or c.onScreen) and markerCount < S.Performance.MaxMarkers
        if outlineWanted or markerWanted then
            if outlineWanted then outlineCount = outlineCount + 1 end
            if markerWanted then markerCount = markerCount + 1 end
            table.insert(selected, { candidate = c, outline = outlineWanted, marker = markerWanted })
            keep[c.key] = { outline = outlineWanted, marker = markerWanted }
        end
    end
    -- Release visibility first, preserving the underlying objects. Newly visible
    -- actors can reuse an existing pool slot in the very same refresh.
    for key, r in pairs(records) do
        local wanted = keep[key]
        if not wanted or not wanted.outline then hideOutline(r) end
        if not wanted or not wanted.marker then hideMarker(r) end
    end
    for _, entry in ipairs(selected) do updateVisual(entry.candidate, entry.outline, entry.marker) end
    if S.Performance.HighlightOnly then API.HighlightStep() end
    sweepCache(present, os.clock())
    outlineCount, markerCount = 0, 0
    for _, entry in ipairs(selected) do
        local r = records[entry.candidate.key]
        if r and (r.outlineShowing or r.markerShowing) then shown[entry.candidate.kind] = shown[entry.candidate.kind] + 1 end
        if r and r.outlineShowing then outlineCount = outlineCount + 1 end
        if r and r.markerShowing then markerCount = markerCount + 1 end
    end
    API.Stats = { Found = totals, Shown = shown, Outlines = outlineCount, Markers = markerCount, Registry = registry ~= nil }
    if statusLabel then
        statusLabel:Set(string.format("Active: Enemies %d | NPCs %d | Players %d",
            shown.Enemies, shown.NPCs, shown.Players))
    end
    if aimStatus then
        aimStatus:Set(API.AimError or (not S.Aim.Enabled and "Aimbot disabled"
            or API.AimTarget and "Target: hostile AI"
            or "Ready - hold the aim key"))
    end
    if gameplayStatus then
        gameplayStatus:Set(API.SilentError or API.FallError or string.format("Silent aim: %s | Fall protection: %s",
            S.Silent.Enabled and "on" or "off", S.NoFallDamage and "on" or "off"))
    end
    if API.UpdateFeatureStatus then API.UpdateFeatureStatus() end
    API.Performance.RefreshMs = (os.clock() - refreshStart) * 1000
    API.Performance.WorstRefreshMs = math.max(API.Performance.WorstRefreshMs, API.Performance.RefreshMs)
    API.Performance.MarkerCount = markerCount
end


-- Extended BRM5 features; inserted into the same script before UI construction.
local weapons = setmetatable({}, { __mode = "k" })
local velocitySamples = setmetatable({}, { __mode = "k" })
local dataChanges = {}
local worldChanges = {}
local worldCandidates = setmetatable({}, { __mode = "k" })
local flyPositions = setmetatable({}, { __mode = "k" })
local featureGui, crossBars, crossDot, targetLine
local configControls, configStatus, movementStatus, gunStatus
local autoWeapon, autoBusy = nil, false
local lastSample, lastAuto = 0, 0
local worldWriting = false
local worldDirty, lastWorldMask = true, nil
local lastOverlay = {}
local lineTarget, nextLineScan = nil, 0
local frameTime, frameCount, worstFrame = 0, 0, 0
local nextMarkerProjection = 0
local frameWorkTime = 0
local highlightAccumulator = 0
local cfgRoot = "Vantix/BRM5"
local configName, selectedConfig = "", nil
local defaults = {}
for k, v in pairs(S) do defaults[k] = type(v) == "table" and table.clone(v) or v end

local sourceClasses = {
    Camera = { "Update", "ReplicatedFirst.Flux/client.Services.CameraService.CharacterCamera" },
    View = { "Update", "ReplicatedFirst.Flux/client.Services.ViewmodelService.ViewmodelClass" },
    Recoil = { "GetCameraAdjustment", "ReplicatedFirst.Flux/client.Services.ViewmodelService.Recoiler" },
    VehicleSolver = { "Update", "ReplicatedStorage.Shared.Vehicle.VehicleSolver" },
}
function API.DiscoverFeatureTable(t)
    for key, spec in pairs(sourceClasses) do
        local fn = rawget(t, spec[1])
        if type(fn) == "function" then
            local ok, src = pcall(debug.info, fn, "s")
            if ok and src == spec[2] then classes[key] = t end
        end
    end
    if type(rawget(t, "_actor")) == "table" and type(rawget(t, "_firearm")) == "table" then
        weapons[t] = true
    end
end

local function activeInput()
    if UIS:GetFocusedTextBox() then return false end
    if type(isrbxactive) == "function" and not isrbxactive() then return false end
    if Window and Window.IsMinimized and not Window:IsMinimized() then return false end
    return true
end

function API.IsTargetActor(actor, settings)
    settings = settings or S.Aim
    if not isActor(actor) or isLocalActor(actor) or rawget(actor, "Alive") == false then return false end
    local health = rawget(actor, "Health")
    if type(health) == "number" and health <= 0 then return false end
    local model = rawget(actor, "Character")
    if not model:IsA("Model") or not model:IsDescendantOf(workspace) then return false end
    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    if humanoid and humanoid.Health <= 0 then return false end
    local owner = playerOwner(actor)
    if owner then
        if not settings.TargetPlayers then return false end
        -- BRM5 PvE operators are allies; team check keeps them excluded even
        -- when the game does not assign Roblox Team objects.
        if settings.TeamCheck and (not LP.Team or not owner.Team or LP.Team == owner.Team) then return false end
        return true
    end
    return settings.TargetNPCs and rawget(actor, "Owner") == nil and rawget(actor, "OwnerName") == "???"
end

function API.GetTargetPosition(actor, settings)
    local part = aimPart(actor, settings)
    if not part then return nil end
    local sample = velocitySamples[actor]
    local lead = math.clamp((settings.Prediction or 0) / 1000, 0, 0.5)
    return part.Position + (sample and sample.velocity or Vector3.zero) * lead
end

function API.TargetUsable(actor, settings)
    if not actor or not API.IsTargetActor(actor, settings) then return false end
    local camera, part = workspace.CurrentCamera, aimPart(actor, settings)
    if not camera or not part then return false end
    local p, onScreen = camera:WorldToViewportPoint(part.Position)
    return onScreen and p.Z > 0 and (part.Position - camera.CFrame.Position).Magnitude <= settings.Distance
        and (not settings.UseFOV or (Vector2.new(p.X, p.Y) - camera.ViewportSize / 2).Magnitude <= (settings.Radius or S.Aim.Radius))
        and visibleTarget(camera, part, rawget(actor, "Character"), settings)
end

local nativeAimTarget
local nextNativeScan = 0
local function driveCamera(cameraController, dt, beforeX, beforeY)
    if not S.Aim.Enabled or S.Aim.Mode ~= "BRM5 Camera" or not activeInput() or not aimHeld() then
        nativeAimTarget, API.AimTarget = nil, nil
        nextNativeScan = 0
        return
    end
    local usable = API.TargetUsable(nativeAimTarget, S.Aim)
    if os.clock() >= nextNativeScan and (not S.Aim.StickToTarget or not usable) then
        nativeAimTarget = API.FindAimTarget(nil, S.Aim)
        nextNativeScan = os.clock() + 0.08
        usable = API.TargetUsable(nativeAimTarget, S.Aim)
    end
    if not usable then API.AimTarget = nil; return end
    local camera = workspace.CurrentCamera
    local goal = API.GetTargetPosition(nativeAimTarget, S.Aim)
    local desired = CFrame.lookAt(camera.CFrame.Position, goal)
    local currentPitch, currentYaw = camera.CFrame:ToOrientation()
    local pitch, yaw = desired:ToOrientation()
    -- The rendered CFrame is from the prior frame. Correct the current
    -- controller angles, rather than adding that prior frame's error again.
    local yawBase = currentYaw - beforeX
    local pitchBase = currentPitch - beforeY
    local targetX, targetY = yaw - yawBase, pitch - pitchBase
    local yawDelta = math.atan2(math.sin(targetX - cameraController._x), math.cos(targetX - cameraController._x))
    local alpha = S.Aim.Smoothing == 0 and 1 or 1 - math.exp(-((100 - S.Aim.Smoothing) * 0.6 + 4) * math.min(dt, 0.05))
    cameraController._x = cameraController._x + yawDelta * alpha
    cameraController._y = math.clamp(cameraController._y + (targetY - cameraController._y) * alpha,
        cameraController._yLimitDown or -1.5, cameraController._yLimitUp or 1.5)
    local actor = cameraController._localActor
    actor.CameraX, actor.CameraY = cameraController._x, cameraController._y
    API.AimTarget = rawget(nativeAimTarget, "UID")
end

function API.GetFlightVector(cameraFrame, input)
    local x, z, y
    if input then x, z, y = input.X, input.Z, input.Y
    elseif activeInput() then
        x = (UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
        z = (UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
        y = (UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0)
    else x, z, y = 0, 0, 0 end
    local vector = cameraFrame.RightVector * x + cameraFrame.LookVector * z + Vector3.yAxis * y
    return vector.Magnitude > 1 and vector.Unit or vector
end

function API.ApplyCharacterFlight(controller, dt, input)
    local actor = rawget(controller, "_localActor")
    if not S.Player.Fly or not isLocalActor(actor) or actor.Alive == false or actor.Downed or actor.Seat then return false end
    local camera = workspace.CurrentCamera
    if not camera then return false end
    local position = flyPositions[controller] or actor.SimulatedPosition or actor.Position or controller._position
    if typeof(position) ~= "Vector3" then return false end
    position = position + API.GetFlightVector(camera.CFrame, input) * S.Player.FlySpeed * math.clamp(dt, 0, 0.05)
    flyPositions[controller] = position
    controller._position, controller._lastSafePosition = position, position
    controller._groundHitbox, controller._correctedPosition = nil, nil
    controller.VelocityGravity, controller.MoveSpeed = 0, 0
    controller.IsGrounded, controller.IsSliding, controller.IsSprinting = false, false, false
    controller._lastMovement = Vector2.zero
    actor.Platform, actor.SimulatedPosition = nil, position
    actor.Grounded, actor.Sliding, actor.Sprinting, actor.Walking = false, false, false, false
    API.FlyActive = true
    return true
end

function API.ApplyVehicleFlight(solver, dt, input, testOwner)
    local actor = API.LocalActor
    local controller = actor and actor.Controller
    local owned = testOwner or type(controller) == "table" and rawget(controller, "_solver") == solver
    local vehicle = rawget(solver, "_vehicle")
    if not S.Vehicle.Fly or not owned or type(vehicle) ~= "table" or vehicle.Alive == false then return nil end
    local state = rawget(solver, "_state")
    local frame = flyPositions[solver] or type(state) == "table" and state.CFrame or vehicle.CFrame
    local camera = workspace.CurrentCamera
    if typeof(frame) ~= "CFrame" or not camera then return nil end
    local velocity = API.GetFlightVector(camera.CFrame, input) * S.Vehicle.FlySpeed
    local position = frame.Position + velocity * math.clamp(dt, 0, 0.05)
    local _, yaw = camera.CFrame:ToOrientation()
    local nextFrame = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    flyPositions[solver] = nextFrame
    solver:SetState(nextFrame, Vector3.zero, Vector3.zero, vehicle.ComponentReplicates)
    if state then state.CFrame = nextFrame end
    solver._state = state or { CFrame = nextFrame, RotorBlades = {}, Transmissions = {} }
    API.VehicleFlyActive = true
    return nextFrame, solver:GetReplicateEffects()
end

local function syncData(target, wanted)
    local record = dataChanges[target]
    if not record and next(wanted) then record = {}; dataChanges[target] = record end
    if not record then return end
    for key, value in pairs(wanted) do
        if not record[key] then record[key] = { value = rawget(target, key) } end
        target[key] = value
    end
    for key, original in pairs(record) do
        if wanted[key] == nil then target[key] = original.value; record[key] = nil end
    end
    if not next(record) then dataChanges[target] = nil end
end

local function baseValue(target, key)
    local r = dataChanges[target]
    return r and r[key] and r[key].value or rawget(target, key)
end

function API.ApplyGunMods(inventory)
    if not API.Running then return end
    local actor, firearm = rawget(inventory, "_actor"), rawget(inventory, "_firearm")
    if not isLocalActor(actor) or type(firearm) ~= "table" or type(firearm.Tune) ~= "table" then return end
    local tune, wanted = firearm.Tune, {}
    if S.Gun.NoRecoil then
        for key, value in pairs(tune) do
            if type(key) == "string" and (key:find("^Recoil_") or key:find("^RecoilForce_")) then
                if type(value) == "number" then wanted[key] = 0
                elseif typeof(value) == "Vector2" then wanted[key] = Vector2.zero end
            end
        end
    end
    if S.Gun.NoSpread then wanted.Barrel_Spread = 0 end
    if S.Gun.FastFireRate then wanted.RPM = (baseValue(tune, "RPM") or 600) * S.Gun.RateMultiplier end
    if S.Gun.InstantEquip or S.Gun.NoShootDelay then wanted.Equip_Delay = 0 end
    if S.Gun.NoShootDelay then
        for _, key in ipairs({ "Bolt", "Bolt_Action_Pause", "ProneDelay" }) do
            if baseValue(tune, key) ~= nil then wanted[key] = 0 end
        end
        inventory._next = 0
    end
    syncData(tune, wanted)
end

local function ownedRecoil(recoil)
    local actor = API.LocalActor
    return actor and type(actor.ViewModel) == "table" and actor.ViewModel.Recoil == recoil
end

function API.EnsureController()
    if not classes.Controller then return false, "Character controller was not found." end
    return patchMethod("Movement", classes.Controller, "Update", function(original)
        return function(controller, input, dt, ...)
            if not API.Running or not isLocalActor(rawget(controller, "_localActor")) then return original(controller, input, dt, ...) end
            if not S.Player.Fly and not S.NoFallDamage then
                flyPositions[controller], API.FlyActive = nil, false
                return original(controller, input, dt, ...)
            end
            if API.Running and isLocalActor(rawget(controller, "_localActor")) then
                if API.ApplyCharacterFlight(controller, dt) then return end
                flyPositions[controller] = nil
                API.FlyActive = false
                API.ClampFallVelocity(controller)
            end
            local result = table.pack(original(controller, input, dt, ...))
            if API.Running then API.ClampFallVelocity(controller) end
            return table.unpack(result, 1, result.n)
        end
    end)
end

-- Replace the earlier fall-only wrapper with one shared controller hook.
function API.SetNoFallDamage(enabled)
    if enabled then local ok, failure = API.EnsureController(); if not ok then return false, failure end end
    S.NoFallDamage, API.FallError = enabled, nil
    return true
end

function API.InstallFeatureHooks()
    local function install(key, classKey, method, factory)
        if classes[classKey] then return patchMethod(key, classes[classKey], method, factory) end
        return false
    end
    API.EnsureController()
    install("CameraAim", "Camera", "Update", function(original)
        return function(controller, input, dt, ...)
            if not API.Running or not S.Aim.Enabled or S.Aim.Mode ~= "BRM5 Camera"
                or not isLocalActor(rawget(controller, "_localActor")) then
                nativeAimTarget, API.AimTarget, nextNativeScan = nil, nil, 0
                return original(controller, input, dt, ...)
            end
            local beforeX, beforeY = controller._x, controller._y
            local result = table.pack(original(controller, input, dt, ...))
            if API.Running and isLocalActor(rawget(controller, "_localActor")) then
                local ok, failure = pcall(driveCamera, controller, dt, beforeX, beforeY)
                API.AimError = not ok and tostring(failure) or nil
            end
            return table.unpack(result, 1, result.n)
        end
    end)
    install("VehicleFlight", "VehicleSolver", "Update", function(original)
        return function(solver, dt, ...)
            if API.Running and S.Vehicle.Fly then
                local frame, effects = API.ApplyVehicleFlight(solver, dt)
                if frame then return frame, effects end
            end
            if flyPositions[solver] then
                -- Synchronize the substepper to the last flight position before
                -- handing simulation back to the normal physics integrator.
                local stepper = rawget(solver, "_subStepper")
                if type(stepper) == "table" then
                    for key, value in pairs(stepper) do
                        if type(value) == "table" and typeof(rawget(value, "CFrame")) == "CFrame" then value.CFrame = flyPositions[solver] end
                    end
                end
                flyPositions[solver] = nil
                API.VehicleFlyActive = false
            end
            return original(solver, dt, ...)
        end
    end)
    install("Speed", "Controller", "_accelerate", function(original)
        return function(controller, ...)
            if not API.Running or not S.Player.WalkSpeed or not isLocalActor(rawget(controller, "_localActor")) then return original(controller, ...) end
            local before = controller._weightMulti
            controller._weightMulti = before * (controller.IsSprinting and S.Player.SprintMultiplier or S.Player.SpeedMultiplier)
            local result = table.pack(pcall(original, controller, ...))
            controller._weightMulti = before
            if not result[1] then error(result[2]) end
            return table.unpack(result, 2, result.n)
        end
    end)
    install("Exhaustion", "Controller", "_exhaust", function(original)
        return function(controller, duration, ...)
            if API.Running and isLocalActor(rawget(controller, "_localActor"))
                and (S.Player.InfiniteStamina or S.Player.NoJumpCooldown and duration <= 0.5) then
                controller._exhaustStart, controller._exhausted = tick() - 2, tick() - 1
                return true
            end
            return original(controller, duration, ...)
        end
    end)
    install("JumpPower", "Controller", "Jump", function(original)
        return function(controller, ...)
            local grounded = controller.IsGrounded
            local result = table.pack(original(controller, ...))
            if API.Running and grounded and S.Player.JumpPower and isLocalActor(rawget(controller, "_localActor")) and controller.VelocityGravity == 25 then
                controller.VelocityGravity = S.Player.JumpVelocity
            end
            return table.unpack(result, 1, result.n)
        end
    end)
    install("FireModes", "Firearm", "_getFiremode", function(original)
        return function(inventory, ...)
            if API.Running and S.Gun.FireModeOverride and isLocalActor(rawget(inventory, "_actor")) and not inventory._reloading then
                return S.Gun.FireMode == "Auto" and 2 or S.Gun.FireMode == "Burst" and 3 or 1
            end
            return original(inventory, ...)
        end
    end)
    install("ADS", "Firearm", "_ads", function(original)
        return function(inventory, value, ...)
            if API.Running and S.Gun.NoADS and isLocalActor(rawget(inventory, "_actor")) then value = false end
            return original(inventory, value, ...)
        end
    end)
    install("GunEquip", "Firearm", "Equip", function(original)
        return function(inventory, ...)
            if API.Running then API.ApplyGunMods(inventory) end
            local result = table.pack(original(inventory, ...))
            if API.Running and isLocalActor(rawget(inventory, "_actor")) then
                weapons[inventory] = true
                API.CurrentWeapon = inventory
                if S.Gun.InstantEquip then inventory._next = 0 end
            end
            return table.unpack(result, 1, result.n)
        end
    end)
    install("DischargeMods", "Firearm", "_discharge", function(original)
        return function(inventory, value, ...)
            if API.Running then API.ApplyGunMods(inventory) end
            return original(inventory, value, ...)
        end
    end)
    install("RecoilView", "Recoil", "GetViewmodelAdjustment", function(original)
        return function(recoil, ...)
            if API.Running and S.Gun.NoRecoil and ownedRecoil(recoil) then return CFrame.identity end
            return original(recoil, ...)
        end
    end)
    install("RecoilCamera", "Recoil", "GetCameraAdjustment", function(original)
        return function(recoil, ...)
            if API.Running and S.Gun.NoRecoil and ownedRecoil(recoil) then return CFrame.identity, 0 end
            return original(recoil, ...)
        end
    end)
    install("ViewSway", "View", "Update", function(original)
        local proxies = setmetatable({}, { __mode = "k" })
        local zeroRotation = { ToCFrame = function() return CFrame.identity end }
        return function(view, ...)
            if not API.Running or not S.Gun.NoSway or not isLocalActor(rawget(view, "Actor")) then return original(view, ...) end
            local spring = view._swaySpring
            local cached = proxies[view]
            if not cached or cached.spring ~= spring then
                cached = { spring = spring }
                cached.proxy = setmetatable({}, {
                    __index = function(_, key) return key == "Position" and zeroRotation or spring[key] end,
                    __newindex = function(_, key, value) spring[key] = value end,
                })
                proxies[view] = cached
            end
            view._swaySpring = cached.proxy
            local result = table.pack(pcall(original, view, ...))
            view._swaySpring = spring
            if not result[1] then error(result[2]) end
            return table.unpack(result, 2, result.n)
        end
    end)
end

local function desiredWorldProperty(inst, prop)
    if inst == Lighting then
        if prop == "ClockTime" and S.World.Daytime then return 12 end
        if prop == "GlobalShadows" and (S.World.NoShadows or S.World.NoLighting) then return false end
        if S.World.NoLighting then
            if prop == "Brightness" then return 2 end
            if prop == "Ambient" or prop == "OutdoorAmbient" then return Color3.new(1, 1, 1) end
            if prop == "FogEnd" then return 1000000 end
        elseif S.World.Daytime then
            if prop == "Brightness" then return 2.5 end
            if prop == "Ambient" or prop == "OutdoorAmbient" then return Color3.fromRGB(170, 170, 170) end
        end
    elseif inst:IsA("Clouds") and prop == "Enabled" and S.World.NoClouds then return false
    elseif inst:IsA("Atmosphere") and prop == "Density" and S.World.NoLighting then return 0
    elseif inst:IsA("PostEffect") and prop == "Enabled" and S.World.NoLighting then return false
    elseif inst:IsA("BasePart") and prop == "LocalTransparencyModifier" and S.World.NoLeaves then return 1 end
    return nil
end

local function worldProperty(inst, prop)
    local wanted = desiredWorldProperty(inst, prop)
    local fields = worldChanges[inst]
    if wanted ~= nil then
        if not fields then fields = {}; worldChanges[inst] = fields end
        if not fields[prop] then fields[prop] = { value = inst[prop] } end
        if inst[prop] ~= wanted then inst[prop] = wanted end
    elseif fields and fields[prop] then
        inst[prop] = fields[prop].value
        fields[prop] = nil
        if not next(fields) then worldChanges[inst] = nil end
    end
end

local function rememberWorld(inst)
    if inst:IsA("Clouds") or inst:IsA("Atmosphere") or inst:IsA("PostEffect")
        or inst:IsA("BasePart") and not inst:FindFirstAncestor("Male") and (inst.Name:lower():find("leaves", 1, true) or inst.Name:lower():find("foliage", 1, true)) then
        worldCandidates[inst], worldDirty = true, true
    end
end
connect(workspace.DescendantAdded, rememberWorld)
connect(Lighting.DescendantAdded, rememberWorld)
for _, inst in ipairs(workspace:GetDescendants()) do rememberWorld(inst) end
for _, inst in ipairs(Lighting:GetDescendants()) do rememberWorld(inst) end

function API.ApplyWorld()
    if not API.Running then return end
    local mask = (S.World.Daytime and 1 or 0) + (S.World.NoLeaves and 2 or 0)
        + (S.World.NoShadows and 4 or 0) + (S.World.NoClouds and 8 or 0) + (S.World.NoLighting and 16 or 0)
    if lastWorldMask == mask and not worldDirty then return end
    lastWorldMask, worldDirty = mask, false
    worldWriting = true
    local ok, failure = pcall(function()
        for _, prop in ipairs({ "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "GlobalShadows", "FogEnd" }) do worldProperty(Lighting, prop) end
        for inst in pairs(worldCandidates) do
            if not inst.Parent then worldCandidates[inst], worldChanges[inst] = nil, nil
            elseif inst:IsA("BasePart") then worldProperty(inst, "LocalTransparencyModifier")
            elseif inst:IsA("Atmosphere") then worldProperty(inst, "Density")
            else worldProperty(inst, "Enabled") end
        end
    end)
    worldWriting = false
    API.WorldError = not ok and tostring(failure) or nil
end
connect(Lighting.Changed, function(prop)
    if worldWriting then return end
    local fields = worldChanges[Lighting]
    if fields and fields[prop] then fields[prop].value = Lighting[prop] end
    if desiredWorldProperty(Lighting, prop) ~= nil then
        -- A clock tick only needs its changed Lighting property corrected.
        -- Do not revisit every leaf/cloud/effect for each time-of-day update.
        worldWriting = true
        local ok, failure = pcall(worldProperty, Lighting, prop)
        worldWriting = false
        if not ok then API.WorldError = tostring(failure) end
    end
end)

function API.StopAutoShoot()
    if autoWeapon then pcall(function() autoWeapon:_discharge(false) end) end
    autoWeapon = nil
end

function API.GetEquippedWeapon()
    local current = API.CurrentWeapon
    if current and current.Equipped and isLocalActor(rawget(current, "_actor")) then return current end
    for inventory in pairs(weapons) do
        if rawget(inventory, "Equipped") and isLocalActor(rawget(inventory, "_actor")) then API.CurrentWeapon = inventory; return inventory end
    end
end

local function autoShoot()
    if not S.Gun.AutoShoot or not activeInput() then API.StopAutoShoot(); return end
    local options = table.clone(S.Silent.Enabled and S.Silent or S.Aim)
    options.VisibleCheck = S.Gun.AutoShootVisibleCheck
    local target = API.FindAimTarget(nil, options)
    local inventory = API.GetEquippedWeapon()
    if not target or not inventory then API.StopAutoShoot(); return end
    if not S.Silent.Enabled then
        local point = workspace.CurrentCamera:WorldToViewportPoint(API.GetTargetPosition(target, options))
        if (Vector2.new(point.X, point.Y) - workspace.CurrentCamera.ViewportSize / 2).Magnitude > 12 then API.StopAutoShoot(); return end
    end
    if autoWeapon and autoWeapon ~= inventory then API.StopAutoShoot() end
    autoWeapon = inventory
    if autoBusy then return end
    autoBusy = true
    task.spawn(function()
        local ok, failure = pcall(function() inventory:_discharge(true) end)
        autoBusy = false
        if not ok then API.GunError = tostring(failure) end
    end)
end

local function makeOverlayFrame(name)
    local f = Instance.new("Frame")
    f.Name, f.BorderSizePixel = name, 0
    f.Visible = false
    f.Parent = featureGui
    return f
end

function API.CreateFeatureOverlays()
    featureGui = Instance.new("ScreenGui")
    featureGui.Name = "Vantix_BRM5_Overlays"
    featureGui.IgnoreGuiInset, featureGui.ResetOnSpawn = true, false
    featureGui.Parent = CoreGui
    crossBars = { makeOverlayFrame("Left"), makeOverlayFrame("Right"), makeOverlayFrame("Top"), makeOverlayFrame("Bottom") }
    crossDot, targetLine = makeOverlayFrame("CenterDot"), makeOverlayFrame("TargetLine")
    targetLine.AnchorPoint = Vector2.new(0.5, 0.5)
end

local function drawOverlays()
    if not featureGui or not workspace.CurrentCamera then return end
    local c = S.Crosshair
    local center = c.Position == "Mouse" and UIS:GetMouseLocation() or workspace.CurrentCamera.ViewportSize / 2
    local crossChanged = lastOverlay.enabled ~= c.Enabled or c.Enabled and (lastOverlay.center ~= center
        or lastOverlay.size ~= c.Size or lastOverlay.gap ~= c.Gap or lastOverlay.thickness ~= c.Thickness
        or lastOverlay.color ~= c.Color or lastOverlay.dot ~= c.CenterDot)
    if crossChanged then
    local positions = {
        { center.X - c.Gap - c.Size, center.Y - c.Thickness / 2, c.Size, c.Thickness },
        { center.X + c.Gap, center.Y - c.Thickness / 2, c.Size, c.Thickness },
        { center.X - c.Thickness / 2, center.Y - c.Gap - c.Size, c.Thickness, c.Size },
        { center.X - c.Thickness / 2, center.Y + c.Gap, c.Thickness, c.Size },
    }
    for i, f in ipairs(crossBars) do
        local p = positions[i]
        f.Visible, f.BackgroundColor3 = c.Enabled, c.Color
        f.Position, f.Size = UDim2.fromOffset(p[1], p[2]), UDim2.fromOffset(p[3], p[4])
    end
    crossDot.Visible, crossDot.BackgroundColor3 = c.Enabled and c.CenterDot, c.Color
    crossDot.Position, crossDot.Size = UDim2.fromOffset(center.X - c.Thickness / 2, center.Y - c.Thickness / 2), UDim2.fromOffset(c.Thickness, c.Thickness)
    lastOverlay.enabled, lastOverlay.center, lastOverlay.size, lastOverlay.gap = c.Enabled, center, c.Size, c.Gap
    lastOverlay.thickness, lastOverlay.color, lastOverlay.dot = c.Thickness, c.Color, c.CenterDot
    end
    if S.Silent.Enabled and S.Silent.ShowLine then
        if os.clock() < nextLineScan then return end
        nextLineScan = os.clock() + 0.08
        local target = API.FindAimTarget(nil, S.Silent)
        if target then
            local p, visible = workspace.CurrentCamera:WorldToViewportPoint(API.GetTargetPosition(target, S.Silent))
            if visible then
                local from, to = workspace.CurrentCamera.ViewportSize / 2, Vector2.new(p.X, p.Y)
                local delta, midpoint = to - from, (from + to) / 2
                targetLine.Visible, targetLine.BackgroundColor3 = true, S.Silent.LineColor
                targetLine.Position, targetLine.Size = UDim2.fromOffset(midpoint.X, midpoint.Y), UDim2.fromOffset(delta.Magnitude, 1)
                targetLine.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                lastOverlay.lineVisible = true
                return
            end
        end
    end
    if lastOverlay.lineVisible then targetLine.Visible = false; lastOverlay.lineVisible = false end
end

function API.FeatureStep(dt)
    local now = os.clock()
    local workStart = now
    highlightAccumulator = highlightAccumulator + dt
    if highlightAccumulator >= 1 / S.Performance.HighlightFPS then
        highlightAccumulator = highlightAccumulator % (1 / S.Performance.HighlightFPS)
        API.HighlightStep()
    end
    frameTime, frameCount, worstFrame = frameTime + dt, frameCount + 1, math.max(worstFrame, dt)
    if frameTime >= 1 then
        API.Performance.FPS, API.Performance.WorstFrameMs = frameCount / frameTime, worstFrame * 1000
        API.Performance.RenderWorkMs = frameWorkTime / math.max(frameCount, 1) * 1000
        frameTime, frameCount, worstFrame = 0, 0, 0
        frameWorkTime = 0
    end
    if now - lastSample >= 0.08 then
        if S.Aim.Prediction > 0 or S.Silent.Prediction > 0 then
            for _, actor in next, API.AimActors or {} do
                if isActor(actor) then
                    local part = aimPart(actor)
                    if part and part:IsDescendantOf(workspace) then
                        local before = velocitySamples[actor]
                        local velocity = Vector3.zero
                        if before and now - before.time < 1 and now > before.time then
                            local measured = (part.Position - before.position) / (now - before.time)
                            if measured.Magnitude < 200 then velocity = before.velocity:Lerp(measured, 0.5) end
                        end
                        velocitySamples[actor] = { position = part.Position, time = now, velocity = velocity }
                    end
                end
            end
        end
        lastSample = now
        if S.Gun.AutoShoot or autoWeapon then autoShoot() end
    end
    if not S.Performance.HighlightOnly and now >= nextMarkerProjection then
        API.ProjectCachedMarkers()
        nextMarkerProjection = now + 0.05
    end
    drawOverlays()
    frameWorkTime = frameWorkTime + os.clock() - workStart
end

function API.UpdateFeatureStatus()
    API.ApplyWorld()
    local actor = API.LocalActor
    if actor then
        syncData(actor, S.Player.NoProneDelay and { ProneDelay = 0 } or {})
        if S.Player.InfiniteStamina and type(actor.Controller) == "table" and actor.Controller._exhaustStart then
            actor.Controller._exhaustStart, actor.Controller._exhausted = tick() - 2, tick() - 1
        end
    end
    if not S.Player.Fly or actor and actor.Seat then API.FlyActive = false end
    if not S.Vehicle.Fly or not actor or type(actor.Controller) ~= "table" or not actor.Controller._solver then API.VehicleFlyActive = false end
    for inventory in pairs(weapons) do
        if isLocalActor(rawget(inventory, "_actor")) then API.ApplyGunMods(inventory) end
    end
    if movementStatus then
        movementStatus:Set(API.FlyActive and "Character flight active" or API.VehicleFlyActive and "Vehicle flight active"
            or S.Vehicle.Fly and "Vehicle fly: enter the driver / pilot seat" or S.Player.Fly and "Fly: waiting for an on-foot character" or "Movement options ready")
    end
    if gunStatus then gunStatus:Set(API.GunError or (API.GetEquippedWeapon() and "Weapon detected" or "Equip a weapon to apply gun modifications")) end
end

function API.StopFeatures()
    API.StopAutoShoot()
    for target, fields in pairs(dataChanges) do
        for key, original in pairs(fields) do pcall(function() target[key] = original.value end) end
    end
    table.clear(dataChanges)
    worldWriting = true
    for inst, fields in pairs(worldChanges) do
        for prop, original in pairs(fields) do pcall(function() inst[prop] = original.value end) end
    end
    table.clear(worldChanges)
    worldWriting = false
    if featureGui then featureGui:Destroy() end
    table.clear(flyPositions)
end

function API.DebugSuspend()
    local suspended = {}
    for key, patch in pairs(patches) do
        if key ~= "Movement" and key ~= "Exhaustion" and key ~= "JumpPower" and key ~= "Speed"
            and rawget(patch.class, patch.method) == patch.wrapper then
            patch.class[patch.method] = patch.original
            table.insert(suspended, patch)
        end
    end
    return function()
        for _, patch in ipairs(suspended) do
            if rawget(patch.class, patch.method) == patch.original then patch.class[patch.method] = patch.wrapper end
        end
    end
end

-- Config data is JSON only; values are checked against the known settings schema.
local function encodeSettings(value)
    if typeof(value) == "Color3" then return { kind = "Color3", r = value.R, g = value.G, b = value.B } end
    if type(value) ~= "table" then return value end
    local out = {}; for k, v in pairs(value) do out[k] = encodeSettings(v) end; return out
end
local function decodeSettings(value, schema)
    if typeof(schema) == "Color3" then
        if type(value) == "table" and value.kind == "Color3" and type(value.r) == "number" and type(value.g) == "number" and type(value.b) == "number" then
            return Color3.new(math.clamp(value.r, 0, 1), math.clamp(value.g, 0, 1), math.clamp(value.b, 0, 1))
        end
        return schema
    end
    if type(schema) ~= "table" then
        if typeof(value) ~= typeof(schema) then return schema end
        if type(value) == "number" and (value ~= value or math.abs(value) == math.huge) then return schema end
        return value
    end
    local fields = type(value) == "table" and value or nil
    local out = {}
    for k, v in pairs(schema) do
        local field
        if fields then field = fields[k] end
        out[k] = decodeSettings(field, v)
    end
    return out
end
local function safeConfigName(name)
    return type(name) == "string" and #name > 0 and #name <= 64 and name:match("^[%w _%-]+$") and name or nil
end
local function fileReady()
    return type(writefile) == "function" and type(readfile) == "function" and type(makefolder) == "function" and type(isfolder) == "function" and type(isfile) == "function" and type(listfiles) == "function"
end
local function ensureConfigFolders()
    assert(fileReady(), "The executor does not support config files.")
    for _, path in ipairs({ "Vantix", cfgRoot, cfgRoot .. "/configs" }) do
        if not isfolder(path) then makefolder(path) end
    end
end
local function readAutoLoad()
    local path = cfgRoot .. "/autoload.json"
    if not fileReady() or not isfile(path) then return { place = {}, game = {}, global = false } end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if ok and type(data) == "table" then
        data.place, data.game = type(data.place) == "table" and data.place or {}, type(data.game) == "table" and data.game or {}
        return data
    end
    return { place = {}, game = {}, global = false }
end
function API.ListConfigs()
    ensureConfigFolders()
    local out = {}
    for _, path in ipairs(listfiles(cfgRoot .. "/configs")) do
        local name = path:match("([^/\\]+)%.json$")
        if safeConfigName(name) then table.insert(out, name) end
    end
    table.sort(out)
    return out
end
function API.SaveConfig(name, overwrite)
    name = assert(safeConfigName(name), "Use letters, numbers, spaces, underscores or hyphens for config names.")
    ensureConfigFolders()
    local path = cfgRoot .. "/configs/" .. name .. ".json"
    assert(overwrite or not isfile(path), "Config already exists; use Overwrite config.")
    writefile(path, HttpService:JSONEncode({ version = 2, settings = encodeSettings(S) }))
    return true
end
function API.LoadConfig(name)
    name = assert(safeConfigName(name), "Select a valid config.")
    ensureConfigFolders()
    local data = HttpService:JSONDecode(readfile(cfgRoot .. "/configs/" .. name .. ".json"))
    assert(type(data) == "table" and type(data.settings) == "table", "Invalid config data.")
    local loaded = decodeSettings(data.settings, defaults)
    for _, entry in ipairs(configControls or {}) do
        local value
        if entry.group then value = loaded[entry.group][entry.key] else value = loaded[entry.key] end
        if entry.scale then value = value * entry.scale end
        if entry.min then value = math.clamp(value, entry.min, entry.max) end
        if entry.options and not table.find(entry.options, value) then value = entry.default end
        if entry.keybind then value = Enum.KeyCode[value] or Enum.KeyCode.Unknown end
        entry.control:Set(value)
    end
    API.Refresh()
    return true
end
function API.SetAutoLoad(scope, name)
    assert(scope == "place" or scope == "game" or scope == "global", "Invalid autoload scope.")
    name = assert(safeConfigName(name), "Select a valid config.")
    ensureConfigFolders()
    assert(isfile(cfgRoot .. "/configs/" .. name .. ".json"), "Create the config first.")
    local data = readAutoLoad()
    if scope == "global" then data.global = name else data[scope][tostring(scope == "place" and game.PlaceId or game.GameId)] = name end
    writefile(cfgRoot .. "/autoload.json", HttpService:JSONEncode(data))
end
function API.DeleteConfig(name)
    name = assert(safeConfigName(name), "Select a valid config.")
    assert(type(delfile) == "function", "The executor cannot delete config files.")
    ensureConfigFolders()
    local path = cfgRoot .. "/configs/" .. name .. ".json"
    if isfile(path) then delfile(path) end
    local data = readAutoLoad()
    for _, scope in ipairs({ "place", "game" }) do for id, value in pairs(data[scope]) do if value == name then data[scope][id] = nil end end end
    if data.global == name then data.global = false end
    writefile(cfgRoot .. "/autoload.json", HttpService:JSONEncode(data))
end

local ok, err = pcall(function()
    discoverRegistry()
    API.InstallFeatureHooks()
    Window = VantixUI:CreateWindow({ Title = "Vantix | BRM5", Size = { 840, 550 }, Theme = "Vantix" })
    API.Window = Window
    if Window.SetToggleKey then Window:SetToggleKey(Enum.KeyCode.RightShift) end
    Window:CreateTag("BRM5", Color3.fromRGB(75, 165, 255))
    ui = CoreGui:FindFirstChild("VantixUI")
    if not ui and type(gethui) == "function" then
        local found, parent = pcall(gethui)
        if found and typeof(parent) == "Instance" then ui = parent:FindFirstChild("VantixUI") end
    end
    if ui then connect(ui.Destroying, API.Destroy) end
    API.Controls, configControls = {}, {}
    local function notify(title, message)
        Window:Notify({ Title = title, Text = tostring(message), Duration = 4 })
    end
    local function control(tab, kind, title, group, key, params)
        params = params or {}
        local values = group and S[group] or S
        local id = group and group .. "." .. key or key
        local object
        local default = values[key]
        local numberLabel
        local function formatNumber(value)
            return string.format("%." .. tostring(params.precision or 0) .. "f", value)
        end
        local function changed(value)
            if kind == "Slider" and numberLabel then numberLabel.Text = formatNumber(value) end
            if params.scale then value = value / params.scale end
            values[key] = value
            if not API.Running then return end
            local success, failure = true, nil
            if id == "Silent.Enabled" then success, failure = API.SetSilentEnabled(value)
            elseif id == "NoFallDamage" then success, failure = API.SetNoFallDamage(value)
            elseif id == "Player.Fly" and value and not classes.Controller then success, failure = false, "Character controller unavailable."
            elseif id == "Vehicle.Fly" and value and not classes.VehicleSolver then success, failure = false, "Vehicle solver unavailable."
            elseif id == "Aim.Enabled" and value and S.Aim.Mode == "BRM5 Camera" and not classes.Camera then success, failure = false, "BRM5 camera unavailable; select Mouse mode."
            end
            if not success then
                values[key] = false
                if object and kind == "Toggle" then object:Set(false) end
                notify("Feature unavailable", failure)
                return
            end
            if id == "Gun.AutoShoot" and not value then API.StopAutoShoot() end
            if group == "Aim" then nativeAimTarget, aimTarget, API.AimTarget = nil, nil, nil end
            API.Refresh()
        end
        local opts = { Title = title, Subtitle = params.subtitle, Icon = params.icon, Default = default, Callback = changed }
        if kind == "Slider" then opts.Min, opts.Max, opts.Default = params.min, params.max, default * (params.scale or 1)
        elseif kind == "Dropdown" then
            opts.Options, opts.Default = params.options, table.find(params.options, default) or 1
        end
        local before
        if kind == "Slider" and ui then before = {}; for _, inst in ipairs(ui:GetDescendants()) do before[inst] = true end end
        object = tab["Add" .. kind](tab, opts)
        if before then
            for _, inst in ipairs(ui:GetDescendants()) do
                if not before[inst] and inst:IsA("TextLabel") and inst.Text == title then
                    for _, label in ipairs(inst.Parent:GetChildren()) do
                        if label:IsA("TextLabel") and label.Size.X.Offset == 55 and label.AnchorPoint.X == 1 then numberLabel = label end
                    end
                end
            end
            if numberLabel then numberLabel.Text = formatNumber(opts.Default) end
        end
        API.Controls[id] = object
        table.insert(configControls, { control = object, group = group, key = key, min = params.min,
            max = params.max, options = params.options, default = default, scale = params.scale, title = title, toggle = kind == "Toggle" })
        return object
    end
    local function toggle(tab, title, group, key, subtitle) return control(tab, "Toggle", title, group, key, { subtitle = subtitle }) end
    local function slider(tab, title, group, key, min, max, precision, scale) return control(tab, "Slider", title, group, key, { min = min, max = max, precision = precision, scale = scale }) end
    local function dropdown(tab, title, group, key, options) return control(tab, "Dropdown", title, group, key, { options = options }) end
    local function color(tab, title, group, key) return control(tab, "ColorPicker", title, group, key) end
    local parts = { "Head", "Upper Torso", "Lower Torso" }
    local highlight = Window:AddTab("Highlights", "eye")
    statusLabel = highlight:AddLabel("Detecting characters ...", "users")
    API.Controls.Enabled = toggle(highlight, "Enable highlights", nil, "Enabled")
    API.Controls.Enemies = toggle(highlight, "Enemies", nil, "Enemies")
    API.Controls.NPCs = toggle(highlight, "Passive NPCs", nil, "NPCs")
    API.Controls.Players = toggle(highlight, "Players", nil, "Players")
    toggle(highlight, "Visible through walls", nil, "ThroughWalls")
    highlight:AddLabel("Lightweight ESP: native highlights, updated at 30 FPS.", "info")
    slider(highlight, "Maximum distance (studs)", nil, "MaxDistance", 100, 15000)
    color(highlight, "Enemy color", "Colors", "Enemies")
    color(highlight, "Passive NPC color", "Colors", "NPCs")
    color(highlight, "Player color", "Colors", "Players")
    slider(highlight, "Fill transparency (%)", nil, "Fill", 0, 100, 0, 100)
    slider(highlight, "Outline transparency (%)", nil, "Outline", 0, 100, 0, 100)

    local aim = Window:AddTab("Aimbot", "crosshair")
    aimStatus = aim:AddLabel("Aimbot ready", "target")
    API.Controls.AimEnabled = toggle(aim, "Aimbot", "Aim", "Enabled")
    toggle(aim, "Use FOV", "Aim", "UseFOV")
    toggle(aim, "Show aimbot FOV", "Aim", "ShowCircle")
    slider(aim, "Aimbot FOV size (pixels)", "Aim", "Radius", 20, 500)
    color(aim, "Aimbot FOV color", "Aim", "FOVColor")
    toggle(aim, "Stick to target", "Aim", "StickToTarget")
    dropdown(aim, "Keybind (hold)", "Aim", "Key", { "Right Mouse Button", "Left Mouse Button", "LeftAlt", "LeftControl", "E", "Q", "F" })
    dropdown(aim, "Target part", "Aim", "Part", parts)
    dropdown(aim, "Aim mode", "Aim", "Mode", { "BRM5 Camera", "Mouse", "Camera" })
    slider(aim, "Smoothing (%)", "Aim", "Smoothing", 0, 95)
    slider(aim, "Prediction (milliseconds)", "Aim", "Prediction", 0, 500)
    toggle(aim, "Wall check", "Aim", "VisibleCheck")
    toggle(aim, "Team check", "Aim", "TeamCheck", "BRM5 PvE operators are allies")
    toggle(aim, "Target players", "Aim", "TargetPlayers")
    toggle(aim, "Target NPC enemies", "Aim", "TargetNPCs")
    slider(aim, "Maximum target distance (studs)", "Aim", "Distance", 50, 5000)

    local silent = Window:AddTab("Silent Aim", "target")
    gameplayStatus = silent:AddLabel("Silent aim ready", "info")
    API.Controls.SilentEnabled = toggle(silent, "Silent aim", "Silent", "Enabled")
    toggle(silent, "Team check", "Silent", "TeamCheck")
    toggle(silent, "Target players", "Silent", "TargetPlayers")
    toggle(silent, "Target NPC enemies", "Silent", "TargetNPCs")
    toggle(silent, "Use FOV", "Silent", "UseFOV", "Uses the aimbot FOV size")
    toggle(silent, "Visible check", "Silent", "VisibleCheck")
    slider(silent, "Hit chance (%)", "Silent", "HitChance", 0, 100)
    dropdown(silent, "Target part", "Silent", "Part", parts)
    toggle(silent, "Show target line", "Silent", "ShowLine")
    color(silent, "Target line color", "Silent", "LineColor")
    toggle(silent, "Require aim key", "Silent", "RequireHold")
    toggle(silent, "Bullet drop compensation", "Silent", "CompensateDrop")
    slider(silent, "Prediction (milliseconds)", "Silent", "Prediction", 0, 500)
    slider(silent, "Maximum target distance (studs)", "Silent", "Distance", 50, 5000)

    local gun = Window:AddTab("Gun Mods", "crosshair")
    gunStatus = gun:AddLabel("Equip a weapon to apply gun modifications", "info")
    for _, option in ipairs({ {"No recoil", "NoRecoil"}, {"No spread", "NoSpread"}, {"No ADS", "NoADS"}, {"No sway", "NoSway"} }) do toggle(gun, option[1], "Gun", option[2]) end
    toggle(gun, "Fire mode override", "Gun", "FireModeOverride")
    dropdown(gun, "Fire mode", "Gun", "FireMode", { "Auto", "Burst", "Semi" })
    toggle(gun, "Fast fire rate", "Gun", "FastFireRate")
    slider(gun, "Fire rate multiplier", "Gun", "RateMultiplier", 1, 10, 2)
    gun:AddLabel("Instant hit: unavailable; the server simulates bullet travel.", "info")
    toggle(gun, "No shoot delay", "Gun", "NoShootDelay")
    toggle(gun, "Instant equip", "Gun", "InstantEquip")
    toggle(gun, "Auto shoot", "Gun", "AutoShoot")
    toggle(gun, "Auto shoot visible check", "Gun", "AutoShootVisibleCheck")

    local player = Window:AddTab("Player", "user")
    movementStatus = player:AddLabel("Movement options ready", "info")
    toggle(player, "WalkSpeed", "Player", "WalkSpeed")
    slider(player, "Speed multiplier", "Player", "SpeedMultiplier", 1, 5, 2)
    slider(player, "Sprint multiplier", "Player", "SprintMultiplier", 1, 5, 2)
    toggle(player, "Fly", "Player", "Fly")
    slider(player, "Fly speed", "Player", "FlySpeed", 10, 500)
    toggle(player, "Infinite stamina", "Player", "InfiniteStamina")
    toggle(player, "No jump cooldown", "Player", "NoJumpCooldown")
    toggle(player, "Jump power", "Player", "JumpPower")
    slider(player, "Jump power", "Player", "JumpVelocity", 10, 150)
    toggle(player, "No prone delay", "Player", "NoProneDelay")
    API.Controls.NoFallDamage = toggle(player, "No fall damage", nil, "NoFallDamage", "Limits downward speed")
    player:AddLabel("Fly: WASD + Space / Left Ctrl. Minimize the UI to move.", "keyboard")

    local vehicle = Window:AddTab("Vehicle", "car")
    toggle(vehicle, "Vehicle fly", "Vehicle", "Fly")
    slider(vehicle, "Vehicle fly speed", "Vehicle", "FlySpeed", 10, 500)
    vehicle:AddLabel("Driver / pilot seat only. WASD + Space / Left Ctrl.", "keyboard")

    local cross = Window:AddTab("Crosshair", "plus")
    toggle(cross, "Crosshair", "Crosshair", "Enabled")
    dropdown(cross, "Position", "Crosshair", "Position", { "Center", "Mouse" })
    slider(cross, "Size", "Crosshair", "Size", 1, 40)
    slider(cross, "Gap size", "Crosshair", "Gap", 0, 20)
    slider(cross, "Thickness", "Crosshair", "Thickness", 1, 8)
    color(cross, "Crosshair color", "Crosshair", "Color")
    toggle(cross, "Center dot", "Crosshair", "CenterDot")

    local world = Window:AddTab("World", "sun")
    toggle(world, "Night to day", "World", "Daytime")
    toggle(world, "No leaves", "World", "NoLeaves")
    toggle(world, "No shadows", "World", "NoShadows")
    toggle(world, "No clouds", "World", "NoClouds")
    toggle(world, "No lighting (fullbright)", "World", "NoLighting")

    local config = Window:AddTab("Configuration", "save")
    local initialList = {}
    local canConfig, configs = pcall(API.ListConfigs)
    if canConfig then initialList = configs end
    local selector = config:AddDropdown({ Title = "Config list", Options = #initialList > 0 and initialList or { "No configs saved" }, Default = 1,
        Callback = function(name) selectedConfig = table.find(initialList, name) and name or nil end })
    selectedConfig = initialList[1]
    config:AddTextBox({ Title = "Config name", Placeholder = "Enter name...", Callback = function(name) configName = name end })
    local function refreshConfigs()
        initialList = API.ListConfigs()
        selector:SetOptions(#initialList > 0 and initialList or { "No configs saved" })
        if not table.find(initialList, selectedConfig) then selectedConfig = initialList[1] end
        if selectedConfig then selector:Set(selectedConfig) end
        local auto = readAutoLoad()
        if configStatus then configStatus:Set(string.format("Place: %s | Game: %s | Global: %s",
            tostring(auto.place[tostring(game.PlaceId)] or "none"), tostring(auto.game[tostring(game.GameId)] or "none"), tostring(auto.global or "none"))) end
    end
    local function configAction(title, action)
        config:AddButton({ Title = title, ButtonText = title, Callback = function()
            local success, failure = pcall(action)
            if success then pcall(refreshConfigs); notify("Configuration", title .. " completed.") else notify("Configuration error", failure) end
        end })
    end
    configAction("Create config", function() API.SaveConfig(configName, false); selectedConfig = configName end)
    configAction("Load config", function() API.LoadConfig(selectedConfig) end)
    configAction("Overwrite config", function() API.SaveConfig(selectedConfig, true) end)
    configAction("Set place autoload", function() API.SetAutoLoad("place", selectedConfig) end)
    configAction("Set game autoload", function() API.SetAutoLoad("game", selectedConfig) end)
    configAction("Set global autoload", function() API.SetAutoLoad("global", selectedConfig) end)
    configAction("Clear autoloads", function() ensureConfigFolders(); writefile(cfgRoot .. "/autoload.json", HttpService:JSONEncode({place={},game={},global=false})) end)
    configAction("Delete config", function() API.DeleteConfig(selectedConfig) end)
    configAction("Refresh config list", refreshConfigs)
    configStatus = config:AddLabel("Autoload: none", "info")
    if not canConfig then config:AddLabel("Config files unavailable: " .. tostring(configs), "info") else refreshConfigs() end

    local bindings = Window:AddTab("Keybinds", "keyboard")
    bindings:AddLabel("Click a key field, then press a key. Escape clears a binding.", "keyboard")
    bindings:AddLabel("Default shortcuts: player fly H, vehicle fly J. Aim hold key is set in Aimbot.", "info")
    local toggleEntries, boundKeys = {}, {}
    local bindingButtons = {}
    local bindingCapture, lastBindingChange = false, 0
    for _, entry in ipairs(configControls) do
        if entry.toggle then table.insert(toggleEntries, entry) end
    end
    local function rebuildBindings()
        table.clear(boundKeys)
        for _, entry in ipairs(toggleEntries) do
            local id = entry.group and entry.group .. "." .. entry.key or entry.key
            local key = S.Keybinds[id]
            if key and key ~= "Unknown" and key ~= "None" and key ~= S.Keybinds["UI.Toggle"] then boundKeys[key] = entry end
        end
    end
    function API.TriggerKeybind(keyName)
        if not API.Running then return false end
        local entry = boundKeys[keyName]
        if not entry then return false end
        local values = entry.group and S[entry.group] or S
        entry.control:Set(not values[entry.key])
        return true
    end
    local function addBinding(title, id)
        local current = Enum.KeyCode[S.Keybinds[id]] or Enum.KeyCode.Unknown
        S.Keybinds[id] = current == Enum.KeyCode.Unknown and "Unknown" or current.Name
        local before = {}
        if ui then for _, inst in ipairs(ui:GetDescendants()) do before[inst] = true end end
        local object = bindings:AddKeybind({ Title = title, Default = current })
        API.Controls["Keybinds." .. id] = object
        local button
        if ui then
            for _, inst in ipairs(ui:GetDescendants()) do
                if not before[inst] and inst:IsA("TextButton") and (inst.Text == current.Name or inst.Text == "None") then button = inst end
            end
        end
        if button then
            table.insert(bindingButtons, button)
            connect(button.MouseButton1Click, function()
            bindingCapture = true
            if Window.SetToggleKey then Window:SetToggleKey(nil) end
        end) end
        local function applyBinding(key)
            if not API.Running then return end
            bindingCapture, lastBindingChange = false, os.clock()
            S.Keybinds[id] = key == Enum.KeyCode.Unknown and "Unknown" or key.Name
            if Window.SetToggleKey then
                local uiKey = Enum.KeyCode[S.Keybinds["UI.Toggle"]] or Enum.KeyCode.RightShift
                Window:SetToggleKey(uiKey ~= Enum.KeyCode.Unknown and uiKey or nil)
            end
            rebuildBindings()
        end
        connect(object.Changed, applyBinding)
        local nativeSet = object.Set
        object.Set = function(self, key)
            nativeSet(self, key)
            -- Apply immediately; delayed BindableEvent delivery at low FPS must
            -- not save the old key or leave the shortcut map one frame behind.
            applyBinding(key)
        end
        table.insert(configControls, { control = object, group = "Keybinds", key = id, keybind = true, default = S.Keybinds[id] })
    end
    addBinding("UI toggle", "UI.Toggle")
    for _, entry in ipairs(toggleEntries) do
        local id = entry.group and entry.group .. "." .. entry.key or entry.key
        addBinding((entry.group and entry.group .. ": " or "") .. entry.title, id)
    end
    rebuildBindings()
    connect(UIS.InputBegan, function(input, processed)
        if not API.Running or processed or bindingCapture or os.clock() - lastBindingChange < 0.15
            or UIS:GetFocusedTextBox() or input.KeyCode == Enum.KeyCode.Unknown then return end
        if type(isrbxactive) == "function" and not isrbxactive() then return end
        -- Some executors defer GUI signals. Checking the capture text avoids
        -- activating a shortcut while another row is awaiting its new key.
        if ui and Window.IsMinimized and not Window:IsMinimized() then
            for _, button in ipairs(bindingButtons) do
                if button.Text == "..." then return end
            end
        end
        API.TriggerKeybind(input.KeyCode.Name)
    end)

    local performance = Window:AddTab("Performance", "monitor")
    performance:AddLabel("ESP uses cached highlights only. No names or distance markers.", "info")
    slider(performance, "Maximum active highlights", "Performance", "MaxHighlights", 8, 128)
    slider(performance, "Entity discovery interval (milliseconds)", "Performance", "ESPInterval", 250, 2000)
    slider(performance, "Keep missing entities cached (seconds)", "Performance", "CacheTTL", 30, 600)
    slider(performance, "Maximum cached entities", "Performance", "MaxCachedEntities", 128, 1024)
    performance:AddLabel("ESP objects are pooled and reused across visibility/model changes.", "info")
    local perfLabel = performance:AddLabel("Measuring frame rate ...", "monitor")
    local previousStatusUpdate = API.UpdateFeatureStatus
    function API.UpdateFeatureStatus()
        previousStatusUpdate()
        local p, c = API.Performance, API.CacheMetrics
        local text = string.format("%.0f FPS | ESP %.2f ms | Cached %d | Marker pool %d", p.FPS, p.RefreshMs, c.Entities, c.MarkersCreated)
        if API.LastPerformanceText ~= text then perfLabel:Set(text); API.LastPerformanceText = text end
    end

    local settings = Window:AddTab("Settings", "settings")
    settings:AddLabel("RightShift: minimize / restore the UI", "keyboard")
    settings:AddLabel("PvE defaults target enemy NPCs and exclude players.", "shield")
    settings:AddButton({ Title = "Rescan game objects", ButtonText = "Scan", Callback = function() discoverRegistry(); API.InstallFeatureHooks(); API.Refresh() end })
    settings:AddButton({ Title = "Stop script", ButtonText = "Unload", Callback = API.Destroy })

    aimGui = Instance.new("ScreenGui")
    aimGui.Name, aimGui.IgnoreGuiInset, aimGui.ResetOnSpawn = "Ocean_BRM5_Aim", true, false
    aimGui.Parent = CoreGui
    aimCircle = Instance.new("Frame")
    aimCircle.Name, aimCircle.BackgroundTransparency = "FOV", 1
    aimCircle.AnchorPoint, aimCircle.Visible, aimCircle.Parent = Vector2.new(0.5, 0.5), false, aimGui
    local corner = Instance.new("UICorner"); corner.CornerRadius, corner.Parent = UDim.new(1, 0), aimCircle
    local stroke = Instance.new("UIStroke"); stroke.Color, stroke.Transparency, stroke.Thickness, stroke.Parent = S.Aim.FOVColor, 0.25, 1, aimCircle
    API.CreateFeatureOverlays()
    API.SetSilentEnabled(S.Silent.Enabled)
    API.SetNoFallDamage(S.NoFallDamage)
    if not savedSettings and canConfig then
        local auto = readAutoLoad()
        local name = auto.place[tostring(game.PlaceId)] or auto.game[tostring(game.GameId)] or auto.global
        if name then local success, failure = pcall(API.LoadConfig, name); if not success then notify("Autoload error", failure) end end
    end
    API.Refresh()
    RunService:BindToRenderStep(aimBinding, Enum.RenderPriority.Last.Value + 1, function(dt)
        local success, failure = pcall(aimStep, dt)
        if not success then API.AimError = tostring(failure); aimTarget, API.AimTarget = nil, nil end
    end)
    aimBound = true
    Window:Notify({ Title = "BRM5 ready", Text = savedSettings and "Settings restored. New features are available in their tabs." or "Minimize the UI with RightShift to use movement and aim controls.", Duration = 5 })
end)
if not ok then API.Destroy(); error("BRM5: " .. tostring(err)) end

task.spawn(function()
    local discoveryBackoff, nextDiscovery = 2, os.clock() + 2
    while API.Running do
        task.wait(math.clamp(S.Performance.ESPInterval / 1000, 0.1, 2))
        if not API.Running then break end
        -- The actor dictionary updates itself. Only retry discovery while its
        -- initial references are missing; normal operation never rescans getgc.
        if API.NeedsDiscovery() and os.clock() >= nextDiscovery then
            local found, failure = pcall(function() discoverRegistry(); API.InstallFeatureHooks() end)
            if not found then API.LastError = tostring(failure) end
            discoveryBackoff = math.min(discoveryBackoff * 2, 60)
            nextDiscovery = os.clock() + discoveryBackoff
        end
        local success, failure = pcall(API.Refresh)
        if success then API.LastError = nil else API.LastError = tostring(failure) end
    end
end)
return API
