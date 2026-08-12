-- ============================================================
--  Blox_Fruit_Script.lua  (Single-File Executor · Luau)
--  Author  : Hilichurl  |  Version : 4.1.0 (Optimized)
-- ============================================================

-- ╔══════════════════════════════════════════════════════════╗
-- ║         [GLOBAL CLEANUP] TỰ ĐỘNG DỌN DẸP SCRIPT CŨ       ║
-- ╚══════════════════════════════════════════════════════════╝
if _G.UnloadScript then
    pcall(function() _G.UnloadScript() end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║          [SECTION 1] CUSTOM UI LIBRARY ENGINE            ║
-- ╚══════════════════════════════════════════════════════════╝

-- ── Services ────────────────────────────────────────────────
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local HttpService        = game:GetService("HttpService")
local VirtualUser        = game:GetService("VirtualUser")
local Lighting           = game:GetService("Lighting")
local CoreGui            = game:GetService("CoreGui")
local LocalPlayer        = Players.LocalPlayer

-- ── UI Scale ────────────────────────────────────────────────
local UI_W  = 420
local UI_H  = 300
local SB_W  = 98   -- sidebar width
local TH    = 35    -- title bar height

-- ── Theme ────────────────────────────────────────────────────
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

-- ── ProtectGui ───────────────────────────────────────────────
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

-- ── Helper Tải & Hiển Thị Ảnh Cục Bộ ──────────────────────────
local function GetOnlineImage(url, fileName)
    if not url or url == "" then return "" end
    local path = fileName or "Hilichurl_icon.png"
    
    if isfile("hilichurl_icon.webp") then pcall(function() delfile("hilichurl_icon.webp") end) end
    if isfile("hilichurl_icon.png")  then pcall(function() delfile("hilichurl_icon.png") end)  end

    if not isfile(path) then
        pcall(function()
            local content = game:HttpGet(url)
            if content and #content > 0 then
                writefile(path, content)
            end
        end)
    end

    if isfile(path) then
        if getcustomasset then
            return getcustomasset(path)
        elseif getsynasset then
            return getsynasset(path)
        end
    end
    return url
end

-- ── Low-level helpers ────────────────────────────────────────
local function MkFrame(p)
    local f = Instance.new("Frame")
    f.BackgroundColor3   = p.Color or THEME.BG
    f.BackgroundTransparency = p.Alpha or 0
    f.BorderSizePixel    = 0
    f.Size               = p.Size or UDim2.fromOffset(100,30)
    f.Position           = p.Pos  or UDim2.fromOffset(0,0)
    f.Name               = p.Name or "Frame"
    if p.Parent then f.Parent = p.Parent end
    if p.Radius ~= false then
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, p.Radius or 7)
        c.Parent = f
    end
    return f
end

local function MkLabel(p)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextColor3  = p.Color  or THEME.TEXT
    l.Text        = p.Text   or ""
    l.Font        = p.Font   or Enum.Font.GothamSemibold
    l.TextSize    = p.Size   or 13
    l.TextXAlignment = p.XA or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Size        = p.FS    or UDim2.new(1,0,1,0)
    l.Position    = p.Pos   or UDim2.fromOffset(0,0)
    l.Name        = p.Name  or "Lbl"
    l.RichText    = true
    if p.Parent then l.Parent = p.Parent end
    return l
end

-- ── Dragging ─────────────────────────────────────────────────
local function EnableDrag(handle, root)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = root.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or
                     i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            root.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end

-- ── Notify Toast ─────────────────────────────────────────────
local _nh = nil
local function EnsureNH()
    if _nh and _nh.Parent then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "LevNotify"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    ProtectGui(sg)
    local h = Instance.new("Frame")
    h.Name = "H"; h.BackgroundTransparency = 1
    h.Size = UDim2.new(0,224,1,0)
    h.Position = UDim2.new(1,-238,0,0)
    h.Parent = sg
    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding = UDim.new(0,6)
    ll.VerticalAlignment = Enum.VerticalAlignment.Bottom
    ll.Parent = h
    local pd = Instance.new("UIPadding")
    pd.PaddingBottom = UDim.new(0,14); pd.Parent = h
    _nh = h
end

local UILib = {}
function UILib.Notify(title, msg, dur)
    dur = dur or 3; EnsureNH()
    local card = MkFrame({Color=THEME.NOTIFY_BG, Size=UDim2.new(1,0,0,58), Name="NC", Parent=_nh, Radius=8, Alpha=0.08})
    card.ClipsDescendants = true
    local ac = Instance.new("Frame"); ac.BackgroundColor3=THEME.ACCENT; ac.BorderSizePixel=0
    ac.Size = UDim2.new(0,3,1,0); ac.Parent = card; Instance.new("UICorner").Parent = ac
    local inn = Instance.new("Frame"); inn.BackgroundTransparency=1
    inn.Size = UDim2.new(1,-10,1,0); inn.Position = UDim2.fromOffset(8,0); inn.Parent = card
    MkLabel({Text=title,   Size=12, Color=THEME.ACCENT,   Pos=UDim2.fromOffset(0,6),  FS=UDim2.new(1,0,0,16), Parent=inn})
    MkLabel({Text=msg,     Size=11, Color=THEME.TEXT,      Pos=UDim2.fromOffset(0,23), FS=UDim2.new(1,0,0,14), Font=Enum.Font.Gotham, Parent=inn})
    MkLabel({Text=os.date("%H:%M"), Size=9, Color=THEME.TEXT_SUB, Pos=UDim2.fromOffset(0,40), FS=UDim2.new(1,0,0,12), Font=Enum.Font.Gotham, Parent=inn})
    card.Position = UDim2.new(1,8,0,0)
    TweenService:Create(card,TI_MED,{Position=UDim2.new(0,0,0,0)}):Play()
    task.delay(dur, function()
        TweenService:Create(card,TI_MED,{Position=UDim2.new(1,8,0,0)}):Play()
        task.delay(0.28, function() card:Destroy() end)
    end)
end

-- ── Toggle Icon Button ───────────────────────────────────────
local _iconGui = nil
local _winRef  = nil
local _iconVisible = true

local function BuildIconToggle(iconUrl)
    if _iconGui then pcall(function() _iconGui:Destroy() end) end
    local sg = Instance.new("ScreenGui")
    sg.Name = "LevIcon"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    ProtectGui(sg)
    _iconGui = sg

    local btn = Instance.new("ImageButton")
    btn.Name = "IconBtn"
    btn.Image = GetOnlineImage(iconUrl, "Hilichurl_icon.png")
    btn.Size = UDim2.fromOffset(50,50)
    btn.Position = UDim2.new(0,16,0.5,-25)
    btn.BackgroundColor3 = THEME.ICON_BTN_BG
    btn.BackgroundTransparency = 0.3
    btn.AutoButtonColor = false
    btn.Parent = sg

    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,10); cr.Parent = btn
    local st = Instance.new("UIStroke"); st.Color = THEME.BORDER; st.Thickness = 1.5; st.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(st,TI_FAST,{Color=THEME.ACCENT}):Play()
        TweenService:Create(btn,TI_FAST,{BackgroundColor3=THEME.ICON_BTN_HOV, BackgroundTransparency=0}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(st,TI_FAST,{Color=THEME.BORDER}):Play()
        TweenService:Create(btn,TI_FAST,{BackgroundColor3=THEME.ICON_BTN_BG, BackgroundTransparency=0.3}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if _winRef then
            _iconVisible = not _iconVisible
            _winRef.Visible = _iconVisible
            TweenService:Create(btn,TI_FAST,{BackgroundTransparency=0}):Play()
            task.delay(0.12,function()
                TweenService:Create(btn,TI_FAST,{BackgroundTransparency=0.3}):Play()
            end)
        end
    end)

    EnableDrag(btn, btn)
end

-- ── CreateWindow ─────────────────────────────────────────────
function UILib.CreateWindow(cfg)
    cfg = cfg or {}
    local title = cfg.Title or "Hili Hub"
    local sub   = cfg.Subtitle or "made by Hilichurl"

    local sg = Instance.new("ScreenGui")
    sg.Name = "LevHub"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    ProtectGui(sg)

    local win = MkFrame({
        Color=THEME.BG, Alpha=0,
        Size=UDim2.fromOffset(UI_W, UI_H),
        Pos=UDim2.new(0.5,-UI_W/2, 0.5,-UI_H/2),
        Name="Window", Parent=sg, Radius=10,
    })
    win.ClipsDescendants = true
    _winRef = win

    local outStroke = Instance.new("UIStroke")
    outStroke.Color = THEME.BORDER; outStroke.Thickness = 1.2; outStroke.Parent = win

    local tb = MkFrame({Color=THEME.BG_OVERLAY, Size=UDim2.new(1,0,0,TH), Name="TitleBar", Parent=win, Radius=10})
    
    local tbMask = Instance.new("Frame")
    tbMask.Name = "TitleBarMask"; tbMask.BackgroundColor3 = THEME.BG_OVERLAY; tbMask.BorderSizePixel = 0
    tbMask.Size = UDim2.new(1, 0, 0, 10); tbMask.Position = UDim2.new(0, 0, 1, -10); tbMask.Parent = tb

    local strip = Instance.new("Frame")
    strip.Name = "AccentStrip"; strip.BackgroundColor3 = THEME.ACCENT; strip.BorderSizePixel = 0
    strip.Size = UDim2.new(0, 3, 1, -4); strip.Position = UDim2.fromOffset(2, 2); strip.Parent = tb
    
    local stripCorner = Instance.new("UICorner"); stripCorner.CornerRadius = UDim.new(0, 4); stripCorner.Parent = strip

    local titleContainer = Instance.new("Frame")
    titleContainer.Size = UDim2.new(1, -100, 1, 0); titleContainer.Position = UDim2.fromOffset(12, 0)
    titleContainer.BackgroundTransparency = 1; titleContainer.Parent = tb

    local titleListLayout = Instance.new("UIListLayout")
    titleListLayout.FillDirection = Enum.FillDirection.Horizontal; titleListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    titleListLayout.Padding = UDim.new(0, 8); titleListLayout.SortOrder = Enum.SortOrder.LayoutOrder; titleListLayout.Parent = titleContainer

    local tLbl = Instance.new("TextLabel")
    tLbl.BackgroundTransparency = 1; tLbl.TextColor3 = THEME.TEXT; tLbl.Text = title; tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 13; tLbl.AutomaticSize = Enum.AutomaticSize.X; tLbl.Size = UDim2.new(0, 0, 1, 0); tLbl.LayoutOrder = 1; tLbl.Parent = titleContainer

    local subLbl = Instance.new("TextLabel")
    subLbl.BackgroundTransparency = 1; subLbl.TextColor3 = THEME.TEXT_SUB; subLbl.Text = sub; subLbl.Font = Enum.Font.Gotham
    subLbl.TextSize = 10; subLbl.AutomaticSize = Enum.AutomaticSize.X; subLbl.Size = UDim2.new(0, 0, 1, 0); subLbl.LayoutOrder = 2; subLbl.Parent = titleContainer

    local function MkWinBtn(icon, xOff, bgColor)
        local b = Instance.new("TextButton")
        b.Text=icon; b.Font=Enum.Font.GothamBold; b.TextSize=11; b.TextColor3=THEME.TEXT_SUB; b.BackgroundColor3=bgColor
        b.BackgroundTransparency=1; b.AutoButtonColor=false; b.Size=UDim2.fromOffset(24,24)
        b.Position=UDim2.new(1, xOff, 0.5, -12); b.Parent=tb
        Instance.new("UICorner").Parent=b
        b.MouseEnter:Connect(function() TweenService:Create(b,TI_FAST,{BackgroundTransparency=0, TextColor3=Color3.new(1,1,1)}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b,TI_FAST,{BackgroundTransparency=1, TextColor3=THEME.TEXT_SUB}):Play() end)
        return b
    end

    local closeBtn = MkWinBtn("X", -30, Color3.fromRGB(180,40,40))
    closeBtn.MouseButton1Click:Connect(function()
        if _G.UnloadScript then _G.UnloadScript() end
    end)

    local minBtn = MkWinBtn("─", -58, Color3.fromRGB(60,60,60))
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(win,TI_MED,{
            Size = minimized and UDim2.fromOffset(UI_W,TH) or UDim2.fromOffset(UI_W,UI_H)
        }):Play()
    end)

    local body = MkFrame({Color=THEME.BG, Size=UDim2.new(1,0,1,-TH), Pos=UDim2.fromOffset(0,TH), Name="Body", Parent=win, Radius=10})
    
    local bodyMask = Instance.new("Frame")
    bodyMask.Name = "BodyMask"; bodyMask.BackgroundColor3 = THEME.BG; bodyMask.BorderSizePixel = 0
    bodyMask.Size = UDim2.new(1, 0, 0, 10); bodyMask.Position = UDim2.new(0, 0, 0, 0); bodyMask.Parent = body

    local sidebar = MkFrame({Color=THEME.BG_OVERLAY, Size=UDim2.new(0,SB_W,1,0), Name="Sidebar", Parent=body, Radius=10})
    local sbll = Instance.new("UIListLayout"); sbll.SortOrder=Enum.SortOrder.LayoutOrder; sbll.Padding=UDim.new(0,3); sbll.Parent=sidebar
    local sbp = Instance.new("UIPadding"); sbp.PaddingTop=UDim.new(0,8); sbp.PaddingLeft=UDim.new(0,6); sbp.PaddingRight=UDim.new(0,6); sbp.Parent=sidebar

    local cpane = MkFrame({Color=THEME.BG, Size=UDim2.new(1,-SB_W,1,0), Pos=UDim2.fromOffset(SB_W,0), Name="Content", Parent=body, Radius=10})
    cpane.ClipsDescendants = true

    EnableDrag(tb, win)

    local W = {}
    local tabs = {}; local activePage=nil; local activeTabBtn=nil

    function W:Destroy() 
        sg:Destroy() 
        if _iconGui then pcall(function() _iconGui:Destroy() end) end
        if _nh then pcall(function() _nh.Parent:Destroy() end) end
    end

    function W:AddTab(cfg2)
        cfg2 = cfg2 or {}
        local tname = cfg2.Name or "Tab"
        local ticon = cfg2.Icon or ""

        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_"..tname; tabBtn.Text = (ticon~="" and ticon.."  " or "")..tname
        tabBtn.Font = Enum.Font.GothamSemibold; tabBtn.TextSize = 11; tabBtn.TextColor3 = THEME.TEXT_SUB
        tabBtn.BackgroundColor3 = THEME.TAB_IDLE; tabBtn.AutoButtonColor = false; tabBtn.Size = UDim2.new(1,0,0,28)
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left; tabBtn.Parent = sidebar
        local tc = Instance.new("UICorner"); tc.CornerRadius=UDim.new(0,6); tc.Parent=tabBtn
        local tp = Instance.new("UIPadding"); tp.PaddingLeft=UDim.new(0,8); tp.Parent=tabBtn

        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_"..tname; page.BackgroundTransparency = 1; page.Size = UDim2.new(1,0,1,0)
        page.CanvasSize = UDim2.new(0,0,0,0); page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.ScrollBarThickness = 2; page.ScrollBarImageColor3 = THEME.ACCENT
        page.Visible = false; page.BorderSizePixel = 0; page.ClipsDescendants = true; page.Parent = cpane
        local pl = Instance.new("UIListLayout"); pl.SortOrder=Enum.SortOrder.LayoutOrder; pl.Padding=UDim.new(0,6); pl.Parent=page
        local pp = Instance.new("UIPadding"); pp.PaddingTop=UDim.new(0,8); pp.PaddingLeft=UDim.new(0,10); pp.PaddingRight=UDim.new(0,10); pp.PaddingBottom=UDim.new(0,8); pp.Parent=page

        local function activate()
            if activePage   then activePage.Visible   = false end
            if activeTabBtn then
                TweenService:Create(activeTabBtn,TI_FAST,{BackgroundColor3=THEME.TAB_IDLE, TextColor3=THEME.TEXT_SUB}):Play()
            end
            page.Visible=true; activePage=page; activeTabBtn=tabBtn
            TweenService:Create(tabBtn,TI_FAST,{BackgroundColor3=THEME.ACCENT, TextColor3=THEME.TAB_TEXT_ACT}):Play()
        end
        tabBtn.MouseButton1Click:Connect(activate)
        tabBtn.MouseEnter:Connect(function()
            if activeTabBtn~=tabBtn then TweenService:Create(tabBtn,TI_FAST,{BackgroundColor3=Color3.fromRGB(32,32,40)}):Play() end
        end)
        tabBtn.MouseLeave:Connect(function()
            if activeTabBtn~=tabBtn then TweenService:Create(tabBtn,TI_FAST,{BackgroundColor3=THEME.TAB_IDLE}):Play() end
        end)
        if #tabs==0 then activate() end
        table.insert(tabs,{btn=tabBtn,page=page})

        local Tab = {}

        function Tab:AddSection(name)
            local s = MkFrame({Color=Color3.fromRGB(0,0,0), Size=UDim2.new(1,0,0,20), Name="Sec_"..name, Parent=page, Alpha=1, Radius=0})
            MkLabel({Text="• "..name:upper(), Size=9, Color=THEME.ACCENT, Font=Enum.Font.GothamBold, FS=UDim2.new(1,0,1,0), Parent=s})
            local d=Instance.new("Frame"); d.BackgroundColor3=THEME.BORDER; d.BorderSizePixel=0; d.Size=UDim2.new(1,0,0,1); d.Position=UDim2.new(0,0,1,0); d.Parent=s
            return s
        end

        function Tab:AddButton(bc)
            bc=bc or {}
            local lbl=bc.Name or "Button"; local desc=bc.Desc or ""; local cb=bc.Callback or function()end
            local rH = desc~="" and 42 or 28
            local row = MkFrame({Color=THEME.BTN_IDLE, Size=UDim2.new(1,0,0,rH), Name="Btn_"..lbl, Parent=page, Radius=6})
            local ip=Instance.new("UIPadding"); ip.PaddingLeft=UDim.new(0,10); ip.PaddingRight=UDim.new(0,10); ip.Parent=row
            MkLabel({Text=lbl, Size=11, Color=THEME.TEXT, FS=UDim2.new(1,0,0,16), Pos=UDim2.fromOffset(0,6), Parent=row})
            if desc~="" then MkLabel({Text=desc, Size=9, Color=THEME.TEXT_SUB, Font=Enum.Font.Gotham, FS=UDim2.new(1,0,0,13), Pos=UDim2.fromOffset(0,22), Parent=row}) end
            local cl=Instance.new("TextButton"); cl.Text=""; cl.BackgroundTransparency=1; cl.Size=UDim2.new(1,0,1,0); cl.AutoButtonColor=false; cl.Parent=row
            cl.MouseEnter:Connect(function()
                TweenService:Create(row,TI_FAST,{BackgroundColor3=THEME.BTN_HOVER}):Play()
                for _,v in ipairs(row:GetChildren()) do if v:IsA("TextLabel") then TweenService:Create(v,TI_FAST,{TextColor3=THEME.BTN_TEXT_HOV}):Play() end end
            end)
            cl.MouseLeave:Connect(function()
                TweenService:Create(row,TI_FAST,{BackgroundColor3=THEME.BTN_IDLE}):Play()
                for _,v in ipairs(row:GetChildren()) do if v:IsA("TextLabel") then TweenService:Create(v,TI_FAST,{TextColor3=v.TextSize>=11 and THEME.TEXT or THEME.TEXT_SUB}):Play() end end
            end)
            cl.MouseButton1Click:Connect(function()
                pcall(cb)
                TweenService:Create(row,TI_FAST,{BackgroundColor3=THEME.ACCENT_DIM}):Play()
                task.delay(0.1,function() TweenService:Create(row,TI_FAST,{BackgroundColor3=THEME.BTN_IDLE}):Play()
                    for _,v in ipairs(row:GetChildren()) do if v:IsA("TextLabel") then TweenService:Create(v,TI_FAST,{TextColor3=v.TextSize>=11 and THEME.TEXT or THEME.TEXT_SUB}):Play() end end end)
            end)
            return row
        end

        function Tab:AddToggle(tc2)
            tc2=tc2 or {}
            local lbl=tc2.Name or "Toggle"; local desc=tc2.Desc or ""; local def=tc2.Default or false; local cb=tc2.Callback or function()end
            local rH=desc~="" and 42 or 28; local st=def
            local row=MkFrame({Color=THEME.BTN_IDLE, Size=UDim2.new(1,0,0,rH), Name="Tog_"..lbl, Parent=page, Radius=6})
            local ip=Instance.new("UIPadding"); ip.PaddingLeft=UDim.new(0,10); ip.PaddingRight=UDim.new(0,10); ip.Parent=row
            MkLabel({Text=lbl, Size=11, Color=THEME.TEXT, FS=UDim2.new(1,-46,0,16), Pos=UDim2.fromOffset(0,6), Parent=row})
            if desc~="" then MkLabel({Text=desc, Size=9, Color=THEME.TEXT_SUB, Font=Enum.Font.Gotham, FS=UDim2.new(1,-46,0,13), Pos=UDim2.fromOffset(0,22), Parent=row}) end

            local pill=MkFrame({Color=st and THEME.TOGGLE_ON or THEME.TOGGLE_OFF, Size=UDim2.fromOffset(34,18), Pos=UDim2.new(1,-34,0.5,-9), Name="Pill", Parent=row, Radius=9})
            local knob=MkFrame({Color=Color3.new(1,1,1), Size=UDim2.fromOffset(13,13), Pos=st and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2), Name="Knob", Parent=pill, Radius=6})

            local function upd()
                TweenService:Create(pill,TI_FAST,{BackgroundColor3=st and THEME.TOGGLE_ON or THEME.TOGGLE_OFF}):Play()
                TweenService:Create(knob,TI_FAST,{Position=st and UDim2.fromOffset(18,2) or UDim2.fromOffset(2,2)}):Play()
            end

            local cl=Instance.new("TextButton"); cl.Text=""; cl.BackgroundTransparency=1; cl.Size=UDim2.new(1,0,1,0); cl.AutoButtonColor=false; cl.Parent=row
            cl.MouseButton1Click:Connect(function() st=not st; upd(); pcall(cb,st) end)
            cl.MouseEnter:Connect(function() TweenService:Create(row,TI_FAST,{BackgroundColor3=Color3.fromRGB(28,28,34)}):Play() end)
            cl.MouseLeave:Connect(function() TweenService:Create(row,TI_FAST,{BackgroundColor3=THEME.BTN_IDLE}):Play() end)
            upd()

            local TO={}
            function TO:Set(v) st=v; upd(); pcall(cb,st) end
            function TO:Get() return st end
            return TO
        end

        -- [YÊU CẦU 3] SLIDER KẾT HỢP INPUT BOX HIỂN THỊ & NHẬP GIÁ TRỊ TRỰC TIẾP
        function Tab:AddSlider(sc)
            sc=sc or {}
            local lbl=sc.Name or "Slider"; local desc=sc.Desc or ""; local mn=sc.Min or 0; local mx=sc.Max or 100
            local def=sc.Default or mn; local sfx=sc.Suffix or ""; local cb=sc.Callback or function()end
            local rH=desc~="" and 58 or 44; local value=math.clamp(def,mn,mx)
            local row=MkFrame({Color=THEME.BTN_IDLE, Size=UDim2.new(1,0,0,rH), Name="Sl_"..lbl, Parent=page, Radius=6})
            local ip=Instance.new("UIPadding"); ip.PaddingLeft=UDim.new(0,10); ip.PaddingRight=UDim.new(0,10); ip.Parent=row
            
            MkLabel({Text=lbl, Size=11, Color=THEME.TEXT, FS=UDim2.new(1,-65,0,16), Pos=UDim2.fromOffset(0,6), Parent=row})
            if desc~="" then MkLabel({Text=desc, Size=9, Color=THEME.TEXT_SUB, Font=Enum.Font.Gotham, FS=UDim2.new(1,-65,0,12), Pos=UDim2.fromOffset(0,22), Parent=row}) end
            
            -- Ô Input Box kết hợp hiển thị giá trị
            local valBoxBG = MkFrame({Color=Color3.fromRGB(10,10,14), Size=UDim2.fromOffset(55, 18), Pos=UDim2.new(1,-55,0,5), Name="ValBoxBG", Parent=row, Radius=4})
            local valBoxSt = Instance.new("UIStroke"); valBoxSt.Color=THEME.BORDER; valBoxSt.Thickness=1; valBoxSt.Parent=valBoxBG
            
            local valBox = Instance.new("TextBox")
            valBox.Size = UDim2.new(1,0,1,0)
            valBox.BackgroundTransparency = 1
            valBox.Text = tostring(value) .. sfx
            valBox.TextColor3 = THEME.ACCENT
            valBox.Font = Enum.Font.GothamBold
            valBox.TextSize = 10
            valBox.TextXAlignment = Enum.TextXAlignment.Center
            valBox.ClearTextOnFocus = false
            valBox.Parent = valBoxBG

            local tY=desc~="" and 38 or 26
            local track=MkFrame({Color=THEME.SLIDER_TRACK, Size=UDim2.new(1,0,0,5), Pos=UDim2.fromOffset(0,tY), Name="Tr", Parent=row, Radius=2})
            local fp=(value-mn)/(mx-mn)
            local fill=MkFrame({Color=THEME.SLIDER_FILL, Size=UDim2.new(fp,0,1,0), Name="Fl", Parent=track, Radius=2})
            local thumb=MkFrame({Color=Color3.new(1,1,1), Size=UDim2.fromOffset(11,11), Pos=UDim2.new(fp,-5,0.5,-5), Name="Th", Parent=track, Radius=5})
            local ts=Instance.new("UIStroke"); ts.Color=THEME.ACCENT; ts.Thickness=1.2; ts.Parent=thumb
            local dSlider=false

            local function updateUI(val)
                value = math.clamp(val, mn, mx)
                local p = (value - mn) / (mx - mn)
                fill.Size = UDim2.new(p, 0, 1, 0)
                thumb.Position = UDim2.new(p, -5, 0.5, -5)
                valBox.Text = tostring(value) .. sfx
                pcall(cb, value)
            end

            local function updSl(ax)
                local rx=math.clamp(ax-track.AbsolutePosition.X,0,track.AbsoluteSize.X)
                local p=rx/track.AbsoluteSize.X
                local v=math.floor(mn+p*(mx-mn)+0.5)
                updateUI(v)
            end

            track.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dSlider=true; updSl(i.Position.X) end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dSlider and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then updSl(i.Position.X) end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dSlider=false end
            end)

            valBox.Focused:Connect(function()
                valBox.Text = tostring(value)
                TweenService:Create(valBoxSt, TI_FAST, {Color=THEME.ACCENT}):Play()
            end)

            valBox.FocusLost:Connect(function()
                TweenService:Create(valBoxSt, TI_FAST, {Color=THEME.BORDER}):Play()
                local num = tonumber(valBox.Text)
                if num then
                    updateUI(num)
                else
                    valBox.Text = tostring(value) .. sfx
                end
            end)

            local SO={}
            function SO:Set(v) updateUI(v) end
            function SO:Get() return value end
            return SO
        end

        function Tab:AddDropdown(dc)
            dc=dc or {}
            local lbl=dc.Name or "Dropdown"; local opts=dc.Options or {}; local cb=dc.Callback or function()end
            local desc=dc.Desc or ""; local rH=desc~="" and 42 or 28; local selectedText="None"
            local row=MkFrame({Color=THEME.BTN_IDLE, Size=UDim2.new(1,0,0,rH), Name="DD_"..lbl, Parent=page, Radius=6})
            local ip=Instance.new("UIPadding"); ip.PaddingLeft=UDim.new(0,10); ip.PaddingRight=UDim.new(0,10); ip.Parent=row
            MkLabel({Text=lbl, Size=11, Color=THEME.TEXT, FS=UDim2.new(1,-100,0,16), Pos=UDim2.fromOffset(0,6), Parent=row})
            if desc~="" then MkLabel({Text=desc, Size=9, Color=THEME.TEXT_SUB, Font=Enum.Font.Gotham, FS=UDim2.new(1,-100,0,13), Pos=UDim2.fromOffset(0,22), Parent=row}) end
            local selLbl=MkLabel({Text=selectedText.."", Size=10, Color=THEME.ACCENT, XA=Enum.TextXAlignment.Right, FS=UDim2.new(0,100,0,16), Pos=UDim2.new(1,-100,0,6), Name="SelLbl", Parent=row})

            local activeDropdown = nil

            local function BuildDropdown()
                if activeDropdown then activeDropdown:Destroy(); activeDropdown = nil; return end
                local n = #opts
                if n == 0 then return end

                local ddH = math.min(n, 5) * 26 + 6
                local dropdown = MkFrame({
                    Color = THEME.BG_OVERLAY,
                    Size = UDim2.fromOffset(row.AbsoluteSize.X, ddH),
                    Pos = UDim2.fromOffset(row.AbsolutePosition.X, row.AbsolutePosition.Y + row.AbsoluteSize.Y + 4),
                    Name = "GlobalDDList", Parent = sg, Radius = 6
                })
                dropdown.ZIndex = 500; activeDropdown = dropdown

                local outSt = Instance.new("UIStroke"); outSt.Color = THEME.ACCENT; outSt.Thickness = 1; outSt.Parent = dropdown

                local scrollDD = Instance.new("ScrollingFrame")
                scrollDD.Size = UDim2.new(1, 0, 1, 0); scrollDD.BackgroundTransparency = 1; scrollDD.BorderSizePixel = 0
                scrollDD.ScrollBarThickness = 3; scrollDD.ScrollBarImageColor3 = THEME.ACCENT
                scrollDD.CanvasSize = UDim2.new(0, 0, 0, n * 26); scrollDD.ZIndex = 501; scrollDD.Parent = dropdown

                local dll = Instance.new("UIListLayout"); dll.SortOrder = Enum.SortOrder.LayoutOrder; dll.Padding = UDim.new(0, 2); dll.Parent = scrollDD

                for _, opt in ipairs(opts) do
                    local ob = Instance.new("TextButton")
                    ob.Text = opt; ob.Font = Enum.Font.GothamMedium; ob.TextSize = 11; ob.TextColor3 = THEME.TEXT
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
            ic=ic or {}
            local lbl=ic.Name or "Input"; local desc=ic.Desc or ""; local ph=ic.Placeholder or "Type here..."; local cb=ic.Callback or function()end
            local rH=desc~="" and 58 or 44
            local row=MkFrame({Color=THEME.BTN_IDLE, Size=UDim2.new(1,0,0,rH), Name="Inp_"..lbl, Parent=page, Radius=6})
            local ip=Instance.new("UIPadding"); ip.PaddingLeft=UDim.new(0,10); ip.PaddingRight=UDim.new(0,10); ip.Parent=row
            MkLabel({Text=lbl, Size=11, Color=THEME.TEXT, FS=UDim2.new(1,0,0,16), Pos=UDim2.fromOffset(0,5), Parent=row})
            if desc~="" then MkLabel({Text=desc, Size=9, Color=THEME.TEXT_SUB, Font=Enum.Font.Gotham, FS=UDim2.new(1,0,0,12), Pos=UDim2.fromOffset(0,20), Parent=row}) end
            local bxY=desc~="" and 34 or 22
            local bxBG=MkFrame({Color=Color3.fromRGB(10,10,14), Size=UDim2.new(1,0,0,20), Pos=UDim2.fromOffset(0,bxY), Name="BxBG", Parent=row, Radius=5})
            local bxSt=Instance.new("UIStroke"); bxSt.Color=THEME.BORDER; bxSt.Thickness=1; bxSt.Parent=bxBG
            local tbx=Instance.new("TextBox"); tbx.Text=""; tbx.PlaceholderText=ph; tbx.PlaceholderColor3=THEME.TEXT_SUB
            tbx.TextColor3=THEME.TEXT; tbx.Font=Enum.Font.Gotham; tbx.TextSize=10
            tbx.BackgroundTransparency=1; tbx.Size=UDim2.new(1,-8,1,0); tbx.Position=UDim2.fromOffset(5,0)
            tbx.TextXAlignment=Enum.TextXAlignment.Left; tbx.ClearTextOnFocus=false; tbx.Parent=bxBG
            tbx.Focused:Connect(function() TweenService:Create(bxSt,TI_FAST,{Color=THEME.ACCENT}):Play() end)
            
            tbx.FocusLost:Connect(function() 
                TweenService:Create(bxSt,TI_FAST,{Color=THEME.BORDER}):Play()
                if tbx.Text ~= "" then pcall(cb, tbx.Text) end
            end)
            local IO={}
            function IO:Get() return tbx.Text end
            function IO:Set(t) tbx.Text=t end
            return IO
        end

        return Tab
    end

    return W
end


-- ╔══════════════════════════════════════════════════════════╗
-- ║        [SECTION 2] UTILITY & GAME HELPER FUNCTIONS       ║
-- ╚══════════════════════════════════════════════════════════╝

local Utility = {}
local _conns  = {}

-- Quản lý bộ nhớ Cache Parts dùng cho NoClip (Tối ưu hóa tài nguyên)
local CharacterParts = {}
local BoatParts = {}

local function killConn(key)
    if _conns[key] then pcall(function() _conns[key]:Disconnect() end); _conns[key]=nil end
end

-- Cập nhật danh sách Parts nhân vật
local function UpdateCharacterCache()
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

-- Cập nhật danh sách Parts của thuyền
local function UpdateBoatCache(boat)
    table.clear(BoatParts)
    if boat then
        for _, part in ipairs(boat:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsA("Seat") and not part:IsA("VehicleSeat") then
                table.insert(BoatParts, part)
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    UpdateCharacterCache()
end)
if LocalPlayer.Character then UpdateCharacterCache() end

function Utility.GetBoat()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        return hum.SeatPart.Parent
    end
    return nil
end

function Utility.ForceStopBoat(boat)
    if not boat then return end
    task.spawn(function()
        for i=1,10 do
            for _, part in ipairs(boat:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.AssemblyLinearVelocity  = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
            local seat = boat:FindFirstChildOfClass("VehicleSeat") or boat.PrimaryPart
            if seat then
                if seat:FindFirstChild("FlyLinearVelocity")   then seat.FlyLinearVelocity:Destroy()   end
                if seat:FindFirstChild("FlyAlignOrientation") then seat.FlyAlignOrientation:Destroy() end
                if seat:FindFirstChild("FlyAttachment")       then seat.FlyAttachment:Destroy()       end
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

-- [YÊU CẦU 1] TỐI ƯU HÀM ISFROZENWATCHER KHI KIỂM TRA FOLDER NPC
function Utility.IsFrozenWatcher()
    local npcFolder = workspace:FindFirstChild("NPC")
    if npcFolder and npcFolder:FindFirstChild("Frozen Watcher") then
        return true
    end
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if enemiesFolder and enemiesFolder:FindFirstChild("Frozen Watcher") then
        return true
    end
    return false
end

function Utility.OptimizeGraphics()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 1
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then v:Destroy() end
    end
    pcall(function() settings().Rendering.QualityLevel = 1 end)
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterWaveSize    = 0
        terrain.WaterWaveSpeed   = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency= 0
    end
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material     = Enum.Material.SmoothPlastic
            part.Reflectance  = 0
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part:Destroy()
        end
    end
    UILib.Notify("🎮 Graphics", "Đã tối ưu đồ họa!", 4)
end

-- Walk On Water Ảo
local WaterPart = Instance.new("Part")
WaterPart.Name            = "WalkOnWaterPart"
WaterPart.Size            = Vector3.new(3, 1, 3)
WaterPart.Transparency    = 0.85
WaterPart.Color           = Color3.fromRGB(0, 170, 255)
WaterPart.Material        = Enum.Material.SmoothPlastic
WaterPart.Anchored        = true
WaterPart.CanCollide      = false
WaterPart.CanTouch        = false
WaterPart.Parent          = workspace

function Utility.SendWebhook(url, player)
    local req = (syn and syn.request) or (http and http.request) or http_request
                or (fluxus and fluxus.request) or request
    if not req then return end
    local payload = {
        ["content"] = "@here **LEVIATHAN HAS SPAWNED!**",
        ["embeds"]  = {{
            ["title"]       = "❄️ Frozen Dimension Alert!",
            ["description"] = "Đã tìm thấy **Frozen Watcher / Leviathan**!",
            ["color"]       = 65535,
            ["fields"]      = {
                {["name"]="Player", ["value"]=player.Name, ["inline"]=true},
                {["name"]="Job ID", ["value"]=game.JobId,  ["inline"]=true},
            },
            ["timestamp"]   = DateTime.now():ToIsoDate()
        }}
    }
    pcall(function()
        req({Url=url, Method="POST",
             Headers={["Content-Type"]="application/json"},
             Body=HttpService:JSONEncode(payload)})
    end)
end


-- ╔══════════════════════════════════════════════════════════╗
-- ║          [SECTION 3] MAIN LOGIC & UI BINDINGS            ║
-- ╚══════════════════════════════════════════════════════════╝

local S = {
    BoatFlySpeed          = 220,
    BoatFlyHeight         = 195,
    CustomBoatSpeed       = 250,
    EnableBoatSpeed       = false,
    FindLeviathanEnabled  = false,
    BoatNoClipEnabled     = false,
    PlayerNoClipEnabled   = false,
    WalkOnWaterEnabled    = true,
    AntiAFKEnabled        = true,
    TeleportPlayerEnabled = false,
    SelectedPlayer        = nil,
    WebhookEnabled        = true,
    WebhookURL            = "",
    CustomWalkSpeed       = 16,
    CustomJumpPower       = 50,
}

local WebhookSent            = false
local FindLeviathanConnection = nil
local FindLeviathanToggle    = nil
local TeleportConnection     = nil
local BoatSpeedConnection    = nil

local ICON_URL = "https://raw.githubusercontent.com/TheHilichurl/Roblox_Script/refs/heads/main/Hilichurl_icon.png"

BuildIconToggle(ICON_URL)

local Window = UILib.CreateWindow({
    Title    = "Hili Hub",
    Subtitle = "made by Hilichurl",
})

-- HÀM TẮT DỌN DẸP SCRIPT TOÀN BỘ
_G.UnloadScript = function()
    S.FindLeviathanEnabled = false
    S.BoatNoClipEnabled = false
    S.PlayerNoClipEnabled = false
    S.WalkOnWaterEnabled = false
    S.EnableBoatSpeed = false
    S.TeleportPlayerEnabled = false

    killConn("findLev")
    killConn("bspd")
    killConn("telplr")
    killConn("steppedLoop")
    killConn("renderLoop")
    killConn("leviathanCheckLoop")

    local boat = Utility.GetBoat()
    if boat then Utility.ForceStopBoat(boat) end

    table.clear(CharacterParts)
    table.clear(BoatParts)

    if WaterPart then WaterPart:Destroy() end
    Window:Destroy()
    _G.UnloadScript = nil
end

-- TAB 1 : Main Features
local MainTab = Window:AddTab({ Name = "Main", Icon = "" })

MainTab:AddSection("Leviathan Finder")

-- [YÊU CẦU 4] QUẢN LÝ VÒNG LẶP CHECK LEVIATHAN CHỈ KHI KÍCH HOẠT TÍNH NĂNG
local function StartLeviathanWatcherLoop()
    killConn("leviathanCheckLoop")
    _conns["leviathanCheckLoop"] = task.spawn(function()
        while S.FindLeviathanEnabled do
            task.wait(0.1)
            if Utility.IsFrozenWatcher() then
                local boat = Utility.GetBoat()
                
                if FindLeviathanConnection then
                    FindLeviathanConnection:Disconnect()
                    FindLeviathanConnection = nil
                end
                
                if boat then Utility.ForceStopBoat(boat) end
                
                S.FindLeviathanEnabled = false
                S.BoatNoClipEnabled = false
                if FindLeviathanToggle then FindLeviathanToggle:Set(false) end

                if not WebhookSent and S.WebhookEnabled and S.WebhookURL ~= "" then
                    WebhookSent = true
                    Utility.SendWebhook(S.WebhookURL, LocalPlayer)
                end

                UILib.Notify("❄️ LEVIATHAN SPAWNED!", "Đã phát hiện Frozen Watcher! Đã phanh thuyền.", 6)
                break
            end
        end
    end)
end

FindLeviathanToggle = MainTab:AddToggle({
    Name    = "Find Leviathan",
    Desc    = "Bay thuyền tự động đi tìm Frozen Dimension",
    Default = false,
    Callback = function(val)
        S.FindLeviathanEnabled = val
        S.BoatNoClipEnabled    = val
        local boat = Utility.GetBoat()

        if val then
            if not LocalPlayer.Character or not boat then
                FindLeviathanToggle:Set(false)
                UILib.Notify("Lỗi","Bạn phải ngồi trên ghế lái thuyền!",3)
                return
            end

            UpdateBoatCache(boat)
            WebhookSent = false
            StartLeviathanWatcherLoop()

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
            ao.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(0,0,1)); ao.Parent = seat

            local startY = seat.Position.Y
            local flyUpDur = 10
            local t0 = os.clock()

            killConn("findLev")
            FindLeviathanConnection = RunService.Heartbeat:Connect(function()
                if not S.FindLeviathanEnabled or seat.Occupant==nil or Utility.IsFrozenWatcher() then
                    if FindLeviathanConnection then FindLeviathanConnection:Disconnect(); FindLeviathanConnection=nil end
                    Utility.ForceStopBoat(boat)
                    if S.FindLeviathanEnabled and FindLeviathanToggle then FindLeviathanToggle:Set(false) end
                    return
                end

                local pos = seat.Position
                local el  = os.clock() - t0
                if el <= flyUpDur then
                    local prog = el/flyUpDur
                    local ty   = startY + (800 - startY)*prog
                    lv.VectorVelocity = Vector3.new(0, (ty-pos.Y)*15, 0)
                elseif el <= (flyUpDur+4) then
                    lv.VectorVelocity = Vector3.new(-S.BoatFlySpeed, (800-pos.Y)*10, 0)
                else
                    lv.VectorVelocity = Vector3.new(-S.BoatFlySpeed, (S.BoatFlyHeight-pos.Y)*5, 0)
                end
            end)
            _conns["findLev"] = FindLeviathanConnection
        else
            killConn("findLev")
            killConn("leviathanCheckLoop")
            Utility.ForceStopBoat(boat)
            S.BoatNoClipEnabled = false
        end
    end,
})

MainTab:AddSection("Fly Settings")

MainTab:AddSlider({
    Name    = "Fly Speed",
    Desc    = "Tốc độ bay thuyền khi tìm Leviathan",
    Min     = 100, Max = 350, Default = 220,
    Suffix  = " s/s",
    Callback = function(v) S.BoatFlySpeed = v end,
})

MainTab:AddSlider({
    Name    = "Fly Height",
    Desc    = "Độ cao khi bay của thuyền khi tìm Leviathan",
    Min     = 20, Max = 300, Default = 195,
    Suffix  = " Y",
    Callback = function(v) S.BoatFlyHeight = v end,
})

MainTab:AddSection("Boat Speed")

MainTab:AddToggle({
    Name    = "Enable Boat Speed",
    Desc    = "Chỉnh tốc độ của thuyền",
    Default = false,
    Callback = function(val)
        S.EnableBoatSpeed = val
        if val then
            killConn("bspd")
            BoatSpeedConnection = RunService.Heartbeat:Connect(function()
                if not S.EnableBoatSpeed then killConn("bspd"); return end
                local bt = Utility.GetBoat()
                if bt then
                    local seat = bt:FindFirstChildOfClass("VehicleSeat")
                    if seat then
                        seat.MaxSpeed = S.CustomBoatSpeed
                        local mv = seat.CFrame.LookVector * (seat.ThrottleFloat * S.CustomBoatSpeed)
                        seat.AssemblyLinearVelocity = Vector3.new(mv.X, seat.AssemblyLinearVelocity.Y, mv.Z)
                    end
                end
            end)
            _conns["bspd"] = BoatSpeedConnection
        else
            killConn("bspd")
        end
    end,
})

MainTab:AddSlider({
    Name    = "Boat Speed",
    Desc    = "Tốc độ tuỳ chỉnh của thuyền",
    Min     = 100, Max = 500, Default = 250,
    Suffix  = " sp",
    Callback = function(v) S.CustomBoatSpeed = v end,
})

-- TAB 2 : Teleport
local TelTab = Window:AddTab({ Name = "Teleport", Icon = "" })

TelTab:AddSection("Teleport to Player")

local function GetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    return list
end

local PlayerDD = TelTab:AddDropdown({
    Name    = "Select Player",
    Desc    = "Chọn người chơi để teleport đến",
    Options = GetPlayerList(),
    Callback = function(opt)
        S.SelectedPlayer = Players:FindFirstChild(opt)
    end,
})

TelTab:AddButton({
    Name = "Refresh Player List",
    Desc = "Cập nhật lại danh sách người chơi trong server",
    Callback = function()
        PlayerDD:Refresh(GetPlayerList())
        UILib.Notify("Teleport", "Đã cập nhật danh sách người chơi!", 2)
    end,
})

TelTab:AddToggle({
    Name    = "Teleport to Player",
    Desc    = "Liên tục di chuyển đến vị trí người chơi đã chọn",
    Default = false,
    Callback = function(val)
        S.TeleportPlayerEnabled = val
        if val then
            if not S.SelectedPlayer or not S.SelectedPlayer.Character then
                UILib.Notify("Lỗi","Hãy chọn người chơi hợp lệ!",3)
                return
            end
            killConn("telplr")
            TeleportConnection = RunService.Heartbeat:Connect(function()
                if not S.TeleportPlayerEnabled or not S.SelectedPlayer or not S.SelectedPlayer.Character then
                    killConn("telplr"); return
                end
                local myR  = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local tgtR = S.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myR and tgtR then
                    myR.CFrame = myR.CFrame:Lerp(tgtR.CFrame * CFrame.new(0,2,3), 0.2)
                end
            end)
            _conns["telplr"] = TeleportConnection
        else
            killConn("telplr")
        end
    end,
})

-- TAB 3 : Misc & Optimize
local MiscTab = Window:AddTab({ Name = "Misc", Icon = "" })

MiscTab:AddSection("Movement")

MiscTab:AddSlider({
    Name="Walk Speed", Desc="Tốc độ di chuyển",
    Min=16, Max=250, Default=16, Suffix=" sp",
    Callback=function(v) S.CustomWalkSpeed = v end,
})

MiscTab:AddSlider({
    Name="Jump Power", Desc="Lực nhảy",
    Min=50, Max=500, Default=50, Suffix=" jp",
    Callback=function(v) S.CustomJumpPower = v end,
})

MiscTab:AddSection("NoClip")

MiscTab:AddToggle({
    Name="Player Noclip", Desc="Cho phép nhân vật xuyên qua vật thể", Default=false,
    Callback=function(val) 
        S.PlayerNoClipEnabled = val
        if val then
            UpdateCharacterCache()
        else
            for _, part in ipairs(CharacterParts) do
                if part and part.Parent then part.CanCollide = true end
            end
        end
    end,
})

MiscTab:AddSection("Water & AFK")

MiscTab:AddToggle({
    Name="Walk on Water", Desc="Tạo mặt phẳng ảo đứng trên nước", Default=true,
    Callback=function(val) S.WalkOnWaterEnabled=val end,
})

MiscTab:AddToggle({
    Name="Anti-AFK", Desc="Ngăn bị kick khi AFK", Default=true,
    Callback=function(val) S.AntiAFKEnabled=val end,
})

MiscTab:AddSection("Graphics")

MiscTab:AddButton({
    Name="Boost FPS / Smooth Graphics",
    Desc="Xoá hiệu ứng, tối ưu render",
    Callback=function() Utility.OptimizeGraphics() end,
})

-- TAB 4 : Webhook Config
local WhTab = Window:AddTab({ Name = "Webhook", Icon = "" })

WhTab:AddSection("Discord Webhook")

WhTab:AddToggle({
    Name="Webhook Leviathan Spawn",
    Desc="Gửi thông báo Discord khi xuất hiện Leviathan",
    Default=true,
    Callback=function(val) S.WebhookEnabled=val end,
})

WhTab:AddInput({
    Name="Discord Webhook URL",
    Desc="Dán link webhook vào đây",
    Placeholder="https://discord.com/api/webhooks/...",
    Callback=function(text)
        if string.find(text, "http") then
            S.WebhookURL = text
            UILib.Notify("Webhook", "Đã nhận Webhook URL thành công!", 3)
        end
    end,
})

WhTab:AddSection("Manual Test")

WhTab:AddButton({
    Name="Test Webhook",
    Desc="Gửi thử webhook để kiểm tra",
    Callback=function()
        if S.WebhookURL=="" then
            UILib.Notify("Lỗi","Chưa nhập Webhook URL!",3); return
        end
        Utility.SendWebhook(S.WebhookURL, LocalPlayer)
        UILib.Notify("Webhook","Đã gửi test webhook!",3)
    end,
})

-- ═══════════════════════════════════════════════════════════
--  RUNTIME LOOPS
-- ═══════════════════════════════════════════════════════════

_conns["renderLoop"] = RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        
        if hum then
            if S.CustomWalkSpeed ~= 16 then hum.WalkSpeed = S.CustomWalkSpeed end
            if S.CustomJumpPower ~= 50 then hum.JumpPower = S.CustomJumpPower end
        end

        if root and hum then
            if hum.SeatPart then
                WaterPart.CanCollide = false
            elseif S.WalkOnWaterEnabled then
                WaterPart.CFrame = CFrame.new(root.Position.X, -1, root.Position.Z)
                WaterPart.CanCollide = (root.Position.Y >= -5)
            else
                WaterPart.CanCollide = false
            end
        end
    end
end)

-- [YÊU CẦU 2] TỐI ƯU NOCLIP: DUYỆT BẢNG CACHE DÙNG SẴN THAY VÌ GETDESCENDANTS CONTINUOUSLY
_conns["steppedLoop"] = RunService.Stepped:Connect(function()
    if S.PlayerNoClipEnabled then
        for i = #CharacterParts, 1, -1 do
            local part = CharacterParts[i]
            if part and part.Parent then
                part.CanCollide = false
            else
                table.remove(CharacterParts, i)
            end
        end
    end

    if S.BoatNoClipEnabled or S.FindLeviathanEnabled then
        for i = #BoatParts, 1, -1 do
            local part = BoatParts[i]
            if part and part.Parent then
                part.CanCollide = false
            else
                table.remove(BoatParts, i)
            end
        end
    end
end)

local function SetupAntiAFK()
    if not S.AntiAFKEnabled then return end
    pcall(function() VirtualUser:CaptureController() end)
end
SetupAntiAFK()

LocalPlayer.Idled:Connect(function()
    if S.AntiAFKEnabled then
        pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
    end
end)

task.delay(0.6, function()
    UILib.Notify("Hili Hub","Click icon Hilichurl để bật/tắt UI",5)
end)
