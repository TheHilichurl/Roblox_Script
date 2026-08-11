-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- Global Variables
local Settings = {
    BoatFlySpeed = 220,
    BoatFlyHeight = 195,
    TeleportSpeed = 220,
    CustomBoatSpeed = 250,
    EnableBoatSpeed = false,
    WebhookURL = "",
    WebhookEnabled = true,
    FindLeviathanEnabled = false,
    BoatNoClipEnabled = false,
    PlayerNoClipEnabled = false,
    WalkOnWaterEnabled = true,
    AntiAFKEnabled = true,
    TeleportPlayerEnabled = false,
    SelectedPlayer = nil
}

local WebhookSent = false
local FindLeviathanConnection = nil
local FindLeviathanToggle = nil 
local TeleportConnection = nil
local BoatSpeedConnection = nil

-- Rayfield UI Library Setup (Bao bọc trong pcall)
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Không thể tải Rayfield UI. Hãy kiểm tra kết nối mạng/DNS!")
    return
end

local Window = Rayfield:CreateWindow({
   Name = "Leviathan Hunter | Utility Hub",
   LoadingTitle = "Leviathan Script Loading...",
   LoadingSubtitle = "by Assistant",
   ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Main Features", 4483362458)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local MiscTab = Window:CreateTab("Misc & Optimize", 4483362458)
local WebhookTab = Window:CreateTab("Webhook Config", 4483362458)

-- Utility Functions
local function GetBoat()
    local character = LocalPlayer.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
        return humanoid.SeatPart.Parent
    end
    return nil
end

local function ForceStopBoat(boat)
    if not boat then return end
    task.spawn(function()
        for i = 1, 10 do
            for _, part in ipairs(boat:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
            local seat = boat:FindFirstChildOfClass("VehicleSeat") or boat.PrimaryPart
            if seat then
                if seat:FindFirstChild("FlyLinearVelocity") then seat.FlyLinearVelocity:Destroy() end
                if seat:FindFirstChild("FlyAlignOrientation") then seat.FlyAlignOrientation:Destroy() end
                if seat:FindFirstChild("FlyAttachment") then seat.FlyAttachment:Destroy() end
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

local function ForceNoClipModel(model)
    if not model then return end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsA("Seat") and not part:IsA("VehicleSeat") then
            part.CanCollide = false
            part.CanTouch = true
        end
    end
end

local function OptimizeGraphics()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 1
    
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
            v:Destroy()
        end
    end

    pcall(function() settings().Rendering.QualityLevel = 1 end)

    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
    end

    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.SmoothPlastic
            part.Reflectance = 0
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part:Destroy()
        end
    end
end

local function IsFrozenWatcherExist()
    local frozenNPC = workspace:FindFirstChild("Frozen Watcher", true) 
    local frozenIsland = workspace:FindFirstChild("FrozenDimension", true) or workspace:FindFirstChild("Frozen Island", true)
    return (frozenNPC or frozenIsland) and true or false
end

local function SendWebhookNotification()
    if WebhookSent or not Settings.WebhookEnabled or Settings.WebhookURL == "" then return end
    local request = (syn and syn.request) or (http and http.request) or http_request or fluxus and fluxus.request or request
    if request then
        WebhookSent = true
        local payload = {
            ["content"] = "@here **LEVIATHAN HAS SPAWNED!**",
            ["embeds"] = {{
                ["title"] = "❄️ Frozen Dimension Alert!",
                ["description"] = "Đã tìm thấy **Frozen Watcher / Leviathan** trong Server!",
                ["color"] = 65535,
                ["fields"] = {
                    { ["name"] = "Player", ["value"] = LocalPlayer.Name, ["inline"] = true },
                    { ["name"] = "Job ID", ["value"] = game.JobId, ["inline"] = true }
                },
                ["timestamp"] = DateTime.now():ToIsoDate()
            }}
        }
        request({
            Url = Settings.WebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end
end

-- Walk On Water Logic
local WaterPart = Instance.new("Part")
WaterPart.Name = "JesusWaterPart"
WaterPart.Size = Vector3.new(20000, 2, 20000)
WaterPart.Transparency = 0.8
WaterPart.Color = Color3.fromRGB(0, 170, 255)
WaterPart.Material = Enum.Material.SmoothPlastic
WaterPart.Anchored = true
WaterPart.CanCollide = false
WaterPart.Parent = workspace

RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local root = character.HumanoidRootPart
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if humanoid and humanoid.SeatPart then
            WaterPart.CanCollide = false
            return
        end

        if Settings.WalkOnWaterEnabled then
            WaterPart.CFrame = CFrame.new(root.Position.X, -1, root.Position.Z)
            if root.Position.Y >= -5 then
                WaterPart.CanCollide = true
            else
                WaterPart.CanCollide = false
            end
        else
            WaterPart.CanCollide = false
        end
    else
        WaterPart.CanCollide = false
    end
end)

-- ==================== ANTI-AFK (ĐÃ SỬA) ====================
local function SetupAntiAFK()
    if not Settings.AntiAFKEnabled then return end
    pcall(function()
        VirtualUser:CaptureController()
    end)
end

SetupAntiAFK()  -- Gọi khởi tạo một lần

LocalPlayer.Idled:Connect(function()
    if Settings.AntiAFKEnabled then
        pcall(function()
            VirtualUser:ClickButton2(Vector2.new())  -- Dùng Vector2 thay vì Vector3
        end)
    end
end)
-- ============================================================

-- Check Leviathan Loop
task.spawn(function()
    while task.wait(1) do
        if IsFrozenWatcherExist() then
            if not WebhookSent and Settings.WebhookEnabled and Settings.WebhookURL ~= "" then
                SendWebhookNotification()
            end
            if Settings.FindLeviathanEnabled and FindLeviathanToggle then
                FindLeviathanToggle:Set(false)
                Rayfield:Notify({
                    Title = "❄️ LEVIATHAN SPAWNED!",
                    Content = "Phát hiện Frozen Watcher! Đã dừng thuyền lập tức.",
                    Duration = 6,
                    Image = 4483362458
                })
            end
        end
    end
end)

-- Execute Noclip Logic
local function ExecuteNoClipLogic()
    if Settings.PlayerNoClipEnabled and LocalPlayer.Character then
        ForceNoClipModel(LocalPlayer.Character)
    end
    if Settings.BoatNoClipEnabled or Settings.FindLeviathanEnabled then
        if LocalPlayer.Character then ForceNoClipModel(LocalPlayer.Character) end
        local boat = GetBoat()
        if boat then ForceNoClipModel(boat) end
    end
end

RunService.Stepped:Connect(ExecuteNoClipLogic)
RunService.RenderStepped:Connect(ExecuteNoClipLogic)

-- Main Tab UI
FindLeviathanToggle = MainTab:CreateToggle({
   Name = "Find Leviathan",
   CurrentValue = false,
   Callback = function(Value)
      Settings.FindLeviathanEnabled = Value
      Settings.BoatNoClipEnabled = Value
      local character = LocalPlayer.Character
      local boat = GetBoat()
      
      if Value then
          if IsFrozenWatcherExist() then
              FindLeviathanToggle:Set(false)
              Rayfield:Notify({Title = "Thông Báo", Content = "Đã xuất hiện Frozen Dimension!", Duration = 5})
              return
          end
          if not character or not boat then
              FindLeviathanToggle:Set(false)
              Rayfield:Notify({Title = "Lỗi", Content = "Bạn phải ngồi trên ghế lái thuyền!", Duration = 3})
              return
          end
          
          local seat = boat:FindFirstChildOfClass("VehicleSeat") or boat.PrimaryPart
          if not seat then return end

          for _, part in ipairs(boat:GetDescendants()) do
              if part:IsA("BasePart") then
                  part.AssemblyLinearVelocity = Vector3.zero
                  part.AssemblyAngularVelocity = Vector3.zero
              end
          end

          local attachment = seat:FindFirstChild("FlyAttachment") or Instance.new("Attachment")
          attachment.Name = "FlyAttachment"
          attachment.Parent = seat

          local lv = seat:FindFirstChild("FlyLinearVelocity") or Instance.new("LinearVelocity")
          lv.Name = "FlyLinearVelocity"
          lv.Attachment0 = attachment
          lv.MaxForce = math.huge
          lv.RelativeTo = Enum.ActuatorRelativeTo.World
          lv.Parent = seat

          local ao = seat:FindFirstChild("FlyAlignOrientation") or Instance.new("AlignOrientation")
          ao.Name = "FlyAlignOrientation"
          ao.Attachment0 = attachment
          ao.MaxTorque = math.huge
          ao.Responsiveness = 200
          ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
          ao.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(0, 0, 1))
          ao.Parent = seat

          local startY = seat.Position.Y
          local targetUpY = 800
          local flyUpDuration = 10 
          local startTime = os.clock()

          FindLeviathanConnection = RunService.Heartbeat:Connect(function()
              if not Settings.FindLeviathanEnabled or seat.Occupant == nil or IsFrozenWatcherExist() then
                  if FindLeviathanConnection then FindLeviathanConnection:Disconnect() end
                  ForceStopBoat(boat)
                  if Settings.FindLeviathanEnabled and FindLeviathanToggle then FindLeviathanToggle:Set(false) end
                  return
              end

              local currentPos = seat.Position
              local elapsedTime = os.clock() - startTime

              if elapsedTime <= flyUpDuration then
                  local progress = elapsedTime / flyUpDuration
                  local currentTargetY = startY + (targetUpY - startY) * progress
                  local yVelocity = (currentTargetY - currentPos.Y) * 15
                  lv.VectorVelocity = Vector3.new(0, yVelocity, 0)
              elseif elapsedTime <= (flyUpDuration + 4) then
                  local yVelocity = (800 - currentPos.Y) * 10
                  lv.VectorVelocity = Vector3.new(-Settings.BoatFlySpeed, yVelocity, 0)
              else
                  local yVelocity = (Settings.BoatFlyHeight - currentPos.Y) * 5
                  lv.VectorVelocity = Vector3.new(-Settings.BoatFlySpeed, yVelocity, 0)
              end
          end)
      else
          if FindLeviathanConnection then FindLeviathanConnection:Disconnect() end
          ForceStopBoat(boat)
          Settings.BoatNoClipEnabled = false
      end
   end,
})

MainTab:CreateSlider({
   Name = "Fly Speed",
   Range = {100, 350},
   Increment = 5,
   Suffix = "studs/s",
   CurrentValue = Settings.BoatFlySpeed,
   Callback = function(Value) Settings.BoatFlySpeed = Value end,
})

MainTab:CreateSlider({
   Name = "BoatFlyHeight",
   Range = {20, 300},
   Increment = 5,
   Suffix = "Studs Y",
   CurrentValue = Settings.BoatFlyHeight,
   Callback = function(Value) Settings.BoatFlyHeight = Value end,
})

MainTab:CreateToggle({
   Name = "Enable Boat Speed",
   CurrentValue = false,
   Callback = function(Value)
      Settings.EnableBoatSpeed = Value
      if Value then
          BoatSpeedConnection = RunService.Heartbeat:Connect(function()
              if not Settings.EnableBoatSpeed then
                  if BoatSpeedConnection then BoatSpeedConnection:Disconnect() end
                  return
              end
              local boat = GetBoat()
              if boat then
                  local seat = boat:FindFirstChildOfClass("VehicleSeat")
                  if seat then
                      seat.MaxSpeed = Settings.CustomBoatSpeed
                      local moveVector = seat.CFrame.LookVector * (seat.ThrottleFloat * Settings.CustomBoatSpeed)
                      seat.AssemblyLinearVelocity = Vector3.new(moveVector.X, seat.AssemblyLinearVelocity.Y, moveVector.Z)
                  end
              end
          end)
      else
          if BoatSpeedConnection then BoatSpeedConnection:Disconnect() end
      end
   end,
})

MainTab:CreateSlider({
   Name = "Boat Speed",
   Range = {100, 500},
   Increment = 5,
   Suffix = "Speed",
   CurrentValue = Settings.CustomBoatSpeed,
   Callback = function(Value) Settings.CustomBoatSpeed = Value end,
})

-- Teleport Tab UI
local playerNames = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then table.insert(playerNames, p.Name) end
end

local PlayerDropdown = TeleportTab:CreateDropdown({
   Name = "Select Player",
   Options = playerNames,
   CurrentOption = "",
   Callback = function(Option)
      Settings.SelectedPlayer = Players:FindFirstChild(Option[1] or Option)
   end,
})

Players.PlayerAdded:Connect(function(p)
    table.insert(playerNames, p.Name)
    PlayerDropdown:Refresh(playerNames)
end)

Players.PlayerRemoving:Connect(function(p)
    for i, name in ipairs(playerNames) do
        if name == p.Name then table.remove(playerNames, i) break end
    end
    PlayerDropdown:Refresh(playerNames)
end)

TeleportTab:CreateToggle({
   Name = "Teleport to Player",
   CurrentValue = false,
   Callback = function(Value)
      Settings.TeleportPlayerEnabled = Value
      if Value then
          if not Settings.SelectedPlayer or not Settings.SelectedPlayer.Character then
              Rayfield:Notify({Title = "Lỗi", Content = "Hãy chọn người chơi hợp lệ!", Duration = 3})
              return
          end
          TeleportConnection = RunService.Heartbeat:Connect(function()
              if not Settings.TeleportPlayerEnabled or not Settings.SelectedPlayer or not Settings.SelectedPlayer.Character then
                  if TeleportConnection then TeleportConnection:Disconnect() end
                  return
              end
              local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
              local targetRoot = Settings.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
              if myRoot and targetRoot then
                  local targetCFrame = targetRoot.CFrame * CFrame.new(0, 2, 3)
                  myRoot.CFrame = myRoot.CFrame:Lerp(targetCFrame, 0.2)
              end
          end)
      else
          if TeleportConnection then TeleportConnection:Disconnect() end
      end
   end,
})

-- Misc Tab UI
MiscTab:CreateToggle({
   Name = "Walk On Water (Jesus)",
   CurrentValue = Settings.WalkOnWaterEnabled,
   Callback = function(Value) Settings.WalkOnWaterEnabled = Value end,
})

MiscTab:CreateToggle({
   Name = "Player Noclip",
   CurrentValue = false,
   Callback = function(Value) Settings.PlayerNoClipEnabled = Value end,
})

MiscTab:CreateToggle({
   Name = "Anti-AFK",
   CurrentValue = Settings.AntiAFKEnabled,
   Callback = function(Value) Settings.AntiAFKEnabled = Value end,
})

MiscTab:CreateButton({
   Name = "Boost FPS / Smooth Graphics",
   Callback = function()
      OptimizeGraphics()
      Rayfield:Notify({Title = "Tối Ưu Đồ Họa", Content = "Đã dọn dẹp hiệu ứng!", Duration = 4})
   end,
})

-- Webhook Tab UI
WebhookTab:CreateToggle({
   Name = "Webhook when Leviathan Spawn",
   CurrentValue = Settings.WebhookEnabled,
   Callback = function(Value) Settings.WebhookEnabled = Value end,
})

WebhookTab:CreateInput({
   Name = "Discord Webhook URL",
   PlaceholderText = "Paste Webhook URL...",
   RemoveTextOnFocus = false,
   Callback = function(Text) Settings.WebhookURL = Text end,
})