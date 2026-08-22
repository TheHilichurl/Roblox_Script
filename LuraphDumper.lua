--[[
    ================================================================
    =  Luraph VM Dumper - All-In-One (No File Access Required)     =
    =  Dành cho Delta X và các executor không có readfile/writefile =
    =                                                                =
    =  Cách dùng: Paste toàn bộ script này vào executor rồi chạy   =
    =  Kết quả sẽ tự động gửi lên Discord webhook                  =
    ================================================================
--]]

-- ╔═══════════════════════════════════════════════════╗
-- ║  CẤU HÌNH - THAY ĐỔI CÁC GIÁ TRỊ BÊN DƯỚI     ║
-- ╚═══════════════════════════════════════════════════╝

local SETTINGS = {
    -- Discord Webhook URL (BẮT BUỘC)
    WebhookURL = "https://discord.com/api/webhooks/1540742443459416074/OoigNnHKVnNmTh9unbAqX4hEyE7o7e2p9HM7P5Hob1_cEemOFY_0OMIE9SbO9JHGhKI5",
    
    -- URL của script cần dump (thay bằng raw link GitHub/Pastebin của bạn)
    -- Ví dụ: "https://raw.githubusercontent.com/user/repo/main/BF-BananaCat.lua"
    TargetScriptURL = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/QuantumOnyx.lua",
    
    -- HOẶC: Nếu bạn có loadstring trực tiếp, đặt code vào đây
    -- Để trống "" nếu dùng URL ở trên
    TargetScriptCode = "",
    
    -- Tên script (để hiển thị trong Discord)
    ScriptName = "BF-BananaCat.lua",
    
    -- Cài đặt dumper
    WebhookUsername = "Luraph VM Dumper",
    EmbedColor     = 0x5865F2,
    MaxChunkSize   = 1850,
    MaxDepth       = 50,
    MinStringLen   = 2,
}

-- ╔═══════════════════════════════════════════════════╗
-- ║  HỆ THỐNG NỘI BỘ - KHÔNG CẦN SỬA                ║
-- ╚═══════════════════════════════════════════════════╝

-- Utilities
local Utils = {}
function Utils.timestamp()
    return tostring(os.time and os.time() or tick and tick() or 0)
end
function Utils.safeStr(v)
    local ok, r = pcall(tostring, v)
    return ok and r or "<?>"
end
function Utils.escapeJSON(s)
    if type(s) ~= "string" then return Utils.safeStr(s) end
    return s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t'):gsub('[%c]', function(c) return ('\\u%04X'):format(string.byte(c)) end)
end
function Utils.isPrintable(s)
    if type(s) ~= "string" then return false end
    for i = 1, math.min(#s, 100) do
        local b = string.byte(s, i)
        if b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then return false end
    end
    return true
end
function Utils.truncate(s, n)
    n = n or 200
    if type(s) ~= "string" then return Utils.safeStr(s) end
    if #s <= n then return s end
    return s:sub(1, n) .. "...[" .. #s .. " chars]"
end

-- Logger
local Log = { buf = {}, n = 0 }
function Log:w(t) self.n = self.n + 1; self.buf[self.n] = t or "" end
function Log:f(fmt, ...) self:w(fmt:format(...)) end
function Log:section(t) self:w(""); self:w("-- === " .. t .. " " .. string.rep("=", math.max(0, 50 - #t))); self:w("") end
function Log:get() return table.concat(self.buf, "\n") end

-- String Capture
local Strings = { seen = {}, list = {}, count = 0 }
function Strings:add(s, src)
    if type(s) ~= "string" or #s < SETTINGS.MinStringLen then return end
    if self.seen[s] then return end
    if not Utils.isPrintable(s) and #s > 50 then return end
    self.seen[s] = true
    self.count = self.count + 1
    self.list[self.count] = { value = s, source = src or "?", idx = self.count }
end

-- Function Scanner
local FuncScan = { scanned = {}, funcs = {}, count = 0 }
function FuncScan:scan(fn, depth, path)
    depth = depth or 0; path = path or "root"
    if depth > SETTINGS.MaxDepth then return end
    local key = tostring(fn)
    if self.scanned[key] then return end
    self.scanned[key] = true
    if type(fn) ~= "function" then return end
    if islclosure and not islclosure(fn) then return end
    if iscclosure and iscclosure(fn) then return end

    self.count = self.count + 1
    local idx = self.count
    local data = { index = idx, path = path, depth = depth, constants = {}, upvalues = {}, protos = {}, info = nil }

    pcall(function() data.info = debug.getinfo(fn) end)

    if debug.getconstants then
        pcall(function()
            for i, v in pairs(debug.getconstants(fn)) do
                table.insert(data.constants, { index = i, type = type(v), value = v })
                if type(v) == "string" then Strings:add(v, ("const@f%d[%d]"):format(idx, i)) end
            end
        end)
    end

    if debug.getupvalues then
        pcall(function()
            for i, v in pairs(debug.getupvalues(fn)) do
                table.insert(data.upvalues, { index = i, type = type(v), value = v })
                if type(v) == "string" then Strings:add(v, ("upval@f%d[%d]"):format(idx, i)) end
                if type(v) == "function" then self:scan(v, depth + 1, path .. ".up[" .. i .. "]") end
            end
        end)
    end

    if debug.getprotos then
        pcall(function()
            for i, p in pairs(debug.getprotos(fn)) do
                table.insert(data.protos, { index = i })
                self:scan(p, depth + 1, path .. ".proto[" .. i .. "]")
            end
        end)
    end

    self.funcs[idx] = data
end

function FuncScan:scanGC()
    if not getgc then return 0, 0 end
    local fc, sc = 0, 0
    for _, obj in ipairs(getgc(true)) do
        if type(obj) == "function" then
            fc = fc + 1
            self:scan(obj, 0, "gc_f" .. fc)
        elseif type(obj) == "table" then
            pcall(function()
                for k, v in pairs(obj) do
                    if type(v) == "function" then fc = fc + 1; self:scan(v, 0, "gc_t." .. Utils.safeStr(k)) end
                    if type(v) == "string" and #v >= SETTINGS.MinStringLen then sc = sc + 1; Strings:add(v, "gc_val") end
                    if type(k) == "string" and #k >= SETTINGS.MinStringLen then Strings:add(k, "gc_key") end
                end
            end)
        end
    end
    return fc, sc
end

-- Loadstring Interceptor
local LoadCaptures = { list = {}, count = 0 }
function LoadCaptures:hook()
    if not hookfunction or not newcclosure then return false end
    local orig = loadstring or load
    if not orig then return false end
    local ok = pcall(function()
        local h = newcclosure(function(code, ...)
            if type(code) == "string" and #code > 10 then
                LoadCaptures.count = LoadCaptures.count + 1
                LoadCaptures.list[LoadCaptures.count] = {
                    idx = LoadCaptures.count, len = #code,
                    preview = code:sub(1, 300), time = Utils.timestamp()
                }
            end
            return orig(code, ...)
        end)
        if loadstring then hookfunction(loadstring, h) end
    end)
    return ok
end

-- String Lib Hooks
local function installStringHooks()
    if not hookfunction or not newcclosure then return false end
    local targets = {
        { string, "char", string.char }, { string, "sub", string.sub },
        { string, "gsub", string.gsub }, { string, "rep", string.rep },
        { string, "reverse", string.reverse },
    }
    local hooked = 0
    for _, t in ipairs(targets) do
        local orig, name = t[3], t[2]
        pcall(function()
            hookfunction(t[1][name], newcclosure(function(...)
                local r = { orig(...) }
                for _, v in ipairs(r) do
                    if type(v) == "string" and #v >= SETTINGS.MinStringLen then
                        Strings:add(v, "str." .. name)
                    end
                end
                return unpack(r)
            end))
            hooked = hooked + 1
        end)
    end
    return hooked > 0
end

-- JSON Encoder (minimal)
local function jsonEncode(v)
    local t = type(v)
    if v == nil then return "null"
    elseif t == "boolean" then return v and "true" or "false"
    elseif t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        return tostring(v)
    elseif t == "string" then return '"' .. Utils.escapeJSON(v) .. '"'
    elseif t == "table" then
        local isArr, mx = true, 0
        for k in pairs(v) do
            if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then isArr = false; break end
            if k > mx then mx = k end
        end
        isArr = isArr and mx == #v
        if isArr then
            local p = {}; for i, x in ipairs(v) do p[i] = jsonEncode(x) end
            return "[" .. table.concat(p, ",") .. "]"
        else
            local p, n = {}, 0
            for k, x in pairs(v) do n = n + 1; p[n] = jsonEncode(tostring(k)) .. ":" .. jsonEncode(x) end
            return "{" .. table.concat(p, ",") .. "}"
        end
    end
    return '"' .. tostring(v) .. '"'
end

-- HTTP Sender
local function httpPost(url, body)
    local fn, method
    if syn and syn.request then
        fn = function() return syn.request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end
        method = "syn.request"
    elseif request then
        fn = function() return request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end
        method = "request"
    elseif http_request then
        fn = function() return http_request({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end
        method = "http_request"
    elseif game and game.HttpGet then
        -- Fallback: some executors support HttpService
        local hs = nil
        pcall(function() hs = game:GetService("HttpService") end)
        if hs then
            fn = function() return hs:PostAsync(url, body, Enum.HttpContentType.ApplicationJson) end
            method = "HttpService"
        end
    end
    if not fn then return false, "No HTTP method" end
    local ok, r = pcall(fn)
    return ok, ok and method or tostring(r)
end

local function sendWebhook(payload)
    return httpPost(SETTINGS.WebhookURL, jsonEncode(payload))
end

local function sendMessage(text)
    return sendWebhook({ content = text, username = SETTINGS.WebhookUsername })
end

local function sendEmbed(embed)
    return sendWebhook({ username = SETTINGS.WebhookUsername, embeds = { embed } })
end

local function delayFn(sec)
    if task and task.wait then task.wait(sec)
    elseif wait then wait(sec)
    else
        local t = os.clock(); while os.clock() - t < sec do end
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  CHẠY CHÍNH                                       ║
-- ╚═══════════════════════════════════════════════════╝

local function main()
    print("[Dumper] Luraph VM Dumper All-In-One starting...")
    Log:section("LURAPH VM DUMPER - ALL IN ONE")
    Log:f("Timestamp: %s", Utils.timestamp())
    Log:f("Target: %s", SETTINGS.ScriptName)

    -- 1) Detect capabilities
    Log:section("EXECUTOR CAPABILITIES")
    local caps = {
        { "debug.getconstants", debug and debug.getconstants },
        { "debug.getprotos",    debug and debug.getprotos },
        { "debug.getupvalues",  debug and debug.getupvalues },
        { "debug.getinfo",      debug and debug.getinfo },
        { "debug.sethook",      debug and debug.sethook },
        { "hookfunction",       hookfunction },
        { "newcclosure",        newcclosure },
        { "getgc",              getgc },
        { "islclosure",         islclosure },
        { "decompile",          decompile },
        { "getrawmetatable",    getrawmetatable },
        { "readfile",           readfile },
        { "writefile",          writefile },
        { "request/http",       request or http_request or (syn and syn.request) },
    }
    for _, c in ipairs(caps) do
        local status = c[2] and "[YES]" or "[NO ]"
        Log:f("  %s %s", status, c[1])
        print(("  %s %s"):format(status, c[1]))
    end

    -- 2) Install hooks BEFORE loading target script
    Log:section("INSTALLING HOOKS")

    local strHooked = installStringHooks()
    Log:f("  String hooks: %s", strHooked and "OK" or "SKIPPED (no hookfunction)")
    print(("  String hooks: %s"):format(strHooked and "OK" or "SKIPPED"))

    local loadHooked = LoadCaptures:hook()
    Log:f("  Loadstring hook: %s", loadHooked and "OK" or "SKIPPED")
    print(("  Loadstring hook: %s"):format(loadHooked and "OK" or "SKIPPED"))

    -- 3) Load and execute target script
    Log:section("EXECUTING TARGET SCRIPT")
    local targetFunc = nil
    local targetErr = nil

    if SETTINGS.TargetScriptCode ~= "" then
        -- Load from embedded code
        Log:w("  Loading from embedded code...")
        print("[Dumper] Loading from embedded code...")
        local fn, err = (loadstring or load)(SETTINGS.TargetScriptCode, SETTINGS.ScriptName)
        if fn then targetFunc = fn else targetErr = err end

    elseif SETTINGS.TargetScriptURL ~= "" then
        -- Load from URL
        Log:f("  Loading from URL: %s", SETTINGS.TargetScriptURL)
        print("[Dumper] Loading from URL: " .. SETTINGS.TargetScriptURL)
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
        if code then
            local fn, err = (loadstring or load)(code, SETTINGS.ScriptName)
            if fn then targetFunc = fn else targetErr = err end
        else
            targetErr = "Failed to fetch URL"
        end
    else
        Log:w("  [!] No target script configured!")
        Log:w("  Set SETTINGS.TargetScriptURL or SETTINGS.TargetScriptCode")
        print("[Dumper] WARNING: No target script! Set TargetScriptURL or TargetScriptCode")
    end

    -- Pre-execution scan
    if targetFunc then
        Log:w("  Pre-execution scan...")
        FuncScan:scan(targetFunc, 0, "target_main")

        Log:w("  Executing target...")
        print("[Dumper] Executing target script...")
        local ok, result = pcall(targetFunc)
        if ok then
            Log:w("  [OK] Execution successful")
            print("[Dumper] Target executed successfully")
            if type(result) == "function" then
                FuncScan:scan(result, 0, "target_return")
            elseif type(result) == "table" then
                for k, v in pairs(result) do
                    if type(v) == "function" then
                        FuncScan:scan(v, 0, "ret." .. Utils.safeStr(k))
                    end
                end
            end
        else
            Log:f("  [!] Execution error: %s", Utils.safeStr(result))
            print("[Dumper] Execution error: " .. Utils.safeStr(result))
        end
    elseif targetErr then
        Log:f("  [!] Load error: %s", Utils.safeStr(targetErr))
        print("[Dumper] Load error: " .. Utils.safeStr(targetErr))
    end

    -- 4) Post-execution: Scan GC for ALL functions in memory
    Log:section("POST-EXECUTION MEMORY SCAN")
    print("[Dumper] Scanning memory...")
    local gcFuncs, gcStrings = FuncScan:scanGC()
    Log:f("  GC functions found: %d", gcFuncs)
    Log:f("  GC strings found: %d", gcStrings)
    print(("[Dumper] GC: %d functions, %d strings"):format(gcFuncs, gcStrings))

    -- Scan metatables
    if getrawmetatable and getgc then
        local mtCount = 0
        pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" then
                    pcall(function()
                        local mt = getrawmetatable(obj)
                        if mt then
                            for k, v in pairs(mt) do
                                if type(v) == "function" then
                                    mtCount = mtCount + 1
                                    FuncScan:scan(v, 0, "mt.__" .. Utils.safeStr(k))
                                end
                            end
                        end
                    end)
                end
            end
        end)
        Log:f("  Metamethods found: %d", mtCount)
    end

    -- 5) Generate report
    Log:section(("FUNCTIONS (%d scanned)"):format(FuncScan.count))
    for i = 1, FuncScan.count do
        local d = FuncScan.funcs[i]
        if d then
            local indent = string.rep("  ", math.min(d.depth, 5) + 1)
            Log:f("%s[F#%d] %s", indent, i, d.path)
            if d.info then
                Log:f("%s  src: %s:%s", indent, d.info.short_src or "?", d.info.linedefined or "?")
            end
            if #d.constants > 0 then
                Log:f("%s  constants(%d):", indent, #d.constants)
                for _, c in ipairs(d.constants) do
                    if c.type == "string" then
                        Log:f('%s    [%d] "%s"', indent, c.index, Utils.escapeJSON(Utils.truncate(c.value, 120)))
                    elseif c.type == "number" or c.type == "boolean" then
                        Log:f("%s    [%d] %s", indent, c.index, tostring(c.value))
                    end
                end
            end
            if #d.upvalues > 0 then
                Log:f("%s  upvalues(%d):", indent, #d.upvalues)
                for _, u in ipairs(d.upvalues) do
                    if u.type == "string" then
                        Log:f('%s    [%d] "%s"', indent, u.index, Utils.escapeJSON(Utils.truncate(u.value, 80)))
                    elseif u.type == "function" then
                        Log:f("%s    [%d] function", indent, u.index)
                    elseif u.type == "table" then
                        Log:f("%s    [%d] table", indent, u.index)
                    else
                        Log:f("%s    [%d] (%s) %s", indent, u.index, u.type, Utils.safeStr(u.value))
                    end
                end
            end
            if #d.protos > 0 then
                Log:f("%s  sub-protos: %d", indent, #d.protos)
            end
        end
    end

    -- Strings report
    Log:section(("CAPTURED STRINGS (%d unique)"):format(Strings.count))
    local bySrc = {}
    for _, e in ipairs(Strings.list) do
        bySrc[e.source] = bySrc[e.source] or {}
        table.insert(bySrc[e.source], e)
    end
    for src, entries in pairs(bySrc) do
        Log:f("  --- %s (%d) ---", src, #entries)
        for _, e in ipairs(entries) do
            Log:f('    [%04d] "%s"', e.idx, Utils.escapeJSON(Utils.truncate(e.value, 150)))
        end
    end

    -- Loadstring captures
    Log:section(("LOADSTRING CAPTURES (%d)"):format(LoadCaptures.count))
    for _, c in ipairs(LoadCaptures.list) do
        Log:f("  #%d (time:%s, %d bytes)", c.idx, c.time, c.len)
        Log:f("    %s", Utils.escapeJSON(Utils.truncate(c.preview, 300)))
    end

    -- Summary
    Log:section("SUMMARY")
    Log:f("  Functions scanned:   %d", FuncScan.count)
    Log:f("  Strings captured:    %d", Strings.count)
    Log:f("  Loadstring captures: %d", LoadCaptures.count)
    print(("[Dumper] Done! Functions: %d, Strings: %d, Loadstrings: %d"):format(
        FuncScan.count, Strings.count, LoadCaptures.count))

    -- 6) Send to Discord
    if SETTINGS.WebhookURL == "" then
        print("[Dumper] No webhook URL set, skipping Discord send")
        return
    end

    print("[Dumper] Sending to Discord...")

    -- Send summary embed
    local embed = {
        title = "Luraph VM Dump: " .. SETTINGS.ScriptName,
        color = SETTINGS.EmbedColor,
        fields = {
            { name = "Functions", value = tostring(FuncScan.count), inline = true },
            { name = "Strings", value = tostring(Strings.count), inline = true },
            { name = "Loadstrings", value = tostring(LoadCaptures.count), inline = true },
        },
        footer = { text = "Luraph Dumper AIO | " .. Utils.timestamp() },
    }

    -- Add string preview to embed
    local preview = {}
    local previewCount = 0
    for _, e in ipairs(Strings.list) do
        if previewCount >= 15 then break end
        local s = e.value
        if #s > 3 and #s < 100 then
            previewCount = previewCount + 1
            preview[previewCount] = "`" .. Utils.truncate(s, 50) .. "`"
        end
    end
    if previewCount > 0 then
        table.insert(embed.fields, {
            name = "String Preview (" .. previewCount .. ")",
            value = table.concat(preview, "\n"),
            inline = false,
        })
    end

    sendEmbed(embed)
    delayFn(1.5)

    -- Send dump in chunks
    local fullDump = Log:get()
    local chunks = {}
    local remaining = fullDump
    while #remaining > 0 do
        if #remaining <= SETTINGS.MaxChunkSize then
            table.insert(chunks, remaining); break
        end
        local splitAt = SETTINGS.MaxChunkSize
        local nl = remaining:sub(1, splitAt):find("\n[^\n]*$")
        if nl and nl > splitAt * 0.5 then splitAt = nl end
        table.insert(chunks, remaining:sub(1, splitAt))
        remaining = remaining:sub(splitAt + 1)
    end

    for i, chunk in ipairs(chunks) do
        local header = ("**[%d/%d]** `%s`"):format(i, #chunks, SETTINGS.ScriptName)
        local msg = header .. "\n```lua\n" .. chunk .. "\n```"
        if #msg > 2000 then
            msg = header .. "\n```lua\n" .. chunk:sub(1, 1850 - #header) .. "\n...cut\n```"
        end
        sendMessage(msg)
        delayFn(1.5)
    end

    print(("[Dumper] Sent %d chunks to Discord!"):format(#chunks))

    -- Also try to save file locally if possible
    local wf = writefile or (syn and syn.writefile)
    if wf then
        pcall(function()
            wf("LuraphDump_" .. Utils.timestamp() .. ".lua", fullDump)
            print("[Dumper] Also saved to local file")
        end)
    end

    print("[Dumper] ALL DONE!")
end

-- Run
main()
