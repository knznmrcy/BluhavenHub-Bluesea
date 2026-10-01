-- BluhavenHub | Anime Dice
-- WindUI Ocean Theme

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- ═══════════════════════════════════
-- STATE
-- ═══════════════════════════════════
local State = {
    HybridAutoRoll    = false,
    ServerAutoRoll    = false,
    AutoBuyDice       = false,
    AutoEquipDice     = false,
    AutoEquipUnits    = false,
    AutoLevelSlots    = false,
    AutoBuyUpgrades   = false,
    UnitESP           = false,
    PlotESP           = false,
    PlayerESP         = false,
    InfiniteJump      = false,
    NoClip            = false,
    AutoEquipBestTower= false,
    AutoFight         = false,
    RollDelay         = 0.5,
    DiceAllowlist     = {},
    SelectedTower     = "Slayer Tower",
}

-- ═══════════════════════════════════
-- REMOTES
-- ═══════════════════════════════════
local Network = ReplicatedStorage:WaitForChild("Network")

local RollRemote = Network
    :WaitForChild("RollService")
    :WaitForChild("RF")
    :WaitForChild("RollDice")

local EquipBestRemote = Network
    :WaitForChild("PlotService")
    :WaitForChild("RE")
    :WaitForChild("EquipBest")

local LevelUpSlotRemote = Network
    :WaitForChild("PlotService")
    :WaitForChild("RE")
    :WaitForChild("LevelUpSlot")

local BuyDiceRemote = Network
    :WaitForChild("DiceShopService")
    :WaitForChild("RE")
    :WaitForChild("BuyDice")

local TowerService = Network:WaitForChild("Towers")
local EquipBestTowerRemote = TowerService:WaitForChild("RE"):WaitForChild("EquipBestTowerTeam")
local PlayTowerRemote = TowerService:WaitForChild("RF"):WaitForChild("PlayTower")

-- ═══════════════════════════════════
-- DICE LIST
-- ═══════════════════════════════════
local ALL_DICE = {
    "Light", "Toxic", "Cyber", "Frostfire", "Alchemy",
    "Chrono", "Arcane", "Titan", "Corrupted", "Radiant",
    "Ethereal", "Prismatic", "Royal", "Dragon",
    "Solar", "Lunar", "Galaxy", "Black Hole",
    "Blood Moon", "Void"
}

local TOTAL_SLOTS = 4

-- ═══════════════════════════════════
-- FUNCTIONS
-- ═══════════════════════════════════

-- Roll
local function doRoll()
    pcall(function() RollRemote:InvokeServer() end)
end

local function hybridRoll()
    local btn = LP.PlayerGui:FindFirstChild("RollButton", true)
        or LP.PlayerGui:FindFirstChild("Roll", true)
    if btn and btn:IsA("GuiButton") then
        btn.MouseButton1Click:Fire()
    else
        doRoll()
    end
end

-- Equip Best
local function doEquipBest()
    pcall(function() EquipBestRemote:FireServer() end)
end

-- Level Up All Slots
local function doLevelUpAllSlots()
    for slot = 1, TOTAL_SLOTS do
        if not State.AutoLevelSlots then break end
        pcall(function() LevelUpSlotRemote:FireServer(slot) end)
        task.wait(0.2)
    end
end

-- Buy Dice
local function doAutoBuyDice()
    for _, diceName in ipairs(ALL_DICE) do
        if not State.AutoBuyDice then break end
        if #State.DiceAllowlist == 0 or table.find(State.DiceAllowlist, diceName) then
            pcall(function() BuyDiceRemote:FireServer(diceName) end)
            task.wait(0.3)
        end
    end
end

-- Tower
local function doEquipBestTower()
    pcall(function() EquipBestTowerRemote:FireServer() end)
end

local function doFight()
    pcall(function() PlayTowerRemote:InvokeServer(State.SelectedTower) end)
end

-- ═══════════════════════════════════
-- ESP AURA
-- ═══════════════════════════════════
local ESPFolder = Instance.new("Folder", Workspace)
ESPFolder.Name = "BluhavenESP"
local activeAuras = {}

local function clearESP()
    for _, data in pairs(activeAuras) do
        if data.hl then pcall(function() data.hl:Destroy() end) end
        if data.bb then pcall(function() data.bb:Destroy() end) end
    end
    activeAuras = {}
end

local function createAura(target, fillColor, outlineColor, label, transparency)
    if not target or not target.Parent then return end
    local key = tostring(target)
    if activeAuras[key] then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = target
    hl.FillColor = fillColor
    hl.OutlineColor = outlineColor
    hl.FillTransparency = transparency or 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = ESPFolder

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 120, 0, 28)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.Parent = target

    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = outlineColor
    lbl.TextStrokeTransparency = 0
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaleType = Enum.TextScaleType.Fit

    activeAuras[key] = { hl = hl, bb = bb }
end

local function updateESP()
    -- Unit ESP
    if State.UnitESP then
        local units = Workspace:FindFirstChild("Units", true)
        if units then
            for _, u in ipairs(units:GetDescendants()) do
                if u:IsA("Model") then
                    createAura(u, Color3.fromRGB(0,200,100), Color3.fromRGB(0,255,150), "⚔ " .. u.Name, 0.5)
                end
            end
        end
    end

    -- Plot ESP
    if State.PlotESP then
        local plots = Workspace:FindFirstChild("Plots", true)
        if plots then
            for _, p in ipairs(plots:GetChildren()) do
                if p:IsA("Model") then
                    local owner = p:FindFirstChild("Owner")
                    local ownerName = owner and owner.Value or "Empty"
                    createAura(p, Color3.fromRGB(200,150,0), Color3.fromRGB(255,200,0), "🏠 " .. ownerName, 0.5)
                end
            end
        end
    end

    -- Player ESP
    if State.PlayerESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                createAura(plr.Character, Color3.fromRGB(200,0,0), Color3.fromRGB(255,80,80), "👤 " .. plr.Name, 0.4)
            end
        end
    end

    if not State.UnitESP and not State.PlotESP and not State.PlayerESP then
        clearESP()
    end
end

-- ═══════════════════════════════════
-- LOOPS
-- ═══════════════════════════════════

-- Auto Roll
task.spawn(function()
    while true do
        if State.HybridAutoRoll then
            hybridRoll()
            task.wait(State.RollDelay)
        elseif State.ServerAutoRoll then
            doRoll()
            task.wait(State.RollDelay)
        else
            task.wait(0.1)
        end
    end
end)

-- Auto Equip Best
task.spawn(function()
    while true do
        if State.AutoEquipDice or State.AutoEquipUnits then
            doEquipBest()
        end
        task.wait(3)
    end
end)

-- Auto Level Slots
task.spawn(function()
    while true do
        if State.AutoLevelSlots then
            doLevelUpAllSlots()
        end
        task.wait(1.5)
    end
end)

-- Auto Buy Dice
task.spawn(function()
    while true do
        if State.AutoBuyDice then
            doAutoBuyDice()
        end
        task.wait(2)
    end
end)

-- Auto Tower + Fight
task.spawn(function()
    while true do
        if State.AutoFight then
            if State.AutoEquipBestTower then
                doEquipBestTower()
                task.wait(0.5)
            end
            doFight()
            task.wait(2)
        end
        task.wait(0.5)
    end
end)

-- ESP Loop
RunService.Heartbeat:Connect(function()
    updateESP()
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- NoClip
RunService.Stepped:Connect(function()
    if State.NoClip and Character then
        for _, p in ipairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
end)

-- Respawn update
LP.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
end)

-- ═══════════════════════════════════
-- WINDUI
-- ═══════════════════════════════════
local Window = WindUI:CreateWindow({
    Title = "BluhavenHub",
    Icon = "dices",
    Author = "Bluhaven",
    Folder = "BluhavenHub",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Ocean",
    DisableWindUI = false,
})

Window:Intro({
    Title = "BluhavenHub",
    Description = "Anime Dice Script",
    Icon = "dices",
})

-- ═══════════════════════════════════
-- TAB: ROLL
-- ═══════════════════════════════════
local TabRoll = Window:Tab({
    Title = "Roll",
    Icon = "dices",
})

local SectRoll = TabRoll:Section({ Title = "Auto Roll" })

SectRoll:Toggle({
    Title = "Hybrid Auto Roll",
    Description = "GUI click + server fallback",
    Default = false,
    Callback = function(v) State.HybridAutoRoll = v end,
})

SectRoll:Toggle({
    Title = "Server-Sided Auto Roll",
    Description = "Pure server invoke",
    Default = false,
    Callback = function(v) State.ServerAutoRoll = v end,
})

SectRoll:Slider({
    Title = "Roll Delay",
    Description = "Delay antar roll (detik)",
    Min = 0.05,
    Max = 3,
    Default = 0.5,
    Decimals = 2,
    Callback = function(v) State.RollDelay = v end,
})

SectRoll:Button({
    Title = "Manual Instant Roll",
    Description = "Roll sekali langsung",
    Callback = function() doRoll() end,
})

-- ═══════════════════════════════════
-- TAB: DICE
-- ═══════════════════════════════════
local TabDice = Window:Tab({
    Title = "Dice",
    Icon = "box",
})

local SectDice = TabDice:Section({ Title = "Dice Management" })

SectDice:Toggle({
    Title = "Auto Buy Best Affordable Dice",
    Description = "Beli semua dice yang ada",
    Default = false,
    Callback = function(v) State.AutoBuyDice = v end,
})

SectDice:Toggle({
    Title = "Auto Equip Best Dice",
    Description = "Equip dice terkuat otomatis",
    Default = false,
    Callback = function(v) State.AutoEquipDice = v end,
})

SectDice:Input({
    Title = "Dice Allowlist",
    Description = "Pisah dengan koma. Kosongin = beli semua",
    Placeholder = "Void,Blood Moon,Galaxy",
    Callback = function(v)
        State.DiceAllowlist = {}
        for name in v:gmatch("[^,]+") do
            table.insert(State.DiceAllowlist, name:match("^%s*(.-)%s*$"))
        end
    end,
})

-- ═══════════════════════════════════
-- TAB: UNITS
-- ═══════════════════════════════════
local TabUnits = Window:Tab({
    Title = "Units",
    Icon = "sword",
})

local SectUnits = TabUnits:Section({ Title = "Unit Management" })

SectUnits:Toggle({
    Title = "Auto Equip Best Units",
    Description = "Equip unit terkuat otomatis",
    Default = false,
    Callback = function(v) State.AutoEquipUnits = v end,
})

SectUnits:Toggle({
    Title = "Auto Level Occupied Slots",
    Description = "Level up slot 1-4 otomatis",
    Default = false,
    Callback = function(v) State.AutoLevelSlots = v end,
})

SectUnits:Button({
    Title = "Manual Level Up All Slots",
    Description = "Level up semua slot sekali",
    Callback = function() doLevelUpAllSlots() end,
})

-- ═══════════════════════════════════
-- TAB: TOWER & FIGHT
-- ═══════════════════════════════════
local TabTower = Window:Tab({
    Title = "Tower",
    Icon = "castle",
})

local SectTower = TabTower:Section({ Title = "Tower & Fight" })

SectTower:Toggle({
    Title = "Auto Equip Best Tower Team",
    Description = "Equip team tower terkuat sebelum fight",
    Default = false,
    Callback = function(v) State.AutoEquipBestTower = v end,
})

SectTower:Toggle({
    Title = "Auto Fight",
    Description = "Loop fight otomatis",
    Default = false,
    Callback = function(v) State.AutoFight = v end,
})

SectTower:Input({
    Title = "Tower Name",
    Description = "Nama tower yang mau difight",
    Placeholder = "Slayer Tower",
    Callback = function(v)
        if v ~= "" then State.SelectedTower = v end
    end,
})

SectTower:Button({
    Title = "Manual Equip Best Tower",
    Description = "Equip team tower sekali",
    Callback = function() doEquipBestTower() end,
})

SectTower:Button({
    Title = "Manual Fight Once",
    Description = "Fight sekali langsung",
    Callback = function()
        doEquipBestTower()
        task.wait(0.3)
        doFight()
    end,
})

-- ═══════════════════════════════════
-- TAB: ESP
-- ═══════════════════════════════════
local TabESP = Window:Tab({
    Title = "ESP",
    Icon = "eye",
})

local SectESP = TabESP:Section({ Title = "ESP Aura" })

SectESP:Toggle({
    Title = "Unit ESP",
    Description = "Aura hijau pada semua unit",
    Default = false,
    Callback = function(v)
        State.UnitESP = v
        if not v then clearESP() end
    end,
})

SectESP:Toggle({
    Title = "Plot ESP",
    Description = "Aura kuning pada semua plot",
    Default = false,
    Callback = function(v)
        State.PlotESP = v
        if not v then clearESP() end
    end,
})

SectESP:Toggle({
    Title = "Player ESP",
    Description = "Aura merah pada semua player",
    Default = false,
    Callback = function(v)
        State.PlayerESP = v
        if not v then clearESP() end
    end,
})

-- ═══════════════════════════════════
-- TAB: MOVEMENT
-- ═══════════════════════════════════
local TabMove = Window:Tab({
    Title = "Movement",
    Icon = "footprints",
})

local SectMove = TabMove:Section({ Title = "Movement" })

SectMove:Toggle({
    Title = "Infinite Jump",
    Description = "Lompat terus tanpa batas",
    Default = false,
    Callback = function(v) State.InfiniteJump = v end,
})

SectMove:Toggle({
    Title = "NoClip",
    Description = "Tembus semua objek",
    Default = false,
    Callback = function(v) State.NoClip = v end,
})

print("[BluhavenHub] Loaded!")