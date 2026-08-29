-- ============================================================
--  Blox_Fruit_Script.lua  (Single-File Executor · Luau)
--  Author  : Hilichurl  |  Version : 7.0.0 (Standardized Architecture)
-- ============================================================
-- Link loading script:
--loadstring(game:HttpGet(""))()

-- ╔══════════════════════════════════════════════════════════╗
-- ║                     [GLOBAL CLEANUP]                     ║
-- ╚══════════════════════════════════════════════════════════╝
if _G.UnloadScript then
    pcall(function() _G.UnloadScript() end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                 [SECTION 1] SERVICES & THEME             ║
-- ╚══════════════════════════════════════════════════════════╝

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local HttpService        = game:GetService("HttpService")
local VirtualUser        = game:GetService("VirtualUser")
local Lighting           = game:GetService("Lighting")
local CoreGui            = game:GetService("CoreGui")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local LocalPlayer        = Players.LocalPlayer
local fSetClipboard      = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set) or function() end

local THEME = {
    BG            = Color3.fromRGB(12,  12,  14),
    BG_OVERLAY    = Color3.fromRGB(18,  18,  22),
    BORDER        = Color3.fromRGB(40,  40,  48),
    ACCENT        = Color3.fromRGB(163, 230, 53),
    ACCENT_DIM    = Color3.fromRGB(101, 163, 13),
    TEXT          = Color3.fromRGB(240, 240, 240),
    TEXT_SUB      = Color3.fromRGB(140, 140, 155),
    BTN_IDLE      = Color3.fromRGB(22,  22,  26),
    BTN_HOVER     = Color3.fromRGB(163, 230, 53),
    BTN_TEXT_HOV  = Color3.fromRGB(10,  10,  10),
    TOGGLE_ON     = Color3.fromRGB(163, 230, 53),
    TOGGLE_OFF    = Color3.fromRGB(50,  50,  58),
    SLIDER_FILL   = Color3.fromRGB(163, 230, 53),
    SLIDER_TRACK  = Color3.fromRGB(40,  40,  50),
    TAB_IDLE      = Color3.fromRGB(20,  20,  24),
    TAB_ACTIVE    = Color3.fromRGB(163, 230, 53),
    TAB_TEXT_ACT  = Color3.fromRGB(10,  10,  10),
    NOTIFY_BG     = Color3.fromRGB(20,  24,  20),
    ICON_BTN_BG   = Color3.fromRGB(10,  10,  14),
    ICON_BTN_HOV  = Color3.fromRGB(163, 230, 53),
}

local TI_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ╔══════════════════════════════════════════════════════════╗
-- ║             [SECTION 2] UI ENGINE (RESPONSIVE)           ║
-- ╚══════════════════════════════════════════════════════════╝

--[[ Protect GUI from game security checks ]]
local function ProtectGui(gui)
    local ok = pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui); gui.Parent = CoreGui
        elseif gethui then
            gui.Parent = gethui()
        else
            gui.Parent = CoreGui
        end
    end)
    if not ok then gui.Parent = CoreGui end
end

--[[ Fetch online image asset and cache locally ]]
local function GetOnlineImage(url, fileName)
    if not url or url == "" then return "" end
    local path = fileName or "Hilichurl_icon.png"
    if isfile("hilichurl_icon.webp") then pcall(function() delfile("hilichurl_icon.webp") end) end
    if isfile("hilichurl_icon.png")  then pcall(function() delfile("hilichurl_icon.png")  end) end

    if not isfile(path) then
        pcall(function()
            local content = game:HttpGet(url)
            if content and #content > 0 then writefile(path, content) end
        end)
    end

    if isfile(path) then
        if getcustomasset then return getcustomasset(path)
        elseif getsynasset then return getsynasset(path) end
    end
    return url
end

--[[ Create standard rounded Frame component ]]
local function CreateFrame(p)
    local f = Instance.new("Frame")
    f.BackgroundColor3   = p.Color or THEME.BG
    f.BackgroundTransparency = p.Alpha or 0
    f.BorderSizePixel    = 0
    f.Size               = p.Size or UDim2.fromOffset(100, 30)
    f.Position           = p.Pos  or UDim2.fromOffset(0, 0)
    f.Name               = p.Name or "Frame"
    if p.Parent then f.Parent = p.Parent end
    if p.Radius ~= false then
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, p.Radius or 7)
        c.Parent = f
    end
    return f
end

--[[ Create standard TextLabel component ]]
local function CreateLabel(p)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextColor3  = p.Color  or THEME.TEXT
    l.Text        = p.Text   or ""
    l.Font        = p.Font   or Enum.Font.GothamSemibold
    l.TextSize    = p.Size   or 13
    l.TextXAlignment = p.XA or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Size        = p.FS    or UDim2.new(1, 0, 1, 0)
    l.Position    = p.Pos   or UDim2.fromOffset(0, 0)
    l.Name        = p.Name  or "Lbl"
    l.RichText    = true
    if p.Parent then l.Parent = p.Parent end
    return l
end

--[[ Enable dragging for UI on all input devices ]]
local function EnableDragging(handle, root)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = root.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            root.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end

local _notificationHolder = nil
--[[ Initialize notification container in screen corner ]]
local function EnsureNotificationHolder()
    if _notificationHolder and _notificationHolder.Parent then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "LevNotify"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    ProtectGui(sg)
    local h = Instance.new("Frame")
    h.Name = "H"; h.BackgroundTransparency = 1
    h.Size = UDim2.new(0, 240, 1, 0)
    h.Position = UDim2.new(1, -250, 0, 0)
    h.Parent = sg
    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0, 6); ll.VerticalAlignment = Enum.VerticalAlignment.Bottom; ll.Parent = h
    local pd = Instance.new("UIPadding")
    pd.PaddingBottom = UDim.new(0, 14); pd.Parent = h
    _notificationHolder = h
end

local UILib = {}
--[[ Display smooth floating notification card ]]
function UILib.Notify(title, msg, dur)
    dur = dur or 3; EnsureNotificationHolder()
    local card = CreateFrame({Color = THEME.NOTIFY_BG, Size = UDim2.new(1, 0, 0, 56), Name = "NC", Parent = _notificationHolder, Radius = 6, Alpha = 0.08})
    card.ClipsDescendants = true
    local ac = Instance.new("Frame"); ac.BackgroundColor3 = THEME.ACCENT; ac.BorderSizePixel = 0
    ac.Size = UDim2.new(0, 3, 1, 0); ac.Parent = card; Instance.new("UICorner").Parent = ac
    local inn = Instance.new("Frame"); inn.BackgroundTransparency = 1
    inn.Size = UDim2.new(1, -10, 1, 0); inn.Position = UDim2.fromOffset(8, 0); inn.Parent = card
    CreateLabel({Text = title,   Size = 12, Color = THEME.ACCENT,   Pos = UDim2.fromOffset(0, 4),  FS = UDim2.new(1, 0, 0, 16), Parent = inn})
    CreateLabel({Text = msg,     Size = 10, Color = THEME.TEXT,      Pos = UDim2.fromOffset(0, 20), FS = UDim2.new(1, 0, 0, 16), Font = Enum.Font.Gotham, Parent = inn})
    CreateLabel({Text = os.date("%H:%M"), Size = 8, Color = THEME.TEXT_SUB, Pos = UDim2.fromOffset(0, 38), FS = UDim2.new(1, 0, 0, 14), Font = Enum.Font.Gotham, Parent = inn})
    card.Position = UDim2.new(1, 8, 0, 0)
    TweenService:Create(card, TI_MED, {Position = UDim2.new(0, 0, 0, 0)}):Play()
    task.delay(dur, function()
        TweenService:Create(card, TI_MED, {Position = UDim2.new(1, 8, 0, 0)}):Play()
        task.delay(0.28, function() card:Destroy() end)
    end)
end

local _iconGui = nil
local _winRef  = nil
local _iconVisible = true

--[[ Build floating draggable circle button to toggle UI ]]
local function BuildIconToggle(iconUrl)
    if _iconGui then pcall(function() _iconGui:Destroy() end) end
    local sg = Instance.new("ScreenGui")
    sg.Name = "LevIcon"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    ProtectGui(sg)
    _iconGui = sg

    local btn = Instance.new("ImageButton")
    btn.Name = "IconBtn"; btn.Image = GetOnlineImage(iconUrl, "Hilichurl_icon.png")
    btn.Size = UDim2.fromOffset(50, 50); btn.Position = UDim2.new(0, 16, 0.5, -25); btn.BackgroundColor3 = THEME.ICON_BTN_BG
    btn.BackgroundTransparency = 0.3; btn.AutoButtonColor = false; btn.Parent = sg

    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = btn
    local st = Instance.new("UIStroke"); st.Color = THEME.BORDER; st.Thickness = 1.5; st.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(st, TI_FAST, {Color = THEME.ACCENT}):Play()
        TweenService:Create(btn, TI_FAST, {BackgroundColor3 = THEME.ICON_BTN_HOV, BackgroundTransparency = 0}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(st, TI_FAST, {Color = THEME.BORDER}):Play()
        TweenService:Create(btn, TI_FAST, {BackgroundColor3 = THEME.ICON_BTN_BG, BackgroundTransparency = 0.3}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if _winRef then
            _iconVisible = not _iconVisible
            _winRef.Visible = _iconVisible
            TweenService:Create(btn, TI_FAST, {BackgroundTransparency = 0}):Play()
            task.delay(0.12, function() TweenService:Create(btn, TI_FAST, {BackgroundTransparency = 0.3}):Play() end)
        end
    end)

    EnableDragging(btn, btn)
end

--[[ Initialize main responsive window for Mobile and PC ]]
function UILib.CreateWindow(cfg)
    cfg = cfg or {}
    local title = cfg.Title or "Hili Hub"
    local sub   = cfg.Subtitle or "made by Hilichurl"

    local sg = Instance.new("ScreenGui")
    sg.Name = "LevHub"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    ProtectGui(sg)

    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local winW = 450
    local winH = 290

    local win = CreateFrame({
        Color = THEME.BG, Alpha = 0, Size = UDim2.fromOffset(winW, winH),
        Pos = UDim2.new(0.5, -winW / 2, 0.5, -winH / 2), Name = "Window", Parent = sg, Radius = 8,
    })
    win.ClipsDescendants = true; _winRef = win

    local initialScale = 1.0
    if isMobile or vp.Y < 450 then
        initialScale = math.clamp(vp.Y / 380, 0.75, 0.95)
    end

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = initialScale
    uiScale.Parent = win

    local outStroke = Instance.new("UIStroke")
    outStroke.Color = THEME.BORDER; outStroke.Thickness = 1.2; outStroke.Parent = win

    local tb = CreateFrame({Color = THEME.BG_OVERLAY, Size = UDim2.new(1, 0, 0, 36), Name = "TitleBar", Parent = win, Radius = 8})
    local tbMask = Instance.new("Frame"); tbMask.Name = "TitleBarMask"; tbMask.BackgroundColor3 = THEME.BG_OVERLAY; tbMask.BorderSizePixel = 0
    tbMask.Size = UDim2.new(1, 0, 0, 8); tbMask.Position = UDim2.new(0, 0, 1, -8); tbMask.Parent = tb

    local strip = Instance.new("Frame"); strip.Name = "AccentStrip"; strip.BackgroundColor3 = THEME.ACCENT; strip.BorderSizePixel = 0
    strip.Size = UDim2.new(0, 3, 1, -4); strip.Position = UDim2.fromOffset(2, 2); strip.Parent = tb
    local stripCorner = Instance.new("UICorner"); stripCorner.CornerRadius = UDim.new(0, 4); stripCorner.Parent = strip

    local titleContainer = Instance.new("Frame")
    titleContainer.Size = UDim2.new(0.7, 0, 1, 0); titleContainer.Position = UDim2.fromOffset(12, 0)
    titleContainer.BackgroundTransparency = 1; titleContainer.Parent = tb

    local titleListLayout = Instance.new("UIListLayout")
    titleListLayout.FillDirection = Enum.FillDirection.Horizontal; titleListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    titleListLayout.Padding = UDim.new(0, 6); titleListLayout.SortOrder = Enum.SortOrder.LayoutOrder; titleListLayout.Parent = titleContainer

    local tLbl = Instance.new("TextLabel")
    tLbl.BackgroundTransparency = 1; tLbl.TextColor3 = THEME.TEXT; tLbl.Text = title; tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 13; tLbl.AutomaticSize = Enum.AutomaticSize.X; tLbl.Size = UDim2.new(0, 0, 1, 0); tLbl.LayoutOrder = 1; tLbl.Parent = titleContainer

    local subLbl = Instance.new("TextLabel")
    subLbl.BackgroundTransparency = 1; subLbl.TextColor3 = THEME.TEXT_SUB; subLbl.Text = sub; subLbl.Font = Enum.Font.Gotham
    subLbl.TextSize = 10; subLbl.AutomaticSize = Enum.AutomaticSize.X; subLbl.Size = UDim2.new(0, 0, 1, 0); subLbl.LayoutOrder = 2; subLbl.Parent = titleContainer

    local function CreateWinButton(icon, xOff, bgColor)
        local b = Instance.new("TextButton")
        b.Text = icon; b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.TextColor3 = THEME.TEXT_SUB; b.BackgroundColor3 = bgColor
        b.BackgroundTransparency = 1; b.AutoButtonColor = false; b.Size = UDim2.fromOffset(24, 24); b.Position = UDim2.new(1, xOff, 0.5, -12); b.Parent = tb
        Instance.new("UICorner").Parent = b
        b.MouseEnter:Connect(function() TweenService:Create(b, TI_FAST, {BackgroundTransparency = 0, TextColor3 = Color3.new(1, 1, 1)}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b, TI_FAST, {BackgroundTransparency = 1, TextColor3 = THEME.TEXT_SUB}):Play() end)
        return b
    end

    local closeBtn = CreateWinButton("X", -30, Color3.fromRGB(180, 40, 40))
    closeBtn.MouseButton1Click:Connect(function() if _G.UnloadScript then _G.UnloadScript() end end)

    local minBtn = CreateWinButton("─", -58, Color3.fromRGB(60, 60, 60))
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(win, TI_MED, {Size = minimized and UDim2.fromOffset(winW, 36) or UDim2.fromOffset(winW, winH)}):Play()
    end)

    local body = CreateFrame({Color = THEME.BG, Size = UDim2.new(1, 0, 1, -36), Pos = UDim2.new(0, 0, 0, 36), Name = "Body", Parent = win, Radius = 8})
    local bodyMask = Instance.new("Frame"); bodyMask.Name = "BodyMask"; bodyMask.BackgroundColor3 = THEME.BG; bodyMask.BorderSizePixel = 0
    bodyMask.Size = UDim2.new(1, 0, 0, 8); bodyMask.Position = UDim2.new(0, 0, 0, 0); bodyMask.Parent = body

    local sidebar = CreateFrame({Color = THEME.BG_OVERLAY, Size = UDim2.new(0.26, 0, 1, 0), Name = "Sidebar", Parent = body, Radius = 8})
    
    local sidebarScroll = Instance.new("ScrollingFrame")
    sidebarScroll.Name = "SidebarScroll"; sidebarScroll.BackgroundTransparency = 1; sidebarScroll.BorderSizePixel = 0
    sidebarScroll.Size = UDim2.new(1, 0, 1, -34); sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0); sidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sidebarScroll.ScrollBarThickness = 0; sidebarScroll.Parent = sidebar

    local sbll = Instance.new("UIListLayout"); sbll.SortOrder = Enum.SortOrder.LayoutOrder; sbll.Padding = UDim.new(0, 4); sbll.Parent = sidebarScroll
    local sbp = Instance.new("UIPadding"); sbp.PaddingTop = UDim.new(0, 6); sbp.PaddingLeft = UDim.new(0, 5); sbp.PaddingRight = UDim.new(0, 5); sbp.Parent = sidebarScroll

    local scaleBtn = Instance.new("TextButton")
    scaleBtn.Name = "ScaleToggleBtn"; scaleBtn.Text = string.format("Change UI: %.0f%%", uiScale.Scale * 100)
    scaleBtn.Font = Enum.Font.GothamBold; scaleBtn.TextSize = 10; scaleBtn.TextColor3 = THEME.ACCENT
    scaleBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 24); scaleBtn.AutoButtonColor = false
    scaleBtn.Size = UDim2.new(1, -10, 0, 24); scaleBtn.Position = UDim2.new(0, 5, 1, -28); scaleBtn.Parent = sidebar

    local scaleCorner = Instance.new("UICorner"); scaleCorner.CornerRadius = UDim.new(0, 4); scaleCorner.Parent = scaleBtn
    local scaleStroke = Instance.new("UIStroke"); scaleStroke.Color = THEME.BORDER; scaleStroke.Thickness = 1; scaleStroke.Parent = scaleBtn

    local scaleLevels = { 0.75, 0.85, 1.0, 1.15, 1.3 }
    local currentScaleIdx = 3

    scaleBtn.MouseEnter:Connect(function()
        TweenService:Create(scaleStroke, TI_FAST, {Color = THEME.ACCENT}):Play()
        TweenService:Create(scaleBtn, TI_FAST, {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}):Play()
    end)
    scaleBtn.MouseLeave:Connect(function()
        TweenService:Create(scaleStroke, TI_FAST, {Color = THEME.BORDER}):Play()
        TweenService:Create(scaleBtn, TI_FAST, {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}):Play()
    end)
    scaleBtn.MouseButton1Click:Connect(function()
        currentScaleIdx = currentScaleIdx + 1
        if currentScaleIdx > #scaleLevels then currentScaleIdx = 1 end
        local newScale = scaleLevels[currentScaleIdx]
        uiScale.Scale = newScale
        scaleBtn.Text = string.format("Change UI: %.0f%%", newScale * 100)
        UILib.Notify("UI Scale", string.format("Changed UI scale to %.0f%%!", newScale * 100), 2)
    end)

    local cpane = CreateFrame({Color = THEME.BG, Size = UDim2.new(0.74, 0, 1, 0), Pos = UDim2.new(0.26, 0, 0, 0), Name = "Content", Parent = body, Radius = 8})
    cpane.ClipsDescendants = true

    EnableDragging(tb, win)

    local W = {}
    local tabs = {}; local activePage = nil; local activeTabBtn = nil

    function W:Destroy() 
        sg:Destroy() 
        if _iconGui then pcall(function() _iconGui:Destroy() end) end
        if _notificationHolder then pcall(function() _notificationHolder.Parent:Destroy() end) end
    end

    local ActiveGlobalDropdown = nil

    function W:AddTab(cfg2)
        cfg2 = cfg2 or {}
        local tname = cfg2.Name or "Tab"; local ticon = cfg2.Icon or ""

        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. tname; tabBtn.Text = (ticon ~= "" and ticon .. "  " or "") .. tname
        tabBtn.Font = Enum.Font.GothamSemibold; tabBtn.TextSize = 11; tabBtn.TextColor3 = THEME.TEXT_SUB
        tabBtn.BackgroundColor3 = THEME.TAB_IDLE; tabBtn.AutoButtonColor = false; tabBtn.Size = UDim2.new(1, 0, 0, 28)
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left; tabBtn.Parent = sidebarScroll
        local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 5); tc.Parent = tabBtn
        local tp = Instance.new("UIPadding"); tp.PaddingLeft = UDim.new(0, 8); tp.Parent = tabBtn

        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. tname; page.BackgroundTransparency = 1; page.Size = UDim2.new(1, 0, 1, 0)
        page.CanvasSize = UDim2.new(0, 0, 0, 0); page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.ScrollBarThickness = 2; page.ScrollBarImageColor3 = THEME.ACCENT
        page.Visible = false; page.BorderSizePixel = 0; page.ClipsDescendants = true; page.Parent = cpane
        local pl = Instance.new("UIListLayout"); pl.SortOrder = Enum.SortOrder.LayoutOrder; pl.Padding = UDim.new(0, 5); pl.Parent = page
        local pp = Instance.new("UIPadding"); pp.PaddingTop = UDim.new(0, 6); pp.PaddingLeft = UDim.new(0, 8); pp.PaddingRight = UDim.new(0, 8); pp.PaddingBottom = UDim.new(0, 6); pp.Parent = page

        local function ActivateTab()
            if ActiveGlobalDropdown then ActiveGlobalDropdown() end
            if activePage   then activePage.Visible   = false end
            if activeTabBtn then TweenService:Create(activeTabBtn, TI_FAST, {BackgroundColor3 = THEME.TAB_IDLE, TextColor3 = THEME.TEXT_SUB}):Play() end
            page.Visible = true; activePage = page; activeTabBtn = tabBtn
            TweenService:Create(tabBtn, TI_FAST, {BackgroundColor3 = THEME.ACCENT, TextColor3 = THEME.TAB_TEXT_ACT}):Play()
        end
        tabBtn.MouseButton1Click:Connect(ActivateTab)
        tabBtn.MouseEnter:Connect(function()
            if activeTabBtn ~= tabBtn then TweenService:Create(tabBtn, TI_FAST, {BackgroundColor3 = Color3.fromRGB(32, 32, 40)}):Play() end
        end)
        tabBtn.MouseLeave:Connect(function()
            if activeTabBtn ~= tabBtn then TweenService:Create(tabBtn, TI_FAST, {BackgroundColor3 = THEME.TAB_IDLE}):Play() end
        end)
        if #tabs == 0 then ActivateTab() end
        table.insert(tabs, {btn = tabBtn, page = page})

        local Tab = {}

        function Tab:AddSection(name)
            local s = CreateFrame({Color = Color3.fromRGB(0, 0, 0), Size = UDim2.new(1, 0, 0, 22), Name = "Sec_" .. name, Parent = page, Alpha = 1, Radius = 0})
            CreateLabel({Text = "• " .. name:upper(), Size = 9, Color = THEME.ACCENT, Font = Enum.Font.GothamBold, FS = UDim2.new(1, 0, 1, 0), Parent = s})
            local d = Instance.new("Frame"); d.BackgroundColor3 = THEME.BORDER; d.BorderSizePixel = 0; d.Size = UDim2.new(1, 0, 0, 1); d.Position = UDim2.new(0, 0, 1, 0); d.Parent = s
            return s
        end

        function Tab:AddButton(bc)
            bc = bc or {}
            local lbl = bc.Name or "Button"; local desc = bc.Desc or ""; local cb = bc.Callback or function() end
            local rH = desc ~= "" and 44 or 30
            local row = CreateFrame({Color = THEME.BTN_IDLE, Size = UDim2.new(1, 0, 0, rH), Name = "Btn_" .. lbl, Parent = page, Radius = 5})
            local ip = Instance.new("UIPadding"); ip.PaddingLeft = UDim.new(0, 8); ip.PaddingRight = UDim.new(0, 8); ip.Parent = row
            CreateLabel({Text = lbl, Size = 11, Color = THEME.TEXT, FS = UDim2.new(1, 0, 0, 16), Pos = UDim2.fromOffset(0, 4), Parent = row})
            if desc ~= "" then CreateLabel({Text = desc, Size = 9, Color = THEME.TEXT_SUB, Font = Enum.Font.Gotham, FS = UDim2.new(1, 0, 0, 14), Pos = UDim2.fromOffset(0, 22), Parent = row}) end
            local cl = Instance.new("TextButton"); cl.Text = ""; cl.BackgroundTransparency = 1; cl.Size = UDim2.new(1, 0, 1, 0); cl.AutoButtonColor = false; cl.Parent = row
            cl.MouseEnter:Connect(function()
                TweenService:Create(row, TI_FAST, {BackgroundColor3 = THEME.BTN_HOVER}):Play()
                for _, v in ipairs(row:GetChildren()) do if v:IsA("TextLabel") then TweenService:Create(v, TI_FAST, {TextColor3 = THEME.BTN_TEXT_HOV}):Play() end end
            end)
            cl.MouseLeave:Connect(function()
                TweenService:Create(row, TI_FAST, {BackgroundColor3 = THEME.BTN_IDLE}):Play()
                for _, v in ipairs(row:GetChildren()) do if v:IsA("TextLabel") then TweenService:Create(v, TI_FAST, {TextColor3 = v.TextSize >= 11 and THEME.TEXT or THEME.TEXT_SUB}):Play() end end
            end)
            cl.MouseButton1Click:Connect(function()
                pcall(cb)
                TweenService:Create(row, TI_FAST, {BackgroundColor3 = THEME.ACCENT_DIM}):Play()
                task.delay(0.1, function() TweenService:Create(row, TI_FAST, {BackgroundColor3 = THEME.BTN_IDLE}):Play()
                    for _, v in ipairs(row:GetChildren()) do if v:IsA("TextLabel") then TweenService:Create(v, TI_FAST, {TextColor3 = v.TextSize >= 11 and THEME.TEXT or THEME.TEXT_SUB}):Play() end end end)
            end)
            return row
        end

        function Tab:AddToggle(tc2)
            tc2 = tc2 or {}
            local lbl = tc2.Name or "Toggle"; local desc = tc2.Desc or ""; local def = tc2.Default or false; local cb = tc2.Callback or function() end
            local rH = desc ~= "" and 44 or 30; local st = def
            local row = CreateFrame({Color = THEME.BTN_IDLE, Size = UDim2.new(1, 0, 0, rH), Name = "Tog_" .. lbl, Parent = page, Radius = 5})
            local ip = Instance.new("UIPadding"); ip.PaddingLeft = UDim.new(0, 8); ip.PaddingRight = UDim.new(0, 8); ip.Parent = row
            CreateLabel({Text = lbl, Size = 11, Color = THEME.TEXT, FS = UDim2.new(1, -45, 0, 16), Pos = UDim2.fromOffset(0, 4), Parent = row})
            if desc ~= "" then CreateLabel({Text = desc, Size = 9, Color = THEME.TEXT_SUB, Font = Enum.Font.Gotham, FS = UDim2.new(1, -45, 0, 14), Pos = UDim2.fromOffset(0, 22), Parent = row}) end

            local pill = CreateFrame({Color = st and THEME.TOGGLE_ON or THEME.TOGGLE_OFF, Size = UDim2.fromOffset(34, 18), Pos = UDim2.new(1, -34, 0.5, -9), Name = "Pill", Parent = row, Radius = 9})
            local knob = CreateFrame({Color = Color3.new(1, 1, 1), Size = UDim2.fromOffset(14, 14), Pos = st and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2), Name = "Knob", Parent = pill, Radius = 7})

            local function UpdateToggle()
                TweenService:Create(pill, TI_FAST, {BackgroundColor3 = st and THEME.TOGGLE_ON or THEME.TOGGLE_OFF}):Play()
                TweenService:Create(knob, TI_FAST, {Position = st and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2)}):Play()
            end

            local cl = Instance.new("TextButton"); cl.Text = ""; cl.BackgroundTransparency = 1; cl.Size = UDim2.new(1, 0, 1, 0); cl.AutoButtonColor = false; cl.Parent = row
            cl.MouseButton1Click:Connect(function() st = not st; UpdateToggle(); pcall(cb, st) end)
            cl.MouseEnter:Connect(function() TweenService:Create(row, TI_FAST, {BackgroundColor3 = Color3.fromRGB(28, 28, 34)}):Play() end)
            cl.MouseLeave:Connect(function() TweenService:Create(row, TI_FAST, {BackgroundColor3 = THEME.BTN_IDLE}):Play() end)
            UpdateToggle()

            local TO = {}
            function TO:Set(v) st = v; UpdateToggle(); pcall(cb, st) end
            function TO:Get() return st end
            return TO
        end

        function Tab:AddSlider(sc)
            sc = sc or {}
            local lbl = sc.Name or "Slider"; local desc = sc.Desc or ""; local mn = sc.Min or 0; local mx = sc.Max or 100
            local def = sc.Default or mn; local sfx = sc.Suffix or ""; local cb = sc.Callback or function() end
            local decimals = sc.Decimals or ((mx - mn <= 10 and (mn % 1 ~= 0 or mx % 1 ~= 0 or def % 1 ~= 0)) and 2 or 0)
            local rH = desc ~= "" and 56 or 42; local value = math.clamp(def, mn, mx)
            local row = CreateFrame({Color = THEME.BTN_IDLE, Size = UDim2.new(1, 0, 0, rH), Name = "Sl_" .. lbl, Parent = page, Radius = 5})
            local ip = Instance.new("UIPadding"); ip.PaddingLeft = UDim.new(0, 8); ip.PaddingRight = UDim.new(0, 8); ip.Parent = row
            
            CreateLabel({Text = lbl, Size = 11, Color = THEME.TEXT, FS = UDim2.new(1, -60, 0, 16), Pos = UDim2.fromOffset(0, 4), Parent = row})
            if desc ~= "" then CreateLabel({Text = desc, Size = 9, Color = THEME.TEXT_SUB, Font = Enum.Font.Gotham, FS = UDim2.new(1, -60, 0, 14), Pos = UDim2.fromOffset(0, 20), Parent = row}) end
            
            local valBoxBG = CreateFrame({Color = Color3.fromRGB(10, 10, 14), Size = UDim2.fromOffset(52, 18), Pos = UDim2.new(1, -52, 0, 4), Name = "ValBoxBG", Parent = row, Radius = 3})
            local valBoxSt = Instance.new("UIStroke"); valBoxSt.Color = THEME.BORDER; valBoxSt.Thickness = 1; valBoxSt.Parent = valBoxBG
            
            local valBox = Instance.new("TextBox")
            valBox.Size = UDim2.new(1, 0, 1, 0); valBox.BackgroundTransparency = 1; valBox.Text = tostring(value) .. sfx
            valBox.TextColor3 = THEME.ACCENT; valBox.Font = Enum.Font.GothamBold; valBox.TextSize = 10
            valBox.TextXAlignment = Enum.TextXAlignment.Center; valBox.ClearTextOnFocus = false; valBox.Parent = valBoxBG

            local tY = desc ~= "" and 38 or 24
            local track = CreateFrame({Color = THEME.SLIDER_TRACK, Size = UDim2.new(1, 0, 0, 4), Pos = UDim2.fromOffset(0, tY), Name = "Tr", Parent = row, Radius = 2})
            local fp = (value - mn) / (mx - mn)
            local fill = CreateFrame({Color = THEME.SLIDER_FILL, Size = UDim2.new(fp, 0, 1, 0), Name = "Fl", Parent = track, Radius = 2})
            local thumb = CreateFrame({Color = Color3.new(1, 1, 1), Size = UDim2.fromOffset(10, 10), Pos = UDim2.new(fp, -5, 0.5, -5), Name = "Th", Parent = track, Radius = 5})
            local ts = Instance.new("UIStroke"); ts.Color = THEME.ACCENT; ts.Thickness = 1; ts.Parent = thumb
            local dSlider = false

            local function RoundVal(num)
                if decimals > 0 then
                    local mult = 10 ^ decimals
                    return math.floor(num * mult + 0.5) / mult
                else
                    return math.floor(num + 0.5)
                end
            end

            local function UpdateUI(val)
                value = math.clamp(RoundVal(val), mn, mx)
                local p = (value - mn) / (mx - mn)
                fill.Size = UDim2.new(p, 0, 1, 0); thumb.Position = UDim2.new(p, -5, 0.5, -5)
                valBox.Text = tostring(value) .. sfx
                pcall(cb, value)
            end

            local function UpdateSliderFromInput(ax)
                local rx = math.clamp(ax - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
                local p = rx / track.AbsoluteSize.X
                local v = RoundVal(mn + p * (mx - mn))
                UpdateUI(v)
            end

            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dSlider = true; UpdateSliderFromInput(i.Position.X) end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dSlider and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then UpdateSliderFromInput(i.Position.X) end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dSlider = false end
            end)

            valBox.Focused:Connect(function()
                valBox.Text = tostring(value)
                TweenService:Create(valBoxSt, TI_FAST, {Color = THEME.ACCENT}):Play()
            end)

            valBox.FocusLost:Connect(function()
                TweenService:Create(valBoxSt, TI_FAST, {Color = THEME.BORDER})
                local num = tonumber(valBox.Text)
                if num then UpdateUI(num) else valBox.Text = tostring(value) .. sfx end
            end)

            local SO = {}
            function SO:Set(v) UpdateUI(v) end
            function SO:Get() return value end
            return SO
        end

        function Tab:AddDropdown(dc)
            dc = dc or {}
            local lbl = dc.Name or "Dropdown"; local opts = dc.Options or {}; local cb = dc.Callback or function() end
            local desc = dc.Desc or ""; local rH = desc ~= "" and 44 or 30; local isMulti = dc.Multi or false

            local selectedList = {}
            local selectedText = "None"

            if isMulti then
                if type(dc.Default) == "table" then
                    for _, v in ipairs(dc.Default) do
                        table.insert(selectedList, v)
                    end
                elseif type(dc.Default) == "string" and dc.Default ~= "" and dc.Default ~= "None" then
                    table.insert(selectedList, dc.Default)
                end
                selectedText = #selectedList > 0 and table.concat(selectedList, ", ") or "None"
            else
                selectedText = type(dc.Default) == "string" and dc.Default or (opts[1] or "None")
            end

            local row = CreateFrame({Color = THEME.BTN_IDLE, Size = UDim2.new(1, 0, 0, rH), Name = "DD_" .. lbl, Parent = page, Radius = 5})
            local ip = Instance.new("UIPadding"); ip.PaddingLeft = UDim.new(0, 8); ip.PaddingRight = UDim.new(0, 8); ip.Parent = row
            CreateLabel({Text = lbl, Size = 11, Color = THEME.TEXT, FS = UDim2.new(1, -120, 0, 16), Pos = UDim2.fromOffset(0, 4), Parent = row})
            if desc ~= "" then CreateLabel({Text = desc, Size = 9, Color = THEME.TEXT_SUB, Font = Enum.Font.Gotham, FS = UDim2.new(1, -120, 0, 14), Pos = UDim2.fromOffset(0, 22), Parent = row}) end
            local selLbl = CreateLabel({Text = selectedText .. "", Size = 10, Color = THEME.ACCENT, XA = Enum.TextXAlignment.Right, FS = UDim2.new(0, 115, 0, 16), Pos = UDim2.new(1, -115, 0, 4), Name = "SelLbl", Parent = row})

            local activeDropdown = nil
            local activeBackdrop = nil

            local function CloseDropdown()
                if activeDropdown then
                    activeDropdown:Destroy()
                    activeDropdown = nil
                end
                if activeBackdrop then
                    activeBackdrop:Destroy()
                    activeBackdrop = nil
                end
                if ActiveGlobalDropdown == CloseDropdown then
                    ActiveGlobalDropdown = nil
                end
            end

            local function BuildDropdown()
                if activeDropdown then
                    CloseDropdown()
                    return
                end
                if ActiveGlobalDropdown then
                    ActiveGlobalDropdown()
                end

                local n = #opts
                if n == 0 then return end

                -- Lớp phủ tàng hình toàn màn hình: Bấm vào bất kỳ đâu ngoài dropdown sẽ tự động đóng lại
                local backdrop = Instance.new("TextButton")
                backdrop.Name = "DropdownBackdrop"
                backdrop.BackgroundTransparency = 1
                backdrop.Text = ""
                backdrop.Size = UDim2.new(1, 0, 1, 0)
                backdrop.Position = UDim2.new(0, 0, 0, 0)
                backdrop.ZIndex = 499
                backdrop.AutoButtonColor = false
                backdrop.Parent = sg
                activeBackdrop = backdrop

                backdrop.MouseButton1Click:Connect(CloseDropdown)

                local ddH = math.min(n, 5) * 26 + 4
                local dropdown = CreateFrame({
                    Color = THEME.BG_OVERLAY, Size = UDim2.fromOffset(row.AbsoluteSize.X, ddH),
                    Pos = UDim2.fromOffset(row.AbsolutePosition.X, row.AbsolutePosition.Y + row.AbsoluteSize.Y + 4),
                    Name = "GlobalDDList", Parent = sg, Radius = 5
                })
                dropdown.ZIndex = 500
                activeDropdown = dropdown
                ActiveGlobalDropdown = CloseDropdown

                local outSt = Instance.new("UIStroke"); outSt.Color = THEME.ACCENT; outSt.Thickness = 1; outSt.Parent = dropdown

                local scrollDD = Instance.new("ScrollingFrame")
                scrollDD.Size = UDim2.new(1, 0, 1, 0); scrollDD.BackgroundTransparency = 1; scrollDD.BorderSizePixel = 0
                scrollDD.ScrollBarThickness = 2; scrollDD.ScrollBarImageColor3 = THEME.ACCENT
                scrollDD.CanvasSize = UDim2.new(0, 0, 0, n * 26); scrollDD.ZIndex = 501; scrollDD.Parent = dropdown

                local dll = Instance.new("UIListLayout"); dll.SortOrder = Enum.SortOrder.LayoutOrder; dll.Padding = UDim.new(0, 2); dll.Parent = scrollDD

                local buttons = {}

                local function UpdateButtonsUI()
                    for optName, ob in pairs(buttons) do
                        if isMulti then
                            local isSelected = table.find(selectedList, optName) ~= nil
                            ob.Text = (isSelected and "[✓] " or "[   ] ") .. optName
                            ob.TextColor3 = isSelected and THEME.ACCENT or THEME.TEXT
                            ob.BackgroundColor3 = isSelected and Color3.fromRGB(30, 35, 45) or THEME.BTN_IDLE
                        else
                            local isSelected = (selectedText == optName)
                            ob.Text = optName
                            ob.TextColor3 = isSelected and THEME.ACCENT or THEME.TEXT
                            ob.BackgroundColor3 = isSelected and Color3.fromRGB(30, 35, 45) or THEME.BTN_IDLE
                        end
                    end
                end

                for _, opt in ipairs(opts) do
                    local ob = Instance.new("TextButton")
                    ob.Font = Enum.Font.GothamMedium; ob.TextSize = 10
                    ob.BackgroundTransparency = 0.2; ob.AutoButtonColor = false
                    ob.Size = UDim2.new(1, 0, 0, 24); ob.TextXAlignment = Enum.TextXAlignment.Left; ob.ZIndex = 502; ob.Parent = scrollDD

                    local op = Instance.new("UIPadding"); op.PaddingLeft = UDim.new(0, 8); op.Parent = ob
                    buttons[opt] = ob

                    ob.MouseEnter:Connect(function() TweenService:Create(ob, TI_FAST, {BackgroundTransparency = 0, TextColor3 = THEME.BTN_TEXT_HOV, BackgroundColor3 = THEME.BTN_HOVER}):Play() end)
                    ob.MouseLeave:Connect(function()
                        UpdateButtonsUI()
                    end)

                    ob.MouseButton1Click:Connect(function()
                        if isMulti then
                            local idx = table.find(selectedList, opt)
                            if idx then
                                table.remove(selectedList, idx)
                            else
                                table.insert(selectedList, opt)
                            end
                            selectedText = #selectedList > 0 and table.concat(selectedList, ", ") or "None"
                            selLbl.Text = selectedText
                            UpdateButtonsUI()
                            pcall(cb, selectedList)
                        else
                            selectedText = opt; selLbl.Text = opt .. ""
                            UpdateButtonsUI()
                            CloseDropdown()
                            pcall(cb, opt)
                        end
                    end)
                end

                UpdateButtonsUI()
            end

            local clDD = Instance.new("TextButton"); clDD.Text = ""; clDD.BackgroundTransparency = 1; clDD.Size = UDim2.new(1, 0, 1, 0); clDD.AutoButtonColor = false; clDD.Parent = row
            clDD.MouseButton1Click:Connect(BuildDropdown)

            local DDObj = {}
            function DDObj:Refresh(newOpts) 
                opts = newOpts 
                if isMulti then
                    selectedList = {}
                    if #opts > 0 then table.insert(selectedList, opts[1]) end
                    selectedText = #selectedList > 0 and table.concat(selectedList, ", ") or "None"
                else
                    selectedText = opts[1] or "None"
                end
                selLbl.Text = selectedText
                CloseDropdown()
            end
            function DDObj:Get() 
                return isMulti and selectedList or selectedText 
            end
            function DDObj:Set(val)
                if isMulti and type(val) == "table" then
                    selectedList = val
                    selectedText = #selectedList > 0 and table.concat(selectedList, ", ") or "None"
                else
                    selectedText = tostring(val)
                end
                selLbl.Text = selectedText
            end
            return DDObj
        end

        function Tab:AddMultiDropdown(dc)
            dc = dc or {}
            dc.Multi = true
            return Tab:AddDropdown(dc)
        end

        function Tab:AddInput(ic)
            ic = ic or {}
            local lbl = ic.Name or "Input"; local desc = ic.Desc or ""; local ph = ic.Placeholder or "Type here..."; local cb = ic.Callback or function() end
            local rH = desc ~= "" and 56 or 42
            local row = CreateFrame({Color = THEME.BTN_IDLE, Size = UDim2.new(1, 0, 0, rH), Name = "Inp_" .. lbl, Parent = page, Radius = 5})
            local ip = Instance.new("UIPadding"); ip.PaddingLeft = UDim.new(0, 8); ip.PaddingRight = UDim.new(0, 8); ip.Parent = row
            CreateLabel({Text = lbl, Size = 11, Color = THEME.TEXT, FS = UDim2.new(1, 0, 0, 16), Pos = UDim2.fromOffset(0, 4), Parent = row})
            if desc ~= "" then CreateLabel({Text = desc, Size = 9, Color = THEME.TEXT_SUB, Font = Enum.Font.Gotham, FS = UDim2.new(1, 0, 0, 14), Pos = UDim2.fromOffset(0, 20), Parent = row}) end
            local bxY = desc ~= "" and 36 or 22
            local bxBG = CreateFrame({Color = Color3.fromRGB(10, 10, 14), Size = UDim2.new(1, 0, 0, 18), Pos = UDim2.fromOffset(0, bxY), Name = "BxBG", Parent = row, Radius = 4})
            local bxSt = Instance.new("UIStroke"); bxSt.Color = THEME.BORDER; bxSt.Thickness = 1; bxSt.Parent = bxBG
            local tbx = Instance.new("TextBox"); tbx.Text = ""; tbx.PlaceholderText = ph; tbx.PlaceholderColor3 = THEME.TEXT_SUB
            tbx.TextColor3 = THEME.TEXT; tbx.Font = Enum.Font.Gotham; tbx.TextSize = 10
            tbx.BackgroundTransparency = 1; tbx.Size = UDim2.new(1, -6, 1, 0); tbx.Position = UDim2.fromOffset(4, 0)
            tbx.TextXAlignment = Enum.TextXAlignment.Left; tbx.ClearTextOnFocus = false; tbx.Parent = bxBG
            tbx.Focused:Connect(function() TweenService:Create(bxSt, TI_FAST, {Color = THEME.ACCENT}):Play() end)
            
            tbx.FocusLost:Connect(function() 
                TweenService:Create(bxSt, TI_FAST, {Color = THEME.BORDER})
                if tbx.Text ~= "" then pcall(cb, tbx.Text) end
            end)
            local IO = {}
            function IO:Get() return tbx.Text end
            function IO:Set(t) tbx.Text = t end
            return IO
        end

        function Tab:AddInfo(ic)
            ic = ic or {}
            local title = ic.Title or "Info"
            local value = ic.Value or "-"
            local row = CreateFrame({Color = THEME.BTN_IDLE, Size = UDim2.new(1, 0, 0, 30), Name = "Info_" .. title, Parent = page, Radius = 5})
            local ip = Instance.new("UIPadding"); ip.PaddingLeft = UDim.new(0, 8); ip.PaddingRight = UDim.new(0, 8); ip.Parent = row
            CreateLabel({Text = title, Size = 11, Color = THEME.TEXT, FS = UDim2.new(0.35, 0, 1, 0), Pos = UDim2.fromOffset(0, 0), Parent = row})
            local valLbl = CreateLabel({Text = tostring(value), Size = 10, Color = THEME.ACCENT, XA = Enum.TextXAlignment.Right, FS = UDim2.new(0.65, 0, 1, 0), Pos = UDim2.new(0.35, 0, 0, 0), Parent = row})
            local InfoObj = {}
            function InfoObj:Set(newVal)
                valLbl.Text = tostring(newVal)
            end
            function InfoObj:Get()
                return valLbl.Text
            end
            return InfoObj
        end

        return Tab
    end

    return W
end


-- ╔══════════════════════════════════════════════════════════╗
-- ║         [SECTION 3] UTILITY & CORE LOGIC FUNCTIONS       ║
-- ╚══════════════════════════════════════════════════════════╝

local Utility = {}
local _conns  = {}

local SessionStartTime = os.clock()
local CharacterParts = {}
local BoatParts = {}
local FlyActive = false

local S = {
    BoatFlySpeed                = 220,
    BoatFlyHeight               = 190,
    CustomBoatSpeed             = 250,
    EnableBoatSpeed             = false,
    AutoBuyBoatEnabled          = false,
    SelectedBoat                = "Beast Hunter",
    FindLeviathanEnabled        = false,
    MultipleFindLeviathanEnabled= false,
    SelectedBoatOwner           = "",
    AutoShootBoatOwner          = "",
    AutoShootLeviEnabled        = false,
    AutoAttackEnemyEnabled      = false,
    BoatNoClipEnabled           = false,
    PlayerNoClipEnabled         = true,
    WalkOnWaterEnabled          = true,
    AntiAFKEnabled              = true,
    TeleportPlayerEnabled       = false,
    SelectedPlayer              = nil,
    SelectedIsland              = nil,
    WebhookEnabled              = true,
    WebhookURL                  = "",
    CustomWalkSpeed             = 100,
    CustomJumpPower             = 50,
    TeleportFlySpeed            = 180,
    RequiredCannonPassengers    = 4,
    ResetWhenBoatDestroyed      = false,
    ResetWhenSelectedOwnerDie   = false,
    AutoTalkFrozenWatcherEnabled= false,
    AutoShootBoatMode           = "Shoot with your boat",
    AutoDriveTikiEnabled        = false,
    AutoDriveHydraEnabled       = false,
    AutoFlyTikiEnabled          = false,
    AutoFlyHydraEnabled         = false,
    SelectedWeaponType          = "Melee",
    AttackHeight                = 30,
    AutoFarmUseSkills           = false,
    AutoAttackLeviEnabled       = false,
    AutoSkillsLeviEnabled       = false,
    AutoFarmWithSkillsEnabled   = false,
    -- Sea Events Tab Configuration
    SeaEventsBoat               = "Guardian",
    SeaEventsWeapon             = "",
    SeaEventsWeapons            = {},
    SelectedSeaEvent            = "All",
    SelectedSeaEvents           = { "All" },
    AutoFarmSeaEventsEnabled    = false,
    AutoFarmSeaEventsSkills     = false,
    -- Farm Setting & Skills Configuration
    AutoRaceV3                  = false,
    AutoAwakeningV4             = false,
    HoldMeleeSkills             = false,
    HoldFruitSkills             = false,
    HoldSwordSkills             = false,
    HoldGunSkills               = false,
    SkillHoldDuration           = 0.35,
    MeleeSkillZ                 = true,
    MeleeSkillX                 = true,
    MeleeSkillC                 = true,
    FruitSkillZ                 = true,
    FruitSkillX                 = true,
    FruitSkillC                 = true,
    FruitSkillV                 = true,
    FruitSkillF                 = true,
    SwordSkillZ                 = true,
    SwordSkillX                 = true,
    GunSkillZ                   = true,
    GunSkillX                   = true,
    LeviathanSelectedWeapon     = "Melee",
}

local CONFIG_FILE = "hilichurl_config.json"

--[[ Save current settings directly to local executor storage ]]
function Utility.SaveLocalConfig()
    local ok, res = pcall(function()
        local saveTable = {}
        for k, v in pairs(S) do
            if typeof(v) == "boolean" or typeof(v) == "number" or typeof(v) == "string" or typeof(v) == "table" then
                saveTable[k] = v
            end
        end
        local json = HttpService:JSONEncode(saveTable)
        if writefile then
            writefile(CONFIG_FILE, json)
            return true
        end
        return false
    end)
    if ok and res then
        UILib.Notify("Config", "Settings saved successfully to local storage!", 3)
    else
        UILib.Notify("Config", "Saved to session (executor has no writefile)!", 3)
    end
    return ok and res
end

--[[ Load settings from getgenv().HilichurlConfig, _G.HilichurlConfig, or local file ]]
function Utility.LoadLocalConfig()
    pcall(function()
        local passedConfig = (getgenv and getgenv().HilichurlConfig) or _G.HilichurlConfig
        if passedConfig and typeof(passedConfig) == "table" then
            for k, v in pairs(passedConfig) do
                if S[k] ~= nil then S[k] = v end
            end
        elseif isfile and readfile and isfile(CONFIG_FILE) then
            local data = readfile(CONFIG_FILE)
            if data and #data > 0 then
                local decoded = HttpService:JSONDecode(data)
                if typeof(decoded) == "table" then
                    for k, v in pairs(decoded) do
                        if S[k] ~= nil then S[k] = v end
                    end
                end
            end
        end
    end)
end

--[[ Generate standalone executable script code with current config ]]
function Utility.GenerateConfigCode()
    local lines = {}
    table.insert(lines, "-- [[ Hilichurl Hub Config ]]")
    table.insert(lines, "getgenv().HilichurlConfig = {")
    for k, v in pairs(S) do
        if typeof(v) == "boolean" then
            table.insert(lines, string.format("    [%q] = %s,", k, tostring(v)))
        elseif typeof(v) == "number" then
            table.insert(lines, string.format("    [%q] = %s,", k, tostring(v)))
        elseif typeof(v) == "string" then
            table.insert(lines, string.format("    [%q] = %q,", k, v))
        elseif typeof(v) == "table" then
            local items = {}
            for _, item in ipairs(v) do
                table.insert(items, string.format("%q", tostring(item)))
            end
            table.insert(lines, string.format("    [%q] = { %s },", k, table.concat(items, ", ")))
        end
    end
    table.insert(lines, "}")
    table.insert(lines, "")
    table.insert(lines, "-- Execute Hilichurl Hub (Protected Loader)")
    table.insert(lines, 'loadstring(game:HttpGet("https://raw.githubusercontent.com/TheHilichurl/Roblox_Script/refs/heads/main/loader.lua"))()')
    return table.concat(lines, "\n")
end

-- Auto load saved config upon initialization
Utility.LoadLocalConfig()

local WAYPOINTS_TIKI = {
    Vector3.new(7048, 28, -5518),
    Vector3.new(-5619, 28, 179),
    Vector3.new(-13500, 28, 220),
    Vector3.new(-16096, 28, 422),
}

local WAYPOINTS_HYDRA = {
    Vector3.new(7048, 28, -5518),
    Vector3.new(10488, 28, 799),
    Vector3.new(5238, 28, 4308),
    Vector3.new(5068, 28, 2201),
}

local WebhookSent                 = false
local FindLeviathanConnection      = nil
local FindLeviathanToggle          = nil
local MultipleFindLeviathanToggle  = nil
local AutoDriveTikiToggle         = nil
local AutoDriveHydraToggle        = nil
local AutoFlyTikiToggle           = nil
local AutoFlyHydraToggle          = nil
local BoatSpeedConnection         = nil
local ActiveBoat                  = nil

--[[ Safely disconnect a connection key ]]
local function DisconnectConnection(key)
    if _conns[key] then
        pcall(function()
            if typeof(_conns[key]) == "RBXScriptConnection" then
                _conns[key]:Disconnect()
            elseif typeof(_conns[key]) == "thread" then
                task.cancel(_conns[key])
            elseif type(_conns[key]) == "table" and _conns[key].Disconnect then
                _conns[key]:Disconnect()
            end
        end)
        _conns[key] = nil
    end
end

--[[ Cache character parts for noclip processing ]]
function Utility.UpdateCharacterCache()
    table.clear(CharacterParts)
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsA("Seat") and not part:IsA("VehicleSeat") then
                table.insert(CharacterParts, part)
            end
        end
    end
end

--[[ Cache boat parts for noclip processing ]]
function Utility.UpdateBoatCache(boat)
    table.clear(BoatParts)
    if boat then
        for _, part in ipairs(boat:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsA("Seat") and not part:IsA("VehicleSeat") then
                table.insert(BoatParts, part)
            end
        end
    end
end

--[[ Cập nhật trạng thái Player NoClip (Tự động kích hoạt khi bật tay hoặc khi Auto Farm Sea Events hoạt động) ]]
function Utility.UpdatePlayerNoClipState()
    local shouldNoClip = S.PlayerNoClipEnabled or S.AutoFarmSeaEventsEnabled
    DisconnectConnection("playerNoClipStepped")
    if shouldNoClip then
        Utility.UpdateCharacterCache()
        _conns["playerNoClipStepped"] = RunService.Stepped:Connect(function()
            local active = S.PlayerNoClipEnabled or S.AutoFarmSeaEventsEnabled
            if not active then
                DisconnectConnection("playerNoClipStepped")
                for _, part in ipairs(CharacterParts) do
                    if part and part.Parent then part.CanCollide = true end
                end
                return
            end
            for _, part in ipairs(CharacterParts) do
                if part and part.Parent then part.CanCollide = false end
            end
        end)
    else
        for _, part in ipairs(CharacterParts) do
            if part and part.Parent then part.CanCollide = true end
        end
    end
end

--[[ Bật / tắt Player NoClip tối ưu - Chỉ lắng nghe Stepped khi kích hoạt ]]
function Utility.SetPlayerNoClip(enabled)
    S.PlayerNoClipEnabled = enabled
    Utility.UpdatePlayerNoClipState()
end

--[[ Bật / tắt Boat NoClip tối ưu - Chỉ lắng nghe Stepped khi kích hoạt ]]
function Utility.SetBoatNoClip(enabled)
    S.BoatNoClipEnabled = enabled
    DisconnectConnection("boatNoClipStepped")
    if enabled then
        if ActiveBoat then Utility.UpdateBoatCache(ActiveBoat) end
        _conns["boatNoClipStepped"] = RunService.Stepped:Connect(function()
            if not S.BoatNoClipEnabled then
                DisconnectConnection("boatNoClipStepped")
                return
            end
            if ActiveBoat and ActiveBoat.Parent then
                for _, part in ipairs(BoatParts) do
                    if part and part.Parent then part.CanCollide = false end
                end
            end
        end)
    end
end

--[[ Kiểm tra xem nhân vật đã bật Buso Haki (Aura) hay chưa ]]
function Utility.IsBusoActive()
    local char = LocalPlayer.Character
    if not char then return false end
    return char:FindFirstChild("HasBuso") ~= nil
end

--[[ Tự động kích hoạt Buso Haki (Aura) chạy ngầm ]]
function Utility.EnableBuso()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum or hum.Health <= 0 then return end

    if not Utility.IsBusoActive() then
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            local remotes = rep:FindFirstChild("Remotes")
            local commF = remotes and remotes:FindFirstChild("CommF_")
            if commF and commF:IsA("RemoteFunction") then
                commF:InvokeServer("Buso")
            end
            local commE = remotes and remotes:FindFirstChild("CommE")
            if commE and commE:IsA("RemoteEvent") then
                commE:FireServer("Buso")
            end
        end)
    end
end

--[[ Vòng lặp nền tự động duy trì Buso Haki ]]
function Utility.StartAutoBusoLoop()
    DisconnectConnection("autoBusoLoop")
    _conns["autoBusoLoop"] = task.spawn(function()
        while true do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum and hum.Health > 0 then
                if not Utility.IsBusoActive() then
                    Utility.EnableBuso()
                    task.wait(0.5)
                end
            end
            task.wait(1)
        end
    end)
end

--[[ Get boat that local player is currently driving ]]
function Utility.GetBoat()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        return hum.SeatPart.Parent
    end
    return nil
end

--[[ Force stop boat physics and clear all velocity ]]
function Utility.ForceStopBoat(boat)
    if not boat then return end
    
    for _, part in ipairs(boat:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity  = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
        if part.Name == "FlyLinearVelocity" or part.Name == "FlyAlignOrientation" or part.Name == "FlyAttachment" then
            part:Destroy()
        end
    end

    task.spawn(function()
        for i = 1, 5 do
            for _, part in ipairs(boat:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.AssemblyLinearVelocity  = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

--[[ Kiểm tra xem có Fishboat / Tàu cá / Pirate Boat / Thuyền ma trong bán kính quanh thuyền không ]]
function Utility.IsFishboatNearby(pos, radius)
    local rad = radius or 500
    local checkFolders = {
        workspace:FindFirstChild("Enemies"),
        workspace:FindFirstChild("SeaEvents"),
        workspace:FindFirstChild("SeaBeasts"),
        workspace:FindFirstChild("Boats")
    }
    for _, folder in ipairs(checkFolders) do
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") and model ~= ActiveBoat then
                    local lowerName = model.Name:lower()
                    if lowerName:find("fishboat") or lowerName:find("fish ship") or lowerName:find("fish crew") or lowerName:find("fish")
                       or lowerName:find("pirate") or lowerName:find("ghost") or lowerName:find("brigade") or lowerName:find("bridge")
                       or lowerName:find("ship") or lowerName:find("boat") then
                        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
                        if root then
                            local dist = (root.Position - pos).Magnitude
                            if dist <= rad then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

--[[ Check if Frozen Watcher or Leviathan Gate spawned in workspace ]]
function Utility.IsFrozenWatcher()
    local npcsFolder = workspace:FindFirstChild("NPCs")
    if npcsFolder and (npcsFolder:FindFirstChild("Frozen Watcher") or npcsFolder:FindFirstChild("FrozenWatcher")) then
        return true
    end

    local mapFolder = workspace:FindFirstChild("Map")
    if mapFolder then
        local gate = mapFolder:FindFirstChild("LeviathanGate")
        if gate and (gate:FindFirstChild("FrozenWatcherPart") or gate:FindFirstChildOfClass("Model") or gate:FindFirstChildOfClass("Part")) then
            return true
        end
    end

    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    if worldOrigin then
        local locations = worldOrigin:FindFirstChild("Locations")
        if locations and (locations:FindFirstChild("Frozen Dimension") or locations:FindFirstChild("FrozenDimension")) then
            return true
        end
    end

    local seaEventsFolder = workspace:FindFirstChild("SeaEvents")
    if seaEventsFolder and (seaEventsFolder:FindFirstChild("Frozen Watcher") or seaEventsFolder:FindFirstChild("FrozenDimension") or seaEventsFolder:FindFirstChild("LeviathanGate")) then
        return true
    end

    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if enemiesFolder and (enemiesFolder:FindFirstChild("Frozen Watcher") or enemiesFolder:FindFirstChild("Leviathan")) then
        return true
    end

    return false
end

local currentFlyTarget = nil
local currentFlySpeed = 180
local currentFlyOnComplete = nil

--[[ Fly character with physics constraints BodyVelocity and BodyGyro ]]
function Utility.PhysicsFlyTo(targetCFrame, speed, onComplete)
    currentFlyTarget = typeof(targetCFrame) == "CFrame" and targetCFrame.Position or (typeof(targetCFrame) == "Instance" and targetCFrame.Position or targetCFrame)
    currentFlySpeed = speed or S.TeleportFlySpeed or 180
    currentFlyOnComplete = onComplete

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    root.Anchored = false

    if not FlyActive then
        FlyActive = true
        hum.PlatformStand = false

        local bv = root:FindFirstChild("PlayerFlyBV") or Instance.new("BodyVelocity")
        bv.Name = "PlayerFlyBV"
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity = Vector3.zero
        bv.Parent = root

        local bg = root:FindFirstChild("PlayerFlyBG") or Instance.new("BodyGyro")
        bg.Name = "PlayerFlyBG"
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.P = 10000
        bg.Parent = root

        DisconnectConnection("physicsFlyNoclip")
        _conns["physicsFlyNoclip"] = RunService.Stepped:Connect(function()
            if FlyActive and LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)

        DisconnectConnection("physicsFlyLoop")
        _conns["physicsFlyLoop"] = RunService.Heartbeat:Connect(function()
            if not FlyActive or not root or not root.Parent or not currentFlyTarget then
                Utility.StopPhysicsFly()
                return
            end

            local currentPos = root.Position
            local dir = (currentFlyTarget - currentPos)
            local dist = dir.Magnitude

            if currentFlyOnComplete and dist <= 6 then
                Utility.StopPhysicsFly()
                currentFlyOnComplete()
                return
            end

            local activeBV = root:FindFirstChild("PlayerFlyBV")
            if activeBV then
                if dist <= 1.2 then
                    activeBV.Velocity = Vector3.zero
                else
                    activeBV.Velocity = dir.Unit * math.min(currentFlySpeed, math.max(dist * 12, 15))
                end
            end

            local activeBG = root:FindFirstChild("PlayerFlyBG")
            if activeBG then
                local flatDir = Vector3.new(dir.X, 0, dir.Z)
                if flatDir.Magnitude > 1 then
                    activeBG.CFrame = CFrame.lookAt(currentPos, currentPos + flatDir.Unit)
                else
                    local fwd = root.CFrame.LookVector
                    activeBG.CFrame = CFrame.lookAt(currentPos, currentPos + Vector3.new(fwd.X, 0, fwd.Z))
                end
            end
        end)
    end
end

--[[ Stop physics flight and restore character collision ]]
function Utility.StopPhysicsFly()
    FlyActive = false
    DisconnectConnection("physicsFlyLoop")
    DisconnectConnection("physicsFlyNoclip")

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.PlatformStand = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        if root then
            root.Anchored = false
            if root:FindFirstChild("PlayerFlyBV") then root.PlayerFlyBV:Destroy() end
            if root:FindFirstChild("PlayerFlyBG") then root.PlayerFlyBG:Destroy() end
            if root:FindFirstChild("PlayerFlyLV") then root.PlayerFlyLV:Destroy() end
            if root:FindFirstChild("PlayerFlyAO") then root.PlayerFlyAO:Destroy() end
            if root:FindFirstChild("PlayerFlyAtt") then root.PlayerFlyAtt:Destroy() end
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end

    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
            if char and char:FindFirstChildOfClass("Humanoid") then
                cam.CameraSubject = char:FindFirstChildOfClass("Humanoid")
            end
        end
    end)
end

--[[ Reset camera view and unstuck character ]]
function Utility.ResetCameraAndCharacter()
    Utility.StopPhysicsFly()

    DisconnectConnection("findLev")
    DisconnectConnection("autoShootLev")
    DisconnectConnection("teleportPlayerLoop")

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.PlatformStand = false
            hum.Sit = false
        end
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end

    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
            if char and char:FindFirstChildOfClass("Humanoid") then
                cam.CameraSubject = char:FindFirstChildOfClass("Humanoid")
            end
        end
    end)

    UILib.Notify("Unstuck", "Camera and character controls released!", 3)
end

--[[ Extract boat owner name from boat instance ]]
function Utility.GetBoatOwnerName(boat)
    if not boat then return "" end
    local ownerObj = boat:FindFirstChild("Owner")
    if ownerObj then
        if typeof(ownerObj.Value) == "Instance" then
            return ownerObj.Value.Name
        elseif ownerObj.Value ~= nil then
            return tostring(ownerObj.Value)
        end
    end
    local ownerAttr = boat:GetAttribute("Owner")
    if ownerAttr then return tostring(ownerAttr) end
    return ""
end

--[[ Find boat in workspace.Boats by owner name ]]
function Utility.GetBoatByOwner(ownerName)
    if not ownerName or ownerName == "" then return nil end
    local boatsFolder = workspace:FindFirstChild("Boats")
    if not boatsFolder then return nil end

    local targetPlr = Players:FindFirstChild(ownerName)
    local targetIdStr = targetPlr and tostring(targetPlr.UserId) or ""
    local targetNameClean = string.lower(string.gsub(ownerName, "%s+", ""))

    for _, boat in ipairs(boatsFolder:GetChildren()) do
        local ownerObj = boat:FindFirstChild("Owner")
        if ownerObj then
            local val = ownerObj.Value
            if val == targetPlr 
                or val == ownerName 
                or (targetPlr and val == targetPlr.UserId) 
                or tostring(val) == ownerName 
                or (targetIdStr ~= "" and tostring(val) == targetIdStr) 
                or string.lower(string.gsub(tostring(val), "%s+", "")) == targetNameClean then
                return boat
            end
        end

        local ownerAttr = boat:GetAttribute("Owner")
        if ownerAttr then
            local aStr = tostring(ownerAttr)
            if aStr == ownerName or (targetIdStr ~= "" and aStr == targetIdStr) or string.lower(string.gsub(aStr, "%s+", "")) == targetNameClean then
                return boat
            end
        end
    end

    if targetPlr and targetPlr.Character then
        local tHum = targetPlr.Character:FindFirstChildOfClass("Humanoid")
        if tHum and tHum.SeatPart then
            local b = tHum.SeatPart:FindFirstAncestorOfClass("Model")
            if b and b.Parent == boatsFolder then
                return b
            end
        end

        local tRoot = targetPlr.Character:FindFirstChild("HumanoidRootPart")
        if tRoot then
            for _, boat in ipairs(boatsFolder:GetChildren()) do
                local seat = boat:FindFirstChildOfClass("VehicleSeat") or boat:FindFirstChild("VehicleSeat", true)
                local pos = seat and seat.Position or (boat:IsA("Model") and boat:GetPivot().Position)
                if pos and (pos - tRoot.Position).Magnitude <= 30 then
                    return boat
                end
            end
        end
    end

    return nil
end

--[[ Find available empty cannon seat on boat ]]
function Utility.GetAvailableCannonSeat(boat)
    if not boat then return nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if hum and hum.SeatPart and hum.SeatPart:IsA("Seat") and not hum.SeatPart:IsA("VehicleSeat") then
        local p = hum.SeatPart.Parent
        if p and (p.Name == "Cannon" or p.Parent == boat or p == boat) then
            return hum.SeatPart
        end
    end

    for _, child in ipairs(boat:GetChildren()) do
        if child.Name == "Cannon" then
            local seat = child:FindFirstChildOfClass("Seat") or child:FindFirstChild("Seat")
            if seat and (not seat.Occupant or seat.Occupant == hum) then
                return seat
            end
        end
    end

    for _, seat in ipairs(boat:GetDescendants()) do
        if seat:IsA("Seat") and not seat:IsA("VehicleSeat") then
            if not seat.Occupant or seat.Occupant == hum then
                return seat
            end
        end
    end

    return nil
end

--[[ Count players currently seated on boat cannon seats ]]
function Utility.GetBoatCannonOccupantsCount(boat)
    if not boat then return 0 end
    local count = 0
    local checkedSeats = {}

    local function CheckSeat(seat)
        if seat and seat:IsA("Seat") and not seat:IsA("VehicleSeat") and not checkedSeats[seat] then
            checkedSeats[seat] = true
            if seat.Occupant and seat.Occupant:IsA("Humanoid") and seat.Occupant.Health > 0 then
                count = count + 1
            end
        end
    end

    for _, child in ipairs(boat:GetChildren()) do
        if child.Name == "Cannon" then
            for _, s in ipairs(child:GetDescendants()) do
                CheckSeat(s)
            end
        end
    end

    for _, seat in ipairs(boat:GetDescendants()) do
        CheckSeat(seat)
    end

    return count
end

--[[ Respawn local player character ]]
function Utility.RespawnPlayer()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
        else
            char:BreakJoints()
        end
    end
end

--[[ Get list of all other players in server ]]
function Utility.GetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    return list
end

--[[ Get player boat by name or closest distance ]]
function Utility.GetPlayerBoat(boatName)
    boatName = boatName or S.SelectedBoat or "Beast Hunter"
    local boatsFolder = workspace:FindFirstChild("Boats")
    if not boatsFolder then return nil end

    local targetNameLower = string.lower(boatName)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if hum and hum.SeatPart then
        local currentBoat = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if currentBoat and currentBoat.Parent == boatsFolder and string.find(string.lower(currentBoat.Name), targetNameLower) then
            return currentBoat
        end
    end

    for _, boat in ipairs(boatsFolder:GetChildren()) do
        if string.find(string.lower(boat.Name), targetNameLower) then
            local ownerVal = boat:FindFirstChild("Owner")
            if ownerVal then
                local val = ownerVal.Value
                if val == LocalPlayer 
                    or val == LocalPlayer.Name 
                    or val == LocalPlayer.UserId 
                    or tostring(val) == LocalPlayer.Name 
                    or tostring(val) == tostring(LocalPlayer.UserId) then
                    return boat
                end
            end
            local ownerAttr = boat:GetAttribute("Owner")
            if ownerAttr and (ownerAttr == LocalPlayer.Name or tostring(ownerAttr) == tostring(LocalPlayer.UserId)) then
                return boat
            end
        end
    end

    for _, boat in ipairs(boatsFolder:GetChildren()) do
        if string.find(string.lower(boat.Name), targetNameLower) then
            return boat
        end
    end

    local root = char and char:FindFirstChild("HumanoidRootPart")
    local nearestBoat = nil
    local minDist = math.huge
    for _, boat in ipairs(boatsFolder:GetChildren()) do
        local seat = boat:FindFirstChildOfClass("VehicleSeat") or boat:FindFirstChild("VehicleSeat", true)
        if seat and root then
            local d = (seat.Position - root.Position).Magnitude
            if d < minDist then
                minDist = d
                nearestBoat = boat
            end
        end
    end

    return nearestBoat
end

--[[ Fly to target seat and securely sit down ]]
function Utility.FlyToAndSitSeat(targetSeat, onSeatSuccess)
    if not targetSeat or not targetSeat.Parent then return false end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end

    -- 1. Nếu đã thực sự ngồi đúng ghế mục tiêu
    if hum.SeatPart == targetSeat then
        if FlyActive then Utility.StopPhysicsFly() end
        if onSeatSuccess then onSeatSuccess() end
        return true
    end

    local function AttemptNativeSit()
        Utility.StopPhysicsFly()
        hum.PlatformStand = false
        hum.Jump = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)

        if targetSeat and targetSeat.Parent then
            pcall(function() targetSeat.Disabled = false end)
            
            for _ = 1, 3 do
                if hum.SeatPart == targetSeat then break end
                root.CFrame = targetSeat.CFrame * CFrame.new(0, 0.5, 0)
                pcall(function()
                    targetSeat.Disabled = false
                    targetSeat:Sit(hum)
                end)
                if firetouchinterest then
                    pcall(function()
                        firetouchinterest(root, targetSeat, 0)
                        task.wait(0.02)
                        firetouchinterest(root, targetSeat, 1)
                    end)
                end
                task.wait(0.08)
            end
        end

        for _ = 1, 10 do
            if hum.SeatPart == targetSeat then
                if onSeatSuccess then onSeatSuccess() end
                return true
            end
            task.wait(0.08)
        end

        return (hum.SeatPart == targetSeat)
    end

    local seatPos = targetSeat.Position
    local dist = (seatPos - root.Position).Magnitude

    if dist <= 5 then
        return AttemptNativeSit()
    end

    local speed = S.TeleportFlySpeed or 180
    local targetPos = seatPos + Vector3.new(0, 1.5, 0)

    Utility.PhysicsFlyTo(targetPos, speed, function()
        if targetSeat and targetSeat.Parent and LocalPlayer.Character then
            AttemptNativeSit()
        end
    end)

    return (hum.SeatPart == targetSeat)
end

--[[ Sit on boat driver VehicleSeat ]]
function Utility.SitVehicleSeat(boat)
    if not boat then return false end
    local vSeat = boat:FindFirstChildOfClass("VehicleSeat") or boat:FindFirstChild("VehicleSeat", true)
    if not vSeat then return false end
    return Utility.FlyToAndSitSeat(vSeat)
end

--[[ Sit on available boat Cannon seat ]]
function Utility.SitCannonSeat(boat)
    if not boat then return false end
    local cannonSeat = Utility.GetAvailableCannonSeat(boat)
    if not cannonSeat then return false end
    return Utility.FlyToAndSitSeat(cannonSeat)
end

--[[ Get player's Beast Hunter boat ]]
function Utility.GetBeastHunterBoat()
    return Utility.GetPlayerBoat("Beast Hunter")
end

--[[ Send remote request to purchase boat by name ]]
function Utility.BuyBoat(boatName)
    local target = boatName or S.SelectedBoat or "Beast Hunter"
    local ok, res = pcall(function()
        local Event = game:GetService("ReplicatedStorage").Remotes.CommF_
        return Event:InvokeServer("BuyBoat", target)
    end)
    return ok, res
end

--[[ Find Frozen Heart object in workspace.Map ]]
function Utility.GetFrozenHeart()
    local mapFolder = workspace:FindFirstChild("Map")
    if mapFolder then
        local fh = mapFolder:FindFirstChild("FrozenHeart")
        if fh then return fh end

        for _, child in ipairs(mapFolder:GetChildren()) do
            if child.Name == "FrozenHeart" then
                return child
            end
        end
    end
    return nil
end

--[[ Get list of all island names in the game ]]
function Utility.GetIslandList()
    local islands = {}
    local knownIslands = {
        "Boat Castle", "CakeLoaf", "CandyCane", "ChocolateIsland", "Great Tree",
        "Haunted Castle", "Ice Cream Island", "Peanut Island", "Port", "TikiOutpost",
        "Turtle", "Waterfall"
    }

    local function CheckParentFolder(parentFolder)
        if not parentFolder then return end
        for _, name in ipairs(knownIslands) do
            local found = parentFolder:FindFirstChild(name)
            if found and not table.find(islands, name) then
                table.insert(islands, name)
            end
        end
        for _, obj in ipairs(parentFolder:GetChildren()) do
            if (obj:IsA("Model") or obj:IsA("Folder")) and (string.find(obj.Name, "Island") or string.find(obj.Name, "Castle") or string.find(obj.Name, "Outpost")) and not table.find(islands, obj.Name) then
                table.insert(islands, obj.Name)
            end
        end
    end

    CheckParentFolder(workspace)
    CheckParentFolder(workspace:FindFirstChild("Map"))
    CheckParentFolder(workspace:FindFirstChild("Locations"))
    return islands
end

--[[ Get island Model or Folder instance by name ]]
function Utility.GetIslandObject(islandName)
    if not islandName then return nil end
    local mapFolder = workspace:FindFirstChild("Map")
    local locFolder = workspace:FindFirstChild("Locations")
    return (mapFolder and mapFolder:FindFirstChild(islandName))
        or (locFolder and locFolder:FindFirstChild(islandName))
        or workspace:FindFirstChild(islandName)
end

--[[ Optimize rendering and lighting for smooth FPS ]]
function Utility.OptimizeGraphics(silent)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1

        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then
                v.Enabled = false
            end
        end

        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end

        sethiddenproperty(workspace, "InterpolationThrottling", Enum.InterpolationThrottlingMode.Low)
    end)
    if not silent then
        UILib.Notify("Boost FPS", "Graphics optimized smoothly!", 3)
    end
end

--[[ Send Discord Webhook notification when Leviathan spawns ]]
function Utility.SendWebhook(url, player)
    if not url or url == "" then return end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local pos = root and root.Position or Vector3.new(0, 0, 0)
    local posStr = string.format("(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)

    local payload = {
        username = "Leviathan Hunter",
        avatar_url = "https://raw.githubusercontent.com/TheHilichurl/Roblox_Script/refs/heads/main/Hilichurl_icon.png",
        embeds = {{
            title = "❄️ LEVIATHAN DETECTED! ❄️",
            description = string.format("**Player:** `%s`\n**User ID:** `%d`\n**Coordinates:** `%s`\n**Time:** `%s`",
                player.Name, player.UserId, posStr, os.date("%H:%M:%S - %d/%m/%Y")),
            color = 3840742,
            fields = {
                { name = "Status", value = "Leviathan Gate / Frozen Dimension detected!", inline = true },
                { name = "Game", value = "Blox Fruits (Sea 3)", inline = true }
            },
            footer = { text = "Hilichurl Hub • Auto Leviathan Tracker" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    local json = HttpService:JSONEncode(payload)
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if req then
            req({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = json
            })
        end
    end)
end

--[[ Start automated boat flight routine to find Leviathan ]]
function Utility.StartBoatFlight(boat)
    ActiveBoat = boat
    Utility.UpdateBoatCache(boat)

    local seat = boat:FindFirstChildOfClass("VehicleSeat") or boat.PrimaryPart
    if not seat then return end

    for _, part in ipairs(boat:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity  = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end

    local att = seat:FindFirstChild("FlyAttachment") or Instance.new("Attachment")
    att.Name = "FlyAttachment"; att.Parent = seat

    local lv = seat:FindFirstChild("FlyLinearVelocity") or Instance.new("LinearVelocity")
    lv.Name = "FlyLinearVelocity"; lv.Attachment0 = att
    lv.MaxForce = math.huge; lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.Parent = seat

    local ao = seat:FindFirstChild("FlyAlignOrientation") or Instance.new("AlignOrientation")
    ao.Name = "FlyAlignOrientation"; ao.Attachment0 = att
    ao.MaxTorque = math.huge; ao.Responsiveness = 200
    ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    ao.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(-1, 0, 0))
    ao.Parent = seat

    local startY = seat.Position.Y
    local stage1_Dur = 7
    local stage2_Dur = 10
    local t0 = os.clock()

    local targetPointA = Vector3.new(-16130, 199, 58000)
    local targetPointB = Vector3.new(-16130, 199, 38000)
    local currentTarget = targetPointA

    DisconnectConnection("findLev")
    FindLeviathanConnection = RunService.Heartbeat:Connect(function()
        if not S.FindLeviathanEnabled then
            DisconnectConnection("findLev")
            Utility.ForceStopBoat(boat)
            return
        end

        if Utility.IsFrozenWatcher() then
            Utility.HandleLeviathanFound()
            return
        end

        local pos = seat.Position
        local speed = S.BoatFlySpeed or 220
        local flyY = S.BoatFlyHeight or 190

        local targetWithY = Vector3.new(currentTarget.X, flyY, currentTarget.Z)
        local dir = (targetWithY - pos)
        local dist = dir.Magnitude

        if dist <= 35 then
            if currentTarget == targetPointA then
                currentTarget = targetPointB
            else
                currentTarget = targetPointA
            end
        end

        local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
        local distFromOriginZ = math.abs(pos.Z - 480)
        local isNearFishboat = Utility.IsFishboatNearby(pos, 500)

        -- 1. Ưu tiên kiểm tra toạ độ Z = 480: trong bán kính 2000 studs luôn đẩy lên Y = 800 trước rồi mới bay tiếp
        if distFromOriginZ <= 2000 then
            local climbSpeed = 200
            local deltaY = 800 - pos.Y
            local vy = math.clamp(deltaY * 10, -climbSpeed, climbSpeed)

            if pos.Y < 790 then
                -- Đẩy thẳng đứng đạt độ cao 800 trước
                lv.VectorVelocity = Vector3.new(0, vy, 0)
            else
                -- Đã đạt độ cao 800 thì bắt đầu bay tiếp
                lv.VectorVelocity = Vector3.new(flatDir.X * speed, vy, flatDir.Z * speed)
            end
        -- 2. Khi phát hiện Fishboat / Pirate Boat trong bán kính 500 studs: tự động bay lên Y = 450 với tốc độ 200 studs/s
        elseif isNearFishboat then
            local climbSpeed = 200
            local deltaY = 450 - pos.Y
            local vy = math.clamp(deltaY * 10, -climbSpeed, climbSpeed)

            if pos.Y < 440 then
                -- Ưu tiên nâng độ cao vượt qua đỉnh cột buồm thuyền ma / tàu hải tặc
                lv.VectorVelocity = Vector3.new(flatDir.X * (speed * 0.6), vy, flatDir.Z * (speed * 0.6))
            else
                -- Đã đạt độ cao 450 thì bay thẳng mượt mà ở trên cao
                lv.VectorVelocity = Vector3.new(flatDir.X * speed, vy, flatDir.Z * speed)
            end
        else
            -- 3. Ra khỏi bán kính 2000 studs so với toạ độ Z và không có Fishboat / Pirate Boat: trở về độ cao bình thường (Y = 190)
            lv.VectorVelocity = Vector3.new(dir.Unit.X * speed, (flyY - pos.Y) * 5, dir.Unit.Z * speed)
        end

        ao.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(-1, 0, 0))
    end)
    _conns["findLev"] = FindLeviathanConnection
end

--[[ Handle Leviathan detection cleanup, safe smooth landing, and camera release ]]
function Utility.HandleLeviathanFound()
    DisconnectConnection("findLev")
    DisconnectConnection("levNpcAdded")
    DisconnectConnection("levSeaAdded")
    DisconnectConnection("levMapAdded")
    DisconnectConnection("seatWatcher")
    DisconnectConnection("teleportPlayerLoop")

    S.FindLeviathanEnabled = false
    S.TeleportPlayerEnabled = false
    if FindLeviathanToggle then FindLeviathanToggle:Set(false) end

    -- Lưu ý: Nếu đang bật Multiple Find Leviathan thì KHÔNG tắt toggle và KHÔNG ngắt multiFindLev để tiếp tục ngồi yên trên thuyền
    if not S.MultipleFindLeviathanEnabled then
        DisconnectConnection("multiFindLev")
    end

    Utility.StopPhysicsFly()

    task.delay(0.1, function()
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                cam.CameraType = Enum.CameraType.Custom
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    cam.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                end
            end
        end)
    end)

    if not WebhookSent and S.WebhookEnabled and S.WebhookURL ~= "" then
        WebhookSent = true
        task.spawn(function()
            Utility.SendWebhook(S.WebhookURL, LocalPlayer)
        end)
    end

    if S.MultipleFindLeviathanEnabled then
        UILib.Notify("Leviathan", "❄️ Đã tìm thấy Leviathan! Đang tiếp tục ngồi trên thuyền của " .. tostring(S.SelectedBoatOwner) .. "...", 6)
    else
        UILib.Notify("Leviathan", "❄️ Đã tìm thấy Leviathan! Đang hạ cánh an toàn xuống mặt nước...", 6)
    end

    -- Cơ chế hạ cánh từ từ 60 studs/s xuống mặt biển an toàn (Y = 25) trước khi tắt lực bay & tắt NoClip (chỉ áp dụng khi tự lái thuyền)
    if not S.MultipleFindLeviathanEnabled then
        task.spawn(function()
            local boat = ActiveBoat
            local seat = boat and (boat:FindFirstChildOfClass("VehicleSeat") or boat.PrimaryPart)
            if seat then
                local att = seat:FindFirstChild("FlyAttachment") or Instance.new("Attachment")
                att.Name = "FlyAttachment"; att.Parent = seat

                local lv = seat:FindFirstChild("FlyLinearVelocity") or Instance.new("LinearVelocity")
                lv.Name = "FlyLinearVelocity"; lv.Attachment0 = att
                lv.MaxForce = math.huge; lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.Parent = seat

                local ao = seat:FindFirstChild("FlyAlignOrientation") or Instance.new("AlignOrientation")
                ao.Name = "FlyAlignOrientation"; ao.Attachment0 = att
                ao.MaxTorque = math.huge; ao.Responsiveness = 200
                ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
                ao.Parent = seat

                local t0 = os.clock()
                while boat and boat.Parent and seat and seat.Position.Y > 25 and (os.clock() - t0 < 15) do
                    -- Hạ độ cao với tốc độ 60 stud/s, triệt tiêu vận tốc ngang
                    lv.VectorVelocity = Vector3.new(0, -60, 0)
                    ao.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(-1, 0, 0))
                    task.wait(0.03)
                end
            end

            if boat and boat.Parent then
                Utility.ForceStopBoat(boat)
            end
            S.BoatNoClipEnabled = false
            Utility.SetBoatNoClip(false)
        end)
    end
end

--[[ Enable object watcher for Leviathan spawn in workspace folders ]]
function Utility.EnableLeviathanWatcher()
    local npcsFolder = workspace:FindFirstChild("NPCs")
    local seaEventsFolder = workspace:FindFirstChild("SeaEvents")
    local mapFolder = workspace:FindFirstChild("Map")

    local function OnChildAdded(child)
        local cName = child.Name
        if string.find(cName, "Frozen") or string.find(cName, "Watcher") or string.find(cName, "Leviathan") or cName == "LeviathanGate" then
            Utility.HandleLeviathanFound()
        end
    end

    if npcsFolder then
        DisconnectConnection("levNpcAdded")
        _conns["levNpcAdded"] = npcsFolder.ChildAdded:Connect(OnChildAdded)
    end

    if seaEventsFolder then
        DisconnectConnection("levSeaAdded")
        _conns["levSeaAdded"] = seaEventsFolder.ChildAdded:Connect(OnChildAdded)
    end

    if mapFolder then
        DisconnectConnection("levMapAdded")
        _conns["levMapAdded"] = mapFolder.ChildAdded:Connect(OnChildAdded)
    end
end


-- ╔══════════════════════════════════════════════════════════╗
-- ║               [SECTION 4] RUNTIME CONTROLLERS            ║
-- ╚══════════════════════════════════════════════════════════╝

--[[ Start automated Find Leviathan runtime loop ]]
function Utility.StartFindLeviathan()
    WebhookSent = false
    Utility.EnableLeviathanWatcher()

    if Utility.IsFrozenWatcher() then
        Utility.HandleLeviathanFound()
        return
    end

    DisconnectConnection("seatWatcher")
    _conns["seatWatcher"] = task.spawn(function()
        local lastPassengerNotify = 0
        local lastCharacter = LocalPlayer.Character
        local needBuyNewBoat = true

        while S.FindLeviathanEnabled do
            if Utility.IsFrozenWatcher() then
                Utility.HandleLeviathanFound()
                break
            end

            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if char ~= lastCharacter then
                lastCharacter = char
                needBuyNewBoat = true
                if ActiveBoat then
                    Utility.ForceStopBoat(ActiveBoat)
                    ActiveBoat = nil
                end
                DisconnectConnection("findLev")
            end

            local selBoatName = S.SelectedBoat or "Beast Hunter"
            local playerBoat = nil

            if needBuyNewBoat then
                UILib.Notify("Find Leviathan", "Buying boat " .. selBoatName .. "...", 3)
                Utility.BuyBoat(selBoatName)

                local t0 = os.clock()
                while S.FindLeviathanEnabled and (os.clock() - t0 < 6) do
                    playerBoat = Utility.GetPlayerBoat(selBoatName)
                    if playerBoat and playerBoat.Parent then 
                        needBuyNewBoat = false
                        break 
                    end
                    task.wait(0.5)
                end
            else
                playerBoat = Utility.GetPlayerBoat(selBoatName)
                if not playerBoat or not playerBoat.Parent then
                    needBuyNewBoat = true
                end
            end

            if playerBoat and playerBoat.Parent and char and hum and hum.Health > 0 then
                local vSeat = playerBoat:FindFirstChildOfClass("VehicleSeat") or playerBoat:FindFirstChild("VehicleSeat", true)

                if vSeat then
                    if hum.SeatPart ~= vSeat then
                        Utility.SitVehicleSeat(playerBoat)
                    end

                    if hum.SeatPart == vSeat then
                        local cannonCount = Utility.GetBoatCannonOccupantsCount(playerBoat)
                        local req = S.RequiredCannonPassengers or 4

                        if cannonCount >= req then
                            if not _conns["findLev"] or ActiveBoat ~= playerBoat then
                                Utility.StartBoatFlight(playerBoat)
                            end
                        else
                            if _conns["findLev"] then
                                DisconnectConnection("findLev")
                                Utility.ForceStopBoat(playerBoat)
                                ActiveBoat = nil
                            end
                            if os.clock() - lastPassengerNotify > 6 then
                                UILib.Notify("Find Leviathan", string.format("Waiting players (%d/%d)...", cannonCount, req), 4)
                                lastPassengerNotify = os.clock()
                            end
                        end
                    end
                end
            end

            task.wait(0.5)
        end
    end)
end

--[[ Stop Find Leviathan runtime loop ]]
function Utility.StopFindLeviathan()
    DisconnectConnection("findLev")
    DisconnectConnection("levNpcAdded")
    DisconnectConnection("levSeaAdded")
    DisconnectConnection("levMapAdded")
    DisconnectConnection("seatWatcher")

    if ActiveBoat then
        Utility.ForceStopBoat(ActiveBoat)
        ActiveBoat = nil
    end
    Utility.StopPhysicsFly()
    S.BoatNoClipEnabled = false
end

--[[ Start Multiple Find Leviathan routine (Cannon passenger) ]]
function Utility.StartMultipleFindLeviathan()
    if not S.SelectedBoatOwner or S.SelectedBoatOwner == "" then
        UILib.Notify("Error", "Select boat owner!", 3)
        if MultipleFindLeviathanToggle then MultipleFindLeviathanToggle:Set(false) end
        return
    end

    WebhookSent = false
    Utility.EnableLeviathanWatcher()

    if Utility.IsFrozenWatcher() then
        Utility.HandleLeviathanFound()
    end

    DisconnectConnection("multiFindLev")
    _conns["multiFindLev"] = task.spawn(function()
        local lastNotifyTime = 0
        local leviFoundAnnounced = false

        while S.MultipleFindLeviathanEnabled do
            if Utility.IsFrozenWatcher() then
                if not leviFoundAnnounced then
                    leviFoundAnnounced = true
                    Utility.HandleLeviathanFound()
                end
            end

            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local ownerBoat = Utility.GetBoatByOwner(S.SelectedBoatOwner)

            if ownerBoat and ownerBoat.Parent then
                local cannonSeat = Utility.GetAvailableCannonSeat(ownerBoat)

                if hum then
                    local isSeatedInBoat = (hum.SeatPart and (hum.SeatPart == cannonSeat or hum.SeatPart:IsDescendantOf(ownerBoat)))

                    if isSeatedInBoat then
                        if FlyActive then
                            Utility.StopPhysicsFly()
                        end
                    else
                        if cannonSeat then
                            Utility.SitCannonSeat(ownerBoat)
                        else
                            if os.clock() - lastNotifyTime > 5 then
                                UILib.Notify("Multiple Find Leviathan", "Couldn't find empty Cannon seat on " .. S.SelectedBoatOwner .. "'s boat!", 3)
                                lastNotifyTime = os.clock()
                            end
                        end
                    end
                end
            else
                if FlyActive then
                    Utility.StopPhysicsFly()
                end
                if os.clock() - lastNotifyTime > 5 then
                    UILib.Notify("Multiple Find Leviathan", "Waiting for " .. S.SelectedBoatOwner .. "'s boat to spawn...", 3)
                    lastNotifyTime = os.clock()
                end
            end

            task.wait(0.5)
        end
    end)
end

--[[ Stop Multiple Find Leviathan loop ]]
function Utility.StopMultipleFindLeviathan()
    DisconnectConnection("multiFindLev")
    DisconnectConnection("levNpcAdded")
    DisconnectConnection("levSeaAdded")
    DisconnectConnection("levMapAdded")
    Utility.StopPhysicsFly()
end

--[[ Start auto buy boat loop ]]
function Utility.StartAutoBuyBoat()
    DisconnectConnection("autoBuyBoat")
    _conns["autoBuyBoat"] = task.spawn(function()
        while S.AutoBuyBoatEnabled do
            local currentBoat = Utility.GetBoat()
            if not currentBoat then
                pcall(function()
                    local Event = game:GetService("ReplicatedStorage").Remotes.CommF_
                    Event:InvokeServer("BuyBoat", S.SelectedBoat or "Beast Hunter")
                end)
            end
            task.wait(3)
        end
    end)
end

--[[ Stop auto buy boat loop ]]
function Utility.StopAutoBuyBoat()
    DisconnectConnection("autoBuyBoat")
end

--[[ Helper to find Harpoon Model & Seat on boat ]]
function Utility.GetHarpoon(boat)
    if not boat then return nil, nil end
    local harpoonModel = boat:FindFirstChild("Harpoon") or boat:FindFirstChild("Harpoon", true)
    if not harpoonModel then
        for _, d in ipairs(boat:GetDescendants()) do
            if d.Name:lower():find("harpoon") and (d:IsA("Model") or d:IsA("BasePart")) then
                harpoonModel = d
                break
            end
        end
    end
    local harpoonSeat = nil
    if harpoonModel then
        harpoonSeat = harpoonModel:FindFirstChildOfClass("Seat") or harpoonModel:FindFirstChild("Seat", true)
    end
    if not harpoonSeat then
        for _, d in ipairs(boat:GetDescendants()) do
            if d:IsA("Seat") and not d:IsA("VehicleSeat") and (d.Name:lower():find("harpoon") or (d.Parent and d.Parent.Name:lower():find("harpoon"))) then
                harpoonSeat = d
                if not harpoonModel then harpoonModel = d.Parent end
                break
            end
        end
    end
    return harpoonModel, harpoonSeat
end

--[[ Start Auto Shoot Leviathan Heart loop (Beast Hunter Harpoon) ]]
function Utility.StartAutoShootLeviathan()
    DisconnectConnection("autoShootLev")
    _conns["autoShootLev"] = task.spawn(function()
        local stage = 1        -- 1: Sit driver seat, 2: Approach & descend in front of Heart, 3: Sit Harpoon & Shoot
        local flyStep = 1      -- 1: Ascend, 2: Horizontal approach, 3: Descend
        local lastNotify = 0

        local function GetHeartPos(heart)
            if not heart then return nil end
            if heart:IsA("Model") then
                local p = heart.PrimaryPart or heart:FindFirstChild("Heart") or heart:FindFirstChild("HumanoidRootPart") or heart:FindFirstChildOfClass("BasePart")
                if p then return p.Position end
                return heart:GetPivot().Position
            elseif heart:IsA("BasePart") then
                return heart.Position
            end
            return nil
        end

        while S.AutoShootLeviEnabled do
            local targetBoat = nil
            if S.AutoShootBoatOwner and S.AutoShootBoatOwner ~= "" and S.AutoShootBoatOwner ~= "My Boat" then
                targetBoat = Utility.GetBoatByOwner(S.AutoShootBoatOwner)
            else
                targetBoat = Utility.GetBoat() or Utility.GetBeastHunterBoat() or Utility.GetPlayerBoat()
            end

            if not targetBoat or not targetBoat.Parent then
                if os.clock() - lastNotify > 5 then
                    local boatNameStr = (S.AutoShootBoatOwner and S.AutoShootBoatOwner ~= "" and S.AutoShootBoatOwner ~= "My Boat") and ("boat of " .. S.AutoShootBoatOwner) or "your Beast Hunter boat"
                    UILib.Notify("Auto Shoot", "Waiting for " .. boatNameStr .. "...", 3)
                    lastNotify = os.clock()
                end
                task.wait(0.5)
            else
                local vSeat = targetBoat:FindFirstChildOfClass("VehicleSeat") or targetBoat:FindFirstChild("VehicleSeat", true)
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if vSeat and hum and root then
                    local frozenHeart = Utility.GetFrozenHeart()

                    if not frozenHeart then
                        if os.clock() - lastNotify > 5 then
                            UILib.Notify("Auto Shoot", "Waiting for Frozen Heart spawn", 4)
                            lastNotify = os.clock()
                        end
                        task.wait(0.5)
                    else
                        local fhPos = GetHeartPos(frozenHeart)
                        if not fhPos then
                            task.wait(0.5)
                        else
                            local att = vSeat:FindFirstChild("FlyAttachment") or Instance.new("Attachment")
                            att.Name = "FlyAttachment"; att.Parent = vSeat

                            local lv = vSeat:FindFirstChild("FlyLinearVelocity") or Instance.new("LinearVelocity")
                            lv.Name = "FlyLinearVelocity"; lv.Attachment0 = att
                            lv.MaxForce = math.huge; lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.Parent = vSeat

                            local ao = vSeat:FindFirstChild("FlyAlignOrientation") or Instance.new("AlignOrientation")
                            ao.Name = "FlyAlignOrientation"; ao.Attachment0 = att
                            ao.MaxTorque = math.huge; ao.Responsiveness = 200
                            ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; ao.Parent = vSeat

                            ActiveBoat = targetBoat
                            local seatPos = vSeat.Position

                            -- Tính toán vị trí đậu thuyền trước tim Leviathan (khoảng cách 180 studs theo phương ngang, cao hơn tim 20 studs)
                            local heartToBoat = Vector3.new(seatPos.X - fhPos.X, 0, seatPos.Z - fhPos.Z)
                            local approachDir = (heartToBoat.Magnitude > 5) and heartToBoat.Unit or Vector3.new(1, 0, 0)
                            local standOffDist = 180
                            local hoverTargetPos = fhPos + approachDir * standOffDist
                            local targetShootHeight = math.max(fhPos.Y + 20, 45)

                            -- Bước 1: Người chơi tìm đến vị trí thuyền và ngồi vào ghế lái
                            if stage == 1 then
                                if hum.SeatPart == vSeat then
                                    stage = 2
                                    flyStep = 1
                                    UILib.Notify("Auto Shoot", "In driver seat! Ascending boat...", 3)
                                else
                                    Utility.SitVehicleSeat(targetBoat)
                                end
                            -- Bước 2: Bay thuyền đến vị trí phía trước tim Leviathan và hạ độ cao mượt mà
                            elseif stage == 2 then
                                -- Luôn hướng mũi thuyền thẳng vào tim Leviathan
                                ao.CFrame = CFrame.lookAt(vSeat.Position, Vector3.new(fhPos.X, vSeat.Position.Y, fhPos.Z))

                                if flyStep == 1 then
                                    -- Nâng độ cao lên Y = 280 để tránh va chạm địa hình
                                    local deltaY = 280 - seatPos.Y
                                    if deltaY <= 15 or seatPos.Y >= 265 then
                                        lv.VectorVelocity = Vector3.zero
                                        flyStep = 2
                                        UILib.Notify("Auto Shoot", "Flying to position in front of Heart...", 3)
                                    else
                                        local speedY = math.clamp(deltaY * 6, 40, S.BoatFlySpeed or 220)
                                        lv.VectorVelocity = Vector3.new(0, speedY, 0)
                                    end
                                elseif flyStep == 2 then
                                    -- Bay tiếp đến tọa độ ngang của điểm ngắm (ở độ cao 280)
                                    local highTarget = Vector3.new(hoverTargetPos.X, 280, hoverTargetPos.Z)
                                    local flatDiff = (Vector3.new(highTarget.X, 0, highTarget.Z) - Vector3.new(seatPos.X, 0, seatPos.Z))
                                    local flatDist = flatDiff.Magnitude

                                    if flatDist <= 20 then
                                        lv.VectorVelocity = Vector3.zero
                                        flyStep = 3
                                        UILib.Notify("Auto Shoot", "Descending boat to shooting altitude...", 3)
                                    else
                                        local moveDir = flatDiff.Unit
                                        local speed = math.clamp(flatDist * 5, 40, S.BoatFlySpeed or 220)
                                        lv.VectorVelocity = Vector3.new(moveDir.X * speed, 0, moveDir.Z * speed)
                                    end
                                elseif flyStep == 3 then
                                    -- Hạ độ cao xuống vị trí bắn chuẩn (targetShootHeight) với tốc độ giảm tốc mượt
                                    local finalTarget = Vector3.new(hoverTargetPos.X, targetShootHeight, hoverTargetPos.Z)
                                    local dist3D = (finalTarget - seatPos).Magnitude
                                    local deltaY = targetShootHeight - seatPos.Y

                                    if dist3D <= 25 or (math.abs(deltaY) <= 12 and (Vector3.new(hoverTargetPos.X, 0, hoverTargetPos.Z) - Vector3.new(seatPos.X, 0, seatPos.Z)).Magnitude <= 30) then
                                        lv.VectorVelocity = Vector3.zero
                                        stage = 3
                                        UILib.Notify("Auto Shoot", "Position reached! Sitting on Harpoon...", 3)
                                    else
                                        local dir = (finalTarget - seatPos).Unit
                                        local speed = math.clamp(dist3D * 4, 30, S.BoatFlySpeed or 220)
                                        lv.VectorVelocity = dir * speed
                                    end
                                end
                            -- Bước 3: Đậu thuyền cố định, ngồi lên Harpoon và ngắm bắn tim
                            elseif stage == 3 then
                                -- Dừng thuyền cố định hoàn toàn và khóa góc nhìn vào tim
                                lv.VectorVelocity = Vector3.zero
                                ao.CFrame = CFrame.lookAt(vSeat.Position, Vector3.new(fhPos.X, vSeat.Position.Y, fhPos.Z))

                                local harpoonModel, harpoonSeat = Utility.GetHarpoon(targetBoat)

                                if harpoonSeat and harpoonModel then
                                    if hum.SeatPart == harpoonSeat then
                                        -- Tính toán góc bắn chính xác từ vị trí người bắn đến tim Leviathan
                                        local shooterPos = (root and root.Position) or harpoonSeat.Position
                                        local dx = fhPos.X - shooterPos.X
                                        local dz = fhPos.Z - shooterPos.Z
                                        local horizontalDist = math.sqrt(dx * dx + dz * dz)
                                        local deltaY = fhPos.Y - shooterPos.Y

                                        -- tan(theta) = deltaY / horizontalDist => theta = atan2(deltaY, horizontalDist) + 0.15 bù góc
                                        local pitchAngle = math.atan2(deltaY, math.max(horizontalDist, 0.1)) + 0.15
                                        pitchAngle = math.clamp(pitchAngle, -0.175, 0.785)

                                        pcall(function()
                                            local Event = game:GetService("ReplicatedStorage").Remotes.CommF_
                                            local serverTime = workspace:GetServerTimeNow()
                                            Event:InvokeServer(
                                                "FireHarpoon",
                                                pitchAngle,
                                                0,
                                                harpoonModel,
                                                serverTime
                                            )
                                        end)
                                        task.wait(1.2)
                                    else
                                        -- Nếu còn ngồi ghế lái thì rời ghế ngay lập tức
                                        if hum.SeatPart == vSeat or hum.SeatPart ~= harpoonSeat then
                                            hum.Sit = false
                                            hum.Jump = true
                                            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                                        end

                                        -- Trực tiếp đưa nhân vật đến ghế Harpoon và ngồi lên
                                        harpoonSeat.Disabled = false
                                        root.CFrame = harpoonSeat.CFrame * CFrame.new(0, 1, 0)
                                        task.wait(0.05)
                                        pcall(function() harpoonSeat:Sit(hum) end)
                                        if firetouchinterest then
                                            pcall(function()
                                                firetouchinterest(root, harpoonSeat, 0)
                                                task.wait(0.02)
                                                firetouchinterest(root, harpoonSeat, 1)
                                            end)
                                        end
                                    end
                                else
                                    if os.clock() - lastNotify > 5 then
                                        UILib.Notify("Auto Shoot", "Couldn't find Harpoon on selected boat!", 3)
                                        lastNotify = os.clock()
                                    end
                                end
                            end
                        end
                    end
                end
            end

            task.wait(0.15)
        end
    end)
end

--[[ Stop Auto Shoot Leviathan Heart loop ]]
function Utility.StopAutoShootLeviathan()
    DisconnectConnection("autoShootLev")
    if ActiveBoat then
        Utility.ForceStopBoat(ActiveBoat)
        ActiveBoat = nil
    end
end

--[[ Send remote request to bribe the Spy NPC for Leviathan info ]]
function Utility.BribeSpy()
    local ok, res = pcall(function()
        local Event = game:GetService("ReplicatedStorage").Remotes.CommF_
        return Event:InvokeServer("InfoLeviathan", "2")
    end)
    if ok then
        UILib.Notify("Spy NPC", "Bribed Spy for Leviathan info!", 3)
    else
        UILib.Notify("Spy NPC", "Failed to bribe Spy: " .. tostring(res), 3)
    end
    return ok, res
end

--[[ Start Auto Talk Frozen Watcher loop to open Leviathan Gate ]]
function Utility.StartAutoTalkFrozenWatcher()
    DisconnectConnection("autoTalkWatcher")
    _conns["autoTalkWatcher"] = task.spawn(function()
        while S.AutoTalkFrozenWatcherEnabled do
            local npcsFolder = workspace:FindFirstChild("NPCs")
            local watcher = npcsFolder and (npcsFolder:FindFirstChild("Frozen Watcher") or npcsFolder:FindFirstChild("FrozenWatcher"))

            if not watcher then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj.Name == "Frozen Watcher" or obj.Name == "FrozenWatcher" then
                        watcher = obj
                        break
                    end
                end
            end

            if watcher then
                local wPart = watcher.PrimaryPart or watcher:FindFirstChildOfClass("BasePart") or watcher:FindFirstChild("HumanoidRootPart") or watcher:FindFirstChild("Head")
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if wPart and root then
                    local dist = (wPart.Position - root.Position).Magnitude
                    if dist > 8 then
                        Utility.PhysicsFlyTo(wPart.CFrame * CFrame.new(0, 2, 4), S.TeleportFlySpeed or 180)
                        task.wait(0.5)
                    else
                        Utility.StopPhysicsFly()
                        pcall(function()
                            local Event = game:GetService("ReplicatedStorage").Remotes.CommF_
                            Event:InvokeServer("OpenLeviathanGate")
                        end)
                        UILib.Notify("Frozen Watcher", "Opened Leviathan Gate!", 3)
                        task.wait(3)
                    end
                else
                    task.wait(1)
                end
            else
                UILib.Notify("Frozen Watcher", "Finding Frozen Watcher", 3)
                task.wait(2)
            end
        end
    end)
end

--[[ Stop Auto Talk Frozen Watcher loop ]]
function Utility.StopAutoTalkFrozenWatcher()
    DisconnectConnection("autoTalkWatcher")
    Utility.StopPhysicsFly()
end

--[[ Find active Leviathan Segments or main Leviathan in workspace.SeaBeasts ]]
function Utility.GetLeviathanTarget()
    local seaBeasts = workspace:FindFirstChild("SeaBeasts")
    local enemies = workspace:FindFirstChild("Enemies")
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.zero

    local aliveSegments = {}
    local mainLeviathan = nil

    local function ProcessFolder(folder)
        if not folder then return end
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") then
                local hum = model:FindFirstChildOfClass("Humanoid")
                local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
                local isAlive = (hum and hum.Health > 0) or (not hum and root ~= nil)

                if isAlive and root then
                    local name = model.Name:lower()
                    if name:find("segment") then
                        table.insert(aliveSegments, {
                            Model = model,
                            Root = root,
                            Distance = (root.Position - myPos).Magnitude
                        })
                    elseif name == "leviathan" or (name:find("leviathan") and not name:find("tail")) then
                        mainLeviathan = model
                    end
                end
            end
        end
    end

    ProcessFolder(seaBeasts)
    ProcessFolder(enemies)

    if #aliveSegments > 0 then
        table.sort(aliveSegments, function(a, b)
            return a.Distance < b.Distance
        end)
        return aliveSegments[1].Model, true
    end

    if mainLeviathan then
        return mainLeviathan, false
    end

    return nil, false
end

--[[ Thi triển kỹ năng tấn công Leviathan dựa trên cấu hình từ Tab Farm Setting ]]
function Utility.CastSkillsLeviathan(targetPos, targetEnemy, weaponTypeOverride)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not myRoot then return end

    local wType = weaponTypeOverride or S.LeviathanSelectedWeapon or S.SelectedWeaponType or "Melee"
    local tool = Utility.EquipWeaponByType(wType)

    local targetPart = targetEnemy and (targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy:FindFirstChild("Head") or targetEnemy.PrimaryPart or targetEnemy:FindFirstChildOfClass("BasePart"))
    local actualTargetPos = targetPart and targetPart.Position or targetPos
    if not actualTargetPos then return end

    myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(actualTargetPos.X, myRoot.Position.Y, actualTargetPos.Z))

    local toolRemote = tool and (tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent"))
    local skillRemotes = {}
    for _, child in ipairs(hum:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end

    local skillKeys = {}
    if wType == "Melee" then
        if S.MeleeSkillZ then table.insert(skillKeys, "Z") end
        if S.MeleeSkillX then table.insert(skillKeys, "X") end
        if S.MeleeSkillC then table.insert(skillKeys, "C") end
    elseif wType == "Fruit" then
        if S.FruitSkillZ then table.insert(skillKeys, "Z") end
        if S.FruitSkillX then table.insert(skillKeys, "X") end
        if S.FruitSkillC then table.insert(skillKeys, "C") end
        if S.FruitSkillV then table.insert(skillKeys, "V") end
        if S.FruitSkillF then table.insert(skillKeys, "F") end
    elseif wType == "Sword" then
        if S.SwordSkillZ then table.insert(skillKeys, "Z") end
        if S.SwordSkillX then table.insert(skillKeys, "X") end
    elseif wType == "Gun" or wType == "Dragonstorm" or wType == "Dragon Storm" then
        if S.GunSkillZ then table.insert(skillKeys, "Z") end
        if S.GunSkillX then table.insert(skillKeys, "X") end
    end

    for _, key in ipairs(skillKeys) do
        if not char or not char.Parent or not hum or hum.Health <= 0 then break end

        local curPart = (targetEnemy and targetEnemy.Parent and (targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy:FindFirstChild("Head") or targetEnemy.PrimaryPart or targetEnemy:FindFirstChildOfClass("BasePart"))) or targetPart
        local livePos = curPart and curPart.Position or actualTargetPos
        local myPos = myRoot.Position
        local aimCF = CFrame.lookAt(myPos, livePos)
        local hitCF = curPart and curPart.CFrame or CFrame.new(livePos)

        -- 1. Kích hoạt chiêu thức chuẩn Cobalt tương ứng từng loại vũ khí
        for _, rf in ipairs(skillRemotes) do
            task.spawn(function()
                if wType == "Melee" then
                    pcall(function() rf:InvokeServer(key, aimCF, hitCF, "Aaa") end)
                elseif wType == "Fruit" then
                    pcall(function() rf:InvokeServer(key) end)
                elseif wType == "Sword" then
                    pcall(function() rf:InvokeServer(key, livePos) end)
                elseif wType == "Gun" or wType == "Dragonstorm" or wType == "Dragon Storm" then
                    pcall(function() rf:InvokeServer(key) end)
                end
            end)
        end

        -- 2. Liên tục cập nhật tọa độ Aim Vector3 trong suốt thời gian giữ chiêu (Skills Only cho Leviathan)
        local holdEnabled = (wType == "Melee" and S.HoldMeleeSkills)
            or (wType == "Fruit" and S.HoldFruitSkills)
            or (wType == "Sword" and S.HoldSwordSkills)
            or ((wType == "Gun" or wType == "Dragonstorm" or wType == "Dragon Storm") and S.HoldGunSkills)
        local duration = holdEnabled and (S.SkillHoldDuration or 0.35) or 0.05
        local t0 = os.clock()
        while os.clock() - t0 < duration do
            if not char.Parent or not hum or hum.Health <= 0 then break end
            local curLivePart = (targetEnemy and targetEnemy.Parent and (targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy:FindFirstChild("Head") or targetEnemy.PrimaryPart or targetEnemy:FindFirstChildOfClass("BasePart"))) or targetPart
            local cPos = curLivePart and curLivePart.Position or livePos

            if toolRemote then
                pcall(function() toolRemote:FireServer(cPos) end)
            end
            task.wait(0.035)
        end

        task.wait(0.12)
    end
end
Utility.CastSkills = Utility.CastSkillsLeviathan

--[[ Start auto attack Leviathan routine ]]
function Utility.StartAutoAttackLeviathan()
    DisconnectConnection("autoAttackLevi")
    if S.MultipleFindLeviathanEnabled then
        S.MultipleFindLeviathanEnabled = false
        if MultipleFindLeviathanToggle then MultipleFindLeviathanToggle:Set(false) end
        Utility.StopMultipleFindLeviathan()
    end

    _conns["autoAttackLevi"] = task.spawn(function()
        while S.AutoAttackLeviEnabled do
            local target, isSegment = Utility.GetLeviathanTarget()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if target and target.Parent and root and hum and hum.Health > 0 then
                -- Rời khỏi ghế lái trước khi bay tới tấn công
                if hum.SeatPart or hum.Sit then
                    hum.Sit = false
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                    task.wait(0.05)
                end

                local eRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") or target.PrimaryPart or target:FindFirstChildOfClass("BasePart")

                if eRoot then
                    local chosenWeapon = S.LeviathanSelectedWeapon or "Dragonstorm"
                    local targetPos = eRoot.Position
                    local attackHeight = (chosenWeapon == "Dragonstorm" or chosenWeapon == "Dragon Storm" or chosenWeapon == "Gun") and 40 or 25
                    local flyTargetPos = targetPos + Vector3.new(0, attackHeight, 0)
                    Utility.PhysicsFlyTo(flyTargetPos, S.BoatFlySpeed or S.TeleportFlySpeed or 220)

                    -- Thực hiện tấn công vũ khí liên tục
                    if chosenWeapon == "Dragonstorm" or chosenWeapon == "Dragon Storm" then
                        Utility.AttackDragonstorm(target, eRoot)
                    elseif chosenWeapon == "Melee" then
                        Utility.AttackMelee(target, eRoot)
                    elseif chosenWeapon == "Sword" then
                        Utility.AttackSword(target, eRoot)
                    elseif chosenWeapon == "Fruit" then
                        Utility.AttackFruitM1(target, eRoot)
                    elseif chosenWeapon == "Gun" then
                        Utility.AttackGun(target, eRoot)
                    end
                end
            else
                Utility.StopPhysicsFly()
            end
            task.wait(0.035)
        end
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop auto attack Leviathan routine ]]
function Utility.StopAutoAttackLeviathan()
    DisconnectConnection("autoAttackLevi")
    Utility.StopPhysicsFly()
end

--[[ Start auto use skills to attack Leviathan routine ]]
function Utility.StartAutoSkillsLeviathan()
    DisconnectConnection("autoSkillsLevi")
    _conns["autoSkillsLevi"] = task.spawn(function()
        local weaponRotation = { "Melee", "Sword", "Fruit", "Gun" }
        local wIndex = 1

        while S.AutoSkillsLeviEnabled do
            local target, _ = Utility.GetLeviathanTarget()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if target and target.Parent and root and hum and hum.Health > 0 then
                -- Rời khỏi ghế lái trước khi tung chiêu
                if hum.SeatPart or hum.Sit then
                    hum.Sit = false
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                    task.wait(0.05)
                end

                local eRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") or target.PrimaryPart or target:FindFirstChildOfClass("BasePart")
                if eRoot then
                    local chosenWeapon = S.LeviathanSelectedWeapon or "Melee"
                    if chosenWeapon == "Rotate All" then
                        chosenWeapon = weaponRotation[wIndex]
                        wIndex = (wIndex % #weaponRotation) + 1
                    end

                    Utility.CastSkillsLeviathan(eRoot.Position, target, chosenWeapon)
                    task.wait(1.5)
                else
                    task.wait(0.5)
                end
            else
                task.wait(0.5)
            end
        end
    end)
end

--[[ Stop auto use skills to attack Leviathan routine ]]
function Utility.StopAutoSkillsLeviathan()
    DisconnectConnection("autoSkillsLevi")
end

--[[ Start auto respawn loop when boat is destroyed ]]
function Utility.StartResetWhenBoatDestroyed()
    DisconnectConnection("resetWhenBoatDestroyed")
    _conns["resetWhenBoatDestroyed"] = task.spawn(function()
        local trackedBoat = nil
        while S.ResetWhenBoatDestroyed do
            local boatsFolder = workspace:FindFirstChild("Boats")

            if not trackedBoat or not trackedBoat.Parent or trackedBoat.Parent ~= boatsFolder then
                local b = Utility.GetBoat() or Utility.GetPlayerBoat() or (S.SelectedBoatOwner and S.SelectedBoatOwner ~= "" and Utility.GetBoatByOwner(S.SelectedBoatOwner))
                if b and b.Parent and b.Parent == boatsFolder then
                    trackedBoat = b
                end
            end

            if trackedBoat then
                local isDestroyed = false

                if not trackedBoat.Parent or trackedBoat.Parent ~= boatsFolder or not trackedBoat:IsDescendantOf(workspace) then
                    isDestroyed = true
                else
                    local boatHp = trackedBoat:FindFirstChild("Humanoid")
                    if boatHp and (boatHp:IsA("IntValue") or boatHp:IsA("NumberValue")) and boatHp.Value <= 0 then
                        isDestroyed = true
                    end
                end

                if isDestroyed then
                    trackedBoat = nil
                    UILib.Notify("Boat Destroyed", "Boat destroyed! Respawning...", 4)
                    Utility.RespawnPlayer()
                    task.wait(3)
                end
            end

            task.wait(0.5)
        end
    end)
end

--[[ Stop auto respawn loop when boat is destroyed ]]
function Utility.StopResetWhenBoatDestroyed()
    DisconnectConnection("resetWhenBoatDestroyed")
end

--[[ Start auto respawn loop when selected boat owner dies ]]
function Utility.StartResetWhenSelectedOwnerDie()
    DisconnectConnection("resetWhenOwnerDie")
    _conns["resetWhenOwnerDie"] = task.spawn(function()
        local ownerHadCharacter = false
        while S.ResetWhenSelectedOwnerDie do
            if S.SelectedBoatOwner and S.SelectedBoatOwner ~= "" then
                local targetPlr = Players:FindFirstChild(S.SelectedBoatOwner)
                if targetPlr then
                    local tChar = targetPlr.Character
                    local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

                    if tHum and tHum.Health > 0 then
                        ownerHadCharacter = true
                    elseif ownerHadCharacter and (not tHum or tHum.Health <= 0) then
                        ownerHadCharacter = false
                        UILib.Notify("Owner Died", S.SelectedBoatOwner .. " died! Respawning...", 4)
                        Utility.RespawnPlayer()
                        task.wait(3)
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

--[[ Stop auto respawn loop when selected boat owner dies ]]
function Utility.StopResetWhenSelectedOwnerDie()
    DisconnectConnection("resetWhenOwnerDie")
end

--[[ Start boat waypoint navigation routine for driving or flying ]]
function Utility.StartBoatWaypointNavigation(waypoints, isFlyMode, locationName, completionCallback)
    DisconnectConnection("boatNavLoop")

    local targetBoat = Utility.GetBoat() or Utility.GetPlayerBoat()
    if not targetBoat or not targetBoat.Parent then
        UILib.Notify("Navigation", "Please spawn or sit on a boat first!", 3)
        if completionCallback then completionCallback() end
        return
    end

    ActiveBoat = targetBoat
    Utility.UpdateBoatCache(targetBoat)

    local vSeat = targetBoat:FindFirstChildOfClass("VehicleSeat") or targetBoat.PrimaryPart
    if not vSeat then
        UILib.Notify("Navigation", "VehicleSeat not found on boat!", 3)
        if completionCallback then completionCallback() end
        return
    end

    local currentIdx = 1
    local totalPoints = #waypoints
    local modeName = isFlyMode and "Fly" or "Drive"
    local flyAscended = not isFlyMode -- Nếu bay thì bắt đầu là false để nâng độ cao lên 300 studs trước

    UILib.Notify("Navigation", string.format("Starting %s to %s...", modeName, locationName), 3)

    _conns["boatNavLoop"] = RunService.Heartbeat:Connect(function()
        if not targetBoat or not targetBoat.Parent then
            Utility.StopBoatWaypointNavigation()
            if completionCallback then completionCallback() end
            return
        end

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart ~= vSeat then
            Utility.SitVehicleSeat(targetBoat)
        end

        local seatPos = vSeat.Position

        local att = vSeat:FindFirstChild("FlyAttachment") or Instance.new("Attachment")
        att.Name = "FlyAttachment"; att.Parent = vSeat

        local lv = vSeat:FindFirstChild("FlyLinearVelocity") or Instance.new("LinearVelocity")
        lv.Name = "FlyLinearVelocity"; lv.Attachment0 = att
        lv.MaxForce = math.huge; lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.Parent = vSeat

        local ao = vSeat:FindFirstChild("FlyAlignOrientation") or Instance.new("AlignOrientation")
        ao.Name = "FlyAlignOrientation"; ao.Attachment0 = att
        ao.MaxTorque = math.huge; ao.Responsiveness = 200
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; ao.Parent = vSeat

        local speed = isFlyMode and (S.BoatFlySpeed or 220) or (S.CustomBoatSpeed or 250)

        -- Bước 1 (Fly Mode): Nâng độ cao thuyền lên 300 studs tại vị trí hiện tại
        if isFlyMode and not flyAscended then
            local deltaY = 300 - seatPos.Y
            if math.abs(deltaY) <= 8 then
                flyAscended = true
                lv.VectorVelocity = Vector3.zero
                UILib.Notify("Navigation", "Reached Y = 300. Navigating through waypoints...", 3)
            else
                local dirY = Vector3.new(0, deltaY > 0 and 1 or -1, 0)
                lv.VectorVelocity = dirY * speed
                return
            end
        end

        -- Bước 2: Giữ ở độ cao 300 studs bay đến điểm 1, 2, 3 và hạ xuống 100 studs ở điểm 4
        local targetWP = waypoints[currentIdx]
        if not targetWP then
            Utility.StopBoatWaypointNavigation()
            UILib.Notify("Navigation", "Arrived at " .. locationName .. "!", 4)
            if completionCallback then completionCallback() end
            return
        end

        local flyY = targetWP.Y
        if isFlyMode then
            if currentIdx < totalPoints then
                flyY = 300 -- Điểm 1, 2, 3 giữ cố định ở 300 studs
            else
                flyY = 100 -- Điểm 4 hạ xuống 100 studs
            end
        end

        local targetPos = Vector3.new(targetWP.X, flyY, targetWP.Z)
        local flatDist = (Vector3.new(targetWP.X, 0, targetWP.Z) - Vector3.new(seatPos.X, 0, seatPos.Z)).Magnitude

        local reached = false
        if isFlyMode and currentIdx == totalPoints then
            if flatDist <= 40 and math.abs(seatPos.Y - 100) <= 20 then
                reached = true
            end
        else
            if flatDist <= 45 then
                reached = true
            end
        end

        if reached then
            currentIdx = currentIdx + 1
            if currentIdx > totalPoints then
                Utility.StopBoatWaypointNavigation()
                UILib.Notify("Navigation", "Arrived at " .. locationName .. "!", 4)
                if completionCallback then completionCallback() end
                return
            else
                if isFlyMode and currentIdx == totalPoints then
                    UILib.Notify("Navigation", string.format("Approaching final waypoint %d/%d (descending to 100 studs)...", currentIdx, totalPoints), 3)
                else
                    UILib.Notify("Navigation", string.format("Approaching waypoint %d/%d (altitude 300 studs)...", currentIdx, totalPoints), 2)
                end
            end
        end

        local dir = (targetPos - seatPos)
        if dir.Magnitude > 0 then
            lv.VectorVelocity = dir.Unit * speed
        else
            lv.VectorVelocity = Vector3.zero
        end

        local lookTarget = Vector3.new(targetPos.X, seatPos.Y, targetPos.Z)
        if (lookTarget - seatPos).Magnitude > 1 then
            ao.CFrame = CFrame.lookAt(seatPos, lookTarget)
        end
    end)
end

--[[ Stop boat waypoint navigation routine ]]
function Utility.StopBoatWaypointNavigation()
    DisconnectConnection("boatNavLoop")
    if ActiveBoat then
        Utility.ForceStopBoat(ActiveBoat)
    end
end

--[[ Start auto drive boat to Tiki Outpost ]]
function Utility.StartAutoDriveToTiki()
    Utility.StartBoatWaypointNavigation(WAYPOINTS_TIKI, false, "Tiki Outpost", function()
        S.AutoDriveTikiEnabled = false
        if AutoDriveTikiToggle then AutoDriveTikiToggle:Set(false) end
    end)
end

--[[ Start auto drive boat to Hydra Island ]]
function Utility.StartAutoDriveToHydra()
    Utility.StartBoatWaypointNavigation(WAYPOINTS_HYDRA, false, "Hydra Island", function()
        S.AutoDriveHydraEnabled = false
        if AutoDriveHydraToggle then AutoDriveHydraToggle:Set(false) end
    end)
end

--[[ Start auto fly boat to Tiki Outpost ]]
function Utility.StartAutoFlyToTiki()
    Utility.StartBoatWaypointNavigation(WAYPOINTS_TIKI, true, "Tiki Outpost", function()
        S.AutoFlyTikiEnabled = false
        if AutoFlyTikiToggle then AutoFlyTikiToggle:Set(false) end
    end)
end

--[[ Start auto fly boat to Hydra Island ]]
function Utility.StartAutoFlyToHydra()
    Utility.StartBoatWaypointNavigation(WAYPOINTS_HYDRA, true, "Hydra Island", function()
        S.AutoFlyHydraEnabled = false
        if AutoFlyHydraToggle then AutoFlyHydraToggle:Set(false) end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  SEA EVENTS MODULAR CONTROLLERS & DODGE ENGINE
-- ═══════════════════════════════════════════════════════════

local terrorsharkDodgeActive = false
local terrorsharkDodgeEndTime = 0

--[[ Phân loại đối tượng Sea Event dựa trên tên Model ]]
local function GetSeaEventType(model)
    if not model then return "Default" end
    local lowerName = model.Name:lower()

    if lowerName:find("terrorshark") then
        return "Terrorshark"
    elseif lowerName:find("piranha") then
        return "Piranha"
    elseif lowerName:find("shark") then
        return "Shark"
    elseif lowerName:find("fish crew") or lowerName:find("crew member") then
        return "Fish Crew Member"
    elseif lowerName:find("boat") or lowerName:find("ship") or lowerName:find("bridge") or lowerName:find("brigade") then
        return "Boat"
    elseif model.Parent == workspace:FindFirstChild("SeaBeasts") or lowerName:find("seabeast") or lowerName:find("sea beast") or lowerName:find("waterwater") then
        return "Sea Beast"
    end
    return "Default"
end

--[[ Lắng nghe sự kiện BodyMover từ server để né đòn Terrorshark lên Y = 600 ]]
function Utility.EnsureBodyMoverListener()
    if _conns["terrorsharkBodyMover"] then return end
    local rep = game:GetService("ReplicatedStorage")
    local remotes = rep:FindFirstChild("Remotes")
    local bodyMover = remotes and remotes:FindFirstChild("BodyMover")
    if bodyMover and bodyMover:IsA("RemoteEvent") then
        _conns["terrorsharkBodyMover"] = bodyMover.OnClientEvent:Connect(function(data1, op, moverType, data2)
            if not S.AutoFarmSeaEventsEnabled then return end
            local isForMe = false
            local myName = LocalPlayer.Name
            if typeof(data1) == "table" then
                if data1.Character and (data1.Character == myName or (typeof(data1.Character) == "table" and table.find(data1.Character, myName))) then
                    isForMe = true
                end
            end
            if typeof(data2) == "table" then
                if data2.Character and (data2.Character == myName or (typeof(data2.Character) == "table" and table.find(data2.Character, myName))) then
                    isForMe = true
                end
            end
            if isForMe or tostring(op) == "Create" or tostring(moverType) == "BodyVelocity" then
                terrorsharkDodgeActive = true
                terrorsharkDodgeEndTime = os.clock() + 2.0
            end
        end)
    end
end

--[[ Lấy danh sách các đối tượng Sea Event đang còn sống và khớp với bộ lọc ]]
function Utility.GetActiveSeaEventTargets()
    local targets = {}
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    local seaBeasts = workspace:FindFirstChild("SeaBeasts")
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.zero

    local function ProcessModel(model)
        if not model or not model:IsA("Model") then return end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
        local isAlive = (hum and hum.Health > 0) or (not hum and root ~= nil)
        if not isAlive or not root then return end

        local lowerName = model.Name:lower()
        if lowerName:find("leviathan") then return end

        local isSeaEvent = false
        if lowerName:find("piratebridge") or lowerName:find("pirategrandbridge") or lowerName:find("piratebrigade") or lowerName:find("pirategrandbrigade")
            or lowerName:find("shark") or lowerName:find("fish crew") or lowerName:find("fishboat") or lowerName:find("piranha") or lowerName:find("terrorshark") then
            isSeaEvent = true
        elseif model.Parent == seaBeasts or lowerName:find("seabeast") or lowerName:find("sea beast") then
            isSeaEvent = true
        end

        if isSeaEvent then
            local eventType = GetSeaEventType(model)
            local matchFilter = false
            local selEvents = (type(S.SelectedSeaEvents) == "table" and #S.SelectedSeaEvents > 0) and S.SelectedSeaEvents or (S.SelectedSeaEvent and { S.SelectedSeaEvent } or { "All" })

            if table.find(selEvents, "All") or #selEvents == 0 then
                matchFilter = true
            else
                for _, sel in ipairs(selEvents) do
                    if sel == "Shark" and eventType == "Shark" then
                        matchFilter = true; break
                    elseif sel == "Piranha" and eventType == "Piranha" then
                        matchFilter = true; break
                    elseif sel == "Fish Crew" and eventType == "Fish Crew Member" then
                        matchFilter = true; break
                    elseif sel == "Pirate Ships" and eventType == "Boat" then
                        matchFilter = true; break
                    elseif sel == "Sea Beast" and eventType == "Sea Beast" then
                        matchFilter = true; break
                    elseif sel == "Terrorshark" and eventType == "Terrorshark" then
                        matchFilter = true; break
                    end
                end
            end

            if matchFilter then
                table.insert(targets, {
                    Model = model,
                    Root = root,
                    Humanoid = hum,
                    Type = eventType,
                    Distance = (root.Position - myPos).Magnitude
                })
            end
        end
    end

    if enemiesFolder then
        for _, child in ipairs(enemiesFolder:GetChildren()) do ProcessModel(child) end
    end
    if seaBeasts then
        for _, child in ipairs(seaBeasts:GetChildren()) do ProcessModel(child) end
    end

    table.sort(targets, function(a, b) return a.Distance < b.Distance end)
    return targets
end

--[[ Bắt đầu luồng bay thuyền cho Sea Events với 3 giai đoạn nâng độ cao chuẩn Find Leviathan ]]
function Utility.StartSeaEventsBoatFlight(boat)
    ActiveBoat = boat
    Utility.UpdateBoatCache(boat)

    local seat = boat:FindFirstChildOfClass("VehicleSeat") or boat.PrimaryPart
    if not seat then return end

    for _, part in ipairs(boat:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity  = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end

    local att = seat:FindFirstChild("FlyAttachment") or Instance.new("Attachment")
    att.Name = "FlyAttachment"; att.Parent = seat

    local lv = seat:FindFirstChild("FlyLinearVelocity") or Instance.new("LinearVelocity")
    lv.Name = "FlyLinearVelocity"; lv.Attachment0 = att
    lv.MaxForce = math.huge; lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.Parent = seat

    local ao = seat:FindFirstChild("FlyAlignOrientation") or Instance.new("AlignOrientation")
    ao.Name = "FlyAlignOrientation"; ao.Attachment0 = att
    ao.MaxTorque = math.huge; ao.Responsiveness = 200
    ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    ao.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(-1, 0, 0))
    ao.Parent = seat

    local startY = seat.Position.Y
    local stage1_Dur = 7
    local stage2_Dur = 10
    local t0 = os.clock()

    local targetPointA = Vector3.new(-16130, 199, 58000)
    local targetPointB = Vector3.new(-16130, 199, 38000)
    local currentTarget = targetPointA

    DisconnectConnection("seaEventsBoatFly")
    _conns["seaEventsBoatFly"] = RunService.Heartbeat:Connect(function()
        if not S.AutoFarmSeaEventsEnabled or not boat or not boat.Parent then
            DisconnectConnection("seaEventsBoatFly")
            Utility.ForceStopBoat(boat)
            return
        end

        local seaTargets = Utility.GetActiveSeaEventTargets()
        if #seaTargets > 0 then
            DisconnectConnection("seaEventsBoatFly")
            return
        end

        local pos = seat.Position
        local speed = S.BoatFlySpeed or 220
        local flyY = S.BoatFlyHeight or 190

        local targetWithY = Vector3.new(currentTarget.X, flyY, currentTarget.Z)
        local dir = (targetWithY - pos)
        local dist = dir.Magnitude

        if dist <= 35 then
            if currentTarget == targetPointA then
                currentTarget = targetPointB
            else
                currentTarget = targetPointA
            end
        end

        local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
        local distFromOriginZ = math.abs(pos.Z - 480)

        -- Kiểm tra toạ độ Z = 480: trong bán kính 2000 studs luôn đẩy lên Y = 800 trước rồi mới bay tiếp, ra ngoài bán kính 2000 studs thì chuyển về độ cao bình thường
        if distFromOriginZ <= 2000 then
            local climbSpeed = 200
            local deltaY = 800 - pos.Y
            local vy = math.clamp(deltaY * 10, -climbSpeed, climbSpeed)

            if pos.Y < 790 then
                -- Đẩy thẳng đứng đạt độ cao 800 trước
                lv.VectorVelocity = Vector3.new(0, vy, 0)
            else
                -- Đã đạt độ cao 800 thì bắt đầu bay tiếp
                lv.VectorVelocity = Vector3.new(flatDir.X * speed, vy, flatDir.Z * speed)
            end
        else
            -- Ra khỏi bán kính 2000 studs so với toạ độ Z: trở về độ cao bình thường (Y = 190)
            lv.VectorVelocity = Vector3.new(dir.Unit.X * speed, (flyY - pos.Y) * 5, dir.Unit.Z * speed)
        end

        ao.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(-1, 0, 0))
    end)
end

--[[ Vòng lặp Auto Farm Sea Events ]]
function Utility.StartAutoFarmSeaEvents()
    DisconnectConnection("autoFarmSeaEvents")
    DisconnectConnection("seaEventsBoatFly")
    Utility.EnsureBodyMoverListener()
    Utility.UpdatePlayerNoClipState()

    _conns["autoFarmSeaEvents"] = task.spawn(function()
        local lastCharacter = LocalPlayer.Character
        local needBuyNewBoat = true
        local boatDestroyedAtSea = false
        local playerBoat = nil
        local currentWeaponIndex = 1
        local lastWeaponSwitchTime = os.clock()

        while S.AutoFarmSeaEventsEnabled do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")

            if not hum or hum.Health <= 0 or not myRoot then
                task.wait(0.5)
            else
                -- 1. Xử lý khi nhân vật hồi sinh hoặc thay đổi
                if char ~= lastCharacter then
                    lastCharacter = char
                    needBuyNewBoat = true
                    boatDestroyedAtSea = false
                    DisconnectConnection("seaEventsBoatFly")
                    if ActiveBoat then
                        Utility.ForceStopBoat(ActiveBoat)
                        ActiveBoat = nil
                    end
                end

                -- 2. Quét danh sách các mục tiêu Sea Event đã chọn còn sống
                local seaTargets = Utility.GetActiveSeaEventTargets()

                -- [TRƯỜNG HỢP A]: CÒN KẺ ĐỊCH ĐANG TỒN TẠI (#seaTargets > 0)
                -- TUYỆT ĐỐI KHÔNG MUA THUYỀN, KHÔNG RESET, TẬP TRUNG 100% TẤN CÔNG DIỆT QUÁI
                if #seaTargets > 0 then
                    DisconnectConnection("seaEventsBoatFly")

                    -- Theo dõi nếu thuyền bị quái đánh nổ trong lúc giao tranh
                    if playerBoat and playerBoat.Parent then
                        local boatHp = playerBoat:FindFirstChild("Humanoid")
                        if boatHp and (boatHp:IsA("IntValue") or boatHp:IsA("NumberValue")) and boatHp.Value <= 0 then
                            boatDestroyedAtSea = true
                        end
                    elseif not needBuyNewBoat then
                        boatDestroyedAtSea = true
                    end

                    -- Rời khỏi ghế lái nếu đang ngồi để bay tới tấn công
                    if hum.SeatPart or hum.Sit then
                        hum.Sit = false
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                        task.wait(0.05)
                    end

                    -- Dừng thuyền tại chỗ nếu thuyền còn tồn tại
                    if playerBoat and playerBoat.Parent then
                        local vSeat = playerBoat:FindFirstChildOfClass("VehicleSeat") or playerBoat:FindFirstChild("VehicleSeat", true)
                        if vSeat then
                            local att = vSeat:FindFirstChild("FlyAttachment") or Instance.new("Attachment")
                            att.Name = "FlyAttachment"; att.Parent = vSeat

                            local lv = vSeat:FindFirstChild("FlyLinearVelocity") or Instance.new("LinearVelocity")
                            lv.Name = "FlyLinearVelocity"; lv.Attachment0 = att
                            lv.MaxForce = math.huge; lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.Parent = vSeat

                            local ao = vSeat:FindFirstChild("FlyAlignOrientation") or Instance.new("AlignOrientation")
                            ao.Name = "FlyAlignOrientation"; ao.Attachment0 = att
                            ao.MaxTorque = math.huge; ao.Responsiveness = 200
                            ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; ao.Parent = vSeat

                            lv.VectorVelocity = Vector3.zero
                        end
                    end

                    -- Quản lý đổi vũ khí định kỳ 2 giây nếu chọn từ 2 vũ khí trở lên
                    local wList = (type(S.SeaEventsWeapons) == "table" and #S.SeaEventsWeapons > 0) and S.SeaEventsWeapons or ((S.SeaEventsWeapon and S.SeaEventsWeapon ~= "" and S.SeaEventsWeapon ~= "None") and { S.SeaEventsWeapon } or {})
                    local wType = ""
                    if #wList >= 2 then
                        if os.clock() - lastWeaponSwitchTime >= 2.0 then
                            currentWeaponIndex = (currentWeaponIndex % #wList) + 1
                            lastWeaponSwitchTime = os.clock()
                            local nextW = wList[currentWeaponIndex]
                            Utility.EquipWeaponByType(nextW)
                        end
                        wType = wList[currentWeaponIndex] or ""
                    elseif #wList == 1 then
                        currentWeaponIndex = 1
                        wType = wList[1] or ""
                    else
                        wType = ""
                    end
                    S.SeaEventsWeapon = wType

                    -- Tấn công mục tiêu gần nhất
                    local bestTarget = seaTargets[1]
                    local tModel = bestTarget.Model
                    local tRoot = bestTarget.Root
                    local tType = bestTarget.Type

                    if tModel and tModel.Parent and tRoot then
                        local basePos = tRoot.Position

                        if tType == "Terrorshark" and terrorsharkDodgeActive and os.clock() < terrorsharkDodgeEndTime then
                            -- Né chiêu Terrorshark: bay lên Y = 500 với tốc độ 200
                            local dodgePos = Vector3.new(basePos.X, 500, basePos.Z)
                            Utility.PhysicsFlyTo(dodgePos, 200)
                        elseif tType == "Sea Beast" then
                            -- Tấn công Sea Beast: bay đến độ cao 150 studs so với humanoid và luôn đảm bảo cao hơn Y = 30
                            terrorsharkDodgeActive = false
                            local sbAttackY = math.max(30, basePos.Y + 150)
                            local attackPos = Vector3.new(basePos.X, sbAttackY, basePos.Z)
                            Utility.PhysicsFlyTo(attackPos, S.TeleportFlySpeed or 200)
                        else
                            -- Tấn công các quái Sea Event khác: mặc định 40 studs (Gun 200 studs), luôn đảm bảo không thấp hơn Y = 30
                            terrorsharkDodgeActive = false
                            local baseAttackHeight = (wType == "Gun") and 200 or 40
                            local attackY = math.max(30, basePos.Y + baseAttackHeight)
                            local attackPos = Vector3.new(basePos.X, attackY, basePos.Z)
                            Utility.PhysicsFlyTo(attackPos, S.TeleportFlySpeed or 200)
                        end

                        if wType == "Melee" then
                            Utility.AttackMelee(tModel, tRoot)
                        elseif wType == "Sword" then
                            Utility.AttackSword(tModel, tRoot)
                        elseif wType == "Fruit" then
                            Utility.AttackFruitM1(tModel, tRoot)
                        elseif wType == "Gun" then
                            Utility.AttackGun(tModel, tRoot)
                        end

                        if S.AutoFarmSeaEventsSkills and wType ~= "" then
                            if wType == "Melee" then
                                Utility.CastSkillsMelee(basePos, tModel)
                            elseif wType == "Sword" then
                                Utility.CastSkillsSword(basePos, tModel)
                            elseif wType == "Fruit" then
                                Utility.CastSkillsFruit(basePos, tModel)
                            elseif wType == "Gun" then
                                Utility.CastSkillsGun(basePos, tModel)
                            end
                        end
                    end

                -- [TRƯỜNG HỢP B]: ĐÃ TIÊU DIỆT HẾT KẺ ĐỊCH (#seaTargets == 0)
                else
                    local selBoatName = S.SeaEventsBoat or "Guardian"

                    -- Nếu thuyền bị nổ ngoài biển trong lúc đánh quái VÀ hiện tại đã diệt sạch quái: Reset nhân vật về bến 1 lần
                    if boatDestroyedAtSea then
                        boatDestroyedAtSea = false
                        playerBoat = nil
                        ActiveBoat = nil
                        needBuyNewBoat = true
                        DisconnectConnection("seaEventsBoatFly")
                        Utility.StopPhysicsFly()
                        UILib.Notify("Sea Events", "Boat destroyed & all enemies defeated! Respawning...", 3)
                        Utility.RespawnPlayer()
                        task.wait(3)
                        continue
                    end

                    -- Nếu chưa có thuyền (vừa hồi sinh hoặc đang ở đảo): Tiến hành mua thuyền
                    if needBuyNewBoat then
                        UILib.Notify("Sea Events", "Buying boat " .. selBoatName .. "...", 3)
                        Utility.BuyBoat(selBoatName)

                        local tBuy = os.clock()
                        while S.AutoFarmSeaEventsEnabled and (os.clock() - tBuy < 6) do
                            playerBoat = Utility.GetPlayerBoat(selBoatName)
                            if playerBoat and playerBoat.Parent then
                                needBuyNewBoat = false
                                boatDestroyedAtSea = false
                                break
                            end
                            task.wait(0.5)
                        end
                    else
                        playerBoat = Utility.GetPlayerBoat(selBoatName)
                        if not playerBoat or not playerBoat.Parent then
                            needBuyNewBoat = true
                        end
                    end

                    -- Nếu thuyền còn sống và không có quái: Ngồi vào ghế lái và tiếp tục bay tuần tra tìm quái
                    if playerBoat and playerBoat.Parent then
                        ActiveBoat = playerBoat
                        local vSeat = playerBoat:FindFirstChildOfClass("VehicleSeat") or playerBoat:FindFirstChild("VehicleSeat", true)

                        if vSeat then
                            if hum.SeatPart ~= vSeat then
                                DisconnectConnection("seaEventsBoatFly")
                                Utility.SitVehicleSeat(playerBoat)
                            end

                            if hum.SeatPart == vSeat then
                                if FlyActive then Utility.StopPhysicsFly() end

                                -- Kích hoạt luồng bay tìm quái Sea Events
                                if not _conns["seaEventsBoatFly"] or ActiveBoat ~= playerBoat then
                                    Utility.StartSeaEventsBoatFlight(playerBoat)
                                end
                            end
                        end
                    end
                end
            end

            task.wait(0.08)
        end

        DisconnectConnection("seaEventsBoatFly")
        Utility.StopPhysicsFly()
        if ActiveBoat then Utility.ForceStopBoat(ActiveBoat) end
    end)
end

--[[ Dừng vòng lặp Auto Farm Sea Events ]]
function Utility.StopAutoFarmSeaEvents()
    DisconnectConnection("autoFarmSeaEvents")
    DisconnectConnection("seaEventsBoatFly")
    DisconnectConnection("terrorsharkBodyMover")
    Utility.UpdatePlayerNoClipState()
    Utility.StopPhysicsFly()
    if ActiveBoat then
        Utility.ForceStopBoat(ActiveBoat)
    end
end

-- ═══════════════════════════════════════════════════════════
--  AUTO FARM MODULAR FUNCTIONS (1 -> 12)
-- ═══════════════════════════════════════════════════════════

--[[ 1. Duyệt tìm kẻ địch còn sống trong thư mục enemy (workspace.Enemies, SeaBeasts, Raids) ]]
function Utility.GetNearestEnemyFromFolder()
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    local seaBeasts = workspace:FindFirstChild("SeaBeasts")
    local raidsFolder = workspace:FindFirstChild("Raids")
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local nearest = nil
    local minDist = math.huge

    local function CheckEnemy(enemy)
        if not enemy or not enemy:IsA("Model") then return end
        if enemy == myChar then return end
        if Players:GetPlayerFromCharacter(enemy) then return end
        if Players:FindFirstChild(enemy.Name) then return end
        if enemy:FindFirstChild("PlayerGui") then return end

        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChild("Head") or enemy:FindFirstChildOfClass("BasePart")
        if hum and root and hum.Health > 0 then
            local dist = (root.Position - myRoot.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = enemy
            end
        end
    end

    if enemiesFolder then
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do CheckEnemy(enemy) end
    end
    if seaBeasts then
        for _, enemy in ipairs(seaBeasts:GetChildren()) do CheckEnemy(enemy) end
    end
    if raidsFolder then
        for _, enemy in ipairs(raidsFolder:GetChildren()) do CheckEnemy(enemy) end
    end

    return nearest
end
Utility.GetNearestEnemy = Utility.GetNearestEnemyFromFolder

--[[ 2. Lấy vị trí CFrame của HumanoidRootPart ]]
function Utility.GetEnemyRootCFrame(enemy)
    if not enemy then return nil, nil, nil end
    local root = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")
    if not root then return nil, nil, nil end
    return root.CFrame, root.Position, root
end

--[[ 3. Bay đến vị trí cao hơn CFrame mục tiêu (Mặc định 30 đơn vị) ]]
function Utility.FlyAboveTarget(enemyCFrame, heightOffset, flySpeed)
    local basePos = typeof(enemyCFrame) == "CFrame" and enemyCFrame.Position or (typeof(enemyCFrame) == "Vector3" and enemyCFrame or (enemyCFrame and enemyCFrame.Position or Vector3.zero))
    local height = heightOffset or S.AttackHeight or 30
    local targetPos = basePos + Vector3.new(0, height, 0)
    Utility.PhysicsFlyTo(targetPos, flySpeed or S.TeleportFlySpeed or 180)
end

--[[ Equip weapon tool by selected category from Backpack or Character ]]
function Utility.EquipWeaponByType(category)
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:FindFirstChild("Backpack")
    local targetType = category or S.SelectedWeaponType or "Melee"

    local function MatchesType(tool)
        if not tool or not tool:IsA("Tool") then return false end
        local tip = tostring(tool.ToolTip or ""):lower()
        local name = tool.Name:lower()

        if targetType == "Melee" then
            return tip:find("melee") or tool:FindFirstChild("Combat") or name:find("combat") or name:find("talon") or name:find("karate") or name:find("superhuman") or name:find("godhuman") or name:find("electric") or name:find("death step") or name:find("dark step") or name:find("dragon breath") or name:find("sanguine") or name:find("water kung fu") or name:find("sharkman")
        elseif targetType == "Sword" then
            return tip:find("sword") or name:find("blade") or name:find("katana") or name:find("saber") or name:find("pole") or name:find("scythe") or name:find("cutlass") or name:find("dagger") or name:find("sword") or name:find("triple") or name:find("yoru") or name:find("cursed") or name:find("hallow") or name:find("tushita") or name:find("yama") or name:find("anchor")
        elseif targetType == "Fruit" then
            return tip:find("fruit") or tip:find("blox fruit") or tool:FindFirstChild("LeftClickRemote") or name:find("-") or tool:FindFirstChild("Fruit")
        elseif targetType == "Gun" then
            return tip:find("gun") or name:find("gun") or name:find("rifle") or name:find("guitar") or name:find("bow") or name:find("cannon") or name:find("slingshot") or name:find("blaster") or name:find("pistol") or name:find("musket") or name:find("kabucha") or name:find("bizarre") or name:find("serpent") or name:find("acidum")
        elseif targetType == "Dragonstorm" or targetType == "Dragon Storm" then
            return name:find("dragonstorm") or name:find("dragon storm") or name:find("dragon's storm") or name:find("dragon") or tip:find("dragon")
        end
        return false
    end

    -- Check currently equipped in Character
    for _, item in ipairs(char:GetChildren()) do
        if MatchesType(item) then
            return item
        end
    end

    -- Check Backpack and equip
    if bp and hum then
        for _, item in ipairs(bp:GetChildren()) do
            if MatchesType(item) then
                hum:EquipTool(item)
                return item
            end
        end
    end

    -- Fallback: Return currently equipped tool or first tool in Backpack
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped then return equipped end
    if bp and hum then
        local firstTool = bp:FindFirstChildOfClass("Tool")
        if firstTool then
            hum:EquipTool(firstTool)
            return firstTool
        end
    end
    return nil
end

--[[ 4. Thực hiện tấn công bằng Melee ]]
function Utility.AttackMelee(enemy, enemyRoot)
    local tool = Utility.EquipWeaponByType("Melee")
    local eRoot = enemyRoot or (enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart))
    local eHead = enemy and enemy:FindFirstChild("Head")
    if not eRoot then return end

    local rep = game:GetService("ReplicatedStorage")
    local net = rep:FindFirstChild("Modules") and rep.Modules:FindFirstChild("Net")
    local regAttack = net and net:FindFirstChild("RE/RegisterAttack")
    local regHit = net and net:FindFirstChild("RE/RegisterHit")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        local cfModule = ps and ps:FindFirstChild("CombatFramework")
        if cfModule then
            local cf = require(cfModule)
            if cf and cf.activeController then
                local ctrl = cf.activeController
                ctrl.timeToNextAttack = 0
                ctrl:attack()
            end
        end
    end)

    if tool then pcall(function() tool:Activate() end) end

    if regAttack and regAttack:IsA("RemoteEvent") then
        pcall(function() regAttack:FireServer(0) end)
        pcall(function() regAttack:FireServer(0.1) end)
    end
    if regHit and regHit:IsA("RemoteEvent") then
        local hitArray1 = { [1] = { [1] = eRoot, [2] = eRoot } }
        local hitArray2 = { [1] = { [1] = eHead or eRoot, [2] = eRoot } }
        pcall(function() regHit:FireServer(eRoot, hitArray1) end)
        pcall(function() regHit:FireServer(eRoot, hitArray2) end)
        pcall(function() regHit:FireServer(eRoot, { eRoot, eHead or eRoot }) end)
    end
    if commF and commF:IsA("RemoteFunction") then
        pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
    end
end

--[[ 5. Thực hiện tấn công bằng Sword ]]
function Utility.AttackSword(enemy, enemyRoot)
    local tool = Utility.EquipWeaponByType("Sword")
    local eRoot = enemyRoot or (enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart))
    local eHead = enemy and enemy:FindFirstChild("Head")
    if not eRoot then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")

    local rep = game:GetService("ReplicatedStorage")
    local net = rep:FindFirstChild("Modules") and rep.Modules:FindFirstChild("Net")
    local regAttack = net and net:FindFirstChild("RE/RegisterAttack")
    local regHit = net and net:FindFirstChild("RE/RegisterHit")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        local cfModule = ps and ps:FindFirstChild("CombatFramework")
        if cfModule then
            local cf = require(cfModule)
            if cf and cf.activeController then
                local ctrl = cf.activeController
                ctrl.timeToNextAttack = 0
                ctrl:attack()
            end
        end
    end)

    if tool then
        pcall(function() tool:Activate() end)
        local lcr = tool:FindFirstChild("LeftClickRemote")
        if lcr and lcr:IsA("RemoteEvent") and myRoot then
            pcall(function() lcr:FireServer((eRoot.Position - myRoot.Position).Unit, 1, true, eRoot.Position) end)
        end
    end

    if regAttack and regAttack:IsA("RemoteEvent") then
        pcall(function() regAttack:FireServer(0) end)
        pcall(function() regAttack:FireServer(0.1) end)
    end
    if regHit and regHit:IsA("RemoteEvent") then
        local hitArray1 = { [1] = { [1] = eRoot, [2] = eRoot } }
        local hitArray2 = { [1] = { [1] = eHead or eRoot, [2] = eRoot } }
        pcall(function() regHit:FireServer(eRoot, hitArray1) end)
        pcall(function() regHit:FireServer(eRoot, hitArray2) end)
        pcall(function() regHit:FireServer(eRoot, { eRoot, eHead or eRoot }) end)
    end
    if commF and commF:IsA("RemoteFunction") then
        pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
    end
end

local fruitM1ComboIndex = 1

--[[ Giải phóng trạng thái giữ chiêu (Release hold) & Reset công cụ khi dừng farm để tránh kẹt vũ khí ]]
function Utility.ReleaseAllHeldSkills()
    local char = LocalPlayer.Character
    if not char then return end
    local VIM = game:GetService("VirtualInputManager")
    for _, k in ipairs({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V, Enum.KeyCode.F }) do
        pcall(function() VIM:SendKeyEvent(false, k, false, game) end)
    end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            local tr = item:FindFirstChild("RemoteEvent") or item:FindFirstChildOfClass("RemoteEvent")
            if tr then
                pcall(function() tr:FireServer(false) end)
                pcall(function() tr:FireServer(false, Vector3.zero) end)
            end
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, child in ipairs(hum:GetChildren()) do
            if child:IsA("RemoteFunction") then
                for _, key in ipairs({ "Z", "X", "C", "V", "F" }) do
                    pcall(function() child:InvokeServer(key, "KeyUp") end)
                    pcall(function() child:InvokeServer(key, false) end)
                end
            end
        end
        local curTool = char:FindFirstChildOfClass("Tool")
        if curTool then
            hum:UnequipTools()
            task.wait(0.05)
            hum:EquipTool(curTool)
        end
    end
end

--[[ 6. Thực hiện tấn công bằng M1 của Fruit ]]
function Utility.AttackFruitM1(enemy, enemyRoot)
    local tool = Utility.EquipWeaponByType("Fruit")
    local eRoot = enemyRoot or (enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")))
    local eHead = enemy and enemy:FindFirstChild("Head")
    if not eRoot then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local myPos = myRoot.Position
    local targetPos = eRoot.Position

    -- Xoay nhân vật hướng thẳng về phía mục tiêu
    local flatTarget = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
    if (flatTarget - myPos).Magnitude > 0.1 then
        myRoot.CFrame = CFrame.lookAt(myPos, flatTarget)
    end

    local diff = (targetPos - myPos)
    local aim3D = (diff.Magnitude > 0) and diff.Unit or Vector3.new(0, -1, 0)
    local aimFlat = Vector3.new(diff.X, 0, diff.Z)
    local aimHorizontal = (aimFlat.Magnitude > 0) and aimFlat.Unit or aim3D

    local combo = fruitM1ComboIndex
    fruitM1ComboIndex = (fruitM1ComboIndex % 4) + 1

    -- Bắn trực tiếp LeftClickRemote với combo 1..4 và vector hướng chuẩn
    if tool then
        pcall(function() tool:Activate() end)
        local lcr = tool:FindFirstChild("LeftClickRemote") or tool:FindFirstChild("LeftClickRemote", true)
        if lcr and lcr:IsA("RemoteEvent") then
            pcall(function() lcr:FireServer(aimHorizontal, combo, true, targetPos) end)
            pcall(function() lcr:FireServer(aim3D, combo, true, targetPos) end)
        end
    end

    -- Kích hoạt CombatFramework
    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        local cfModule = ps and ps:FindFirstChild("CombatFramework")
        if cfModule then
            local cf = require(cfModule)
            if cf and cf.activeController then
                local ctrl = cf.activeController
                ctrl.timeToNextAttack = 0
                ctrl:attack()
            end
        end
    end)

    -- Gửi RegisterAttack và RegisterHit lên server gây sát thương
    local rep = game:GetService("ReplicatedStorage")
    local net = rep:FindFirstChild("Modules") and rep.Modules:FindFirstChild("Net")
    local regAttack = net and net:FindFirstChild("RE/RegisterAttack")
    local regHit = net and net:FindFirstChild("RE/RegisterHit")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

    if regAttack and regAttack:IsA("RemoteEvent") then
        pcall(function() regAttack:FireServer(0) end)
        pcall(function() regAttack:FireServer(0.1) end)
    end
    if regHit and regHit:IsA("RemoteEvent") then
        local hitArray1 = { [1] = { [1] = eRoot, [2] = eRoot } }
        local hitArray2 = { [1] = { [1] = eHead or eRoot, [2] = eRoot } }
        pcall(function() regHit:FireServer(eRoot, hitArray1) end)
        pcall(function() regHit:FireServer(eRoot, hitArray2) end)
        pcall(function() regHit:FireServer(eRoot, { eRoot, eHead or eRoot }) end)
    end
    if commF and commF:IsA("RemoteFunction") then
        pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
    end
end

local lastGunClickTime = 0

--[[ 7. Thực hiện tấn công bằng Gun (VIM click ngoài màn hình mỗi 1s, xả 6 hit sát thương) ]]
function Utility.AttackGun(enemy, enemyRoot)
    local tool = Utility.EquipWeaponByType("Gun")
    local eRoot = enemyRoot or (enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart))
    local eHead = enemy and enemy:FindFirstChild("Head")
    if not eRoot then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.zero
    local targetPos = eRoot.Position

    local rep = game:GetService("ReplicatedStorage")
    local net = rep:FindFirstChild("Modules") and rep.Modules:FindFirstChild("Net")
    local shootGunEvent = net and net:FindFirstChild("RE/ShootGunEvent")
    local regAttack = net and net:FindFirstChild("RE/RegisterAttack")
    local regHit = net and net:FindFirstChild("RE/RegisterHit")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

    -- 1. Kích hoạt VirtualInputManager tại vị trí (0, 0) trên màn hình mỗi 1s
    if tick() - lastGunClickTime >= 1 then
        lastGunClickTime = tick()
        if tool then
            pcall(function() tool:Activate() end)
        end
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.delay(0.001, function()
                pcall(function()
                    vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end)
            end)
        end)
    end

    -- 2. Gây 6 đợt sát thương trực tiếp siêu tốc
    local hitArray1 = { [1] = { [1] = eRoot, [2] = eRoot } }
    local hitArray2 = { [1] = { [1] = eHead or eRoot, [2] = eRoot } }

    for i = 1, 6 do
        if shootGunEvent and shootGunEvent:IsA("RemoteEvent") then
            pcall(function() shootGunEvent:FireServer(targetPos, { eRoot }) end)
            pcall(function() shootGunEvent:FireServer(targetPos, {}) end)
            pcall(function() shootGunEvent:FireServer(targetPos, { eHead or eRoot }) end)
        end

        if regAttack and regAttack:IsA("RemoteEvent") then
            pcall(function() regAttack:FireServer(0) end)
            pcall(function() regAttack:FireServer(0.1) end)
        end

        if regHit and regHit:IsA("RemoteEvent") then
            pcall(function() regHit:FireServer(eRoot, hitArray1) end)
            pcall(function() regHit:FireServer(eRoot, hitArray2) end)
            pcall(function() regHit:FireServer(eRoot, { eRoot, eHead or eRoot }) end)
        end
    end

    if commF and commF:IsA("RemoteFunction") then
        pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
    end
end

--[[ Thực hiện tấn công bằng Dragonstorm (Tool activation & bão rồng siêu tốc) ]]
function Utility.AttackDragonstorm(enemy, enemyRoot)
    local tool = Utility.EquipWeaponByType("Dragonstorm")
    local eRoot = enemyRoot or (enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")))
    local eHead = enemy and enemy:FindFirstChild("Head")
    if not eRoot then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local targetPos = eRoot.Position

    if myRoot then
        local flatTarget = Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z)
        if (flatTarget - myRoot.Position).Magnitude > 0.1 then
            myRoot.CFrame = CFrame.lookAt(myRoot.Position, flatTarget)
        end
    end

    local rep = game:GetService("ReplicatedStorage")
    local net = rep:FindFirstChild("Modules") and rep.Modules:FindFirstChild("Net")
    local shootGunEvent = net and net:FindFirstChild("RE/ShootGunEvent")
    local regAttack = net and net:FindFirstChild("RE/RegisterAttack")
    local regHit = net and net:FindFirstChild("RE/RegisterHit")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

    -- 1. Kích hoạt chuột qua VirtualInputManager
    if tick() - lastGunClickTime >= 0.5 then
        lastGunClickTime = tick()
        if tool then
            pcall(function() tool:Activate() end)
            local lcr = tool:FindFirstChild("LeftClickRemote") or tool:FindFirstChild("LeftClickRemote", true)
            if lcr and lcr:IsA("RemoteEvent") and myRoot then
                pcall(function() lcr:FireServer((targetPos - myRoot.Position).Unit, 1, true, targetPos) end)
            end
        end
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.delay(0.001, function()
                pcall(function()
                    vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end)
            end)
        end)
    end

    -- 2. Gây đa tầng sát thương trực tiếp lên Leviathan
    local hitArray1 = { [1] = { [1] = eRoot, [2] = eRoot } }
    local hitArray2 = { [1] = { [1] = eHead or eRoot, [2] = eRoot } }

    for i = 1, 8 do
        if shootGunEvent and shootGunEvent:IsA("RemoteEvent") then
            pcall(function() shootGunEvent:FireServer(targetPos, { eRoot }) end)
            pcall(function() shootGunEvent:FireServer(targetPos, {}) end)
            pcall(function() shootGunEvent:FireServer(targetPos, { eHead or eRoot }) end)
        end

        if regAttack and regAttack:IsA("RemoteEvent") then
            pcall(function() regAttack:FireServer(0) end)
            pcall(function() regAttack:FireServer(0.1) end)
        end

        if regHit and regHit:IsA("RemoteEvent") then
            pcall(function() regHit:FireServer(eRoot, hitArray1) end)
            pcall(function() regHit:FireServer(eRoot, hitArray2) end)
            pcall(function() regHit:FireServer(eRoot, { eRoot, eHead or eRoot }) end)
        end
    end

    if commF and commF:IsA("RemoteFunction") then
        pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
    end
end

--[[ 8. Định hướng chiêu thức đến mục tiêu ]]
function Utility.AimTarget(targetPosition)
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.zero

    local downTargetPos = Vector3.new(myPos.X, -100, myPos.Z)
    local downAimCF = CFrame.lookAt(myPos, downTargetPos)
    local downHitCF = CFrame.new(downTargetPos)
    local downDir = Vector3.new(0, -1, 0)

    if myRoot and targetPosition then
        local flatTarget = Vector3.new(targetPosition.X, myPos.Y, targetPosition.Z)
        if (flatTarget - myPos).Magnitude > 0.5 then
            myRoot.CFrame = CFrame.lookAt(myPos, flatTarget)
        end
    end

    return downTargetPos, downAimCF, downHitCF, downDir
end

--[[ 9. Thi triển kỹ năng cho Melee (Z, X, C) tự động Aim liên tục vào mục tiêu & kết hợp đánh thường ]]
function Utility.CastSkillsMelee(targetPosition, enemy)
    local tool = Utility.EquipWeaponByType("Melee")
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not myRoot then return end

    local enemyPart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))
    local aimPos = enemyPart and enemyPart.Position or targetPosition
    if not aimPos then return end

    -- Xoay nhân vật hướng về phía mục tiêu
    myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(aimPos.X, myRoot.Position.Y, aimPos.Z))

    local toolRemote = tool and (tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent"))
    local skillRemotes = {}
    for _, child in ipairs(hum:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end

    local skillKeys = {}
    if S.MeleeSkillZ then table.insert(skillKeys, "Z") end
    if S.MeleeSkillX then table.insert(skillKeys, "X") end
    if S.MeleeSkillC then table.insert(skillKeys, "C") end

    for _, key in ipairs(skillKeys) do
        if not char.Parent or not hum or hum.Health <= 0 then break end

        local curPart = (enemy and enemy.Parent and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))) or enemyPart
        local currentTargetPos = (curPart and curPart.Position) or targetPosition
        local myPos = myRoot.Position
        local aimCF = CFrame.lookAt(myPos, currentTargetPos)
        local hitCF = curPart and curPart.CFrame or CFrame.new(currentTargetPos)

        -- 1. Kích hoạt chiêu thức Melee
        for _, rf in ipairs(skillRemotes) do
            task.spawn(function()
                pcall(function() rf:InvokeServer(key, aimCF, hitCF, "Aaa") end)
            end)
        end

        -- 2. Liên tục cập nhật tọa độ Aim Vector3 và đồng thời đánh thường gây sát thương
        local duration = S.HoldMeleeSkills and (S.SkillHoldDuration or 0.35) or 0.05
        local t0 = os.clock()
        while os.clock() - t0 < duration do
            if not char.Parent or not hum or hum.Health <= 0 then break end
            local livePart = (enemy and enemy.Parent and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))) or enemyPart
            local livePos = livePart and livePart.Position or currentTargetPos

            if toolRemote then
                pcall(function() toolRemote:FireServer(livePos) end)
            end
            Utility.AttackMelee(enemy, livePart)
            task.wait(0.035)
        end

        task.wait(0.12)
    end
end

--[[ 10. Thi triển kỹ năng cho Fruit (Z, X, C, V, F) tự động Aim liên tục vào mục tiêu & kết hợp đánh thường ]]
function Utility.CastSkillsFruit(targetPosition, enemy)
    local tool = Utility.EquipWeaponByType("Fruit")
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not myRoot then return end

    local enemyPart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))
    local aimPos = enemyPart and enemyPart.Position or targetPosition
    if not aimPos then return end

    -- Xoay nhân vật hướng về phía mục tiêu
    myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(aimPos.X, myRoot.Position.Y, aimPos.Z))

    local toolRemote = tool and (tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent"))
    local skillRemotes = {}
    for _, child in ipairs(hum:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end

    local skillKeys = {}
    if S.FruitSkillZ then table.insert(skillKeys, "Z") end
    if S.FruitSkillX then table.insert(skillKeys, "X") end
    if S.FruitSkillC then table.insert(skillKeys, "C") end
    if S.FruitSkillV then table.insert(skillKeys, "V") end
    if S.FruitSkillF then table.insert(skillKeys, "F") end

    for _, key in ipairs(skillKeys) do
        if not char.Parent or not hum or hum.Health <= 0 then break end

        local curPart = (enemy and enemy.Parent and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))) or enemyPart
        local currentTargetPos = (curPart and curPart.Position) or targetPosition

        -- 1. Kích hoạt chiêu thức Fruit
        for _, rf in ipairs(skillRemotes) do
            task.spawn(function()
                pcall(function() rf:InvokeServer(key) end)
            end)
        end

        -- 2. Liên tục cập nhật tọa độ Aim Vector3 và đồng thời đánh thường M1 Fruit
        local duration = S.HoldFruitSkills and (S.SkillHoldDuration or 0.35) or 0.05
        local t0 = os.clock()
        while os.clock() - t0 < duration do
            if not char.Parent or not hum or hum.Health <= 0 then break end
            local livePart = (enemy and enemy.Parent and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))) or enemyPart
            local livePos = livePart and livePart.Position or currentTargetPos

            if toolRemote then
                pcall(function() toolRemote:FireServer(livePos) end)
            end
            Utility.AttackFruitM1(enemy, livePart)
            task.wait(0.035)
        end

        task.wait(0.12)
    end
end

--[[ 11. Thi triển kỹ năng cho Sword (Z, X) tự động Aim liên tục vào mục tiêu & kết hợp đánh thường ]]
function Utility.CastSkillsSword(targetPosition, enemy)
    local tool = Utility.EquipWeaponByType("Sword")
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not myRoot then return end

    local enemyPart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))
    local aimPos = enemyPart and enemyPart.Position or targetPosition
    if not aimPos then return end

    -- Xoay nhân vật hướng về phía mục tiêu
    myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(aimPos.X, myRoot.Position.Y, aimPos.Z))

    local toolRemote = tool and (tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent"))
    local skillRemotes = {}
    for _, child in ipairs(hum:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end

    local skillKeys = {}
    if S.SwordSkillZ then table.insert(skillKeys, "Z") end
    if S.SwordSkillX then table.insert(skillKeys, "X") end

    for _, key in ipairs(skillKeys) do
        if not char.Parent or not hum or hum.Health <= 0 then break end

        local curPart = (enemy and enemy.Parent and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))) or enemyPart
        local currentTargetPos = (curPart and curPart.Position) or targetPosition

        -- 1. Kích hoạt chiêu thức Sword
        for _, rf in ipairs(skillRemotes) do
            task.spawn(function()
                pcall(function() rf:InvokeServer(key, currentTargetPos) end)
            end)
        end

        -- 2. Liên tục cập nhật tọa độ Aim Vector3 và đồng thời chém thường Sword
        local duration = S.HoldSwordSkills and (S.SkillHoldDuration or 0.35) or 0.05
        local t0 = os.clock()
        while os.clock() - t0 < duration do
            if not char.Parent or not hum or hum.Health <= 0 then break end
            local livePart = (enemy and enemy.Parent and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))) or enemyPart
            local livePos = livePart and livePart.Position or currentTargetPos

            if toolRemote then
                pcall(function() toolRemote:FireServer(livePos) end)
            end
            Utility.AttackSword(enemy, livePart)
            task.wait(0.035)
        end

        task.wait(0.12)
    end
end

--[[ 12. Thi triển kỹ năng cho Gun (Z, X) tự động Aim liên tục vào mục tiêu & kết hợp đánh thường ]]
function Utility.CastSkillsGun(targetPosition, enemy)
    local tool = Utility.EquipWeaponByType("Gun")
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not myRoot then return end

    local enemyPart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))
    local aimPos = enemyPart and enemyPart.Position or targetPosition
    if not aimPos then return end

    -- Xoay nhân vật hướng về phía mục tiêu
    myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(aimPos.X, myRoot.Position.Y, aimPos.Z))

    local toolRemote = tool and (tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent"))
    local skillRemotes = {}
    for _, child in ipairs(hum:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end

    local skillKeys = {}
    if S.GunSkillZ then table.insert(skillKeys, "Z") end
    if S.GunSkillX then table.insert(skillKeys, "X") end

    for _, key in ipairs(skillKeys) do
        if not char.Parent or not hum or hum.Health <= 0 then break end

        local curPart = (enemy and enemy.Parent and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))) or enemyPart
        local currentTargetPos = (curPart and curPart.Position) or targetPosition

        -- 1. Kích hoạt chiêu thức Gun
        for _, rf in ipairs(skillRemotes) do
            task.spawn(function()
                pcall(function() rf:InvokeServer(key) end)
            end)
        end

        -- 2. Liên tục cập nhật tọa độ Aim Vector3 và đồng thời xả đạn thường Gun
        local duration = S.HoldGunSkills and (S.SkillHoldDuration or 0.35) or 0.05
        local t0 = os.clock()
        while os.clock() - t0 < duration do
            if not char.Parent or not hum or hum.Health <= 0 then break end
            local livePart = (enemy and enemy.Parent and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))) or enemyPart
            local livePos = livePart and livePart.Position or currentTargetPos

            if toolRemote then
                pcall(function() toolRemote:FireServer(livePos) end)
            end
            Utility.AttackGun(enemy, livePart)
            task.wait(0.035)
        end

        task.wait(0.12)
    end
end

--[[ Start auto attack nearest enemy routine ]]
function Utility.StartAutoAttackNearestEnemy()
    DisconnectConnection("autoAttackEnemyLoop")
    _conns["autoAttackEnemyLoop"] = task.spawn(function()
        while S.AutoAttackEnemyEnabled do
            local enemy = Utility.GetNearestEnemyFromFolder()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if enemy and root and hum and hum.Health > 0 then
                local eHum = enemy:FindFirstChildOfClass("Humanoid")
                local eCF, ePos, eRoot = Utility.GetEnemyRootCFrame(enemy)

                if eRoot and eHum and eHum.Health > 0 then
                    -- 3. Bay đến độ cao mục tiêu (mặc định 30 studs)
                    Utility.FlyAboveTarget(eCF, S.AttackHeight or 30, S.TeleportFlySpeed or 180)

                    local wType = S.SelectedWeaponType or "Melee"
                    if wType == "Melee" then
                        Utility.AttackMelee(enemy, eRoot)
                    elseif wType == "Sword" then
                        Utility.AttackSword(enemy, eRoot)
                    elseif wType == "Fruit" then
                        Utility.AttackFruitM1(enemy, eRoot)
                    elseif wType == "Gun" then
                        Utility.AttackGun(enemy, eRoot)
                    end

                    if S.AutoFarmUseSkills then
                        if wType == "Melee" then
                            Utility.CastSkillsMelee(ePos, enemy)
                        elseif wType == "Fruit" then
                            Utility.CastSkillsFruit(ePos, enemy)
                        elseif wType == "Sword" then
                            Utility.CastSkillsSword(ePos, enemy)
                        elseif wType == "Gun" then
                            Utility.CastSkillsGun(ePos, enemy)
                        end
                    end
                end
            else
                Utility.StopPhysicsFly()
            end
            task.wait(0.035)
        end
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop auto attack nearest enemy routine ]]
function Utility.StopAutoAttackNearestEnemy()
    DisconnectConnection("autoAttackEnemyLoop")
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

--[[ Start auto farm nearest enemy with skills routine ]]
function Utility.StartAutoFarmWithSkills()
    DisconnectConnection("autoFarmSkills")
    _conns["autoFarmSkills"] = task.spawn(function()
        while S.AutoFarmWithSkillsEnabled do
            local enemy = Utility.GetNearestEnemyFromFolder()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if enemy and root and hum and hum.Health > 0 then
                local eHum = enemy:FindFirstChildOfClass("Humanoid")
                local eCF, ePos, eRoot = Utility.GetEnemyRootCFrame(enemy)

                if eRoot and eHum and eHum.Health > 0 then
                    Utility.FlyAboveTarget(eCF, S.AttackHeight or 30, S.TeleportFlySpeed or 180)
                    local wType = S.SelectedWeaponType or "Melee"
                    if wType == "Melee" then
                        Utility.AttackMelee(enemy, eRoot)
                        Utility.CastSkillsMelee(ePos, enemy)
                    elseif wType == "Fruit" then
                        Utility.AttackFruitM1(enemy, eRoot)
                        Utility.CastSkillsFruit(ePos, enemy)
                    elseif wType == "Sword" then
                        Utility.AttackSword(enemy, eRoot)
                        Utility.CastSkillsSword(ePos, enemy)
                    elseif wType == "Gun" then
                        Utility.AttackGun(enemy, eRoot)
                        Utility.CastSkillsGun(ePos, enemy)
                    end
                end
            else
                Utility.StopPhysicsFly()
            end
            task.wait(0.035)
        end
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop auto farm nearest enemy with skills routine ]]
function Utility.StopAutoFarmWithSkills()
    DisconnectConnection("autoFarmSkills")
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

local lastRaceV3Time = 0
local lastAwakeningV4Time = 0

--[[ Kích hoạt tộc V3 với debounce chống spam lag ]]
function Utility.TriggerAutoRaceV3()
    if os.clock() - lastRaceV3Time < 4 then return end
    lastRaceV3Time = os.clock()

    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local events = rep:FindFirstChild("Events")
        local raceEvent = events and events:FindFirstChild("UsedRaceSkill")
        if raceEvent then
            if firesignal then
                firesignal(raceEvent.OnClientEvent)
            end
        end
    end)
end

--[[ Kích hoạt thức tỉnh tộc V4 không gây block thread ]]
function Utility.TriggerAutoAwakeningV4()
    if os.clock() - lastAwakeningV4Time < 5 then return end
    lastAwakeningV4Time = os.clock()

    task.spawn(function()
        pcall(function()
            local char = LocalPlayer.Character
            local bp = LocalPlayer:FindFirstChild("Backpack")
            local awakening = (bp and bp:FindFirstChild("Awakening")) or (char and char:FindFirstChild("Awakening"))
            if awakening then
                local remote = awakening:FindFirstChild("RemoteFunction") or awakening:FindFirstChildOfClass("RemoteFunction")
                if remote then
                    remote:InvokeServer(true)
                end
            end
        end)
    end)
end

--[[ Vòng lặp tự động kích hoạt V3 và V4 tối ưu hiệu năng ]]
function Utility.StartAutoAwakeningLoop()
    DisconnectConnection("autoAwakeningLoop")
    _conns["autoAwakeningLoop"] = task.spawn(function()
        while S.AutoRaceV3 or S.AutoAwakeningV4 do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if S.AutoRaceV3 then
                    Utility.TriggerAutoRaceV3()
                end
                if S.AutoAwakeningV4 then
                    Utility.TriggerAutoAwakeningV4()
                end
            end
            task.wait(2.5)
        end
    end)
end

--[[ Start Fly Follow Player loop ]]
function Utility.StartFlyFollowPlayer()
    if not S.SelectedPlayer then
        UILib.Notify("Error", "Please select a player!", 3)
        return
    end

    DisconnectConnection("teleportPlayerLoop")
    _conns["teleportPlayerLoop"] = RunService.Heartbeat:Connect(function()
        if not S.TeleportPlayerEnabled or not S.SelectedPlayer then
            DisconnectConnection("teleportPlayerLoop")
            Utility.ResetCameraAndCharacter()
            return
        end

        local targetChar = S.SelectedPlayer.Character
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and myRoot then
            local targetRoot = targetChar.HumanoidRootPart
            local targetCF = targetRoot.CFrame * CFrame.new(0, 5, 2)
            Utility.PhysicsFlyTo(targetCF, S.TeleportFlySpeed)
        end
    end)
end

--[[ Stop Fly Follow Player loop ]]
function Utility.StopFlyFollowPlayer()
    DisconnectConnection("teleportPlayerLoop")
    Utility.ResetCameraAndCharacter()
end

--[[ Start Player Panel live update loop ]]
function Utility.StartPlayerPanelLoop(statusInfo, coordsInfo, timeInfo, sessionInfo)
    DisconnectConnection("playerPanelLoop")
    _conns["playerPanelLoop"] = task.spawn(function()
        while true do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if statusInfo then
                if not hum or hum.Health <= 0 then
                    statusInfo:Set("Dead")
                elseif hum.SeatPart then
                    if hum.SeatPart:IsA("VehicleSeat") then
                        local boatName = hum.SeatPart.Parent and hum.SeatPart.Parent.Name or "Boat"
                        statusInfo:Set("Driving (" .. boatName .. ")")
                    else
                        statusInfo:Set("Seated (" .. (hum.SeatPart.Parent and hum.SeatPart.Parent.Name or "Seat") .. ")")
                    end
                elseif FlyActive then
                    statusInfo:Set("Flying")
                else
                    statusInfo:Set(string.format("Alive (HP: %d/%d)", math.floor(hum.Health), math.floor(hum.MaxHealth)))
                end
            end

            if coordsInfo then
                if root then
                    local p = root.Position
                    coordsInfo:Set(string.format("X: %.0f, Y: %.0f, Z: %.0f", p.X, p.Y, p.Z))
                else
                    coordsInfo:Set("N/A")
                end
            end

            if timeInfo then
                local srvSec = math.floor(workspace.DistributedGameTime)
                local sHrs = math.floor(srvSec / 3600)
                local sMins = math.floor((srvSec % 3600) / 60)
                local sSecs = srvSec % 60
                timeInfo:Set(string.format("%02d:%02d:%02d", sHrs, sMins, sSecs))
            end

            if sessionInfo then
                local sessSec = math.floor(os.clock() - SessionStartTime)
                local pHrs = math.floor(sessSec / 3600)
                local pMins = math.floor((sessSec % 3600) / 60)
                local pSecs = sessSec % 60
                sessionInfo:Set(string.format("%02d:%02d:%02d", pHrs, pMins, pSecs))
            end

            task.wait(0.5)
        end
    end)
end

--[[ Stop Player Panel live update loop ]]
function Utility.StopPlayerPanelLoop()
    DisconnectConnection("playerPanelLoop")
end


-- ╔══════════════════════════════════════════════════════════╗
-- ║                 [SECTION 5] UI INITIALIZATION            ║
-- ╚══════════════════════════════════════════════════════════╝

local ICON_URL = "https://raw.githubusercontent.com/TheHilichurl/Roblox_Script/refs/heads/main/Hilichurl_icon.png"
BuildIconToggle(ICON_URL)

local Window = UILib.CreateWindow({
    Title    = "Hili Hub",
    Subtitle = "made by Hilichurl",
})

--[[ Clean up entire script on unload ]]
function Utility.UnloadAllScript()
    S.AutoBuyBoatEnabled = false
    S.FindLeviathanEnabled = false
    S.MultipleFindLeviathanEnabled = false
    S.AutoShootLeviEnabled = false
    S.AutoAttackEnemyEnabled = false
    S.AutoAttackLeviEnabled = false
    S.AutoSkillsLeviEnabled = false
    S.AutoFarmWithSkillsEnabled = false
    S.AutoFarmSeaEventsEnabled = false
    S.AutoFarmSeaEventsSkills = false
    S.AutoRaceV3 = false
    S.AutoAwakeningV4 = false
    S.BoatNoClipEnabled = false
    S.PlayerNoClipEnabled = false
    S.WalkOnWaterEnabled = false
    S.EnableBoatSpeed = false
    S.TeleportPlayerEnabled = false
    S.ResetWhenBoatDestroyed = false
    S.ResetWhenSelectedOwnerDie = false
    S.AutoTalkFrozenWatcherEnabled = false
    S.AutoDriveTikiEnabled = false
    S.AutoDriveHydraEnabled = false
    S.AutoFlyTikiEnabled = false
    S.AutoFlyHydraEnabled = false

    DisconnectConnection("autoBuyBoat")
    DisconnectConnection("findLev")
    DisconnectConnection("multiFindLev")
    DisconnectConnection("autoAttackLevi")
    DisconnectConnection("autoSkillsLevi")
    DisconnectConnection("autoFarmSkills")
    DisconnectConnection("autoFarmSeaEvents")
    DisconnectConnection("seaEventsBoatFly")
    DisconnectConnection("terrorsharkBodyMover")
    DisconnectConnection("autoAwakeningLoop")
    DisconnectConnection("autoBusoLoop")
    DisconnectConnection("autoAttackEnemyLoop")
    DisconnectConnection("boatNavLoop")
    DisconnectConnection("resetWhenBoatDestroyed")
    DisconnectConnection("resetWhenOwnerDie")
    DisconnectConnection("autoTalkWatcher")
    DisconnectConnection("autoShootLev")
    DisconnectConnection("bspd")
    DisconnectConnection("teleportPlayerLoop")
    DisconnectConnection("playerPanelLoop")
    DisconnectConnection("renderLoop")
    DisconnectConnection("antiAfk")
    DisconnectConnection("antiAfkLoop")
    DisconnectConnection("boatNoClipStepped")
    DisconnectConnection("playerNoClipStepped")
    DisconnectConnection("keyExpiryLoop")

    if ActiveBoat then Utility.ForceStopBoat(ActiveBoat) end
    Utility.StopPhysicsFly()

    if WaterPart and WaterPart.Parent then WaterPart:Destroy() end

    Window:Destroy()
    _G.UnloadScript = nil
end
_G.UnloadScript = Utility.UnloadAllScript

-- ═══════════════════════════════════════════════════════════
--  TAB 1 : LEVIATHAN
-- ═══════════════════════════════════════════════════════════
local LevTab = Window:AddTab({ Name = "Leviathan", Icon = "" })

LevTab:AddSection("Auto Shoot Leviathan Heart (Beast Hunter)")

local function GetShootBoatDropdownOptions()
    local opts = { "My Boat" }
    for _, name in ipairs(Utility.GetPlayerList()) do
        table.insert(opts, name)
    end
    return opts
end

local ShootBoatDropdown = LevTab:AddDropdown({
    Name    = "Select Boat for Shoot Heart",
    Desc    = "Default: My Boat (or select another player's boat)",
    Options = GetShootBoatDropdownOptions(),
    Callback = function(opt)
        if opt == "My Boat" or opt == "None" or opt == "" then
            S.AutoShootBoatOwner = ""
        else
            S.AutoShootBoatOwner = opt
        end
    end,
})

_conns["shootBoatPlrAdded"] = Players.PlayerAdded:Connect(function()
    if ShootBoatDropdown then ShootBoatDropdown:Refresh(GetShootBoatDropdownOptions()) end
end)
_conns["shootBoatPlrRemoved"] = Players.PlayerRemoving:Connect(function()
    if ShootBoatDropdown then ShootBoatDropdown:Refresh(GetShootBoatDropdownOptions()) end
end)

LevTab:AddToggle({
    Name    = "Auto Shoot Leviathan Heart",
    Desc    = "Auto fly boat, sit Harpoon and shoot heart",
    Default = false,
    Callback = function(val)
        S.AutoShootLeviEnabled = val
        if val then
            Utility.StartAutoShootLeviathan()
        else
            Utility.StopAutoShootLeviathan()
        end
    end,
})

LevTab:AddSection("Auto Attack Leviathan")

LevTab:AddDropdown({
    Name    = "Select Weapon for Leviathan",
    Desc    = "Choose weapon or rotate all (reads skills from Farm Setting)",
    Options = { "Dragonstorm", "Melee", "Sword", "Fruit", "Gun", "Rotate All" },
    Default = S.LeviathanSelectedWeapon or "Dragonstorm",
    Callback = function(opt)
        S.LeviathanSelectedWeapon = opt
    end,
})

AutoAttackLeviToggle = LevTab:AddToggle({
    Name    = "Auto Attack Leviathan",
    Desc    = "Fly to Leviathan Segments then Leviathan (attacks with selected weapon)",
    Default = false,
    Callback = function(val)
        S.AutoAttackLeviEnabled = val
        if val then
            if S.MultipleFindLeviathanEnabled then
                S.MultipleFindLeviathanEnabled = false
                if MultipleFindLeviathanToggle then MultipleFindLeviathanToggle:Set(false) end
                Utility.StopMultipleFindLeviathan()
            end
            Utility.StartAutoAttackLeviathan()
        else
            Utility.StopAutoAttackLeviathan()
        end
    end,
})

LevTab:AddToggle({
    Name    = "Auto Attack Leviathan (Dragonstorm)",
    Desc    = "Instantly equip Dragonstorm, fly & attack Leviathan",
    Default = false,
    Callback = function(val)
        if val then
            S.LeviathanSelectedWeapon = "Dragonstorm"
            S.AutoAttackLeviEnabled = true
            if AutoAttackLeviToggle then AutoAttackLeviToggle:Set(true) end
            if S.MultipleFindLeviathanEnabled then
                S.MultipleFindLeviathanEnabled = false
                if MultipleFindLeviathanToggle then MultipleFindLeviathanToggle:Set(false) end
                Utility.StopMultipleFindLeviathan()
            end
            Utility.StartAutoAttackLeviathan()
        else
            S.AutoAttackLeviEnabled = false
            if AutoAttackLeviToggle then AutoAttackLeviToggle:Set(false) end
            Utility.StopAutoAttackLeviathan()
        end
    end,
})

AutoSkillsLeviToggle = LevTab:AddToggle({
    Name    = "Auto Use Skills to Attack Leviathan",
    Desc    = "Auto cast configured weapon skills and aim at Leviathan",
    Default = false,
    Callback = function(val)
        S.AutoSkillsLeviEnabled = val
        if val then
            Utility.StartAutoSkillsLeviathan()
        else
            Utility.StopAutoSkillsLeviathan()
        end
    end,
})

LevTab:AddSection("Frozen Watcher & Gate")

LevTab:AddButton({
    Name = "Bribe Spy",
    Desc = "Bribe Spy NPC for Leviathan information",
    Callback = function()
        Utility.BribeSpy()
    end,
})

LevTab:AddToggle({
    Name    = "Auto Talk Frozen Watcher",
    Desc    = "Auto start Leviathan",
    Default = false,
    Callback = function(val)
        S.AutoTalkFrozenWatcherEnabled = val
        if val then
            Utility.StartAutoTalkFrozenWatcher()
        else
            Utility.StopAutoTalkFrozenWatcher()
        end
    end,
})

LevTab:AddSection("Leviathan Finder")

FindLeviathanToggle = LevTab:AddToggle({
    Name    = "Find Leviathan",
    Desc    = "Auto Find Leviathan",
    Default = false,
    Callback = function(val)
        S.FindLeviathanEnabled = val
        Utility.SetBoatNoClip(val)
        if val then
            Utility.StartFindLeviathan()
        else
            Utility.StopFindLeviathan()
        end
    end,
})

LevTab:AddSlider({
    Name    = "Required Passengers",
    Desc    = "Minimum players sit on your boat (not include you)",
    Min     = 0, Max = 6, Default = 4, Suffix = "",
    Callback = function(v) S.RequiredCannonPassengers = v end,
})

LevTab:AddToggle({
    Name    = "Reset When Boat Destroyed",
    Desc    = "Respawn when your boat destroyed",
    Default = false,
    Callback = function(val)
        S.ResetWhenBoatDestroyed = val
        if val then
            Utility.StartResetWhenBoatDestroyed()
        else
            Utility.StopResetWhenBoatDestroyed()
        end
    end,
})

LevTab:AddSection("Multiple Find Leviathan")

local BoatOwnerDD = LevTab:AddDropdown({
    Name    = "Select Boat Owner",
    Desc    = "Select boat owner to multiple find Leviathan",
    Options = Utility.GetPlayerList(),
    Callback = function(opt)
        S.SelectedBoatOwner = opt
    end,
})

LevTab:AddButton({
    Name = "Refresh Boat Owner List",
    Desc = "Refresh list of boat owner",
    Callback = function()
        BoatOwnerDD:Refresh(Utility.GetPlayerList())
        UILib.Notify("Leviathan", "List of boat owner refreshed!", 2)
    end,
})

MultipleFindLeviathanToggle = LevTab:AddToggle({
    Name    = "Multiple Find Leviathan",
    Desc    = "Sit on owner boat to find Leviathan",
    Default = false,
    Callback = function(val)
        S.MultipleFindLeviathanEnabled = val
        if val then
            Utility.StartMultipleFindLeviathan()
        else
            Utility.StopMultipleFindLeviathan()
        end
    end,
})

LevTab:AddToggle({
    Name    = "Reset When Selected Owner Die",
    Desc    = "Respawn when selected owner die",
    Default = false,
    Callback = function(val)
        S.ResetWhenSelectedOwnerDie = val
        if val then
            Utility.StartResetWhenSelectedOwnerDie()
        else
            Utility.StopResetWhenSelectedOwnerDie()
        end
    end,
})

LevTab:AddSection("Auto Buy Boat")

LevTab:AddDropdown({
    Name    = "Select Boat",
    Desc    = "Choose boat",
    Options = {
        "Beast Hunter",
        "Grand Brigade",
        "Guardian",
        "Miracle",
        "PirateBrigade",
        "Sloop",
        "Dinghy"
    },
    Callback = function(opt)
        S.SelectedBoat = opt
    end,
})

LevTab:AddButton({
    Name = "Buy Boat",
    Desc = "Beast Hunter is default",
    Callback = function()
        local boatName = S.SelectedBoat or "Beast Hunter"
        local ok, err = Utility.BuyBoat(boatName)
        if ok then
            UILib.Notify("Boat", "Bought succesfully " .. boatName .. "!", 3)
        else
            UILib.Notify("Error", "Couldn't buy boat: " .. tostring(err), 3)
        end
    end,
})

LevTab:AddToggle({
    Name    = "Auto Buy Boat",
    Desc    = "Auto buy boat (Beast Hunter is default)",
    Default = false,
    Callback = function(val)
        S.AutoBuyBoatEnabled = val
        if val then
            Utility.StartAutoBuyBoat()
        else
            Utility.StopAutoBuyBoat()
        end
    end,
})

LevTab:AddSection("Fly & Boat Settings")

LevTab:AddSlider({
    Name    = "Boat Fly Speed",
    Desc    = "Boat fly speed when find Leviathan",
    Min     = 100, Max = 350, Default = 220, Suffix  = " s/s",
    Callback = function(v) S.BoatFlySpeed = v end,
})

LevTab:AddSlider({
    Name    = "Boat Fly Height",
    Desc    = "Boat height when find Leviathan",
    Min     = 20, Max = 300, Default = 190, Suffix  = " Y",
    Callback = function(v) S.BoatFlyHeight = v end,
})

LevTab:AddToggle({
    Name    = "Enable Boat Speed",
    Desc    = "Change speed boat",
    Default = false,
    Callback = function(val)
        S.EnableBoatSpeed = val
        if val then
            DisconnectConnection("bspd")
            _conns["bspd"] = RunService.Heartbeat:Connect(function()
                local b = Utility.GetBoat()
                if b then
                    local s = b:FindFirstChildOfClass("VehicleSeat")
                    if s then s.MaxSpeed = S.CustomBoatSpeed end
                end
            end)
        else
            DisconnectConnection("bspd")
            local b = Utility.GetBoat()
            if b then
                local s = b:FindFirstChildOfClass("VehicleSeat")
                if s then s.MaxSpeed = 40 end
            end
        end
    end,
})

LevTab:AddSlider({
    Name    = "Boat Speed",
    Desc    = "Boat speed setting",
    Min     = 40, Max = 500, Default = 250, Suffix  = " sp",
    Callback = function(v) S.CustomBoatSpeed = v end,
})

LevTab:AddSection("Boat Auto Navigation (Tiki / Hydra)")

AutoDriveTikiToggle = LevTab:AddToggle({
    Name    = "Auto Drive to Tiki",
    Desc    = "Drive boat along waypoints to Tiki Outpost",
    Default = false,
    Callback = function(val)
        S.AutoDriveTikiEnabled = val
        if val then
            if S.AutoDriveHydraEnabled and AutoDriveHydraToggle then AutoDriveHydraToggle:Set(false) end
            if S.AutoFlyTikiEnabled and AutoFlyTikiToggle then AutoFlyTikiToggle:Set(false) end
            if S.AutoFlyHydraEnabled and AutoFlyHydraToggle then AutoFlyHydraToggle:Set(false) end
            Utility.StartAutoDriveToTiki()
        else
            Utility.StopBoatWaypointNavigation()
        end
    end,
})

AutoDriveHydraToggle = LevTab:AddToggle({
    Name    = "Auto Drive to Hydra",
    Desc    = "Drive boat along waypoints to Hydra Island",
    Default = false,
    Callback = function(val)
        S.AutoDriveHydraEnabled = val
        if val then
            if S.AutoDriveTikiEnabled and AutoDriveTikiToggle then AutoDriveTikiToggle:Set(false) end
            if S.AutoFlyTikiEnabled and AutoFlyTikiToggle then AutoFlyTikiToggle:Set(false) end
            if S.AutoFlyHydraEnabled and AutoFlyHydraToggle then AutoFlyHydraToggle:Set(false) end
            Utility.StartAutoDriveToHydra()
        else
            Utility.StopBoatWaypointNavigation()
        end
    end,
})

AutoFlyTikiToggle = LevTab:AddToggle({
    Name    = "Auto Fly to Tiki",
    Desc    = "Fly boat along waypoints to Tiki Outpost",
    Default = false,
    Callback = function(val)
        S.AutoFlyTikiEnabled = val
        if val then
            if S.AutoDriveTikiEnabled and AutoDriveTikiToggle then AutoDriveTikiToggle:Set(false) end
            if S.AutoDriveHydraEnabled and AutoDriveHydraToggle then AutoDriveHydraToggle:Set(false) end
            if S.AutoFlyHydraEnabled and AutoFlyHydraToggle then AutoFlyHydraToggle:Set(false) end
            Utility.StartAutoFlyToTiki()
        else
            Utility.StopBoatWaypointNavigation()
        end
    end,
})

AutoFlyHydraToggle = LevTab:AddToggle({
    Name    = "Auto Fly to Hydra",
    Desc    = "Fly boat along waypoints to Hydra Island",
    Default = false,
    Callback = function(val)
        S.AutoFlyHydraEnabled = val
        if val then
            if S.AutoDriveTikiEnabled and AutoDriveTikiToggle then AutoDriveTikiToggle:Set(false) end
            if S.AutoDriveHydraEnabled and AutoDriveHydraToggle then AutoDriveHydraToggle:Set(false) end
            if S.AutoFlyTikiEnabled and AutoFlyTikiToggle then AutoFlyTikiToggle:Set(false) end
            Utility.StartAutoFlyToHydra()
        else
            Utility.StopBoatWaypointNavigation()
        end
    end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 2 : SEA EVENTS
-- ═══════════════════════════════════════════════════════════
local SeaEventsTab = Window:AddTab({ Name = "Sea Events", Icon = "" })

SeaEventsTab:AddSection("Sea Events Configuration")

SeaEventsTab:AddDropdown({
    Name    = "Select Boat",
    Desc    = "Choose boat to auto farm Sea Events",
    Options = {
        "Beast Hunter",
        "Grand Brigade",
        "Guardian",
        "Miracle",
        "PirateBrigade",
        "Sloop",
        "Dinghy"
    },
    Default = S.SeaEventsBoat or "Guardian",
    Callback = function(opt)
        S.SeaEventsBoat = opt
    end,
})

SeaEventsTab:AddMultiDropdown({
    Name    = "Select Weapons",
    Desc    = "Choose weapons (switches every 2s if >= 2 selected)",
    Options = { "Melee", "Sword", "Fruit", "Gun" },
    Default = S.SeaEventsWeapons or {},
    Callback = function(opts)
        S.SeaEventsWeapons = opts
        if #opts > 0 then
            S.SeaEventsWeapon = opts[1]
            Utility.EquipWeaponByType(opts[1])
        else
            S.SeaEventsWeapon = ""
        end
    end,
})

SeaEventsTab:AddMultiDropdown({
    Name    = "Select Sea Events",
    Desc    = "Filter target Sea Events (choose one or multiple)",
    Options = { "All", "Shark", "Piranha", "Fish Crew", "Pirate Ships", "Sea Beast", "Terrorshark" },
    Default = S.SelectedSeaEvents or { "All" },
    Callback = function(opts)
        S.SelectedSeaEvents = opts
        S.SelectedSeaEvent = (#opts > 0 and opts[1] or "All")
    end,
})

SeaEventsTab:AddSection("Auto Farm Actions")

AutoFarmSeaEventsToggle = SeaEventsTab:AddToggle({
    Name    = "Auto Farm Sea Events",
    Desc    = "Continuous boat flight, anchor boat at Y=-200 during events & attack",
    Default = false,
    Callback = function(val)
        S.AutoFarmSeaEventsEnabled = val
        if val then
            Utility.StartAutoFarmSeaEvents()
        else
            Utility.StopAutoFarmSeaEvents()
        end
    end,
})

SeaEventsTab:AddToggle({
    Name    = "Auto Farm Sea Events With Skills",
    Desc    = "Cast weapon skills & auto-aim during sea event combat",
    Default = false,
    Callback = function(val)
        S.AutoFarmSeaEventsSkills = val
    end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 3 : AUTO FARM
-- ═══════════════════════════════════════════════════════════
local FarmTab = Window:AddTab({ Name = "Auto Farm", Icon = "" })

FarmTab:AddSection("Weapon & Combat Configuration")

FarmTab:AddDropdown({
    Name    = "Select Weapon Type",
    Desc    = "Choose weapon category (Melee, Sword, Fruit, Gun)",
    Options = { "Melee", "Sword", "Fruit", "Gun" },
    Default = S.SelectedWeaponType or "Melee",
    Callback = function(opt)
        S.SelectedWeaponType = opt
        Utility.EquipWeaponByType(opt)
    end,
})

FarmTab:AddSlider({
    Name    = "Attack Height",
    Desc    = "Hover height above enemy CFrame (studs)",
    Min     = 5, Max = 60, Default = S.AttackHeight or 30, Suffix = " studs",
    Callback = function(v)
        S.AttackHeight = v
    end,
})

FarmTab:AddSlider({
    Name    = "Farm Fly Speed",
    Desc    = "Flight speed when moving between targets",
    Min     = 50, Max = 350, Default = S.TeleportFlySpeed or 180, Suffix = " sp",
    Callback = function(v)
        S.TeleportFlySpeed = v
    end,
})

FarmTab:AddSection("Auto Farm Actions")

FarmTab:AddToggle({
    Name    = "Auto Farm Nearest Enemy",
    Desc    = "Automatically fly to and attack nearest enemy",
    Default = false,
    Callback = function(val)
        S.AutoAttackEnemyEnabled = val
        if val then
            Utility.StartAutoAttackNearestEnemy()
        else
            Utility.StopAutoAttackNearestEnemy()
        end
    end,
})

FarmTab:AddToggle({
    Name    = "Use Skills While Farming",
    Desc    = "Automatically cast weapon skills (Z, X, C, V) while farming",
    Default = false,
    Callback = function(val)
        S.AutoFarmUseSkills = val
    end,
})

FarmTab:AddToggle({
    Name    = "Farm with Skills Only",
    Desc    = "Auto cast skills only on nearest enemy (Skill testing mode)",
    Default = false,
    Callback = function(val)
        S.AutoFarmWithSkillsEnabled = val
        if val then
            Utility.StartAutoFarmWithSkills()
        else
            Utility.StopAutoFarmWithSkills()
        end
    end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 4 : FARM SETTING
-- ═══════════════════════════════════════════════════════════
local FarmSettingTab = Window:AddTab({ Name = "Farm Setting", Icon = "" })

FarmSettingTab:AddSection("Race Skills & Awakening (V3 & V4)")

FarmSettingTab:AddToggle({
    Name    = "Auto Race V3",
    Desc    = "Automatically activate Race V3 skill",
    Default = false,
    Callback = function(val)
        S.AutoRaceV3 = val
        if val then
            Utility.StartAutoAwakeningLoop()
        end
    end,
})

FarmSettingTab:AddToggle({
    Name    = "Auto Awakening V4",
    Desc    = "Automatically activate Race V4 Awakening",
    Default = false,
    Callback = function(val)
        S.AutoAwakeningV4 = val
        if val then
            Utility.StartAutoAwakeningLoop()
        end
    end,
})

FarmSettingTab:AddSection("Skill Hold Duration Settings")

FarmSettingTab:AddToggle({
    Name    = "Hold Melee Skills",
    Desc    = "Hold Melee skills and aim continuously at target",
    Default = false,
    Callback = function(val) S.HoldMeleeSkills = val end,
})

FarmSettingTab:AddToggle({
    Name    = "Hold Fruit Skills",
    Desc    = "Hold Fruit skills and aim continuously at target",
    Default = false,
    Callback = function(val) S.HoldFruitSkills = val end,
})

FarmSettingTab:AddToggle({
    Name    = "Hold Sword Skills",
    Desc    = "Hold Sword skills and aim continuously at target",
    Default = false,
    Callback = function(val) S.HoldSwordSkills = val end,
})

FarmSettingTab:AddToggle({
    Name    = "Hold Gun Skills",
    Desc    = "Hold Gun skills and aim continuously at target",
    Default = false,
    Callback = function(val) S.HoldGunSkills = val end,
})

FarmSettingTab:AddSlider({
    Name    = "Skill Hold Duration",
    Desc    = "Duration to hold and aim skill at target (seconds)",
    Min     = 0.1, Max = 3.0, Default = 0.35, Suffix = "s",
    Callback = function(v)
        S.SkillHoldDuration = v
    end,
})

FarmSettingTab:AddSection("Melee Skills (Z, X, C)")

FarmSettingTab:AddToggle({
    Name    = "Use Melee Skill Z",
    Desc    = "Enable or disable Melee Z skill",
    Default = true,
    Callback = function(val) S.MeleeSkillZ = val end,
})

FarmSettingTab:AddToggle({
    Name    = "Use Melee Skill X",
    Desc    = "Enable or disable Melee X skill",
    Default = true,
    Callback = function(val) S.MeleeSkillX = val end,
})

FarmSettingTab:AddToggle({
    Name    = "Use Melee Skill C",
    Desc    = "Enable or disable Melee C skill",
    Default = true,
    Callback = function(val) S.MeleeSkillC = val end,
})

FarmSettingTab:AddSection("Fruit Skills (Z, X, C, V, F)")

FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill Z",
    Desc    = "Enable or disable Fruit Z skill",
    Default = true,
    Callback = function(val) S.FruitSkillZ = val end,
})

FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill X",
    Desc    = "Enable or disable Fruit X skill",
    Default = true,
    Callback = function(val) S.FruitSkillX = val end,
})

FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill C",
    Desc    = "Enable or disable Fruit C skill",
    Default = true,
    Callback = function(val) S.FruitSkillC = val end,
})

FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill V",
    Desc    = "Enable or disable Fruit V skill",
    Default = true,
    Callback = function(val) S.FruitSkillV = val end,
})

FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill F",
    Desc    = "Enable or disable Fruit F skill",
    Default = true,
    Callback = function(val) S.FruitSkillF = val end,
})

FarmSettingTab:AddSection("Sword Skills (Z, X)")

FarmSettingTab:AddToggle({
    Name    = "Use Sword Skill Z",
    Desc    = "Enable or disable Sword Z skill",
    Default = true,
    Callback = function(val) S.SwordSkillZ = val end,
})

FarmSettingTab:AddToggle({
    Name    = "Use Sword Skill X",
    Desc    = "Enable or disable Sword X skill",
    Default = true,
    Callback = function(val) S.SwordSkillX = val end,
})

FarmSettingTab:AddSection("Gun Skills (Z, X)")

FarmSettingTab:AddToggle({
    Name    = "Use Gun Skill Z",
    Desc    = "Enable or disable Gun Z skill",
    Default = true,
    Callback = function(val) S.GunSkillZ = val end,
})

FarmSettingTab:AddToggle({
    Name    = "Use Gun Skill X",
    Desc    = "Enable or disable Gun X skill",
    Default = true,
    Callback = function(val) S.GunSkillX = val end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 5 : TELEPORT
-- ═══════════════════════════════════════════════════════════
local TelTab = Window:AddTab({ Name = "Teleport", Icon = "" })

TelTab:AddSection("Teleport Settings")

TelTab:AddSlider({
    Name    = "Teleport Fly Speed",
    Desc    = "Fly speed",
    Min     = 50, Max = 350, Default = 180, Suffix = " sp",
    Callback = function(v)
        S.TeleportFlySpeed = v
    end,
})

TelTab:AddSection("Teleport to Island")

local IslandDD = TelTab:AddDropdown({
    Name    = "Select Island",
    Desc    = "Select island to teleport",
    Options = Utility.GetIslandList(),
    Callback = function(opt)
        S.SelectedIsland = opt
    end,
})

TelTab:AddButton({
    Name = "Teleport to Island",
    Desc = "Teleport to selected island",
    Callback = function()
        if not S.SelectedIsland then
            UILib.Notify("Error", "Select island!", 3); return
        end

        local islObj = Utility.GetIslandObject(S.SelectedIsland)
        if islObj then
            local targetCF = islObj:GetPivot()
            UILib.Notify("Teleport", "Teleporting " .. S.SelectedIsland .. "...", 4)
            Utility.PhysicsFlyTo(targetCF + Vector3.new(0, 100, 0), S.TeleportFlySpeed, function()
                UILib.Notify("Teleport", "Done! " .. S.SelectedIsland .. "!", 4)
            end)
        else
            UILib.Notify("Error", "Can't find island!", 3)
        end
    end,
})

TelTab:AddSection("Teleport to Player")

local PlayerDD = TelTab:AddDropdown({
    Name    = "Select Player",
    Desc    = "Select player to teleport",
    Options = Utility.GetPlayerList(),
    Callback = function(opt)
        S.SelectedPlayer = Players:FindFirstChild(opt)
    end,
})

TelTab:AddButton({
    Name = "Refresh Player List",
    Desc = "Refresh player list",
    Callback = function()
        PlayerDD:Refresh(Utility.GetPlayerList())
        UILib.Notify("Teleport", "Refreshed players list!", 2)
    end,
})

TelTab:AddToggle({
    Name    = "Fly Follow Player",
    Desc    = "Fly follow player",
    Default = false,
    Callback = function(val)
        S.TeleportPlayerEnabled = val
        if val then
            Utility.StartFlyFollowPlayer()
        else
            Utility.StopFlyFollowPlayer()
        end
    end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 6 : MISC
-- ═══════════════════════════════════════════════════════════
local MiscTab = Window:AddTab({ Name = "Misc", Icon = "" })

MiscTab:AddSection("Movement")

MiscTab:AddSlider({
    Name = "Walk Speed", Desc = "Walk speed",
    Min = 16, Max = 300, Default = 100, Suffix = "",
    Callback = function(v) S.CustomWalkSpeed = v end,
})

MiscTab:AddSlider({
    Name = "Jump Power", Desc = "Jump power",
    Min = 50, Max = 500, Default = 50, Suffix = "",
    Callback = function(v) S.CustomJumpPower = v end,
})

MiscTab:AddSection("NoClip")

MiscTab:AddToggle({
    Name = "Player Noclip", Desc = "Player noclip", Default = true,
    Callback = function(val) 
        Utility.SetPlayerNoClip(val)
    end,
})

MiscTab:AddSection("Water & AFK")

MiscTab:AddToggle({
    Name = "Walk on Water", Desc = "Walk on water", Default = true,
    Callback = function(val) S.WalkOnWaterEnabled = val end,
})

MiscTab:AddToggle({
    Name = "Anti-AFK", Desc = "Anti-AFK", Default = true,
    Callback = function(val) S.AntiAFKEnabled = val end,
})

MiscTab:AddSection("Graphics")

MiscTab:AddButton({
    Name = "Boost FPS / Smooth Graphics",
    Desc = "Smooth graphics",
    Callback = function() Utility.OptimizeGraphics() end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 7 : WEBHOOK CONFIG
-- ═══════════════════════════════════════════════════════════
local WhTab = Window:AddTab({ Name = "Webhook", Icon = "" })

WhTab:AddSection("Discord Webhook")

WhTab:AddToggle({
    Name = "Webhook Leviathan Spawn",
    Desc = "Webhook leviathan spawn",
    Default = true,
    Callback = function(val) S.WebhookEnabled = val end,
})

WhTab:AddInput({
    Name = "Discord Webhook URL",
    Desc = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(text)
        if string.find(text, "http") then
            S.WebhookURL = text
            UILib.Notify("Webhook", "Webhook URL recived!", 3)
        end
    end,
})

WhTab:AddSection("Manual Test")

WhTab:AddButton({
    Name = "Test Webhook",
    Desc = "Webhook test",
    Callback = function()
        if S.WebhookURL == "" then
            UILib.Notify("Error", "Webhook URL not recived!", 3); return
        end
        Utility.SendWebhook(S.WebhookURL, LocalPlayer)
        UILib.Notify("Webhook", "Webhook test sended!", 3)
    end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 8 : PLAYER PANEL
-- ═══════════════════════════════════════════════════════════
local PlayerTab = Window:AddTab({ Name = "Player Panel", Icon = "" })

PlayerTab:AddSection("Player Status")

local statusInfo = PlayerTab:AddInfo({ Title = "Status", Value = "Checking..." })
local coordsInfo = PlayerTab:AddInfo({ Title = "Coordinates", Value = "Checking..." })

PlayerTab:AddButton({
    Name = "Copy Coordinates",
    Desc = "Copy current coordinates to clipboard",
    Callback = function()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local posStr = string.format("%.0f, %.0f, %.0f", root.Position.X, root.Position.Y, root.Position.Z)
            pcall(function()
                if setclipboard then setclipboard(posStr)
                elseif toclipboard then toclipboard(posStr) end
            end)
            UILib.Notify("Clipboard", "Coordinates copied: " .. posStr, 3)
        end
    end,
})

PlayerTab:AddSection("Server & Session")

local timeInfo = PlayerTab:AddInfo({ Title = "Server Lifetime", Value = "00:00:00" })
local sessionInfo = PlayerTab:AddInfo({ Title = "Time in Server", Value = "00:00:00" })
local jobIdStr = (game.JobId ~= "") and game.JobId or "SinglePlayer / Studio"
local jobIdInfo = PlayerTab:AddInfo({ Title = "Job ID", Value = string.sub(jobIdStr, 1, 14) .. "..." })

PlayerTab:AddButton({
    Name = "Copy Job ID",
    Desc = "Copy server Job ID to clipboard",
    Callback = function()
        pcall(function()
            if setclipboard then setclipboard(game.JobId)
            elseif toclipboard then toclipboard(game.JobId) end
        end)
        UILib.Notify("Clipboard", "Job ID copied to clipboard!", 3)
    end,
})

if _G.HilichurlKeyData and _G.HilichurlKeyData.LoadedFromLoader then
    PlayerTab:AddSection("Key Information")
    local keyExpiryInfo = PlayerTab:AddInfo({ Title = "Key Expiration", Value = _G.HilichurlKeyData.RemainingText or "Active" })
    
    _conns["keyExpiryLoop"] = task.spawn(function()
        while true do
            task.wait(1)
            if _G.HilichurlKeyData and _G.HilichurlKeyData.ExpiresAt then
                local remainingSec = _G.HilichurlKeyData.ExpiresAt - os.time()
                if remainingSec > 0 then
                    local days = math.floor(remainingSec / 86400)
                    local hours = math.floor((remainingSec % 86400) / 3600)
                    local mins = math.floor((remainingSec % 3600) / 60)
                    local secs = math.floor(remainingSec % 60)
                    if days > 0 then
                        keyExpiryInfo:Set(string.format("%dd %dh %dm", days, hours, mins))
                    elseif hours > 0 then
                        keyExpiryInfo:Set(string.format("%dh %dm %ds", hours, mins, secs))
                    elseif mins > 0 then
                        keyExpiryInfo:Set(string.format("%dm %ds", mins, secs))
                    else
                        keyExpiryInfo:Set(string.format("%ds", secs))
                    end
                else
                    keyExpiryInfo:Set("Expired")
                end
            end
        end
    end)
end

PlayerTab:AddSection("Configuration & Backup")

PlayerTab:AddButton({
    Name = "Save Setting",
    Desc = "Save current settings directly to local executor storage",
    Callback = function()
        Utility.SaveLocalConfig()
    end,
})

PlayerTab:AddButton({
    Name = "Copy Config",
    Desc = "Export current config & loader code to clipboard",
    Callback = function()
        local code = Utility.GenerateConfigCode()
        pcall(function()
            if setclipboard then setclipboard(code)
            elseif toclipboard then toclipboard(code)
            elseif Clipboard and Clipboard.set then Clipboard.set(code) end
        end)
        UILib.Notify("Config", "Config script copied to clipboard!", 3)
    end,
})

Utility.StartPlayerPanelLoop(statusInfo, coordsInfo, timeInfo, sessionInfo)


-- ═══════════════════════════════════════════════════════════
--  RUNTIME LOOPS & LISTENERS
-- ═══════════════════════════════════════════════════════════

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    Utility.UpdateCharacterCache()
    Utility.UpdatePlayerNoClipState()
    task.spawn(function()
        task.wait(0.8)
        if not Utility.IsBusoActive() then
            Utility.EnableBuso()
        end
    end)
end)
if LocalPlayer.Character then 
    Utility.UpdateCharacterCache()
    Utility.UpdatePlayerNoClipState()
    if not Utility.IsBusoActive() then
        Utility.EnableBuso()
    end
else
    Utility.UpdatePlayerNoClipState()
end
Utility.StartAutoBusoLoop()
Utility.OptimizeGraphics(true)

local WaterPart = Instance.new("Part")
WaterPart.Name = "WalkOnWaterPlatform"
WaterPart.Size = Vector3.new(6, 0.3, 6)
WaterPart.Transparency = 1
WaterPart.Anchored = true
WaterPart.CanCollide = false
WaterPart.Parent = workspace

_conns["renderLoop"] = RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        
        if hum then
            if S.CustomWalkSpeed ~= 100 then hum.WalkSpeed = S.CustomWalkSpeed end
            if S.CustomJumpPower ~= 50 then hum.JumpPower = S.CustomJumpPower end
        end

        if root and hum then
            if hum.SeatPart then
                WaterPart.CanCollide = false
            elseif S.WalkOnWaterEnabled then
                if root.Position.Y >= -3.0 then
                    WaterPart.Position = Vector3.new(root.Position.X, -4.2, root.Position.Z)
                    WaterPart.CanCollide = true
                else
                    WaterPart.CanCollide = false
                end
            else
                WaterPart.CanCollide = false
            end
        else
            WaterPart.CanCollide = false
        end
    end
end)

_conns["antiAfk"] = LocalPlayer.Idled:Connect(function()
    if S.AntiAFKEnabled then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(100, 100))
        end)
    end
end)

_conns["antiAfkLoop"] = task.spawn(function()
    while true do
        task.wait(300)
        if S.AntiAFKEnabled then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(100, 100))
            end)
        end
    end
end)
