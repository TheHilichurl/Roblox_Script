-- [HILICHURL MODULAR RUNTIME MODULE]
local CTX = getgenv()._HILICHURL_CTX
if not CTX then return warn('[Hilichurl Hub] Core Context missing!') end

local S = CTX.State
local Utility = CTX.Utility
local UI_ELEMENTS = CTX.UI_ELEMENTS
local _conns = CTX.Connections
local DisconnectConnection = CTX.DisconnectConnection

local Players = CTX.Players or game:GetService("Players")
local LocalPlayer = CTX.LocalPlayer or Players.LocalPlayer
local RunService = CTX.RunService or game:GetService("RunService")
local TweenService = CTX.TweenService or game:GetService("TweenService")
local UserInputService = CTX.UserInputService or game:GetService("UserInputService")
local HttpService = CTX.HttpService or game:GetService("HttpService")

local UILib = setmetatable({}, {
    __index = function(_, k)
        if CTX.UILib and CTX.UILib[k] then return CTX.UILib[k] end
        if k == "Notify" then return function(...) end end
        return nil
    end
})

local function collectgarbage(opt, ...)
    if opt == "count" then return (gcinfo and gcinfo()) or 0 end
    return 0
end

local MELEE_DATABASE = CTX.MELEE_DATABASE or {}
local SWORDS_DATABASE = CTX.SWORDS_DATABASE or {}
local GUNS_DATABASE = CTX.GUNS_DATABASE or {}
local ACCESSORIES_DATABASE = CTX.ACCESSORIES_DATABASE or {}
local MELEE_PROGRESSION_LADDER = CTX.MELEE_PROGRESSION_LADDER or {}
local SWORD_PROGRESSION_LADDER = CTX.SWORD_PROGRESSION_LADDER or {}
local GUN_PROGRESSION_LADDER = CTX.GUN_PROGRESSION_LADDER or {}

-- ========================================================
-- [SECTION: COMBAT & FAST ATTACK ENGINE]
-- ========================================================
function Utility.AttackSword(enemy, enemyRoot, extraTargets)
    local tool = Utility.EquipWeaponByType("Sword")
    local eRoot = enemyRoot or (enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")))
    local eHead = enemy and enemy:FindFirstChild("Head")
    if not eRoot then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")

    local rep = game:GetService("ReplicatedStorage")
    local net = rep:FindFirstChild("Modules") and rep.Modules:FindFirstChild("Net")
    local regAttack = net and net:FindFirstChild("RE/RegisterAttack")
    local regHit = net and net:FindFirstChild("RE/RegisterHit")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        local cfModule = ps and ps:FindFirstChild("CombatFramework")
        if cfModule then
            local cf = require(cfModule)
            if cf and cf.activeController then
                local ctrl = cf.activeController
                ctrl.timeToNextAttack = 0
                ctrl.hitboxMagnitude = 60
                ctrl.active = true
                ctrl.increment = 3
                ctrl:attack()
            end
        end
    end)

    if tool then
        pcall(function() tool:Activate() end)
        local lcr = tool:FindFirstChild("LeftClickRemote")
        if lcr and lcr:IsA("RemoteEvent") and myRoot then
            pcall(function() lcr:FireServer((eRoot.Position - myRoot.Position).Unit, 1, true, eRoot.Position) end)
        end
    end

    local targetList = {}
    if enemy and enemy:IsA("Model") then
        local root = eRoot or enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")
        local head = eHead or enemy:FindFirstChild("Head") or root
        if root then
            table.insert(targetList, { Model = enemy, Root = root, Head = head })
        end
        if enemy.Parent and enemy.Parent:IsA("Model") and enemy.Parent ~= workspace and enemy.Parent ~= workspace:FindFirstChild("SeaBeasts") and enemy.Parent ~= workspace:FindFirstChild("Enemies") then
            local pRoot = enemy.Parent:FindFirstChild("HumanoidRootPart") or enemy.Parent.PrimaryPart or root
            local pHead = enemy.Parent:FindFirstChild("Head") or pRoot or head
            if pRoot then
                table.insert(targetList, { Model = enemy.Parent, Root = pRoot, Head = pHead })
            end
        end
    elseif eRoot then
        local model = (enemy and enemy:IsA("Model") and enemy) or eRoot.Parent
        table.insert(targetList, { Model = model, Root = eRoot, Head = eHead or eRoot })
    end

    if extraTargets and typeof(extraTargets) == "table" then
        for _, t in ipairs(extraTargets) do
            local model = (typeof(t) == "table" and t.Model) or (typeof(t) == "Instance" and t:IsA("Model") and t) or (typeof(t) == "table" and t.Root and t.Root.Parent)
            local root = (typeof(t) == "table" and t.Root) or (model and (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Hitbox") or model.PrimaryPart or model:FindFirstChildOfClass("BasePart")))
            local head = (typeof(t) == "table" and t.Head) or (model and model:FindFirstChild("Head")) or root
            if model and root and model ~= enemy then
                table.insert(targetList, { Model = model, Root = root, Head = head })
            end
        end
    end

    if currentBringData and currentBringData.Mobs then
        for _, item in ipairs(currentBringData.Mobs) do
            local m = (typeof(item) == "table" and item.Model) or (typeof(item) == "Instance" and item)
            local r = (typeof(item) == "table" and item.Root) or (m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart))
            local h = (typeof(item) == "table" and item.Head) or (m and m:FindFirstChild("Head")) or r
            if m and r and m ~= enemy and m.Parent then
                local exists = false
                for _, existing in ipairs(targetList) do
                    if existing.Model == m then exists = true; break end
                end
                if not exists then
                    table.insert(targetList, { Model = m, Root = r, Head = h })
                end
            end
        end
    end

    local fullBatchHit = {}
    for _, t in ipairs(targetList) do
        if t.Model and t.Head then
            table.insert(fullBatchHit, { t.Model, t.Head })
        end
        if t.Model and t.Root and t.Root ~= t.Head then
            table.insert(fullBatchHit, { t.Model, t.Root })
        end
    end

    if regAttack and regAttack:IsA("RemoteEvent") then
        pcall(function() regAttack:FireServer(0) end)
        pcall(function() regAttack:FireServer(0.1) end)
    end

    if regHit and regHit:IsA("RemoteEvent") then
        pcall(function() regHit:FireServer(eHead or eRoot, fullBatchHit) end)
        pcall(function() regHit:FireServer(eRoot, fullBatchHit) end)

        for _, t in ipairs(targetList) do
            pcall(function()
                regHit:FireServer(t.Head or t.Root, fullBatchHit)
                regHit:FireServer(t.Head or t.Root, { { t.Model, t.Head or t.Root }, { t.Model, t.Root } })
            end)
        end
    end

    if commF and commF:IsA("RemoteFunction") then
        task.spawn(function()
            pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
        end)
    end
end

local fruitM1ComboIndex = 1

--[[ Clean up state upon stopping combat safely ]]
function Utility.ReleaseAllHeldSkills()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        for _, kc in ipairs({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V, Enum.KeyCode.F }) do
            pcall(function() vim:SendKeyEvent(false, kc, false, game) end)
        end
        pcall(function() vim:SendMouseButtonEvent(0, 0, 0, false, game, 0) end)
        pcall(function() vim:SendMouseButtonEvent(0, 0, 1, false, game, 0) end)

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.PlatformStand = false
            hum.Sit = false
            hum.AutoRotate = true
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
            if S.CustomWalkSpeed then hum.WalkSpeed = S.CustomWalkSpeed end
            if S.CustomJumpPower then hum.JumpPower = S.CustomJumpPower end
        end
        if root then
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.Velocity = Vector3.zero
            root.RotVelocity = Vector3.zero
        end
    end)
end

--[[ 6. Fruit M1 attack execution:
     Truyền sát thương trực tiếp vào các Body Part (BasePart: UpperTorso, Torso, Root, Head, Arms, Legs)
     thay vì truyền vào Humanoid, kết hợp gọi LeftClickRemote combos 1..4 & 2 regist chuẩn ]]
local function GetMobBodyParts(model)
    local parts = {}
    if not model or not model:IsA("Model") then return parts end
    local bodyNames = {
        "UpperTorso", "Torso", "HumanoidRootPart", "Head", "LowerTorso",
        "RightUpperArm", "LeftUpperArm", "Right Arm", "Left Arm",
        "RightHand", "LeftHand", "RightUpperLeg", "LeftUpperLeg",
        "Right Leg", "Left Leg", "RightFoot", "LeftFoot"
    }
    for _, n in ipairs(bodyNames) do
        local p = model:FindFirstChild(n)
        if p and p:IsA("BasePart") then
            table.insert(parts, p)
        end
    end
    if #parts == 0 then
        for _, c in ipairs(model:GetChildren()) do
            if c:IsA("BasePart") then
                table.insert(parts, c)
            end
        end
    end
    return parts
end

function Utility.AttackFruitM1(enemy, enemyRoot, extraTargets)
    local tool = Utility.EquipWeaponByType("Fruit")
    local primaryModel = (enemy and enemy:IsA("Model") and enemy) or (enemyRoot and enemyRoot.Parent)
    local primaryParts = GetMobBodyParts(primaryModel)
    local primaryBodyPart = (primaryModel and (primaryModel:FindFirstChild("UpperTorso") or primaryModel:FindFirstChild("Torso") or primaryModel:FindFirstChild("HumanoidRootPart") or primaryModel:FindFirstChild("Head")))
                            or enemyRoot 
                            or (primaryParts and primaryParts[1])
    if not primaryBodyPart then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local myPos = myRoot.Position
    local targetPos = primaryBodyPart.Position

    local flatTarget = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
    if (flatTarget - myPos).Magnitude > 0.1 then
        myRoot.CFrame = CFrame.lookAt(myPos, flatTarget)
    end

    local diff = (targetPos - myPos)
    local aim3D = (diff.Magnitude > 0) and diff.Unit or Vector3.new(0, -1, 0)
    local aimFlat = Vector3.new(diff.X, 0, diff.Z)
    local aimHorizontal = (aimFlat.Magnitude > 0) and aimFlat.Unit or aim3D

    local charTool = char:FindFirstChildOfClass("Tool")
    local currentTool = tool or charTool
    if currentTool then
        pcall(function() currentTool:Activate() end)
    end

    -- 1. Tìm LeftClickRemote trên Fruit tool
    local lcr = (currentTool and (currentTool:FindFirstChild("LeftClickRemote") or currentTool:FindFirstChild("LeftClickRemote", true)))
                or (charTool and (charTool:FindFirstChild("LeftClickRemote") or charTool:FindFirstChild("LeftClickRemote", true)))

    -- 2. Gọi tất cả các đòn leftclickremote từ combo 1, 2, 3, 4 truyền vào body part
    if lcr and lcr:IsA("RemoteEvent") then
        for combo = 1, 4 do
            pcall(function() lcr:FireServer(aimHorizontal, combo, true, targetPos, primaryBodyPart) end)
            pcall(function() lcr:FireServer(aim3D, combo, true, targetPos, primaryBodyPart) end)
            pcall(function() lcr:FireServer((targetPos - myPos).Unit, combo, true, targetPos, primaryBodyPart) end)
            pcall(function() lcr:FireServer(primaryBodyPart, combo, true, targetPos) end)
        end
    end

    -- 3. Trigger CombatFramework animation & hit registration
    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        local cfModule = ps and ps:FindFirstChild("CombatFramework")
        if cfModule then
            local cf = require(cfModule)
            if cf and cf.activeController then
                local ctrl = cf.activeController
                ctrl.timeToNextAttack = 0
                ctrl.hitboxMagnitude = 60
                ctrl.active = true
                ctrl.increment = 3
                ctrl:attack()
            end
        end
    end)

    -- 4. Thu thập danh sách mục tiêu và toàn bộ Body Parts (BasePart)
    local targetList = {}
    if primaryModel and primaryModel:IsA("Model") then
        table.insert(targetList, { Model = primaryModel, BodyParts = primaryParts, MainPart = primaryBodyPart })
        if primaryModel.Parent and primaryModel.Parent:IsA("Model") and primaryModel.Parent ~= workspace and primaryModel.Parent ~= workspace:FindFirstChild("SeaBeasts") and primaryModel.Parent ~= workspace:FindFirstChild("Enemies") then
            local parentParts = GetMobBodyParts(primaryModel.Parent)
            local pMain = primaryModel.Parent:FindFirstChild("UpperTorso") or primaryModel.Parent:FindFirstChild("Torso") or primaryModel.Parent:FindFirstChild("HumanoidRootPart") or parentParts[1]
            if pMain then
                table.insert(targetList, { Model = primaryModel.Parent, BodyParts = parentParts, MainPart = pMain })
            end
        end
    end

    if extraTargets and typeof(extraTargets) == "table" then
        for _, t in ipairs(extraTargets) do
            local model = (typeof(t) == "table" and t.Model) or (typeof(t) == "Instance" and t:IsA("Model") and t) or (typeof(t) == "table" and t.Root and t.Root.Parent)
            if model and model ~= primaryModel and model.Parent then
                local exists = false
                for _, existing in ipairs(targetList) do
                    if existing.Model == model then exists = true; break end
                end
                if not exists then
                    local bParts = GetMobBodyParts(model)
                    local mainP = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart") or bParts[1]
                    if mainP then
                        table.insert(targetList, { Model = model, BodyParts = bParts, MainPart = mainP })
                    end
                end
            end
        end
    end

    if currentBringData and currentBringData.Mobs then
        for _, item in ipairs(currentBringData.Mobs) do
            local m = (typeof(item) == "table" and item.Model) or (typeof(item) == "Instance" and item)
            if m and m ~= primaryModel and m.Parent then
                local exists = false
                for _, existing in ipairs(targetList) do
                    if existing.Model == m then exists = true; break end
                end
                if not exists then
                    local bParts = (typeof(item) == "table" and item.Parts) or GetMobBodyParts(m)
                    local mainP = (typeof(item) == "table" and item.Root) or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso") or m:FindFirstChild("HumanoidRootPart") or bParts[1]
                    if mainP then
                        table.insert(targetList, { Model = m, BodyParts = bParts, MainPart = mainP })
                    end
                end
            end
        end
    end

    -- Tạo batch hit hoàn toàn từ các Body Parts (BasePart) - Tuyệt đối không truyền Humanoid
    local fullBatchHit = {}
    for _, t in ipairs(targetList) do
        if t.BodyParts and #t.BodyParts > 0 then
            for _, bp in ipairs(t.BodyParts) do
                if bp and bp:IsA("BasePart") then
                    table.insert(fullBatchHit, { t.Model, bp })
                end
            end
        elseif t.MainPart and t.MainPart:IsA("BasePart") then
            table.insert(fullBatchHit, { t.Model, t.MainPart })
        end
    end

    -- Bắn thêm LeftClickRemote combo 1..4 cho từng body part của quái gom cụm
    if lcr and lcr:IsA("RemoteEvent") and #targetList > 1 then
        for _, t in ipairs(targetList) do
            local bp = t.MainPart
            if bp and bp ~= primaryBodyPart then
                local tPos = bp.Position
                local tDir = (tPos - myPos).Unit
                for combo = 1, 4 do
                    pcall(function() lcr:FireServer(tDir, combo, true, tPos, bp) end)
                    pcall(function() lcr:FireServer(bp, combo, true, tPos) end)
                end
            end
        end
    end

    -- 5. Gửi cả 2 regist (RE/RegisterAttack & RE/RegisterHit) truyền vào Body Part
    local rep = game:GetService("ReplicatedStorage")
    local net = rep:FindFirstChild("Modules") and rep.Modules:FindFirstChild("Net")
    local regAttack = net and net:FindFirstChild("RE/RegisterAttack")
    local regHit = net and net:FindFirstChild("RE/RegisterHit")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

    -- [Regist 1]: RE/RegisterAttack
    if regAttack and regAttack:IsA("RemoteEvent") then
        pcall(function() regAttack:FireServer(0) end)
        pcall(function() regAttack:FireServer(0.1) end)
    end

    -- [Regist 2]: RE/RegisterHit - Truyền sát thương trực tiếp vào các body part
    if regHit and regHit:IsA("RemoteEvent") and #fullBatchHit > 0 then
        pcall(function() regHit:FireServer(primaryBodyPart, fullBatchHit) end)

        for _, t in ipairs(targetList) do
            local bp = t.MainPart or (t.BodyParts and t.BodyParts[1])
            if bp and bp:IsA("BasePart") then
                pcall(function()
                    regHit:FireServer(bp, fullBatchHit)
                    local singleHit = {}
                    for _, p in ipairs(t.BodyParts or { bp }) do
                        if p:IsA("BasePart") then
                            table.insert(singleHit, { t.Model, p })
                        end
                    end
                    regHit:FireServer(bp, singleHit)
                end)
            end
        end
    end

    -- CommF_ RegisterAttack
    if commF and commF:IsA("RemoteFunction") then
        task.spawn(function()
            pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
        end)
    end
end

local lastGunClickTime = 0

--[[ 7. Gun attack execution (Rapid fire M1 multi-hit applied to all guns) ]]
function Utility.AttackGun(enemy, enemyRoot, extraTargets)
    local tool = Utility.EquipWeaponByType("Gun")
    local eRoot = enemyRoot or (enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")))
    local eHead = enemy and enemy:FindFirstChild("Head")
    if not eRoot then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local myPos = myRoot.Position
    local targetPos = eRoot.Position

    -- 1. Auto orient character towards target
    local flatTarget = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
    if (flatTarget - myPos).Magnitude > 0.1 then
        myRoot.CFrame = CFrame.lookAt(myPos, flatTarget)
    end

    local rep = game:GetService("ReplicatedStorage")
    local net = rep:FindFirstChild("Modules") and rep.Modules:FindFirstChild("Net")
    local shootGunEvent = net and net:FindFirstChild("RE/ShootGunEvent")
    local regAttack = net and net:FindFirstChild("RE/RegisterAttack")
    local regHit = net and net:FindFirstChild("RE/RegisterHit")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

    -- 2. Trigger Gun M1 (Tool Activation + LeftClickRemote + VirtualInputManager Validator)
    if tool then
        pcall(function() tool:Activate() end)
        local lcr = tool:FindFirstChild("LeftClickRemote") or tool:FindFirstChild("LeftClickRemote", true)
        if lcr and lcr:IsA("RemoteEvent") then
            local aimDir = (targetPos - myPos).Magnitude > 0 and (targetPos - myPos).Unit or Vector3.new(0, 0, -1)
            pcall(function() lcr:FireServer(aimDir, 1, true, targetPos) end)
        end
    end

    if tick() - lastGunClickTime >= 0.5 then
        lastGunClickTime = tick()
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.delay(0.001, function()
                pcall(function()
                    vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end)
            end)
        end)
    end

    -- 3. AoE target cluster list (supports segments, Sea Beasts, and multi-models)
    local targetList = {}
    if enemy and enemy:IsA("Model") then
        local root = eRoot or enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")
        local head = eHead or enemy:FindFirstChild("Head") or root
        if root then
            table.insert(targetList, { Model = enemy, Root = root, Head = head })
        end
        if enemy.Parent and enemy.Parent:IsA("Model") and enemy.Parent ~= workspace and enemy.Parent ~= workspace:FindFirstChild("SeaBeasts") and enemy.Parent ~= workspace:FindFirstChild("Enemies") then
            local pRoot = enemy.Parent:FindFirstChild("HumanoidRootPart") or enemy.Parent.PrimaryPart or root
            local pHead = enemy.Parent:FindFirstChild("Head") or pRoot or head
            if pRoot then
                table.insert(targetList, { Model = enemy.Parent, Root = pRoot, Head = pHead })
            end
        end
    elseif eRoot then
        local model = (enemy and enemy:IsA("Model") and enemy) or eRoot.Parent
        table.insert(targetList, { Model = model, Root = eRoot, Head = eHead or eRoot })
    end

    if extraTargets and typeof(extraTargets) == "table" then
        for _, t in ipairs(extraTargets) do
            local model = (typeof(t) == "table" and t.Model) or (typeof(t) == "Instance" and t:IsA("Model") and t) or (typeof(t) == "table" and t.Root and t.Root.Parent)
            local root = (typeof(t) == "table" and t.Root) or (model and (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Hitbox") or model.PrimaryPart or model:FindFirstChildOfClass("BasePart")))
            local head = (typeof(t) == "table" and t.Head) or (model and model:FindFirstChild("Head")) or root
            if model and root and model ~= enemy then
                table.insert(targetList, { Model = model, Root = root, Head = head })
            end
        end
    end

    if currentBringData and currentBringData.Mobs then
        for _, item in ipairs(currentBringData.Mobs) do
            local m = (typeof(item) == "table" and item.Model) or (typeof(item) == "Instance" and item)
            local r = (typeof(item) == "table" and item.Root) or (m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart))
            local h = (typeof(item) == "table" and item.Head) or (m and m:FindFirstChild("Head")) or r
            if m and r and m ~= enemy and m.Parent then
                local exists = false
                for _, existing in ipairs(targetList) do
                    if existing.Model == m then exists = true; break end
                end
                if not exists then
                    table.insert(targetList, { Model = m, Root = r, Head = h })
                end
            end
        end
    end

    local fullBatchHit = {}
    for _, t in ipairs(targetList) do
        if t.Model and t.Head then
            table.insert(fullBatchHit, { t.Model, t.Head })
        end
        if t.Model and t.Root and t.Root ~= t.Head then
            table.insert(fullBatchHit, { t.Model, t.Root })
        end
    end

    -- 4. Clean bullet burst ShootGunEvent + RegisterHit (optimized network load)
    if shootGunEvent and shootGunEvent:IsA("RemoteEvent") then
        pcall(function() shootGunEvent:FireServer(targetPos, { eRoot }) end)
        if eHead and eHead ~= eRoot then
            pcall(function() shootGunEvent:FireServer(targetPos, { eHead }) end)
        end
        pcall(function() shootGunEvent:FireServer(targetPos, {}) end)
    end

    if regAttack and regAttack:IsA("RemoteEvent") then
        pcall(function() regAttack:FireServer(0) end)
        pcall(function() regAttack:FireServer(0.1) end)
    end

    if regHit and regHit:IsA("RemoteEvent") and #fullBatchHit > 0 then
        pcall(function() regHit:FireServer(eHead or eRoot, fullBatchHit) end)
        pcall(function() regHit:FireServer(eRoot, fullBatchHit) end)
        for _, t in ipairs(targetList) do
            pcall(function()
                regHit:FireServer(t.Head or t.Root, fullBatchHit)
                regHit:FireServer(t.Head or t.Root, { { t.Model, t.Head or t.Root }, { t.Model, t.Root } })
            end)
        end
    end

    if commF and commF:IsA("RemoteFunction") then
        task.spawn(function()
            pcall(function() commF:InvokeServer("RegisterAttack", 1) end)
        end)
    end
end

--[[ Dragonstorm combat execution (Routed directly to Gun attack) ]]
function Utility.AttackDragonstorm(enemy, enemyRoot)
    Utility.AttackGun(enemy, enemyRoot)
end

--[[ Helper to find tool in Character or Backpack and return its RemoteEvent without interfering with player controls ]]
function Utility.GetWeaponRemote(wType)
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")

    -- Priority containers based on weapon type:
    -- Gun: check Backpack first, then Character
    -- Melee, Sword, Fruit: check Character first, then Backpack
    local containers = (wType == "Gun") and { bp, char } or { char, bp }

    for _, container in ipairs(containers) do
        if container then
            local tool = Utility.FindWeaponInContainer(container, wType)
            if tool then
                local ev = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent") or tool:FindFirstChild("LeftClickRemote")
                if ev and ev:IsA("RemoteEvent") then
                    return ev, tool
                end
            end
        end
    end
    return nil, nil
end

--[[ 8. Aim skill direction towards target (downwards hit vector) ]]
function Utility.AimTarget(targetPosition)
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.zero

    local downTargetPos = Vector3.new(myPos.X, -100, myPos.Z)
    local downAimCF = CFrame.lookAt(myPos, downTargetPos)
    local downHitCF = CFrame.new(downTargetPos)
    local downDir = Vector3.new(0, -1, 0)

    return downTargetPos, downAimCF, downHitCF, downDir
end

--[[ Helper to check if enemy model is valid and alive ]]
function Utility.IsTargetAlive(enemy)
    if not enemy or not enemy.Parent then return false end
    if enemy:GetAttribute("Dead") == true or enemy:FindFirstChild("Dead") then return false end
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    local attrHealth = enemy:GetAttribute("Health")
    if typeof(attrHealth) == "number" and attrHealth <= 0 then return false end
    return true
end

--[[ Check KenTrail Emission Enabled in Character.Head and activate Ken Haki if disabled ]]
function Utility.CheckAndEnableKenHaki()
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local kenTrail = head:FindFirstChild("KenTrail")
    local isEnabled = false

    if kenTrail then
        if kenTrail:IsA("ParticleEmitter") or kenTrail:IsA("Trail") then
            isEnabled = kenTrail.Enabled
        elseif typeof(kenTrail.Enabled) == "boolean" then
            isEnabled = kenTrail.Enabled
        end
    end

    if not isEnabled then
        local rep = game:GetService("ReplicatedStorage")
        local commE = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommE")
        if commE and commE:IsA("RemoteEvent") then
            pcall(function()
                commE:FireServer("Ken", true)
            end)
        end
    end
end

function Utility.StartAutoObservationLoop()
    DisconnectConnection("autoObservationLoop")
    _conns["autoObservationLoop"] = task.spawn(function()
        while S.AutoObservation do
            pcall(function()
                Utility.CheckAndEnableKenHaki()
            end)
            collectgarbage("step", 50) -- Per-cycle GC
            task.wait(1.5)
        end
    end)
end

--[[ Check KenTrail Emission Enabled in Character.Head and activate Ken Haki if disabled ]]
function Utility.CheckAndEnableKenHaki()
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local kenTrail = head:FindFirstChild("KenTrail")
    local isEnabled = false

    if kenTrail then
        if kenTrail:IsA("ParticleEmitter") or kenTrail:IsA("Trail") then
            isEnabled = kenTrail.Enabled
        elseif typeof(kenTrail.Enabled) == "boolean" then
            isEnabled = kenTrail.Enabled
        end
    end

    if not isEnabled then
        local rep = game:GetService("ReplicatedStorage")
        local commE = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommE")
        if commE and commE:IsA("RemoteEvent") then
            pcall(function()
                commE:FireServer("Ken", true)
            end)
        end
    end
end

function Utility.StartAutoObservationLoop()
    DisconnectConnection("autoObservationLoop")
    _conns["autoObservationLoop"] = task.spawn(function()
        while S.AutoObservation do
            pcall(function()
                Utility.CheckAndEnableKenHaki()
            end)
            collectgarbage("step", 50) -- Per-cycle GC
            task.wait(1.5)
        end
    end)
end

--[[ 9. Cast Melee skills (Z, X, C) with weapon equipping, key trigger & continuous aim loop ]]
function Utility.CastSkillsMelee(targetPosition, enemy)
    local tool = Utility.EquipWeaponByType("Melee")
    local enemyPart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))
    local currentTargetPos = (enemyPart and enemyPart.Position) or targetPosition
    if not currentTargetPos then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local ev = tool and (tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent") or tool:FindFirstChild("LeftClickRemote"))
    local skillRemotes = {}
    for _, child in ipairs(hum:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end

    local skillKeys = {}
    if S.MeleeSkillZ then table.insert(skillKeys, "Z") end
    if S.MeleeSkillX then table.insert(skillKeys, "X") end
    if S.MeleeSkillC then table.insert(skillKeys, "C") end

    local vim = game:GetService("VirtualInputManager")

    for _, key in ipairs(skillKeys) do
        if not char.Parent or not hum or hum.Health <= 0 then break end

        local livePart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")) or enemyPart
        local livePos = livePart and livePart.Position or currentTargetPos
        local liveCF = livePart and livePart.CFrame or CFrame.new(livePos)

        -- 1. Kích hoạt chiêu qua Remote & Server
        for _, rf in ipairs(skillRemotes) do
            task.spawn(function()
                pcall(function() rf:InvokeServer(key, livePos) end)
                pcall(function() rf:InvokeServer(key, liveCF, "Aaa") end)
                pcall(function() rf:InvokeServer(key) end)
            end)
        end
        if ev then
            pcall(function() ev:FireServer(livePos) end)
            pcall(function() ev:FireServer(liveCF) end)
        end

        -- 2. Kích hoạt phím qua VirtualInputManager
        local kc = Enum.KeyCode[key]
        if kc then
            pcall(function() vim:SendKeyEvent(true, kc, false, game) end)
            local holdTime = S.HoldMeleeSkills and (S.SkillHoldDuration or 0.25) or 0.06
            task.wait(holdTime)
            pcall(function() vim:SendKeyEvent(false, kc, false, game) end)
        end

        -- 3. Vòng lặp ngắm chiêu liên tục gửi tọa độ mục tiêu
        local duration = S.HoldMeleeSkills and (S.SkillHoldDuration or 0.35) or 0.08
        local t0 = os.clock()
        while (os.clock() - t0 < duration) and Utility.IsTargetAlive(enemy) do
            if not char.Parent or not hum or hum.Health <= 0 then break end

            livePart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")) or enemyPart
            livePos = livePart and livePart.Position or currentTargetPos
            liveCF = livePart and livePart.CFrame or CFrame.new(livePos)

            if ev then
                pcall(function() ev:FireServer(livePos) end)
                pcall(function() ev:FireServer(liveCF) end)
            end
            for _, rf in ipairs(skillRemotes) do
                task.spawn(function()
                    pcall(function() rf:InvokeServer(key, livePos) end)
                end)
            end

            Utility.AttackMelee(enemy, livePart)
            task.wait(0.035)
        end

        task.wait(0.04)
    end
end

--[[ 10. Cast Fruit skills (Z, X, C, V, F) with weapon equipping, key trigger & continuous aim loop ]]
function Utility.CastSkillsFruit(targetPosition, enemy)
    local tool = Utility.EquipWeaponByType("Fruit")
    local enemyPart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))
    local currentTargetPos = (enemyPart and enemyPart.Position) or targetPosition
    if not currentTargetPos then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local ev = tool and (tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent") or tool:FindFirstChild("LeftClickRemote"))
    local skillRemotes = {}
    for _, child in ipairs(hum:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end

    local skillKeys = {}
    if S.FruitSkillZ then table.insert(skillKeys, "Z") end
    if S.FruitSkillX then table.insert(skillKeys, "X") end
    if S.FruitSkillC then table.insert(skillKeys, "C") end
    if S.FruitSkillV then table.insert(skillKeys, "V") end
    if S.FruitSkillF then table.insert(skillKeys, "F") end

    local vim = game:GetService("VirtualInputManager")

    for _, key in ipairs(skillKeys) do
        if not char.Parent or not hum or hum.Health <= 0 then break end

        local livePart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")) or enemyPart
        local livePos = livePart and livePart.Position or currentTargetPos
        local liveCF = livePart and livePart.CFrame or CFrame.new(livePos)

        -- 1. Kích hoạt chiêu thức
        for _, rf in ipairs(skillRemotes) do
            task.spawn(function()
                pcall(function() rf:InvokeServer(key, livePos) end)
                pcall(function() rf:InvokeServer(key, liveCF, "Aaa") end)
                pcall(function() rf:InvokeServer(key) end)
            end)
        end
        if ev then
            pcall(function() ev:FireServer(livePos) end)
            pcall(function() ev:FireServer(liveCF) end)
        end

        -- 2. Kích hoạt phím qua VirtualInputManager
        local kc = Enum.KeyCode[key]
        if kc then
            pcall(function() vim:SendKeyEvent(true, kc, false, game) end)
            local holdTime = S.HoldFruitSkills and (S.SkillHoldDuration or 0.25) or 0.06
            task.wait(holdTime)
            pcall(function() vim:SendKeyEvent(false, kc, false, game) end)
        end

        -- 3. Vòng lặp ngắm chiêu liên tục gửi tọa độ mục tiêu
        local duration = S.HoldFruitSkills and (S.SkillHoldDuration or 0.35) or 0.08
        local t0 = os.clock()
        while (os.clock() - t0 < duration) and Utility.IsTargetAlive(enemy) do
            if not char.Parent or not hum or hum.Health <= 0 then break end

            livePart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")) or enemyPart
            livePos = livePart and livePart.Position or currentTargetPos
            liveCF = livePart and livePart.CFrame or CFrame.new(livePos)

            if ev then
                pcall(function() ev:FireServer(livePos) end)
                pcall(function() ev:FireServer(liveCF) end)
            end
            for _, rf in ipairs(skillRemotes) do
                task.spawn(function()
                    pcall(function() rf:InvokeServer(key, livePos) end)
                end)
            end

            Utility.AttackFruitM1(enemy, livePart)
            task.wait(0.035)
        end

        task.wait(0.04)
    end
end

--[[ 11. Cast Sword skills (Z, X) with weapon equipping, key trigger & continuous aim loop ]]
function Utility.CastSkillsSword(targetPosition, enemy)
    local tool = Utility.EquipWeaponByType("Sword")
    local enemyPart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))
    local currentTargetPos = (enemyPart and enemyPart.Position) or targetPosition
    if not currentTargetPos then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local ev = tool and (tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent") or tool:FindFirstChild("LeftClickRemote"))
    local skillRemotes = {}
    for _, child in ipairs(hum:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end

    local skillKeys = {}
    if S.SwordSkillZ then table.insert(skillKeys, "Z") end
    if S.SwordSkillX then table.insert(skillKeys, "X") end

    local vim = game:GetService("VirtualInputManager")

    for _, key in ipairs(skillKeys) do
        if not char.Parent or not hum or hum.Health <= 0 then break end

        local livePart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")) or enemyPart
        local livePos = livePart and livePart.Position or currentTargetPos
        local liveCF = livePart and livePart.CFrame or CFrame.new(livePos)

        -- 1. Kích hoạt chiêu thức
        for _, rf in ipairs(skillRemotes) do
            task.spawn(function()
                pcall(function() rf:InvokeServer(key, livePos) end)
                pcall(function() rf:InvokeServer(key, liveCF, "Aaa") end)
                pcall(function() rf:InvokeServer(key) end)
            end)
        end
        if ev then
            pcall(function() ev:FireServer(livePos) end)
            pcall(function() ev:FireServer(liveCF) end)
        end

        -- 2. Kích hoạt phím qua VirtualInputManager
        local kc = Enum.KeyCode[key]
        if kc then
            pcall(function() vim:SendKeyEvent(true, kc, false, game) end)
            local holdTime = S.HoldSwordSkills and (S.SkillHoldDuration or 0.25) or 0.06
            task.wait(holdTime)
            pcall(function() vim:SendKeyEvent(false, kc, false, game) end)
        end

        -- 3. Vòng lặp ngắm chiêu liên tục gửi tọa độ mục tiêu
        local duration = S.HoldSwordSkills and (S.SkillHoldDuration or 0.35) or 0.08
        local t0 = os.clock()
        while (os.clock() - t0 < duration) and Utility.IsTargetAlive(enemy) do
            if not char.Parent or not hum or hum.Health <= 0 then break end

            livePart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")) or enemyPart
            livePos = livePart and livePart.Position or currentTargetPos
            liveCF = livePart and livePart.CFrame or CFrame.new(livePos)

            if ev then
                pcall(function() ev:FireServer(livePos) end)
                pcall(function() ev:FireServer(liveCF) end)
            end
            for _, rf in ipairs(skillRemotes) do
                task.spawn(function()
                    pcall(function() rf:InvokeServer(key, livePos) end)
                end)
            end

            Utility.AttackSword(enemy, livePart)
            task.wait(0.035)
        end

        task.wait(0.04)
    end
end

--[[ 12. Cast Gun skills (Z, X) with weapon equipping, key trigger & continuous aim loop ]]
function Utility.CastSkillsGun(targetPosition, enemy)
    local tool = Utility.EquipWeaponByType("Gun")
    local enemyPart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart"))
    local currentTargetPos = (enemyPart and enemyPart.Position) or targetPosition
    if not currentTargetPos then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local ev = tool and (tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent") or tool:FindFirstChild("LeftClickRemote"))
    local skillRemotes = {}
    for _, child in ipairs(hum:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(skillRemotes, child)
        end
    end

    local skillKeys = {}
    if S.GunSkillZ then table.insert(skillKeys, "Z") end
    if S.GunSkillX then table.insert(skillKeys, "X") end

    local vim = game:GetService("VirtualInputManager")

    for _, key in ipairs(skillKeys) do
        if not char.Parent or not hum or hum.Health <= 0 then break end

        local livePart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")) or enemyPart
        local livePos = livePart and livePart.Position or currentTargetPos
        local liveCF = livePart and livePart.CFrame or CFrame.new(livePos)

        -- 1. Kích hoạt chiêu thức
        for _, rf in ipairs(skillRemotes) do
            task.spawn(function()
                pcall(function() rf:InvokeServer(key, livePos) end)
                pcall(function() rf:InvokeServer(key, liveCF, "Aaa") end)
                pcall(function() rf:InvokeServer(key) end)
            end)
        end
        if ev then
            pcall(function() ev:FireServer(livePos) end)
            pcall(function() ev:FireServer(liveCF) end)
        end

        -- 2. Kích hoạt phím qua VirtualInputManager
        local kc = Enum.KeyCode[key]
        if kc then
            pcall(function() vim:SendKeyEvent(true, kc, false, game) end)
            local holdTime = S.HoldGunSkills and (S.SkillHoldDuration or 0.25) or 0.06
            task.wait(holdTime)
            pcall(function() vim:SendKeyEvent(false, kc, false, game) end)
        end

        -- 3. Vòng lặp ngắm chiêu liên tục gửi tọa độ mục tiêu
        local duration = S.HoldGunSkills and (S.SkillHoldDuration or 0.35) or 0.08
        local t0 = os.clock()
        while (os.clock() - t0 < duration) and Utility.IsTargetAlive(enemy) do
            if not char.Parent or not hum or hum.Health <= 0 then break end

            livePart = enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChild("Hitbox") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")) or enemyPart
            livePos = livePart and livePart.Position or currentTargetPos
            liveCF = livePart and livePart.CFrame or CFrame.new(livePos)

            if ev then
                pcall(function() ev:FireServer(livePos) end)
                pcall(function() ev:FireServer(liveCF) end)
            end
            for _, rf in ipairs(skillRemotes) do
                task.spawn(function()
                    pcall(function() rf:InvokeServer(key, livePos) end)
                end)
            end

            Utility.AttackGun(enemy, livePart)
            task.wait(0.035)
        end

        task.wait(0.04)
    end
end

--[[ Start auto attack nearest enemy routine ]]
function Utility.StartAutoAttackNearestEnemy()
    DisconnectConnection("autoAttackEnemyLoop")
    _conns["autoAttackEnemyLoop"] = task.spawn(function()
        while S.AutoAttackEnemyEnabled do
            local enemy = Utility.GetNearestEnemyFromFolder()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if enemy and root and hum and hum.Health > 0 then
                local eHum = enemy:FindFirstChildOfClass("Humanoid")
                local eCF, ePos, eRoot = Utility.GetEnemyRootCFrame(enemy)

                if eRoot and eHum and eHum.Health > 0 then
                    -- 3. Fly to target height (default 30 studs)
                    Utility.FlyAboveTarget(eCF, S.AttackHeight or 30, S.TeleportFlySpeed or 180)

                    local wType = S.SelectedWeaponType or "Melee"
                    if wType == "Melee" then
                        Utility.AttackMelee(enemy, eRoot)
                    elseif wType == "Sword" then
                        Utility.AttackSword(enemy, eRoot)
                    elseif wType == "Fruit" then
                        Utility.AttackFruitM1(enemy, eRoot)
                    elseif wType == "Gun" then
                        Utility.AttackGun(enemy, eRoot)
                    end

                    if S.AutoFarmUseSkills then
                        if wType == "Melee" then
                            Utility.CastSkillsMelee(ePos, enemy)
                        elseif wType == "Fruit" then
                            Utility.CastSkillsFruit(ePos, enemy)
                        elseif wType == "Sword" then
                            Utility.CastSkillsSword(ePos, enemy)
                        elseif wType == "Gun" then
                            Utility.CastSkillsGun(ePos, enemy)
                        end
                    end
                end
            else
                Utility.StopPhysicsFly()
            end
            collectgarbage("step", 50) -- Per-cycle GC
            task.wait(0.035)
        end
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop auto attack nearest enemy routine ]]
function Utility.StopAutoAttackNearestEnemy()
    DisconnectConnection("autoAttackEnemyLoop")
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

--[[ Start auto farm nearest enemy with skills routine ]]
function Utility.StartAutoFarmWithSkills()
    DisconnectConnection("autoFarmSkills")
    _conns["autoFarmSkills"] = task.spawn(function()
        while S.AutoFarmWithSkillsEnabled do
            local enemy = Utility.GetNearestEnemyFromFolder()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if enemy and root and hum and hum.Health > 0 then
                local eHum = enemy:FindFirstChildOfClass("Humanoid")
                local eCF, ePos, eRoot = Utility.GetEnemyRootCFrame(enemy)

                if eRoot and eHum and eHum.Health > 0 then
                    Utility.FlyAboveTarget(eCF, S.AttackHeight or 30, S.TeleportFlySpeed or 180)
                    local wType = S.SelectedWeaponType or "Melee"
                    if wType == "Melee" then
                        Utility.AttackMelee(enemy, eRoot)
                        Utility.CastSkillsMelee(ePos, enemy)
                    elseif wType == "Fruit" then
                        Utility.AttackFruitM1(enemy, eRoot)
                        Utility.CastSkillsFruit(ePos, enemy)
                    elseif wType == "Sword" then
                        Utility.AttackSword(enemy, eRoot)
                        Utility.CastSkillsSword(ePos, enemy)
                    elseif wType == "Gun" then
                        Utility.AttackGun(enemy, eRoot)
                        Utility.CastSkillsGun(ePos, enemy)
                    end
                end
            else
                Utility.StopPhysicsFly()
            end
            collectgarbage("step", 50) -- Per-cycle GC
            task.wait(0.035)
        end
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop auto farm nearest enemy with skills routine ]]
function Utility.StopAutoFarmWithSkills()
    DisconnectConnection("autoFarmSkills")
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

-- ═══════════════════════════════════════════════════════════


-- ========================================================
-- [SECTION: AUTO FARM DATABASE & PROGRESSION ENGINE]
-- ========================================================
--  AUTO FARM DATABASE & PROGRESSION ENGINE
-- ═══════════════════════════════════════════════════════════


local LEVEL_QUEST_DATA = {
    {
        Min = 1, Max = 9,
        Mob = "Bandit",
        Quest = "BanditQuest1",
        QLevel = 1,
        GiverPos = Vector3.new(1059, 16, 1549),
        MobPos = Vector3.new(1337, 16, 1572),
        SpawnPoints = {
            Vector3.new(1337, 16, 1572),
            Vector3.new(1233, 16, 1555),
            Vector3.new(1274, 16, 1630),
            Vector3.new(1219, 16, 1669),
            Vector3.new(1013, 18, 1570),
            Vector3.new(949, 16, 1619),
            Vector3.new(937, 16, 1513),
        }
    },
    {
        Min = 10, Max = 14,
        Mob = "Monkey",
        Quest = "JungleQuest",
        QLevel = 1,
        GiverPos = Vector3.new(-1601, 36, 153),
        MobPos = Vector3.new(-1295, 12, -3),
        SpawnPoints = {
            Vector3.new(-1295, 12, -3),
            Vector3.new(-1201, 12, 278),
            Vector3.new(-1578, 23, 381),
            Vector3.new(-1796, 23, 103),
            Vector3.new(-1739, 23, -87),
            Vector3.new(-1615, 23, -40),
            Vector3.new(-1494, 23, 91),
        }
    },
    {
        Min = 15, Max = 29,
        Mob = "Gorilla",
        Quest = "JungleQuest",
        QLevel = 2,
        GiverPos = Vector3.new(-1601, 36, 153),
        MobPos = Vector3.new(-1364, 19, -484),
        SpawnPoints = {
            Vector3.new(-1364, 19, -484),
            Vector3.new(-1190, 6, -649),
            Vector3.new(-1247, 6, -551),
            Vector3.new(-1247, 6, -467),
        }
    },
    {
        Min = 30, Max = 39,
        Mob = "Pirate",
        Quest = "BuggyQuest1",
        QLevel = 1,
        GiverPos = Vector3.new(-1140, 4, 3829),
        MobPos = Vector3.new(-1272, 5, 3856),
        SpawnPoints = {
            Vector3.new(-1272, 5, 3856),
            Vector3.new(-1286, 5, 3949),
            Vector3.new(-1186, 5, 3978),
            Vector3.new(-1133, 5, 3902),
            Vector3.new(-971, 14, 3942),
            Vector3.new(-963, 14, 4041),
        }
    },
    {
        Min = 40, Max = 59,
        Mob = "Brute",
        Quest = "BuggyQuest1",
        QLevel = 2,
        GiverPos = Vector3.new(-1140, 4, 3829),
        MobPos = Vector3.new(-982, 15, 4220),
        SpawnPoints = {
            Vector3.new(-982, 15, 4220),
            Vector3.new(-870, 15, 4283),
            Vector3.new(-1053, 15, 4414),
            Vector3.new(-1228, 15, 4342),
            Vector3.new(-1182, 15, 4238),
            Vector3.new(-1394, 15, 4193),
        }
    },
    {
        Min = 60, Max = 74,
        Mob = "Desert Bandit",
        Quest = "DesertQuest",
        QLevel = 1,
        GiverPos = Vector3.new(896, 6, 4390),
        MobPos = Vector3.new(860, 7, 4499),
        SpawnPoints = {
            Vector3.new(860, 7, 4499),
            Vector3.new(939, 7, 4538),
            Vector3.new(994, 7, 4487),
            Vector3.new(938, 7, 4423),
        }
    },
    {
        Min = 75, Max = 89,
        Mob = "Desert Officer",
        Quest = "DesertQuest",
        QLevel = 2,
        GiverPos = Vector3.new(896, 6, 4390),
        MobPos = Vector3.new(1586, 2, 4296),
        SpawnPoints = {
            Vector3.new(1586, 2, 4296),
            Vector3.new(1659, 17, 4320),
            Vector3.new(1671, 10, 4397),
            Vector3.new(1614, 1, 4470),
        }
    },
    {
        Min = 90, Max = 99,
        Mob = "Snow Bandit",
        Quest = "SnowQuest",
        QLevel = 1,
        GiverPos = Vector3.new(1385, 87, -1298),
        MobPos = Vector3.new(1460, 87, -1446),
        SpawnPoints = {
            Vector3.new(1460, 87, -1446),
            Vector3.new(1385, 87, -1466),
            Vector3.new(1310, 87, -1398),
            Vector3.new(1310, 87, -1398),
            Vector3.new(1276, 88, -1347),
        }
    },
    {
        Min = 100, Max = 119,
        Mob = "Snowman",
        Quest = "SnowQuest",
        QLevel = 2,
        GiverPos = Vector3.new(1385, 87, -1298),
        MobPos = Vector3.new(1182, 106, -1624),
        SpawnPoints = {
            Vector3.new(1182, 106, -1624),
            Vector3.new(1031, 106, -1489),
            Vector3.new(1155, 106, -1431),
            Vector3.new(1270, 106, -1479),
        }
    },
    {
        Min = 120, Max = 149,
        Mob = "Chief Petty Officer",
        Quest = "MarineQuest2",
        QLevel = 1,
        GiverPos = Vector3.new(-5035, 29, 4325),
        MobPos = Vector3.new(-5121, 21, 4058),
        SpawnPoints = {
            Vector3.new(-5121, 21, 4058),
            Vector3.new(-4986, 21, 3943),
            Vector3.new(-4918, 21, 4078),
            Vector3.new(-4805, 21, 3996),
            Vector3.new(-4621, 21, 4408),
            Vector3.new(-4636, 21, 4549),
            Vector3.new(-4812, 21, 4529),
            Vector3.new(-4866, 21, 4654),
        }
    },
    {
        Min = 150, Max = 174,
        Mob = "Sky Bandit",
        Quest = "SkyQuest",
        QLevel = 1,
        GiverPos = Vector3.new(-4839, 718, -2619),
        MobPos = Vector3.new(-4943, 278, -2782),
        SpawnPoints = {
            Vector3.new(-4943, 278, -2782),
            Vector3.new(-5117, 278, -2807),
            Vector3.new(-5088, 278, -2944),
            Vector3.new(-4862, 278, -2902),
        }
    },
    {
        Min = 175, Max = 189,
        Mob = "Dark Master",
        Quest = "SkyQuest",
        QLevel = 2,
        GiverPos = Vector3.new(-4839, 718, -2619),
        MobPos = Vector3.new(-5332, 389, -2269),
        SpawnPoints = {
            Vector3.new(-5332, 389, -2269),
            Vector3.new(-5241, 389, -2164),
            Vector3.new(-5170, 389, -2241),
            Vector3.new(-5238, 389, -2370),
        }
    },
    {
        Min = 190, Max = 209,
        Mob = "Prisoner",
        Quest = "PrisonerQuest",
        QLevel = 1,
        GiverPos = Vector3.new(5308, 2, 474),
        MobPos = Vector3.new(5354, 2, 386),
        SpawnPoints = {
            Vector3.new(5354, 2, 386),
            Vector3.new(5219, 2, 448),
            Vector3.new(5093, 2, 418),
            Vector3.new(5064, 2, 542),
            Vector3.new(4936, 2, 647),
        }
    },
    {
        Min = 210, Max = 249,
        Mob = "Dangerous Prisoner",
        Quest = "PrisonerQuest",
        QLevel = 2,
        GiverPos = Vector3.new(5308, 2, 474),
        MobPos = Vector3.new(5488, 2, 459),
        SpawnPoints = {
            Vector3.new(5488, 2, 459),
            Vector3.new(5562, 2, 583),
            Vector3.new(5651, 2, 763),
            Vector3.new(5564, 2, 957),
            Vector3.new(5434, 2, 1067),
            Vector3.new(5111, 2, 1053),
            Vector3.new(4968, 2, 921),
        }
    },
    {
        Min = 250, Max = 274,
        Mob = "Toga Warrior",
        Quest = "ColosseumQuest",
        QLevel = 1,
        GiverPos = Vector3.new(-1576, 7, -2988),
        MobPos = Vector3.new(-1796, 7, -2856),
        SpawnPoints = {
            Vector3.new(-1796, 7, -2856),
            Vector3.new(-2127, 7, -2857),
            Vector3.new(-2049, 7, -2717),
            Vector3.new(-1833, 7, -2670),
            Vector3.new(-1678, 7, -2686),
        }
    },
    {
        Min = 275, Max = 299,
        Mob = "Gladiator",
        Quest = "ColosseumQuest",
        QLevel = 2,
        GiverPos = Vector3.new(-1576, 7, -2988),
        MobPos = Vector3.new(-1476, 8, -3188),
        SpawnPoints = {
            Vector3.new(-1476, 8, -3188),
            Vector3.new(-1370, 7, -3381),
            Vector3.new(-1355, 7, -3597),
            Vector3.new(-1118, 7, -3278),
            Vector3.new(-1230, 7, -3058),
        }
    },
    {
        Min = 300, Max = 324,
        Mob = "Military Soldier",
        Quest = "MagmaQuest",
        QLevel = 1,
        GiverPos = Vector3.new(-5315, 12, 8515),
        MobPos = Vector3.new(-5678, 9, 8428),
        SpawnPoints = {
            Vector3.new(-5678, 9, 8428),
            Vector3.new(-5561, 9, 8335),
            Vector3.new(-5438, 9, 8353),
            Vector3.new(-5409, 9, 8588),
            Vector3.new(-5290, 9, 8655),
        }
    },
    {
        Min = 325, Max = 374,
        Mob = "Military Spy",
        Quest = "MagmaQuest",
        QLevel = 2,
        GiverPos = Vector3.new(-5315, 12, 8515),
        MobPos = Vector3.new(-5798, 77, 8902),
        SpawnPoints = {
            Vector3.new(-5798, 77, 8902),
            Vector3.new(-5923, 77, 8847),
            Vector3.new(-5857, 77, 8780),
            Vector3.new(-5783, 77, 8644),
        }
    },
    {
        Min = 375, Max = 399,
        Mob = "Fishman Warrior",
        Quest = "FishmanQuest",
        QLevel = 1,
        GiverPos = Vector3.new(60900, 19, 1500),
        MobPos = Vector3.new(60932, 19, 1182),
        SpawnPoints = {
            Vector3.new(60932, 19, 1182),
            Vector3.new(60844, 19, 1300),
            Vector3.new(60941, 19, 1376),
            Vector3.new(60906, 19, 1465),
            Vector3.new(60792, 19, 1534),
            Vector3.new(60842, 18, 1654),
            Vector3.new(60946, 19, 1747),
        }
    },
    {
        Min = 400, Max = 449,
        Mob = "Fishman Commando",
        Quest = "FishmanQuest",
        QLevel = 2,
        GiverPos = Vector3.new(60900, 19, 1500),
        MobPos = Vector3.new(61702, 19, 1526),
        SpawnPoints = {
            Vector3.new(61702, 19, 1526),
            Vector3.new(61756, 19, 1461),
            Vector3.new(61796, 19, 1285),
            Vector3.new(62057, 19, 1420),
            Vector3.new(61972, 19, 1618),
            Vector3.new(61855, 18, 1689),
        }
    },
    {
        Min = 450, Max = 474,
        Mob = "God's Guard",
        Quest = "SkyExp1Quest",
        QLevel = 1,
        GiverPos = Vector3.new(-4723, 845, -1948),
        MobPos = Vector3.new(-4587, 843, -1937),
        SpawnPoints = {
            Vector3.new(-4587, 843, -1937),
            Vector3.new(-4616, 843, -2049),
            Vector3.new(-4818, 843, -2039),
            Vector3.new(-4857, 843, -1908),
            Vector3.new(-4828, 843, -1782),
            Vector3.new(-4692, 845, -1800),
        }
    },
    {
        Min = 475, Max = 524,
        Mob = "Shanda",
        Quest = "SkyExp1Quest",
        QLevel = 2,
        GiverPos = Vector3.new(-7862, 5546, -383),
        MobPos = Vector3.new(-7717, 5546, -584),
        SpawnPoints = {
            Vector3.new(-7717, 5546, -584),
            Vector3.new(-7590, 5546, -651),
            Vector3.new(-7537, 5546, -523),
            Vector3.new(-7565, 5546, -423),
            Vector3.new(-7711, 5545, -343),
            Vector3.new(-7795, 5546, -482),
        }
    },
    {
        Min = 525, Max = 549,
        Mob = "Royal Squad",
        Quest = "SkyExp2Quest",
        QLevel = 1,
        GiverPos = Vector3.new(-7909, 5636, -1409),
        MobPos = Vector3.new(-7840.4, 5606.9, -1410.6),
        SpawnPoints = {
            Vector3.new(-7840.4, 5606.9, -1410.6),
            Vector3.new(-7723.8, 5606.9, -1515.1),
            Vector3.new(-7532.1, 5606.9, -1542.5),
            Vector3.new(-7523.1, 5606.9, -1421.2),
            Vector3.new(-7670.4, 5606.9, -1379.3),
        }
    },
    {
        Min = 550, Max = 624,
        Mob = "Royal Soldier",
        Quest = "SkyExp2Quest",
        QLevel = 2,
        GiverPos = Vector3.new(-7909, 5636, -1409),
        MobPos = Vector3.new(-7773, 5608, -1725),
        SpawnPoints = {
            Vector3.new(-7773, 5608, -1725),
            Vector3.new(-7760, 5607, -1864),
            Vector3.new(-7949, 5607, -1821),
            Vector3.new(-7918, 5607, -1719),
            Vector3.new(-7937, 5607, -1618),
        }
    },
    {
        Min = 625, Max = 649,
        Mob = "Galley Pirate",
        Quest = "FountainQuest",
        QLevel = 1,
        GiverPos = Vector3.new(5257, 39, 4049),
        MobPos = Vector3.new(5828, 39, 3928),
        SpawnPoints = {
            Vector3.new(5828, 39, 3928),
            Vector3.new(5721, 59, 4049),
            Vector3.new(5656, 39, 3912),
            Vector3.new(5521, 39, 3933),
            Vector3.new(5490, 55, 4059),
            Vector3.new(5359, 39, 3958),
        }
    },
    {
        Min = 650, Max = 699,
        Mob = "Galley Captain",
        Quest = "FountainQuest",
        QLevel = 2,
        GiverPos = Vector3.new(5257, 39, 4049),
        MobPos = Vector3.new(5895, 39, 4948),
        SpawnPoints = {
            Vector3.new(5895, 39, 4948),
            Vector3.new(5954, 39, 4875),
            Vector3.new(5911, 50, 4775),
            Vector3.new(5792, 57, 4825),
            Vector3.new(5574, 53, 4861),
            Vector3.new(5548, 39, 4999),
            Vector3.new(5352, 39, 4919),
            Vector3.new(5420, 61, 4776),
        }
    },
    {
        Min = 700, Max = 724,
        Mob = "Raider",
        Quest = "Area1Quest",
        QLevel = 1,
        GiverPos = Vector3.new(-430, 73, 1834),
        MobPos = Vector3.new(-601, 39, 2211),
        SpawnPoints = {
            Vector3.new(-601, 39, 2211),
            Vector3.new(-912, 39, 2241),
            Vector3.new(-907, 39, 2503),
            Vector3.new(-614, 39, 2561),
            Vector3.new(226, 39, 2198),
            Vector3.new(546, 39, 2187),
            Vector3.new(468, 39, 2440),
            Vector3.new(266, 39, 2492),
        }
    },
    {
        Min = 725, Max = 774,
        Mob = "Mercenary",
        Quest = "Area1Quest",
        QLevel = 2,
        GiverPos = Vector3.new(-430, 73, 1834),
        MobPos = Vector3.new(-915, 73, 1576),
        SpawnPoints = {
            Vector3.new(-915, 73, 1576),
            Vector3.new(-1082, 73, 1699),
            Vector3.new(-926, 73, 1802),
            Vector3.new(-981, 73, 1088),
            Vector3.new(-1206, 73, 1079),
            Vector3.new(-1140, 73, 1244),
        }
    },
    {
        Min = 775, Max = 799,
        Mob = "Swan Pirate",
        Quest = "Area2Quest",
        QLevel = 1,
        GiverPos = Vector3.new(636, 73, 921),
        MobPos = Vector3.new(829, 73, 1331),
        SpawnPoints = {
            Vector3.new(829, 73, 1331),
            Vector3.new(976, 73, 1405),
            Vector3.new(1064, 73, 1400),
            Vector3.new(1054, 73, 1070),
            Vector3.new(965, 73, 1173),
            Vector3.new(821, 73, 1164),
        }
    },
    {
        Min = 800, Max = 874,
        Mob = "Factory Staff",
        Quest = "Area2Quest",
        QLevel = 2,
        GiverPos = Vector3.new(636, 73, 921),
        MobPos = Vector3.new(-430, 73, -372),
        SpawnPoints = {
            Vector3.new(-430, 73, -372),
            Vector3.new(-101, 73, -672),
            Vector3.new(-96, 73, -39),
            Vector3.new(376, 73, 90),
            Vector3.new(694, 73, 222),
            Vector3.new(930, 73, -69),
        }
    },
    {
        Min = 875, Max = 899,
        Mob = "Marine Lieutenant",
        Quest = "MarineQuest3",
        QLevel = 1,
        GiverPos = Vector3.new(-2439, 73, -3212),
        MobPos = Vector3.new(-2940, 73, -2599),
        SpawnPoints = {
            Vector3.new(-2940, 73, -2599),
            Vector3.new(-3020, 73, -2931),
            Vector3.new(-3255, 73, -3002),
            Vector3.new(-2765, 73, -3147),
            Vector3.new(-2588, 73, -3039),
        }
    },
    {
        Min = 900, Max = 949,
        Mob = "Marine Captain",
        Quest = "MarineQuest3",
        QLevel = 2,
        GiverPos = Vector3.new(-2439, 73, -3212),
        MobPos = Vector3.new(-1924, 73, -3119),
        SpawnPoints = {
            Vector3.new(-1924, 73, -3119),
            Vector3.new(-1615, 73, -3309),
            Vector3.new(-1807, 73, -3319),
            Vector3.new(-2029, 73, -3482),
            Vector3.new(-2131, 73, -3253),
        }
    },
    {
        Min = 950, Max = 974,
        Mob = "Zombie",
        Quest = "ZombieQuest",
        QLevel = 1,
        GiverPos = Vector3.new(-5495, 49, -796),
        MobPos = Vector3.new(-5594, 49, -530),
        SpawnPoints = {
            Vector3.new(-5594, 49, -530),
            Vector3.new(-5769, 49, -657),
            Vector3.new(-5859, 70, -743),
            Vector3.new(-5765, 49, -830),
            Vector3.new(-5614, 49, -942),
            Vector3.new(-5520, 49, -845),
        }
    },
    {
        Min = 975, Max = 999,
        Mob = "Vampire",
        Quest = "ZombieQuest",
        QLevel = 2,
        GiverPos = Vector3.new(-5495, 49, -796),
        MobPos = Vector3.new(-5777, 6, -1384),
        SpawnPoints = {
            Vector3.new(-5777, 6, -1384),
            Vector3.new(-5947, 6, -1565),
            Vector3.new(-6123, 6, -1475),
            Vector3.new(-6278, 7, -1268),
            Vector3.new(-6042, 6, -1095),
        }
    },
    {
        Min = 1000, Max = 1049,
        Mob = "Snow Trooper",
        Quest = "SnowMountainQuest",
        QLevel = 1,
        GiverPos = Vector3.new(613, 401, -5369),
        MobPos = Vector3.new(449, 401, -5065),
        SpawnPoints = {
            Vector3.new(449, 401, -5065),
            Vector3.new(402, 401, -5202),
            Vector3.new(485, 401, -5466),
            Vector3.new(637, 401, -5452),
            Vector3.new(573, 401, -5602),
            Vector3.new(716, 401, -5695),
            Vector3.new(453, 442, -5548),
        }
    },
    {
        Min = 1050, Max = 1099,
        Mob = "Winter Warrior",
        Quest = "SnowMountainQuest",
        QLevel = 2,
        GiverPos = Vector3.new(613, 401, -5369),
        MobPos = Vector3.new(1205, 429, -5395),
        SpawnPoints = {
            Vector3.new(1205, 429, -5395),
            Vector3.new(1447, 429, -5364),
            Vector3.new(1356, 429, -5200),
            Vector3.new(1224, 429, -5217),
            Vector3.new(1137, 429, -5046),
            Vector3.new(1039, 429, -5054),
        }
    },
    {
        Min = 1100, Max = 1124,
        Mob = "Lab Subordinate",
        Quest = "IceSideQuest",
        QLevel = 1,
        GiverPos = Vector3.new(-6229, 82, -4852),
        MobPos = Vector3.new(-5897, 82, -4552),
        SpawnPoints = {
            Vector3.new(-5897, 82, -4552),
            Vector3.new(-5996, 90, -4393),
            Vector3.new(-5767, 82, -4253),
            Vector3.new(-5629, 82, -4441),
            Vector3.new(-5687, 82, -4627),
        }
    },
    {
        Min = 1125, Max = 1174,
        Mob = "Horned Warrior",
        Quest = "IceSideQuest",
        QLevel = 2,
        GiverPos = Vector3.new(-6229, 82, -4852),
        MobPos = Vector3.new(-6140, 29, -6049),
        SpawnPoints = {
            Vector3.new(-6140, 29, -6049),
            Vector3.new(-6182, 29, -5910),
            Vector3.new(-6337, 29, -5776),
            Vector3.new(-6444, 29, -5847),
            Vector3.new(-6531, 29, -5717),
            Vector3.new(-6420, 29, -5589),
        }
    },
    {
        Min = 1175, Max = 1199,
        Mob = "Magma Ninja",
        Quest = "FireSideQuest",
        QLevel = 1,
        GiverPos = Vector3.new(-5403, 29, -5369),
        MobPos = Vector3.new(-5789, 29, -5388),
        SpawnPoints = {
            Vector3.new(-5789, 29, -5388),
            Vector3.new(-5882, 29, -5503),
            Vector3.new(-5811, 29, -5581),
            Vector3.new(-5665, 29, -5553),
            Vector3.new(-5715, 43, -5659),
            Vector3.new(-5849, 49, -5667),
        }
    },
    {
        Min = 1200, Max = 1249,
        Mob = "Lava Pirate",
        Quest = "FireSideQuest",
        QLevel = 2,
        GiverPos = Vector3.new(-5403, 29, -5369),
        MobPos = Vector3.new(-5229, 29, -4998),
        SpawnPoints = {
            Vector3.new(-5229, 29, -4998),
            Vector3.new(-5081, 29, -4793),
            Vector3.new(-5011, 29, -4915),
            Vector3.new(-5009, 29, -5029),
            Vector3.new(-5112, 29, -5112),
        }
    },
    {
        Min = 1250, Max = 1274,
        Mob = "Ship Deckhand",
        Quest = "ShipQuest1",
        QLevel = 1,
        GiverPos = Vector3.new(1039, 125, 32907),
        MobPos = Vector3.new(1150, 126, 32929),
        SpawnPoints = {
            Vector3.new(1150, 126, 32929),
            Vector3.new(1257, 126, 33028),
            Vector3.new(1180, 126, 33124),
            Vector3.new(1249, 126, 33216),
            Vector3.new(720, 126, 33031),
            Vector3.new(584, 126, 32927),
            Vector3.new(581, 125, 33124),
        }
    },
    {
        Min = 1275, Max = 1299,
        Mob = "Ship Engineer",
        Quest = "ShipQuest1",
        QLevel = 2,
        GiverPos = Vector3.new(1039, 125, 32907),
        MobPos = Vector3.new(1023, 40, 32741),
        SpawnPoints = {
            Vector3.new(1023, 40, 32741),
            Vector3.new(1089, 40, 32894),
            Vector3.new(1023, 41, 33071),
            Vector3.new(806, 41, 33102),
            Vector3.new(731, 41, 32952),
            Vector3.new(838, 40, 32725),
        }
    },
    {
        Min = 1300, Max = 1324,
        Mob = "Ship Steward",
        Quest = "ShipQuest2",
        QLevel = 1,
        GiverPos = Vector3.new(976, 125, 33256),
        MobPos = Vector3.new(985, 125, 33364),
        SpawnPoints = {
            Vector3.new(985, 125, 33364),
            Vector3.new(811, 125, 33374),
            Vector3.new(802, 125, 33499),
            Vector3.new(918, 125, 33508),
            Vector3.new(1038, 125, 33508),
        }
    },
    {
        Min = 1325, Max = 1349,
        Mob = "Ship Officer",
        Quest = "ShipQuest2",
        QLevel = 2,
        GiverPos = Vector3.new(976, 125, 33256),
        MobPos = Vector3.new(688, 181, 33110),
        SpawnPoints = {
            Vector3.new(688, 181, 33110),
            Vector3.new(509, 181, 33267),
            Vector3.new(657, 181, 33462),
            Vector3.new(1166, 181, 33446),
            Vector3.new(1320, 181, 33289),
            Vector3.new(1143, 181, 33111),
        }
    },
    {
        Min = 1350, Max = 1374,
        Mob = "Arctic Warrior",
        Quest = "FrostQuest",
        QLevel = 1,
        GiverPos = Vector3.new(5666, 28, -6484),
        MobPos = Vector3.new(6092, 28, -6071),
        SpawnPoints = {
            Vector3.new(6092, 28, -6071),
            Vector3.new(6268, 28, -6151),
            Vector3.new(6170, 28, -6315),
            Vector3.new(5986, 29, -6327),
            Vector3.new(5839, 28, -6241),
        }
    },
    {
        Min = 1375, Max = 1424,
        Mob = "Snow Lurker",
        Quest = "FrostQuest",
        QLevel = 2,
        GiverPos = Vector3.new(5666, 28, -6484),
        MobPos = Vector3.new(5519, 28, -6588),
        SpawnPoints = {
            Vector3.new(5519, 28, -6588),
            Vector3.new(5484, 29, -6733),
            Vector3.new(5450, 28, -7025),
            Vector3.new(5568, 28, -6904),
            Vector3.new(5767, 28, -6663),
        }
    },
    {
        Min = 1425, Max = 1449,
        Mob = "Sea Soldier",
        Quest = "ForgottenQuest",
        QLevel = 1,
        GiverPos = Vector3.new(-3054, 240, -10144),
        MobPos = Vector3.new(-2554, 27, -9838),
        SpawnPoints = {
            Vector3.new(-2554, 27, -9838),
            Vector3.new(-2848, 27, -9806),
            Vector3.new(-3297, 6, -9641),
            Vector3.new(-3487, 18, -9738),
            Vector3.new(-3449, 27, -9910),
            Vector3.new(-3244, 27, -9831),
        }
    },
    {
        Min = 1450, Max = 1499,
        Mob = "Water Fighter",
        Quest = "ForgottenQuest",
        QLevel = 2,
        GiverPos = Vector3.new(-3054, 240, -10144),
        MobPos = Vector3.new(-3341, 239, -10529),
        SpawnPoints = {
            Vector3.new(-3341, 239, -10529),
            Vector3.new(-3384, 239, -10723),
            Vector3.new(-3644, 239, -10620),
            Vector3.new(-3523, 239, -10356),
            Vector3.new(-3323, 239, -10347),
        }
    },
    {
        Min = 1500, Max = 1524,
        Mob = "Pirate Millionaire",
        Quest = "PiratePortQuest",
        QLevel = 1,
        GiverPos = Vector3.new(-449, 109, 5948),
        MobPos = Vector3.new(-603, 57, 5516),
        SpawnPoints = {
            Vector3.new(-603, 57, 5516),
            Vector3.new(-745, 57, 5637),
            Vector3.new(-544, 57, 5653),
            Vector3.new(-232, 57, 5756),
            Vector3.new(-119, 57, 5653),
            Vector3.new(-66, 57, 5804),
        }
    },
    {
        Min = 1525, Max = 1574,
        Mob = "Pistol Billionaire",
        Quest = "PiratePortQuest",
        QLevel = 2,
        GiverPos = Vector3.new(-449, 109, 5948),
        MobPos = Vector3.new(-184, 86, 6109),
        SpawnPoints = {
            Vector3.new(-184, 86, 6109),
            Vector3.new(-183, 86, 6336),
            Vector3.new(39, 86, 6113),
            Vector3.new(-60, 85, 5954),
            Vector3.new(-673, 86, 6008),
            Vector3.new(-853, 71, 6169),
            Vector3.new(-900, 86, 5889),
            Vector3.new(-736, 86, 5835),
        }
    },
    {
        Min = 1575, Max = 1599,
        Mob = "Dragon Crew Warrior",
        Quest = "DragonCrewQuest",
        QLevel = 1,
        GiverPos = Vector3.new(6737, 127, -712),
        MobPos = Vector3.new(7002, 56, -525),
        SpawnPoints = {
            Vector3.new(7002, 56, -525),
            Vector3.new(7215, 56, -689),
            Vector3.new(6925, 56, -948),
            Vector3.new(6621, 52, -986),
            Vector3.new(6708, 52, -1143),
            Vector3.new(6476, 52, -1234),
        }
    },
    {
        Min = 1600, Max = 1624,
        Mob = "Dragon Crew Archer",
        Quest = "DragonCrewQuest",
        QLevel = 2,
        GiverPos = Vector3.new(6737, 127, -712),
        MobPos = Vector3.new(6951, 486, 187),
        SpawnPoints = {
            Vector3.new(6951, 486, 187),
            Vector3.new(6815, 484, 511),
            Vector3.new(6583, 520, 510),
            Vector3.new(6667, 484, 335),
            Vector3.new(6758, 484, 105),
        }
    },
    {
        Min = 1625, Max = 1649,
        Mob = "Hydra Enforcer",
        Quest = "VenomCrewQuest",
        QLevel = 1,
        GiverPos = Vector3.new(6758, 484, 105),
        MobPos = Vector3.new(4560, 1002, 670),
        SpawnPoints = {
            Vector3.new(4560, 1002, 670),
            Vector3.new(4453, 1004, 517),
            Vector3.new(4457, 1008, 391),
            Vector3.new(4438, 1005, 184),
            Vector3.new(4548, 1002, 328),
            Vector3.new(4670, 1002, 15),
        }
    },
    {
        Min = 1650, Max = 1699,
        Mob = "Venomous Assailant",
        Quest = "VenomCrewQuest",
        QLevel = 2,
        GiverPos = Vector3.new(6758, 484, 105),
        MobPos = Vector3.new(4443, 1232, 336),
        SpawnPoints = {
            Vector3.new(4443, 1232, 336),
            Vector3.new(4448, 1218, 541),
            Vector3.new(4453, 1218, 700),
            Vector3.new(4641, 1079, 882),
            Vector3.new(4671, 1133, 996),
            Vector3.new(4884, 1090, 1105),
        }
    },
    {
        Min = 1700, Max = 1724,
        Mob = "Marine Commodore",
        Quest = "MarineTreeIsland",
        QLevel = 1,
        GiverPos = Vector3.new(2488, 74, -6790),
        MobPos = Vector3.new(2497, 81, -7354),
        SpawnPoints = {
            Vector3.new(2497, 81, -7354),
            Vector3.new(2369, 74, -7793),
            Vector3.new(2577, 74, -7740),
            Vector3.new(2678, 74, -8066),
            Vector3.new(2992, 74, -8047),
            Vector3.new(3217, 74, -7827),
        }
    },
    {
        Min = 1725, Max = 1774,
        Mob = "Marine Rear Admiral",
        Quest = "MarineTreeIsland",
        QLevel = 2,
        GiverPos = Vector3.new(2488, 74, -6790),
        MobPos = Vector3.new(3469, 124, -7179),
        SpawnPoints = {
            Vector3.new(3469, 124, -7179),
            Vector3.new(3756, 124, -7399),
            Vector3.new(3919, 146, -7175),
            Vector3.new(3972, 124, -6934),
            Vector3.new(3760, 124, -6823),
        }
    },
    {
        Min = 1775, Max = 1799,
        Mob = "Fishman Raider",
        Quest = "DeepForestIsland3",
        QLevel = 1,
        GiverPos = Vector3.new(-10579, 332, -8762),
        MobPos = Vector3.new(-10850, 332, -8426),
        SpawnPoints = {
            Vector3.new(-10850, 332, -8426),
            Vector3.new(-10602, 332, -8311),
            Vector3.new(-10392, 332, -8209),
            Vector3.new(-10125, 332, -8179),
            Vector3.new(-10225, 332, -8487),
            Vector3.new(-10525, 332, -8598),
        }
    },
    {
        Min = 1800, Max = 1824,
        Mob = "Fishman Captain",
        Quest = "DeepForestIsland3",
        QLevel = 2,
        GiverPos = Vector3.new(-10579, 332, -8762),
        MobPos = Vector3.new(-11076, 332, -8607),
        SpawnPoints = {
            Vector3.new(-11076, 332, -8607),
            Vector3.new(-11109, 332, -8840),
            Vector3.new(-11207, 332, -9075),
            Vector3.new(-11134, 332, -9241),
            Vector3.new(-10830, 332, -9048),
            Vector3.new(-10736, 332, -8807),
        }
    },
    {
        Min = 1825, Max = 1849,
        Mob = "Forest Pirate",
        Quest = "DeepForestIsland",
        QLevel = 1,
        GiverPos = Vector3.new(-13239, 332, -7632),
        MobPos = Vector3.new(-13286, 332, -7899),
        SpawnPoints = {
            Vector3.new(-13286, 332, -7899),
            Vector3.new(-13516, 332, -8006),
            Vector3.new(-13651, 332, -7895),
            Vector3.new(-13600, 332, -7741),
            Vector3.new(-13344, 332, -7632),
            Vector3.new(-13106, 332, -7704),
        }
    },
    {
        Min = 1850, Max = 1899,
        Mob = "Mythological Pirate",
        Quest = "DeepForestIsland",
        QLevel = 2,
        GiverPos = Vector3.new(-13239, 332, -7632),
        MobPos = Vector3.new(-13214, 520, -6897),
        SpawnPoints = {
            Vector3.new(-13214, 520, -6897),
            Vector3.new(-13223, 520, -6689),
            Vector3.new(-13320, 520, -6784),
            Vector3.new(-13729, 470, -6831),
            Vector3.new(-13871, 470, -7005),
            Vector3.new(-13458, 470, -7042),
        }
    },
    {
        Min = 1900, Max = 1924,
        Mob = "Jungle Pirate",
        Quest = "DeepForestIsland2",
        QLevel = 1,
        GiverPos = Vector3.new(-12681, 392, -9903),
        MobPos = Vector3.new(-12318, 332, -10669),
        SpawnPoints = {
            Vector3.new(-12318, 332, -10669),
            Vector3.new(-11909, 332, -10741),
            Vector3.new(-11709, 332, -10691),
            Vector3.new(-11618, 332, -10488),
            Vector3.new(-11903, 332, -10433),
            Vector3.new(-12147, 332, -10419),
            Vector3.new(-12311, 332, -10351),
        }
    },
    {
        Min = 1925, Max = 1974,
        Mob = "Musketeer Pirate",
        Quest = "DeepForestIsland2",
        QLevel = 2,
        GiverPos = Vector3.new(-12681, 392, -9903),
        MobPos = Vector3.new(-13070, 391, -9890),
        SpawnPoints = {
            Vector3.new(-13070, 391, -9890),
            Vector3.new(-13261, 472, -9862),
            Vector3.new(-13419, 392, -9958),
            Vector3.new(-13509, 404, -9861),
            Vector3.new(-13556, 392, -9734),
            Vector3.new(-13331, 487, -9696),
            Vector3.new(-13201, 391, -9610),
        }
    },
    {
        Min = 1975, Max = 1999,
        Mob = "Reborn Skeleton",
        Quest = "HauntedQuest1",
        QLevel = 1,
        GiverPos = Vector3.new(-9481, 142, 5566),
        MobPos = Vector3.new(-8763, 142, 6181),
        SpawnPoints = {
            Vector3.new(-8763, 142, 6181),
            Vector3.new(-8870, 141, 6031),
            Vector3.new(-8826, 141, 6164),
            Vector3.new(-8708, 141, 6112),
            Vector3.new(-8681, 141, 5971),
            Vector3.new(-8815, 141, 5876),
            Vector3.new(-8646, 141, 5851),
        }
    },
    {
        Min = 2000, Max = 2024,
        Mob = "Living Zombie",
        Quest = "HauntedQuest1",
        QLevel = 2,
        GiverPos = Vector3.new(-9481, 142, 5566),
        MobPos = Vector3.new(-10186, 154, 5745),
        SpawnPoints = {
            Vector3.new(-10186, 154, 5745),
            Vector3.new(-10208, 153, 5867),
            Vector3.new(-10293, 154, 5967),
            Vector3.new(-10169, 141, 6162),
            Vector3.new(-10054, 141, 6035),
            Vector3.new(-9956, 141, 5966),
        }
    },
    {
        Min = 2025, Max = 2049,
        Mob = "Demonic Soul",
        Quest = "HauntedQuest2",
        QLevel = 1,
        GiverPos = Vector3.new(-9518, 172, 6080),
        MobPos = Vector3.new(-9631, 172, 6053),
        SpawnPoints = {
            Vector3.new(-9631, 172, 6053),
            Vector3.new(-9751, 172, 6170),
            Vector3.new(-9562, 172, 6234),
            Vector3.new(-9346, 172, 6202),
            Vector3.new(-9256, 172, 6050),
            Vector3.new(-9424, 172, 6060),
        }
    },
    {
        Min = 2050, Max = 2074,
        Mob = "Possessed Mummy",
        Quest = "HauntedQuest2",
        QLevel = 2,
        GiverPos = Vector3.new(-9518, 172, 6080),
        MobPos = Vector3.new(-9406, 12, 6122),
        SpawnPoints = {
            Vector3.new(-9406, 12, 6122),
            Vector3.new(-9455, 6, 6338),
            Vector3.new(-9617, 6, 6358),
            Vector3.new(-9758, 28, 6368),
            Vector3.new(-9760, 28, 6052),
        }
    },
    {
        Min = 2075, Max = 2099,
        Mob = "Peanut Scout",
        Quest = "NutsIslandQuest",
        QLevel = 1,
        GiverPos = Vector3.new(-2103, 38, -10192),
        MobPos = Vector3.new(-2379, 38, -10309),
        SpawnPoints = {
            Vector3.new(-2379, 38, -10309),
            Vector3.new(-2293, 38, -10171),
            Vector3.new(-2249, 10, -9948),
            Vector3.new(-2075, 10, -9988),
            Vector3.new(-2065, 38, -10067),
            Vector3.new(-1867, 10, -10090),
            Vector3.new(-1921, 38, -10204),
        }
    },
    {
        Min = 2100, Max = 2124,
        Mob = "Peanut President",
        Quest = "NutsIslandQuest",
        QLevel = 2,
        GiverPos = Vector3.new(-2103, 38, -10192),
        MobPos = Vector3.new(-1990, 38, -10504),
        SpawnPoints = {
            Vector3.new(-1990, 38, -10504),
            Vector3.new(-1877, 38, -10596),
            Vector3.new(-1993, 38, -10681),
            Vector3.new(-2313, 88, -10604),
            Vector3.new(-2395, 88, -10454),
            Vector3.new(-2247, 88, -10440),
        }
    },
    {
        Min = 2125, Max = 2149,
        Mob = "Ice Cream Chef",
        Quest = "IceCreamIslandQuest",
        QLevel = 1,
        GiverPos = Vector3.new(-823, 66, -10963),
        MobPos = Vector3.new(-511, 66, -10877),
        SpawnPoints = {
            Vector3.new(-511, 66, -10877),
            Vector3.new(-723, 66, -10912),
            Vector3.new(-805, 66, -10800),
            Vector3.new(-937, 66, -11145),
            Vector3.new(-1110, 66, -10931),
            Vector3.new(-969, 66, -10975),
        }
    },
    {
        Min = 2150, Max = 2199,
        Mob = "Ice Cream Commander",
        Quest = "IceCreamIslandQuest",
        QLevel = 2,
        GiverPos = Vector3.new(-823, 66, -10963),
        MobPos = Vector3.new(-373, 65, -11098),
        SpawnPoints = {
            Vector3.new(-373, 65, -11098),
            Vector3.new(-653, 127, -11227),
            Vector3.new(-537, 66, -11346),
            Vector3.new(-666, 66, -11368),
            Vector3.new(-884, 72, -11484),
            Vector3.new(-762, 127, -11161),
        }
    },
    {
        Min = 2200, Max = 2224,
        Mob = "Cookie Crafter",
        Quest = "CakeQuest1",
        QLevel = 1,
        GiverPos = Vector3.new(-2024, 38, -12030),
        MobPos = Vector3.new(-2256, 38, -12131),
        SpawnPoints = {
            Vector3.new(-2256, 38, -12131),
            Vector3.new(-2332, 38, -12214),
            Vector3.new(-2431, 38, -12260),
            Vector3.new(-2496, 38, -12156),
            Vector3.new(-2458, 38, -12052),
            Vector3.new(-2329, 38, -12008),
            Vector3.new(-2209, 38, -11969),
        }
    },
    {
        Min = 2225, Max = 2249,
        Mob = "Cake Guard",
        Quest = "CakeQuest1",
        QLevel = 2,
        GiverPos = Vector3.new(-2024, 38, -12030),
        MobPos = Vector3.new(-1684, 38, -12434),
        SpawnPoints = {
            Vector3.new(-1684, 38, -12434),
            Vector3.new(-1467, 38, -12427),
            Vector3.new(-1429, 38, -12250),
            Vector3.new(-1538, 38, -12135),
            Vector3.new(-1738, 38, -12248),
        }
    },
    {
        Min = 2250, Max = 2274,
        Mob = "Baking Staff",
        Quest = "CakeQuest2",
        QLevel = 1,
        GiverPos = Vector3.new(-1934, 38, -12840),
        MobPos = Vector3.new(-1972, 38, -12985),
        SpawnPoints = {
            Vector3.new(-1972, 38, -12985),
            Vector3.new(-1847, 38, -13123),
            Vector3.new(-1723, 38, -13094),
            Vector3.new(-1762, 38, -12990),
            Vector3.new(-1776, 38, -12862),
            Vector3.new(-1822, 38, -12691),
        }
    },
    {
        Min = 2275, Max = 2299,
        Mob = "Head Baker",
        Quest = "CakeQuest2",
        QLevel = 2,
        GiverPos = Vector3.new(-1934, 38, -12840),
        MobPos = Vector3.new(-2165, 53, -13031),
        SpawnPoints = {
            Vector3.new(-2165, 53, -13031),
            Vector3.new(-2255, 54, -13025),
            Vector3.new(-2385, 53, -13013),
            Vector3.new(-2362, 53, -12799),
            Vector3.new(-2249, 53, -12712),
            Vector3.new(-2099, 53, -12722),
        }
    },
    {
        Min = 2300, Max = 2324,
        Mob = "Cocoa Warrior",
        Quest = "ChocQuest1",
        QLevel = 1,
        GiverPos = Vector3.new(235, 25, -12197),
        MobPos = Vector3.new(169, 25, -12238),
        SpawnPoints = {
            Vector3.new(169, 25, -12238),
            Vector3.new(35, 25, -12174),
            Vector3.new(14, 25, -12300),
            Vector3.new(-118, 25, -12337),
            Vector3.new(-125, 25, -12246),
        }
    },
    {
        Min = 2325, Max = 2349,
        Mob = "Chocolate Bar Battler",
        Quest = "ChocQuest1",
        QLevel = 2,
        GiverPos = Vector3.new(235, 25, -12197),
        MobPos = Vector3.new(709, 25, -12704),
        SpawnPoints = {
            Vector3.new(709, 25, -12704),
            Vector3.new(805, 25, -12780),
            Vector3.new(832, 25, -12666),
            Vector3.new(722, 25, -12551),
            Vector3.new(581, 25, -12549),
            Vector3.new(598, 25, -12396),
        }
    },
    {
        Min = 2350, Max = 2374,
        Mob = "Sweet Thief",
        Quest = "ChocQuest2",
        QLevel = 1,
        GiverPos = Vector3.new(147, 25, -12775),
        MobPos = Vector3.new(84, 25, -12663),
        SpawnPoints = {
            Vector3.new(84, 25, -12663),
            Vector3.new(-79, 25, -12764),
            Vector3.new(-137, 25, -12649),
            Vector3.new(-2, 25, -12542),
            Vector3.new(144, 25, -12532),
        }
    },
    {
        Min = 2375, Max = 2399,
        Mob = "Candy Rebel",
        Quest = "ChocQuest2",
        QLevel = 2,
        GiverPos = Vector3.new(147, 25, -12775),
        MobPos = Vector3.new(216, 25, -12918),
        SpawnPoints = {
            Vector3.new(216, 25, -12918),
            Vector3.new(171, 25, -13036),
            Vector3.new(45, 25, -13023),
            Vector3.new(-71, 25, -12940),
            Vector3.new(54, 25, -12851),
        }
    },
    {
        Min = 2400, Max = 2424,
        Mob = "Candy Pirate",
        Quest = "CandyQuest1",
        QLevel = 1,
        GiverPos = Vector3.new(-1164, 60, -14491),
        MobPos = Vector3.new(-1254, 32, -14509),
        SpawnPoints = {
            Vector3.new(-1254, 32, -14509),
            Vector3.new(-1231, 37, -14773),
            Vector3.new(-1382, 37, -14795),
            Vector3.new(-1428, 37, -14628),
            Vector3.new(-1439, 32, -14437),
            Vector3.new(-1337, 24, -14329),
        }
    },
    {
        Min = 2425, Max = 2449,
        Mob = "Snow Demon",
        Quest = "CandyQuest1",
        QLevel = 2,
        GiverPos = Vector3.new(-1162, 60, -14487),
        MobPos = Vector3.new(-820, 13, -14327),
        SpawnPoints = {
            Vector3.new(-820, 13, -14327),
            Vector3.new(-772, 13, -14435),
            Vector3.new(-794, 24, -14630),
            Vector3.new(-900, 24, -14734),
            Vector3.new(-939, 13, -14550),
        }
    },
    {
        Min = 2450, Max = 2474,
        Mob = "Isle Outlaw",
        Quest = "TikiQuest1",
        QLevel = 1,
        GiverPos = Vector3.new(-16546, 56, -179),
        MobPos = Vector3.new(-16124, 12, -248),
        SpawnPoints = {
            Vector3.new(-16124, 12, -248),
            Vector3.new(-16167, 12, -105),
            Vector3.new(-16295, 22, -188),
            Vector3.new(-16353, 22, -277),
            Vector3.new(-16435, 56, -196),
        }
    },
    {
        Min = 2475, Max = 2499,
        Mob = "Island Boy",
        Quest = "TikiQuest1",
        QLevel = 2,
        GiverPos = Vector3.new(-16546, 56, -179),
        MobPos = Vector3.new(-16985, 12, -181),
        SpawnPoints = {
            Vector3.new(-16985, 12, -181),
            Vector3.new(-16904, 12, -85),
            Vector3.new(-16878, 22, -243),
            Vector3.new(-16731, 22, -139),
            Vector3.new(-16662, 56, -252),
        }
    },
    {
        Min = 2500, Max = 2524,
        Mob = "Sun-kissed Warrior",
        Quest = "TikiQuest2",
        QLevel = 1,
        GiverPos = Vector3.new(-16539, 56, 1052),
        MobPos = Vector3.new(-16184, 22, 1092),
        SpawnPoints = {
            Vector3.new(-16184, 22, 1092),
            Vector3.new(-16062, 13, 1059),
            Vector3.new(-16159, 12, 946),
            Vector3.new(-16351, 22, 1008),
            Vector3.new(-16405, 56, 1053),
        }
    },
    {
        Min = 2525, Max = 2549,
        Mob = "Isle Champion",
        Quest = "TikiQuest2",
        QLevel = 2,
        GiverPos = Vector3.new(-16539, 56, 1052),
        MobPos = Vector3.new(-16937, 12, 1064),
        SpawnPoints = {
            Vector3.new(-16937, 12, 1064),
            Vector3.new(-16903, 12, 972),
            Vector3.new(-16788, 22, 997),
            Vector3.new(-16731, 22, 1108),
            Vector3.new(-16618, 56, 1100),
        }
    },
    {
        Min = 2550, Max = 2574,
        Mob = "Serpent Hunter",
        Quest = "TikiQuest3",
        QLevel = 1,
        GiverPos = Vector3.new(-16666, 105, 1575),
        MobPos = Vector3.new(-16599, 71, 1757),
        SpawnPoints = {
            Vector3.new(-16599, 71, 1757),
            Vector3.new(-16445, 71, 1693),
            Vector3.new(-16517, 106, 1487),
            Vector3.new(-16540, 107, 1345),
            Vector3.new(-16621, 122, 1292),
        }
    },
    {
        Min = 2575, Max = 2599,
        Mob = "Skull Slayer",
        Quest = "TikiQuest3",
        QLevel = 2,
        GiverPos = Vector3.new(-16666, 105, 1575),
        MobPos = Vector3.new(-16814, 86, 1539),
        SpawnPoints = {
            Vector3.new(-16814, 86, 1539),
            Vector3.new(-16853, 122, 1474),
            Vector3.new(-16986, 58, 1634),
            Vector3.new(-16952, 192, 1641),
            Vector3.new(-16829, 192, 1753),
            Vector3.new(-16813, 71, 1757),
        }
    },
    {
        Min = 2600, Max = 2624,
        Mob = "Reef Bandit",
        Quest = "SubmergedQuest1",
        QLevel = 1,
        GiverPos = Vector3.new(10780, -2088, 9264),
        MobPos = Vector3.new(10905, -2145, 9278),
        SpawnPoints = {
            Vector3.new(10905, -2145, 9278),
            Vector3.new(11027, -2160, 9300),
            Vector3.new(11081, -2160, 9128),
            Vector3.new(10976, -2160, 9051),
            Vector3.new(10884, -2160, 9076),
        }
    },
    {
        Min = 2625, Max = 2649,
        Mob = "Coral Pirate",
        Quest = "SubmergedQuest1",
        QLevel = 2,
        GiverPos = Vector3.new(10780, -2088, 9264),
        MobPos = Vector3.new(10735, -2088, 9412),
        SpawnPoints = {
            Vector3.new(10735, -2088, 9412),
            Vector3.new(10648, -2088, 9305),
            Vector3.new(10702, -2088, 9263),
            Vector3.new(10821, -2088, 9357),
            Vector3.new(10839, -2088, 9484),
        }
    },
    {
        Min = 2650, Max = 2674,
        Mob = "Sea Chanter",
        Quest = "SubmergedQuest2",
        QLevel = 1,
        GiverPos = Vector3.new(10881, -2086, 10033),
        MobPos = Vector3.new(10679, -2057, 9935),
        SpawnPoints = {
            Vector3.new(10679, -2057, 9935),
            Vector3.new(10578, -2072, 10027),
            Vector3.new(10468, -2088, 10109),
            Vector3.new(10627, -2088, 10186),
            Vector3.new(10786, -2088, 10105),
        }
    },
    {
        Min = 2675, Max = 2699,
        Mob = "Ocean Prophet",
        Quest = "SubmergedQuest2",
        QLevel = 2,
        GiverPos = Vector3.new(10881, -2086, 10033),
        MobPos = Vector3.new(10869, -2008, 10242),
        SpawnPoints = {
            Vector3.new(10869, -2008, 10242),
            Vector3.new(11002, -2008, 10223),
            Vector3.new(11110, -2008, 10202),
            Vector3.new(11125, -2008, 10054),
            Vector3.new(11125, -2008, 10054),
            Vector3.new(10931, -1999, 10135),
        }
    },
    {
        Min = 2700, Max = 2724,
        Mob = "High Disciple",
        Quest = "SubmergedQuest3",
        QLevel = 1,
        GiverPos = Vector3.new(9638, -1992, 9618),
        MobPos = Vector3.new(9854, -1994, 9962),
        SpawnPoints = {
            Vector3.new(9854, -1994, 9962),
            Vector3.new(9781, -1994, 9873),
            Vector3.new(9785, -1994, 9718),
            Vector3.new(9883, -1994, 9630),
            Vector3.new(9834, -1994, 9534),
        }
    },
    {
        Min = 2725, Max = 2750,
        Mob = "Grand Devotee",
        Quest = "SubmergedQuest3",
        QLevel = 2,
        GiverPos = Vector3.new(9638, -1992, 9618),
        MobPos = Vector3.new(9716, -1989, 10133),
        SpawnPoints = {
            Vector3.new(9716, -1989, 10133),
            Vector3.new(9564, -1989, 10086),
            Vector3.new(9607, -1993, 9953),
            Vector3.new(9622, -1993, 9874),
            Vector3.new(9563, -1993, 9790),
            Vector3.new(9587, -1993, 9697),
        }
    },
}

local MATERIAL_FARM_DATA = {
    ["Bones"] = { Mob = "Reborn Skeleton", Pos = Vector3.new(-8764, 142, 5963) },
    ["Dragon Scale"] = { Mob = "Dragon Crew Warrior", Pos = Vector3.new(7021, 55, -730) },
    ["Conjured Cocoa"] = { Mob = "Cocoa Warrior", Pos = Vector3.new(95, 73, -12309) },
    ["Demonic Wisp"] = { Mob = "Demonic Soul", Pos = Vector3.new(-9579, 6, 6194) },
    ["Ectoplasm"] = { Mob = "Ship Deckhand", Pos = Vector3.new(923, 125, 32885) },
    ["Fish Tail"] = { Mob = "Fishman Warrior", Pos = Vector3.new(61163, 19, 1569) },
    ["Magma Ore"] = { Mob = "Military Soldier", Pos = Vector3.new(-5231, 12, 8503) },
    ["Vampire Fang"] = { Mob = "Vampire", Pos = Vector3.new(-5491, 48, -794) },
    ["Mini Tusk"] = { Mob = "Mythological Pirate", Pos = Vector3.new(-13446, 413, -7760) },
    ["Scrap Metal"] = { Mob = "Pirate Millionaire", Pos = Vector3.new(-712, 98, 5711) },
    ["Leather"] = { Mob = "Monkey", Pos = Vector3.new(-1497, 23, 37) },
    ["Angel Wings"] = { Mob = "God's Guard", Pos = Vector3.new(-7859, 5545, -380) },
}

local BOSS_DATABASE = {
    -- Sea 1
    ["The Gorilla King"] = { Mob = "The Gorilla King", Quest = "JungleQuest", QLevel = 3, Pos = Vector3.new(-1240, 7, -500), Sea = 1 },
    ["Bobby"] = { Mob = "Bobby", Quest = "BuggyQuest1", QLevel = 3, Pos = Vector3.new(-1142, 15, 4134), Sea = 1 },
    ["The Saw"] = { Mob = "The Saw", Quest = "", QLevel = 1, Pos = Vector3.new(-680, 15, 4300), Sea = 1 },
    ["Yeti"] = { Mob = "Yeti", Quest = "SnowQuest", QLevel = 3, Pos = Vector3.new(1185, 106, -1519), Sea = 1 },
    ["Mob Leader"] = { Mob = "Mob Leader", Quest = "", QLevel = 1, Pos = Vector3.new(-2850, 7, 5300), Sea = 1 },
    ["Vice Admiral"] = { Mob = "Vice Admiral", Quest = "MarineQuest2", QLevel = 2, Pos = Vector3.new(-4843, 22, 4360), Sea = 1 },
    ["Saber Expert"] = { Mob = "Saber Expert", Quest = "", QLevel = 1, Pos = Vector3.new(-1497, 23, 37), Sea = 1 },
    ["Warden"] = { Mob = "Warden", Quest = "PrisonerQuest", QLevel = 3, Pos = Vector3.new(5130, 4, 480), Sea = 1 },
    ["Chief Warden"] = { Mob = "Chief Warden", Quest = "PrisonerQuest", QLevel = 4, Pos = Vector3.new(5130, 4, 480), Sea = 1 },
    ["Swan"] = { Mob = "Swan", Quest = "PrisonerQuest", QLevel = 5, Pos = Vector3.new(5130, 4, 480), Sea = 1 },
    ["Magma Admiral"] = { Mob = "Magma Admiral", Quest = "MagmaQuest", QLevel = 3, Pos = Vector3.new(-5800, 77, 8800), Sea = 1 },
    ["Fishman Lord"] = { Mob = "Fishman Lord", Quest = "FishmanQuest", QLevel = 3, Pos = Vector3.new(61900, 19, 1500), Sea = 1 },
    ["Wysper"] = { Mob = "Wysper", Quest = "SkyExp1Quest", QLevel = 3, Pos = Vector3.new(-7859, 5545, -380), Sea = 1 },
    ["Thunder God"] = { Mob = "Thunder God", Quest = "SkyExp2Quest", QLevel = 3, Pos = Vector3.new(-7752, 5607, -1490), Sea = 1 },
    ["Cyborg"] = { Mob = "Cyborg", Quest = "FountainQuest", QLevel = 3, Pos = Vector3.new(5259, 39, 4050), Sea = 1 },
    ["Greybeard"] = { Mob = "Greybeard", Quest = "", QLevel = 1, Pos = Vector3.new(-5035, 29, 4325), Sea = 1 },

    -- Sea 2
    ["Diamond"] = { Mob = "Diamond", Quest = "Area1Quest", QLevel = 3, Pos = Vector3.new(-1580, 198, -120), Sea = 2 },
    ["Jeremy"] = { Mob = "Jeremy", Quest = "Area2Quest", QLevel = 3, Pos = Vector3.new(2314, 448, 786), Sea = 2 },
    ["Fajita"] = { Mob = "Fajita", Quest = "FajitaQuest", QLevel = 1, Pos = Vector3.new(-2440, 73, -3217), Sea = 2 },
    ["Don Swan"] = { Mob = "Don Swan", Quest = "SwanBossQuest", QLevel = 1, Pos = Vector3.new(2284, 15, 804), Sea = 2 },
    ["Smoke Admiral"] = { Mob = "Smoke Admiral", Quest = "IceAdmiralQuest", QLevel = 1, Pos = Vector3.new(-5086, 16, -5389), Sea = 2 },
    ["Awakened Ice Admiral"] = { Mob = "Awakened Ice Admiral", Quest = "CastleBossQuest", QLevel = 1, Pos = Vector3.new(6040, 29, -6226), Sea = 2 },
    ["Tide Keeper"] = { Mob = "Tide Keeper", Quest = "ForgottenBossQuest", QLevel = 1, Pos = Vector3.new(-3800, 77, -11000), Sea = 2 },
    ["Darkbeard"] = { Mob = "Darkbeard", Quest = "", QLevel = 1, Pos = Vector3.new(3700, 16, -3500), Sea = 2 },
    ["Cursed Captain"] = { Mob = "Cursed Captain", Quest = "", QLevel = 1, Pos = Vector3.new(923, 125, 32885), Sea = 2 },
    ["Order"] = { Mob = "Order", Quest = "", QLevel = 1, Pos = Vector3.new(-5800, 16, -5000), Sea = 2 },

    -- Sea 3
    ["Stone"] = { Mob = "Stone", Quest = "PiratePortQuest", QLevel = 3, Pos = Vector3.new(-1050, 40, 6790), Sea = 3 },
    ["Hydra Leader"] = { Mob = "Hydra Leader", Quest = "HydraQuest", QLevel = 3, Pos = Vector3.new(5749, 610, -267), Sea = 3 },
    ["Kilo Admiral"] = { Mob = "Kilo Admiral", Quest = "AmazonQuest", QLevel = 3, Pos = Vector3.new(2800, 1030, -7000), Sea = 3 },
    ["Captain Elephant"] = { Mob = "Captain Elephant", Quest = "ElephantQuest", QLevel = 1, Pos = Vector3.new(-13390, 318, -8400), Sea = 3 },
    ["Beautiful Pirate"] = { Mob = "Beautiful Pirate", Quest = "BeautifulPirateQuest", QLevel = 1, Pos = Vector3.new(5250, 20, 100), Sea = 3 },
    ["Cake Queen"] = { Mob = "Cake Queen", Quest = "CakeQueenQuest", QLevel = 1, Pos = Vector3.new(-710, 381, -11150), Sea = 3 },
    ["Longma"] = { Mob = "Longma", Quest = "", QLevel = 1, Pos = Vector3.new(-10220, 332, -9450), Sea = 3 },
    ["Soul Reaper"] = { Mob = "Soul Reaper", Quest = "", QLevel = 1, Pos = Vector3.new(-9515, 142, 5535), Sea = 3 },
    ["Rip Indra"] = { Mob = "rip_indra True Form", Quest = "", QLevel = 1, Pos = Vector3.new(-5330, 424, -2640), Sea = 3 },
    ["Cake Prince"] = { Mob = "Cake Prince", Quest = "", QLevel = 1, Pos = Vector3.new(-2021, 38, -12028), Sea = 3 },
    ["Dough King"] = { Mob = "Dough King", Quest = "", QLevel = 1, Pos = Vector3.new(-2021, 38, -12028), Sea = 3 },
}

CTX.MATERIAL_FARM_DATA = MATERIAL_FARM_DATA
CTX.BOSS_DATABASE = BOSS_DATABASE

--[[ Get quest for player's current level ]]

function Utility.GetQuestForLevel(lvl)
    local curLevel = lvl or (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
    local bestQuest = LEVEL_QUEST_DATA[1]
    for _, q in ipairs(LEVEL_QUEST_DATA) do
        if curLevel >= q.Min and curLevel <= q.Max then
            return q
        elseif curLevel >= q.Min then
            bestQuest = q
        end
    end
    return bestQuest
end

local patrolState = {
    index = 1,
    lastTime = 0,
    currentMob = "",
}

--[[ Get patrol position to trigger mob spawn if spawn point list exists ]]
function Utility.GetSpawnPatrolPos(qData)
    if not qData then return Vector3.zero end
    local spList = qData.SpawnPoints
    if spList and #spList > 0 then
        local now = os.clock()
        if patrolState.currentMob ~= qData.Mob then
            patrolState.currentMob = qData.Mob
            patrolState.index = 1
            patrolState.lastTime = now
        elseif now - patrolState.lastTime > 20.0 then
            patrolState.lastTime = now
            patrolState.index = (patrolState.index % #spList) + 1
        end
        return spList[patrolState.index]
    end
    return qData.MobPos
end

--[[ Helper to look up full quest data by mob name from LEVEL_QUEST_DATA and BOSS_DATABASE ]]
function Utility.GetQuestDataForMob(targetMob)
    if not targetMob or targetMob == "" then return nil end
    local cleanTarget = Utility.NormalizeMobString(targetMob)

    for _, spot in ipairs(LEVEL_QUEST_DATA) do
        if Utility.NormalizeMobString(spot.Mob) == cleanTarget then
            return spot
        end
    end

    if BOSS_DATABASE then
        for bName, bData in pairs(BOSS_DATABASE) do
            if Utility.NormalizeMobString(bData.Mob or bName) == cleanTarget then
                return {
                    Mob = bData.Mob or bName,
                    Quest = bData.Quest or "",
                    QLevel = bData.QLevel or 1,
                    GiverPos = bData.Pos,
                    MobPos = bData.Pos,
                    SpawnPoints = { bData.Pos }
                }
            end
        end
    end

    return nil
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     SERVER REMOTE-DRIVEN QUEST SYSTEM (CommF_ InvokeServer & QuestUpdate Event)
     - Nhận quest: CommF_:InvokeServer("StartQuest", Quest, Level) -> Result[1] == 0 (ExpectedResult = 0)
     - Hoàn thành: ReplicatedStorage.Remotes.QuestUpdate.OnClientEvent -> Context == "Complete"
     - Hoàn toàn loại bỏ quét UI text để tránh độ trễ mạng và sai lệch tên hiển thị
   ═══════════════════════════════════════════════════════════════════════════ ]]

local _activeQuestState = (CTX and CTX._activeQuestState) or {
    Active = false,
    Quest = "",
    Level = 1,
    Mob = "",
    StartTime = 0,
}
if CTX then CTX._activeQuestState = _activeQuestState end

local _questUpdateHooked = (CTX and CTX._questUpdateHooked) or false
if CTX then CTX._questUpdateHooked = _questUpdateHooked end

-- Hook sự kiện QuestUpdate từ Server để bắt thời điểm hoàn thành/hủy quest chính xác 100%
local function _initQuestUpdateListener()
    if _questUpdateHooked then return end
    _questUpdateHooked = true
    if CTX then CTX._questUpdateHooked = true end

    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local remotes = rep:WaitForChild("Remotes", 10)
        local questUpdate = remotes and remotes:WaitForChild("QuestUpdate", 10)
        if questUpdate and questUpdate:IsA("RemoteEvent") then
            questUpdate.OnClientEvent:Connect(function(arg1, arg2)
                -- Hỗ trợ cả 2 dạng tham số (nil, { ... }) hoặc ({ ... })
                local data = (type(arg2) == "table" and arg2) or (type(arg1) == "table" and arg1)
                if data and type(data) == "table" then
                    local ctx = data.Context or ""
                    if ctx == "Complete" or ctx == "Abandon" or ctx == "Fail" then
                        _activeQuestState.Active = false
                        _activeQuestState.Quest = ""
                        _activeQuestState.Mob = ""
                        _activeQuestState.Level = 1
                    elseif ctx == "Start" or ctx == "Active" then
                        _activeQuestState.Active = true
                        if data.InternalQuestName then _activeQuestState.Quest = data.InternalQuestName end
                        if data.Name then _activeQuestState.Mob = data.Name end
                    end
                end
            end)
        end
    end)
end
pcall(_initQuestUpdateListener)

--[[ ═══════════════════════════════════════════════════════════════════════════
     PLURAL TO SINGULAR ENGLISH NORMALIZATION SYSTEM FOR BLOX FRUITS
     - Chuẩn hóa tên quái số nhiều (Quest Title: "Bandits", "Reef Bandits", "Snowmen", "Sweet Thieves")
       về dạng số ít đồng nhất với Database LEVEL_QUEST_DATA ("Bandit", "Reef Bandit", "Snowman", "Sweet Thief").
    ═══════════════════════════════════════════════════════════════════════════ ]]
local function _pluralToSingularWord(w)
    if not w or #w <= 2 then return w end
    local low = w:lower()

    -- 1. Bất quy tắc hoặc danh từ tập hợp/không đếm được
    if low == "men" then return "man" end
    if low:sub(-3) == "men" and #low > 3 then
        return low:sub(1, -4) .. "man"
    end
    if low == "staff" or low == "crew" or low == "fish" or low == "corps" or low == "police" then
        return low
    end

    -- 2. Đuôi -thieves, -wolves, -ves -> -thief, -wolf, -f
    if low == "thieves" then
        return "thief"
    elseif low:sub(-7) == "thieves" and #low > 7 then
        return low:sub(1, -8) .. "thief"
    elseif low == "wolves" then
        return "wolf"
    elseif low:sub(-6) == "wolves" and #low > 6 then
        return low:sub(1, -7) .. "wolf"
    elseif low:sub(-3) == "ves" and #low > 4 then
        return low:sub(1, -4) .. "f"
    end

    -- 3. Đuôi -zombies, -cookies -> -zombie, -cookie
    if low:sub(-7) == "zombies" or low:sub(-7) == "cookies" then
        return low:sub(1, -2)
    end

    -- 4. Nguyên âm + ys (vd: monkeys, boys, days) -> chỉ bỏ 's'
    if low:find("[aeiou]ys$") then
        return low:sub(1, -2)
    end

    -- 5. Phụ âm + ies (vd: mummies, candies) -> đổi sang 'y'
    if low:sub(-3) == "ies" and #low > 3 then
        return low:sub(1, -4) .. "y"
    end

    -- 6. Đuôi -sses (vd: bosses) -> -ss
    if low:sub(-4) == "sses" then
        return low:sub(1, -3)
    end

    -- 7. Đuôi -ches, -shes, -xes, -zes (vd: witches, boxes) -> bỏ -es
    if low:find("[cs]hes$") or low:find("[xz]es$") then
        return low:sub(1, -3)
    end

    -- 8. Đuôi -oes (vd: heroes) -> bỏ -es
    if low:sub(-3) == "oes" and #low > 3 then
        return low:sub(1, -3)
    end

    -- 9. Đuôi -s thông thường (không phải -ss, -us, -is, dài > 3)
    if low:sub(-1) == "s" and low:sub(-2) ~= "ss" and low:sub(-2) ~= "us" and low:sub(-2) ~= "is" and #low > 3 then
        return low:sub(1, -2)
    end

    return low
end

local _mobNameNormalizeCache = {}

--[[ Normalize mob / quest string with plural->singular normalization & high-performance memoization ]]
function Utility.NormalizeMobString(str)
    if not str or str == "" then return "" end
    local cached = _mobNameNormalizeCache[str]
    if cached then return cached end

    local s = str:lower()
    s = s:gsub("<.->", "") -- strip RichText
    s = s:gsub("%s*%[.-%]", "") -- strip [Lv. 100]
    s = s:gsub("%s*%(.-%)", "") -- strip (0/8) or progress
    s = s:gsub("^[Dd]efeat%s+%d*%s*", "")
    s = s:gsub("^[Kk]ill%s+%d*%s*", "")
    s = s:gsub("['’]s", "")
    s = s:gsub("['’]", "")
    s = s:gsub("%s*%d+$", "") -- strip trailing spawn index numbers like Pirate1 or Pirate 2
    s = s:gsub("^%s+", ""):gsub("%s+$", "")

    -- Blox Fruits In-game Typo Fixes
    s = s:gsub("posessed", "possessed")
    s = s:gsub("mummys", "mummy")

    -- Chuẩn hóa từ cuối cùng từ số nhiều về số ít theo tiếng Anh
    local prefix, lastWord = s:match("^(.-)%s*([%a]+)$")
    if lastWord and #lastWord > 0 then
        local singular = _pluralToSingularWord(lastWord)
        if prefix and prefix ~= "" then
            s = prefix .. " " .. singular
        else
            s = singular
        end
    end

    s = s:gsub("[-_]", " ")
    s = s:gsub("%s+", " ")
    local result = s:gsub("^%s+", ""):gsub("%s+$", "")
    _mobNameNormalizeCache[str] = result
    return result
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     GUI QUEST SCANNER (Ưu tiên: Players.LocalPlayer.PlayerGui.TrackedQuestFrame.Frame.header)
     - Quét chính xác vị trí hiển thị quest: TrackedQuestFrame.Frame.header
     - Fallback: Main.Quest.Container.QuestTitle
     - Bóc tách tiến độ: CurrentKills / TotalKills từ chuỗi "(X/Y)" hoặc "X/Y"
     - Chuẩn hóa tên quái số nhiều về số ít qua NormalizeMobString
    ═══════════════════════════════════════════════════════════════════════════ ]]
local _questGuiCache = { data = nil, lastCheck = 0 }

local function _extractQuestDataFromObject(textObj, parentContainer)
    if not textObj then return nil end
    local rawText = ""
    if textObj:IsA("TextLabel") or textObj:IsA("TextBox") then
        rawText = textObj.Text or ""
    else
        pcall(function()
            if textObj.Text then rawText = tostring(textObj.Text) end
        end)
        if rawText == "" then
            local tl = textObj:FindFirstChildOfClass("TextLabel")
            if tl and tl.Text ~= "" then
                rawText = tl.Text
            end
        end
    end

    local plainText = rawText:gsub("<.->", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if plainText == "" then
        return nil
    end

    -- Trích xuất tiến độ (CurrentKills / TotalKills)
    local curKills, totalKills = plainText:match("%((%d+)/(%d+)%)")
    if not curKills then
        curKills, totalKills = plainText:match("(%d+)%s*/%s*(%d+)")
    end

    -- Nếu không có trên chính nhãn này, quét tìm trong container cha (ví dụ Frame hoặc Container)
    if not curKills and parentContainer then
        for _, child in ipairs(parentContainer:GetDescendants()) do
            if child:IsA("TextLabel") and child.Visible and child.Text ~= "" then
                local t = child.Text:gsub("<.->", "")
                local c, tot = t:match("%((%d+)/(%d+)%)")
                if not c then
                    c, tot = t:match("(%d+)%s*/%s*(%d+)")
                end
                if c and tot then
                    curKills, totalKills = c, tot
                    break
                end
            end
        end
    end

    local curKillsNum = tonumber(curKills) or 0
    local totalKillsNum = tonumber(totalKills) or 0
    local isComplete = (totalKillsNum > 0 and curKillsNum >= totalKillsNum)

    -- Chuẩn hóa tên quái từ chuỗi (tự động chuyển số nhiều sang số ít: Reef Bandits -> reef bandit)
    local normMob = Utility.NormalizeMobString(plainText)
    if normMob == "" then
        return nil
    end

    return {
        RawText = rawText,
        PlainText = plainText,
        NormalizedMob = normMob,
        CurrentKills = curKillsNum,
        TotalKills = totalKillsNum,
        IsComplete = isComplete,
    }
end

function Utility.GetActiveQuestGuiData(forceRefresh)
    local now = os.clock()
    if not forceRefresh and (now - _questGuiCache.lastCheck) < 0.25 then
        return _questGuiCache.data
    end
    _questGuiCache.lastCheck = now

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        _questGuiCache.data = nil
        return nil
    end

    -- [1. ƯU TIÊN CHÍNH XÁC]: game.Players.LocalPlayer.PlayerGui.TrackedQuestFrame.Frame.header
    local trackedGui = pg:FindFirstChild("TrackedQuestFrame")
    if trackedGui and trackedGui:IsA("ScreenGui") and trackedGui.Enabled ~= false then
        local frame = trackedGui:FindFirstChild("Frame")
        if frame and frame:IsA("GuiObject") and frame.Visible then
            local header = frame:FindFirstChild("header") or frame:FindFirstChild("Header")
            if header then
                local data = _extractQuestDataFromObject(header, frame)
                if data then
                    _questGuiCache.data = data
                    return data
                end
            end

            -- Nếu header là Frame hoặc tên khác, tìm TextLabel con đầu tiên có text
            for _, child in ipairs(frame:GetChildren()) do
                if child:IsA("TextLabel") and child.Visible and child.Text ~= "" then
                    local data = _extractQuestDataFromObject(child, frame)
                    if data then
                        _questGuiCache.data = data
                        return data
                    end
                end
            end
        end
    end

    -- [2. FALLBACK]: game.Players.LocalPlayer.PlayerGui.Main.Quest.Container.QuestTitle
    local mainGui = pg:FindFirstChild("Main")
    local questGui = mainGui and mainGui:FindFirstChild("Quest")
    if questGui and questGui.Visible then
        local container = questGui:FindFirstChild("Container")
        if container and container:IsA("GuiObject") and container.Visible then
            local titleObj = container:FindFirstChild("QuestTitle") or container:FindFirstChild("Title")
            if titleObj then
                local data = _extractQuestDataFromObject(titleObj, container)
                if data then
                    _questGuiCache.data = data
                    return data
                end
            end
        end
    end

    _questGuiCache.data = nil
    return nil
end

--[[ Check if player already has an active quest ]]
function Utility.HasActiveQuest()
    local guiData = Utility.GetActiveQuestGuiData()
    if guiData and not guiData.IsComplete then
        return true
    end
    return (_activeQuestState.Active == true)
end

--[[ Get text description of currently active quest ]]
function Utility.GetActiveQuestText()
    local guiData = Utility.GetActiveQuestGuiData()
    if guiData then
        return guiData.PlainText
    end
    return ""
end

--[[ Check if active quest matches target mob (Độ chính xác tuyệt đối nhờ chuẩn hóa số ít) ]]
function Utility.IsQuestMatchingMob(targetMob)
    if not targetMob or targetMob == "" then return false end

    -- 1. Ưu tiên quét trực tiếp GUI người chơi (thời gian thực, chuẩn xác 100%)
    local guiData = Utility.GetActiveQuestGuiData()
    if guiData and not guiData.IsComplete then
        local normTarget = Utility.NormalizeMobString(targetMob)
        if guiData.NormalizedMob == normTarget then
            return true
        end
        if Utility.IsMobNameMatch(guiData.NormalizedMob, targetMob) then
            return true
        end

        local qData = Utility.GetQuestDataForMob(targetMob)
        if qData and qData.Quest and qData.Quest ~= "" then
            local normQName = Utility.NormalizeMobString(qData.Quest)
            if guiData.NormalizedMob == normQName then
                return true
            end
        end
        return false
    end

    -- 2. Fallback kiểm tra qua state Server Remote nếu GUI chưa kịp render
    if _activeQuestState.Active and _activeQuestState.Quest ~= "" then
        local qData = Utility.GetQuestDataForMob(targetMob)
        if qData then
            local qMatch = (_activeQuestState.Quest == qData.Quest) and (_activeQuestState.Level == (qData.QLevel or 1))
            local mobMatch = (_activeQuestState.Mob == targetMob) or Utility.IsMobNameMatch(_activeQuestState.Mob, targetMob)
            return (qMatch or mobMatch)
        end
    end

    return false
end

--[[ Call CommF_ to abandon quest if mismatched ]]
function Utility.AbandonQuest()
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if commF and commF:IsA("RemoteFunction") then
        pcall(function()
            commF:InvokeServer("AbandonQuest")
        end)
    end
    _activeQuestState.Active = false
    _activeQuestState.Quest = ""
    _activeQuestState.Mob = ""
    _activeQuestState.Level = 1
    _questGuiCache.data = nil
    _questGuiCache.lastCheck = 0
end

--[[ Call CommF_ to start quest - Chuẩn ExpectedResult = 0 ]]
function Utility.StartQuest(qName, qLevel)
    if not qName or qName == "" then return false end
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if not commF or not commF:IsA("RemoteFunction") then return false end

    local success, result = pcall(function()
        return table.pack(commF:InvokeServer("StartQuest", qName, qLevel or 1))
    end)

    -- ExpectedResult = 0: Server xác nhận đủ điều kiện và chấp thuận nhận nhiệm vụ
    if success and type(result) == "table" and result[1] == 0 then
        _activeQuestState.Active = true
        _activeQuestState.Quest = qName
        _activeQuestState.Level = qLevel or 1
        _activeQuestState.StartTime = os.clock()
        return true, 0
    end

    return false, (success and result and result[1]) or nil
end

local _giverStuckTracker = {}
local _lastAbandonTime = 0

--[[ Ensure player has the correct matching quest before attacking:
     - Quét GUI: Nếu đang có quest -> Xem đã đánh bao nhiêu con (CurrentKills / TotalKills).
     - Nếu đúng quest + đúng quái -> Tiến hành đánh tiếp.
     - Nếu không đúng quest / quái -> Hủy quest (AbandonQuest) và nhận lại quest đúng level! ]]
function Utility.EnsureQuestForMob(targetMob)
    local qData = Utility.GetQuestDataForMob(targetMob)
    if not qData or not qData.Quest or qData.Quest == "" then return true end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local now = os.clock()
    local guiData = Utility.GetActiveQuestGuiData()

    -- 1. Nếu GUI đang có quest hiển thị (và chưa đánh xong)
    if guiData and not guiData.IsComplete then
        local isMatch = Utility.IsQuestMatchingMob(targetMob)

        if isMatch then
            -- Đúng quest + đúng quái: Cập nhật tiến độ và cho phép đánh tiếp
            _activeQuestState.Active = true
            _activeQuestState.Mob = targetMob
            _activeQuestState.CurrentKills = guiData.CurrentKills
            _activeQuestState.TotalKills = guiData.TotalKills
            _giverStuckTracker[targetMob] = nil
            return true
        else
            -- Có quest nhưng KHÔNG ĐÚNG quái/quest cần farm:
            -- Hủy quest ngay để quay về làm quest đúng với level hiện tại (Cooldown 4s tránh spam remote)
            if (now - _lastAbandonTime > 4.0) then
                _lastAbandonTime = now
                Utility.AbandonQuest()
                task.wait(0.3)
            end
            return false
        end
    end

    -- 2. Nếu không có quest trên GUI (hoặc đã hoàn thành): Bay đến NPC nhận quest chuẩn
    local transitioning = Utility.CheckAndHandleAreaTransitions(qData.GiverPos)
    if transitioning then
        return false
    end

    local giverDist = (root.Position - qData.GiverPos).Magnitude
    if giverDist > 35 then
        _giverStuckTracker[targetMob] = nil
        Utility.PhysicsFlyTo(qData.GiverPos + Vector3.new(0, 5, 0), S.TeleportFlySpeed or 200)
        return false
    else
        -- Đã tới gần NPC: Gửi remote StartQuest lên server và kiểm tra ExpectedResult = 0
        local isSuccess, resCode = Utility.StartQuest(qData.Quest, qData.QLevel or 1)

        if isSuccess then
            -- Server trả về 0 -> Đủ điều kiện và đã nhận quest thành công!
            _activeQuestState.Active = true
            _activeQuestState.Quest = qData.Quest
            _activeQuestState.Level = qData.QLevel or 1
            _activeQuestState.Mob = targetMob
            _activeQuestState.StartTime = now
            _giverStuckTracker[targetMob] = nil
            task.wait(0.2)
            Utility.GetActiveQuestGuiData(true)
            return true
        else
            -- Nếu đứng sát NPC gọi StartQuest mà không thành công (vd còn sót quest cũ bị kẹt trên server):
            -- Chỉ gọi AbandonQuest sau 4s cooldown để xóa quest kẹt rồi thử lại
            if (now - _lastAbandonTime > 4.0) then
                _lastAbandonTime = now
                Utility.AbandonQuest()
                task.wait(0.3)
            else
                task.wait(0.3)
            end
            return false
        end
    end
end

function Utility.IsMobNameMatch(enemyName, targetMobName)
    if not targetMobName or targetMobName == "" then return true end
    if not enemyName or enemyName == "" then return false end

    local normEnemy = Utility.NormalizeMobString(enemyName)
    local normTarget = Utility.NormalizeMobString(targetMobName)

    return (normEnemy == normTarget)
end

--[[ Find enemy by mob name ]]
function Utility.GetEnemyByName(mobName)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = root and root.Position or Vector3.zero
    local isPlayerUnder = (myPos.Y < -1000)

    local nearest = nil
    local shortestDist = math.huge

    for _, enemy in ipairs(enemies:GetChildren()) do
        if enemy:IsA("Model") and Utility.IsMobNameMatch(enemy.Name, mobName) then
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local eRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")
            if hum and hum.Health > 0 and eRoot then
                local isEnemyUnder = (eRoot.Position.Y < -1000)
                if isPlayerUnder == isEnemyUnder then
                    local dist = (eRoot.Position - myPos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        nearest = enemy
                    end
                end
            end
        end
    end
    return nearest
end

local _ignoredDesyncedMobs = (CTX and CTX._ignoredDesyncedMobs) or setmetatable({}, { __mode = "k" })
local _mobDamageTracker = (CTX and CTX._mobDamageTracker) or { model = nil, lastHealth = 0, lastDamageTime = 0, startTime = 0 }
local _lockedMobCluster = (CTX and CTX._lockedMobCluster) or { mob = "", center = nil, lockTime = 0 }
if CTX then
    CTX._ignoredDesyncedMobs = _ignoredDesyncedMobs
    CTX._mobDamageTracker = _mobDamageTracker
    CTX._lockedMobCluster = _lockedMobCluster
end

--[[ Clean up any physics movers and restore enemy humanoid state ]]
function Utility.CleanEnemyMoverAttributes(root, model, hum)
    if root then
        for _, name in ipairs({"HiliBringBP", "HiliBringBG", "HiliBringBV"}) do
            local m = root:FindFirstChild(name)
            if m then pcall(function() m:Destroy() end) end
        end
    end
    if model then
        pcall(function()
            for _, child in ipairs(model:GetDescendants()) do
                if child:IsA("BasePart") then
                    for _, name in ipairs({"HiliBringBP", "HiliBringBG", "HiliBringBV"}) do
                        local m = child:FindFirstChild(name)
                        if m then pcall(function() m:Destroy() end) end
                    end
                end
            end
        end)
    end
    if hum and hum.Parent and hum.Health > 0 then
        pcall(function()
            hum.PlatformStand = false
            hum.AutoRotate = true
        end)
    end
end

local _activatedMobs = (CTX and CTX._activatedMobs) or setmetatable({}, { __mode = "k" })
if CTX then CTX._activatedMobs = _activatedMobs end

--[[ Clean up all physics movers applied to enemy models in workspace.Enemies and clear bring tracking ]]
function Utility.CleanupBringMobMovers()
    DisconnectConnection("bringMobStepped")
    if currentBringData and currentBringData.Mobs then
        for _, item in ipairs(currentBringData.Mobs) do
            if type(item) == "table" then
                if item._diedConn then pcall(function() item._diedConn:Disconnect() end) item._diedConn = nil end
                if item._ancestryConn then pcall(function() item._ancestryConn:Disconnect() end) item._ancestryConn = nil end
                Utility.CleanEnemyMoverAttributes(item.Root, item.Model, item.Hum)
                item.Model = nil
                item.Root = nil
                item.Hum = nil
                item.Parts = nil
            end
        end
        currentBringData.Mobs = {}
    end
    currentBringData = nil
    if CTX then CTX.currentBringData = nil end

    _lockedMobCluster.mob = ""
    _lockedMobCluster.center = nil
    _lockedMobCluster.lockTime = 0
    if CTX then CTX._lockedMobCluster = _lockedMobCluster end

    table.clear(_activatedMobs)

    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            Utility.CleanEnemyMoverAttributes(root, enemy, hum)
        end
    end
    collectgarbage("step", 50)
end

function Utility.UpdateBringMobSteppedState()
    local isAllowed = (S.BringMobEnabled or (currentBringData and currentBringData.Force))
    if not isAllowed or not currentBringData or not currentBringData.Mobs or #currentBringData.Mobs == 0 then
        DisconnectConnection("bringMobStepped")
        Utility.CleanupBringMobMovers()
        return
    end

    if _conns["bringMobStepped"] then return end

    _conns["bringMobStepped"] = RunService.Stepped:Connect(function(_, dt)
        local isAllowed = (S.BringMobEnabled or (currentBringData and currentBringData.Force))
        if not isAllowed or not currentBringData or not currentBringData.Mobs or #currentBringData.Mobs == 0 then
            DisconnectConnection("bringMobStepped")
            Utility.CleanupBringMobMovers()
            return
        end
        local center = currentBringData.Center
        if not center then return end

        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        local myPos = myRoot and myRoot.Position or Vector3.zero

        -- Giữ simulation radius vô hạn mỗi frame
        pcall(function()
            if sethiddenproperty and LocalPlayer then
                sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                sethiddenproperty(LocalPlayer, "MaximumSimulationRadius", math.huge)
            end
            if setsimulationradius then
                setsimulationradius(math.huge, math.huge)
            end
        end)

        local speed = S.BringMobSpeed or 450
        if speed > 800 then speed = 800 end

        for i = #currentBringData.Mobs, 1, -1 do
            local item = currentBringData.Mobs[i]
            local model = (typeof(item) == "Instance" and item) or (type(item) == "table" and item.Model)

            if model and model.Parent then
                local hum = (type(item) == "table" and item.Hum) or model:FindFirstChildOfClass("Humanoid")
                local root = (type(item) == "table" and item.Root) or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildOfClass("BasePart")

                if root and root.Parent and hum and hum.Health > 0 then
                    -- Quái còn sống: Gắn hook dọn dẹp khi chết hoặc despawn
                    if type(item) == "table" and not item._hooked then
                        item._hooked = true
                        item._diedConn = hum.Died:Connect(function()
                            Utility.CleanEnemyMoverAttributes(root, model, hum)
                            if item._diedConn then pcall(function() item._diedConn:Disconnect() end) item._diedConn = nil end
                            if item._ancestryConn then pcall(function() item._ancestryConn:Disconnect() end) item._ancestryConn = nil end
                        end)
                        item._ancestryConn = model.AncestryChanged:Connect(function(_, parent)
                            if not parent then
                                Utility.CleanEnemyMoverAttributes(root, model, hum)
                                if item._diedConn then pcall(function() item._diedConn:Disconnect() end) item._diedConn = nil end
                                if item._ancestryConn then pcall(function() item._ancestryConn:Disconnect() end) item._ancestryConn = nil end
                            end
                        end)
                    end

                    -- Kiểm tra cự ly tới trọng tâm: Nếu xa quá 200 stud thì KHÔNG KÉO!
                    local toCenter = center - root.Position
                    local dist = toCenter.Magnitude

                    if dist <= 200 then
                        -- Bỏ va chạm, không neo
                        for _, part in ipairs(model:GetDescendants()) do
                            if part:IsA("BasePart") then
                                if part.CanCollide then part.CanCollide = false end
                                pcall(function()
                                    if part.Anchored then part.Anchored = false end
                                    part.Massless = true
                                end)
                            end
                        end

                        pcall(function()
                            if root.Anchored then root.Anchored = false end
                            root.CanCollide = false
                            root.Massless = true
                        end)

                        local oldBv = root:FindFirstChild("HiliBringBV")
                        if oldBv then pcall(function() oldBv:Destroy() end) end

                        -- 1. Setup BodyPosition (HiliBringBP) kéo về tọa độ trọng tâm
                        local bp = root:FindFirstChild("HiliBringBP")
                        if not bp then
                            bp = Instance.new("BodyPosition")
                            bp.Name = "HiliBringBP"
                            bp.Parent = root
                        end
                        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

                        -- 2. Setup BodyGyro (HiliBringBG)
                        local bg = root:FindFirstChild("HiliBringBG")
                        if not bg then
                            bg = Instance.new("BodyGyro")
                            bg.Name = "HiliBringBG"
                            bg.Parent = root
                        end
                        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                        bg.P = 30000
                        bg.D = 1200
                        bg.CFrame = CFrame.new(center)

                        -- 3. Di chuyển mượt mà về trọng tâm center với tốc độ 450
                        if dist > 2.5 then
                            local approachSpeed = speed
                            if dist < 60 then
                                approachSpeed = math.clamp((dist / 60) * speed, 20, speed)
                            end
                            root.AssemblyLinearVelocity = toCenter.Unit * approachSpeed

                            bp.P = 30000
                            bp.D = 600
                            bp.Position = center
                        else
                            bp.P = 50000
                            bp.D = 2500
                            bp.Position = center
                        end

                        pcall(function()
                            if sethiddenproperty then
                                sethiddenproperty(root, "NetworkIsSleeping", false)
                            end
                        end)
                    else
                        -- Xa quá 200 stud: KHÔNG KÉO! Gỡ bỏ mover nếu có
                        Utility.CleanEnemyMoverAttributes(root, model, hum)
                    end
                else
                    -- Quái đã chết: Dọn dẹp mover ngay
                    Utility.CleanEnemyMoverAttributes(root, model, hum)
                    table.remove(currentBringData.Mobs, i)
                end
            else
                table.remove(currentBringData.Mobs, i)
            end
        end

        if #currentBringData.Mobs == 0 then
            Utility.CleanupBringMobMovers()
            DisconnectConnection("bringMobStepped")
        end
    end)
end

--[[ Bring matching mobs theo cơ chế Trọng Tâm & Giới hạn 200 studs:
     - Radar tìm quái: Quét trong bán kính 400 studs (S.BringMobDistance or 400).
     - Tìm tất cả quái cùng tên, còn sống trong bãi.
     - Lọc cụm quái gần nhân vật và tính TỌA ĐỘ TRỌNG TÂM (Centroid).
     - QUY TẮC CHỐNG BAY ẢO: Nếu vị trí trung tâm mà xa quái quá 200 stud thì KHÔNG KÉO quái đó!
     - DÙNG XONG LÀ PHẢI XÓA SẠCH: Khi toàn bộ quái chết hoặc không còn quái -> CleanupBringMobMovers(). ]]
function Utility.BringMatchingMobs(mobName, maxRadius)
    local now = os.clock()
    pcall(function()
        if sethiddenproperty and LocalPlayer then
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            sethiddenproperty(LocalPlayer, "MaximumSimulationRadius", math.huge)
        end
        if setsimulationradius then
            setsimulationradius(math.huge, math.huge)
        end
    end)

    if mobPatrolState and mobPatrolState.forcePatrolUntil and now < mobPatrolState.forcePatrolUntil then
        Utility.CleanupBringMobMovers()
        return nil, nil, {}
    end

    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then 
        Utility.CleanupBringMobMovers()
        return nil, nil, {} 
    end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.zero
    local isPlayerUnder = (myPos.Y < -1000)

    -- 1. Radar quét tìm quái cùng tên trong bán kính 400 studs
    local radius = math.clamp(maxRadius or S.BringMobDistance or 400, 100, 1000)
    local matchingMobs = {}

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy:IsA("Model") and Utility.IsMobNameMatch(enemy.Name, mobName) then
            if not (_ignoredDesyncedMobs[enemy] and now < _ignoredDesyncedMobs[enemy]) then
                local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildOfClass("BasePart")
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local ePos = root.Position
                    local isEnemyUnder = (ePos.Y < -1000)
                    if isPlayerUnder == isEnemyUnder then
                        local dist = (ePos - myPos).Magnitude
                        if dist <= radius then
                            local parts = {}
                            for _, p in ipairs(enemy:GetDescendants()) do
                                if p:IsA("BasePart") then
                                    table.insert(parts, p)
                                end
                            end

                            table.insert(matchingMobs, {
                                Model = enemy,
                                Root = root,
                                Hum = hum,
                                Pos = ePos,
                                Parts = parts,
                            })
                        end
                    end
                end
            end
        end
    end

    -- 2. DÙNG XONG / KHÔNG CÒN QUÁI: XÓA SẠCH ĐỂ TỰ ĐỘNG TÌM QUÁI KHÁC ĐÁNH
    if #matchingMobs == 0 then
        Utility.CleanupBringMobMovers()
        return nil, nil, {}
    end

    -- 3. XÁC ĐỊNH MỎ NEO & CỤM QUÁI TRONG BÁN KÍNH 200 STUD
    -- Tìm quái gần nhân vật nhất làm mỏ neo chính
    local anchorMob = matchingMobs[1]
    local minDistToMe = (anchorMob.Pos - myPos).Magnitude
    for i = 2, #matchingMobs do
        local d = (matchingMobs[i].Pos - myPos).Magnitude
        if d < minDistToMe then
            minDistToMe = d
            anchorMob = matchingMobs[i]
        end
    end

    -- Gom các quái nằm trong bán kính 200 stud quanh anchorMob
    local clusterMobs = {}
    local sumPos = Vector3.zero
    for _, item in ipairs(matchingMobs) do
        local distToAnchor = (item.Pos - anchorMob.Pos).Magnitude
        if distToAnchor <= 200 then
            table.insert(clusterMobs, item)
            sumPos = sumPos + item.Pos
        end
    end

    if #clusterMobs == 0 then
        table.insert(clusterMobs, anchorMob)
        sumPos = anchorMob.Pos
    end

    -- Tọa độ trọng tâm (Centroid) của cụm quái
    local centerPos = sumPos / #clusterMobs

    -- QUY TẮC: Nếu vị trí trung tâm mà xa quái quá 200 stud thì KHÔNG KÉO quái đó!
    local validBringMobs = {}
    for _, item in ipairs(clusterMobs) do
        local distToCenter = (item.Root.Position - centerPos).Magnitude
        if distToCenter <= 200 then
            table.insert(validBringMobs, item)
        else
            Utility.CleanEnemyMoverAttributes(item.Root, item.Model, item.Hum)
        end
    end

    if #validBringMobs == 0 then
        validBringMobs = { anchorMob }
        centerPos = anchorMob.Pos
    end

    local primaryModel = anchorMob.Model

    _lockedMobCluster.mob = primaryModel.Name
    _lockedMobCluster.center = centerPos
    _lockedMobCluster.lockTime = now
    if CTX then CTX._lockedMobCluster = _lockedMobCluster end

    -- 4. Kéo quái về trọng tâm (nếu bật BringMob)
    if S.BringMobEnabled then
        currentBringData = {
            Center = centerPos,
            Mobs = validBringMobs,
        }
        if CTX then CTX.currentBringData = currentBringData end
        Utility.UpdateBringMobSteppedState()
    else
        Utility.CleanupBringMobMovers()
    end

    return centerPos, primaryModel, validBringMobs
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     SPECIAL QUESTS & AUTO NEXT SEA PROGRESSION SYSTEM
   ═══════════════════════════════════════════════════════════════════════════ ]]

local _inventoryCache = {}
local _lastInventoryFetch = 0
local _locallyOwnedItems = {}


function Utility.GetCachedInventory()
    local now = os.clock()
    if (now - _lastInventoryFetch > 4.0) or #_inventoryCache == 0 then
        _lastInventoryFetch = now
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if commF then
            pcall(function()
                local inv = commF:InvokeServer("getInventory")
                if typeof(inv) == "table" then
                    _inventoryCache = inv
                    for _, itm in pairs(inv) do
                        if typeof(itm) == "table" and itm.Name then
                            _locallyOwnedItems[itm.Name] = true
                        elseif typeof(itm) == "string" then
                            _locallyOwnedItems[itm] = true
                        end
                    end
                end
            end)
        end
    end
    return _inventoryCache
end
Utility.GetInventoryCached = Utility.GetCachedInventory

--[[ Quét kho đồ CHỈ VŨ KHÍ (Weapons: Sword / Gun / Tools) để kiểm tra một món cụ thể (vd: "Saber") ]]
function Utility.CheckWeaponInventory(targetName)
    if not targetName or targetName == "" then return false end
    local lowTarget = string.lower(targetName)

    -- 1. Kiểm tra Tools trong Backpack
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local tName = string.lower(item.Name)
                local tTip = string.lower(tostring(item.ToolTip or ""))
                local isWep = tTip == "sword" or tTip == "gun" or tTip == "weapon" or tTip == ""
                if isWep and (tName == lowTarget or string.find(tName, lowTarget, 1, true)) then
                    return true
                end
            end
        end
    end

    -- 2. Kiểm tra Tool đang trang bị trên tay (Character)
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                local tName = string.lower(item.Name)
                local tTip = string.lower(tostring(item.ToolTip or ""))
                local isWep = tTip == "sword" or tTip == "gun" or tTip == "weapon" or tTip == ""
                if isWep and (tName == lowTarget or string.find(tName, lowTarget, 1, true)) then
                    return true
                end
            end
        end
    end

    -- 3. Quét Server Inventory của CHỈ VŨ KHÍ qua commF_
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if commF then
        local okWep, wepList = pcall(function() return commF:InvokeServer("getInventoryWeapons") end)
        if okWep and typeof(wepList) == "table" then
            for _, itm in pairs(wepList) do
                if typeof(itm) == "table" then
                    local iName = itm.Name or itm[1] or itm.DisplayName or itm.Id
                    local iType = string.lower(tostring(itm.Type or itm.type or ""))
                    if iName and typeof(iName) == "string" then
                        local lowName = string.lower(iName)
                        local isWeaponType = string.find(iType, "sword") or string.find(iType, "gun") or string.find(iType, "weapon") or iType == "" or iType == "item"
                        if isWeaponType and (lowName == lowTarget or string.find(lowName, lowTarget, 1, true)) then
                            return true
                        end
                    end
                elseif typeof(itm) == "string" then
                    local lowName = string.lower(itm)
                    if lowName == lowTarget or string.find(lowName, lowTarget, 1, true) then
                        return true
                    end
                end
            end
        end

        local okInv, invList = pcall(function() return commF:InvokeServer("getInventory") end)
        if okInv and typeof(invList) == "table" then
            for _, itm in pairs(invList) do
                if typeof(itm) == "table" then
                    local iName = itm.Name or itm[1] or itm.DisplayName
                    local iType = string.lower(tostring(itm.Type or itm.type or ""))
                    if iName and typeof(iName) == "string" then
                        local lowName = string.lower(iName)
                        local isWeaponType = string.find(iType, "sword") or string.find(iType, "gun") or string.find(iType, "weapon")
                        if (isWeaponType or iType == "") and (lowName == lowTarget or string.find(lowName, lowTarget, 1, true)) then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

--[[ Quét kho đồ CHỈ PHỤ KIỆN / TRANG BỊ (Accessories / Wear) để kiểm tra một món cụ thể (vd: "Warrior Helmet", "Swan Glasses") ]]
function Utility.CheckAccessoryInventory(targetName)
    if not targetName or targetName == "" then return false end
    local lowTarget = string.lower(targetName)

    -- 1. Kiểm tra trong Backpack (Accessory / Tool)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            local tName = string.lower(item.Name)
            if tName == lowTarget or string.find(tName, lowTarget, 1, true) then
                return true
            end
        end
    end

    -- 2. Kiểm tra trong Character (Accessory / Tool đã mặc)
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Accessory") or item:IsA("Tool") then
                local tName = string.lower(item.Name)
                if tName == lowTarget or string.find(tName, lowTarget, 1, true) then
                    return true
                end
            end
        end
    end

    -- 3. Quét Server Inventory của CHỈ PHỤ KIỆN qua commF_ (Wear / Accessory)
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if commF then
        local okWep, wepList = pcall(function() return commF:InvokeServer("getInventoryWeapons") end)
        if okWep and typeof(wepList) == "table" then
            for _, itm in pairs(wepList) do
                if typeof(itm) == "table" then
                    local iName = itm.Name or itm[1] or itm.DisplayName or itm.Id
                    local iType = string.lower(tostring(itm.Type or itm.type or ""))
                    if iName and typeof(iName) == "string" then
                        local lowName = string.lower(iName)
                        local isWear = string.find(iType, "wear") or string.find(iType, "accessory") or iType == ""
                        if isWear and (lowName == lowTarget or string.find(lowName, lowTarget, 1, true)) then
                            return true
                        end
                    end
                elseif typeof(itm) == "string" then
                    local lowName = string.lower(itm)
                    if lowName == lowTarget or string.find(lowName, lowTarget, 1, true) then
                        return true
                    end
                end
            end
        end

        local okInv, invList = pcall(function() return commF:InvokeServer("getInventory") end)
        if okInv and typeof(invList) == "table" then
            for _, itm in pairs(invList) do
                if typeof(itm) == "table" then
                    local iName = itm.Name or itm[1] or itm.DisplayName
                    local iType = string.lower(tostring(itm.Type or itm.type or ""))
                    if iName and typeof(iName) == "string" then
                        local lowName = string.lower(iName)
                        local isWear = string.find(iType, "wear") or string.find(iType, "accessory")
                        if (isWear or iType == "") and (lowName == lowTarget or string.find(lowName, lowTarget, 1, true)) then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

function Utility.HasItem(itemName)
    if not itemName or itemName == "" then return false end
    if _locallyOwnedItems[itemName] then return true end

    -- 1. Check Backpack inventory
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(itemName) then 
        _locallyOwnedItems[itemName] = true
        return true 
    end

    -- 2. Check currently equipped item (Character)
    local ch = LocalPlayer.Character
    if ch and ch:FindFirstChild(itemName) then 
        _locallyOwnedItems[itemName] = true
        return true 
    end
    -- 3. Check cached remote inventory data
    local inv = Utility.GetCachedInventory()
    if typeof(inv) == "table" then
        for _, item in pairs(inv) do
            if typeof(item) == "table" and item.Name then
                if item.Name == itemName or string.find(item.Name:lower(), itemName:lower(), 1, true) then
                    _locallyOwnedItems[itemName] = true
                    return true
                end
            elseif typeof(item) == "string" and (item == itemName or string.find(item:lower(), itemName:lower(), 1, true)) then
                _locallyOwnedItems[itemName] = true
                return true
            end
        end
    end

    return false
end

function Utility.EquipItemByName(itemName)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if ch and ch:FindFirstChild(itemName) then return ch[itemName] end
    if bp and bp:FindFirstChild(itemName) and hum then
        local t = bp[itemName]
        hum:EquipTool(t)
        return t
    end

    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if commF then
        for _, m in ipairs(MELEE_DATABASE) do
            if m.Name == itemName and m.Remote then
                pcall(function()
                    commF:InvokeServer(m.Remote, unpack(m.Args or {}))
                end)
                task.wait(0.15)
                break
            end
        end
        pcall(function()
            commF:InvokeServer("LoadItem", itemName)
        end)
        task.wait(0.15)
    end

    bp = LocalPlayer:FindFirstChild("Backpack")
    ch = LocalPlayer.Character
    hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if ch and ch:FindFirstChild(itemName) then return ch[itemName] end
    if bp and bp:FindFirstChild(itemName) and hum then
        local t = bp[itemName]
        hum:EquipTool(t)
        return t
    end

    return nil
end

-- ╔══════════════════════════════════════════════════════════╗


-- ========================================================
-- [SECTION: LEVEL FARMING RUNTIME LOOP]
-- ========================================================

function Utility.HasSaber()
    return Utility.CheckWeaponInventory("Saber")
end

--[[ Helper: Get Final Door position from Workspace.Map.Jungle.Final ]]
function Utility.GetSaberFinalDoorPos()
    local jungleMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle")
    local finalFolder = (jungleMap and jungleMap:FindFirstChild("Final")) or (workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Final", true)) or workspace:FindFirstChild("Final", true)
    if finalFolder then
        if finalFolder:IsA("Model") then
            local p = finalFolder.PrimaryPart or finalFolder:FindFirstChildOfClass("BasePart")
            if p then return p.Position, finalFolder end
            if finalFolder:GetPivot() then return finalFolder:GetPivot().Position, finalFolder end
        elseif finalFolder:IsA("Folder") then
            local p = finalFolder:FindFirstChildOfClass("BasePart")
            if p then return p.Position, finalFolder end
        end
    end
    return Vector3.new(-1405, 29, 3), finalFolder
end

--[[ Auto detect Saber door status in Workspace.Map.Jungle.Final:
     - Before opening: Parts have Transparency < 0.95
     - After opening: ALL parts in Workspace.Map.Jungle.Final have Transparency >= 0.95 (effectively 1)
]]
function Utility.IsSaberDoorUnlocked()
    if Utility.HasSaber() then return true end

    local jungleMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle")
    local finalFolder = (jungleMap and jungleMap:FindFirstChild("Final")) or (workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Final", true)) or workspace:FindFirstChild("Final", true)
    
    if finalFolder then
        local parts = {}
        for _, child in ipairs(finalFolder:GetChildren()) do
            if child:IsA("BasePart") and child.Name ~= "Invis" then
                table.insert(parts, child)
            end
        end
        if #parts > 0 then
            for _, part in ipairs(parts) do
                if part.Transparency < 0.95 then
                    return false
                end
            end
            return true
        end
    end

    return false
end

--[[ Find 5 puzzle plates in Workspace.Map.Jungle.QuestPlates ]]
function Utility.GetJungleQuestPlates()
    local plates = {}
    local fallbackPositions = {
        [1] = Vector3.new(-1610, 36, 148),
        [2] = Vector3.new(-1240, 12, -490),
        [3] = Vector3.new(-1612, 11, 155),
        [4] = Vector3.new(-1495, 23, 35),
        [5] = Vector3.new(-1338, 12, -460),
    }

    local jungleMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle")
    local questPlatesFolder = (jungleMap and jungleMap:FindFirstChild("QuestPlates"))
        or workspace:FindFirstChild("QuestPlates", true)

    for i = 1, 5 do
        local plateName = "Plate" .. tostring(i)
        local plateObj = questPlatesFolder and questPlatesFolder:FindFirstChild(plateName)
        if not plateObj then
            plateObj = workspace:FindFirstChild(plateName, true)
        end

        local pos = nil
        local part = nil
        if plateObj then
            if plateObj:IsA("BasePart") then
                pos = plateObj.Position
                part = plateObj
            elseif plateObj:IsA("Model") then
                part = plateObj.PrimaryPart or plateObj:FindFirstChildOfClass("BasePart") or plateObj:FindFirstChild("Button") or plateObj:FindFirstChild("Plate")
                pos = part and part.Position or (plateObj:GetPivot() and plateObj:GetPivot().Position)
            end
        end

        if not pos then
            pos = fallbackPositions[i]
        end

        plates[i] = {
            Index = i,
            Name = plateName,
            Instance = plateObj,
            Part = part,
            Position = pos
        }
    end

    return plates
end

--[[ Get Torch position from Workspace.Map.Jungle.Torch ]]
function Utility.GetJungleTorchPos()
    local jungleMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle")
    local torchObj = (jungleMap and jungleMap:FindFirstChild("Torch")) or workspace:FindFirstChild("Torch", true)
    if torchObj then
        if torchObj:IsA("BasePart") then return torchObj.Position, torchObj end
        if torchObj:IsA("Model") then
            local part = torchObj.PrimaryPart or torchObj:FindFirstChildOfClass("BasePart")
            if part then return part.Position, torchObj end
            if torchObj:GetPivot() then return torchObj:GetPivot().Position, torchObj end
        end
    end
    return Vector3.new(-1610, 11, 155), torchObj
end

--[[ Get Burn door position from Workspace.Map.Desert.Burn ]]
function Utility.GetDesertBurnDoor()
    local desertMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Desert")
    local burnObj = (desertMap and desertMap:FindFirstChild("Burn")) or workspace:FindFirstChild("Burn", true)
    if burnObj then
        if burnObj:IsA("BasePart") then return burnObj.Position, burnObj end
        if burnObj:IsA("Model") then
            local part = burnObj.PrimaryPart or burnObj:FindFirstChildOfClass("BasePart")
            if part then return part.Position, burnObj end
            if burnObj:GetPivot() then return burnObj:GetPivot().Position, burnObj end
        end
    end
    return nil, nil
end

--[[ Get Cup position from Workspace.Map.Desert.Cup ]]
function Utility.GetDesertCupPos()
    local desertMap = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Desert")
    local cupObj = (desertMap and desertMap:FindFirstChild("Cup")) or workspace:FindFirstChild("Cup", true)
    if cupObj then
        if cupObj:IsA("BasePart") then return cupObj.Position, cupObj end
        if cupObj:IsA("Model") then
            local part = cupObj:FindFirstChild("Part") or cupObj.PrimaryPart or cupObj:FindFirstChildOfClass("BasePart")
            if part then return part.Position, cupObj end
            if cupObj:GetPivot() then return cupObj:GetPivot().Position, cupObj end
        end
    end
    return Vector3.new(1113, 4, 4350), cupObj
end

--[[ Get NPC position from Workspace.NPCs ]]
function Utility.GetNPCLocation(npcNames)
    local names = typeof(npcNames) == "table" and npcNames or { npcNames }
    local npcsFolder = workspace:FindFirstChild("NPCs")
    for _, name in ipairs(names) do
        local npc = (npcsFolder and npcsFolder:FindFirstChild(name, true)) or workspace:FindFirstChild(name, true)
        if npc and npc:IsA("Model") then
            local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildOfClass("BasePart")
            if root then return root.Position, npc end
        end
    end
    return nil, nil
end

--[[ Physics flight to target position and wait until arrival (safe physics fly without direct CFrame teleport) ]]
function Utility.FlyAndWaitArrival(targetPos, speed, timeout, reachDist)
    reachDist = reachDist or 8
    timeout = timeout or 35
    local flySpeed = speed or S.TeleportFlySpeed or 200
    local t0 = os.clock()

    -- Handle dimension/area transition if target is in a sub-realm (Underwater City or Ghost Ship)
    Utility.CheckAndHandleAreaTransitions(targetPos)

    Utility.PhysicsFlyTo(targetPos, flySpeed)
    while os.clock() - t0 < timeout do
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - targetPos).Magnitude <= reachDist then
            task.wait(0.2)
            Utility.StopPhysicsFly()
            return true
        end
        task.wait(0.1)
    end
    Utility.StopPhysicsFly()
    return false
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     1. SABER QUEST (SHANKS / SABER EXPERT - LEVEL 200+)
   ═══════════════════════════════════════════════════════════════════════════ ]]

local saberQuestRunning = false
function Utility.HandleSaberQuest(forceRun)
    if saberQuestRunning then return end
    saberQuestRunning = true
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if not commF then saberQuestRunning = false; return end

        local flySpeed = S.TeleportFlySpeed or 200
        local lockCFrame = CFrame.new(
            -1405.79102, 31.151001, 2.20799255,
            0.500218391, -0.000192676569, -0.865899265,
            0.000106373409, 1, -0.000161065647,
            0.865899265, -1.15406583e-05, 0.500218391
        )

        -- 1. Check if Saber is already owned in weapon inventory
        if not forceRun and Utility.CheckWeaponInventory("Saber") then
            S.AutoSaberQuestEnabled = false
            task.spawn(function()
                task.wait(0.05)
                if UI_ELEMENTS["AutoSaberQuestEnabled"] and UI_ELEMENTS["AutoSaberQuestEnabled"].Set then
                    UI_ELEMENTS["AutoSaberQuestEnabled"]:Set(false)
                end
            end)
            UILib.Notify("Saber Quest", "Saber is already owned in weapon inventory! Quest disabled.", 4)
            saberQuestRunning = false
            return
        end

        -- 2. Auto detect Final door state (Workspace.Map.Jungle.Final)
        -- If door already opened (all parts transparency == 1) and not forceRun: Skip puzzle, engage boss if spawned
        if not forceRun and Utility.IsSaberDoorUnlocked() then
            local saberExpert = Utility.GetEnemyByName("Saber Expert")
            if saberExpert then
                UILib.Notify("Saber Quest", "Saber door is open & Saber Expert detected! Flying to defeat Boss...", 4)
                Utility.FlyAndWaitArrival(Vector3.new(-1405, 29, 3), flySpeed, 35, 5)
                local t1 = os.clock()
                while os.clock() - t1 < 45 and not Utility.HasSaber() do
                    saberExpert = Utility.GetEnemyByName("Saber Expert")
                    if saberExpert then
                        local _, _, seRoot = Utility.GetEnemyRootCFrame(saberExpert)
                        if seRoot then
                            Utility.FlyAboveTarget(seRoot.CFrame, S.AttackHeight or 40, flySpeed)
                            local wType = S.SelectedWeaponType or "Melee"
                            if wType == "Melee" then Utility.AttackMelee(saberExpert, seRoot)
                            elseif wType == "Sword" then Utility.AttackSword(saberExpert, seRoot)
                            elseif wType == "Fruit" then Utility.AttackFruitM1(saberExpert, seRoot)
                            elseif wType == "Gun" then Utility.AttackGun(saberExpert, seRoot)
                            end
                        end
                    else
                        break
                    end
                    task.wait(0.04)
                end
                Utility.StopPhysicsFly()
            else
                UILib.Notify("Saber Quest", "Saber Door is already open! Boss not spawned yet.", 4)
            end
            saberQuestRunning = false
            return
        end

        -- 3. If door not opened: Run complete Saber puzzle solver sequence
        UILib.Notify("Saber Quest", "Starting puzzle quest sequence...", 4)
        local skipToStep5 = false

        -- STEP 1: 5 Jungle puzzle plates (Run only if Relic/Cup not acquired)
        if not Utility.HasItem("Relic") and not Utility.HasItem("Water Cup") and not Utility.HasItem("Cup") then
            local plates = Utility.GetJungleQuestPlates()
            for i = 1, 5 do
                local plate = plates[i]
                local pPos = plate and plate.Position or Vector3.new(-1610, 36, 148)
                UILib.Notify("Saber Quest", "Flying to Quest Plate " .. i .. "/5 (Workspace.Map.Jungle.QuestPlates)...", 3)
                
                -- Fly to puzzle plate position
                Utility.FlyAndWaitArrival(pPos + Vector3.new(0, 1.2, 0), flySpeed, 25, 4)
                task.wait(0.3)

                -- Touch plate and invoke ProQuestProgress Plate on server
                pcall(function()
                    commF:InvokeServer("ProQuestProgress", "Plate", i)
                end)

                -- Physical touch event trigger if part exists
                if plate.Part and (firetouchinterest or fire_touch_interest) then
                    local ft = firetouchinterest or fire_touch_interest
                    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if r then
                        pcall(function()
                            ft(r, plate.Part, 0)
                            task.wait(0.05)
                            ft(r, plate.Part, 1)
                        end)
                    end
                end
                task.wait(0.6)
            end
        end

        -- STEP 2: Collect Torch from Workspace.Map.Jungle.Torch
        if not Utility.HasItem("Relic") and not Utility.HasItem("Water Cup") and not Utility.HasItem("Cup") then
            local torchPos, torchObj = Utility.GetJungleTorchPos()
            UILib.Notify("Saber Quest", "Flying to Jungle basement for Torch (Workspace.Map.Jungle.Torch)...", 3)
            Utility.FlyAndWaitArrival(torchPos, flySpeed, 25, 3)
            task.wait(1.5)
        end

        -- STEP 3: Burn wooden door in Desert house (Workspace.Map.Desert.Burn)
        if not Utility.HasItem("Relic") and not Utility.HasItem("Water Cup") and not Utility.HasItem("Cup") then
            local burnPos, burnObj = Utility.GetDesertBurnDoor()
            if not burnObj or not burnPos then
                -- If Burn door not found -> Proceed directly to Step 5
                UILib.Notify("Saber Quest", "Burn door not found (already opened), skipping directly to Step 5...", 3)
                skipToStep5 = true
            else
                UILib.Notify("Saber Quest", "Flying to Desert Burn door (Workspace.Map.Desert.Burn)...", 3)
                Utility.FlyAndWaitArrival(burnPos, flySpeed, 40, 4)
                Utility.EquipItemByName("Torch")
                task.wait(0.5)

                -- When Burn door disappears, proceed to next step
                local t0 = os.clock()
                while os.clock() - t0 < 5 do
                    local _, currentBurn = Utility.GetDesertBurnDoor()
                    if not currentBurn or not currentBurn.Parent then
                        break
                    end
                    task.wait(0.4)
                end
                task.wait(0.8)
            end
        end

        -- STEP 4: Collect Cup from Workspace.Map.Desert.Cup
        if not skipToStep5 and not Utility.HasItem("Cup") and not Utility.HasItem("Water Cup") and not Utility.HasItem("Relic") then
            local cupPos, cupObj = Utility.GetDesertCupPos()
            UILib.Notify("Saber Quest", "Flying to Desert Cup (Workspace.Map.Desert.Cup)...", 3)
            Utility.FlyAndWaitArrival(cupPos, flySpeed, 20, 3)
            task.wait(1.5)

            -- Check if Cup is in Backpack / Character
            local t0 = os.clock()
            while os.clock() - t0 < 4 and not Utility.HasItem("Cup") do
                task.wait(0.3)
            end
        end

        -- STEP 5: Fly to ice cave drip, equip Cup, invoke ProQuestProgress FillCup
        if not Utility.HasItem("Relic") then
            UILib.Notify("Saber Quest", "Flying to Frozen Village icicle (1397, 37, -1325)...", 3)
            Utility.FlyAndWaitArrival(Vector3.new(1397, 37, -1325), flySpeed, 40, 3)
            Utility.EquipItemByName("Cup")
            task.wait(2.0)

            -- Invoke ProQuestProgress FillCup on server with Cup tool
            pcall(function()
                local cupTool = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Cup"))
                    or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Cup"))
                commF:InvokeServer("ProQuestProgress", "FillCup", cupTool)
            end)
            task.wait(1.0)
        end

        -- STEP 6: Fly to Sick Man in Frozen Village, invoke ProQuestProgress SickMan
        if not Utility.HasItem("Relic") then
            local sickManPos = Utility.GetNPCLocation({"Sick Man", "SickMan"}) or Vector3.new(1392, 87, -1297)
            UILib.Notify("Saber Quest", "Flying to Sick Man in NPCs (Workspace.NPCs.Sick Man)...", 3)
            Utility.FlyAndWaitArrival(sickManPos, flySpeed, 25, 5)
            if not Utility.EquipItemByName("Water Cup") then
                Utility.EquipItemByName("Cup")
            end
            task.wait(0.5)
            pcall(function()
                commF:InvokeServer("ProQuestProgress", "SickMan")
            end)
            task.wait(0.8)
        end

        -- STEPS 7 & 8: Talk to Rich Man in Pirate Village, defeat Mob Leader, obtain Relic
        if not Utility.HasItem("Relic") then
            -- STEP 7: Fly to Pirate Village, talk to Rich Man
            local richManPos = Utility.GetNPCLocation({"Rich Man", "Rich Son", "RichMan", "RichSon"}) or Vector3.new(-909, 14, 4078)
            UILib.Notify("Saber Quest", "Flying to Rich Man in Pirate Village (Workspace.NPCs)...", 3)
            Utility.FlyAndWaitArrival(richManPos, flySpeed, 35, 5)
            task.wait(0.5)
            pcall(function()
                commF:InvokeServer("ProQuestProgress", "RichSon")
            end)
            task.wait(0.8)

            -- STEP 8: Fly to Mob Island, defeat Mob Leader
            UILib.Notify("Saber Quest", "Flying to Mob Island to defeat Mob Leader...", 3)
            Utility.FlyAndWaitArrival(Vector3.new(-2850, 7, 5350), flySpeed, 40, 20)
            local t0 = os.clock()
            while os.clock() - t0 < 30 do
                local mobLeader = Utility.GetEnemyByName("Mob Leader")
                if mobLeader then
                    local _, _, mlRoot = Utility.GetEnemyRootCFrame(mobLeader)
                    if mlRoot then
                        Utility.FlyAboveTarget(mlRoot.CFrame, S.AttackHeight or 40, flySpeed)
                        local wType = S.SelectedWeaponType or "Melee"
                        if wType == "Melee" then Utility.AttackMelee(mobLeader, mlRoot)
                        elseif wType == "Sword" then Utility.AttackSword(mobLeader, mlRoot)
                        elseif wType == "Fruit" then Utility.AttackFruitM1(mobLeader, mlRoot)
                        elseif wType == "Gun" then Utility.AttackGun(mobLeader, mlRoot)
                        end
                    end
                else
                    task.wait(0.5)
                    local mlCheck = Utility.GetEnemyByName("Mob Leader")
                    if not mlCheck then break end
                end
                task.wait(0.04)
            end
            Utility.StopPhysicsFly()

            -- Return to Step 7: Talk to Rich Man again to receive Relic
            UILib.Notify("Saber Quest", "Returning to Rich Man to get Relic...", 3)
            richManPos = Utility.GetNPCLocation({"Rich Man", "Rich Son", "RichMan", "RichSon"}) or Vector3.new(-909, 14, 4078)
            Utility.FlyAndWaitArrival(richManPos, flySpeed, 35, 5)
            task.wait(0.5)
            pcall(function()
                commF:InvokeServer("ProQuestProgress", "RichSon")
            end)
            task.wait(1.0)
        end

        -- STEP 9: Fly to Final Door in Jungle, equip Relic, orient character and camera into Keyhole lock, insert key until door is 100% open
        if not Utility.IsSaberDoorUnlocked() then
            local finalDoorPos, _ = Utility.GetSaberFinalDoorPos()
            local lockPos = lockCFrame.Position

            UILib.Notify("Saber Quest", "Flying to Jungle Final Door & aiming into Keyhole lock...", 3)
            Utility.FlyAndWaitArrival(finalDoorPos, flySpeed, 20, 8)

            local unlockTimeout = os.clock()
            while not Utility.IsSaberDoorUnlocked() and (os.clock() - unlockTimeout < 25) do
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local cam = workspace.CurrentCamera

                if char and root and hum and hum.Health > 0 then
                    -- 1. Equip Relic
                    Utility.EquipItemByName("Relic")

                    -- 2. Stand at Final Door and orient character and camera looking directly into the Keyhole lock
                    local standPos = finalDoorPos
                    if (standPos - lockPos).Magnitude > 15 then
                        standPos = lockPos + (lockCFrame.LookVector * -3)
                    end

                    root.CFrame = CFrame.lookAt(standPos, lockPos)
                    if cam then
                        cam.CFrame = CFrame.lookAt(standPos + Vector3.new(0, 1.5, 0), lockPos)
                    end

                    -- 3. Activate tool if equipped
                    local relicTool = char:FindFirstChild("Relic") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Relic"))
                    if relicTool then
                        if relicTool.Parent ~= char then
                            hum:EquipTool(relicTool)
                        end
                        pcall(function() relicTool:Activate() end)
                    end

                    -- 4. Invoke Remote & physical touch trigger with Final parts / lock
                    pcall(function()
                        commF:InvokeServer("ProQuestProgress", "UsedRelic")
                    end)

                    local finalFolder = (workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Jungle") and workspace.Map.Jungle:FindFirstChild("Final")) or workspace:FindFirstChild("Final", true)
                    if finalFolder and (firetouchinterest or fire_touch_interest) then
                        local ft = firetouchinterest or fire_touch_interest
                        for _, p in ipairs(finalFolder:GetChildren()) do
                            if p:IsA("BasePart") then
                                pcall(function()
                                    ft(root, p, 0)
                                    task.wait(0.02)
                                    ft(root, p, 1)
                                end)
                            end
                        end
                    end
                end

                task.wait(0.4)
            end
        end

        -- STEP 10: Check if door is unlocked (Transparency == 1 on all parts of workspace.Map.Jungle.Final)
        if Utility.IsSaberDoorUnlocked() then
            UILib.Notify("Saber Quest", "Saber Door is OPEN! Checking for Saber Expert...", 4)

            local saberExpert = Utility.GetEnemyByName("Saber Expert")
            if saberExpert then
                UILib.Notify("Saber Quest", "Fighting Saber Expert (Shanks)...", 4)
                local t1 = os.clock()
                while os.clock() - t1 < 45 and not Utility.HasSaber() do
                    saberExpert = Utility.GetEnemyByName("Saber Expert")
                    if saberExpert then
                        local _, _, seRoot = Utility.GetEnemyRootCFrame(saberExpert)
                        if seRoot then
                            Utility.FlyAboveTarget(seRoot.CFrame, S.AttackHeight or 40, flySpeed)
                            local wType = S.SelectedWeaponType or "Melee"
                            if wType == "Melee" then Utility.AttackMelee(saberExpert, seRoot)
                            elseif wType == "Sword" then Utility.AttackSword(saberExpert, seRoot)
                            elseif wType == "Fruit" then Utility.AttackFruitM1(saberExpert, seRoot)
                            elseif wType == "Gun" then Utility.AttackGun(saberExpert, seRoot)
                            end
                        end
                    else
                        break
                    end
                    task.wait(0.04)
                end
                Utility.StopPhysicsFly()
            else
                UILib.Notify("Saber Quest", "Saber Door is open, but Boss not spawned yet.", 4)
            end
        else
            UILib.Notify("Saber Quest", "Saber Door is still closed! Will retry opening sequence...", 4)
        end

        saberQuestRunning = false
    end)
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     2. THE SON QUEST (SICK MAN & RICH SON & MOB LEADER)
   ═══════════════════════════════════════════════════════════════════════════ ]]

local theSonQuestRunning = false
function Utility.StartTheSonQuest()
    if Utility.HasItem("Relic") or Utility.CheckWeaponInventory("Saber") then
        S.AutoTheSonQuestEnabled = false
        task.spawn(function()
            task.wait(0.05)
            if UI_ELEMENTS["AutoTheSonQuestEnabled"] and UI_ELEMENTS["AutoTheSonQuestEnabled"].Set then
                UI_ELEMENTS["AutoTheSonQuestEnabled"]:Set(false)
            end
        end)
        UILib.Notify("The Son Quest", "Relic / Saber already acquired! Quest disabled.", 4)
        return
    end
    if theSonQuestRunning then return end
    theSonQuestRunning = true
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if not commF then theSonQuestRunning = false; return end

        local flySpeed = S.TeleportFlySpeed or 200
        UILib.Notify("The Son Quest", "Starting The Son Quest (Rich Son & Sick Man)...", 4)

        -- 1. Fly to Sick Man house in Frozen Village
        local sickManPos = Utility.GetNPCLocation({"Sick Man", "SickMan"}) or Vector3.new(1392, 87, -1297)
        UILib.Notify("The Son Quest", "Flying to Sick Man in Frozen Village...", 3)
        Utility.FlyAndWaitArrival(sickManPos, flySpeed, 35, 5)
        task.wait(0.5)
        pcall(function() commF:InvokeServer("ProQuestProgress", "SickMan") end)
        task.wait(0.5)

        -- 2. Fly to Pirate Village, talk to Rich Man
        local richManPos = Utility.GetNPCLocation({"Rich Man", "Rich Son", "RichMan", "RichSon"}) or Vector3.new(-909, 14, 4078)
        UILib.Notify("The Son Quest", "Flying to Rich Man in Pirate Village...", 3)
        Utility.FlyAndWaitArrival(richManPos, flySpeed, 35, 5)
        task.wait(0.5)
        pcall(function() commF:InvokeServer("ProQuestProgress", "RichSon") end)
        task.wait(0.5)

        -- 3. Fly to Mob Island, defeat Mob Leader
        UILib.Notify("The Son Quest", "Flying to Mob Island to defeat Mob Leader...", 3)
        Utility.FlyAndWaitArrival(Vector3.new(-2850, 7, 5350), flySpeed, 40, 20)
        local t0 = os.clock()
        while os.clock() - t0 < 30 do
            local mobLeader = Utility.GetEnemyByName("Mob Leader")
            if mobLeader then
                local _, _, mlRoot = Utility.GetEnemyRootCFrame(mobLeader)
                if mlRoot then
                    Utility.FlyAboveTarget(mlRoot.CFrame, S.AttackHeight or 40, flySpeed)
                    local wType = S.SelectedWeaponType or "Melee"
                    if wType == "Melee" then Utility.AttackMelee(mobLeader, mlRoot)
                    elseif wType == "Sword" then Utility.AttackSword(mobLeader, mlRoot)
                    elseif wType == "Fruit" then Utility.AttackFruitM1(mobLeader, mlRoot)
                    elseif wType == "Gun" then Utility.AttackGun(mobLeader, mlRoot)
                    end
                end
            else
                task.wait(0.5)
                local mlCheck = Utility.GetEnemyByName("Mob Leader")
                if not mlCheck then break end
            end
            task.wait(0.04)
        end
        Utility.StopPhysicsFly()

        -- 4. Fly back to Rich Man for reward
        UILib.Notify("The Son Quest", "Flying back to Rich Man for reward / Relic...", 3)
        richManPos = Utility.GetNPCLocation({"Rich Man", "Rich Son", "RichMan", "RichSon"}) or Vector3.new(-909, 14, 4078)
        Utility.FlyAndWaitArrival(richManPos, flySpeed, 35, 5)
        task.wait(0.5)
        pcall(function() commF:InvokeServer("ProQuestProgress", "RichSon") end)
        task.wait(0.8)

        UILib.Notify("The Son Quest", "The Son Quest completed successfully!", 4)
        S.AutoTheSonQuestEnabled = false
        task.spawn(function()
            task.wait(0.05)
            if UI_ELEMENTS["AutoTheSonQuestEnabled"] and UI_ELEMENTS["AutoTheSonQuestEnabled"].Set then
                UI_ELEMENTS["AutoTheSonQuestEnabled"]:Set(false)
            end
        end)
        theSonQuestRunning = false
    end)
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     3. MILITARY DETECTIVE QUEST (SEA 2 PROGRESSION - LEVEL 700+)
   ═══════════════════════════════════════════════════════════════════════════ ]]

--[[ Helper: Get Military Detective NPC position at Prison from Workspace.NPCs ]]

function Utility.GetMilitaryDetectivePos()
    local npcsFolder = workspace:FindFirstChild("NPCs")
    if npcsFolder then
        local npc = npcsFolder:FindFirstChild("Military Detective") or npcsFolder:FindFirstChild("MilitaryDetective")
        if npc and npc:IsA("Model") then
            local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildOfClass("BasePart")
            if root then return root.Position, npc end
        end
    end
    local loc, obj = Utility.GetNPCLocation({"Military Detective", "MilitaryDetective"})
    if loc then return loc, obj end
    return Vector3.new(4850, 5, 740), nil
end

--[[ Helper: Get Ice Cave Door position from Workspace.Map.Ice.Door ]]
function Utility.GetIceDoorPos()
    local mapFolder = workspace:FindFirstChild("Map")
    if mapFolder then
        local ice = mapFolder:FindFirstChild("Ice") or mapFolder:FindFirstChild("FrozenVillage")
        if ice then
            local door = ice:FindFirstChild("Door") or ice:FindFirstChild("Door", true)
            if door and door:IsA("BasePart") then
                return door.Position, door
            end
        end
    end
    return Vector3.new(1347, 37, -1325), nil
end

local detectiveQuestRunning = false
function Utility.HandleSea2EntranceQuest()
    if detectiveQuestRunning or Utility.GetCurrentSea() ~= 1 then return end

    -- BƯỚC 1: XÁC ĐỊNH CÁC ĐIỀU KIỆN CẦN (Level >= 700 ở Sea 1)
    local curLevel = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
    if curLevel < 700 then return end

    detectiveQuestRunning = true
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if not commF then detectiveQuestRunning = false; return end

        local flySpeed = S.TeleportFlySpeed or 200

        -- ═══════════════════════════════════════════════════════════
        -- [ĐIỀU KIỆN 1]: THỬ TRỰC TIẾP DỊCH CHUYỂN SANG SEA 2 BẰNG REMOTE TRAVELDRESSROSA
        -- ═══════════════════════════════════════════════════════════
        UILib.Notify("Auto Next Sea", "Attempting direct teleport to Sea 2 (TravelDressrosa)...", 4)
        
        pcall(function()
            commF:InvokeServer("TravelDressrosa")
        end)
        task.wait(2.0)

        -- Kiểm tra xem có đang THỰC SỰ ở Sea 2 hay không:
        if Utility.GetCurrentSea() >= 2 then
            UILib.Notify("Auto Next Sea", "Already in Second Sea!", 5)
            detectiveQuestRunning = false
            return
        end

        -- ═══════════════════════════════════════════════════════════
        -- [ĐIỀU KIỆN 2]: NẾU KHÔNG ĐƯỢC -> TIẾN HÀNH CHUỖI NHIỆM VỤ SEA 2
        -- ═══════════════════════════════════════════════════════════
        UILib.Notify("Auto Next Sea", "Direct travel unavailable. Starting Second Sea Entrance Quest (Lv 700+)...", 4)

        -- STEP 2: Fly to Military Detective at Prison, invoke DressrosaQuestProgress Detective
        if not Utility.HasItem("Key") then
            local detPos, _ = Utility.GetMilitaryDetectivePos()
            UILib.Notify("Auto Next Sea", "Flying to Military Detective at Prison...", 3)
            Utility.FlyAndWaitArrival(detPos, flySpeed, 25, 30)
            task.wait(0.5)
            pcall(function()
                commF:InvokeServer("DressrosaQuestProgress", "Detective")
            end)
            task.wait(0.8)
        end

        -- STEP 3: Fly to Ice Cave Door in Frozen Village, equip Key to unlock
        if Utility.HasItem("Key") then
            local doorPos, _ = Utility.GetIceDoorPos()
            UILib.Notify("Auto Next Sea", "Flying to Ice Cave Door in Frozen Village...", 3)
            Utility.FlyAndWaitArrival(doorPos, flySpeed, 25, 6)
            Utility.EquipItemByName("Key")
            task.wait(1.5)
        end

        -- STEP 4: Attack and defeat Ice Admiral in Workspace.Enemies
        local doorPos, _ = Utility.GetIceDoorPos()
        UILib.Notify("Auto Next Sea", "Attacking Ice Admiral inside Ice Cave...", 4)
        Utility.FlyAndWaitArrival(doorPos + Vector3.new(0, 5, -20), flySpeed, 25, 15)

        local t0 = os.clock()
        while os.clock() - t0 < 50 do
            local enemiesFolder = workspace:FindFirstChild("Enemies")
            local iceBoss = (enemiesFolder and enemiesFolder:FindFirstChild("Ice Admiral")) or Utility.GetEnemyByName("Ice Admiral")
            if iceBoss then
                local hum = iceBoss:FindFirstChildOfClass("Humanoid")
                local _, _, ibRoot = Utility.GetEnemyRootCFrame(iceBoss)
                if hum and hum.Health > 0 and ibRoot then
                    Utility.FlyAboveTarget(ibRoot.CFrame, S.AttackHeight or 40, flySpeed)
                    local wType = S.SelectedWeaponType or "Melee"
                    if wType == "Melee" then Utility.AttackMelee(iceBoss, ibRoot)
                    elseif wType == "Sword" then Utility.AttackSword(iceBoss, ibRoot)
                    elseif wType == "Fruit" then Utility.AttackFruitM1(iceBoss, ibRoot)
                    elseif wType == "Gun" then Utility.AttackGun(iceBoss, ibRoot)
                    end
                    if S.AutoFarmUseSkills then
                        if wType == "Melee" then Utility.CastSkillsMelee(ibRoot.Position, iceBoss)
                        elseif wType == "Fruit" then Utility.CastSkillsFruit(ibRoot.Position, iceBoss)
                        elseif wType == "Sword" then Utility.CastSkillsSword(ibRoot.Position, iceBoss)
                        elseif wType == "Gun" then Utility.CastSkillsGun(ibRoot.Position, iceBoss)
                        end
                    end
                else
                    break
                end
            else
                task.wait(0.5)
                local checkAgain = (enemiesFolder and enemiesFolder:FindFirstChild("Ice Admiral")) or Utility.GetEnemyByName("Ice Admiral")
                if not checkAgain then break end
            end
            task.wait(0.04)
        end
        Utility.StopPhysicsFly()
        task.wait(0.5)

        -- After defeat, fly back to Military Detective at Prison, report completion
        local detPos, _ = Utility.GetMilitaryDetectivePos()
        UILib.Notify("Auto Next Sea", "Ice Admiral defeated! Reporting back to Military Detective...", 3)
        Utility.FlyAndWaitArrival(detPos, flySpeed, 25, 30)
        task.wait(0.5)
        pcall(function()
            commF:InvokeServer("DressrosaQuestProgress", "Detective")
        end)
        task.wait(0.8)

        -- STEP 5: Teleport player directly to Second Sea
        UILib.Notify("Auto Next Sea", "Teleporting to Second Sea (TravelDressrosa)...", 5)
        task.wait(0.5)
        pcall(function()
            commF:InvokeServer("TravelDressrosa")
        end)
        task.wait(5)

        if Utility.GetCurrentSea() >= 2 then
            S.AutoMilitaryDetectiveQuestEnabled = false
            task.spawn(function()
                task.wait(0.05)
                if UI_ELEMENTS["AutoMilitaryDetectiveQuestEnabled"] and UI_ELEMENTS["AutoMilitaryDetectiveQuestEnabled"].Set then
                    UI_ELEMENTS["AutoMilitaryDetectiveQuestEnabled"]:Set(false)
                end
            end)
        end

        detectiveQuestRunning = false
    end)
end

function Utility.StartMilitaryDetectiveQuest()
    Utility.HandleSea2EntranceQuest()
end

--[[ Check if Bartilo Quest has been completed (Inventory check + CellDoor transparency check) ]]

function Utility.HasCompletedBartilo()
    -- 1. Check if player owns "Warrior Helmet" in accessory inventory
    if Utility.CheckAccessoryInventory("Warrior Helmet") then
        return true
    end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp and (bp:FindFirstChild("Warrior Helmet") or bp:FindFirstChild("WarriorHelmet")) then 
        return true 
    end

    local char = LocalPlayer.Character
    if char and (char:FindFirstChild("Warrior Helmet") or char:FindFirstChild("WarriorHelmet")) then 
        return true 
    end

    -- 2. Check CellDoor in Workspace/Map/Dressrosa/CellDoor
    local mapFolder = workspace:FindFirstChild("Map")
    local dressrosa = mapFolder and mapFolder:FindFirstChild("Dressrosa")
    local cellDoor = (dressrosa and dressrosa:FindFirstChild("CellDoor")) or workspace:FindFirstChild("CellDoor", true)

    if cellDoor then
        local doorParts = cellDoor:GetChildren()
        if #doorParts > 0 then
            local openPartsCount = 0
            local totalPartsCount = 0
            for _, part in ipairs(doorParts) do
                if part:IsA("BasePart") then
                    totalPartsCount = totalPartsCount + 1
                    if part.Transparency >= 0.9 or not part.CanCollide then
                        openPartsCount = openPartsCount + 1
                    end
                end
            end
            if totalPartsCount > 0 and (openPartsCount / totalPartsCount) >= 0.5 then
                return true
            end
        end
    end

    return false
end

--[[ Auto Bartilo Quest full 7-step sequence with strict step-validation & retry (Level 850+ in Sea 2) ]]
local bartiloRunning = false
function Utility.HandleBartiloQuest()
    -- Kiểm tra kho đồ của CHỈ ACCESSORY có "Warrior Helmet" thì dừng và gửi thông báo
    if Utility.CheckAccessoryInventory("Warrior Helmet") then
        S.AutoBartiloQuestEnabled = false
        task.spawn(function()
            task.wait(0.05)
            if UI_ELEMENTS["AutoBartiloQuestEnabled"] and UI_ELEMENTS["AutoBartiloQuestEnabled"].Set then
                UI_ELEMENTS["AutoBartiloQuestEnabled"]:Set(false)
            end
        end)
        UILib.Notify("Bartilo Quest", "Warrior Helmet already owned in accessory inventory! Quest stopped.", 4)
        return
    end

    if bartiloRunning or Utility.HasCompletedBartilo() then return end
    bartiloRunning = true
    DisconnectConnection("bartiloQuest")

    _conns["bartiloQuest"] = task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if not commF then 
            bartiloRunning = false
            _conns["bartiloQuest"] = nil
            return 
        end

        local flySpeed = S.TeleportFlySpeed or 200
        local BARTILO_POS = Vector3.new(-459, 73, 302)
        local SWAN_PIRATES_SPOTS = {
            Vector3.new(819, 73, 1159),
            Vector3.new(822, 73, 1324),
            Vector3.new(1023, 73, 1393),
            Vector3.new(1064, 73, 1086),
            Vector3.new(983, 73, 1165)
        }
        local JEREMY_POS = Vector3.new(2196, 449, 713)
        local COLOSSEUM_POS = Vector3.new(-1834, 10, 1692)

        local function GetSwanPirateQuestState()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local mainGui = pg and pg:FindFirstChild("Main")
            local questGui = mainGui and mainGui:FindFirstChild("Quest")
            
            if not questGui or not questGui.Visible then
                return false, 0, 50, false
            end
            
            local hasSwanQuest = false
            local curCount = 0
            local maxCount = 50
            
            for _, desc in ipairs(questGui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text and desc.Text ~= "" then
                    local t = desc.Text:lower()
                    if t:find("swan") or t:find("bartilo") then
                        hasSwanQuest = true
                    end
                    local cur, max = desc.Text:match("(%d+)/(%d+)")
                    if cur and max then
                        curCount = tonumber(cur) or 0
                        maxCount = tonumber(max) or 50
                    end
                end
            end
            
            local isDone = (hasSwanQuest and curCount >= maxCount and maxCount > 0)
            return hasSwanQuest, curCount, maxCount, isDone
        end

        local function TalkToBartilo()
            if not S.AutoBartiloQuestEnabled then return false end
            UILib.Notify("Bartilo Quest", "Flying to Bartilo at Cafe...", 3)
            Utility.FlyAndWaitArrival(BARTILO_POS, flySpeed, 35, 6)
            task.wait(0.5)
            pcall(function()
                commF:InvokeServer("BartiloQuestProgress", "Bartilo")
            end)
            task.wait(0.5)
            return true
        end

        local function AttackTarget(targetMob, targetRoot, cluster)
            if not targetMob or not targetRoot then return end
            local wType = S.SelectedWeaponType or "Melee"
            if wType == "Melee" then
                Utility.AttackMelee(targetMob, targetRoot, cluster)
            elseif wType == "Sword" then
                Utility.AttackSword(targetMob, targetRoot, cluster)
            elseif wType == "Fruit" then
                Utility.AttackFruitM1(targetMob, targetRoot, cluster)
            elseif wType == "Gun" then
                Utility.AttackGun(targetMob, targetRoot, cluster)
            end
        end

        -- Outer loop: If final check doesn't have Warrior Helmet or Cell Door not open, retry entire sequence from Step 1
        while S.AutoBartiloQuestEnabled and not Utility.HasCompletedBartilo() do

            -- ═══════════════════════════════════════════════════════════
            -- BƯỚC 1: Bay đến -459, 73, 302, kích hoạt BartiloQuestProgress
            -- ═══════════════════════════════════════════════════════════
            if not S.AutoBartiloQuestEnabled then break end
            TalkToBartilo()

            -- ═══════════════════════════════════════════════════════════
            -- BƯỚC 2: Tiêu diệt 50 Swan Pirate
            -- Dịch chuyển đến đúng từng mobpos trước rồi mới gom quái & tấn công:
            -- (819, 73, 1159) -> (822, 73, 1324) -> (1023, 73, 1393) -> (1064, 73, 1086) -> (983, 73, 1165)
            -- ═══════════════════════════════════════════════════════════
            if not S.AutoBartiloQuestEnabled or Utility.HasCompletedBartilo() then break end
            UILib.Notify("Bartilo Quest", "Step 2: Checking / Starting 50 Swan Pirates Quest...", 3)
            pcall(function() commF:InvokeServer("StartQuest", "BartiloQuest", 1) end)
            collectgarbage("step", 50) -- Per-cycle GC
            task.wait(0.8)

            local initActive, initCur, initMax, initDone = GetSwanPirateQuestState()

            -- NẾU SAU KHI LẤY QUEST MÀ KHÔNG NHẢY RA QUEST SWAN PIRATE (đã làm xong từ trước):
            -- Tự động bỏ qua Bước 2 và chuyển thẳng sang Bước 3 / Bước 4
            if not initActive or initDone then
                UILib.Notify("Bartilo Quest", "Swan Pirates quest already completed or not active! Skipping Step 2...", 3)
            else
                local currentSpotIndex = 1
                local attackY = 18
                local questEverActive = true

                -- Lặp tuần tra 5 mobpos cho đến khi HOÀN THÀNH ĐỦ 50 SWAN PIRATE
                while S.AutoBartiloQuestEnabled do
                    if Utility.HasCompletedBartilo() then 
                        break 
                    end

                    local active, cur, max, done = GetSwanPirateQuestState()

                    -- Điều kiện hoàn thành:
                    -- 1) UI hiển thị 50/50
                    -- 2) Quest đã từng active và giờ biến mất (đã xong 50 con, GUI tự đóng)
                    if done or (active and cur >= 50) or (questEverActive and not active) then
                        UILib.Notify("Bartilo Quest", "50 Swan Pirates defeated! Moving to Step 3...", 3)
                        break
                    end

                    local curSpot = SWAN_PIRATES_SPOTS[currentSpotIndex] or SWAN_PIRATES_SPOTS[1]

                    -- 1. DỊCH CHUYỂN ĐẾN ĐÚNG MOBPOS TRƯỚC
                    Utility.FlyAndWaitArrival(curSpot + Vector3.new(0, attackY, 0), flySpeed, 8, 12)
                    collectgarbage("step", 50) -- Per-cycle GC
                    task.wait(0.15)

                    -- 2. SAU KHI ĐÃ ĐẾN MOBPOS: THỰC HIỆN GOM QUÁI & TẤN CÔNG TẠI BÃI NÀY
                    local spotStartTime = os.clock()
                    local step2Completed = false

                    while S.AutoBartiloQuestEnabled and (os.clock() - spotStartTime < 4.5) do
                        if Utility.HasCompletedBartilo() then break end

                        local a, c, m, d = GetSwanPirateQuestState()
                        if d or (a and c >= 50) or (questEverActive and not a) then
                            step2Completed = true
                            break
                        end

                        local centerPos, mainMob, cluster = Utility.BringMatchingMobs("Swan Pirate", S.BringMobDistance or 400)
                        if centerPos and mainMob and #cluster > 0 then
                            local _, _, mRoot = Utility.GetEnemyRootCFrame(mainMob)
                            if mRoot then
                                local targetFlyPos = (S.BringMobEnabled and centerPos or mRoot.Position) + Vector3.new(0, attackY, 0)
                                Utility.PhysicsFlyTo(targetFlyPos, flySpeed)
                                AttackTarget(mainMob, mRoot, cluster)
                            end
                        else
                            Utility.CleanupBringMobMovers()
                            DisconnectConnection("bringMobStepped")
                            currentBringData = nil
                            if CTX then CTX.currentBringData = nil end
                            -- Đã dọn sạch quái ở bãi này, dừng đánh sớm để chuyển sang bãi tiếp theo
                            Utility.PhysicsFlyTo(curSpot + Vector3.new(0, attackY, 0), flySpeed)
                            if os.clock() - spotStartTime >= 1.5 then
                                break
                            end
                        end
                        collectgarbage("step", 50) -- Per-cycle GC
                        task.wait(0.035)
                    end

                    if step2Completed then
                        UILib.Notify("Bartilo Quest", "50 Swan Pirates defeated! Moving to Step 3...", 3)
                        break
                    end

                    -- Chuyển sang mobpos tiếp theo
                    currentSpotIndex = (currentSpotIndex % #SWAN_PIRATES_SPOTS) + 1
                    task.wait(0.05)
                end
            end

            -- ═══════════════════════════════════════════════════════════
            -- BƯỚC 3: Bay đến -459, 73, 302, kích hoạt BartiloQuestProgress
            -- ═══════════════════════════════════════════════════════════
            if not S.AutoBartiloQuestEnabled or Utility.HasCompletedBartilo() then break end
            TalkToBartilo()

            -- ═══════════════════════════════════════════════════════════
            -- BƯỚC 4: Bay đến 2196, 449, 713, tấn công mục tiêu Jeremy
            -- ═══════════════════════════════════════════════════════════
            if not S.AutoBartiloQuestEnabled or Utility.HasCompletedBartilo() then break end
            UILib.Notify("Bartilo Quest", "Step 4: Defeating Boss Jeremy...", 4)
            Utility.FlyAndWaitArrival(JEREMY_POS + Vector3.new(0, 18, 0), flySpeed, 35, 10)

            local jeremyEngaged = false
            local jeremyDefeated = false

            while S.AutoBartiloQuestEnabled do
                if Utility.HasCompletedBartilo() then 
                    break 
                end

                local jeremyMob = Utility.GetEnemyByName("Jeremy") 
                    or (workspace:FindFirstChild("Enemies") and workspace.Enemies:FindFirstChild("Jeremy")) 
                    or workspace:FindFirstChild("Jeremy")

                if jeremyMob and jeremyMob.Parent then
                    local hum = jeremyMob:FindFirstChildOfClass("Humanoid")
                    local root = jeremyMob:FindFirstChild("HumanoidRootPart") or jeremyMob.PrimaryPart or jeremyMob:FindFirstChildOfClass("BasePart")
                    if hum and hum.Health > 0 and root then
                        jeremyEngaged = true
                        Utility.PhysicsFlyTo(root.Position + Vector3.new(0, 18, 0), flySpeed)
                        AttackTarget(jeremyMob, root)
                    else
                        if jeremyEngaged then
                            jeremyDefeated = true
                            break
                        end
                        Utility.PhysicsFlyTo(JEREMY_POS + Vector3.new(0, 18, 0), flySpeed)
                    end
                else
                    if jeremyEngaged then
                        jeremyDefeated = true
                        break
                    end
                    Utility.PhysicsFlyTo(JEREMY_POS + Vector3.new(0, 18, 0), flySpeed)
                end
                collectgarbage("step", 50) -- Per-cycle GC
                task.wait(0.035)
            end

            if jeremyDefeated then
                UILib.Notify("Bartilo Quest", "Boss Jeremy defeated! Moving to Step 5...", 3)
            end

            -- ═══════════════════════════════════════════════════════════
            -- BƯỚC 5: Bay đến -459, 73, 302, kích hoạt BartiloQuestProgress
            -- ═══════════════════════════════════════════════════════════
            if not S.AutoBartiloQuestEnabled or Utility.HasCompletedBartilo() then break end
            TalkToBartilo()

            -- ═══════════════════════════════════════════════════════════
            -- BƯỚC 6: Bay đến -1834, 10, 1692, CFrame teleport Plate 1 -> 8 (3 lần, cách nhau 0.1s)
            -- ═══════════════════════════════════════════════════════════
            if not S.AutoBartiloQuestEnabled or Utility.HasCompletedBartilo() then break end
            UILib.Notify("Bartilo Quest", "Step 6: Flying to Colosseum...", 3)
            Utility.FlyAndWaitArrival(COLOSSEUM_POS, flySpeed, 35, 10)
            Utility.StopPhysicsFly()
            task.wait(0.2)

            UILib.Notify("Bartilo Quest", "Step 6: CFrame Teleporting Plates 1 -> 8 (3 Rounds)...", 4)
            local mapFolder = workspace:FindFirstChild("Map")
            local dressrosa = mapFolder and mapFolder:FindFirstChild("Dressrosa")
            local platesFolder = dressrosa and dressrosa:FindFirstChild("BartiloPlates")

            for round = 1, 3 do
                if not S.AutoBartiloQuestEnabled or Utility.HasCompletedBartilo() then break end
                for plateIndex = 1, 8 do
                    if not S.AutoBartiloQuestEnabled then break end
                    local plateName = "Plate" .. tostring(plateIndex)
                    local plate = (platesFolder and platesFolder:FindFirstChild(plateName)) or workspace:FindFirstChild(plateName, true)
                    if plate then
                        local platePos = plate:IsA("BasePart") and plate.Position 
                            or (plate.PrimaryPart and plate.PrimaryPart.Position) 
                            or (plate:IsA("Model") and plate:GetPivot().Position)
                        if platePos then
                            pcall(function()
                                local char = LocalPlayer.Character
                                local r = char and char:FindFirstChild("HumanoidRootPart")
                                if r then
                                    r.CFrame = CFrame.new(platePos + Vector3.new(0, 1.2, 0))
                                end
                            end)
                        end
                    end
                    task.wait(0.1)
                end
                task.wait(0.1)
            end

            task.wait(0.3)

            -- ═══════════════════════════════════════════════════════════
            -- BƯỚC 7: Bay đến -459, 73, 302, kích hoạt BartiloQuestProgress
            -- ═══════════════════════════════════════════════════════════
            if not S.AutoBartiloQuestEnabled then break end
            TalkToBartilo()
            task.wait(1)

            -- Final verification: Check if Warrior Helmet is owned OR CellDoor opened
            if Utility.HasCompletedBartilo() then
                Utility.StopPhysicsFly()
                S.AutoBartiloQuestEnabled = false
                task.spawn(function()
                    task.wait(0.05)
                    if UI_ELEMENTS["AutoBartiloQuestEnabled"] and UI_ELEMENTS["AutoBartiloQuestEnabled"].Set then
                        UI_ELEMENTS["AutoBartiloQuestEnabled"]:Set(false)
                    end
                end)
                UILib.Notify("Bartilo Quest", "Bartilo Quest completed successfully! (Warrior Helmet & Cell Door unlocked)", 5)
                break
            else
                UILib.Notify("Bartilo Quest", "Bartilo Quest not fully verified yet. Restarting sequence from Step 1...", 4)
                task.wait(1.5)
            end
        end

        Utility.StopPhysicsFly()
        _conns["bartiloQuest"] = nil
        bartiloRunning = false
    end)
end

--[[ Stop Auto Bartilo Quest ]]
function Utility.StopAutoBartiloQuest()
    S.AutoBartiloQuestEnabled = false
    DisconnectConnection("bartiloQuest")
    Utility.CleanupBringMobMovers()
    DisconnectConnection("bringMobStepped")
    currentBringData = nil
    if CTX then CTX.currentBringData = nil end
    bartiloRunning = false
    Utility.StopPhysicsFly()
end



-- ╔══════════════════════════════════════════════════════════╗


-- ========================================================
-- [SECTION: PROGRESSION QUESTS & AWAKENING]
-- ========================================================
-- ║         [SECTION 4.7] AUTO DON SWAN QUEST / PUZZLE       ║
-- ╚══════════════════════════════════════════════════════════╝

local FRUIT_PRICES = {
    ["Quake-Quake"]         = 1000000,
    ["Buddha-Buddha"]       = 1200000,
    ["Love-Love"]           = 1300000,
    ["Spider-Spider"]       = 1500000,
    ["Sound-Sound"]         = 1700000,
    ["Phoenix-Phoenix"]     = 1800000,
    ["Portal-Portal"]       = 1900000,
    ["Lightning-Lightning"] = 2100000,
    ["Pain-Pain"]           = 2300000,
    ["Blizzard-Blizzard"]   = 2400000,
    ["Gravity-Gravity"]     = 2500000,
    ["Mammoth-Mammoth"]     = 2700000,
    ["T-Rex-T-Rex"]         = 2700000,
    ["Dough-Dough"]         = 2800000,
    ["Shadow-Shadow"]       = 2900000,
    ["Venom-Venom"]         = 3000000,
    ["Gas-Gas"]             = 3200000,
    ["Control-Control"]     = 3200000,
    ["Spirit-Spirit"]       = 3400000,
    ["Dragon-Dragon"]       = 3500000,
    ["Tiger-Tiger"]         = 5000000,
    ["Yeti-Yeti"]           = 5000000,
    ["Kitsune-Kitsune"]     = 8000000,
}


function Utility.HasSwanGlasses()
    return Utility.CheckAccessoryInventory("Swan Glasses")
end

function Utility.IsTrevorUnlocked()
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if not commF then return false end
    local res = nil
    pcall(function()
        res = commF:InvokeServer("TalkTrevor", "1")
    end)
    return res == 0
end

--[[ Helper: Check if a tool is a Fruit and whether its price >= 1,000,000 ]]
function Utility.GetFruitTool1MStatus(tool)
    if not tool or not tool:IsA("Tool") or not Utility.IsFruitTool(tool) then
        return false, nil, 0
    end
    local orig = tool:GetAttribute("OriginalName")
    if not orig or orig == "" then
        orig = Utility.GetFruitInternalName(tool.Name)
    end
    if orig and FRUIT_PRICES[orig] and FRUIT_PRICES[orig] >= 1000000 then
        return true, orig, FRUIT_PRICES[orig]
    end
    local toolNameLower = tool.Name:lower()
    for fName, price in pairs(FRUIT_PRICES) do
        local raw = fName:gsub("%-.*", ""):lower()
        if toolNameLower:find(raw, 1, true) then
            return true, fName, price
        end
    end
    return false, orig or tool.Name, 0
end

-- Danh sách trái 1M+ sắp xếp tăng dần theo giá trị (Duyệt từ dưới lên để tối ưu fruit value, bảo vệ trái xịn)
local ONE_MILLION_FRUITS_ASCENDING = {
    { Internal = "Quake-Quake",         Price = 1000000, Display = "Quake",   Aliases = {"Quake-Quake"} },
    { Internal = "Buddha-Buddha",       Price = 1200000, Display = "Buddha",  Aliases = {"Buddha-Buddha"} },
    { Internal = "Love-Love",           Price = 1300000, Display = "Love",    Aliases = {"Love-Love"} },
    { Internal = "Spider-Spider",       Price = 1500000, Display = "Spider",  Aliases = {"Spider-Spider", "String-String"} },
    { Internal = "Sound-Sound",         Price = 1700000, Display = "Sound",   Aliases = {"Sound-Sound"} },
    { Internal = "Phoenix-Phoenix",     Price = 1800000, Display = "Phoenix", Aliases = {"Phoenix-Phoenix"} },
    { Internal = "Portal-Portal",       Price = 1900000, Display = "Portal",  Aliases = {"Portal-Portal", "Door-Door"} },
    { Internal = "Lightning-Lightning", Price = 2100000, Display = "Rumble",  Aliases = {"Lightning-Lightning", "Rumble-Rumble"} },
    { Internal = "Pain-Pain",           Price = 2300000, Display = "Pain",    Aliases = {"Pain-Pain", "Paw-Paw"} },
    { Internal = "Blizzard-Blizzard",   Price = 2400000, Display = "Blizzard",Aliases = {"Blizzard-Blizzard"} },
    { Internal = "Gravity-Gravity",     Price = 2500000, Display = "Gravity", Aliases = {"Gravity-Gravity"} },
    { Internal = "Mammoth-Mammoth",     Price = 2700000, Display = "Mammoth", Aliases = {"Mammoth-Mammoth"} },
    { Internal = "T-Rex-T-Rex",         Price = 2700000, Display = "T-Rex",   Aliases = {"T-Rex-T-Rex"} },
    { Internal = "Dough-Dough",         Price = 2800000, Display = "Dough",   Aliases = {"Dough-Dough"} },
    { Internal = "Shadow-Shadow",       Price = 2900000, Display = "Shadow",  Aliases = {"Shadow-Shadow"} },
    { Internal = "Venom-Venom",         Price = 3000000, Display = "Venom",   Aliases = {"Venom-Venom"} },
    { Internal = "Gas-Gas",             Price = 3200000, Display = "Gas",     Aliases = {"Gas-Gas"} },
    { Internal = "Control-Control",     Price = 3200000, Display = "Control", Aliases = {"Control-Control"} },
    { Internal = "Spirit-Spirit",       Price = 3400000, Display = "Spirit",  Aliases = {"Spirit-Spirit"} },
    { Internal = "Dragon-Dragon",       Price = 3500000, Display = "Dragon",  Aliases = {"Dragon-Dragon"} },
    { Internal = "Tiger-Tiger",         Price = 5000000, Display = "Leopard", Aliases = {"Tiger-Tiger", "Leopard-Leopard"} },
    { Internal = "Yeti-Yeti",           Price = 5000000, Display = "Yeti",    Aliases = {"Yeti-Yeti"} },
    { Internal = "Kitsune-Kitsune",     Price = 8000000, Display = "Kitsune", Aliases = {"Kitsune-Kitsune"} },
}

--[[ Gọi trực tiếp hàm lấy fruit từ kho đồ của Blox Fruit ("LoadFruit"), duyệt từ dưới lên để tối ưu fruit value ]]
function Utility.RetrieveBest1MFruitFromStorage()
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if not commF then return nil end

    -- 1. Kiểm tra trên người (Backpack & Character) hiện tại có trái 1M+ nào sẵn chưa
    local heldFruits = Utility.FindFruitTools()
    for _, tool in ipairs(heldFruits) do
        local is1M, fName, price = Utility.GetFruitTool1MStatus(tool)
        if is1M then
            return tool, fName, price
        end
    end

    -- 2. Nếu đang cầm trái dưới 1M: dùng cơ chế respawn (như lúc mua thuyền) để giải phóng trái rác
    local hasUnder1M = false
    local junkName = nil
    for _, tool in ipairs(heldFruits) do
        local is1M = Utility.GetFruitTool1MStatus(tool)
        if not is1M then
            hasUnder1M = true
            junkName = tool.Name
            break
        end
    end

    if hasUnder1M then
        UILib.Notify("Don Swan Quest", "Holding fruit under 1M (" .. tostring(junkName) .. "). Respawning...", 3)
        Utility.RespawnPlayer()
        task.wait(3.0)
    end

    -- 3. Quét lại sau respawn xem đã có trái 1M+ chưa
    heldFruits = Utility.FindFruitTools()
    for _, tool in ipairs(heldFruits) do
        local is1M, fName, price = Utility.GetFruitTool1MStatus(tool)
        if is1M then
            return tool, fName, price
        end
    end

    -- 4. Gọi trực tiếp hàm lấy fruit từ kho đồ, duyệt từ dưới lên (cheapest 1M+ fruit first)
    UILib.Notify("Don Swan Quest", "Checking fruit storage directly (cheapest 1M+ first)...", 3)
    for _, fInfo in ipairs(ONE_MILLION_FRUITS_ASCENDING) do
        local namesToTry = fInfo.Aliases or { fInfo.Internal }
        for _, tryName in ipairs(namesToTry) do
            pcall(function()
                commF:InvokeServer("LoadFruit", tryName)
            end)
            task.wait(0.35)

            -- Kiểm tra xem Tool trái ác quỷ đã xuất hiện trong Backpack hoặc Character chưa
            local currentFruits = Utility.FindFruitTools()
            for _, tool in ipairs(currentFruits) do
                local is1M, fName, price = Utility.GetFruitTool1MStatus(tool)
                if is1M then
                    UILib.Notify("Don Swan Quest", "Retrieved " .. tostring(fInfo.Display) .. " ($" .. tostring(fInfo.Price) .. ") from storage!", 3.5)
                    return tool, fName, price
                end
            end
        end
    end

    -- Đã duyệt hết danh sách trái 1M+ từ dưới lên mà không có trái nào trong kho
    return nil
end

-- Helper tương thích ngược nếu có module gọi GetBest1MStoredFruitOnly / GetBest1MStoredFruit
function Utility.GetBest1MStoredFruitOnly()
    local tool, fName, price = Utility.RetrieveBest1MFruitFromStorage()
    if tool then
        return { Internal = fName or tool.Name, Price = price or 1000000, Tool = tool }
    end
    return nil
end

function Utility.GetBest1MStoredFruit()
    local tool, fName, price = Utility.RetrieveBest1MFruitFromStorage()
    if tool then
        return { Internal = fName or tool.Name, Tool = tool, Price = price or 1000000, InHand = true }
    end
    return nil
end

--[[ Helper: Kiểm tra chính xác trong Workspace._WorldOrigin.EnemySpawns xem có "Don Swan [Lv. 1000] [Boss]" không ]]
function Utility.IsDonSwanSpawnAvailable()
    local folder = Utility.GetWorldOriginEnemySpawnsFolder()
    if not folder then return false end
    return folder:FindFirstChild("Don Swan [Lv. 1000] [Boss]") ~= nil
end

function Utility.CanDoDonSwanQuest()
    if Utility.GetCurrentSea() ~= 2 then return false end
    local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
    if pLevel < 1000 then return false end

    -- Kiểm tra kho accessory xem đã có "Swan Glasses" chưa
    if Utility.CheckAccessoryInventory("Swan Glasses") then
        if S.AutoDonSwanQuestEnabled then
            S.AutoDonSwanQuestEnabled = false
            task.spawn(function()
                task.wait(0.05)
                if UI_ELEMENTS["AutoDonSwanQuestEnabled"] and UI_ELEMENTS["AutoDonSwanQuestEnabled"].Set then
                    UI_ELEMENTS["AutoDonSwanQuestEnabled"]:Set(false)
                end
            end)
            UILib.Notify("Don Swan Quest", "Swan Glasses already owned in accessory inventory! Disabling quest.", 4)
        end
        return false
    end

    -- Nếu cửa Trevor đã mở: người chơi đã mở khóa, CHỈ CHẠY khi boss Don Swan đã xuất hiện!
    -- Kiểm tra từ xa trong Workspace._WorldOrigin.EnemySpawns xem có đúng chính tả "Don Swan [Lv. 1000] [Boss]" không!
    if Utility.IsTrevorUnlocked() then
        -- 1. Kiểm tra trong EnemySpawns xem có Part spawn chính xác "Don Swan [Lv. 1000] [Boss]" không
        if Utility.IsDonSwanSpawnAvailable() then
            return true
        end

        -- 2. Hoặc nếu nhân vật đang ở gần phòng và boss đã render trong Workspace.Enemies với tên "Don Swan"
        local en = workspace:FindFirstChild("Enemies")
        if en then
            for _, child in ipairs(en:GetChildren()) do
                if child:IsA("Model") and (child.Name == "Don Swan" or child.Name:lower():find("don swan")) then
                    local hum = child:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        return true
                    end
                end
            end
        end

        -- Boss chưa xuất hiện ở cả EnemySpawns lẫn Enemies -> Trả về false để nhường luồng 100% cho Farm Level!
        return false
    end

    -- Nếu cửa Trevor chưa mở:
    -- Nếu người chơi đã có sẵn trái 1M+ trên người: sẵn sàng làm quest
    local heldFruits = Utility.FindFruitTools()
    for _, tool in ipairs(heldFruits) do
        local is1M = Utility.GetFruitTool1MStatus(tool)
        if is1M then return true end
    end

    -- Nếu toggle AutoDonSwanQuestEnabled đang bật: cho phép pipeline chạy HandleDonSwanQuest
    -- để trực tiếp lấy trái 1M+ từ kho đồ (nếu kho không có thì hàm sẽ tắt toggle và thông báo)
    if S.AutoDonSwanQuestEnabled then
        return true
    end

    return false
end

local donSwanRunning = false
function Utility.HandleDonSwanQuest(forceRun)
    -- 0. Kiểm tra kho accessory xem đã có "Swan Glasses" chưa (nếu forceRun từ Sea 3 thì không bỏ qua vì Sea 3 bắt buộc phải hạ Don Swan)
    if not forceRun and Utility.CheckAccessoryInventory("Swan Glasses") then
        S.AutoDonSwanQuestEnabled = false
        task.spawn(function()
            task.wait(0.05)
            if UI_ELEMENTS["AutoDonSwanQuestEnabled"] and UI_ELEMENTS["AutoDonSwanQuestEnabled"].Set then
                UI_ELEMENTS["AutoDonSwanQuestEnabled"]:Set(false)
            end
        end)
        UILib.Notify("Don Swan Quest", "Swan Glasses already owned in accessory inventory! Disabling quest.", 4)
        return false
    end

    if donSwanRunning then return false end
    if not S.AutoDonSwanQuestEnabled and not forceRun then return false end
    if Utility.GetCurrentSea() ~= 2 then return false end
    local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
    if pLevel < 1000 then return false end

    donSwanRunning = true
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if not commF then donSwanRunning = false; return false end

    local flySpeed = S.TeleportFlySpeed or 200

    -- ═══════════════════════════════════════════════════════════
    -- BƯỚC 1: KIỂM TRA MỞ CỬA BIỆT THỰ TREVOR NẾU CHƯA MỞ
    -- ═══════════════════════════════════════════════════════════
    if not Utility.IsTrevorUnlocked() then
        -- Gọi trực tiếp hàm lấy fruit từ kho đồ, duyệt từ dưới lên để tối ưu fruit value
        local fruit1MTool, fruitName, fruitPrice = Utility.RetrieveBest1MFruitFromStorage()

        -- NẾU KHÔNG LẤY ĐƯỢC -> MỚI KHÔNG LÀM QUEST!
        if not fruit1MTool or not fruit1MTool.Parent then
            UILib.Notify("Don Swan Quest", "No 1M+ fruit available in storage! Skipping quest.", 4)
            if not forceRun then
                S.AutoDonSwanQuestEnabled = false
                task.spawn(function()
                    task.wait(0.05)
                    if UI_ELEMENTS["AutoDonSwanQuestEnabled"] and UI_ELEMENTS["AutoDonSwanQuestEnabled"].Set then
                        UI_ELEMENTS["AutoDonSwanQuestEnabled"]:Set(false)
                    end
                end)
            end
            donSwanRunning = false
            return false
        end

        -- ═══════════════════════════════════════════════════════════
        -- ĐÃ LẤY ĐƯỢC TRÁI 1M+ -> THỰC HIỆN CÁC BƯỚC PUZZLE CỦA QUEST DON SWAN
        -- ═══════════════════════════════════════════════════════════
        UILib.Notify("Don Swan Quest", "1M+ fruit ready (" .. tostring(fruit1MTool.Name) .. ")! Flying to Trevor Mansion...", 4)
        Utility.FlyAndWaitArrival(Vector3.new(-333, 332, 645), flySpeed, 25, 10)
        task.wait(0.5)

        -- Trang bị trái 1M+ lên tay nhân vật
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if fruit1MTool and hum then
            hum:EquipTool(fruit1MTool)
            task.wait(0.5)
        end

        -- Kích hoạt remote đối thoại với Trevor để nộp trái 1M+ và mở cửa
        UILib.Notify("Don Swan Quest", "Talking to Trevor with 1M+ fruit to unlock Mansion...", 3)
        pcall(function() commF:InvokeServer("TalkTrevor", "1") end)
        task.wait(0.4)
        pcall(function() commF:InvokeServer("TalkTrevor", "2") end)
        task.wait(0.4)
        pcall(function() commF:InvokeServer("TalkTrevor", "3") end)
        task.wait(0.8)

        if not Utility.IsTrevorUnlocked() then
            task.wait(0.5)
            pcall(function() commF:InvokeServer("TalkTrevor", "1") end)
            task.wait(0.4)
            pcall(function() commF:InvokeServer("TalkTrevor", "2") end)
            task.wait(0.4)
            pcall(function() commF:InvokeServer("TalkTrevor", "3") end)
            task.wait(0.8)
        end

        if Utility.IsTrevorUnlocked() then
            UILib.Notify("Don Swan Quest", "Trevor accepted 1M+ fruit! Mansion door is OPEN!", 4)
        else
            UILib.Notify("Don Swan Quest", "Trevor dialogue finished. Checking Don Swan chamber...", 3)
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- BƯỚC 2: BAY ĐẾN VỊ TRÍ DON SWAN VÀ TIÊU DIỆT BOSS
    -- ═══════════════════════════════════════════════════════════
    -- Kiểm tra chính xác trong Workspace._WorldOrigin.EnemySpawns xem có "Don Swan [Lv. 1000] [Boss]" không
    local hasSwanSpawn = Utility.IsDonSwanSpawnAvailable()

    local function findDonSwan()
        local en = workspace:FindFirstChild("Enemies")
        if en then
            for _, child in ipairs(en:GetChildren()) do
                if child:IsA("Model") and (child.Name == "Don Swan" or child.Name:lower():find("don swan")) then
                    local hum = child:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then return child end
                end
            end
        end
        return nil
    end

    local donSwan = findDonSwan()

    -- Nếu cả trong EnemySpawns lẫn Enemies đều không có boss -> Không bay đi, nhường luồng cho farm level
    if not hasSwanSpawn and not donSwan then
        UILib.Notify("Don Swan Quest", "Don Swan not in EnemySpawns, resuming farm level...", 3)
        donSwanRunning = false
        return false
    end

    local dsSpawnCF, dsSpawnPos = Utility.GetEnemySpawnCFrame("Don Swan [Lv. 1000] [Boss]")
    if not dsSpawnPos then
        dsSpawnCF, dsSpawnPos = Utility.GetEnemySpawnCFrame("Don Swan")
    end
    if not dsSpawnPos then
        dsSpawnPos = Vector3.new(2284.4, 15.2, 860.5)
    end

    -- Đã xác nhận có boss trong EnemySpawns: Bay đến chamber để nạp và tấn công boss!
    UILib.Notify("Don Swan Quest", "Don Swan detected in EnemySpawns! Flying to chamber...", 3)
    Utility.FlyAndWaitArrival(dsSpawnPos + Vector3.new(0, S.AttackHeight or 20, 0), flySpeed, 30, 8)
    task.wait(1.0)

    -- Sau khi bay đến chamber: quét trong thư mục Workspace/Enemies tìm đúng "Don Swan" để tấn công
    donSwan = findDonSwan()
    if not donSwan then
        UILib.Notify("Don Swan Quest", "Don Swan not spawned in chamber, resuming farm level...", 3)
        donSwanRunning = false
        return false
    end

    -- Boss Don Swan tồn tại: tấn công boss!
    UILib.Notify("Don Swan Quest", "Don Swan boss found! Engaging boss...", 4)

    local t0 = os.clock()
    while S.AutoDonSwanQuestEnabled and (os.clock() - t0 < 90) do
        if Utility.HasSwanGlasses() then
            break
        end

        donSwan = findDonSwan()
        if not donSwan then
            break
        end

        local _, _, dsRoot = Utility.GetEnemyRootCFrame(donSwan)
        if dsRoot then
            Utility.FlyAboveTarget(dsRoot.CFrame, S.AttackHeight or 20, flySpeed)
            local wType = S.SelectedWeaponType or "Melee"
            if wType == "Melee" then Utility.AttackMelee(donSwan, dsRoot)
            elseif wType == "Sword" then Utility.AttackSword(donSwan, dsRoot)
            elseif wType == "Fruit" then Utility.AttackFruitM1(donSwan, dsRoot)
            elseif wType == "Gun" then Utility.AttackGun(donSwan, dsRoot)
            end

            if S.AutoFarmUseSkills then
                if wType == "Melee" then Utility.CastSkillsMelee(dsRoot.Position, donSwan)
                elseif wType == "Fruit" then Utility.CastSkillsFruit(dsRoot.Position, donSwan)
                elseif wType == "Sword" then Utility.CastSkillsSword(dsRoot.Position, donSwan)
                elseif wType == "Gun" then Utility.CastSkillsGun(dsRoot.Position, donSwan)
                end
            end
        else
            collectgarbage("step", 50) -- Per-cycle GC
            task.wait(0.1)
        end
        task.wait(0.04)
    end

    Utility.StopPhysicsFly()

    -- Kiểm tra lại kho phụ kiện sau khi boss chết
    if Utility.HasSwanGlasses() then
        S.AutoDonSwanQuestEnabled = false
        task.spawn(function()
            task.wait(0.05)
            if UI_ELEMENTS["AutoDonSwanQuestEnabled"] and UI_ELEMENTS["AutoDonSwanQuestEnabled"].Set then
                UI_ELEMENTS["AutoDonSwanQuestEnabled"]:Set(false)
            end
        end)
        UILib.Notify("Don Swan Quest", "Swan Glasses acquired! Quest complete!", 5)
    end

    donSwanRunning = false
    return true
end

function Utility.StopAutoDonSwanQuest()
    S.AutoDonSwanQuestEnabled = false
    DisconnectConnection("donSwanQuest")
    donSwanRunning = false
    Utility.StopPhysicsFly()
end



-- ╔══════════════════════════════════════════════════════════╗
-- ║       [SECTION 4.8] _WORLDORIGIN ENEMY SPAWNS UTILITY    ║
-- ╚══════════════════════════════════════════════════════════╝


function Utility.GetWorldOriginEnemySpawnsFolder()
    local wo = workspace:FindFirstChild("_WorldOrigin")
    if not wo then return nil end
    return wo:FindFirstChild("EnemySpawns")
end

function Utility.GetEnemySpawnsList()
    local folder = Utility.GetWorldOriginEnemySpawnsFolder()
    local list = {}
    local seen = {}
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            local name = child.Name
            if not seen[name] then
                seen[name] = true
                table.insert(list, name)
            end
        end
    end
    table.sort(list)
    if #list == 0 then
        table.insert(list, "No Spawns Found")
    end
    return list
end

--[[ Get primary spawn position for enemy with strict exact name matching ]]
function Utility.GetEnemySpawnCFrame(spawnName)
    if not spawnName or spawnName == "" or spawnName == "No Spawns Found" then return nil, nil end
    local folder = Utility.GetWorldOriginEnemySpawnsFolder()
    if not folder then return nil, nil end

    -- 1. Exact direct match first
    for _, child in ipairs(folder:GetChildren()) do
        if child.Name == spawnName then
            if child:IsA("BasePart") then
                return child.CFrame, child.Position
            elseif child:IsA("Model") then
                local cf = (child.PrimaryPart and child.PrimaryPart.CFrame) or child:GetPivot()
                return cf, cf.Position
            end
        end
    end

    -- 2. Strict normalized match
    local normTarget = Utility.NormalizeMobString(spawnName)
    for _, child in ipairs(folder:GetChildren()) do
        if Utility.NormalizeMobString(child.Name) == normTarget then
            if child:IsA("BasePart") then
                return child.CFrame, child.Position
            elseif child:IsA("Model") then
                local cf = (child.PrimaryPart and child.PrimaryPart.CFrame) or child:GetPivot()
                return cf, cf.Position
            end
        end
    end

    return nil, nil
end

--[[ Get all spawn points for a mob in _WorldOrigin.EnemySpawns with strict exact matching ]]
function Utility.GetAllEnemySpawnsByMob(mobName)
    local spawns = {}
    local folder = Utility.GetWorldOriginEnemySpawnsFolder()
    if not folder or not mobName or mobName == "" then return spawns end
    local normTarget = Utility.NormalizeMobString(mobName)

    for _, child in ipairs(folder:GetChildren()) do
        local normChild = Utility.NormalizeMobString(child.Name)
        if normChild == normTarget then
            local cf = nil
            local pos = nil
            if child:IsA("BasePart") then
                cf = child.CFrame
                pos = child.Position
            elseif child:IsA("Model") then
                cf = (child.PrimaryPart and child.PrimaryPart.CFrame) or child:GetPivot()
                pos = cf.Position
            end
            if pos then
                table.insert(spawns, { CFrame = cf or CFrame.new(pos), Position = pos, Object = child, Name = child.Name })
            end
        end
    end
    return spawns
end

local mobPatrolState = {
    mobName = "",
    index = 1,
    lastTime = 0,
    lastArrival = 0,
    arrived = false,
    spawns = {},
    pauseFlightUntil = 0,
}

function Utility.GetLevelFarmTargetSpawn(mobName, fallbackPos, qData)
    local now = os.clock()
    if mobPatrolState.mobName ~= mobName then
        mobPatrolState.mobName = mobName
        local sps = Utility.GetAllEnemySpawnsByMob(mobName)
        if (not sps or #sps == 0) and qData and qData.SpawnPoints and #qData.SpawnPoints > 0 then
            sps = {}
            for _, pt in ipairs(qData.SpawnPoints) do
                table.insert(sps, { Position = pt, CFrame = CFrame.new(pt) })
            end
        end
        mobPatrolState.spawns = sps
        mobPatrolState.index = 1
        mobPatrolState.lastTime = now
        mobPatrolState.arrived = false
        mobPatrolState.lastArrival = 0
        mobPatrolState.forcePatrolUntil = 0
    end

    local spawns = mobPatrolState.spawns
    if not spawns or #spawns == 0 then
        local sps = Utility.GetAllEnemySpawnsByMob(mobName)
        if (not sps or #sps == 0) and qData and qData.SpawnPoints and #qData.SpawnPoints > 0 then
            sps = {}
            for _, pt in ipairs(qData.SpawnPoints) do
                table.insert(sps, { Position = pt, CFrame = CFrame.new(pt) })
            end
        end
        mobPatrolState.spawns = sps
        spawns = mobPatrolState.spawns
    end

    if spawns and #spawns > 0 then
        if mobPatrolState.index > #spawns or mobPatrolState.index < 1 then
            mobPatrolState.index = 1
        end
        local currentSpawn = spawns[mobPatrolState.index]
        local currentPos = (typeof(currentSpawn) == "table" and currentSpawn.Position) or currentSpawn or fallbackPos or Vector3.zero
        return currentPos, spawns, mobPatrolState
    end

    if qData and qData.SpawnPoints and #qData.SpawnPoints > 0 then
        local pts = {}
        for _, pt in ipairs(qData.SpawnPoints) do
            table.insert(pts, { Position = pt, CFrame = CFrame.new(pt) })
        end
        mobPatrolState.spawns = pts
        return pts[1].Position, pts, mobPatrolState
    end

    return fallbackPos or Vector3.zero, {}, mobPatrolState
end

function Utility.GetNextMobPatrolPosition(mobName, fallbackPos)
    local targetPos, _, _ = Utility.GetLevelFarmTargetSpawn(mobName, fallbackPos)
    return targetPos
end

function Utility.FlyToEnemySpawn(spawnName, onArrival)
    local cf, pos = Utility.GetEnemySpawnCFrame(spawnName)
    if not cf or not pos then
        UILib.Notify("Testing", "Spawn point not found: " .. tostring(spawnName), 4)
        return false
    end

    local flySpeed = S.TeleportFlySpeed or 200
    local targetCF = cf + Vector3.new(0, S.AttackHeight or 20, 0)

    UILib.Notify("Testing", "✈️ Flying to spawn: " .. tostring(spawnName) .. "...", 3)
    Utility.PhysicsFlyTo(targetCF, flySpeed, function()
        UILib.Notify("Testing", "Arrived at " .. tostring(spawnName) .. "!", 3)
        if onArrival then onArrival() end
    end)
    return true
end

--[[ Auto Next Sea 2 -> Sea 3 (Level 1500+): Direct Travel Check -> Fallback to ZQuest (rip_indra) ]]
local sea3QuestRunning = false

function Utility.HandleSea3EntranceQuest()
    if sea3QuestRunning or Utility.GetCurrentSea() >= 3 then return end

    -- BƯỚC 1: XÁC ĐỊNH CÁC ĐIỀU KIỆN CẦN
    local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
    if pLevel < 1500 or Utility.GetCurrentSea() ~= 2 then return end

    sea3QuestRunning = true
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
        if not commF then sea3QuestRunning = false; return end

        local flySpeed = S.TeleportFlySpeed or 200

        -- ═══════════════════════════════════════════════════════════
        -- [ĐIỀU KIỆN 1]: THỬ TRỰC TIẾP DỊCH CHUYỂN SANG SEA 3 BẰNG REMOTE TRAVELZOU
        -- ═══════════════════════════════════════════════════════════
        UILib.Notify("Auto Next Sea", "Attempting direct teleport to Sea 3 (TravelZou)...", 4)
        
        pcall(function()
            commF:InvokeServer("TravelZou")
        end)
        task.wait(2.0)

        -- Kiểm tra xem có đang THỰC SỰ ở Sea 3 hay không:
        if Utility.GetCurrentSea() >= 3 then
            UILib.Notify("Auto Next Sea", "Already in Third Sea!", 5)
            sea3QuestRunning = false
            return
        end

        -- ═══════════════════════════════════════════════════════════
        -- [ĐIỀU KIỆN 2]: KIỂM TRA ĐIỀU KIỆN TIÊN QUYẾT (BARTILO QUEST)
        -- ═══════════════════════════════════════════════════════════
        if not Utility.CheckAccessoryInventory("Warrior Helmet") and not Utility.HasCompletedBartilo() then
            UILib.Notify("Auto Next Sea", "Bartilo Quest not completed yet! Running Bartilo Quest first...", 5)
            if S.AutoBartiloQuestEnabled then
                Utility.HandleBartiloQuest()
            end
            sea3QuestRunning = false
            return
        end

        -- ═══════════════════════════════════════════════════════════
        -- [ĐIỀU KIỆN 3]: BẮT ĐẦU ZQUEST TẠI COLOSSEUM PRISON
        -- ═══════════════════════════════════════════════════════════
        UILib.Notify("Auto Next Sea", "Flying to Colosseum prison (-1928, 13, 1736)...", 4)
        Utility.FlyAndWaitArrival(Vector3.new(-1928, 13, 1736), flySpeed, 25, 10)
        task.wait(0.5)

        UILib.Notify("Auto Next Sea", "Starting ZQuest Progress (Begin)...", 3)
        pcall(function()
            commF:InvokeServer("ZQuestProgress", "Begin")
        end)
        task.wait(2.5)

        -- KIỂM TRA XEM KING RED HEAD CÓ TỪ CHỐI DO CHƯA ĐÁNH BẠI DON SWAN KHÔNG
        -- Nếu server chấp nhận: nhân vật sẽ được TELEPORT TRỰC TIẾP vào arena đánh rip_indra
        -- Nếu server từ chối: nhân vật VẪN ĐANG ĐỨNG TẠI Colosseum prison!
        local charRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local stillAtPrison = charRoot and (charRoot.Position - Vector3.new(-1928, 13, 1736)).Magnitude < 60

        if stillAtPrison then
            UILib.Notify("Auto Next Sea", "Sea 3 requires defeating Don Swan at least once!", 5)
            UILib.Notify("Auto Next Sea", "Starting Don Swan puzzle & boss fight...", 4)
            sea3QuestRunning = false
            local okSwan = Utility.HandleDonSwanQuest(true)
            if okSwan then
                UILib.Notify("Auto Next Sea", "Don Swan defeated! Returning to King Red Head for Sea 3...", 5)
                task.wait(1)
                Utility.FlyAndWaitArrival(Vector3.new(-1928, 13, 1736), flySpeed, 25, 10)
                task.wait(0.5)
                pcall(function() commF:InvokeServer("ZQuestProgress", "Begin") end)
                task.wait(2.5)
            else
                UILib.Notify("Auto Next Sea", "Please check: Need a 1M+ fruit in bag/storage to unlock Trevor for Don Swan!", 6)
            end
            return
        end

        -- ═══════════════════════════════════════════════════════════
        -- [ĐIỀU KIỆN 4]: ĐÃ ĐƯỢC SERVER TELEPORT VÀO ARENA ĐÁNH RIP_INDRA
        -- Không cần bay thủ công đến đảo indra vì game đã teleport người chơi đến thẳng phòng đấu!
        -- ═══════════════════════════════════════════════════════════
        UILib.Notify("Auto Next Sea", "Teleported to rip_indra arena! Engaging boss...", 4)
        task.wait(1.0)

        local function findRipIndraInEnemies()
            local en = workspace:FindFirstChild("Enemies")
            if en then
                for _, child in ipairs(en:GetChildren()) do
                    if child:IsA("Model") and child.Name:lower():find("rip_indra") then
                        local hum = child:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then return child end
                    end
                end
            end
            return nil
        end

        -- Tấn công tiêu diệt rip_indra ngay trong arena
        local t0 = os.clock()
        while S.AutoNextSeaEnabled and (os.clock() - t0 < 120) do
            local indra = findRipIndraInEnemies()
            if not indra then
                if (os.clock() - t0) > 4 then
                    break
                end
                collectgarbage("step", 50) -- Per-cycle GC
                task.wait(0.5)
            else
                local _, _, inRoot = Utility.GetEnemyRootCFrame(indra)
                if inRoot then
                    Utility.FlyAboveTarget(inRoot.CFrame, S.AttackHeight or 30, flySpeed)
                    local wType = S.SelectedWeaponType or "Melee"
                    if wType == "Melee" then Utility.AttackMelee(indra, inRoot)
                    elseif wType == "Sword" then Utility.AttackSword(indra, inRoot)
                    elseif wType == "Fruit" then Utility.AttackFruitM1(indra, inRoot)
                    elseif wType == "Gun" then Utility.AttackGun(indra, inRoot)
                    end

                    if S.AutoFarmUseSkills then
                        if wType == "Melee" then Utility.CastSkillsMelee(inRoot.Position, indra)
                        elseif wType == "Fruit" then Utility.CastSkillsFruit(inRoot.Position, indra)
                        elseif wType == "Sword" then Utility.CastSkillsSword(inRoot.Position, indra)
                        elseif wType == "Gun" then Utility.CastSkillsGun(inRoot.Position, indra)
                        end
                    end
                end
            end
            task.wait(0.04)
        end

        Utility.StopPhysicsFly()

        -- 2.3 Sau khi hạ rip_indra -> Trực tiếp gọi remote TravelZou dịch chuyển qua Sea 3!
        UILib.Notify("Auto Next Sea", "rip_indra defeated! Teleporting to Sea 3 (TravelZou)...", 5)
        task.wait(1.0)
        pcall(function()
            commF:InvokeServer("TravelZou")
        end)
        task.wait(5)
        sea3QuestRunning = false
    end)
end

--[[ Start Auto Farm Level 1 -> 2550 with Bring Mobs, Auto Quest & Auto Next Sea ]]

--[[ ═══════════════════════════════════════════════════════════════════════════
     MODULAR TASK PROGRESSION PIPELINE & ENGINES
   ═══════════════════════════════════════════════════════════════════════════ ]]

--[[ Helper: Get weapon current Mastery points ]]

function Utility.GetItemMastery(itemName)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local ch = LocalPlayer.Character
    local sources = { ch, bp }
    for _, src in ipairs(sources) do
        if src then
            local tool = src:FindFirstChild(itemName)
            if tool and tool:IsA("Tool") then
                local l = tool:FindFirstChild("Level") or tool:FindFirstChild("Mastery")
                if l and (l:IsA("IntValue") or l:IsA("NumberValue")) then
                    return l.Value
                end
            end
        end
    end
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local mFolder = data:FindFirstChild("Masteries") or data:FindFirstChild("Weapons")
        if mFolder then
            local itemData = mFolder:FindFirstChild(itemName)
            if itemData and itemData:FindFirstChild("Level") then
                return itemData.Level.Value
            end
        end
    end
    return 0
end

--[[ Helper: Find next fighting style in linear progression ladder
     Sequential progression target ]]
function Utility.GetNextLinearUnownedMelee()
    if not S.AutoGetAllMeleesEnabled then return nil end
    local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
    local pFrags = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Fragments") and LocalPlayer.Data.Fragments.Value) or 0
    local curSea = Utility.GetCurrentSea()

    for _, melee in ipairs(MELEE_DATABASE) do
        if not Utility.HasItem(melee.Name) then
            -- First unowned fighting style in progression ladder
            if curSea >= melee.Sea and pBeli >= melee.Price and pFrags >= (melee.Frags or 0) then
                -- Check prerequisite Mastery requirements if applicable
                local meetsMastery = true
                if melee.RequiredMastery then
                    for reqName, reqMas in pairs(melee.RequiredMastery) do
                        if Utility.GetItemMastery(reqName) < reqMas then
                            meetsMastery = false
                            break
                        end
                    end
                end
                if meetsMastery then
                    return melee
                end
            end
            -- If insufficient funds/prerequisites for this target -> Halt, do not skip
            return nil
        end
    end
    return nil
end

local _masteryTargetCache = {
    Melee = { Target = nil, LastCheck = 0 },
    Sword = { Target = nil, LastCheck = 0 },
    Gun   = { Target = nil, LastCheck = 0 },
}

--[[ Backtracking Mastery Farming Algorithm:
     - Prioritizes highest tier owned weapon to grind.
     - When highest reaches 600 -> Backtracks to grind earlier weapons.
]]
function Utility.GetBacktrackingMasteryTarget(wType, maxTargetMastery)
    maxTargetMastery = maxTargetMastery or S.MasteryTargetLevel or 600
    local now = os.clock()
    local c = _masteryTargetCache[wType]
    if c and c.Target and (now - c.LastCheck < 3.0) then
        local curMas = Utility.GetItemMastery(c.Target)
        if curMas < maxTargetMastery then
            return c.Target
        end
    end

    local ladder = nil
    if wType == "Melee" then
        ladder = MELEE_PROGRESSION_LADDER
    elseif wType == "Sword" then
        ladder = SWORD_PROGRESSION_LADDER
    elseif wType == "Gun" then
        ladder = GUN_PROGRESSION_LADDER
    end
    if not ladder then return nil end

    -- 1. Find all weapons the player currently OWNS in the ladder
    local ownedList = {}
    for _, entry in ipairs(ladder) do
        local itemName = typeof(entry) == "table" and entry.Name or entry
        if Utility.HasItem(itemName) then
            local curMas = Utility.GetItemMastery(itemName)
            table.insert(ownedList, { Name = itemName, Mastery = curMas })
        end
    end

    if #ownedList == 0 then
        local unfin, _ = Utility.GetUnfinishedMasteryWeapon(wType, maxTargetMastery)
        if c then c.Target = unfin; c.LastCheck = now end
        return unfin
    end

    -- 2. Highest Tier Owned weapon
    local highestOwned = ownedList[#ownedList]

    -- If highest tier weapon has NOT reached Max Mastery -> Grind with this weapon
    if highestOwned.Mastery < maxTargetMastery then
        if c then c.Target = highestOwned.Name; c.LastCheck = now end
        return highestOwned.Name
    end

    -- 3. IF HIGHEST TIER WEAPON REACHED MAX MASTERY (>= 600):
    -- Backtrack to earlier owned weapons that have not reached max mastery
    for i = #ownedList - 1, 1, -1 do
        local prevItem = ownedList[i]
        if prevItem.Mastery < maxTargetMastery then
            if c then c.Target = prevItem.Name; c.LastCheck = now end
            return prevItem.Name
        end
    end

    if c then c.Target = nil; c.LastCheck = now end
    return nil
end

--[[ Check unowned Swords affordable for remote purchase ]]
function Utility.HasAnyAffordableUnownedSword()
    if not S.AutoGetAllSwordsEnabled then return false end
    local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
    local curSea = Utility.GetCurrentSea()
    for _, sw in ipairs(SWORDS_DATABASE) do
        if not Utility.HasItem(sw.Name) and curSea >= sw.Sea and pBeli >= sw.Price then
            return true
        end
    end
    return false
end

--[[ Purchase all affordable swords in queue ]]
function Utility.BuyAllAffordableSwordsStep()
    if not S.AutoGetAllSwordsEnabled then return false end
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if not commF then return false end

    local curSea = Utility.GetCurrentSea()
    local anyPurchased = false

    for _, sw in ipairs(SWORDS_DATABASE) do
        local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
        if not Utility.HasItem(sw.Name) and curSea >= sw.Sea and pBeli >= sw.Price then
            pcall(function()
                commF:InvokeServer("BuyItem", sw.Name)
            end)
            _locallyOwnedItems[sw.Name] = true
            table.insert(_inventoryCache, sw.Name)
            anyPurchased = true
            UILib.Notify("Auto Buy Sword", "Purchased Sword: " .. sw.Name, 2)
            task.wait(0.3)
        end
    end
    return anyPurchased
end

--[[ Check unowned Guns affordable for remote purchase ]]
function Utility.HasAnyAffordableUnownedGun()
    if not S.AutoGetAllGunsEnabled then return false end
    local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
    local pFrags = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Fragments") and LocalPlayer.Data.Fragments.Value) or 0
    local curSea = Utility.GetCurrentSea()
    for _, g in ipairs(GUNS_DATABASE) do
        if not Utility.HasItem(g.Name) and curSea >= g.Sea and pBeli >= (g.Price or 0) and pFrags >= (g.Frags or 0) then
            return true
        end
    end
    return false
end

--[[ Purchase all affordable guns in queue ]]
function Utility.BuyAllAffordableGunsStep()
    if not S.AutoGetAllGunsEnabled then return false end
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if not commF then return false end

    local curSea = Utility.GetCurrentSea()
    local anyPurchased = false

    for _, g in ipairs(GUNS_DATABASE) do
        local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
        local pFrags = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Fragments") and LocalPlayer.Data.Fragments.Value) or 0
        if not Utility.HasItem(g.Name) and curSea >= g.Sea and pBeli >= (g.Price or 0) and pFrags >= (g.Frags or 0) then
            pcall(function()
                if g.Remote then
                    commF:InvokeServer(g.Remote, unpack(g.Args or {}))
                else
                    commF:InvokeServer("BuyItem", g.Name)
                end
            end)
            _locallyOwnedItems[g.Name] = true
            table.insert(_inventoryCache, g.Name)
            anyPurchased = true
            UILib.Notify("Auto Buy Gun", "Purchased Gun: " .. g.Name, 2)
            task.wait(0.3)
        end
    end
    return anyPurchased
end

--[[ Check unowned Accessories affordable for remote purchase ]]
function Utility.HasAnyAffordableUnownedAccessory()
    if not S.AutoGetAllAccessoriesEnabled then return false end
    local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
    local curSea = Utility.GetCurrentSea()
    for _, acc in ipairs(ACCESSORIES_DATABASE) do
        if not Utility.HasItem(acc.Name) and curSea >= acc.Sea and pBeli >= acc.Price then
            return true
        end
    end
    return false
end

--[[ Purchase all affordable accessories in queue ]]
function Utility.BuyAllAffordableAccessoriesStep()
    if not S.AutoGetAllAccessoriesEnabled then return false end
    local rep = game:GetService("ReplicatedStorage")
    local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
    if not commF then return false end

    local curSea = Utility.GetCurrentSea()
    local anyPurchased = false

    for _, acc in ipairs(ACCESSORIES_DATABASE) do
        local pBeli = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Beli") and LocalPlayer.Data.Beli.Value) or 0
        if not Utility.HasItem(acc.Name) and curSea >= acc.Sea and pBeli >= acc.Price then
            pcall(function()
                commF:InvokeServer("BuyItem", acc.Name)
            end)
            _locallyOwnedItems[acc.Name] = true
            table.insert(_inventoryCache, acc.Name)
            anyPurchased = true
            UILib.Notify("Auto Buy Accessory", "Purchased Accessory: " .. acc.Name, 2)
            task.wait(0.3)
        end
    end
    return anyPurchased
end

--[[ Helper: Attack single boss step with _WorldOrigin spawn trigger ]]
function Utility.FarmSingleBossStep(bossName, enemyModel, bData, spawnPos)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local flySpeed = S.TeleportFlySpeed or 200

    -- Case 1: Boss model is already spawned and alive in workspace.Enemies
    if enemyModel then
        local _, _, bRoot = Utility.GetEnemyRootCFrame(enemyModel)
        if not bRoot then return end

        -- Take quest for boss if available and near giver
        if bData and bData.Quest and bData.Quest ~= "" and not Utility.HasActiveQuest() and bData.Pos then
            local pDist = (root.Position - bData.Pos).Magnitude
            if pDist <= 40 then
                Utility.StartQuest(bData.Quest, bData.QLevel or 1)
                task.wait(0.3)
            end
        end

        -- Fly above Boss and attack
        Utility.FlyAboveTarget(bRoot.CFrame, S.AttackHeight or 40, flySpeed)
        local wType = S.SelectedWeaponType or "Melee"
        if wType == "Melee" then Utility.AttackMelee(enemyModel, bRoot)
        elseif wType == "Sword" then Utility.AttackSword(enemyModel, bRoot)
        elseif wType == "Fruit" then Utility.AttackFruitM1(enemyModel, bRoot)
        elseif wType == "Gun" then Utility.AttackGun(enemyModel, bRoot)
        end

        if S.AutoFarmUseSkills then
            if wType == "Melee" then Utility.CastSkillsMelee(bRoot.Position, enemyModel)
            elseif wType == "Fruit" then Utility.CastSkillsFruit(bRoot.Position, enemyModel)
            elseif wType == "Sword" then Utility.CastSkillsSword(bRoot.Position, enemyModel)
            elseif wType == "Gun" then Utility.CastSkillsGun(bRoot.Position, enemyModel)
            end
        end
        return
    end

    -- Case 2: Boss not in workspace.Enemies -> fly to spawn point in _WorldOrigin.EnemySpawns
    if spawnPos then
        local targetFlyPos = spawnPos + Vector3.new(0, S.AttackHeight or 40, 0)
        Utility.PhysicsFlyTo(targetFlyPos, flySpeed)

        local dist = (root.Position - spawnPos).Magnitude
        if dist < 60 then
            task.wait(0.8) -- Chờ server load quái vào workspace.Enemies
            local spawnedModel = Utility.GetEnemyByName(bData and bData.Mob or bossName)
            if spawnedModel then
                return
            end
        end
    end
end

--[[ Helper: Find weapon not at target Mastery (Fallback) ]]
function Utility.GetUnfinishedMasteryWeapon(wType, targetMastery)
    targetMastery = targetMastery or 300
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local ch = LocalPlayer.Character
    local sources = { ch, bp }

    for _, src in ipairs(sources) do
        if src then
            for _, item in ipairs(src:GetChildren()) do
                if item:IsA("Tool") and item:FindFirstChild("ToolTip") then
                    local tType = item.ToolTip.Value
                    if (wType == "Sword" and tType == "Sword") or (wType == "Gun" and tType == "Gun") or (wType == "Melee" and tType == "Melee") then
                        local masteryVal = item:FindFirstChild("Level") and item.Level.Value
                        if masteryVal and masteryVal < targetMastery then
                            return item.Name, item
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

--[[ Helper: Farm Mastery Step ]]
function Utility.FarmMasteryStep(toolName, wType)
    Utility.EquipItemByName(toolName)
    local prevWeapon = S.SelectedWeaponType
    S.SelectedWeaponType = wType
    Utility.ExecuteStandardLevelFarmStep()
    S.SelectedWeaponType = prevWeapon
end

local swanFarmState = {
    spotIndex = 1,
    lastSwitchTime = 0,
    spots = {
        Vector3.new(819, 73, 1159),
        Vector3.new(822, 73, 1324),
        Vector3.new(1023, 73, 1393),
        Vector3.new(1064, 73, 1086),
        Vector3.new(983, 73, 1165)
    }
}

--[[ Dedicated Swan Pirate farm routine (Arrival at MobPos -> Bring Mob & Proximity Attack at 18 studs) ]]
function Utility.FarmSwanPiratesStep(qData)
    local flySpeed = S.TeleportFlySpeed or 200
    local attackY = 18
    local curSpot = swanFarmState.spots[swanFarmState.spotIndex] or swanFarmState.spots[1]

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local distToSpot = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(curSpot.X, 0, curSpot.Z)).Magnitude

    -- 1. If not yet arrived at current mobpos spot, fly and arrive first
    if distToSpot > 10 then
        swanFarmState.arrived = false
        Utility.PhysicsFlyTo(curSpot + Vector3.new(0, attackY, 0), flySpeed)
        swanFarmState.lastSwitchTime = os.clock()
        return
    end

    if not swanFarmState.arrived then
        swanFarmState.arrived = true
        swanFarmState.arrivalTime = os.clock()
        Utility.StopPhysicsFly()
    end

    -- 2. Once arrived at mobpos: Bring mob + Attack
    local centerPos, mainMob, cluster = Utility.BringMatchingMobs("Swan Pirate", S.BringMobDistance or 400)
    if centerPos and mainMob and #cluster > 0 then
        local aliveCluster = {}
        for _, item in ipairs(cluster) do
            local m = (typeof(item) == "Instance" and item) or (type(item) == "table" and item.Model)
            local h = m and m:FindFirstChildOfClass("Humanoid")
            if m and m.Parent and h and h.Health > 0 then
                table.insert(aliveCluster, item)
            end
        end

        if #aliveCluster == 0 then
            Utility.CleanupBringMobMovers()
            DisconnectConnection("bringMobStepped")
            currentBringData = nil
            if CTX then CTX.currentBringData = nil end
            swanFarmState.spotIndex = (swanFarmState.spotIndex % #swanFarmState.spots) + 1
            swanFarmState.lastSwitchTime = os.clock()
            swanFarmState.arrived = false
            return
        end

        local mainCF, mainPos, mainRoot = Utility.GetEnemyRootCFrame(mainMob)
        if mainRoot then
            local targetFlyPos = (S.BringMobEnabled and centerPos or mainRoot.Position) + Vector3.new(0, attackY, 0)
            Utility.PhysicsFlyTo(targetFlyPos, flySpeed)

            local wType = S.SelectedWeaponType or "Melee"
            if wType == "Melee" then Utility.AttackMelee(mainMob, mainRoot, aliveCluster)
            elseif wType == "Sword" then Utility.AttackSword(mainMob, mainRoot, aliveCluster)
            elseif wType == "Fruit" then Utility.AttackFruitM1(mainMob, mainRoot, aliveCluster)
            elseif wType == "Gun" then Utility.AttackGun(mainMob, mainRoot, aliveCluster)
            end

            if S.AutoFarmUseSkills then
                if wType == "Melee" then Utility.CastSkillsMelee(centerPos, mainMob)
                elseif wType == "Fruit" then Utility.CastSkillsFruit(centerPos, mainMob)
                elseif wType == "Sword" then Utility.CastSkillsSword(centerPos, mainMob)
                elseif wType == "Gun" then Utility.CastSkillsGun(centerPos, mainMob)
                end
            end
        end
    else
        Utility.CleanupBringMobMovers()
        DisconnectConnection("bringMobStepped")
        currentBringData = nil
        if CTX then CTX.currentBringData = nil end
        swanFarmState.spotIndex = (swanFarmState.spotIndex % #swanFarmState.spots) + 1
        swanFarmState.lastSwitchTime = os.clock()
        swanFarmState.arrived = false
        Utility.PhysicsFlyTo(curSpot + Vector3.new(0, attackY, 0), flySpeed)
    end

    -- 3. Rotate to next spot periodically (every 4.5s) or when spot is clear
    local now = os.clock()
    if (now - swanFarmState.lastSwitchTime >= 4.5) or not mainMob then
        swanFarmState.spotIndex = (swanFarmState.spotIndex % #swanFarmState.spots) + 1
        swanFarmState.lastSwitchTime = now
        swanFarmState.arrived = false
    end
end

--[[ Helper: Execute 1 standard level farm tick with 2s spawn-hopping & server spawn trigger ]]
function Utility.ExecuteStandardLevelFarmStep()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local curLevel = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
    local qData = nil

    -- [KIỂM TRA TIẾN ĐỘ NHIỆM VỤ DỞ DANG ĐỌC TỪ GUI]:
    -- Quét GUI người chơi tại Players.LocalPlayer.PlayerGui.Main.Quest.Container.QuestTitle
    local guiQuest = Utility.GetActiveQuestGuiData()

    if guiQuest and not guiQuest.IsComplete then
        -- GUI đang hiển thị quest dở dang! Kiểm tra xem quái này ứng với quest nào trong cơ sở dữ liệu
        local ongoingData = Utility.GetQuestDataForMob(guiQuest.NormalizedMob)
        if ongoingData then
            local maxLevel = ongoingData.Max or ongoingData.Min or 9999
            -- Nếu level hiện tại không vượt quá quest này quá xa (lệch không quá 50 level):
            -- Giữ nguyên qData này để tiếp tục đánh nốt số quái còn lại cho xong nhiệm vụ!
            if curLevel <= maxLevel + 50 then
                qData = ongoingData
            end
        end
    elseif _activeQuestState.Active and _activeQuestState.Mob ~= "" then
        local ongoingData = Utility.GetQuestDataForMob(_activeQuestState.Mob)
        if ongoingData then
            local maxLevel = ongoingData.Max or ongoingData.Min or 9999
            if curLevel <= maxLevel + 50 then
                qData = ongoingData
            end
        end
    end

    -- Nếu không có quest dở dang (hoặc quest cũ đã hoàn thành xong / quá lệch level): Lấy quest chuẩn theo level mới
    if not qData then
        qData = Utility.GetQuestForLevel(curLevel)
    end
    if not qData then return end

    -- 1. Ensure quest matches target mob before attacking
    local questReady = Utility.EnsureQuestForMob(qData.Mob)
    if not questReady then return end

    -- 2. Handle area transition if mob resides across dimension portal (e.g. Submerged Island, Underwater City, Cursed Ship)
    local transitioning = Utility.CheckAndHandleAreaTransitions(qData.MobPos)
    if transitioning then return end

    -- Dimension barrier check
    local playerInUnderwater = (root.Position.Y < -1000)
    local targetInUnderwater = (qData.MobPos.Y < -1000)
    if playerInUnderwater ~= targetInUnderwater then
        return
    end

    local flySpeed = S.TeleportFlySpeed or 200
    local attackY = S.AttackHeight or 20
    local now = os.clock()

    -- 3. Check if there are active mobs already in range (scan island-wide)
    local centerPos, mainMob, cluster = Utility.BringMatchingMobs(qData.Mob, S.BringMobDistance or 400)
    if centerPos and mainMob and #cluster > 0 then
        -- Khi quái xuất hiện: Hủy đếm giờ ngắt bay để Auto Farm lao vào đánh quái ngay lập tức
        local _, _, patrolState = Utility.GetLevelFarmTargetSpawn(qData.Mob, qData.MobPos, qData)
        if patrolState then patrolState.pauseFlightUntil = 0 end

        local _, _, mainRoot = Utility.GetEnemyRootCFrame(mainMob)
        if mainRoot then
            local targetFlyPos = (S.BringMobEnabled and centerPos or mainRoot.Position) + Vector3.new(0, attackY, 0)
            local distToCombat = (root.Position - targetFlyPos).Magnitude

            -- Fly towards combat position
            Utility.PhysicsFlyTo(targetFlyPos, flySpeed)

            -- If player has arrived in combat range, execute attacks & check damage
            if distToCombat <= 45 then
                local hum = mainMob:FindFirstChildOfClass("Humanoid")
                local curHealth = hum and hum.Health or 0

                -- 1. Kiểm tra chính xác các quái còn sống trong cụm
                local aliveCluster = {}
                if cluster and #cluster > 0 then
                    for _, item in ipairs(cluster) do
                        local m = (typeof(item) == "Instance" and item) or (type(item) == "table" and item.Model)
                        local h = m and m:FindFirstChildOfClass("Humanoid")
                        local r = m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildOfClass("BasePart"))
                        if m and m.Parent and h and h.Health > 0 and r then
                            table.insert(aliveCluster, item)
                        end
                    end
                end

                if #aliveCluster == 0 then
                    -- Toàn bộ cụm quái đã bị tiêu diệt: Dọn dẹp & lập tức chuyển sang bãi tiếp theo, 0s đứng chờ!
                    Utility.CleanupBringMobMovers()
                    DisconnectConnection("bringMobStepped")
                    _mobDamageTracker.model = nil
                    _mobDamageTracker.lastHealth = 0
                    _mobDamageTracker.lastDamageTime = 0
                    currentBringData = nil
                    if CTX then CTX.currentBringData = nil end
                    _lockedMobCluster.mob = ""
                    _lockedMobCluster.center = nil
                    _lockedMobCluster.lockTime = 0
                    if CTX then CTX._lockedMobCluster = _lockedMobCluster end

                    local _, spawns, patrolState = Utility.GetLevelFarmTargetSpawn(qData.Mob, qData.MobPos, qData)
                    local countSpawns = (spawns and #spawns > 0) and #spawns or 1
                    if patrolState and countSpawns > 0 then
                        patrolState.index = (patrolState.index % countSpawns) + 1
                        patrolState.arrived = false
                        patrolState.arrivalTime = now
                        patrolState.pauseFlightUntil = 0 -- Chuyển bãi tức thì 0s delay
                        local nextSpawnPos = (spawns and spawns[patrolState.index] and (spawns[patrolState.index].Position or spawns[patrolState.index])) or qData.MobPos
                        if typeof(nextSpawnPos) == "table" and nextSpawnPos.Position then nextSpawnPos = nextSpawnPos.Position end
                        Utility.PhysicsFlyTo(nextSpawnPos + Vector3.new(0, attackY, 0), flySpeed)
                        return
                    end
                end

                -- Nếu mainMob đã chết nhưng trong cụm vẫn còn con quái khác sống: Chuyển target sang con còn sống ngay!
                if curHealth <= 0 or not mainMob.Parent then
                    local nextAliveItem = aliveCluster[1]
                    local nextModel = (typeof(nextAliveItem) == "Instance" and nextAliveItem) or (type(nextAliveItem) == "table" and nextAliveItem.Model)
                    if nextModel then
                        mainMob = nextModel
                        hum = mainMob:FindFirstChildOfClass("Humanoid")
                        curHealth = hum and hum.Health or 0
                        local _, _, newRoot = Utility.GetEnemyRootCFrame(mainMob)
                        if newRoot then mainRoot = newRoot end
                    end
                end

                -- 2. Theo dõi sát thương & Chống kẹt tối ưu
                local distToTarget = (mainRoot.Position - targetFlyPos).Magnitude
                if distToTarget > 35 then
                    -- Quái vẫn đang trên đường kéo về vị trí chiến đấu: Tiếp tục gia hạn thời gian, không coi là kẹt
                    _mobDamageTracker.lastDamageTime = now
                end

                if _mobDamageTracker.model ~= mainMob then
                    _mobDamageTracker.model = mainMob
                    _mobDamageTracker.lastHealth = curHealth
                    _mobDamageTracker.lastDamageTime = now
                    _mobDamageTracker.startTime = now
                else
                    if curHealth < _mobDamageTracker.lastHealth then
                        _mobDamageTracker.lastHealth = curHealth
                        _mobDamageTracker.lastDamageTime = now
                    end

                    -- Nếu quái đã ở gần (< 35 studs) nhưng bị kẹt địa hình / desync không nhận sát thương quá 5.0s:
                    if (now - _mobDamageTracker.lastDamageTime) >= 5.0 then
                        -- CHỈ bỏ qua đúng con quái này trong 6s (TUYỆT ĐỐI không bỏ qua cả đàn quái!)
                        _ignoredDesyncedMobs[mainMob] = now + 6.0
                        _mobDamageTracker.model = nil
                        _mobDamageTracker.lastHealth = 0
                        _mobDamageTracker.lastDamageTime = now

                        -- Nếu trong cụm quái chỉ còn mỗi con này sống, mới lập tức chuyển sang bãi spawn tiếp theo
                        if #aliveCluster <= 1 then
                            Utility.CleanupBringMobMovers()
                            DisconnectConnection("bringMobStepped")
                            currentBringData = nil
                            if CTX then CTX.currentBringData = nil end
                            _lockedMobCluster.mob = ""
                            _lockedMobCluster.center = nil
                            _lockedMobCluster.lockTime = 0
                            if CTX then CTX._lockedMobCluster = _lockedMobCluster end

                            local _, spawns, patrolState = Utility.GetLevelFarmTargetSpawn(qData.Mob, qData.MobPos, qData)
                            local countSpawns = (spawns and #spawns > 0) and #spawns or 1
                            if patrolState then
                                patrolState.index = (patrolState.index % countSpawns) + 1
                                patrolState.arrived = false
                                patrolState.arrivalTime = now
                                patrolState.forcePatrolUntil = now + 3.0
                                patrolState.pauseFlightUntil = 0
                            end

                            local nextSpawnPos = (spawns and #spawns > 0 and spawns[patrolState.index] and (spawns[patrolState.index].Position or spawns[patrolState.index])) or qData.MobPos
                            if typeof(nextSpawnPos) == "table" and nextSpawnPos.Position then nextSpawnPos = nextSpawnPos.Position end

                            UILib.Notify("Combat Anti-Desync", string.format("Quái kẹt >5s! Lập tức chuyển sang bãi spawn %d/%d...", patrolState and patrolState.index or 1, countSpawns), 2)

                            Utility.PhysicsFlyTo(nextSpawnPos + Vector3.new(0, attackY, 0), flySpeed)
                            return
                        end
                    end
                end

                -- Execute attacks
                local wType = S.SelectedWeaponType or "Melee"
                if wType == "Melee" then Utility.AttackMelee(mainMob, mainRoot, aliveCluster)
                elseif wType == "Sword" then Utility.AttackSword(mainMob, mainRoot, aliveCluster)
                elseif wType == "Fruit" then Utility.AttackFruitM1(mainMob, mainRoot, aliveCluster)
                elseif wType == "Gun" then Utility.AttackGun(mainMob, mainRoot, aliveCluster)
                end

                if S.AutoFarmUseSkills then
                    if wType == "Melee" then Utility.CastSkillsMelee(centerPos, mainMob)
                    elseif wType == "Fruit" then Utility.CastSkillsFruit(centerPos, mainMob)
                    elseif wType == "Sword" then Utility.CastSkillsSword(centerPos, mainMob)
                    elseif wType == "Gun" then Utility.CastSkillsGun(centerPos, mainMob)
                    end
                end
            else
                _mobDamageTracker.lastDamageTime = now
            end

            -- Reset patrol timer while actively engaging enemies
            local _, _, patrolState = Utility.GetLevelFarmTargetSpawn(qData.Mob, qData.MobPos, qData)
            if patrolState then
                patrolState.arrivalTime = now
            end
            return
        end
    else
        _mobDamageTracker.model = nil
    end

    -- 4. Không có quái sống trong tầm: Tuần tra các bãi spawn tuần tự
    local targetSpawnPos, spawns, patrolState = Utility.GetLevelFarmTargetSpawn(qData.Mob, qData.MobPos, qData)
    local targetFlyPos = targetSpawnPos + Vector3.new(0, attackY, 0)
    local flatDist = (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(targetSpawnPos.X, targetSpawnPos.Z)).Magnitude
    local dist = (root.Position - targetSpawnPos).Magnitude

    -- Nếu đã ở gần điểm tuần tra hiện tại (flatDist <= 35 hoặc dist <= 45) mà KHÔNG CÓ QUÁI:
    -- LẬP TỨC CHUYỂN SANG BÃI TIẾP THEO, 0s đứng chờ!
    if #spawns > 1 and (flatDist <= 35 or dist <= 45) then
        patrolState.index = (patrolState.index % #spawns) + 1
        patrolState.arrived = false
        patrolState.arrivalTime = now
        patrolState.pauseFlightUntil = 0
        local nextSpawn = (spawns[patrolState.index] and (spawns[patrolState.index].Position or spawns[patrolState.index])) or targetSpawnPos
        if typeof(nextSpawn) == "table" and nextSpawn.Position then nextSpawn = nextSpawn.Position end
        Utility.PhysicsFlyTo(nextSpawn + Vector3.new(0, attackY, 0), flySpeed)
        return
    end

    -- Tiếp tục bay tới điểm tuần tra mục tiêu ở độ cao an toàn attackY
    patrolState.arrived = false
    Utility.PhysicsFlyTo(targetFlyPos, flySpeed)
end

--[[ ═══════════════════════════════════════════════════════════════════════════
     MODULAR TASK PROGRESSION PIPELINE (PRIORITY DISPATCHER)
     Priority Order: Next Sea -> Puzzle Quests -> Buy Melee/Sword/Gun/Acc -> Bosses -> Mastery -> Farm Level
   ═══════════════════════════════════════════════════════════════════════════ ]]

-- ╔══════════════════════════════════════════════════════════╗



-- [SECTION: SPECIALIZED FARMS & PIPELINE MANAGER MOVED TO FILE 3]
--[[ Step 1: Check if player has killed Tiki Raid Boss (Tyrant of the Skies) ]]
function Utility.CheckUnderwaterKilledTikiBoss()
    local now = os.clock()
    if (now - _tikiBossKillCache.lastCheck < 10.0) then
        return _tikiBossKillCache.killed
    end
    _tikiBossKillCache.lastCheck = now

    local net = game:GetService("ReplicatedStorage"):FindFirstChild("Modules") and game.ReplicatedStorage.Modules:FindFirstChild("Net")
    local event = net and net:FindFirstChild("RF/SubmarineWorkerSpeak")
    if not event then return false end

    local success, result = pcall(function()
        return event:InvokeServer("CheckPlayerKilledBoss")
    end)

    if success then
        if typeof(result) == "table" then
            local val = result[1]
            _tikiBossKillCache.killed = (val == true)
            return _tikiBossKillCache.killed
        end
        _tikiBossKillCache.killed = (result == true)
        return _tikiBossKillCache.killed
    end
    return false
end

--[[ Step 2: Travel to Submerged Island (Underwater) via Submarine Worker NPC ]]
function Utility.TravelToSubmergedIsland()
    local flySpeed = S.TeleportFlySpeed or 200
    local entrancePos = Vector3.new(-16271, 25, 1374)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local dist = (root.Position - entrancePos).Magnitude
    if dist > 35 then
        Utility.PhysicsFlyTo(entrancePos + Vector3.new(0, 5, 0), flySpeed)
        return false
    end

    local net = game:GetService("ReplicatedStorage"):FindFirstChild("Modules") and game.ReplicatedStorage.Modules:FindFirstChild("Net")
    local event = net and net:FindFirstChild("RF/SubmarineWorkerSpeak")
    if event then
        pcall(function()
            event:InvokeServer("TravelToSubmergedIsland")
        end)
        Utility.StopPhysicsFly()
        task.wait(5)
        return true
    end
    return false
end

--[[ Step 3: Return from Submerged Island to Tiki Outpost via Submarine Transportation ]]
function Utility.ReturnFromSubmergedToTiki()
    local flySpeed = S.TeleportFlySpeed or 200
    local exitPos = Vector3.new(11426, -2155, 9727)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local dist = (root.Position - exitPos).Magnitude
    if dist > 35 then
        Utility.PhysicsFlyTo(exitPos + Vector3.new(0, 5, 0), flySpeed)
        return false
    end

    local net = game:GetService("ReplicatedStorage"):FindFirstChild("Modules") and game.ReplicatedStorage.Modules:FindFirstChild("Net")
    local event = net and net:FindFirstChild("RF/SubmarineTransportation")
    if event then
        pcall(function()
            event:InvokeServer("InitiateTeleport", "Tiki Outpost")
        end)
        Utility.StopPhysicsFly()
        task.wait(5)
        return true
    end
    return false
end

--[[ Check 4 Eyes strictly matching Workspace hierarchy:
     Eye1: workspace.Map.TikiOutpost.IslandModel.Eye1
     Eye2: workspace.Map.TikiOutpost.IslandModel.Eye2
     Eye3: workspace.Map.TikiOutpost.IslandModel.IslandChunks.E.Eye3
     Eye4: workspace.Map.TikiOutpost.IslandModel.IslandChunks.E.Eye4
]]
function Utility.CheckTikiBossEyesActive()
    local map = workspace:FindFirstChild("Map")
    local tiki = map and map:FindFirstChild("TikiOutpost")
    local model = tiki and tiki:FindFirstChild("IslandModel")
    if not model then return false, 0 end

    -- Eye1 và Eye2 nằm trực tiếp dưới IslandModel
    local eye1 = model:FindFirstChild("Eye1")
    local eye2 = model:FindFirstChild("Eye2")

    -- Eye3 và Eye4 nằm dưới IslandModel.IslandChunks.E
    local chunks = model:FindFirstChild("IslandChunks")
    local eChunk = chunks and chunks:FindFirstChild("E")
    local eye3 = eChunk and eChunk:FindFirstChild("Eye3")
    local eye4 = eChunk and eChunk:FindFirstChild("Eye4")

    -- Fallback an toàn (phòng hờ Roblox load trễ hoặc biến thể giữa các bản đồ)
    eye1 = eye1 or tiki:FindFirstChild("Eye1") or (chunks and chunks:FindFirstChild("Eye1")) or (eChunk and eChunk:FindFirstChild("Eye1"))
    eye2 = eye2 or tiki:FindFirstChild("Eye2") or (chunks and chunks:FindFirstChild("Eye2")) or (eChunk and eChunk:FindFirstChild("Eye2"))
    eye3 = eye3 or (chunks and chunks:FindFirstChild("Eye3")) or model:FindFirstChild("Eye3") or tiki:FindFirstChild("Eye3")
    eye4 = eye4 or (chunks and chunks:FindFirstChild("Eye4")) or model:FindFirstChild("Eye4") or tiki:FindFirstChild("Eye4")

    local eyes = { eye1, eye2, eye3, eye4 }
    local activeCount = 0

    for i = 1, 4 do
        local eye = eyes[i]
        if eye and eye:IsA("BasePart") then
            -- Thuộc tính: Transparency 0 là đã kích hoạt, Transparency 1 là chưa kích hoạt
            if eye.Transparency <= 0.1 then
                activeCount = activeCount + 1
            end
        end
    end

    return (activeCount >= 4), activeCount
end

local TYRANT_TREE_WAYPOINTS = {
    Vector3.new(-16212, 155, 1467),
    Vector3.new(-16253, 155, 1466),
    Vector3.new(-16289, 155, 1473),
    Vector3.new(-16332, 155, 1457),
    Vector3.new(-16338, 155, 1323),
    Vector3.new(-16292, 155, 1319),
    Vector3.new(-16252, 155, 1318),
    Vector3.new(-16217, 155, 1320),
}

local _tyrantTreeState = {
    index = 1,
    lastHop = 0,
    maxPerTreeTime = 0.6,
    lastSkillCast = 0,
}

--[[ Find, aim, cast skills across all 4 weapons at predefined Tree coordinates in EagleBossArena to summon Tyrant of the Skies ]]
function Utility.SummonTikiRaidBoss()
    local flySpeed = math.max(S.TeleportFlySpeed or 200, 280)
    local now = os.clock()

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end

    if _tyrantTreeState.index > #TYRANT_TREE_WAYPOINTS then
        _tyrantTreeState.index = 1
        _tyrantTreeState.lastHop = now
    end

    local targetPos = TYRANT_TREE_WAYPOINTS[_tyrantTreeState.index]
    local targetFlyPos = targetPos + Vector3.new(0, 8, 0)
    local dist = (root.Position - targetPos).Magnitude

    -- Fly rapidly to target tree coordinate
    Utility.PhysicsFlyTo(targetFlyPos, flySpeed)

    -- Aim player directly at the target tree coordinate
    local lookPos = Vector3.new(targetPos.X, root.Position.Y - 4, targetPos.Z)
    if (lookPos - root.Position).Magnitude > 0.1 then
        root.CFrame = CFrame.lookAt(root.Position, lookPos)
    end

    if dist <= 38 then
        -- 1. Execute weapon M1 attacks
        local wType = S.SelectedWeaponType or "Melee"
        if wType == "Melee" then Utility.AttackMelee(nil, nil)
        elseif wType == "Sword" then Utility.AttackSword(nil, nil)
        elseif wType == "Fruit" then Utility.AttackFruitM1(nil, nil)
        elseif wType == "Gun" then Utility.AttackGun(nil, nil)
        end

        -- 2. Cast skills across all 4 weapons (Melee, Sword, Fruit, Gun) with rapid aiming
        if (now - _tyrantTreeState.lastSkillCast) >= 0.08 then
            _tyrantTreeState.lastSkillCast = now

            pcall(function()
                Utility.CastSkillsMelee(targetPos, nil)
                Utility.CastSkillsSword(targetPos, nil)
                Utility.CastSkillsFruit(targetPos, nil)
                Utility.CastSkillsGun(targetPos, nil)
            end)

            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                for _, kc in ipairs({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V, Enum.KeyCode.F }) do
                    vim:SendKeyEvent(true, kc, false, game)
                    task.wait(0.015)
                    vim:SendKeyEvent(false, kc, false, game)
                end
            end)
        end

        -- Advance to next tree waypoint rapidly (0.6s per spot)
        if (now - _tyrantTreeState.lastHop) >= _tyrantTreeState.maxPerTreeTime then
            _tyrantTreeState.index = (_tyrantTreeState.index % #TYRANT_TREE_WAYPOINTS) + 1
            _tyrantTreeState.lastHop = now
        end
    else
        _tyrantTreeState.lastHop = now
    end

    return true
end

--[[ Get appropriate Tiki Outpost mob quest for player's level ]]
function Utility.GetTikiOutpostFarmMob()
    local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
    if pLevel >= 2575 then
        return "Skull Slayer", "TikiQuest3", 2
    elseif pLevel >= 2550 then
        return "Serpent Hunter", "TikiQuest3", 1
    elseif pLevel >= 2525 then
        return "Isle Champion", "TikiQuest2", 2
    elseif pLevel >= 2500 then
        return "Sun-kissed Warrior", "TikiQuest2", 1
    elseif pLevel >= 2475 then
        return "Island Boy", "TikiQuest1", 2
    elseif pLevel >= 2450 then
        return "Isle Outlaw", "TikiQuest1", 1
    else
        return "Skull Slayer", "TikiQuest3", 2
    end
end

local _lastEyes4Notify = 0

local TIKI_MOB_ZONES = {
    { Mob = "Skull Slayer",       Pos = Vector3.new(-16814, 86, 1539) },
    { Mob = "Serpent Hunter",     Pos = Vector3.new(-16599, 71, 1757) },
    { Mob = "Isle Champion",      Pos = Vector3.new(-16937, 12, 1064) },
    { Mob = "Sun-kissed Warrior",  Pos = Vector3.new(-16184, 22, 1092) },
    { Mob = "Island Boy",         Pos = Vector3.new(-16985, 12, -181) },
    { Mob = "Isle Outlaw",        Pos = Vector3.new(-16124, 12, -248) },
}
local TYRANT_SAFE_LOCK_POS = Vector3.new(-16323, 135, 1396)
local _tyrantZoneIndex = 1
local _tyrantZoneArrived = false
local _tyrantZoneArriveTime = 0

--[[ Execute 1 tick of Auto Tyrant Skies:
     - 4 High-level Tiki mob zones continuous sweep (Excluding low level Island Boy & Isle Outlaw)
     - Tyrant Raid Boss pulled & locked at safe wall position (-16323, 135, 1396) to minimize incoming damage
]]
function Utility.ExecuteAutoTyrantTick()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local flySpeed = S.TeleportFlySpeed or 200
    local attackY = S.AttackHeight or 20
    local now = os.clock()

    -- 1. Check if Raid Boss is already spawned in workspace.Enemies
    local bossNames = { "Tyrant of the Skies", "Tyrant", "Tiki Boss", "Eagle Boss" }
    local bossModel = nil
    for _, bName in ipairs(bossNames) do
        bossModel = Utility.GetEnemyByName(bName)
        if bossModel then break end
    end

    if bossModel then
        local _, bPos, bRoot = Utility.GetEnemyRootCFrame(bossModel)
        if bRoot then
            -- Kéo Tyrant boss khóa chặt về Safe Pos (-16323, 135, 1396) chống bay lung tung
            local bParts = {}
            for _, p in ipairs(bossModel:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                    pcall(function() if p.Anchored then p.Anchored = false end end)
                    table.insert(bParts, p)
                end
            end
            pcall(function()
                if bRoot.Anchored then bRoot.Anchored = false end
                bRoot.CanCollide = false
            end)

            currentBringData = {
                Center = TYRANT_SAFE_LOCK_POS,
                Mobs = {
                    {
                        Model = bossModel,
                        Root = bRoot,
                        Hum = bHum,
                        Parts = bParts
                    }
                }
            }
            Utility.UpdateBringMobSteppedState()

            -- Người chơi bay an toàn ngay phía trên Safe Pos của Tyrant
            local playerSafePos = TYRANT_SAFE_LOCK_POS + Vector3.new(0, attackY, 0)
            Utility.PhysicsFlyTo(playerSafePos, flySpeed)

            local wType = S.SelectedWeaponType or "Melee"
            if wType == "Melee" then Utility.AttackMelee(bossModel, bRoot)
            elseif wType == "Sword" then Utility.AttackSword(bossModel, bRoot)
            elseif wType == "Fruit" then Utility.AttackFruitM1(bossModel, bRoot)
            elseif wType == "Gun" then Utility.AttackGun(bossModel, bRoot)
            end

            if S.AutoFarmUseSkills then
                if wType == "Melee" then Utility.CastSkillsMelee(TYRANT_SAFE_LOCK_POS, bossModel)
                elseif wType == "Fruit" then Utility.CastSkillsFruit(TYRANT_SAFE_LOCK_POS, bossModel)
                elseif wType == "Sword" then Utility.CastSkillsSword(TYRANT_SAFE_LOCK_POS, bossModel)
                elseif wType == "Gun" then Utility.CastSkillsGun(TYRANT_SAFE_LOCK_POS, bossModel)
                end
            end
            return
        end
    else
        -- Dọn dẹp physics movers khi Tyrant đã bị tiêu diệt
        if currentBringData and currentBringData.Center == TYRANT_SAFE_LOCK_POS then
            currentBringData = nil
            Utility.CleanupBringMobMovers()
            DisconnectConnection("bringMobStepped")
        end
    end

    -- 2. Check 4 Eyes status
    local allActive, activeCount = Utility.CheckTikiBossEyesActive()
    if allActive then
        if (now - _lastEyes4Notify) >= 4.0 then
            _lastEyes4Notify = now
            UILib.Notify("Auto Tyrant", "All 4 Eyes Activated (4/4)! Shattering trees in EagleBossArena...", 3)
        end
        Utility.SummonTikiRaidBoss()
        return
    end

    -- 3. Multi-zone sweep: Wipe all 6 Tiki mob zones (1 coordinate/zone, BringMob 400 studs)
    if _tyrantZoneIndex > #TIKI_MOB_ZONES or _tyrantZoneIndex < 1 then
        _tyrantZoneIndex = 1
    end

    local currentZone = TIKI_MOB_ZONES[_tyrantZoneIndex]
    local targetMob = currentZone.Mob
    local bringRange = S.BringMobDistance or 400

    -- Check if mobs are in range for current zone
    local centerPos, mainMob, cluster = Utility.BringMatchingMobs(targetMob, bringRange)
    if not mainMob then
        -- Scan all other Tiki mob zones in range to eliminate instantly if present nearby
        for idx, zone in ipairs(TIKI_MOB_ZONES) do
            local cPos, mMob, cCluster = Utility.BringMatchingMobs(zone.Mob, bringRange)
            if mMob and #cCluster > 0 then
                _tyrantZoneIndex = idx
                currentZone = zone
                targetMob = zone.Mob
                centerPos, mainMob, cluster = cPos, mMob, cCluster
                break
            end
        end
    end

    if centerPos and mainMob and #cluster > 0 then
        _tyrantZoneArrived = false
        local _, _, mRoot = Utility.GetEnemyRootCFrame(mainMob)
        if mRoot then
            local targetFlyPos = (S.BringMobEnabled and centerPos or mRoot.Position) + Vector3.new(0, attackY, 0)
            local distToCombat = (root.Position - targetFlyPos).Magnitude

            Utility.PhysicsFlyTo(targetFlyPos, flySpeed)

            if distToCombat <= 45 then
                local hum = mainMob:FindFirstChildOfClass("Humanoid")
                local curHealth = hum and hum.Health or 0

                -- 1. Kiểm tra chính xác các quái còn sống trong cụm
                local aliveCluster = {}
                if cluster and #cluster > 0 then
                    for _, item in ipairs(cluster) do
                        local m = (typeof(item) == "Instance" and item) or (type(item) == "table" and item.Model)
                        local h = m and m:FindFirstChildOfClass("Humanoid")
                        local r = m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildOfClass("BasePart"))
                        if m and m.Parent and h and h.Health > 0 and r then
                            table.insert(aliveCluster, item)
                        end
                    end
                end

                if #aliveCluster == 0 then
                    -- Quái ở zone này đã bị tiêu diệt hết: Chuyển zone kế tiếp ngay lập tức, 0s delay!
                    Utility.CleanupBringMobMovers()
                    DisconnectConnection("bringMobStepped")
                    _mobDamageTracker.model = nil
                    _mobDamageTracker.lastHealth = 0
                    _mobDamageTracker.lastDamageTime = 0
                    currentBringData = nil
                    if CTX then CTX.currentBringData = nil end
                    _lockedMobCluster.mob = ""
                    _lockedMobCluster.center = nil
                    _lockedMobCluster.lockTime = 0
                    if CTX then CTX._lockedMobCluster = _lockedMobCluster end

                    _tyrantZoneIndex = (_tyrantZoneIndex % #TIKI_MOB_ZONES) + 1
                    _tyrantZoneArrived = false
                    _tyrantZoneArriveTime = now
                    local nextZone = TIKI_MOB_ZONES[_tyrantZoneIndex]
                    Utility.PhysicsFlyTo(nextZone.Pos + Vector3.new(0, attackY, 0), flySpeed)
                    return
                end

                -- Nếu mainMob chết nhưng còn quái khác sống: Chuyển target ngay
                if curHealth <= 0 or not mainMob.Parent then
                    local nextAliveItem = aliveCluster[1]
                    local nextModel = (typeof(nextAliveItem) == "Instance" and nextAliveItem) or (type(nextAliveItem) == "table" and nextAliveItem.Model)
                    if nextModel then
                        mainMob = nextModel
                        hum = mainMob:FindFirstChildOfClass("Humanoid")
                        curHealth = hum and hum.Health or 0
                        local _, _, newRoot = Utility.GetEnemyRootCFrame(mainMob)
                        if newRoot then mRoot = newRoot end
                    end
                end

                -- 2. Anti-Desync: Nếu kẹt > 5.0s không nhận sát thương, bỏ qua và chuyển zone
                local distToTarget = (mRoot.Position - (centerPos or mRoot.Position)).Magnitude
                if distToTarget > 35 then
                    _mobDamageTracker.lastDamageTime = now
                end

                if _mobDamageTracker.model ~= mainMob then
                    _mobDamageTracker.model = mainMob
                    _mobDamageTracker.lastHealth = curHealth
                    _mobDamageTracker.lastDamageTime = now
                    _mobDamageTracker.startTime = now
                else
                    if curHealth < _mobDamageTracker.lastHealth then
                        _mobDamageTracker.lastHealth = curHealth
                        _mobDamageTracker.lastDamageTime = now
                    end

                    if (now - _mobDamageTracker.lastDamageTime) >= 5.0 then
                        _ignoredDesyncedMobs[mainMob] = now + 6.0
                        _mobDamageTracker.model = nil
                        _mobDamageTracker.lastHealth = 0
                        _mobDamageTracker.lastDamageTime = now

                        if #aliveCluster <= 1 then
                            Utility.CleanupBringMobMovers()
                            DisconnectConnection("bringMobStepped")
                            currentBringData = nil
                            if CTX then CTX.currentBringData = nil end
                            _lockedMobCluster.mob = ""
                            _lockedMobCluster.center = nil
                            _lockedMobCluster.lockTime = 0
                            if CTX then CTX._lockedMobCluster = _lockedMobCluster end

                            _tyrantZoneIndex = (_tyrantZoneIndex % #TIKI_MOB_ZONES) + 1
                            _tyrantZoneArrived = false
                            _tyrantZoneArriveTime = now

                            local nextZone = TIKI_MOB_ZONES[_tyrantZoneIndex]
                            UILib.Notify("Combat Anti-Desync", string.format("Quái kẹt >5s! Chuyển sang zone: %s...", nextZone.Mob), 2)
                            Utility.PhysicsFlyTo(nextZone.Pos + Vector3.new(0, attackY, 0), flySpeed)
                            return
                        end
                    end
                end

                local wType = S.SelectedWeaponType or "Melee"
                if wType == "Melee" then Utility.AttackMelee(mainMob, mRoot, aliveCluster)
                elseif wType == "Sword" then Utility.AttackSword(mainMob, mRoot, aliveCluster)
                elseif wType == "Fruit" then Utility.AttackFruitM1(mainMob, mRoot, aliveCluster)
                elseif wType == "Gun" then Utility.AttackGun(mainMob, mRoot, aliveCluster)
                end

                if S.AutoFarmUseSkills then
                    if wType == "Melee" then Utility.CastSkillsMelee(centerPos, mainMob)
                    elseif wType == "Fruit" then Utility.CastSkillsFruit(centerPos, mainMob)
                    elseif wType == "Sword" then Utility.CastSkillsSword(centerPos, mainMob)
                    elseif wType == "Gun" then Utility.CastSkillsGun(centerPos, mainMob)
                    end
                end
            else
                _mobDamageTracker.lastDamageTime = now
            end
            return
        end
    else
        _mobDamageTracker.model = nil
    end

    -- 4. Không có quái trong tầm: Bay tới toạ độ zone hiện tại. Nếu trống quái, chuyển ngay sang zone tiếp theo!
    local targetZonePos = currentZone.Pos
    local targetFlyPos = targetZonePos + Vector3.new(0, attackY, 0)
    local distToZone = (root.Position - targetZonePos).Magnitude

    if distToZone > 40 then
        _tyrantZoneArrived = false
        Utility.PhysicsFlyTo(targetFlyPos, flySpeed)
        return
    end

    -- Đã ở zone hiện tại nhưng không có quái: Chuyển ngay lập tức sang zone kế tiếp, 0s đứng chờ!
    _tyrantZoneIndex = (_tyrantZoneIndex % #TIKI_MOB_ZONES) + 1
    _tyrantZoneArrived = false
    _tyrantZoneArriveTime = now
    local nextZone = TIKI_MOB_ZONES[_tyrantZoneIndex]
    Utility.PhysicsFlyTo(nextZone.Pos + Vector3.new(0, attackY, 0), flySpeed)
end

function Utility.StartAutoTyrantSkies()
    S.AutoTyrantSkiesEnabled = true
    if Utility.GetCurrentSea() ~= 3 then
        UILib.Notify("Auto Tyrant", "Auto Tyrant is only available in Sea 3 (Tiki Outpost)!", 4)
    end
    Utility.StartPipelineCoordinator()
    UILib.Notify("Auto Tyrant", "Auto Tyrant Skies activated!", 3)
end

function Utility.StopAutoTyrantSkies()
    S.AutoTyrantSkiesEnabled = false
    currentBringData = nil
    Utility.CleanupBringMobMovers()
    DisconnectConnection("bringMobStepped")
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
    UILib.Notify("Auto Tyrant", "Auto Tyrant Skies stopped.", 3)
end

local PipelineModules = {
    -- [PRIORITY 0]: AUTO TYRANT OF THE SKIES (SEA 3 TIKI RAID BOSS)
    {
        Name = "AutoTyrantSkies",
        Priority = 0,
        CanRun = function()
            return S.AutoTyrantSkiesEnabled == true and Utility.GetCurrentSea() == 3
        end,
        ExecuteTick = function()
            Utility.ExecuteAutoTyrantTick()
        end,
    },
    -- [PRIORITY 1]: PROGRESSION QUESTS & PUZZLES (SABER, BARTILO, DON SWAN - HIGHER PRIORITY THAN NEXT SEA)
    {
        Name = "PuzzleQuests",
        Priority = 1,
        CanRun = function()
            local curSea = Utility.GetCurrentSea()
            local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
            if S.AutoTheSonQuestEnabled and curSea == 1 and pLevel >= 200 and not Utility.HasItem("Relic") and not Utility.CheckWeaponInventory("Saber") then
                return true
            end
            if S.AutoSaberQuestEnabled and curSea == 1 and pLevel >= 200 and not Utility.CheckWeaponInventory("Saber") and (not Utility.IsSaberDoorUnlocked() or Utility.GetEnemyByName("Saber Expert")) then
                return true
            end
            if S.AutoBartiloQuestEnabled and curSea == 2 and pLevel >= 850 and not Utility.CheckAccessoryInventory("Warrior Helmet") then
                return true
            end
            if S.AutoDonSwanQuestEnabled and curSea == 2 and pLevel >= 1000 and Utility.CanDoDonSwanQuest() then
                return true
            end
            return false
        end,
        ExecuteTick = function()
            local curSea = Utility.GetCurrentSea()
            local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
            if S.AutoTheSonQuestEnabled and curSea == 1 and pLevel >= 200 and not Utility.HasItem("Relic") and not Utility.CheckWeaponInventory("Saber") then
                Utility.StartTheSonQuest()
                task.wait(1)
            elseif S.AutoSaberQuestEnabled and curSea == 1 and pLevel >= 200 and not Utility.CheckWeaponInventory("Saber") and (not Utility.IsSaberDoorUnlocked() or Utility.GetEnemyByName("Saber Expert")) then
                Utility.HandleSaberQuest()
                task.wait(1)
            elseif S.AutoBartiloQuestEnabled and curSea == 2 and pLevel >= 850 and not Utility.CheckAccessoryInventory("Warrior Helmet") then
                Utility.HandleBartiloQuest()
                task.wait(1)
            elseif S.AutoDonSwanQuestEnabled and curSea == 2 and pLevel >= 1000 and Utility.CanDoDonSwanQuest() then
                Utility.HandleDonSwanQuest()
                task.wait(1)
            end
        end,
    },

    -- [PRIORITY 2]: AUTO NEXT SEA PROGRESSION (LV 700 / 1500)
    {
        Name = "NextSeaProgression",
        Priority = 2,
        CanRun = function()
            local curSea = Utility.GetCurrentSea()
            local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
            if (S.AutoNextSeaEnabled or S.AutoMilitaryDetectiveQuestEnabled) and curSea == 1 and pLevel >= 700 then
                return true
            end
            if S.AutoNextSeaEnabled and curSea == 2 and pLevel >= 1500 then
                return true
            end
            return false
        end,
        ExecuteTick = function()
            local curSea = Utility.GetCurrentSea()
            local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
            if (S.AutoNextSeaEnabled or S.AutoMilitaryDetectiveQuestEnabled) and curSea == 1 and pLevel >= 700 then
                Utility.HandleSea2EntranceQuest()
                task.wait(1)
            elseif S.AutoNextSeaEnabled and curSea == 2 and pLevel >= 1500 then
                Utility.HandleSea3EntranceQuest()
                task.wait(1)
            end
        end,
    },

    -- [PRIORITY 3]: AUTO BUY NEXT-TIER FIGHTING STYLE (FLY TO NPC)
    {
        Name = "AutoBuyMelee",
        Priority = 3,
        CanRun = function()
            return Utility.GetNextLinearUnownedMelee() ~= nil
        end,
        ExecuteTick = function()
            local targetMelee = Utility.GetNextLinearUnownedMelee()
            if targetMelee then
                local curSea = Utility.GetCurrentSea()
                local flySpeed = S.TeleportFlySpeed or 200

                -- 1. Locate NPC Model in Workspace or standard Sea coordinates
                local targetPos = nil
                local npcFolder = workspace:FindFirstChild("NPCs")
                local altNames = typeof(targetMelee.NPC) == "table" and targetMelee.NPC or { targetMelee.NPC }
                local foundNpc = nil
                for _, n in ipairs(altNames) do
                    foundNpc = (npcFolder and npcFolder:FindFirstChild(n, true)) or workspace:FindFirstChild(n, true)
                    if foundNpc and foundNpc:IsA("Model") then break end
                end

                if foundNpc and foundNpc:IsA("Model") then
                    local root = foundNpc:FindFirstChild("HumanoidRootPart") or foundNpc.PrimaryPart or foundNpc:FindFirstChildOfClass("BasePart")
                    if root then targetPos = root.Position end
                end

                if not targetPos and targetMelee.Positions then
                    targetPos = targetMelee.Positions[curSea] or targetMelee.Positions[3] or targetMelee.Positions[2] or targetMelee.Positions[1]
                end

                -- 2. Fly to NPC location
                if targetPos then
                    UILib.Notify("Auto Buy Melee", "Enough funds! Flying to " .. targetMelee.DisplayName .. " NPC...", 4)
                    Utility.CheckAndHandleUnderwaterTransition(targetPos)
                    Utility.FlyAndWaitArrival(targetPos + Vector3.new(0, 3, 0), flySpeed, 25, 10)
                    task.wait(0.5)
                end

                -- 3. Invoke remote to purchase fighting style near NPC
                local rep = game:GetService("ReplicatedStorage")
                local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")
                if commF then
                    pcall(function()
                        commF:InvokeServer(targetMelee.Remote, unpack(targetMelee.Args or {}))
                        if targetMelee.AlternateArgs then
                            task.wait(0.2)
                            commF:InvokeServer(targetMelee.Remote, unpack(targetMelee.AlternateArgs))
                        end
                    end)
                end
                task.wait(0.8)
                UILib.Notify("Auto Buy Melee", "Unlocked " .. targetMelee.DisplayName .. "! Resuming...", 3)
            end
        end,
    },

    -- [PRIORITY 4]: AUTO BUY ALL AFFORDABLE SWORDS (REMOTE)
    {
        Name = "AutoBuySword",
        Priority = 4,
        CanRun = function()
            return Utility.HasAnyAffordableUnownedSword()
        end,
        ExecuteTick = function()
            Utility.BuyAllAffordableSwordsStep()
        end,
    },

    -- [PRIORITY 5]: AUTO BUY ALL AFFORDABLE GUNS (REMOTE)
    {
        Name = "AutoBuyGun",
        Priority = 5,
        CanRun = function()
            return Utility.HasAnyAffordableUnownedGun()
        end,
        ExecuteTick = function()
            Utility.BuyAllAffordableGunsStep()
        end,
    },

    -- [PRIORITY 6]: AUTO BUY ALL AFFORDABLE ACCESSORIES (REMOTE)
    {
        Name = "AutoBuyAccessory",
        Priority = 6,
        CanRun = function()
            return Utility.HasAnyAffordableUnownedAccessory()
        end,
        ExecuteTick = function()
            Utility.BuyAllAffordableAccessoriesStep()
        end,
    },

    -- [PRIORITY 7]: HUNT SELECTED BOSSES (WHEN SPAWNED OR PATROL SPAWN)
    {
        Name = "SelectedBosses",
        Priority = 7,
        CanRun = function()
            if not S.AutoFarmSelectedBossesEnabled and not S.AutoFarmSelectedBossEnabled then return false end
            local bName, bModel, bData, bSpawnPos = Utility.GetSpawnedSelectedBoss()
            return bName ~= nil and bData ~= nil and (bModel ~= nil or bSpawnPos ~= nil)
        end,
        ExecuteTick = function()
            local bName, bModel, bData, bSpawnPos = Utility.GetSpawnedSelectedBoss()
            if bName and bData and (bModel or bSpawnPos) then
                Utility.FarmSingleBossStep(bName, bModel, bData, bSpawnPos)
                task.wait(0.04)
            end
        end,
    },

    -- [PRIORITY 8]: FIGHTING STYLE MASTERY FARM (PROGRESSION & BACKTRACK)
    {
        Name = "MasteryMelee",
        Priority = 8,
        CanRun = function()
            if not S.AutoFarmMasteryMeleeEnabled then return false end
            local mName = Utility.GetBacktrackingMasteryTarget("Melee", S.MasteryTargetLevel or 600)
            return mName ~= nil
        end,
        ExecuteTick = function()
            local mName = Utility.GetBacktrackingMasteryTarget("Melee", S.MasteryTargetLevel or 600)
            if mName then
                Utility.FarmMasteryStep(mName, "Melee")
            end
        end,
    },

    -- [PRIORITY 9]: SWORD MASTERY FARM (PROGRESSION & BACKTRACK)
    {
        Name = "MasterySword",
        Priority = 9,
        CanRun = function()
            if not S.AutoFarmMasterySwordEnabled then return false end
            local swName = Utility.GetBacktrackingMasteryTarget("Sword", S.MasteryTargetLevel or 600)
            return swName ~= nil
        end,
        ExecuteTick = function()
            local swName = Utility.GetBacktrackingMasteryTarget("Sword", S.MasteryTargetLevel or 600)
            if swName then
                Utility.FarmMasteryStep(swName, "Sword")
            end
        end,
    },

    -- [PRIORITY 10]: GUN MASTERY FARM (PROGRESSION & BACKTRACK)
    {
        Name = "MasteryGun",
        Priority = 10,
        CanRun = function()
            if not S.AutoFarmMasteryGunEnabled then return false end
            local gnName = Utility.GetBacktrackingMasteryTarget("Gun", S.MasteryTargetLevel or 600)
            return gnName ~= nil
        end,
        ExecuteTick = function()
            local gnName = Utility.GetBacktrackingMasteryTarget("Gun", S.MasteryTargetLevel or 600)
            if gnName then
                Utility.FarmMasteryStep(gnName, "Gun")
            end
        end,
    },

    -- [PRIORITY 11]: DEFAULT LEVEL AUTO FARM (1 - 2550)
    {
        Name = "FarmLevel",
        Priority = 11,
        CanRun = function()
            return S.AutoFarmLevelEnabled == true
        end,
        ExecuteTick = function()
            Utility.ExecuteStandardLevelFarmStep()
        end,
    },
}

--[[ Execute 1 tick of the Modular Task Progression Pipeline ]]
function Utility.ExecutePipelineTick()
    for _, mod in ipairs(PipelineModules) do
        if mod.CanRun() then
            mod.ExecuteTick()
            return
        end
    end
end

--[[ Check if any Pipeline feature is currently ENABLED ]]
function Utility.IsAnyPipelineTaskEnabled()
    local pLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
    local curSea = Utility.GetCurrentSea()
    return S.AutoFarmLevelEnabled
        or (S.AutoTyrantSkiesEnabled and curSea == 3)
        or S.AutoFarmSelectedBossesEnabled
        or S.AutoFarmSelectedBossEnabled
        or S.AutoGetAllMeleesEnabled
        or S.AutoGetAllSwordsEnabled
        or S.AutoGetAllGunsEnabled
        or S.AutoGetAllAccessoriesEnabled
        or S.AutoFarmMasteryMeleeEnabled
        or S.AutoFarmMasterySwordEnabled
        or S.AutoFarmMasteryGunEnabled
        or (S.AutoNextSeaEnabled and ((curSea == 1 and pLevel >= 700) or (curSea == 2 and pLevel >= 1500)))
        or (S.AutoMilitaryDetectiveQuestEnabled and curSea == 1 and pLevel >= 700)
        or (S.AutoTheSonQuestEnabled and curSea == 1 and pLevel >= 200 and not Utility.HasItem("Relic"))
        or (S.AutoSaberQuestEnabled and curSea == 1 and pLevel >= 200 and not Utility.HasSaber())
        or (S.AutoBartiloQuestEnabled and curSea == 2 and pLevel >= 850 and not Utility.HasCompletedBartilo())
        or (S.AutoDonSwanQuestEnabled and curSea == 2 and pLevel >= 1000 and not Utility.CheckAccessoryInventory("Swan Glasses"))
end

--[[ Task Coordinator Pipeline Loop ]]
function Utility.StartPipelineCoordinator()
    DisconnectConnection("pipelineCoordinator")
    _conns["pipelineCoordinator"] = task.spawn(function()
        while Utility.IsAnyPipelineTaskEnabled() do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health > 0 and root then
                Utility.ExecutePipelineTick()
            else
                currentBringData = nil
                Utility.StopPhysicsFly()
            end
            task.wait(0.035)
        end
        currentBringData = nil
        Utility.StopPhysicsFly()
    end)
end

function Utility.StopPipelineCoordinator()
    DisconnectConnection("pipelineCoordinator")
    Utility.CleanupBringMobMovers()
    DisconnectConnection("bringMobStepped")
    currentBringData = nil
    if CTX then CTX.currentBringData = nil end
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end



function Utility.StartAutoFarmLevel()
    S.AutoFarmLevelEnabled = true
    Utility.StartPipelineCoordinator()
end

--[[ Stop Auto Farm Level ]]
function Utility.StopAutoFarmLevel()
    S.AutoFarmLevelEnabled = false
    S.AutoTyrantSkiesEnabled = false
    DisconnectConnection("pipelineCoordinator")
    DisconnectConnection("autoFarmLevel")
    Utility.CleanupBringMobMovers()
    DisconnectConnection("bringMobStepped")
    currentBringData = nil
    if CTX then CTX.currentBringData = nil end
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

--[[ Start Auto Farm Selected Mob with Bring Mobs ]]
function Utility.StartAutoFarmSelectedMob()
    DisconnectConnection("autoFarmMob")
    _conns["autoFarmMob"] = task.spawn(function()
        while S.AutoFarmSelectedMobEnabled do
            local mobName = S.SelectedMob
            if not mobName or mobName == "" then
                task.wait(0.5)
            else
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if char and hum and hum.Health > 0 and root then
                    -- Ensure quest matches target mob before attacking
                    local questReady = Utility.EnsureQuestForMob(mobName)
                    if questReady then
                        local qData = Utility.GetQuestDataForMob(mobName)
                        if qData then Utility.CheckAndHandleAreaTransitions(qData.MobPos) end

                        if mobName == "Swan Pirate" then
                            Utility.FarmSwanPiratesStep(qData)
                        else
                            local centerPos, mainMob, cluster = Utility.BringMatchingMobs(mobName, S.BringMobDistance or 400)
                            if centerPos and mainMob and #cluster > 0 then
                                local mainCF, mainPos, mainRoot = Utility.GetEnemyRootCFrame(mainMob)
                                if mainRoot then
                                    local targetFlyPos = (S.BringMobEnabled and centerPos or mainRoot.Position) + Vector3.new(0, S.AttackHeight or 40, 0)
                                    local distToCombat = (root.Position - targetFlyPos).Magnitude
                                    Utility.PhysicsFlyTo(targetFlyPos, S.TeleportFlySpeed or 200)

                                    local wType = S.SelectedWeaponType or "Melee"
                                    if wType == "Melee" then Utility.AttackMelee(mainMob, mainRoot, cluster)
                                    elseif wType == "Sword" then Utility.AttackSword(mainMob, mainRoot, cluster)
                                    elseif wType == "Fruit" then Utility.AttackFruitM1(mainMob, mainRoot, cluster)
                                    elseif wType == "Gun" then Utility.AttackGun(mainMob, mainRoot, cluster)
                                    end

                                    if S.AutoFarmUseSkills then
                                        if wType == "Melee" then Utility.CastSkillsMelee(centerPos, mainMob)
                                        elseif wType == "Fruit" then Utility.CastSkillsFruit(centerPos, mainMob)
                                        elseif wType == "Sword" then Utility.CastSkillsSword(centerPos, mainMob)
                                        elseif wType == "Gun" then Utility.CastSkillsGun(centerPos, mainMob)
                                        end
                                    end
                                end
                            else
                                Utility.CleanupBringMobMovers()
                                DisconnectConnection("bringMobStepped")
                                currentBringData = nil
                                if CTX then CTX.currentBringData = nil end
                                local patrolTarget = qData and Utility.GetSpawnPatrolPos(qData) or (qData and qData.MobPos)
                                if patrolTarget then
                                    local distToPatrol = (root.Position - patrolTarget).Magnitude
                                    local flatDist = (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(patrolTarget.X, patrolTarget.Z)).Magnitude
                                    local now = os.clock()
                                    if not _mobSelectedPatrolPause then _mobSelectedPatrolPause = {} end
                                    if _mobSelectedPatrolPause[mobName] and _mobSelectedPatrolPause[mobName] > 0 then
                                        if now < _mobSelectedPatrolPause[mobName] then
                                            Utility.StopPhysicsFly()
                                        else
                                            _mobSelectedPatrolPause[mobName] = 0
                                            Utility.PhysicsFlyTo(patrolTarget + Vector3.new(0, S.AttackHeight or 40, 0), S.TeleportFlySpeed or 200)
                                        end
                                    elseif distToPatrol <= 10 or flatDist <= 10 then
                                        -- Đến điểm tuần tra: Ngắt bay trong 1s (Auto Farm vẫn hoạt động)
                                        _mobSelectedPatrolPause[mobName] = now + 1.0
                                        Utility.StopPhysicsFly()
                                    else
                                        Utility.PhysicsFlyTo(patrolTarget + Vector3.new(0, S.AttackHeight or 40, 0), S.TeleportFlySpeed or 200)
                                    end
                                else
                                    Utility.StopPhysicsFly()
                                end
                            end
                        end
                    end
                else
                    Utility.CleanupBringMobMovers()
                    DisconnectConnection("bringMobStepped")
                    currentBringData = nil
                    if CTX then CTX.currentBringData = nil end
                    Utility.StopPhysicsFly()
                end
            end
            task.wait(0.035)
        end
        Utility.CleanupBringMobMovers()
        DisconnectConnection("bringMobStepped")
        currentBringData = nil
        if CTX then CTX.currentBringData = nil end
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop Auto Farm Selected Mob ]]
function Utility.StopAutoFarmSelectedMob()
    DisconnectConnection("autoFarmMob")
    Utility.CleanupBringMobMovers()
    DisconnectConnection("bringMobStepped")
    currentBringData = nil
    if CTX then CTX.currentBringData = nil end
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

--[[ Start Auto Farm Selected Boss ]]
function Utility.StartAutoFarmSelectedBoss()
    DisconnectConnection("autoFarmBoss")
    _conns["autoFarmBoss"] = task.spawn(function()
        while S.AutoFarmSelectedBossEnabled do
            local bossName = S.SelectedBoss
            local bData = BOSS_DATABASE[bossName]
            local targetBoss = Utility.GetEnemyByName(bossName)
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health > 0 and root then
                if targetBoss then
                    if bData and bData.Quest ~= "" and not Utility.HasActiveQuest() then
                        Utility.StartQuest(bData.Quest, bData.QLevel)
                    end

                    local eCF, ePos, eRoot = Utility.GetEnemyRootCFrame(targetBoss)
                    if eRoot then
                        Utility.FlyAboveTarget(eCF, S.AttackHeight or 40, S.TeleportFlySpeed or 200)
                        local wType = S.SelectedWeaponType or "Melee"
                        if wType == "Melee" then Utility.AttackMelee(targetBoss, eRoot)
                        elseif wType == "Sword" then Utility.AttackSword(targetBoss, eRoot)
                        elseif wType == "Fruit" then Utility.AttackFruitM1(targetBoss, eRoot)
                        elseif wType == "Gun" then Utility.AttackGun(targetBoss, eRoot)
                        end

                        if S.AutoFarmUseSkills then
                            if wType == "Melee" then Utility.CastSkillsMelee(ePos, targetBoss)
                            elseif wType == "Fruit" then Utility.CastSkillsFruit(ePos, targetBoss)
                            elseif wType == "Sword" then Utility.CastSkillsSword(ePos, targetBoss)
                            elseif wType == "Gun" then Utility.CastSkillsGun(ePos, targetBoss)
                            end
                        end
                    end
                else
                    if bData and bData.Pos then
                        Utility.PhysicsFlyTo(bData.Pos + Vector3.new(0, S.AttackHeight or 40, 0), S.TeleportFlySpeed or 200)
                    else
                        Utility.StopPhysicsFly()
                    end
                end
            else
                Utility.StopPhysicsFly()
            end
            task.wait(0.035)
        end
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop Auto Farm Selected Boss ]]
function Utility.StopAutoFarmSelectedBoss()
    DisconnectConnection("autoFarmBoss")
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

--[[ Start Auto Farm Material with Bring Mobs ]]
function Utility.StartAutoFarmMaterial()
    DisconnectConnection("autoFarmMat")
    _conns["autoFarmMat"] = task.spawn(function()
        while S.AutoFarmMaterialEnabled do
            local matName = S.SelectedMaterial
            local mData = MATERIAL_FARM_DATA[matName]
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health > 0 and root and mData then
                local centerPos, mainMob, cluster = Utility.BringMatchingMobs(mData.Mob, S.BringMobDistance or 400)
                if centerPos and mainMob and #cluster > 0 then
                    local mainCF, mainPos, mainRoot = Utility.GetEnemyRootCFrame(mainMob)
                    if mainRoot then
                        local targetFlyPos = (S.BringMobEnabled and centerPos or mainRoot.Position) + Vector3.new(0, S.AttackHeight or 40, 0)
                        local distToCombat = (root.Position - targetFlyPos).Magnitude
                        Utility.PhysicsFlyTo(targetFlyPos, S.TeleportFlySpeed or 200)

                        local wType = S.SelectedWeaponType or "Melee"
                        if wType == "Melee" then Utility.AttackMelee(mainMob, mainRoot, cluster)
                        elseif wType == "Sword" then Utility.AttackSword(mainMob, mainRoot, cluster)
                        elseif wType == "Fruit" then Utility.AttackFruitM1(mainMob, mainRoot, cluster)
                        elseif wType == "Gun" then Utility.AttackGun(mainMob, mainRoot, cluster)
                        end

                        if S.AutoFarmUseSkills then
                            if wType == "Melee" then Utility.CastSkillsMelee(centerPos, mainMob)
                            elseif wType == "Fruit" then Utility.CastSkillsFruit(centerPos, mainMob)
                            elseif wType == "Sword" then Utility.CastSkillsSword(centerPos, mainMob)
                            elseif wType == "Gun" then Utility.CastSkillsGun(centerPos, mainMob)
                            end
                        end
                    end
                else
                    Utility.CleanupBringMobMovers()
                    DisconnectConnection("bringMobStepped")
                    currentBringData = nil
                    if CTX then CTX.currentBringData = nil end
                    Utility.PhysicsFlyTo(mData.Pos + Vector3.new(0, S.AttackHeight or 40, 0), S.TeleportFlySpeed or 200)
                end
            else
                Utility.CleanupBringMobMovers()
                DisconnectConnection("bringMobStepped")
                currentBringData = nil
                if CTX then CTX.currentBringData = nil end
                Utility.StopPhysicsFly()
            end
            task.wait(0.035)
        end
        Utility.CleanupBringMobMovers()
        DisconnectConnection("bringMobStepped")
        currentBringData = nil
        if CTX then CTX.currentBringData = nil end
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop Auto Farm Material ]]
function Utility.StopAutoFarmMaterial()
    DisconnectConnection("autoFarmMat")
    Utility.CleanupBringMobMovers()
    DisconnectConnection("bringMobStepped")
    currentBringData = nil
    if CTX then CTX.currentBringData = nil end
    Utility.ReleaseAllHeldSkills()
    Utility.StopPhysicsFly()
end

--[[ Start Auto Farm Chests ]]
function Utility.StartAutoFarmChests()
    DisconnectConnection("autoFarmChest")
    _conns["autoFarmChest"] = task.spawn(function()
        while S.AutoFarmChestEnabled do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health > 0 and root then
                local chests = {}
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name:find("Chest") or (obj.Parent and obj.Parent.Name:find("Chest"))) then
                        if obj:FindFirstChildOfClass("TouchTransmitter") or obj.Transparency < 1 then
                            table.insert(chests, obj)
                        end
                    end
                end

                if #chests > 0 then
                    table.sort(chests, function(a, b)
                        return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude
                    end)

                    local targetChest = chests[1]
                    if targetChest and targetChest.Parent then
                        Utility.PhysicsFlyTo(targetChest.Position + Vector3.new(0, 2, 0), S.TeleportFlySpeed or 180)
                        task.wait(0.2)
                    end
                else
                    task.wait(2)
                end
            else
                Utility.StopPhysicsFly()
            end
            task.wait(0.05)
        end
        Utility.StopPhysicsFly()
    end)
end

--[[ Stop Auto Farm Chests ]]
function Utility.StopAutoFarmChests()
    DisconnectConnection("autoFarmChest")
    Utility.StopPhysicsFly()
end


--[[ Start Auto Stats Loop ]]
function Utility.StartAutoStatsLoop()
    DisconnectConnection("autoStats")
    _conns["autoStats"] = task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local commF = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("CommF_")

        while S.AutoStatsMelee or S.AutoStatsDefense or S.AutoStatsSword or S.AutoStatsGun or S.AutoStatsFruit do
            local points = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Points") and LocalPlayer.Data.Points.Value) or 0
            if points > 0 and commF and commF:IsA("RemoteFunction") then
                local function AddToStat(statName)
                    local currentPts = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Points") and LocalPlayer.Data.Points.Value) or 0
                    local targetAmt = tonumber(S.StatsPointsAmount) or 1
                    local toAdd = math.min(targetAmt, currentPts)
                    if toAdd > 0 then
                        pcall(function() commF:InvokeServer("AddPoint", statName, toAdd) end)
                    end
                end

                if S.AutoStatsMelee then AddToStat("Melee") end
                if S.AutoStatsDefense then AddToStat("Defense") end
                if S.AutoStatsSword then AddToStat("Sword") end
                if S.AutoStatsGun then AddToStat("Gun") end
                if S.AutoStatsFruit then AddToStat("Demon Fruit") end
            end
            collectgarbage("step", 50)
            task.wait(1.5)
        end
    end)
end


--[[ Helper function to get available mobs ]]
function Utility.GetAvailableMobsList()
    local mobs = {}
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, enemy in ipairs(enemies:GetChildren()) do
            if enemy:IsA("Model") and not table.find(mobs, enemy.Name) then
                table.insert(mobs, enemy.Name)
            end
        end
    end
    if #mobs == 0 then
        mobs = { "Bandit", "Monkey", "Gorilla", "Pirate", "Brute", "Desert Bandit", "Snow Bandit", "Swan Pirate", "Ship Deckhand", "Pirate Millionaire", "Dragon Crew Warrior", "Reborn Skeleton", "Cookie Crafter", "Cocoa Warrior", "Isle Outlaw" }
    end
    table.sort(mobs)
    return mobs
end

--[[ Helper function to get available bosses filtered by Sea ]]
function Utility.GetAvailableBossesList(targetSea)
    local curSea = targetSea or Utility.GetCurrentSea()
    local bosses = {}
    for bossName, data in pairs(BOSS_DATABASE) do
        if data.Sea == curSea or not data.Sea then
            table.insert(bosses, bossName)
        end
    end
    table.sort(bosses)
    if #bosses == 0 then
        for bossName, _ in pairs(BOSS_DATABASE) do
            table.insert(bosses, bossName)
        end
        table.sort(bosses)
    end
    return bosses
end

--[[ Helper function to check if any user-selected boss is currently spawned or present in _WorldOrigin ]]
function Utility.GetSpawnedSelectedBoss()
    if not S.AutoFarmSelectedBossesEnabled and not S.AutoFarmSelectedBossEnabled then return nil, nil, nil, nil end
    local selected = S.SelectedBosses or {}
    if #selected == 0 and S.SelectedBoss and S.SelectedBoss ~= "" then
        selected = { S.SelectedBoss }
    end
    if #selected == 0 then return nil, nil, nil, nil end

    -- 1. Check if any selected boss is ALREADY alive in workspace.Enemies
    for _, bossName in ipairs(selected) do
        local bData = BOSS_DATABASE[bossName]
        if bData then
            local enemyModel = Utility.GetEnemyByName(bData.Mob or bossName)
            if enemyModel then
                local _, _, root = Utility.GetEnemyRootCFrame(enemyModel)
                if root then
                    return bossName, enemyModel, bData, nil
                end
            end
        end
    end

    -- 2. If no alive boss found in workspace.Enemies, check spawn points from _WorldOrigin.EnemySpawns
    for _, bossName in ipairs(selected) do
        local bData = BOSS_DATABASE[bossName]
        if bData then
            local cf, pos = Utility.GetEnemySpawnCFrame(bData.Mob or bossName)
            if pos then
                return bossName, nil, bData, pos
            end
        end
    end

    return nil, nil, nil, nil
end

--[[ Helper function to get available materials ]]
function Utility.GetAvailableMaterialsList()
    local mats = {}
    for matName, _ in pairs(MATERIAL_FARM_DATA) do
        table.insert(mats, matName)
    end
    table.sort(mats)
    return mats
end




-- ========================================================
-- [TAB BUILDER: AUTO FARM]
-- ========================================================
CTX.TabBuilders['Auto Farm'] = function(Window)
local FarmTab = Window:AddTab({ Name = "Auto Farm", Icon = "" })

FarmTab:AddSection("Weapon & Combat Configuration")

FarmTab:AddDropdown({
    Name    = "Select Weapon",
    Desc    = "Choose weapon type",
    Options = { "Melee", "Sword", "Fruit", "Gun" },
    Default = S.SelectedWeaponType or "Melee",
    Callback = function(opt)
        S.SelectedWeaponType = opt
        Utility.EquipWeaponByType(opt)
    end,
})

FarmTab:AddSlider({
    Name    = "Attack Height",
    Desc    = "Height above target",
    Min     = 5, Max = 80, Default = S.AttackHeight or 40, Suffix = " studs",
    Callback = function(v)
        S.AttackHeight = v
    end,
})

FarmTab:AddSlider({
    Name    = "Farm Fly Speed",
    Desc    = "Fly speed when farming",
    Min     = 50, Max = 350, Default = S.TeleportFlySpeed or 200, Suffix = " sp",
    Callback = function(v)
        S.TeleportFlySpeed = v
    end,
})

UI_ELEMENTS["BringMobEnabled"] = FarmTab:AddToggle({
    Name    = "Bring Mobs",
    Desc    = "Pull & lock mobs to center",
    Default = (S.BringMobEnabled ~= nil and S.BringMobEnabled) or true,
    Callback = function(val)
        S.BringMobEnabled = val
        if not val then
            Utility.CleanupBringMobMovers()
            DisconnectConnection("bringMobStepped")
            currentBringData = nil
            if CTX then CTX.currentBringData = nil end
            collectgarbage("step", 50)
        end
    end,
})

if not S.BringMobDistance or S.BringMobDistance > 1500 or S.BringMobDistance < 50 or S.BringMobDistance == 300 or S.BringMobDistance == 450 then
    S.BringMobDistance = 900
end

if not S.BringMobSpeed or S.BringMobSpeed == 280 then
    S.BringMobSpeed = 550
end

FarmTab:AddSlider({
    Name    = "Bring Mob Range",
    Desc    = "Tầm quét quái xung quanh (Radar 900)",
    Min     = 100, Max = 1200, Default = S.BringMobDistance or 900, Suffix = " studs",
    Callback = function(v)
        S.BringMobDistance = math.clamp(v, 100, 1500)
    end,
})

FarmTab:AddSlider({
    Name    = "Bring Mob Speed",
    Desc    = "Pull speed with smooth braking",
    Min     = 100, Max = 800, Default = S.BringMobSpeed or 550, Suffix = " studs/s",
    Callback = function(v)
        S.BringMobSpeed = v
    end,
})

UI_ELEMENTS["AutoFarmUseSkills"] = FarmTab:AddToggle({
    Name    = "Use Skills While Farming",
    Desc    = "Auto cast skills while farming",
    Default = S.AutoFarmUseSkills or false,
    Callback = function(val)
        S.AutoFarmUseSkills = val
    end,
})

AutoFarmWithSkillsToggle = FarmTab:AddToggle({
    Name    = "Farm with Skills Only",
    Desc    = "Attack with skills only",
    Default = S.AutoFarmWithSkillsEnabled or false,
    Callback = function(val)
        S.AutoFarmWithSkillsEnabled = val
        if val then
            Utility.StartAutoFarmWithSkills()
        else
            Utility.StopAutoFarmWithSkills()
        end
    end,
})
UI_ELEMENTS["AutoFarmWithSkillsEnabled"] = AutoFarmWithSkillsToggle

FarmTab:AddSection("Auto Farm Progression")

AutoFarmLevelToggle = FarmTab:AddToggle({
    Name    = "Auto Farm Level",
    Desc    = "Auto quest & level up to Max 2550",
    Default = S.AutoFarmLevelEnabled or false,
    Callback = function(val)
        S.AutoFarmLevelEnabled = val
        if val then
            Utility.StartAutoFarmLevel()
        else
            Utility.StopAutoFarmLevel()
        end
    end,
})
UI_ELEMENTS["AutoFarmLevelEnabled"] = AutoFarmLevelToggle

UI_ELEMENTS["AutoTyrantSkies"] = FarmTab:AddToggle({
    Name    = "Auto Tyrant of the Skies",
    Desc    = "Auto farm Tiki mobs, activate 4 Eyes, summon & defeat Tyrant Raid Boss (Sea 3)",
    Default = S.AutoTyrantSkiesEnabled or false,
    Callback = function(val)
        if val then
            Utility.StartAutoTyrantSkies()
        else
            Utility.StopAutoTyrantSkies()
        end
    end,
})

FarmTab:AddSection("Boss Hunting")

local BossDropdown
BossDropdown = FarmTab:AddDropdown({
    Name    = "Select Target Bosses",
    Desc    = "Choose bosses to hunt (Current Sea)",
    Multi   = true,
    Options = Utility.GetAvailableBossesList(),
    Default = S.SelectedBosses or {},
    Callback = function(selectedList)
        S.SelectedBosses = selectedList
    end,
})

FarmTab:AddButton({
    Name    = "Refresh Boss List (Current Sea)",
    Desc    = "Scan bosses for current Sea",
    Callback = function()
        if BossDropdown then
            local bList = Utility.GetAvailableBossesList()
            BossDropdown:Refresh(bList)
            UILib.Notify("Boss List", "Refreshed " .. #bList .. " bosses for Sea " .. Utility.GetCurrentSea(), 2)
        end
    end,
})

AutoFarmSelectedBossToggle = FarmTab:AddToggle({
    Name    = "Auto Farm Selected Bosses",
    Desc    = "Only attacks when boss has spawned",
    Default = S.AutoFarmSelectedBossesEnabled or false,
    Callback = function(val)
        S.AutoFarmSelectedBossesEnabled = val
        S.AutoFarmSelectedBossEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})
UI_ELEMENTS["AutoFarmSelectedBossesEnabled"] = AutoFarmSelectedBossToggle

FarmTab:AddSection("Items & Fighting Styles Progression")

UI_ELEMENTS["AutoGetAllMeleesEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Get All Melees",
    Desc    = "Fly to NPC & buy fighting styles when funds are ready",
    Default = S.AutoGetAllMeleesEnabled or false,
    Callback = function(val)
        S.AutoGetAllMeleesEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoGetAllSwordsEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Get All Swords",
    Desc    = "Auto buy unowned shop swords remotely when funds are ready",
    Default = S.AutoGetAllSwordsEnabled or false,
    Callback = function(val)
        S.AutoGetAllSwordsEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoGetAllGunsEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Get All Guns",
    Desc    = "Auto buy unowned shop guns remotely when funds are ready",
    Default = S.AutoGetAllGunsEnabled or false,
    Callback = function(val)
        S.AutoGetAllGunsEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoGetAllAccessoriesEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Get All Accessories",
    Desc    = "Auto buy unowned shop accessories remotely when funds are ready",
    Default = S.AutoGetAllAccessoriesEnabled or false,
    Callback = function(val)
        S.AutoGetAllAccessoriesEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

FarmTab:AddSection("Mastery Farming (Melee, Sword, Gun)")

UI_ELEMENTS["AutoFarmMasteryMeleeEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Farm Max Mastery Melee",
    Desc    = "Farm mastery on fighting styles with backtracking",
    Default = S.AutoFarmMasteryMeleeEnabled or false,
    Callback = function(val)
        S.AutoFarmMasteryMeleeEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoFarmMasterySwordEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Farm Max Mastery Sword",
    Desc    = "Farm mastery on swords with backtracking",
    Default = S.AutoFarmMasterySwordEnabled or false,
    Callback = function(val)
        S.AutoFarmMasterySwordEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoFarmMasteryGunEnabled"] = FarmTab:AddToggle({
    Name    = "Auto Farm Max Mastery Gun",
    Desc    = "Farm mastery on guns with backtracking",
    Default = S.AutoFarmMasteryGunEnabled or false,
    Callback = function(val)
        S.AutoFarmMasteryGunEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

FarmTab:AddDropdown({
    Name    = "Mastery Target Level",
    Desc    = "Target mastery level threshold",
    Options = { "300", "400", "600" },
    Default = tostring(S.MasteryTargetLevel or 600),
    Callback = function(opt)
        S.MasteryTargetLevel = tonumber(opt) or 600
    end,
})

FarmTab:AddSection("Single Mob Farming")

local MobDropdown = FarmTab:AddDropdown({
    Name    = "Select Target Mob",
    Desc    = "Choose mob to farm",
    Options = Utility.GetAvailableMobsList(),
    Default = S.SelectedMob or "Bandit",
    Callback = function(opt)
        S.SelectedMob = opt
    end,
})

FarmTab:AddButton({
    Name    = "Refresh Mob List",
    Desc    = "Scan available mobs in server",
    Callback = function()
        if MobDropdown then
            MobDropdown:Refresh(Utility.GetAvailableMobsList())
            UILib.Notify("Mob List", "Mob list refreshed!", 2)
        end
    end,
})

AutoFarmSelectedMobToggle = FarmTab:AddToggle({
    Name    = "Auto Farm Selected Mob",
    Desc    = "Farm chosen mob continuously",
    Default = S.AutoFarmSelectedMobEnabled or false,
    Callback = function(val)
        S.AutoFarmSelectedMobEnabled = val
        if val then
            Utility.StartAutoFarmSelectedMob()
        else
            Utility.StopAutoFarmSelectedMob()
        end
    end,
})
UI_ELEMENTS["AutoFarmSelectedMobEnabled"] = AutoFarmSelectedMobToggle

FarmTab:AddSection("Materials & Chests Farming")

FarmTab:AddDropdown({
    Name    = "Select Material",
    Desc    = "Choose material to farm",
    Options = Utility.GetAvailableMaterialsList(),
    Default = S.SelectedMaterial or "Bones",
    Callback = function(opt)
        S.SelectedMaterial = opt
    end,
})

AutoFarmMaterialToggle = FarmTab:AddToggle({
    Name    = "Auto Farm Material",
    Desc    = "Farm mobs dropping selected material",
    Default = S.AutoFarmMaterialEnabled or false,
    Callback = function(val)
        S.AutoFarmMaterialEnabled = val
        if val then
            Utility.StartAutoFarmMaterial()
        else
            Utility.StopAutoFarmMaterial()
        end
    end,
})
UI_ELEMENTS["AutoFarmMaterialEnabled"] = AutoFarmMaterialToggle

AutoFarmChestToggle = FarmTab:AddToggle({
    Name    = "Auto Farm Chests",
    Desc    = "Collect chests across the map",
    Default = S.AutoFarmChestEnabled or false,
    Callback = function(val)
        S.AutoFarmChestEnabled = val
        if val then
            Utility.StartAutoFarmChests()
        else
            Utility.StopAutoFarmChests()
        end
    end,
})
UI_ELEMENTS["AutoFarmChestEnabled"] = AutoFarmChestToggle

FarmTab:AddSection("Auto Stats Distribution")

UI_ELEMENTS["AutoStatsMelee"] = FarmTab:AddToggle({
    Name    = "Auto Stats Melee",
    Desc    = "Auto add points to Melee",
    Default = S.AutoStatsMelee or false,
    Callback = function(val)
        S.AutoStatsMelee = val
        if val then Utility.StartAutoStatsLoop() end
    end,
})

UI_ELEMENTS["AutoStatsDefense"] = FarmTab:AddToggle({
    Name    = "Auto Stats Defense",
    Desc    = "Auto add points to Defense",
    Default = S.AutoStatsDefense or false,
    Callback = function(val)
        S.AutoStatsDefense = val
        if val then Utility.StartAutoStatsLoop() end
    end,
})

UI_ELEMENTS["AutoStatsSword"] = FarmTab:AddToggle({
    Name    = "Auto Stats Sword",
    Desc    = "Auto add points to Sword",
    Default = S.AutoStatsSword or false,
    Callback = function(val)
        S.AutoStatsSword = val
        if val then Utility.StartAutoStatsLoop() end
    end,
})

UI_ELEMENTS["AutoStatsGun"] = FarmTab:AddToggle({
    Name    = "Auto Stats Gun",
    Desc    = "Auto add points to Gun",
    Default = S.AutoStatsGun or false,
    Callback = function(val)
        S.AutoStatsGun = val
        if val then Utility.StartAutoStatsLoop() end
    end,
})

UI_ELEMENTS["AutoStatsFruit"] = FarmTab:AddToggle({
    Name    = "Auto Stats Blox Fruit",
    Desc    = "Auto add points to Demon Fruit",
    Default = S.AutoStatsFruit or false,
    Callback = function(val)
        S.AutoStatsFruit = val
        if val then Utility.StartAutoStatsLoop() end
    end,
})

FarmTab:AddSlider({
    Name    = "Points Per Upgrade",
    Desc    = "Amount of points to add each time",
    Min     = 1, Max = 100, Default = S.StatsPointsAmount or 3, Suffix = " pts",
    Callback = function(v)
        S.StatsPointsAmount = tonumber(v) or 1
    end,
})



-- ═══════════════════════════════════════════════════════════

end

-- ========================================================
-- [TAB BUILDER: FARM SETTING]
-- ========================================================
CTX.TabBuilders['Farm Setting'] = function(Window)
--  TAB 4 : FARM SETTING
-- ═══════════════════════════════════════════════════════════
local FarmSettingTab = Window:AddTab({ Name = "Farm Setting", Icon = "" })

FarmSettingTab:AddSection("Progression & Special Quests")

UI_ELEMENTS["AutoNextSeaEnabled"] = FarmSettingTab:AddToggle({
    Name    = "Auto Next Sea (1 -> 2 -> 3)",
    Desc    = "Auto unlock quest & travel to next Sea",
    Default = (S.AutoNextSeaEnabled ~= nil and S.AutoNextSeaEnabled) or false,
    Callback = function(val)
        S.AutoNextSeaEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoSaberQuestEnabled"] = FarmSettingTab:AddToggle({
    Name    = "Auto Saber Quest (Lv 200+)",
    Desc    = "Auto puzzle & defeat Saber Expert",
    Default = (S.AutoSaberQuestEnabled ~= nil and S.AutoSaberQuestEnabled) or false,
    Callback = function(val)
        if val then
            -- Quét kho đồ của CHỈ VŨ KHÍ kiểm tra nếu có "Saber" rồi thì tự tắt tính năng và gửi thông báo
            if Utility.CheckWeaponInventory("Saber") then
                S.AutoSaberQuestEnabled = false
                task.spawn(function()
                    task.wait(0.05)
                    if UI_ELEMENTS["AutoSaberQuestEnabled"] and UI_ELEMENTS["AutoSaberQuestEnabled"].Set then
                        UI_ELEMENTS["AutoSaberQuestEnabled"]:Set(false)
                    end
                end)
                UILib.Notify("Saber Quest", "Saber is already owned in weapon inventory! Feature disabled.", 4)
                return
            end
            S.AutoSaberQuestEnabled = true
            Utility.StartPipelineCoordinator()
        else
            S.AutoSaberQuestEnabled = false
        end
    end,
})

UI_ELEMENTS["AutoTheSonQuestEnabled"] = FarmSettingTab:AddToggle({
    Name    = "Auto The Son Quest (Rich Son)",
    Desc    = "Auto help Sick Man & kill Mob Leader",
    Default = (S.AutoTheSonQuestEnabled ~= nil and S.AutoTheSonQuestEnabled) or false,
    Callback = function(val)
        S.AutoTheSonQuestEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoMilitaryDetectiveQuestEnabled"] = FarmSettingTab:AddToggle({
    Name    = "Auto Military Detective Quest (Lv 700+)",
    Desc    = "Auto Key puzzle, kill Ice Admiral & travel Sea 2",
    Default = (S.AutoMilitaryDetectiveQuestEnabled ~= nil and S.AutoMilitaryDetectiveQuestEnabled) or false,
    Callback = function(val)
        S.AutoMilitaryDetectiveQuestEnabled = val
        if val then Utility.StartPipelineCoordinator() end
    end,
})

UI_ELEMENTS["AutoBartiloQuestEnabled"] = FarmSettingTab:AddToggle({
    Name    = "Auto Bartilo Quest (Lv 850+)",
    Desc    = "Auto Bartilo quest & Colosseum puzzle",
    Default = (S.AutoBartiloQuestEnabled ~= nil and S.AutoBartiloQuestEnabled) or false,
    Callback = function(val)
        if val then
            -- Quét kho đồ CHỈ ACCESSORY có "Warrior Helmet" thì dừng và gửi thông báo
            if Utility.CheckAccessoryInventory("Warrior Helmet") then
                S.AutoBartiloQuestEnabled = false
                task.spawn(function()
                    task.wait(0.05)
                    if UI_ELEMENTS["AutoBartiloQuestEnabled"] and UI_ELEMENTS["AutoBartiloQuestEnabled"].Set then
                        UI_ELEMENTS["AutoBartiloQuestEnabled"]:Set(false)
                    end
                end)
                UILib.Notify("Bartilo Quest", "Warrior Helmet already owned in accessory inventory! Quest stopped.", 4)
                return
            end
            S.AutoBartiloQuestEnabled = true
            Utility.StartPipelineCoordinator() 
        else
            Utility.StopAutoBartiloQuest()
        end
    end,
})

UI_ELEMENTS["AutoDonSwanQuestEnabled"] = FarmSettingTab:AddToggle({
    Name    = "Auto Don Swan Quest (Lv 1000+)",
    Desc    = "Auto unlock Trevor with 1M fruit & defeat Don Swan for Swan Glasses",
    Default = (S.AutoDonSwanQuestEnabled ~= nil and S.AutoDonSwanQuestEnabled) or false,
    Callback = function(val)
        if val then
            -- Kiểm tra kho accessory xem đã có "Swan Glasses" chưa
            if Utility.CheckAccessoryInventory("Swan Glasses") then
                S.AutoDonSwanQuestEnabled = false
                task.spawn(function()
                    task.wait(0.05)
                    if UI_ELEMENTS["AutoDonSwanQuestEnabled"] and UI_ELEMENTS["AutoDonSwanQuestEnabled"].Set then
                        UI_ELEMENTS["AutoDonSwanQuestEnabled"]:Set(false)
                    end
                end)
                UILib.Notify("Don Swan Quest", "Swan Glasses already owned in accessory inventory! Disabling quest.", 4)
                return
            end
            if not Utility.IsTrevorUnlocked() and not Utility.CanDoDonSwanQuest() then
                UILib.Notify("Don Swan Quest", "Trevor is locked and no 1M+ fruit found in storage! Will farm level until 1M+ fruit is available.", 5)
            elseif Utility.IsTrevorUnlocked() and not Utility.IsDonSwanSpawnAvailable() then
                UILib.Notify("Don Swan Quest", "Auto Don Swan enabled! Waiting for boss in EnemySpawns...", 4)
            end
            S.AutoDonSwanQuestEnabled = true
            Utility.StartPipelineCoordinator() 
        else
            Utility.StopAutoDonSwanQuest()
        end
    end,
})

FarmSettingTab:AddSection("Race Skills & Awakening")

UI_ELEMENTS["AutoRaceV3V4"] = FarmSettingTab:AddToggle({
    Name    = "Auto Race V3 & V4 Awakening",
    Desc    = "Auto V3 (31s cd) & Auto V4 (1s cd)",
    Default = (S.AutoRaceV3V4 ~= nil) and S.AutoRaceV3V4 or true,
    Callback = function(val)
        S.AutoRaceV3V4 = val
        S.AutoRaceV3 = val
        S.AutoAwakeningV4 = val
        if val then
            Utility.StartAutoAwakeningLoop()
        end
    end,
})

UI_ELEMENTS["AutoObservation"] = FarmSettingTab:AddToggle({
    Name    = "Auto Observation Haki (Ken)",
    Desc    = "Automatically activate Ken Haki when KenTrail emission is disabled",
    Default = (S.AutoObservation ~= nil) and S.AutoObservation or false,
    Callback = function(val)
        S.AutoObservation = val
        if val then
            Utility.StartAutoObservationLoop()
        else
            DisconnectConnection("autoObservationLoop")
        end
    end,
})

FarmSettingTab:AddSection("Skill Hold Settings")

UI_ELEMENTS["HoldMeleeSkills"] = FarmSettingTab:AddToggle({
    Name    = "Hold Melee Skills",
    Desc    = "Hold Melee skills  ",
    Default = S.HoldMeleeSkills or false,
    Callback = function(val) S.HoldMeleeSkills = val end,
})

UI_ELEMENTS["HoldFruitSkills"] = FarmSettingTab:AddToggle({
    Name    = "Hold Fruit Skills",
    Desc    = "Hold Fruit skills  ",
    Default = S.HoldFruitSkills or false,
    Callback = function(val) S.HoldFruitSkills = val end,
})

UI_ELEMENTS["HoldSwordSkills"] = FarmSettingTab:AddToggle({
    Name    = "Hold Sword Skills",
    Desc    = "Hold Sword skills  ",
    Default = S.HoldSwordSkills or false,
    Callback = function(val) S.HoldSwordSkills = val end,
})

UI_ELEMENTS["HoldGunSkills"] = FarmSettingTab:AddToggle({
    Name    = "Hold Gun Skills",
    Desc    = "Hold Gun skills  ",
    Default = S.HoldGunSkills or false,
    Callback = function(val) S.HoldGunSkills = val end,
})

FarmSettingTab:AddSlider({
    Name    = "Skill Hold Duration",
    Desc    = "Duration to hold skill (seconds)",
    Min     = 0.1, Max = 3.0, Default = S.SkillHoldDuration or 0.35, Suffix = "s",
    Callback = function(v)
        S.SkillHoldDuration = v
    end,
})

FarmSettingTab:AddSection("Melee Skills (Z, X, C)")

UI_ELEMENTS["MeleeSkillZ"] = FarmSettingTab:AddToggle({
    Name    = "Use Melee Skill Z",
    Desc    = "Enable/disable Melee Z",
    Default = (S.MeleeSkillZ ~= nil) and S.MeleeSkillZ or true,
    Callback = function(val) S.MeleeSkillZ = val end,
})

UI_ELEMENTS["MeleeSkillX"] = FarmSettingTab:AddToggle({
    Name    = "Use Melee Skill X",
    Desc    = "Enable/disable Melee X",
    Default = (S.MeleeSkillX ~= nil) and S.MeleeSkillX or true,
    Callback = function(val) S.MeleeSkillX = val end,
})

UI_ELEMENTS["MeleeSkillC"] = FarmSettingTab:AddToggle({
    Name    = "Use Melee Skill C",
    Desc    = "Enable/disable Melee C",
    Default = (S.MeleeSkillC ~= nil) and S.MeleeSkillC or true,
    Callback = function(val) S.MeleeSkillC = val end,
})

FarmSettingTab:AddSection("Fruit Skills (Z, X, C, V, F)")

UI_ELEMENTS["FruitSkillZ"] = FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill Z",
    Desc    = "Enable/disable Fruit Z",
    Default = (S.FruitSkillZ ~= nil) and S.FruitSkillZ or true,
    Callback = function(val) S.FruitSkillZ = val end,
})

UI_ELEMENTS["FruitSkillX"] = FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill X",
    Desc    = "Enable/disable Fruit X",
    Default = (S.FruitSkillX ~= nil) and S.FruitSkillX or true,
    Callback = function(val) S.FruitSkillX = val end,
})

UI_ELEMENTS["FruitSkillC"] = FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill C",
    Desc    = "Enable/disable Fruit C",
    Default = (S.FruitSkillC ~= nil) and S.FruitSkillC or true,
    Callback = function(val) S.FruitSkillC = val end,
})

UI_ELEMENTS["FruitSkillV"] = FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill V",
    Desc    = "Enable/disable Fruit V",
    Default = (S.FruitSkillV ~= nil) and S.FruitSkillV or true,
    Callback = function(val) S.FruitSkillV = val end,
})

UI_ELEMENTS["FruitSkillF"] = FarmSettingTab:AddToggle({
    Name    = "Use Fruit Skill F",
    Desc    = "Enable/disable Fruit F",
    Default = (S.FruitSkillF ~= nil) and S.FruitSkillF or true,
    Callback = function(val) S.FruitSkillF = val end,
})

FarmSettingTab:AddSection("Sword Skills (Z, X)")

UI_ELEMENTS["SwordSkillZ"] = FarmSettingTab:AddToggle({
    Name    = "Use Sword Skill Z",
    Desc    = "Enable/disable Sword Z",
    Default = (S.SwordSkillZ ~= nil) and S.SwordSkillZ or true,
    Callback = function(val) S.SwordSkillZ = val end,
})

UI_ELEMENTS["SwordSkillX"] = FarmSettingTab:AddToggle({
    Name    = "Use Sword Skill X",
    Desc    = "Enable/disable Sword X",
    Default = (S.SwordSkillX ~= nil) and S.SwordSkillX or true,
    Callback = function(val) S.SwordSkillX = val end,
})

FarmSettingTab:AddSection("Gun Skills (Z, X)")

UI_ELEMENTS["GunSkillZ"] = FarmSettingTab:AddToggle({
    Name    = "Use Gun Skill Z",
    Desc    = "Enable/disable Gun Z",
    Default = (S.GunSkillZ ~= nil) and S.GunSkillZ or true,
    Callback = function(val) S.GunSkillZ = val end,
})

UI_ELEMENTS["GunSkillX"] = FarmSettingTab:AddToggle({
    Name    = "Use Gun Skill X",
    Desc    = "Enable/disable Gun X",
    Default = (S.GunSkillX ~= nil) and S.GunSkillX or true,
    Callback = function(val) S.GunSkillX = val end,
})


-- ═══════════════════════════════════════════════════════════

end
