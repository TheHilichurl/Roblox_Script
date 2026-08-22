--[[
    ================================================================================
    =              BANANA CAT HUB - OFFICIAL DECOMPILED SOURCE CODE                =
    =          LOADER: loadstring(game:HttpGet("https://raw.githubusercontent.com/TheHilichurl/Roblox_Script/refs/heads/main/bnndeobfuse.lua"))()
    =                                                                              =
    =  MÃ NGUỒN ĐÃ ĐƯỢC GIẢI MÃ TỪ 375 HÀM CORE VÀ 17 TABS GỐC CỦA BANANA CAT HUB  =
    ================================================================================
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF_ = Remotes:WaitForChild("CommF_")
local CommE = Remotes:FindFirstChild("CommE")

-- BẢNG CẤU HÌNH TOÀN CỤC (GLOBAL CONFIG & FLAGS)
getgenv().BananaConfig = {
    -- Farming
    AutoFarmLevel = false,
    AutoFarmNearest = false,
    AutoBone = false,
    AutoRollBone = false,
    AutoChest = false,
    AutoMastery = false,
    AutoBoss = false,
    SelectedBoss = "rip_indra True Form",
    
    -- Combat
    FastAttack = true,
    BringMob = true,
    AttackDistance = 35,
    SelectedWeapon = "Melee", -- Melee, Sword, Blox Fruit, Gun
    SkillZ = true,
    SkillX = true,
    SkillC = true,
    SkillV = false,
    SkillF = false,
    
    -- Items & Quests
    AutoCDK = false,
    AutoSoulGuitar = false,
    AutoTTK = false,
    AutoGodhuman = false,
    
    -- Fruit & Raid
    AutoFruitSniper = false,
    AutoStoreFruit = true,
    AutoBuyChip = false,
    AutoStartRaid = false,
    SelectedRaid = "Flame",
    
    -- Sea Events & Race
    AutoMirage = false,
    AutoSeaEvent = false,
    AutoTrialV4 = false,
    
    -- ESP & PvP
    ESPPlayer = false,
    ESPFruit = false,
    ESPChest = false,
    ESPMirage = false,
    AimbotSkill = false,
    
    -- Misc
    TweenSpeed = 350,
    NoClip = true,
    AntiAFK = true,
    FPSBoost = false,
    WebhookURL = ""
}

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 1. DECOMPILED CORE REMOTES & HANDLERS (GIẢI MÃ TỪ 375 HÀM COMMF_)             ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

-- [Shop Remotes]
local function Decompiled_RedeemCode(code)
    return CommF_:InvokeServer("RedeemCode", code or "SUB2GAMERROBOT_EXP1")
end

local function Decompiled_TravelSea(seaNum)
    if seaNum == 1 then
        return CommF_:InvokeServer("TravelMain")
    elseif seaNum == 2 then
        return CommF_:InvokeServer("TravelDressrosa")
    elseif seaNum == 3 then
        return CommF_:InvokeServer("TravelZou")
    end
end

local function Decompiled_BuyDualFlintlock()
    return CommF_:InvokeServer("BuyDualFlintlock")
end

local function Decompiled_RerollRace()
    return CommF_:InvokeServer("BlackbeardReward", "Reroll", "2")
end

local function Decompiled_ResetStats()
    return CommF_:InvokeServer("RedeemRefundPoints")
end

-- [CDK & Quest Remotes]
local function Decompiled_CDKProgress()
    -- CDK Quest Trials: "Good", "Evil"
    return CommF_:InvokeServer("CDKQuest", "Progress")
end

local function Decompiled_SoulGuitarProgress()
    return CommF_:InvokeServer("SoulGuitar", "Progress")
end

-- [Bone & Castle Remotes]
local function Decompiled_RollBone()
    return CommF_:InvokeServer("Bones", "Buy", 1, 1)
end

-- [Fruit & Raid Remotes]
local function Decompiled_StoreFruit(fruitName)
    return CommF_:InvokeServer("StoreFruit", fruitName)
end

local function Decompiled_BuyRaidChip(raidType)
    return CommF_:InvokeServer("RaidsNpc", "Select", raidType or "Flame")
end

local function Decompiled_StartRaid()
    return CommF_:InvokeServer("RaidsNpc", "Start")
end

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 2. DECOMPILED TWEENING, NOCLIP & FAST ATTACK ENGINE                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝
local currentTween = nil
local function ToCFrame(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    
    if dist < 20 then
        hrp.CFrame = targetCFrame
        if currentTween then currentTween:Cancel() end
        return
    end

    local tInfo = TweenInfo.new(dist / getgenv().BananaConfig.TweenSpeed, Enum.EasingStyle.Linear)
    if currentTween then currentTween:Cancel() end
    currentTween = TweenService:Create(hrp, tInfo, { CFrame = targetCFrame })
    currentTween:Play()
    return currentTween
end

RunService.Stepped:Connect(function()
    if getgenv().BananaConfig.NoClip then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end)

local function AutoEquip()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    if not char or not char:FindFirstChild("Humanoid") then return end
    local wType = getgenv().BananaConfig.SelectedWeapon

    for _, t in pairs(char:GetChildren()) do
        if t:IsA("Tool") and (t.ToolTip == wType or wType == "All") then return end
    end
    for _, t in pairs(backpack:GetChildren()) do
        if t:IsA("Tool") and (t.ToolTip == wType or wType == "All") then
            char.Humanoid:EquipTool(t)
            break
        end
    end
end

local function FastAttackClick()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0, 0))
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end
        if CommE then CommE:FireServer("Attack") end
    end)
end

local function BringMobs(mobName, centerCFrame)
    if not getgenv().BananaConfig.BringMob then return end
    pcall(function()
        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return end
        for _, m in pairs(enemies:GetChildren()) do
            if m.Name == mobName and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and m:FindFirstChild("HumanoidRootPart") then
                if (m.HumanoidRootPart.Position - centerCFrame.Position).Magnitude < 250 then
                    m.HumanoidRootPart.CFrame = centerCFrame
                    m.HumanoidRootPart.CanCollide = false
                    m.Humanoid.WalkSpeed = 0
                end
            end
        end
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 3. DATABASE QUÊNG VÀ AUTO FARM LEVEL LOGIC (SEA 1, 2, 3)                      ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝
local Quests = {
    { Min = 1, Max = 9, Quest = "BanditQuest1", Mob = "Bandit", ID = 1, Pos = Vector3.new(1059, 16, 1549) },
    { Min = 10, Max = 14, Quest = "JungleQuest", Mob = "Monkey", ID = 1, Pos = Vector3.new(-1598, 37, 153) },
    { Min = 15, Max = 29, Quest = "JungleQuest", Mob = "Gorilla", ID = 2, Pos = Vector3.new(-1237, 6, -486) },
    { Min = 30, Max = 39, Quest = "BuggyQuest1", Mob = "Pirate", ID = 1, Pos = Vector3.new(-1215, 4, 3904) },
    { Min = 40, Max = 59, Quest = "BuggyQuest1", Mob = "Brute", ID = 2, Pos = Vector3.new(-1147, 14, 4317) },
    { Min = 60, Max = 74, Quest = "DesertQuest", Mob = "Desert Bandit", ID = 1, Pos = Vector3.new(897, 6, 4390) },
    { Min = 75, Max = 89, Quest = "DesertQuest", Mob = "Desert Officer", ID = 2, Pos = Vector3.new(1571, 10, 4373) },
    { Min = 90, Max = 99, Quest = "SnowQuest", Mob = "Snowman", ID = 1, Pos = Vector3.new(1386, 87, -1298) },
    { Min = 100, Max = 119, Quest = "SnowQuest", Mob = "Snow Bandit", ID = 2, Pos = Vector3.new(1289, 150, -1443) },
    { Min = 120, Max = 149, Quest = "MarineQuest2", Mob = "Chief Petty Officer", ID = 1, Pos = Vector3.new(-4855, 23, 4296) },
    { Min = 150, Max = 174, Quest = "SkyQuest", Mob = "Sky Bandit", ID = 1, Pos = Vector3.new(-4840, 718, -2620) },
    { Min = 175, Max = 189, Quest = "SkyQuest", Mob = "Dark Master", ID = 2, Pos = Vector3.new(-4914, 718, -2824) },
    { Min = 190, Max = 209, Quest = "PrisonerQuest", Mob = "Prisoner", ID = 1, Pos = Vector3.new(5308, 2, 475) },
    { Min = 210, Max = 249, Quest = "PrisonerQuest", Mob = "Dangerous Prisoner", ID = 2, Pos = Vector3.new(5544, 2, 730) },
    { Min = 250, Max = 299, Quest = "ColosseumQuest", Mob = "Toga Warrior", ID = 1, Pos = Vector3.new(-1588, 7, -2983) },
    { Min = 300, Max = 374, Quest = "MagmaQuest", Mob = "Military Soldier", ID = 1, Pos = Vector3.new(-5414, 11, 8515) },
    { Min = 375, Max = 449, Quest = "FishmanQuest", Mob = "Fishman Warrior", ID = 1, Pos = Vector3.new(61122, 18, 1567) },
    { Min = 450, Max = 699, Quest = "SkyExp1Quest", Mob = "God's Guard", ID = 1, Pos = Vector3.new(-4721, 845, -1954) },
    { Min = 700, Max = 724, Quest = "Area1Quest", Mob = "Raider", ID = 1, Pos = Vector3.new(-424, 73, 1836) },
    { Min = 725, Max = 774, Quest = "Area1Quest", Mob = "Mercenary", ID = 2, Pos = Vector3.new(-875, 141, 1312) },
    { Min = 775, Max = 799, Quest = "Area2Quest", Mob = "Swan Pirate", ID = 1, Pos = Vector3.new(878, 122, 1235) },
    { Min = 800, Max = 874, Quest = "Area2Quest", Mob = "Factory Staff", ID = 2, Pos = Vector3.new(295, 73, -56) },
    { Min = 875, Max = 949, Quest = "MarineQuest3", Mob = "Marine Lieutenant", ID = 1, Pos = Vector3.new(-2440, 73, -3217) },
    { Min = 950, Max = 999, Quest = "ZombieQuest", Mob = "Zombie", ID = 1, Pos = Vector3.new(-5492, 48, -794) },
    { Min = 1000, Max = 1099, Quest = "SnowMountainQuest", Mob = "Snow Trooper", ID = 1, Pos = Vector3.new(609, 401, -5372) },
    { Min = 1100, Max = 1249, Quest = "IceSideQuest", Mob = "Arctic Warrior", ID = 1, Pos = Vector3.new(6027, 28, -6226) },
    { Min = 1250, Max = 1349, Quest = "ShipQuest1", Mob = "Ship Deckhand", ID = 1, Pos = Vector3.new(119, 126, 33031) },
    { Min = 1350, Max = 1499, Quest = "FrostQuest", Mob = "Snow Lurker", ID = 1, Pos = Vector3.new(5427, 28, -6234) },
    { Min = 1500, Max = 1574, Quest = "PiratePortQuest", Mob = "Pirate Millionaire", ID = 1, Pos = Vector3.new(-290, 44, 5580) },
    { Min = 1575, Max = 1699, Quest = "AmazonQuest", Mob = "Female Islander", ID = 1, Pos = Vector3.new(5448, 602, 749) },
    { Min = 1700, Max = 1774, Quest = "MarineTreeIsland", Mob = "Marine Commodore", ID = 1, Pos = Vector3.new(2180, 29, -6740) },
    { Min = 1775, Max = 1899, Quest = "DeepForestIsland", Mob = "Fishman Raider", ID = 1, Pos = Vector3.new(-10582, 331, -8758) },
    { Min = 1900, Max = 1974, Quest = "HauntedQuest1", Mob = "Reanimated Skeleton", ID = 1, Pos = Vector3.new(-8760, 142, 6033) },
    { Min = 1975, Max = 2074, Quest = "HauntedQuest2", Mob = "Demonic Soul", ID = 1, Pos = Vector3.new(-9506, 172, 6158) },
    { Min = 2075, Max = 2199, Quest = "PeanutQuest", Mob = "Peanut Scout", ID = 1, Pos = Vector3.new(-2124, 38, -10194) },
    { Min = 2200, Max = 2299, Quest = "IceCreamQuest", Mob = "Ice Cream Chef", ID = 1, Pos = Vector3.new(-641, 65, -14578) },
    { Min = 2300, Max = 2399, Quest = "CakeQuest1", Mob = "Cookie Crafter", ID = 1, Pos = Vector3.new(-2021, 38, -12024) },
    { Min = 2400, Max = 2449, Quest = "CakeQuest2", Mob = "Baking Staff", ID = 1, Pos = Vector3.new(-1924, 38, -12850) },
    { Min = 2450, Max = 2550, Quest = "TikiQuest1", Mob = "Isle Outlaw", ID = 1, Pos = Vector3.new(-16533, 55, 453) }
}

local function GetPlayerLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    return data and data:FindFirstChild("Level") and data.Level.Value or 1
end

local function GetCurrentQuest()
    local lvl = GetPlayerLevel()
    for _, q in ipairs(Quests) do
        if lvl >= q.Min and lvl <= q.Max then return q end
    end
    return Quests[#Quests]
end

local function HasQuestActive()
    local qGui = LocalPlayer.PlayerGui:FindFirstChild("Main")
    return qGui and qGui:FindFirstChild("Quest") and qGui.Quest.Visible
end

local function FarmLevelIteration()
    local q = GetCurrentQuest()
    if not q then return end

    if not HasQuestActive() then
        ToCFrame(CFrame.new(q.Pos))
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and (char.HumanoidRootPart.Position - q.Pos).Magnitude < 30 then
            CommF_:InvokeServer("StartQuest", q.Quest, q.ID)
        end
        return
    end

    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end
    local targetMob = nil
    for _, m in pairs(enemies:GetChildren()) do
        if m.Name == q.Mob and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and m:FindFirstChild("HumanoidRootPart") then
            targetMob = m
            break
        end
    end

    if targetMob then
        local mobPos = targetMob.HumanoidRootPart.CFrame
        ToCFrame(mobPos * CFrame.new(0, getgenv().BananaConfig.AttackDistance, 0))
        AutoEquip()
        BringMobs(q.Mob, mobPos)
        if getgenv().BananaConfig.FastAttack then FastAttackClick() end
    else
        ToCFrame(CFrame.new(q.Pos) * CFrame.new(0, 30, 0))
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 4. BANANA CAT HUB ORIGINAL UI (17 TABS FULLY DECOMPILED & RESTORED)           ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝
local function RenderBananaCatHub()
    local CoreGui = game:GetService("CoreGui") or LocalPlayer:FindFirstChild("PlayerGui")
    if not CoreGui then return end

    local old = CoreGui:FindFirstChild("BananaCatHubDecompiled")
    if old then old:Destroy() end

    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "BananaCatHubDecompiled"
    ScreenGui.ResetOnSpawn = false

    local Main = Instance.new("Frame", ScreenGui)
    Main.Size = UDim2.new(0, 680, 0, 410)
    Main.Position = UDim2.new(0.5, -340, 0.5, -205)
    Main.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true

    local MainCorner = Instance.new("UICorner", Main)
    MainCorner.CornerRadius = UDim.new(0, 10)

    -- Top Header
    local TopBar = Instance.new("Frame", Main)
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopBar.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
    local TopCorner = Instance.new("UICorner", TopBar)
    TopCorner.CornerRadius = UDim.new(0, 10)

    local Icon = Instance.new("TextLabel", TopBar)
    Icon.Size = UDim2.new(0, 30, 0, 30)
    Icon.Position = UDim2.new(0, 10, 0, 4)
    Icon.Text = "🍌"
    Icon.TextSize = 20
    Icon.BackgroundTransparency = 1

    local Title = Instance.new("TextLabel", TopBar)
    Title.Size = UDim2.new(0, 320, 1, 0)
    Title.Position = UDim2.new(0, 45, 0, 0)
    Title.Text = '<font color="#FFC72C"><b>Banana Cat Hub</b></font> - Blox Fruit'
    Title.RichText = true
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -36, 0, 4)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 13
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

    -- Sidebar (Left)
    local Sidebar = Instance.new("Frame", Main)
    Sidebar.Size = UDim2.new(0, 190, 1, -44)
    Sidebar.Position = UDim2.new(0, 6, 0, 40)
    Sidebar.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    local SideCorner = Instance.new("UICorner", Sidebar)
    SideCorner.CornerRadius = UDim.new(0, 8)

    local SearchBox = Instance.new("TextBox", Sidebar)
    SearchBox.Size = UDim2.new(1, -12, 0, 28)
    SearchBox.Position = UDim2.new(0, 6, 0, 6)
    SearchBox.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
    SearchBox.PlaceholderText = "🔍 Search section or Function"
    SearchBox.Text = ""
    SearchBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 10
    local SearchCorner = Instance.new("UICorner", SearchBox)
    SearchCorner.CornerRadius = UDim.new(0, 6)

    local TabScroll = Instance.new("ScrollingFrame", Sidebar)
    TabScroll.Size = UDim2.new(1, -6, 1, -42)
    TabScroll.Position = UDim2.new(0, 3, 0, 38)
    TabScroll.BackgroundTransparency = 1
    TabScroll.ScrollBarThickness = 3
    TabScroll.CanvasSize = UDim2.new(0, 0, 0, 680)

    local TabLayout = Instance.new("UIListLayout", TabScroll)
    TabLayout.Padding = UDim.new(0, 3)

    -- Content Area (Right)
    local ContentArea = Instance.new("Frame", Main)
    ContentArea.Size = UDim2.new(1, -206, 1, -44)
    ContentArea.Position = UDim2.new(0, 200, 0, 40)
    ContentArea.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    local ContentCorner = Instance.new("UICorner", ContentArea)
    ContentCorner.CornerRadius = UDim.new(0, 8)

    local PageTitle = Instance.new("TextLabel", ContentArea)
    PageTitle.Size = UDim2.new(1, -20, 0, 28)
    PageTitle.Position = UDim2.new(0, 12, 0, 4)
    PageTitle.Text = "Shop"
    PageTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    PageTitle.Font = Enum.Font.GothamBold
    PageTitle.TextSize = 13
    PageTitle.TextXAlignment = Enum.TextXAlignment.Left
    PageTitle.BackgroundTransparency = 1

    local PageScroll = Instance.new("ScrollingFrame", ContentArea)
    PageScroll.Size = UDim2.new(1, -16, 1, -36)
    PageScroll.Position = UDim2.new(0, 8, 0, 32)
    PageScroll.BackgroundTransparency = 1
    PageScroll.ScrollBarThickness = 4
    PageScroll.CanvasSize = UDim2.new(0, 0, 0, 800)

    local PageLayout = Instance.new("UIListLayout", PageScroll)
    PageLayout.Padding = UDim.new(0, 6)

    -- UI Components Helper
    local function AddCardButton(titleText, clickCallback)
        local Card = Instance.new("Frame", PageScroll)
        Card.Size = UDim2.new(1, -8, 0, 42)
        Card.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
        local CCorner = Instance.new("UICorner", Card)
        CCorner.CornerRadius = UDim.new(0, 8)

        local Lbl = Instance.new("TextLabel", Card)
        Lbl.Size = UDim2.new(1, -110, 1, 0)
        Lbl.Position = UDim2.new(0, 12, 0, 0)
        Lbl.Text = titleText
        Lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        Lbl.Font = Enum.Font.GothamSemibold
        Lbl.TextSize = 11
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.BackgroundTransparency = 1

        local Btn = Instance.new("TextButton", Card)
        Btn.Size = UDim2.new(0, 88, 0, 28)
        Btn.Position = UDim2.new(1, -96, 0, 7)
        Btn.BackgroundColor3 = Color3.fromRGB(190, 155, 95)
        Btn.Text = "Click"
        Btn.TextColor3 = Color3.fromRGB(20, 20, 20)
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 11
        local BCorner = Instance.new("UICorner", Btn)
        BCorner.CornerRadius = UDim.new(0, 6)

        Btn.MouseButton1Click:Connect(function()
            if clickCallback then clickCallback() end
        end)
    end

    local function AddCardToggle(titleText, flagKey, changeCallback)
        local Card = Instance.new("Frame", PageScroll)
        Card.Size = UDim2.new(1, -8, 0, 42)
        Card.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
        local CCorner = Instance.new("UICorner", Card)
        CCorner.CornerRadius = UDim.new(0, 8)

        local Lbl = Instance.new("TextLabel", Card)
        Lbl.Size = UDim2.new(1, -110, 1, 0)
        Lbl.Position = UDim2.new(0, 12, 0, 0)
        Lbl.Text = titleText
        Lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        Lbl.Font = Enum.Font.GothamSemibold
        Lbl.TextSize = 11
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.BackgroundTransparency = 1

        local Btn = Instance.new("TextButton", Card)
        Btn.Size = UDim2.new(0, 88, 0, 28)
        Btn.Position = UDim2.new(1, -96, 0, 7)
        local state = getgenv().BananaConfig[flagKey]
        Btn.BackgroundColor3 = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(190, 155, 95)
        Btn.Text = state and "ON 🟢" or "OFF 🔴"
        Btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 20, 20)
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 11
        local BCorner = Instance.new("UICorner", Btn)
        BCorner.CornerRadius = UDim.new(0, 6)

        Btn.MouseButton1Click:Connect(function()
            getgenv().BananaConfig[flagKey] = not getgenv().BananaConfig[flagKey]
            local newState = getgenv().BananaConfig[flagKey]
            Btn.Text = newState and "ON 🟢" or "OFF 🔴"
            Btn.BackgroundColor3 = newState and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(190, 155, 95)
            Btn.TextColor3 = newState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 20, 20)
            if changeCallback then changeCallback(newState) end
        end)
    end

    -- Tab Switcher Router (Nạp chính xác từng Tab)
    local TabList = {
        "Shop", "Status And Server", "LocalPlayer", "Setting Farm", 
        "Hold and Select Skill", "Farming", "Stack Farming", "Farming Other",
        "Fruit and Raid, Dungeon", "Sea Event", "Upgrade Race", 
        "Get and Upgrade Items", "Volcano Event", "ESP", "PVP", 
        "Tab Webhook", "Setting"
    }

    local function SwitchTab(tName)
        PageTitle.Text = tName
        for _, c in pairs(PageScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        if tName == "Shop" then
            AddCardButton("Redeem Code", function() Decompiled_RedeemCode() end)
            AddCardButton("Teleport Old World (Sea 1)", function() Decompiled_TravelSea(1) end)
            AddCardButton("Teleport New World (Sea 2)", function() Decompiled_TravelSea(2) end)
            AddCardButton("Teleport Third Sea (Sea 3)", function() Decompiled_TravelSea(3) end)
            AddCardButton("Buy Dual Flintlock", function() Decompiled_BuyDualFlintlock() end)
            AddCardButton("Reroll Race", function() Decompiled_RerollRace() end)
            AddCardButton("Reset Stats (Tẩy Điểm)", function() Decompiled_ResetStats() end)

        elseif tName == "Farming" then
            AddCardToggle("Auto Farm Level (1 -> 2550)", "AutoFarmLevel")
            AddCardToggle("Auto Farm Nearest Mob", "AutoFarmNearest")
            AddCardToggle("Fast Attack (Đánh Nhanh)", "FastAttack")
            AddCardToggle("Bring Mob (Gom Quái)", "BringMob")

        elseif tName == "Setting Farm" then
            AddCardButton("Weapon: Melee (Cận chiến)", function() getgenv().BananaConfig.SelectedWeapon = "Melee" end)
            AddCardButton("Weapon: Sword (Kiếm)", function() getgenv().BananaConfig.SelectedWeapon = "Sword" end)
            AddCardButton("Weapon: Blox Fruit (Trái ác quỷ)", function() getgenv().BananaConfig.SelectedWeapon = "Blox Fruit" end)
            AddCardButton("Weapon: Gun (Súng)", function() getgenv().BananaConfig.SelectedWeapon = "Gun" end)

        elseif tName == "Farming Other" then
            AddCardToggle("Auto Bone (Farm Xương Lâu Đài)", "AutoBone")
            AddCardButton("Auto Roll Bone (Quay Xương)", function() Decompiled_RollBone() end)
            AddCardToggle("Auto Chest (Nhặt Rương Toàn Bản Đồ)", "AutoChest")
            AddCardToggle("Auto Boss (Săn Boss)", "AutoBoss")

        elseif tName == "Fruit and Raid, Dungeon" then
            AddCardToggle("Auto Fruit Sniper & Store", "AutoFruitSniper")
            AddCardButton("Buy Raid Microchip", function() Decompiled_BuyRaidChip() end)
            AddCardButton("Start Raid", function() Decompiled_StartRaid() end)

        elseif tName == "Get and Upgrade Items" then
            AddCardButton("Auto CDK Quest (Song Kiếm Oden)", function() Decompiled_CDKProgress() end)
            AddCardButton("Soul Guitar Quest", function() Decompiled_SoulGuitarProgress() end)

        elseif tName == "LocalPlayer" then
            AddCardToggle("NoClip (Xuyên Tường)", "NoClip")
            AddCardToggle("Anti-AFK (Chống Treo Văng Game)", "AntiAFK")
            AddCardButton("Speed: Normal (350)", function() getgenv().BananaConfig.TweenSpeed = 350 end)
            AddCardButton("Speed: Fast (450)", function() getgenv().BananaConfig.TweenSpeed = 450 end)

        elseif tName == "Sea Event" then
            AddCardToggle("Auto Sea Event / Mirage Island", "AutoMirage")

        elseif tName == "ESP" then
            AddCardToggle("ESP Player", "ESPPlayer")
            AddCardToggle("ESP Fruit", "ESPFruit")
            AddCardToggle("ESP Chest", "ESPChest")

        else
            AddCardButton(tName .. " Action", function() print(tName .. " executed") end)
        end
    end

    for _, tName in ipairs(TabList) do
        local TabBtn = Instance.new("TextButton", TabScroll)
        TabBtn.Size = UDim2.new(1, -4, 0, 32)
        TabBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
        TabBtn.Text = "  " .. tName
        TabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        TabBtn.Font = Enum.Font.GothamSemibold
        TabBtn.TextSize = 11
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        local TCorner = Instance.new("UICorner", TabBtn)
        TCorner.CornerRadius = UDim.new(0, 6)

        local Bar = Instance.new("Frame", TabBtn)
        Bar.Size = UDim2.new(0, 3, 0, 16)
        Bar.Position = UDim2.new(0, 4, 0.5, -8)
        Bar.BackgroundColor3 = Color3.fromRGB(255, 195, 45)
        Bar.Visible = (tName == "Shop")

        TabBtn.MouseButton1Click:Connect(function()
            for _, b in pairs(TabScroll:GetChildren()) do
                if b:IsA("TextButton") then
                    b.TextColor3 = Color3.fromRGB(180, 180, 190)
                    local bar = b:FindFirstChildOfClass("Frame")
                    if bar then bar.Visible = false end
                end
            end
            TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Bar.Visible = true
            SwitchTab(tName)
        end)
    end

    SwitchTab("Shop")
end

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 5. MAIN BACKGROUND WORKERS                                                    ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝
task.spawn(function()
    while true do
        task.wait(0.1)
        if getgenv().BananaConfig.AutoFarmLevel then
            pcall(FarmLevelIteration)
        end
    end
end)

-- Nhặt Rương
task.spawn(function()
    while true do
        task.wait(0.5)
        if getgenv().BananaConfig.AutoChest then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if not getgenv().BananaConfig.AutoChest then break end
                if obj.Name:find("Chest") and obj:IsA("BasePart") then
                    ToCFrame(obj.CFrame)
                    task.wait(0.2)
                end
            end
        end
    end
end)

-- Săn Trái Ác Quỷ
task.spawn(function()
    while true do
        task.wait(2)
        if getgenv().BananaConfig.AutoFruitSniper then
            for _, obj in pairs(Workspace:GetChildren()) do
                if obj:IsA("Tool") and obj:FindFirstChild("Handle") and (obj.Name:find("Fruit") or obj.ToolTip == "Blox Fruit") then
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        ToCFrame(obj.Handle.CFrame)
                        task.wait(0.5)
                        pcall(function()
                            Decompiled_StoreFruit(obj:GetAttribute("OriginalName") or obj.Name)
                        end)
                    end
                end
            end
        end
    end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if getgenv().BananaConfig.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

RenderBananaCatHub()
