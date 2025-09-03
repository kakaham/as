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

local bg = Instance.new("ImageLabel")
bg.Size = UDim2.new(1,0,1,0)
bg.Position = UDim2.new(0,0,0,0)
bg.BackgroundTransparency = 1
bg.Image = "93418379039111"
bg.ScaleType = Enum.ScaleType.Crop
bg.Parent = frame

local mask = Instance.new("Frame")
mask.Size = UDim2.new(1,0,1,0)
mask.Position = UDim2.new(0,0,0,0)
mask.BackgroundColor3 = Color3.fromRGB(0,0,0)
mask.BackgroundTransparency = 0.25
mask.BorderSizePixel = 0
mask.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 20, 0, 10)
title.BackgroundTransparency = 1
title.Text = "By: Eligant"
title.TextColor3 = Color3.fromRGB(240,200,255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 100)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.AutoButtonColor = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,6)
corner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	frame:Destroy()
end)

closeBtn.Parent = frame

local function makeDraggable(f, handle)
	handle = handle or f
	local UIS = game:GetService("UserInputService")
	local dragging, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		f.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = f.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
			update(input)
		end
	end)
end

makeDraggable(frame, title)

local function createButton(text, color, pos, link)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 140, 0, 40)
	btn.Position = pos
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.BackgroundColor3 = color
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,8)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(link)
		end
		error("Link copied")
	end)

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local goal = {BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.2)}
	local tween = TweenService:Create(btn, tweenInfo, goal)
	tween:Play()
end

createButton("Youtube", Color3.fromRGB(180,30,50), UDim2.new(0, 40, 0, 100), "https://www.youtube.com/@MixalamsLams")
createButton("Discord", Color3.fromRGB(50,30,180), UDim2.new(0, 200, 0, 100), "https://discord.com/channels/@me/1288262049151057941")

local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local goal = {BackgroundColor3 = Color3.fromRGB(255,80,150)}
local tween = TweenService:Create(closeBtn, tweenInfo, goal)
tween:Play()


game.StarterGui:SetCore("SendNotification",{Title="Notification",Text="Enjoy using the animation script by Eligant",Icon="rbxassetid://7072718364",Duration=5});local v0=Instance.new("ScreenGui");local v1=Instance.new("Frame");local v2=Instance.new("UICorner");local v3=Instance.new("UIStroke");local v4=Instance.new("TextLabel");local v5=Instance.new("ImageLabel");v0.Name="LoadingGUI";v0.Parent=game.Players.LocalPlayer:WaitForChild("PlayerGui");v0.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;v1.Name="loadingFrame";v1.Parent=v0;v1.AnchorPoint=Vector2.new(0.5,0.5);v1.BackgroundColor3=Color3.fromRGB(25,25,25);v1.Position=UDim2.new(0.5,0,0.5,0);v1.Size=UDim2.new(0,200,0,200);v2.CornerRadius=UDim.new(0,25);v2.Parent=v1;v3.Parent=v1;v3.Color=Color3.fromRGB(255,255,255);v3.Thickness=2;v5.Name="loadingCircle";v5.Parent=v1;v5.AnchorPoint=Vector2.new(0.5,0.5);v5.Position=UDim2.new(0.5,0,0.4,0);v5.Size=UDim2.new(0,70,0,70);v5.Image="rbxassetid://133898459740182";v5.BackgroundTransparency=1;v4.Name="loadingText";v4.Parent=v1;v4.AnchorPoint=Vector2.new(0.5,1);v4.Position=UDim2.new(0.5,0,1, -10);v4.Size=UDim2.new(1,0,0,30);v4.Text="Wait a minute";v4.TextColor3=Color3.fromRGB(255,255,255);v4.BackgroundTransparency=1;v4.TextScaled=true;v4.Font=Enum.Font.Gotham;local v39=game:GetService("TweenService");local v40=true;coroutine.wrap(function() while v40 do local v42=v39:Create(v5,TweenInfo.new(1,Enum.EasingStyle.Linear),{Rotation=v5.Rotation + 360 });v42:Play();v42.Completed:Wait();end end)();wait(3);v40=false;local v41=v39:Create(v1,TweenInfo.new(1,Enum.EasingStyle.Sine),{Size=UDim2.new(0,0,0,0),Rotation=720,Position=UDim2.new(0.5,0,0.5,0),BackgroundTransparency=1});v41:Play();v41.Completed:Wait();v0:Destroy();loadstring(game:HttpGet("https://raw.githubusercontent.com/alifSTARZ/Animation-by-Alip-/refs/heads/main/Xploit%20force"))();
