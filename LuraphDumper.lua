--[[
    =============================================================================
    =  STEALTH ZERO-HOOK SCRIPT LISTENER - CALIBRATED PRECISION ENGINE          =
    =                                                                           =
    =  TẠI SAO BỊ NHẢY LÊN 24780 HÀM NGAY KHI MỞ:                              =
    =   Trong Blox Fruits có sẵn hơn 25.000 hàm game nội bộ (Physics, Quái,     =
    =   Animation, Skill, Map). Nếu quét GC mà không lọc chữ ký Hub thì hệ      =
    =   thống sẽ coi toàn bộ 25.000 hàm game Blox Fruits là script mới!         =
    =                                                                           =
    =  GIẢI PHÁP HIỆU CHUẨN CHUẨN XÁC (ZERO-BASELINE CALIBRATION):              =
    =   1. Khởi động với Calibration 100%: Toàn bộ hàm game ban đầu bị khóa    =
    =      vào Baseline và ĐẶT SỐ ĐẾM BAN ĐẦU CHÍNH XÁC VỀ 0.                   =
    =   2. Lọc thông minh theo Chữ ký Script / Hub (Hub Signature Matcher):    =
    =      - Chỉ nhận diện các hàm chứa logic Script/Hub (Tween, UI Library,    =
    =        Auto Farm, CommF_, Quest, Combat, Webhook, Key System,...).        =
    =   3. Giám sát Thư viện UI (Fluent, Rayfield, Orion, Linoria, WindUI,...): =
    =      - Tự động bắt ngay các hàm logic khi Menu Hub xuất hiện.             =
    =============================================================================
--]]

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  CẤU HÌNH HỆ THỐNG (CONFIGURATION)                                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local CONFIG = {
    -- Link Discord Webhook nhận dữ liệu
    WebhookUrl = "https://discord.com/api/webhooks/1540764685681299526/mFnSqvWMbpNimmzJ4d2w9oJdMvZxDis8hHQVNjlBCNVWIpZTm2nnDC90M87LZ-m6T-to",
    
    -- Tần số quét Delta (giây)
    ScanInterval = 1.5,

    -- Tự động gửi về Webhook sau mỗi X giây (nếu có dữ liệu giải mã mới)
    AutoSendInterval = 25, 
    AutoSendEnabled = true,

    -- Bóc tách sâu cây hàm con (Protos, Upvalues, Constants)
    DeepProtoExtraction = true,
    MaxProtoDepth = 4,

    -- Thử decompile hàm nếu executor hỗ trợ
    AttemptDecompile = true
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

local get_gc = getgc or debug.getgc
local get_genv = getgenv or function() return _G end
local get_connections = getconnections or get_signal_cons
local decompile_func = decompile or disassemble
local is_executor_closure = isexecutorclosure or isourclosure or checkcaller or function() return false end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  CHỮ KÝ ĐẶC TRƯNG CỦA CÁC SCRIPT & HUB (HUB SIGNATURES)                   ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local SCRIPT_HUB_KEYWORDS = {
    -- Blox Fruits & Game remotes
    "commf_", "comme_", "remotes", "combat", "attack", "autofarm", "farm",
    "tweenservice", "tween", "bringmob", "fastattack", "killauras", "aimbot",
    "esp", "chest", "fruit", "storefruit", "dungeon", "raid", "mirage", "sea",
    "kitsune", "v4", "racev4", "lever", "mastery", "bounty", "hop", "rejoin",
    
    -- Hub names & brands
    "banana", "bananacat", "hoho", "redz", "maru", "w-azure", "zenith", "mukuro",
    "tablehub", "cframehub", "vthang", "obiiyeuem", "trai", "min", "vector",
    
    -- UI Libraries & Loaders
    "rayfield", "orion", "fluent", "linoria", "windui", "solaris", "kavo",
    "maclib", "loadstring", "httpget", "webhook", "discord.com", "pastebin",
    "github", "raw.githubusercontent", "key", "whitelist", "hwid"
}

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  REGISTRY LOẠI TRỪ CHÍNH MÌNH (SELF-EXCLUSION)                            ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local MY_OWN_FUNCS = {}
local function markSelf(f)
    if type(f) == "function" then
        MY_OWN_FUNCS[f] = true
    end
    return f
end

local SELF_KEYWORDS = {
    "ZeroHookStealthListener", "ClientScriptListener", "SniffedData",
    "performDeltaScan", "takeInitialBaseline", "extractFunctionDetails",
    "sendDumpToWebhook", "createDashboardUI", "MY_OWN_FUNCS", "CONFIG"
}

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
    DecryptedClosures = {},      -- Toàn bộ hàm thực sự từ script khác
    DiscoveredStrings = {},      -- Hằng số chuỗi giải mã từ script khác
    DiscoveredUIHooks = {},      -- Callbacks gắn vào nút bấm UI từ script khác
    GlobalSnapshots = {},        -- Biến môi trường mới trong getgenv()
    TotalNewFunctions = 0
}

local stats = {
    newFunctionsFound = 0,
    newStringsFound = 0,
    uiCallbacksFound = 0,
    totalDispatched = 0
}

local baselineFunctions = {}
local baselineGenv = {}
local seenExtracted = {}
local stringPool = {}
local isCalibrated = false

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
markSelf(safeToString)

local function escapeJson(s)
    if type(s) ~= "string" then s = safeToString(s) end
    return s:gsub('\\', '\\\\')
            :gsub('"', '\\"')
            :gsub('\n', '\\n')
            :gsub('\r', '\\r')
            :gsub('\t', '\\t')
            :gsub('[%c]', function(c) return ('\\u%04X'):format(c:byte()) end)
end
markSelf(escapeJson)

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
markSelf(serializeValue)

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
markSelf(jsonEncode)

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  BỘ LỌC CHỮ KÝ CHÍNH XÁC (HUB SIGNATURE MATCHER)                          ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function isSelfFunction(func, constants, src)
    if MY_OWN_FUNCS[func] then return true end
    if src and (string.find(src, "ZeroHook") or string.find(src, "ClientScriptListener")) then
        return true
    end
    if constants then
        for _, c in pairs(constants) do
            if type(c) == "string" then
                for _, kw in ipairs(SELF_KEYWORDS) do
                    if string.find(c, kw, 1, true) then
                        return true
                    end
                end
            end
        end
    end
    return false
end
markSelf(isSelfFunction)

local function matchesScriptSignature(constants, upvalues, src, name)
    local checkStr = function(str)
        if type(str) ~= "string" then return false end
        local lower = string.lower(str)
        for _, kw in ipairs(SCRIPT_HUB_KEYWORDS) do
            if string.find(lower, kw, 1, true) then
                return true
            end
        end
        return false
    end

    if checkStr(src) or checkStr(name) then return true end

    if constants then
        for _, c in pairs(constants) do
            if checkStr(c) then return true end
        end
    end

    if upvalues then
        for _, u in pairs(upvalues) do
            if checkStr(u) then return true end
        end
    end

    return false
end
markSelf(matchesScriptSignature)

local function isTargetScriptFunction(func)
    if type(func) ~= "function" then return false end
    if MY_OWN_FUNCS[func] then return false end
    if baselineFunctions[func] then return false end

    local info = debug.getinfo and debug.getinfo(func) or {}
    local src = info.source or ""
    local name = info.name or ""

    -- Bỏ qua script hệ thống
    if string.find(src, "CoreGui") or string.find(src, "CorePackages") or string.find(src, "PlayerScripts") then
        return false
    end

    local constants = debug.getconstants and debug.getconstants(func) or {}
    local upvalues = debug.getupvalues and debug.getupvalues(func) or {}

    if isSelfFunction(func, constants, src) then
        MY_OWN_FUNCS[func] = true
        return false
    end

    -- Khớp với chữ ký của script/hub giải mã
    if matchesScriptSignature(constants, upvalues, src, name) then
        return true
    end

    -- Hoặc là closure của executor và có chứa hằng số đáng kể
    if is_executor_closure(func) and (#constants >= 3 or #upvalues >= 2) then
        return true
    end

    return false
end
markSelf(isTargetScriptFunction)

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

    local constants = debug.getconstants and debug.getconstants(func) or {}
    local upvalues = debug.getupvalues and debug.getupvalues(func) or {}
    local protos = (CONFIG.DeepProtoExtraction and debug.getprotos and debug.getprotos(func)) or {}

    if isSelfFunction(func, constants, src) then
        MY_OWN_FUNCS[func] = true
        return nil
    end

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
markSelf(extractFunctionDetails)

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  HIỆU CHUẨN BAN ĐẦU & QUÉT DELTA (ZERO BASELINE)                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function performFullCalibration()
    if not get_gc then return end
    
    -- Khóa toàn bộ hàm hiện có của Blox Fruits vào Baseline
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

    -- Đặt lại toàn bộ số liệu về 0
    stats.newFunctionsFound = 0
    stats.newStringsFound = 0
    stats.uiCallbacksFound = 0
    stats.totalDispatched = 0
    SniffedData.DecryptedClosures = {}
    SniffedData.DiscoveredStrings = {}
    SniffedData.DiscoveredUIHooks = {}
    SniffedData.GlobalSnapshots = {}
    SniffedData.TotalNewFunctions = 0
    stringPool = {}
    seenExtracted = {}

    isCalibrated = true
end
markSelf(performFullCalibration)

local function performDeltaScan()
    if not get_gc or not isCalibrated then return 0 end

    local currentObjs = get_gc(true)
    local newlyFoundCount = 0

    for _, obj in ipairs(currentObjs) do
        if type(obj) == "function" and not baselineFunctions[obj] and not seenExtracted[obj] then
            seenExtracted[obj] = true

            if isTargetScriptFunction(obj) then
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
    end

    -- Quét các biến mới trong getgenv()
    local currentGenv = get_genv()
    for k, v in pairs(currentGenv) do
        if not baselineGenv[k] and k ~= "SniffedData" and not string.find(tostring(k), "^_") then
            if not isSelfFunction(v) then
                SniffedData.GlobalSnapshots[safeToString(k)] = serializeValue(v, 1, 2)
            end
        end
    end

    SniffedData.TotalNewFunctions = stats.newFunctionsFound
    return newlyFoundCount
end
markSelf(performDeltaScan)

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  BẮT HÀM TỪ GIAO DIỆN UI & CONNECTIONS                                    ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function setupPassiveUIListener()
    if not get_connections then return end

    local function checkInstance(inst)
        if not inst then return end
        pcall(function()
            if inst:IsA("GuiButton") then
                for _, eventName in ipairs({"MouseButton1Click", "MouseButton1Down", "Activated"}) do
                    local cons = get_connections(inst[eventName])
                    if cons then
                        for _, con in ipairs(cons) do
                            local f = con.Function
                            if f and type(f) == "function" and not seenExtracted[f] and isTargetScriptFunction(f) then
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
    markSelf(checkInstance)

    local CoreGui = game:GetService("CoreGui")
    local PlayerGui = game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChild("PlayerGui")

    pcall(function()
        CoreGui.DescendantAdded:Connect(function(descendant)
            task.wait(0.3)
            checkInstance(descendant)
        end)
    end)

    if PlayerGui then
        PlayerGui.DescendantAdded:Connect(function(descendant)
            task.wait(0.3)
            checkInstance(descendant)
        end)
    end
end
markSelf(setupPassiveUIListener)

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
    local fileName = string.format("PrecisionDecryptedDump_%s_%d.json", game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Client", os.time())
    local title = customTitle or "🛡️ PRECISION ZERO-HOOK DECRYPTION REPORT"

    local description = string.format(
        "**Game:** `%s` (ID: `%d`)\n" ..
        "**Player:** `%s`\n" ..
        "**Executor:** `%s`\n" ..
        "**Dung lượng JSON:** `%d KB`\n\n" ..
        "**🧬 Hàm giải mã mới:** `%d`\n" ..
        "**🔤 Chuỗi Constants:** `%d`\n" ..
        "**🎯 UI Callbacks:** `%d`\n" ..
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
        username = "Precision Zero-Hook Dumper",
        avatar_url = "https://i.imgur.com/8Q1qD8s.png",
        embeds = {{
            title = title,
            color = 3066993,
            description = description,
            footer = { text = "Precision Zero-Hook Passive Sniffer" },
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
markSelf(sendDumpToWebhook)

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  GIAO DIỆN ĐIỀU KHIỂN (GUI)                                               ║
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
    Title.Text = "🛡️ PRECISION ZERO-HOOK SCRIPT LISTENER"
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
            " [🛡️] Trạng thái: ĐÃ HIỆU CHUẨN (Baseline: 0)\n" ..
            " [🧬] Hàm giải mã mới: %d\n" ..
            " [🔤] Hằng số Constants: %d\n" ..
            " [🎯] UI Hooks / Callbacks: %d\n" ..
            " [📤] Số lần gửi Webhook: %d",
            stats.newFunctionsFound,
            stats.newStringsFound,
            stats.uiCallbacksFound,
            stats.totalDispatched
        )
    end
    markSelf(refreshUI)

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

    -- Button: Recalibrate Baseline to 0
    local CalibBtn = Instance.new("TextButton")
    CalibBtn.Size = UDim2.new(1, -20, 0, 32)
    CalibBtn.Position = UDim2.new(0, 10, 0, 180)
    CalibBtn.BackgroundColor3 = Color3.fromRGB(28, 40, 52)
    CalibBtn.TextColor3 = Color3.fromRGB(46, 204, 113)
    CalibBtn.Font = Enum.Font.GothamBold
    CalibBtn.TextSize = 11
    CalibBtn.Text = "🔄 HIỆU CHUẨN LẠI (RESET SỐ VỀ 0)"
    CalibBtn.Parent = Main
    local BtnCorner2 = Instance.new("UICorner", CalibBtn)
    BtnCorner2.CornerRadius = UDim.new(0, 6)

    -- Status Bar Text
    local StatusFooter = Instance.new("TextLabel")
    StatusFooter.Size = UDim2.new(1, -20, 0, 26)
    StatusFooter.Position = UDim2.new(0, 10, 0, 222)
    StatusFooter.BackgroundTransparency = 1
    StatusFooter.Font = Enum.Font.Gotham
    StatusFooter.TextSize = 11
    StatusFooter.TextColor3 = Color3.fromRGB(150, 170, 190)
    StatusFooter.Text = "🟢 Baseline 0 - Đang chờ script chạy..."
    StatusFooter.Parent = Main

    SendBtn.MouseButton1Click:Connect(markSelf(function()
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
    end))

    CalibBtn.MouseButton1Click:Connect(markSelf(function()
        StatusFooter.Text = "🔄 Đang hiệu chuẩn lại bộ nhớ về 0..."
        StatusFooter.TextColor3 = Color3.fromRGB(0, 200, 255)
        task.wait(0.05)
        performFullCalibration()
        StatusFooter.Text = "✅ Đã hiệu chuẩn! Số đếm hiện tại: 0"
        StatusFooter.TextColor3 = Color3.fromRGB(80, 230, 120)
        refreshUI()
    end))

    task.spawn(markSelf(function()
        while true do
            refreshUI()
            task.wait(1.5)
        end
    end))
end
markSelf(createDashboardUI)

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  VÒNG LẶP QUÉT & TỰ ĐỘNG GỬI                                               ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function startBackgroundLoops()
    task.spawn(markSelf(function()
        while true do
            task.wait(CONFIG.ScanInterval)
            if isCalibrated then
                pcall(performDeltaScan)
            end
        end
    end))

    if CONFIG.AutoSendEnabled then
        task.spawn(markSelf(function()
            while true do
                task.wait(CONFIG.AutoSendInterval)
                local hasNewData = (stats.newFunctionsFound > 0 or stats.newStringsFound > 0 or stats.uiCallbacksFound > 0)
                if hasNewData and not isSending and isCalibrated then
                    sendDumpToWebhook("⏱️ BÁO CÁO ĐỊNH KỲ TỰ ĐỘNG (STEALTH DELTA)")
                end
            end
        end))
    end
end
markSelf(startBackgroundLoops)

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  KHỞI ĐỘNG HỆ THỐNG VÀ HIỆU CHUẨN                                         ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function initialize()
    createDashboardUI()
    setupPassiveUIListener()
    performFullCalibration()
    startBackgroundLoops()
    print("[PrecisionListener] Khởi động thành công! Đã hiệu chuẩn đưa Baseline về 0.")
end
markSelf(initialize)

initialize()
