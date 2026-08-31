-- ============================================================
--  Blox_Fruit_Script.lua  (Single-File Executor · Luau)
--  Author  : Hilichurl  |  Version : 7.0.0
-- ============================================================

-- [LOCAL TEST MODE]
-- Cho phép chạy trực tiếp ở local mà không cần loader hay cloud
if _G.HilichurlAuthSecret then
    _G.HilichurlAuthSecret = nil
end

-- Dọn dẹp phiên script cũ nếu đang chạy
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
        if gethui then
            gui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        else
            gui.Parent = CoreGui
        end
    end)
    if not ok then 
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui") 
    end
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
    TeleportFlySpeed            = 200,
    RequiredCannonPassengers    = 4,
    ResetWhenBoatDestroyed      = false,
    ResetWhenSelectedOwnerDie   = false,
    AutoTalkFrozenWatcherEnabled= false,
    AutoShootBoatMode           = "Shoot with your boat",
    AutoFlyTikiEnabled          = false,
    AutoFlyHydraEnabled         = false,
    SelectedWeaponType          = "Melee",
    AttackHeight                = 40,
    AutoFarmUseSkills           = false,
    AutoAttackLeviEnabled       = false,
    AutoSkillsLeviEnabled       = false,
    AutoFarmWithSkillsEnabled   = false,
    -- Advanced Auto Farm Suite Configuration
    BringMobEnabled             = true,
    BringMobDistance            = 240,
    BringMobSpeed               = 110,
    AutoFarmLevelEnabled        = false,
    AutoNextSeaEnabled          = true,
    AutoSaberQuestEnabled       = true,
    AutoTheSonQuestEnabled      = true,
    AutoMilitaryDetectiveQuestEnabled = true,
    AutoBartiloQuestEnabled     = true,
    AutoFarmSelectedMobEnabled  = false,
    SelectedMob                 = "Bandit",
    AutoFarmSelectedBossEnabled = false,
    SelectedBoss                = "The Gorilla King",
    SelectedBosses              = {},
    AutoGetAllMeleesEnabled     = false,
    AutoGetAllSwordsEnabled     = false,
    AutoGetAllGunsEnabled       = false,
    AutoGetAllAccessoriesEnabled = false,
    AutoUpgradeWeaponsEnabled   = false,
    AutoFarmMasteryMeleeEnabled = false,
    AutoFarmMasterySwordEnabled = false,
    AutoFarmMasteryGunEnabled   = false,
    MasteryTargetLevel          = 600,
    AutoFarmMaterialEnabled     = false,
    SelectedMaterial            = "Bones",
    AutoFarmChestEnabled        = false,
    TestMilestoneIndex          = 1,
    TestAutoFarmMilestoneEnabled = false,
    AutoStatsMelee              = false,
    AutoStatsDefense            = false,
    AutoStatsSword              = false,
    AutoStatsGun                = false,
    AutoStatsFruit              = false,
    StatsPointsAmount           = 1,
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
    LeviathanSelectedWeapons    = { "Melee" },
}

local SETTING_STORAGE_FILE = ".hlc_sys_cache_9a.bin"
local POP_CONFIG_FILE       = ".hlc_sys_dump_c8.tmp"
local XOR_SECRET_KEY        = "HLC_K9_X7_SEC"

local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Encode(data)
    local result = {}
    local len = #data
    for i = 1, len, 3 do
        local b1 = string.byte(data, i)
        local b2 = string.byte(data, i + 1) or 0
        local b3 = string.byte(data, i + 2) or 0
        
        local n = b1 * 65536 + b2 * 256 + b3
        local c1 = math.floor(n / 262144) % 64 + 1
        local c2 = math.floor(n / 4096) % 64 + 1
        local c3 = math.floor(n / 64) % 64 + 1
        local c4 = n % 64 + 1
        
        table.insert(result, string.sub(b64chars, c1, c1))
        table.insert(result, string.sub(b64chars, c2, c2))
        table.insert(result, (i + 1 <= len) and string.sub(b64chars, c3, c3) or "=")
        table.insert(result, (i + 2 <= len) and string.sub(b64chars, c4, c4) or "=")
    end
    return table.concat(result)
end

local function Base64Decode(data)
    data = string.gsub(data, "[^A-Za-z0-9+/=]", "")
    local result = {}
    local len = #data
    for i = 1, len, 4 do
        local c1 = string.find(b64chars, string.sub(data, i, i), 1, true)
        local c2 = string.find(b64chars, string.sub(data, i + 1, i + 1), 1, true)
        local c3 = string.find(b64chars, string.sub(data, i + 2, i + 2), 1, true)
        local c4 = string.find(b64chars, string.sub(data, i + 3, i + 3), 1, true)
        
        if c1 and c2 then
            c1 = c1 - 1
            c2 = c2 - 1
            local b1 = (c1 * 4) + math.floor(c2 / 16)
            table.insert(result, string.char(b1))
            
            if c3 then
                c3 = c3 - 1
                local b2 = ((c2 % 16) * 16) + math.floor(c3 / 4)
                table.insert(result, string.char(b2))
                
                if c4 then
                    c4 = c4 - 1
                    local b3 = ((c3 % 4) * 64) + c4
                    table.insert(result, string.char(b3))
                end
            end
        end
    end
    return table.concat(result)
end

local function SafeXorByte(a, b)
    if bit32 and bit32.bxor then
        return bit32.bxor(a, b)
    elseif bit and bit.bxor then
        return bit.bxor(a, b)
    end
    local res, p = 0, 1
    while a > 0 or b > 0 do
        local ra, rb = a % 2, b % 2
        if ra ~= rb then res = res + p end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        p = p * 2
    end
    return res
end

local function XorEncryptDecrypt(input, key)
    key = key or XOR_SECRET_KEY
    local output = {}
    local kLen = #key
    for i = 1, #input do
        local inByte = string.byte(input, i)
        local kByte = string.byte(key, ((i - 1) % kLen) + 1)
        local xorByte = SafeXorByte(inByte, kByte)
        table.insert(output, string.char(xorByte))
    end
    return table.concat(output)
end

local function EncryptConfig(rawJson)
    local xored = XorEncryptDecrypt(rawJson, XOR_SECRET_KEY)
    return Base64Encode(xored)
end

local function DecryptConfig(cipherText)
    if not cipherText or cipherText == "" then return nil end
    local decoded = Base64Decode(cipherText)
    if not decoded or #decoded == 0 then return nil end
    return XorEncryptDecrypt(decoded, XOR_SECRET_KEY)
end

--[[ Save current settings encrypted directly to stealth storage file ]]
function Utility.SaveLocalConfig()
    local ok, res = pcall(function()
        local saveTable = {}
        for k, v in pairs(S) do
            if typeof(v) == "boolean" or typeof(v) == "number" or typeof(v) == "string" or typeof(v) == "table" then
                saveTable[k] = v
            end
        end
        local json = HttpService:JSONEncode(saveTable)
        local encryptedData = EncryptConfig(json)
        if writefile then
            writefile(SETTING_STORAGE_FILE, encryptedData)
            return true
        end
        return false
    end)
    if ok and res then
        UILib.Notify("Settings", "Settings saved successfully!", 3)
    else
        UILib.Notify("Error", "Failed to save settings!", 3)
    end
    return ok and res
end

--[[ Load settings with priority: 1) One-time POP Config (Auto-deleted), 2) Permanent Encrypted Settings ]]
function Utility.LoadLocalConfig()
    local loadedFromPop = false

    -- 1. Check for temporary POP Config file on disk (Priority 1)
    pcall(function()
        if isfile and isfile(POP_CONFIG_FILE) and readfile then
            local rawCipher = readfile(POP_CONFIG_FILE)
            -- POP Mechanism: Immediately delete temporary config file from disk!
            if delfile then
                pcall(function() delfile(POP_CONFIG_FILE) end)
            end

            if rawCipher and #rawCipher > 0 then
                local decrypted = DecryptConfig(rawCipher)
                if decrypted and #decrypted > 0 then
                    local decoded = HttpService:JSONDecode(decrypted)
                    if typeof(decoded) == "table" then
                        for k, v in pairs(decoded) do
                            if S[k] ~= nil then S[k] = v end
                        end
                        loadedFromPop = true
                    end
                end
            end
        end
    end)

    -- 1.5 Check for in-memory sync token (Fallback)
    if not loadedFromPop then
        pcall(function()
            local token = (getgenv and getgenv()._h_sync_token) or _G._h_sync_token
            if token and typeof(token) == "string" and #token > 0 then
                local decrypted = DecryptConfig(token)
                if decrypted and #decrypted > 0 then
                    local decoded = HttpService:JSONDecode(decrypted)
                    if typeof(decoded) == "table" then
                        for k, v in pairs(decoded) do
                            if S[k] ~= nil then S[k] = v end
                        end
                        loadedFromPop = true
                    end
                end
                if getgenv then getgenv()._h_sync_token = nil end
                _G._h_sync_token = nil
            end
        end)
    end

    -- 2. Check for permanent encrypted settings file (Priority 2)
    if not loadedFromPop then
        pcall(function()
            if isfile and isfile(SETTING_STORAGE_FILE) and readfile then
                local rawCipher = readfile(SETTING_STORAGE_FILE)
                if rawCipher and #rawCipher > 0 then
                    local decrypted = DecryptConfig(rawCipher)
                    if decrypted and #decrypted > 0 then
                        local decoded = HttpService:JSONDecode(decrypted)
                        if typeof(decoded) == "table" then
                            for k, v in pairs(decoded) do
                                if S[k] ~= nil then S[k] = v end
                            end
                        end
                    end
                end
            end
        end)
    end
end

--[[ Generate stealth executable script with encrypted pop config ]]
function Utility.GenerateConfigCode()
    local saveTable = {}
    for k, v in pairs(S) do
        if typeof(v) == "boolean" or typeof(v) == "number" or typeof(v) == "string" or typeof(v) == "table" then
            saveTable[k] = v
        end
    end
    local json = HttpService:JSONEncode(saveTable)
    local encryptedToken = EncryptConfig(json)

    local lines = {}
    table.insert(lines, "-- [ Hilichurl Hub Config Sync ]")
    table.insert(lines, "pcall(function()")
    table.insert(lines, string.format('    local _t = %q', encryptedToken))
    table.insert(lines, string.format('    if writefile then writefile(%q, _t) end', POP_CONFIG_FILE))
    table.insert(lines, '    if getgenv then getgenv()._h_sync_token = _t end')
    table.insert(lines, "end)")
    table.insert(lines, 'loadstring(game:HttpGet("https://raw.githubusercontent.com/TheHilichurl/Roblox_Script/refs/heads/main/loader.lua"))()')
    return table.concat(lines, "\n")
end

-- Auto load saved or pop config upon initialization
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

--[[ Cập nhật trạng thái Boat NoClip (Tự động kích hoạt khi bật tay hoặc khi Auto Farm Sea Events hoạt động) ]]
function Utility.UpdateBoatNoClipState()
    local shouldNoClip = S.BoatNoClipEnabled or S.AutoFarmSeaEventsEnabled
    DisconnectConnection("boatNoClipStepped")
    if shouldNoClip then
        if ActiveBoat then Utility.UpdateBoatCache(ActiveBoat) end
        _conns["boatNoClipStepped"] = RunService.Stepped:Connect(function()
            local active = S.BoatNoClipEnabled or S.AutoFarmSeaEventsEnabled
            if not active then
                DisconnectConnection("boatNoClipStepped")
                for _, part in ipairs(BoatParts) do
                    if part and part.Parent then part.CanCollide = true end
                end
                return
            end
            if ActiveBoat and ActiveBoat.Parent then
                if #BoatParts == 0 then Utility.UpdateBoatCache(ActiveBoat) end
                for _, part in ipairs(BoatParts) do
                    if part and part.Parent then part.CanCollide = false end
                end
            end
        end)
    else
        for _, part in ipairs(BoatParts) do
            if part and part.Parent then part.CanCollide = true end
        end
    end
end

--[[ Bật / tắt Boat NoClip ]]
function Utility.SetBoatNoClip(enabled)
    S.BoatNoClipEnabled = enabled
    Utility.UpdateBoatNoClipState()
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

--[[ Kiểm tra xem thuyền còn tồn tại và còn máu ]]
function Utility.IsBoatAlive(boat)
    if not boat or not boat.Parent then return false end
    local hum = boat:FindFirstChildOfClass("Humanoid") or boat:FindFirstChild("Humanoid")
    if hum then
        if hum:IsA("Humanoid") and hum.Health <= 0 then return false end
        if (hum:IsA("IntValue") or hum:IsA("NumberValue")) and hum.Value <= 0 then return false end
    end
    local vSeat = boat:FindFirstChildOfClass("VehicleSeat") or boat:FindFirstChild("VehicleSeat", true)
    if not vSeat or not vSeat.Parent then return false end
    return true
end

--[[ Tìm thuyền của người chơi còn sống trong bán kính gần (mặc định 1200 studs) ]]
function Utility.GetNearbyPlayerBoat(boatName, maxDistance)
    local maxDist = maxDistance or 1500
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = root and root.Position or Vector3.zero
    local boatsFolder = workspace:FindFirstChild("Boats")
    if not boatsFolder then return nil end

    local targetNameLower = (boatName and boatName ~= "") and string.lower(boatName) or ""

    -- 1. Ưu tiên thuyền đang ngồi
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        local currentBoat = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if currentBoat and currentBoat.Parent == boatsFolder and Utility.IsBoatAlive(currentBoat) then
            return currentBoat
        end
    end

    -- 2. Thuyền thuộc sở hữu của LocalPlayer trong bán kính maxDist
    local bestBoat = nil
    local bestDist = maxDist

    for _, boat in ipairs(boatsFolder:GetChildren()) do
        if Utility.IsBoatAlive(boat) then
            local nameMatch = (targetNameLower == "" or string.find(string.lower(boat.Name), targetNameLower))
            local isMyOwner = false

            local ownerVal = boat:FindFirstChild("Owner")
            if ownerVal then
                local val = ownerVal.Value
                if val == LocalPlayer or val == LocalPlayer.Name or val == LocalPlayer.UserId or tostring(val) == LocalPlayer.Name or tostring(val) == tostring(LocalPlayer.UserId) then
                    isMyOwner = true
                end
            end
            local ownerAttr = boat:GetAttribute("Owner")
            if ownerAttr and (ownerAttr == LocalPlayer.Name or tostring(ownerAttr) == tostring(LocalPlayer.UserId)) then
                isMyOwner = true
            end

            local seat = boat:FindFirstChildOfClass("VehicleSeat") or boat:FindFirstChild("VehicleSeat", true)
            if seat and root then
                local dist = (seat.Position - myPos).Magnitude
                if isMyOwner and dist <= maxDist then
                    return boat
                elseif nameMatch and dist < bestDist then
                    bestDist = dist
                    bestBoat = boat
                end
            end
        end
    end

    return bestBoat
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
        if string.find(string.lower(boat.Name), targetNameLower) and Utility.IsBoatAlive(boat) then
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

    local root = char and char:FindFirstChild("HumanoidRootPart")
    local nearestBoat = nil
    local minDist = math.huge
    for _, boat in ipairs(boatsFolder:GetChildren()) do
        if Utility.IsBoatAlive(boat) then
            local seat = boat:FindFirstChildOfClass("VehicleSeat") or boat:FindFirstChild("VehicleSeat", true)
            if seat and root then
                local d = (seat.Position - root.Position).Magnitude
                if d < minDist then
                    minDist = d
                    nearestBoat = boat
                end
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

    pcall(function() targetSeat.Disabled = false end)
    local seatPos = targetSeat.Position
    local dist = (seatPos - root.Position).Magnitude

    if dist <= 15 then
        Utility.StopPhysicsFly()
        hum.PlatformStand = false
        hum.Jump = false
        hum.Sit = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)

        root.CFrame = targetSeat.CFrame * CFrame.new(0, 0.5, 0)
        pcall(function()
            targetSeat.Disabled = false
            targetSeat:Sit(hum)
        end)
        if firetouchinterest then
            pcall(function()
                firetouchinterest(root, targetSeat, 0)
                task.wait(0.01)
                firetouchinterest(root, targetSeat, 1)
            end)
        end

        if hum.SeatPart == targetSeat then
            if onSeatSuccess then onSeatSuccess() end
            return true
        end
    else
        local speed = S.TeleportFlySpeed or 200
        local targetPos = seatPos + Vector3.new(0, 1.5, 0)
        Utility.PhysicsFlyTo(targetPos, speed)
    end

    return (hum.SeatPart == targetSeat)
end

--[[ Sit on boat driver VehicleSeat ]]
function Utility.SitVehicleSeat(boat)
    if not boat or not boat.Parent then return false end
    local vSeat = boat:FindFirstChildOfClass("VehicleSeat") or boat:FindFirstChild("VehicleSeat", true)
    if not vSeat or not vSeat.Parent then return false end

    -- Nếu người chơi chưa ngồi vào ghế: LẬP TỨC PHANH DỪNG THUYỀN TẠI CHỖ để thuyền không bay/trôi mất!
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.SeatPart ~= vSeat then
        local lv = vSeat:FindFirstChild("FlyLinearVelocity")
        if lv then lv.VectorVelocity = Vector3.zero end
        for _, part in ipairs(boat:GetDescendants()) do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

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

--[[ Send remote request to purchase boat by name (checks distance to spawn point and flies if > 30 studs) ]]
function Utility.BuyBoat(boatName)
    local target = boatName or S.SelectedBoat or "Beast Hunter"
    local spawnPos = Vector3.new(-16219, 9, 440)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if root then
        local dist = (root.Position - spawnPos).Magnitude
        if dist > 30 then
            UILib.Notify("Buy Boat", "Buying boat...", 3)
            local flySpeed = S.TeleportFlySpeed or 200
            local flyTarget = spawnPos + Vector3.new(0, 3, 0)
            Utility.PhysicsFlyTo(flyTarget, flySpeed)

            local t0 = os.clock()
            while (os.clock() - t0 < 15) do
                local curChar = LocalPlayer.Character
                local curRoot = curChar and curChar:FindFirstChild("HumanoidRootPart")
                if curRoot and (curRoot.Position - spawnPos).Magnitude <= 30 then
                    break
                end
                task.wait(0.1)
            end
            Utility.StopPhysicsFly()
            task.wait(0.2)
        end
    end

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

--[[ ═══════════════════════════════════════════════════════════════════════════
     ISLAND TELEPORT DATABASE (SEA 1, SEA 2, SEA 3)
   ═══════════════════════════════════════════════════════════════════════════ ]]

function Utility.GetCurrentSea()
    local pId = game.PlaceId
    if pId == 2753915549 then return 1
    elseif pId == 4442272183 then return 2
    elseif pId == 7449423635 then return 3
    end
    if workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations") then
        if workspace._WorldOrigin.Locations:FindFirstChild("Tiki Outpost") or workspace._WorldOrigin.Locations:FindFirstChild("Floating Turtle") then
            return 3
        elseif workspace._WorldOrigin.Locations:FindFirstChild("Kingdom of Rose") or workspace._WorldOrigin.Locations:FindFirstChild("Ice Castle") then
            return 2
        end
    end
    return 1
end

local WHIRLPOOL_SEA_SURFACE = Vector3.new(4019, 0, -1848)
local WHIRLPOOL_UNDERWATER  = Vector3.new(61170, 0, 1942)

local ISLAND_DATABASE = {
    [1] = {
        { Name = "Windmill Island (Pirate Starter)", Pos = Vector3.new(1060, 16.5, 1428) },
        { Name = "Marine Starter Island",          Pos = Vector3.new(-2763, 24, 2115) },
        { Name = "Middle Town",                    Pos = Vector3.new(-650, 7.5, 1445) },
        { Name = "Jungle",                         Pos = Vector3.new(-1612, 36.8, 149) },
        { Name = "Pirate Village",                 Pos = Vector3.new(-1181, 4.8, 3840) },
        { Name = "Desert",                         Pos = Vector3.new(945, 6.5, 4373) },
        { Name = "Frozen Village",                 Pos = Vector3.new(1198, 27, -1212) },
        { Name = "Marine Fortress",                Pos = Vector3.new(-5035, 20.6, 4324) },
        { Name = "Skylands (Lower / Tầng 1)",       Pos = Vector3.new(-4840, 717.7, -2623) },
        { Name = "Skylands (Upper / Đền Enel)",     Pos = Vector3.new(-4622, 860, -1703) },
        { Name = "Prison",                         Pos = Vector3.new(4875, 5.6, 735) },
        { Name = "Colosseum (Sea 1)",              Pos = Vector3.new(-1461, 7, -2873) },
        { Name = "Magma Village",                  Pos = Vector3.new(-5230, 8.5, 8468) },
        { Name = "Underwater City (Đảo Người Cá)",  Pos = Vector3.new(4019, 0, -1848) },
        { Name = "Fountain City",                  Pos = Vector3.new(5127, 4.3, 4024) },
        { Name = "Mob Island (Đảo Bí Mật)",        Pos = Vector3.new(-2850, 7.4, 5350) },
    },
    [2] = {
        { Name = "Kingdom of Rose (Docks)",        Pos = Vector3.new(90, 20, 2900) },
        { Name = "Cafe",                           Pos = Vector3.new(-380, 73, 295) },
        { Name = "Mansion (Sea 2)",                Pos = Vector3.new(-288, 332, 595) },
        { Name = "Colosseum (Sea 2)",              Pos = Vector3.new(-1820, 50, -2740) },
        { Name = "Green Zone",                     Pos = Vector3.new(-2450, 73, -3150) },
        { Name = "Graveyard Island",               Pos = Vector3.new(-5415, 48.5, -795) },
        { Name = "Snow Mountain",                  Pos = Vector3.new(650, 401, -5334) },
        { Name = "Hot and Cold (Băng Lửa)",        Pos = Vector3.new(-580, 16, -1140) },
        { Name = "Cursed Ship (Thuyền Ám)",        Pos = Vector3.new(920, 125, 32870) },
        { Name = "Ice Castle (Lâu Đài Băng)",      Pos = Vector3.new(6115, 295, -6740) },
        { Name = "Forgotten Island",               Pos = Vector3.new(-3050, 237, -10140) },
        { Name = "Dark Arena (Blackbeard)",        Pos = Vector3.new(3800, 15, -3500) },
        { Name = "Usoap's Island",                 Pos = Vector3.new(4815, 8.5, 2855) },
    },
    [3] = {
        { Name = "Port Town",                      Pos = Vector3.new(-290, 7.4, 5325) },
        { Name = "Hydra Island",                   Pos = Vector3.new(5745, 610, -260) },
        { Name = "Great Tree",                     Pos = Vector3.new(2280, 26, -6680) },
        { Name = "Floating Turtle (Dinh Thự Rùa)", Pos = Vector3.new(-12460, 332, -7560) },
        { Name = "Mansion (Sea 3)",                Pos = Vector3.new(-12460, 332, -7560) },
        { Name = "Castle on the Sea",              Pos = Vector3.new(-5048, 314.5, -3153) },
        { Name = "Haunted Castle",                 Pos = Vector3.new(-9515, 142, 5530) },
        { Name = "Peanut Island",                  Pos = Vector3.new(-2050, 38, -10250) },
        { Name = "Ice Cream Island",               Pos = Vector3.new(-900, 65, -10950) },
        { Name = "Cake Loaf (Đảo Bánh)",           Pos = Vector3.new(-2050, 38, -12150) },
        { Name = "Chocolate Island",               Pos = Vector3.new(280, 24, -12500) },
        { Name = "Candy Cane Island",              Pos = Vector3.new(-1150, 14, -14450) },
        { Name = "Tiki Outpost",                   Pos = Vector3.new(-16235, 10, 430) },
    }
}

--[[ Kiểm tra xem người chơi có đang ở bên trong Underwater City không ]]
function Utility.IsInsideUnderwaterCity()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    return root and (root.Position.X > 50000)
end

--[[ Dịch chuyển tức thì trực tiếp bằng CFrame không cần bay ]]
function Utility.InstantCFrameTeleport(pos, name)
    pcall(function()
        Utility.StopPhysicsFly()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if root and hum then
            hum.PlatformStand = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.new(pos)
            UILib.Notify("Teleport", "Instant CFrame Teleported to " .. (name or string.format("(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)) .. "!", 3)
        end
    end)
end

--[[ Lấy danh sách tên tất cả các đảo theo Sea hiện tại ]]
function Utility.GetIslandList()
    local curSea = Utility.GetCurrentSea()
    local list = {}
    local seaData = ISLAND_DATABASE[curSea] or ISLAND_DATABASE[1]
    for _, item in ipairs(seaData) do
        table.insert(list, item.Name)
    end
    return list
end

--[[ Lấy toạ độ chuẩn của đảo theo tên ]]
function Utility.GetIslandPosition(islandName)
    if not islandName then return nil end
    local curSea = Utility.GetCurrentSea()
    local seaData = ISLAND_DATABASE[curSea] or ISLAND_DATABASE[1]
    for _, item in ipairs(seaData) do
        if item.Name == islandName then
            return item.Pos
        end
    end
    for sea = 1, 3 do
        for _, item in ipairs(ISLAND_DATABASE[sea] or {}) do
            if item.Name == islandName then
                return item.Pos
            end
        end
    end
    local obj = Utility.GetIslandObject(islandName)
    if obj then
        return obj:GetPivot().Position
    end
    return nil
end

--[[ Kiểm tra và tự động chuyển vùng qua cổng Whirlpool nếu điểm đến nằm khác khu vực (Sea 1) ]]
function Utility.CheckAndHandleUnderwaterTransition(targetPos)
    if not targetPos or Utility.GetCurrentSea() ~= 1 then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local isUnder = (root.Position.X > 50000)
    local targetIsUnder = (targetPos.X > 50000)

    if isUnder and not targetIsUnder then
        UILib.Notify("Teleport", "Exiting Underwater City via Whirlpool...", 3)
        Utility.PhysicsFlyTo(WHIRLPOOL_UNDERWATER, S.TeleportFlySpeed or 200)
        local t0 = os.clock()
        while Utility.IsInsideUnderwaterCity() and os.clock() - t0 < 4.5 do
            pcall(function()
                local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if r then r.CFrame = CFrame.new(WHIRLPOOL_UNDERWATER) end
            end)
            task.wait(0.15)
        end
        task.wait(0.3)
        Utility.StopPhysicsFly()
    elseif not isUnder and targetIsUnder then
        UILib.Notify("Teleport", "Entering Underwater City via Whirlpool...", 3)
        Utility.PhysicsFlyTo(WHIRLPOOL_SEA_SURFACE, S.TeleportFlySpeed or 200)
        local t0 = os.clock()
        while not Utility.IsInsideUnderwaterCity() and os.clock() - t0 < 4.5 do
            pcall(function()
                local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if r then r.CFrame = CFrame.new(WHIRLPOOL_SEA_SURFACE) end
            end)
            task.wait(0.15)
        end
        task.wait(0.3)
        Utility.StopPhysicsFly()
    end
end

--[[ Điều hướng thông minh có xử lý tự động qua cổng Whirlpool khi ra/vào Underwater City ]]
function Utility.SmartFlyTo(targetPos, speed, onComplete)
    task.spawn(function()
        local flySpeed = speed or S.TeleportFlySpeed or 200
        Utility.CheckAndHandleUnderwaterTransition(targetPos)
        Utility.PhysicsFlyTo(targetPos, flySpeed, onComplete)
    end)
end

--[[ Thuật toán dịch chuyển đảo thông minh: Tự động qua cổng Whirlpool khi vào/ra Underwater City ]]
function Utility.SmartTeleportToIsland(islandName, onArrivalCallback)
    task.spawn(function()
        local curSea = Utility.GetCurrentSea()
        local targetPos = Utility.GetIslandPosition(islandName)
        if not targetPos then
            UILib.Notify("Teleport", "Cannot find coordinates for " .. tostring(islandName), 3)
            return
        end

        local flySpeed = S.TeleportFlySpeed or 200
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local isUnder = Utility.IsInsideUnderwaterCity()
        local isTargetUnder = (islandName:lower():find("underwater") or targetPos.X > 50000)

        if curSea == 1 then
            -- TH1: Đang ở trong Underwater City và muốn ra bất kỳ đảo nào ở ngoài
            if isUnder and not isTargetUnder then
                UILib.Notify("Teleport", "Exiting Underwater City via Whirlpool...", 3)
                Utility.PhysicsFlyTo(WHIRLPOOL_UNDERWATER, flySpeed)
                local t0 = os.clock()
                while Utility.IsInsideUnderwaterCity() and os.clock() - t0 < 4.5 do
                    pcall(function()
                        local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if r then r.CFrame = CFrame.new(WHIRLPOOL_UNDERWATER) end
                    end)
                    task.wait(0.15)
                end
                task.wait(0.3)
                Utility.StopPhysicsFly()
            -- TH2: Đang ở ngoài biển và chọn Underwater City -> Bay thẳng vào Whirlpool mặt biển (4019, 0, -1848)
            elseif not isUnder and isTargetUnder then
                UILib.Notify("Teleport", "Flying to Whirlpool (4019, 0, -1848)...", 3)
                Utility.PhysicsFlyTo(WHIRLPOOL_SEA_SURFACE, flySpeed, function()
                    local t0 = os.clock()
                    while not Utility.IsInsideUnderwaterCity() and os.clock() - t0 < 4.5 do
                        pcall(function()
                            local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if r then r.CFrame = CFrame.new(WHIRLPOOL_SEA_SURFACE) end
                        end)
                        task.wait(0.15)
                    end
                    UILib.Notify("Teleport", "Teleported inside Underwater City!", 4)
                    if onArrivalCallback then onArrivalCallback() end
                end)
                return
            end
        end

        -- Tiếp tục bay êm ái đến đảo mục tiêu
        UILib.Notify("Teleport", "Flying to " .. islandName .. "...", 3)
        Utility.PhysicsFlyTo(targetPos + Vector3.new(0, 40, 0), flySpeed, function()
            UILib.Notify("Teleport", "Arrived at " .. islandName .. "!", 4)
            if onArrivalCallback then onArrivalCallback() end
        end)
    end)
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

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.SeatPart ~= seat then
            -- Người chơi không còn ngồi trên ghế lái: LẬP TỨC PHANH DỪNG THUYỀN TẠI CHỖ và bay đưa người chơi về ghế
            lv.VectorVelocity = Vector3.zero
            Utility.SitVehicleSeat(boat)
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
        UILib.Notify("Leviathan", "❄️ Leviathan found! Sitting on " .. tostring(S.SelectedBoatOwner) .. "'s boat...", 6)
    else
        UILib.Notify("Leviathan", "❄️ Leviathan found!", 6)
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
                        task.wait(0.08)
                        continue
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

            task.wait(0.2)
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
                                UILib.Notify("Multiple Find Leviathan", "No empty Cannon seat on " .. S.SelectedBoatOwner .. "'s boat!", 3)
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
                    UILib.Notify("Multiple Find Leviathan", "Waiting for " .. S.SelectedBoatOwner .. "'s boat...", 3)
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
                            UILib.Notify("Auto Shoot", "Waiting for Frozen Heart...", 4)
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

                            -- Tính toán vị trí đậu thuyền trước tim Leviathan (khoảng cách 260 studs theo phương ngang, cao hơn tim 20 studs)
                            local heartToBoat = Vector3.new(seatPos.X - fhPos.X, 0, seatPos.Z - fhPos.Z)
                            local approachDir = (heartToBoat.Magnitude > 5) and heartToBoat.Unit or Vector3.new(1, 0, 0)
                            local standOffDist = 260
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
                                        UILib.Notify("Auto Shoot", "Flying in front of Heart...", 3)
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
                                        UILib.Notify("Auto Shoot", "Descending boat to shoot Heart...", 3)
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
                                        UILib.Notify("Auto Shoot", "In position! Sitting on Harpoon...", 3)
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
                                        UILib.Notify("Auto Shoot", "Couldn't find Harpoon on boat!", 3)
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

--[[ Send remote request to bribe the Spy NPC  ]]
function Utility.BribeSpy()
    local ok, res = pcall(function()
        local Event = game:GetService("ReplicatedStorage").Remotes.CommF_
        return Event:InvokeServer("InfoLeviathan", "2")
    end)
    if ok then
        UILib.Notify("Spy NPC", "Bribed Spy !", 3)
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
                UILib.Notify("Frozen Watcher", "Finding Frozen Watcher...", 3)
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

    local rawWeapons = S.LeviathanSelectedWeapons or { "Melee" }
    if typeof(rawWeapons) == "string" then rawWeapons = { rawWeapons } end
    local wType = weaponTypeOverride or rawWeapons[1] or S.SelectedWeaponType or "Melee"

    -- Súng khi đánh Leviathan TUYỆT ĐỐI KHÔNG DÙNG CHIÊU, CHỈ DÙNG M1 BẮN SIÊU TỐC
    if wType == "Gun" or wType == "Dragonstorm" or wType == "Dragon Storm" then
        return
    end

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
    end

    for _, key in ipairs(skillKeys) do
        if not char or not char.Parent or not hum or hum.Health <= 0 then break end

        local curPart = (targetEnemy and targetEnemy.Parent and (targetEnemy:FindFirstChild("HumanoidRootPart") or targetEnemy:FindFirstChild("Head") or targetEnemy.PrimaryPart or targetEnemy:FindFirstChildOfClass("BasePart"))) or targetPart
        local livePos = curPart and curPart.Position or actualTargetPos
        local myPos = myRoot.Position
        local aimCF = CFrame.lookAt(myPos, livePos)
        local hitCF = curPart and curPart.CFrame or CFrame.new(livePos)

        for _, rf in ipairs(skillRemotes) do
            task.spawn(function()
                if wType == "Melee" then
                    pcall(function() rf:InvokeServer(key, aimCF, hitCF, "Aaa") end)
                elseif wType == "Fruit" then
                    pcall(function() rf:InvokeServer(key) end)
                elseif wType == "Sword" then
                    pcall(function() rf:InvokeServer(key, livePos) end)
                end
            end)
        end

        local holdEnabled = (wType == "Melee" and S.HoldMeleeSkills)
            or (wType == "Fruit" and S.HoldFruitSkills)
            or (wType == "Sword" and S.HoldSwordSkills)
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
        local wIndex = 1
        local lastSwapTime = os.clock()

        while S.AutoAttackLeviEnabled do
            local target, isSegment = Utility.GetLeviathanTarget()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if target and target.Parent and root and hum and hum.Health > 0 then
                if hum.SeatPart or hum.Sit then
                    hum.Sit = false
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                    task.wait(0.05)
                end

                local eRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") or target.PrimaryPart or target:FindFirstChildOfClass("BasePart")

                if eRoot then
                    -- Lấy danh sách vũ khí được chọn (Đổi qua lại nếu chọn từ 2 vũ khí trở lên)
                    local weaponList = S.LeviathanSelectedWeapons
                    if typeof(weaponList) == "string" then weaponList = { weaponList } end
                    if not weaponList or #weaponList == 0 then weaponList = { "Melee" } end

                    if #weaponList > 1 and (os.clock() - lastSwapTime >= 1.5) then
                        wIndex = (wIndex % #weaponList) + 1
                        lastSwapTime = os.clock()
                    elseif wIndex > #weaponList then
                        wIndex = 1
                    end

                    local chosenWeapon = weaponList[wIndex] or "Melee"
                    local targetPos = eRoot.Position
                    local attackHeight = (chosenWeapon == "Gun" or chosenWeapon == "Dragonstorm") and 40 or 25
                    local flyTargetPos = targetPos + Vector3.new(0, attackHeight, 0)
                    Utility.PhysicsFlyTo(flyTargetPos, S.BoatFlySpeed or S.TeleportFlySpeed or 220)

                    -- Thực hiện tấn công vũ khí (Tích hợp cơ chế Dragonstorm cho toàn bộ súng, không dùng chiêu)
                    if chosenWeapon == "Melee" then
                        Utility.AttackMelee(target, eRoot)
                    elseif chosenWeapon == "Sword" then
                        Utility.AttackSword(target, eRoot)
                    elseif chosenWeapon == "Fruit" then
                        Utility.AttackFruitM1(target, eRoot)
                    elseif chosenWeapon == "Gun" or chosenWeapon == "Dragonstorm" then
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
        local sIndex = 1

        while S.AutoSkillsLeviEnabled do
            local target, _ = Utility.GetLeviathanTarget()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if target and target.Parent and root and hum and hum.Health > 0 then
                if hum.SeatPart or hum.Sit then
                    hum.Sit = false
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                    task.wait(0.05)
                end

                local eRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") or target.PrimaryPart or target:FindFirstChildOfClass("BasePart")
                if eRoot then
                    local rawList = S.LeviathanSelectedWeapons
                    if typeof(rawList) == "string" then rawList = { rawList } end
                    if not rawList or #rawList == 0 then rawList = { "Melee" } end

                    -- Lọc bỏ Gun (vì súng đánh Leviathan không được dùng chiêu, chỉ dùng M1)
                    local skillEligibleWeapons = {}
                    for _, w in ipairs(rawList) do
                        if w ~= "Gun" and w ~= "Dragonstorm" then
                            table.insert(skillEligibleWeapons, w)
                        end
                    end

                    if #skillEligibleWeapons > 0 then
                        if sIndex > #skillEligibleWeapons then sIndex = 1 end
                        local chosenWeapon = skillEligibleWeapons[sIndex]
                        sIndex = (sIndex % #skillEligibleWeapons) + 1

                        Utility.CastSkillsLeviathan(eRoot.Position, target, chosenWeapon)
                        task.wait(1.5)
                    else
                        task.wait(0.5)
                    end
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
                local dist = (root.Position - myPos).Magnitude
                if dist <= 1500 then
                    table.insert(targets, {
                        Model = model,
                        Root = root,
                        Humanoid = hum,
                        Type = eventType,
                        Distance = dist
                    })
                end
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

--[[ Bắt đầu luồng bay thuyền cho Sea Events: Bay theo trục X về phía âm, lấy (-16219, 9, 440) làm trung tâm, leo Y = 800 trong bán kính 1000 studs ]]
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

    local targetPointA = Vector3.new(-58000, 190, 440)
    local targetPointB = Vector3.new(-38000, 190, 440)
    local currentTarget = targetPointA

    Utility.UpdateBoatCache(boat)
    Utility.UpdateBoatNoClipState()

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

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.SeatPart ~= seat then
            -- Người chơi không còn ngồi trên ghế lái: LẬP TỨC PHANH DỪNG THUYỀN TẠI CHỖ và bay đưa người chơi về ghế
            lv.VectorVelocity = Vector3.zero
            Utility.SitVehicleSeat(boat)
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
        local distFromCenter = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(-16219, 0, 440)).Magnitude

        -- Trong bán kính 1500 studs so với toạ độ trung tâm (-16219, 9, 440): luôn đẩy lên Y = 800 trước rồi mới bay tiếp
        if distFromCenter <= 1500 then
            local climbSpeed = 200
            local deltaY = 800 - pos.Y
            local vy = math.clamp(deltaY * 10, -climbSpeed, climbSpeed)

            if pos.Y < 790 then
                -- Đẩy thẳng đứng đạt độ cao 800 trước
                lv.VectorVelocity = Vector3.new(0, vy, 0)
            else
                -- Đã đạt độ cao 800 thì bắt đầu bay tiếp về phía âm trục X
                lv.VectorVelocity = Vector3.new(flatDir.X * speed, vy, flatDir.Z * speed)
            end

            -- Trong phạm vi 1500 studs: mũi thuyền quay theo hướng bay ban đầu (hướng thẳng)
            if flatDir.Magnitude > 0.1 then
                ao.CFrame = CFrame.lookAt(Vector3.zero, flatDir)
            else
                ao.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(-1, 0, 0))
            end
        else
            -- Rời khỏi bán kính 1500 studs so với toạ độ trung tâm: hạ về độ cao bình thường (Y = 190)
            lv.VectorVelocity = Vector3.new(dir.Unit.X * speed, (flyY - pos.Y) * 5, dir.Unit.Z * speed)

            -- Ra ngoài phạm vi 1500 studs: mũi thuyền quay sang hướng hiện tại (xoay 90 độ sang phải)
            if flatDir.Magnitude > 0.1 then
                ao.CFrame = CFrame.lookAt(Vector3.zero, flatDir) * CFrame.Angles(0, math.rad(-90), 0)
            else
                ao.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(-1, 0, 0)) * CFrame.Angles(0, math.rad(-90), 0)
            end
        end
    end)
end

--[[ Vòng lặp Auto Farm Sea Events ]]
function Utility.StartAutoFarmSeaEvents()
    DisconnectConnection("autoFarmSeaEvents")
    DisconnectConnection("seaEventsBoatFly")
    Utility.EnsureBodyMoverListener()
    Utility.UpdatePlayerNoClipState()
    Utility.UpdateBoatNoClipState()

    _conns["autoFarmSeaEvents"] = task.spawn(function()
        local lastCharacter = LocalPlayer.Character
        local playerBoat = nil
        local currentWeaponIndex = 1
        local lastWeaponSwitchTime = os.clock()
        local TIKI_SPAWN = Vector3.new(-16219, 9, 440)
        local isRespawning = false

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
                    isRespawning = false
                    playerBoat = nil
                    ActiveBoat = nil
                    DisconnectConnection("seaEventsBoatFly")
                end

                -- 2. Quét danh sách các mục tiêu Sea Event đã chọn còn sống trong bán kính 700 studs
                local seaTargets = Utility.GetActiveSeaEventTargets()

                -- [TRƯỜNG HỢP A]: CÒN KẺ ĐỊCH ĐANG TỒN TẠI (#seaTargets > 0)
                -- TUYỆT ĐỐI KHÔNG MUA THUYỀN, KHÔNG RESPAWN, TẬP TRUNG 100% TẤN CÔNG TIÊU DIỆT SẠCH QUÁI
                if #seaTargets > 0 then
                    DisconnectConnection("seaEventsBoatFly")

                    -- Rời khỏi ghế lái nếu đang ngồi để bay tới tấn công
                    if hum.SeatPart or hum.Sit then
                        hum.Sit = false
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                        task.wait(0.05)
                    end

                    -- Dừng/neo thuyền tại chỗ nếu thuyền còn tồn tại gần đó
                    if playerBoat and playerBoat.Parent and Utility.IsBoatAlive(playerBoat) then
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

                    -- 1. Kiểm tra xem có thuyền hợp lệ trong bán kính 1200 studs hay không
                    if not playerBoat or not playerBoat.Parent or not Utility.IsBoatAlive(playerBoat) then
                        playerBoat = Utility.GetNearbyPlayerBoat(selBoatName, 1200)
                    end

                    -- 2. Nếu KHÔNG có thuyền hợp lệ trong bán kính 1200 studs (thuyền vỡ / mất thuyền / ở quá xa):
                    if not playerBoat or not playerBoat.Parent or not Utility.IsBoatAlive(playerBoat) then
                        playerBoat = nil
                        ActiveBoat = nil
                        DisconnectConnection("seaEventsBoatFly")
                        Utility.StopPhysicsFly()

                        local distToSpawn = (myRoot.Position - TIKI_SPAWN).Magnitude

                        -- Nếu ở ngoài biển xa (> 1500 studs so với bến Tiki): Respawn về bến Tiki
                        if distToSpawn > 1500 then
                            if not isRespawning then
                                isRespawning = true
                                UILib.Notify("Sea Events", "Respawning...", 3)
                                Utility.RespawnPlayer()
                                task.wait(3)
                            end
                            continue
                        else
                            -- Nếu đã ở gần bến Tiki (<= 1500 studs): Mua thuyền mới tại bến
                            UILib.Notify("Sea Events", "Buying boat " .. selBoatName .. "...", 3)
                            Utility.BuyBoat(selBoatName)

                            local tBuy = os.clock()
                            while S.AutoFarmSeaEventsEnabled and (os.clock() - tBuy < 6) do
                                playerBoat = Utility.GetNearbyPlayerBoat(selBoatName, 500)
                                if playerBoat and playerBoat.Parent and Utility.IsBoatAlive(playerBoat) then
                                    break
                                end
                                task.wait(0.5)
                            end
                        end

                    -- 3. Nếu ĐÃ CÓ thuyền hợp lệ trong bán kính 1200 studs:
                    else
                        ActiveBoat = playerBoat
                        local vSeat = playerBoat:FindFirstChildOfClass("VehicleSeat") or playerBoat:FindFirstChild("VehicleSeat", true)

                        if vSeat then
                            -- Nếu chưa ngồi vào ghế lái (hoặc vừa bị quái hất văng ra): Bay tới ghế lái và ngồi vào
                            if hum.SeatPart ~= vSeat then
                                DisconnectConnection("seaEventsBoatFly")
                                Utility.SitVehicleSeat(playerBoat)
                            -- Khi đã ngồi chắc chắn trên ghế lái: Tiếp tục bay tuần tra tìm quái
                            else
                                if FlyActive then Utility.StopPhysicsFly() end

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
    Utility.UpdateBoatNoClipState()
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

--[[ 4. Thực hiện tấn công bằng Melee (Hỗ trợ đánh lan 100% đa mục tiêu Bring Mob & Burst Attack 0.2s) ]]
function Utility.AttackMelee(enemy, enemyRoot, extraTargets)
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
                ctrl.hitboxMagnitude = 60
                ctrl.active = true
                ctrl.increment = 3
                ctrl:attack()
            end
        end
    end)

    if tool then pcall(function() tool:Activate() end) end

    -- Thu thập toàn bộ danh sách quái cần gây sát thương
    local targetList = {}
    if enemy and enemy:IsA("Model") then
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            table.insert(targetList, { Model = enemy, Root = eRoot, Head = eHead or eRoot })
        end
    end

    if extraTargets and typeof(extraTargets) == "table" then
        for _, t in ipairs(extraTargets) do
            local model = t.Model or t
            if model and model ~= enemy and model:IsA("Model") then
                local hum = model:FindFirstChildOfClass("Humanoid")
                local root = t.Root or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                local head = model:FindFirstChild("Head") or root
                if hum and hum.Health > 0 and root then
                    table.insert(targetList, { Model = model, Root = root, Head = head })
                end
            end
        end
    end

    if #targetList == 0 and eRoot then
        table.insert(targetList, { Model = enemy or eRoot.Parent, Root = eRoot, Head = eHead or eRoot })
    end

    local fullBatchHit = {}
    for _, t in ipairs(targetList) do
        table.insert(fullBatchHit, { t.Model, t.Head })
        table.insert(fullBatchHit, { t.Model, t.Root })
    end

    -- Fast Attack Multi-Hit (Không dùng task.wait gây nghẽn luồng)
    if regAttack and regAttack:IsA("RemoteEvent") then
        pcall(function() regAttack:FireServer(0) end)
        pcall(function() regAttack:FireServer(0.1) end)
    end

    if regHit and regHit:IsA("RemoteEvent") then
        pcall(function() regHit:FireServer(eHead or eRoot, fullBatchHit) end)
        pcall(function() regHit:FireServer(eRoot, fullBatchHit) end)

        for _, t in ipairs(targetList) do
            pcall(function()
                regHit:FireServer(t.Head or t.Root, fullBatchHit)
                regHit:FireServer(t.Head or t.Root, { { t.Model, t.Head or t.Root }, { t.Model, t.Root } })
            end)
        end
    end

    if commF and commF:IsA("RemoteFunction") then
        task.spawn(function()
            pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
        end)
    end
end

--[[ 5. Thực hiện tấn công bằng Sword (Hỗ trợ đánh lan 100% đa mục tiêu Bring Mob & Siêu tốc không nghẽn luồng) ]]
function Utility.AttackSword(enemy, enemyRoot, extraTargets)
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
                ctrl.hitboxMagnitude = 60
                ctrl.active = true
                ctrl.increment = 3
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

    local targetList = {}
    if enemy and enemy:IsA("Model") then
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            table.insert(targetList, { Model = enemy, Root = eRoot, Head = eHead or eRoot })
        end
    end

    if extraTargets and typeof(extraTargets) == "table" then
        for _, t in ipairs(extraTargets) do
            local model = t.Model or t
            if model and model ~= enemy and model:IsA("Model") then
                local hum = model:FindFirstChildOfClass("Humanoid")
                local root = t.Root or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                local head = model:FindFirstChild("Head") or root
                if hum and hum.Health > 0 and root then
                    table.insert(targetList, { Model = model, Root = root, Head = head })
                end
            end
        end
    end

    if #targetList == 0 and eRoot then
        table.insert(targetList, { Model = enemy or eRoot.Parent, Root = eRoot, Head = eHead or eRoot })
    end

    local fullBatchHit = {}
    for _, t in ipairs(targetList) do
        table.insert(fullBatchHit, { t.Model, t.Head })
        table.insert(fullBatchHit, { t.Model, t.Root })
    end

    if regAttack and regAttack:IsA("RemoteEvent") then
        pcall(function() regAttack:FireServer(0) end)
        pcall(function() regAttack:FireServer(0.1) end)
    end

    if regHit and regHit:IsA("RemoteEvent") then
        pcall(function() regHit:FireServer(eHead or eRoot, fullBatchHit) end)
        pcall(function() regHit:FireServer(eRoot, fullBatchHit) end)

        for _, t in ipairs(targetList) do
            pcall(function()
                regHit:FireServer(t.Head or t.Root, fullBatchHit)
                regHit:FireServer(t.Head or t.Root, { { t.Model, t.Head or t.Root }, { t.Model, t.Root } })
            end)
        end
    end

    if commF and commF:IsA("RemoteFunction") then
        task.spawn(function()
            pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
        end)
    end
end

local fruitM1ComboIndex = 1

--[[ Dọn dẹp trạng thái khi dừng farm an toàn - Không gửi lệnh xả chiêu giả lập ]]
function Utility.ReleaseAllHeldSkills()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
        end
    end)
end

--[[ 6. Thực hiện tấn công bằng M1 của Fruit (Hỗ trợ đánh lan 100% đa mục tiêu Bring Mob & Siêu tốc) ]]
function Utility.AttackFruitM1(enemy, enemyRoot, extraTargets)
    local tool = Utility.EquipWeaponByType("Fruit")
    local eRoot = enemyRoot or (enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")))
    local eHead = enemy and enemy:FindFirstChild("Head")
    if not eRoot then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local myPos = myRoot.Position
    local targetPos = eRoot.Position

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

    if tool then
        pcall(function() tool:Activate() end)
        local lcr = tool:FindFirstChild("LeftClickRemote") or tool:FindFirstChild("LeftClickRemote", true)
        if lcr and lcr:IsA("RemoteEvent") then
            pcall(function() lcr:FireServer(aimHorizontal, combo, true, targetPos) end)
            pcall(function() lcr:FireServer(aim3D, combo, true, targetPos) end)
        end
    end

    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        local cfModule = ps and ps:FindFirstChild("CombatFramework")
        if cfModule then
            local cf = require(cfModule)
            if cf and cf.activeController then
                local ctrl = cf.activeController
                ctrl.timeToNextAttack = 0
                ctrl.hitboxMagnitude = 60
                ctrl.active = true
                ctrl.increment = 3
                ctrl:attack()
            end
        end
    end)

    local rep = game:GetService("ReplicatedStorage")
    local net = rep:FindFirstChild("Modules") and rep.Modules:FindFirstChild("Net")
    local regAttack = net and net:FindFirstChild("RE/RegisterAttack")
    local regHit = net and net:FindFirstChild("RE/RegisterHit")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

    local targetList = {}
    if enemy and enemy:IsA("Model") then
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            table.insert(targetList, { Model = enemy, Root = eRoot, Head = eHead or eRoot })
        end
    end

    if extraTargets and typeof(extraTargets) == "table" then
        for _, t in ipairs(extraTargets) do
            local model = t.Model or t
            if model and model ~= enemy and model:IsA("Model") then
                local hum = model:FindFirstChildOfClass("Humanoid")
                local root = t.Root or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                local head = model:FindFirstChild("Head") or root
                if hum and hum.Health > 0 and root then
                    table.insert(targetList, { Model = model, Root = root, Head = head })
                end
            end
        end
    end

    if #targetList == 0 and eRoot then
        table.insert(targetList, { Model = enemy or eRoot.Parent, Root = eRoot, Head = eHead or eRoot })
    end

    local fullBatchHit = {}
    for _, t in ipairs(targetList) do
        table.insert(fullBatchHit, { t.Model, t.Head })
        table.insert(fullBatchHit, { t.Model, t.Root })
    end

    if regAttack and regAttack:IsA("RemoteEvent") then
        pcall(function() regAttack:FireServer(0) end)
        pcall(function() regAttack:FireServer(0.1) end)
    end

    if regHit and regHit:IsA("RemoteEvent") then
        pcall(function() regHit:FireServer(eHead or eRoot, fullBatchHit) end)
        pcall(function() regHit:FireServer(eRoot, fullBatchHit) end)

        for _, t in ipairs(targetList) do
            pcall(function()
                regHit:FireServer(t.Head or t.Root, fullBatchHit)
                regHit:FireServer(t.Head or t.Root, { { t.Model, t.Head or t.Root }, { t.Model, t.Root } })
            end)
        end
    end

    if commF and commF:IsA("RemoteFunction") then
        task.spawn(function()
            pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
        end)
    end
end

local lastGunClickTime = 0

--[[ 7. Thực hiện tấn công bằng Gun (Áp dụng toàn diện cơ chế M1 Dragonstorm Leviathan cho TẤT CẢ các loại súng) ]]
function Utility.AttackGun(enemy, enemyRoot, extraTargets)
    local tool = Utility.EquipWeaponByType("Gun")
    local eRoot = enemyRoot or (enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")))
    local eHead = enemy and enemy:FindFirstChild("Head")
    if not eRoot then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local myPos = myRoot.Position
    local targetPos = eRoot.Position

    -- 1. Tự động xoay nhân vật chuẩn xác về hướng quái
    local flatTarget = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
    if (flatTarget - myPos).Magnitude > 0.1 then
        myRoot.CFrame = CFrame.lookAt(myPos, flatTarget)
    end

    local rep = game:GetService("ReplicatedStorage")
    local net = rep:FindFirstChild("Modules") and rep.Modules:FindFirstChild("Net")
    local shootGunEvent = net and net:FindFirstChild("RE/ShootGunEvent")
    local regAttack = net and net:FindFirstChild("RE/RegisterAttack")
    local regHit = net and net:FindFirstChild("RE/RegisterHit")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

    -- 2. Kích hoạt M1 Gun (Tool Activation + LeftClickRemote + VirtualInputManager)
    if tool then
        pcall(function() tool:Activate() end)
        local lcr = tool:FindFirstChild("LeftClickRemote") or tool:FindFirstChild("LeftClickRemote", true)
        if lcr and lcr:IsA("RemoteEvent") then
            local aimDir = (targetPos - myPos).Magnitude > 0 and (targetPos - myPos).Unit or Vector3.new(0, 0, -1)
            pcall(function() lcr:FireServer(aimDir, 1, true, targetPos) end)
        end
    end

    if tick() - lastGunClickTime >= 0.25 then
        lastGunClickTime = tick()
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

    -- 3. Danh sách mục tiêu đánh lan
    local targetList = {}
    if enemy and enemy:IsA("Model") then
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            table.insert(targetList, { Model = enemy, Root = eRoot, Head = eHead or eRoot })
        end
    end

    if extraTargets and typeof(extraTargets) == "table" then
        for _, t in ipairs(extraTargets) do
            local model = t.Model or t
            if model and model ~= enemy and model:IsA("Model") then
                local hum = model:FindFirstChildOfClass("Humanoid")
                local root = t.Root or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                local head = model:FindFirstChild("Head") or root
                if hum and hum.Health > 0 and root then
                    table.insert(targetList, { Model = model, Root = root, Head = head })
                end
            end
        end
    end

    if #targetList == 0 and eRoot then
        table.insert(targetList, { Model = enemy or eRoot.Parent, Root = eRoot, Head = eHead or eRoot })
    end

    local fullBatchHit = {}
    for _, t in ipairs(targetList) do
        table.insert(fullBatchHit, { t.Model, t.Head })
        table.insert(fullBatchHit, { t.Model, t.Root })
    end

    -- 4. Bão đạn ShootGunEvent + RegisterHit đa tầng
    for i = 1, 6 do
        if shootGunEvent and shootGunEvent:IsA("RemoteEvent") then
            for _, t in ipairs(targetList) do
                pcall(function() shootGunEvent:FireServer(t.Root.Position, { t.Root }) end)
                pcall(function() shootGunEvent:FireServer(t.Root.Position, { t.Head or t.Root }) end)
                pcall(function() shootGunEvent:FireServer(t.Root.Position, {}) end)
            end
        end

        if regAttack and regAttack:IsA("RemoteEvent") then
            pcall(function() regAttack:FireServer(0) end)
            pcall(function() regAttack:FireServer(0.1) end)
        end

        if regHit and regHit:IsA("RemoteEvent") then
            pcall(function() regHit:FireServer(eHead or eRoot, fullBatchHit) end)
            pcall(function() regHit:FireServer(eRoot, fullBatchHit) end)
            for _, t in ipairs(targetList) do
                pcall(function()
                    regHit:FireServer(t.Head or t.Root, fullBatchHit)
                    regHit:FireServer(t.Head or t.Root, { { t.Model, t.Head or t.Root }, { t.Model, t.Root } })
                end)
            end
        end
    end

    if commF and commF:IsA("RemoteFunction") then
        task.spawn(function()
            pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
        end)
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

-- ═══════════════════════════════════════════════════════════
--  AUTO FARM DATABASE & PROGRESSION ENGINE
-- ═══════════════════════════════════════════════════════════

local LEVEL_QUEST_DATA = {
    -- Sea 1 (World 1)
    { Min = 1, Max = 9, Mob = "Bandit", Quest = "BanditQuest1", QLevel = 1, GiverPos = Vector3.new(1059, 16, 1549), MobPos = Vector3.new(1145, 17, 1634) },
    { Min = 10, Max = 14, Mob = "Monkey", Quest = "JungleQuest", QLevel = 1, GiverPos = Vector3.new(-1601, 36, 153), MobPos = Vector3.new(-1497, 23, 37) },
    { Min = 15, Max = 29, Mob = "Gorilla", Quest = "JungleQuest", QLevel = 2, GiverPos = Vector3.new(-1601, 36, 153), MobPos = Vector3.new(-1240, 7, -500) },
    { Min = 30, Max = 39, Mob = "Pirate", Quest = "BuggyQuest1", QLevel = 1, GiverPos = Vector3.new(-1140, 4, 3829), MobPos = Vector3.new(-1115, 5, 3848) },
    { Min = 40, Max = 59, Mob = "Brute", Quest = "BuggyQuest1", QLevel = 2, GiverPos = Vector3.new(-1140, 4, 3829), MobPos = Vector3.new(-1142, 15, 4134) },
    { Min = 60, Max = 74, Mob = "Desert Bandit", Quest = "DesertQuest", QLevel = 1, GiverPos = Vector3.new(896, 6, 4390), MobPos = Vector3.new(996, 7, 4430) },
    { Min = 75, Max = 89, Mob = "Desert Officer", Quest = "DesertQuest", QLevel = 2, GiverPos = Vector3.new(896, 6, 4390), MobPos = Vector3.new(1571, 4, 4373) },
    { Min = 90, Max = 99, Mob = "Snow Bandit", Quest = "SnowQuest", QLevel = 1, GiverPos = Vector3.new(1385, 87, -1298), MobPos = Vector3.new(1287, 106, -1299) },
    { Min = 100, Max = 119, Mob = "Snowman", Quest = "SnowQuest", QLevel = 2, GiverPos = Vector3.new(1385, 87, -1298), MobPos = Vector3.new(1185, 106, -1519) },
    { Min = 120, Max = 149, Mob = "Chief Petty Officer", Quest = "MarineQuest2", QLevel = 1, GiverPos = Vector3.new(-5035, 29, 4325), MobPos = Vector3.new(-4710, 112, 4584) },
    { Min = 150, Max = 174, Mob = "Sky Bandit", Quest = "SkyQuest", QLevel = 1, GiverPos = Vector3.new(-4839, 718, -2619), MobPos = Vector3.new(-4965, 357, -2848) },
    { Min = 175, Max = 189, Mob = "Dark Master", Quest = "SkyQuest", QLevel = 2, GiverPos = Vector3.new(-4839, 718, -2619), MobPos = Vector3.new(-5224, 484, -2275) },
    { Min = 190, Max = 209, Mob = "Prisoner", Quest = "PrisonerQuest", QLevel = 1, GiverPos = Vector3.new(5308, 2, 474), MobPos = Vector3.new(5276, 88, 561) },
    { Min = 210, Max = 249, Mob = "Dangerous Prisoner", Quest = "PrisonerQuest", QLevel = 2, GiverPos = Vector3.new(5308, 2, 474), MobPos = Vector3.new(5276, 88, 561) },
    { Min = 250, Max = 274, Mob = "Toga Warrior", Quest = "ColosseumQuest", QLevel = 1, GiverPos = Vector3.new(-1576, 7, -2988), MobPos = Vector3.new(-1820, 52, -2740) },
    { 
        Min = 275, Max = 299, 
        Mob = "Gladiator", 
        Quest = "ColosseumQuest", 
        QLevel = 2, 
        GiverPos = Vector3.new(-1576, 7, -2988), 
        MobPos = Vector3.new(-1334, 71, -3394),
        SpawnPoints = {
            Vector3.new(-1447, 1, -3194),
            Vector3.new(-1264, 1, -3073),
            Vector3.new(-1155, 1, -3289),
            Vector3.new(-1334, 1, -3394),
            Vector3.new(-1359, 1, -3562),
        }
    },
    { Min = 300, Max = 324, Mob = "Military Soldier", Quest = "MagmaQuest", QLevel = 1, GiverPos = Vector3.new(-5315, 12, 8515), MobPos = Vector3.new(-5411, 11, 8454) },
    { Min = 325, Max = 374, Mob = "Military Spy", Quest = "MagmaQuest", QLevel = 2, GiverPos = Vector3.new(-5315, 12, 8515), MobPos = Vector3.new(-5800, 77, 8800) },
    { Min = 375, Max = 399, Mob = "Fishman Warrior", Quest = "FishmanQuest", QLevel = 1, GiverPos = Vector3.new(60900, 19, 1500), MobPos = Vector3.new(61163, 19, 1569) },
    { Min = 400, Max = 449, Mob = "Fishman Commando", Quest = "FishmanQuest", QLevel = 2, GiverPos = Vector3.new(60900, 19, 1500), MobPos = Vector3.new(61900, 19, 1500) },
    { Min = 450, Max = 474, Mob = "God's Guard", Quest = "SkyExp1Quest", QLevel = 1, GiverPos = Vector3.new(-4723, 845, -1952), MobPos = Vector3.new(-4720, 889, -1938) },
    { Min = 475, Max = 524, Mob = "Shanda", Quest = "SkyExp1Quest", QLevel = 2, GiverPos = Vector3.new(-7861, 5546, -382), MobPos = Vector3.new(-7700, 5545, -450) },
    { Min = 525, Max = 549, Mob = "Royal Squad", Quest = "SkyExp2Quest", QLevel = 1, GiverPos = Vector3.new(-7752, 5607, -1490), MobPos = Vector3.new(-7600, 5607, -1400) },
    { Min = 550, Max = 624, Mob = "Royal Soldier", Quest = "SkyExp2Quest", QLevel = 2, GiverPos = Vector3.new(-7752, 5607, -1490), MobPos = Vector3.new(-7800, 5607, -1800) },
    { Min = 625, Max = 649, Mob = "Galley Pirate", Quest = "FountainQuest", QLevel = 1, GiverPos = Vector3.new(5259, 39, 4050), MobPos = Vector3.new(5500, 39, 3950) },
    { Min = 650, Max = 699, Mob = "Galley Captain", Quest = "FountainQuest", QLevel = 2, GiverPos = Vector3.new(5259, 39, 4050), MobPos = Vector3.new(5600, 39, 4900) },

    -- Sea 2 (World 2)
    { 
        Min = 700, Max = 724, 
        Mob = "Raider", 
        Quest = "Area1Quest", 
        QLevel = 1, 
        GiverPos = Vector3.new(-424, 73, 1836), 
        MobPos = Vector3.new(-733, 39, 2383),
        SpawnPoints = {
            Vector3.new(-733, 39, 2383),
            Vector3.new(373, 39, 2331)
        }
    },
    { Min = 725, Max = 774, Mob = "Mercenary", Quest = "Area1Quest", QLevel = 2, GiverPos = Vector3.new(-424, 73, 1836), MobPos = Vector3.new(-1005, 73, 1398) },
    { Min = 775, Max = 799, Mob = "Swan Pirate", Quest = "Area2Quest", QLevel = 1, GiverPos = Vector3.new(638, 73, 918), MobPos = Vector3.new(850, 73, 1200) },
    { 
        Min = 800, Max = 874, 
        Mob = "Factory Staff", 
        Quest = "Area2Quest", 
        QLevel = 2, 
        GiverPos = Vector3.new(638, 73, 918), 
        MobPos = Vector3.new(300, 73, -100),
        SpawnPoints = {
            Vector3.new(-258, 73, -550),
            Vector3.new(-96, 149, -161),
            Vector3.new(637, 73, 42)
        }
    },
    { Min = 875, Max = 899, Mob = "Marine Lieutenant", Quest = "MarineQuest3", QLevel = 1, GiverPos = Vector3.new(-2440, 73, -3217), MobPos = Vector3.new(-2800, 73, -3000) },
    { Min = 900, Max = 949, Mob = "Marine Captain", Quest = "MarineQuest3", QLevel = 2, GiverPos = Vector3.new(-2440, 73, -3217), MobPos = Vector3.new(-2000, 73, -3300) },
    { Min = 950, Max = 974, Mob = "Zombie", Quest = "ZombieQuest", QLevel = 1, GiverPos = Vector3.new(-5491, 48, -794), MobPos = Vector3.new(-5600, 48, -700) },
    { Min = 975, Max = 999, Mob = "Vampire", Quest = "ZombieQuest", QLevel = 2, GiverPos = Vector3.new(-5491, 48, -794), MobPos = Vector3.new(-6000, 6, -1300) },
    { Min = 1000, Max = 1049, Mob = "Snow Trooper", Quest = "SnowMountainQuest", QLevel = 1, GiverPos = Vector3.new(609, 401, -5372), MobPos = Vector3.new(500, 401, -5500) },
    { Min = 1050, Max = 1099, Mob = "Winter Warrior", Quest = "SnowMountainQuest", QLevel = 2, GiverPos = Vector3.new(609, 401, -5372), MobPos = Vector3.new(1200, 450, -5200) },
    { Min = 1100, Max = 1124, Mob = "Lab Subordinate", Quest = "IceSideQuest", QLevel = 1, GiverPos = Vector3.new(-6228, 82, -4851), MobPos = Vector3.new(-5769, 82, -4490) },
    { Min = 1125, Max = 1174, Mob = "Horned Warrior", Quest = "FireSideQuest", QLevel = 1, GiverPos = Vector3.new(-6228, 82, -4851), MobPos = Vector3.new(-6347, 35, -5887) },
    { Min = 1175, Max = 1199, Mob = "Magma Ninja", Quest = "FireSideQuest", QLevel = 2, GiverPos = Vector3.new(-6228, 82, -4851), MobPos = Vector3.new(-5400, 16, -5900) },
    { Min = 1200, Max = 1249, Mob = "Lava Pirate", Quest = "FireSideQuest", QLevel = 2, GiverPos = Vector3.new(-6228, 82, -4851), MobPos = Vector3.new(-5200, 39, -4700) },
    { Min = 1250, Max = 1274, Mob = "Ship Deckhand", Quest = "ShipQuest1", QLevel = 1, GiverPos = Vector3.new(923, 125, 32885), MobPos = Vector3.new(1150, 125, 33000) },
    { Min = 1275, Max = 1299, Mob = "Ship Engineer", Quest = "ShipQuest1", QLevel = 2, GiverPos = Vector3.new(923, 125, 32885), MobPos = Vector3.new(900, 45, 33000) },
    { Min = 1300, Max = 1324, Mob = "Ship Steward", Quest = "ShipQuest2", QLevel = 1, GiverPos = Vector3.new(923, 125, 32885), MobPos = Vector3.new(900, 90, 33400) },
    { Min = 1325, Max = 1349, Mob = "Ship Officer", Quest = "ShipQuest2", QLevel = 2, GiverPos = Vector3.new(923, 125, 32885), MobPos = Vector3.new(1000, 170, 33400) },
    { Min = 1350, Max = 1374, Mob = "Arctic Warrior", Quest = "IceCastleQuest", QLevel = 1, GiverPos = Vector3.new(6040, 29, -6226), MobPos = Vector3.new(6000, 29, -6800) },
    { Min = 1375, Max = 1424, Mob = "Snow Lurker", Quest = "IceCastleQuest", QLevel = 2, GiverPos = Vector3.new(6040, 29, -6226), MobPos = Vector3.new(5500, 29, -6800) },
    { Min = 1425, Max = 1449, Mob = "Sea Soldier", Quest = "ForgottenQuest", QLevel = 1, GiverPos = Vector3.new(-3054, 237, -10148), MobPos = Vector3.new(-3200, 237, -9700) },
    { Min = 1450, Max = 1499, Mob = "Water Fighter", Quest = "ForgottenQuest", QLevel = 2, GiverPos = Vector3.new(-3054, 237, -10148), MobPos = Vector3.new(-3400, 237, -10400) },

    -- Sea 3 (World 3)
    { Min = 1500, Max = 1524, Mob = "Pirate Millionaire", Quest = "PortTownQuest", QLevel = 1, GiverPos = Vector3.new(-290, 7, 5330), MobPos = Vector3.new(-712, 98, 5711) },
    { Min = 1525, Max = 1574, Mob = "Pistol Billionaire", Quest = "PortTownQuest", QLevel = 2, GiverPos = Vector3.new(-290, 7, 5330), MobPos = Vector3.new(-723, 147, 5931) },
    { Min = 1575, Max = 1599, Mob = "Dragon Crew Warrior", Quest = "HydraQuest", QLevel = 1, GiverPos = Vector3.new(5749, 610, -267), MobPos = Vector3.new(7021, 55, -730) },
    { Min = 1600, Max = 1624, Mob = "Dragon Crew Archer", Quest = "HydraQuest", QLevel = 2, GiverPos = Vector3.new(5749, 610, -267), MobPos = Vector3.new(6625, 378, 244) },
    { Min = 1625, Max = 1649, Mob = "Female Islander", Quest = "AmazonQuest", QLevel = 1, GiverPos = Vector3.new(5749, 610, -267), MobPos = Vector3.new(4692, 797, 858) },
    { Min = 1650, Max = 1699, Mob = "Giant Islander", Quest = "AmazonQuest", QLevel = 2, GiverPos = Vector3.new(5749, 610, -267), MobPos = Vector3.new(4902, 670, 39) },
    { Min = 1700, Max = 1724, Mob = "Marine Commodore", Quest = "MarineTreeQuest", QLevel = 1, GiverPos = Vector3.new(2401, 123, -7589), MobPos = Vector3.new(2401, 123, -7589) },
    { Min = 1725, Max = 1774, Mob = "Marine Rear Admiral", Quest = "MarineTreeQuest", QLevel = 2, GiverPos = Vector3.new(2401, 123, -7589), MobPos = Vector3.new(3588, 229, -7085) },
    { Min = 1775, Max = 1799, Mob = "Fishman Raider", Quest = "FloatingTurtleQuest", QLevel = 1, GiverPos = Vector3.new(-10941, 332, -8760), MobPos = Vector3.new(-10941, 332, -8760) },
    { Min = 1800, Max = 1824, Mob = "Fishman Captain", Quest = "FloatingTurtleQuest", QLevel = 2, GiverPos = Vector3.new(-10941, 332, -8760), MobPos = Vector3.new(-11035, 332, -9087) },
    { Min = 1825, Max = 1849, Mob = "Forest Pirate", Quest = "FloatingTurtleQuest2", QLevel = 1, GiverPos = Vector3.new(-13446, 413, -7760), MobPos = Vector3.new(-13446, 413, -7760) },
    { Min = 1850, Max = 1899, Mob = "Mythological Pirate", Quest = "FloatingTurtleQuest2", QLevel = 2, GiverPos = Vector3.new(-13446, 413, -7760), MobPos = Vector3.new(-13510, 584, -6987) },
    { Min = 1900, Max = 1924, Mob = "Jungle Pirate", Quest = "FloatingTurtleQuest3", QLevel = 1, GiverPos = Vector3.new(-11778, 426, -10592), MobPos = Vector3.new(-11778, 426, -10592) },
    { Min = 1925, Max = 1974, Mob = "Musketeer Pirate", Quest = "FloatingTurtleQuest3", QLevel = 2, GiverPos = Vector3.new(-11778, 426, -10592), MobPos = Vector3.new(-13282, 496, -9565) },
    { Min = 1975, Max = 1999, Mob = "Reborn Skeleton", Quest = "HauntedCastleQuest", QLevel = 1, GiverPos = Vector3.new(-8764, 142, 5963), MobPos = Vector3.new(-8764, 142, 5963) },
    { Min = 2000, Max = 2024, Mob = "Living Zombie", Quest = "HauntedCastleQuest", QLevel = 2, GiverPos = Vector3.new(-8764, 142, 5963), MobPos = Vector3.new(-10227, 421, 6161) },
    { Min = 2025, Max = 2049, Mob = "Demonic Soul", Quest = "HauntedCastleQuest2", QLevel = 1, GiverPos = Vector3.new(-9579, 6, 6194), MobPos = Vector3.new(-9579, 6, 6194) },
    { Min = 2050, Max = 2074, Mob = "Posessed Mummy", Quest = "HauntedCastleQuest2", QLevel = 2, GiverPos = Vector3.new(-9579, 6, 6194), MobPos = Vector3.new(-9579, 6, 6194) },
    { Min = 2075, Max = 2099, Mob = "Peanut Scout", Quest = "PeanutQuest", QLevel = 1, GiverPos = Vector3.new(-1993, 187, -10103), MobPos = Vector3.new(-1993, 187, -10103) },
    { Min = 2100, Max = 2124, Mob = "Peanut President", Quest = "PeanutQuest", QLevel = 2, GiverPos = Vector3.new(-1993, 187, -10103), MobPos = Vector3.new(-2215, 159, -10474) },
    { Min = 2125, Max = 2149, Mob = "Ice Cream Chef", Quest = "IceCreamIslandQuest", QLevel = 1, GiverPos = Vector3.new(-877, 118, -11032), MobPos = Vector3.new(-877, 118, -11032) },
    { Min = 2150, Max = 2199, Mob = "Ice Cream Commander", Quest = "IceCreamIslandQuest", QLevel = 2, GiverPos = Vector3.new(-877, 118, -11032), MobPos = Vector3.new(-877, 118, -11032) },
    { Min = 2200, Max = 2224, Mob = "Cookie Crafter", Quest = "CakeQuest1", QLevel = 1, GiverPos = Vector3.new(-2021, 38, -12028), MobPos = Vector3.new(-2021, 38, -12028) },
    { Min = 2225, Max = 2249, Mob = "Cake Guard", Quest = "CakeQuest1", QLevel = 2, GiverPos = Vector3.new(-2021, 38, -12028), MobPos = Vector3.new(-2024, 38, -12026) },
    { Min = 2250, Max = 2274, Mob = "Baking Staff", Quest = "CakeQuest2", QLevel = 1, GiverPos = Vector3.new(-1932, 38, -12848), MobPos = Vector3.new(-1932, 38, -12848) },
    { Min = 2275, Max = 2299, Mob = "Head Baker", Quest = "CakeQuest2", QLevel = 2, GiverPos = Vector3.new(-1932, 38, -12848), MobPos = Vector3.new(-1932, 38, -12848) },
    { Min = 2300, Max = 2324, Mob = "Cocoa Warrior", Quest = "CandyQuest1", QLevel = 1, GiverPos = Vector3.new(95, 73, -12309), MobPos = Vector3.new(95, 73, -12309) },
    { Min = 2325, Max = 2349, Mob = "Chocolate Bar Battler", Quest = "CandyQuest1", QLevel = 2, GiverPos = Vector3.new(95, 73, -12309), MobPos = Vector3.new(647, 42, -12401) },
    { Min = 2350, Max = 2374, Mob = "Sweet Thief", Quest = "CandyQuest2", QLevel = 1, GiverPos = Vector3.new(116, 36, -12478), MobPos = Vector3.new(116, 36, -12478) },
    { Min = 2375, Max = 2449, Mob = "Candy Rebel", Quest = "CandyQuest2", QLevel = 2, GiverPos = Vector3.new(116, 36, -12478), MobPos = Vector3.new(47, 61, -12889) },
    { Min = 2450, Max = 2499, Mob = "Isle Outlaw", Quest = "TikiQuest1", QLevel = 1, GiverPos = Vector3.new(-16533, 55, -85), MobPos = Vector3.new(-16533, 55, -85) },
    { Min = 2500, Max = 2550, Mob = "Sun-kissed Warrior", Quest = "TikiQuest2", QLevel = 1, GiverPos = Vector3.new(-16533, 55, -85), MobPos = Vector3.new(-16533, 55, -85) },
}

local MATERIAL_FARM_DATA = {
    ["Bones"] = { Mob = "Reborn Skeleton", Pos = Vector3.new(-8764, 142, 5963) },
    ["Dragon Scale"] = { Mob = "Dragon Crew Warrior", Pos = Vector3.new(7021, 55, -730) },
    ["Conjured Cocoa"] = { Mob = "Cocoa Warrior", Pos = Vector3.new(95, 73, -12309) },
    ["Demonic Wisp"] = { Mob = "Demonic Soul", Pos = Vector3.new(-9579, 6, 6194) },
    ["Ectoplasm"] = { Mob = "Ship Deckhand", Pos = Vector3.new(923, 125, 32885) },
    ["Fish Tail"] = { Mob = "Fishman Warrior", Pos = Vector3.new(61163, 19, 1569) },
    ["Magma Ore"] = { Mob = "Military Soldier", Pos = Vector3.new(-5231, 12, 8503) },
    ["Vampire Fang"] = { Mob = "Vampire", Pos = Vector3.new(-5491, 48, -794) },
    ["Mini Tusk"] = { Mob = "Mythological Pirate", Pos = Vector3.new(-13446, 413, -7760) },
    ["Scrap Metal"] = { Mob = "Pirate Millionaire", Pos = Vector3.new(-712, 98, 5711) },
    ["Leather"] = { Mob = "Monkey", Pos = Vector3.new(-1497, 23, 37) },
    ["Angel Wings"] = { Mob = "God's Guard", Pos = Vector3.new(-7859, 5545, -380) },
}

local BOSS_DATABASE = {
    -- Sea 1
    ["The Gorilla King"] = { Mob = "The Gorilla King", Quest = "JungleQuest", QLevel = 3, Pos = Vector3.new(-1240, 7, -500), Sea = 1 },
    ["Bobby"] = { Mob = "Bobby", Quest = "BuggyQuest1", QLevel = 3, Pos = Vector3.new(-1142, 15, 4134), Sea = 1 },
    ["The Saw"] = { Mob = "The Saw", Quest = "", QLevel = 1, Pos = Vector3.new(-680, 15, 4300), Sea = 1 },
    ["Yeti"] = { Mob = "Yeti", Quest = "SnowQuest", QLevel = 3, Pos = Vector3.new(1185, 106, -1519), Sea = 1 },
    ["Mob Leader"] = { Mob = "Mob Leader", Quest = "", QLevel = 1, Pos = Vector3.new(-2850, 7, 5300), Sea = 1 },
    ["Vice Admiral"] = { Mob = "Vice Admiral", Quest = "MarineQuest2", QLevel = 2, Pos = Vector3.new(-4843, 22, 4360), Sea = 1 },
    ["Saber Expert"] = { Mob = "Saber Expert", Quest = "", QLevel = 1, Pos = Vector3.new(-1497, 23, 37), Sea = 1 },
    ["Warden"] = { Mob = "Warden", Quest = "PrisonerQuest", QLevel = 3, Pos = Vector3.new(5130, 4, 480), Sea = 1 },
    ["Chief Warden"] = { Mob = "Chief Warden", Quest = "PrisonerQuest", QLevel = 4, Pos = Vector3.new(5130, 4, 480), Sea = 1 },
    ["Swan"] = { Mob = "Swan", Quest = "PrisonerQuest", QLevel = 5, Pos = Vector3.new(5130, 4, 480), Sea = 1 },
    ["Magma Admiral"] = { Mob = "Magma Admiral", Quest = "MagmaQuest", QLevel = 3, Pos = Vector3.new(-5800, 77, 8800), Sea = 1 },
    ["Fishman Lord"] = { Mob = "Fishman Lord", Quest = "FishmanQuest", QLevel = 3, Pos = Vector3.new(61900, 19, 1500), Sea = 1 },
    ["Wysper"] = { Mob = "Wysper", Quest = "SkyExp1Quest", QLevel = 3, Pos = Vector3.new(-7859, 5545, -380), Sea = 1 },
    ["Thunder God"] = { Mob = "Thunder God", Quest = "SkyExp2Quest", QLevel = 3, Pos = Vector3.new(-7752, 5607, -1490), Sea = 1 },
    ["Cyborg"] = { Mob = "Cyborg", Quest = "FountainQuest", QLevel = 3, Pos = Vector3.new(5259, 39, 4050), Sea = 1 },
    ["Greybeard"] = { Mob = "Greybeard", Quest = "", QLevel = 1, Pos = Vector3.new(-5035, 29, 4325), Sea = 1 },

    -- Sea 2
    ["Diamond"] = { Mob = "Diamond", Quest = "Area1Quest", QLevel = 3, Pos = Vector3.new(-1580, 198, -120), Sea = 2 },
    ["Jeremy"] = { Mob = "Jeremy", Quest = "Area2Quest", QLevel = 3, Pos = Vector3.new(2314, 448, 786), Sea = 2 },
    ["Fajita"] = { Mob = "Fajita", Quest = "FajitaQuest", QLevel = 1, Pos = Vector3.new(-2440, 73, -3217), Sea = 2 },
    ["Don Swan"] = { Mob = "Don Swan", Quest = "SwanBossQuest", QLevel = 1, Pos = Vector3.new(2284, 15, 804), Sea = 2 },
    ["Smoke Admiral"] = { Mob = "Smoke Admiral", Quest = "IceAdmiralQuest", QLevel = 1, Pos = Vector3.new(-5086, 16, -5389), Sea = 2 },
    ["Awakened Ice Admiral"] = { Mob = "Awakened Ice Admiral", Quest = "CastleBossQuest", QLevel = 1, Pos = Vector3.new(6040, 29, -6226), Sea = 2 },
    ["Tide Keeper"] = { Mob = "Tide Keeper", Quest = "ForgottenBossQuest", QLevel = 1, Pos = Vector3.new(-3800, 77, -11000), Sea = 2 },
    ["Darkbeard"] = { Mob = "Darkbeard", Quest = "", QLevel = 1, Pos = Vector3.new(3700, 16, -3500), Sea = 2 },
    ["Cursed Captain"] = { Mob = "Cursed Captain", Quest = "", QLevel = 1, Pos = Vector3.new(923, 125, 32885), Sea = 2 },
    ["Order"] = { Mob = "Order", Quest = "", QLevel = 1, Pos = Vector3.new(-5800, 16, -5000), Sea = 2 },

    -- Sea 3
    ["Stone"] = { Mob = "Stone", Quest = "PortTownQuest", QLevel = 3, Pos = Vector3.new(-1050, 40, 6790), Sea = 3 },
    ["Hydra Leader"] = { Mob = "Hydra Leader", Quest = "HydraQuest", QLevel = 3, Pos = Vector3.new(5749, 610, -267), Sea = 3 },
    ["Kilo Admiral"] = { Mob = "Kilo Admiral", Quest = "AmazonQuest", QLevel = 3, Pos = Vector3.new(2800, 1030, -7000), Sea = 3 },
    ["Captain Elephant"] = { Mob = "Captain Elephant", Quest = "ElephantQuest", QLevel = 1, Pos = Vector3.new(-13390, 318, -8400), Sea = 3 },
    ["Beautiful Pirate"] = { Mob = "Beautiful Pirate", Quest = "BeautifulPirateQuest", QLevel = 1, Pos = Vector3.new(5250, 20, 100), Sea = 3 },
    ["Cake Queen"] = { Mob = "Cake Queen", Quest = "CakeQueenQuest", QLevel = 1, Pos = Vector3.new(-710, 381, -11150), Sea = 3 },
    ["Longma"] = { Mob = "Longma", Quest = "", QLevel = 1, Pos = Vector3.new(-10220, 332, -9450), Sea = 3 },
    ["Soul Reaper"] = { Mob = "Soul Reaper", Quest = "", QLevel = 1, Pos = Vector3.new(-9515, 142, 5535), Sea = 3 },
    ["Rip Indra"] = { Mob = "rip_indra True Form", Quest = "", QLevel = 1, Pos = Vector3.new(-5330, 424, -2640), Sea = 3 },
    ["Cake Prince"] = { Mob = "Cake Prince", Quest = "", QLevel = 1, Pos = Vector3.new(-2021, 38, -12028), Sea = 3 },
    ["Dough King"] = { Mob = "Dough King", Quest = "", QLevel = 1, Pos = Vector3.new(-2021, 38, -12028), Sea = 3 },
}

--[[ Get quest for player's current level ]]
function Utility.GetQuestForLevel(lvl)
    local curLevel = lvl or (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
    local bestQuest = LEVEL_QUEST_DATA[1]
    for _, q in ipairs(LEVEL_QUEST_DATA) do
        if curLevel >= q.Min and curLevel <= q.Max then
            return q
        elseif curLevel >= q.Min then
            bestQuest = q
        end
    end
    return bestQuest
end

local patrolState = {
    index = 1,
    lastTime = 0,
    currentMob = "",
}

--[[ Lấy vị trí tuần tra kích hoạt quái spawn nếu có danh sách SpawnPoints ]]
function Utility.GetSpawnPatrolPos(qData)
    if not qData then return Vector3.zero end
    local spList = qData.SpawnPoints
    if spList and #spList > 0 then
        local now = os.clock()
        if patrolState.currentMob ~= qData.Mob then
            patrolState.currentMob = qData.Mob
            patrolState.index = 1
            patrolState.lastTime = now
        elseif now - patrolState.lastTime > 2.0 then
            patrolState.lastTime = now
            patrolState.index = (patrolState.index % #spList) + 1
        end
        return spList[patrolState.index]
    end
    return qData.MobPos
end

--[[ Check if player already has an active quest ]]
function Utility.HasActiveQuest()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local mainGui = pg and pg:FindFirstChild("Main")
    local questGui = mainGui and mainGui:FindFirstChild("Quest")
    return questGui and questGui.Visible
end

--[[ Get text description of currently active quest ]]
function Utility.GetActiveQuestText()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local mainGui = pg and pg:FindFirstChild("Main")
    local questGui = mainGui and mainGui:FindFirstChild("Quest")
    if questGui and questGui.Visible then
        local container = questGui:FindFirstChild("Container")
        local title = container and container:FindFirstChild("QuestTitle")
        local textLabel = title and (title:FindFirstChild("Title") or title:FindFirstChildOfClass("TextLabel") or (title:IsA("TextLabel") and title))
        if textLabel and textLabel.Text ~= "" then
            return textLabel.Text
        end
    end
    return ""
end

--[[ Verify if active quest matches the target mob ]]
function Utility.IsQuestMatchingMob(mobName)
    if not Utility.HasActiveQuest() then return false end
    if not mobName or mobName == "" then return true end
    local qText = Utility.GetActiveQuestText():lower()
    if qText == "" then return true end
    local target = mobName:lower()
    if qText:find(target, 1, true) then return true end
    for word in target:gmatch("%w+") do
        if #word >= 4 and qText:find(word, 1, true) then
            return true
        end
    end
    return false
end

--[[ Call CommF_ to abandon quest if mismatched ]]
function Utility.AbandonQuest()
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if commF and commF:IsA("RemoteFunction") then
        pcall(function()
            commF:InvokeServer("AbandonQuest")
        end)
    end
end

--[[ Call CommF_ to start quest ]]
function Utility.StartQuest(qName, qLevel)
    if not qName or qName == "" then return end
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if commF and commF:IsA("RemoteFunction") then
        pcall(function()
            commF:InvokeServer("StartQuest", qName, qLevel or 1)
        end)
    end
end

--[[ Tìm thông tin Quest gắn liền với tên quái cụ thể (Dùng cho cả Auto Farm và Testing Milestones) ]]
function Utility.GetQuestDataForMob(mobName)
    if not mobName or mobName == "" then return nil end
    local lowerName = mobName:lower()
    for _, q in ipairs(LEVEL_FARM_DATA) do
        if q.Mob == mobName or q.Mob:lower() == lowerName then
            return q
        end
    end
    for _, q in ipairs(LEVEL_FARM_DATA) do
        if q.Mob:lower():find(lowerName, 1, true) or lowerName:find(q.Mob:lower(), 1, true) then
            return q
        end
    end
    return nil
end

--[[ Đảm bảo nhận đúng quest của quái mục tiêu trước khi tấn công ]]
function Utility.EnsureQuestForMob(mobName)
    local qData = Utility.GetQuestDataForMob(mobName)
    if not qData then return true end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    -- 1. Nếu đang có quest nhưng quest đó KHÔNG PHẢI của quái mục tiêu -> HỦY QUEST CŨ NGAY
    if Utility.HasActiveQuest() and not Utility.IsQuestMatchingMob(qData.Mob) then
        Utility.AbandonQuest()
        task.wait(0.25)
        return false
    end

    -- 2. Nếu chưa có quest -> Bay tới NPC giao quest và nhận quest của quái mục tiêu
    if not Utility.HasActiveQuest() then
        currentBringData = nil
        Utility.CheckAndHandleUnderwaterTransition(qData.GiverPos)
        local giverDist = (root.Position - qData.GiverPos).Magnitude
        if giverDist > 25 then
            Utility.PhysicsFlyTo(qData.GiverPos + Vector3.new(0, 5, 0), S.TeleportFlySpeed or 200)
            return false
        else
            Utility.StartQuest(qData.Quest, qData.QLevel)
            task.wait(0.35)
            return Utility.HasActiveQuest() and Utility.IsQuestMatchingMob(qData.Mob)
        end
    end

    return true
end

--[[ Find enemy by mob name ]]
function Utility.GetEnemyByName(mobName)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = root and root.Position or Vector3.zero

    local nearest = nil
    local shortestDist = math.huge

    for _, enemy in ipairs(enemies:GetChildren()) do
        if enemy:IsA("Model") and (not mobName or enemy.Name:lower():find(mobName:lower())) then
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local eRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")
            if hum and hum.Health > 0 and eRoot then
                local dist = (eRoot.Position - myPos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    nearest = enemy
                end
            end
        end
    end
    return nearest
end

local currentBringData = nil

--[[ Vòng lặp Stepped 60 FPS: Kéo quái mượt mà 100% không giật và khóa vị trí quái ]]
_conns["bringMobStepped"] = RunService.Stepped:Connect(function(_, dt)
    if not S.BringMobEnabled or not currentBringData or not currentBringData.Mobs then return end
    local center = currentBringData.Center
    if not center then return end
    if center.Y < 10 then center = Vector3.new(center.X, 10, center.Z) end

    local speed = S.BringMobSpeed or 110
    local delta = dt or 0.016
    local step = speed * delta

    for i = #currentBringData.Mobs, 1, -1 do
        local item = currentBringData.Mobs[i]
        local model = item.Model
        local root = item.Root
        local hum = item.Hum

        if root and root.Parent and hum and hum.Health > 0 then
            for _, part in ipairs(model:GetChildren()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end

            hum.WalkSpeed = 0
            hum.PlatformStand = true
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero

            local curPos = root.Position
            local dist = (center - curPos).Magnitude
            if dist > 2 then
                local dir = (center - curPos).Unit
                local moveDist = math.min(dist, step)
                local nextPos = curPos + dir * moveDist
                if nextPos.Y < 10 then nextPos = Vector3.new(nextPos.X, 10, nextPos.Z) end
                root.CFrame = CFrame.new(nextPos)
            else
                root.CFrame = CFrame.new(center)
            end
        else
            table.remove(currentBringData.Mobs, i)
        end
    end
end)

--[[ Gom quái về điểm tâm với tốc độ mượt mà và giới hạn Y >= 10 ]]
function Utility.BringMatchingMobs(mobName, maxRadius)
    local radius = maxRadius or S.BringMobDistance or 240
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then 
        currentBringData = nil
        return nil, nil, {} 
    end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.zero

    local matchingMobs = {}
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy:IsA("Model") and (not mobName or enemy.Name:lower():find(mobName:lower())) then
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")
            if hum and hum.Health > 0 and root then
                table.insert(matchingMobs, { Model = enemy, Root = root, Hum = hum, Pos = root.Position })
            end
        end
    end

    if #matchingMobs == 0 then 
        currentBringData = nil
        return nil, nil, {} 
    end

    table.sort(matchingMobs, function(a, b)
        return (a.Pos - myPos).Magnitude < (b.Pos - myPos).Magnitude
    end)

    local primary = matchingMobs[1]
    local cluster = { primary }

    for i = 2, #matchingMobs do
        local candidate = matchingMobs[i]
        local d = (candidate.Pos - primary.Pos).Magnitude
        if d <= radius then
            table.insert(cluster, candidate)
        end
    end

    local sumPos = Vector3.zero
    for _, item in ipairs(cluster) do
        sumPos = sumPos + item.Pos
    end
    local centerPos = sumPos / #cluster

    local validCluster = {}
    for _, item in ipairs(cluster) do
        if (item.Pos - centerPos).Magnitude <= radius then
            table.insert(validCluster, item)
        end
    end
    if #validCluster == 0 then validCluster = { primary } end

    sumPos = Vector3.zero
    for _, item in ipairs(validCluster) do
        sumPos = sumPos + item.Pos
    end
    centerPos = sumPos / #validCluster
    if centerPos.Y < 10 then 
        centerPos = Vector3.new(centerPos.X, 10, centerPos.Z) 
    end

    if S.BringMobEnabled then
        currentBringData = { Center = centerPos, Mobs = validCluster }
    else
        currentBringData = nil
    end

    return centerPos, primary.Model, validCluster
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     SPECIAL QUESTS & AUTO NEXT SEA PROGRESSION SYSTEM
   ═══════════════════════════════════════════════════════════════════════════ ]]

local _inventoryCache = {}
local _lastInventoryFetch = 0
local _locallyOwnedItems = {}

function Utility.GetCachedInventory()
    local now = os.clock()
    if (now - _lastInventoryFetch > 4.0) or #_inventoryCache == 0 then
        _lastInventoryFetch = now
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if commF then
            pcall(function()
                local inv = commF:InvokeServer("getInventory")
                if typeof(inv) == "table" then
                    _inventoryCache = inv
                    for _, itm in pairs(inv) do
                        if typeof(itm) == "table" and itm.Name then
                            _locallyOwnedItems[itm.Name] = true
                        elseif typeof(itm) == "string" then
                            _locallyOwnedItems[itm] = true
                        end
                    end
                end
            end)
        end
    end
    return _inventoryCache
end

function Utility.HasItem(itemName)
    if not itemName or itemName == "" then return false end
    if _locallyOwnedItems[itemName] then return true end

    -- 1. Kiểm tra trong túi đồ đang có (Backpack)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(itemName) then 
        _locallyOwnedItems[itemName] = true
        return true 
    end

    -- 2. Kiểm tra nếu đang trang bị cầm trên tay (Character)
    local ch = LocalPlayer.Character
    if ch and ch:FindFirstChild(itemName) then 
        _locallyOwnedItems[itemName] = true
        return true 
    end

    -- 3. Kiểm tra qua dữ liệu Inventory Remote đã cache
    local inv = Utility.GetCachedInventory()
    if typeof(inv) == "table" then
        for _, item in pairs(inv) do
            if typeof(item) == "table" and item.Name then
                if item.Name == itemName or string.find(item.Name:lower(), itemName:lower(), 1, true) then
                    _locallyOwnedItems[itemName] = true
                    return true
                end
            elseif typeof(item) == "string" and (item == itemName or string.find(item:lower(), itemName:lower(), 1, true)) then
                _locallyOwnedItems[itemName] = true
                return true
            end
        end
    end

    return false
end

function Utility.EquipItemByName(itemName)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if ch and ch:FindFirstChild(itemName) then return ch[itemName] end
    if bp and bp:FindFirstChild(itemName) and hum then
        local t = bp[itemName]
        hum:EquipTool(t)
        return t
    end

    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if commF then
        for _, m in ipairs(MELEE_DATABASE) do
            if m.Name == itemName and m.Remote then
                pcall(function()
                    commF:InvokeServer(m.Remote, unpack(m.Args or {}))
                end)
                task.wait(0.15)
                break
            end
        end
        pcall(function()
            commF:InvokeServer("LoadItem", itemName)
        end)
        task.wait(0.15)
    end

    bp = LocalPlayer:FindFirstChild("Backpack")
    ch = LocalPlayer.Character
    hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if ch and ch:FindFirstChild(itemName) then return ch[itemName] end
    if bp and bp:FindFirstChild(itemName) and hum then
        local t = bp[itemName]
        hum:EquipTool(t)
        return t
    end

    return nil
end

function Utility.HasSaber()
    return Utility.HasItem("Saber")
end

--[[ Kiểm tra tự nhận diện cửa Saber trong Workspace.Map.Jungle.Final:
     - Trước khi mở: Các Part có Transparency == 0
     - Khi đã mở xong: Các Part có Transparency == 1
]]
function Utility.IsSaberDoorUnlocked()
    if Utility.HasSaber() then return true end

    local jungleMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle")
    local finalFolder = (jungleMap and jungleMap:FindFirstChild("Final")) or workspace:FindFirstChild("Final", true)
    
    if finalFolder then
        local checkCount = 0
        local openCount = 0
        for _, child in ipairs(finalFolder:GetChildren()) do
            if child:IsA("BasePart") and child.Name ~= "Invis" then
                checkCount = checkCount + 1
                if child.Transparency >= 0.8 then
                    openCount = openCount + 1
                end
            end
        end
        if checkCount > 0 and (openCount / checkCount) >= 0.5 then
            return true
        end
    end

    return false
end

--[[ Tìm kiếm và lấy vị trí 5 Plates trong Workspace.Map.Jungle.QuestPlates ]]
function Utility.GetJungleQuestPlates()
    local plates = {}
    local fallbackPositions = {
        [1] = Vector3.new(-1610, 36, 148),
        [2] = Vector3.new(-1240, 12, -490),
        [3] = Vector3.new(-1612, 11, 155),
        [4] = Vector3.new(-1495, 23, 35),
        [5] = Vector3.new(-1338, 12, -460),
    }

    local jungleMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle")
    local questPlatesFolder = (jungleMap and jungleMap:FindFirstChild("QuestPlates"))
        or workspace:FindFirstChild("QuestPlates", true)

    for i = 1, 5 do
        local plateName = "Plate" .. tostring(i)
        local plateObj = questPlatesFolder and questPlatesFolder:FindFirstChild(plateName)
        if not plateObj then
            plateObj = workspace:FindFirstChild(plateName, true)
        end

        local pos = nil
        local part = nil
        if plateObj then
            if plateObj:IsA("BasePart") then
                pos = plateObj.Position
                part = plateObj
            elseif plateObj:IsA("Model") then
                part = plateObj.PrimaryPart or plateObj:FindFirstChildOfClass("BasePart") or plateObj:FindFirstChild("Button") or plateObj:FindFirstChild("Plate")
                pos = part and part.Position or (plateObj:GetPivot() and plateObj:GetPivot().Position)
            end
        end

        if not pos then
            pos = fallbackPositions[i]
        end

        plates[i] = {
            Index = i,
            Name = plateName,
            Instance = plateObj,
            Part = part,
            Position = pos
        }
    end

    return plates
end

--[[ Lấy vị trí Torch từ Workspace.Map.Jungle.Torch ]]
function Utility.GetJungleTorchPos()
    local jungleMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle")
    local torchObj = (jungleMap and jungleMap:FindFirstChild("Torch")) or workspace:FindFirstChild("Torch", true)
    if torchObj then
        if torchObj:IsA("BasePart") then return torchObj.Position, torchObj end
        if torchObj:IsA("Model") then
            local part = torchObj.PrimaryPart or torchObj:FindFirstChildOfClass("BasePart")
            if part then return part.Position, torchObj end
            if torchObj:GetPivot() then return torchObj:GetPivot().Position, torchObj end
        end
    end
    return Vector3.new(-1610, 11, 155), torchObj
end

--[[ Lấy vị trí Burn từ Workspace.Map.Desert.Burn ]]
function Utility.GetDesertBurnDoor()
    local desertMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Desert")
    local burnObj = (desertMap and desertMap:FindFirstChild("Burn")) or workspace:FindFirstChild("Burn", true)
    if burnObj then
        if burnObj:IsA("BasePart") then return burnObj.Position, burnObj end
        if burnObj:IsA("Model") then
            local part = burnObj.PrimaryPart or burnObj:FindFirstChildOfClass("BasePart")
            if part then return part.Position, burnObj end
            if burnObj:GetPivot() then return burnObj:GetPivot().Position, burnObj end
        end
    end
    return nil, nil
end

--[[ Lấy vị trí Cup từ Workspace.Map.Desert.Cup ]]
function Utility.GetDesertCupPos()
    local desertMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Desert")
    local cupObj = (desertMap and desertMap:FindFirstChild("Cup")) or workspace:FindFirstChild("Cup", true)
    if cupObj then
        if cupObj:IsA("BasePart") then return cupObj.Position, cupObj end
        if cupObj:IsA("Model") then
            local part = cupObj:FindFirstChild("Part") or cupObj.PrimaryPart or cupObj:FindFirstChildOfClass("BasePart")
            if part then return part.Position, cupObj end
            if cupObj:GetPivot() then return cupObj:GetPivot().Position, cupObj end
        end
    end
    return Vector3.new(1113, 4, 4350), cupObj
end

--[[ Lấy vị trí NPC từ Workspace.NPCs ]]
function Utility.GetNPCLocation(npcNames)
    local names = typeof(npcNames) == "table" and npcNames or { npcNames }
    local npcsFolder = workspace:FindFirstChild("NPCs")
    for _, name in ipairs(names) do
        local npc = (npcsFolder and npcsFolder:FindFirstChild(name, true)) or workspace:FindFirstChild(name, true)
        if npc and npc:IsA("Model") then
            local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildOfClass("BasePart")
            if root then return root.Position, npc end
        end
    end
    return nil, nil
end

--[[ Di chuyển bằng cách bay vật lý và chờ đến khi thực sự đến gần vị trí mục tiêu (Không dùng CFrame trực tiếp) ]]
function Utility.FlyAndWaitArrival(targetPos, speed, timeout, reachDist)
    reachDist = reachDist or 8
    timeout = timeout or 35
    local flySpeed = speed or S.TeleportFlySpeed or 200
    local t0 = os.clock()

    -- Xử lý chuyển vùng qua Whirlpool nếu điểm đến nằm khác khu vực (Underwater City)
    Utility.CheckAndHandleUnderwaterTransition(targetPos)

    Utility.PhysicsFlyTo(targetPos, flySpeed)
    while os.clock() - t0 < timeout do
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - targetPos).Magnitude <= reachDist then
            task.wait(0.2)
            Utility.StopPhysicsFly()
            return true
        end
        task.wait(0.1)
    end
    Utility.StopPhysicsFly()
    return false
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     1. SABER QUEST (SHANKS / SABER EXPERT - LEVEL 200+)
   ═══════════════════════════════════════════════════════════════════════════ ]]

local saberQuestRunning = false
function Utility.HandleSaberQuest(forceRun)
    if saberQuestRunning then return end
    saberQuestRunning = true
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if not commF then saberQuestRunning = false; return end

        local flySpeed = S.TeleportFlySpeed or 200

        -- 1. KIỂM TRA ĐÃ CÓ SABER CHƯA
        if not forceRun and Utility.HasSaber() then
            UILib.Notify("Saber Quest", "You already own the Saber sword in inventory!", 4)
            saberQuestRunning = false
            return
        end

        -- 2. TỰ ĐỘNG NHẬN DIỆN CỬA FINAL (WORKSPACE.MAP.JUNGLE.FINAL)
        -- Trước khi mở: Transparency == 0. Đã mở: Transparency == 1
        -- Nếu cửa đã mở và không ép chạy (forceRun): KHÔNG làm lại quest, chỉ đánh Boss nếu có mặt trong server
        if not forceRun and Utility.IsSaberDoorUnlocked() then
            local saberExpert = Utility.GetEnemyByName("Saber Expert")
            if saberExpert then
                UILib.Notify("Saber Quest", "Saber door is open & Saber Expert detected! Flying to defeat Boss...", 4)
                Utility.FlyAndWaitArrival(Vector3.new(-1405, 29, 3), flySpeed, 35, 5)
                local t1 = os.clock()
                while os.clock() - t1 < 45 and not Utility.HasSaber() do
                    saberExpert = Utility.GetEnemyByName("Saber Expert")
                    if saberExpert then
                        local _, _, seRoot = Utility.GetEnemyRootCFrame(saberExpert)
                        if seRoot then
                            Utility.FlyAboveTarget(seRoot.CFrame, S.AttackHeight or 40, flySpeed)
                            local wType = S.SelectedWeaponType or "Melee"
                            if wType == "Melee" then Utility.AttackMelee(saberExpert, seRoot)
                            elseif wType == "Sword" then Utility.AttackSword(saberExpert, seRoot)
                            elseif wType == "Fruit" then Utility.AttackFruitM1(saberExpert, seRoot)
                            elseif wType == "Gun" then Utility.AttackGun(saberExpert, seRoot)
                            end
                        end
                    else
                        break
                    end
                    task.wait(0.04)
                end
                Utility.StopPhysicsFly()
            else
                UILib.Notify("Saber Quest", "Saber Door is already open! Boss not spawned yet.", 4)
            end
            saberQuestRunning = false
            return
        end

        -- 3. NẾU CỬA CHƯA MỞ HOẶC FORCE RUN TEST: CHẠY QUY TRÌNH GIẢI PUZZLE MỞ CỬA
        UILib.Notify("Saber Quest", "Starting puzzle quest sequence...", 4)
        local skipToStep5 = false

        -- BƯỚC 1: 5 NÚT BẤM JUNGLE (QUEST PLATES) (Chỉ làm khi chưa có Relic, Water Cup, Cup)
        if not Utility.HasItem("Relic") and not Utility.HasItem("Water Cup") and not Utility.HasItem("Cup") then
            local plates = Utility.GetJungleQuestPlates()
            for i = 1, 5 do
                local plate = plates[i]
                local pPos = plate and plate.Position or Vector3.new(-1610, 36, 148)
                UILib.Notify("Saber Quest", "Flying to Quest Plate " .. i .. "/5 (Workspace.Map.Jungle.QuestPlates)...", 3)
                
                -- Bay đến tận nơi plate
                Utility.FlyAndWaitArrival(pPos + Vector3.new(0, 1.2, 0), flySpeed, 25, 4)
                task.wait(0.3)

                -- Khi chạm vào plate, gửi tín hiệu ProQuestProgress Plate lên Server
                pcall(function()
                    commF:InvokeServer("ProQuestProgress", "Plate", i)
                end)

                -- Hỗ trợ chạm vật lý touch event nếu part tồn tại
                if plate.Part and (firetouchinterest or fire_touch_interest) then
                    local ft = firetouchinterest or fire_touch_interest
                    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if r then
                        pcall(function()
                            ft(r, plate.Part, 0)
                            task.wait(0.05)
                            ft(r, plate.Part, 1)
                        end)
                    end
                end
                task.wait(0.6)
            end
        end

        -- BƯỚC 2: NHẶT ĐUỐC (TORCH) TỪ WORKSPACE.MAP.JUNGLE.TORCH (Bay đến xong chuyển sang bước tiếp theo)
        if not Utility.HasItem("Relic") and not Utility.HasItem("Water Cup") and not Utility.HasItem("Cup") then
            local torchPos, torchObj = Utility.GetJungleTorchPos()
            UILib.Notify("Saber Quest", "Flying to Jungle basement for Torch (Workspace.Map.Jungle.Torch)...", 3)
            Utility.FlyAndWaitArrival(torchPos, flySpeed, 25, 3)
            task.wait(1.5)
        end

        -- BƯỚC 3: ĐỐT CỬA SA MẠC (WORKSPACE.MAP.DESERT.BURN)
        if not Utility.HasItem("Relic") and not Utility.HasItem("Water Cup") and not Utility.HasItem("Cup") then
            local burnPos, burnObj = Utility.GetDesertBurnDoor()
            if not burnObj or not burnPos then
                -- Nếu không tìm thấy vị trí của Burn -> trực tiếp chuyển qua bước 5
                UILib.Notify("Saber Quest", "Burn door not found (already opened), skipping directly to Step 5...", 3)
                skipToStep5 = true
            else
                UILib.Notify("Saber Quest", "Flying to Desert Burn door (Workspace.Map.Desert.Burn)...", 3)
                Utility.FlyAndWaitArrival(burnPos, flySpeed, 40, 4)
                Utility.EquipItemByName("Torch")
                task.wait(0.5)

                -- Kiểm tra nếu Burn đã biến mất thì đến bước tiếp theo
                local t0 = os.clock()
                while os.clock() - t0 < 5 do
                    local _, currentBurn = Utility.GetDesertBurnDoor()
                    if not currentBurn or not currentBurn.Parent then
                        break
                    end
                    task.wait(0.4)
                end
                task.wait(0.8)
            end
        end

        -- BƯỚC 4: LẤY CUP TỪ WORKSPACE.MAP.DESERT.CUP (Nếu không bị skip sang bước 5)
        if not skipToStep5 and not Utility.HasItem("Cup") and not Utility.HasItem("Water Cup") and not Utility.HasItem("Relic") then
            local cupPos, cupObj = Utility.GetDesertCupPos()
            UILib.Notify("Saber Quest", "Flying to Desert Cup (Workspace.Map.Desert.Cup)...", 3)
            Utility.FlyAndWaitArrival(cupPos, flySpeed, 20, 3)
            task.wait(1.5)

            -- Kiểm tra trong Backpack / Character đã có Cup chưa
            local t0 = os.clock()
            while os.clock() - t0 < 4 and not Utility.HasItem("Cup") do
                task.wait(0.3)
            end
        end

        -- BƯỚC 5: BAY ĐẾN 1397, 37, -1325 VÀ TRANG BỊ CUP, GỬI PROQUESTPROGRESS FILLCUP
        if not Utility.HasItem("Relic") then
            UILib.Notify("Saber Quest", "Flying to Frozen Village icicle (1397, 37, -1325)...", 3)
            Utility.FlyAndWaitArrival(Vector3.new(1397, 37, -1325), flySpeed, 40, 3)
            Utility.EquipItemByName("Cup")
            task.wait(2.0)

            -- Gửi tín hiệu ProQuestProgress FillCup lên Server kèm Cup Tool
            pcall(function()
                local cupTool = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Cup"))
                    or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Cup"))
                commF:InvokeServer("ProQuestProgress", "FillCup", cupTool)
            end)
            task.wait(1.0)
        end

        -- BƯỚC 6: BAY ĐẾN SICK MAN (WORKSPACE.NPCS.SICK MAN) VÀ KÍCH HOẠT PROQUESTPROGRESS SICKMAN
        if not Utility.HasItem("Relic") then
            local sickManPos = Utility.GetNPCLocation({"Sick Man", "SickMan"}) or Vector3.new(1392, 87, -1297)
            UILib.Notify("Saber Quest", "Flying to Sick Man in NPCs (Workspace.NPCs.Sick Man)...", 3)
            Utility.FlyAndWaitArrival(sickManPos, flySpeed, 25, 5)
            if not Utility.EquipItemByName("Water Cup") then
                Utility.EquipItemByName("Cup")
            end
            task.wait(0.5)
            pcall(function()
                commF:InvokeServer("ProQuestProgress", "SickMan")
            end)
            task.wait(0.8)
        end

        -- BƯỚC 7 & 8: GẶP RICH MAN / RICH SON Ở PIRATE VILLAGE, DIỆT MOB LEADER & LẤY RELIC
        if not Utility.HasItem("Relic") then
            -- BƯỚC 7: Bay đến Pirate Village gặp Rich Man / Rich Son
            local richManPos = Utility.GetNPCLocation({"Rich Man", "Rich Son", "RichMan", "RichSon"}) or Vector3.new(-909, 14, 4078)
            UILib.Notify("Saber Quest", "Flying to Rich Man in Pirate Village (Workspace.NPCs)...", 3)
            Utility.FlyAndWaitArrival(richManPos, flySpeed, 35, 5)
            task.wait(0.5)
            pcall(function()
                commF:InvokeServer("ProQuestProgress", "RichSon")
            end)
            task.wait(0.8)

            -- BƯỚC 8: Bay đến Đảo Mob, tiêu diệt Mob Leader
            UILib.Notify("Saber Quest", "Flying to Mob Island to defeat Mob Leader...", 3)
            Utility.FlyAndWaitArrival(Vector3.new(-2850, 7, 5350), flySpeed, 40, 20)
            local t0 = os.clock()
            while os.clock() - t0 < 30 do
                local mobLeader = Utility.GetEnemyByName("Mob Leader")
                if mobLeader then
                    local _, _, mlRoot = Utility.GetEnemyRootCFrame(mobLeader)
                    if mlRoot then
                        Utility.FlyAboveTarget(mlRoot.CFrame, S.AttackHeight or 40, flySpeed)
                        local wType = S.SelectedWeaponType or "Melee"
                        if wType == "Melee" then Utility.AttackMelee(mobLeader, mlRoot)
                        elseif wType == "Sword" then Utility.AttackSword(mobLeader, mlRoot)
                        elseif wType == "Fruit" then Utility.AttackFruitM1(mobLeader, mlRoot)
                        elseif wType == "Gun" then Utility.AttackGun(mobLeader, mlRoot)
                        end
                    end
                else
                    task.wait(0.5)
                    local mlCheck = Utility.GetEnemyByName("Mob Leader")
                    if not mlCheck then break end
                end
                task.wait(0.04)
            end
            Utility.StopPhysicsFly()

            -- Quay lại Bước 7: Kích hoạt lại RichSon 1 lần nữa để lấy Relic
            UILib.Notify("Saber Quest", "Returning to Rich Man to get Relic...", 3)
            richManPos = Utility.GetNPCLocation({"Rich Man", "Rich Son", "RichMan", "RichSon"}) or Vector3.new(-909, 14, 4078)
            Utility.FlyAndWaitArrival(richManPos, flySpeed, 35, 5)
            task.wait(0.5)
            pcall(function()
                commF:InvokeServer("ProQuestProgress", "RichSon")
            end)
            task.wait(1.0)
        end

        -- BƯỚC 9: BAY ĐẾN CỬA SABER, TRANG BỊ RELIC ĐỂ MỞ CỬA
        if Utility.HasItem("Relic") or not Utility.HasSaber() then
            UILib.Notify("Saber Quest", "Flying to Jungle Saber Door (-1405, 29, 3)...", 3)
            Utility.FlyAndWaitArrival(Vector3.new(-1405, 29, 3), flySpeed, 35, 5)
            if Utility.HasItem("Relic") then
                Utility.EquipItemByName("Relic")
                task.wait(1.5)
            end

            -- KIỂM TRA XEM SABER EXPERT (SHANKS) CÓ ĐANG XUẤT HIỆN HAY KHÔNG
            local saberExpert = Utility.GetEnemyByName("Saber Expert")
            if saberExpert then
                UILib.Notify("Saber Quest", "Fighting Saber Expert (Shanks)...", 4)
                local t1 = os.clock()
                while os.clock() - t1 < 45 and not Utility.HasSaber() do
                    saberExpert = Utility.GetEnemyByName("Saber Expert")
                    if saberExpert then
                        local _, _, seRoot = Utility.GetEnemyRootCFrame(saberExpert)
                        if seRoot then
                            Utility.FlyAboveTarget(seRoot.CFrame, S.AttackHeight or 40, flySpeed)
                            local wType = S.SelectedWeaponType or "Melee"
                            if wType == "Melee" then Utility.AttackMelee(saberExpert, seRoot)
                            elseif wType == "Sword" then Utility.AttackSword(saberExpert, seRoot)
                            elseif wType == "Fruit" then Utility.AttackFruitM1(saberExpert, seRoot)
                            elseif wType == "Gun" then Utility.AttackGun(saberExpert, seRoot)
                            end
                        end
                    else
                        break
                    end
                    task.wait(0.04)
                end
                Utility.StopPhysicsFly()
            else
                UILib.Notify("Saber Quest", "Door unlocked! Saber Expert not spawned yet, continuing level farm...", 3)
            end
        end

        if Utility.HasSaber() then
            UILib.Notify("Saber Quest", "Congratulations! Saber Quest completed & Saber acquired!", 5)
        end
        saberQuestRunning = false
    end)
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     2. THE SON QUEST (SICK MAN & RICH SON & MOB LEADER)
   ═══════════════════════════════════════════════════════════════════════════ ]]

local theSonQuestRunning = false
function Utility.StartTheSonQuest()
    if theSonQuestRunning then return end
    theSonQuestRunning = true
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if not commF then theSonQuestRunning = false; return end

        local flySpeed = S.TeleportFlySpeed or 200
        UILib.Notify("The Son Quest", "Starting The Son Quest (Rich Son & Sick Man)...", 4)

        -- 1. Bay đến nhà Sick Man ở Frozen Village
        local sickManPos = Utility.GetNPCLocation({"Sick Man", "SickMan"}) or Vector3.new(1392, 87, -1297)
        UILib.Notify("The Son Quest", "Flying to Sick Man in Frozen Village...", 3)
        Utility.FlyAndWaitArrival(sickManPos, flySpeed, 35, 5)
        task.wait(0.5)
        pcall(function() commF:InvokeServer("ProQuestProgress", "SickMan") end)
        task.wait(0.5)

        -- 2. Bay sang Pirate Village gặp Rich Son / Rich Man
        local richManPos = Utility.GetNPCLocation({"Rich Man", "Rich Son", "RichMan", "RichSon"}) or Vector3.new(-909, 14, 4078)
        UILib.Notify("The Son Quest", "Flying to Rich Man in Pirate Village...", 3)
        Utility.FlyAndWaitArrival(richManPos, flySpeed, 35, 5)
        task.wait(0.5)
        pcall(function() commF:InvokeServer("ProQuestProgress", "RichSon") end)
        task.wait(0.5)

        -- 3. Bay sang Mob Island tiêu diệt Mob Leader
        UILib.Notify("The Son Quest", "Flying to Mob Island to defeat Mob Leader...", 3)
        Utility.FlyAndWaitArrival(Vector3.new(-2850, 7, 5350), flySpeed, 40, 20)
        local t0 = os.clock()
        while os.clock() - t0 < 30 do
            local mobLeader = Utility.GetEnemyByName("Mob Leader")
            if mobLeader then
                local _, _, mlRoot = Utility.GetEnemyRootCFrame(mobLeader)
                if mlRoot then
                    Utility.FlyAboveTarget(mlRoot.CFrame, S.AttackHeight or 40, flySpeed)
                    local wType = S.SelectedWeaponType or "Melee"
                    if wType == "Melee" then Utility.AttackMelee(mobLeader, mlRoot)
                    elseif wType == "Sword" then Utility.AttackSword(mobLeader, mlRoot)
                    elseif wType == "Fruit" then Utility.AttackFruitM1(mobLeader, mlRoot)
                    elseif wType == "Gun" then Utility.AttackGun(mobLeader, mlRoot)
                    end
                end
            else
                task.wait(0.5)
                local mlCheck = Utility.GetEnemyByName("Mob Leader")
                if not mlCheck then break end
            end
            task.wait(0.04)
        end
        Utility.StopPhysicsFly()

        -- 4. Bay trở lại Rich Son nhận thưởng
        UILib.Notify("The Son Quest", "Flying back to Rich Man for reward / Relic...", 3)
        richManPos = Utility.GetNPCLocation({"Rich Man", "Rich Son", "RichMan", "RichSon"}) or Vector3.new(-909, 14, 4078)
        Utility.FlyAndWaitArrival(richManPos, flySpeed, 35, 5)
        task.wait(0.5)
        pcall(function() commF:InvokeServer("ProQuestProgress", "RichSon") end)
        task.wait(0.8)

        UILib.Notify("The Son Quest", "The Son Quest completed successfully!", 4)
        theSonQuestRunning = false
    end)
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     3. MILITARY DETECTIVE QUEST (SEA 2 PROGRESSION - LEVEL 700+)
   ═══════════════════════════════════════════════════════════════════════════ ]]

local detectiveQuestRunning = false
function Utility.HandleSea2EntranceQuest()
    if detectiveQuestRunning or Utility.GetCurrentSea() >= 2 then return end
    detectiveQuestRunning = true
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if not commF then detectiveQuestRunning = false; return end

        local flySpeed = S.TeleportFlySpeed or 200
        UILib.Notify("Military Detective", "Starting Military Detective Quest (Sea 2 entrance)...", 4)

        local prog = nil
        pcall(function() prog = commF:InvokeServer("DressrosaQuestProgress") end)

        -- 1. BƯỚC 1: NHẬN CHÌA KHÓA TỪ DETECTIVE TẠI PRISON
        if not Utility.HasItem("Key") and (typeof(prog) ~= "table" or prog.UsedKey ~= true) then
            UILib.Notify("Military Detective", "Flying to Military Detective at Prison...", 3)
            Utility.FlyAndWaitArrival(Vector3.new(4850, 5, 740), flySpeed, 35, 6)
            task.wait(0.5)
            pcall(function() commF:InvokeServer("requestEntrance") end)
            pcall(function() commF:InvokeServer("DressrosaQuestProgress", "Detective") end)
            task.wait(0.8)
        end

        -- 2. BƯỚC 2: MỞ CỬA HANG BĂNG TẠI FROZEN VILLAGE
        if Utility.HasItem("Key") then
            UILib.Notify("Military Detective", "Flying to Ice Cave door in Frozen Village...", 3)
            Utility.FlyAndWaitArrival(Vector3.new(1347, 37, -1325), flySpeed, 40, 5)
            Utility.EquipItemByName("Key")
            task.wait(1.5)
        end

        -- 3. BƯỚC 3: DIỆT BOSS ICE ADMIRAL NẾU CHƯA DIỆT
        if typeof(prog) ~= "table" or prog.KilledIceBoss ~= true then
            UILib.Notify("Military Detective", "Flying into Ice Cave to fight Ice Admiral...", 3)
            Utility.FlyAndWaitArrival(Vector3.new(1347, 37, -1325), flySpeed, 20, 15)
            local t0 = os.clock()
            while os.clock() - t0 < 40 do
                local iceBoss = Utility.GetEnemyByName("Ice Admiral")
                if iceBoss then
                    local _, _, ibRoot = Utility.GetEnemyRootCFrame(iceBoss)
                    if ibRoot then
                        Utility.FlyAboveTarget(ibRoot.CFrame, S.AttackHeight or 40, flySpeed)
                        local wType = S.SelectedWeaponType or "Melee"
                        if wType == "Melee" then Utility.AttackMelee(iceBoss, ibRoot)
                        elseif wType == "Sword" then Utility.AttackSword(iceBoss, ibRoot)
                        elseif wType == "Fruit" then Utility.AttackFruitM1(iceBoss, ibRoot)
                        elseif wType == "Gun" then Utility.AttackGun(iceBoss, ibRoot)
                        end
                    end
                else
                    task.wait(0.5)
                    local ibCheck = Utility.GetEnemyByName("Ice Admiral")
                    if not ibCheck then break end
                end
                task.wait(0.04)
            end
            Utility.StopPhysicsFly()
            task.wait(0.5)
        end

        -- 4. BƯỚC 4: BÁO CÁO LẠI CHO DETECTIVE TẠI PRISON
        UILib.Notify("Military Detective", "Flying back to Detective at Prison...", 3)
        Utility.FlyAndWaitArrival(Vector3.new(4850, 5, 740), flySpeed, 35, 6)
        task.wait(0.5)
        pcall(function() commF:InvokeServer("DressrosaQuestProgress", "Detective") end)
        task.wait(0.8)

        -- 5. BƯỚC 5: GẶP EXPERIENCED CAPTAIN TẠI MIDDLE TOWN ĐỂ DỊCH CHUYỂN SEA 2
        UILib.Notify("Military Detective", "Flying to Experienced Captain at Middle Town...", 3)
        Utility.FlyAndWaitArrival(Vector3.new(-650, 7.5, 1445), flySpeed, 35, 6)
        task.wait(0.5)
        pcall(function() commF:InvokeServer("TravelDressrosa") end)
        task.wait(2)
        detectiveQuestRunning = false
    end)
end

function Utility.StartMilitaryDetectiveQuest()
    Utility.HandleSea2EntranceQuest()
end

function Utility.HasCompletedBartilo()
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if commF then
        local res = nil
        pcall(function() res = commF:InvokeServer("BartiloQuestProgress", "Check") end)
        if res == 3 or res == 2 then return true end
    end
    return Utility.HasItem("Warrior Helmet")
end

--[[ Auto Bartilo Quest (Level 850+ ở Sea 2) ]]
local bartiloRunning = false
function Utility.HandleBartiloQuest()
    if bartiloRunning or Utility.HasCompletedBartilo() then return end
    bartiloRunning = true
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if not commF then bartiloRunning = false; return end

        local flySpeed = S.TeleportFlySpeed or 200

        -- Nhận quest Bartilo tại Cafe
        UILib.Notify("Bartilo Quest", "Flying to Bartilo at Cafe...", 3)
        Utility.FlyAndWaitArrival(Vector3.new(-456, 73, 299), flySpeed, 35, 6)
        task.wait(0.5)
        pcall(function() commF:InvokeServer("StartQuest", "BartiloQuest", 1) end)
        task.wait(0.5)

        -- Farm 50 Swan Pirate
        local centerPos, mainMob, cluster = Utility.BringMatchingMobs("Swan Pirate", S.BringMobDistance or 240)
        if centerPos and mainMob and #cluster > 0 then
            local _, _, mRoot = Utility.GetEnemyRootCFrame(mainMob)
            if mRoot then
                Utility.PhysicsFlyTo(centerPos + Vector3.new(0, S.AttackHeight or 40, 0), flySpeed)
                local wType = S.SelectedWeaponType or "Melee"
                if wType == "Melee" then Utility.AttackMelee(mainMob, mRoot, cluster)
                elseif wType == "Sword" then Utility.AttackSword(mainMob, mRoot, cluster)
                elseif wType == "Fruit" then Utility.AttackFruitM1(mainMob, mRoot, cluster)
                elseif wType == "Gun" then Utility.AttackGun(mainMob, mRoot, cluster)
                end
            end
        else
            Utility.FlyAndWaitArrival(Vector3.new(850, 73, 1200), flySpeed, 35, 15)
        end

        bartiloRunning = false
    end)
end

--[[ Auto Next Sea 2 -> Sea 3 (Level 1500+): Hạ Don Swan, Nhận ZQuest, Diệt Rip Indra & Sang Sea 3 ]]
local sea3QuestRunning = false
function Utility.HandleSea3EntranceQuest()
    if sea3QuestRunning or Utility.GetCurrentSea() >= 3 then return end
    sea3QuestRunning = true
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if not commF then sea3QuestRunning = false; return end

        local flySpeed = S.TeleportFlySpeed or 200
        local zProg = nil
        pcall(function() zProg = commF:InvokeServer("ZQuestProgress", "Check") end)

        if zProg == 1 then
            UILib.Notify("Auto Next Sea", "Flying to Captain to travel to Sea 3...", 4)
            Utility.FlyAndWaitArrival(Vector3.new(-288, 73, 532), flySpeed, 35, 8)
            task.wait(0.5)
            pcall(function() commF:InvokeServer("TravelZou") end)
            task.wait(5)
            sea3QuestRunning = false
            return
        end

        -- 1. Bắt đầu ZQuest tại Mansion nếu chưa bắt đầu
        UILib.Notify("Auto Next Sea", "Flying to Mansion for ZQuest...", 3)
        Utility.FlyAndWaitArrival(Vector3.new(-288, 73, 532), flySpeed, 35, 6)
        task.wait(0.5)
        pcall(function() commF:InvokeServer("ZQuestProgress", "Begin") end)
        task.wait(0.5)

        -- 2. Diệt rip_indra tại Colosseum
        UILib.Notify("Auto Next Sea", "Flying to Colosseum to defeat rip_indra...", 4)
        local indra = Utility.GetEnemyByName("rip_indra")
        if indra then
            local _, _, inRoot = Utility.GetEnemyRootCFrame(indra)
            if inRoot then
                Utility.FlyAboveTarget(inRoot.CFrame, S.AttackHeight or 40, flySpeed)
                local wType = S.SelectedWeaponType or "Melee"
                if wType == "Melee" then Utility.AttackMelee(indra, inRoot)
                elseif wType == "Sword" then Utility.AttackSword(indra, inRoot)
                elseif wType == "Fruit" then Utility.AttackFruitM1(indra, inRoot)
                elseif wType == "Gun" then Utility.AttackGun(indra, inRoot)
                end
            end
        else
            Utility.FlyAndWaitArrival(Vector3.new(-1820, 50, -2740), flySpeed, 35, 15)
        end

        task.wait(0.5)
        pcall(function()
            if commF:InvokeServer("ZQuestProgress", "Check") == 1 then
                commF:InvokeServer("TravelZou")
            end
        end)

        sea3QuestRunning = false
    end)
end

--[[ Start Auto Farm Level 1 -> 2550 with Bring Mobs, Auto Quest & Auto Next Sea ]]
--[[ ═══════════════════════════════════════════════════════════════════════════
     MODULAR TASK PROGRESSION PIPELINE & ENGINES
   ═══════════════════════════════════════════════════════════════════════════ ]]

-- Danh sách dữ liệu các bộ võ (Melee) và vị trí NPC theo từng Sea trong Blox Fruits
local MELEE_DATABASE = {
    {
        Name = "Black Leg",
        DisplayName = "Dark Step (Black Leg)",
        NPC = { "Dark Step Teacher", "Black Leg Teacher" },
        Positions = {
            [1] = Vector3.new(-987, 14, 3989),
            [2] = Vector3.new(-582, 16, -1141),
            [3] = Vector3.new(-5048, 315, -3153),
        },
        Price = 150000,
        Frags = 0,
        Sea = 1,
        Remote = "BuyBlackLeg",
        Args = {},
    },
    {
        Name = "Electro",
        DisplayName = "Electro",
        NPC = "Mad Scientist",
        Positions = {
            [1] = Vector3.new(-5389, 13, -2150),
            [2] = Vector3.new(-598, 16, -1134),
            [3] = Vector3.new(-5035, 315, -3168),
        },
        Price = 500000,
        Frags = 0,
        Sea = 1,
        Remote = "BuyElectro",
        Args = {},
    },
    {
        Name = "Fishman Karate",
        DisplayName = "Water Kung Fu (Fishman Karate)",
        NPC = { "Water Kung Fu Teacher", "Water Kung-fu Teacher" },
        Positions = {
            [1] = Vector3.new(61584, 19, 988),
            [2] = Vector3.new(-614, 16, -1127),
            [3] = Vector3.new(-5020, 315, -3183),
        },
        Price = 750000,
        Frags = 0,
        Sea = 1,
        Remote = "BuyFishmanKarate",
        Args = {},
    },
    {
        Name = "Dragon Breath",
        DisplayName = "Dragon Breath",
        NPC = "Sabi",
        Positions = {
            [2] = Vector3.new(-1205, 12, -4388),
            [3] = Vector3.new(-5005, 315, -3198),
        },
        Price = 0,
        Frags = 1500,
        Sea = 2,
        Remote = "BlackbeardReward",
        Args = { "DragonClaw", "1" },
        AlternateArgs = { "DragonClaw", "2" },
    },
    {
        Name = "Superhuman",
        DisplayName = "Superhuman",
        NPC = "Martial Arts Master",
        Positions = {
            [2] = Vector3.new(650, 401, -5334),
            [3] = Vector3.new(-4990, 315, -3213),
        },
        Price = 3000000,
        Frags = 0,
        Sea = 2,
        Remote = "BuySuperhuman",
        Args = {},
    },
    {
        Name = "Death Step",
        DisplayName = "Death Step",
        NPC = "Phoeyu, the Reformed",
        Positions = {
            [2] = Vector3.new(6115, 295, -6740),
            [3] = Vector3.new(-4975, 315, -3228),
        },
        Price = 2500000,
        Frags = 5000,
        Sea = 2,
        Remote = "BuyDeathStep",
        Args = {},
    },
    {
        Name = "Sharkman Karate",
        DisplayName = "Sharkman Karate",
        NPC = "Daigrock, the Sharkman",
        Positions = {
            [2] = Vector3.new(-2600, 240, -10300),
            [3] = Vector3.new(-4960, 315, -3243),
        },
        Price = 2500000,
        Frags = 5000,
        Sea = 2,
        Remote = "BuySharkmanKarate",
        Args = {},
    },
    {
        Name = "Electric Claw",
        DisplayName = "Electric Claw",
        NPC = "Previous Hero",
        Positions = {
            [3] = Vector3.new(-10368, 332, -10130),
        },
        Price = 3000000,
        Frags = 5000,
        Sea = 3,
        Remote = "BuyElectricClaw",
        Args = {},
    },
    {
        Name = "Dragon Talon",
        DisplayName = "Dragon Talon",
        NPC = "Uzoth",
        Positions = {
            [3] = Vector3.new(-5400, 314, -2800),
        },
        Price = 3000000,
        Frags = 5000,
        Sea = 3,
        Remote = "BuyDragonTalon",
        Args = {},
    },
    {
        Name = "Godhuman",
        DisplayName = "Godhuman",
        NPC = "Ancient Monk",
        Positions = {
            [3] = Vector3.new(-2450, 74, -11900),
        },
        Price = 5000000,
        Frags = 5000,
        Sea = 3,
        Remote = "BuyGodhuman",
        Args = {},
    },
    {
        Name = "Sanguine Art",
        DisplayName = "Sanguine Art",
        NPC = "Shafi",
        Positions = {
            [3] = Vector3.new(-16500, 10, 400),
        },
        Price = 5000000,
        Frags = 5000,
        Sea = 3,
        Remote = "BuySanguineArt",
        Args = {},
    },
}

-- Danh sách dữ liệu các loại Kiếm (Swords) trong Blox Fruits (Mua từ xa)
local SWORDS_DATABASE = {
    { Name = "Katana", Price = 1000, Sea = 1 },
    { Name = "Cutlass", Price = 1000, Sea = 1 },
    { Name = "Dual Katana", Price = 12000, Sea = 1 },
    { Name = "Iron Mace", Price = 25000, Sea = 1 },
    { Name = "Triple Katana", Price = 60000, Sea = 1 },
    { Name = "Pipe", Price = 100000, Sea = 1 },
    { Name = "Soul Cane", Price = 750000, Sea = 1 },
    { Name = "Bisento", Price = 1000000, Sea = 1 },
    { Name = "Dual-Headed Blade", Price = 400000, Sea = 1 },
}

-- Danh sách dữ liệu các loại Súng (Guns) trong Blox Fruits (Mua từ xa)
local GUNS_DATABASE = {
    { Name = "Slingshot", Price = 5000, Sea = 1 },
    { Name = "Musket", Price = 8000, Sea = 1 },
    { Name = "Flintlock", Price = 10500, Sea = 1 },
    { Name = "Refined Slingshot", Price = 30000, Sea = 1 },
    { Name = "Refined Flintlock", Price = 65000, Sea = 1 },
    { Name = "Cannon", Price = 100000, Sea = 1 },
    { Name = "Refined Musket", Price = 150000, Sea = 1 },
    { Name = "Kabucha", Price = 0, Frags = 1500, Sea = 2, Remote = "BlackbeardReward", Args = { "Slingshot", "2" } },
}

-- Danh sách dữ liệu Phụ kiện (Accessories) trong Blox Fruits (Mua từ xa)
local ACCESSORIES_DATABASE = {
    { Name = "Black Cape", Price = 50000, Sea = 1 },
    { Name = "Swordsman Hat", Price = 150000, Sea = 1 },
    { Name = "Tomoe Ring", Price = 500000, Sea = 1 },
}

--[[ THANG TIẾN TRÌNH CHUẨN CỦA VÕ (MELEE PROGRESSION LADDER) ]]
local MELEE_PROGRESSION_LADDER = {
    { Name = "Combat", DisplayName = "Combat", Sea = 1, Price = 0, Frags = 0 },
    { Name = "Black Leg", DisplayName = "Black Leg (Dark Step)", Sea = 1, Price = 150000, Frags = 0 },
    { Name = "Electro", DisplayName = "Electro", Sea = 1, Price = 500000, Frags = 0 },
    { Name = "Fishman Karate", DisplayName = "Water Kung Fu (Fishman Karate)", Sea = 1, Price = 750000, Frags = 0 },
    { Name = "Dragon Breath", DisplayName = "Dragon Breath", Sea = 2, Price = 0, Frags = 1500 },
    { Name = "Superhuman", DisplayName = "Superhuman", Sea = 2, Price = 3000000, Frags = 0, RequiredMastery = { ["Black Leg"] = 300, ["Electro"] = 300, ["Fishman Karate"] = 300, ["Dragon Breath"] = 300 } },
    { Name = "Death Step", DisplayName = "Death Step", Sea = 2, Price = 2500000, Frags = 5000, RequiredMastery = { ["Black Leg"] = 400 } },
    { Name = "Sharkman Karate", DisplayName = "Sharkman Karate", Sea = 2, Price = 2500000, Frags = 5000, RequiredMastery = { ["Fishman Karate"] = 400 } },
    { Name = "Electric Claw", DisplayName = "Electric Claw", Sea = 3, Price = 3000000, Frags = 5000, RequiredMastery = { ["Electro"] = 400 } },
    { Name = "Dragon Talon", DisplayName = "Dragon Talon", Sea = 3, Price = 3000000, Frags = 5000, RequiredMastery = { ["Dragon Breath"] = 400 } },
    { Name = "Godhuman", DisplayName = "Godhuman", Sea = 3, Price = 5000000, Frags = 5000, RequiredMastery = { ["Superhuman"] = 400, ["Death Step"] = 400, ["Sharkman Karate"] = 400, ["Electric Claw"] = 400, ["Dragon Talon"] = 400 } },
    { Name = "Sanguine Art", DisplayName = "Sanguine Art", Sea = 3, Price = 5000000, Frags = 5000 },
}

--[[ THANG TIẾN TRÌNH CHUẨN CỦA KIẾM (SWORD PROGRESSION LADDER) ]]
local SWORD_PROGRESSION_LADDER = {
    "Katana", "Cutlass", "Dual Katana", "Iron Mace", "Triple Katana", "Pipe", 
    "Dual-Headed Blade", "Soul Cane", "Bisento", "Saber", "Pole (1st Form)",
    "Dragon Trident", "Jitte", "Gravity Cane", "Longsword", "Midnight Blade",
    "Rengoku", "Saddi", "Shisui", "Wando", "True Triple Katana",
    "Dark Dagger", "Tushita", "Yama", "Cursed Dual Katana", "Shark Anchor", "Spikey Trident", "Hallow Scythe"
}

--[[ THANG TIẾN TRÌNH CHUẨN CỦA SÚNG (GUN PROGRESSION LADDER) ]]
local GUN_PROGRESSION_LADDER = {
    "Slingshot",
    "Musket",
    "Flintlock",
    "Refined Slingshot",
    "Refined Flintlock",
    "Dual Flintlock",
    "Cannon",
    "Refined Musket",
    "Acidum Rifle",
    "Bizarre Rifle",
    "Kabucha",
    "Serpent Bow",
    "Soul Guitar",
    "Dragonstorm",
}

--[[ Helper: Lấy điểm Mastery thực tế của vũ khí ]]
function Utility.GetItemMastery(itemName)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local ch = LocalPlayer.Character
    local sources = { ch, bp }
    for _, src in ipairs(sources) do
        if src then
            local tool = src:FindFirstChild(itemName)
            if tool and tool:IsA("Tool") then
                local l = tool:FindFirstChild("Level") or tool:FindFirstChild("Mastery")
                if l and (l:IsA("IntValue") or l:IsA("NumberValue")) then
                    return l.Value
                end
            end
        end
    end
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local mFolder = data:FindFirstChild("Masteries") or data:FindFirstChild("Weapons")
        if mFolder then
            local itemData = mFolder:FindFirstChild(itemName)
            if itemData and itemData:FindFirstChild("Level") then
                return itemData.Level.Value
            end
        end
    end
    return 0
end

--[[ Helper: Tìm bộ võ tiếp theo theo chuỗi tuyến tính (Linear Next Target)
     Không mua ngược lại, không mua vô tội vạ ]]
function Utility.GetNextLinearUnownedMelee()
    if not S.AutoGetAllMeleesEnabled then return nil end
    local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
    local pFrags = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Fragments") and LocalPlayer.Data.Fragments.Value) or 0
    local curSea = Utility.GetCurrentSea()

    for _, melee in ipairs(MELEE_DATABASE) do
        if not Utility.HasItem(melee.Name) then
            -- Đây là võ đầu tiên chưa sở hữu trong chuỗi tiến trình
            if curSea >= melee.Sea and pBeli >= melee.Price and pFrags >= (melee.Frags or 0) then
                -- Kiểm tra điều kiện Mastery trước đó nếu có (VD Superhuman, Death Step...)
                local meetsMastery = true
                if melee.RequiredMastery then
                    for reqName, reqMas in pairs(melee.RequiredMastery) do
                        if Utility.GetItemMastery(reqName) < reqMas then
                            meetsMastery = false
                            break
                        end
                    end
                end
                if meetsMastery then
                    return melee
                end
            end
            -- Nếu chưa đủ tiền/điều kiện cho võ mục tiêu duy nhất này -> DỪNG LẠI, không mua các võ khác!
            return nil
        end
    end
    return nil
end

local _masteryTargetCache = {
    Melee = { Target = nil, LastCheck = 0 },
    Sword = { Target = nil, LastCheck = 0 },
    Gun   = { Target = nil, LastCheck = 0 },
}

--[[ Thuật toán Farm Max Mastery & Quay lui (Backtracking Mastery Algorithm):
     - Ưu tiên dùng vũ khí bậc cao nhất hiện có để cày.
     - Khi vũ khí cao nhất đạt 600 (hoặc max target) -> Quay lui về cày các vũ khí trước đó chưa max.
]]
function Utility.GetBacktrackingMasteryTarget(wType, maxTargetMastery)
    maxTargetMastery = maxTargetMastery or S.MasteryTargetLevel or 600
    local now = os.clock()
    local c = _masteryTargetCache[wType]
    if c and c.Target and (now - c.LastCheck < 3.0) then
        local curMas = Utility.GetItemMastery(c.Target)
        if curMas < maxTargetMastery then
            return c.Target
        end
    end

    local ladder = nil
    if wType == "Melee" then
        ladder = MELEE_PROGRESSION_LADDER
    elseif wType == "Sword" then
        ladder = SWORD_PROGRESSION_LADDER
    elseif wType == "Gun" then
        ladder = GUN_PROGRESSION_LADDER
    end
    if not ladder then return nil end

    -- 1. Tìm tất cả các món người chơi ĐANG SỞ HỮU trong thang cấp bậc
    local ownedList = {}
    for _, entry in ipairs(ladder) do
        local itemName = typeof(entry) == "table" and entry.Name or entry
        if Utility.HasItem(itemName) then
            local curMas = Utility.GetItemMastery(itemName)
            table.insert(ownedList, { Name = itemName, Mastery = curMas })
        end
    end

    if #ownedList == 0 then
        local unfin, _ = Utility.GetUnfinishedMasteryWeapon(wType, maxTargetMastery)
        if c then c.Target = unfin; c.LastCheck = now end
        return unfin
    end

    -- 2. Món cao nhất hiện tại đang sở hữu (Highest Tier Owned)
    local highestOwned = ownedList[#ownedList]

    -- Nếu món cao nhất CHƯA ĐẠT Max Mastery -> Tiếp tục dùng món cao nhất này để farm
    if highestOwned.Mastery < maxTargetMastery then
        if c then c.Target = highestOwned.Name; c.LastCheck = now end
        return highestOwned.Name
    end

    -- 3. NẾU MÓN CAO NHẤT ĐÃ ĐẠT MAX MASTERY (>= 600 hoặc >= maxTargetMastery):
    -- QUAY LUI (Backtrack) về các món trước đó chưa đạt max mastery
    for i = #ownedList - 1, 1, -1 do
        local prevItem = ownedList[i]
        if prevItem.Mastery < maxTargetMastery then
            if c then c.Target = prevItem.Name; c.LastCheck = now end
            return prevItem.Name
        end
    end

    if c then c.Target = nil; c.LastCheck = now end
    return nil
end

--[[ Kiểm tra Kiếm nào chưa sở hữu mà người chơi đã ĐỦ TIỀN để mua từ xa ]]
function Utility.HasAnyAffordableUnownedSword()
    if not S.AutoGetAllSwordsEnabled then return false end
    local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
    local curSea = Utility.GetCurrentSea()
    for _, sw in ipairs(SWORDS_DATABASE) do
        if not Utility.HasItem(sw.Name) and curSea >= sw.Sea and pBeli >= sw.Price then
            return true
        end
    end
    return false
end

--[[ Mua toàn bộ Kiếm có thể mua được trong list miễn là đủ tiền ]]
function Utility.BuyAllAffordableSwordsStep()
    if not S.AutoGetAllSwordsEnabled then return false end
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if not commF then return false end

    local curSea = Utility.GetCurrentSea()
    local anyPurchased = false

    for _, sw in ipairs(SWORDS_DATABASE) do
        local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
        if not Utility.HasItem(sw.Name) and curSea >= sw.Sea and pBeli >= sw.Price then
            pcall(function()
                commF:InvokeServer("BuyItem", sw.Name)
            end)
            _locallyOwnedItems[sw.Name] = true
            table.insert(_inventoryCache, sw.Name)
            anyPurchased = true
            UILib.Notify("Auto Buy Sword", "Purchased Sword: " .. sw.Name, 2)
            task.wait(0.3)
        end
    end
    return anyPurchased
end

--[[ Kiểm tra Súng nào chưa sở hữu mà người chơi đã ĐỦ TIỀN để mua từ xa ]]
function Utility.HasAnyAffordableUnownedGun()
    if not S.AutoGetAllGunsEnabled then return false end
    local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
    local pFrags = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Fragments") and LocalPlayer.Data.Fragments.Value) or 0
    local curSea = Utility.GetCurrentSea()
    for _, g in ipairs(GUNS_DATABASE) do
        if not Utility.HasItem(g.Name) and curSea >= g.Sea and pBeli >= (g.Price or 0) and pFrags >= (g.Frags or 0) then
            return true
        end
    end
    return false
end

--[[ Mua toàn bộ Súng có thể mua được trong list miễn là đủ tiền ]]
function Utility.BuyAllAffordableGunsStep()
    if not S.AutoGetAllGunsEnabled then return false end
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if not commF then return false end

    local curSea = Utility.GetCurrentSea()
    local anyPurchased = false

    for _, g in ipairs(GUNS_DATABASE) do
        local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
        local pFrags = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Fragments") and LocalPlayer.Data.Fragments.Value) or 0
        if not Utility.HasItem(g.Name) and curSea >= g.Sea and pBeli >= (g.Price or 0) and pFrags >= (g.Frags or 0) then
            pcall(function()
                if g.Remote then
                    commF:InvokeServer(g.Remote, unpack(g.Args or {}))
                else
                    commF:InvokeServer("BuyItem", g.Name)
                end
            end)
            _locallyOwnedItems[g.Name] = true
            table.insert(_inventoryCache, g.Name)
            anyPurchased = true
            UILib.Notify("Auto Buy Gun", "Purchased Gun: " .. g.Name, 2)
            task.wait(0.3)
        end
    end
    return anyPurchased
end

--[[ Kiểm tra Phụ kiện nào chưa sở hữu mà người chơi đã ĐỦ TIỀN để mua từ xa ]]
function Utility.HasAnyAffordableUnownedAccessory()
    if not S.AutoGetAllAccessoriesEnabled then return false end
    local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
    local curSea = Utility.GetCurrentSea()
    for _, acc in ipairs(ACCESSORIES_DATABASE) do
        if not Utility.HasItem(acc.Name) and curSea >= acc.Sea and pBeli >= acc.Price then
            return true
        end
    end
    return false
end

--[[ Mua toàn bộ Phụ kiện có thể mua được trong list miễn là đủ tiền ]]
function Utility.BuyAllAffordableAccessoriesStep()
    if not S.AutoGetAllAccessoriesEnabled then return false end
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if not commF then return false end

    local curSea = Utility.GetCurrentSea()
    local anyPurchased = false

    for _, acc in ipairs(ACCESSORIES_DATABASE) do
        local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
        if not Utility.HasItem(acc.Name) and curSea >= acc.Sea and pBeli >= acc.Price then
            pcall(function()
                commF:InvokeServer("BuyItem", acc.Name)
            end)
            _locallyOwnedItems[acc.Name] = true
            table.insert(_inventoryCache, acc.Name)
            anyPurchased = true
            UILib.Notify("Auto Buy Accessory", "Purchased Accessory: " .. acc.Name, 2)
            task.wait(0.3)
        end
    end
    return anyPurchased
end

--[[ Helper: Tấn công Boss đơn lẻ ]]
function Utility.FarmSingleBossStep(bossName, enemyModel, bData)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local _, _, bRoot = Utility.GetEnemyRootCFrame(enemyModel)
    if not bRoot then return end

    local flySpeed = S.TeleportFlySpeed or 200

    -- Nhận quest cho boss nếu có quest và chưa có quest
    if bData and bData.Quest and bData.Quest ~= "" and not Utility.HasActiveQuest() then
        local pDist = (root.Position - bData.Pos).Magnitude
        if pDist <= 30 then
            Utility.StartQuest(bData.Quest, bData.QLevel or 1)
            task.wait(0.3)
        end
    end

    -- Bay phía trên Boss và tấn công
    Utility.FlyAboveTarget(bRoot.CFrame, S.AttackHeight or 40, flySpeed)
    local wType = S.SelectedWeaponType or "Melee"
    if wType == "Melee" then Utility.AttackMelee(enemyModel, bRoot)
    elseif wType == "Sword" then Utility.AttackSword(enemyModel, bRoot)
    elseif wType == "Fruit" then Utility.AttackFruitM1(enemyModel, bRoot)
    elseif wType == "Gun" then Utility.AttackGun(enemyModel, bRoot)
    end

    if S.AutoFarmUseSkills then
        if wType == "Melee" then Utility.CastSkillsMelee(bRoot.Position, enemyModel)
        elseif wType == "Fruit" then Utility.CastSkillsFruit(bRoot.Position, enemyModel)
        elseif wType == "Sword" then Utility.CastSkillsSword(bRoot.Position, enemyModel)
        elseif wType == "Gun" then Utility.CastSkillsGun(bRoot.Position, enemyModel)
        end
    end
end

--[[ Helper: Tìm vũ khí chưa đạt mức Mastery mục tiêu (Fallback) ]]
function Utility.GetUnfinishedMasteryWeapon(wType, targetMastery)
    targetMastery = targetMastery or 300
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local ch = LocalPlayer.Character
    local sources = { ch, bp }

    for _, src in ipairs(sources) do
        if src then
            for _, item in ipairs(src:GetChildren()) do
                if item:IsA("Tool") and item:FindFirstChild("ToolTip") then
                    local tType = item.ToolTip.Value
                    if (wType == "Sword" and tType == "Sword") or (wType == "Gun" and tType == "Gun") or (wType == "Melee" and tType == "Melee") then
                        local masteryVal = item:FindFirstChild("Level") and item.Level.Value
                        if masteryVal and masteryVal < targetMastery then
                            return item.Name, item
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

--[[ Helper: Farm Mastery Step ]]
function Utility.FarmMasteryStep(toolName, wType)
    Utility.EquipItemByName(toolName)
    local prevWeapon = S.SelectedWeaponType
    S.SelectedWeaponType = wType
    Utility.ExecuteStandardLevelFarmStep()
    S.SelectedWeaponType = prevWeapon
end

--[[ Helper: Thực hiện 1 tick Farm Level tiêu chuẩn ]]
function Utility.ExecuteStandardLevelFarmStep()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local qData = Utility.GetQuestForLevel()
    if not qData then return end

    -- Đảm bảo kiểm tra & nhận đúng quest của quái trước khi tấn công
    local questReady = Utility.EnsureQuestForMob(qData.Mob)
    if not questReady then return end

    local centerPos, mainMob, cluster = Utility.BringMatchingMobs(qData.Mob, S.BringMobDistance or 240)
    if centerPos and mainMob and #cluster > 0 then
        local mainCF, mainPos, mainRoot = Utility.GetEnemyRootCFrame(mainMob)
        if mainRoot then
            local targetFlyPos = centerPos + Vector3.new(0, S.AttackHeight or 40, 0)
            Utility.PhysicsFlyTo(targetFlyPos, S.TeleportFlySpeed or 200)

            local wType = S.SelectedWeaponType or "Melee"
            if wType == "Melee" then Utility.AttackMelee(mainMob, mainRoot, cluster)
            elseif wType == "Sword" then Utility.AttackSword(mainMob, mainRoot, cluster)
            elseif wType == "Fruit" then Utility.AttackFruitM1(mainMob, mainRoot, cluster)
            elseif wType == "Gun" then Utility.AttackGun(mainMob, mainRoot, cluster)
            end

            if S.AutoFarmUseSkills then
                if wType == "Melee" then Utility.CastSkillsMelee(centerPos, mainMob)
                elseif wType == "Fruit" then Utility.CastSkillsFruit(centerPos, mainMob)
                elseif wType == "Sword" then Utility.CastSkillsSword(centerPos, mainMob)
                elseif wType == "Gun" then Utility.CastSkillsGun(centerPos, mainMob)
                end
            end
        end
    else
        currentBringData = nil
        local patrolTarget = Utility.GetSpawnPatrolPos(qData)
        Utility.PhysicsFlyTo(patrolTarget + Vector3.new(0, S.AttackHeight or 40, 0), S.TeleportFlySpeed or 200)
    end
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     DANH SÁCH CÁC MODULE THEO THỨ TỰ ƯU TIÊN (PRIORITY DISPATCHER)
     Thứ tự ưu tiên: Melee -> Sword -> Gun -> Accessory -> Boss -> Next Sea -> Puzzle -> Mas Melee -> Mas Sword -> Mas Gun -> Level
   ═══════════════════════════════════════════════════════════════════════════ ]]

local PipelineModules = {
    -- [ƯU TIÊN 1]: TỰ ĐỘNG MUA VÕ TIẾP THEO (UNLOCK NEXT-TIER MELEE -> BAY ĐẾN NPC MUA)
    {
        Name = "AutoBuyMelee",
        Priority = 1,
        CanRun = function()
            return Utility.GetNextLinearUnownedMelee() ~= nil
        end,
        ExecuteTick = function()
            local targetMelee = Utility.GetNextLinearUnownedMelee()
            if targetMelee then
                local curSea = Utility.GetCurrentSea()
                local flySpeed = S.TeleportFlySpeed or 200

                -- 1. Tìm vị trí NPC theo Model trong Workspace hoặc toạ độ chuẩn của Sea
                local targetPos = nil
                local npcFolder = workspace:FindFirstChild("NPCs")
                local altNames = typeof(targetMelee.NPC) == "table" and targetMelee.NPC or { targetMelee.NPC }
                local foundNpc = nil
                for _, n in ipairs(altNames) do
                    foundNpc = (npcFolder and npcFolder:FindFirstChild(n, true)) or workspace:FindFirstChild(n, true)
                    if foundNpc and foundNpc:IsA("Model") then break end
                end

                if foundNpc and foundNpc:IsA("Model") then
                    local root = foundNpc:FindFirstChild("HumanoidRootPart") or foundNpc.PrimaryPart or foundNpc:FindFirstChildOfClass("BasePart")
                    if root then targetPos = root.Position end
                end

                if not targetPos and targetMelee.Positions then
                    targetPos = targetMelee.Positions[curSea] or targetMelee.Positions[3] or targetMelee.Positions[2] or targetMelee.Positions[1]
                end

                -- 2. Bay đến tận vị trí NPC
                if targetPos then
                    UILib.Notify("Auto Buy Melee", "Enough funds! Flying to " .. targetMelee.DisplayName .. " NPC...", 4)
                    Utility.CheckAndHandleUnderwaterTransition(targetPos)
                    Utility.FlyAndWaitArrival(targetPos + Vector3.new(0, 3, 0), flySpeed, 25, 10)
                    task.wait(0.5)
                end

                -- 3. Gửi Remote mua võ khi đã ở gần NPC (Chỉ unlock võ, không ép trang bị)
                local rep = game:GetService("ReplicatedStorage")
                local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
                if commF then
                    pcall(function()
                        commF:InvokeServer(targetMelee.Remote, unpack(targetMelee.Args or {}))
                        if targetMelee.AlternateArgs then
                            task.wait(0.2)
                            commF:InvokeServer(targetMelee.Remote, unpack(targetMelee.AlternateArgs))
                        end
                    end)
                end
                task.wait(0.8)
                UILib.Notify("Auto Buy Melee", "Unlocked " .. targetMelee.DisplayName .. "! Resuming...", 3)
            end
        end,
    },

    -- [ƯU TIÊN 2]: TỰ ĐỘNG MUA TOÀN BỘ KIẾM TỪ XA (KHI ĐỦ TIỀN)
    {
        Name = "AutoBuySword",
        Priority = 2,
        CanRun = function()
            return Utility.HasAnyAffordableUnownedSword()
        end,
        ExecuteTick = function()
            Utility.BuyAllAffordableSwordsStep()
        end,
    },

    -- [ƯU TIÊN 3]: TỰ ĐỘNG MUA TOÀN BỘ SÚNG TỪ XA (KHI ĐỦ TIỀN)
    {
        Name = "AutoBuyGun",
        Priority = 3,
        CanRun = function()
            return Utility.HasAnyAffordableUnownedGun()
        end,
        ExecuteTick = function()
            Utility.BuyAllAffordableGunsStep()
        end,
    },

    -- [ƯU TIÊN 4]: TỰ ĐỘNG MUA TOÀN BỘ PHỤ KIỆN TỪ XA (KHI ĐỦ TIỀN)
    {
        Name = "AutoBuyAccessory",
        Priority = 4,
        CanRun = function()
            return Utility.HasAnyAffordableUnownedAccessory()
        end,
        ExecuteTick = function()
            Utility.BuyAllAffordableAccessoriesStep()
        end,
    },

    -- [ƯU TIÊN 5]: SĂN BOSS ĐÃ CHỌN (CHỈ KHI BOSS SPAWN)
    {
        Name = "SelectedBosses",
        Priority = 5,
        CanRun = function()
            if not S.AutoFarmSelectedBossesEnabled and not S.AutoFarmSelectedBossEnabled then return false end
            local bName, bModel, bData = Utility.GetSpawnedSelectedBoss()
            return bName ~= nil and bModel ~= nil and bData ~= nil
        end,
        ExecuteTick = function()
            local bName, bModel, bData = Utility.GetSpawnedSelectedBoss()
            if bName and bModel and bData then
                Utility.FarmSingleBossStep(bName, bModel, bData)
                task.wait(0.04)
            end
        end,
    },

    -- [ƯU TIÊN 6]: CHUYỂN SEA TỰ ĐỘNG (CẤP 700 / 1500)
    {
        Name = "NextSeaProgression",
        Priority = 6,
        CanRun = function()
            if not S.AutoNextSeaEnabled then return false end
            local curSea = Utility.GetCurrentSea()
            local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
            return (curSea == 1 and pLevel >= 700) or (curSea == 2 and pLevel >= 1500)
        end,
        ExecuteTick = function()
            local curSea = Utility.GetCurrentSea()
            local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
            if curSea == 1 and pLevel >= 700 then
                Utility.HandleSea2EntranceQuest()
                task.wait(1)
            elseif curSea == 2 and pLevel >= 1500 then
                Utility.HandleSea3EntranceQuest()
                task.wait(1)
            end
        end,
    },

    -- [ƯU TIÊN 7]: NHIỆM VỤ TIẾN TRÌNH / GIẢI ĐỐ (SABER, BARTILO)
    {
        Name = "PuzzleQuests",
        Priority = 7,
        CanRun = function()
            local curSea = Utility.GetCurrentSea()
            local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
            if S.AutoSaberQuestEnabled and curSea == 1 and pLevel >= 200 and not Utility.HasSaber() and (not Utility.IsSaberDoorUnlocked() or Utility.GetEnemyByName("Saber Expert")) then
                return true
            end
            if S.AutoBartiloQuestEnabled and curSea == 2 and pLevel >= 850 and not Utility.HasCompletedBartilo() then
                return true
            end
            return false
        end,
        ExecuteTick = function()
            local curSea = Utility.GetCurrentSea()
            local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
            if S.AutoSaberQuestEnabled and curSea == 1 and pLevel >= 200 and not Utility.HasSaber() and (not Utility.IsSaberDoorUnlocked() or Utility.GetEnemyByName("Saber Expert")) then
                Utility.HandleSaberQuest()
                task.wait(1)
            elseif S.AutoBartiloQuestEnabled and curSea == 2 and pLevel >= 850 and not Utility.HasCompletedBartilo() then
                Utility.HandleBartiloQuest()
                task.wait(1)
            end
        end,
    },

    -- [ƯU TIÊN 8]: CÀY MAX MASTERY VÕ (TIẾN TRÌNH & QUAY LUI)
    {
        Name = "MasteryMelee",
        Priority = 8,
        CanRun = function()
            if not S.AutoFarmMasteryMeleeEnabled then return false end
            local mName = Utility.GetBacktrackingMasteryTarget("Melee", S.MasteryTargetLevel or 600)
            return mName ~= nil
        end,
        ExecuteTick = function()
            local mName = Utility.GetBacktrackingMasteryTarget("Melee", S.MasteryTargetLevel or 600)
            if mName then
                Utility.FarmMasteryStep(mName, "Melee")
            end
        end,
    },

    -- [ƯU TIÊN 9]: CÀY MAX MASTERY KIẾM (TIẾN TRÌNH & QUAY LUI)
    {
        Name = "MasterySword",
        Priority = 9,
        CanRun = function()
            if not S.AutoFarmMasterySwordEnabled then return false end
            local swName = Utility.GetBacktrackingMasteryTarget("Sword", S.MasteryTargetLevel or 600)
            return swName ~= nil
        end,
        ExecuteTick = function()
            local swName = Utility.GetBacktrackingMasteryTarget("Sword", S.MasteryTargetLevel or 600)
            if swName then
                Utility.FarmMasteryStep(swName, "Sword")
            end
        end,
    },

    -- [ƯU TIÊN 10]: CÀY MAX MASTERY SÚNG (TIẾN TRÌNH & QUAY LUI)
    {
        Name = "MasteryGun",
        Priority = 10,
        CanRun = function()
            if not S.AutoFarmMasteryGunEnabled then return false end
            local gnName = Utility.GetBacktrackingMasteryTarget("Gun", S.MasteryTargetLevel or 600)
            return gnName ~= nil
        end,
        ExecuteTick = function()
            local gnName = Utility.GetBacktrackingMasteryTarget("Gun", S.MasteryTargetLevel or 600)
            if gnName then
                Utility.FarmMasteryStep(gnName, "Gun")
            end
        end,
    },

    -- [ƯU TIÊN 11]: FARM LEVEL MẶC ĐỊNH (1 - 2550)
    {
        Name = "FarmLevel",
        Priority = 11,
        CanRun = function()
            return S.AutoFarmLevelEnabled == true
        end,
        ExecuteTick = function()
            Utility.ExecuteStandardLevelFarmStep()
        end,
    },
}

--[[ Hàm thực thi 1 tick của Modular Task Pipeline ]]
function Utility.ExecutePipelineTick()
    for _, mod in ipairs(PipelineModules) do
        if mod.CanRun() then
            mod.ExecuteTick()
            return
        end
    end
end

--[[ Kiểm tra xem có bất kỳ tính năng Pipeline nào đang được BẬT hay không ]]
function Utility.IsAnyPipelineTaskEnabled()
    return S.AutoFarmLevelEnabled
        or S.AutoFarmSelectedBossesEnabled
        or S.AutoFarmSelectedBossEnabled
        or S.AutoGetAllMeleesEnabled
        or S.AutoGetAllSwordsEnabled
        or S.AutoGetAllGunsEnabled
        or S.AutoGetAllAccessoriesEnabled
        or S.AutoFarmMasteryMeleeEnabled
        or S.AutoFarmMasterySwordEnabled
        or S.AutoFarmMasteryGunEnabled
        or (S.AutoNextSeaEnabled and ((Utility.GetCurrentSea() == 1 and ((LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1) >= 700) or (Utility.GetCurrentSea() == 2 and ((LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1) >= 1500)))
        or (S.AutoSaberQuestEnabled and Utility.GetCurrentSea() == 1 and ((LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1) >= 200 and not Utility.HasSaber())
        or (S.AutoBartiloQuestEnabled and Utility.GetCurrentSea() == 2 and ((LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1) >= 850 and not Utility.HasCompletedBartilo())
end

--[[ Điều phối luồng trung tâm (Task Coordinator Loop) ]]
function Utility.StartPipelineCoordinator()
    DisconnectConnection("pipelineCoordinator")
    _conns["pipelineCoordinator"] = task.spawn(function()
        while Utility.IsAnyPipelineTaskEnabled() do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health > 0 and root then
                Utility.ExecutePipelineTick()
            else
                currentBringData = nil
                Utility.StopPhysicsFly()
            end
            task.wait(0.035)
        end
        currentBringData = nil
        Utility.StopPhysicsFly()
    end)
end

function Utility.StopPipelineCoordinator()
    DisconnectConnection("pipelineCoordinator")
    currentBringData = nil
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

function Utility.StartAutoFarmLevel()
    S.AutoFarmLevelEnabled = true
    Utility.StartPipelineCoordinator()
end

--[[ Stop Auto Farm Level ]]
function Utility.StopAutoFarmLevel()
    DisconnectConnection("autoFarmLevel")
    currentBringData = nil
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

--[[ Start Auto Farm Selected Mob with Bring Mobs ]]
function Utility.StartAutoFarmSelectedMob()
    DisconnectConnection("autoFarmMob")
    _conns["autoFarmMob"] = task.spawn(function()
        while S.AutoFarmSelectedMobEnabled do
            local mobName = S.SelectedMob
            if not mobName or mobName == "" then
                task.wait(0.5)
            else
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if char and hum and hum.Health > 0 and root then
                    -- Đảm bảo kiểm tra & nhận đúng quest của mob mục tiêu trước khi tấn công
                    local questReady = Utility.EnsureQuestForMob(mobName)
                    if questReady then
                        local centerPos, mainMob, cluster = Utility.BringMatchingMobs(mobName, S.BringMobDistance or 240)
                        if centerPos and mainMob and #cluster > 0 then
                            local mainCF, mainPos, mainRoot = Utility.GetEnemyRootCFrame(mainMob)
                            if mainRoot then
                                local targetFlyPos = centerPos + Vector3.new(0, S.AttackHeight or 40, 0)
                                Utility.PhysicsFlyTo(targetFlyPos, S.TeleportFlySpeed or 200)

                                local wType = S.SelectedWeaponType or "Melee"
                                if wType == "Melee" then Utility.AttackMelee(mainMob, mainRoot, cluster)
                                elseif wType == "Sword" then Utility.AttackSword(mainMob, mainRoot, cluster)
                                elseif wType == "Fruit" then Utility.AttackFruitM1(mainMob, mainRoot, cluster)
                                elseif wType == "Gun" then Utility.AttackGun(mainMob, mainRoot, cluster)
                                end

                                if S.AutoFarmUseSkills then
                                    if wType == "Melee" then Utility.CastSkillsMelee(centerPos, mainMob)
                                    elseif wType == "Fruit" then Utility.CastSkillsFruit(centerPos, mainMob)
                                    elseif wType == "Sword" then Utility.CastSkillsSword(centerPos, mainMob)
                                    elseif wType == "Gun" then Utility.CastSkillsGun(centerPos, mainMob)
                                    end
                                end
                            end
                        else
                            currentBringData = nil
                            local qData = Utility.GetQuestDataForMob(mobName)
                            local patrolTarget = qData and Utility.GetSpawnPatrolPos(qData) or (qData and qData.MobPos)
                            if patrolTarget then
                                Utility.PhysicsFlyTo(patrolTarget + Vector3.new(0, S.AttackHeight or 40, 0), S.TeleportFlySpeed or 200)
                            else
                                Utility.StopPhysicsFly()
                            end
                        end
                    end
                else
                    currentBringData = nil
                    Utility.StopPhysicsFly()
                end
            end
            task.wait(0.035)
        end
        currentBringData = nil
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop Auto Farm Selected Mob ]]
function Utility.StopAutoFarmSelectedMob()
    DisconnectConnection("autoFarmMob")
    currentBringData = nil
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

--[[ Start Auto Farm Selected Boss ]]
function Utility.StartAutoFarmSelectedBoss()
    DisconnectConnection("autoFarmBoss")
    _conns["autoFarmBoss"] = task.spawn(function()
        while S.AutoFarmSelectedBossEnabled do
            local bossName = S.SelectedBoss
            local bData = BOSS_DATABASE[bossName]
            local targetBoss = Utility.GetEnemyByName(bossName)
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health > 0 and root then
                if targetBoss then
                    if bData and bData.Quest ~= "" and not Utility.HasActiveQuest() then
                        Utility.StartQuest(bData.Quest, bData.QLevel)
                    end

                    local eCF, ePos, eRoot = Utility.GetEnemyRootCFrame(targetBoss)
                    if eRoot then
                        Utility.FlyAboveTarget(eCF, S.AttackHeight or 40, S.TeleportFlySpeed or 200)
                        local wType = S.SelectedWeaponType or "Melee"
                        if wType == "Melee" then Utility.AttackMelee(targetBoss, eRoot)
                        elseif wType == "Sword" then Utility.AttackSword(targetBoss, eRoot)
                        elseif wType == "Fruit" then Utility.AttackFruitM1(targetBoss, eRoot)
                        elseif wType == "Gun" then Utility.AttackGun(targetBoss, eRoot)
                        end

                        if S.AutoFarmUseSkills then
                            if wType == "Melee" then Utility.CastSkillsMelee(ePos, targetBoss)
                            elseif wType == "Fruit" then Utility.CastSkillsFruit(ePos, targetBoss)
                            elseif wType == "Sword" then Utility.CastSkillsSword(ePos, targetBoss)
                            elseif wType == "Gun" then Utility.CastSkillsGun(ePos, targetBoss)
                            end
                        end
                    end
                else
                    if bData and bData.Pos then
                        Utility.PhysicsFlyTo(bData.Pos + Vector3.new(0, S.AttackHeight or 40, 0), S.TeleportFlySpeed or 200)
                    else
                        Utility.StopPhysicsFly()
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

--[[ Stop Auto Farm Selected Boss ]]
function Utility.StopAutoFarmSelectedBoss()
    DisconnectConnection("autoFarmBoss")
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

--[[ Start Auto Farm Material with Bring Mobs ]]
function Utility.StartAutoFarmMaterial()
    DisconnectConnection("autoFarmMat")
    _conns["autoFarmMat"] = task.spawn(function()
        while S.AutoFarmMaterialEnabled do
            local matName = S.SelectedMaterial
            local mData = MATERIAL_FARM_DATA[matName]
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health > 0 and root and mData then
                local centerPos, mainMob, cluster = Utility.BringMatchingMobs(mData.Mob, S.BringMobDistance or 240)
                if centerPos and mainMob and #cluster > 0 then
                    local mainCF, mainPos, mainRoot = Utility.GetEnemyRootCFrame(mainMob)
                    if mainRoot then
                        local targetFlyPos = centerPos + Vector3.new(0, S.AttackHeight or 40, 0)
                        Utility.PhysicsFlyTo(targetFlyPos, S.TeleportFlySpeed or 200)

                        local wType = S.SelectedWeaponType or "Melee"
                        if wType == "Melee" then Utility.AttackMelee(mainMob, mainRoot, cluster)
                        elseif wType == "Sword" then Utility.AttackSword(mainMob, mainRoot, cluster)
                        elseif wType == "Fruit" then Utility.AttackFruitM1(mainMob, mainRoot, cluster)
                        elseif wType == "Gun" then Utility.AttackGun(mainMob, mainRoot, cluster)
                        end

                        if S.AutoFarmUseSkills then
                            if wType == "Melee" then Utility.CastSkillsMelee(centerPos, mainMob)
                            elseif wType == "Fruit" then Utility.CastSkillsFruit(centerPos, mainMob)
                            elseif wType == "Sword" then Utility.CastSkillsSword(centerPos, mainMob)
                            elseif wType == "Gun" then Utility.CastSkillsGun(centerPos, mainMob)
                            end
                        end
                    end
                else
                    currentBringData = nil
                    Utility.PhysicsFlyTo(mData.Pos + Vector3.new(0, S.AttackHeight or 40, 0), S.TeleportFlySpeed or 200)
                end
            else
                currentBringData = nil
                Utility.StopPhysicsFly()
            end
            task.wait(0.035)
        end
        currentBringData = nil
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop Auto Farm Material ]]
function Utility.StopAutoFarmMaterial()
    DisconnectConnection("autoFarmMat")
    currentBringData = nil
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

--[[ Start Auto Farm Chests ]]
function Utility.StartAutoFarmChests()
    DisconnectConnection("autoFarmChest")
    _conns["autoFarmChest"] = task.spawn(function()
        while S.AutoFarmChestEnabled do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health > 0 and root then
                local chests = {}
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name:find("Chest") or (obj.Parent and obj.Parent.Name:find("Chest"))) then
                        if obj:FindFirstChildOfClass("TouchTransmitter") or obj.Transparency < 1 then
                            table.insert(chests, obj)
                        end
                    end
                end

                if #chests > 0 then
                    table.sort(chests, function(a, b)
                        return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude
                    end)

                    local targetChest = chests[1]
                    if targetChest and targetChest.Parent then
                        Utility.PhysicsFlyTo(targetChest.Position + Vector3.new(0, 2, 0), S.TeleportFlySpeed or 180)
                        task.wait(0.2)
                    end
                else
                    task.wait(2)
                end
            else
                Utility.StopPhysicsFly()
            end
            task.wait(0.05)
        end
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop Auto Farm Chests ]]
function Utility.StopAutoFarmChests()
    DisconnectConnection("autoFarmChest")
    Utility.StopPhysicsFly()
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     TESTING & DEBUG LEVEL MILESTONE AUTO FARM ENGINE
   ═══════════════════════════════════════════════════════════════════════════ ]]

function Utility.GetMilestoneList()
    local list = {}
    for i, data in ipairs(LEVEL_QUEST_DATA) do
        -- Tạm thời lọc bỏ các mốc farm quái của Sea 1 (Min < 700), chỉ giữ Sea 2 và Sea 3
        if data.Min >= 700 then
            local entryName = string.format("[%d] Lv %d - %d: %s (%s)", i, data.Min, data.Max, data.Mob, data.Quest)
            table.insert(list, entryName)
        end
    end
    return list
end

function Utility.GetMilestoneByIndex(index)
    return LEVEL_QUEST_DATA[index] or LEVEL_QUEST_DATA[27] or LEVEL_QUEST_DATA[1]
end

--[[ Start Auto Farm Test Milestone ]]
function Utility.StartTestAutoFarmMilestone()
    DisconnectConnection("testAutoFarmMilestone")
    _conns["testAutoFarmMilestone"] = task.spawn(function()
        while S.TestAutoFarmMilestoneEnabled do
            local qData = Utility.GetMilestoneByIndex(S.TestMilestoneIndex or 1)
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health > 0 and root and qData then
                local questReady = Utility.EnsureQuestForMob(qData.Mob)
                if questReady then
                    local centerPos, mainMob, cluster = Utility.BringMatchingMobs(qData.Mob, S.BringMobDistance or 240)
                    if centerPos and mainMob and #cluster > 0 then
                        local mainCF, mainPos, mainRoot = Utility.GetEnemyRootCFrame(mainMob)
                        if mainRoot then
                            local targetFlyPos = centerPos + Vector3.new(0, S.AttackHeight or 40, 0)
                            Utility.PhysicsFlyTo(targetFlyPos, S.TeleportFlySpeed or 200)

                            local wType = S.SelectedWeaponType or "Melee"
                            if wType == "Melee" then Utility.AttackMelee(mainMob, mainRoot, cluster)
                            elseif wType == "Sword" then Utility.AttackSword(mainMob, mainRoot, cluster)
                            elseif wType == "Fruit" then Utility.AttackFruitM1(mainMob, mainRoot, cluster)
                            elseif wType == "Gun" then Utility.AttackGun(mainMob, mainRoot, cluster)
                            end

                            if S.AutoFarmUseSkills then
                                if wType == "Melee" then Utility.CastSkillsMelee(centerPos, mainMob)
                                elseif wType == "Fruit" then Utility.CastSkillsFruit(centerPos, mainMob)
                                elseif wType == "Sword" then Utility.CastSkillsSword(centerPos, mainMob)
                                elseif wType == "Gun" then Utility.CastSkillsGun(centerPos, mainMob)
                                end
                            end
                        end
                    else
                        currentBringData = nil
                        local patrolTarget = Utility.GetSpawnPatrolPos(qData)
                        Utility.PhysicsFlyTo(patrolTarget + Vector3.new(0, S.AttackHeight or 40, 0), S.TeleportFlySpeed or 200)
                    end
                end
            else
                currentBringData = nil
                Utility.StopPhysicsFly()
            end
            task.wait(0.035)
        end
        currentBringData = nil
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop Auto Farm Test Milestone ]]
function Utility.StopTestAutoFarmMilestone()
    DisconnectConnection("testAutoFarmMilestone")
    currentBringData = nil
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

--[[ Start Auto Stats Loop ]]
function Utility.StartAutoStatsLoop()
    DisconnectConnection("autoStats")
    _conns["autoStats"] = task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

        while S.AutoStatsMelee or S.AutoStatsDefense or S.AutoStatsSword or S.AutoStatsGun or S.AutoStatsFruit do
            local points = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Points") and LocalPlayer.Data.Points.Value) or 0
            local amt = math.min(S.StatsPointsAmount or 1, points)

            if points > 0 and commF and commF:IsA("RemoteFunction") then
                if S.AutoStatsMelee then pcall(function() commF:InvokeServer("AddPoint", "Melee", amt) end) end
                if S.AutoStatsDefense then pcall(function() commF:InvokeServer("AddPoint", "Defense", amt) end) end
                if S.AutoStatsSword then pcall(function() commF:InvokeServer("AddPoint", "Sword", amt) end) end
                if S.AutoStatsGun then pcall(function() commF:InvokeServer("AddPoint", "Gun", amt) end) end
                if S.AutoStatsFruit then pcall(function() commF:InvokeServer("AddPoint", "Demon Fruit", amt) end) end
            end
            task.wait(1.5)
        end
    end)
end

--[[ Helper function to get available mobs ]]
function Utility.GetAvailableMobsList()
    local mobs = {}
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, enemy in ipairs(enemies:GetChildren()) do
            if enemy:IsA("Model") and not table.find(mobs, enemy.Name) then
                table.insert(mobs, enemy.Name)
            end
        end
    end
    if #mobs == 0 then
        mobs = { "Bandit", "Monkey", "Gorilla", "Pirate", "Brute", "Desert Bandit", "Snow Bandit", "Swan Pirate", "Ship Deckhand", "Pirate Millionaire", "Dragon Crew Warrior", "Reborn Skeleton", "Cookie Crafter", "Cocoa Warrior", "Isle Outlaw" }
    end
    table.sort(mobs)
    return mobs
end

--[[ Helper function to get available bosses filtered by Sea ]]
function Utility.GetAvailableBossesList(targetSea)
    local curSea = targetSea or Utility.GetCurrentSea()
    local bosses = {}
    for bossName, data in pairs(BOSS_DATABASE) do
        if data.Sea == curSea or not data.Sea then
            table.insert(bosses, bossName)
        end
    end
    table.sort(bosses)
    if #bosses == 0 then
        for bossName, _ in pairs(BOSS_DATABASE) do
            table.insert(bosses, bossName)
        end
        table.sort(bosses)
    end
    return bosses
end

--[[ Helper function to check if any user-selected boss is currently spawned ]]
function Utility.GetSpawnedSelectedBoss()
    if not S.AutoFarmSelectedBossesEnabled and not S.AutoFarmSelectedBossEnabled then return nil, nil, nil end
    local selected = S.SelectedBosses or {}
    if #selected == 0 and S.SelectedBoss and S.SelectedBoss ~= "" then
        selected = { S.SelectedBoss }
    end
    if #selected == 0 then return nil, nil, nil end

    for _, bossName in ipairs(selected) do
        local bData = BOSS_DATABASE[bossName]
        if bData then
            local enemyModel = Utility.GetEnemyByName(bData.Mob or bossName)
            if enemyModel then
                local _, _, root = Utility.GetEnemyRootCFrame(enemyModel)
                if root then
                    return bossName, enemyModel, bData
                end
            end
        end
    end
    return nil, nil, nil
end

--[[ Helper function to get available materials ]]
function Utility.GetAvailableMaterialsList()
    local mats = {}
    for matName, _ in pairs(MATERIAL_FARM_DATA) do
        table.insert(mats, matName)
    end
    table.sort(mats)
    return mats
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
    S.AutoFlyTikiEnabled = false
    S.AutoFlyHydraEnabled = false
    S.AutoFarmLevelEnabled = false
    S.AutoFarmSelectedMobEnabled = false
    S.AutoFarmSelectedBossEnabled = false
    S.AutoFarmMaterialEnabled = false
    S.AutoFarmChestEnabled = false
    S.AutoStatsMelee = false
    S.AutoStatsDefense = false
    S.AutoStatsSword = false
    S.AutoStatsGun = false
    S.AutoStatsFruit = false

    DisconnectConnection("findLev")
    DisconnectConnection("multiFindLev")
    DisconnectConnection("autoAttackLevi")
    DisconnectConnection("autoSkillsLevi")
    DisconnectConnection("autoFarmSkills")
    DisconnectConnection("autoFarmLevel")
    DisconnectConnection("autoFarmMob")
    DisconnectConnection("autoFarmBoss")
    DisconnectConnection("autoFarmMat")
    DisconnectConnection("autoFarmChest")
    DisconnectConnection("autoStats")
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
    DisconnectConnection("bringMobStepped")
    currentBringData = nil
    DisconnectConnection("keyExpiryLoop")
    DisconnectConnection("keyExpiryIntegrityLoop")

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

LevTab:AddSection("Auto Shoot Leviathan Heart")

local function GetShootBoatDropdownOptions()
    local opts = { "My Boat" }
    for _, name in ipairs(Utility.GetPlayerList()) do
        table.insert(opts, name)
    end
    return opts
end

local ShootBoatDropdown = LevTab:AddDropdown({
    Name    = "Select Target Boat",
    Desc    = "Choose your boat or another player's boat",
    Options = GetShootBoatDropdownOptions(),
    Callback = function(opt)
        if opt == "My Boat" or opt == "None" or opt == "" then
            S.AutoShootBoatOwner = ""
        else
            S.AutoShootBoatOwner = opt
        end
    end,
})

local UI_ELEMENTS = {}
local AutoAttackLeviToggle, MultipleFindLeviathanToggle, FindLeviathanToggle
local AutoSkillsLeviToggle, AutoFlyTikiToggle, AutoFlyHydraToggle
local AutoFarmSeaEventsToggle, AutoAttackEnemyToggle, AutoFarmWithSkillsToggle
local AutoFarmLevelToggle, AutoFarmSelectedMobToggle, AutoFarmSelectedBossToggle
local AutoFarmMaterialToggle, AutoFarmChestToggle

_conns["shootBoatPlrAdded"] = Players.PlayerAdded:Connect(function()
    if ShootBoatDropdown then ShootBoatDropdown:Refresh(GetShootBoatDropdownOptions()) end
end)
_conns["shootBoatPlrRemoved"] = Players.PlayerRemoving:Connect(function()
    if ShootBoatDropdown then ShootBoatDropdown:Refresh(GetShootBoatDropdownOptions()) end
end)

UI_ELEMENTS["AutoShootLeviEnabled"] = LevTab:AddToggle({
    Name    = "Auto Shoot Leviathan Heart",
    Desc    = "Automatically fires the Harpoon",
    Default = S.AutoShootLeviEnabled or false,
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
    Name    = "Leviathan Combat Weapons",
    Desc    = "Select weapon(s) to attack Leviathan (Rotates if 2+ selected)",
    Multi   = true,
    Options = { "Melee", "Sword", "Fruit", "Gun" },
    Default = S.LeviathanSelectedWeapons or { "Melee" },
    Callback = function(opts)
        if typeof(opts) == "string" then opts = { opts } end
        S.LeviathanSelectedWeapons = (typeof(opts) == "table" and #opts > 0) and opts or { "Melee" }
    end,
})

AutoAttackLeviToggle = LevTab:AddToggle({
    Name    = "Auto Attack Leviathan",
    Desc    = "Automatically attack Leviathan with selected weapon(s)",
    Default = S.AutoAttackLeviEnabled or false,
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
UI_ELEMENTS["AutoAttackLeviEnabled"] = AutoAttackLeviToggle

AutoSkillsLeviToggle = LevTab:AddToggle({
    Name    = "Auto Use Skills for Leviathan",
    Desc    = "Auto cast skills to attack Leviathan",
    Default = S.AutoSkillsLeviEnabled or false,
    Callback = function(val)
        S.AutoSkillsLeviEnabled = val
        if val then
            Utility.StartAutoSkillsLeviathan()
        else
            Utility.StopAutoSkillsLeviathan()
        end
    end,
})
UI_ELEMENTS["AutoSkillsLeviEnabled"] = AutoSkillsLeviToggle

LevTab:AddSection("Frozen Watcher & Gate")

LevTab:AddButton({
    Name = "Bribe Spy",
    Desc = "Bribe Spy ",
    Callback = function()
        Utility.BribeSpy()
    end,
})

UI_ELEMENTS["AutoTalkFrozenWatcherEnabled"] = LevTab:AddToggle({
    Name    = "Auto Talk Frozen Watcher",
    Desc    = "Auto open Leviathan Gate",
    Default = S.AutoTalkFrozenWatcherEnabled or false,
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
    Desc    = "Auto find Leviathan",
    Default = S.FindLeviathanEnabled or false,
    Callback = function(val)
        S.FindLeviathanEnabled = val
        if val then
            Utility.StartFindLeviathan()
        else
            Utility.StopFindLeviathan()
        end
    end,
})
UI_ELEMENTS["FindLeviathanEnabled"] = FindLeviathanToggle

LevTab:AddSlider({
    Name    = "Required Passengers",
    Desc    = "Minimum players sit on boat",
    Min     = 0, Max = 6, Default = S.RequiredCannonPassengers or 4, Suffix = "",
    Callback = function(v) S.RequiredCannonPassengers = v end,
})

UI_ELEMENTS["ResetWhenBoatDestroyed"] = LevTab:AddToggle({
    Name    = "Reset When Boat Destroyed",
    Desc    = "Respawn when boat destroyed",
    Default = S.ResetWhenBoatDestroyed or false,
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
    Desc    = "Select boat owner to find Leviathan",
    Options = Utility.GetPlayerList(),
    Default = S.SelectedBoatOwner or "None",
    Callback = function(opt)
        S.SelectedBoatOwner = opt
    end,
})

LevTab:AddButton({
    Name = "Refresh Boat Owner List",
    Desc = "Refresh list of boat owner",
    Callback = function()
        BoatOwnerDD:Refresh(Utility.GetPlayerList())
        UILib.Notify("Leviathan", "Boat owner list refreshed!", 2)
    end,
})

MultipleFindLeviathanToggle = LevTab:AddToggle({
    Name    = "Multiple Find Leviathan",
    Desc    = "Sit on owner boat to find Leviathan",
    Default = S.MultipleFindLeviathanEnabled or false,
    Callback = function(val)
        S.MultipleFindLeviathanEnabled = val
        if val then
            Utility.StartMultipleFindLeviathan()
        else
            Utility.StopMultipleFindLeviathan()
        end
    end,
})
UI_ELEMENTS["MultipleFindLeviathanEnabled"] = MultipleFindLeviathanToggle

UI_ELEMENTS["ResetWhenSelectedOwnerDie"] = LevTab:AddToggle({
    Name    = "Reset When Owner Die",
    Desc    = "Respawn when boat owner dies",
    Default = S.ResetWhenSelectedOwnerDie or false,
    Callback = function(val)
        S.ResetWhenSelectedOwnerDie = val
        if val then
            Utility.StartResetWhenSelectedOwnerDie()
        else
            Utility.StopResetWhenSelectedOwnerDie()
        end
    end,
})

LevTab:AddSection("Buy Boat")

LevTab:AddDropdown({
    Name    = "Select Boat",
    Desc    = "Choose boat to buy",
    Options = {
        "Beast Hunter",
        "Grand Brigade",
        "Guardian",
        "Miracle",
        "PirateBrigade",
        "Sloop",
        "Dinghy"
    },
    Default = S.SelectedBoat or "Beast Hunter",
    Callback = function(opt)
        S.SelectedBoat = opt
    end,
})

LevTab:AddButton({
    Name = "Buy Boat",
    Desc = "Buy selected boat",
    Callback = function()
        task.spawn(function()
            local boatName = S.SelectedBoat or "Beast Hunter"
            local ok, err = Utility.BuyBoat(boatName)
            if ok then
                UILib.Notify("Boat", "Bought successfully " .. boatName .. "!", 3)
            else
                UILib.Notify("Error", "Couldn't buy boat: " .. tostring(err), 3)
            end
        end)
    end,
})

LevTab:AddSection("Fly & Boat Settings")

LevTab:AddSlider({
    Name    = "Boat Fly Speed",
    Desc    = "Boat fly speed",
    Min     = 100, Max = 350, Default = S.BoatFlySpeed or 220, Suffix  = " s/s",
    Callback = function(v) S.BoatFlySpeed = v end,
})

LevTab:AddSlider({
    Name    = "Boat Fly Height",
    Desc    = "Boat fly height",
    Min     = 20, Max = 300, Default = S.BoatFlyHeight or 190, Suffix  = " Y",
    Callback = function(v) S.BoatFlyHeight = v end,
})

UI_ELEMENTS["EnableBoatSpeed"] = LevTab:AddToggle({
    Name    = "Enable Boat Speed",
    Desc    = "Change boat speed",
    Default = S.EnableBoatSpeed or false,
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
    Desc    = "Boat speed value",
    Min     = 40, Max = 500, Default = S.CustomBoatSpeed or 250, Suffix  = " sp",
    Callback = function(v) S.CustomBoatSpeed = v end,
})

LevTab:AddSection("Boat Auto Navigation")

AutoFlyTikiToggle = LevTab:AddToggle({
    Name    = "Auto Fly to Tiki",
    Desc    = "Fly boat to Tiki Outpost",
    Default = S.AutoFlyTikiEnabled or false,
    Callback = function(val)
        S.AutoFlyTikiEnabled = val
        if val then
            if S.AutoFlyHydraEnabled and AutoFlyHydraToggle then AutoFlyHydraToggle:Set(false) end
            Utility.StartAutoFlyToTiki()
        else
            Utility.StopBoatWaypointNavigation()
        end
    end,
})
UI_ELEMENTS["AutoFlyTikiEnabled"] = AutoFlyTikiToggle

AutoFlyHydraToggle = LevTab:AddToggle({
    Name    = "Auto Fly to Hydra",
    Desc    = "Fly boat to Hydra Island",
    Default = S.AutoFlyHydraEnabled or false,
    Callback = function(val)
        S.AutoFlyHydraEnabled = val
        if val then
            if S.AutoFlyTikiEnabled and AutoFlyTikiToggle then AutoFlyTikiToggle:Set(false) end
            Utility.StartAutoFlyToHydra()
        else
            Utility.StopBoatWaypointNavigation()
        end
    end,
})
UI_ELEMENTS["AutoFlyHydraEnabled"] = AutoFlyHydraToggle


-- ═══════════════════════════════════════════════════════════
--  TAB 2 : SEA EVENTS
-- ═══════════════════════════════════════════════════════════
local SeaEventsTab = Window:AddTab({ Name = "Sea Events", Icon = "" })

SeaEventsTab:AddSection("Sea Events Configuration")

SeaEventsTab:AddDropdown({
    Name    = "Select Boat",
    Desc    = "Choose boat for Sea Events",
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
    Desc    = "Choose weapons ",
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
    Desc    = "Filter target Sea Events",
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
    Desc    = "Auto fly boat & farm Sea Events",
    Default = S.AutoFarmSeaEventsEnabled or false,
    Callback = function(val)
        S.AutoFarmSeaEventsEnabled = val
        if val then
            Utility.StartAutoFarmSeaEvents()
        else
            Utility.StopAutoFarmSeaEvents()
        end
    end,
})
UI_ELEMENTS["AutoFarmSeaEventsEnabled"] = AutoFarmSeaEventsToggle

UI_ELEMENTS["AutoFarmSeaEventsSkills"] = SeaEventsTab:AddToggle({
    Name    = "Use Skills for Sea Events",
    Desc    = "Auto cast skills when farm Sea Events",
    Default = S.AutoFarmSeaEventsSkills or false,
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
    Name    = "Select Weapon",
    Desc    = "Choose weapon type",
    Options = { "Melee", "Sword", "Fruit", "Gun" },
    Default = S.SelectedWeaponType or "Melee",
    Callback = function(opt)
        S.SelectedWeaponType = opt
        Utility.EquipWeaponByType(opt)
    end,
})

FarmTab:AddSlider({
    Name    = "Attack Height",
    Desc    = "Height above target",
    Min     = 5, Max = 80, Default = S.AttackHeight or 40, Suffix = " studs",
    Callback = function(v)
        S.AttackHeight = v
    end,
})

FarmTab:AddSlider({
    Name    = "Farm Fly Speed",
    Desc    = "Fly speed when farming",
    Min     = 50, Max = 350, Default = S.TeleportFlySpeed or 200, Suffix = " sp",
    Callback = function(v)
        S.TeleportFlySpeed = v
    end,
})

UI_ELEMENTS["BringMobEnabled"] = FarmTab:AddToggle({
    Name    = "Bring Mobs",
    Desc    = "Pull & lock mobs to center",
    Default = (S.BringMobEnabled ~= nil and S.BringMobEnabled) or true,
    Callback = function(val)
        S.BringMobEnabled = val
    end,
})

FarmTab:AddSlider({
    Name    = "Bring Mob Range",
    Desc    = "Max search range",
    Min     = 50, Max = 350, Default = S.BringMobDistance or 240, Suffix = " studs",
    Callback = function(v)
        S.BringMobDistance = v
    end,
})

FarmTab:AddSlider({
    Name    = "Bring Mob Speed",
    Desc    = "Pull speed",
    Min     = 50, Max = 350, Default = S.BringMobSpeed or 110, Suffix = " sp",
    Callback = function(v)
        S.BringMobSpeed = v
    end,
})

UI_ELEMENTS["AutoFarmUseSkills"] = FarmTab:AddToggle({
    Name    = "Use Skills While Farming",
    Desc    = "Auto cast skills while farming",
    Default = S.AutoFarmUseSkills or false,
    Callback = function(val)
        S.AutoFarmUseSkills = val
    end,
})

AutoFarmWithSkillsToggle = FarmTab:AddToggle({
    Name    = "Farm with Skills Only",
    Desc    = "Attack with skills only",
    Default = S.AutoFarmWithSkillsEnabled or false,
    Callback = function(val)
        S.AutoFarmWithSkillsEnabled = val
        if val then
            Utility.StartAutoFarmWithSkills()
        else
            Utility.StopAutoFarmWithSkills()
        end
    end,
})
UI_ELEMENTS["AutoFarmWithSkillsEnabled"] = AutoFarmWithSkillsToggle

FarmTab:AddSection("Auto Farm Progression (Unified Pipeline)")

AutoFarmLevelToggle = FarmTab:AddToggle({
    Name    = "Auto Farm Level",
    Desc    = "Auto quest & level up to Max 2550",
    Default = S.AutoFarmLevelEnabled or false,
    Callback = function(val)
        S.AutoFarmLevelEnabled = val
        if val then
            Utility.StartAutoFarmLevel()
        else
            Utility.StopAutoFarmLevel()
        end
    end,
})
UI_ELEMENTS["AutoFarmLevelEnabled"] = AutoFarmLevelToggle

UI_ELEMENTS["AutoNextSeaEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Next Sea (1 -> 2 -> 3)",
    Desc    = "Auto unlock quest & travel to next Sea",
    Default = (S.AutoNextSeaEnabled ~= nil and S.AutoNextSeaEnabled) or true,
    Callback = function(val)
        S.AutoNextSeaEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoSaberQuestEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Saber Quest (Lv 200+)",
    Desc    = "Auto puzzle & defeat Saber Expert",
    Default = (S.AutoSaberQuestEnabled ~= nil and S.AutoSaberQuestEnabled) or true,
    Callback = function(val)
        S.AutoSaberQuestEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoBartiloQuestEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Bartilo Quest (Lv 850+)",
    Desc    = "Auto Bartilo quest & Colosseum puzzle",
    Default = (S.AutoBartiloQuestEnabled ~= nil and S.AutoBartiloQuestEnabled) or true,
    Callback = function(val)
        S.AutoBartiloQuestEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

FarmTab:AddSection("Boss Hunting (Sea Adaptive & Multi-Select)")

local BossDropdown
BossDropdown = FarmTab:AddDropdown({
    Name    = "Select Target Bosses",
    Desc    = "Choose bosses to hunt (Current Sea)",
    Multi   = true,
    Options = Utility.GetAvailableBossesList(),
    Default = S.SelectedBosses or {},
    Callback = function(selectedList)
        S.SelectedBosses = selectedList
    end,
})

FarmTab:AddButton({
    Name    = "Refresh Boss List (Current Sea)",
    Desc    = "Scan bosses for current Sea",
    Callback = function()
        if BossDropdown then
            local bList = Utility.GetAvailableBossesList()
            BossDropdown:Refresh(bList)
            UILib.Notify("Boss List", "Refreshed " .. #bList .. " bosses for Sea " .. Utility.GetCurrentSea(), 2)
        end
    end,
})

AutoFarmSelectedBossToggle = FarmTab:AddToggle({
    Name    = "Auto Farm Selected Bosses",
    Desc    = "Only attacks when boss has spawned",
    Default = S.AutoFarmSelectedBossesEnabled or false,
    Callback = function(val)
        S.AutoFarmSelectedBossesEnabled = val
        S.AutoFarmSelectedBossEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})
UI_ELEMENTS["AutoFarmSelectedBossesEnabled"] = AutoFarmSelectedBossToggle

FarmTab:AddSection("Items & Fighting Styles Progression (Optional Auto)")

UI_ELEMENTS["AutoGetAllMeleesEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Get All Melees",
    Desc    = "Fly to NPC & buy fighting styles when funds are ready",
    Default = S.AutoGetAllMeleesEnabled or false,
    Callback = function(val)
        S.AutoGetAllMeleesEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoGetAllSwordsEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Get All Swords",
    Desc    = "Auto buy unowned shop swords remotely when funds are ready",
    Default = S.AutoGetAllSwordsEnabled or false,
    Callback = function(val)
        S.AutoGetAllSwordsEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoGetAllGunsEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Get All Guns",
    Desc    = "Auto buy unowned shop guns remotely when funds are ready",
    Default = S.AutoGetAllGunsEnabled or false,
    Callback = function(val)
        S.AutoGetAllGunsEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoGetAllAccessoriesEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Get All Accessories",
    Desc    = "Auto buy unowned shop accessories remotely when funds are ready",
    Default = S.AutoGetAllAccessoriesEnabled or false,
    Callback = function(val)
        S.AutoGetAllAccessoriesEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

FarmTab:AddSection("Weapon & Fighting Style Mastery Farming (Progression & Backtracking)")

UI_ELEMENTS["AutoFarmMasteryMeleeEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Farm Max Mastery Melee",
    Desc    = "Farm mastery on fighting styles with backtracking",
    Default = S.AutoFarmMasteryMeleeEnabled or false,
    Callback = function(val)
        S.AutoFarmMasteryMeleeEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoFarmMasterySwordEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Farm Max Mastery Sword",
    Desc    = "Farm mastery on swords with backtracking",
    Default = S.AutoFarmMasterySwordEnabled or false,
    Callback = function(val)
        S.AutoFarmMasterySwordEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoFarmMasteryGunEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Farm Max Mastery Gun",
    Desc    = "Farm mastery on guns with backtracking",
    Default = S.AutoFarmMasteryGunEnabled or false,
    Callback = function(val)
        S.AutoFarmMasteryGunEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

FarmTab:AddDropdown({
    Name    = "Mastery Target Level",
    Desc    = "Target mastery level threshold",
    Options = { "300", "400", "600" },
    Default = tostring(S.MasteryTargetLevel or 600),
    Callback = function(opt)
        S.MasteryTargetLevel = tonumber(opt) or 600
    end,
})

FarmTab:AddSection("Target Mob Farming (Single Target)")

local MobDropdown = FarmTab:AddDropdown({
    Name    = "Select Target Mob",
    Desc    = "Choose mob to farm",
    Options = Utility.GetAvailableMobsList(),
    Default = S.SelectedMob or "Bandit",
    Callback = function(opt)
        S.SelectedMob = opt
    end,
})

FarmTab:AddButton({
    Name    = "Refresh Mob List",
    Desc    = "Scan available mobs in server",
    Callback = function()
        if MobDropdown then
            MobDropdown:Refresh(Utility.GetAvailableMobsList())
            UILib.Notify("Mob List", "Mob list refreshed!", 2)
        end
    end,
})

AutoFarmSelectedMobToggle = FarmTab:AddToggle({
    Name    = "Auto Farm Selected Mob",
    Desc    = "Farm chosen mob continuously",
    Default = S.AutoFarmSelectedMobEnabled or false,
    Callback = function(val)
        S.AutoFarmSelectedMobEnabled = val
        if val then
            Utility.StartAutoFarmSelectedMob()
        else
            Utility.StopAutoFarmSelectedMob()
        end
    end,
})
UI_ELEMENTS["AutoFarmSelectedMobEnabled"] = AutoFarmSelectedMobToggle

FarmTab:AddSection("Materials & Chests Farming")

FarmTab:AddDropdown({
    Name    = "Select Material",
    Desc    = "Choose material to farm",
    Options = Utility.GetAvailableMaterialsList(),
    Default = S.SelectedMaterial or "Bones",
    Callback = function(opt)
        S.SelectedMaterial = opt
    end,
})

AutoFarmMaterialToggle = FarmTab:AddToggle({
    Name    = "Auto Farm Material",
    Desc    = "Farm mobs dropping selected material",
    Default = S.AutoFarmMaterialEnabled or false,
    Callback = function(val)
        S.AutoFarmMaterialEnabled = val
        if val then
            Utility.StartAutoFarmMaterial()
        else
            Utility.StopAutoFarmMaterial()
        end
    end,
})
UI_ELEMENTS["AutoFarmMaterialEnabled"] = AutoFarmMaterialToggle

AutoFarmChestToggle = FarmTab:AddToggle({
    Name    = "Auto Farm Chests",
    Desc    = "Collect chests across the map",
    Default = S.AutoFarmChestEnabled or false,
    Callback = function(val)
        S.AutoFarmChestEnabled = val
        if val then
            Utility.StartAutoFarmChests()
        else
            Utility.StopAutoFarmChests()
        end
    end,
})
UI_ELEMENTS["AutoFarmChestEnabled"] = AutoFarmChestToggle

FarmTab:AddSection("Auto Stats Distribution")

UI_ELEMENTS["AutoStatsMelee"] = FarmTab:AddToggle({
    Name    = "Auto Stats Melee",
    Desc    = "Auto add points to Melee",
    Default = S.AutoStatsMelee or false,
    Callback = function(val)
        S.AutoStatsMelee = val
        if val then Utility.StartAutoStatsLoop() end
    end,
})

UI_ELEMENTS["AutoStatsDefense"] = FarmTab:AddToggle({
    Name    = "Auto Stats Defense",
    Desc    = "Auto add points to Defense",
    Default = S.AutoStatsDefense or false,
    Callback = function(val)
        S.AutoStatsDefense = val
        if val then Utility.StartAutoStatsLoop() end
    end,
})

UI_ELEMENTS["AutoStatsSword"] = FarmTab:AddToggle({
    Name    = "Auto Stats Sword",
    Desc    = "Auto add points to Sword",
    Default = S.AutoStatsSword or false,
    Callback = function(val)
        S.AutoStatsSword = val
        if val then Utility.StartAutoStatsLoop() end
    end,
})

UI_ELEMENTS["AutoStatsGun"] = FarmTab:AddToggle({
    Name    = "Auto Stats Gun",
    Desc    = "Auto add points to Gun",
    Default = S.AutoStatsGun or false,
    Callback = function(val)
        S.AutoStatsGun = val
        if val then Utility.StartAutoStatsLoop() end
    end,
})

UI_ELEMENTS["AutoStatsFruit"] = FarmTab:AddToggle({
    Name    = "Auto Stats Blox Fruit",
    Desc    = "Auto add points to Demon Fruit",
    Default = S.AutoStatsFruit or false,
    Callback = function(val)
        S.AutoStatsFruit = val
        if val then Utility.StartAutoStatsLoop() end
    end,
})

FarmTab:AddSlider({
    Name    = "Points Per Upgrade",
    Desc    = "Amount of points to add each time",
    Min     = 1, Max = 100, Default = S.StatsPointsAmount or 1, Suffix = " pts",
    Callback = function(v)
        S.StatsPointsAmount = v
    end,
})



-- ═══════════════════════════════════════════════════════════
--  TAB 4 : FARM SETTING
-- ═══════════════════════════════════════════════════════════
local FarmSettingTab = Window:AddTab({ Name = "Farm Setting", Icon = "" })

FarmSettingTab:AddSection("Progression & Special Quests")

UI_ELEMENTS["AutoNextSeaEnabled"] = FarmSettingTab:AddToggle({
    Name    = "Auto Next Sea (1 -> 2 -> 3)",
    Desc    = "Auto unlock quest & travel to next Sea",
    Default = (S.AutoNextSeaEnabled ~= nil and S.AutoNextSeaEnabled) or true,
    Callback = function(val)
        S.AutoNextSeaEnabled = val
    end,
})

UI_ELEMENTS["AutoSaberQuestEnabled"] = FarmSettingTab:AddToggle({
    Name    = "Auto Saber Quest (Lv 200+)",
    Desc    = "Auto puzzle & defeat Saber Expert",
    Default = (S.AutoSaberQuestEnabled ~= nil and S.AutoSaberQuestEnabled) or true,
    Callback = function(val)
        S.AutoSaberQuestEnabled = val
    end,
})

UI_ELEMENTS["AutoTheSonQuestEnabled"] = FarmSettingTab:AddToggle({
    Name    = "Auto The Son Quest (Rich Son)",
    Desc    = "Auto help Sick Man & kill Mob Leader",
    Default = (S.AutoTheSonQuestEnabled ~= nil and S.AutoTheSonQuestEnabled) or true,
    Callback = function(val)
        S.AutoTheSonQuestEnabled = val
    end,
})

UI_ELEMENTS["AutoMilitaryDetectiveQuestEnabled"] = FarmSettingTab:AddToggle({
    Name    = "Auto Military Detective Quest (Lv 700+)",
    Desc    = "Auto Key puzzle, kill Ice Admiral & travel Sea 2",
    Default = (S.AutoMilitaryDetectiveQuestEnabled ~= nil and S.AutoMilitaryDetectiveQuestEnabled) or true,
    Callback = function(val)
        S.AutoMilitaryDetectiveQuestEnabled = val
    end,
})

UI_ELEMENTS["AutoBartiloQuestEnabled"] = FarmSettingTab:AddToggle({
    Name    = "Auto Bartilo Quest (Lv 850+)",
    Desc    = "Auto Bartilo quest & Colosseum puzzle",
    Default = (S.AutoBartiloQuestEnabled ~= nil and S.AutoBartiloQuestEnabled) or true,
    Callback = function(val)
        S.AutoBartiloQuestEnabled = val
    end,
})

FarmSettingTab:AddSection("Race Skills & Awakening")

UI_ELEMENTS["AutoRaceV3"] = FarmSettingTab:AddToggle({
    Name    = "Auto Race V3",
    Desc    = "Auto activate Race V3",
    Default = S.AutoRaceV3 or false,
    Callback = function(val)
        S.AutoRaceV3 = val
        if val then
            Utility.StartAutoAwakeningLoop()
        end
    end,
})

UI_ELEMENTS["AutoAwakeningV4"] = FarmSettingTab:AddToggle({
    Name    = "Auto Awakening V4",
    Desc    = "Auto activate Race V4 Awakening",
    Default = S.AutoAwakeningV4 or false,
    Callback = function(val)
        S.AutoAwakeningV4 = val
        if val then
            Utility.StartAutoAwakeningLoop()
        end
    end,
})

FarmSettingTab:AddSection("Skill Hold Settings")

UI_ELEMENTS["HoldMeleeSkills"] = FarmSettingTab:AddToggle({
    Name    = "Hold Melee Skills",
    Desc    = "Hold Melee skills  ",
    Default = S.HoldMeleeSkills or false,
    Callback = function(val) S.HoldMeleeSkills = val end,
})

UI_ELEMENTS["HoldFruitSkills"] = FarmSettingTab:AddToggle({
    Name    = "Hold Fruit Skills",
    Desc    = "Hold Fruit skills  ",
    Default = S.HoldFruitSkills or false,
    Callback = function(val) S.HoldFruitSkills = val end,
})

UI_ELEMENTS["HoldSwordSkills"] = FarmSettingTab:AddToggle({
    Name    = "Hold Sword Skills",
    Desc    = "Hold Sword skills  ",
    Default = S.HoldSwordSkills or false,
    Callback = function(val) S.HoldSwordSkills = val end,
})

UI_ELEMENTS["HoldGunSkills"] = FarmSettingTab:AddToggle({
    Name    = "Hold Gun Skills",
    Desc    = "Hold Gun skills  ",
    Default = S.HoldGunSkills or false,
    Callback = function(val) S.HoldGunSkills = val end,
})

FarmSettingTab:AddSlider({
    Name    = "Skill Hold Duration",
    Desc    = "Duration to hold skill (seconds)",
    Min     = 0.1, Max = 3.0, Default = S.SkillHoldDuration or 0.35, Suffix = "s",
    Callback = function(v)
        S.SkillHoldDuration = v
    end,
})

FarmSettingTab:AddSection("Melee Skills (Z, X, C)")

UI_ELEMENTS["MeleeSkillZ"] = FarmSettingTab:AddToggle({
    Name    = "Use Melee Skill Z",
    Desc    = "Enable/disable Melee Z",
    Default = (S.MeleeSkillZ ~= nil) and S.MeleeSkillZ or true,
    Callback = function(val) S.MeleeSkillZ = val end,
})

UI_ELEMENTS["MeleeSkillX"] = FarmSettingTab:AddToggle({
    Name    = "Use Melee Skill X",
    Desc    = "Enable/disable Melee X",
    Default = (S.MeleeSkillX ~= nil) and S.MeleeSkillX or true,
    Callback = function(val) S.MeleeSkillX = val end,
})

UI_ELEMENTS["MeleeSkillC"] = FarmSettingTab:AddToggle({
    Name    = "Use Melee Skill C",
    Desc    = "Enable/disable Melee C",
    Default = (S.MeleeSkillC ~= nil) and S.MeleeSkillC or true,
    Callback = function(val) S.MeleeSkillC = val end,
})

FarmSettingTab:AddSection("Fruit Skills (Z, X, C, V, F)")

UI_ELEMENTS["FruitSkillZ"] = FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill Z",
    Desc    = "Enable/disable Fruit Z",
    Default = (S.FruitSkillZ ~= nil) and S.FruitSkillZ or true,
    Callback = function(val) S.FruitSkillZ = val end,
})

UI_ELEMENTS["FruitSkillX"] = FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill X",
    Desc    = "Enable/disable Fruit X",
    Default = (S.FruitSkillX ~= nil) and S.FruitSkillX or true,
    Callback = function(val) S.FruitSkillX = val end,
})

UI_ELEMENTS["FruitSkillC"] = FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill C",
    Desc    = "Enable/disable Fruit C",
    Default = (S.FruitSkillC ~= nil) and S.FruitSkillC or true,
    Callback = function(val) S.FruitSkillC = val end,
})

UI_ELEMENTS["FruitSkillV"] = FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill V",
    Desc    = "Enable/disable Fruit V",
    Default = (S.FruitSkillV ~= nil) and S.FruitSkillV or true,
    Callback = function(val) S.FruitSkillV = val end,
})

UI_ELEMENTS["FruitSkillF"] = FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill F",
    Desc    = "Enable/disable Fruit F",
    Default = (S.FruitSkillF ~= nil) and S.FruitSkillF or true,
    Callback = function(val) S.FruitSkillF = val end,
})

FarmSettingTab:AddSection("Sword Skills (Z, X)")

UI_ELEMENTS["SwordSkillZ"] = FarmSettingTab:AddToggle({
    Name    = "Use Sword Skill Z",
    Desc    = "Enable/disable Sword Z",
    Default = (S.SwordSkillZ ~= nil) and S.SwordSkillZ or true,
    Callback = function(val) S.SwordSkillZ = val end,
})

UI_ELEMENTS["SwordSkillX"] = FarmSettingTab:AddToggle({
    Name    = "Use Sword Skill X",
    Desc    = "Enable/disable Sword X",
    Default = (S.SwordSkillX ~= nil) and S.SwordSkillX or true,
    Callback = function(val) S.SwordSkillX = val end,
})

FarmSettingTab:AddSection("Gun Skills (Z, X)")

UI_ELEMENTS["GunSkillZ"] = FarmSettingTab:AddToggle({
    Name    = "Use Gun Skill Z",
    Desc    = "Enable/disable Gun Z",
    Default = (S.GunSkillZ ~= nil) and S.GunSkillZ or true,
    Callback = function(val) S.GunSkillZ = val end,
})

UI_ELEMENTS["GunSkillX"] = FarmSettingTab:AddToggle({
    Name    = "Use Gun Skill X",
    Desc    = "Enable/disable Gun X",
    Default = (S.GunSkillX ~= nil) and S.GunSkillX or true,
    Callback = function(val) S.GunSkillX = val end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 5 : SHOP
-- ═══════════════════════════════════════════════════════════
local ShopTab = Window:AddTab({ Name = "Shop", Icon = "" })

local function ShopInvoke(name, ...)
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if commF and commF:IsA("RemoteFunction") then
        local args = { ... }
        local res = nil
        pcall(function()
            if #args > 0 then
                res = commF:InvokeServer(name, unpack(args))
            else
                res = commF:InvokeServer(name)
            end
        end)
        return res
    end
    return nil
end

local function GetCurrentSeaIndex()
    local pId = game.PlaceId
    if pId == 2753915549 then return 1
    elseif pId == 4442272183 then return 2
    elseif pId == 7449423635 then return 3
    end
    if workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations") then
        if workspace._WorldOrigin.Locations:FindFirstChild("Tiki Outpost") or workspace._WorldOrigin.Locations:FindFirstChild("Floating Turtle") then
            return 3
        elseif workspace._WorldOrigin.Locations:FindFirstChild("Kingdom of Rose") or workspace._WorldOrigin.Locations:FindFirstChild("Ice Castle") then
            return 2
        end
    end
    return 1
end

local function FlyToNPCAndExecute(npcName, seaPositions, actionCallback)
    task.spawn(function()
        local currentSea = GetCurrentSeaIndex()
        local targetPos = nil

        -- 1. Tìm NPC trong Workspace nếu có (Hỗ trợ danh sách tên gọi)
        local npcFolder = workspace:FindFirstChild("NPCs")
        local altNames = typeof(npcName) == "table" and npcName or { npcName }
        local foundNpc = nil
        for _, n in ipairs(altNames) do
            foundNpc = (npcFolder and npcFolder:FindFirstChild(n, true)) or workspace:FindFirstChild(n, true)
            if foundNpc and foundNpc:IsA("Model") then break end
        end
        
        if foundNpc and foundNpc:IsA("Model") then
            local root = foundNpc:FindFirstChild("HumanoidRootPart") or foundNpc.PrimaryPart or foundNpc:FindFirstChildOfClass("BasePart")
            if root then
                targetPos = root.Position
            end
        end

        -- 2. Dùng toạ độ mặc định chuẩn theo Sea nếu không tìm thấy Model NPC
        local displayName = typeof(npcName) == "table" and npcName[1] or npcName
        if not targetPos and seaPositions then
            targetPos = seaPositions[currentSea] or seaPositions[3] or seaPositions[2] or seaPositions[1]
        end

        if not targetPos then
            UILib.Notify("Shop", "NPC " .. displayName .. " not available in this Sea!", 4)
            if actionCallback then actionCallback() end
            return
        end

        UILib.Notify("Shop", "Flying to " .. displayName .. "...", 4)

        -- 3. Bay đến vị trí NPC và thực hiện hành động (tự động qua cổng Whirlpool nếu cần)
        Utility.SmartFlyTo(targetPos + Vector3.new(0, 3, 0), S.TeleportFlySpeed or 200, function()
            task.wait(0.25)
            if actionCallback then actionCallback() end
            UILib.Notify("Shop", "Completed purchase/equip for " .. displayName .. "!", 4)
        end)
    end)
end

ShopTab:AddSection("Race & Stats Management")

ShopTab:AddButton({
    Name = "Reroll Race",
    Desc = "Reroll race (Cost: 3,000 Fragments)",
    Callback = function()
        ShopInvoke("BlackbeardReward", "Reroll", "1")
        ShopInvoke("BlackbeardReward", "Reroll", "2")
        UILib.Notify("Shop", "Sent Reroll Race request!", 4)
    end,
})

ShopTab:AddButton({
    Name = "Reset Stats",
    Desc = "Refund & reset all stat points (Cost: 2,500 Frags)",
    Callback = function()
        ShopInvoke("BlackbeardReward", "Refund", "1")
        ShopInvoke("BlackbeardReward", "Refund", "2")
        UILib.Notify("Shop", "Sent Reset Stats request!", 4)
    end,
})

ShopTab:AddButton({
    Name = "Buy Ghoul Race",
    Desc = "Get Ghoul Race (Cost: 100 Ectoplasm + Hellfire Torch)",
    Callback = function()
        ShopInvoke("Ectoplasm", "BuyCheck", 4)
        task.wait(0.2)
        ShopInvoke("Ectoplasm", "Change", 4)
        UILib.Notify("Shop", "Sent Buy Ghoul Race request!", 4)
    end,
})

ShopTab:AddButton({
    Name = "Buy Cyborg Race",
    Desc = "Get Cyborg Race (Cost: 2,500 Fragments + Core Brain)",
    Callback = function()
        ShopInvoke("CyborgTrainer", "Buy")
        UILib.Notify("Shop", "Sent Buy Cyborg Race request!", 4)
    end,
})

ShopTab:AddSection("Abilities & Haki")

ShopTab:AddButton({
    Name = "Skyjump (Geppo)",
    Desc = "Air jump ability (Cost: $10,000 Beli)",
    Callback = function()
        ShopInvoke("BuyHaki", "Geppo")
        UILib.Notify("Shop", "Purchased Skyjump / Geppo!", 4)
    end,
})

ShopTab:AddButton({
    Name = "Buso Haki (Enhancement)",
    Desc = "Armament Haki (Cost: $25,000 Beli)",
    Callback = function()
        ShopInvoke("BuyHaki", "Buso")
        UILib.Notify("Shop", "Purchased Buso Haki!", 4)
    end,
})

ShopTab:AddButton({
    Name = "Observation Haki (Ken)",
    Desc = "Observation Haki (Cost: $750,000 Beli)",
    Callback = function()
        ShopInvoke("KenTalk", "Buy")
        UILib.Notify("Shop", "Purchased Observation Haki!", 4)
    end,
})

ShopTab:AddButton({
    Name = "Flash Step (Soru)",
    Desc = "Instant teleport step (Cost: $100,000 Beli)",
    Callback = function()
        ShopInvoke("BuyHaki", "Soru")
        UILib.Notify("Shop", "Purchased Flash Step / Soru!", 4)
    end,
})

ShopTab:AddSection("Fighting Styles (Melee)")

local FIGHTING_STYLES_DATABASE = {
    ["Black Leg"] = {
        NPC = { "Dark Step Teacher", "Black Leg Teacher" },
        Positions = {
            [1] = Vector3.new(-987, 14, 3989),
            [2] = Vector3.new(-582, 16, -1141),
            [3] = Vector3.new(-5048, 315, -3153),
        },
        Action = function() ShopInvoke("BuyBlackLeg") end,
    },
    ["Electro"] = {
        NPC = "Mad Scientist",
        Positions = {
            [1] = Vector3.new(-5389, 13, -2150),
            [2] = Vector3.new(-598, 16, -1134),
            [3] = Vector3.new(-5035, 315, -3168),
        },
        Action = function() ShopInvoke("BuyElectro") end,
    },
    ["Fishman Karate"] = {
        NPC = { "Water Kung Fu Teacher", "Water Kung-fu Teacher" },
        Positions = {
            [1] = Vector3.new(61584, 19, 988),
            [2] = Vector3.new(-614, 16, -1127),
            [3] = Vector3.new(-5020, 315, -3183),
        },
        Action = function() ShopInvoke("BuyFishmanKarate") end,
    },
    ["Dragon Breath"] = {
        NPC = "Sabi",
        Positions = {
            [2] = Vector3.new(-1205, 12, -4388),
            [3] = Vector3.new(-5005, 315, -3198),
        },
        Action = function()
            ShopInvoke("BlackbeardReward", "DragonClaw", "1")
            ShopInvoke("BlackbeardReward", "DragonClaw", "2")
        end,
    },
    ["Superhuman"] = {
        NPC = "Martial Arts Master",
        Positions = {
            [2] = Vector3.new(650, 401, -5334),
            [3] = Vector3.new(-4990, 315, -3213),
        },
        Action = function() ShopInvoke("BuySuperhuman") end,
    },
    ["Death Step"] = {
        NPC = "Phoeyu, the Reformed",
        Positions = {
            [2] = Vector3.new(6115, 295, -6740),
            [3] = Vector3.new(-4975, 315, -3228),
        },
        Action = function() ShopInvoke("BuyDeathStep") end,
    },
    ["Sharkman Karate"] = {
        NPC = "Daigrock, the Sharkman",
        Positions = {
            [2] = Vector3.new(-2600, 240, -10300),
            [3] = Vector3.new(-4960, 315, -3243),
        },
        Action = function() ShopInvoke("BuySharkmanKarate") end,
    },
    ["Electric Claw"] = {
        NPC = "Previous Hero",
        Positions = {
            [3] = Vector3.new(-10368, 332, -10130),
        },
        Action = function() ShopInvoke("BuyElectricClaw") end,
    },
    ["Dragon Talon"] = {
        NPC = "Uzoth",
        Positions = {
            [3] = Vector3.new(-5400, 314, -2800),
        },
        Action = function() ShopInvoke("BuyDragonTalon") end,
    },
    ["Godhuman"] = {
        NPC = "Ancient Monk",
        Positions = {
            [3] = Vector3.new(-2450, 74, -11900),
        },
        Action = function() ShopInvoke("BuyGodhuman") end,
    },
    ["Sanguine Art"] = {
        NPC = "Shafi",
        Positions = {
            [3] = Vector3.new(-16500, 10, 400),
        },
        Action = function() ShopInvoke("BuySanguineArt") end,
    },
}

local selectedMeleeShop = "Black Leg"
ShopTab:AddDropdown({
    Name    = "Select Fighting Style",
    Desc    = "Choose melee to purchase/equip",
    Options = {
        "Black Leg",
        "Electro",
        "Fishman Karate",
        "Dragon Breath",
        "Superhuman",
        "Death Step",
        "Sharkman Karate",
        "Electric Claw",
        "Dragon Talon",
        "Godhuman",
        "Sanguine Art",
    },
    Default = "Black Leg",
    Callback = function(opt)
        selectedMeleeShop = opt
    end,
})

ShopTab:AddButton({
    Name = "Buy / Equip Fighting Style",
    Desc = "Fly to NPC & buy/equip selected style",
    Callback = function()
        local styleData = FIGHTING_STYLES_DATABASE[selectedMeleeShop]
        if styleData then
            FlyToNPCAndExecute(styleData.NPC, styleData.Positions, styleData.Action)
        end
    end,
})

ShopTab:AddSection("Swords & Guns")

local SWORDS_GUNS_LIST = {
    "Katana",
    "Cutlass",
    "Dual Katana",
    "Iron Mace",
    "Triple Katana",
    "Pipe",
    "Soul Cane",
    "Bisento",
    "Dual-Headed Blade",
    "Slingshot",
    "Refined Slingshot",
    "Flintlock",
    "Musket",
    "Dual Flintlock",
    "Cannon",
    "Kabucha",
}

local selectedWeaponShop = "Katana"
ShopTab:AddDropdown({
    Name    = "Select Weapon",
    Desc    = "Choose weapon to buy",
    Options = SWORDS_GUNS_LIST,
    Default = "Katana",
    Callback = function(opt)
        selectedWeaponShop = opt
    end,
})

ShopTab:AddButton({
    Name = "Buy Selected Weapon",
    Desc = "Purchase selected Sword / Gun",
    Callback = function()
        if selectedWeaponShop == "Kabucha" then
            ShopInvoke("BlackbeardReward", "Slingshot", "1")
            ShopInvoke("BlackbeardReward", "Slingshot", "2")
        else
            ShopInvoke("BuyItem", selectedWeaponShop)
        end
        UILib.Notify("Shop", "Sent purchase for " .. selectedWeaponShop .. "!", 4)
    end,
})

ShopTab:AddSection("Accessories & Capes")

local ACCESSORIES_LIST = {
    "Black Cape",
    "Swordsman Hat",
    "Tomoe Ring",
}

local selectedAccessory = "Black Cape"
ShopTab:AddDropdown({
    Name    = "Select Accessory",
    Desc    = "Choose accessory to buy",
    Options = ACCESSORIES_LIST,
    Default = "Black Cape",
    Callback = function(opt)
        selectedAccessory = opt
    end,
})

ShopTab:AddButton({
    Name = "Buy Selected Accessory",
    Desc = "Purchase selected accessory",
    Callback = function()
        ShopInvoke("BuyItem", selectedAccessory)
        UILib.Notify("Shop", "Purchased " .. selectedAccessory .. "!", 4)
    end,
})

ShopTab:AddSection("Fruit Gacha & Bone Surprise")

ShopTab:AddButton({
    Name = "Random Blox Fruit (Zioles)",
    Desc = "Buy random devil fruit from Gacha NPC",
    Callback = function()
        ShopInvoke("Cousin", "Buy")
        UILib.Notify("Shop", "Rolled Random Blox Fruit!", 4)
    end,
})

ShopTab:AddButton({
    Name = "Random Bone Surprise (50 Bones)",
    Desc = "Buy random item from Death King",
    Callback = function()
        ShopInvoke("Bones", "Buy", 1, 1)
        UILib.Notify("Shop", "Rolled Random Bone Surprise!", 4)
    end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 6 : TELEPORT
-- ═══════════════════════════════════════════════════════════
local TelTab = Window:AddTab({ Name = "Teleport", Icon = "" })

TelTab:AddSection("Teleport Settings")

TelTab:AddSlider({
    Name    = "Teleport Fly Speed",
    Desc    = "Fly speed when teleporting",
    Min     = 50, Max = 350, Default = S.TeleportFlySpeed or 180, Suffix = " sp",
    Callback = function(v)
        S.TeleportFlySpeed = v
    end,
})

TelTab:AddSection("Teleport to Island")

local currentIslands = Utility.GetIslandList()
local selectedIsland = S.SelectedIsland or currentIslands[1] or "Windmill Island (Pirate Starter)"

local IslandDD = TelTab:AddDropdown({
    Name    = "Select Island",
    Desc    = "Choose island to teleport",
    Options = currentIslands,
    Default = selectedIsland,
    Callback = function(opt)
        selectedIsland = opt
        S.SelectedIsland = opt
    end,
})

TelTab:AddButton({
    Name = "Teleport to Island",
    Desc = "Fly smoothly to selected island (Smart Portal navigation)",
    Callback = function()
        local chosen = selectedIsland or S.SelectedIsland
        if not chosen or chosen == "" or chosen == "None" then
            UILib.Notify("Teleport", "Please select an island first!", 3)
            return
        end

        Utility.SmartTeleportToIsland(chosen)
    end,
})

TelTab:AddButton({
    Name = "Refresh Island List",
    Desc = "Refresh island list for current Sea",
    Callback = function()
        local newList = Utility.GetIslandList()
        if IslandDD then IslandDD:Refresh(newList) end
        UILib.Notify("Teleport", "Refreshed island list for Sea " .. Utility.GetCurrentSea() .. "!", 3)
    end,
})

TelTab:AddSection("Instant CFrame Teleport (No Fly)")

TelTab:AddButton({
    Name = "⚡ Instant CFrame to Selected Island",
    Desc = "Instant CFrame teleport directly to selected island",
    Callback = function()
        local chosen = selectedIsland or S.SelectedIsland
        if not chosen or chosen == "" or chosen == "None" then
            UILib.Notify("Teleport", "Please select an island first!", 3)
            return
        end
        local pos = Utility.GetIslandPosition(chosen)
        if pos then
            Utility.InstantCFrameTeleport(pos + Vector3.new(0, 15, 0), chosen)
        else
            UILib.Notify("Teleport", "Cannot find coordinates for " .. chosen .. "!", 3)
        end
    end,
})

TelTab:AddSection("Teleport to Player")

local PlayerDD = TelTab:AddDropdown({
    Name    = "Select Player",
    Desc    = "Choose player to follow",
    Options = Utility.GetPlayerList(),
    Default = S.SelectedPlayer and S.SelectedPlayer.Name or "None",
    Callback = function(opt)
        S.SelectedPlayer = Players:FindFirstChild(opt)
    end,
})

TelTab:AddButton({
    Name = "Refresh Player List",
    Desc = "Refresh list of players",
    Callback = function()
        PlayerDD:Refresh(Utility.GetPlayerList())
        UILib.Notify("Teleport", "Refreshed players list!", 2)
    end,
})

UI_ELEMENTS["TeleportPlayerEnabled"] = TelTab:AddToggle({
    Name    = "Fly Follow Player",
    Desc    = "Fly and follow player",
    Default = S.TeleportPlayerEnabled or false,
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
--  TAB 7 : TESTING & DEBUG (AUTO FARM MILESTONES)
-- ═══════════════════════════════════════════════════════════
local TestTab = Window:AddTab({ Name = "Testing", Icon = "" })

TestTab:AddSection("Level Milestone Auto Farm Tester")

local milestoneList = Utility.GetMilestoneList()
local selectedMilestoneIndex = S.TestMilestoneIndex or 27

local TestMilestoneDD = TestTab:AddDropdown({
    Name    = "Select Level Milestone (Sea 2 & 3)",
    Desc    = "Choose level bracket/quest to test (Sea 1 hidden)",
    Options = milestoneList,
    Default = milestoneList[1],
    Callback = function(opt)
        local idx = tonumber(opt:match("%[(%d+)%]")) or 27
        selectedMilestoneIndex = idx
        S.TestMilestoneIndex = idx
    end,
})

local TestAutoFarmToggle = TestTab:AddToggle({
    Name    = "Auto Farm Selected Milestone",
    Desc    = "Farm quest & mob of selected level milestone",
    Default = S.TestAutoFarmMilestoneEnabled or false,
    Callback = function(val)
        S.TestAutoFarmMilestoneEnabled = val
        if val then
            -- Tắt Auto Farm Level chính nếu đang chạy để tránh xung đột
            if S.AutoFarmLevelEnabled then
                S.AutoFarmLevelEnabled = false
                if UI_ELEMENTS["AutoFarmLevelEnabled"] then UI_ELEMENTS["AutoFarmLevelEnabled"]:Set(false) end
                Utility.StopAutoFarmLevel()
            end
            Utility.StartTestAutoFarmMilestone()
            UILib.Notify("Testing", "Started Auto Farm for Milestone [" .. selectedMilestoneIndex .. "]!", 4)
        else
            Utility.StopTestAutoFarmMilestone()
            UILib.Notify("Testing", "Stopped Milestone Auto Farm.", 3)
        end
    end,
})
UI_ELEMENTS["TestAutoFarmMilestoneEnabled"] = TestAutoFarmToggle

TestTab:AddSection("Special Quests Automation (Sea 1)")

TestTab:AddButton({
    Name = "🗡️ Run Saber Quest (Smart Check)",
    Desc = "Check door & sword first, fight Shanks if spawned",
    Callback = function()
        Utility.HandleSaberQuest(false)
    end,
})

TestTab:AddButton({
    Name = "⚡ Force Run Saber Quest (All 9 Steps)",
    Desc = "Force test all 9 steps regardless of door status",
    Callback = function()
        Utility.HandleSaberQuest(true)
    end,
})

TestTab:AddButton({
    Name = "💰 Run The Son Quest (Rich Son & Mob Leader)",
    Desc = "Sick man, rich son, defeat mob leader & get reward",
    Callback = function()
        Utility.StartTheSonQuest()
    end,
})

TestTab:AddButton({
    Name = "🕵️ Run Military Detective Quest (Sea 2 Entrance)",
    Desc = "Prison key, unlock ice cave, kill Ice Admiral & Sea 2",
    Callback = function()
        Utility.StartMilitaryDetectiveQuest()
    end,
})

TestTab:AddSection("Milestone Quick Teleport & Inspection")

TestTab:AddButton({
    Name = "Fly to Quest Giver",
    Desc = "Fly to selected milestone's Quest Giver",
    Callback = function()
        local qData = Utility.GetMilestoneByIndex(selectedMilestoneIndex)
        if qData and qData.GiverPos then
            UILib.Notify("Testing", "Flying to Quest Giver for " .. qData.Mob .. "...", 3)
            Utility.PhysicsFlyTo(qData.GiverPos + Vector3.new(0, 5, 0), S.TeleportFlySpeed or 200, function()
                UILib.Notify("Testing", "Arrived at Quest Giver!", 3)
            end)
        end
    end,
})

TestTab:AddButton({
    Name = "Fly to Mob Spawn Area",
    Desc = "Fly to selected milestone's Mob Area",
    Callback = function()
        local qData = Utility.GetMilestoneByIndex(selectedMilestoneIndex)
        if qData and qData.MobPos then
            UILib.Notify("Testing", "Flying to Mob Area (" .. qData.Mob .. ")...", 3)
            Utility.PhysicsFlyTo(qData.MobPos + Vector3.new(0, S.AttackHeight or 40, 0), S.TeleportFlySpeed or 200, function()
                UILib.Notify("Testing", "Arrived at Mob Area!", 3)
            end)
        end
    end,
})

TestTab:AddButton({
    Name = "Check Active Mobs in Range",
    Desc = "Count how many mobs exist for selected milestone",
    Callback = function()
        local qData = Utility.GetMilestoneByIndex(selectedMilestoneIndex)
        if not qData then return end
        local enemiesFolder = workspace:FindFirstChild("Enemies")
        local count = 0
        if enemiesFolder then
            for _, model in ipairs(enemiesFolder:GetChildren()) do
                if model:IsA("Model") and model.Name:lower():find(qData.Mob:lower()) then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        count = count + 1
                    end
                end
            end
        end
        UILib.Notify("Testing", "Found " .. count .. " alive " .. qData.Mob .. " in workspace!", 5)
    end,
})

TestTab:AddButton({
    Name = "Take Selected Quest Instantly",
    Desc = "Manually start the selected milestone quest",
    Callback = function()
        local qData = Utility.GetMilestoneByIndex(selectedMilestoneIndex)
        if qData then
            Utility.StartQuest(qData.Quest, qData.QLevel)
            UILib.Notify("Testing", "Requested quest: " .. qData.Quest .. " (Lvl " .. qData.QLevel .. ")", 4)
        end
    end,
})

TestTab:AddButton({
    Name = "Abandon Current Quest",
    Desc = "Cancel your active quest immediately",
    Callback = function()
        Utility.AbandonQuest()
        UILib.Notify("Testing", "Abandoned active quest!", 3)
    end,
})

TestTab:AddSection("Instant CFrame Test Teleport (No Fly)")

TestTab:AddButton({
    Name = "⚡ Instant CFrame to Milestone Giver",
    Desc = "Instant CFrame teleport to milestone Quest Giver",
    Callback = function()
        local qData = Utility.GetMilestoneByIndex(selectedMilestoneIndex)
        if qData and qData.GiverPos then
            Utility.InstantCFrameTeleport(qData.GiverPos + Vector3.new(0, 3, 0), "Quest Giver (" .. qData.Mob .. ")")
        end
    end,
})

TestTab:AddButton({
    Name = "⚡ Instant CFrame to Milestone Mob Area",
    Desc = "Instant CFrame teleport to milestone Mob Area",
    Callback = function()
        local qData = Utility.GetMilestoneByIndex(selectedMilestoneIndex)
        if qData and qData.MobPos then
            Utility.InstantCFrameTeleport(qData.MobPos + Vector3.new(0, 5, 0), "Mob Area (" .. qData.Mob .. ")")
        end
    end,
})

-- ═══════════════════════════════════════════════════════════
--  TAB 8 : MISC
-- ═══════════════════════════════════════════════════════════
local MiscTab = Window:AddTab({ Name = "Misc", Icon = "" })

MiscTab:AddSection("Movement")

MiscTab:AddSlider({
    Name = "Walk Speed", Desc = "Custom walk speed",
    Min = 16, Max = 300, Default = S.CustomWalkSpeed or 100, Suffix = "",
    Callback = function(v) S.CustomWalkSpeed = v end,
})

MiscTab:AddSlider({
    Name = "Jump Power", Desc = "Custom jump power",
    Min = 50, Max = 500, Default = S.CustomJumpPower or 50, Suffix = "",
    Callback = function(v) S.CustomJumpPower = v end,
})

MiscTab:AddSection("NoClip")

UI_ELEMENTS["PlayerNoClipEnabled"] = MiscTab:AddToggle({
    Name = "Player Noclip", Desc = "Enable player noclip", Default = (S.PlayerNoClipEnabled ~= nil) and S.PlayerNoClipEnabled or true,
    Callback = function(val) 
        Utility.SetPlayerNoClip(val)
    end,
})

MiscTab:AddSection("Water & AFK")

UI_ELEMENTS["WalkOnWaterEnabled"] = MiscTab:AddToggle({
    Name = "Walk on Water", Desc = "Walk on water platform", Default = (S.WalkOnWaterEnabled ~= nil) and S.WalkOnWaterEnabled or true,
    Callback = function(val) S.WalkOnWaterEnabled = val end,
})

UI_ELEMENTS["AntiAFKEnabled"] = MiscTab:AddToggle({
    Name = "Anti-AFK", Desc = "Prevent AFK kick", Default = (S.AntiAFKEnabled ~= nil) and S.AntiAFKEnabled or true,
    Callback = function(val) S.AntiAFKEnabled = val end,
})

MiscTab:AddSection("Graphics")

MiscTab:AddButton({
    Name = "Boost FPS",
    Desc = "Optimize graphics for FPS",
    Callback = function() Utility.OptimizeGraphics() end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 9 : WEBHOOK CONFIG
-- ═══════════════════════════════════════════════════════════
local WhTab = Window:AddTab({ Name = "Webhook", Icon = "" })

WhTab:AddSection("Discord Webhook")

UI_ELEMENTS["WebhookEnabled"] = WhTab:AddToggle({
    Name = "Webhook Leviathan",
    Desc = "Notify when Leviathan spawns",
    Default = (S.WebhookEnabled ~= nil) and S.WebhookEnabled or true,
    Callback = function(val) S.WebhookEnabled = val end,
})

WhTab:AddInput({
    Name = "Discord Webhook URL",
    Desc = "Enter Discord Webhook URL",
    Placeholder = S.WebhookURL ~= "" and S.WebhookURL or "https://discord.com/api/webhooks/...",
    Callback = function(text)
        if string.find(text, "http") then
            S.WebhookURL = text
            UILib.Notify("Webhook", "Webhook URL received!", 3)
        end
    end,
})

WhTab:AddSection("Manual Test")

WhTab:AddButton({
    Name = "Test Webhook",
    Desc = "Send test webhook ",
    Callback = function()
        if S.WebhookURL == "" then
            UILib.Notify("Error", "Webhook URL not set!", 3); return
        end
        Utility.SendWebhook(S.WebhookURL, LocalPlayer)
        UILib.Notify("Webhook", "Webhook test sent!", 3)
    end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 10 : PLAYER PANEL
-- ═══════════════════════════════════════════════════════════
local PlayerTab = Window:AddTab({ Name = "Player Panel", Icon = "" })

PlayerTab:AddSection("Player Status")

local statusInfo = PlayerTab:AddInfo({ Title = "Status", Value = "Checking..." })
local coordsInfo = PlayerTab:AddInfo({ Title = "Coordinates", Value = "Checking..." })

PlayerTab:AddButton({
    Name = "Copy Coordinates",
    Desc = "Copy coordinates to clipboard",
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
    Desc = "Copy Job ID to clipboard",
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
    Name = "Save Settings",
    Desc = "Save settings to local storage",
    Callback = function()
        Utility.SaveLocalConfig()
    end,
})

PlayerTab:AddButton({
    Name = "Copy Config",
    Desc = "Copy config loader to clipboard",
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

--[[ Restore & activate all background routines based on loaded config ]]
function Utility.RestoreAndActivateAll()
    task.spawn(function()
        task.wait(0.3)
        if S.PlayerNoClipEnabled then Utility.SetPlayerNoClip(true) end
        if S.BoatNoClipEnabled then Utility.SetBoatNoClip(true) end
        if S.AutoFarmSeaEventsEnabled then Utility.StartAutoFarmSeaEvents() end
        if S.FindLeviathanEnabled then Utility.StartFindLeviathan() end
        if S.MultipleFindLeviathanEnabled then Utility.StartMultipleFindLeviathan() end
        if S.AutoShootLeviEnabled then Utility.StartAutoShootLeviathan() end
        if S.AutoAttackLeviEnabled then Utility.StartAutoAttackLeviathan() end
        if S.AutoSkillsLeviEnabled then Utility.StartAutoSkillsLeviathan() end
        if S.AutoTalkFrozenWatcherEnabled then Utility.StartAutoTalkFrozenWatcher() end
        if S.AutoAttackEnemyEnabled then Utility.StartAutoAttackNearestEnemy() end
        if S.AutoFarmWithSkillsEnabled then Utility.StartAutoFarmWithSkills() end
        if S.AutoFarmLevelEnabled then Utility.StartAutoFarmLevel() end
        if S.AutoFarmSelectedMobEnabled then Utility.StartAutoFarmSelectedMob() end
        if S.AutoFarmSelectedBossEnabled then Utility.StartAutoFarmSelectedBoss() end
        if S.AutoFarmMaterialEnabled then Utility.StartAutoFarmMaterial() end
        if S.AutoFarmChestEnabled then Utility.StartAutoFarmChests() end
        if S.AutoStatsMelee or S.AutoStatsDefense or S.AutoStatsSword or S.AutoStatsGun or S.AutoStatsFruit then Utility.StartAutoStatsLoop() end
        if S.AutoRaceV3 or S.AutoAwakeningV4 then Utility.StartAutoAwakeningLoop() end
        if S.ResetWhenBoatDestroyed then Utility.StartResetWhenBoatDestroyed() end
        if S.ResetWhenSelectedOwnerDie then Utility.StartResetWhenSelectedOwnerDie() end
        if S.AutoFlyTikiEnabled then Utility.StartAutoFlyToTiki() end
        if S.AutoFlyHydraEnabled then Utility.StartAutoFlyToHydra() end
        if S.TeleportPlayerEnabled then Utility.StartFlyFollowPlayer() end
    end)
end
Utility.RestoreAndActivateAll()


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

-- Vòng lặp kiểm tra hạn Key (Chỉ kích hoạt nếu chạy qua Cloud Loader, an toàn 100% khi test local)
_conns["keyExpiryIntegrityLoop"] = task.spawn(function()
    while true do
        task.wait(300) -- 5 phút (300 giây)
        if _G.HilichurlKeyData and _G.HilichurlKeyData.ExpiresAt then
            if os.time() >= _G.HilichurlKeyData.ExpiresAt then
                if UILib and UILib.Notify then
                    UILib.Notify("Key System", "Key expired! Unloading script...", 4)
                end
                task.wait(1)
                if _G.UnloadScript then 
                    _G.UnloadScript() 
                end
                break
            end
        end
    end
end)
