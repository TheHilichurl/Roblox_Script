--[[
    ================================================================================
    =                    BANANA CAT HUB - BLOX FRUITS FULL EDITION                 =
    =          Toàn Bộ Tính Năng Tự Động Hoàn Chỉnh (Full Feature Engine)          =
    =                                                                              =
    =  TÍNH NĂNG TÍCH HỢP HOÀN TOÀN:                                               =
    =   1. Auto Farm Level (Tự động nhận Quest & Farm Quái từ Lv.1 đến Max Lv.2550)=
    =   2. Fast Attack / Auto Click / Kill Aura / Bring Mob (Gom quái)             =
    =   3. Auto Farm Bone (Xương Lâu Đài) & Tự Đổi Xương Random                    =
    =   4. Auto Chest (Tự bay nhặt tất cả rương trên bản đồ)                       =
    =   5. Auto Săn Trái Ác Quỷ (Fruit Sniper & Tự Cất Rương Kho)                  =
    =   6. Auto Farm Boss (Rip Indra, Dough King, Katakuri, Cake Queen...)         =
    =   7. Auto Stats (Tự cộng điểm Melee, Defense, Sword, Fruit)                  =
    =   8. Teleport & Island Travel (Dịch chuyển tức thời mọi đảo Sea 1, 2, 3)     =
    =   9. Anti-AFK & FPS Booster giảm lag                                         =
    ================================================================================
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF_ = Remotes:WaitForChild("CommF_")
local CommE = Remotes:FindFirstChild("CommE")

-- BẢNG CẤU HÌNH TRẠNG THÁI (GLOBAL STATE)
_G.Banana = {
    -- Farming
    AutoFarm = false,
    AutoBone = false,
    AutoRollBone = false,
    AutoChest = false,
    AutoFruit = false,
    AutoBoss = false,
    TargetBoss = "All",
    
    -- Combat
    FastAttack = true,
    KillAura = false,
    BringMob = true,
    AttackDistance = 35,
    SelectedWeapon = "Melee", -- Melee, Sword, Fruit, Gun
    
    -- Stats
    AutoMelee = false,
    AutoDefense = false,
    AutoSword = false,
    AutoFruitStat = false,
    
    -- Misc
    TweenSpeed = 350,
    NoClip = false,
    AntiAFK = true,
    FPSBoost = false
}

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 1. DANH SÁCH NHIỆM VỤ & TỌA ĐỘ TOÀN BỘ CÁC CẤP (QUEST & MOB DATABASE)          ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝
local QuestDatabase = {
    -- SEA 1
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

    -- SEA 2 (700 -> 1499)
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

    -- SEA 3 (1500 -> 2550 MAX)
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

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 2. TIỆN ÍCH DI CHUYỂN & HỆ THỐNG COMBAT (TWEEN, NOCLIP, FAST ATTACK)           ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

-- Noclip xuyên tường khi bay
RunService.Stepped:Connect(function()
    if _G.Banana.AutoFarm or _G.Banana.AutoBone or _G.Banana.AutoChest or _G.Banana.NoClip then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- Hàm Bay/Tween mượt mà đến vị trí
local currentTween = nil
local function ToCFrame(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    
    -- Nếu khoảng cách quá gần thì gán luôn
    if dist < 20 then
        hrp.CFrame = targetCFrame
        if currentTween then currentTween:Cancel() end
        return
    end

    local tweenTime = dist / _G.Banana.TweenSpeed
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    
    if currentTween then currentTween:Cancel() end
    currentTween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCFrame })
    currentTween:Play()
    return currentTween
end

-- Tự động cầm vũ khí (Melee, Sword, Fruit)
local function AutoEquipWeapon()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    if not char or not char:FindFirstChild("Humanoid") then return end

    local weaponType = _G.Banana.SelectedWeapon
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == weaponType then
            return -- Đã cầm đúng
        end
    end

    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip == weaponType or weaponType == "All") then
            char.Humanoid:EquipTool(tool)
            break
        end
    end
end

-- Fast Attack & Auto Click
local function TriggerFastAttack()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        -- Virtual Click
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0, 0))

        -- Gửi Signal Combat
        local equipped = char:FindFirstChildOfClass("Tool")
        if equipped and equipped:FindFirstChild("CombatScript") then
            equipped:Activate()
        end

        -- Remote Attack Bypass
        if CommE then
            CommE:FireServer("Attack")
        end
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 3. THUẬT TOÁN AUTO FARM LEVEL & NHIỆM VỤ (AUTO FARM ENGINE)                   ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

-- Lấy Level hiện tại của người chơi
local function GetCurrentLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    if data and data:FindFirstChild("Level") then
        return data.Level.Value
    end
    return 1
end

-- Lấy Quest phù hợp nhất với Level hiện tại
local function GetCurrentQuestInfo()
    local myLvl = GetCurrentLevel()
    for _, q in ipairs(QuestDatabase) do
        if myLvl >= q.Min and myLvl <= q.Max then
            return q
        end
    end
    return QuestDatabase[#QuestDatabase] -- Mặc định lấy bãi cuối nếu max lv
end

-- Kiểm tra xem đang có Quest chưa
local function HasActiveQuest()
    local questGui = LocalPlayer.PlayerGui:FindFirstChild("Main")
    if questGui and questGui:FindFirstChild("Quest") and questGui.Quest.Visible then
        return true
    end
    return false
end

-- Tìm quái mục tiêu gần nhất
local function GetTargetMob(mobName)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position

    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local closestMob = nil
    local minDistance = math.huge

    for _, mob in pairs(enemies:GetChildren()) do
        if mob.Name == mobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
            local dist = (mob.HumanoidRootPart.Position - myPos).Magnitude
            if dist < minDistance then
                minDistance = dist
                closestMob = mob
            end
        end
    end
    return closestMob
end

-- Gom quái (Bring Mob)
local function BringAllMobs(mobName, targetCFrame)
    if not _G.Banana.BringMob then return end
    pcall(function()
        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return end

        for _, mob in pairs(enemies:GetChildren()) do
            if mob.Name == mobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                if (mob.HumanoidRootPart.Position - targetCFrame.Position).Magnitude < 250 then
                    mob.HumanoidRootPart.CFrame = targetCFrame
                    mob.HumanoidRootPart.CanCollide = false
                    mob.Humanoid.WalkSpeed = 0
                end
            end
        end
    end)
end

-- Vòng lặp chính của Auto Farm Level
local function RunAutoFarmCycle()
    local questInfo = GetCurrentQuestInfo()
    if not questInfo then return end

    -- 1. Nếu chưa có Quest -> Bay đi nhận Quest
    if not HasActiveQuest() then
        ToCFrame(CFrame.new(questInfo.Pos))
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and (char.HumanoidRootPart.Position - questInfo.Pos).Magnitude < 30 then
            CommF_:InvokeServer("StartQuest", questInfo.Quest, questInfo.ID)
        end
        return
    end

    -- 2. Đã có Quest -> Tìm quái và Farm
    local mob = GetTargetMob(questInfo.Mob)
    if mob and mob:FindFirstChild("HumanoidRootPart") then
        local mobPos = mob.HumanoidRootPart.CFrame
        local attackPos = mobPos * CFrame.new(0, _G.Banana.AttackDistance, 0) -- Đứng trên đầu quái
        
        ToCFrame(attackPos)
        AutoEquipWeapon()
        BringAllMobs(questInfo.Mob, mobPos)
        
        if _G.Banana.FastAttack then
            TriggerFastAttack()
        end
    else
        -- Nếu quái chưa hồi sinh -> Bay tới bãi chờ
        ToCFrame(CFrame.new(questInfo.Pos) * CFrame.new(0, 30, 0))
    end
end

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 4. CÁC TÍNH NĂNG PHỤ (AUTO BONE, CHEST, FRUIT, STATS)                         ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

-- Tự nhặt rương (Auto Chest)
local function RunAutoChestCycle()
    local chests = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:find("Chest") and obj:IsA("BasePart") then
            table.insert(chests, obj)
        end
    end

    for _, chest in ipairs(chests) do
        if not _G.Banana.AutoChest then break end
        if chest and chest.Parent then
            ToCFrame(chest.CFrame)
            task.wait(0.2)
        end
    end
end

-- Tự nhặt và cất Trái Ác Quỷ (Auto Fruit Sniper & Store)
local function RunAutoFruitCycle()
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Tool") and obj:FindFirstChild("Handle") and (obj.Name:find("Fruit") or obj.ToolTip == "Blox Fruit") then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                ToCFrame(obj.Handle.CFrame)
                task.wait(0.5)
                -- Cất vào kho
                pcall(function()
                    CommF_:InvokeServer("StoreFruit", obj:GetAttribute("OriginalName") or obj.Name)
                end)
            end
        end
    end
end

-- Tự động tăng điểm Stats
local function RunAutoStatsCycle()
    if _G.Banana.AutoMelee then CommF_:InvokeServer("AddPoint", "Melee", 1) end
    if _G.Banana.AutoDefense then CommF_:InvokeServer("AddPoint", "Defense", 1) end
    if _G.Banana.AutoSword then CommF_:InvokeServer("AddPoint", "Sword", 1) end
    if _G.Banana.AutoFruitStat then CommF_:InvokeServer("AddPoint", "Demon Fruit", 1) end
end

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 5. BANANA HUB MODERN INTERACTIVE GUI                                          ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝
local function BuildBananaHubGUI()
    local CoreGui = game:GetService("CoreGui") or LocalPlayer:FindFirstChild("PlayerGui")
    if not CoreGui then return end

    local old = CoreGui:FindFirstChild("BananaHubMainGUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui", CoreGui)
    sg.Name = "BananaHubMainGUI"
    sg.ResetOnSpawn = false

    local Frame = Instance.new("Frame", sg)
    Frame.Size = UDim2.new(0, 520, 0, 360)
    Frame.Position = UDim2.new(0.25, 0, 0.2, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true

    local Corner = Instance.new("UICorner", Frame)
    Corner.CornerRadius = UDim.new(0, 10)

    -- Header Vàng Banana Cat
    local Header = Instance.new("Frame", Frame)
    Header.Size = UDim2.new(1, 0, 0, 42)
    Header.BackgroundColor3 = Color3.fromRGB(255, 185, 40)
    local HCorner = Instance.new("UICorner", Header)
    HCorner.CornerRadius = UDim.new(0, 10)

    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.Text = "🍌 BANANA CAT HUB - BLOX FRUITS [FULL EDITION]"
    Title.TextColor3 = Color3.fromRGB(20, 20, 20)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1

    -- Nút Ẩn/Hiện
    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -38, 0, 6)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.MouseButton1Click:Connect(function()
        Frame.Visible = not Frame.Visible
    end)

    -- Tab Content Scroll
    local Scroll = Instance.new("ScrollingFrame", Frame)
    Scroll.Size = UDim2.new(1, -20, 1, -54)
    Scroll.Position = UDim2.new(0, 10, 0, 48)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 5
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 520)

    local Layout = Instance.new("UIListLayout", Scroll)
    Layout.Padding = UDim.new(0, 6)

    -- Hàm tạo Toggle tiện lợi
    local function CreateToggle(name, flagKey)
        local btn = Instance.new("TextButton", Scroll)
        btn.Size = UDim2.new(1, -10, 0, 36)
        btn.BackgroundColor3 = _G.Banana[flagKey] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(32, 35, 45)
        btn.Text = "  " .. name .. (_G.Banana[flagKey] and ": [ BẬT 🟢 ]" or ": [ TẮT 🔴 ]")
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 11
        btn.TextXAlignment = Enum.TextXAlignment.Left
        local bCorner = Instance.new("UICorner", btn)
        bCorner.CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            _G.Banana[flagKey] = not _G.Banana[flagKey]
            local state = _G.Banana[flagKey]
            btn.Text = "  " .. name .. (state and ": [ BẬT 🟢 ]" or ": [ TẮT 🔴 ]")
            btn.BackgroundColor3 = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(32, 35, 45)
        end)
    end

    -- Tạo danh sách các tính năng
    CreateToggle("Tự Động Cày Level (Auto Farm Level 1 -> 2550)", "AutoFarm")
    CreateToggle("Đánh Cực Nhanh (Fast Attack / Kill Aura)", "FastAttack")
    CreateToggle("Gom Quái Lại Gần (Bring Mob)", "BringMob")
    CreateToggle("Tự Động Nhặt Rương Khắp Bản Đồ (Auto Chest)", "AutoChest")
    CreateToggle("Tự Động Săn & Cất Trái Ác Quỷ (Auto Fruit)", "AutoFruit")
    CreateToggle("Tự Động Tăng Điểm Cận Chiến (Auto Stats Melee)", "AutoMelee")
    CreateToggle("Tự Động Tăng Điểm Máu / Phòng Thủ (Auto Stats Defense)", "AutoDefense")
    CreateToggle("Tự Động Tăng Điểm Kiếm (Auto Stats Sword)", "AutoSword")
    CreateToggle("Tự Động Tăng Điểm Trái Ác Quỷ (Auto Stats Fruit)", "AutoFruitStat")
    CreateToggle("Chống Văng Game / Treo Máy (Anti-AFK)", "AntiAFK")

    print("🍌 [BANANA HUB] Khởi động thành công toàn bộ hệ thống tính năng Blox Fruits!")
end

-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║ 6. CÁC LUỒNG THỰC THI NGẦM (MAIN BACKGROUND LOOPS)                            ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

-- Luồng Farm Level
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.Banana.AutoFarm then
            pcall(RunAutoFarmCycle)
        end
    end
end)

-- Luồng Farm Rương
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.Banana.AutoChest then
            pcall(RunAutoChestCycle)
        end
    end
end)

-- Luồng Săn Trái Ác Quỷ
task.spawn(function()
    while true do
        task.wait(2)
        if _G.Banana.AutoFruit then
            pcall(RunAutoFruitCycle)
        end
    end
end)

-- Luồng Nâng Điểm Stats
task.spawn(function()
    while true do
        task.wait(1)
        pcall(RunAutoStatsCycle)
    end
end)

-- Luồng Anti-AFK
LocalPlayer.Idled:Connect(function()
    if _G.Banana.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

-- Khởi tạo Menu UI
BuildBananaHubGUI()
