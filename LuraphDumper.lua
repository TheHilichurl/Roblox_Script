--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              Luraph VM Dumper v1.0                          ║
    ║  Captures decoded bytecode & strings from Luraph-protected  ║
    ║  scripts by hooking Lua VM internals at runtime.            ║
    ║                                                              ║
    ║  Requirements: Roblox executor with debug/hooking support    ║
    ║  (e.g., hookfunction, debug.getinfo, debug.getconstants,    ║
    ║   debug.getprotos, getgc, newcclosure, etc.)                 ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════
local Config = {
    -- Output settings
    OutputToConsole   = true,     -- Print results to console/dev console
    SaveToFile        = true,     -- Save dump to file (if writefile is available)
    OutputFileName    = "LuraphDump_%s.lua",  -- %s = timestamp
    
    -- Dumper settings
    CaptureStrings    = true,     -- Capture all decrypted strings
    CaptureConstants  = true,     -- Capture function constants
    CaptureUpvalues   = true,     -- Capture upvalue names/values
    CaptureProtos     = true,     -- Capture sub-prototypes (nested functions)
    TraceExecution    = true,     -- Trace VM execution flow
    HookLoadstring    = true,     -- Hook loadstring/load to intercept dynamic code
    HookGC            = true,     -- Scan garbage collector for function objects
    MaxDepth          = 50,       -- Max recursion depth for proto scanning
    MaxStringLength   = 5000,     -- Truncate very long strings in output
    
    -- Filtering
    IgnoreRobloxInternals = true, -- Skip Roblox engine functions
    MinStringLength       = 2,    -- Ignore very short captured strings
    
    -- Discord Webhook settings
    WebhookURL        = "https://discord.com/api/webhooks/1540742443459416074/OoigNnHKVnNmTh9unbAqX4hEyE7o7e2p9HM7P5Hob1_cEemOFY_0OMIE9SbO9JHGhKI5",       -- Set your Discord webhook URL here
    WebhookUsername   = "Luraph VM Dumper",
    WebhookAvatarURL  = "",       -- Optional avatar URL for the bot
    EmbedColor        = 0x5865F2, -- Discord blurple color for embeds
    MaxMessageLength  = 1900,     -- Discord max is 2000, leave margin
    SendAsFile        = true,     -- Send full dump as .lua file attachment
    SendEmbedSummary  = true,     -- Send a summary embed with key stats
}

-- ═══════════════════════════════════════════════════════════════
-- UTILITY MODULE
-- ═══════════════════════════════════════════════════════════════
local Utils = {}

function Utils.timestamp()
    return tostring(os.time and os.time() or tick and tick() or 0)
end

function Utils.safeToString(value)
    local success, result = pcall(tostring, value)
    return success and result or "<unable to convert>"
end

function Utils.truncate(str, maxLen)
    maxLen = maxLen or Config.MaxStringLength
    if type(str) ~= "string" then return Utils.safeToString(str) end
    if #str <= maxLen then return str end
    return str:sub(1, maxLen) .. ("... [truncated, %d total chars]"):format(#str)
end

function Utils.escapeString(str)
    if type(str) ~= "string" then return Utils.safeToString(str) end
    return str:gsub("\\", "\\\\")
              :gsub("\"", "\\\"")
              :gsub("\n", "\\n")
              :gsub("\r", "\\r")
              :gsub("\t", "\\t")
              :gsub("[%c]", function(c)
                  return ("\\x%02X"):format(string.byte(c))
              end)
end

function Utils.isPrintable(str)
    if type(str) ~= "string" then return false end
    for i = 1, math.min(#str, 100) do
        local b = string.byte(str, i)
        if b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then
            return false
        end
    end
    return true
end

function Utils.tableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end

function Utils.getTypeTag(value)
    local t = type(value)
    if t == "function" then
        local info = nil
        pcall(function() info = debug.getinfo(value) end)
        if info then
            return ("function<%s:%s>"):format(
                info.short_src or "?",
                info.linedefined or "?"
            )
        end
        return "function<?>"
    end
    return t
end

-- ═══════════════════════════════════════════════════════════════
-- LOGGER MODULE
-- ═══════════════════════════════════════════════════════════════
local Logger = {
    _buffer = {},
    _lineCount = 0,
}

function Logger:clear()
    self._buffer = {}
    self._lineCount = 0
end

function Logger:write(text)
    text = text or ""
    self._lineCount = self._lineCount + 1
    self._buffer[self._lineCount] = text
    
    if Config.OutputToConsole then
        if rconsoleprint then
            rconsoleprint(text .. "\n")
        else
            print(text)
        end
    end
end

function Logger:writef(fmt, ...)
    self:write(fmt:format(...))
end

function Logger:section(title)
    self:write("")
    self:write(("-- === %s %s"):format(title, string.rep("=", math.max(0, 55 - #title))))
    self:write("")
end

function Logger:subsection(title)
    self:write(("  -- --- %s %s"):format(title, string.rep("-", math.max(0, 49 - #title))))
end

function Logger:getOutput()
    return table.concat(self._buffer, "\n")
end

function Logger:save()
    if not Config.SaveToFile then return false end
    
    local writefileFn = writefile or (syn and syn.writefile)
    if not writefileFn then
        self:write("-- [!] writefile not available, cannot save to disk")
        return false
    end
    
    local filename = Config.OutputFileName:format(Utils.timestamp())
    local success, err = pcall(writefileFn, filename, self:getOutput())
    
    if success then
        self:write(("-- [OK] Saved dump to: %s"):format(filename))
        return true
    else
        self:write(("-- [!] Failed to save: %s"):format(tostring(err)))
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CAPABILITY DETECTOR
-- ═══════════════════════════════════════════════════════════════
local Capabilities = {}

function Capabilities.detect()
    local caps = {
        hasDebugLib          = type(debug) == "table",
        hasGetInfo           = type(debug) == "table" and type(debug.getinfo) == "function",
        hasGetConstants      = type(debug) == "table" and type(debug.getconstants) == "function",
        hasGetConstant       = type(debug) == "table" and type(debug.getconstant) == "function",
        hasGetProtos         = type(debug) == "table" and type(debug.getprotos) == "function",
        hasGetUpvalues       = type(debug) == "table" and type(debug.getupvalues) == "function",
        hasGetUpvalue        = type(debug) == "table" and type(debug.getupvalue) == "function",
        hasGetStack          = type(debug) == "table" and type(debug.getstack) == "function",
        hasSetStack          = type(debug) == "table" and type(debug.setstack) == "function",
        hasHookFunction      = type(hookfunction) == "function",
        hasNewCClosure       = type(newcclosure) == "function",
        hasGetGC             = type(getgc) == "function",
        hasGetLoadedModules  = type(getloadedmodules) == "function",
        hasGetScripts        = type(getscripts) == "function",
        hasDecompile         = type(decompile) == "function",
        hasGetScriptClosure  = type(getscriptclosure) == "function",
        hasWriteFile         = type(writefile) == "function" or (type(syn) == "table" and type(syn.writefile) == "function"),
        hasIsLClosure        = type(islclosure) == "function",
        hasIsCClosure        = type(iscclosure) == "function",
        hasCheckcaller       = type(checkcaller) == "function",
        hasGetRawMetatable   = type(getrawmetatable) == "function",
        hasHttpGet           = type(game) == "userdata" and pcall(function() return game.HttpGet end),
    }
    return caps
end

function Capabilities.report(caps)
    Logger:section("EXECUTOR CAPABILITIES")
    
    local capNames = {
        {"Debug Library",       "hasDebugLib"},
        {"debug.getinfo",       "hasGetInfo"},
        {"debug.getconstants",  "hasGetConstants"},
        {"debug.getprotos",     "hasGetProtos"},
        {"debug.getupvalues",   "hasGetUpvalues"},
        {"debug.getstack",      "hasGetStack"},
        {"hookfunction",        "hasHookFunction"},
        {"newcclosure",         "hasNewCClosure"},
        {"getgc",               "hasGetGC"},
        {"getscripts",          "hasGetScripts"},
        {"decompile",           "hasDecompile"},
        {"getscriptclosure",    "hasGetScriptClosure"},
        {"writefile",           "hasWriteFile"},
        {"islclosure",          "hasIsLClosure"},
        {"checkcaller",         "hasCheckcaller"},
        {"getrawmetatable",     "hasGetRawMetatable"},
    }
    
    for _, cap in ipairs(capNames) do
        local name, key = cap[1], cap[2]
        local status = caps[key] and "[YES]" or "[NO ]"
        Logger:writef("  %s %s", status, name)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- STRING CAPTURE MODULE
-- Intercepts and collects decrypted strings from the VM
-- ═══════════════════════════════════════════════════════════════
local StringCapture = {
    _captured = {},
    _seen = {},
    _count = 0,
    _hooks = {},
}

function StringCapture:add(str, source)
    if type(str) ~= "string" then return end
    if #str < Config.MinStringLength then return end
    if self._seen[str] then return end
    
    -- Filter out binary/non-printable data
    if not Utils.isPrintable(str) and #str > 50 then return end
    
    self._seen[str] = true
    self._count = self._count + 1
    self._captured[self._count] = {
        value  = str,
        source = source or "unknown",
        index  = self._count,
    }
end

function StringCapture:hookStringLib()
    -- Hook string operations that Luraph uses for decryption
    local targets = {
        {obj = string, name = "byte",    fn = string.byte},
        {obj = string, name = "char",    fn = string.char},
        {obj = string, name = "sub",     fn = string.sub},
        {obj = string, name = "gsub",    fn = string.gsub},
        {obj = string, name = "rep",     fn = string.rep},
        {obj = string, name = "reverse", fn = string.reverse},
        {obj = string, name = "format",  fn = string.format},
    }
    
    if not hookfunction or not newcclosure then
        Logger:write("  [!] hookfunction/newcclosure not available, skipping string hooks")
        return
    end
    
    for _, target in ipairs(targets) do
        local original = target.fn
        local name = target.name
        
        local success, err = pcall(function()
            local hook = newcclosure(function(...)
                local results = {original(...)}
                
                -- Capture string results
                for _, result in ipairs(results) do
                    if type(result) == "string" and #result >= Config.MinStringLength then
                        StringCapture:add(result, "string." .. name)
                    end
                end
                
                return unpack(results)
            end)
            
            hookfunction(target.obj[name], hook)
            self._hooks[name] = {original = original, hooked = true}
        end)
        
        if not success then
            Logger:writef("  [!] Failed to hook string.%s: %s", name, tostring(err))
        end
    end
    
    Logger:write("  [OK] String library hooks installed")
end

function StringCapture:hookTableConcat()
    if not hookfunction or not newcclosure then return end
    
    local originalConcat = table.concat
    pcall(function()
        hookfunction(table.concat, newcclosure(function(...)
            local result = originalConcat(...)
            if type(result) == "string" and #result >= Config.MinStringLength then
                StringCapture:add(result, "table.concat")
            end
            return result
        end))
        Logger:write("  [OK] table.concat hook installed")
    end)
end

function StringCapture:report()
    Logger:section("CAPTURED STRINGS (" .. self._count .. " unique)")
    
    if self._count == 0 then
        Logger:write("  (no strings captured)")
        return
    end
    
    -- Group by source
    local bySource = {}
    for _, entry in ipairs(self._captured) do
        bySource[entry.source] = bySource[entry.source] or {}
        table.insert(bySource[entry.source], entry)
    end
    
    for source, entries in pairs(bySource) do
        Logger:subsection(("%s (%d strings)"):format(source, #entries))
        for _, entry in ipairs(entries) do
            Logger:writef("    [%04d] \"%s\"", entry.index, 
                Utils.escapeString(Utils.truncate(entry.value, 200)))
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FUNCTION SCANNER MODULE
-- Recursively scans function prototypes for constants/protos
-- ═══════════════════════════════════════════════════════════════
local FunctionScanner = {
    _scanned = {},
    _functions = {},
    _funcCount = 0,
}

function FunctionScanner:isScanned(func)
    local key = tostring(func)
    if self._scanned[key] then return true end
    self._scanned[key] = true
    return false
end

function FunctionScanner:scanConstants(func, depth, path)
    depth = depth or 0
    path = path or "root"
    
    if depth > Config.MaxDepth then return end
    if self:isScanned(func) then return end
    if type(func) ~= "function" then return end
    
    -- Check if it's an L-closure (Lua function, not C function)
    if islclosure and not islclosure(func) then return end
    if iscclosure and iscclosure(func) then return end
    
    self._funcCount = self._funcCount + 1
    local funcIndex = self._funcCount
    local funcData = {
        index     = funcIndex,
        path      = path,
        depth     = depth,
        constants = {},
        upvalues  = {},
        protos    = {},
        info      = nil,
    }
    
    -- Get debug info
    pcall(function()
        funcData.info = debug.getinfo(func)
    end)
    
    -- Get constants
    if Config.CaptureConstants and debug.getconstants then
        pcall(function()
            local constants = debug.getconstants(func)
            for idx, value in pairs(constants) do
                local entry = {
                    index = idx,
                    type  = type(value),
                    value = value,
                }
                table.insert(funcData.constants, entry)
                
                -- Also add strings to the string capture
                if type(value) == "string" then
                    StringCapture:add(value, ("const@func_%d[%d]"):format(funcIndex, idx))
                end
            end
        end)
    end
    
    -- Get upvalues
    if Config.CaptureUpvalues and debug.getupvalues then
        pcall(function()
            local upvalues = debug.getupvalues(func)
            for idx, value in pairs(upvalues) do
                table.insert(funcData.upvalues, {
                    index = idx,
                    type  = type(value),
                    value = value,
                })
                
                if type(value) == "string" then
                    StringCapture:add(value, ("upval@func_%d[%d]"):format(funcIndex, idx))
                end
                
                -- Recursively scan function upvalues
                if type(value) == "function" then
                    self:scanConstants(value, depth + 1, 
                        ("%s.upval[%d]"):format(path, idx))
                end
            end
        end)
    end
    
    -- Get protos (nested/child functions)
    if Config.CaptureProtos and debug.getprotos then
        pcall(function()
            local protos = debug.getprotos(func)
            for idx, proto in pairs(protos) do
                table.insert(funcData.protos, {
                    index = idx,
                    func  = proto,
                })
                
                -- Recursively scan sub-protos
                self:scanConstants(proto, depth + 1, 
                    ("%s.proto[%d]"):format(path, idx))
            end
        end)
    end
    
    self._functions[funcIndex] = funcData
end

function FunctionScanner:scanGC()
    if not getgc then
        Logger:write("  [!] getgc not available, skipping GC scan")
        return
    end
    
    Logger:write("  [*] Scanning garbage collector for function objects...")
    
    local gcObjects = getgc(true)  -- true = include tables
    local funcCount = 0
    local strCount = 0
    
    for _, obj in ipairs(gcObjects) do
        if type(obj) == "function" then
            funcCount = funcCount + 1
            self:scanConstants(obj, 0, ("gc_func_%d"):format(funcCount))
            
        elseif type(obj) == "table" then
            -- Scan tables for function values
            pcall(function()
                for k, v in pairs(obj) do
                    if type(v) == "function" then
                        funcCount = funcCount + 1
                        self:scanConstants(v, 0, 
                            ("gc_table.%s"):format(Utils.safeToString(k)))
                    end
                    if type(v) == "string" and #v >= Config.MinStringLength then
                        strCount = strCount + 1
                        StringCapture:add(v, "gc_table_value")
                    end
                    if type(k) == "string" and #k >= Config.MinStringLength then
                        StringCapture:add(k, "gc_table_key")
                    end
                end
            end)
        end
    end
    
    Logger:writef("  [OK] GC scan complete: %d functions, %d strings found", funcCount, strCount)
end

function FunctionScanner:report()
    Logger:section(("FUNCTION PROTOTYPES (%d scanned)"):format(self._funcCount))
    
    if self._funcCount == 0 then
        Logger:write("  (no functions scanned)")
        return
    end
    
    for idx = 1, self._funcCount do
        local funcData = self._functions[idx]
        if funcData then
            local indent = string.rep("  ", funcData.depth + 1)
            
            Logger:writef("")
            Logger:writef("%s+-- Function #%d [%s]", indent, idx, funcData.path)
            
            -- Info
            if funcData.info then
                local info = funcData.info
                Logger:writef("%s|  Source: %s:%s-%s", indent,
                    info.short_src or "?",
                    info.linedefined or "?",
                    info.lastlinedefined or "?")
                Logger:writef("%s|  Params: %s | Upvalues: %s", indent,
                    info.numparams or "?",
                    info.nups or "?")
            end
            
            -- Constants
            if #funcData.constants > 0 then
                Logger:writef("%s|  Constants (%d):", indent, #funcData.constants)
                for _, const in ipairs(funcData.constants) do
                    local displayValue
                    if const.type == "string" then
                        displayValue = '"' .. Utils.escapeString(Utils.truncate(const.value, 150)) .. '"'
                    elseif const.type == "number" or const.type == "boolean" then
                        displayValue = tostring(const.value)
                    else
                        displayValue = ("[%s]"):format(const.type)
                    end
                    Logger:writef("%s|    [%d] (%s) %s", indent, const.index, const.type, displayValue)
                end
            end
            
            -- Upvalues
            if #funcData.upvalues > 0 then
                Logger:writef("%s|  Upvalues (%d):", indent, #funcData.upvalues)
                for _, upval in ipairs(funcData.upvalues) do
                    local displayValue
                    if upval.type == "string" then
                        displayValue = '"' .. Utils.escapeString(Utils.truncate(upval.value, 100)) .. '"'
                    elseif upval.type == "function" then
                        displayValue = Utils.getTypeTag(upval.value)
                    elseif upval.type == "table" then
                        local count = 0
                        pcall(function() for _ in pairs(upval.value) do count = count + 1 end end)
                        displayValue = ("table[%d entries]"):format(count)
                    else
                        displayValue = Utils.safeToString(upval.value)
                    end
                    Logger:writef("%s|    [%d] (%s) %s", indent, upval.index, upval.type, displayValue)
                end
            end
            
            -- Proto count
            if #funcData.protos > 0 then
                Logger:writef("%s|  Sub-protos: %d", indent, #funcData.protos)
            end
            
            Logger:writef("%s+--", indent)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- LOADSTRING INTERCEPTOR
-- Hooks loadstring/load to capture any dynamically loaded code
-- ═══════════════════════════════════════════════════════════════
local LoadInterceptor = {
    _captures = {},
    _count = 0,
}

function LoadInterceptor:install()
    if not Config.HookLoadstring then return end
    if not hookfunction or not newcclosure then
        Logger:write("  [!] Cannot install loadstring hooks (missing hookfunction/newcclosure)")
        return
    end
    
    -- Hook loadstring
    local originalLoadstring = loadstring or load
    if originalLoadstring then
        pcall(function()
            local hook = newcclosure(function(code, ...)
                if type(code) == "string" and #code > 10 then
                    LoadInterceptor._count = LoadInterceptor._count + 1
                    LoadInterceptor._captures[LoadInterceptor._count] = {
                        index   = LoadInterceptor._count,
                        length  = #code,
                        preview = code:sub(1, 500),
                        time    = Utils.timestamp(),
                    }
                    
                    if Config.OutputToConsole then
                        print(("[LuraphDumper] Intercepted loadstring: %d bytes"):format(#code))
                    end
                end
                return originalLoadstring(code, ...)
            end)
            
            if loadstring then
                hookfunction(loadstring, hook)
            end
            Logger:write("  [OK] loadstring hook installed")
        end)
    end
end

function LoadInterceptor:report()
    Logger:section(("INTERCEPTED LOADSTRING CALLS (%d)"):format(self._count))
    
    if self._count == 0 then
        Logger:write("  (no loadstring calls intercepted)")
        return
    end
    
    for _, capture in ipairs(self._captures) do
        Logger:writef("  --- Capture #%d (time: %s, size: %d bytes) ---", 
            capture.index, capture.time, capture.length)
        Logger:writef("    %s", Utils.escapeString(Utils.truncate(capture.preview, 400)))
        Logger:write("")
    end
end

-- ═══════════════════════════════════════════════════════════════
-- EXECUTION TRACER
-- Traces VM execution to map control flow
-- ═══════════════════════════════════════════════════════════════
local ExecutionTracer = {
    _trace = {},
    _traceCount = 0,
    _maxTraceEntries = 10000,
    _active = false,
}

function ExecutionTracer:install()
    if not Config.TraceExecution then return end
    if not debug or not debug.sethook then
        Logger:write("  [!] debug.sethook not available, skipping execution tracer")
        return
    end
    
    self._active = true
    
    pcall(function()
        debug.sethook(function(event, line)
            if not ExecutionTracer._active then return end
            if ExecutionTracer._traceCount >= ExecutionTracer._maxTraceEntries then
                ExecutionTracer._active = false
                return
            end
            
            ExecutionTracer._traceCount = ExecutionTracer._traceCount + 1
            
            local info = debug.getinfo(2, "Sln")
            ExecutionTracer._trace[ExecutionTracer._traceCount] = {
                event  = event,
                line   = line,
                source = info and info.short_src or "?",
                name   = info and info.name or "?",
                what   = info and info.what or "?",
            }
        end, "cl", 100)  -- call + line events, every 100th instruction
        
        Logger:write("  [OK] Execution tracer installed (sampling every 100th instruction)")
    end)
end

function ExecutionTracer:stop()
    self._active = false
    pcall(function()
        debug.sethook()  -- Remove hook
    end)
end

function ExecutionTracer:report()
    Logger:section(("EXECUTION TRACE (%d entries)"):format(self._traceCount))
    
    if self._traceCount == 0 then
        Logger:write("  (no trace data collected)")
        return
    end
    
    -- Summarize unique call sites
    local callSites = {}
    for _, entry in ipairs(self._trace) do
        local key = ("%s:%s (%s)"):format(entry.source, entry.line, entry.name)
        callSites[key] = (callSites[key] or 0) + 1
    end
    
    -- Sort by frequency
    local sorted = {}
    for site, count in pairs(callSites) do
        table.insert(sorted, {site = site, count = count})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    Logger:write("  Top call sites (by frequency):")
    for i = 1, math.min(50, #sorted) do
        Logger:writef("    [%5dx] %s", sorted[i].count, sorted[i].site)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- DECOMPILER BRIDGE
-- Attempts to use the executor's built-in decompiler
-- ═══════════════════════════════════════════════════════════════
local DecompilerBridge = {}

function DecompilerBridge:tryDecompile(func, name)
    if not decompile then return nil end
    
    local success, result = pcall(decompile, func)
    if success and type(result) == "string" and #result > 0 then
        return result
    end
    return nil
end

function DecompilerBridge:tryDecompileScript(script)
    if not decompile then return nil end
    
    local success, result = pcall(decompile, script)
    if success and type(result) == "string" and #result > 0 then
        return result
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- METATABLE SCANNER
-- Scans metatables for hidden function references
-- ═══════════════════════════════════════════════════════════════
local MetatableScanner = {
    _found = {},
    _count = 0,
}

function MetatableScanner:scan()
    if not getrawmetatable then
        Logger:write("  [!] getrawmetatable not available, skipping metatable scan")
        return
    end
    
    if not getgc then return end
    
    Logger:write("  [*] Scanning metatables for hidden function references...")
    
    local gcObjects = getgc(true)
    for _, obj in ipairs(gcObjects) do
        if type(obj) == "table" then
            pcall(function()
                local mt = getrawmetatable(obj)
                if mt then
                    for k, v in pairs(mt) do
                        if type(v) == "function" then
                            self._count = self._count + 1
                            self._found[self._count] = {
                                key = tostring(k),
                                func = v,
                            }
                            FunctionScanner:scanConstants(v, 0, 
                                ("metatable.__" .. tostring(k)))
                        end
                    end
                end
            end)
        end
    end
    
    Logger:writef("  [OK] Metatable scan: %d metamethods found", self._count)
end

-- ═══════════════════════════════════════════════════════════════
-- REGISTRY SCANNER  
-- Scans the Lua registry for function references
-- ═══════════════════════════════════════════════════════════════
local RegistryScanner = {}

function RegistryScanner:scan()
    if not debug or not debug.getregistry then
        Logger:write("  [!] debug.getregistry not available")
        return
    end
    
    Logger:write("  [*] Scanning Lua registry...")
    
    local registry = nil
    pcall(function() registry = debug.getregistry() end)
    
    if not registry then return end
    
    local funcCount = 0
    local function scanTable(tbl, path, depth)
        if depth > 5 then return end
        pcall(function()
            for k, v in pairs(tbl) do
                if type(v) == "function" then
                    funcCount = funcCount + 1
                    FunctionScanner:scanConstants(v, 0, 
                        ("%s.%s"):format(path, tostring(k)))
                elseif type(v) == "table" and depth < 5 then
                    scanTable(v, ("%s.%s"):format(path, tostring(k)), depth + 1)
                end
            end
        end)
    end
    
    scanTable(registry, "registry", 0)
    Logger:writef("  [OK] Registry scan: %d functions found", funcCount)
end

-- ═══════════════════════════════════════════════════════════════
-- TARGET SCRIPT LOADER
-- Loads and executes the target Luraph script while capturing
-- ═══════════════════════════════════════════════════════════════
local TargetLoader = {}

function TargetLoader:loadFromString(code, scriptName)
    scriptName = scriptName or "target_script"
    Logger:section("LOADING TARGET: " .. scriptName)
    Logger:writef("  Code size: %d bytes", #code)
    
    -- Install hooks before loading
    if Config.CaptureStrings then
        StringCapture:hookStringLib()
        StringCapture:hookTableConcat()
    end
    LoadInterceptor:install()
    ExecutionTracer:install()
    
    -- Load and execute
    Logger:write("  [*] Loading target script...")
    
    local loadFn = loadstring or load
    if not loadFn then
        Logger:write("  [!] No loadstring/load function available")
        return nil
    end
    
    local func, err = loadFn(code, scriptName)
    if not func then
        Logger:writef("  [!] Failed to load: %s", tostring(err))
        return nil
    end
    
    -- Scan the loaded function before execution
    Logger:write("  [*] Pre-execution scan...")
    FunctionScanner:scanConstants(func, 0, "target_main")
    
    -- Execute with error handling
    Logger:write("  [*] Executing target script...")
    local execSuccess, execResult = pcall(func)
    
    if execSuccess then
        Logger:write("  [OK] Execution completed successfully")
        
        -- If the script returned a function/table, scan that too
        if type(execResult) == "function" then
            FunctionScanner:scanConstants(execResult, 0, "target_return_func")
        elseif type(execResult) == "table" then
            for k, v in pairs(execResult) do
                if type(v) == "function" then
                    FunctionScanner:scanConstants(v, 0, 
                        ("target_return.%s"):format(tostring(k)))
                end
            end
        end
    else
        Logger:writef("  [!] Execution error: %s", tostring(execResult))
    end
    
    -- Stop tracer
    ExecutionTracer:stop()
    
    return execResult
end

function TargetLoader:loadFromFile(filePath)
    local readfileFn = readfile or (syn and syn.readfile)
    if not readfileFn then
        Logger:write("  [!] readfile not available")
        return nil
    end
    
    local success, code = pcall(readfileFn, filePath)
    if not success or not code then
        Logger:writef("  [!] Failed to read file: %s", tostring(code))
        return nil
    end
    
    return self:loadFromString(code, filePath)
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN DUMPER ORCHESTRATOR
-- ═══════════════════════════════════════════════════════════════
local LuraphDumper = {}

function LuraphDumper.banner()
    Logger:write("--[[")
    Logger:write("  ================================================================")
    Logger:write("  =           LURAPH VM DUMPER - Output Report                    =")
    Logger:write("  =              Generated: " .. Utils.timestamp() .. string.rep(" ", 31 - #Utils.timestamp()) .. "=")
    Logger:write("  ================================================================")
    Logger:write("--]]")
end

--- Dump a Luraph-obfuscated script from a code string
--- @param code string The obfuscated Lua source code
--- @param name string Optional name for the script
function LuraphDumper.dumpFromString(code, name)
    Logger:clear()
    LuraphDumper.banner()
    
    -- Detect capabilities
    local caps = Capabilities.detect()
    Capabilities.report(caps)
    
    -- Load and capture
    TargetLoader:loadFromString(code, name or "input_script")
    
    -- Additional scans
    if Config.HookGC then
        FunctionScanner:scanGC()
    end
    MetatableScanner:scan()
    RegistryScanner:scan()
    
    -- Generate reports
    FunctionScanner:report()
    StringCapture:report()
    LoadInterceptor:report()
    ExecutionTracer:report()
    
    -- Summary
    Logger:section("SUMMARY")
    Logger:writef("  Functions scanned:   %d", FunctionScanner._funcCount)
    Logger:writef("  Strings captured:    %d", StringCapture._count)
    Logger:writef("  Loadstring captures: %d", LoadInterceptor._count)
    Logger:writef("  Trace entries:       %d", ExecutionTracer._traceCount)
    
    -- Save
    Logger:save()
    
    return Logger:getOutput()
end

--- Dump a Luraph-obfuscated script from a file
--- @param filePath string Path to the .lua file
function LuraphDumper.dumpFromFile(filePath)
    local readfileFn = readfile or (syn and syn.readfile)
    if not readfileFn then
        print("[LuraphDumper] Error: readfile not available in this executor")
        return nil
    end
    
    local success, code = pcall(readfileFn, filePath)
    if not success then
        print("[LuraphDumper] Error reading file: " .. tostring(code))
        return nil
    end
    
    return LuraphDumper.dumpFromString(code, filePath)
end

--- Scan all GC objects without loading a specific script
--- Useful after a Luraph script has already been executed
function LuraphDumper.dumpPostExecution()
    Logger:clear()
    LuraphDumper.banner()
    
    local caps = Capabilities.detect()
    Capabilities.report(caps)
    
    Logger:section("POST-EXECUTION GC DUMP")
    Logger:write("  Scanning all functions currently in memory...")
    
    FunctionScanner:scanGC()
    MetatableScanner:scan()
    RegistryScanner:scan()
    
    FunctionScanner:report()
    StringCapture:report()
    
    Logger:section("SUMMARY")
    Logger:writef("  Functions scanned:  %d", FunctionScanner._funcCount)
    Logger:writef("  Strings captured:   %d", StringCapture._count)
    
    Logger:save()
    return Logger:getOutput()
end

--- Quick-dump: Just extract all constants and strings from a function
--- @param func function The function to analyze
function LuraphDumper.quickDump(func)
    if type(func) ~= "function" then
        print("[LuraphDumper] Error: expected function, got " .. type(func))
        return
    end
    
    Logger:clear()
    Logger:write("-- Quick Dump: " .. tostring(func))
    Logger:write("")
    
    FunctionScanner:scanConstants(func, 0, "quick_dump")
    FunctionScanner:report()
    StringCapture:report()
    
    Logger:save()
    return Logger:getOutput()
end

-- ═══════════════════════════════════════════════════════════════
-- DISCORD WEBHOOK MODULE
-- Sends dump results to a Discord webhook as JSON
-- ═══════════════════════════════════════════════════════════════
local DiscordWebhook = {}

-- Minimal JSON encoder (no external dependencies)
function DiscordWebhook.jsonEncode(value)
    local t = type(value)
    
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "number" then
        if value ~= value then return "null" end -- NaN
        if value == math.huge or value == -math.huge then return "null" end
        return tostring(value)
    elseif t == "string" then
        -- Escape special JSON characters
        local escaped = value
            :gsub('\\', '\\\\')
            :gsub('"', '\\"')
            :gsub('\n', '\\n')
            :gsub('\r', '\\r')
            :gsub('\t', '\\t')
            :gsub('[%c]', function(c)
                return ('\\u%04X'):format(string.byte(c))
            end)
        return '"' .. escaped .. '"'
    elseif t == "table" then
        -- Check if array or object
        local isArray = true
        local maxIndex = 0
        for k, _ in pairs(value) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                isArray = false
                break
            end
            if k > maxIndex then maxIndex = k end
        end
        isArray = isArray and maxIndex == #value
        
        if isArray then
            local parts = {}
            for i, v in ipairs(value) do
                parts[i] = DiscordWebhook.jsonEncode(v)
            end
            return '[' .. table.concat(parts, ',') .. ']'
        else
            local parts = {}
            local idx = 0
            for k, v in pairs(value) do
                idx = idx + 1
                parts[idx] = DiscordWebhook.jsonEncode(tostring(k)) .. ':' .. DiscordWebhook.jsonEncode(v)
            end
            return '{' .. table.concat(parts, ',') .. '}'
        end
    end
    
    return '"' .. tostring(value) .. '"'
end

-- Send raw JSON payload to webhook
function DiscordWebhook.sendRaw(webhookUrl, jsonPayload)
    if not webhookUrl or webhookUrl == "" then
        print("[LuraphDumper] Error: No webhook URL configured")
        return false, "No webhook URL"
    end
    
    -- Try multiple HTTP methods available in different executors
    local httpFn = nil
    local httpMethod = "unknown"
    
    -- Method 1: syn.request (Synapse X)
    if syn and syn.request then
        httpFn = function(url, body)
            return syn.request({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end
        httpMethod = "syn.request"
    
    -- Method 2: request (generic executor)
    elseif request then
        httpFn = function(url, body)
            return request({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end
        httpMethod = "request"
    
    -- Method 3: http_request
    elseif http_request then
        httpFn = function(url, body)
            return http_request({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end
        httpMethod = "http_request"
    
    -- Method 4: HttpService (Roblox)
    elseif game and game:GetService then
        local httpService = nil
        pcall(function()
            httpService = game:GetService("HttpService")
        end)
        if httpService then
            httpFn = function(url, body)
                return { StatusCode = 200, Body = httpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson) }
            end
            httpMethod = "HttpService"
        end
    end
    
    if not httpFn then
        print("[LuraphDumper] Error: No HTTP function available (need syn.request/request/http_request)")
        return false, "No HTTP method available"
    end
    
    local success, result = pcall(httpFn, webhookUrl, jsonPayload)
    if success then
        print(("[LuraphDumper] Webhook sent via %s"):format(httpMethod))
        return true, result
    else
        print(("[LuraphDumper] Webhook failed: %s"):format(tostring(result)))
        return false, tostring(result)
    end
end

-- Send a simple text message
function DiscordWebhook.sendMessage(webhookUrl, content)
    local payload = {
        content  = content,
        username = Config.WebhookUsername,
    }
    if Config.WebhookAvatarURL and Config.WebhookAvatarURL ~= "" then
        payload.avatar_url = Config.WebhookAvatarURL
    end
    return DiscordWebhook.sendRaw(webhookUrl, DiscordWebhook.jsonEncode(payload))
end

-- Send an embed message
function DiscordWebhook.sendEmbed(webhookUrl, embed)
    local payload = {
        username = Config.WebhookUsername,
        embeds   = { embed },
    }
    if Config.WebhookAvatarURL and Config.WebhookAvatarURL ~= "" then
        payload.avatar_url = Config.WebhookAvatarURL
    end
    return DiscordWebhook.sendRaw(webhookUrl, DiscordWebhook.jsonEncode(payload))
end

-- Split long text into chunks that fit Discord's message limit
function DiscordWebhook.splitIntoChunks(text, maxLen)
    maxLen = maxLen or Config.MaxMessageLength
    local chunks = {}
    local remaining = text
    
    while #remaining > 0 do
        if #remaining <= maxLen then
            table.insert(chunks, remaining)
            break
        end
        
        -- Try to split at a newline boundary
        local splitAt = maxLen
        local newlinePos = remaining:sub(1, maxLen):find("\n[^\n]*$")
        if newlinePos and newlinePos > maxLen * 0.5 then
            splitAt = newlinePos
        end
        
        table.insert(chunks, remaining:sub(1, splitAt))
        remaining = remaining:sub(splitAt + 1)
    end
    
    return chunks
end

-- Build a summary embed from the dump data
function DiscordWebhook.buildSummaryEmbed(scriptName, dumpOutput)
    local embed = {
        title       = "Luraph VM Dump Report",
        description = ("Target: **%s**"):format(scriptName or "Unknown Script"),
        color       = Config.EmbedColor,
        fields      = {},
        footer      = {
            text = "Luraph VM Dumper v1.0 | " .. Utils.timestamp(),
        },
    }
    
    -- Extract stats from dump output
    local funcCount = dumpOutput:match("Functions scanned:%s*(%d+)") or "0"
    local strCount  = dumpOutput:match("Strings captured:%s*(%d+)") or "0"
    local loadCount = dumpOutput:match("Loadstring captures:%s*(%d+)") or "0"
    local traceCount = dumpOutput:match("Trace entries:%s*(%d+)") or "0"
    
    table.insert(embed.fields, {
        name   = "Functions Scanned",
        value  = tostring(funcCount),
        inline = true,
    })
    table.insert(embed.fields, {
        name   = "Strings Captured",
        value  = tostring(strCount),
        inline = true,
    })
    table.insert(embed.fields, {
        name   = "Loadstring Calls",
        value  = tostring(loadCount),
        inline = true,
    })
    table.insert(embed.fields, {
        name   = "Trace Entries",
        value  = tostring(traceCount),
        inline = true,
    })
    table.insert(embed.fields, {
        name   = "Dump Size",
        value  = ("%d bytes"):format(#dumpOutput),
        inline = true,
    })
    
    -- Extract some captured strings as preview (first 10)
    local preview = {}
    local count = 0
    for str in dumpOutput:gmatch('%[%d+%]%s*"([^"]+)"') do
        count = count + 1
        if count <= 10 then
            local displayStr = str
            if #displayStr > 60 then
                displayStr = displayStr:sub(1, 57) .. "..."
            end
            table.insert(preview, ("`%s`"):format(displayStr))
        end
    end
    
    if #preview > 0 then
        table.insert(embed.fields, {
            name   = "String Preview (first " .. #preview .. ")",
            value  = table.concat(preview, "\n"),
            inline = false,
        })
    end
    
    return embed
end

-- Save dump as a JSON file locally
function DiscordWebhook.saveAsJSON(dumpOutput, scriptName)
    local writefileFn = writefile or (syn and syn.writefile)
    if not writefileFn then
        print("[LuraphDumper] writefile not available, cannot save JSON")
        return nil
    end
    
    local jsonData = {
        tool       = "Luraph VM Dumper v1.0",
        timestamp  = Utils.timestamp(),
        target     = scriptName or "unknown",
        dumpSize   = #dumpOutput,
        funcCount  = FunctionScanner._funcCount,
        strCount   = StringCapture._count,
        strings    = {},
        dump       = dumpOutput,
    }
    
    -- Collect all captured strings into JSON
    for _, entry in ipairs(StringCapture._captured) do
        table.insert(jsonData.strings, {
            index  = entry.index,
            value  = entry.value,
            source = entry.source,
        })
    end
    
    local filename = ("LuraphDump_%s.json"):format(Utils.timestamp())
    local jsonStr = DiscordWebhook.jsonEncode(jsonData)
    
    local success, err = pcall(writefileFn, filename, jsonStr)
    if success then
        print(("[LuraphDumper] JSON saved to: %s"):format(filename))
        return filename, jsonStr
    else
        print(("[LuraphDumper] Failed to save JSON: %s"):format(tostring(err)))
        return nil
    end
end

--- Send dump results to a Discord webhook
--- @param webhookUrl string Discord webhook URL (optional, uses Config.WebhookURL if not provided)
--- @param scriptName string Name of the dumped script (optional)
--- @param dumpOutput string The dump output text (optional, uses last Logger output)
function LuraphDumper.sendToDiscord(webhookUrl, scriptName, dumpOutput)
    webhookUrl = webhookUrl or Config.WebhookURL
    dumpOutput = dumpOutput or Logger:getOutput()
    scriptName = scriptName or "Unknown Script"
    
    if not webhookUrl or webhookUrl == "" then
        print("[LuraphDumper] Error: No webhook URL provided.")
        print("[LuraphDumper] Set Config.WebhookURL or pass it as first argument.")
        return false
    end
    
    if not dumpOutput or dumpOutput == "" then
        print("[LuraphDumper] Error: No dump data available. Run a dump first.")
        return false
    end
    
    print("[LuraphDumper] Sending dump to Discord webhook...")
    
    -- 1) Send summary embed
    if Config.SendEmbedSummary then
        local embed = DiscordWebhook.buildSummaryEmbed(scriptName, dumpOutput)
        local ok, err = DiscordWebhook.sendEmbed(webhookUrl, embed)
        if ok then
            print("[LuraphDumper] Summary embed sent!")
        else
            print("[LuraphDumper] Failed to send embed: " .. tostring(err))
        end
        -- Small delay to avoid rate limiting
        if wait then wait(1) elseif task and task.wait then task.wait(1) end
    end
    
    -- 2) Send full dump as code blocks (chunked)
    if Config.SendAsFile then
        -- Try to send as file attachment if possible
        local chunks = DiscordWebhook.splitIntoChunks(dumpOutput, Config.MaxMessageLength - 20)
        
        for i, chunk in ipairs(chunks) do
            local header = ("**[Part %d/%d]** `%s`"):format(i, #chunks, scriptName)
            local message = header .. "\n```lua\n" .. chunk .. "\n```"
            
            -- If message is too long even with the chunk, truncate
            if #message > 2000 then
                message = header .. "\n```lua\n" .. chunk:sub(1, 1900 - #header) .. "\n...truncated\n```"
            end
            
            DiscordWebhook.sendMessage(webhookUrl, message)
            
            -- Rate limit protection
            if wait then wait(1.5) elseif task and task.wait then task.wait(1.5) end
        end
        
        print(("[LuraphDumper] Sent %d message chunks to Discord"):format(#chunks))
    end
    
    -- 3) Also save JSON locally
    DiscordWebhook.saveAsJSON(dumpOutput, scriptName)
    
    print("[LuraphDumper] Discord webhook delivery complete!")
    return true
end

--- Set the webhook URL at runtime
--- @param url string Discord webhook URL
function LuraphDumper.setWebhook(url)
    Config.WebhookURL = url
    print(("[LuraphDumper] Webhook URL set: %s...%s"):format(
        url:sub(1, 40), url:sub(-10)))
end

--- Dump a file AND send to Discord in one call
--- @param filePath string Path to the .lua file
--- @param webhookUrl string Discord webhook URL (optional)
function LuraphDumper.dumpAndSend(filePath, webhookUrl)
    local output = LuraphDumper.dumpFromFile(filePath)
    if output then
        LuraphDumper.sendToDiscord(webhookUrl, filePath, output)
    end
    return output
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO-RUN / USAGE
-- ═══════════════════════════════════════════════════════════════
--[[
    USAGE EXAMPLES:
    
    1) Dump a file:
       LuraphDumper.dumpFromFile("BF-BananaCat.lua")
    
    2) Dump from string:
       LuraphDumper.dumpFromString(your_obfuscated_code, "ScriptName")
    
    3) Dump after script already ran (scan memory):
       LuraphDumper.dumpPostExecution()
    
    4) Quick-dump a specific function:
       LuraphDumper.quickDump(someFunctionRef)
    
    5) In executor console, paste this entire script then run:
       LuraphDumper.dumpFromFile("BF-BananaCat.lua")
    
    6) Send dump to Discord webhook:
       LuraphDumper.setWebhook("https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN")
       LuraphDumper.dumpFromFile("BF-BananaCat.lua")
       LuraphDumper.sendToDiscord()
    
    7) Dump + send in one call:
       LuraphDumper.dumpAndSend("BF-BananaCat.lua", "https://discord.com/api/webhooks/...")
    
    8) Save dump as JSON file locally:
       LuraphDumper.dumpFromFile("BF-BananaCat.lua")
       -- JSON is auto-saved when sending to Discord, or call manually:
       -- DiscordWebhook.saveAsJSON(output, "ScriptName")
--]]

-- Auto-detect: if running in a Roblox executor, print ready message
if game and typeof then
    -- Running inside Roblox executor
    if rconsolecreate then rconsolecreate() end
    if rconsolesettitle then rconsolesettitle("Luraph VM Dumper v1.0") end
    print("=============================================")
    print("  Luraph VM Dumper v1.0 loaded!")
    print("  Use LuraphDumper.dumpFromFile('filename')")
    print("  or  LuraphDumper.dumpPostExecution()")
    print("=============================================")
else
    -- Running outside Roblox (standalone Lua)
    print("[LuraphDumper] Loaded in standalone mode.")
    print("[LuraphDumper] Note: Full functionality requires a Roblox executor.")
    print("[LuraphDumper] Available: LuraphDumper.dumpFromString(code)")
end

-- Export to global scope in executor environment
if getgenv then
    getgenv().LuraphDumper = LuraphDumper
end

return LuraphDumper
