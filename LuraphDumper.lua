--[[
    ================================================================
    =  Luraph VM Dumper v3 - Standby & Auto Interceptor            =
    =  Hỗ trợ đặc biệt cho Delta X, Fluxus, Arceus X, CodeX...     =
    =                                                              =
    =  TÍNH NĂNG HOẠT ĐỘNG:                                        =
    =   1. Tự động chạy nền và kích hoạt tất cả Hook (HttpGet,     =
    =      loadstring, string.*, setmetatable, task.spawn...).     =
    =   2. Tự động tải và chạy script mục tiêu (TargetScriptURL).  =
    =   3. Có GUI mini trên màn hình Roblox hiển thị số liệu thực  =
    =      và nút bấm [DUMP & SEND NOW] để gửi Discord bất kỳ lúc  =
    =      nào bạn muốn.                                           =
    =   4. Tự động gửi Discord sau X giây nếu bạn không bấm tay.   =
    ================================================================
--]]

-- ╔═══════════════════════════════════════════════════╗
-- ║  CẤU HÌNH (SETTINGS)                              ║
-- ╚═══════════════════════════════════════════════════╝
local SETTINGS = {
    -- Discord Webhook URL (BẮT BUỘC)
    WebhookURL = "https://discord.com/api/webhooks/1540742443459416074/OoigNnHKVnNmTh9unbAqX4hEyE7o7e2p9HM7P5Hob1_cEemOFY_0OMIE9SbO9JHGhKI5",

    -- Script muốn dump (Nếu để trống "", Dumper chỉ chờ bạn tự chạy script)
    TargetScriptURL = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/QuantumOnyx.lua",

    -- Tự động chạy TargetScriptURL ngay khi Dumper sẵn sàng
    AutoRunTarget = true,

    -- Tự động gửi Discord sau khi script chạy được X giây
    AutoSendAfterSeconds = 12,

    -- Tên hiển thị
    ScriptName = "QuantumOnyx.lua",

    -- Cài đặt gửi
    WebhookUsername = "Luraph VM Dumper v3",
    EmbedColor     = 0x5865F2,
    MaxChunkSize   = 1850,
    MinStringLen   = 2,
    MaxDepth       = 50,
}

-- ╔═══════════════════════════════════════════════════╗
-- ║  BỘ NHỚ LƯU TRỮ VÀ TIỆN ÍCH                      ║
-- ╚═══════════════════════════════════════════════════╝
local State = {
    IsRunning = true,
    HasSent = false,
    CapturedStrings = {},
    CapturedStringsList = {},
    StringCount = 0,
    CapturedFuncs = {},
    FuncCount = 0,
    CapturedLoads = {},
    LoadCount = 0,
    CapturedHttp = {},
    HttpCount = 0,
    Logs = {},
    HookStatus = {},
}

local function safeStr(v) local ok, r = pcall(tostring, v); return ok and r or "<?>" end

local function escJSON(s)
    if type(s) ~= "string" then return safeStr(s) end
    return s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t'):gsub('[%c]',function(c) return ('\\u%04X'):format(c:byte()) end)
end

local function isPrintable(s)
    if type(s) ~= "string" then return false end
    for i = 1, math.min(#s, 80) do
        local b = s:byte(i)
        if b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then return false end
    end
    return true
end

local function trunc(s, n)
    n = n or 200
    if type(s) ~= "string" then return safeStr(s) end
    if #s <= n then return s end
    return s:sub(1, n) .. "...[" .. #s .. " chars]"
end

local function logMsg(msg)
    local t = ("[%s] %s"):format(os.date and os.date("%X") or tostring(math.floor(tick())), msg)
    table.insert(State.Logs, t)
    print("[Dumper] " .. msg)
end

local function recordString(s, src)
    if type(s) ~= "string" or #s < SETTINGS.MinStringLen then return end
    if State.CapturedStrings[s] then return end
    if not isPrintable(s) and #s > 60 then return end
    State.CapturedStrings[s] = true
    State.StringCount = State.StringCount + 1
    table.insert(State.CapturedStringsList, { value = s, source = src or "unknown", index = State.StringCount })
end

local function recordLoadstring(code, src)
    if type(code) ~= "string" or #code < 5 then return end
    State.LoadCount = State.LoadCount + 1
    table.insert(State.CapturedLoads, {
        index = State.LoadCount,
        length = #code,
        source = src or "loadstring",
        preview = code:sub(1, 400),
        fullCode = code,
    })
    logMsg(("🔥 INTERCEPTED LOADSTRING: %d bytes (Source: %s)"):format(#code, src or "loadstring"))
end

local function recordHttp(url, method)
    if type(url) ~= "string" then return end
    State.HttpCount = State.HttpCount + 1
    table.insert(State.CapturedHttp, {
        index = State.HttpCount,
        url = url,
        method = method or "GET",
        time = tick(),
    })
    logMsg(("🌐 CAPTURED HTTP REQUEST: [%s] %s"):format(method or "GET", url))
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  SCANNER (Quét Function / Constants / Upvalues)   ║
-- ╚═══════════════════════════════════════════════════╝
local function scanFunction(fn, depth, path)
    depth = depth or 0
    path = path or "root"
    if depth > SETTINGS.MaxDepth then return end
    if type(fn) ~= "function" then return end
    local key = tostring(fn)
    if State.CapturedFuncs[key] then return end
    State.CapturedFuncs[key] = true

    if islclosure and not islclosure(fn) then return end
    if iscclosure and iscclosure(fn) then return end

    State.FuncCount = State.FuncCount + 1
    local funcIdx = State.FuncCount

    local d = {
        index = funcIdx,
        path = path,
        depth = depth,
        constants = {},
        upvalues = {},
        protos = {},
        info = nil
    }

    pcall(function() d.info = debug.getinfo(fn) end)

    if debug and debug.getconstants then
        pcall(function()
            for i, v in pairs(debug.getconstants(fn)) do
                table.insert(d.constants, { index = i, type = type(v), value = v })
                if type(v) == "string" then
                    recordString(v, ("const@f%d[%d]"):format(funcIdx, i))
                end
            end
        end)
    end

    if debug and debug.getupvalues then
        pcall(function()
            for i, v in pairs(debug.getupvalues(fn)) do
                table.insert(d.upvalues, { index = i, type = type(v), value = v })
                if type(v) == "string" then
                    recordString(v, ("upval@f%d[%d]"):format(funcIdx, i))
                elseif type(v) == "function" then
                    scanFunction(v, depth + 1, path .. ".up[" .. i .. "]")
                end
            end
        end)
    end

    if debug and debug.getprotos then
        pcall(function()
            for i, p in pairs(debug.getprotos(fn)) do
                table.insert(d.protos, { index = i })
                scanFunction(p, depth + 1, path .. ".proto[" .. i .. "]")
            end
        end)
    end
end

local function scanGarbageCollector()
    if not getgc then return end
    logMsg("Scanning Memory GC...")
    local gcObjs = getgc(true)
    for _, obj in ipairs(gcObjs) do
        if type(obj) == "function" then
            scanFunction(obj, 0, "gc_fn")
        elseif type(obj) == "table" then
            pcall(function()
                for k, v in pairs(obj) do
                    if type(v) == "function" then
                        scanFunction(v, 0, "gc_tbl." .. safeStr(k))
                    end
                    if type(v) == "string" and #v >= SETTINGS.MinStringLen then
                        recordString(v, "gc_val")
                    end
                    if type(k) == "string" and #k >= SETTINGS.MinStringLen then
                        recordString(k, "gc_key")
                    end
                end
            end)
        end
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  CÀI ĐẶT HOOKS (Intercepting Engine)              ║
-- ╚═══════════════════════════════════════════════════╝
local function installAllHooks()
    logMsg("Installing system hooks...")

    -- 1. Hook loadstring & load
    local origLoadstring = loadstring or load
    if origLoadstring and hookfunction and newcclosure then
        pcall(function()
            local hook = newcclosure(function(code, chunkname, ...)
                if type(code) == "string" then
                    recordLoadstring(code, tostring(chunkname or "loadstring"))
                end
                return origLoadstring(code, chunkname, ...)
            end)
            hookfunction(origLoadstring, hook)
            if loadstring and loadstring ~= origLoadstring then
                hookfunction(loadstring, hook)
            end
            State.HookStatus["loadstring"] = true
        end)
    end

    -- 2. Hook game:HttpGet
    if game and hookfunction and newcclosure then
        pcall(function()
            local oldHttpGet
            oldHttpGet = hookfunction(game.HttpGet, newcclosure(function(self, url, ...)
                recordHttp(url, "HttpGet")
                local content = oldHttpGet(self, url, ...)
                if type(content) == "string" and #content > 20 then
                    recordString(content, "http_response@" .. tostring(url):sub(1, 40))
                end
                return content
            end))
            State.HookStatus["HttpGet"] = true
        end)
    end

    -- 3. Hook string functions (char, sub, gsub, format)
    if hookfunction and newcclosure then
        local stringTargets = {
            {"char", string.char},
            {"sub", string.sub},
            {"gsub", string.gsub},
            {"rep", string.rep},
            {"reverse", string.reverse},
            {"format", string.format},
        }
        for _, t in ipairs(stringTargets) do
            local name, orig = t[1], t[2]
            pcall(function()
                hookfunction(string[name], newcclosure(function(...)
                    local res = { orig(...) }
                    for _, r in ipairs(res) do
                        if type(r) == "string" and #r >= SETTINGS.MinStringLen then
                            recordString(r, "str." .. name)
                        end
                    end
                    return unpack(res)
                end))
                State.HookStatus["string." .. name] = true
            end)
        end

        -- Hook table.concat
        local origConcat = table.concat
        pcall(function()
            hookfunction(table.concat, newcclosure(function(...)
                local r = origConcat(...)
                if type(r) == "string" and #r >= SETTINGS.MinStringLen then
                    recordString(r, "table.concat")
                end
                return r
            end))
            State.HookStatus["table.concat"] = true
        end)
    end

    logMsg("Hooks setup completed!")
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  DISCORD TRANSMITTER                              ║
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
    if not fn then return false, "No HTTP Function" end
    local ok, r = pcall(fn)
    return ok, ok and "OK" or safeStr(r)
end

local function sendDiscordDump()
    if SETTINGS.WebhookURL == "" then
        logMsg("ERROR: No Webhook URL provided!")
        return
    end

    logMsg("Preparing dump payload for Discord...")
    scanGarbageCollector()

    -- 1. Embed Tổng Quan
    local embed = {
        title = "🚀 Luraph VM Dumper - Báo Cáo Hoạt Động",
        description = ("Script: **%s**\nThời gian: `%s`"):format(SETTINGS.ScriptName, os.date and os.date("%c") or "N/A"),
        color = SETTINGS.EmbedColor,
        fields = {
            { name = "📦 Strings Thu Được", value = ("**%d** chuỗi"):format(State.StringCount), inline = true },
            { name = "🧩 Functions Đã Quét", value = ("**%d** hàm"):format(State.FuncCount), inline = true },
            { name = "⚡ Loadstring Bắt Được", value = ("**%d** lần"):format(State.LoadCount), inline = true },
            { name = "🌐 HTTP Requests", value = ("**%d** link"):format(State.HttpCount), inline = true },
        },
        footer = { text = "Luraph Dumper v3 Delta X Edition" }
    }

    -- Danh sách HTTP URLs bắt được
    if State.HttpCount > 0 then
        local urls = {}
        for i, h in ipairs(State.CapturedHttp) do
            if i > 8 then break end
            table.insert(urls, ("• `[%s]` %s"):format(h.method, trunc(h.url, 60)))
        end
        table.insert(embed.fields, { name = "🔗 Links HTTP đã gọi", value = table.concat(urls, "\n"), inline = false })
    end

    -- Preview Strings
    if State.StringCount > 0 then
        local previews = {}
        local count = 0
        for _, s in ipairs(State.CapturedStringsList) do
            if count >= 15 then break end
            if #s.value >= 3 and #s.value <= 100 then
                count = count + 1
                table.insert(previews, ("`%s`"):format(trunc(s.value, 45)))
            end
        end
        if #previews > 0 then
            table.insert(embed.fields, { name = "📝 Preview Strings", value = table.concat(previews, "\n"), inline = false })
        end
    end

    httpPost(SETTINGS.WebhookURL, jsonEncode({
        username = SETTINGS.WebhookUsername,
        embeds = { embed }
    }))

    -- 2. Gửi Chi Tiết Strings theo từng Chunks
    local dumpLines = {}
    table.insert(dumpLines, "-- ==========================================")
    table.insert(dumpLines, "-- CAPTURED STRINGS REPORT (" .. State.StringCount .. " total)")
    table.insert(dumpLines, "-- ==========================================")

    for i, s in ipairs(State.CapturedStringsList) do
        table.insert(dumpLines, ('[%04d] [%s] "%s"'):format(i, s.source, escJSON(trunc(s.value, 180))))
    end

    if State.LoadCount > 0 then
        table.insert(dumpLines, "")
        table.insert(dumpLines, "-- ==========================================")
        table.insert(dumpLines, "-- CAPTURED LOADSTRINGS / BYTECODES")
        table.insert(dumpLines, "-- ==========================================")
        for i, l in ipairs(State.CapturedLoads) do
            table.insert(dumpLines, ("\n-- Loadstring #%d (%d bytes, source: %s)"):format(i, l.length, l.source))
            table.insert(dumpLines, l.preview)
        end
    end

    local fullDumpText = table.concat(dumpLines, "\n")
    local chunks = {}
    local remaining = fullDumpText

    while #remaining > 0 do
        if #remaining <= SETTINGS.MaxChunkSize then
            table.insert(chunks, remaining)
            break
        end
        local splitAt = SETTINGS.MaxChunkSize
        local nl = remaining:sub(1, splitAt):find("\n[^\n]*$")
        if nl and nl > splitAt * 0.5 then splitAt = nl end
        table.insert(chunks, remaining:sub(1, splitAt))
        remaining = remaining:sub(splitAt + 1)
    end

    for i, chunk in ipairs(chunks) do
        local header = ("**[Strings Dump %d/%d]** `%s`"):format(i, #chunks, SETTINGS.ScriptName)
        local msg = header .. "\n```lua\n" .. chunk .. "\n```"
        httpPost(SETTINGS.WebhookURL, jsonEncode({
            username = SETTINGS.WebhookUsername,
            content = msg
        }))
        if task and task.wait then task.wait(1.5) elseif wait then wait(1.5) end
    end

    logMsg(("✅ Successfully sent %d chunks to Discord Webhook!"):format(#chunks))
    State.HasSent = true
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  GIAO DIỆN MINI GUI (Trên màn hình Roblox)       ║
-- ╚═══════════════════════════════════════════════════╝
local function createMiniGUI()
    local pcallOK = pcall(function()
        local CoreGui = game:GetService("CoreGui") or (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))
        if not CoreGui then return end

        local existing = CoreGui:FindFirstChild("LuraphDumperGUI")
        if existing then existing:Destroy() end

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "LuraphDumperGUI"
        screenGui.ResetOnSpawn = false
        pcall(function() screenGui.Parent = CoreGui end)

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 220, 0, 150)
        frame.Position = UDim2.new(0.02, 0, 0.35, 0)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Draggable = true
        frame.Parent = screenGui

        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 8)

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1, 0, 0, 25)
        title.Text = "🛡️ Luraph Dumper v3"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 13
        title.Font = Enum.Font.GothamBold
        title.BackgroundTransparency = 1

        local stats = Instance.new("TextLabel", frame)
        stats.Size = UDim2.new(1, -10, 0, 50)
        stats.Position = UDim2.new(0, 5, 0, 28)
        stats.Text = "Strings: 0 | Funcs: 0\nLoads: 0 | Http: 0"
        stats.TextColor3 = Color3.fromRGB(200, 200, 220)
        stats.TextSize = 11
        stats.Font = Enum.Font.Gotham
        stats.BackgroundTransparency = 1

        local sendBtn = Instance.new("TextButton", frame)
        sendBtn.Size = UDim2.new(1, -16, 0, 30)
        sendBtn.Position = UDim2.new(0, 8, 0, 82)
        sendBtn.Text = "🚀 DUMP & SEND NOW"
        sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        sendBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        sendBtn.Font = Enum.Font.GothamBold
        sendBtn.TextSize = 12
        local btnCorner = Instance.new("UICorner", sendBtn)
        btnCorner.CornerRadius = UDim.new(0, 6)

        sendBtn.MouseButton1Click:Connect(function()
            sendBtn.Text = "⏳ Sending..."
            sendBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
            task.spawn(function()
                sendDiscordDump()
                sendBtn.Text = "✅ Sent to Discord!"
                sendBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
                if task and task.wait then task.wait(3) end
                sendBtn.Text = "🚀 DUMP & SEND NOW"
                sendBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            end)
        end)

        local statusLbl = Instance.new("TextLabel", frame)
        statusLbl.Size = UDim2.new(1, 0, 0, 20)
        statusLbl.Position = UDim2.new(0, 0, 0, 120)
        statusLbl.Text = "Listening for scripts..."
        statusLbl.TextColor3 = Color3.fromRGB(150, 255, 150)
        statusLbl.TextSize = 10
        statusLbl.Font = Enum.Font.Gotham
        statusLbl.BackgroundTransparency = 1

        -- Background updater
        task.spawn(function()
            while screenGui.Parent do
                stats.Text = ("Strings: %d | Funcs: %d\nLoads: %d | Http: %d"):format(
                    State.StringCount, State.FuncCount, State.LoadCount, State.HttpCount
                )
                if task and task.wait then task.wait(0.5) elseif wait then wait(0.5) end
            end
        end)
    end)
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  EXECUTION CONTROLLER                             ║
-- ╚═══════════════════════════════════════════════════╝
local function startDumper()
    logMsg("========================================")
    logMsg("  Luraph VM Dumper v3 - Standby Active")
    logMsg("========================================")

    -- Bước 1: Cài Hooks
    installAllHooks()

    -- Bước 2: Tạo GUI mini
    createMiniGUI()

    -- Bước 3: Nếu bật AutoRunTarget -> tải và chạy script mục tiêu
    if SETTINGS.AutoRunTarget and SETTINGS.TargetScriptURL ~= "" then
        logMsg("Auto-running target script in 2 seconds...")
        if task and task.wait then task.wait(2) elseif wait then wait(2) end

        task.spawn(function()
            logMsg("Fetching target script from: " .. SETTINGS.TargetScriptURL)
            local code = nil
            pcall(function()
                if game and game.HttpGet then
                    code = game:HttpGet(SETTINGS.TargetScriptURL, true)
                elseif syn and syn.request then
                    code = syn.request({ Url = SETTINGS.TargetScriptURL, Method = "GET" }).Body
                elseif request then
                    code = request({ Url = SETTINGS.TargetScriptURL, Method = "GET" }).Body
                elseif http_request then
                    code = http_request({ Url = SETTINGS.TargetScriptURL, Method = "GET" }).Body
                end
            end)

            if code and #code > 10 then
                logMsg(("Target code loaded (%d bytes). Compiling..."):format(#code))
                local fn, err = (loadstring or load)(code, SETTINGS.ScriptName)
                if fn then
                    logMsg("Target compiled successfully! Running inside VM...")
                    scanFunction(fn, 0, "target_root")
                    local ok, res = pcall(fn)
                    if ok then
                        logMsg("Target executed cleanly!")
                    else
                        logMsg("Target script notice/error: " .. safeStr(res))
                    end
                else
                    logMsg("Compile error: " .. safeStr(err))
                end
            else
                logMsg("Failed to download TargetScriptURL!")
            end
        end)
    else
        logMsg("Standing by! You can now execute any script in your executor.")
    end

    -- Bước 4: Tự động đếm lùi để quét và gửi Discord
    if SETTINGS.AutoSendAfterSeconds > 0 then
        task.spawn(function()
            local waitTime = SETTINGS.AutoSendAfterSeconds + (SETTINGS.AutoRunTarget and 3 or 0)
            logMsg(("Auto-send timer started: %d seconds..."):format(waitTime))
            if task and task.wait then task.wait(waitTime) elseif wait then wait(waitTime) end
            if not State.HasSent then
                logMsg("Timer reached! Triggering automated Discord dump...")
                sendDiscordDump()
            end
        end)
    end
end

-- Khởi động ngay
startDumper()
