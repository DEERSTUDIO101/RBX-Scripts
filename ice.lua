-- Ice Hub UI Library
local IceHub = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Hauptfarben (Ice Hub Theme)
local Colors = {
    Background = Color3.fromRGB(20, 20, 25),
    Secondary = Color3.fromRGB(30, 30, 35),
    Accent = Color3.fromRGB(100, 200, 255), -- Hellblau/Teal für Selection
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(200, 200, 200),
    Border = Color3.fromRGB(40, 40, 50),
    ButtonBg = Color3.fromRGB(35, 35, 40),
    IconGray = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(100, 255, 150),
    Warning = Color3.fromRGB(255, 200, 100)
}

-- Utility Funktionen
local function Tween(obj, props, duration)
    duration = duration or 0.2
    local tween = TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad), props)
    tween:Play()
    return tween
end

local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Colors.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- Haupt Window Funktion
function IceHub:CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "Ice Hub"
    local windowSize = config.Size or UDim2.new(0, 425, 0, 300)
    
    -- ScreenGui erstellen
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "IceHubUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game.CoreGui
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = windowSize
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    CreateCorner(MainFrame, 10)
    
    -- Popup Holder / Overlay (Dropdowns, Color Picker etc.)
    local PopupHolder = Instance.new("Frame")
    PopupHolder.Name = "PopupHolder"
    PopupHolder.BackgroundTransparency = 1
    PopupHolder.Size = UDim2.new(1, 0, 1, 0)
    PopupHolder.ZIndex = 50
    PopupHolder.Parent = ScreenGui
    
    local PopupOverlay = Instance.new("TextButton")
    PopupOverlay.Name = "PopupOverlay"
    PopupOverlay.BackgroundTransparency = 1
    PopupOverlay.AutoButtonColor = false
    PopupOverlay.Text = ""
    PopupOverlay.Visible = false
    PopupOverlay.Size = UDim2.new(1, 0, 1, 0)
    PopupOverlay.ZIndex = 49
    PopupOverlay.Parent = PopupHolder
    
    -- Notification Holder
    local NotificationHolder = Instance.new("Frame")
    NotificationHolder.Name = "NotificationHolder"
    NotificationHolder.AnchorPoint = Vector2.new(1, 0)
    NotificationHolder.Position = UDim2.new(1, -20, 0, 60)
    NotificationHolder.Size = UDim2.new(0, 260, 1, -80)
    NotificationHolder.BackgroundTransparency = 1
    NotificationHolder.Parent = ScreenGui
    
    local NotificationList = Instance.new("UIListLayout")
    NotificationList.Padding = UDim.new(0, 8)
    NotificationList.SortOrder = Enum.SortOrder.LayoutOrder
    NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    NotificationList.VerticalAlignment = Enum.VerticalAlignment.Top
    NotificationList.Parent = NotificationHolder
    
    -- Optional drop shadow removed for cleaner border
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 45)
    Header.BackgroundColor3 = Colors.Secondary
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    CreateCorner(Header, 10)
    
    -- Header Bottom Border removed - cleaner look
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = windowName
    Title.TextColor3 = Colors.Text
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- Minimize Button
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Size = UDim2.new(0, 35, 0, 35)
    MinimizeButton.Position = UDim2.new(1, -85, 0.5, 0)
    MinimizeButton.AnchorPoint = Vector2.new(0, 0.5)
    MinimizeButton.BackgroundColor3 = Colors.Background
    MinimizeButton.Text = "–"
    MinimizeButton.TextColor3 = Colors.Text
    MinimizeButton.TextSize = 24
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Parent = Header
    CreateCorner(MinimizeButton, 8)
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 35, 0, 35)
    CloseButton.Position = UDim2.new(1, -40, 0.5, 0)
    CloseButton.AnchorPoint = Vector2.new(0, 0.5)
    CloseButton.BackgroundColor3 = Colors.Background
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Colors.Text
    CloseButton.TextSize = 24
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = Header
    CreateCorner(CloseButton, 8)
    
    -- Tab Container (Left Navigation)
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(0, 140, 1, -55)
    TabContainer.Position = UDim2.new(0, 10, 0, 50)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 8)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = TabContainer
    
    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingTop = UDim.new(0, 10)
    TabPadding.PaddingBottom = UDim.new(0, 10)
    TabPadding.PaddingLeft = UDim.new(0, 10)
    TabPadding.PaddingRight = UDim.new(0, 10)
    TabPadding.Parent = TabContainer
    
    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -160, 1, -55)
    ContentContainer.Position = UDim2.new(0, 160, 0, 50)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame
    
    local minimized = false
    local minimizedHeight = Header.Size.Y.Offset + 12
    local isClosing = false
    
    local function updateMinimizeIcon()
        MinimizeButton.Text = minimized and "◻" or "–"
    end
    
    local function setInterfaceVisible(state)
        TabContainer.Visible = state
        ContentContainer.Visible = state
        if SectionHeader then
            SectionHeader.Visible = state and SectionHeader.Text ~= ""
        end
    end
    
    local function toggleMinimize(force)
        if isClosing then return end
        
        local target = force
        if target == nil then
            target = not minimized
        end
        if target == minimized then
            return
        end
        minimized = target
        updateMinimizeIcon()
        
        if minimized then
            setInterfaceVisible(false)
            -- Smooth minimize animation with scale effect
            Tween(MainFrame, {
                Size = UDim2.new(windowSize.X.Scale, windowSize.X.Offset, 0, minimizedHeight)
            }, 0.3)
            Tween(Title, {TextTransparency = 0}, 0.2)
        else
            -- Smooth expand animation
            local tween = Tween(MainFrame, {
                Size = windowSize
            }, 0.3)
            tween.Completed:Connect(function()
                setInterfaceVisible(true)
            end)
        end
    end
    
    MinimizeButton.MouseButton1Click:Connect(toggleMinimize)
    updateMinimizeIcon()
    
    CloseButton.MouseButton1Click:Connect(function()
        if isClosing then return end
        isClosing = true
        
        setInterfaceVisible(false)
        
        -- Smooth close animation with fade and scale
        local currentSize = MainFrame.Size
        local currentPos = MainFrame.Position
        
        -- Fade out
        Tween(MainFrame, {BackgroundTransparency = 1}, 0.25)
        Tween(Header, {BackgroundTransparency = 1}, 0.25)
        Tween(Title, {TextTransparency = 1}, 0.25)
        Tween(MinimizeButton, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25)
        Tween(CloseButton, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25)
        
        -- Scale down and fade
        local closeTween = Tween(MainFrame, {
            Size = UDim2.new(0, currentSize.X.Offset * 0.8, 0, currentSize.Y.Offset * 0.8),
            Position = UDim2.new(
                currentPos.X.Scale,
                currentPos.X.Offset + (currentSize.X.Offset * 0.1),
                currentPos.Y.Scale,
                currentPos.Y.Offset + (currentSize.Y.Offset * 0.1)
            )
        }, 0.2)
        
        closeTween.Completed:Connect(function()
            task.wait(0.1)
            -- Final scale to zero
            Tween(MainFrame, {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }, 0.15).Completed:Connect(function()
                ScreenGui:Destroy()
            end)
        end)
    end)
    
    -- Section Header (wird dynamisch geändert)
    local SectionHeader = Instance.new("TextLabel")
    SectionHeader.Name = "SectionHeader"
    SectionHeader.Size = UDim2.new(1, -20, 0, 30)
    SectionHeader.Position = UDim2.new(0, 10, 0, 10)
    SectionHeader.BackgroundTransparency = 1
    SectionHeader.Text = ""
    SectionHeader.TextColor3 = Colors.Accent
    SectionHeader.TextSize = 16
    SectionHeader.Font = Enum.Font.GothamBold
    SectionHeader.TextXAlignment = Enum.TextXAlignment.Left
    SectionHeader.Visible = false
    SectionHeader.Parent = ContentContainer
    
    -- Dragging
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    local dragConnection
    local inputChangedConnection
    
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            dragConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    dragInput = nil
                    if dragConnection then
                        dragConnection:Disconnect()
                        dragConnection = nil
                    end
                end
            end)
        end
    end)
    
    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            if dragStart and startPos then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragInput = nil
            dragStart = nil
            startPos = nil
            if dragConnection then
                dragConnection:Disconnect()
                dragConnection = nil
            end
        end
    end)
    
    -- Window Object / Theme + Popup handling
    local Window = {
        Tabs = {},
        CurrentTab = nil,
        SectionHeader = SectionHeader,
        NotificationHolder = NotificationHolder,
        PopupHolder = PopupHolder,
        PopupOverlay = PopupOverlay,
        ActivePopup = nil,
        ActivePopupClose = nil,
        FlagValues = {
            bc = Colors.Background,
            secondary = Colors.Secondary,
            accent = Colors.Accent,
            text = Colors.Text,
            textdark = Colors.TextDark,
            buttonbg = Colors.ButtonBg,
            border = Colors.Border
        },
        ThemedObjects = {},
        FlagListeners = {}
    }
    
    local flagToColorKey = {
        bc = "Background",
        secondary = "Secondary",
        accent = "Accent",
        text = "Text",
        textdark = "TextDark",
        buttonbg = "ButtonBg",
        border = "Border"
    }
    
    local colorKeyToFlag = {
        Background = "bc",
        Secondary = "secondary",
        Accent = "accent",
        Text = "text",
        TextDark = "textdark",
        ButtonBg = "buttonbg",
        Border = "border"
    }
    
    local function registerTheme(instance, property, flag)
        if not instance then
            warn("registerTheme: instance is nil")
            return
        end
        Window.ThemedObjects[flag] = Window.ThemedObjects[flag] or {}
        table.insert(Window.ThemedObjects[flag], {
            Instance = instance,
            Property = property
        })
        if Window.FlagValues[flag] and instance then
            instance[property] = Window.FlagValues[flag]
        end
    end
    
    local function style(instance, property, colorKey)
        local flag = colorKeyToFlag[colorKey] or colorKey
        if flag then
            registerTheme(instance, property, flag)
        end
    end
    
    -- Apply style to elements created before style function was defined
    style(MainFrame, "BackgroundColor3", "Background")
    style(Header, "BackgroundColor3", "Secondary")
    -- HeaderBorder removed, no longer needs styling
    style(Title, "TextColor3", "Text")
    style(MinimizeButton, "BackgroundColor3", "Background")
    style(MinimizeButton, "TextColor3", "Text")
    style(CloseButton, "BackgroundColor3", "Background")
    style(CloseButton, "TextColor3", "Text")
    style(SectionHeader, "TextColor3", "Accent")
    
    -- Setup button hover effects (after Window is created)
    CloseButton.MouseEnter:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}, 0.1)
    end)
    
    CloseButton.MouseLeave:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Window:GetFlag("bc")}, 0.1)
    end)
    
    MinimizeButton.MouseEnter:Connect(function()
        Tween(MinimizeButton, {BackgroundColor3 = Window:GetFlag("secondary")}, 0.1)
    end)
    
    MinimizeButton.MouseLeave:Connect(function()
        Tween(MinimizeButton, {BackgroundColor3 = Window:GetFlag("bc")}, 0.1)
    end)
    
    -- Update dragging to close popups (after Window is created)
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if Window.ActivePopupClose then
                Window.ActivePopupClose()
            end
        end
    end)
    
    function Window:SetFlag(flag, value)
        self.FlagValues[flag] = value
        
        if flagToColorKey[flag] then
            Colors[flagToColorKey[flag]] = value
        end
        
        if self.ThemedObjects[flag] then
            for _, entry in ipairs(self.ThemedObjects[flag]) do
                if entry.Instance and entry.Instance.Parent then
                    entry.Instance[entry.Property] = value
                end
            end
        end
        
        if self.FlagListeners[flag] then
            for _, cb in ipairs(self.FlagListeners[flag]) do
                task.spawn(cb, value)
            end
        end
    end
    
    function Window:GetFlag(flag)
        return self.FlagValues[flag]
    end
    
    function Window:BindFlag(flag, callback)
        self.FlagListeners[flag] = self.FlagListeners[flag] or {}
        table.insert(self.FlagListeners[flag], callback)
        if self.FlagValues[flag] then
            callback(self.FlagValues[flag])
        end
    end
    
    function Window:ShowPopup(owner, closeCallback)
        if self.ActivePopup and self.ActivePopup ~= owner and self.ActivePopupClose then
            self.ActivePopupClose()
        end
        self.ActivePopup = owner
        self.ActivePopupClose = closeCallback
        self.PopupOverlay.Visible = true
    end
    
    function Window:HidePopup(owner)
        if self.ActivePopup == owner then
            self.PopupOverlay.Visible = false
            self.ActivePopup = nil
            self.ActivePopupClose = nil
        end
    end
    
    PopupOverlay.MouseButton1Click:Connect(function()
        if Window.ActivePopupClose then
            Window.ActivePopupClose()
        end
    end)
    
    -- Toggle UI Function
    local uiVisible = true
    local toggleKeyConnection = nil
    
    function Window:ToggleUI()
        uiVisible = not uiVisible
        MainFrame.Visible = uiVisible
        if not uiVisible and Window.ActivePopupClose then
            Window.ActivePopupClose()
        end
    end
    
    -- Toggle UI Keybind
    function Window:SetToggleKey(keyCode)
        if toggleKeyConnection then
            toggleKeyConnection:Disconnect()
        end
        
        toggleKeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == keyCode then
                Window:ToggleUI()
            end
        end)
    end
    
    -- Mobile Toggle Button
    -- Detect mobile devices (phones and tablets with touch)
    local isMobile = UserInputService.TouchEnabled
    local MobileToggleButton = nil
    
    if isMobile then
        MobileToggleButton = Instance.new("TextButton")
        MobileToggleButton.Name = "MobileToggleButton"
        MobileToggleButton.Size = UDim2.new(0, 60, 0, 60)
        MobileToggleButton.Position = UDim2.new(1, -70, 1, -70)
        MobileToggleButton.AnchorPoint = Vector2.new(1, 1)
        MobileToggleButton.BackgroundColor3 = Colors.Accent
        style(MobileToggleButton, "BackgroundColor3", "Accent")
        MobileToggleButton.Text = "☰"
        MobileToggleButton.TextColor3 = Colors.Text
        style(MobileToggleButton, "TextColor3", "Text")
        MobileToggleButton.TextSize = 28
        MobileToggleButton.Font = Enum.Font.GothamBold
        MobileToggleButton.BorderSizePixel = 0
        MobileToggleButton.ZIndex = 100
        MobileToggleButton.Parent = ScreenGui
        CreateCorner(MobileToggleButton, 12)
        
        -- Shadow/Glow effect
        local Shadow = Instance.new("Frame")
        Shadow.Name = "Shadow"
        Shadow.Size = UDim2.new(1, 4, 1, 4)
        Shadow.Position = UDim2.new(0, -2, 0, -2)
        Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Shadow.BackgroundTransparency = 0.7
        Shadow.BorderSizePixel = 0
        Shadow.ZIndex = 99
        Shadow.Parent = MobileToggleButton
        CreateCorner(Shadow, 12)
        
        local buttonRotation = 0
        local isAnimating = false
        
        local function handleToggle()
            if isAnimating then return end
            isAnimating = true
            
            -- Smooth rotation animation
            buttonRotation = buttonRotation + 90
            Tween(MobileToggleButton, {Rotation = buttonRotation}, 0.3)
            
            -- Scale animation (press effect)
            Tween(MobileToggleButton, {Size = UDim2.new(0, 55, 0, 55)}, 0.1)
            task.wait(0.1)
            Tween(MobileToggleButton, {Size = UDim2.new(0, 60, 0, 60)}, 0.1)
            
            -- Toggle UI with smooth fade animation
            local wasVisible = uiVisible
            Window:ToggleUI()
            
            if not wasVisible then
                -- Fade in
                MainFrame.BackgroundTransparency = 1
                Tween(MainFrame, {BackgroundTransparency = 0}, 0.2)
            else
                -- Fade out
                Tween(MainFrame, {BackgroundTransparency = 1}, 0.2)
            end
            
            task.wait(0.1)
            isAnimating = false
        end
        
        -- Support both mouse and touch
        MobileToggleButton.MouseButton1Click:Connect(handleToggle)
        MobileToggleButton.Activated:Connect(handleToggle)
        
        -- Hover effects (for tablets with mouse support)
        MobileToggleButton.MouseEnter:Connect(function()
            if not isAnimating then
                Tween(MobileToggleButton, {Size = UDim2.new(0, 65, 0, 65)}, 0.15)
                Tween(Shadow, {BackgroundTransparency = 0.5}, 0.15)
            end
        end)
        
        MobileToggleButton.MouseLeave:Connect(function()
            if not isAnimating then
                Tween(MobileToggleButton, {Size = UDim2.new(0, 60, 0, 60)}, 0.15)
                Tween(Shadow, {BackgroundTransparency = 0.7}, 0.15)
            end
        end)
    end
    
    -- Tab erstellen
    function Window:CreateTab(tabName)
        local Tab = {}
        
        -- Tab Button (Text only, animated underline)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName
        TabButton.Size = UDim2.new(1, 0, 0, 30)
        TabButton.BackgroundTransparency = 1
        TabButton.Text = tabName
        TabButton.TextColor3 = Colors.TextDark
        style(TabButton, "TextColor3", "TextDark")
        TabButton.TextSize = 14
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.Parent = TabContainer
        
        local Highlight = Instance.new("Frame")
        Highlight.Name = "Highlight"
        Highlight.Size = UDim2.new(0, 0, 0, 2)
        Highlight.Position = UDim2.new(0, 0, 1, -2)
        Highlight.BackgroundColor3 = Colors.Accent
        style(Highlight, "BackgroundColor3", "Accent")
        Highlight.BorderSizePixel = 0
        Highlight.Parent = TabButton
        
        -- Tab Content
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = tabName .. "Content"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 4
        TabContent.ClipsDescendants = true
        TabContent.ScrollBarImageColor3 = Colors.Accent
        style(TabContent, "ScrollBarImageColor3", "Accent")
        TabContent.Visible = false
        TabContent.Parent = ContentContainer
        
        local ContentList = Instance.new("UIListLayout")
        ContentList.Padding = UDim.new(0, 8)
        ContentList.SortOrder = Enum.SortOrder.LayoutOrder
        ContentList.Parent = TabContent
        
        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingTop = UDim.new(0, 10)
        ContentPadding.PaddingBottom = UDim.new(0, 20)
        ContentPadding.PaddingLeft = UDim.new(0, 5)
        ContentPadding.PaddingRight = UDim.new(0, 10)
        ContentPadding.Parent = TabContent
        
        -- Auto-resize ScrollingFrame
        ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + ContentPadding.PaddingTop.Offset + ContentPadding.PaddingBottom.Offset + 20)
        end)
        
        TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(Window.Tabs) do
                tab.Content.Visible = false
                Tween(tab.Button, {TextColor3 = Window.FlagValues.textdark})
                if tab.Highlight then
                    Tween(tab.Highlight, {Size = UDim2.new(0, 0, 0, 2)})
                end
            end
            
            TabContent.Visible = true
            Tween(TabButton, {TextColor3 = Window.FlagValues.accent})
            Tween(Highlight, {Size = UDim2.new(1, 0, 0, 2)})
            Window.CurrentTab = Tab
            
            -- Update Section Header
            if Window.SectionHeader then
                local sectionText = "FE " .. tabName .. " Section"
                Window.SectionHeader.Text = sectionText
                Window.SectionHeader.Visible = true
            end
        end)
        
        Tab.Button = TabButton
        Tab.Content = TabContent
        Tab.Elements = {}
        Tab.Highlight = Highlight
        
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, {TextColor3 = Window.FlagValues.text})
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, {TextColor3 = Window.FlagValues.textdark})
            end
        end)
        
        -- Button (Standard)
        function Tab:CreateButton(config)
            config = config or {}
            local buttonName = config.Name or "Button"
            local callback = config.Callback or function() end
            
            local ButtonFrame = Instance.new("Frame")
            ButtonFrame.Size = UDim2.new(1, 0, 0, 40)
            ButtonFrame.BackgroundColor3 = Colors.ButtonBg
            style(ButtonFrame, "BackgroundColor3", "ButtonBg")
            ButtonFrame.BorderSizePixel = 0
            ButtonFrame.Parent = TabContent
            CreateCorner(ButtonFrame, 6)
            
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, -10, 1, -10)
            Button.Position = UDim2.new(0, 5, 0, 5)
            Button.BackgroundTransparency = 1
            Button.Text = buttonName
            Button.TextColor3 = Colors.Text
            style(Button, "TextColor3", "Text")
            Button.TextSize = 14
            Button.Font = Enum.Font.Gotham
            Button.Parent = ButtonFrame
            
            Button.MouseButton1Click:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Window.FlagValues.accent}, 0.1)
                wait(0.1)
                Tween(ButtonFrame, {BackgroundColor3 = Window.FlagValues.buttonbg}, 0.1)
                callback()
            end)
            
            Button.MouseEnter:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Window.FlagValues.border})
            end)
            
            Button.MouseLeave:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Window.FlagValues.buttonbg})
            end)
        end
        
        -- Premium Button (mit Icon und drei Punkten)
        function Tab:CreatePremiumButton(config)
            config = config or {}
            local buttonName = config.Name or "Premium Button"
            local callback = config.Callback or function() end
            
        local ButtonFrame = Instance.new("Frame")
        ButtonFrame.Size = UDim2.new(1, 0, 0, 45)
        ButtonFrame.BackgroundColor3 = Colors.ButtonBg
        style(ButtonFrame, "BackgroundColor3", "ButtonBg")
            ButtonFrame.BorderSizePixel = 0
            ButtonFrame.Parent = TabContent
            CreateCorner(ButtonFrame, 6)
            
            -- Thumbs up Icon (links)
            local Icon = Instance.new("TextLabel")
            Icon.Name = "Icon"
            Icon.Size = UDim2.new(0, 20, 0, 20)
            Icon.Position = UDim2.new(0, 12, 0.5, 0)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.BackgroundTransparency = 1
            Icon.Text = "👍"
            Icon.TextSize = 16
            Icon.Font = Enum.Font.Gotham
            Icon.TextColor3 = Colors.IconGray
            Icon.Parent = ButtonFrame
            
            -- Button Text
            local ButtonText = Instance.new("TextLabel")
            ButtonText.Name = "Text"
            ButtonText.Size = UDim2.new(1, -70, 1, 0)
            ButtonText.Position = UDim2.new(0, 40, 0, 0)
            ButtonText.BackgroundTransparency = 1
            ButtonText.Text = buttonName
            ButtonText.TextColor3 = Colors.Text
            style(ButtonText, "TextColor3", "Text")
            ButtonText.TextSize = 14
            ButtonText.Font = Enum.Font.Gotham
            ButtonText.TextXAlignment = Enum.TextXAlignment.Left
            ButtonText.Parent = ButtonFrame
            
            -- Three dots Icon (rechts)
            local DotsIcon = Instance.new("TextLabel")
            DotsIcon.Name = "DotsIcon"
            DotsIcon.Size = UDim2.new(0, 20, 0, 20)
            DotsIcon.Position = UDim2.new(1, -15, 0.5, 0)
            DotsIcon.AnchorPoint = Vector2.new(0, 0.5)
            DotsIcon.BackgroundTransparency = 1
            DotsIcon.Text = "⋮"
            DotsIcon.TextSize = 18
            DotsIcon.Font = Enum.Font.GothamBold
            DotsIcon.TextColor3 = Colors.IconGray
            DotsIcon.Rotation = 90
            DotsIcon.Parent = ButtonFrame
            
            -- Clickable Button
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 1, 0)
            Button.BackgroundTransparency = 1
            Button.Text = ""
            Button.Parent = ButtonFrame
            
            Button.MouseButton1Click:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Window.FlagValues.border}, 0.1)
                wait(0.1)
                Tween(ButtonFrame, {BackgroundColor3 = Window.FlagValues.buttonbg}, 0.1)
                callback()
            end)
            
            Button.MouseEnter:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Window.FlagValues.border})
            end)
            
            Button.MouseLeave:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Window.FlagValues.buttonbg})
            end)
        end
        
        -- Toggle
        function Tab:CreateToggle(config)
            config = config or {}
            local toggleName = config.Name or "Toggle"
            local default = config.Default or false
            local callback = config.Callback or function() end
            
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
            ToggleFrame.BackgroundColor3 = Colors.ButtonBg
            style(ToggleFrame, "BackgroundColor3", "ButtonBg")
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Parent = TabContent
            CreateCorner(ToggleFrame, 6)
            
            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = toggleName
            ToggleLabel.TextColor3 = Colors.Text
            style(ToggleLabel, "TextColor3", "Text")
            ToggleLabel.TextSize = 14
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.Parent = ToggleFrame
            
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Size = UDim2.new(0, 45, 0, 25)
            ToggleButton.Position = UDim2.new(1, -50, 0.5, 0)
            ToggleButton.AnchorPoint = Vector2.new(0, 0.5)
            ToggleButton.BackgroundColor3 = default and Colors.Success or Window.FlagValues.border
            ToggleButton.Text = ""
            ToggleButton.Parent = ToggleFrame
            CreateCorner(ToggleButton, 12)
            
            local ToggleCircle = Instance.new("Frame")
            ToggleCircle.Size = UDim2.new(0, 19, 0, 19)
            ToggleCircle.Position = default and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            ToggleCircle.AnchorPoint = Vector2.new(0, 0.5)
            ToggleCircle.BackgroundColor3 = Colors.Text
            style(ToggleCircle, "BackgroundColor3", "Text")
            ToggleCircle.BorderSizePixel = 0
            ToggleCircle.Parent = ToggleButton
            CreateCorner(ToggleCircle, 10)
            
            local toggled = default
            
            ToggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                
                Tween(ToggleButton, {BackgroundColor3 = toggled and Colors.Success or Window.FlagValues.border})
                Tween(ToggleCircle, {Position = toggled and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)})
                
                callback(toggled)
            end)
        end
        
        -- Slider
        function Tab:CreateSlider(config)
            config = config or {}
            local sliderName = config.Name or "Slider"
            local min = config.Min or 0
            local max = config.Max or 100
            local default = config.Default or min
            local callback = config.Callback or function() end
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 55)
            SliderFrame.BackgroundColor3 = Colors.ButtonBg
            style(SliderFrame, "BackgroundColor3", "ButtonBg")
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Parent = TabContent
            CreateCorner(SliderFrame, 6)
            
            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Size = UDim2.new(1, -60, 0, 20)
            SliderLabel.Position = UDim2.new(0, 10, 0, 5)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Text = sliderName
            SliderLabel.TextColor3 = Colors.Text
            style(SliderLabel, "TextColor3", "Text")
            SliderLabel.TextSize = 14
            SliderLabel.Font = Enum.Font.Gotham
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            SliderLabel.Parent = SliderFrame
            
            local SliderValue = Instance.new("TextLabel")
            SliderValue.Size = UDim2.new(0, 50, 0, 20)
            SliderValue.Position = UDim2.new(1, -55, 0, 5)
            SliderValue.BackgroundTransparency = 1
            SliderValue.Text = tostring(default)
            SliderValue.TextColor3 = Colors.Accent
            style(SliderValue, "TextColor3", "Accent")
            SliderValue.TextSize = 14
            SliderValue.Font = Enum.Font.GothamBold
            SliderValue.TextXAlignment = Enum.TextXAlignment.Right
            SliderValue.Parent = SliderFrame
            
            local SliderBar = Instance.new("Frame")
            SliderBar.Size = UDim2.new(1, -20, 0, 6)
            SliderBar.Position = UDim2.new(0, 10, 1, -15)
            SliderBar.BackgroundColor3 = Colors.Background
            style(SliderBar, "BackgroundColor3", "Background")
            SliderBar.BorderSizePixel = 0
            SliderBar.Parent = SliderFrame
            CreateCorner(SliderBar, 3)
            
            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            SliderFill.BackgroundColor3 = Colors.Accent
            style(SliderFill, "BackgroundColor3", "Accent")
            SliderFill.BorderSizePixel = 0
            SliderFill.Parent = SliderBar
            CreateCorner(SliderFill, 3)
            
            local dragging = false
            
            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local sizeX = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                    local value = math.floor(min + (max - min) * sizeX)
                    
                    SliderFill.Size = UDim2.new(sizeX, 0, 1, 0)
                    SliderValue.Text = tostring(value)
                    callback(value)
                end
            end)
        end
        
        -- Text Input
        function Tab:CreateTextBox(config)
            config = config or {}
            local inputName = config.Name or "Input"
            local placeholder = config.Placeholder or "Type here..."
            local default = config.Default or ""
            local callback = config.Callback or function() end
            
            local InputFrame = Instance.new("Frame")
            InputFrame.Size = UDim2.new(1, 0, 0, 60)
            InputFrame.BackgroundColor3 = Colors.ButtonBg
            style(InputFrame, "BackgroundColor3", "ButtonBg")
            InputFrame.BorderSizePixel = 0
            InputFrame.Parent = TabContent
            CreateCorner(InputFrame, 8)
            
            local InputLabel = Instance.new("TextLabel")
            InputLabel.Size = UDim2.new(1, -20, 0, 18)
            InputLabel.Position = UDim2.new(0, 10, 0, 8)
            InputLabel.BackgroundTransparency = 1
            InputLabel.Text = inputName
            InputLabel.TextColor3 = Colors.TextDark
            InputLabel.TextSize = 13
            InputLabel.Font = Enum.Font.Gotham
            InputLabel.TextXAlignment = Enum.TextXAlignment.Left
            InputLabel.Parent = InputFrame
            
            local TextBox = Instance.new("TextBox")
            TextBox.Size = UDim2.new(1, -20, 0, 28)
            TextBox.Position = UDim2.new(0, 10, 0, 28)
            TextBox.BackgroundColor3 = Colors.Secondary
            style(TextBox, "BackgroundColor3", "Secondary")
            TextBox.BorderSizePixel = 0
            TextBox.PlaceholderText = placeholder
            TextBox.Text = default
            TextBox.TextColor3 = Colors.Text
            TextBox.PlaceholderColor3 = Colors.TextDark
            TextBox.TextSize = 14
            TextBox.ClearTextOnFocus = false
            TextBox.Font = Enum.Font.Gotham
            TextBox.Parent = InputFrame
            CreateCorner(TextBox, 6)
            
            local function setActive(active)
                Tween(InputFrame, {BackgroundColor3 = active and Colors.Secondary or Colors.ButtonBg}, 0.15)
                Tween(TextBox, {BackgroundColor3 = active and Colors.Border or Colors.Secondary}, 0.15)
            end
            
            TextBox.Focused:Connect(function()
                setActive(true)
            end)
            
            TextBox.FocusLost:Connect(function(enterPressed)
                setActive(false)
                callback(TextBox.Text, enterPressed)
            end)
            
            return TextBox
        end
        
        -- Keybind Setter
        function Tab:CreateKeybind(config)
            config = config or {}
            local bindName = config.Name or "Keybind"
            local defaultKey = config.Default or Enum.KeyCode.E
            local callback = config.Callback or function() end
            
            local currentKey = defaultKey
            local listening = false
            local keyConnection
            
            local KeybindFrame = Instance.new("Frame")
            KeybindFrame.Size = UDim2.new(1, 0, 0, 55)
            KeybindFrame.BackgroundColor3 = Colors.ButtonBg
            style(KeybindFrame, "BackgroundColor3", "ButtonBg")
            KeybindFrame.BorderSizePixel = 0
            KeybindFrame.Parent = TabContent
            CreateCorner(KeybindFrame, 8)
            
            local KeybindLabel = Instance.new("TextLabel")
            KeybindLabel.Size = UDim2.new(1, -20, 0, 20)
            KeybindLabel.Position = UDim2.new(0, 10, 0, 8)
            KeybindLabel.BackgroundTransparency = 1
            KeybindLabel.Text = bindName
            KeybindLabel.TextColor3 = Colors.Text
            KeybindLabel.TextSize = 14
            KeybindLabel.Font = Enum.Font.Gotham
            KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
            KeybindLabel.Parent = KeybindFrame
            
            local KeybindButton = Instance.new("TextButton")
            KeybindButton.Size = UDim2.new(0, 120, 0, 26)
            KeybindButton.Position = UDim2.new(1, -130, 0, 24)
            KeybindButton.BackgroundColor3 = Colors.Secondary
            style(KeybindButton, "BackgroundColor3", "Secondary")
            KeybindButton.TextColor3 = Colors.Text
            KeybindButton.TextSize = 14
            KeybindButton.Font = Enum.Font.GothamBold
            KeybindButton.Text = defaultKey.Name
            KeybindButton.Parent = KeybindFrame
            KeybindButton.AutoButtonColor = false
            CreateCorner(KeybindButton, 6)
            
            local function updateText(temp)
                if temp then
                    KeybindButton.Text = "Press key..."
                else
                    KeybindButton.Text = currentKey.Name
                end
            end
            
            local function setListening(state)
                listening = state
                updateText(state)
                Tween(KeybindButton, {BackgroundColor3 = state and Colors.Accent or Colors.Secondary}, 0.15)
            end
            
            keyConnection = UserInputService.InputBegan:Connect(function(input, gp)
                if not listening or gp then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    currentKey = input.KeyCode
                    setListening(false)
                    callback(currentKey)
                end
            end)
            
            KeybindButton.MouseButton1Click:Connect(function()
                setListening(true)
            end)
            
            KeybindButton.MouseEnter:Connect(function()
                if not listening then
                    Tween(KeybindButton, {BackgroundColor3 = Colors.Border}, 0.15)
                end
            end)
            
            KeybindButton.MouseLeave:Connect(function()
                if not listening then
                    Tween(KeybindButton, {BackgroundColor3 = Colors.Secondary}, 0.15)
                end
            end)
            
            KeybindFrame.AncestryChanged:Connect(function(_, parent)
                if not parent and keyConnection then
                    keyConnection:Disconnect()
                end
            end)
            
            return {
                SetKey = function(_, newKey)
                    currentKey = newKey
                    updateText()
                end,
                GetKey = function()
                    return currentKey
                end
            }
        end
        
        -- Color Picker
        function Tab:CreateColorPicker(config)
            config = config or {}
            local pickerName = config.Name or "Color Picker"
            local flag = config.Flag
            local default = config.Default or Color3.fromRGB(255, 255, 255)
            if flag and Window:GetFlag(flag) then
                default = Window:GetFlag(flag)
            end
            local callback = config.Callback or function() end
            
            local hsv = {Color3.toHSV(default)}
            local currentColor = default
            
            local PickerFrame = Instance.new("Frame")
            PickerFrame.Size = UDim2.new(1, 0, 0, 80)
            PickerFrame.BackgroundColor3 = Colors.ButtonBg
            style(PickerFrame, "BackgroundColor3", "ButtonBg")
            PickerFrame.BorderSizePixel = 0
            PickerFrame.Visible = true
            PickerFrame.Parent = TabContent
            PickerFrame.ClipsDescendants = false
            CreateCorner(PickerFrame, 8)
            
            local PickerLabel = Instance.new("TextLabel")
            PickerLabel.Size = UDim2.new(1, -20, 0, 20)
            PickerLabel.Position = UDim2.new(0, 10, 0, 8)
            PickerLabel.BackgroundTransparency = 1
            PickerLabel.Text = pickerName
            PickerLabel.TextColor3 = Colors.Text
            style(PickerLabel, "TextColor3", "Text")
            PickerLabel.TextSize = 14
            PickerLabel.Font = Enum.Font.Gotham
            PickerLabel.TextXAlignment = Enum.TextXAlignment.Left
            PickerLabel.Visible = true
            PickerLabel.Parent = PickerFrame
            
            local PreviewButton = Instance.new("TextButton")
            PreviewButton.Size = UDim2.new(0, 160, 0, 30)
            PreviewButton.Position = UDim2.new(0, 10, 0, 36)
            PreviewButton.Text = ""
            PreviewButton.AutoButtonColor = false
            PreviewButton.BackgroundColor3 = Colors.Secondary
            style(PreviewButton, "BackgroundColor3", "Secondary")
            PreviewButton.TextColor3 = Colors.Text
            PreviewButton.Font = Enum.Font.GothamBold
            PreviewButton.TextSize = 14
            PreviewButton.Parent = PickerFrame
            CreateCorner(PreviewButton, 6)
            
            local PreviewColor = Instance.new("Frame")
            PreviewColor.Size = UDim2.new(0, 26, 0, 26)
            PreviewColor.Position = UDim2.new(0, 4, 0.5, 0)
            PreviewColor.AnchorPoint = Vector2.new(0, 0.5)
            PreviewColor.BackgroundColor3 = currentColor
            PreviewColor.BorderSizePixel = 0
            PreviewColor.Parent = PreviewButton
            CreateCorner(PreviewColor, 6)
            
            local PreviewHex = Instance.new("TextLabel")
            PreviewHex.Size = UDim2.new(1, -36, 1, 0)
            PreviewHex.Position = UDim2.new(0, 34, 0, 0)
            PreviewHex.BackgroundTransparency = 1
            PreviewHex.Text = ""
            PreviewHex.TextColor3 = Colors.Text
            PreviewHex.TextSize = 14
            PreviewHex.Font = Enum.Font.Gotham
            PreviewHex.TextXAlignment = Enum.TextXAlignment.Left
            PreviewHex.Parent = PreviewButton
            
            local PickerPanel = Instance.new("Frame")
            PickerPanel.Size = UDim2.new(0, 260, 0, 0)
            PickerPanel.BackgroundColor3 = Colors.Secondary
            style(PickerPanel, "BackgroundColor3", "Secondary")
            PickerPanel.BorderSizePixel = 0
            PickerPanel.Visible = false
            PickerPanel.ZIndex = 100
            PickerPanel.ClipsDescendants = true
            PickerPanel.Parent = Window.PopupHolder
            CreateCorner(PickerPanel, 8)
            
            local PanelPadding = Instance.new("UIPadding")
            PanelPadding.PaddingTop = UDim.new(0, 10)
            PanelPadding.PaddingBottom = UDim.new(0, 10)
            PanelPadding.PaddingLeft = UDim.new(0, 10)
            PanelPadding.PaddingRight = UDim.new(0, 10)
            PanelPadding.Parent = PickerPanel
            
            local ColorMap = Instance.new("ImageLabel")
            ColorMap.Size = UDim2.new(0, 170, 0, 120)
            ColorMap.BackgroundColor3 = Color3.new(1, 1, 1)
            ColorMap.BorderSizePixel = 0
            ColorMap.Image = "rbxassetid://4155801252"
            ColorMap.ZIndex = 21
            ColorMap.Parent = PickerPanel
            
            local MapIndicator = Instance.new("Frame")
            MapIndicator.Size = UDim2.new(0, 10, 0, 10)
            MapIndicator.BackgroundColor3 = Colors.Text
            MapIndicator.BorderSizePixel = 0
            MapIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
            MapIndicator.ZIndex = 22
            MapIndicator.Parent = ColorMap
            CreateCorner(MapIndicator, 5)
            
            local ValueSlider = Instance.new("Frame")
            ValueSlider.Size = UDim2.new(0, 20, 0, 120)
            ValueSlider.Position = UDim2.new(0, 180, 0, 0)
            ValueSlider.BackgroundColor3 = Colors.ButtonBg
            style(ValueSlider, "BackgroundColor3", "ButtonBg")
            ValueSlider.BorderSizePixel = 0
            ValueSlider.ZIndex = 21
            ValueSlider.Parent = PickerPanel
            CreateCorner(ValueSlider, 6)
            
            local ValueGradient = Instance.new("UIGradient")
            ValueGradient.Rotation = -90
            ValueGradient.Color = ColorSequence.new(Color3.fromHSV(hsv[1], hsv[2], 1), Color3.new(0, 0, 0))
            ValueGradient.Parent = ValueSlider
            
            local ValueHandle = Instance.new("Frame")
            ValueHandle.Size = UDim2.new(1, 0, 0, 8)
            ValueHandle.BackgroundColor3 = Colors.Text
            ValueHandle.BorderSizePixel = 0
            ValueHandle.AnchorPoint = Vector2.new(0, 0.5)
            ValueHandle.ZIndex = 22
            ValueHandle.Parent = ValueSlider
            CreateCorner(ValueHandle, 4)
            
            local HexInputLabel = Instance.new("TextLabel")
            HexInputLabel.Size = UDim2.new(0, 100, 0, 18)
            HexInputLabel.Position = UDim2.new(0, 0, 0, 132)
            HexInputLabel.BackgroundTransparency = 1
            HexInputLabel.Text = "Hex"
            HexInputLabel.TextColor3 = Colors.TextDark
            HexInputLabel.TextSize = 12
            HexInputLabel.Font = Enum.Font.Gotham
            HexInputLabel.TextXAlignment = Enum.TextXAlignment.Left
            HexInputLabel.ZIndex = 21
            HexInputLabel.Parent = PickerPanel
            
            local HexInput = Instance.new("TextBox")
            HexInput.Size = UDim2.new(1, 0, 0, 28)
            HexInput.Position = UDim2.new(0, 0, 0, 150)
            HexInput.BackgroundColor3 = Colors.ButtonBg
            style(HexInput, "BackgroundColor3", "ButtonBg")
            HexInput.BorderSizePixel = 0
            HexInput.TextColor3 = Colors.Text
            HexInput.PlaceholderText = "#FFFFFF"
            HexInput.TextSize = 14
            HexInput.Font = Enum.Font.Gotham
            HexInput.ZIndex = 21
            HexInput.Parent = PickerPanel
            HexInput.ClearTextOnFocus = false
            CreateCorner(HexInput, 6)
            
            local RGBInputLabel = Instance.new("TextLabel")
            RGBInputLabel.Size = UDim2.new(0, 100, 0, 18)
            RGBInputLabel.Position = UDim2.new(0, 0, 0, 184)
            RGBInputLabel.BackgroundTransparency = 1
            RGBInputLabel.Text = "RGB"
            RGBInputLabel.TextColor3 = Colors.TextDark
            RGBInputLabel.TextSize = 12
            RGBInputLabel.Font = Enum.Font.Gotham
            RGBInputLabel.TextXAlignment = Enum.TextXAlignment.Left
            RGBInputLabel.ZIndex = 21
            RGBInputLabel.Parent = PickerPanel
            
            local RGBInput = Instance.new("TextBox")
            RGBInput.Size = UDim2.new(1, 0, 0, 28)
            RGBInput.Position = UDim2.new(0, 0, 0, 202)
            RGBInput.BackgroundColor3 = Colors.ButtonBg
            style(RGBInput, "BackgroundColor3", "ButtonBg")
            RGBInput.BorderSizePixel = 0
            RGBInput.TextColor3 = Colors.Text
            RGBInput.PlaceholderText = "255, 255, 255"
            RGBInput.TextSize = 14
            RGBInput.Font = Enum.Font.Gotham
            RGBInput.ZIndex = 21
            RGBInput.ClearTextOnFocus = false
            RGBInput.Parent = PickerPanel
            CreateCorner(RGBInput, 6)
            
            PickerPanel.Size = UDim2.new(0, 260, 0, 0)
            
            local panelOpen = false
            
            local function colorToHex(color)
                local r = math.floor(color.R * 255 + 0.5)
                local g = math.floor(color.G * 255 + 0.5)
                local b = math.floor(color.B * 255 + 0.5)
                return string.format("#%02X%02X%02X", r, g, b), r, g, b
            end
            
            local function updateUI()
                PreviewColor.BackgroundColor3 = currentColor
                local hex, r, g, b = colorToHex(currentColor)
                PreviewHex.Text = hex
                HexInput.Text = hex
                RGBInput.Text = string.format("%d, %d, %d", r, g, b)
                MapIndicator.Position = UDim2.new(hsv[1], -5, 1 - hsv[2], -5)
                ValueHandle.Position = UDim2.new(0, 0, 1 - hsv[3], 0)
                ValueGradient.Color = ColorSequence.new(Color3.fromHSV(hsv[1], hsv[2], 1), Color3.new(0, 0, 0))
            end
            
            local suppressFlagUpdate = false
            
            local function setColorFromHSV(h, s, v)
                hsv[1] = math.clamp(h, 0, 1)
                hsv[2] = math.clamp(s, 0, 1)
                hsv[3] = math.clamp(v, 0, 1)
                currentColor = Color3.fromHSV(hsv[1], hsv[2], hsv[3])
                updateUI()
                callback(currentColor)
                if flag and not suppressFlagUpdate then
                    Window:SetFlag(flag, currentColor)
                end
            end
            
            setColorFromHSV(hsv[1], hsv[2], hsv[3])
            
            local function updatePanelPosition()
                if not PreviewButton or not PreviewButton.Parent then return end
                
                local buttonPos = PreviewButton.AbsolutePosition
                local buttonSize = PreviewButton.AbsoluteSize
                local screenSize = Window.PopupHolder.AbsoluteSize
                
                local panelWidth = 260
                local panelHeight = 240
                
                local x = buttonPos.X
                local y = buttonPos.Y + buttonSize.Y + 8
                
                -- Check if panel goes off screen bottom
                if y + panelHeight > screenSize.Y - 10 then
                    y = buttonPos.Y - panelHeight - 8
                    -- If still off screen top, position below
                    if y < 10 then
                        y = buttonPos.Y + buttonSize.Y + 8
                        panelHeight = math.min(240, screenSize.Y - y - 10)
                    end
                end
                
                -- Clamp X position
                x = math.clamp(x, 10, screenSize.X - panelWidth - 10)
                
                PickerPanel.Position = UDim2.new(0, x, 0, y)
            end
            
            local function togglePanel(force)
                local target = force
                if target == nil then
                    target = not panelOpen
                end
                if target == panelOpen then
                    return
                end
                panelOpen = target
                
                if panelOpen then
                    updatePanelPosition()
                    PickerPanel.Visible = true
                    PickerPanel.Size = UDim2.new(0, 260, 0, 0)
                    Tween(PickerPanel, {Size = UDim2.new(0, 260, 0, 240)}, 0.25)
                    Window:ShowPopup(PickerPanel, function()
                        togglePanel(false)
                    end)
                else
                    Window:HidePopup(PickerPanel)
                    local tween = Tween(PickerPanel, {Size = UDim2.new(0, 260, 0, 0)}, 0.2)
                    tween.Completed:Connect(function()
                        if not panelOpen then
                            PickerPanel.Visible = false
                        end
                    end)
                end
            end
            
            PreviewButton.MouseButton1Click:Connect(function()
                togglePanel()
            end)
            
            local mapDragging = false
            local valueDragging = false
            
            local function handleMapInput(input)
                local relative = Vector2.new(
                    math.clamp((input.Position.X - ColorMap.AbsolutePosition.X) / ColorMap.AbsoluteSize.X, 0, 1),
                    math.clamp((input.Position.Y - ColorMap.AbsolutePosition.Y) / ColorMap.AbsoluteSize.Y, 0, 1)
                )
                setColorFromHSV(relative.X, 1 - relative.Y, hsv[3])
            end
            
            local function handleValueInput(input)
                local relativeY = math.clamp((input.Position.Y - ValueSlider.AbsolutePosition.Y) / ValueSlider.AbsoluteSize.Y, 0, 1)
                setColorFromHSV(hsv[1], hsv[2], 1 - relativeY)
            end
            
            ColorMap.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    mapDragging = true
                    handleMapInput(input)
                end
            end)
            
            ValueSlider.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    valueDragging = true
                    handleValueInput(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    mapDragging = false
                    valueDragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    if mapDragging then
                        handleMapInput(input)
                    elseif valueDragging then
                        handleValueInput(input)
                    end
                end
            end)
            
            HexInput.FocusLost:Connect(function(enterPressed)
                if not enterPressed then return end
                local text = HexInput.Text:gsub("#", "")
                if #text == 6 and text:match("%x%x%x%x%x%x") then
                    local r = tonumber(text:sub(1, 2), 16)
                    local g = tonumber(text:sub(3, 4), 16)
                    local b = tonumber(text:sub(5, 6), 16)
                    local color = Color3.fromRGB(r, g, b)
                    hsv = {Color3.toHSV(color)}
                    setColorFromHSV(hsv[1], hsv[2], hsv[3])
                else
                    updateUI()
                end
            end)
            
            RGBInput.FocusLost:Connect(function(enterPressed)
                if not enterPressed then return end
                local r, g, b = RGBInput.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
                r = tonumber(r)
                g = tonumber(g)
                b = tonumber(b)
                if r and g and b then
                    r = math.clamp(r, 0, 255)
                    g = math.clamp(g, 0, 255)
                    b = math.clamp(b, 0, 255)
                    local color = Color3.fromRGB(r, g, b)
                    hsv = {Color3.toHSV(color)}
                    setColorFromHSV(hsv[1], hsv[2], hsv[3])
                else
                    updateUI()
                end
            end)
            
            if flag then
                Window:BindFlag(flag, function(color)
                    if not mapDragging and not valueDragging then
                        suppressFlagUpdate = true
                        hsv = {Color3.toHSV(color)}
                        setColorFromHSV(hsv[1], hsv[2], hsv[3])
                        suppressFlagUpdate = false
                    end
                end)
            end
            
            return {
                SetColor = function(_, color)
                    hsv = {Color3.toHSV(color)}
                    setColorFromHSV(hsv[1], hsv[2], hsv[3])
                end,
                GetColor = function()
                    return currentColor
                end
            }
        end
        
        -- Section Label
        function Tab:CreateSection(title)
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Size = UDim2.new(1, 0, 0, 30)
            SectionFrame.BackgroundTransparency = 1
            SectionFrame.Parent = TabContent
            
            local SectionLabel = Instance.new("TextLabel")
            SectionLabel.Size = UDim2.new(1, 0, 1, 0)
            SectionLabel.BackgroundTransparency = 1
            SectionLabel.Text = title or "Section"
            SectionLabel.TextColor3 = Colors.Text
            SectionLabel.TextSize = 16
            SectionLabel.Font = Enum.Font.GothamBold
            SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
            SectionLabel.Parent = SectionFrame
            
            local AccentLine = Instance.new("Frame")
            AccentLine.Size = UDim2.new(0, 70, 0, 2)
            AccentLine.Position = UDim2.new(0, 0, 1, -2)
            AccentLine.BackgroundColor3 = Colors.Accent
            AccentLine.BorderSizePixel = 0
            AccentLine.Parent = SectionFrame
            
            Tween(AccentLine, {Size = UDim2.new(0, 120, 0, 2)}, 0.4)
            
            return SectionFrame
        end
        
        -- Dropdown (Completely rewritten)
        function Tab:CreateDropdown(config)
            config = config or {}
            local dropdownName = config.Name or "Dropdown"
            local options = config.Options or {"Option 1", "Option 2"}
            local callback = config.Callback or function() end
            local flag = config.Flag
            local default = config.Default or options[1]
            
            if flag and Window:GetFlag(flag) then
                default = Window:GetFlag(flag)
            end
            
            local currentValue = default
            
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 60)
            Row.BackgroundTransparency = 1
            Row.Parent = TabContent
            
            local Shell = Instance.new("Frame")
            Shell.Size = UDim2.new(1, 0, 1, 0)
            Shell.BackgroundColor3 = Colors.ButtonBg
            style(Shell, "BackgroundColor3", "buttonbg")
            Shell.BorderSizePixel = 0
            Shell.Parent = Row
            CreateCorner(Shell, 8)
            
            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -20, 0, 18)
            TitleLabel.Position = UDim2.new(0, 10, 0, 8)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Font = Enum.Font.Gotham
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Text = dropdownName
            TitleLabel.TextColor3 = Colors.TextDark
            style(TitleLabel, "TextColor3", "textdark")
            TitleLabel.TextSize = 13
            TitleLabel.Parent = Shell
            
            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Size = UDim2.new(1, -40, 0, 26)
            ValueLabel.Position = UDim2.new(0, 10, 0, 30)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
            ValueLabel.Text = tostring(currentValue)
            ValueLabel.TextColor3 = Colors.Text
            style(ValueLabel, "TextColor3", "text")
            ValueLabel.TextSize = 15
            ValueLabel.Parent = Shell
            
            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 20, 0, 20)
            Arrow.Position = UDim2.new(1, -25, 0, 30)
            Arrow.AnchorPoint = Vector2.new(0, 0.5)
            Arrow.BackgroundTransparency = 1
            Arrow.Font = Enum.Font.GothamBold
            Arrow.Text = "▼"
            Arrow.TextSize = 16
            Arrow.TextColor3 = Colors.TextDark
            style(Arrow, "TextColor3", "textdark")
            Arrow.Parent = Shell
            
            local ClickArea = Instance.new("TextButton")
            ClickArea.Size = UDim2.new(1, 0, 1, 0)
            ClickArea.BackgroundTransparency = 1
            ClickArea.Text = ""
            ClickArea.AutoButtonColor = false
            ClickArea.Parent = Shell
            
            -- Menu Frame (in PopupHolder)
            local Menu = Instance.new("Frame")
            Menu.Size = UDim2.new(0, 0, 0, 0)
            Menu.BackgroundColor3 = Colors.Secondary
            style(Menu, "BackgroundColor3", "secondary")
            Menu.BorderSizePixel = 0
            Menu.Visible = false
            Menu.ZIndex = 70
            Menu.ClipsDescendants = true
            Menu.Parent = Window.PopupHolder
            CreateCorner(Menu, 8)
            
            local Scroll = Instance.new("ScrollingFrame")
            Scroll.Size = UDim2.new(1, -12, 1, -12)
            Scroll.Position = UDim2.new(0, 6, 0, 6)
            Scroll.BackgroundTransparency = 1
            Scroll.BorderSizePixel = 0
            Scroll.ScrollBarThickness = 4
            Scroll.ScrollBarImageColor3 = Colors.Accent
            style(Scroll, "ScrollBarImageColor3", "accent")
            Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            Scroll.Parent = Menu
            
            local OptionList = Instance.new("UIListLayout")
            OptionList.Padding = UDim.new(0, 6)
            OptionList.Parent = Scroll
            OptionList.SortOrder = Enum.SortOrder.LayoutOrder
            
            local OptionPadding = Instance.new("UIPadding")
            OptionPadding.PaddingLeft = UDim.new(0, 4)
            OptionPadding.PaddingRight = UDim.new(0, 4)
            OptionPadding.PaddingTop = UDim.new(0, 4)
            OptionPadding.PaddingBottom = UDim.new(0, 4)
            OptionPadding.Parent = Scroll
            
            OptionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Scroll.CanvasSize = UDim2.new(0, 0, 0, OptionList.AbsoluteContentSize.Y + 8)
            end)
            
            local function setValue(value)
                currentValue = value
                ValueLabel.Text = tostring(value)
                if flag then
                    Window:SetFlag(flag, value)
                end
                callback(value)
            end
            setValue(default)
            
            local menuOpen = false
            local menuTween
            
            local function updateMenuPosition()
                if not Shell or not Shell.Parent then return end
                
                local shellPos = Shell.AbsolutePosition
                local shellSize = Shell.AbsoluteSize
                local screenSize = Window.PopupHolder.AbsoluteSize
                
                local optionHeight = 32
                local maxHeight = 220
                local minHeight = 90
                local calculatedHeight = math.clamp(#options * (optionHeight + 6) + 8, minHeight, maxHeight)
                
                local menuWidth = shellSize.X
                local menuHeight = calculatedHeight
                
                local x = shellPos.X
                local y = shellPos.Y + shellSize.Y + 6
                
                -- Check if menu goes off screen bottom
                if y + menuHeight > screenSize.Y - 10 then
                    y = shellPos.Y - menuHeight - 6
                    -- If still off screen top, position below
                    if y < 10 then
                        y = shellPos.Y + shellSize.Y + 6
                        menuHeight = math.min(calculatedHeight, screenSize.Y - y - 10)
                    end
                end
                
                -- Clamp X position
                x = math.clamp(x, 10, screenSize.X - menuWidth - 10)
                
                Menu.Position = UDim2.new(0, x, 0, y)
                return menuWidth, menuHeight
            end
            
            local function closeMenu()
                if not menuOpen then return end
                menuOpen = false
                
                if menuTween then
                    menuTween:Cancel()
                end
                
                Window:HidePopup(Menu)
                
                local currentSize = Menu.AbsoluteSize
                menuTween = Tween(Menu, {
                    Size = UDim2.new(0, currentSize.X, 0, 0)
                }, 0.2)
                
                menuTween.Completed:Connect(function()
                    if not menuOpen then
                        Menu.Visible = false
                        Menu.Size = UDim2.new(0, 0, 0, 0)
                    end
                end)
                
                Tween(Arrow, {Rotation = 0}, 0.2)
            end
            
            local function openMenu()
                if menuOpen then
                    closeMenu()
                    return
                end
                
                -- Close any other popups
                if Window.ActivePopupClose then
                    Window.ActivePopupClose()
                end
                
                menuOpen = true
                local menuWidth, menuHeight = updateMenuPosition()
                
                Menu.Visible = true
                Menu.Size = UDim2.new(0, menuWidth, 0, 0)
                
                Window:ShowPopup(Menu, closeMenu)
                
                menuTween = Tween(Menu, {
                    Size = UDim2.new(0, menuWidth, 0, menuHeight)
                }, 0.2)
                
                Tween(Arrow, {Rotation = 180}, 0.2)
            end
            
            ClickArea.MouseButton1Click:Connect(function()
                openMenu()
            end)
            
            -- Create option buttons
            for i, option in ipairs(options) do
                local OptionButton = Instance.new("TextButton")
                OptionButton.Size = UDim2.new(1, -8, 0, 32)
                OptionButton.BackgroundColor3 = Colors.ButtonBg
                style(OptionButton, "BackgroundColor3", "buttonbg")
                OptionButton.Text = tostring(option)
                OptionButton.TextColor3 = Colors.Text
                style(OptionButton, "TextColor3", "text")
                OptionButton.TextSize = 14
                OptionButton.Font = Enum.Font.Gotham
                OptionButton.TextXAlignment = Enum.TextXAlignment.Left
                OptionButton.AutoButtonColor = false
                OptionButton.Parent = Scroll
                CreateCorner(OptionButton, 6)
                
                local OptionPadding = Instance.new("UIPadding")
                OptionPadding.PaddingLeft = UDim.new(0, 10)
                OptionPadding.Parent = OptionButton
                
                OptionButton.MouseButton1Click:Connect(function()
                    setValue(option)
                    closeMenu()
                end)
                
                OptionButton.MouseEnter:Connect(function()
                    if not menuOpen then return end
                    Tween(OptionButton, {BackgroundColor3 = Window.FlagValues.border}, 0.1)
                end)
                
                OptionButton.MouseLeave:Connect(function()
                    if not menuOpen then return end
                    Tween(OptionButton, {BackgroundColor3 = Window.FlagValues.buttonbg}, 0.1)
                end)
            end
            
            -- Update position when window moves
            local updateConnection
            updateConnection = UserInputService.InputChanged:Connect(function()
                if menuOpen then
                    updateMenuPosition()
                end
            end)
            
            Menu.AncestryChanged:Connect(function()
                if not Menu.Parent and updateConnection then
                    updateConnection:Disconnect()
                end
            end)
        end
        
        -- Label
        function Tab:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, 0, 0, 35)
            LabelFrame.BackgroundColor3 = Colors.ButtonBg
            style(LabelFrame, "BackgroundColor3", "ButtonBg")
            LabelFrame.BorderSizePixel = 0
            LabelFrame.Parent = TabContent
            CreateCorner(LabelFrame, 6)
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Colors.TextDark
            style(Label, "TextColor3", "TextDark")
            Label.TextSize = 13
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = LabelFrame
            
            return {
                SetText = function(self, newText)
                    Label.Text = newText
                end
            }
        end
        
        table.insert(Window.Tabs, Tab)
        
        if #Window.Tabs == 1 then
            TabContent.Visible = true
            TabButton.TextColor3 = Window.FlagValues.accent
            Highlight.Size = UDim2.new(1, 0, 0, 2)
            Window.CurrentTab = Tab
            if Window.SectionHeader then
                local sectionText = "FE " .. tabName .. " Section"
                Window.SectionHeader.Text = sectionText
                Window.SectionHeader.Visible = true
            end
        end
        
        return Tab
    end
    
    -- Notification System
    function Window:Notify(config)
        config = config or {}
        local title = config.Title or "Ice Hub"
        local message = config.Message or ""
        local duration = config.Duration or 4
        local accentColor = config.Color or Window.FlagValues.accent
        
        local NotificationFrame = Instance.new("Frame")
        NotificationFrame.Size = UDim2.new(1, 0, 0, message ~= "" and 70 or 52)
        NotificationFrame.BackgroundColor3 = Colors.Secondary
        style(NotificationFrame, "BackgroundColor3", "Secondary")
        NotificationFrame.BackgroundTransparency = 1
        NotificationFrame.Parent = self.NotificationHolder
        NotificationFrame.ClipsDescendants = true
        NotificationFrame.ZIndex = 50
        CreateCorner(NotificationFrame, 8)
        
        local AccentBar = Instance.new("Frame")
        AccentBar.Size = UDim2.new(0, 4, 1, 0)
        AccentBar.BackgroundColor3 = accentColor
        AccentBar.BorderSizePixel = 0
        AccentBar.ZIndex = 51
        AccentBar.Parent = NotificationFrame
        
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, -14, 0, 20)
        TitleLabel.Position = UDim2.new(0, 10, 0, 6)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = title
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextSize = 15
        TitleLabel.TextColor3 = Colors.Text
        style(TitleLabel, "TextColor3", "Text")
        TitleLabel.TextTransparency = 1
        TitleLabel.ZIndex = 51
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = NotificationFrame
        
        local MessageLabel = Instance.new("TextLabel")
        MessageLabel.Size = UDim2.new(1, -14, 0, 36)
        MessageLabel.Position = UDim2.new(0, 10, 0, 26)
        MessageLabel.BackgroundTransparency = 1
        MessageLabel.Text = message
        MessageLabel.Font = Enum.Font.Gotham
        MessageLabel.TextSize = 13
        MessageLabel.TextColor3 = Colors.TextDark
        style(MessageLabel, "TextColor3", "TextDark")
        MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
        MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
        MessageLabel.TextWrapped = true
        MessageLabel.TextTransparency = 1
        MessageLabel.ZIndex = 51
        MessageLabel.Visible = message ~= ""
        MessageLabel.Parent = NotificationFrame
        
        local function fade(transparency)
            Tween(NotificationFrame, {BackgroundTransparency = transparency}, 0.2)
            Tween(TitleLabel, {TextTransparency = transparency}, 0.2)
            Tween(MessageLabel, {TextTransparency = transparency}, 0.2)
        end
        
        fade(1)
        Tween(NotificationFrame, {BackgroundTransparency = 0}, 0.2)
        Tween(TitleLabel, {TextTransparency = 0}, 0.2)
        Tween(MessageLabel, {TextTransparency = 0}, 0.2)
        
        task.delay(duration, function()
            fade(1)
            task.wait(0.22)
            NotificationFrame:Destroy()
        end)
    end
    
    -- Animation beim Start
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.BackgroundTransparency = 1
    Tween(MainFrame, {Size = windowSize, BackgroundTransparency = 0}, 0.4)
    
    return Window
end

return IceHub

--[[
================================================================================
BEISPIEL VERWENDUNG - Alle Funktionen
================================================================================

local IceHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/DEERSTUDIO101/frosthub-v6/refs/heads/main/frostv6.lua"))()

-- ============================================================================
-- 1. FENSTER ERSTELLEN
-- ============================================================================
local Window = IceHub:CreateWindow({
    Name = "IceHub - Brookhaven v4.8",  -- Titel des Fensters
    Size = UDim2.new(0, 600, 0, 450)    -- Größe: Breite x Höhe
})

-- ============================================================================
-- 2. TABS ERSTELLEN
-- ============================================================================
local MainTab = Window:CreateTab("Main")
local PremiumTab = Window:CreateTab("Premium")
local ToolsTab = Window:CreateTab("Tools")
local SettingsTab = Window:CreateTab("Settings")

-- ============================================================================
-- 3. BUTTON (Standard Button)
-- ============================================================================
MainTab:CreateButton({
    Name = "Test Button",
    Callback = function()
        print("Button geklickt!")
    end
})

-- ============================================================================
-- 4. PREMIUM BUTTON (Button mit Icon und drei Punkten)
-- ============================================================================
PremiumTab:CreatePremiumButton({
    Name = "Unlock Face Pass",
    Callback = function()
        print("Unlock Face Pass clicked!")
    end
})

PremiumTab:CreatePremiumButton({
    Name = "Unlock Premium Avatar Editor",
    Callback = function()
        print("Unlock Premium Avatar Editor clicked!")
    end
})

-- ============================================================================
-- 5. TOGGLE (Ein/Aus Schalter)
-- ============================================================================
ToolsTab:CreateToggle({
    Name = "ESP",
    Default = false,  -- Standardwert: true oder false
    Callback = function(value)
        print("ESP:", value)
        -- value ist true wenn aktiviert, false wenn deaktiviert
    end
})

ToolsTab:CreateToggle({
    Name = "Auto Farm",
    Default = true,
    Callback = function(value)
        print("Auto Farm:", value)
    end
})

-- ============================================================================
-- 6. SLIDER (Schieberegler)
-- ============================================================================
SettingsTab:CreateSlider({
    Name = "Speed",
    Min = 16,        -- Minimaler Wert
    Max = 200,       -- Maximaler Wert
    Default = 16,    -- Standardwert
    Callback = function(value)
        print("Speed Wert:", value)
        -- value ist eine Zahl zwischen Min und Max
    end
})

SettingsTab:CreateSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 500,
    Default = 50,
    Callback = function(value)
        print("Jump Power:", value)
    end
})

-- ============================================================================
-- 7. DROPDOWN (Auswahlmenü)
-- ============================================================================
SettingsTab:CreateDropdown({
    Name = "Theme",
    Options = {"Dark", "Light", "Blue", "Red"},  -- Verfügbare Optionen
    Default = "Dark",  -- Standardauswahl
    Callback = function(selected)
        print("Theme ausgewählt:", selected)
        -- selected ist der ausgewählte String
    end
})

SettingsTab:CreateDropdown({
    Name = "Language",
    Options = {"English", "Deutsch", "Français", "Español"},
    Default = "English",
    Callback = function(selected)
        print("Sprache:", selected)
    end
})

-- ============================================================================
-- 8. LABEL (Textanzeige)
-- ============================================================================
local StatusLabel = MainTab:CreateLabel("Status: Bereit")
-- Label kann später aktualisiert werden:
-- StatusLabel:SetText("Status: Aktiv")

MainTab:CreateLabel("Willkommen im Ice Hub!")
MainTab:CreateLabel("Version 4.8")

-- ============================================================================
-- 9. TEXTBOX & KEYBIND
-- ============================================================================
SettingsTab:CreateTextBox({
    Name = "Nickname",
    Placeholder = "backfisch1424",
    Callback = function(text)
        print("Nickname:", text)
    end
})

-- Keybind Element (optional - nur zum Anzeigen, nicht zum Togglen)
SettingsTab:CreateKeybind({
    Name = "Toggle UI Key",
    Default = Enum.KeyCode.RightControl,
    Callback = function(key)
        -- Hier kannst du den Toggle Key ändern, wenn der User einen neuen Key wählt
        Window:SetToggleKey(key)
        print("Toggle UI Key gesetzt auf:", key.Name)
    end
})

-- ============================================================================
-- ============================================================================
-- 10. COLOR PICKER & THEME FLAGS
-- ============================================================================
-- Alle UI-Elemente unterstützen jetzt Flags! Ändere die Farben mit dem Color Picker
-- und alle Elemente werden automatisch aktualisiert.

SettingsTab:CreateColorPicker({
    Name = "Theme Accent",
    Flag = "accent",
    Default = Window:GetFlag("accent"),
    Callback = function(color)
        print("Accent Farbe:", color)
    end
})

SettingsTab:CreateColorPicker({
    Name = "Background Color",
    Flag = "bc",  -- Ändert alle Background-Elemente
    Default = Window:GetFlag("bc"),
    Callback = function(color)
        print("Background Farbe:", color)
    end
})

SettingsTab:CreateColorPicker({
    Name = "Secondary Color",
    Flag = "secondary",  -- Ändert Header, Secondary-Elemente
    Default = Window:GetFlag("secondary"),
    Callback = function(color)
        print("Secondary Farbe:", color)
    end
})

SettingsTab:CreateColorPicker({
    Name = "Button Background",
    Flag = "buttonbg",  -- Ändert alle Button-Hintergründe
    Default = Window:GetFlag("buttonbg"),
    Callback = function(color)
        print("Button Background Farbe:", color)
    end
})

SettingsTab:CreateColorPicker({
    Name = "Text Color",
    Flag = "text",  -- Ändert alle Text-Farben
    Default = Window:GetFlag("text"),
    Callback = function(color)
        print("Text Farbe:", color)
    end
})

-- ============================================================================
-- 11. TOGGLE UI KEYBIND
-- ============================================================================
-- Setze einen Keybind zum Ein-/Ausblenden der UI
-- WICHTIG: Setze den Toggle Key NACH dem Erstellen aller Tabs!
Window:SetToggleKey(Enum.KeyCode.RightControl)  -- Drücke RightControl um UI zu togglen
-- Oder verwende einen anderen Key:
-- Window:SetToggleKey(Enum.KeyCode.Insert)  -- Insert Key
-- Window:SetToggleKey(Enum.KeyCode.Home)    -- Home Key

-- ============================================================================
-- 12. NOTIFY SYSTEM
-- ============================================================================
Window:Notify({
    Title = "IceHub",
    Message = "Willkommen zurück!",
    Duration = 4
})

-- ============================================================================
-- HINWEISE:
-- ============================================================================
-- - Minimize Button: Minimiert das Fenster mit Animation
-- - Close Button: Schließt das Fenster mit schöner Animation
-- - Alle UI-Elemente unterstützen Flags (bc, secondary, accent, text, etc.)
-- - Dropdown wurde komplett neu geschrieben und funktioniert jetzt perfekt
-- - Keine schwarzen Ränder mehr - alles ist clean!

--]]
--]]
