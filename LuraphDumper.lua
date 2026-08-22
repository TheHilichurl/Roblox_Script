--[[
    ================================================================
    =  Luraph VM JSON Chunk Exporter (Multipart Attachment Mode)   =
    =  Gửi File JSON đính kèm (File Attachment) qua Discord Webhook=
    =                                                              =
    =  ĐẶC ĐIỂM:                                                   =
    =   1. Toàn bộ Bytecode, Functions, Constants, Strings được    =
    =      đóng gói thành định dạng JSON chuẩn.                    =
    =   2. Chia thành các file JSON (mỗi file tối đa ~7MB để an    =
    =      toàn với giới hạn 8MB của Discord và tránh lag RAM).    =
    =   3. Gửi thẳng file JSON đính kèm (.json) qua Webhook.       =
    =   4. Trên PC chỉ cần 1 script Python nhỏ là gộp lại thành   =
    =      1 file Bytecode hoàn chỉnh 100%!                        =
    ================================================================
--]]

-- ╔═══════════════════════════════════════════════════╗
-- ║  CẤU HÌNH (SETTINGS)                              ║
-- ╚═══════════════════════════════════════════════════╝
local CONFIG = {
    -- Discord Webhook URL
    WebhookURL = "https://discord.com/api/webhooks/1540742443459416074/OoigNnHKVnNmTh9unbAqX4hEyE7o7e2p9HM7P5Hob1_cEemOFY_0OMIE9SbO9JHGhKI5",

    -- Tên file xuất ra trên Discord (ví dụ: BananaCat_Part1.json)
    FileBaseName = "BytecodeDump",

    -- Kích thước tối đa mỗi file JSON (Byte). 
    -- 7 * 1024 * 1024 = 7.340.032 Bytes (~7MB an toàn dưới mốc 8MB của Discord)
    MaxFileSizeLimit = 7 * 1024 * 1024,

    -- Lọc độ dài chuỗi tối thiểu
    MinStringLength = 2,
}

-- ╔═══════════════════════════════════════════════════╗
-- ║  TIỆN ÍCH HỆ THỐNG & JSON                         ║
-- ╚═══════════════════════════════════════════════════╝
local function safeStr(v)
    local ok, r = pcall(tostring, v)
    return ok and r or "<?>"
end

local function escJSON(s)
    if type(s) ~= "string" then return safeStr(s) end
    return s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t'):gsub('[%c]', function(c) return ('\\u%04X'):format(c:byte()) end)
end

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

-- ╔═══════════════════════════════════════════════════╗
-- ║  HTTP MULTIPART UPLOADER CHO DISCORD              ║
-- ╚═══════════════════════════════════════════════════╝
local function sendDiscordFile(filename, fileContent, partIndex, totalParts)
    local boundary = "------------------------" .. tostring(math.floor(tick() * 1000)) .. tostring(math.random(10000, 99999))
    
    local payloadParts = {
        "--" .. boundary,
        'Content-Disposition: form-data; name="payload_json"',
        'Content-Type: application/json',
        '',
        jsonEncode({
            username = "Luraph Bytecode Exporter",
            content = ("📦 **[Bytecode File Attachment %d/%d]**\n📄 Tên file: `%s`\n📊 Kích thước: `%.2f MB`"):format(
                partIndex, totalParts, filename, #fileContent / (1024 * 1024)
            )
        }),
        "--" .. boundary,
        ('Content-Disposition: form-data; name="file"; filename="%s"'):format(filename),
        'Content-Type: application/json',
        '',
        fileContent,
        "--" .. boundary .. "--",
        ""
    }
    
    local rawBody = table.concat(payloadParts, "\r\n")
    local contentType = "multipart/form-data; boundary=" .. boundary

    local fn
    if syn and syn.request then
        fn = function() return syn.request({ Url = CONFIG.WebhookURL, Method = "POST", Headers = { ["Content-Type"] = contentType }, Body = rawBody }) end
    elseif request then
        fn = function() return request({ Url = CONFIG.WebhookURL, Method = "POST", Headers = { ["Content-Type"] = contentType }, Body = rawBody }) end
    elseif http_request then
        fn = function() return http_request({ Url = CONFIG.WebhookURL, Method = "POST", Headers = { ["Content-Type"] = contentType }, Body = rawBody }) end
    end

    if not fn then
        print("[Exporter] LỖI: Executor không hỗ trợ request() multipart!")
        return false
    end

    local ok, res = pcall(fn)
    if ok then
        print(("[Exporter] ✅ Đã gửi thành công %s (%.2f MB) lên Discord!"):format(filename, #fileContent / (1024 * 1024)))
        return true
    else
        print("[Exporter] ❌ Lỗi gửi file: " .. safeStr(res))
        return false
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  BỘ CHỤP TOÀN BỘ CẤU TRÚC RAM & BYTECODE           ║
-- ╚═══════════════════════════════════════════════════╝
local DumpVault = {
    Functions = {},
    Strings = {},
    StringsLookup = {},
    TotalFuncCount = 0,
    TotalStringCount = 0,
}

local scannedFuncMap = {}

local function scanFunctionObject(fn, depth, path)
    depth = depth or 0
    if depth > 8 or type(fn) ~= "function" then return end
    local key = tostring(fn)
    if scannedFuncMap[key] then return end
    scannedFuncMap[key] = true

    if islclosure and not islclosure(fn) then return end
    if iscclosure and iscclosure(fn) then return end

    DumpVault.TotalFuncCount = DumpVault.TotalFuncCount + 1
    local funcId = DumpVault.TotalFuncCount

    local fInfo = nil
    pcall(function() fInfo = debug.getinfo(fn) end)

    local funcConstants = {}
    local funcUpvalues = {}
    local funcProtosCount = 0

    -- Constants
    if debug and debug.getconstants then
        pcall(function()
            local cList = debug.getconstants(fn)
            for idx, cVal in pairs(cList) do
                table.insert(funcConstants, {
                    index = idx,
                    type = type(cVal),
                    value = cVal
                })
                if type(cVal) == "string" and #cVal >= CONFIG.MinStringLength and not DumpVault.StringsLookup[cVal] then
                    DumpVault.StringsLookup[cVal] = true
                    DumpVault.TotalStringCount = DumpVault.TotalStringCount + 1
                    table.insert(DumpVault.Strings, { id = DumpVault.TotalStringCount, val = cVal, src = "const" })
                end
            end
        end)
    end

    -- Upvalues
    if debug and debug.getupvalues then
        pcall(function()
            local uList = debug.getupvalues(fn)
            for idx, uVal in pairs(uList) do
                local uType = type(uVal)
                table.insert(funcUpvalues, {
                    index = idx,
                    type = uType,
                    value = (uType == "string" or uType == "number" or uType == "boolean") and uVal or safeStr(uVal)
                })
                if uType == "string" and #uVal >= CONFIG.MinStringLength and not DumpVault.StringsLookup[uVal] then
                    DumpVault.StringsLookup[uVal] = true
                    DumpVault.TotalStringCount = DumpVault.TotalStringCount + 1
                    table.insert(DumpVault.Strings, { id = DumpVault.TotalStringCount, val = uVal, src = "upval" })
                elseif uType == "function" then
                    scanFunctionObject(uVal, depth + 1, path .. ".up[" .. idx .. "]")
                end
            end
        end)
    end

    -- Protos
    if debug and debug.getprotos then
        pcall(function()
            local pList = debug.getprotos(fn)
            funcProtosCount = #pList
            for idx, pFn in pairs(pList) do
                scanFunctionObject(pFn, depth + 1, path .. ".proto[" .. idx .. "]")
            end
        end)
    end

    table.insert(DumpVault.Functions, {
        id = funcId,
        path = path,
        depth = depth,
        source = fInfo and (fInfo.short_src or "") or "",
        line = fInfo and (fInfo.linedefined or 0) or 0,
        numparams = fInfo and (fInfo.numparams or 0) or 0,
        constants = funcConstants,
        upvalues = funcUpvalues,
        protos_count = funcProtosCount
    })
end

local function captureMemory()
    if not getgc then return end
    print("[Exporter] Đang quét GC Memory...")
    local ok, objs = pcall(getgc, true)
    if not ok or type(objs) ~= "table" then return end

    for i = 1, #objs do
        local o = objs[i]
        if type(o) == "function" then
            scanFunctionObject(o, 0, "fn_" .. i)
        elseif type(o) == "table" then
            pcall(function()
                for k, v in pairs(o) do
                    if type(v) == "string" and #v >= CONFIG.MinStringLength and not DumpVault.StringsLookup[v] then
                        DumpVault.StringsLookup[v] = true
                        DumpVault.TotalStringCount = DumpVault.TotalStringCount + 1
                        table.insert(DumpVault.Strings, { id = DumpVault.TotalStringCount, val = v, src = "tbl_val" })
                    elseif type(v) == "function" then
                        scanFunctionObject(v, 0, "tbl_fn")
                    end
                end
            end)
        end
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  BỘ CHIA FILE JSON & GỬI TỰ ĐỘNG                  ║
-- ╚═══════════════════════════════════════════════════╝
local function buildAndExportJSON()
    print("[Exporter] 🚀 Đang khởi tạo toàn bộ Snapshot...")
    captureMemory()
    print(("[Exporter] Đã gom được %d hàm và %d chuỗi. Bắt đầu đóng gói JSON..."):format(DumpVault.TotalFuncCount, DumpVault.TotalStringCount))

    -- Đóng gói dữ liệu thành các packages nhỏ nếu quá lớn
    local allFunctions = DumpVault.Functions
    local allStrings = DumpVault.Strings

    local jsonPackages = {}
    local currentPackage = {
        metadata = {
            session_id = tostring(math.floor(tick())),
            timestamp = os.date and os.date("%c") or "N/A",
            total_functions = DumpVault.TotalFuncCount,
            total_strings = DumpVault.TotalStringCount,
        },
        functions = {},
        strings = (allStrings) -- Đưa strings vào gói đầu tiên
    }

    local currentPackageSize = 0

    for i = 1, #allFunctions do
        local fnObj = allFunctions[i]
        table.insert(currentPackage.functions, fnObj)
        
        -- Cứ mỗi 150 hàm, kiểm tra dung lượng chuỗi JSON một lần
        if i % 150 == 0 or i == #allFunctions then
            local testJson = jsonEncode(currentPackage)
            if #testJson >= CONFIG.MaxFileSizeLimit or i == #allFunctions then
                table.insert(jsonPackages, testJson)
                -- Tạo package mới cho các hàm tiếp theo
                currentPackage = {
                    metadata = {
                        session_id = tostring(math.floor(tick())),
                        part = #jsonPackages + 1,
                    },
                    functions = {},
                    strings = {} -- Các gói sau không cần gửi lại strings
                }
            end
        end
    end

    if #jsonPackages == 0 then
        table.insert(jsonPackages, jsonEncode(currentPackage))
    end

    local totalParts = #jsonPackages
    print(("[Exporter] Đã phân tách thành %d file JSON (< 7MB/file). Bắt đầu truyền dữ liệu..."):format(totalParts))

    for partIdx, jsonStr in ipairs(jsonPackages) do
        local fileName = ("%s_Part%d_of_%d.json"):format(CONFIG.FileBaseName, partIdx, totalParts)
        sendDiscordFile(fileName, jsonStr, partIdx, totalParts)
        if task and task.wait then task.wait(2.5) elseif wait then wait(2.5) end
    end

    print("[Exporter] 🎉 ĐÃ TRUYỀN TOÀN BỘ FILE BYTECODE JSON XONG!")
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  GIAO DIỆN NÚT BẤM KÍCH HOẠT XUẤT JSON            ║
-- ╚═══════════════════════════════════════════════════╝
local function createExportUI()
    pcall(function()
        local CoreGui = game:GetService("CoreGui") or (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))
        if not CoreGui then return end

        local old = CoreGui:FindFirstChild("LuraphJsonExportUI")
        if old then old:Destroy() end

        local sg = Instance.new("ScreenGui")
        sg.Name = "LuraphJsonExportUI"
        sg.ResetOnSpawn = false
        sg.Parent = CoreGui

        local frame = Instance.new("Frame", sg)
        frame.Size = UDim2.new(0, 240, 0, 100)
        frame.Position = UDim2.new(0.02, 0, 0.4, 0)
        frame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
        frame.Active = true
        frame.Draggable = true

        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 8)

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1, 0, 0, 24)
        title.Position = UDim2.new(0, 0, 0, 4)
        title.Text = "📁 Luraph JSON Exporter (7MB Chunks)"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 11
        title.BackgroundTransparency = 1

        local sub = Instance.new("TextLabel", frame)
        sub.Size = UDim2.new(1, 0, 0, 18)
        sub.Position = UDim2.new(0, 0, 0, 26)
        sub.Text = "Chạy script game xong -> Bấm xuất File"
        sub.TextColor3 = Color3.fromRGB(150, 255, 170)
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.BackgroundTransparency = 1

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(1, -16, 0, 38)
        btn.Position = UDim2.new(0, 8, 0, 50)
        btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        btn.Text = "📤 XUẤT FILE JSON & GỬI DISCORD"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 6)

        local isExporting = false
        btn.MouseButton1Click:Connect(function()
            if isExporting then return end
            isExporting = true
            btn.Text = "⏳ Đang đóng gói JSON (Xin chờ)..."
            btn.BackgroundColor3 = Color3.fromRGB(230, 150, 40)
            
            task.spawn(function()
                buildAndExportJSON()
                btn.Text = "✅ ĐÃ GỬI XONG CÁC FILE JSON!"
                btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
                if task and task.wait then task.wait(4) end
                btn.Text = "📤 XUẤT FILE JSON & GỬI DISCORD"
                btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                isExporting = false
            end)
        end)
    end)
end

-- Khởi động
print("==================================================")
print("  Luraph JSON Chunk Exporter - SẴN SÀNG          ")
print("==================================================")
createExportUI()
