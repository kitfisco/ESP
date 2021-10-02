local ESP = {
    Enabled = true,
    BoxShift = CFrame.new(0,-1.5,0),
    BoxSize = Vector3.new(4,6,0),
    Color = Color3.fromRGB(255, 170, 0),
    Thickness = 2,
    AttachShift = 1,    
    Objects = setmetatable({}, {__mode="kv"}),
}

local Camera = workspace.CurrentCamera
local WorldToViewportPoint = Camera.WorldToViewportPoint

local RunService= game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function Draw(obj, props)
	local new = Drawing.new(obj)
	for i,v in pairs(props) do
		new[i] = v
	end
	return new
end

function ESP:Toggle(bool)
    ESP.Enabled = bool
    if not bool then
        for _,v in pairs(self.Objects) do
            if v.Type == "Box" then --fov circle etc
                for _,vv in pairs(v.Components) do
                    vv.Visible = false
                end
            end
        end
    end
end

function ESP:GetBox(obj)
    return self.Objects[obj]
end

local boxBase = {}
boxBase.__index = boxBase

function boxBase:Remove()
    ESP.Objects[self.Object] = nil
    for i,v in pairs(self.Components) do
        v.Visible = false
        v:Remove()
        self.Components[i] = nil
    end
end

function boxBase:Update()
    local color = self.Color or ESP.Color
    local cf = self.PrimaryPart.CFrame
    local locsTagPos = cf * ESP.BoxShift * CFrame.new(0,self.Size.Y/2,0)

    local TagPos, Vis5 = WorldToViewportPoint(Camera, locsTagPos.Position)
        
    if Vis5 then
        self.Components.Name.Visible = true
        self.Components.Name.Position = Vector2.new(TagPos.X, TagPos.Y)
        self.Components.Name.Text = self.Name
        self.Components.Name.Color = color
        
        self.Components.Distance.Visible = true
        self.Components.Distance.Position = Vector2.new(TagPos.X, TagPos.Y + 14)
        self.Components.Distance.Text = string.format("[%s][%s][%s]", math.floor((Camera.CFrame.Position - cf.Position).Magnitude), math.floor(self.Extra.Health.Value).."/"..math.floor(self.Extra.Health:IsA("NumberValue") and self.Extra.Health.Max.Value or self.Extra.Health.MaxValue), self.Extra.BP.Value)
        self.Components.Distance.Color = Color3.fromRGB(255,255,255)
    else
        self.Components.Name.Visible = false
        self.Components.Distance.Visible = false
    end
end

function ESP:Add(obj, options)
    if obj.Parent == nil then return end

    local foundCharacter = obj.Parent == workspace and Players:FindFirstChild(obj.Name)
    local box = setmetatable({
        Name = obj.Name,
        Type = "Box",
        Object = obj,
        Extra = options.Extra,
        Color = options.Color or ESP.Color,
        Size = options.Size or self.BoxSize,
        Player = options.Player or foundCharacter,
        PrimaryPart = options.PrimaryPart or obj:FindFirstChild("HumanoidRootPart"),
		Components = {},
    }, boxBase)

    if self:GetBox(obj) then
        self:GetBox(obj):Remove()
    end

    box.Components["Name"] = Draw("Text", {
		Text = box.Name,
		Color = box.Color,
		Center = true,
		Outline = true,
        Size = 19,
        Visible = self.Enabled
	})
	box.Components["Distance"] = Draw("Text", {
		Color = box.Color,
		Center = true,
		Outline = true,
        Size = 19,
        Visible = self.Enabled
	})

    self.Objects[obj] = box
    
    obj.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            box:Remove()
        end
    end)
    obj:GetPropertyChangedSignal("Parent"):Connect(function()
        if obj.Parent == nil then
            box:Remove()
        end
    end)
    return box
end

do
    local function BPAdded(battlepower)
        if battlepower:IsA("IntValue") and battlepower.Name == "BattlePower" then
            local character = battlepower.Parent.Parent
            local health = character:WaitForChild("Health", 20)
            local root = health and character:WaitForChild("HumanoidRootPart", 20)
            if root and character ~= LocalPlayer.Character then
                ESP:Add(character, {
                    Name = character.Name,
                    Player = character,
                    PrimaryPart = root,
                    Extra = {
                        BP = battlepower,
                        Health = health
                    }
                })
            else
                print(character, health, root)
            end
        end
    end

    workspace.DescendantAdded:Connect(BPAdded)
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("IntValue") and v.Name == "BattlePower" then
            task.spawn(BPAdded, v)
        end
    end
end

RunService.RenderStepped:Connect(function()
    for _,v in (ESP.Enabled and pairs or ipairs)(ESP.Objects) do
        if v.Update then
            local s,e = pcall(v.Update, v)
            if not s then warn("[EU]", e, v.Object:GetFullName()) end
        end
    end
end)
