-- ============================================================
--  Blox_Fruit_Script.lua  (Single-File Executor · Luau)
--  Author  : Hilichurl  |  Version : 7.0.0 (Standardized Architecture)
-- ============================================================

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

--[[ Bảo vệ GUI khỏi các cơ chế phát hiện của game ]]
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

--[[ Tải ảnh từ đường dẫn online và lưu trữ tạm thời ]]
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

--[[ Tạo thành phần Frame chuẩn với bo góc ]]
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

--[[ Tạo thành phần TextLabel chuẩn ]]
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

--[[ Cho phép kéo thả giao diện trên mọi thiết bị ]]
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
--[[ Khởi tạo vùng hiển thị thông báo góc màn hình ]]
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
--[[ Hiển thị thông báo dạng thẻ nổi mượt mà ]]
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

--[[ Xây dựng nút tròn đóng mở UI di động trên màn hình ]]
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

--[[ Khởi tạo cửa sổ chính Responsive chuẩn xác cho cả Mobile và PC ]]
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

    -- Nút điều chỉnh độ to nhỏ của UI ở góc dưới bên trái
    local scaleBtn = Instance.new("TextButton")
    scaleBtn.Name = "ScaleToggleBtn"; scaleBtn.Text = string.format("📏 UI: %.0f%%", uiScale.Scale * 100)
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
        scaleBtn.Text = string.format("📏 UI: %.0f%%", newScale * 100)
        UILib.Notify("UI Scale", string.format("Đã chỉnh kích thước UI về %.0f%%!", newScale * 100), 2)
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

            local function UpdateUI(val)
                value = math.clamp(val, mn, mx)
                local p = (value - mn) / (mx - mn)
                fill.Size = UDim2.new(p, 0, 1, 0); thumb.Position = UDim2.new(p, -5, 0.5, -5)
                valBox.Text = tostring(value) .. sfx
                pcall(cb, value)
            end

            local function UpdateSliderFromInput(ax)
                local rx = math.clamp(ax - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
                local p = rx / track.AbsoluteSize.X
                local v = math.floor(mn + p * (mx - mn) + 0.5)
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
            local desc = dc.Desc or ""; local rH = desc ~= "" and 44 or 30; local selectedText = "None"
            local row = CreateFrame({Color = THEME.BTN_IDLE, Size = UDim2.new(1, 0, 0, rH), Name = "DD_" .. lbl, Parent = page, Radius = 5})
            local ip = Instance.new("UIPadding"); ip.PaddingLeft = UDim.new(0, 8); ip.PaddingRight = UDim.new(0, 8); ip.Parent = row
            CreateLabel({Text = lbl, Size = 11, Color = THEME.TEXT, FS = UDim2.new(1, -100, 0, 16), Pos = UDim2.fromOffset(0, 4), Parent = row})
            if desc ~= "" then CreateLabel({Text = desc, Size = 9, Color = THEME.TEXT_SUB, Font = Enum.Font.Gotham, FS = UDim2.new(1, -100, 0, 14), Pos = UDim2.fromOffset(0, 22), Parent = row}) end
            local selLbl = CreateLabel({Text = selectedText .. "", Size = 10, Color = THEME.ACCENT, XA = Enum.TextXAlignment.Right, FS = UDim2.new(0, 95, 0, 16), Pos = UDim2.new(1, -95, 0, 4), Name = "SelLbl", Parent = row})

            local activeDropdown = nil

            local function BuildDropdown()
                if activeDropdown then activeDropdown:Destroy(); activeDropdown = nil; return end
                local n = #opts
                if n == 0 then return end

                local ddH = math.min(n, 5) * 26 + 4
                local dropdown = CreateFrame({
                    Color = THEME.BG_OVERLAY, Size = UDim2.fromOffset(row.AbsoluteSize.X, ddH),
                    Pos = UDim2.fromOffset(row.AbsolutePosition.X, row.AbsolutePosition.Y + row.AbsoluteSize.Y + 4),
                    Name = "GlobalDDList", Parent = sg, Radius = 5
                })
                dropdown.ZIndex = 500; activeDropdown = dropdown

                local outSt = Instance.new("UIStroke"); outSt.Color = THEME.ACCENT; outSt.Thickness = 1; outSt.Parent = dropdown

                local scrollDD = Instance.new("ScrollingFrame")
                scrollDD.Size = UDim2.new(1, 0, 1, 0); scrollDD.BackgroundTransparency = 1; scrollDD.BorderSizePixel = 0
                scrollDD.ScrollBarThickness = 2; scrollDD.ScrollBarImageColor3 = THEME.ACCENT
                scrollDD.CanvasSize = UDim2.new(0, 0, 0, n * 26); scrollDD.ZIndex = 501; scrollDD.Parent = dropdown

                local dll = Instance.new("UIListLayout"); dll.SortOrder = Enum.SortOrder.LayoutOrder; dll.Padding = UDim.new(0, 2); dll.Parent = scrollDD

                for _, opt in ipairs(opts) do
                    local ob = Instance.new("TextButton")
                    ob.Text = opt; ob.Font = Enum.Font.GothamMedium; ob.TextSize = 10; ob.TextColor3 = THEME.TEXT
                    ob.BackgroundColor3 = THEME.BTN_IDLE; ob.BackgroundTransparency = 0.2; ob.AutoButtonColor = false
                    ob.Size = UDim2.new(1, 0, 0, 24); ob.TextXAlignment = Enum.TextXAlignment.Left; ob.ZIndex = 502; ob.Parent = scrollDD

                    local op = Instance.new("UIPadding"); op.PaddingLeft = UDim.new(0, 8); op.Parent = ob

                    ob.MouseEnter:Connect(function() TweenService:Create(ob, TI_FAST, {BackgroundTransparency = 0, TextColor3 = THEME.BTN_TEXT_HOV, BackgroundColor3 = THEME.BTN_HOVER}):Play() end)
                    ob.MouseLeave:Connect(function() TweenService:Create(ob, TI_FAST, {BackgroundTransparency = 0.2, TextColor3 = THEME.TEXT, BackgroundColor3 = THEME.BTN_IDLE}):Play() end)
                    ob.MouseButton1Click:Connect(function()
                        selectedText = opt; selLbl.Text = opt .. ""
                        pcall(cb, opt)
                        if activeDropdown then activeDropdown:Destroy(); activeDropdown = nil end
                    end)
                end
            end

            local clDD = Instance.new("TextButton"); clDD.Text = ""; clDD.BackgroundTransparency = 1; clDD.Size = UDim2.new(1, 0, 1, 0); clDD.AutoButtonColor = false; clDD.Parent = row
            clDD.MouseButton1Click:Connect(BuildDropdown)

            local DDObj = {}
            function DDObj:Refresh(newOpts) 
                opts = newOpts 
                if #opts == 0 then selectedText = "None"; selLbl.Text = "None" end
                if activeDropdown then activeDropdown:Destroy(); activeDropdown = nil end
            end
            function DDObj:Get() return selectedText end
            return DDObj
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

        return Tab
    end

    return W
end


-- ╔══════════════════════════════════════════════════════════╗
-- ║         [SECTION 3] UTILITY & CORE LOGIC FUNCTIONS       ║
-- ╚══════════════════════════════════════════════════════════╝

local Utility = {}
local _conns  = {}

local CharacterParts = {}
local BoatParts = {}
local FlyActive = false

local IslandESP_Folder = nil
local PlayerESP_Folder = nil
local SeatESP_Folder   = nil

local S = {
    BoatFlySpeed                = 220,
    BoatFlyHeight               = 195,
    CustomBoatSpeed             = 250,
    EnableBoatSpeed             = false,
    AutoBuyBoatEnabled          = false,
    SelectedBoat                = "Beast Hunter",
    FindLeviathanEnabled        = false,
    MultipleFindLeviathanEnabled= false,
    SelectedBoatOwner           = "",
    AutoShootLeviEnabled        = false,
    AutoAttackEnemyEnabled      = false,
    BoatNoClipEnabled           = false,
    PlayerNoClipEnabled         = false,
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
    IslandESPEnabled            = false,
    PlayerESPEnabled            = false,
    BoatSeatESPEnabled          = false,
}

local WebhookSent                 = false
local FindLeviathanConnection      = nil
local FindLeviathanToggle          = nil
local MultipleFindLeviathanToggle  = nil
local BoatSpeedConnection         = nil
local ActiveBoat                  = nil

--[[ Ngắt kết nối an toàn cho một key kết nối cụ thể ]]
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

--[[ Cập nhật bộ nhớ đệm Part của nhân vật để xử lý NoClip ]]
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

--[[ Cập nhật bộ nhớ đệm Part của thuyền để xử lý NoClip ]]
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

--[[ Lấy đối tượng thuyền mà người chơi hiện đang ngồi lái ]]
function Utility.GetBoat()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        return hum.SeatPart.Parent
    end
    return nil
end

--[[ Buộc thuyền dừng lại và triệt tiêu toàn bộ vận tốc ]]
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

--[[ Kiểm tra xem Frozen Watcher hoặc Leviathan Gate đã xuất hiện chưa ]]
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

--[[ Thực hiện bay vật lý nhân vật đến toạ độ chỉ định bằng BodyVelocity và BodyGyro ]]
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
        hum.PlatformStand = true
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)

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

            if dist <= 6 then
                Utility.StopPhysicsFly()
                if currentFlyOnComplete then currentFlyOnComplete() end
                return
            end

            local activeBV = root:FindFirstChild("PlayerFlyBV")
            if activeBV then
                activeBV.Velocity = dir.Unit * currentFlySpeed
            end

            local activeBG = root:FindFirstChild("PlayerFlyBG")
            if activeBG then
                activeBG.CFrame = CFrame.lookAt(currentPos, currentFlyTarget)
            end
        end)
    end
end

--[[ Dừng hoàn toàn chế độ bay vật lý và phục hồi trạng thái nhân vật ]]
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

--[[ Đặt lại góc nhìn Camera và gỡ kẹt cho nhân vật ]]
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

    UILib.Notify("Unstuck", "Đã giải phóng Camera & Nhân vật thành công!", 3)
end

--[[ Lấy chuỗi tên chủ nhân từ đối tượng thuyền ]]
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

--[[ Tìm thuyền trong workspace.Boats theo tên chủ thuyền ]]
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

--[[ Tìm ghế Cannon còn trống trên thuyền ]]
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

--[[ Lấy danh sách tên tất cả người chơi trong server ngoại trừ bản thân ]]
function Utility.GetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    return list
end

--[[ Lấy thuyền của người chơi dựa trên tên thuyền hoặc vị trí ]]
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

--[[ Bay đến vị trí ghế và ngồi vào ghế an toàn ]]
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
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)

        root.CFrame = targetSeat.CFrame * CFrame.new(0, 1.2, 0)
        task.wait(0.05)
        pcall(function() targetSeat:Sit(hum) end)

        -- Kiểm tra xác thực trạng thái NGỒI THẬT SỰ từ hệ thống Roblox
        for _ = 1, 15 do
            if hum.SeatPart == targetSeat then
                if onSeatSuccess then onSeatSuccess() end
                return true
            end
            task.wait(0.1)
        end

        return (hum.SeatPart == targetSeat)
    end

    local seatPos = targetSeat.Position
    local dist = (seatPos - root.Position).Magnitude

    -- 2. Nếu đã ở cự ly gần (<= 5 studs) -> Thực hiện ngồi trực tiếp
    if dist <= 5 then
        return AttemptNativeSit()
    end

    -- 3. Nếu ở xa -> Bay Physics Fly đến ghế rồi ngồi thật
    local speed = S.TeleportFlySpeed or 180
    local targetPos = seatPos + Vector3.new(0, 1.5, 0)

    Utility.PhysicsFlyTo(targetPos, speed, function()
        if targetSeat and targetSeat.Parent and LocalPlayer.Character then
            AttemptNativeSit()
        end
    end)

    return (hum.SeatPart == targetSeat)
end

--[[ Ngồi vào ghế lái VehicleSeat của thuyền ]]
function Utility.SitVehicleSeat(boat)
    if not boat then return false end
    local vSeat = boat:FindFirstChildOfClass("VehicleSeat") or boat:FindFirstChild("VehicleSeat", true)
    if not vSeat then return false end
    return Utility.FlyToAndSitSeat(vSeat)
end

--[[ Ngồi vào ghế Cannon còn trống của thuyền ]]
function Utility.SitCannonSeat(boat)
    if not boat then return false end
    local cannonSeat = Utility.GetAvailableCannonSeat(boat)
    if not cannonSeat then return false end
    return Utility.FlyToAndSitSeat(cannonSeat)
end

--[[ Lấy thuyền Beast Hunter của người chơi ]]
function Utility.GetBeastHunterBoat()
    return Utility.GetPlayerBoat("Beast Hunter")
end

--[[ Gửi Remote mua thuyền theo tên chỉ định ]]
function Utility.BuyBoat(boatName)
    local target = boatName or S.SelectedBoat or "Beast Hunter"
    local ok, res = pcall(function()
        local Event = game:GetService("ReplicatedStorage").Remotes.CommF_
        return Event:InvokeServer("BuyBoat", target)
    end)
    return ok, res
end

--[[ Tìm đối tượng Frozen Heart trong workspace ]]
function Utility.GetFrozenHeart()
    local assets = workspace:FindFirstChild("Assets")
    if assets then
        local fh = assets:FindFirstChild("FrozenHeart") or assets:FindFirstChild("Frozen Heart")
        if fh then return fh end
    end

    for _, child in ipairs(workspace:GetDescendants()) do
        if child.Name == "FrozenHeart" or child.Name == "Frozen Heart" then
            return child
        end
    end
    return nil
end

--[[ Lấy danh sách tên tất cả các đảo trong game ]]
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

--[[ Lấy đối tượng Model/Folder của đảo dựa trên tên ]]
function Utility.GetIslandObject(islandName)
    if not islandName then return nil end
    local mapFolder = workspace:FindFirstChild("Map")
    local locFolder = workspace:FindFirstChild("Locations")
    return (mapFolder and mapFolder:FindFirstChild(islandName))
        or (locFolder and locFolder:FindFirstChild(islandName))
        or workspace:FindFirstChild(islandName)
end

--[[ Tạo nhãn ESP BillboardGui trên đối tượng Part ]]
function Utility.CreateESPLabel(parent, text, color)
    local bg = Instance.new("BillboardGui")
    bg.Name = "ESP_UI"
    bg.Adornee = parent
    bg.Size = UDim2.fromOffset(200, 35)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0, 10, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color or Color3.fromRGB(163, 230, 53)
    lbl.TextBold = true
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = text
    lbl.Parent = bg

    return bg
end

--[[ Tối ưu hoá đồ hoạ để tăng chỉ số FPS ]]
function Utility.OptimizeGraphics()
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
    UILib.Notify("Boost FPS", "Đã tối ưu đồ họa mượt mà!", 3)
end

--[[ Gửi Webhook Discord thông báo xuất hiện Leviathan ]]
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
            description = string.format("**Player:** `%s`\n**User ID:** `%d`\n**Tọa độ:** `%s`\n**Thời gian:** `%s`",
                player.Name, player.UserId, posStr, os.date("%H:%M:%S - %d/%m/%Y")),
            color = 3840742,
            fields = {
                { name = "Trạng thái", value = "Đã tìm thấy Leviathan Gate / Frozen Dimension!", inline = true },
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

--[[ Khởi động chuyến bay tự động của thuyền tìm Leviathan ]]
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
    ao.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(0, 0, 1))
    ao.Parent = seat

    local startY = seat.Position.Y
    local stage1_Dur = 7
    local stage2_Dur = 10
    local t0 = os.clock()

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
        local el  = os.clock() - t0
        local speedZ = S.BoatFlySpeed

        if el <= stage1_Dur then
            local prog = el / stage1_Dur
            local ty   = startY + (800 - startY) * prog
            lv.VectorVelocity = Vector3.new(0, (ty - pos.Y) * 15, 0)
        elseif el <= (stage1_Dur + stage2_Dur) then
            lv.VectorVelocity = Vector3.new(0, (800 - pos.Y) * 10, speedZ)
        else
            lv.VectorVelocity = Vector3.new(0, (S.BoatFlyHeight - pos.Y) * 5, speedZ)
        end
    end)
    _conns["findLev"] = FindLeviathanConnection
end

--[[ Xử lý khi phát hiện Leviathan xuất hiện ]]
function Utility.HandleLeviathanFound()
    DisconnectConnection("findLev")
    DisconnectConnection("multiFindLev")
    DisconnectConnection("levNpcAdded")
    DisconnectConnection("levSeaAdded")
    DisconnectConnection("levMapAdded")
    DisconnectConnection("seatWatcher")
    DisconnectConnection("teleportPlayerLoop")

    S.FindLeviathanEnabled = false
    S.MultipleFindLeviathanEnabled = false
    S.TeleportPlayerEnabled = false
    S.BoatNoClipEnabled = false
    if FindLeviathanToggle then FindLeviathanToggle:Set(false) end
    if MultipleFindLeviathanToggle then MultipleFindLeviathanToggle:Set(false) end

    if ActiveBoat then Utility.ForceStopBoat(ActiveBoat) end
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

    UILib.Notify("❄️ LEVIATHAN SPAWNED!", "Đã dừng script & giải phóng Camera để chạy Cutscene!", 6)
end

--[[ Kích hoạt trình theo dõi đối tượng Leviathan trong các thư mục ]]
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

--[[ Quản lý vòng lặp Find Leviathan tự động ]]
function Utility.StartFindLeviathan()
    WebhookSent = false
    Utility.EnableLeviathanWatcher()

    if Utility.IsFrozenWatcher() then
        Utility.HandleLeviathanFound()
        return
    end

    DisconnectConnection("seatWatcher")
    _conns["seatWatcher"] = task.spawn(function()
        while S.FindLeviathanEnabled do
            if Utility.IsFrozenWatcher() then
                Utility.HandleLeviathanFound()
                break
            end

            local selBoatName = S.SelectedBoat or "Beast Hunter"
            local playerBoat = Utility.GetPlayerBoat(selBoatName)

            if not playerBoat or not playerBoat.Parent then
                if ActiveBoat then
                    Utility.ForceStopBoat(ActiveBoat)
                    ActiveBoat = nil
                end
                DisconnectConnection("findLev")

                UILib.Notify("Find Leviathan", "Đang mua thuyền " .. selBoatName .. "...", 3)
                Utility.BuyBoat(selBoatName)

                local t0 = os.clock()
                while S.FindLeviathanEnabled and (os.clock() - t0 < 6) do
                    playerBoat = Utility.GetPlayerBoat(selBoatName)
                    if playerBoat and playerBoat.Parent then break end
                    task.wait(0.5)
                end
            end

            if playerBoat and playerBoat.Parent then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local vSeat = playerBoat:FindFirstChildOfClass("VehicleSeat") or playerBoat:FindFirstChild("VehicleSeat", true)

                if hum and vSeat then
                    if hum.SeatPart ~= vSeat then
                        Utility.SitVehicleSeat(playerBoat)
                    end

                    if hum.SeatPart == vSeat then
                        if not _conns["findLev"] or ActiveBoat ~= playerBoat then
                            Utility.StartBoatFlight(playerBoat)
                        end
                    end
                end
            end

            task.wait(0.5)
        end
    end)
end

--[[ Dừng vòng lặp Find Leviathan ]]
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

--[[ Bay đến và ngồi vào ghế Cannon trên thuyền của Owner đã chọn (Kích hoạt 1 lần) ]]
function Utility.FlyToOwnerBoatCannon()
    if not S.SelectedBoatOwner or S.SelectedBoatOwner == "" then
        UILib.Notify("Lỗi", "Vui lòng chọn chủ thuyền trước!", 3)
        return
    end

    local ownerBoat = Utility.GetBoatByOwner(S.SelectedBoatOwner)
    if not ownerBoat or not ownerBoat.Parent then
        UILib.Notify("Lỗi", "Không tìm thấy thuyền của " .. S.SelectedBoatOwner .. "!", 3)
        return
    end

    local cannonSeat = Utility.GetAvailableCannonSeat(ownerBoat)
    if not cannonSeat then
        UILib.Notify("Lỗi", "Không tìm thấy ghế Cannon trống trên thuyền của " .. S.SelectedBoatOwner .. "!", 3)
        return
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart == cannonSeat then
        UILib.Notify("Cannon", "Bạn đã đang ngồi trên ghế Cannon này rồi!", 3)
        return
    end

    UILib.Notify("Cannon", "Đang bay đến ghế Cannon thuyền của " .. S.SelectedBoatOwner .. "...", 3)
    Utility.FlyToAndSitSeat(cannonSeat, function()
        UILib.Notify("Thành công", "Đã ngồi lên Cannon thuyền của " .. S.SelectedBoatOwner .. "!", 3)
    end)
end

--[[ Quản lý vòng lặp tự động mua thuyền ]]
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

--[[ Dừng vòng lặp tự động mua thuyền ]]
function Utility.StopAutoBuyBoat()
    DisconnectConnection("autoBuyBoat")
end

--[[ Quản lý vòng lặp Auto Shoot Leviathan Heart ]]
function Utility.StartAutoShootLeviathan()
    local autoShootNotified = false
    DisconnectConnection("autoShootLev")

    _conns["autoShootLev"] = RunService.Heartbeat:Connect(function()
        if not S.AutoShootLeviEnabled then
            DisconnectConnection("autoShootLev")
            if ActiveBoat then Utility.ForceStopBoat(ActiveBoat) end
            return
        end

        local currentBoat = Utility.GetBoat() or Utility.GetBeastHunterBoat()
        if not currentBoat then
            if not autoShootNotified then
                UILib.Notify("Auto Shoot", "Chờ người chơi ngồi lái thuyền Beast Hunter...", 3)
                autoShootNotified = true
            end
            return
        end

        local vSeat = currentBoat:FindFirstChildOfClass("VehicleSeat") or currentBoat.PrimaryPart
        if not vSeat then return end

        local frozenHeart = Utility.GetFrozenHeart()
        if not frozenHeart then
            if not autoShootNotified then
                UILib.Notify("Auto Shoot", "Thuyền đã sẵn sàng! Đang chờ xuất hiện FrozenHeart...", 4)
                autoShootNotified = true
            end
            return
        end

        local fhCF = frozenHeart:IsA("Model") and frozenHeart:GetPivot() or frozenHeart.CFrame
        local targetCF = fhCF * CFrame.new(12, 80, 0)

        ActiveBoat = currentBoat
        local seatPos = vSeat.Position
        local dir = (targetCF.Position - seatPos)
        local dist = dir.Magnitude

        local att = vSeat:FindFirstChild("FlyAttachment") or Instance.new("Attachment")
        att.Name = "FlyAttachment"; att.Parent = vSeat

        local lv = vSeat:FindFirstChild("FlyLinearVelocity") or Instance.new("LinearVelocity")
        lv.Name = "FlyLinearVelocity"; lv.Attachment0 = att
        lv.MaxForce = math.huge; lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.Parent = vSeat

        local ao = vSeat:FindFirstChild("FlyAlignOrientation") or Instance.new("AlignOrientation")
        ao.Name = "FlyAlignOrientation"; ao.Attachment0 = att
        ao.MaxTorque = math.huge; ao.Responsiveness = 200
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; ao.Parent = vSeat

        if dist <= 8 then
            lv.VectorVelocity = Vector3.zero
            ao.CFrame = CFrame.lookAt(seatPos, fhCF.Position)
        else
            lv.VectorVelocity = dir.Unit * S.BoatFlySpeed
            ao.CFrame = CFrame.lookAt(seatPos, targetCF.Position)
        end
    end)
end

--[[ Dừng vòng lặp Auto Shoot Leviathan Heart ]]
function Utility.StopAutoShootLeviathan()
    DisconnectConnection("autoShootLev")
    if ActiveBoat then
        Utility.ForceStopBoat(ActiveBoat)
        ActiveBoat = nil
    end
end

--[[ Quản lý vòng lặp Fly Follow Player ]]
function Utility.StartFlyFollowPlayer()
    if not S.SelectedPlayer then
        UILib.Notify("Lỗi", "Hãy chọn người chơi hợp lệ!", 3)
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

--[[ Dừng vòng lặp Fly Follow Player ]]
function Utility.StopFlyFollowPlayer()
    DisconnectConnection("teleportPlayerLoop")
    Utility.ResetCameraAndCharacter()
end

--[[ Quản lý vòng lặp Island ESP ]]
function Utility.StartIslandESP()
    if not IslandESP_Folder then
        IslandESP_Folder = Instance.new("Folder")
        IslandESP_Folder.Name = "IslandESP_Container"
        IslandESP_Folder.Parent = CoreGui
    end

    DisconnectConnection("islandEspLoop")
    _conns["islandEspLoop"] = RunService.Heartbeat:Connect(function()
        if not S.IslandESPEnabled then
            DisconnectConnection("islandEspLoop")
            if IslandESP_Folder then IslandESP_Folder:ClearAllChildren() end
            return
        end

        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local currentIslands = Utility.GetIslandList()
        for _, islName in ipairs(currentIslands) do
            local islObj = Utility.GetIslandObject(islName)
            if islObj then
                local primaryPart = islObj.PrimaryPart or islObj:FindFirstChildOfClass("BasePart")
                if primaryPart then
                    local espUI = IslandESP_Folder:FindFirstChild("ESP_" .. islName)
                    local dist = math.floor((primaryPart.Position - myRoot.Position).Magnitude)
                    local textStr = string.format("🏝️ %s\n[%d studs]", islName, dist)

                    if not espUI then
                        espUI = Utility.CreateESPLabel(primaryPart, textStr, Color3.fromRGB(0, 255, 170))
                        espUI.Name = "ESP_" .. islName
                        espUI.Parent = IslandESP_Folder
                    else
                        local lbl = espUI:FindFirstChildOfClass("TextLabel")
                        if lbl then lbl.Text = textStr end
                    end
                end
            end
        end
    end)
end

--[[ Dừng vòng lặp Island ESP ]]
function Utility.StopIslandESP()
    DisconnectConnection("islandEspLoop")
    if IslandESP_Folder then IslandESP_Folder:ClearAllChildren() end
end

--[[ Quản lý vòng lặp Player ESP ]]
function Utility.StartPlayerESP()
    if not PlayerESP_Folder then
        PlayerESP_Folder = Instance.new("Folder")
        PlayerESP_Folder.Name = "PlayerESP_Container"
        PlayerESP_Folder.Parent = CoreGui
    end

    DisconnectConnection("playerEspLoop")
    _conns["playerEspLoop"] = RunService.Heartbeat:Connect(function()
        if not S.PlayerESPEnabled then
            DisconnectConnection("playerEspLoop")
            if PlayerESP_Folder then PlayerESP_Folder:ClearAllChildren() end
            return
        end

        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = p.Character.HumanoidRootPart
                local espUI = PlayerESP_Folder:FindFirstChild("ESP_" .. p.Name)
                local dist = math.floor((targetRoot.Position - myRoot.Position).Magnitude)
                local isSelf = (p == LocalPlayer)
                local displayName = isSelf and (p.Name .. " (You)") or p.Name
                local textStr = string.format("👤 %s\n[%d studs]", displayName, dist)
                local labelColor = isSelf and Color3.fromRGB(163, 230, 53) or Color3.fromRGB(255, 220, 0)

                if not espUI then
                    espUI = Utility.CreateESPLabel(targetRoot, textStr, labelColor)
                    espUI.Name = "ESP_" .. p.Name
                    espUI.Parent = PlayerESP_Folder
                else
                    local lbl = espUI:FindFirstChildOfClass("TextLabel")
                    if lbl then lbl.Text = textStr end
                end
            end
        end
    end)
end

--[[ Dừng vòng lặp Player ESP ]]
function Utility.StopPlayerESP()
    DisconnectConnection("playerEspLoop")
    if PlayerESP_Folder then PlayerESP_Folder:ClearAllChildren() end
end

--[[ Quản lý vòng lặp Boat Seat Live ESP ]]
function Utility.StartBoatSeatESP(targetOwnerName)
    if not SeatESP_Folder then
        SeatESP_Folder = Instance.new("Folder")
        SeatESP_Folder.Name = "SeatESP_Folder"
        SeatESP_Folder.Parent = CoreGui
    end

    DisconnectConnection("boatSeatEspLoop")
    _conns["boatSeatEspLoop"] = RunService.RenderStepped:Connect(function()
        if not S.BoatSeatESPEnabled then
            DisconnectConnection("boatSeatEspLoop")
            if SeatESP_Folder then SeatESP_Folder:ClearAllChildren() end
            return
        end

        local ownerName = (targetOwnerName ~= "") and targetOwnerName or S.SelectedBoatOwner
        local boat = (ownerName ~= "" and Utility.GetBoatByOwner(ownerName)) or Utility.GetBoat()
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myPos = myRoot and myRoot.Position or Vector3.zero

        if boat and boat.Parent then
            local vSeat = boat:FindFirstChildOfClass("VehicleSeat") or boat:FindFirstChild("VehicleSeat", true)
            if vSeat then
                local esp = SeatESP_Folder:FindFirstChild("ESP_VehicleSeat")
                local pos = vSeat.Position
                local d = math.floor((pos - myPos).Magnitude)
                local occ = vSeat.Occupant and vSeat.Occupant.Parent and vSeat.Occupant.Parent.Name or "Trống"
                local textStr = string.format("🚗 Ghế Lái [%s]\n(%.1f, %.1f, %.1f)\n[%d studs]", occ, pos.X, pos.Y, pos.Z, d)
                if not esp then
                    esp = Utility.CreateESPLabel(vSeat, textStr, Color3.fromRGB(0, 255, 170))
                    esp.Name = "ESP_VehicleSeat"
                    esp.Parent = SeatESP_Folder
                else
                    local lbl = esp:FindFirstChildOfClass("TextLabel")
                    if lbl then lbl.Text = textStr end
                end
            end

            local cIndex = 0
            for _, child in ipairs(boat:GetChildren()) do
                if child.Name == "Cannon" then
                    cIndex = cIndex + 1
                    local seat = child:FindFirstChildOfClass("Seat") or child:FindFirstChild("Seat")
                    if seat then
                        local espName = "ESP_Cannon_" .. cIndex
                        local esp = SeatESP_Folder:FindFirstChild(espName)
                        local pos = seat.Position
                        local d = math.floor((pos - myPos).Magnitude)
                        local occ = seat.Occupant and seat.Occupant.Parent and seat.Occupant.Parent.Name or "Trống"
                        local textStr = string.format("💣 Cannon %d [%s]\n(%.1f, %.1f, %.1f)\n[%d studs]", cIndex, occ, pos.X, pos.Y, pos.Z, d)
                        local color = (occ == "Trống") and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 80, 80)
                        if not esp then
                            esp = Utility.CreateESPLabel(seat, textStr, color)
                            esp.Name = espName
                            esp.Parent = SeatESP_Folder
                        else
                            local lbl = esp:FindFirstChildOfClass("TextLabel")
                            if lbl then 
                                lbl.Text = textStr
                                lbl.TextColor3 = color
                            end
                        end
                    end
                end
            end
        else
            if SeatESP_Folder then SeatESP_Folder:ClearAllChildren() end
        end
    end)
end

--[[ Dừng vòng lặp Boat Seat Live ESP ]]
function Utility.StopBoatSeatESP()
    DisconnectConnection("boatSeatEspLoop")
    if SeatESP_Folder then SeatESP_Folder:ClearAllChildren() end
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

--[[ Dọn dẹp toàn bộ script khi unload ]]
function Utility.UnloadAllScript()
    S.AutoBuyBoatEnabled = false
    S.FindLeviathanEnabled = false
    S.MultipleFindLeviathanEnabled = false
    S.AutoShootLeviEnabled = false
    S.AutoAttackEnemyEnabled = false
    S.BoatNoClipEnabled = false
    S.PlayerNoClipEnabled = false
    S.WalkOnWaterEnabled = false
    S.EnableBoatSpeed = false
    S.TeleportPlayerEnabled = false
    S.IslandESPEnabled = false
    S.PlayerESPEnabled = false
    S.BoatSeatESPEnabled = false

    DisconnectConnection("autoBuyBoat")
    DisconnectConnection("findLev")
    DisconnectConnection("multiFindLev")
    DisconnectConnection("autoShootLev")
    DisconnectConnection("bspd")
    DisconnectConnection("teleportPlayerLoop")
    DisconnectConnection("islandEspLoop")
    DisconnectConnection("playerEspLoop")
    DisconnectConnection("boatSeatEspLoop")
    DisconnectConnection("renderLoop")
    DisconnectConnection("antiAfk")
    DisconnectConnection("boatNoClipStepped")
    DisconnectConnection("playerNoClipStepped")

    if ActiveBoat then Utility.ForceStopBoat(ActiveBoat) end
    Utility.StopPhysicsFly()

    if IslandESP_Folder then IslandESP_Folder:Destroy() end
    if PlayerESP_Folder then PlayerESP_Folder:Destroy() end
    if SeatESP_Folder then SeatESP_Folder:Destroy() end

    Window:Destroy()
    _G.UnloadScript = nil
end
_G.UnloadScript = Utility.UnloadAllScript

-- ═══════════════════════════════════════════════════════════
--  TAB 1 : LEVIATHAN
-- ═══════════════════════════════════════════════════════════
local LevTab = Window:AddTab({ Name = "Leviathan", Icon = "" })

LevTab:AddSection("Auto Shoot Leviathan (Beast Hunter)")

LevTab:AddToggle({
    Name    = "Auto Shoot Leviathan",
    Desc    = "Lái thuyền Beast Hunter bay đến (X=12, Y=80, Z=0) so với FrozenHeart và neo cố định",
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

LevTab:AddSection("Leviathan Finder")

FindLeviathanToggle = LevTab:AddToggle({
    Name    = "Find Leviathan",
    Desc    = "Bay đến ghế lái thuyền đã chọn (hoặc mua 1 lần) & bay tìm Leviathan",
    Default = false,
    Callback = function(val)
        S.FindLeviathanEnabled = val
        S.BoatNoClipEnabled    = val
        if val then
            Utility.StartFindLeviathan()
        else
            Utility.StopFindLeviathan()
        end
    end,
})

LevTab:AddSection("Multiple Find Leviathan (Cannon Passenger)")

local BoatOwnerDD = LevTab:AddDropdown({
    Name    = "Select Boat Owner",
    Desc    = "Chọn chủ thuyền để bay đến ngồi ké Cannon",
    Options = Utility.GetPlayerList(),
    Callback = function(opt)
        S.SelectedBoatOwner = opt
    end,
})

LevTab:AddButton({
    Name = "Refresh Boat Owner List",
    Desc = "Cập nhật lại danh sách người chơi trong server",
    Callback = function()
        BoatOwnerDD:Refresh(Utility.GetPlayerList())
        UILib.Notify("Leviathan", "Đã cập nhật danh sách chủ thuyền!", 2)
    end,
})

LevTab:AddButton({
    Name = "Sit Cannon (Selected Owner)",
    Desc = "Bay nhân vật đến và ngồi vào ghế Cannon trên thuyền của Owner đã chọn",
    Callback = function()
        Utility.FlyToOwnerBoatCannon()
    end,
})

LevTab:AddSection("Auto Buy Boat")

LevTab:AddDropdown({
    Name    = "Select Boat",
    Desc    = "Chọn loại thuyền cần mua",
    Options = {
        "Beast Hunter",
        "Grand Brigade",
        "Guardian",
        "Miracle",
        "PirateBrigade",
        "Swan Ship",
        "Flower Ship",
        "Enel's Ship",
        "Speed Boat",
        "Galleon",
        "Sloop",
        "Dinghy"
    },
    Callback = function(opt)
        S.SelectedBoat = opt
    end,
})

LevTab:AddButton({
    Name = "Buy Boat",
    Desc = "Mua thuyền đã chọn (Mặc định: Beast Hunter)",
    Callback = function()
        local boatName = S.SelectedBoat or "Beast Hunter"
        local ok, err = Utility.BuyBoat(boatName)
        if ok then
            UILib.Notify("Boat", "Đã gửi yêu cầu mua thuyền " .. boatName .. "!", 3)
        else
            UILib.Notify("Lỗi", "Không thể mua thuyền: " .. tostring(err), 3)
        end
    end,
})

LevTab:AddToggle({
    Name    = "Auto Buy Boat",
    Desc    = "Tự động mua thuyền nếu hiện tại chưa có thuyền",
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
    Desc    = "Tốc độ bay thuyền khi tìm Leviathan",
    Min     = 100, Max = 350, Default = 220, Suffix  = " s/s",
    Callback = function(v) S.BoatFlySpeed = v end,
})

LevTab:AddSlider({
    Name    = "Boat Fly Height",
    Desc    = "Độ cao khi bay của thuyền khi tìm Leviathan",
    Min     = 20, Max = 300, Default = 195, Suffix  = " Y",
    Callback = function(v) S.BoatFlyHeight = v end,
})

LevTab:AddToggle({
    Name    = "Enable Boat Speed",
    Desc    = "Thay đổi tốc độ lướt mặt nước của thuyền",
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
    Name    = "Boat Custom Speed",
    Desc    = "Tốc độ di chuyển mặt nước của thuyền",
    Min     = 40, Max = 500, Default = 250, Suffix  = " sp",
    Callback = function(v) S.CustomBoatSpeed = v end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 2 : TELEPORT
-- ═══════════════════════════════════════════════════════════
local TelTab = Window:AddTab({ Name = "Teleport", Icon = "" })

TelTab:AddSection("Teleport Settings")

TelTab:AddSlider({
    Name    = "Teleport Fly Speed",
    Desc    = "Tốc độ bay của nhân vật",
    Min     = 50, Max = 350, Default = 180, Suffix = " sp",
    Callback = function(v)
        S.TeleportFlySpeed = v
    end,
})

TelTab:AddSection("Teleport to Island")

local IslandDD = TelTab:AddDropdown({
    Name    = "Select Island",
    Desc    = "Chọn đảo muốn bay tới",
    Options = Utility.GetIslandList(),
    Callback = function(opt)
        S.SelectedIsland = opt
    end,
})

TelTab:AddButton({
    Name = "Fly to Selected Island",
    Desc = "Bay nhân vật mượt mà tới đảo bằng Physics Fly",
    Callback = function()
        if not S.SelectedIsland then
            UILib.Notify("Lỗi", "Chưa chọn đảo!", 3); return
        end

        local islObj = Utility.GetIslandObject(S.SelectedIsland)
        if islObj then
            local targetCF = islObj:GetPivot()
            UILib.Notify("Teleport", "Đang bay đến " .. S.SelectedIsland .. "...", 4)
            Utility.PhysicsFlyTo(targetCF + Vector3.new(0, 100, 0), S.TeleportFlySpeed, function()
                UILib.Notify("Teleport", "Đã đến đảo " .. S.SelectedIsland .. "!", 4)
            end)
        else
            UILib.Notify("Lỗi", "Không tìm thấy vị trí đảo!", 3)
        end
    end,
})

TelTab:AddSection("Teleport to Player")

local PlayerDD = TelTab:AddDropdown({
    Name    = "Select Player",
    Desc    = "Chọn người chơi để theo dõi bay",
    Options = Utility.GetPlayerList(),
    Callback = function(opt)
        S.SelectedPlayer = Players:FindFirstChild(opt)
    end,
})

TelTab:AddButton({
    Name = "Refresh Player List",
    Desc = "Cập nhật lại danh sách người chơi",
    Callback = function()
        PlayerDD:Refresh(Utility.GetPlayerList())
        UILib.Notify("Teleport", "Đã cập nhật danh sách người chơi!", 2)
    end,
})

TelTab:AddToggle({
    Name    = "Fly Follow Player",
    Desc    = "Tự động bay bám theo người chơi đã chọn bằng Physics Fly",
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
--  TAB 3 : ESP
-- ═══════════════════════════════════════════════════════════
local EspTab = Window:AddTab({ Name = "ESP", Icon = "" })

EspTab:AddSection("Visual ESP")

EspTab:AddToggle({
    Name    = "Island ESP",
    Desc    = "Hiển thị Tên Đảo và Khoảng cách trên UI người dùng",
    Default = false,
    Callback = function(val)
        S.IslandESPEnabled = val
        if val then
            Utility.StartIslandESP()
        else
            Utility.StopIslandESP()
        end
    end,
})

EspTab:AddToggle({
    Name    = "Player ESP",
    Desc    = "Hiển thị Tên Người Chơi từ xa qua HumanoidRootPart",
    Default = false,
    Callback = function(val)
        S.PlayerESPEnabled = val
        if val then
            Utility.StartPlayerESP()
        else
            Utility.StopPlayerESP()
        end
    end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 4 : MISC
-- ═══════════════════════════════════════════════════════════
local MiscTab = Window:AddTab({ Name = "Misc", Icon = "" })

MiscTab:AddSection("Fix & Unstuck Controls")

MiscTab:AddButton({
    Name = "Fix Camera & Unstuck Character",
    Desc = "Gỡ kẹt góc nhìn Camera và trả lại quyền điều khiển nhân vật",
    Callback = function()
        Utility.ResetCameraAndCharacter()
    end,
})

MiscTab:AddSection("Movement")

MiscTab:AddSlider({
    Name = "Walk Speed", Desc = "Tốc độ di chuyển nhân vật",
    Min = 16, Max = 300, Default = 100, Suffix = " sp",
    Callback = function(v) S.CustomWalkSpeed = v end,
})

MiscTab:AddSlider({
    Name = "Jump Power", Desc = "Lực nhảy",
    Min = 50, Max = 500, Default = 50, Suffix = " jp",
    Callback = function(v) S.CustomJumpPower = v end,
})

MiscTab:AddSection("NoClip")

MiscTab:AddToggle({
    Name = "Player Noclip", Desc = "Cho phép nhân vật xuyên qua vật thể", Default = false,
    Callback = function(val) 
        S.PlayerNoClipEnabled = val
        if val then
            Utility.UpdateCharacterCache()
        else
            for _, part in ipairs(CharacterParts) do
                if part and part.Parent then part.CanCollide = true end
            end
        end
    end,
})

MiscTab:AddSection("Water & AFK")

MiscTab:AddToggle({
    Name = "Walk on Water", Desc = "Tạo mặt phẳng ảo đứng trên nước ở Y = 0", Default = true,
    Callback = function(val) S.WalkOnWaterEnabled = val end,
})

MiscTab:AddToggle({
    Name = "Anti-AFK", Desc = "Ngăn bị kick khi AFK", Default = true,
    Callback = function(val) S.AntiAFKEnabled = val end,
})

MiscTab:AddSection("Graphics")

MiscTab:AddButton({
    Name = "Boost FPS / Smooth Graphics",
    Desc = "Xoá hiệu ứng, tối ưu render",
    Callback = function() Utility.OptimizeGraphics() end,
})


-- ═══════════════════════════════════════════════════════════
--  TAB 5 : WEBHOOK CONFIG
-- ═══════════════════════════════════════════════════════════
local WhTab = Window:AddTab({ Name = "Webhook", Icon = "" })

WhTab:AddSection("Discord Webhook")

WhTab:AddToggle({
    Name = "Webhook Leviathan Spawn",
    Desc = "Gửi thông báo Discord khi xuất hiện Leviathan",
    Default = true,
    Callback = function(val) S.WebhookEnabled = val end,
})

WhTab:AddInput({
    Name = "Discord Webhook URL",
    Desc = "Dán link webhook vào đây",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(text)
        if string.find(text, "http") then
            S.WebhookURL = text
            UILib.Notify("Webhook", "Đã nhận Webhook URL thành công!", 3)
        end
    end,
})

WhTab:AddSection("Manual Test")

WhTab:AddButton({
    Name = "Test Webhook",
    Desc = "Gửi thử webhook để kiểm tra",
    Callback = function()
        if S.WebhookURL == "" then
            UILib.Notify("Lỗi", "Chưa nhập Webhook URL!", 3); return
        end
        Utility.SendWebhook(S.WebhookURL, LocalPlayer)
        UILib.Notify("Webhook", "Đã gửi test webhook!", 3)
    end,
})


-- ═══════════════════════════════════════════════════════════
--  RUNTIME LOOPS & LISTENERS
-- ═══════════════════════════════════════════════════════════

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    Utility.UpdateCharacterCache()
end)
if LocalPlayer.Character then Utility.UpdateCharacterCache() end

local WaterPart = Instance.new("Part")
WaterPart.Name = "WalkOnWaterPlatform"
WaterPart.Size = Vector3.new(3, 1, 3)
WaterPart.Transparency = 1
WaterPart.Anchored = true
WaterPart.CanCollide = true
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
                WaterPart.Position = Vector3.new(root.Position.X, 0, root.Position.Z)
                WaterPart.CanCollide = true
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
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

_conns["boatNoClipStepped"] = RunService.Stepped:Connect(function()
    if S.BoatNoClipEnabled and ActiveBoat and ActiveBoat.Parent then
        for _, part in ipairs(BoatParts) do
            if part and part.Parent then part.CanCollide = false end
        end
    end
end)

_conns["playerNoClipStepped"] = RunService.Stepped:Connect(function()
    if S.PlayerNoClipEnabled and LocalPlayer.Character then
        for _, part in ipairs(CharacterParts) do
            if part and part.Parent then part.CanCollide = false end
        end
    end
end)
