-- BluhavenHub | Anime Dice
-- WindUI Ocean Theme + Fixed Auto Roll & Tower

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local ICON = "rbxassetid://71760811781401"

pcall(function()
    WindUI:AddTheme({
        Name = "Ocean",
        Accent = Color3.fromHex("#2b5e9c"),
        Background = Color3.fromHex("#0a1a33"),
        Outline = Color3.fromHex("#3b7dd8"),
        Text = Color3.fromHex("#ffffff"),
        Placeholder = Color3.fromHex("#7a7a7a"),
        Button = Color3.fromHex("#1e3a5f"),
        Icon = Color3.fromHex("#a1a1aa"),
    })
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local State = {
    ServerAutoRoll    = false,
    AutoBuyDice       = false,
    AutoEquipDice     = false,
    AutoEquipUnits    = false,
    AutoLevelSlots    = false,
    UnitESP           = false,
    PlotESP           = false,
    PlayerESP         = false,
    InfiniteJump      = false,
    NoClip            = false,
    RollDelay         = 1,
    DiceAllowlist     = {},
}

-- ═══════════════════════════════════
-- REMOTE FINDER
-- ═══════════════════════════════════
local Network = ReplicatedStorage:FindFirstChild("Network") or ReplicatedStorage:WaitForChild("Network", 10)

local function findRemote(root, ...)
    if not root then return nil end
    local current = root
    for _, name in ipairs({...}) do
        if not current then return nil end
        current = current:FindFirstChild(name)
    end
    return current
end

local function findByPattern(root, pattern)
    if not root then return nil end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj.Name == pattern then
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                return obj
            end
        end
    end
    return nil
end

local RollRemote = findRemote(Network, "RollService", "RF", "RollDice")
    or findByPattern(Network, "RollDice")
    or findByPattern(ReplicatedStorage, "RollDice")

local EquipBestRemote = findRemote(Network, "PlotService", "RE", "EquipBest")
    or findByPattern(Network, "EquipBest")

local LevelUpSlotRemote = findRemote(Network, "PlotService", "RE", "LevelUpSlot")
    or findByPattern(Network, "LevelUpSlot")

local BuyDiceRemote = findRemote(Network, "DiceShopService", "RE", "BuyDice")
    or findByPattern(Network, "BuyDice")

print("[BluhavenHub] RollRemote:", RollRemote)
print("[BluhavenHub] EquipBestRemote:", EquipBestRemote)

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
local function doRoll()
    if not RollRemote then return false end
    local ok = pcall(function()
        if RollRemote:IsA("RemoteFunction") then
            RollRemote:InvokeServer()
        else
            RollRemote:FireServer()
        end
    end)
    return ok
end

local function doEquipBest()
    if not EquipBestRemote then return end
    pcall(function()
        if EquipBestRemote:IsA("RemoteFunction") then
            EquipBestRemote:InvokeServer()
        else
            EquipBestRemote:FireServer()
        end
    end)
end

local function doLevelUpAllSlots()
    if not LevelUpSlotRemote then return end
    for slot = 1, TOTAL_SLOTS do
        if not State.AutoLevelSlots then break end
        pcall(function()
            if LevelUpSlotRemote:IsA("RemoteFunction") then
                LevelUpSlotRemote:InvokeServer(slot)
            else
                LevelUpSlotRemote:FireServer(slot)
            end
        end)
        task.wait(0.2)
    end
end

local function doAutoBuyDice()
    if not BuyDiceRemote then return end
    for _, diceName in ipairs(ALL_DICE) do
        if not State.AutoBuyDice then break end
        if #State.DiceAllowlist == 0 or table.find(State.DiceAllowlist, diceName) then
            pcall(function()
                if BuyDiceRemote:IsA("RemoteFunction") then
                    BuyDiceRemote:InvokeServer(diceName)
                else
                    BuyDiceRemote:FireServer(diceName)
                end
            end)
            task.wait(0.3)
        end
    end
end

-- ═══════════════════════════════════
-- ESP
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
    if State.UnitESP then
        local units = Workspace:FindFirstChild("Units", true)
        if units then
            for _, u in ipairs(units:GetDescendants()) do
                if u:IsA("Model") then
                    createAura(u, Color3.fromRGB(0,200,100), Color3.fromRGB(0,255,150), "Unit: " .. u.Name, 0.5)
                end
            end
        end
    end
    if State.PlotESP then
        local plots = Workspace:FindFirstChild("Plots", true)
        if plots then
            for _, p in ipairs(plots:GetChildren()) do
                if p:IsA("Model") then
                    local owner = p:FindFirstChild("Owner")
                    local ownerName = owner and owner.Value or "Empty"
                    createAura(p, Color3.fromRGB(200,150,0), Color3.fromRGB(255,200,0), "Plot: " .. ownerName, 0.5)
                end
            end
        end
    end
    if State.PlayerESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                createAura(plr.Character, Color3.fromRGB(200,0,0), Color3.fromRGB(255,80,80), plr.Name, 0.4)
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
task.spawn(function()
    while true do
        if State.ServerAutoRoll then
            doRoll()
            task.wait(State.RollDelay)
        else
            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while true do
        if State.AutoEquipDice or State.AutoEquipUnits then doEquipBest() end
        task.wait(3)
    end
end)

task.spawn(function()
    while true do
        if State.AutoLevelSlots then doLevelUpAllSlots() end
        task.wait(1.5)
    end
end)

task.spawn(function()
    while true do
        if State.AutoBuyDice then doAutoBuyDice() end
        task.wait(2)
    end
end)

RunService.Heartbeat:Connect(function() updateESP() end)

UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

RunService.Stepped:Connect(function()
    if State.NoClip and Character then
        for _, p in ipairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
end)

LP.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
end)

-- ═══════════════════════════════════
-- WINDUI WINDOW
-- ═══════════════════════════════════
local Window = WindUI:CreateWindow({
    Title = "BluhavenHub",
    Icon = ICON,
    Author = "Bluhaven",
    Folder = "BluhavenHub",
    Size = UDim2.fromOffset(440, 315),
    Transparent = true,
    Theme = "Ocean",
    User = { Enabled = true, Anonymous = false },
    SideBarWidth = 160,
    HasOutline = true,
    HideButton = false,
    MinimizeButton = true,
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local containers = {CoreGui}
            if gethui then
                local ok, hui = pcall(gethui)
                if ok and hui then table.insert(containers, hui) end
            end
            pcall(function() table.insert(containers, LP:WaitForChild("PlayerGui")) end)
            for _, container in pairs(containers) do
                for _, gui in pairs(container:GetChildren()) do
                    if gui.Name:lower():find("bluhaven") then continue end
                    if gui.Name:lower():find("windui") then continue end
                    for _, obj in pairs(gui:GetDescendants()) do
                        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("ImageLabel") then
                            local t = (obj.Text or ""):lower()
                            local n = obj.Name:lower()
                            if t:find("eulen") or n:find("eulen") or n:find("watermark") then
                                obj:Destroy()
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════
-- TAB: ROLL
-- ═══════════════════════════════════
local TabRoll = Window:Tab({ Title = "Roll", Icon = ICON })
local SectRoll = TabRoll:Section({ Title = "Auto Roll", Icon = ICON })

SectRoll:Toggle({
    Title = "Server-Sided Auto Roll",
    Desc = "Invoke remote langsung",
    Value = false,
    Callback = function(v)
        State.ServerAutoRoll = v
        Window:Notify({Title="Auto Roll", Content=v and "ON" or "OFF", Duration=2})
    end,
})
SectRoll:Slider({
    Title = "Roll Delay",
    Desc = "Delay antar roll (detik)",
    Value = { Min = 0.05, Max = 3, Default = 1 },
    Rounding = 2,
    Callback = function(v) State.RollDelay = v end,
})
SectRoll:Button({
    Title = "Manual Instant Roll",
    Desc = "Roll sekali langsung (test)",
    Callback = function()
        local ok = doRoll()
        Window:Notify({Title="Manual Roll", Content=ok and "Sent!" or "FAILED - remote not found", Duration=3})
    end,
})

-- ═══════════════════════════════════
-- TAB: DICE
-- ═══════════════════════════════════
local TabDice = Window:Tab({ Title = "Dice", Icon = ICON })
local SectDice = TabDice:Section({ Title = "Dice Management", Icon = ICON })

SectDice:Toggle({
    Title = "Auto Buy Best Affordable Dice",
    Desc = "Beli semua dice",
    Value = false,
    Callback = function(v) State.AutoBuyDice = v end,
})
SectDice:Toggle({
    Title = "Auto Equip Best Dice",
    Desc = "Equip dice terkuat",
    Value = false,
    Callback = function(v) State.AutoEquipDice = v end,
})
SectDice:Input({
    Title = "Dice Allowlist",
    Desc = "Pisah koma. Kosong = beli semua",
    Placeholder = "Void,Blood Moon,Galaxy",
    Value = "",
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
local TabUnits = Window:Tab({ Title = "Units", Icon = ICON })
local SectUnits = TabUnits:Section({ Title = "Unit Management", Icon = ICON })

SectUnits:Toggle({
    Title = "Auto Equip Best Units",
    Desc = "Equip unit terkuat",
    Value = false,
    Callback = function(v) State.AutoEquipUnits = v end,
})
SectUnits:Toggle({
    Title = "Auto Level Occupied Slots",
    Desc = "Level up slot 1-4",
    Value = false,
    Callback = function(v) State.AutoLevelSlots = v end,
})
SectUnits:Button({
    Title = "Manual Level Up All Slots",
    Desc = "Level up slot sekali",
    Callback = function() doLevelUpAllSlots() end,
})

-- ═══════════════════════════════════
-- TAB: TOWER (MAINTENANCE)
-- ═══════════════════════════════════
local TabTower = Window:Tab({ Title = "Tower", Icon = ICON })
local SectTower = TabTower:Section({ Title = "Tower & Fight", Icon = ICON })

SectTower:Paragraph({
    Title = "🔧 Maintenance",
    Desc = "Tower feature sedang dalam perbaikan. Akan segera hadir kembali.",
})

SectTower:Toggle({
    Title = "Auto Equip Best Tower Team",
    Desc = "[MAINTENANCE] Fitur belum tersedia",
    Value = false,
    Callback = function(v)
        if v then
            Window:Notify({Title="Tower", Content="Feature under maintenance", Duration=3})
        end
    end,
})
SectTower:Toggle({
    Title = "Auto Fight",
    Desc = "[MAINTENANCE] Fitur belum tersedia",
    Value = false,
    Callback = function(v)
        if v then
            Window:Notify({Title="Tower", Content="Feature under maintenance", Duration=3})
        end
    end,
})
SectTower:Input({
    Title = "Tower Name",
    Desc = "[MAINTENANCE] Belum berfungsi",
    Placeholder = "Slayer Tower",
    Value = "Slayer Tower",
    Callback = function(v) end,
})
SectTower:Button({
    Title = "Manual Equip Best Tower",
    Desc = "[MAINTENANCE]",
    Callback = function()
        Window:Notify({Title="Tower", Content="Feature under maintenance", Duration=3})
    end,
})
SectTower:Button({
    Title = "Manual Fight Once",
    Desc = "[MAINTENANCE]",
    Callback = function()
        Window:Notify({Title="Tower", Content="Feature under maintenance", Duration=3})
    end,
})

-- ═══════════════════════════════════
-- TAB: ESP
-- ═══════════════════════════════════
local TabESP = Window:Tab({ Title = "ESP", Icon = ICON })
local SectESP = TabESP:Section({ Title = "ESP Aura", Icon = ICON })

SectESP:Toggle({
    Title = "Unit ESP",
    Desc = "Aura hijau pada unit",
    Value = false,
    Callback = function(v)
        State.UnitESP = v
        if not v then clearESP() end
    end,
})
SectESP:Toggle({
    Title = "Plot ESP",
    Desc = "Aura kuning pada plot",
    Value = false,
    Callback = function(v)
        State.PlotESP = v
        if not v then clearESP() end
    end,
})
SectESP:Toggle({
    Title = "Player ESP",
    Desc = "Aura merah pada player",
    Value = false,
    Callback = function(v)
        State.PlayerESP = v
        if not v then clearESP() end
    end,
})

-- ═══════════════════════════════════
-- TAB: MOVEMENT
-- ═══════════════════════════════════
local TabMove = Window:Tab({ Title = "Movement", Icon = ICON })
local SectMove = TabMove:Section({ Title = "Movement", Icon = ICON })

SectMove:Toggle({
    Title = "Infinite Jump",
    Desc = "Lompat tanpa batas",
    Value = false,
    Callback = function(v) State.InfiniteJump = v end,
})
SectMove:Toggle({
    Title = "NoClip",
    Desc = "Tembus objek",
    Value = false,
    Callback = function(v) State.NoClip = v end,
})

-- ═══════════════════════════════════
-- LOADED NOTIFY
-- ═══════════════════════════════════
Window:Notify({
    Title = "BluhavenHub",
    Content = "Loaded! Tower feature is under maintenance.",
    Duration = 5,
})

print("[BluhavenHub] Loaded! (WindUI Ocean)")
