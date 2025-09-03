-- Load LinoriaLib (with error handling)
local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
end)
if not success then
    warn("Failed to load LinoriaLib: " .. tostring(Library))
    local StarterGui = game:GetService("StarterGui")
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Menu",
            Text = "Failed to load LinoriaLib. Please try again later.",
            Duration = 10
        })
    end)
    return
end

-- Load ThemeManager and SaveManager
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- Player and Character Setup
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

-- Update character references on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    RootPart = newChar:WaitForChild("HumanoidRootPart")
    UpdateESP()
    UpdateItemESP()
    UpdateEnvESP()
    UpdateChams()
    UpdatePlayerHighlights()
    if FlyEnabled then
        StartFly()
    end
    if NoclipEnabled then
        spawn(NoclipLoop)
    end
    if AutoWalkEnabled then
        StartAutoWalk()
    end
    if VisualEffects.Particles.Enabled then
        ApplyCustomParticles()
    end
end)

-- Create GUI with LinoriaLib
local Window = Library:CreateWindow({
    Title = "Town's Menu",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Tabs
local Tabs = {
    Main = Window:AddTab("Main"),
    Lighting = Window:AddTab("Lighting"),
    Miscellaneous = Window:AddTab("Miscellaneous"),
    Player = Window:AddTab("Player"),
    Visual = Window:AddTab("Visual"),
    ["UI Settings"] = Window:AddTab("UI Settings"),
}

-- 1. Main Tab
local MainGroup = Tabs.Main:AddLeftGroupbox("Main Features")
local AntiAfkEnabled = false
local AntiKickEnabled = false
local NoRecoilEnabled = false
local NoRecoilCheckInterval = 3
local AntiAfkInterval = 30
local AntiKickMessage = "Kick attempt blocked."
local AntiCheatWarningEnabled = true
local SpoofClientDataEnabled = false
local SpoofClientConnection = nil

local function SetupAntiAfk()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if AntiAfkEnabled then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            Library:Notify("Anti-AFK triggered.", 3)
        end
    end)
end

local function NoRecoilLoop()
    while NoRecoilEnabled and LocalPlayer.Character do
        local recoil = LocalPlayer:FindFirstChild("Recoil")
        if recoil then
            recoil:Destroy()
            Library:Notify("Recoil removed.", 3)
        end
        task.wait(NoRecoilCheckInterval)
    end
end

local function SetupClientSpoof()
    if SpoofClientConnection then
        SpoofClientConnection:Disconnect()
        SpoofClientConnection = nil
    end
    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    setreadonly(mt, false)
    mt.__index = function(self, key)
        if SpoofClientDataEnabled then
            if key == "WalkSpeed" and WalkspeedEnabled then return 16
            elseif key == "JumpPower" and JumpPowerEnabled then return 50
            end
        end
        return oldIndex(self, key)
    end
    setreadonly(mt, true)
    -- Continuous check to reapply spoofed values
    SpoofClientConnection = RunService.Heartbeat:Connect(function()
        if SpoofClientDataEnabled and Humanoid then
            if WalkspeedEnabled and Humanoid.WalkSpeed ~= CustomWalkspeed then
                Humanoid.WalkSpeed = CustomWalkspeed
            end
            if JumpPowerEnabled and Humanoid.JumpPower ~= CustomJumpPower then
                Humanoid.JumpPower = CustomJumpPower
            end
        end
    end)
end

MainGroup:AddToggle("AntiAFK", {
    Text = "Anti-AFK",
    Default = false,
    Callback = function(state)
        AntiAfkEnabled = state
        if state then
            SetupAntiAfk()
            Library:Notify("Anti-AFK enabled.", 3)
        else
            Library:Notify("Anti-AFK disabled.", 3)
        end
    end
})
MainGroup:AddSlider("AntiAfkInterval", {
    Text = "Anti-AFK Interval (seconds)",
    Min = 10,
    Max = 60,
    Default = 30,
    Rounding = 0,
    Callback = function(value)
        AntiAfkInterval = value
        Library:Notify("Anti-AFK interval set to " .. value .. " seconds.", 3)
    end
})
MainGroup:AddToggle("AntiKick", {
    Text = "Anti-Kick",
    Default = false,
    Callback = function(state)
        AntiKickEnabled = state
        if state then
            local mt = getrawmetatable(game)
            local oldNamecall = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = function(self, ...)
                local method = getnamecallmethod()
                if AntiKickEnabled and self == LocalPlayer and method == "Kick" then
                    Library:Notify(AntiKickMessage, 3)
                    return
                end
                return oldNamecall(self, ...)
            end
            setreadonly(mt, true)
            Library:Notify("Anti-Kick enabled.", 3)
        else
            Library:Notify("Anti-Kick disabled.", 3)
        end
    end
})
MainGroup:AddInput("AntiKickMessage", {
    Text = "Anti-Kick Message",
    Placeholder = "Kick attempt blocked.",
    Callback = function(text)
        AntiKickMessage = text
        Library:Notify("Anti-Kick message set to: " .. text, 3)
    end
})
MainGroup:AddToggle("NoRecoil", {
    Text = "No Recoil",
    Default = false,
    Callback = function(state)
        NoRecoilEnabled = state
        if state then
            spawn(NoRecoilLoop)
            Library:Notify("No Recoil enabled.", 3)
        else
            Library:Notify("No Recoil disabled.", 3)
        end
    end
})
MainGroup:AddSlider("NoRecoilCheckInterval", {
    Text = "No Recoil Check Interval (seconds)",
    Min = 1,
    Max = 10,
    Default = 3,
    Rounding = 0,
    Callback = function(value)
        NoRecoilCheckInterval = value
        Library:Notify("No Recoil check interval set to " .. value .. " seconds.", 3)
    end
})
MainGroup:AddButton({
    Text = "Bypass AntiCheat (beta)",
    Func = function()
        local anticheat = LocalPlayer:FindFirstChild("LCS_NO-CHEAT_V12")
        if anticheat then
            anticheat:Destroy()
            Library:Notify("AntiCheat bypassed.", 3)
        else
            Library:Notify("No AntiCheat found.", 3)
        end
    end
})
MainGroup:AddToggle("AntiCheatWarning", {
    Text = "Anti-Cheat Detection Warning",
    Default = true,
    Callback = function(state)
        AntiCheatWarningEnabled = state
        Library:Notify(state and "Anti-Cheat warnings enabled." or "Anti-Cheat warnings disabled.", 3)
    end
})
MainGroup:AddToggle("SpoofClientData", {
    Text = "Spoof Client Data",
    Default = false,
    Callback = function(state)
        SpoofClientDataEnabled = state
        if state then
            SetupClientSpoof()
            Library:Notify("Client data spoofing enabled.", 3)
        else
            if SpoofClientConnection then
                SpoofClientConnection:Disconnect()
                SpoofClientConnection = nil
            end
            Library:Notify("Client data spoofing disabled.", 3)
        end
    end
})

-- Anti-Cheat Detection
Workspace.DescendantAdded:Connect(function(descendant)
    if AntiCheatWarningEnabled and descendant:IsA("Script") and descendant.Name:lower():find("anticheat") then
        Library:Notify("Warning: Potential anti-cheat script detected: " .. descendant.Name, 5)
    end
end)

-- 2. Lighting Tab
local LightingGroup = Tabs.Lighting:AddLeftGroupbox("Lighting Adjustments")
local LightingEffectsGroup = Tabs.Lighting:AddRightGroupbox("Lighting Effects")
local FullbrightEnabled = false
local OriginalBrightness, OriginalFogEnd, OriginalFogStart, OriginalGlobalShadows
local FOVEnabled = false
local CustomFOV = 70
local FOVConnection = nil
local LightingStates = {FullbrightEnabled = false, FOVEnabled = false}
local LockLightingEnabled = false
local CustomAmbient = Lighting.Ambient
local CustomBrightness = Lighting.Brightness
local CustomClockTime = Lighting.ClockTime
local CustomColorShiftBottom = Lighting.ColorShift_Bottom
local CustomColorShiftTop = Lighting.ColorShift_Top
local CustomEnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
local CustomEnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
local CustomGeographicLatitude = Lighting.GeographicLatitude
local CustomGlobalShadows = Lighting.GlobalShadows
local CustomOutdoorAmbient = Lighting.OutdoorAmbient
local CustomShadowSoftness = Lighting.ShadowSoftness
local CustomTimeOfDay = Lighting.TimeOfDay
local CustomTint = Color3.fromRGB(255, 255, 255)
local CustomFogColor = Lighting.FogColor
local CustomFogEnd = Lighting.FogEnd
local CustomFogStart = Lighting.FogStart
local CustomExposure = Lighting.ExposureCompensation
local LightingConnections = {}
local FullbrightBrightness = 10
local FullbrightFogEnd = 1000000
local FullbrightFogStart = 1000000
local CustomSkyboxEnabled = false
local CustomSkyboxAssetId = "rbxassetid://123456789"
local TimeSpeed = 1

local function ApplyLightingSettings()
    if LockLightingEnabled then
        Lighting.Ambient = CustomAmbient
        Lighting.Brightness = CustomBrightness
        Lighting.ClockTime = CustomClockTime
        Lighting.ColorShift_Bottom = CustomColorShiftBottom
        Lighting.ColorShift_Top = CustomColorShiftTop
        Lighting.EnvironmentDiffuseScale = CustomEnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = CustomEnvironmentSpecularScale
        Lighting.GeographicLatitude = CustomGeographicLatitude
        Lighting.GlobalShadows = CustomGlobalShadows
        Lighting.OutdoorAmbient = CustomOutdoorAmbient
        Lighting.ShadowSoftness = CustomShadowSoftness
        Lighting.TimeOfDay = CustomTimeOfDay
        Lighting.FogColor = CustomFogColor
        Lighting.FogEnd = CustomFogEnd
        Lighting.FogStart = CustomFogStart
        Lighting.ExposureCompensation = CustomExposure
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.TintColor = CustomTint
    end
end

local function StartLightingLocks()
    for _, conn in pairs(LightingConnections) do
        conn:Disconnect()
    end
    LightingConnections = {}

    if LockLightingEnabled then
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
            if LockLightingEnabled and Lighting.Ambient ~= CustomAmbient then
                Lighting.Ambient = CustomAmbient
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
            if LockLightingEnabled and Lighting.Brightness ~= CustomBrightness then
                Lighting.Brightness = CustomBrightness
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
            if LockLightingEnabled and Lighting.ClockTime ~= CustomClockTime then
                Lighting.ClockTime = CustomClockTime
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("ColorShift_Bottom"):Connect(function()
            if LockLightingEnabled and Lighting.ColorShift_Bottom ~= CustomColorShiftBottom then
                Lighting.ColorShift_Bottom = CustomColorShiftBottom
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("ColorShift_Top"):Connect(function()
            if LockLightingEnabled and Lighting.ColorShift_Top ~= CustomColorShiftTop then
                Lighting.ColorShift_Top = CustomColorShiftTop
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("EnvironmentDiffuseScale"):Connect(function()
            if LockLightingEnabled and Lighting.EnvironmentDiffuseScale ~= CustomEnvironmentDiffuseScale then
                Lighting.EnvironmentDiffuseScale = CustomEnvironmentDiffuseScale
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("EnvironmentSpecularScale"):Connect(function()
            if LockLightingEnabled and Lighting.EnvironmentSpecularScale ~= CustomEnvironmentSpecularScale then
                Lighting.EnvironmentSpecularScale = CustomEnvironmentSpecularScale
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("GeographicLatitude"):Connect(function()
            if LockLightingEnabled and Lighting.GeographicLatitude ~= CustomGeographicLatitude then
                Lighting.GeographicLatitude = CustomGeographicLatitude
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function()
            if LockLightingEnabled and Lighting.GlobalShadows ~= CustomGlobalShadows then
                Lighting.GlobalShadows = CustomGlobalShadows
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(function()
            if LockLightingEnabled and Lighting.OutdoorAmbient ~= CustomOutdoorAmbient then
                Lighting.OutdoorAmbient = CustomOutdoorAmbient
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("ShadowSoftness"):Connect(function()
            if LockLightingEnabled and Lighting.ShadowSoftness ~= CustomShadowSoftness then
                Lighting.ShadowSoftness = CustomShadowSoftness
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(function()
            if LockLightingEnabled and Lighting.TimeOfDay ~= CustomTimeOfDay then
                Lighting.TimeOfDay = CustomTimeOfDay
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("FogColor"):Connect(function()
            if LockLightingEnabled and Lighting.FogColor ~= CustomFogColor then
                Lighting.FogColor = CustomFogColor
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
            if LockLightingEnabled and Lighting.FogEnd ~= CustomFogEnd then
                Lighting.FogEnd = CustomFogEnd
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("FogStart"):Connect(function()
            if LockLightingEnabled and Lighting.FogStart ~= CustomFogStart then
                Lighting.FogStart = CustomFogStart
            end
        end))
        table.insert(LightingConnections, Lighting:GetPropertyChangedSignal("ExposureCompensation"):Connect(function()
            if LockLightingEnabled and Lighting.ExposureCompensation ~= CustomExposure then
                Lighting.ExposureCompensation = CustomExposure
            end
        end))
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if cc then
            table.insert(LightingConnections, cc:GetPropertyChangedSignal("TintColor"):Connect(function()
                if LockLightingEnabled and cc.TintColor ~= CustomTint then
                    cc.TintColor = CustomTint
                end
            end))
        end
    end
end

local function ApplyFOV()
    if Camera then
        Camera.FieldOfView = CustomFOV
    end
end

local function ApplyCustomSkybox()
    if CustomSkyboxEnabled then
        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.SkyboxBk = CustomSkyboxAssetId
        sky.SkyboxDn = CustomSkyboxAssetId
        sky.SkyboxFt = CustomSkyboxAssetId
        sky.SkyboxLf = CustomSkyboxAssetId
        sky.SkyboxRt = CustomSkyboxAssetId
        sky.SkyboxUp = CustomSkyboxAssetId
    else
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky then sky:Destroy() end
    end
end

LightingGroup:AddToggle("LockLighting", {
    Text = "Lock Lighting Settings",
    Default = false,
    Callback = function(state)
        LockLightingEnabled = state
        if state then
            ApplyLightingSettings()
            StartLightingLocks()
            Library:Notify("Lighting settings locked.", 3)
        else
            for _, conn in pairs(LightingConnections) do
                conn:Disconnect()
            end
            LightingConnections = {}
            Library:Notify("Lighting settings unlocked.", 3)
        end
    end
})
LightingGroup:AddLabel("Ambient"):AddColorPicker("Ambient", {
    Default = Lighting.Ambient,
    Callback = function(color)
        CustomAmbient = color
        if LockLightingEnabled then
            Lighting.Ambient = color
        end
    end
})
LightingGroup:AddSlider("Brightness", {
    Text = "Brightness",
    Min = 0,
    Max = 20,
    Default = Lighting.Brightness,
    Rounding = 1,
    Callback = function(value)
        CustomBrightness = value
        if LockLightingEnabled then
            Lighting.Brightness = value
        end
    end
})
LightingGroup:AddSlider("ClockTime", {
    Text = "Clock Time",
    Min = 0,
    Max = 24,
    Default = Lighting.ClockTime,
    Rounding = 1,
    Callback = function(value)
        CustomClockTime = value
        if LockLightingEnabled then
            Lighting.ClockTime = value
        end
    end
})
LightingGroup:AddLabel("ColorShift Bottom"):AddColorPicker("ColorShiftBottom", {
    Default = Lighting.ColorShift_Bottom,
    Callback = function(color)
        CustomColorShiftBottom = color
        if LockLightingEnabled then
            Lighting.ColorShift_Bottom = color
        end
    end
})
LightingGroup:AddLabel("ColorShift Top"):AddColorPicker("ColorShiftTop", {
    Default = Lighting.ColorShift_Top,
    Callback = function(color)
        CustomColorShiftTop = color
        if LockLightingEnabled then
            Lighting.ColorShift_Top = color
        end
    end
})
LightingGroup:AddSlider("EnvironmentDiffuseScale", {
    Text = "Environment Diffuse Scale",
    Min = 0,
    Max = 1,
    Default = Lighting.EnvironmentDiffuseScale,
    Rounding = 2,
    Callback = function(value)
        CustomEnvironmentDiffuseScale = value
        if LockLightingEnabled then
            Lighting.EnvironmentDiffuseScale = value
        end
    end
})
LightingGroup:AddSlider("EnvironmentSpecularScale", {
    Text = "Environment Specular Scale",
    Min = 0,
    Max = 1,
    Default = Lighting.EnvironmentSpecularScale,
    Rounding = 2,
    Callback = function(value)
        CustomEnvironmentSpecularScale = value
        if LockLightingEnabled then
            Lighting.EnvironmentSpecularScale = value
        end
    end
})
LightingGroup:AddSlider("ExposureCompensation", {
    Text = "Exposure Compensation",
    Min = -3,
    Max = 3,
    Default = Lighting.ExposureCompensation,
    Rounding = 2,
    Callback = function(value)
        CustomExposure = value
        if LockLightingEnabled then
            Lighting.ExposureCompensation = value
        end
    end
})
LightingGroup:AddSlider("FieldOfView", {
    Text = "Field of View",
    Min = 30,
    Max = 120,
    Default = 70,
    Rounding = 0,
    Callback = function(value)
        CustomFOV = value
        if FOVEnabled then ApplyFOV() end
    end
})
LightingGroup:AddLabel("Fog Color"):AddColorPicker("FogColor", {
    Default = Lighting.FogColor,
    Callback = function(color)
        CustomFogColor = color
        if LockLightingEnabled then
            Lighting.FogColor = color
        end
    end
})
LightingGroup:AddSlider("FogEnd", {
    Text = "Fog End",
    Min = 0,
    Max = 1000000,
    Default = Lighting.FogEnd,
    Rounding = 0,
    Callback = function(value)
        CustomFogEnd = value
        if LockLightingEnabled then
            Lighting.FogEnd = value
        end
    end
})
LightingGroup:AddSlider("FogStart", {
    Text = "Fog Start",
    Min = 0,
    Max = 1000000,
    Default = Lighting.FogStart,
    Rounding = 0,
    Callback = function(value)
        CustomFogStart = value
        if LockLightingEnabled then
            Lighting.FogStart = value
        end
    end
})
LightingGroup:AddToggle("Fullbright", {
    Text = "Fullbright",
    Default = false,
    Callback = function(state)
        FullbrightEnabled = state
        if state then
            OriginalBrightness = Lighting.Brightness
            OriginalFogEnd = Lighting.FogEnd
            OriginalFogStart = Lighting.FogStart
            OriginalGlobalShadows = Lighting.GlobalShadows
            Lighting.Brightness = FullbrightBrightness
            Lighting.FogEnd = FullbrightFogEnd
            Lighting.FogStart = FullbrightFogStart
            Lighting.GlobalShadows = false
            Library:Notify("Fullbright enabled.", 3)
        else
            Lighting.Brightness = OriginalBrightness or 2
            Lighting.FogEnd = OriginalFogEnd or 100
            Lighting.FogStart = OriginalFogStart or 0
            Lighting.GlobalShadows = OriginalGlobalShadows or true
            Library:Notify("Fullbright disabled.", 3)
        end
    end
})
LightingGroup:AddSlider("FullbrightBrightness", {
    Text = "Fullbright Brightness",
    Min = 5,
    Max = 20,
    Default = 10,
    Rounding = 1,
    Callback = function(value)
        FullbrightBrightness = value
        if FullbrightEnabled then
            Lighting.Brightness = value
        end
    end
})
LightingGroup:AddSlider("FullbrightFogEnd", {
    Text = "Fullbright Fog End",
    Min = 1000,
    Max = 2000000,
    Default = 1000000,
    Rounding = 0,
    Callback = function(value)
        FullbrightFogEnd = value
        if FullbrightEnabled then
            Lighting.FogEnd = value
        end
    end
})
LightingGroup:AddSlider("FullbrightFogStart", {
    Text = "Fullbright Fog Start",
    Min = 1000,
    Max = 2000000,
    Default = 1000000,
    Rounding = 0,
    Callback = function(value)
        FullbrightFogStart = value
        if FullbrightEnabled then
            Lighting.FogStart = value
        end
    end
})
LightingGroup:AddSlider("GeographicLatitude", {
    Text = "Geographic Latitude",
    Min = -90,
    Max = 90,
    Default = Lighting.GeographicLatitude,
    Rounding = 1,
    Callback = function(value)
        CustomGeographicLatitude = value
        if LockLightingEnabled then
            Lighting.GeographicLatitude = value
        end
    end
})
LightingGroup:AddToggle("GlobalShadows", {
    Text = "Global Shadows",
    Default = Lighting.GlobalShadows,
    Callback = function(state)
        CustomGlobalShadows = state
        if LockLightingEnabled then
            Lighting.GlobalShadows = state
        end
    end
})
LightingGroup:AddToggle("LockFOV", {
    Text = "Lock FOV",
    Default = false,
    Callback = function(state)
        FOVEnabled = state
        if state then
            ApplyFOV()
            FOVConnection = Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
                if FOVEnabled and Camera.FieldOfView ~= CustomFOV then
                    ApplyFOV()
                end
            end)
            Library:Notify("FOV locked to " .. CustomFOV, 3)
        else
            if FOVConnection then
                FOVConnection:Disconnect()
                FOVConnection = nil
            end
            Camera.FieldOfView = 70
            Library:Notify("FOV unlocked.", 3)
        end
    end
})
LightingGroup:AddLabel("Outdoor Ambient"):AddColorPicker("OutdoorAmbient", {
    Default = Lighting.OutdoorAmbient,
    Callback = function(color)
        CustomOutdoorAmbient = color
        if LockLightingEnabled then
            Lighting.OutdoorAmbient = color
        end
    end
})
LightingEffectsGroup:AddButton({
    Text = "Remove All Effects",
    Func = function()
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("DepthOfFieldEffect") or effect:IsA("BlurEffect") or effect:IsA("BloomEffect") or effect:IsA("SunRaysEffect") then
                effect:Destroy()
            end
        end
        Library:Notify("All lighting effects removed.", 3)
    end
})
LightingEffectsGroup:AddButton({
    Text = "Remove Decorations",
    Func = function()
        local decorations = Workspace:FindFirstChild("MapDecorations")
        if decorations then
            decorations:Destroy()
            Library:Notify("Map decorations removed.", 3)
        else
            Library:Notify("No map decorations found.", 3)
        end
    end
})
LightingEffectsGroup:AddButton({
    Text = "Remove Fog",
    Func = function()
        Lighting.FogEnd = 1000000
        Lighting.FogStart = 1000000
        Library:Notify("Fog removed.", 3)
    end
})
LightingGroup:AddSlider("ShadowSoftness", {
    Text = "Shadow Softness",
    Min = 0,
    Max = 1,
    Default = Lighting.ShadowSoftness,
    Rounding = 2,
    Callback = function(value)
        CustomShadowSoftness = value
        if LockLightingEnabled then
            Lighting.ShadowSoftness = value
        end
    end
})
LightingGroup:AddInput("TimeOfDay", {
    Text = "Time of Day (HH:MM:SS)",
    Placeholder = "14:00:00",
    Callback = function(text)
        CustomTimeOfDay = text
        if LockLightingEnabled then
            Lighting.TimeOfDay = text
        end
    end
})
LightingGroup:AddSlider("TimeSpeed", {
    Text = "Time Speed",
    Min = 0,
    Max = 20,
    Default = 1,
    Rounding = 1,
    Callback = function(value)
        TimeSpeed = value
    end
})
LightingGroup:AddLabel("Tint"):AddColorPicker("Tint", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        CustomTint = color
        if LockLightingEnabled then
            local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
            cc.TintColor = color
        end
    end
})
LightingGroup:AddToggle("CustomSkybox", {
    Text = "Custom Skybox",
    Default = false,
    Callback = function(state)
        CustomSkyboxEnabled = state
        ApplyCustomSkybox()
        Library:Notify(state and "Custom skybox enabled." or "Custom skybox disabled.", 3)
    end
})
LightingGroup:AddInput("CustomSkyboxAssetId", {
    Text = "Skybox Asset ID",
    Placeholder = "rbxassetid://123456789",
    Callback = function(text)
        CustomSkyboxAssetId = text
        if CustomSkyboxEnabled then ApplyCustomSkybox() end
        Library:Notify("Skybox asset ID set to: " .. text, 3)
    end
})

spawn(function()
    while true do
        if not LockLightingEnabled then
            Lighting.ClockTime = Lighting.ClockTime + (TimeSpeed * 0.0167)
            if Lighting.ClockTime >= 24 then Lighting.ClockTime = 0 end
        end
        task.wait(0.0167)
    end
end)

-- 3. Miscellaneous Tab
local MiscGroup = Tabs.Miscellaneous:AddLeftGroupbox("Miscellaneous Features")
local TeleportsGroup = Tabs.Miscellaneous:AddRightGroupbox("Teleport Locations")
local AntiLagEnabled = false
local FakeLagEnabled = false
local FakeLagInterval = 1
local FakeLagDuration = 0.2
local FakeLagConnection = nil
local TeleportFadeEnabled = false
local TeleportFadeDuration = 0.5
local FPSBoostEnabled = false
local AutoWalkEnabled = false
local AutoWalkSpeed = 16
local AutoWalkStrafe = false
local AutoWalkConnection = nil
local TeleportToCursorEnabled = false
local OriginalTransparencies = {}

local function ApplyFPSBoost()
    if FPSBoostEnabled then
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency < 1 and part.Name:lower():find("decoration") then
                OriginalTransparencies[part] = part.Transparency
                part.Transparency = 1
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
    else
        for part, transparency in pairs(OriginalTransparencies) do
            if part.Parent then
                part.Transparency = transparency
            end
        end
        OriginalTransparencies = {}
        Lighting.GlobalShadows = OriginalGlobalShadows or true
        Lighting.FogEnd = OriginalFogEnd or 100
    end
end

local function StartAutoWalk()
    if not Character or not Humanoid or not RootPart then
        Library:Notify("Auto-Walk Error: Character not fully loaded.", 3)
        return
    end
    if AutoWalkConnection then
        AutoWalkConnection:Disconnect()
        AutoWalkConnection = nil
    end
    AutoWalkConnection = RunService.Heartbeat:Connect(function()
        if not AutoWalkEnabled or not Character or not Humanoid or not RootPart then
            if AutoWalkConnection then
                AutoWalkConnection:Disconnect()
                AutoWalkConnection = nil
            end
            return
        end
        local direction = Camera.CFrame.LookVector * Vector3.new(1, 0, 1)
        if AutoWalkStrafe then
            direction = direction + Camera.CFrame.RightVector * math.sin(tick())
        end
        local targetPoint = RootPart.Position + (direction * AutoWalkSpeed * 5)
        Humanoid.WalkToPoint = targetPoint
    end)
end

local function TeleportWithFade(position)
    if not Character or not RootPart then
        Library:Notify("Teleport Error: Character not found.", 3)
        return
    end
    if TeleportFadeEnabled then
        local fadeGui = Instance.new("ScreenGui", CoreGui)
        fadeGui.Name = "TeleportFade"
        local fadeFrame = Instance.new("Frame", fadeGui)
        fadeFrame.Size = UDim2.new(1, 0, 1, 0)
        fadeFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        fadeFrame.BackgroundTransparency = 1
        local fadeIn = TweenService:Create(fadeFrame, TweenInfo.new(TeleportFadeDuration / 2), {BackgroundTransparency = 0})
        local fadeOut = TweenService:Create(fadeFrame, TweenInfo.new(TeleportFadeDuration / 2), {BackgroundTransparency = 1})
        fadeIn:Play()
        fadeIn.Completed:Connect(function()
            RootPart.CFrame = position
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                fadeGui:Destroy()
            end)
        end)
    else
        RootPart.CFrame = position
    end
end

MiscGroup:AddToggle("AntiLag", {
    Text = "Anti-Lag",
    Default = false,
    Callback = function(state)
        AntiLagEnabled = state
        if state then
            ESPStates.SkeletonESPEnabled = ESPSettings.Skeleton.Enabled
            ESPStates.BoxESPEnabled = ESPSettings.Box.Enabled
            ESPStates.HeadDotsEnabled = ESPSettings.HeadDots.Enabled
            ESPStates.TracersEnabled = ESPSettings.Tracers.Enabled
            ESPStates.NameESPEnabled = ESPSettings.Names.Enabled
            ESPStates.ItemESPEnabled = ESPSettings.Items.Enabled
            ESPStates.ChamsEnabled = ChamsSettings.Enabled
            ESPStates.HighlightEnabled = HighlightSettings.Enabled
            ESPStates.HealthESPEnabled = ESPSettings.Health.Enabled
            ESPStates.WeaponESPEnabled = ESPSettings.Weapons.Enabled
            ESPStates.EnvESPEnabled = ESPSettings.Environment.Enabled
            LightingStates.FullbrightEnabled = FullbrightEnabled
            LightingStates.FOVEnabled = FOVEnabled

            ESPSettings.Skeleton.Enabled = false
            ESPSettings.Box.Enabled = false
            ESPSettings.HeadDots.Enabled = false
            ESPSettings.Tracers.Enabled = false
            ESPSettings.Names.Enabled = false
            ESPSettings.Items.Enabled = false
            ChamsSettings.Enabled = false
            HighlightSettings.Enabled = false
            ESPSettings.Health.Enabled = false
            ESPSettings.Weapons.Enabled = false
            ESPSettings.Environment.Enabled = false
            FullbrightEnabled = false
            FOVEnabled = false

            UpdateESP()
            UpdateItemESP()
            UpdateEnvESP()
            UpdateChams()
            UpdatePlayerHighlights()
            Lighting.Brightness = OriginalBrightness or 2
            Lighting.FogEnd = OriginalFogEnd or 100
            Lighting.FogStart = OriginalFogStart or 0
            Lighting.GlobalShadows = OriginalGlobalShadows or true
            if FOVConnection then
                FOVConnection:Disconnect()
                FOVConnection = nil
            end
            Camera.FieldOfView = 70
            Library:Notify("Anti-Lag enabled. Features disabled.", 3)
        else
            ESPSettings.Skeleton.Enabled = ESPStates.SkeletonESPEnabled
            ESPSettings.Box.Enabled = ESPStates.BoxESPEnabled
            ESPSettings.HeadDots.Enabled = ESPStates.HeadDotsEnabled
            ESPSettings.Tracers.Enabled = ESPStates.TracersEnabled
            ESPSettings.Names.Enabled = ESPStates.NameESPEnabled
            ESPSettings.Items.Enabled = ESPStates.ItemESPEnabled
            ChamsSettings.Enabled = ESPStates.ChamsEnabled
            HighlightSettings.Enabled = ESPStates.HighlightEnabled
            ESPSettings.Health.Enabled = ESPStates.HealthESPEnabled
            ESPSettings.Weapons.Enabled = ESPStates.WeaponESPEnabled
            ESPSettings.Environment.Enabled = ESPStates.EnvESPEnabled
            FullbrightEnabled = LightingStates.FullbrightEnabled
            FOVEnabled = LightingStates.FOVEnabled

            UpdateESP()
            UpdateItemESP()
            UpdateEnvESP()
            UpdateChams()
            UpdatePlayerHighlights()
            if FullbrightEnabled then
                Lighting.Brightness = FullbrightBrightness
                Lighting.FogEnd = FullbrightFogEnd
                Lighting.FogStart = FullbrightFogStart
                Lighting.GlobalShadows = false
            end
            if FOVEnabled then
                ApplyFOV()
                FOVConnection = Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
                    if FOVEnabled and Camera.FieldOfView ~= CustomFOV then
                        ApplyFOV()
                    end
                end)
            end
            Library:Notify("Anti-Lag disabled. Features restored.", 3)
        end
    end
})
MiscGroup:AddToggle("FakeLag", {
    Text = "Fake Lag",
    Default = false,
    Callback = function(state)
        FakeLagEnabled = state
        if state then
            FakeLagConnection = RunService.Heartbeat:Connect(function()
                if FakeLagEnabled then
                    game:GetService("NetworkClient"):SetOutgoingKBPSLimit(0)
                    task.wait(FakeLagDuration)
                    game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
                    task.wait(FakeLagInterval - FakeLagDuration)
                end
            end)
            Library:Notify("Fake Lag enabled.", 3)
        else
            if FakeLagConnection then
                FakeLagConnection:Disconnect()
                FakeLagConnection = nil
            end
            game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
            Library:Notify("Fake Lag disabled.", 3)
        end
    end
})
MiscGroup:AddSlider("FakeLagDuration", {
    Text = "Fake Lag Duration",
    Min = 0.1,
    Max = 2,
    Default = 0.2,
    Rounding = 1,
    Callback = function(value)
        FakeLagDuration = value
    end
})
MiscGroup:AddSlider("FakeLagInterval", {
    Text = "Fake Lag Interval",
    Min = 0.5,
    Max = 10,
    Default = 1,
    Rounding = 1,
    Callback = function(value)
        FakeLagInterval = value
    end
})
MiscGroup:AddToggle("FPSBoost", {
    Text = "FPS Boost",
    Default = false,
    Callback = function(state)
        FPSBoostEnabled = state
        ApplyFPSBoost()
        Library:Notify(state and "FPS Boost enabled." or "FPS Boost disabled.", 3)
    end
})
MiscGroup:AddToggle("AutoWalk", {
    Text = "Auto-Walk",
    Default = false,
    Callback = function(state)
        AutoWalkEnabled = state
        if state then
            StartAutoWalk()
            Library:Notify("Auto-Walk enabled.", 3)
        else
            if AutoWalkConnection then
                AutoWalkConnection:Disconnect()
                AutoWalkConnection = nil
            end
            if Humanoid then
                Humanoid.WalkToPoint = nil
            end
            Library:Notify("Auto-Walk disabled.", 3)
        end
    end
})
MiscGroup:AddSlider("AutoWalkSpeed", {
    Text = "Auto-Walk Speed",
    Min = 10,
    Max = 100,
    Default = 16,
    Rounding = 0,
    Callback = function(value)
        AutoWalkSpeed = value
        Library:Notify("Auto-Walk speed set to " .. value, 3)
    end
})
MiscGroup:AddToggle("AutoWalkStrafe", {
    Text = "Auto-Walk Strafe",
    Default = false,
    Callback = function(state)
        AutoWalkStrafe = state
        Library:Notify(state and "Auto-Walk strafe enabled." or "Auto-Walk strafe disabled.", 3)
    end
})
MiscGroup:AddToggle("TeleportToCursor", {
    Text = "Teleport to Cursor",
    Default = false,
    Callback = function(state)
        TeleportToCursorEnabled = state
        Library:Notify(state and "Teleport to Cursor enabled (click to teleport)." or "Teleport to Cursor disabled.", 3)
    end
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if TeleportToCursorEnabled and not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
        if raycastResult then
            TeleportWithFade(CFrame.new(raycastResult.Position + Vector3.new(0, 3, 0)))
            Library:Notify("Teleported to cursor position.", 3)
        end
    end
end)

TeleportsGroup:AddToggle("TeleportFade", {
    Text = "Teleport Fade Effect",
    Default = false,
    Callback = function(state)
        TeleportFadeEnabled = state
        Library:Notify(state and "Teleport fade effect enabled." or "Teleport fade effect disabled.", 3)
    end
})
TeleportsGroup:AddSlider("TeleportFadeDuration", {
    Text = "Teleport Fade Duration (seconds)",
    Min = 0.1,
    Max = 2,
    Default = 0.5,
    Rounding = 1,
    Callback = function(value)
        TeleportFadeDuration = value
        Library:Notify("Teleport fade duration set to " .. value .. " seconds.", 3)
    end
})
TeleportsGroup:AddButton({
    Text = "Blue House",
    Func = function()
        TeleportWithFade(CFrame.new(-53, 6, -123))
        Library:Notify("Teleported to Blue House.", 3)
    end
})
TeleportsGroup:AddButton({
    Text = "Gas Station",
    Func = function()
        TeleportWithFade(CFrame.new(-240.500031, 3.50000024, 107.500015, 0, 0, 1, 0, 1, -0, -1, 0, 0))
        Library:Notify("Teleported to Gas Station.", 3)
    end
})
TeleportsGroup:AddButton({
    Text = "Green House",
    Func = function()
        TeleportWithFade(CFrame.new(82, 8, -30))
        Library:Notify("Teleported to Green House.", 3)
    end
})
TeleportsGroup:AddButton({
    Text = "Yellow House",
    Func = function()
        TeleportWithFade(CFrame.new(30, 7, 156))
        Library:Notify("Teleported to Yellow House.", 3)
    end
})
local function GetPlayerList()
    local players = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(players, player.Name)
        end
    end
    return players
end
TeleportsGroup:AddDropdown("TeleportToPlayer", {
    Text = "Teleport to Player",
    Values = GetPlayerList(),
    AllowNull = true, -- Allow no selection if no other players are present
    Callback = function(name)
        local player = Players:FindFirstChild(name)
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            TeleportWithFade(player.Character.HumanoidRootPart.CFrame)
            Library:Notify("Teleported to " .. name, 3)
        else
            Library:Notify("Player not found or no character.", 3)
        end
    end
})
Players.PlayerAdded:Connect(function()
    TeleportsGroup:UpdateDropdown("TeleportToPlayer", GetPlayerList())
end)
Players.PlayerRemoving:Connect(function()
    TeleportsGroup:UpdateDropdown("TeleportToPlayer", GetPlayerList())
end)

-- 4. Player Tab
local PlayerGroup = Tabs.Player:AddLeftGroupbox("Player Features")
local FlyEnabled, FlySpeed, FlyVerticalSpeed, FlyConnection = false, 50, 50, nil
local FlySmoothingEnabled = false
local FlySmoothingFactor = 0.1
local FlyAcceleration = 1
local NoclipEnabled = false
local InstantRespawnEnabled = false
local GravityEnabled = false
local CustomGravity = 196.2
local WalkspeedEnabled = false
local CustomWalkspeed = 16
local WalkspeedConnection = nil
local JumpPowerEnabled = false
local CustomJumpPower = 50
local JumpPowerConnection = nil
local InfiniteJumpEnabled = false
local PlayerStates = {FlyEnabled = false, NoclipEnabled = false, InstantRespawnEnabled = false, GravityEnabled = false, WalkspeedEnabled = false, JumpPowerEnabled = false, InfiniteJumpEnabled = false}
local DiedConnections = {}

local function StartFly()
    if not Character or not Humanoid or not RootPart then
        Library:Notify("Fly Error: Character not found.", 3)
        return
    end
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    Humanoid.WalkSpeed = 0
    local control = {F = 0, B = 0, L = 0, R = 0, U = 0, D = 0}
    local lastVelocity = Vector3.new(0, 0, 0)
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then control.F = 1
        elseif input.KeyCode == Enum.KeyCode.S then control.B = -1
        elseif input.KeyCode == Enum.KeyCode.A then control.L = -1
        elseif input.KeyCode == Enum.KeyCode.D then control.R = 1
        elseif input.KeyCode == Enum.KeyCode.Space then control.U = 1
        elseif input.KeyCode == Enum.KeyCode.LeftControl then control.D = -1 end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then control.F = 0
        elseif input.KeyCode == Enum.KeyCode.S then control.B = 0
        elseif input.KeyCode == Enum.KeyCode.A then control.L = 0
        elseif input.KeyCode == Enum.KeyCode.D then control.R = 0
        elseif input.KeyCode == Enum.KeyCode.Space then control.U = 0
        elseif input.KeyCode == Enum.KeyCode.LeftControl then control.D = 0 end
    end)
    FlyConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not FlyEnabled or not Character or not Humanoid or not RootPart then
            if Humanoid then
                Humanoid.WalkSpeed = WalkspeedEnabled and CustomWalkspeed or 16
            end
            if FlyConnection then
                FlyConnection:Disconnect()
                FlyConnection = nil
            end
            return
        end
        local direction = (Camera.CFrame.LookVector * (control.F + control.B) + Camera.CFrame.RightVector * (control.R + control.L)).Unit * (FlySpeed * FlyAcceleration)
        local vertical = Vector3.new(0, (control.U + control.D) * FlyVerticalSpeed, 0)
        local targetVelocity = direction + vertical
        if FlySmoothingEnabled then
            lastVelocity = lastVelocity:Lerp(targetVelocity, FlySmoothingFactor)
            RootPart.Velocity = lastVelocity
        else
            RootPart.Velocity = targetVelocity
        end
    end)
end

local function NoclipLoop()
    while NoclipEnabled and Character do
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        RunService.Stepped:Wait()
    end
end

local function ApplyWalkspeed()
    if Humanoid then
        Humanoid.WalkSpeed = CustomWalkspeed
    end
end

local function ApplyJumpPower()
    if Humanoid then
        Humanoid.JumpPower = CustomJumpPower
    end
end

UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

PlayerGroup:AddToggle("CustomGravity", {
    Text = "Custom Gravity",
    Default = false,
    Callback = function(state)
        GravityEnabled = state
        if state then
            Workspace.Gravity = CustomGravity
            Library:Notify("Custom gravity set to " .. CustomGravity, 3)
        else
            Workspace.Gravity = 196.2
            Library:Notify("Gravity reset to default.", 3)
        end
    end
})
PlayerGroup:AddSlider("Gravity", {
    Text = "Gravity",
    Min = 0,
    Max = 392.4,
    Default = 196.2,
    Rounding = 1,
    Callback = function(value)
        CustomGravity = value
        if GravityEnabled then
            Workspace.Gravity = value
            Library:Notify("Gravity updated to " .. value, 3)
        end
    end
})
PlayerGroup:AddToggle("Fly", {
    Text = "Fly",
    Default = false,
    Callback = function(state)
        FlyEnabled = state
        if state then
            StartFly()
            Library:Notify("Fly enabled.", 3)
        else
            if FlyConnection then
                FlyConnection:Disconnect()
                FlyConnection = nil
            end
            if Humanoid then
                Humanoid.WalkSpeed = WalkspeedEnabled and CustomWalkspeed or 16
            end
            Library:Notify("Fly disabled.", 3)
        end
    end
})
PlayerGroup:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Min = 10,
    Max = 300,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        FlySpeed = value
    end
})
PlayerGroup:AddSlider("FlyVerticalSpeed", {
    Text = "Fly Vertical Speed",
    Min = 10,
    Max = 300,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        FlyVerticalSpeed = value
    end
})
PlayerGroup:AddToggle("FlySmoothing", {
    Text = "Fly Smoothing",
    Default = false,
    Callback = function(state)
        FlySmoothingEnabled = state
        Library:Notify(state and "Fly smoothing enabled." or "Fly smoothing disabled.", 3)
    end
})
PlayerGroup:AddSlider("FlySmoothingFactor", {
    Text = "Fly Smoothing Factor",
    Min = 0.01,
    Max = 1,
    Default = 0.1,
    Rounding = 2,
    Callback = function(value)
        FlySmoothingFactor = value
        Library:Notify("Fly smoothing factor set to " .. value, 3)
    end
})
PlayerGroup:AddSlider("FlyAcceleration", {
    Text = "Fly Acceleration",
    Min = 0.5,
    Max = 3,
    Default = 1,
    Rounding = 2,
    Callback = function(value)
        FlyAcceleration = value
        Library:Notify("Fly acceleration set to " .. value, 3)
    end
})
PlayerGroup:AddToggle("InstantRespawn", {
    Text = "Instant Respawn",
    Default = false,
    Callback = function(state)
        InstantRespawnEnabled = state
        if state then
            for _, conn in pairs(DiedConnections) do
                conn:Disconnect()
            end
            DiedConnections = {}
            local conn = Humanoid.Died:Connect(function()
                if InstantRespawnEnabled then
                    LocalPlayer:LoadCharacter()
                end
            end)
            table.insert(DiedConnections, conn)
            Library:Notify("Instant Respawn enabled.", 3)
        else
            for _, conn in pairs(DiedConnections) do
                conn:Disconnect()
            end
            DiedConnections = {}
            Library:Notify("Instant Respawn disabled.", 3)
        end
    end
})
PlayerGroup:AddToggle("CustomJumpPower", {
    Text = "Custom Jump Power",
    Default = false,
    Callback = function(state)
        JumpPowerEnabled = state
        if state then
            ApplyJumpPower()
            JumpPowerConnection = Humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
                if JumpPowerEnabled and Humanoid.JumpPower ~= CustomJumpPower then
                    ApplyJumpPower()
                end
            end)
            Library:Notify("Jump Power locked to " .. CustomJumpPower, 3)
        else
            if JumpPowerConnection then
                JumpPowerConnection:Disconnect()
                JumpPowerConnection = nil
            end
            if Humanoid then
                Humanoid.JumpPower = 50
            end
            Library:Notify("Jump Power unlocked.", 3)
        end
    end
})
PlayerGroup:AddSlider("JumpPower", {
    Text = "Jump Power",
    Min = 50,
    Max = 200,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        CustomJumpPower = value
        if JumpPowerEnabled then
            ApplyJumpPower()
        end
    end
})
PlayerGroup:AddToggle("InfiniteJump", {
    Text = "Infinite Jump",
    Default = false,
    Callback = function(state)
        InfiniteJumpEnabled = state
        Library:Notify(state and "Infinite Jump enabled." or "Infinite Jump disabled.", 3)
    end
})
PlayerGroup:AddToggle("Noclip", {
    Text = "Noclip",
    Default = false,
    Callback = function(state)
        NoclipEnabled = state
        if state then
            spawn(NoclipLoop)
            Library:Notify("Noclip enabled.", 3)
        else
            Library:Notify("Noclip disabled.", 3)
        end
    end
})
PlayerGroup:AddToggle("LockWalkspeed", {
    Text = "Lock Walkspeed",
    Default = false,
    Callback = function(state)
        WalkspeedEnabled = state
        if state then
            ApplyWalkspeed()
            WalkspeedConnection = Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if WalkspeedEnabled and Humanoid.WalkSpeed ~= CustomWalkspeed and not FlyEnabled then
                    ApplyWalkspeed()
                end
            end)
            Library:Notify("Walkspeed locked to " .. CustomWalkspeed, 3)
        else
            if WalkspeedConnection then
                WalkspeedConnection:Disconnect()
                WalkspeedConnection = nil
            end
            if Humanoid and not FlyEnabled then
                Humanoid.WalkSpeed = 16
            end
            Library:Notify("Walkspeed unlocked.", 3)
        end
    end
})
PlayerGroup:AddSlider("Walkspeed", {
    Text = "Walkspeed",
    Min = 16,
    Max = 300,
    Default = 16,
    Rounding = 0,
    Callback = function(value)
        CustomWalkspeed = value
        if WalkspeedEnabled then
            ApplyWalkspeed()
        end
    end
})

-- 5. Visual Tab
-- ESP Settings Organized into Tables
local ESPSettings = {
    Skeleton = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 0),
        Thickness = 2,
        Transparency = 1,
        Elements = {}
    },
    Box = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
        Thickness = 2,
        Transparency = 1,
        Elements = {}
    },
    HeadDots = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 0),
        Radius = 5,
        Transparency = 1,
        Elements = {}
    },
    Tracers = {
        Enabled = false,
        Color = Color3.fromRGB(0, 0, 255),
        Thickness = 2,
        Transparency = 1,
        Elements = {}
    },
    Names = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Size = 20,
        Transparency = 1,
        Elements = {}
    },
    Items = {
        Enabled = false,
        Color = Color3.fromRGB(255, 165, 0),
        Size = 20,
        Transparency = 1,
        Elements = {}
    },
    Health = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
        Size = Vector2.new(50, 5),
        Offset = 3,
        Transparency = 1,
        Elements = {}
    },
    Weapons = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 255),
        Size = 20,
        Offset = 1,
        Transparency = 1,
        Elements = {}
    },
    Environment = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 255),
        Size = 20,
        Transparency = 1,
        Elements = {}
    }
}

local ChamsSettings = {
    Enabled = false,
    FillColor = Color3.fromRGB(255, 0, 0),
    OutlineColor = Color3.fromRGB(255, 255, 0),
    FillTransparency = 0.5,
    OutlineTransparency = 0,
    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    Highlights = {}
}

local HighlightSettings = {
    Enabled = false,
    FillColor = Color3.fromRGB(0, 255, 255),
    OutlineColor = Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.5,
    OutlineTransparency = 0,
    HighlightedPlayers = {},
    PlayerHighlights = {}
}

local ESPConfig = {
    DistanceLimit = 1000,
    FadeEnabled = false,
    FadeDistance = 500,
    FilterMode = "All", -- All, Players, Teams, Objects
    FilteredPlayers = {},
    FilteredTeams = {},
    FilteredObjects = {"Weapon", "Collectible", "Door", "Vehicle", "Interactable"},
    TeamESPEnabled = false,
    TeamESPUseCustom = false,
    DistanceESPEnabled = false
}

local VisualEffects = {
    XRay = {
        Enabled = false,
        Transparency = 0.7
    },
    Particles = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255)
    },
    Crosshair = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 0),
        EnemyColor = Color3.fromRGB(0, 255, 0),
        Size = 10,
        Thickness = 2,
        Transparency = 1,
        RecoilAdjust = false,
        Lines = {}
    }
}

local ESPStates = {
    SkeletonESPEnabled = false,
    BoxESPEnabled = false,
    HeadDotsEnabled = false,
    TracersEnabled = false,
    NameESPEnabled = false,
    ItemESPEnabled = false,
    ChamsEnabled = false,
    HighlightEnabled = false,
    HealthESPEnabled = false,
    WeaponESPEnabled = false,
    EnvESPEnabled = false
}

-- Simplified GetESPColor Function
local function GetESPColor(player, espType)
    if ESPConfig.TeamESPEnabled and not ESPConfig.TeamESPUseCustom and player.Team then
        return player.TeamColor.Color
    end
    return ESPSettings[espType].Color
end

-- Helper Function to Check ESP Filters
local function ShouldRenderESP(player, espType)
    if player == LocalPlayer then return false end
    if not ESPSettings[espType].Enabled then return false end
    if ESPConfig.FilterMode == "Players" and not ESPConfig.FilteredPlayers[player] then return false end
    if ESPConfig.FilterMode == "Teams" and (not player.Team or not table.find(ESPConfig.FilteredTeams, player.Team)) then return false end
    if RootPart and player.Character and (player.Character:GetPivot().Position - RootPart.Position).Magnitude > ESPConfig.DistanceLimit then return false end
    return true
end

-- Modular ESP Creation Functions
local function CreateSkeletonESP(player)
    if not ShouldRenderESP(player, "Skeleton") then return end
    local char = player.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    local humanoid = char:FindFirstChild("Humanoid")
    local rigType = humanoid.RigType
    local bones = rigType == Enum.HumanoidRigType.R15 and {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"LowerTorso", "LeftUpperLeg"},
        {"LowerTorso", "RightUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"RightUpperLeg", "RightLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"}, {"RightLowerLeg", "RightFoot"}, {"UpperTorso", "LeftUpperArm"},
        {"UpperTorso", "RightUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"RightUpperArm", "RightLowerArm"},
        {"LeftLowerArm", "LeftHand"}, {"RightLowerArm", "RightHand"}
    } or {{"Head", "Torso"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}}
    local skeletonElements = {}
    for _, bone in ipairs(bones) do
        local part1, part2 = char:FindFirstChild(bone[1]), char:FindFirstChild(bone[2])
        if part1 and part2 then
            local line = Drawing.new("Line")
            line.Visible = true
            line.Color = GetESPColor(player, "Skeleton")
            line.Thickness = ESPSettings.Skeleton.Thickness
            line.Transparency = ESPSettings.Skeleton.Transparency
            table.insert(skeletonElements, {Line = line, Part1 = part1, Part2 = part2})
        end
    end
    table.insert(ESPSettings.Skeleton.Elements, {Player = player, Lines = skeletonElements})
end

local function CreateBoxESP(player)
    if not ShouldRenderESP(player, "Box") then return end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root, head = char.HumanoidRootPart, char:FindFirstChild("Head")
    local box = Drawing.new("Square")
    box.Visible = true
    box.Color = GetESPColor(player, "Box")
    box.Thickness = ESPSettings.Box.Thickness
    box.Filled = false
    box.Transparency = ESPSettings.Box.Transparency
    table.insert(ESPSettings.Box.Elements, {Box = box, Player = player, Root = root, Head = head})
end

local function CreateHeadDot(player)
    if not ShouldRenderESP(player, "HeadDots") then return end
    local char = player.Character
    if not char or not char:FindFirstChild("Head") then return end
    local head = char.Head
    local dot = Drawing.new("Circle")
    dot.Visible = true
    dot.Color = GetESPColor(player, "HeadDots")
    dot.Thickness = 2
    dot.Radius = ESPSettings.HeadDots.Radius
    dot.Filled = true
    dot.Transparency = ESPSettings.HeadDots.Transparency
    table.insert(ESPSettings.HeadDots.Elements, {Dot = dot, Player = player, Head = head})
end

local function CreateTracer(player)
    if not ShouldRenderESP(player, "Tracers") then return end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    local tracer = Drawing.new("Line")
    tracer.Visible = true
    tracer.Color = GetESPColor(player, "Tracers")
    tracer.Thickness = ESPSettings.Tracers.Thickness
    tracer.Transparency = ESPSettings.Tracers.Transparency
    table.insert(ESPSettings.Tracers.Elements, {Tracer = tracer, Player = player, Root = root})
end

local function CreateNameESP(player)
    if not ShouldRenderESP(player, "Names") then return end
    local char = player.Character
    if not char or not char:FindFirstChild("Head") then return end
    local head = char.Head
    local text = Drawing.new("Text")
    text.Visible = true
    text.Color = GetESPColor(player, "Names")
    text.Size = ESPSettings.Names.Size
    text.Center = true
    text.Outline = true
    text.Text = player.Name
    text.Transparency = ESPSettings.Names.Transparency
    table.insert(ESPSettings.Names.Elements, {Text = text, Player = player, Head = head})
end

local function CreateItemESP(item)
    if not ESPSettings.Items.Enabled then return end
    if ESPConfig.FilterMode == "Objects" and not table.find(ESPConfig.FilteredObjects, item.Name) then return end
    if RootPart and (item.Position - RootPart.Position).Magnitude > ESPConfig.DistanceLimit then return end
    local text = Drawing.new("Text")
    text.Visible = true
    text.Color = ESPSettings.Items.Color
    text.Size = ESPSettings.Items.Size
    text.Center = true
    text.Outline = true
    text.Text = item.Name
    text.Transparency = ESPSettings.Items.Transparency
    table.insert(ESPSettings.Items.Elements, {Text = text, Item = item})
end

local function CreateHealthESP(player)
    if not ShouldRenderESP(player, "Health") then return end
    local char = player.Character
    if not char or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("Head") then return end
    local humanoid, head = char.Humanoid, char.Head
    local bar = Drawing.new("Quad")
    bar.Visible = true
    bar.Color = ESPSettings.Health.Color
    bar.Thickness = 2
    bar.Filled = true
    bar.Transparency = ESPSettings.Health.Transparency
    table.insert(ESPSettings.Health.Elements, {Bar = bar, Player = player, Humanoid = humanoid, Head = head})
end

local function CreateWeaponESP(player)
    if not ShouldRenderESP(player, "Weapons") then return end
    local char = player.Character
    if not char or not char:FindFirstChild("Head") then return end
    local head = char.Head
    local weapon = nil
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            weapon = tool
            break
        end
    end
    local text = Drawing.new("Text")
    text.Visible = true
    text.Color = GetESPColor(player, "Weapons")
    text.Size = ESPSettings.Weapons.Size
    text.Center = true
    text.Outline = true
    text.Text = weapon and weapon.Name or "None"
    text.Transparency = ESPSettings.Weapons.Transparency
    table.insert(ESPSettings.Weapons.Elements, {Text = text, Player = player, Head = head, Weapon = weapon})
end

local function CreateEnvESP(obj)
    if not ESPSettings.Environment.Enabled then return end
    if ESPConfig.FilterMode == "Objects" and not table.find(ESPConfig.FilteredObjects, obj.Name) then return end
    if RootPart and (obj.Position - RootPart.Position).Magnitude > ESPConfig.DistanceLimit then return end
    local text = Drawing.new("Text")
    text.Visible = true
    text.Color = ESPSettings.Environment.Color
    text.Size = ESPSettings.Environment.Size
    text.Center = true
    text.Outline = true
    text.Text = obj.Name
    text.Transparency = ESPSettings.Environment.Transparency
    table.insert(ESPSettings.Environment.Elements, {Text = text, Object = obj})
end

local function CreateChams(player)
    if player == LocalPlayer or not ChamsSettings.Enabled then return end
    local char = player.Character
    if not char then return end
    if RootPart and (char:GetPivot().Position - RootPart.Position).Magnitude > ESPConfig.DistanceLimit then return end
    if ESPConfig.FilterMode == "Players" and not ESPConfig.FilteredPlayers[player] then return end
    if ESPConfig.FilterMode == "Teams" and (not player.Team or not table.find(ESPConfig.FilteredTeams, player.Team)) then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESPConfig.TeamESPEnabled and not ESPConfig.TeamESPUseCustom and player.Team and player.TeamColor.Color or ChamsSettings.FillColor
    highlight.OutlineColor = ChamsSettings.OutlineColor
    highlight.FillTransparency = ChamsSettings.FillTransparency
    highlight.OutlineTransparency = ChamsSettings.OutlineTransparency
    highlight.DepthMode = ChamsSettings.DepthMode
    highlight.Adornee = char
    highlight.Parent = char
    table.insert(ChamsSettings.Highlights, {Highlight = highlight, Player = player})
end

local function CreatePlayerHighlight(player)
    if player == LocalPlayer or not HighlightSettings.Enabled or not HighlightSettings.HighlightedPlayers[player] then return end
    local char = player.Character
    if not char then return end
    if RootPart and (char:GetPivot().Position - RootPart.Position).Magnitude > ESPConfig.DistanceLimit then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = HighlightSettings.FillColor
    highlight.OutlineColor = HighlightSettings.OutlineColor
    highlight.FillTransparency = HighlightSettings.FillTransparency
    highlight.OutlineTransparency = HighlightSettings.OutlineTransparency
    highlight.Adornee = char
    highlight.Parent = char
    table.insert(HighlightSettings.PlayerHighlights, {Highlight = highlight, Player = player})
end

local function CreateCrosshair()
    for _, line in pairs(VisualEffects.Crosshair.Lines) do
        line:Remove()
    end
    VisualEffects.Crosshair.Lines = {}
    if VisualEffects.Crosshair.Enabled then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local positions = {
            {From = screenCenter + Vector2.new(VisualEffects.Crosshair.Size, 0), To = screenCenter + Vector2.new(VisualEffects.Crosshair.Size * 2, 0)}, -- Right
            {From = screenCenter + Vector2.new(-VisualEffects.Crosshair.Size, 0), To = screenCenter + Vector2.new(-VisualEffects.Crosshair.Size * 2, 0)}, -- Left
            {From = screenCenter + Vector2.new(0, VisualEffects.Crosshair.Size), To = screenCenter + Vector2.new(0, VisualEffects.Crosshair.Size * 2)}, -- Bottom
            {From = screenCenter + Vector2.new(0, -VisualEffects.Crosshair.Size), To = screenCenter + Vector2.new(0, -VisualEffects.Crosshair.Size * 2)} -- Top
        }
        for _, pos in ipairs(positions) do
            local line = Drawing.new("Line")
            line.Visible = true
            line.Color = VisualEffects.Crosshair.Color
            line.Thickness = VisualEffects.Crosshair.Thickness
            line.Transparency = VisualEffects.Crosshair.Transparency
            line.From = pos.From
            line.To = pos.To
            table.insert(VisualEffects.Crosshair.Lines, line)
        end
    end
end

local function UpdateCrosshair()
    if not VisualEffects.Crosshair.Enabled then return end
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
    local isEnemy = false
    if raycastResult and raycastResult.Instance then
        local hitChar = raycastResult.Instance:FindFirstAncestorOfClass("Model")
        if hitChar and hitChar ~= Character then
            local player = Players:GetPlayerFromCharacter(hitChar)
            if player and player ~= LocalPlayer then
                isEnemy = true
            end
        end
    end
    local color = isEnemy and VisualEffects.Crosshair.EnemyColor or VisualEffects.Crosshair.Color
    local offset = VisualEffects.Crosshair.RecoilAdjust and math.sin(tick() * 2) * 2 or 0
    local positions = {
        {From = screenCenter + Vector2.new(VisualEffects.Crosshair.Size + offset, 0), To = screenCenter + Vector2.new(VisualEffects.Crosshair.Size * 2 + offset, 0)},
        {From = screenCenter + Vector2.new(-VisualEffects.Crosshair.Size - offset, 0), To = screenCenter + Vector2.new(-VisualEffects.Crosshair.Size * 2 - offset, 0)},
        {From = screenCenter + Vector2.new(0, VisualEffects.Crosshair.Size + offset), To = screenCenter + Vector2.new(0, VisualEffects.Crosshair.Size * 2 + offset)},
        {From = screenCenter + Vector2.new(0, -VisualEffects.Crosshair.Size - offset), To = screenCenter + Vector2.new(0, -VisualEffects.Crosshair.Size * 2 - offset)}
    }
    for i, line in ipairs(VisualEffects.Crosshair.Lines) do
        line.Color = color
        line.From = positions[i].From
        line.To = positions[i].To
    end
end

local function UpdateESP()
    for _, esp in pairs(ESPSettings.Skeleton.Elements) do
        for _, lineData in ipairs(esp.Lines) do
            lineData.Line:Remove()
        end
    end
    ESPSettings.Skeleton.Elements = {}
    for _, esp in pairs(ESPSettings.Box.Elements) do
        esp.Box:Remove()
    end
    ESPSettings.Box.Elements = {}
    for _, esp in pairs(ESPSettings.HeadDots.Elements) do
        esp.Dot:Remove()
    end
    ESPSettings.HeadDots.Elements = {}
    for _, esp in pairs(ESPSettings.Tracers.Elements) do
        esp.Tracer:Remove()
    end
    ESPSettings.Tracers.Elements = {}
    for _, esp in pairs(ESPSettings.Names.Elements) do
        esp.Text:Remove()
    end
    ESPSettings.Names.Elements = {}
    for _, esp in pairs(ESPSettings.Health.Elements) do
        esp.Bar:Remove()
    end
    ESPSettings.Health.Elements = {}
    for _, esp in pairs(ESPSettings.Weapons.Elements) do
        esp.Text:Remove()
    end
    ESPSettings.Weapons.Elements = {}
    for player in pairs(ESPConfig.FilteredPlayers) do
        if not Players:FindFirstChild(player.Name) then
            ESPConfig.FilteredPlayers[player] = nil
        end
    end
    for _, player in pairs(Players:GetPlayers()) do
        if ESPSettings.Skeleton.Enabled then CreateSkeletonESP(player) end
        if ESPSettings.Box.Enabled then CreateBoxESP(player) end
        if ESPSettings.HeadDots.Enabled then CreateHeadDot(player) end
        if ESPSettings.Tracers.Enabled then CreateTracer(player) end
        if ESPSettings.Names.Enabled then CreateNameESP(player) end
        if ESPSettings.Health.Enabled then CreateHealthESP(player) end
        if ESPSettings.Weapons.Enabled then CreateWeaponESP(player) end
    end
end

local function UpdateItemESP()
    for _, esp in pairs(ESPSettings.Items.Elements) do
        esp.Text:Remove()
    end
    ESPSettings.Items.Elements = {}
    if ESPSettings.Items.Enabled then
        for _, item in pairs(Workspace:GetDescendants()) do
            if item:IsA("BasePart") and (item.Name:lower():find("weapon") or item.Name:lower():find("collectible")) then
                CreateItemESP(item)
            end
        end
    end
end

local function UpdateEnvESP()
    for _, esp in pairs(ESPSettings.Environment.Elements) do
        esp.Text:Remove()
    end
    ESPSettings.Environment.Elements = {}
    if ESPSettings.Environment.Enabled then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and table.find({"Door", "Vehicle", "Interactable"}, obj.Name) then
                CreateEnvESP(obj)
            end
        end
    end
end

local function UpdateChams()
    for _, cham in pairs(ChamsSettings.Highlights) do
        cham.Highlight:Destroy()
    end
    ChamsSettings.Highlights = {}
    if ChamsSettings.Enabled then
        for _, player in pairs(Players:GetPlayers()) do
            CreateChams(player)
        end
    end
end

local function UpdatePlayerHighlights()
    for _, highlight in pairs(HighlightSettings.PlayerHighlights) do
        highlight.Highlight:Destroy()
    end
    HighlightSettings.PlayerHighlights = {}
    if HighlightSettings.Enabled then
        for player in pairs(HighlightSettings.HighlightedPlayers) do
            CreatePlayerHighlight(player)
        end
    end
end

local function ApplyXRay()
    if VisualEffects.XRay.Enabled then
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsDescendantOf(Character) then
                part.Transparency = VisualEffects.XRay.Transparency
            end
        end
    else
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsDescendantOf(Character) then
                part.Transparency = OriginalTransparencies[part] or 0
            end
        end
    end
end

local function ApplyCustomParticles()
    if VisualEffects.Particles.Enabled and Character and RootPart then
        local particleEmitter = RootPart:FindFirstChild("CustomParticleEmitter")
        if not particleEmitter then
            particleEmitter = Instance.new("ParticleEmitter")
            particleEmitter.Name = "CustomParticleEmitter"
            particleEmitter.Texture = "rbxassetid://243098098"
            particleEmitter.Lifetime = NumberRange.new(1, 2)
            particleEmitter.Rate = 50
            particleEmitter.Speed = NumberRange.new(5, 10)
            particleEmitter.Parent = RootPart
        end
        particleEmitter.Color = ColorSequence.new(VisualEffects.Particles.Color)
        particleEmitter.Enabled = true
    else
        if Character and RootPart then
            local particleEmitter = RootPart:FindFirstChild("CustomParticleEmitter")
            if particleEmitter then
                particleEmitter:Destroy()
            end
        end
    end
end

-- Visual Tab Groupboxes
local ESPGroup = Tabs.Visual:AddLeftGroupbox("ESP Features")
local ESPConfigGroup = Tabs.Visual:AddLeftGroupbox("ESP Configuration")
local ChamsGroup = Tabs.Visual:AddRightGroupbox("Chams Settings")
local VisualEffectsGroup = Tabs.Visual:AddRightGroupbox("Visual Effects")

-- ESP Features
ESPGroup:AddToggle("SkeletonESP", {
    Text = "Skeleton ESP",
    Default = false,
    Callback = function(state)
        ESPSettings.Skeleton.Enabled = state
        UpdateESP()
        Library:Notify(state and "Skeleton ESP enabled." or "Skeleton ESP disabled.", 3)
    end
})
ESPGroup:AddLabel("Skeleton Color"):AddColorPicker("SkeletonColor", {
    Default = ESPSettings.Skeleton.Color,
    Callback = function(color)
        ESPSettings.Skeleton.Color = color
        UpdateESP()
    end
})
ESPGroup:AddSlider("SkeletonThickness", {
    Text = "Skeleton Thickness",
    Min = 1,
    Max = 5,
    Default = 2,
    Rounding = 0,
    Callback = function(value)
        ESPSettings.Skeleton.Thickness = value
        UpdateESP()
    end
})
ESPGroup:AddSlider("SkeletonTransparency", {
    Text = "Skeleton Transparency",
    Min = 0,
    Max = 1,
    Default = 1,
    Rounding = 2,
    Callback = function(value)
        ESPSettings.Skeleton.Transparency = value
        UpdateESP()
    end
})
ESPGroup:AddToggle("BoxESP", {
    Text = "Box ESP",
    Default = false,
    Callback = function(state)
        ESPSettings.Box.Enabled = state
        UpdateESP()
        Library:Notify(state and "Box ESP enabled." or "Box ESP disabled.", 3)
    end
})
ESPGroup:AddLabel("Box Color"):AddColorPicker("BoxColor", {
    Default = ESPSettings.Box.Color,
    Callback = function(color)
        ESPSettings.Box.Color = color
        UpdateESP()
    end
})
ESPGroup:AddSlider("BoxThickness", {
    Text = "Box Thickness",
    Min = 1,
    Max = 5,
    Default = 2,
    Rounding = 0,
    Callback = function(value)
        ESPSettings.Box.Thickness = value
        UpdateESP()
    end
})
ESPGroup:AddSlider("BoxTransparency", {
    Text = "Box Transparency",
    Min = 0,
    Max = 1,
    Default = 1,
    Rounding = 2,
    Callback = function(value)
        ESPSettings.Box.Transparency = value
        UpdateESP()
    end
})
ESPGroup:AddToggle("HeadDotsESP", {
    Text = "Head Dots ESP",
    Default = false,
    Callback = function(state)
        ESPSettings.HeadDots.Enabled = state
        UpdateESP()
        Library:Notify(state and "Head Dots ESP enabled." or "Head Dots ESP disabled.", 3)
    end
})
ESPGroup:AddLabel("Head Dot Color"):AddColorPicker("HeadDotColor", {
    Default = ESPSettings.HeadDots.Color,
    Callback = function(color)
        ESPSettings.HeadDots.Color = color
        UpdateESP()
    end
})
ESPGroup:AddSlider("HeadDotRadius", {
    Text = "Head Dot Radius",
    Min = 1,
    Max = 10,
    Default = 5,
    Rounding = 0,
    Callback = function(value)
        ESPSettings.HeadDots.Radius = value
        UpdateESP()
    end
})
ESPGroup:AddSlider("HeadDotTransparency", {
    Text = "Head Dot Transparency",
    Min = 0,
    Max = 1,
    Default = 1,
    Rounding = 2,
    Callback = function(value)
        ESPSettings.HeadDots.Transparency = value
        UpdateESP()
    end
})
ESPGroup:AddToggle("TracerESP", {
    Text = "Tracer ESP",
    Default = false,
    Callback = function(state)
        ESPSettings.Tracers.Enabled = state
        UpdateESP()
        Library:Notify(state and "Tracer ESP enabled." or "Tracer ESP disabled.", 3)
    end
})
ESPGroup:AddLabel("Tracer Color"):AddColorPicker("TracerColor", {
    Default = ESPSettings.Tracers.Color,
    Callback = function(color)
        ESPSettings.Tracers.Color = color
        UpdateESP()
    end
})
ESPGroup:AddSlider("TracerThickness", {
    Text = "Tracer Thickness",
    Min = 1,
    Max = 5,
    Default = 2,
    Rounding = 0,
    Callback = function(value)
        ESPSettings.Tracers.Thickness = value
        UpdateESP()
    end
})
ESPGroup:AddSlider("TracerTransparency", {
    Text = "Tracer Transparency",
    Min = 0,
    Max = 1,
    Default = 1,
    Rounding = 2,
    Callback = function(value)
        ESPSettings.Tracers.Transparency = value
        UpdateESP()
    end
})
ESPGroup:AddToggle("NameESP", {
    Text = "Name ESP",
    Default = false,
    Callback = function(state)
        ESPSettings.Names.Enabled = state
        UpdateESP()
        Library:Notify(state and "Name ESP enabled." or "Name ESP disabled.", 3)
    end
})
ESPGroup:AddLabel("Name Color"):AddColorPicker("NameColor", {
    Default = ESPSettings.Names.Color,
    Callback = function(color)
        ESPSettings.Names.Color = color
        UpdateESP()
    end
})
ESPGroup:AddSlider("NameSize", {
    Text = "Name Size",
    Min = 10,
    Max = 30,
    Default = 20,
    Rounding = 0,
    Callback = function(value)
        ESPSettings.Names.Size = value
        UpdateESP()
    end
})
ESPGroup:AddSlider("NameTransparency", {
    Text = "Name Transparency",
    Min = 0,
    Max = 1,
    Default = 1,
    Rounding = 2,
    Callback = function(value)
        ESPSettings.Names.Transparency = value
        UpdateESP()
    end
})
ESPGroup:AddToggle("ItemESP", {
    Text = "Item ESP",
    Default = false,
    Callback = function(state)
        ESPSettings.Items.Enabled = state
        UpdateItemESP()
        Library:Notify(state and "Item ESP enabled." or "Item ESP disabled.", 3)
    end
})
ESPGroup:AddLabel("Item Color"):AddColorPicker("ItemColor", {
    Default = ESPSettings.Items.Color,
    Callback = function(color)
        ESPSettings.Items.Color = color
        UpdateItemESP()
    end
})
ESPGroup:AddSlider("ItemSize", {
    Text = "Item Text Size",
    Min = 10,
    Max = 30,
    Default = 20,
    Rounding = 0,
    Callback = function(value)
        ESPSettings.Items.Size = value
        UpdateItemESP()
    end
})
ESPGroup:AddSlider("ItemTransparency", {
    Text = "Item Transparency",
    Min = 0,
    Max = 1,
    Default = 1,
    Rounding = 2,
    Callback = function(value)
        ESPSettings.Items.Transparency = value
        UpdateItemESP()
    end
})
ESPGroup:AddToggle("HealthESP", {
    Text = "Health ESP",
    Default = false,
    Callback = function(state)
        ESPSettings.Health.Enabled = state
        UpdateESP()
        Library:Notify(state and "Health ESP enabled." or "Health ESP disabled.", 3)
    end
})
ESPGroup:AddLabel("Health Bar Color"):AddColorPicker("HealthColor", {
    Default = ESPSettings.Health.Color,
    Callback = function(color)
        ESPSettings.Health.Color = color
        UpdateESP()
    end
})
ESPGroup:AddSlider("HealthTransparency", {
    Text = "Health Bar Transparency",
    Min = 0,
    Max = 1,
    Default = 1,
    Rounding = 2,
    Callback = function(value)
        ESPSettings.Health.Transparency = value
        UpdateESP()
    end
})
ESPGroup:AddToggle("WeaponESP", {
    Text = "Weapon ESP",
    Default = false,
    Callback = function(state)
        ESPSettings.Weapons.Enabled = state
        UpdateESP()
        Library:Notify(state and "Weapon ESP enabled." or "Weapon ESP disabled.", 3)
    end
})
ESPGroup:AddLabel("Weapon Color"):AddColorPicker("WeaponColor", {
    Default = ESPSettings.Weapons.Color,
    Callback = function(color)
        ESPSettings.Weapons.Color = color
        UpdateESP()
    end
})
ESPGroup:AddSlider("WeaponSize", {
    Text = "Weapon Text Size",
    Min = 10,
    Max = 30,
    Default = 20,
    Rounding = 0,
    Callback = function(value)
        ESPSettings.Weapons.Size = value
        UpdateESP()
    end
})
ESPGroup:AddSlider("WeaponTransparency", {
    Text = "Weapon Transparency",
    Min = 0,
    Max = 1,
    Default = 1,
    Rounding = 2,
    Callback = function(value)
        ESPSettings.Weapons.Transparency = value
        UpdateESP()
    end
})
ESPGroup:AddToggle("EnvESP", {
    Text = "Environment ESP",
    Default = false,
    Callback = function(state)
        ESPSettings.Environment.Enabled = state
        UpdateEnvESP()
        Library:Notify(state and "Environment ESP enabled." or "Environment ESP disabled.", 3)
    end
})
ESPGroup:AddLabel("Environment Color"):AddColorPicker("EnvColor", {
    Default = ESPSettings.Environment.Color,
    Callback = function(color)
        ESPSettings.Environment.Color = color
        UpdateEnvESP()
    end
})
ESPGroup:AddSlider("EnvSize", {
    Text = "Environment Text Size",
    Min = 10,
    Max = 30,
    Default = 20,
    Rounding = 0,
    Callback = function(value)
        ESPSettings.Environment.Size = value
        UpdateEnvESP()
    end
})
ESPGroup:AddSlider("EnvTransparency", {
    Text = "Environment Transparency",
    Min = 0,
    Max = 1,
    Default = 1,
    Rounding = 2,
    Callback = function(value)
        ESPSettings.Environment.Transparency = value
        UpdateEnvESP()
    end
})

-- ESP Configuration
ESPConfigGroup:AddSlider("ESPDistanceLimit", {
    Text = "ESP Distance Limit",
    Min = 100,
    Max = 5000,
    Default = 1000,
    Rounding = 0,
    Callback = function(value)
        ESPConfig.DistanceLimit = value
        UpdateESP()
        UpdateItemESP()
        UpdateEnvESP()
        UpdateChams()
        UpdatePlayerHighlights()
    end
})
ESPConfigGroup:AddToggle("ESPFade", {
    Text = "ESP Fade Effect",
    Default = false,
    Callback = function(state)
        ESPConfig.FadeEnabled = state
    end
})
ESPConfigGroup:AddSlider("ESPFadeDistance", {
    Text = "ESP Fade Distance",
    Min = 100,
    Max = 2000,
    Default = 500,
    Rounding = 0,
    Callback = function(value)
        ESPConfig.FadeDistance = value
    end
})
ESPConfigGroup:AddDropdown("ESPFilterMode", {
    Text = "ESP Filter Mode",
    Values = {"All", "Players", "Teams", "Objects"},
    Default = "All",
    Callback = function(value)
        ESPConfig.FilterMode = value
        UpdateESP()
        UpdateItemESP()
        UpdateEnvESP()
        UpdateChams()
        UpdatePlayerHighlights()
    end
})
ESPConfigGroup:AddDropdown("ESPFilteredPlayers", {
    Text = "Filtered Players",
    Values = GetPlayerList(),
    Multi = true,
    AllowNull = true, -- Fix for "AddDropdown: Missing default value" error
    Callback = function(selected)
        ESPConfig.FilteredPlayers = {}
        for _, name in pairs(selected) do
            local player = Players:FindFirstChild(name)
            if player then
                ESPConfig.FilteredPlayers[player] = true
            end
        end
        UpdateESP()
        UpdateChams()
        UpdatePlayerHighlights()
    end
})
ESPConfigGroup:AddDropdown("ESPFilteredTeams", {
    Text = "Filtered Teams",
    Values = {}, -- TODO: Populate dynamically with available teams
    Multi = true,
    AllowNull = true, -- Allow no selection until teams are populated dynamically
    Callback = function(selected)
        ESPConfig.FilteredTeams = selected
        UpdateESP()
        UpdateChams()
    end
})
ESPConfigGroup:AddDropdown("ESPFilteredObjects", {
    Text = "Filtered Objects",
    Values = {"Weapon", "Collectible", "Door", "Vehicle", "Interactable"},
    Default = {"Weapon", "Collectible", "Door", "Vehicle", "Interactable"},
    Multi = true,
    Callback = function(selected)
        ESPConfig.FilteredObjects = selected
        UpdateItemESP()
        UpdateEnvESP()
    end
})
ESPConfigGroup:AddToggle("TeamESP", {
    Text = "Team-Based ESP Coloring",
    Default = false,
    Callback = function(state)
        ESPConfig.TeamESPEnabled = state
        UpdateESP()
        UpdateChams()
    end
})
ESPConfigGroup:AddToggle("TeamESPUseCustom", {
    Text = "Use Custom Colors for Team ESP",
    Default = false,
    Callback = function(state)
        ESPConfig.TeamESPUseCustom = state
        UpdateESP()
        UpdateChams()
    end
})
ESPConfigGroup:AddToggle("DistanceESP", {
    Text = "Distance ESP",
    Default = false,
    Callback = function(state)
        ESPConfig.DistanceESPEnabled = state
        UpdateESP()
    end
})

-- Chams Settings
ChamsGroup:AddToggle("Chams", {
    Text = "Chams",
    Default = false,
    Callback = function(state)
        ChamsSettings.Enabled = state
        UpdateChams()
        Library:Notify(state and "Chams enabled." or "Chams disabled.", 3)
    end
})
ChamsGroup:AddLabel("Fill Color"):AddColorPicker("ChamsFillColor", {
    Default = ChamsSettings.FillColor,
    Callback = function(color)
        ChamsSettings.FillColor = color
        UpdateChams()
    end
})
ChamsGroup:AddLabel("Outline Color"):AddColorPicker("ChamsOutlineColor", {
    Default = ChamsSettings.OutlineColor,
    Callback = function(color)
        ChamsSettings.OutlineColor = color
        UpdateChams()
    end
})
ChamsGroup:AddSlider("ChamsFillTransparency", {
    Text = "Fill Transparency",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Rounding = 2,
    Callback = function(value)
        ChamsSettings.FillTransparency = value
        UpdateChams()
    end
})
ChamsGroup:AddSlider("ChamsOutlineTransparency", {
    Text = "Outline Transparency",
    Min = 0,
    Max = 1,
    Default = 0,
    Rounding = 2,
    Callback = function(value)
        ChamsSettings.OutlineTransparency = value
        UpdateChams()
    end
})
ChamsGroup:AddDropdown("ChamsDepthMode", {
    Text = "Depth Mode",
    Values = {"AlwaysOnTop", "Occluded"},
    Default = "AlwaysOnTop",
    Callback = function(value)
        ChamsSettings.DepthMode = Enum.HighlightDepthMode[value]
        UpdateChams()
    end
})
ChamsGroup:AddToggle("HighlightPlayers", {
    Text = "Highlight Specific Players",
    Default = false,
    Callback = function(state)
        HighlightSettings.Enabled = state
        UpdatePlayerHighlights()
        Library:Notify(state and "Player highlighting enabled." or "Player highlighting disabled.", 3)
    end
})
ChamsGroup:AddDropdown("HighlightedPlayers", {
    Text = "Highlighted Players",
    Values = GetPlayerList(),
    Multi = true,
    AllowNull = true, -- Allow no selection if no other players are present
    Callback = function(selected)
        HighlightSettings.HighlightedPlayers = {}
        for _, name in pairs(selected) do
            local player = Players:FindFirstChild(name)
            if player then
                HighlightSettings.HighlightedPlayers[player] = true
            end
        end
        UpdatePlayerHighlights()
    end
})
ChamsGroup:AddLabel("Highlight Fill Color"):AddColorPicker("HighlightFillColor", {
    Default = HighlightSettings.FillColor,
    Callback = function(color)
        HighlightSettings.FillColor = color
        UpdatePlayerHighlights()
    end
})
ChamsGroup:AddLabel("Highlight Outline Color"):AddColorPicker("HighlightOutlineColor", {
    Default = HighlightSettings.OutlineColor,
    Callback = function(color)
        HighlightSettings.OutlineColor = color
        UpdatePlayerHighlights()
    end
})
ChamsGroup:AddSlider("HighlightFillTransparency", {
    Text = "Highlight Fill Transparency",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Rounding = 2,
    Callback = function(value)
        HighlightSettings.FillTransparency = value
        UpdatePlayerHighlights()
    end
})
ChamsGroup:AddSlider("HighlightOutlineTransparency", {
    Text = "Highlight Outline Transparency",
    Min = 0,
    Max = 1,
    Default = 0,
    Rounding = 2,
    Callback = function(value)
        HighlightSettings.OutlineTransparency = value
        UpdatePlayerHighlights()
    end
})

-- Visual Effects
VisualEffectsGroup:AddToggle("XRay", {
    Text = "X-Ray Vision",
    Default = false,
    Callback = function(state)
        VisualEffects.XRay.Enabled = state
        ApplyXRay()
        Library:Notify(state and "X-Ray Vision enabled." or "X-Ray Vision disabled.", 3)
    end
})
VisualEffectsGroup:AddSlider("XRayTransparency", {
    Text = "X-Ray Transparency",
    Min = 0,
    Max = 1,
    Default = 0.7,
    Rounding = 2,
    Callback = function(value)
        VisualEffects.XRay.Transparency = value
        if VisualEffects.XRay.Enabled then ApplyXRay() end
    end
})
VisualEffectsGroup:AddToggle("CustomParticles", {
    Text = "Custom Particle Effects",
    Default = false,
    Callback = function(state)
        VisualEffects.Particles.Enabled = state
        ApplyCustomParticles()
        Library:Notify(state and "Custom particles enabled." or "Custom particles disabled.", 3)
    end
})
VisualEffectsGroup:AddLabel("Particle Color"):AddColorPicker("ParticleColor", {
    Default = VisualEffects.Particles.Color,
    Callback = function(color)
        VisualEffects.Particles.Color = color
        if VisualEffects.Particles.Enabled then ApplyCustomParticles() end
    end
})
VisualEffectsGroup:AddToggle("DynamicCrosshair", {
    Text = "Dynamic Crosshair",
    Default = false,
    Callback = function(state)
        VisualEffects.Crosshair.Enabled = state
        CreateCrosshair()
        Library:Notify(state and "Dynamic Crosshair enabled." or "Dynamic Crosshair disabled.", 3)
    end
})
VisualEffectsGroup:AddLabel("Crosshair Color"):AddColorPicker("CrosshairColor", {
    Default = VisualEffects.Crosshair.Color,
    Callback = function(color)
        VisualEffects.Crosshair.Color = color
        CreateCrosshair()
    end
})
VisualEffectsGroup:AddLabel("Crosshair Enemy Color"):AddColorPicker("CrosshairEnemyColor", {
    Default = VisualEffects.Crosshair.EnemyColor,
    Callback = function(color)
        VisualEffects.Crosshair.EnemyColor = color
    end
})
VisualEffectsGroup:AddSlider("CrosshairSize", {
    Text = "Crosshair Size",
    Min = 5,
    Max = 20,
    Default = 10,
    Rounding = 0,
    Callback = function(value)
        VisualEffects.Crosshair.Size = value
        CreateCrosshair()
    end
})
VisualEffectsGroup:AddSlider("CrosshairThickness", {
    Text = "Crosshair Thickness",
    Min = 1,
    Max = 5,
    Default = 2,
    Rounding = 0,
    Callback = function(value)
        VisualEffects.Crosshair.Thickness = value
        CreateCrosshair()
    end
})
VisualEffectsGroup:AddSlider("CrosshairTransparency", {
    Text = "Crosshair Transparency",
    Min = 0,
    Max = 1,
    Default = 1,
    Rounding = 2,
    Callback = function(value)
        VisualEffects.Crosshair.Transparency = value
        CreateCrosshair()
    end
})
VisualEffectsGroup:AddToggle("CrosshairRecoilAdjust", {
    Text = "Crosshair Recoil Adjustment",
    Default = false,
    Callback = function(state)
        VisualEffects.Crosshair.RecoilAdjust = state
    end
})

-- Update Loops
RunService.RenderStepped:Connect(function()
    -- Update Skeleton ESP
    for _, esp in pairs(ESPSettings.Skeleton.Elements) do
        local player = esp.Player
        if player.Character and player.Character.Parent then
            for _, lineData in ipairs(esp.Lines) do
                local part1, part2 = lineData.Part1, lineData.Part2
                local line = lineData.Line
                if part1.Parent and part2.Parent then
                    local pos1 = Camera:WorldToViewportPoint(part1.Position)
                    local pos2 = Camera:WorldToViewportPoint(part2.Position)
                    line.From = Vector2.new(pos1.X, pos1.Y)
                    line.To = Vector2.new(pos2.X, pos2.Y)
                    local distance = RootPart and (part1.Position - RootPart.Position).Magnitude or 0
                    if ESPConfig.FadeEnabled then
                        line.Transparency = math.clamp(ESPSettings.Skeleton.Transparency * (1 - (distance / ESPConfig.FadeDistance)), 0, 1)
                    end
                    line.Visible = pos1.Z > 0 and pos2.Z > 0
                else
                    line.Visible = false
                end
            end
        else
            for _, lineData in ipairs(esp.Lines) do
                lineData.Line.Visible = false
            end
        end
    end

    -- Update Box ESP
    for _, esp in pairs(ESPSettings.Box.Elements) do
        local player, root, head = esp.Player, esp.Root, esp.Head
        local box = esp.Box
        if player.Character and root.Parent and head.Parent then
            local rootPos, rootOnScreen = Camera:WorldToViewportPoint(root.Position)
            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
            local bottomPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            local width = (rootPos.X - (rootPos.X - 40)) * 2
            local height = (headPos.Y - bottomPos.Y)
            box.Size = Vector2.new(width, height)
            box.Position = Vector2.new(rootPos.X - width / 2, headPos.Y)
            local distance = RootPart and (root.Position - RootPart.Position).Magnitude or 0
            if ESPConfig.FadeEnabled then
                box.Transparency = math.clamp(ESPSettings.Box.Transparency * (1 - (distance / ESPConfig.FadeDistance)), 0, 1)
            end
            box.Visible = rootOnScreen
        else
            box.Visible = false
        end
    end

    -- Update Head Dots ESP
    for _, esp in pairs(ESPSettings.HeadDots.Elements) do
        local head, dot = esp.Head, esp.Dot
        if head.Parent then
            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            dot.Position = Vector2.new(headPos.X, headPos.Y)
            local distance = RootPart and (head.Position - RootPart.Position).Magnitude or 0
            if ESPConfig.FadeEnabled then
                dot.Transparency = math.clamp(ESPSettings.HeadDots.Transparency * (1 - (distance / ESPConfig.FadeDistance)), 0, 1)
            end
            dot.Visible = onScreen
        else
            dot.Visible = false
        end
    end

    -- Update Tracers ESP
    for _, esp in pairs(ESPSettings.Tracers.Elements) do
        local root, tracer = esp.Root, esp.Tracer
        if root.Parent then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            local distance = RootPart and (root.Position - RootPart.Position).Magnitude or 0
            if ESPConfig.FadeEnabled then
                tracer.Transparency = math.clamp(ESPSettings.Tracers.Transparency * (1 - (distance / ESPConfig.FadeDistance)), 0, 1)
            end
            tracer.Visible = onScreen
        else
            tracer.Visible = false
        end
    end

    -- Update Names ESP
    for _, esp in pairs(ESPSettings.Names.Elements) do
        local head, text = esp.Head, esp.Text
        if head.Parent then
            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
            text.Position = Vector2.new(headPos.X, headPos.Y)
            if ESPConfig.DistanceESPEnabled and RootPart then
                local distance = (head.Position - RootPart.Position).Magnitude
                text.Text = esp.Player.Name .. " [" .. math.floor(distance) .. "]"
            else
                text.Text = esp.Player.Name
            end
            local distance = RootPart and (head.Position - RootPart.Position).Magnitude or 0
            if ESPConfig.FadeEnabled then
                text.Transparency = math.clamp(ESPSettings.Names.Transparency * (1 - (distance / ESPConfig.FadeDistance)), 0, 1)
            end
            text.Visible = onScreen
        else
            text.Visible = false
        end
    end

    -- Update Health ESP
    for _, esp in pairs(ESPSettings.Health.Elements) do
        local head, bar, humanoid = esp.Head, esp.Bar, esp.Humanoid
        if head.Parent and humanoid.Parent then
            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            local barWidth = ESPSettings.Health.Size.X * healthPercent
            local offset = ESPSettings.Health.Offset
            local p1 = Vector2.new(headPos.X - ESPSettings.Health.Size.X / 2, headPos.Y + offset)
            local p2 = Vector2.new(headPos.X - ESPSettings.Health.Size.X / 2 + barWidth, headPos.Y + offset)
            local p3 = Vector2.new(headPos.X - ESPSettings.Health.Size.X / 2 + barWidth, headPos.Y + offset + ESPSettings.Health.Size.Y)
            local p4 = Vector2.new(headPos.X - ESPSettings.Health.Size.X / 2, headPos.Y + offset + ESPSettings.Health.Size.Y)
            bar.PointA = p1
            bar.PointB = p2
            bar.PointC = p3
            bar.PointD = p4
            bar.Color = ESPSettings.Health.Color:Lerp(Color3.fromRGB(255, 0, 0), 1 - healthPercent)
            local distance = RootPart and (head.Position - RootPart.Position).Magnitude or 0
            if ESPConfig.FadeEnabled then
                bar.Transparency = math.clamp(ESPSettings.Health.Transparency * (1 - (distance / ESPConfig.FadeDistance)), 0, 1)
            end
            bar.Visible = onScreen
        else
            bar.Visible = false
        end
    end

    -- Update Weapon ESP
    for _, esp in pairs(ESPSettings.Weapons.Elements) do
        local head, text, weapon = esp.Head, esp.Text, esp.Weapon
        if head.Parent then
            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position - Vector3.new(0, ESPSettings.Weapons.Offset, 0))
            local newWeapon = nil
            for _, tool in pairs(esp.Player.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    newWeapon = tool
                    break
                end
            end
            if newWeapon ~= weapon then
                esp.Weapon = newWeapon
                text.Text = newWeapon and newWeapon.Name or "None"
            end
            text.Position = Vector2.new(headPos.X, headPos.Y)
            local distance = RootPart and (head.Position - RootPart.Position).Magnitude or 0
            if ESPConfig.FadeEnabled then
                text.Transparency = math.clamp(ESPSettings.Weapons.Transparency * (1 - (distance / ESPConfig.FadeDistance)), 0, 1)
            end
            text.Visible = onScreen
        else
            text.Visible = false
        end
    end

    -- Update Environment ESP
    for _, esp in pairs(ESPSettings.Environment.Elements) do
        local obj, text = esp.Object, esp.Text
        if obj.Parent then
            local pos, onScreen = Camera:WorldToViewportPoint(obj.Position)
            text.Position = Vector2.new(pos.X, pos.Y)
            local distance = RootPart and (obj.Position - RootPart.Position).Magnitude or 0
            if ESPConfig.FadeEnabled then
                text.Transparency = math.clamp(ESPSettings.Environment.Transparency * (1 - (distance / ESPConfig.FadeDistance)), 0, 1)
            end
            text.Visible = onScreen
        else
            text.Visible = false
        end
    end

    -- Update Crosshair
    UpdateCrosshair()
end)

-- Player and Object Added/Removed Handlers
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if ESPSettings.Skeleton.Enabled then CreateSkeletonESP(player) end
        if ESPSettings.Box.Enabled then CreateBoxESP(player) end
        if ESPSettings.HeadDots.Enabled then CreateHeadDot(player) end
        if ESPSettings.Tracers.Enabled then CreateTracer(player) end
        if ESPSettings.Names.Enabled then CreateNameESP(player) end
        if ESPSettings.Health.Enabled then CreateHealthESP(player) end
        if ESPSettings.Weapons.Enabled then CreateWeaponESP(player) end
        if ChamsSettings.Enabled then CreateChams(player) end
        if HighlightSettings.Enabled and HighlightSettings.HighlightedPlayers[player] then CreatePlayerHighlight(player) end
    end)
end)

Workspace.DescendantAdded:Connect(function(descendant)
    if ESPSettings.Items.Enabled and descendant:IsA("BasePart") and (descendant.Name:lower():find("weapon") or descendant.Name:lower():find("collectible")) then
        CreateItemESP(descendant)
    end
    if ESPSettings.Environment.Enabled and descendant:IsA("BasePart") and table.find({"Door", "Vehicle", "Interactable"}, descendant.Name) then
        CreateEnvESP(descendant)
    end
end)

Workspace.DescendantRemoving:Connect(function(descendant)
    for i, esp in pairs(ESPSettings.Items.Elements) do
        if esp.Item == descendant then
            esp.Text:Remove()
            table.remove(ESPSettings.Items.Elements, i)
        end
    end
    for i, esp in pairs(ESPSettings.Environment.Elements) do
        if esp.Object == descendant then
            esp.Text:Remove()
            table.remove(ESPSettings.Environment.Elements, i)
        end
    end
end)

-- 6. UI Settings Tab
local UISettingsGroup = Tabs["UI Settings"]:AddLeftGroupbox("UI Settings")
UISettingsGroup:AddButton({
    Text = "Unload Script",
    Func = function()
        Library:Unload()
        Library:Notify("Script unloaded.", 3)
    end
})
UISettingsGroup:AddLabel("Menu toggle"):AddKeybind("MenuToggle", {
    Default = Enum.KeyCode.RightShift,
    Callback = function()
        Library:Toggle()
    end
})

-- Initialize SaveManager and ThemeManager
SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder("TownHMenu")
SaveManager:SetFolder("TownHMenu/town")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

-- Initial Setup
UpdateESP()
UpdateItemESP()
UpdateEnvESP()
UpdateChams()
UpdatePlayerHighlights()
ApplyCustomSkybox()
ApplyCustomParticles()

-- Cleanup on Script End
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    Library:SaveConfig(SaveManager:GetAutoloadConfig())
end)

Library:Notify("loaded successfully!", 5)
