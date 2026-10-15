-- PartKit: small helpers for building anchored parts, used by WorldBuilder and BuildingModels.

local PartKit = {}

function PartKit.folder(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function PartKit.newPart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Axis-aligned box from min/max coordinates (either order). Easier to keep seamless
-- than centre + size, because neighbouring parts can share exact edge values.
function PartKit.box(parent, name, x0, x1, y0, y1, z0, z1, color, material)
	local size = Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0))
	local center = Vector3.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	return PartKit.newPart(parent, name, size, CFrame.new(center), color, material)
end

function PartKit.ball(parent, name, x, y, z, diameter, color, material)
	local part = PartKit.newPart(parent, name, Vector3.new(diameter, diameter, diameter), CFrame.new(x, y, z), color, material or Enum.Material.Neon)
	part.Shape = Enum.PartType.Ball
	return part
end

-- Flat round platform with a vertical axis spanning y = bottom..top (bottom defaults to -0.1,
-- i.e. buried slightly in the ground).
function PartKit.disc(parent, name, cx, cz, diameter, top, color, material, bottom)
	bottom = bottom or -0.1
	local height = top - bottom
	local part = PartKit.newPart(
		parent,
		name,
		Vector3.new(height, diameter, diameter),
		CFrame.new(cx, bottom + height / 2, cz) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material
	)
	part.Shape = Enum.PartType.Cylinder
	return part
end

function PartKit.glow(part, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = part
end

-- Floating text above a part. The two TextLabels are named "Title" and "Subtitle"
-- so they can be updated later (e.g. plot owner names).
function PartKit.label(adornee, title, subtitle, offsetY, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(300, subtitle and 54 or 30)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = 140
	gui.LightInfluence = 0
	gui.Parent = adornee

	local top = Instance.new("TextLabel")
	top.Name = "Title"
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, 0, 0, 28)
	top.Font = Enum.Font.GothamBold
	top.TextSize = 20
	top.Text = title
	top.TextColor3 = color or Color3.new(1, 1, 1)
	top.TextStrokeTransparency = 0.35
	top.Parent = gui

	if subtitle then
		local bottom = Instance.new("TextLabel")
		bottom.Name = "Subtitle"
		bottom.BackgroundTransparency = 1
		bottom.Position = UDim2.fromOffset(0, 28)
		bottom.Size = UDim2.new(1, 0, 0, 22)
		bottom.Font = Enum.Font.Gotham
		bottom.TextSize = 14
		bottom.Text = subtitle
		bottom.TextColor3 = Color3.fromRGB(220, 232, 245)
		bottom.TextStrokeTransparency = 0.45
		bottom.Parent = gui
	end
	return gui
end

return PartKit
