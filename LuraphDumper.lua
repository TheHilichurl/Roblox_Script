--[[
    ================================================================
    =  Luraph VM True Memory Dumper (Post-Execution Snapshot)      =
    =  Giải quyết triệt để vấn đề spam webhook & bẫy vòng lặp      =
    =                                                              =
    =  CƠ CHẾ HOẠT ĐỘNG CHUẨN XÁC:                                 =
    =   1. Bạn chạy script này trên Delta X / Executor.            =
    =   2. Màn hình hiện bảng điều khiển và nút [BẮT ĐẦU ĐỌC RAM].  =
    =   3. Bạn chạy script hack/game (BananaCat, Quantum, v.v.).   =
    =   4. Đợi script game chạy xong/bung menu hoàn toàn (5-15s).  =
    =   5. BẤM NÚT [BẮT ĐẦU ĐỌC RAM] (hoặc bật Tự động sau 15s)    =
    =      -> Dumper chụp toàn bộ Snapshot RAM một lần duy nhất.   =
    =      -> Lọc ra toàn bộ hàm, hằng số, API, webhook, logic.    =
    =      -> Gửi đúng 1 lần duy nhất về Discord Webhook!          =
    ================================================================
--]]

-- ╔═══════════════════════════════════════════════════╗
-- ║  CẤU HÌNH (SETTINGS)                              ║
-- ╚═══════════════════════════════════════════════════╝
local CONFIG = {
    -- Discord Webhook URL để nhận kết quả dump
    WebhookURL = "https://discord.com/api/webhooks/1540742443459416074/OoigNnHKVnNmTh9unbAqX4hEyE7o7e2p9HM7P5Hob1_cEemOFY_0OMIE9SbO9JHGhKI5",

    -- Tên bot hiển thị
    BotName = "Luraph Post-Execution Dumper",

    -- Tự động kích hoạt đọc RAM sau X giây (0 = Tắt tự động, chỉ đọc khi bấm nút)
    -- Khuyên dùng 15-20s nếu muốn hoàn toàn tự động để script mục tiêu chạy xong
    AutoDumpAfterSeconds = 0,

    -- Lọc độ dài chuỗi tối thiểu
    MinStringLength = 3,

    -- Giới hạn độ dài mỗi tin nhắn Discord
    MaxChunkSize = 1750,
}

-- ╔═══════════════════════════════════════════════════╗
-- ║  TIỆN ÍCH HỆ THỐNG                                ║
-- ╚═══════════════════════════════════════════════════╝
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
    for i = 1, math.min(#s, 40) do
        local b = s:byte(i)
        if b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then return false end
    end
    return true
end

local function trunc(s, n)
    n = n or 200
    if type(s) ~= "string" then return safeStr(s) end
    if #s <= n then return s end
    return s:sub(1, n) .. ("... [%d chars]"):format(#s)
end

-- Bộ mã hóa JSON độc lập
local function jsonEncode(v)
    local t = type(v)
    if v == nil then return "null"
    elseif t == "boolean" then return v and "true" or "false"
    elseif t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        return tostring(v)
    elseif t == "string" then return '"' .. escJSON(v) .. '"'
    elseif t == "table" then
        local isArray, maxIdx = true, 0
        for k in pairs(v) do
            if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then isArray = false; break end
            if k > maxIdx then maxIdx = k end
        end
        isArray = isArray and maxIdx == #v
        if isArray then
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

-- Bộ phát HTTP gửi Discord
local function postDiscord(url, body)
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
    if not fn then return false, "No HTTP" end
    local ok, r = pcall(fn)
    return ok, ok and "OK" or safeStr(r)
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  BỘ TRÍCH XUẤT MEMORY SNAPSHOT                    ║
-- ╚═══════════════════════════════════════════════════╝
local DumpSession = {
    IsDumping = false,
    FunctionsFound = 0,
    StringsFound = 0,
    InterestingKeywords = {},
    CollectedStrings = {},
    CollectedStringsList = {},
    FunctionSignatures = {},
}

-- Phân loại chuỗi quan trọng (Remote, Webhook, Url, Script name, API)
local function categorizeString(str)
    local sLower = str:lower()
    if sLower:find("http://") or sLower:find("https://") or sLower:find("discord.com/api") or sLower:find("webhook") then
        return "URL/WEBHOOK"
    elseif sLower:find("fireserver") or sLower:find("invokeserver") or sLower:find("replicatedstorage") or sLower:find("remotefunction") or sLower:find("remoteevent") then
        return "ROBLOX_NETWORK"
    elseif sLower:find("autofarm") or sLower:find("fruit") or sLower:find("bounty") or sLower:find("teleport") or sLower:find("player") or sLower:find("tween") or sLower:find("bring") then
        return "GAME_FEATURE"
    elseif sLower:find("key") or sLower:find("auth") or sLower:find("hwid") or sLower:find("token") or sLower:find("license") then
        return "AUTH_KEY"
    end
    return nil
end

local function addDumpString(str, src)
    if type(str) ~= "string" or #str < CONFIG.MinStringLength then return end
    if DumpSession.CollectedStrings[str] then return end
    if not isPrintable(str) and #str > 60 then return end
    
    DumpSession.CollectedStrings[str] = true
    DumpSession.StringsFound = DumpSession.StringsFound + 1
    
    local cat = categorizeString(str)
    if cat then
        table.insert(DumpSession.InterestingKeywords, { val = str, category = cat, src = src })
    end

    table.insert(DumpSession.CollectedStringsList, {
        val = str,
        src = src or "ram",
        idx = DumpSession.StringsFound
    })
end

local scannedFunctions = {}
local function scanClosure(fn, depth, path)
    depth = depth or 0
    if depth > 6 or type(fn) ~= "function" then return end
    local key = tostring(fn)
    if scannedFunctions[key] then return end
    scannedFunctions[key] = true

    if islclosure and not islclosure(fn) then return end
    if iscclosure and iscclosure(fn) then return end

    DumpSession.FunctionsFound = DumpSession.FunctionsFound + 1
    local funcId = DumpSession.FunctionsFound

    local funcInfo = nil
    pcall(function() funcInfo = debug.getinfo(fn) end)

    local funcConsts = {}
    local funcUpvals = {}

    -- Đọc Constants
    if debug and debug.getconstants then
        pcall(function()
            for i, v in pairs(debug.getconstants(fn)) do
                if type(v) == "string" then
                    addDumpString(v, ("const@f%d[%d]"):format(funcId, i))
                    table.insert(funcConsts, ('"%s"'):format(escJSON(trunc(v, 40))))
                elseif type(v) == "number" or type(v) == "boolean" then
                    table.insert(funcConsts, tostring(v))
                end
            end
        end)
    end

    -- Đọc Upvalues
    if debug and debug.getupvalues then
        pcall(function()
            for i, v in pairs(debug.getupvalues(fn)) do
                if type(v) == "string" then
                    addDumpString(v, ("upval@f%d[%d]"):format(funcId, i))
                    table.insert(funcUpvals, ('"%s"'):format(escJSON(trunc(v, 40))))
                elseif type(v) == "function" then
                    scanClosure(v, depth + 1, path .. ".up[" .. i .. "]")
                end
            end
        end)
    end

    -- Đọc Protos con
    if debug and debug.getprotos then
        pcall(function()
            for i, p in pairs(debug.getprotos(fn)) do
                scanClosure(p, depth + 1, path .. ".proto[" .. i .. "]")
            end
        end)
    end

    -- Lưu lại cấu trúc hàm nếu có dữ liệu
    if #funcConsts > 0 or #funcUpvals > 0 then
        table.insert(DumpSession.FunctionSignatures, {
            id = funcId,
            src = funcInfo and (funcInfo.short_src or "") or "",
            line = funcInfo and (funcInfo.linedefined or 0) or 0,
            consts = funcConsts,
            upvals = funcUpvals
        })
    end
end

-- Chụp toàn bộ bộ nhớ GC
local function takeMemorySnapshot()
    if not getgc then
        print("[Dumper] LỖI: Executor không hỗ trợ getgc!")
        return
    end

    print("[Dumper] Bắt đầu chụp toàn bộ RAM...")
    local ok, objs = pcall(getgc, true)
    if not ok or type(objs) ~= "table" then return end

    local totalObjs = #objs
    print(("[Dumper] Tìm thấy %d đối tượng trong RAM. Đang lọc..."):format(totalObjs))

    for i = 1, totalObjs do
        local o = objs[i]
        if type(o) == "function" then
            scanClosure(o, 0, "fn")
        elseif type(o) == "table" then
            pcall(function()
                for k, v in pairs(o) do
                    if type(v) == "string" then addDumpString(v, "tbl_val")
                    elseif type(v) == "function" then scanClosure(v, 0, "tbl_fn") end
                    if type(k) == "string" then addDumpString(k, "tbl_key") end
                end
            end)
        end
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  BẮN DỮ LIỆU ĐÃ DUMP VỀ DISCORD (1 LẦN DUY NHẤT)  ║
-- ╚═══════════════════════════════════════════════════╝
local function sendMemoryDumpToDiscord()
    if CONFIG.WebhookURL == "" then
        print("[Dumper] LỖI: Chưa có WebhookURL!")
        return
    end

    print("[Dumper] Đang đóng gói dữ liệu và gửi lên Discord...")

    -- 1. Embed Tổng quan & Phát hiện Quan trọng
    local embed = {
        title = "📦 HOÀN TẤT DUMP BỘ NHỚ RAM (SNAPSHOT)",
        description = ("Thời gian chụp: `%s`\nTrạng thái: **Đã lọc & Trích xuất toàn vẹn**"):format(os.date and os.date("%c") or "N/A"),
        color = 0x5865F2,
        fields = {
            { name = "🧩 Functions Trích Xuất", value = ("**%d** hàm"):format(DumpSession.FunctionsFound), inline = true },
            { name = "📝 Strings Thu Thập", value = ("**%d** chuỗi"):format(DumpSession.StringsFound), inline = true },
            { name = "🔑 Dữ Liệu Đặc Biệt", value = ("**%d** mục"):format(#DumpSession.InterestingKeywords), inline = true },
        },
        footer = { text = "Luraph Post-Execution Memory Dumper v5" }
    }

    -- Hiển thị các URL/Webhook/Remote tìm thấy trong RAM
    if #DumpSession.InterestingKeywords > 0 then
        local keyList = {}
        for i, item in ipairs(DumpSession.InterestingKeywords) do
            if i > 10 then break end
            table.insert(keyList, ("• `[%s]` %s"):format(item.category, trunc(item.val, 55)))
        end
        table.insert(embed.fields, {
            name = "🎯 Các Chuỗi Trọng Tâm Tìm Thấy (URLs/Remotes/Keys):",
            value = table.concat(keyList, "\n"),
            inline = false
        })
    end

    postDiscord(CONFIG.WebhookURL, jsonEncode({
        username = CONFIG.BotName,
        embeds = { embed }
    }))

    if task and task.wait then task.wait(1.5) elseif wait then wait(1.5) end

    -- 2. Gửi Cấu Trúc Functions (Constants & Upvalues)
    if #DumpSession.FunctionSignatures > 0 then
        local fnLines = { "-- ==========================================", "-- CẤU TRÚC LOGIC & CONSTANTS CÁC HÀM TRONG RAM", "-- ==========================================" }
        for i, fn in ipairs(DumpSession.FunctionSignatures) do
            if i > 250 then break end -- Giới hạn 250 hàm rõ nhất
            table.insert(fnLines, ("\nFunction #%d:"):format(fn.id))
            if #fn.consts > 0 then
                table.insert(fnLines, "  Constants: " .. table.concat(fn.consts, ", "))
            end
            if #fn.upvals > 0 then
                table.insert(fnLines, "  Upvalues:  " .. table.concat(fn.upvals, ", "))
            end
        end

        local fnText = table.concat(fnLines, "\n")
        local remFn = fnText
        local pIdx = 1
        while #remFn > 0 do
            local sub = remFn:sub(1, CONFIG.MaxChunkSize)
            local nl = sub:find("\n[^\n]*$")
            if nl and nl > CONFIG.MaxChunkSize * 0.5 then sub = remFn:sub(1, nl); remFn = remFn:sub(nl + 1)
            else remFn = remFn:sub(CONFIG.MaxChunkSize + 1) end

            local msg = ("**[Cấu Trúc Hàm & Logic Phần %d]**\n```lua\n%s\n```"):format(pIdx, sub)
            postDiscord(CONFIG.WebhookURL, jsonEncode({ username = CONFIG.BotName, content = msg }))
            pIdx = pIdx + 1
            if task and task.wait then task.wait(1.2) elseif wait then wait(1.2) end
        end
    end

    -- 3. Gửi Toàn Bộ Strings giải mã được trong RAM
    if DumpSession.StringsFound > 0 then
        local strLines = { "-- ==========================================", "-- TOÀN BỘ CHUỖI ĐÃ GIẢI MÃ TỒN TẠI TRONG RAM", "-- ==========================================" }
        for i, s in ipairs(DumpSession.CollectedStringsList) do
            table.insert(strLines, ('[%04d] "%s"'):format(i, escJSON(trunc(s.val, 150))))
        end

        local fullStrText = table.concat(strLines, "\n")
        local remStr = fullStrText
        local sIdx = 1

        while #remStr > 0 do
            local sub = remStr:sub(1, CONFIG.MaxChunkSize)
            local nl = sub:find("\n[^\n]*$")
            if nl and nl > CONFIG.MaxChunkSize * 0.5 then sub = remStr:sub(1, nl); remStr = remStr:sub(nl + 1)
            else remStr = remStr:sub(CONFIG.MaxChunkSize + 1) end

            local msg = ("**[Danh Sách Strings Phần %d]**\n```lua\n%s\n```"):format(sIdx, sub)
            postDiscord(CONFIG.WebhookURL, jsonEncode({ username = CONFIG.BotName, content = msg }))
            sIdx = sIdx + 1
            if task and task.wait then task.wait(1.2) elseif wait then wait(1.2) end
        end
    end

    print("[Dumper] ✅ ĐÃ GỬI XONG TOÀN BỘ SNAPSHOT VỀ DISCORD!")
end

-- Hàm kích hoạt quá trình Dump
local function triggerDumpProcess(statusBtn)
    if DumpSession.IsDumping then return end
    DumpSession.IsDumping = true

    if statusBtn then
        statusBtn.Text = "⏳ Đang đọc RAM (Xin chờ 3s)..."
        statusBtn.BackgroundColor3 = Color3.fromRGB(220, 140, 30)
    end

    task.spawn(function()
        takeMemorySnapshot()
        sendMemoryDumpToDiscord()

        if statusBtn then
            statusBtn.Text = ("✅ ĐÃ GỬI DISCORD (%d Strings)"):format(DumpSession.StringsFound)
            statusBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
            if task and task.wait then task.wait(4) end
            statusBtn.Text = "🚀 BẮT ĐẦU ĐỌC RAM & GỬI DISCORD"
            statusBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            DumpSession.IsDumping = false
        end
    end)
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  BẢNG ĐIỀU KHIỂN NÚT BẤM (GUI TRÊN MÀN HÌNH)     ║
-- ╚═══════════════════════════════════════════════════╝
local function createDumperControllerUI()
    pcall(function()
        local CoreGui = game:GetService("CoreGui") or (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))
        if not CoreGui then return end

        local old = CoreGui:FindFirstChild("LuraphSnapshotUI")
        if old then old:Destroy() end

        local sg = Instance.new("ScreenGui")
        sg.Name = "LuraphSnapshotUI"
        sg.ResetOnSpawn = false
        sg.Parent = CoreGui

        local frame = Instance.new("Frame", sg)
        frame.Size = UDim2.new(0, 230, 0, 95)
        frame.Position = UDim2.new(0.02, 0, 0.4, 0)
        frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
        frame.Active = true
        frame.Draggable = true

        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 8)

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1, 0, 0, 22)
        title.Position = UDim2.new(0, 0, 0, 4)
        title.Text = "🛡️ Luraph Memory Dumper"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 12
        title.BackgroundTransparency = 1

        local sub = Instance.new("TextLabel", frame)
        sub.Size = UDim2.new(1, 0, 0, 18)
        sub.Position = UDim2.new(0, 0, 0, 24)
        sub.Text = "Chạy script game xong -> Bấm nút dưới"
        sub.TextColor3 = Color3.fromRGB(160, 220, 160)
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.BackgroundTransparency = 1

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(1, -16, 0, 36)
        btn.Position = UDim2.new(0, 8, 0, 48)
        btn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        btn.Text = "🚀 BẮT ĐẦU ĐỌC RAM & GỬI DISCORD"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            triggerDumpProcess(btn)
        end)
    end)
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  KHỞI ĐỘNG VÀ ĐỢI SỰ KIỆN                         ║
-- ╚═══════════════════════════════════════════════════╝
print("==================================================")
print("  Luraph True Memory Dumper v5 - SẴN SÀNG        ")
print("==================================================")

createDumperControllerUI()
print("[Dumper] ✅ Đã hiển thị Bảng điều khiển trên màn hình Roblox!")
print("[Dumper] 💡 HƯỚNG DẪN:")
print("  1. Hãy chạy script game bạn muốn lấy dữ liệu.")
print("  2. Đợi script game bung menu/chạy xong ổn định.")
print("  3. Bấm nút [BẮT ĐẦU ĐỌC RAM & GỬI DISCORD] trên màn hình!")

-- Chế độ tự động nếu đặt AutoDumpAfterSeconds > 0
if CONFIG.AutoDumpAfterSeconds > 0 then
    task.spawn(function()
        print(("[Dumper] Đang đếm ngược tự động: %d giây..."):format(CONFIG.AutoDumpAfterSeconds))
        if task and task.wait then task.wait(CONFIG.AutoDumpAfterSeconds) elseif wait then wait(CONFIG.AutoDumpAfterSeconds) end
        print("[Dumper] Hết thời gian chờ, tự động kích hoạt đọc RAM...")
        triggerDumpProcess()
    end)
end
