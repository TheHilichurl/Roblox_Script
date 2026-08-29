local Config = {
    ServiceId       = 30571,
    Secret          = "HilichurlAuthSecret",
    WorkerAuthURL   = "https://bfscript.vinhgiang782007.workers.dev",
    ShowDiscord     = true,
    DiscordURL      = "https://discord.gg/xU28wb8z4n",
    ShowYoutube     = false,
    YoutubeURL      = "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    KeyFileName     = "hilichurl_key.txt",
    OldGuiName      = "HilichurlKeyLoader",
    MainGuiName     = "HilichurlHubGui",
    HubName         = "HILICHURL HUB",
    HubDescription  = "Blox Fruits | Sea Events & Leviathan"
}

local a=2^32;local b=a-1;local function c(d,e)local f,g=0,1;while d~=0 or e~=0 do local h,i=d%2,e%2;local j=(h+i)%2;f=f+j*g;d=math.floor(d/2)e=math.floor(e/2)g=g*2 end;return f%a end;local function k(d,e,l,...)local m;if e then d=d%a;e=e%a;m=c(d,e)if l then m=k(m,l,...)end;return m elseif d then return d%a else return 0 end end;local function n(d,e,l,...)local m;if e then d=d%a;e=e%a;m=(d+e-c(d,e))/2;if l then m=n(m,l,...)end;return m elseif d then return d%a else return b end end;local function o(p)return b-p end;local function q(d,r)if r<0 then return lshift(d,-r)end;return math.floor(d%2^32/2^r)end;local function s(p,r)if r>31 or r<-31 then return 0 end;return q(p%a,r)end;local function lshift(d,r)if r<0 then return s(d,-r)end;return d*2^r%2^32 end;local function t(p,r)p=p%a;r=r%32;local u=n(p,2^r-1)return s(p,r)+lshift(u,32-r)end;local v={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}local function w(x)return string.gsub(x,".",function(l)return string.format("%02x",string.byte(l))end)end;local function y(z,A)local x=""for B=1,A do local C=z%256;x=string.char(C)..x;z=(z-C)/256 end;return x end;local function D(x,B)local A=0;for B=B,B+3 do A=A*256+string.byte(x,B)end;return A end;local function E(F,G)local H=64-(G+9)%64;G=y(8*G,8)F=F.."\128"..string.rep("\0",H)..G;assert(#F%64==0)return F end;local function I(J)J[1]=0x6a09e667;J[2]=0xbb67ae85;J[3]=0x3c6ef372;J[4]=0xa54ff53a;J[5]=0x510e527f;J[6]=0x9b05688c;J[7]=0x1f83d9ab;J[8]=0x5be0cd19;return J end;local function K(F,B,J)local L={}for M=1,16 do L[M]=D(F,B+(M-1)*4)end;for M=17,64 do local N=L[M-15]local O=k(t(N,7),t(N,18),s(N,3))N=L[M-2]L[M]=(L[M-16]+O+L[M-7]+k(t(N,17),t(N,19),s(N,10)))%a end;local d,e,l,P,Q,R,S,T=J[1],J[2],J[3],J[4],J[5],J[6],J[7],J[8]for B=1,64 do local O=k(t(d,2),t(d,13),t(d,22))local U=k(n(d,e),n(d,l),n(e,l))local V=(O+U)%a;local W=k(t(Q,6),t(Q,11),t(Q,25))local X=k(n(Q,R),n(o(Q),S))local Y=(T+W+X+v[B]+L[B])%a;T=S;S=R;R=Q;Q=(P+Y)%a;P=l;l=e;e=d;d=(Y+V)%a end;J[1]=(J[1]+d)%a;J[2]=(J[2]+e)%a;J[3]=(J[3]+l)%a;J[4]=(J[4]+P)%a;J[5]=(J[5]+Q)%a;J[6]=(J[6]+R)%a;J[7]=(J[7]+S)%a;J[8]=(J[8]+T)%a end;local function Z(F)F=E(F,#F)local J=I({})for B=1,#F,64 do K(F,B,J)end;return w(y(J[1],4)..y(J[2],4)..y(J[3],4)..y(J[4],4)..y(J[5],4)..y(J[6],4)..y(J[7],4)..y(J[8],4))end;
local lDigest = Z

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local function safeRequest(options)
    local req = request or http_request or syn_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
    if not req then return nil, "HTTP requests not supported" end
    local success, response = pcall(function() return req(options) end)
    if success and type(response) == "table" then 
        return response 
    else 
        return nil, "Connection Error: " .. tostring(response or "Unknown") 
    end
end

local fSetClipboard = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set) or function() end
local fGetClipboard = function()
    local text = ""
    pcall(function()
        if getclipboard then text = tostring(getclipboard())
        elseif get_clipboard then text = tostring(get_clipboard())
        elseif fromclipboard then text = tostring(fromclipboard())
        elseif syn and syn.getclipboard then text = tostring(syn.getclipboard())
        elseif fluxus and fluxus.get_clipboard then text = tostring(fluxus.get_clipboard())
        elseif Clipboard and Clipboard.get then text = tostring(Clipboard.get())
        elseif Clipboard and Clipboard.getText then text = tostring(Clipboard.getText())
        end
    end)
    return text or ""
end

local fGetHwid = function()
    local hwid = ""
    pcall(function()
        if gethwid then hwid = tostring(gethwid())
        elseif getgenv and getgenv().gethwid then hwid = tostring(getgenv().gethwid())
        elseif game:GetService("RbxAnalyticsService") and game:GetService("RbxAnalyticsService").GetClientId then
            hwid = tostring(game:GetService("RbxAnalyticsService"):GetClientId())
        end
    end)
    if not hwid or hwid == "" then
        hwid = tostring(Players.LocalPlayer.UserId)
    end
    hwid = string.gsub(hwid, "[{}]", "")
    hwid = string.gsub(hwid, "%s+", "")
    return hwid
end

local function generateNonce()
    local str = ""
    for _ = 1, 16 do 
        str = str .. string.char(math.floor(math.random() * (122 - 97 + 1)) + 97) 
    end
    return str .. "_" .. tostring(os.time())
end

local function FormatRemainingTime(seconds)
    if not seconds or seconds <= 0 then return "Expired" end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)

    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, mins)
    elseif hours > 0 then
        return string.format("%dh %dm %ds", hours, mins, secs)
    elseif mins > 0 then
        return string.format("%dm %ds", mins, secs)
    else
        return string.format("%ds", secs)
    end
end

local cachedLink, cachedTime = "", 0
local host = "https://api.platoboost.com"

local function checkConnectivity()
    local response, err = safeRequest({Url = host .. "/public/connectivity", Method = "GET"})
    if not response or (response.StatusCode ~= 200 and response.StatusCode ~= 429) then
        host = "https://api.platoboost.net"
        local fallbackResponse, fallbackErr = safeRequest({Url = host .. "/public/connectivity", Method = "GET"})
        if not fallbackResponse then return false end
    end
    return true
end

local function cacheLink()
    local isConnected = checkConnectivity()
    if not isConnected then return false, "Network Error" end
    
    if cachedTime + (10 * 60) < os.time() or cachedLink == "" then
        local rawHwid = fGetHwid()
        local hashedIdentifier = lDigest(rawHwid)

        local response, err = safeRequest({
            Url = host .. "/public/start",
            Method = "POST",
            Body = HttpService:JSONEncode({
                service = tonumber(Config.ServiceId) or Config.ServiceId, 
                identifier = hashedIdentifier
            }),
            Headers = {["Content-Type"] = "application/json"}
        })
        
        if response and response.StatusCode == 200 then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(response.Body) end)
            if ok and decoded and decoded.success and decoded.data and decoded.data.url then
                cachedLink = decoded.data.url
                cachedTime = os.time()
                return true, cachedLink
            end
        end

        cachedLink = string.format("https://gateway.platoboost.com/a/%s?id=%s", tostring(Config.ServiceId), rawHwid)
        return true, cachedLink
    end
    return true, cachedLink
end

local function GetSavedKeyData()
    if isfile and isfile(Config.KeyFileName) then
        local content = ""
        pcall(function() content = readfile(Config.KeyFileName) end)
        if content and content ~= "" then
            local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
            if ok and data and data.key then
                return data.key, tonumber(data.expiresAt) or 0
            else
                return string.gsub(content, "%s+", ""), 0
            end
        end
    end
    return nil, 0
end

local function SaveKeyData(keyString, expTimestamp)
    if writefile then
        pcall(function()
            writefile(Config.KeyFileName, HttpService:JSONEncode({
                key = keyString,
                expiresAt = expTimestamp
            }))
        end)
    end
end

local function VerifyKeyAndRun(keyString, onSuccess, onError)
    local cleanKey = string.gsub(keyString or "", "%s+", "")
    if cleanKey == "" then if onError then onError("Empty Key") end return end

    checkConnectivity()
    if cachedLink == "" then pcall(function() cacheLink() end) end

    local nonce = generateNonce()
    local rawHwid = fGetHwid()
    local hashedIdentifier = lDigest(rawHwid)

    local response, err = safeRequest({
        Url = host .. "/public/redeem/" .. tostring(Config.ServiceId),
        Method = "POST",
        Body = HttpService:JSONEncode({
            identifier = hashedIdentifier,
            key = cleanKey,
            nonce = nonce
        }),
        Headers = {["Content-Type"] = "application/json"}
    })

    if response and (response.StatusCode == 200 or response.StatusCode == 400) then
        local ok, decoded = pcall(function() return HttpService:JSONDecode(response.Body) end)
        if ok and decoded and decoded.success and decoded.data and decoded.data.valid and decoded.data.hash then
            
            local expTimestamp = (decoded.data.expires_at and tonumber(decoded.data.expires_at)) 
                or (decoded.data.expires and tonumber(decoded.data.expires)) 
                or (os.time() + 86400)

            local workerRes, workerErr = safeRequest({
                Url = Config.WorkerAuthURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({
                    hash = decoded.data.hash,
                    nonce = nonce,
                    key = cleanKey,
                    identifier = hashedIdentifier
                })
            })

            if workerRes and workerRes.StatusCode == 200 and workerRes.Body and workerRes.Body ~= "" then
                SaveKeyData(cleanKey, expTimestamp)

                _G[Config.Secret] = true
                _G.HilichurlKeyData = {
                    LoadedFromLoader = true,
                    Key              = cleanKey,
                    ExpiresAt        = expTimestamp,
                    RemainingText    = FormatRemainingTime(expTimestamp - os.time())
                }

                if onSuccess then onSuccess(expTimestamp) end

                local func, loadErr = loadstring(workerRes.Body)
                if func then
                    task.spawn(func)
                else
                    warn("[Hilichurl Loader] Loadstring Error: " .. tostring(loadErr))
                end
                return
            end
        end
    end

    if onError then onError("Verification Failed") end
end

local THEME = {
    BG            = Color3.fromRGB(12,  12,  14),
    BG_OVERLAY    = Color3.fromRGB(18,  18,  22),
    BORDER        = Color3.fromRGB(40,  40,  48),
    ACCENT        = Color3.fromRGB(163, 230, 53),
    ACCENT_DIM    = Color3.fromRGB(101, 163, 13),
    TEXT          = Color3.fromRGB(240, 240, 240),
    TEXT_SUB      = Color3.fromRGB(140, 140, 155),
    BTN_FADED_BG  = Color3.fromRGB(20,  30,  20),
    BTN_FADED_TXT = Color3.fromRGB(163, 230, 53),
    BTN_TEXT_HOV  = Color3.fromRGB(10,  10,  10),
    INPUT_BG      = Color3.fromRGB(16,  16,  20),
    SUCCESS       = Color3.fromRGB(163, 230, 53),
    ERROR         = Color3.fromRGB(239, 68,  68),
}

local function CreateGUI(initialKey, initialExp)
    local player = Players.LocalPlayer
    local coreGui = game:GetService("CoreGui")
    local targetParent = pcall(function() return coreGui end) and coreGui or player:WaitForChild("PlayerGui")
    
    if targetParent:FindFirstChild("Hilichurl_KeySystem") then 
        pcall(function() targetParent.Hilichurl_KeySystem:Destroy() end)
    end

    local ScreenGui = Instance.new("ScreenGui", targetParent)
    ScreenGui.Name = "Hilichurl_KeySystem"
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 360, 0, 360)
    MainFrame.Position = UDim2.new(0.5, -180, 0.5, -180)
    MainFrame.BackgroundColor3 = THEME.BG
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = true
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
    
    local mainStroke = Instance.new("UIStroke", MainFrame)
    mainStroke.Thickness = 1.2
    mainStroke.Color = THEME.BORDER

    local TopGlow = Instance.new("Frame", MainFrame)
    TopGlow.Size = UDim2.new(1, -24, 0, 2)
    TopGlow.Position = UDim2.new(0, 12, 0, 1)
    TopGlow.BorderSizePixel = 0
    TopGlow.BackgroundColor3 = THEME.ACCENT
    Instance.new("UICorner", TopGlow).CornerRadius = UDim.new(0, 2)

    local CloseBtn = Instance.new("TextButton", MainFrame)
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -34, 0, 10)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = THEME.TEXT_SUB
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 13
    CloseBtn.ZIndex = 10

    CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = THEME.ERROR end)
    CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = THEME.TEXT_SUB end)
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, -50, 0, 22)
    Title.Position = UDim2.new(0, 18, 0, 14)
    Title.BackgroundTransparency = 1
    Title.Text = Config.HubName
    Title.TextColor3 = THEME.TEXT
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local PromoText = Instance.new("TextLabel", MainFrame)
    PromoText.Size = UDim2.new(1, -40, 0, 16)
    PromoText.Position = UDim2.new(0, 18, 0, 36)
    PromoText.BackgroundTransparency = 1
    PromoText.Text = Config.HubDescription
    PromoText.TextColor3 = THEME.TEXT_SUB
    PromoText.Font = Enum.Font.GothamMedium
    PromoText.TextSize = 11
    PromoText.TextXAlignment = Enum.TextXAlignment.Left

    local ExpiryLabel = Instance.new("TextLabel", MainFrame)
    ExpiryLabel.Name = "ExpiryLabel"
    ExpiryLabel.Size = UDim2.new(1, -36, 0, 18)
    ExpiryLabel.Position = UDim2.new(0, 18, 0, 56)
    ExpiryLabel.BackgroundTransparency = 1
    ExpiryLabel.Text = (initialExp and initialExp > os.time()) 
        and ("Key Remaining: " .. FormatRemainingTime(initialExp - os.time())) 
        or "Key Remaining: None"
    ExpiryLabel.TextColor3 = THEME.ACCENT
    ExpiryLabel.Font = Enum.Font.GothamBold
    ExpiryLabel.TextSize = 10
    ExpiryLabel.TextXAlignment = Enum.TextXAlignment.Left

    local Divider = Instance.new("Frame", MainFrame)
    Divider.Size = UDim2.new(1, -36, 0, 1)
    Divider.Position = UDim2.new(0, 18, 0, 78)
    Divider.BackgroundColor3 = THEME.BORDER
    Divider.BorderSizePixel = 0

    local currentYOffset = 86

    local function SetupFadedButton(btn, stroke)
        btn.BackgroundColor3 = THEME.BTN_FADED_BG
        btn.TextColor3 = THEME.BTN_FADED_TXT
        stroke.Color = Color3.fromRGB(45, 65, 35)

        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = THEME.ACCENT
            btn.TextColor3 = THEME.BTN_TEXT_HOV
            stroke.Color = THEME.ACCENT
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = THEME.BTN_FADED_BG
            btn.TextColor3 = THEME.BTN_FADED_TXT
            stroke.Color = Color3.fromRGB(45, 65, 35)
        end)
    end

    if Config.ShowDiscord then
        local DiscordBtn = Instance.new("TextButton", MainFrame)
        DiscordBtn.Size = UDim2.new(1, -36, 0, 32)
        DiscordBtn.Position = UDim2.new(0, 18, 0, currentYOffset)
        DiscordBtn.Text = "JOIN DISCORD SERVER"
        DiscordBtn.Font = Enum.Font.GothamBold
        DiscordBtn.TextSize = 11
        Instance.new("UICorner", DiscordBtn).CornerRadius = UDim.new(0, 6)
        local dStroke = Instance.new("UIStroke", DiscordBtn)
        dStroke.Thickness = 1
        SetupFadedButton(DiscordBtn, dStroke)

        DiscordBtn.MouseButton1Click:Connect(function()
            fSetClipboard(Config.DiscordURL)
            local Status = MainFrame:FindFirstChild("StatusLabel")
            if Status then 
                Status.Text = "Copied"
                Status.TextColor3 = THEME.SUCCESS
            end
        end)
        currentYOffset = currentYOffset + 38
    end

    if Config.ShowYoutube and Config.YoutubeURL and Config.YoutubeURL ~= "" then
        local YTBtn = Instance.new("TextButton", MainFrame)
        YTBtn.Size = UDim2.new(1, -36, 0, 32)
        YTBtn.Position = UDim2.new(0, 18, 0, currentYOffset)
        YTBtn.Text = "SUBSCRIBE YOUTUBE"
        YTBtn.Font = Enum.Font.GothamBold
        YTBtn.TextSize = 11
        Instance.new("UICorner", YTBtn).CornerRadius = UDim.new(0, 6)
        local ytStroke = Instance.new("UIStroke", YTBtn)
        ytStroke.Thickness = 1
        SetupFadedButton(YTBtn, ytStroke)

        YTBtn.MouseButton1Click:Connect(function()
            fSetClipboard(Config.YoutubeURL)
            local Status = MainFrame:FindFirstChild("StatusLabel")
            if Status then 
                Status.Text = "Copied"
                Status.TextColor3 = THEME.SUCCESS
            end
        end)
        currentYOffset = currentYOffset + 38
    end

    local KeyInputContainer = Instance.new("Frame", MainFrame)
    KeyInputContainer.Size = UDim2.new(1, -36, 0, 38)
    KeyInputContainer.Position = UDim2.new(0, 18, 0, currentYOffset + 6)
    KeyInputContainer.BackgroundColor3 = THEME.INPUT_BG
    Instance.new("UICorner", KeyInputContainer).CornerRadius = UDim.new(0, 6)
    local inputStroke = Instance.new("UIStroke", KeyInputContainer)
    inputStroke.Color = THEME.BORDER
    inputStroke.Thickness = 1

    local KeyInput = Instance.new("TextBox", KeyInputContainer)
    KeyInput.Size = UDim2.new(1, -70, 1, 0)
    KeyInput.Position = UDim2.new(0, 10, 0, 0)
    KeyInput.BackgroundTransparency = 1
    KeyInput.PlaceholderText = "Paste Platoboost Key here..."
    KeyInput.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
    KeyInput.Text = initialKey or ""
    KeyInput.Font = Enum.Font.GothamMedium
    KeyInput.TextSize = 11
    KeyInput.TextColor3 = THEME.TEXT
    KeyInput.TextXAlignment = Enum.TextXAlignment.Left
    KeyInput.ClearTextOnFocus = false

    KeyInput.Focused:Connect(function() inputStroke.Color = THEME.ACCENT end)
    KeyInput.FocusLost:Connect(function() inputStroke.Color = THEME.BORDER end)

    local PasteBtn = Instance.new("TextButton", KeyInputContainer)
    PasteBtn.Size = UDim2.new(0, 54, 0, 24)
    PasteBtn.Position = UDim2.new(1, -60, 0.5, -12)
    PasteBtn.Text = "Paste"
    PasteBtn.Font = Enum.Font.GothamBold
    PasteBtn.TextSize = 10
    PasteBtn.Active = true
    PasteBtn.ZIndex = 20
    Instance.new("UICorner", PasteBtn).CornerRadius = UDim.new(0, 4)
    local pasteStroke = Instance.new("UIStroke", PasteBtn)
    pasteStroke.Thickness = 1
    SetupFadedButton(PasteBtn, pasteStroke)

    local function DoPaste()
        local text = fGetClipboard()
        if text and text ~= "" then
            text = string.gsub(text, "%s+", "")
            KeyInput.Text = text
            local Status = MainFrame:FindFirstChild("StatusLabel")
            if Status then
                Status.Text = "Copied"
                Status.TextColor3 = THEME.SUCCESS
            end
        else
            KeyInput:CaptureFocus()
        end
    end
    PasteBtn.MouseButton1Click:Connect(DoPaste)
    PasteBtn.TouchTap:Connect(DoPaste)

    local GetKeyBtn = Instance.new("TextButton", MainFrame)
    GetKeyBtn.Size = UDim2.new(0.48, -20, 0, 36)
    GetKeyBtn.Position = UDim2.new(0, 18, 0, currentYOffset + 52)
    GetKeyBtn.Text = "GET KEY"
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.TextSize = 11
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 6)
    local getStroke = Instance.new("UIStroke", GetKeyBtn)
    getStroke.Thickness = 1
    SetupFadedButton(GetKeyBtn, getStroke)

    local VerifyBtn = Instance.new("TextButton", MainFrame)
    VerifyBtn.Size = UDim2.new(0.48, -20, 0, 36)
    VerifyBtn.Position = UDim2.new(0.52, 2, 0, currentYOffset + 52)
    VerifyBtn.Text = "VERIFY"
    VerifyBtn.Font = Enum.Font.GothamBold
    VerifyBtn.TextSize = 11
    VerifyBtn.BackgroundColor3 = THEME.ACCENT
    VerifyBtn.TextColor3 = THEME.BTN_TEXT_HOV
    Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 6)

    VerifyBtn.MouseEnter:Connect(function() VerifyBtn.BackgroundColor3 = Color3.fromRGB(190, 242, 100) end)
    VerifyBtn.MouseLeave:Connect(function() VerifyBtn.BackgroundColor3 = THEME.ACCENT end)

    local Status = Instance.new("TextLabel", MainFrame)
    Status.Name = "StatusLabel"
    Status.Size = UDim2.new(1, -36, 0, 26)
    Status.Position = UDim2.new(0, 18, 0, currentYOffset + 96)
    Status.BackgroundTransparency = 1
    Status.Text = ""
    Status.TextColor3 = THEME.TEXT_SUB
    Status.Font = Enum.Font.GothamBold
    Status.TextSize = 13
    Status.TextWrapped = true

    MainFrame.Size = UDim2.new(0, 360, 0, currentYOffset + 132)

    local isVerifying = false
    local function HandleVerify(keyText)
        if isVerifying then return end
        local cleanKey = string.gsub(keyText or "", "%s+", "")
        if cleanKey == "" then 
            Status.Text = "Failed"
            Status.TextColor3 = THEME.ERROR
            return 
        end

        isVerifying = true
        Status.Text = "Checking..."
        Status.TextColor3 = THEME.ACCENT
        VerifyBtn.Text = "CHECKING..."

        VerifyKeyAndRun(cleanKey, function(expTime)
            Status.Text = "Verified"
            Status.TextColor3 = THEME.SUCCESS
            VerifyBtn.Text = "VERIFIED"
            task.wait(0.6)
            ScreenGui:Destroy()
        end, function(errMsg)
            Status.Text = "Failed"
            Status.TextColor3 = THEME.ERROR
            VerifyBtn.Text = "VERIFY"
            isVerifying = false
        end)
    end

    VerifyBtn.MouseButton1Click:Connect(function() HandleVerify(KeyInput.Text) end)
    KeyInput.FocusLost:Connect(function(enter) if enter then HandleVerify(KeyInput.Text) end end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local success, link = cacheLink()
            if success then
                fSetClipboard(link)
                Status.Text = "Copied"
                Status.TextColor3 = THEME.SUCCESS
            else
                Status.Text = "Failed"
                Status.TextColor3 = THEME.ERROR
            end
        end)
    end)
end

local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")

if pGui:FindFirstChild(Config.MainGuiName) then return end

task.spawn(function()
    local savedKey, savedExp = GetSavedKeyData()

    if savedKey and savedKey ~= "" then
        VerifyKeyAndRun(savedKey, function() end, function()
            CreateGUI(savedKey, savedExp)
        end)
        return
    end

    CreateGUI(nil, 0)
end)
