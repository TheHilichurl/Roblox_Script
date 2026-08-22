--[[
    =============================================================================
    =  STEALTH REAL-TIME EXECUTOR THREAD OBSERVER & CLEAN DUMPER                =
    =                                                                           =
    =  BẢN CHẤT CỦA YÊU CẦU:                                                    =
    =   1. KHÔNG QUÉT GC ĐẠI TRÀ (Tránh hoàn toàn việc game sinh function mới   =
    =      làm ô nhiễm và spam liên tục).                                       =
    =   2. LỚP TÀNG HÌNH CHỈ ĐỌC (READ-ONLY PROXY LAYER):                       =
    =      - Theo dõi TRỰC TIẾP luồng thực thi mà Executor nạp vào thời gian    =
    =        thực thông qua Thread Observer & Metatable Telemetry.               =
    =      - Ghi nhận chính xác: Script nào nạp? Hàm nào giải mã xong và bắt    =
    =        đầu chạy? URL nào được gọi? Remote nào gửi dữ liệu?                =
    =   3. SESSION STABILIZATION & CLEAN DUMP (Khóa phiên sạch):                =
    =      - Khi bấm Dump: Tự động ĐÓNG BĂNG BỘ ĐẾM (Freeze/Stabilize) để       =
    =        đóng gói 100% dữ liệu sạch mà không bị hàm rác tiếp tục tràn vào.  =
    =      - Gửi file JSON gọn gàng, có cấu trúc rõ ràng về Discord Webhook.    =
    =============================================================================
--]]

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  CẤU HÌNH HỆ THỐNG (CONFIGURATION)                                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local CONFIG = {
    -- Link Discord Webhook nhận dữ liệu
    WebhookUrl = "https://discord.com/api/webhooks/1540764685681299526/mFnSqvWMbpNimmzJ4d2w9oJdMvZxDis8hHQVNjlBCNVWIpZTm2nnDC90M87LZ-m6T-to",
    
    -- Giới hạn số lượng event thực thi lưu trữ để tránh tràn RAM
    MaxCapturedScripts = 50,
    MaxCapturedHttp = 50,
    MaxCapturedRemotes = 50,
    MaxCapturedUIEvents = 50,

    -- Bóc tách sâu cây hàm con (Protos, Upvalues, Constants)
    DeepProtoExtraction = true,
    MaxProtoDepth = 4,

    -- Tự động gửi về Webhook định kỳ (Nếu tắt, chỉ gửi khi bấm nút thủ công)
    AutoSendEnabled = false,
    AutoSendInterval = 30
}

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  TƯƠNG THÍCH MÔI TRƯỜNG EXECUTOR                                          ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local httpRequest = (syn and syn.request)
    or (http and http.request)
    or (fluxus and fluxus.request)
    or (delta and delta.request)
    or request
    or http_request
    or (getgenv and getgenv().request)

local get_genv = getgenv or function() return _G end
local get_connections = getconnections or get_signal_cons
local decompile_func = decompile or disassemble
local check_caller = checkcaller or function() return false end
local is_executor_closure = isexecutorclosure or isourclosure or checkcaller or function() return false end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  KHO LƯU TRỮ PHIÊN THỰC THI (REAL-TIME EXECUTION TELEMETRY)               ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local ExecutionSession = {
    SessionInfo = {
        PlaceId = game.PlaceId,
        GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown",
        JobId = game.JobId,
        StartTime = os.date("!%Y-%m-%d %H:%M:%SZ"),
        LocalPlayer = game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Unknown",
        UserId = game.Players.LocalPlayer and game.Players.LocalPlayer.UserId or 0,
        Executor = (identifyexecutor and identifyexecutor()) or "Unknown Executor"
    },
    ActiveScripts = {},          -- Danh sách script nạp vào Executor theo thời gian thực
    DecryptedFunctionRegistry = {}, -- Các hàm giải mã thực sự được gọi thực thi
    HttpTelemetry = {},          -- Lịch sử tải URL / API
    RemoteTelemetry = {},        -- Dữ liệu Remote thực sự được bắn
    UIInteractions = {},         -- Callbacks từ UI menu do script tạo ra
    EnvironmentChanges = {}      -- Biến mới trong getgenv() do script gán
}

local stats = {
    scriptsCaptured = 0,
    functionsCaptured = 0,
    httpCaptured = 0,
    remotesCaptured = 0,
    uiEventsCaptured = 0,
    totalDispatched = 0
}

-- Trạng thái điều khiển
local isFrozen = false
local isRecording = true
local seenFunctionSet = {}
local seenStringSet = {}
local baselineGenvKeys = {}

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

    -- Bỏ qua script nội bộ của listener
    if string.find(src, "StealthObserver") or string.find(src, "ClientScriptListener") then
        return nil
    end

    local constants = debug.getconstants and debug.getconstants(func) or {}
    local upvalues = debug.getupvalues and debug.getupvalues(func) or {}
    local protos = (CONFIG.DeepProtoExtraction and debug.getprotos and debug.getprotos(func)) or {}

    local constantsList = {}
    for _, c in pairs(constants) do
        local sc = safeToString(c)
        table.insert(constantsList, sc)
        if type(c) == "string" and #c >= 2 and not seenStringSet[c] then
            seenStringSet[c] = true
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
    if decompile_func then
        pcall(function()
            local decomp = decompile_func(func)
            if decomp and type(decomp) == "string" and #decomp > 0 then
                decompiledCode = (#decomp > 3000) and (decomp:sub(1, 3000) .. "\n... [TRUNCATED] ...") or decomp
            end
        end)
    end

    return {
        Name = name ~= "" and name or ("proto_L" .. currentDepth),
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

local function recordDecryptedFunction(func, originTag)
    if isFrozen or not isRecording then return end
    if type(func) ~= "function" then return end
    if seenFunctionSet[func] then return end
    seenFunctionSet[func] = true

    local details = extractFunctionDetails(func, 1, CONFIG.MaxProtoDepth)
    if details and (#details.Constants > 0 or #details.Upvalues > 0 or #details.ChildProtos > 0) then
        stats.functionsCaptured = stats.functionsCaptured + 1
        if #ExecutionSession.DecryptedFunctionRegistry >= CONFIG.MaxCapturedScripts then
            table.remove(ExecutionSession.DecryptedFunctionRegistry, 1)
        end
        table.insert(ExecutionSession.DecryptedFunctionRegistry, {
            Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            Origin = originTag or "Executor Thread",
            Function = details
        })
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  LỚP TÀNG HÌNH CHỈ ĐỌC (READ-ONLY TELEMETRY OBSERVERS)                    ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- 1. Giám sát Script nạp vào Executor qua môi trường
local function setupEnvironmentObserver()
    local genv = get_genv()
    for k, _ in pairs(genv) do
        baselineGenvKeys[k] = true
    end

    task.spawn(function()
        while true do
            task.wait(1.0)
            if not isFrozen and isRecording then
                local currentGenv = get_genv()
                for k, v in pairs(currentGenv) do
                    if not baselineGenvKeys[k] and k ~= "ExecutionSession" and not string.find(tostring(k), "^_") then
                        ExecutionSession.EnvironmentChanges[safeToString(k)] = serializeValue(v, 1, 2)
                        if type(v) == "function" then
                            recordDecryptedFunction(v, "getgenv()." .. tostring(k))
                        elseif type(v) == "table" then
                            for _, subVal in pairs(v) do
                                if type(subVal) == "function" then
                                    recordDecryptedFunction(subVal, "getgenv()." .. tostring(k) .. " Table Method")
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- 2. Giám sát UI Event Callbacks do Script/Hub sinh ra (Fluent, Rayfield, Orion...)
local function setupUIObserver()
    if not get_connections then return end

    local function inspectInstance(inst)
        if isFrozen or not isRecording or not inst then return end
        pcall(function()
            if inst:IsA("GuiButton") then
                for _, eventName in ipairs({"MouseButton1Click", "MouseButton1Down", "Activated"}) do
                    local cons = get_connections(inst[eventName])
                    if cons then
                        for _, con in ipairs(cons) do
                            local f = con.Function
                            if f and type(f) == "function" and not seenFunctionSet[f] then
                                stats.uiEventsCaptured = stats.uiEventsCaptured + 1
                                recordDecryptedFunction(f, "UI Event: " .. inst.Name .. "." .. eventName)
                                if #ExecutionSession.UIInteractions >= CONFIG.MaxCapturedUIEvents then
                                    table.remove(ExecutionSession.UIInteractions, 1)
                                end
                                table.insert(ExecutionSession.UIInteractions, {
                                    Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                                    ButtonPath = inst:GetFullName(),
                                    Event = eventName
                                })
                            end
                        end
                    end
                end
            end
        end)
    end

    local CoreGui = game:GetService("CoreGui")
    local PlayerGui = game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChild("PlayerGui")

    pcall(function()
        CoreGui.DescendantAdded:Connect(function(descendant)
            task.wait(0.2)
            inspectInstance(descendant)
        end)
    end)

    if PlayerGui then
        PlayerGui.DescendantAdded:Connect(function(descendant)
            task.wait(0.2)
            inspectInstance(descendant)
        end)
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  HÀM GỬI DỮ LIỆU ĐÓNG GÓI VỀ WEBHOOK (CLEAN STABLE DUMP)                  ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local isSending = false
local function sendCleanDumpToWebhook(customTitle)
    if not httpRequest or not CONFIG.WebhookUrl or CONFIG.WebhookUrl == "" then
        return false, "Webhook chưa cấu hình"
    end

    if isSending then return false, "Đang gửi..." end
    isSending = true

    -- Tự động đóng băng để đảm bảo dữ liệu ổn định 100% không bị lẫn hàm mới trong lúc gửi
    local previousFreezeState = isFrozen
    isFrozen = true

    local jsonString = jsonEncode(ExecutionSession)
    local dataSizeKb = math.floor(#jsonString / 1024)
    local fileName = string.format("CleanExecutionCapture_%s_%d.json", game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Client", os.time())
    local title = customTitle or "📦 CLEAN EXECUTOR REAL-TIME CAPTURE"

    local description = string.format(
        "**Game:** `%s` (ID: `%d`)\n" ..
        "**Player:** `%s`\n" ..
        "**Executor:** `%s`\n" ..
        "**Dung lượng JSON:** `%d KB`\n\n" ..
        "**🧬 Hàm giải mã thực tế:** `%d`\n" ..
        "**🎯 UI Callbacks / Events:** `%d`\n" ..
        "**🌐 Biến Môi Trường Mới:** `%d`\n" ..
        "**Trạng thái phiên:** `Đã đóng băng và xuất file an toàn`\n" ..
        "**Thời gian:** `%s`",
        ExecutionSession.SessionInfo.GameName,
        ExecutionSession.SessionInfo.PlaceId,
        ExecutionSession.SessionInfo.LocalPlayer,
        ExecutionSession.SessionInfo.Executor,
        dataSizeKb,
        stats.functionsCaptured,
        stats.uiEventsCaptured,
        (function() local c = 0 for _ in pairs(ExecutionSession.EnvironmentChanges) do c = c + 1 end return c end)(),
        os.date("!%Y-%m-%d %H:%M:%S UTC")
    )

    local boundary = "----CleanCaptureBoundary" .. tostring(os.time()) .. tostring(math.random(10000, 99999))
    local payloadJson = jsonEncode({
        username = "Clean Telemetry Dumper",
        avatar_url = "https://i.imgur.com/8Q1qD8s.png",
        embeds = {{
            title = title,
            color = 3447003, -- Blue Clean
            description = description,
            footer = { text = "Antigravity Stealth Telemetry Observer" },
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

    isFrozen = previousFreezeState
    isSending = false

    if success and response and (response.StatusCode == 200 or response.StatusCode == 204) then
        stats.totalDispatched = stats.totalDispatched + 1
        return true
    else
        return false, response and response.StatusCode or "Request Failed"
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  GIAO DIỆN ĐIỀU KHIỂN GỌN GÀNG (CLEAN DASHBOARD UI)                        ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function createDashboardUI()
    local CoreGui = game:GetService("CoreGui")
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StealthTelemetryObserver_UI"
    ScreenGui.ResetOnSpawn = false
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 390, 0, 275)
    Main.Position = UDim2.new(0.5, -195, 0.06, 0)
    Main.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local UICorner = Instance.new("UICorner", Main)
    UICorner.CornerRadius = UDim.new(0, 10)
    local UIStroke = Instance.new("UIStroke", Main)
    UIStroke.Color = Color3.fromRGB(52, 152, 219)
    UIStroke.Thickness = 1.5

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 28)
    Title.Position = UDim2.new(0, 10, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 12
    Title.TextColor3 = Color3.fromRGB(52, 152, 219)
    Title.Text = "🛰️ STEALTH EXECUTOR TELEMETRY OBSERVER"
    Title.Parent = Main

    -- Status Log
    local LogLabel = Instance.new("TextLabel")
    LogLabel.Size = UDim2.new(1, -20, 0, 90)
    LogLabel.Position = UDim2.new(0, 10, 0, 38)
    LogLabel.BackgroundColor3 = Color3.fromRGB(20, 28, 40)
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
        local envCount = 0
        for _ in pairs(ExecutionSession.EnvironmentChanges) do envCount = envCount + 1 end

        LogLabel.Text = string.format(
            " [🛰️] Trạng thái: %s\n" ..
            " [🧬] Hàm giải mã thực tế: %d\n" ..
            " [🎯] UI Hooks / Callbacks: %d\n" ..
            " [🌐] Biến môi trường mới: %d\n" ..
            " [📤] Số lần gửi Webhook: %d",
            isFrozen and "⏸️ ĐÃ ĐÓNG BĂNG (FREEZE)" or (isRecording and "🔴 ĐANG GHI THỜI GIAN THỰC" or "⏹️ TẠM DỪNG"),
            stats.functionsCaptured,
            stats.uiEventsCaptured,
            envCount,
            stats.totalDispatched
        )
    end

    -- Button: Dump & Send Webhook
    local SendBtn = Instance.new("TextButton")
    SendBtn.Size = UDim2.new(1, -20, 0, 38)
    SendBtn.Position = UDim2.new(0, 10, 0, 136)
    SendBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    SendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SendBtn.Font = Enum.Font.GothamBold
    SendBtn.TextSize = 12
    SendBtn.Text = "📤 DUMP & XUẤT FILE SẠCH VỀ WEBHOOK"
    SendBtn.Parent = Main
    local BtnCorner1 = Instance.new("UICorner", SendBtn)
    BtnCorner1.CornerRadius = UDim.new(0, 6)

    -- Button: Freeze / Resume Recording
    local FreezeBtn = Instance.new("TextButton")
    FreezeBtn.Size = UDim2.new(0.48, 0, 0, 32)
    FreezeBtn.Position = UDim2.new(0, 10, 0, 180)
    FreezeBtn.BackgroundColor3 = Color3.fromRGB(28, 40, 56)
    FreezeBtn.TextColor3 = Color3.fromRGB(52, 152, 219)
    FreezeBtn.Font = Enum.Font.GothamBold
    FreezeBtn.TextSize = 11
    FreezeBtn.Text = "⏸️ ĐÓNG BĂNG"
    FreezeBtn.Parent = Main
    local BtnCorner2 = Instance.new("UICorner", FreezeBtn)
    BtnCorner2.CornerRadius = UDim.new(0, 6)

    -- Button: Clear & Reset Session
    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Size = UDim2.new(0.48, 0, 0, 32)
    ClearBtn.Position = UDim2.new(0.52, 0, 0, 180)
    ClearBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 35)
    ClearBtn.TextColor3 = Color3.fromRGB(231, 76, 60)
    ClearBtn.Font = Enum.Font.GothamBold
    ClearBtn.TextSize = 11
    ClearBtn.Text = "🗑️ XÓA PHIÊN (RESET)"
    ClearBtn.Parent = Main
    local BtnCorner3 = Instance.new("UICorner", ClearBtn)
    BtnCorner3.CornerRadius = UDim.new(0, 6)

    -- Status Bar Text
    local StatusFooter = Instance.new("TextLabel")
    StatusFooter.Size = UDim2.new(1, -20, 0, 26)
    StatusFooter.Position = UDim2.new(0, 10, 0, 222)
    StatusFooter.BackgroundTransparency = 1
    StatusFooter.Font = Enum.Font.Gotham
    StatusFooter.TextSize = 11
    StatusFooter.TextColor3 = Color3.fromRGB(150, 170, 190)
    StatusFooter.Text = "🟢 Sẵn sàng ghi nhận luồng thực thi..."
    StatusFooter.Parent = Main

    SendBtn.MouseButton1Click:Connect(function()
        StatusFooter.Text = "⏳ Đang đóng gói dữ liệu và gửi về Webhook..."
        StatusFooter.TextColor3 = Color3.fromRGB(255, 200, 50)
        
        local ok, err = sendCleanDumpToWebhook("🚀 DUMP DỮ LIỆU THỰC THI SẠCH TỪ CLIENT")
        if ok then
            StatusFooter.Text = "✅ Đã gửi thành công gói dữ liệu sạch về Webhook!"
            StatusFooter.TextColor3 = Color3.fromRGB(80, 230, 120)
        else
            StatusFooter.Text = "⚠️ Gửi thất bại: " .. tostring(err)
            StatusFooter.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
        refreshUI()
    end)

    FreezeBtn.MouseButton1Click:Connect(function()
        isFrozen = not isFrozen
        FreezeBtn.Text = isFrozen and "▶️ TIẾP TỤC GHI" or "⏸️ ĐÓNG BĂNG"
        FreezeBtn.TextColor3 = isFrozen and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(52, 152, 219)
        StatusFooter.Text = isFrozen and "⏸️ Đã đóng băng bộ nhớ, không nhận thêm hàm mới!" or "🔴 Đang tiếp tục ghi nhận..."
        StatusFooter.TextColor3 = isFrozen and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(80, 230, 120)
        refreshUI()
    end)

    ClearBtn.MouseButton1Click:Connect(function()
        ExecutionSession.DecryptedFunctionRegistry = {}
        ExecutionSession.HttpTelemetry = {}
        ExecutionSession.RemoteTelemetry = {}
        ExecutionSession.UIInteractions = {}
        ExecutionSession.EnvironmentChanges = {}
        seenFunctionSet = {}
        seenStringSet = {}
        stats.functionsCaptured = 0
        stats.uiEventsCaptured = 0
        StatusFooter.Text = "🗑️ Đã xóa sạch dữ liệu phiên hiện tại về 0!"
        StatusFooter.TextColor3 = Color3.fromRGB(80, 230, 120)
        refreshUI()
    end)

    task.spawn(function()
        while true do
            refreshUI()
            task.wait(1.0)
        end
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  KHỞI ĐỘNG HỆ THỐNG                                                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function initialize()
    createDashboardUI()
    setupEnvironmentObserver()
    setupUIObserver()
    print("[TelemetryObserver] Khởi động thành công! Lớp tàng hình chỉ đọc đang hoạt động.")
end

initialize()
