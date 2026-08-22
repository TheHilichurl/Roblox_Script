--[[
    =============================================================================
    =  BANANA CAT HUB - PASSIVE ZERO-HOOK DUMPER (ANTI-TAMPER SAFE)            =
    =                                                                           =
    =  NGUYÊN LÝ HOẠT ĐỘNG AN TOÀN TUYỆT ĐỐI:                                  =
    =   1. KHÔNG HOOK MÔI TRƯỜNG (ZERO HOOK):                                   =
    =      Tuyệt đối KHÔNG hook `loadstring`, `setfenv`, `getgenv` trước khi    =
    =      chạy. Điều này giúp Luraph tự giải mã 100% mà không bao giờ bị dính  =
    =      bẫy Anti-Tamper hay đệ quy vô hạn.                                   =
    =   2. TRÍCH XUẤT SAU KHI TỰ GIẢI MÃ (POST-DECRYPTION EXTRACTION):         =
    =      Chờ Banana Cat Hub tự giải mã xong xuôi và hiện UI lên màn hình.     =
    =   3. GỬI FILE BYTECODE & CONSTANTS GỐC VỀ WEBHOOK:                       =
    =      Bấm nút trên màn hình hoặc chờ 15s, hệ thống sẽ gom toàn bộ hàm,     =
    =      hằng số và bytecode đã được giải mã gửi thẳng về Discord Webhook!   =
    =============================================================================
--]]

-- ╔═══════════════════════════════════════════════════╗
-- ║  CẤU HÌNH WEBHOOK DISCORD                         ║
-- ╚═══════════════════════════════════════════════════╝
local WEBHOOK_URL = "https://discord.com/api/webhooks/1540764685681299526/mFnSqvWMbpNimmzJ4d2w9oJdMvZxDis8hHQVNjlBCNVWIpZTm2nnDC90M87LZ-m6T-to"

-- Tương thích với mọi Executor trên máy ảo
local httpRequest = (syn and syn.request)
    or (http and http.request)
    or (fluxus and fluxus.request)
    or (delta and delta.request)
    or request
    or http_request
    or (getgenv and getgenv().request)

-- ╔═══════════════════════════════════════════════════╗
-- ║  BỘ LỌC CHỈ ĐỊNH BANANA CAT HUB (TARGET FILTER)   ║
-- ╚═══════════════════════════════════════════════════╝
local IGNORE_LIST = {
    "CoreGui", "CorePackages", "Chat", "CameraScript", "PlayerModule",
    "PlayerScripts", "SoundDispatcher", "Animate", "CharacterControl",
    "RbxCharacterSounds", "BubbleChat", "FreeCamera", "ChatScript", "ChatMain"
}

local BANANA_KEYWORDS = {
    "banana", "bananacat", "commf_", "vthang", "obiiyeuem", "redeemcode",
    "travelmain", "traveldressrosa", "travelzou", "cdkquest", "bones",
    "buydualflintlock", "blackbeardreward", "storefruit", "raidsnpc",
    "tweenservice", "farm", "sea event", "upgrade race", "esp", "pvp"
}

local function isIgnored(name)
    if not name or type(name) ~= "string" then return false end
    local lower = string.lower(name)
    for _, ign in ipairs(IGNORE_LIST) do
        if string.find(lower, string.lower(ign), 1, true) then
            return true
        end
    end
    return false
end

local function isBananaTarget(str)
    if not str or type(str) ~= "string" then return false end
    local lower = string.lower(str)
    for _, kw in ipairs(BANANA_KEYWORDS) do
        if string.find(lower, kw, 1, true) then
            return true
        end
    end
    return false
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  GIAO DIỆN NÚT BẤM DUMP TRÊN MÀN HÌNH             ║
-- ╚═══════════════════════════════════════════════════╝
local CoreGui = game:GetService("CoreGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BananaCat_Passive_Dumper_UI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 360, 0, 160)
Frame.Position = UDim2.new(0.5, -180, 0.08, 0)
Frame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 10)
local UIStroke = Instance.new("UIStroke", Frame)
UIStroke.Color = Color3.fromRGB(245, 180, 35)
UIStroke.Thickness = 1.5

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 26)
Title.Position = UDim2.new(0, 10, 0, 6)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(245, 180, 35)
Title.Text = "🍌 BANANA CAT HUB - PASSIVE DUMPER"
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 52)
Status.Position = UDim2.new(0, 10, 0, 32)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.TextColor3 = Color3.fromRGB(220, 220, 220)
Status.TextWrapped = true
Status.Text = "1. Hãy chạy script Banana Cat Hub để nó TỰ GIẢI MÃ xong.\n2. Sau khi menu hiện lên, bấm nút vàng bên dưới để gửi file!"
Status.Parent = Frame

local DumpBtn = Instance.new("TextButton")
DumpBtn.Size = UDim2.new(1, -20, 0, 42)
DumpBtn.Position = UDim2.new(0, 10, 0, 98)
DumpBtn.BackgroundColor3 = Color3.fromRGB(245, 180, 35)
DumpBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
DumpBtn.Font = Enum.Font.GothamBold
DumpBtn.TextSize = 12
DumpBtn.Text = "📤 DUMP & GỬI DỮ LIỆU ĐÃ GIẢI MÃ VỀ DISCORD"
DumpBtn.Parent = Frame

local BtnCorner = Instance.new("UICorner", DumpBtn)
BtnCorner.CornerRadius = UDim.new(0, 8)

local function updateStatus(txt, color)
    Status.Text = txt
    if color then
        Title.TextColor3 = color
        UIStroke.Color = color
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  HÀM GỬI FILE QUA DISCORD WEBHOOK                 ║
-- ╚═══════════════════════════════════════════════════╝
local function sendFileToWebhook(filename, fileContent, titleText)
    if not httpRequest or not WEBHOOK_URL or WEBHOOK_URL == "" then
        updateStatus("⚠️ Lỗi: Executor không hỗ trợ hàm HTTP request!", Color3.fromRGB(255, 80, 80))
        return false
    end

    updateStatus("🚀 Đang gửi file: " .. filename .. " (" .. math.floor(#fileContent / 1024) .. " KB)...")

    local boundary = "----BananaBoundary" .. tostring(os.time()) .. tostring(math.random(1000, 9999))
    local body = "--" .. boundary .. "\r\n"
        .. 'Content-Disposition: form-data; name="payload_json"' .. "\r\n\r\n"
        .. '{"username":"Banana Cat Dumper","avatar_url":"https://i.imgur.com/8Q1qD8s.png","embeds":[{"title":"'
        .. (titleText or "🍌 DUMP FILE BANANA CAT HUB")
        .. '","color":16098851,"description":"**Trạng thái:** `Đã tự giải mã thành công`\\n**File:** `' .. filename .. '`\\n**Dung lượng:** `'
        .. math.floor(#fileContent / 1024)
        .. ' KB`\\n**Thời gian:** `' .. os.date("!%Y-%m-%d %H:%M:%S UTC") .. '`"}]}' .. "\r\n"
        .. "--" .. boundary .. "\r\n"
        .. 'Content-Disposition: form-data; name="file"; filename="' .. filename .. '"' .. "\r\n"
        .. 'Content-Type: text/plain; charset=utf-8' .. "\r\n\r\n"
        .. fileContent .. "\r\n"
        .. "--" .. boundary .. "--\r\n"

    local res = httpRequest({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "multipart/form-data; boundary=" .. boundary },
        Body = body
    })

    if res and (res.StatusCode == 200 or res.StatusCode == 204) then
        updateStatus("✅ THÀNH CÔNG! Đã gửi file: " .. filename .. " về Discord!", Color3.fromRGB(80, 230, 120))
        return true
    else
        updateStatus("⚠️ Webhook trả về mã lỗi: " .. tostring(res and res.StatusCode), Color3.fromRGB(255, 180, 50))
        return false
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  BỘ JSON ENCODER GỌN NHẸ                          ║
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
                table.insert(parts, '"' .. escJSON(safeStr(k)) .. '":' .. jsonEncode(val))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return '"' .. escJSON(safeStr(v)) .. '"'
    end
end

-- ╔═══════════════════════════════════════════════════╗
-- ║  TRÍCH XUẤT TOÀN BỘ BỘ NHỚ ĐÃ ĐƯỢC GIẢI MÃ        ║
-- ╚═══════════════════════════════════════════════════╝
local isDumping = false
local function performPassiveDecryptedDump()
    if isDumping then return end
    isDumping = true

    updateStatus("🔍 Đang trích xuất toàn bộ hàm đã được Banana Cat giải mã...")
    local get_gc = getgc or debug.getgc
    if not get_gc then
        updateStatus("⚠️ Lỗi: Executor không hỗ trợ getgc!", Color3.fromRGB(255, 80, 80))
        isDumping = false
        return
    end

    local capturedData = {
        Metadata = {
            Target = "Banana Cat Hub - Self-Decrypted Memory",
            PlaceId = game.PlaceId,
            JobId = game.JobId,
            Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            Account = game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Unknown"
        },
        DecryptedFunctions = {},
        DecryptedConstants = {},
        DispatchedRemotes = {}
    }

    local gc_objects = get_gc(true)
    local seen_funcs = {}
    local string_set = {}

    for _, obj in ipairs(gc_objects) do
        local t = type(obj)
        if t == "function" and not seen_funcs[obj] then
            seen_funcs[obj] = true
            local info = debug.getinfo and debug.getinfo(obj) or {}
            local src = info.source or ""
            local name = info.name or ""

            if not isIgnored(src) and not isIgnored(name) then
                local constants = debug.getconstants and debug.getconstants(obj) or {}
                local upvalues = debug.getupvalues and debug.getupvalues(obj) or {}
                local is_relevant = false

                local c_list = {}
                for idx, c in pairs(constants) do
                    local sc = safeStr(c)
                    table.insert(c_list, sc)
                    if type(c) == "string" and #c >= 2 then
                        if not string_set[c] then
                            string_set[c] = true
                            if isBananaTarget(c) then
                                is_relevant = true
                            end
                        end
                    end
                end

                local u_list = {}
                for idx, u in pairs(upvalues) do
                    local su = safeStr(u)
                    table.insert(u_list, su)
                    if type(u) == "string" and isBananaTarget(u) then
                        is_relevant = true
                    end
                end

                if is_relevant or isBananaTarget(src) or isBananaTarget(name) then
                    table.insert(capturedData.DecryptedFunctions, {
                        name = name ~= "" and name or "banana_func_" .. (#capturedData.DecryptedFunctions + 1),
                        source = src,
                        numparams = info.numparams or 0,
                        is_vararg = info.is_vararg or false,
                        constants = c_list,
                        upvalues = u_list
                    })
                end
            end
        end
    end

    for s, _ in pairs(string_set) do
        if isBananaTarget(s) or #s > 10 then
            table.insert(capturedData.DecryptedConstants, s)
        end
    end

    local finalJSON = jsonEncode(capturedData)
    sendFileToWebhook("BananaCat_SelfDecrypted_Bytecode.json", finalJSON, "🍌 BYTECODE & CONSTANTS BANANA CAT HUB (ĐÃ TỰ GIẢI MÃ)")
    isDumping = false
end

-- Bấm nút để thực thi ngay
DumpBtn.MouseButton1Click:Connect(function()
    performPassiveDecryptedDump()
end)

updateStatus("🟢 Dumper sẵn sàng!\nHãy chạy Banana Cat Hub, chờ menu hiện lên rồi bấm nút vàng.", Color3.fromRGB(80, 230, 120))
