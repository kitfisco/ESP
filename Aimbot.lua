local Settings = {
	AimPart = "Head",
	AimToggleKey = "Y",
	TeamCheck = false
}
local Services = setmetatable({},{__index=function(a,b)local c=game:GetService(b)if c then a[b]=c end;return c end})
local LPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local mouse = LPlayer:GetMouse()
local function getNearestPlayerFromMouse()
	local Closest = {math.huge, nil}
	local MousePos = Vector2.new(mouse.X, mouse.Y)
	for _,v in pairs(Services.Players:GetPlayers()) do
		if v ~= LPlayer and v.Team ~= LPlayer.Team and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
			local vector, onScreen = Camera:WorldToScreenPoint(v.Character.HumanoidRootPart.Position)
			if onScreen then
				local distance = (MousePos - Vector2.new(vector.X, vector.Y)).Magnitude
				if distance < Closest[1] then
					Closest = {distance, v}
				end
			end
		end
	end
	return Closest[2]
end
local Aimlock, MousePressed = true, nil
Services.UserInputService.InputBegan:Connect(function(input)
	if not Services.UserInputService:GetFocusedTextBox() then
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			MousePressed = true
		elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode[Settings.AimToggleKey] then
			Aimlock = not Aimlock
		end
	end
end)
Services.UserInputService.InputEnded:Connect(function(input)
    if not Services.UserInputService:GetFocusedTextBox() and input.UserInputType == Enum.UserInputType.MouseButton2 then
        MousePressed = false
    end
end)
Services.RunService.RenderStepped:Connect(function()
    if Aimlock == true and MousePressed == true then
        local target = getNearestPlayerFromMouse()
        if target ~= nil then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character[Settings.AimPart].Position)
        end
    end
end)
