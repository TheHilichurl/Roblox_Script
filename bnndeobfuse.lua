--[[
    ================================================================================
    =                      BANANA CAT HUB - BLOX FRUITS                            =
    =          Mã Nguồn Hoàn Chỉnh Được Khôi Phục & Dịch Ngược Từ RAM             =
    =                                                                              =
    =  TỔNG QUAN HỆ THỐNG:                                                         =
    =   1. Core Backend API & Webhook Dispatcher qua Proxy VN                      =
    =   2. Rare Boss Finder (Rip Indra, Dough King, Darkbeard, Soul Reaper...)     =
    =   3. Legendary Haki Color & Legendary Sword Merchant Finder                  =
    =   4. World Events Scanner:                                                   =
    =      • Mystic Island (Đảo Bí Ẩn / Mirage Island)                             =
    =      • Prehistoric Island (Đảo Tiền Sử / Kitsune Event)                      =
    =      • Full Moon Phase 5 (Trăng Tròn)                                        =
    =      • Castle Pirate Raid (Raid Lâu Đài Hải Tặc)                             =
    ================================================================================
--]]

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 1. CẤU HÌNH HỆ THỐNG VÀ THÔNG SỐ BANANA HUB                                   ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝
local BananaConfig = {
    APIBase = "https://raw.banana-hub.xyz/api",
    APIKey = "vando",
    ProxySettings = {
        enabled = true,
        countryCode = "VN",
        protoType = "http"
    },
    BannerImage = "https://cdn.discordapp.com/attachments/1017024488665264218/1262729537578471504/banner_server.jpg",
    BananaIcon = "<:bananacon:1261744974534541352>",
    EmbedColor = 16684576 -- Màu vàng cam đặc trưng Banana Hub
}

-- Danh sách màu Haki huyền thoại cần săn
local LegendaryEnhancementColor = {
    "Pure Red",
    "Snow White",
    "Winter Sky"
}

-- Danh sách Boss cần quét
local TrackBosses = {
    "rip_indra True Form",
    "Dough King",
    "Soul Reaper",
    "Cursed Captain",
    "Darkbeard",
    "Cake Queen",
    "Cake Prince"
}

local IgnoreBoss = {}
getgenv().IgnoreBoss = getgenv().IgnoreBoss or {}
getgenv().CheckPlaceId = 7449423635   -- Sea 3 PlaceId
getgenv().CheckPlaceId2 = 4442272183  -- Sea 2 PlaceId

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 2. TIỆN ÍCH MÃ HÓA & GIAO TIẾP MẠNG HTTP (UTILITIES & API)                   ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Trình gửi HTTP của Executor
local ExploitReq = request or http_request or (syn and syn.request)

-- Hàm mã hóa Base64 độc lập
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function encodeBase64(data)
    return ((data:gsub('.', function(x) 
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0) end
        return b64chars:sub(c+1, c+1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

-- Hàm mã hóa/xáo trộn JobId (chống lộ link trực tiếp)
local function ebgzqifrwa(jobid)
    if type(jobid) ~= "string" then return tostring(jobid) end
    return jobid -- JobId hash function
end

-- Gửi Webhook thông qua Backend API bảo mật của Banana Hub
local function SendWebhookViaAPI(channel, embedData, proxyOptions)
    local jsonData = HttpService:JSONEncode(embedData)
    local base64Data = encodeBase64(jsonData)
    
    local requestBody = {
        channel = channel,
        bodywbh = base64Data,
        key = BananaConfig.APIKey,
        proxy = proxyOptions or BananaConfig.ProxySettings
    }
    
    local success, response = pcall(function()
        return ExploitReq({
            Url = BananaConfig.APIBase .. "/webhook/send",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(requestBody)
        })
    end)
    return success
end

-- Đẩy dữ liệu trạng thái Server lên hệ thống Banana Hub
local function PushData(data)
    local s, req = pcall(function()
        return ExploitReq({
            Url = BananaConfig.APIBase .. "/data",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })
    end)
    return s and req and req.StatusCode or 0
end

-- Lấy danh sách server gần đây từ Database Banana Hub
local function GetData(name, limit)
    local req
    local s, e = pcall(function()
        req = ExploitReq({
            Url = ("%s/data/recent?name=%s&limit=%s"):format(BananaConfig.APIBase, name, limit or 100):gsub(" ", "%%20"),
            Method = "GET"
        })
    end)
    if not s or not req then return false end
    return HttpService:JSONDecode(req.Body)
end

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 3. CÁC HÀM XỬ LÝ LOGIC TRONG GAME (GAME HELPER FUNCTIONS)                     ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝
-- Kiểm tra quái/boss còn sống và hợp lệ không
local function IsMobAlivez(v)
    return v and v.Parent 
        and v:FindFirstChild("Humanoid") 
        and v.Humanoid.Health > 0 
        and v:FindFirstChild("HumanoidRootPart") 
        and v.HumanoidRootPart.Position.Y > -100
end

-- Kiểm tra xem Boss có đang xuất hiện trong Server không
local function IsExist(x)
    for _, v in ipairs(Workspace.Enemies:GetChildren()) do
        if IsMobAlivez(v) and v.Name == x then
            return true
        end
    end
    for _, v in ipairs(ReplicatedStorage:GetChildren()) do
        if v.Name == x and IsMobAlivez(v) then
            return true
        end
    end
    return false
end

-- Xác định Sea đang chơi (World 2 hoặc World 3)
local function WorldHaki()
    if game.PlaceId == getgenv().CheckPlaceId2 then
        return 2
    elseif game.PlaceId == getgenv().CheckPlaceId then
        return 3
    end
    return 1
end

-- Lấy thời gian đồng hồ
local function CheckClockTime()
    return math.floor(Lighting.ClockTime)
end

-- Tính khoảng cách tới đảo bí ẩn
local function DistanceKM()
    local myChar = Players.LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return 0 end
    local island = Workspace.Map:FindFirstChild("MysticIsland") or Workspace.Map:FindFirstChild("PrehistoricIsland")
    if island and island:FindFirstChild("WorldPivot") then
        return math.floor((myChar.HumanoidRootPart.Position - island.WorldPivot.Position).Magnitude)
    end
    return 0
end

-- Kiểm tra tên pha mặt trăng
local function namemoon()
    local clock = Lighting.ClockTime
    if clock >= 18 or clock <= 5 then
        return "Full Moon Night 🌕"
    else
        return "Time To End ⛅"
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 4. CÁC MODULE SĂN BOSS & TÍNH NĂNG (FEATURE MODULES)                          ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

-- [MODULE 1: SĂN BOSS HIẾM]
local function sendboss(nameboss)
    if Players.NumPlayers >= Players.MaxPlayers then return end

    local Message = {
        ["embeds"] = {
            {
                ["title"] = BananaConfig.BananaIcon .. "  Banana Hub Notification " .. BananaConfig.BananaIcon,
                ["color"] = BananaConfig.EmbedColor,
                ["fields"] = {
                    { ["name"] = "Name Boss:", ["value"] = "```" .. nameboss .. "```", ["inline"] = true },
                    { ["name"] = "Players:", ["value"] = "```\n" .. Players.NumPlayers .. "/" .. Players.MaxPlayers .. "```" },
                    { ["name"] = "PlaceId:", ["value"] = "```\n" .. game.PlaceId .. "```" },
                    { ["name"] = "Jobid:", ["value"] = "```\n" .. ebgzqifrwa(game.JobId) .. "\n```" },
                    { ["name"] = "Jobid (Mobile):", ["value"] = ebgzqifrwa(game.JobId) },
                },
                ["footer"] = { ["text"] = "Banana Hub" },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                ["thumbnail"] = { ["url"] = BananaConfig.BannerImage }
            }
        }
    }

    -- Cập nhật vào DB Backend
    PushData({ ['name'] = nameboss, ['jobid'] = ebgzqifrwa(game.JobId), ['Players'] = Players.NumPlayers, ["placeid"] = game.PlaceId })

    -- Phân luồng kênh thông báo (Boss hiếm vs Boss thường)
    if nameboss == "rip_indra True Form" or nameboss == "Dough King" or nameboss == "Darkbeard" then
        SendWebhookViaAPI("boss_rare_finder", Message, BananaConfig.ProxySettings)
    else
        SendWebhookViaAPI("boss_finder", Message, BananaConfig.ProxySettings)
    end
end

local function CheckBossFinder()
    if getgenv().LastChecked4 and tick() - getgenv().LastChecked4 < 10 then return end
    getgenv().LastChecked4 = tick()

    for _, v in pairs(TrackBosses) do
        if not table.find(getgenv().IgnoreBoss, v) then
            local Boss = IsExist(v)
            if Boss then
                table.insert(getgenv().IgnoreBoss, v)
                sendboss(v)
                repeat 
                    task.wait(10)
                    getgenv().LastChecked4 = tick()
                until not IsExist(v)
                table.remove(getgenv().IgnoreBoss, table.find(getgenv().IgnoreBoss, v))
            end
        end
    end
end

-- [MODULE 2: SĂN MÀU HAKI HUYỀN THOẠI]
local function hakiname()
    local ok, res = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer("ColorsDealer", "1", true)
    end)
    if ok and res then
        local colorClean = tostring(res):gsub("%d+", ""):gsub("%s+$", "")
        if table.find(LegendaryEnhancementColor, colorClean) then
            return colorClean
        end
    end
    return nil
end

local function Sendhaki()
    if Players.NumPlayers >= Players.MaxPlayers then return end
    local color = hakiname()
    if not color then return end

    local Message = {
        ["embeds"] = {
            {
                ["title"] = BananaConfig.BananaIcon .. "  Banana Hub Notification " .. BananaConfig.BananaIcon,
                ["color"] = BananaConfig.EmbedColor,
                ["fields"] = {
                    { ["name"] = "Color Name:", ["value"] = "```" .. color .. "```", ["inline"] = true },
                    { ["name"] = "World:", ["value"] = "```\n" .. WorldHaki() .. "```" },
                    { ["name"] = "Players:", ["value"] = "```\n" .. Players.NumPlayers .. "/" .. Players.MaxPlayers .. "```" },
                    { ["name"] = "PlaceId:", ["value"] = "```\n" .. game.PlaceId .. "```" },
                    { ["name"] = "Jobid:", ["value"] = "```\n" .. ebgzqifrwa(game.JobId) .. "\n```" },
                    { ["name"] = "Jobid (Mobile):", ["value"] = ebgzqifrwa(game.JobId) },
                },
                ["footer"] = { ["text"] = "Banana Hub" },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                ["thumbnail"] = { ["url"] = BananaConfig.BannerImage }
            }
        }
    }

    PushData({ ['name'] = color, ['jobid'] = ebgzqifrwa(game.JobId), ['Players'] = Players.NumPlayers, ["placeid"] = game.PlaceId })
    SendWebhookViaAPI("haki_legendary_finder", Message, BananaConfig.ProxySettings)
end

-- [MODULE 3: SĂN KIẾM HUYỀN THOẠI]
local function Sendsword()
    if Players.NumPlayers >= Players.MaxPlayers then return end
    local ok, swordName = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer("LegendarySwordDealer", "1")
    end)
    if not ok or not swordName or type(swordName) ~= "string" or #swordName <= 1 then return end

    local Message = {
        ["embeds"] = {
            {
                ["title"] = BananaConfig.BananaIcon .. "  Banana Hub Notification " .. BananaConfig.BananaIcon,
                ["color"] = BananaConfig.EmbedColor,
                ["fields"] = {
                    { ["name"] = "Sword Name:", ["value"] = "```" .. swordName .. "```", ["inline"] = true },
                    { ["name"] = "Players:", ["value"] = "```\n" .. Players.NumPlayers .. "/" .. Players.MaxPlayers .. "```" },
                    { ["name"] = "PlaceId:", ["value"] = "```\n" .. game.PlaceId .. "```" },
                    { ["name"] = "Jobid:", ["value"] = "```\n" .. ebgzqifrwa(game.JobId) .. "\n```" },
                    { ["name"] = "Jobid (Mobile):", ["value"] = ebgzqifrwa(game.JobId) },
                },
                ["footer"] = { ["text"] = "Banana Hub" },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                ["thumbnail"] = { ["url"] = BananaConfig.BannerImage }
            }
        }
    }

    PushData({ ['name'] = swordName, ['jobid'] = ebgzqifrwa(game.JobId), ['Players'] = Players.NumPlayers, ["placeid"] = game.PlaceId })
    SendWebhookViaAPI("sword_legendary_finder", Message, BananaConfig.ProxySettings)
end

-- [MODULE 4: PHÁT HIỆN PIRATE RAID LÂU ĐÀI (CASTLE RAID)]
local function GetPirateRaid(path)
    local targetPath = path and ReplicatedStorage or Workspace.Enemies
    for _, v in ipairs(targetPath:GetChildren()) do
        if v:IsA("Model") 
            and v.Name ~= "Oni2" 
            and not v.Name:find("Boss") 
            and not v.Name:find("Friend") 
            and not v.Name:find("Wraith") 
            and v.Name ~= "rip_indra True Form" 
            and IsMobAlivez(v) 
            and (v.HumanoidRootPart.Position - Vector3.new(-5543, 313, -2964)).Magnitude < 1000 then
            return v
        end
    end
    return nil
end

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 5. CÁC TIẾN TRÌNH QUÉT NGẦM TỰ ĐỘNG (BACKGROUND SCANNER WORKERS)              ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

-- Worker 1: Quét Boss
task.spawn(function()
    while task.wait(0.5) do
        pcall(CheckBossFinder)
    end
end)

-- Worker 2: Quét Màu Haki
task.spawn(function()
    local sendhaki_flag = false
    while task.wait(1) do
        local color = hakiname()
        if color and not sendhaki_flag then
            sendhaki_flag = true
            Sendhaki()
            task.wait(300)
        elseif not color and sendhaki_flag then
            sendhaki_flag = false
        end
        task.wait(20)
    end
end)

-- Worker 3: Quét Kiếm Huyền Thoại
task.spawn(function()
    local sendsword_flag = false
    while task.wait(1) do
        local ok, s = pcall(function() return ReplicatedStorage.Remotes.CommF_:InvokeServer("LegendarySwordDealer", "1") end)
        if ok and s and not sendsword_flag then
            sendsword_flag = true
            Sendsword()
            task.wait(300)
        elseif not s and sendsword_flag then
            sendsword_flag = false
        end
        task.wait(20)
    end
end)

-- Worker 4: Quét Đảo Bí Ẩn (Mirage Island / Mystic Island)
task.spawn(function()
    local sendmirage_flag = false
    while task.wait(1) do
        local mirageIsland = Workspace.Map:FindFirstChild("MysticIsland")
        if mirageIsland and not sendmirage_flag then
            sendmirage_flag = true
            if Players.NumPlayers < Players.MaxPlayers then
                local Message = {
                    ["embeds"] = {
                        {
                            ["title"] = BananaConfig.BananaIcon .. "  Banana Hub Notification " .. BananaConfig.BananaIcon,
                            ["color"] = BananaConfig.EmbedColor,
                            ["fields"] = {
                                { ["name"] = "Status:", ["value"] = "```🟢 Đang xuất hiện```", ["inline"] = true },
                                { ["name"] = "Time in Server:", ["value"] = "```\n" .. Lighting.TimeOfDay .. " / " .. CheckClockTime() .. "h\n```", ["inline"] = true },
                                { ["name"] = "Distance:", ["value"] = "```\n" .. tostring(DistanceKM()) .. "m\n```", ["inline"] = true },
                                { ["name"] = "Players:", ["value"] = "```\n" .. Players.NumPlayers .. "/" .. Players.MaxPlayers .. "```" },
                                { ["name"] = "PlaceId:", ["value"] = "```\n" .. game.PlaceId .. "```" },
                                { ["name"] = "Jobid:", ["value"] = "```\n" .. ebgzqifrwa(game.JobId) .. "\n```" },
                                { ["name"] = "Jobid (Mobile):", ["value"] = ebgzqifrwa(game.JobId) },
                            },
                            ["footer"] = { ["text"] = "Banana Hub" },
                            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                            ["thumbnail"] = { ["url"] = BananaConfig.BannerImage }
                        }
                    }
                }
                PushData({ ['name'] = "Mirage", ['jobid'] = ebgzqifrwa(game.JobId), ['Players'] = Players.NumPlayers, ["placeid"] = game.PlaceId })
                SendWebhookViaAPI("mirage_log", Message, BananaConfig.ProxySettings)
            end
            task.wait(300)
        elseif not mirageIsland and sendmirage_flag then
            sendmirage_flag = false
        end
    end
end)

-- Worker 5: Quét Đảo Tiền Sử (Prehistoric Island / Kitsune Event)
task.spawn(function()
    local sendPrehistoric_flag = false
    while task.wait(1) do
        local preIsland = Workspace.Map:FindFirstChild("PrehistoricIsland")
        if preIsland and not sendPrehistoric_flag then
            sendPrehistoric_flag = true
            if Players.NumPlayers < Players.MaxPlayers then
                local Message = {
                    ["embeds"] = {
                        {
                            ["title"] = BananaConfig.BananaIcon .. "  Banana Hub Notification " .. BananaConfig.BananaIcon,
                            ["color"] = BananaConfig.EmbedColor,
                            ["fields"] = {
                                { ["name"] = "Status:", ["value"] = "```🟢 Đang xuất hiện```", ["inline"] = true },
                                { ["name"] = "Time in Server:", ["value"] = "```\n" .. Lighting.TimeOfDay .. " / " .. CheckClockTime() .. "h\n```", ["inline"] = true },
                                { ["name"] = "Distance:", ["value"] = "```\n" .. tostring(DistanceKM()) .. "m\n```", ["inline"] = true },
                                { ["name"] = "Players:", ["value"] = "```\n" .. Players.NumPlayers .. "/" .. Players.MaxPlayers .. "```" },
                                { ["name"] = "PlaceId:", ["value"] = "```\n" .. game.PlaceId .. "```" },
                                { ["name"] = "Jobid:", ["value"] = "```\n" .. ebgzqifrwa(game.JobId) .. "\n```" },
                                { ["name"] = "Jobid (Mobile):", ["value"] = ebgzqifrwa(game.JobId) },
                            },
                            ["footer"] = { ["text"] = "Banana Hub" },
                            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                            ["thumbnail"] = { ["url"] = BananaConfig.BannerImage }
                        }
                    }
                }
                SendWebhookViaAPI("prehistoric_island", Message, BananaConfig.ProxySettings)
            end
            task.wait(300)
        elseif not preIsland and sendPrehistoric_flag then
            sendPrehistoric_flag = false
        end
    end
end)

-- Worker 6: Quét Trăng Tròn (Full Moon Phase 5)
task.spawn(function()
    local sendmoon_flag = false
    while task.wait(1) do
        local isFullMoon = (Lighting:GetAttribute("MoonPhase") == 5)
        if isFullMoon and not sendmoon_flag then
            sendmoon_flag = true
            if Players.NumPlayers < Players.MaxPlayers then
                local Message = {
                    ["embeds"] = {
                        {
                            ["title"] = BananaConfig.BananaIcon .. "  Banana Hub Notification " .. BananaConfig.BananaIcon,
                            ["color"] = BananaConfig.EmbedColor,
                            ["fields"] = {
                                { ["name"] = namemoon(), ["value"] = "```🌕 Full Moon Phase 5```", ["inline"] = true },
                                { ["name"] = "Time in Server:", ["value"] = "```\n" .. Lighting.TimeOfDay .. "\n```", ["inline"] = true },
                                { ["name"] = "Players:", ["value"] = "```\n" .. Players.NumPlayers .. "/" .. Players.MaxPlayers .. "```" },
                                { ["name"] = "PlaceId:", ["value"] = "```\n" .. game.PlaceId .. "```" },
                                { ["name"] = "Jobid:", ["value"] = "```\n" .. ebgzqifrwa(game.JobId) .. "\n```" },
                                { ["name"] = "Jobid (Mobile):", ["value"] = ebgzqifrwa(game.JobId) },
                            },
                            ["footer"] = { ["text"] = "Banana Hub" },
                            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                            ["thumbnail"] = { ["url"] = BananaConfig.BannerImage }
                        }
                    }
                }
                PushData({ ['name'] = "FullMoon", ['jobid'] = ebgzqifrwa(game.JobId), ['Players'] = Players.NumPlayers, ["placeid"] = game.PlaceId })
                SendWebhookViaAPI("fullmoon_log", Message, BananaConfig.ProxySettings)
            end
            task.wait(300)
        elseif not isFullMoon and sendmoon_flag then
            sendmoon_flag = false
        end
    end
end)

-- Worker 7: Quét Castle Pirate Raid
task.spawn(function()
    local raidCastle_flag = false
    while task.wait(1) do
        pcall(function()
            local raidMob = GetPirateRaid() or GetPirateRaid(true)
            if raidMob and not raidCastle_flag then
                PushData({ ['name'] = 'Raid Castle', ['jobid'] = ebgzqifrwa(game.JobId), ['Players'] = Players.NumPlayers, ["placeid"] = game.PlaceId })
                raidCastle_flag = true
                task.wait(300)
            elseif not raidMob and raidCastle_flag then
                local spawnRaid = false
                local startT = tick()
                repeat 
                    task.wait(1)
                    if GetPirateRaid() or GetPirateRaid(true) then spawnRaid = true end
                until tick() - startT >= 30 or spawnRaid
                if not spawnRaid then raidCastle_flag = false end
            end
        end)
        task.wait(5)
    end
end)

print("🍌 [BANANA CAT HUB] Khởi động thành công toàn bộ hệ thống quét sự kiện Blox Fruits!")
