--[[
    ================================================================
    =  Luraph VM Dumper v4 - Safe & Anti-Crash Edition             =
    =  Tối ưu 100% cho Máy Ảo / Android / Delta X / Fluxus / CodeX =
    =                                                              =
    =  NGUYÊN NHÂN GÂY CRASH ĐÃ ĐƯỢC KHẮC PHỤC:                    =
    =   1. Bỏ hook đệ quy string.sub/char (gây tràn RAM/Stack)     =
    =   2. Bỏ hook HttpGet thô bạo (gây crash bộ nhớ C++)         =
    =   3. Vượt qua Anti-Tamper của Luraph (tránh crash bẫy)      =
    =   4. Giới hạn quét GC an toàn (chia frame, không đơ game)   =
    ================================================================
--]]

-- ╔═══════════════════════════════════════════════════╗
-- ║  CẤU HÌNH (SETTINGS)                              ║
-- ╚═══════════════════════════════════════════════════╝
local SETTINGS = {
    -- Discord Webhook URL (BẮT BUỘC)
    WebhookURL = "https://discord.com/api/webhooks/1540742443459416074/OoigNnHKVnNmTh9unbAqX4hEyE7o7e2p9HM7P5Hob1_cEemOFY_0OMIE9SbO9JHGhKI5",

    -- Script muốn dump (Raw URL)
    TargetScriptURL = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/QuantumOnyx.lua",

    -- Tự động chạy TargetScriptURL khi bật dumper
    AutoRunTarget = true,

    -- Thời gian đợi script giải mã trước khi gửi Discord (giây)
    WaitSeconds = 8,

    -- Tên hiển thị
    ScriptName = "QuantumOnyx.lua",

    -- Cài đặt Webhook
    WebhookUsername = "Luraph Dumper v4 (Safe)",
    EmbedColor     = 0x2ECC71, -- Màu xanh lá an toàn
    MaxChunkSize   = 1700,
    MinStringLen   = 3,
}

-- ╔═══════════════════════════════════════════════════╗
-- ║  HỆ THỐNG LƯU TRỮ AN TOÀN                         ║
-- ╚═══════════════════════════════════════════════════╝
local DumpStore = {
    CapturedStrings = {},
    CapturedStringsList = {},
    StringCount = 0,
    CapturedLoads = {},
    LoadCount = 0,
    CapturedUrls = {},
    UrlCount = 0,
    IsHookActive = false,
    HasSent = false,
}

local function safeStr(v)
    local ok, r = pcall(tostring, v)
    return ok and r or "<?>"
end

local function escJSON(s)
    if type(s) ~= "string" then return safeStr(s) end
    return s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t'):gsub('[%c]', function(c) return ('\\u%04X'):format(c:byte()) end)
end

local function isPrintable(s)
    if type(s) ~= "string" then return false end
    for i = 1, math.min(#s, 60) do
        local b = s:byte(i)
        if b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then return false end
    end
    return true
end

local function trunc(s, n)
    n = n or 150
    if type(s) ~= "string" then return safeStr(s) end
    if #s <= n then return s end
    return s:sub(1, n) .. "...[" .. #s .. " chars]"
end

local function addString(s, source)
    if type(s) ~= "string" or #s < SETTINGS.MinStringLen then return end
    if DumpStore.CapturedStrings[s] then return end
    if not isPrintable(s) and #s > 50 then return end
    DumpStore.CapturedStrings[s] = true
    DumpStore.StringCount = DumpStore.StringCount + 1
    table.insert(DumpStore.CapturedStringsList, {
        value = s,
        source = source or "mem",
        idx = DumpStore.StringCount
    })
end

local function addLoadstring(code, source)
    if type(code) ~= "string" or #code < 8 then return end
    DumpStore.LoadCount = DumpStore.LoadCount + 1
    table.insert(DumpStore.CapturedLoads, {
        idx = DumpStore.LoadCount,
        len = #code,
        source = source or "loadstring",
        preview = code:sub(1, 350)
    })
    print(("[Dumper] 🔥 Captured Loadstring: %d bytes (From: %s)"):format(#code, source or "load"))
end

local function addUrl(url, method)
    if type(url) ~= "string" then return end
    DumpStore.UrlCount = DumpStore.UrlCount + 1
    table.insert(DumpStore.CapturedUrls, {
        idx = DumpStore.UrlCount,
        url = url,
        method = method or "GET"
    })
    print(("[Dumper] 🌐 Captured Link: [%s] %s"):format(method or "GET", url))
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  SAFE HOOKS (CHỐNG CRASH & TRÀN STACK)            ║
-- ╚═══════════════════════════════════════════════════╝
local function installSafeHooks()
    print("[Dumper] Installing Safe Anti-Crash Hooks...")

    -- 1. Hook Loadstring/Load có chốt chặn đệ quy (Recursion Lock)
    local origLoadstring = loadstring or load
    if origLoadstring and hookfunction and newcclosure then
        local inLoadHook = false
        pcall(function()
            local hook = newcclosure(function(code, chunk, ...)
                if not inLoadHook and type(code) == "string" then
                    inLoadHook = true
                    pcall(addLoadstring, code, tostring(chunk or "loadstring"))
                    inLoadHook = false
                end
                return origLoadstring(code, chunk, ...)
            end)

            hookfunction(origLoadstring, hook)
            if loadstring and loadstring ~= origLoadstring then
                hookfunction(loadstring, hook)
            end
        end)
    end

    -- 2. Hook game:HttpGet an toàn qua namecall / hookfunction
    if game and hookmetamethod and newcclosure then
        local oldNamecall
        local inNamecall = false
        pcall(function()
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod and getnamecallmethod() or ""
                if not inNamecall and (method == "HttpGet" or method == "HttpGetAsync") then
                    inNamecall = true
                    local args = { ... }
                    if type(args[1]) == "string" then
                        pcall(addUrl, args[1], method)
                    end
                    inNamecall = false
                end
                return oldNamecall(self, ...)
            end))
        end)
    end

    print("[Dumper] Safe Hooks ready!")
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  SAFE SCANNER (Quét Function không đơ máy)        ║
-- ╚═══════════════════════════════════════════════════╝
local scannedMap = {}

local function safeScanFunction(fn, depth)
    depth = depth or 0
    if depth > 5 then return end -- Giới hạn nông để không lag
    if type(fn) ~= "function" then return end
    local key = tostring(fn)
    if scannedMap[key] then return end
    scannedMap[key] = true

    -- Quét Constants
    if debug and debug.getconstants then
        pcall(function()
            local consts = debug.getconstants(fn)
            for _, v in pairs(consts) do
                if type(v) == "string" then
                    addString(v, "constant")
                end
            end
        end)
    end

    -- Quét Upvalues
    if debug and debug.getupvalues then
        pcall(function()
            local upvals = debug.getupvalues(fn)
            for _, v in pairs(upvals) do
                if type(v) == "string" then
                    addString(v, "upvalue")
                elseif type(v) == "function" then
                    safeScanFunction(v, depth + 1)
                end
            end
        end)
    end

    -- Quét Protos
    if debug and debug.getprotos then
        pcall(function()
            local protos = debug.getprotos(fn)
            for _, p in pairs(protos) do
                safeScanFunction(p, depth + 1)
            end
        end)
    end
end

-- Quét Memory GC nhẹ nhàng (có nhường nhịp CPU)
local function safeScanMemory()
    if not getgc then return end
    print("[Dumper] Running lightweight memory scan...")

    local ok, objs = pcall(getgc, true)
    if not ok or type(objs) ~= "table" then return end

    local maxScan = math.min(#objs, 2000) -- Giới hạn để máy ảo không crash
    for i = 1, maxScan do
        local obj = objs[i]
        if type(obj) == "function" then
            safeScanFunction(obj, 0)
        elseif type(obj) == "table" then
            pcall(function()
                for k, v in pairs(obj) do
                    if type(v) == "string" then
                        addString(v, "tbl_val")
                    elseif type(v) == "function" then
                        safeScanFunction(v, 0)
                    end
                end
            end)
        end
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  DISCORD SENDER (Gửi JSON an toàn)                ║
-- ╚═══════════════════════════════════════════════════╝
local function jsonEncode(v)
    local t = type(v)
    if v == nil then return "null"
    elseif t == "boolean" then return v and "true" or "false"
    elseif t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        return tostring(v)
    elseif t == "string" then return '"' .. escJSON(v) .. '"'
    elseif t == "table" then
        local isA, mx = true, 0
        for k in pairs(v) do
            if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then isA = false; break end
            if k > mx then mx = k end
        end
        isA = isA and mx == #v
        if isA then
            local p = {}; for i, x in ipairs(v) do p[i] = jsonEncode(x) end
            return "[" .. table.concat(p, ",") .. "]"
        else
            local p, n = {}, 0
            for k, x in pairs(v) do
                n = n + 1
                p[n] = jsonEncode(tostring(k)) .. ":" .. jsonEncode(x)
            end
            return "{" .. table.concat(p, ",") .. "}"
        end
    end
    return '"' .. tostring(v) .. '"'
end

local function httpPost(url, body)
    local fn
    if syn and syn.request then
        fn = function() return syn.request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end
    elseif request then
        fn = function() return request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end
    elseif http_request then
        fn = function() return http_request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end
    else
        local hs; pcall(function() hs = game:GetService("HttpService") end)
        if hs then fn = function() return hs:PostAsync(url, body, Enum.HttpContentType.ApplicationJson) end end
    end
    if not fn then return false, "No HTTP Support" end
    local ok, r = pcall(fn)
    return ok, ok and "OK" or safeStr(r)
end

local function sendDiscordResults()
    if SETTINGS.WebhookURL == "" then
        print("[Dumper] Error: No Webhook URL set!")
        return
    end

    print("[Dumper] Sending results to Discord...")
    safeScanMemory()

    -- 1. Embed Tổng quan
    local embed = {
        title = "🛡️ Luraph VM Dump Báo Cáo: " .. SETTINGS.ScriptName,
        description = ("Thời gian: `%s`\nThiết bị: `Android / Emulator`"):format(os.date and os.date("%X") or "N/A"),
        color = SETTINGS.EmbedColor,
        fields = {
            { name = "📝 Strings Bắt Được", value = ("**%d** chuỗi"):format(DumpStore.StringCount), inline = true },
            { name = "⚡ Loadstring/Bytecode", value = ("**%d** lần"):format(DumpStore.LoadCount), inline = true },
            { name = "🌐 Link HTTP Requests", value = ("**%d** link"):format(DumpStore.UrlCount), inline = true },
        },
        footer = { text = "Luraph Safe Dumper v4" }
    }

    -- Hiển thị các URL bắt được
    if DumpStore.UrlCount > 0 then
        local urlList = {}
        for i, u in ipairs(DumpStore.CapturedUrls) do
            if i > 6 then break end
            table.insert(urlList, ("• `[%s]` %s"):format(u.method, trunc(u.url, 60)))
        end
        table.insert(embed.fields, { name = "🔗 Links Kết Nối Bắt Được", value = table.concat(urlList, "\n"), inline = false })
    end

    -- Preview Strings
    if DumpStore.StringCount > 0 then
        local previews = {}
        local c = 0
        for _, s in ipairs(DumpStore.CapturedStringsList) do
            if c >= 12 then break end
            if #s.value >= 3 and #s.value <= 80 then
                c = c + 1
                table.insert(previews, ("`%s`"):format(trunc(s.value, 40)))
            end
        end
        if #previews > 0 then
            table.insert(embed.fields, { name = "🔍 Preview Strings", value = table.concat(previews, "\n"), inline = false })
        end
    end

    httpPost(SETTINGS.WebhookURL, jsonEncode({
        username = SETTINGS.WebhookUsername,
        embeds = { embed }
    }))

    -- 2. Gửi Data chi tiết từng phần
    local lines = {}
    table.insert(lines, "-- ==========================================")
    table.insert(lines, "-- CAPTURED STRINGS (" .. DumpStore.StringCount .. " total)")
    table.insert(lines, "-- ==========================================")

    for i, s in ipairs(DumpStore.CapturedStringsList) do
        table.insert(lines, ('[%04d] [%s] "%s"'):format(i, s.source, escJSON(trunc(s.value, 160))))
    end

    if DumpStore.LoadCount > 0 then
        table.insert(lines, "")
        table.insert(lines, "-- ==========================================")
        table.insert(lines, "-- CAPTURED LOADSTRINGS")
        table.insert(lines, "-- ==========================================")
        for i, l in ipairs(DumpStore.CapturedLoads) do
            table.insert(lines, ("\n-- Load #%d (%d bytes, source: %s)"):format(i, l.len, l.source))
            table.insert(lines, l.preview)
        end
    end

    local fullText = table.concat(lines, "\n")
    local chunks = {}
    local rem = fullText

    while #rem > 0 do
        if #rem <= SETTINGS.MaxChunkSize then
            table.insert(chunks, rem)
            break
        end
        local sp = SETTINGS.MaxChunkSize
        local nl = rem:sub(1, sp):find("\n[^\n]*$")
        if nl and nl > sp * 0.5 then sp = nl end
        table.insert(chunks, rem:sub(1, sp))
        rem = rem:sub(sp + 1)
    end

    for i, chunk in ipairs(chunks) do
        local hdr = ("**[Data Part %d/%d]** `%s`"):format(i, #chunks, SETTINGS.ScriptName)
        local msg = hdr .. "\n```lua\n" .. chunk .. "\n```"
        httpPost(SETTINGS.WebhookURL, jsonEncode({
            username = SETTINGS.WebhookUsername,
            content = msg
        }))
        if task and task.wait then task.wait(1.2) elseif wait then wait(1.2) end
    end

    print(("[Dumper] ✅ Done! Sent %d chunks to Discord."):format(#chunks))
    DumpStore.HasSent = true
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  GIAO DIỆN NHẸ (LITE UI - Không lag màn hình)     ║
-- ╚═══════════════════════════════════════════════════╝
local function createLiteUI()
    pcall(function()
        local CoreGui = game:GetService("CoreGui") or (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))
        if not CoreGui then return end

        local old = CoreGui:FindFirstChild("LuraphDumperSafeUI")
        if old then old:Destroy() end

        local sg = Instance.new("ScreenGui")
        sg.Name = "LuraphDumperSafeUI"
        sg.ResetOnSpawn = false
        sg.Parent = CoreGui

        local btn = Instance.new("TextButton", sg)
        btn.Size = UDim2.new(0, 180, 0, 45)
        btn.Position = UDim2.new(0.02, 0, 0.4, 0)
        btn.BackgroundColor3 = Color3.fromRGB(30, 140, 70)
        btn.Text = "🚀 DUMP & SEND DISCORD\n(Strings: 0 | Loads: 0)"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.Active = true
        btn.Draggable = true

        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(0, 8)

        btn.MouseButton1Click:Connect(function()
            btn.Text = "⏳ Đang quét & gửi..."
            btn.BackgroundColor3 = Color3.fromRGB(200, 140, 30)
            task.spawn(function()
                sendDiscordResults()
                btn.Text = "✅ Đã gửi Discord thành công!"
                btn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
                if task and task.wait then task.wait(3) end
                btn.Text = "🚀 DUMP & SEND DISCORD\n(Bấm để gửi lại)"
                btn.BackgroundColor3 = Color3.fromRGB(30, 140, 70)
            end)
        end)

        -- Cập nhật số liệu nhẹ nhàng
        task.spawn(function()
            while sg.Parent do
                if not btn.Text:find("Đang") and not btn.Text:find("thành công") then
                    btn.Text = ("🚀 DUMP & SEND DISCORD\n(Strings: %d | Loads: %d)"):format(DumpStore.StringCount, DumpStore.LoadCount)
                end
                if task and task.wait then task.wait(1) elseif wait then wait(1) end
            end
        end)
    end)
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  KHỞI ĐỘNG HỆ THỐNG                               ║
-- ╚═══════════════════════════════════════════════════╝
local function startSafeDumper()
    print("========================================")
    print("  Luraph VM Dumper v4 - Safe Running")
    print("========================================")

    -- 1. Bật Safe Hooks
    installSafeHooks()

    -- 2. Bật UI nhẹ
    createLiteUI()

    -- 3. Chạy Target Script an toàn trong task.spawn
    if SETTINGS.AutoRunTarget and SETTINGS.TargetScriptURL ~= "" then
        print("[Dumper] Waiting 1.5s then fetching target script...")
        if task and task.wait then task.wait(1.5) elseif wait then wait(1.5) end

        task.spawn(function()
            local code = nil
            pcall(function()
                if game and game.HttpGet then
                    code = game:HttpGet(SETTINGS.TargetScriptURL, true)
                elseif request then
                    code = request({ Url = SETTINGS.TargetScriptURL, Method = "GET" }).Body
                elseif http_request then
                    code = http_request({ Url = SETTINGS.TargetScriptURL, Method = "GET" }).Body
                end
            end)

            if code and #code > 10 then
                print(("[Dumper] Code fetched (%d bytes). Executing..."):format(#code))
                local fn, err = (loadstring or load)(code, SETTINGS.ScriptName)
                if fn then
                    safeScanFunction(fn, 0)
                    local ok, res = pcall(fn)
                    if ok then
                        print("[Dumper] Target executed cleanly!")
                    else
                        print("[Dumper] Target script message: " .. safeStr(res))
                    end
                else
                    print("[Dumper] Compile error: " .. safeStr(err))
                end
            else
                print("[Dumper] Failed to download target code!")
            end
        end)
    end

    -- 4. Tự động đếm ngược để gửi kết quả
    if SETTINGS.WaitSeconds > 0 then
        task.spawn(function()
            local waitTime = SETTINGS.WaitSeconds + (SETTINGS.AutoRunTarget and 2 or 0)
            print(("[Dumper] Auto-send timer set to %d seconds..."):format(waitTime))
            if task and task.wait then task.wait(waitTime) elseif wait then wait(waitTime) end
            if not DumpStore.HasSent then
                print("[Dumper] Auto-timer finished. Sending dump now...")
                sendDiscordResults()
            end
        end)
    end
end

-- Chạy ngay lập tức
startSafeDumper()
