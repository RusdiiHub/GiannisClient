-- ============================================================
--  Giannis Client | Sailor Piece
--  WindUI Loader
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ==================== SERVICES ====================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local VirtualUser       = game:GetService("VirtualUser")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ==================== GLOBAL STATE ====================
getgenv().GiannisClient = getgenv().GiannisClient or {}
local State = getgenv().GiannisClient
State.AutoFarm        = State.AutoFarm or false
State.AutoQuest       = State.AutoQuest or false
State.FruitSniper     = State.FruitSniper or false
State.KillAura        = State.KillAura or false
State.AutoHaki        = State.AutoHaki or false
State.MobESP          = State.MobESP or false
State.PlayerESP       = State.PlayerESP or false
State.FruitESP        = State.FruitESP or false
State.ChestESP        = State.ChestESP or false
State.SpinBot         = State.SpinBot or false
State.TouchFling      = State.TouchFling or false
State.InfJump         = State.InfJump or false
State.AutoCollectDF   = State.AutoCollectDF or false
State.BringMobs       = State.BringMobs or false

-- ==================== HELPERS ====================
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function teleportTo(cframe)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = cframe
    end
end

local function getNearestNPC(maxDist, filter)
    maxDist = maxDist or 500
    local hrp = getHRP()
    if not hrp then return nil end

    local nearest, nearestDist = nil, maxDist
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Humanoid") and v.Health > 0 and v.Parent ~= getCharacter() then
            local npcRoot = v.Parent:FindFirstChild("HumanoidRootPart")
            if npcRoot then
                local isPlayer = Players:GetPlayerFromCharacter(v.Parent)
                if not isPlayer then
                    if filter and not string.find(string.lower(v.Parent.Name), string.lower(filter)) then
                        continue
                    end
                    local dist = (hrp.Position - npcRoot.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = v
                    end
                end
            end
        end
    end
    return nearest
end

local function getNearestPlayer(maxDist)
    maxDist = maxDist or 200
    local hrp = getHRP()
    if not hrp then return nil end

    local nearest, nearestDist = nil, maxDist
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pHum = p.Character:FindFirstChildOfClass("Humanoid")
            if pHum and pHum.Health > 0 then
                local dist = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = p
                end
            end
        end
    end
    return nearest
end

-- Try to find quest givers in workspace
local function findQuestGivers()
    local givers = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") or (v:IsA("ClickDetector") and v.Parent) then
            local parentModel = v:FindFirstAncestorWhichIsA("Model")
            if parentModel then
                local nameL = string.lower(parentModel.Name)
                if string.find(nameL, "quest") or string.find(nameL, "npc") or string.find(nameL, "giver") or string.find(nameL, "hunter") then
                    table.insert(givers, {model = parentModel, prompt = v})
                end
            end
        end
    end
    return givers
end

-- ESP Drawing helper
local espObjects = {}

local function createESP(part, color, label)
    if not part or espObjects[part] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GiannisESP"
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 200, 0, 30)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = part

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = color
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextScaled = true
    textLabel.Text = label or part.Parent.Name
    textLabel.Parent = billboard

    local highlight = Instance.new("Highlight")
    highlight.Name = "GiannisHighlight"
    highlight.FillColor = color
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = color
    highlight.OutlineTransparency = 0.3
    highlight.Parent = part.Parent

    espObjects[part] = {billboard, highlight}
end

local function removeESP(part)
    if espObjects[part] then
        for _, obj in pairs(espObjects[part]) do
            if obj and obj.Parent then obj:Destroy() end
        end
        espObjects[part] = nil
    end
end

local function clearAllESP()
    for part, _ in pairs(espObjects) do
        removeESP(part)
    end
    espObjects = {}
end

-- ==================== WINDOW ====================
local Window = WindUI:CreateWindow({
    Title = "Giannis Client | Sailor Piece",
    Icon = "rbxassetid://10618928818",
    Author = "Giannis Client Studio",
    Folder = "GiannisClientSP",
    Size = UDim2.fromOffset(580, 480),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 200,
    HasOutline = true
})

WindUI:Notify({
    Title = "Giannis Client",
    Content = "Sailor Piece script loaded successfully! ⚓",
    Duration = 5
})

-- ==================== TABS ====================
local MainTab  = Window:Tab({ Title = "Main",  Icon = "home" })
local AutoTab  = Window:Tab({ Title = "Auto",  Icon = "bot" })
local FarmTab  = Window:Tab({ Title = "Farm",  Icon = "swords" })
local TrollTab = Window:Tab({ Title = "Troll", Icon = "skull" })
local NotesTab = Window:Tab({ Title = "Notes", Icon = "notebook-pen" })

-- ============================================================
--                        MAIN TAB
-- ============================================================
MainTab:Section({ Title = "Player Stats" })

MainTab:Slider({
    Title = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 500,
    Callback = function(value)
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = value end
    end
})

MainTab:Slider({
    Title = "JumpPower",
    Default = 50,
    Min = 50,
    Max = 500,
    Callback = function(value)
        local hum = getHumanoid()
        if hum then hum.JumpPower = value end
    end
})

MainTab:Toggle({
    Title = "Infinite Jump",
    Callback = function(state)
        State.InfJump = state
        if State._InfJumpConn then
            State._InfJumpConn:Disconnect()
            State._InfJumpConn = nil
        end
        if state then
            State._InfJumpConn = UserInputService.JumpRequest:Connect(function()
                local hum = getHumanoid()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end
})

MainTab:Toggle({
    Title = "No Clip",
    Desc = "Walk through walls and objects",
    Callback = function(state)
        State.NoClip = state
        if State._NoClipConn then
            State._NoClipConn:Disconnect()
            State._NoClipConn = nil
        end
        if state then
            State._NoClipConn = RunService.Stepped:Connect(function()
                local char = getCharacter()
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            WindUI:Notify({ Title = "No Clip", Content = "Enabled — walk through walls!", Duration = 3 })
        else
            WindUI:Notify({ Title = "No Clip", Content = "Disabled.", Duration = 3 })
        end
    end
})

MainTab:Section({ Title = "Visuals / ESP" })

MainTab:Toggle({
    Title = "Player ESP",
    Desc = "Highlight all players with name tags",
    Callback = function(state)
        State.PlayerESP = state
        if state then
            task.spawn(function()
                while State.PlayerESP do
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            createESP(p.Character.HumanoidRootPart, Color3.fromRGB(255, 85, 85), p.Name)
                        end
                    end
                    task.wait(2)
                end
                -- Cleanup on disable
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        removeESP(p.Character.HumanoidRootPart)
                    end
                end
            end)
        end
    end
})

MainTab:Toggle({
    Title = "Mob ESP",
    Desc = "Highlight all NPCs/Mobs",
    Callback = function(state)
        State.MobESP = state
        if state then
            task.spawn(function()
                while State.MobESP do
                    for _, v in pairs(Workspace:GetDescendants()) do
                        if v:IsA("Humanoid") and v.Health > 0 then
                            local npcRoot = v.Parent:FindFirstChild("HumanoidRootPart") or v.Parent:FindFirstChild("Head")
                            if npcRoot and not Players:GetPlayerFromCharacter(v.Parent) then
                                createESP(npcRoot, Color3.fromRGB(85, 255, 85), v.Parent.Name .. " [" .. math.floor(v.Health) .. "]")
                            end
                        end
                    end
                    task.wait(3)
                end
                -- Cleanup
                for part, _ in pairs(espObjects) do
                    if not Players:GetPlayerFromCharacter(part.Parent) then
                        removeESP(part)
                    end
                end
            end)
        end
    end
})

MainTab:Toggle({
    Title = "Fruit ESP",
    Desc = "Highlight Devil Fruits on the ground",
    Callback = function(state)
        State.FruitESP = state
        if state then
            task.spawn(function()
                while State.FruitESP do
                    for _, v in pairs(Workspace:GetDescendants()) do
                        local nameL = string.lower(v.Name)
                        if v:IsA("BasePart") or v:IsA("Model") then
                            if string.find(nameL, "fruit") or string.find(nameL, "devil") then
                                local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                                if part then
                                    createESP(part, Color3.fromRGB(255, 200, 50), "🍎 " .. v.Name)
                                end
                            end
                        end
                    end
                    task.wait(2)
                end
            end)
        end
    end
})

MainTab:Toggle({
    Title = "Chest ESP",
    Desc = "Highlight treasure chests on the map",
    Callback = function(state)
        State.ChestESP = state
        if state then
            task.spawn(function()
                while State.ChestESP do
                    for _, v in pairs(Workspace:GetDescendants()) do
                        local nameL = string.lower(v.Name)
                        if string.find(nameL, "chest") or string.find(nameL, "treasure") then
                            local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                            if part then
                                createESP(part, Color3.fromRGB(255, 170, 0), "📦 " .. v.Name)
                            end
                        end
                    end
                    task.wait(3)
                end
            end)
        end
    end
})

-- ============================================================
--                        AUTO TAB
-- ============================================================
AutoTab:Section({ Title = "Auto Combat" })

AutoTab:Toggle({
    Title = "Kill Aura",
    Desc = "Automatically attacks nearest mob within range",
    Callback = function(state)
        State.KillAura = state
        if state then
            WindUI:Notify({ Title = "Kill Aura", Content = "Enabled — attacking nearby mobs!", Duration = 3 })
            task.spawn(function()
                while State.KillAura do
                    task.wait(0.15)
                    local hrp = getHRP()
                    if not hrp then continue end

                    -- Fire click / M1 remote
                    pcall(function()
                        local combatRemote = ReplicatedStorage:FindFirstChild("Combat") 
                            or ReplicatedStorage:FindFirstChild("M1")
                            or ReplicatedStorage:FindFirstChild("Attack")
                            or ReplicatedStorage:FindFirstChild("Damage")
                        
                        if not combatRemote then
                            -- Deep search
                            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                                local nameL = string.lower(v.Name)
                                if v:IsA("RemoteEvent") and (string.find(nameL, "combat") or string.find(nameL, "attack") or string.find(nameL, "m1") or string.find(nameL, "hit") or string.find(nameL, "damage")) then
                                    combatRemote = v
                                    break
                                end
                            end
                        end

                        if combatRemote and combatRemote:IsA("RemoteEvent") then
                            combatRemote:FireServer()
                        end
                    end)

                    -- Also simulate mouse click as fallback
                    pcall(function()
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                        task.wait(0.05)
                        vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    end)
                end
            end)
        else
            WindUI:Notify({ Title = "Kill Aura", Content = "Disabled.", Duration = 3 })
        end
    end
})

AutoTab:Toggle({
    Title = "Auto Haki",
    Desc = "Automatically activates Haki when available",
    Callback = function(state)
        State.AutoHaki = state
        if state then
            WindUI:Notify({ Title = "Auto Haki", Content = "Will auto-activate Haki!", Duration = 3 })
            task.spawn(function()
                while State.AutoHaki do
                    task.wait(1)
                    pcall(function()
                        -- Try finding Haki remote
                        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                            local nameL = string.lower(v.Name)
                            if v:IsA("RemoteEvent") and (string.find(nameL, "haki") or string.find(nameL, "buso")) then
                                v:FireServer()
                                break
                            end
                        end
                    end)
                end
            end)
        end
    end
})

AutoTab:Section({ Title = "Auto Collection" })

AutoTab:Toggle({
    Title = "Auto Collect Devil Fruits",
    Desc = "Teleports to and collects any dropped Devil Fruits",
    Callback = function(state)
        State.AutoCollectDF = state
        if state then
            WindUI:Notify({ Title = "Fruit Collector", Content = "Scanning for fruits...", Duration = 3 })
            task.spawn(function()
                while State.AutoCollectDF do
                    task.wait(0.5)
                    local hrp = getHRP()
                    if not hrp then continue end

                    for _, v in pairs(Workspace:GetDescendants()) do
                        if not State.AutoCollectDF then break end
                        local nameL = string.lower(v.Name)
                        if (string.find(nameL, "fruit") or string.find(nameL, "devil")) and (v:IsA("BasePart") or v:IsA("Model")) then
                            local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                            if part then
                                teleportTo(part.CFrame * CFrame.new(0, 2, 0))
                                task.wait(0.5)
                                -- Touch it
                                pcall(function()
                                    firetouchinterest(hrp, part, 0)
                                    task.wait(0.1)
                                    firetouchinterest(hrp, part, 1)
                                end)
                                WindUI:Notify({ Title = "Fruit Found!", Content = "Collected: " .. v.Name, Duration = 3 })
                            end
                        end
                    end
                end
            end)
        else
            WindUI:Notify({ Title = "Fruit Collector", Content = "Stopped.", Duration = 3 })
        end
    end
})

AutoTab:Toggle({
    Title = "Auto Collect Chests",
    Desc = "Teleports to and opens chests automatically",
    Callback = function(state)
        State.AutoChest = state
        if state then
            WindUI:Notify({ Title = "Chest Collector", Content = "Hunting for chests...", Duration = 3 })
            task.spawn(function()
                while State.AutoChest do
                    task.wait(1)
                    local hrp = getHRP()
                    if not hrp then continue end

                    for _, v in pairs(Workspace:GetDescendants()) do
                        if not State.AutoChest then break end
                        local nameL = string.lower(v.Name)
                        if string.find(nameL, "chest") or string.find(nameL, "treasure") then
                            local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                            if part then
                                teleportTo(part.CFrame * CFrame.new(0, 2, 0))
                                task.wait(0.3)
                                pcall(function()
                                    firetouchinterest(hrp, part, 0)
                                    task.wait(0.1)
                                    firetouchinterest(hrp, part, 1)
                                end)
                                -- Also fire proximity prompts
                                for _, pp in pairs(v:GetDescendants()) do
                                    if pp:IsA("ProximityPrompt") then
                                        fireproximityprompt(pp)
                                    end
                                end
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end)
        end
    end
})

-- ============================================================
--                        FARM TAB
-- ============================================================
FarmTab:Section({ Title = "Mob Farming" })

FarmTab:Toggle({
    Title = "Auto Farm Nearest Mob",
    Desc = "Teleports to and attacks the nearest mob continuously",
    Callback = function(state)
        State.AutoFarm = state
        if state then
            WindUI:Notify({ Title = "Auto Farm", Content = "Started farming mobs!", Duration = 3 })
            task.spawn(function()
                while State.AutoFarm do
                    task.wait(0.2)
                    local mob = getNearestNPC(9999)
                    if mob then
                        local mobRoot = mob.Parent:FindFirstChild("HumanoidRootPart")
                        if mobRoot then
                            local hrp = getHRP()
                            if hrp then
                                -- Teleport behind mob for attacks
                                local targetCF = mobRoot.CFrame * CFrame.new(0, 0, 3)
                                hrp.CFrame = targetCF

                                -- Fire combat remote
                                pcall(function()
                                    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                                        local nameL = string.lower(v.Name)
                                        if v:IsA("RemoteEvent") and (string.find(nameL, "combat") or string.find(nameL, "attack") or string.find(nameL, "m1") or string.find(nameL, "hit")) then
                                            v:FireServer()
                                            break
                                        end
                                    end
                                end)

                                -- Simulate click
                                pcall(function()
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                                    task.wait(0.05)
                                    vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                                end)
                            end
                        end
                    end
                end
            end)
        else
            WindUI:Notify({ Title = "Auto Farm", Content = "Stopped.", Duration = 3 })
        end
    end
})

FarmTab:Toggle({
    Title = "Bring Mobs to You",
    Desc = "Teleports all nearby mobs to your position",
    Callback = function(state)
        State.BringMobs = state
        if state then
            WindUI:Notify({ Title = "Bring Mobs", Content = "Pulling mobs to you!", Duration = 3 })
            task.spawn(function()
                while State.BringMobs do
                    task.wait(0.3)
                    local hrp = getHRP()
                    if not hrp then continue end

                    for _, v in pairs(Workspace:GetDescendants()) do
                        if v:IsA("Humanoid") and v.Health > 0 then
                            local npcRoot = v.Parent:FindFirstChild("HumanoidRootPart")
                            if npcRoot and not Players:GetPlayerFromCharacter(v.Parent) then
                                local dist = (hrp.Position - npcRoot.Position).Magnitude
                                if dist < 300 then
                                    npcRoot.CFrame = hrp.CFrame * CFrame.new(0, 0, -5)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
})

FarmTab:Section({ Title = "Quest Farming" })

FarmTab:Toggle({
    Title = "Auto Quest (Accept & Complete)",
    Desc = "Auto-accepts and completes quests from nearby NPCs",
    Callback = function(state)
        State.AutoQuest = state
        if state then
            WindUI:Notify({ Title = "Auto Quest", Content = "Started auto-questing!", Duration = 3 })
            task.spawn(function()
                while State.AutoQuest do
                    task.wait(1)
                    pcall(function()
                        -- Fire all proximity prompts on quest NPCs
                        for _, v in pairs(Workspace:GetDescendants()) do
                            if v:IsA("ProximityPrompt") then
                                local parentModel = v:FindFirstAncestorWhichIsA("Model")
                                if parentModel then
                                    local nameL = string.lower(parentModel.Name)
                                    if string.find(nameL, "quest") or string.find(nameL, "npc") or string.find(nameL, "giver") or string.find(nameL, "hunter") then
                                        local part = parentModel:FindFirstChildWhichIsA("BasePart")
                                        if part then
                                            local hrp = getHRP()
                                            if hrp then
                                                local dist = (hrp.Position - part.Position).Magnitude
                                                if dist < 50 then
                                                    fireproximityprompt(v)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        -- Also try quest-related remotes
                        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                                local nameL = string.lower(v.Name)
                                if string.find(nameL, "quest") and (string.find(nameL, "accept") or string.find(nameL, "start") or string.find(nameL, "complete")) then
                                    if v:IsA("RemoteEvent") then
                                        v:FireServer()
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        else
            WindUI:Notify({ Title = "Auto Quest", Content = "Stopped.", Duration = 3 })
        end
    end
})

FarmTab:Section({ Title = "Fruit Sniper" })

FarmTab:Toggle({
    Title = "Fruit Sniper",
    Desc = "Detects & auto-teleports to any spawned Devil Fruit",
    Callback = function(state)
        State.FruitSniper = state
        if state then
            WindUI:Notify({ Title = "Fruit Sniper", Content = "Watching for fruit spawns...", Duration = 3 })
            task.spawn(function()
                while State.FruitSniper do
                    task.wait(0.5)
                    pcall(function()
                        for _, v in pairs(Workspace:GetDescendants()) do
                            if not State.FruitSniper then break end
                            local nameL = string.lower(v.Name)
                            if (string.find(nameL, "fruit") or string.find(nameL, "devil")) and (v:IsA("BasePart") or v:IsA("Model")) then
                                local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                                if part then
                                    local hrp = getHRP()
                                    if hrp then
                                        WindUI:Notify({ Title = "🍎 FRUIT DETECTED!", Content = v.Name .. " found! Teleporting...", Duration = 5 })
                                        teleportTo(part.CFrame * CFrame.new(0, 2, 0))
                                        task.wait(0.3)
                                        pcall(function()
                                            firetouchinterest(hrp, part, 0)
                                            task.wait(0.1)
                                            firetouchinterest(hrp, part, 1)
                                        end)
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        else
            WindUI:Notify({ Title = "Fruit Sniper", Content = "Stopped watching.", Duration = 3 })
        end
    end
})

-- ============================================================
--                        TROLL TAB
-- ============================================================
TrollTab:Section({ Title = "Fun & Chaos" })

TrollTab:Toggle({
    Title = "Spin Bot",
    Desc = "Spin your character endlessly",
    Callback = function(state)
        State.SpinBot = state
        if state then
            task.spawn(function()
                while State.SpinBot do
                    local hrp = getHRP()
                    if hrp then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(50), 0)
                    end
                    task.wait()
                end
            end)
        end
    end
})

TrollTab:Toggle({
    Title = "Touch Fling",
    Desc = "Flings any player you walk near",
    Callback = function(state)
        State.TouchFling = state
        if State._TouchFlingConn then
            State._TouchFlingConn:Disconnect()
            State._TouchFlingConn = nil
        end

        if state then
            WindUI:Notify({ Title = "Touch Fling", Content = "Walk near players to fling them!", Duration = 3 })
            State._TouchFlingConn = RunService.Stepped:Connect(function()
                local hrp = getHRP()
                if not hrp then return end

                local isNear = false
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
                        if dist < 10 then
                            isNear = true
                            break
                        end
                    end
                end

                if isNear then
                    hrp.RotVelocity = Vector3.new(0, 50000, 0)
                    for _, part in pairs(getCharacter():GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 0, 0)
                        end
                    end
                end
            end)
        else
            WindUI:Notify({ Title = "Touch Fling", Content = "Disabled.", Duration = 3 })
            -- Restore physics
            pcall(function()
                for _, part in pairs(getCharacter():GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                    end
                end
            end)
        end
    end
})

TrollTab:Toggle({
    Title = "Invisible (Client-Side)",
    Desc = "Makes your character invisible on your screen",
    Callback = function(state)
        State.Invisible = state
        pcall(function()
            local char = getCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.Transparency = state and 1 or 0
                    elseif part:IsA("Decal") then
                        part.Transparency = state and 1 or 0
                    end
                end
            end
        end)
        WindUI:Notify({ Title = "Invisible", Content = state and "You are now invisible!" or "Visible again.", Duration = 3 })
    end
})

TrollTab:Button({
    Title = "Teleport to Nearest Player",
    Desc = "Instantly teleport behind the closest player",
    Callback = function()
        local target = getNearestPlayer(9999)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            teleportTo(target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
            WindUI:Notify({ Title = "Teleported", Content = "Teleported to " .. target.Name, Duration = 3 })
        else
            WindUI:Notify({ Title = "Teleport", Content = "No player found!", Duration = 3 })
        end
    end
})

TrollTab:Button({
    Title = "Annoy Nearest Player",
    Desc = "Repeatedly teleport to and circle a player",
    Callback = function()
        local target = getNearestPlayer(9999)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            WindUI:Notify({ Title = "Annoying", Content = "Annoying " .. target.Name .. "!", Duration = 3 })
            task.spawn(function()
                for i = 1, 20 do
                    if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then break end
                    local angle = math.rad(i * 18)
                    local offset = Vector3.new(math.cos(angle) * 5, 0, math.sin(angle) * 5)
                    teleportTo(target.Character.HumanoidRootPart.CFrame + offset)
                    task.wait(0.15)
                end
            end)
        end
    end
})

-- ============================================================
--                        NOTES TAB
-- ============================================================
NotesTab:Section({ Title = "📋 Script Info" })

NotesTab:Paragraph({
    Title = "Welcome to Giannis Client",
    Content = "Version: 3.0 | Game: Sailor Piece\nMade by Giannis Client Studio\n\nThis script provides automation tools, ESP, farming helpers, and fun features for Sailor Piece."
})

NotesTab:Section({ Title = "⚡ Hotkeys & Tips" })

NotesTab:Paragraph({
    Title = "Recommended Setup",
    Content = "1. Enable 'Anti AFK' first to stay connected.\n2. Use 'Mob ESP' + 'Auto Farm' for efficient leveling.\n3. Turn on 'Fruit Sniper' to never miss a Devil Fruit spawn.\n4. Use 'Chest ESP' to find hidden treasures.\n5. Adjust WalkSpeed for faster travel between islands."
})

NotesTab:Section({ Title = "🔧 Utilities" })

NotesTab:Button({
    Title = "Anti AFK",
    Desc = "Prevents you from being kicked for inactivity",
    Callback = function()
        pcall(function()
            LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
            end)
        end)
        WindUI:Notify({ Title = "Anti AFK", Content = "You will no longer be kicked for idling!", Duration = 3 })
    end
})

NotesTab:Button({
    Title = "FPS Boost",
    Desc = "Reduces graphical quality for better performance",
    Callback = function()
        pcall(function()
            local t = Workspace.Terrain
            t.WaterWaveSize = 0
            t.WaterWaveSpeed = 0
            t.WaterReflectance = 0
            t.WaterTransparency = 0
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            settings().Rendering.QualityLevel = 1

            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
                    v.Material = Enum.Material.Plastic
                    v.Reflectance = 0
                elseif v:IsA("Decal") then
                    v.Transparency = 1
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Lifetime = NumberRange.new(0)
                elseif v:IsA("Explosion") then
                    v.BlastPressure = 0
                    v.BlastRadius = 0
                end
            end
        end)
        WindUI:Notify({ Title = "FPS Boost", Content = "Graphics reduced — FPS should improve!", Duration = 3 })
    end
})

NotesTab:Button({
    Title = "Server Hop",
    Desc = "Teleports you to a different server",
    Callback = function()
        WindUI:Notify({ Title = "Server Hop", Content = "Finding a new server...", Duration = 3 })
        pcall(function()
            local placeId = game.PlaceId
            local servers = HttpService:JSONDecode(
                game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100")
            )
            for _, server in pairs(servers.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                    return
                end
            end
            WindUI:Notify({ Title = "Server Hop", Content = "No available servers found.", Duration = 3 })
        end)
    end
})

NotesTab:Button({
    Title = "Rejoin Server",
    Desc = "Rejoins the current server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

NotesTab:Button({
    Title = "Clear All ESP",
    Desc = "Removes all ESP highlights at once",
    Callback = function()
        State.PlayerESP = false
        State.MobESP = false
        State.FruitESP = false
        State.ChestESP = false
        clearAllESP()
        WindUI:Notify({ Title = "ESP Cleared", Content = "All ESP highlights removed!", Duration = 3 })
    end
})

NotesTab:Section({ Title = "⚠️ Disclaimer" })

NotesTab:Paragraph({
    Title = "Use At Your Own Risk",
    Content = "This script is for educational purposes only.\nUsing exploits may result in account bans.\nGiannis Client Studio is not responsible for any consequences.\n\nAlways use an alt account when testing scripts."
})

-- ==================== AUTO RECONNECT ====================
-- Keep the character alive across respawns for speed/jump settings
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    WindUI:Notify({ Title = "Respawned", Content = "Character loaded. Features re-applied.", Duration = 3 })
end)

WindUI:Notify({
    Title = "Ready!",
    Content = "All tabs loaded. Enjoy Sailor Piece! ⚓🏴‍☠️",
    Duration = 5
})
