--[[
	Fry-A-Falafel · Storage room "Clean Back-of-House"
	Builds the wall elements and applies their materials.

	HOW TO RUN (Roblox Studio):
	  1. (Optional) Select the storage room's floor part (45 x 52.5).
	     The walls are built around it, with the back wall on the floor's -Z side
	     (change YAW below if the back wall is on a different side).
	     If nothing is selected, the room is built at ORIGIN.
	  2. View > Command Bar, paste this whole file, press Enter.
	  3. Ctrl+Z undoes the whole build. Running it again replaces the old build.

	Room coordinates used below: X = left->right, Y = up, Z = back wall -> front.
	The back wall's inside face is Z = 0; the floor top is Y = 0.
]]

local CONFIG = {
	ROOM_W = 45,
	ROOM_D = 52.5,
	WALL_H = 14,
	WALL_T = 1,
	YAW = 0, -- degrees; rotate if the back wall should face another side of the floor
	ORIGIN = CFrame.new(0, 0, 0), -- floor centre (top surface) when nothing is selected
	RECOLOR_SELECTED_FLOOR = true, -- apply the epoxy floor material to the selected floor
	BUILD_RIGHT_WALL = true, -- kitchen partition with door 7 + crate slots
}

-- Palette (matches the design sheet) --------------------------------------
local M = Enum.Material
local MAT = {
	Wall      = { Color3.fromHex("F4F1EA"), M.SmoothPlastic }, -- warm-white FRP panels
	Floor     = { Color3.fromHex("CFC9BD"), M.Granite },       -- speckled epoxy
	Steel     = { Color3.fromHex("B9C2C8"), M.Metal },         -- stainless kick band 0-2.5
	Teal      = { Color3.fromHex("2F6F6A"), M.SmoothPlastic }, -- stripe = kitchen tile
	Chrome    = { Color3.fromHex("D7DDE2"), M.Metal },         -- wire shelves / frames
	Post      = { Color3.fromHex("5C6670"), M.Metal },         -- posts, door hood, top trim
	RollDoor  = { Color3.fromHex("3E6E9C"), M.CorrugatedMetal }, -- roll-up door (hero)
	Ice       = { Color3.fromHex("BFE3F2"), M.SmoothPlastic }, -- cold zone
	IceGlass  = { Color3.fromHex("BFE3F2"), M.Glass },
	CoolWhite = { Color3.fromHex("F7FAFB"), M.SmoothPlastic }, -- walk-in cooler panels
	Yellow    = { Color3.fromHex("F2C230"), M.SmoothPlastic }, -- safety yellow (floor/guards)
	Black     = { Color3.fromHex("2B2B2B"), M.SmoothPlastic },
	Screen    = { Color3.fromHex("5FE8C4"), M.Neon },
	GreenLamp = { Color3.fromHex("2ECC71"), M.Neon },
}

-- Setup -------------------------------------------------------------------
local CHS = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local W, D, H, T = CONFIG.ROOM_W, CONFIG.ROOM_D, CONFIG.WALL_H, CONFIG.WALL_T

local center = CONFIG.ORIGIN
local floor = Selection:Get()[1]
if floor and floor:IsA("BasePart") then
	center = floor.CFrame * CFrame.new(0, floor.Size.Y / 2, 0)
else
	floor = nil
end
local origin = center * CFrame.Angles(0, math.rad(CONFIG.YAW), 0) * CFrame.new(-W / 2, 0, -D / 2)

local recording = CHS:TryBeginRecording("Build storage walls")

local old = workspace:FindFirstChild("Storage_Walls")
if old then
	old:Destroy()
end

local root = Instance.new("Model")
root.Name = "Storage_Walls"

local function folder(name, parent)
	local f = Instance.new("Model")
	f.Name = name
	f.Parent = parent or root
	return f
end

-- Axis-aligned box between two corners in room coordinates.
local function box(parent, name, style, x0, y0, z0, x1, y1, z1, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = style[1]
	p.Material = style[2]
	p.Reflectance = 0
	if props then
		for k, v in pairs(props) do
			p[k] = v
		end
	end
	p.Size = Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0))
	p.CFrame = origin * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	p.Parent = parent
	return p
end

local function label(part, face, text, color)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.TextColor3 = color
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.15, 0)
	pad.PaddingBottom = UDim.new(0.15, 0)
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingRight = UDim.new(0.05, 0)
	pad.Parent = t
	t.Parent = g
	g.Parent = part
	return g
end

-- Each wall maps (a = along the wall, y = height, d = depth into the room
-- from the wall's inside face; negative = inside the wall) to room coords.
local WALLS = {
	back = {
		len = W,
		face = Enum.NormalId.Back, -- +Z faces into the room
		map = function(a0, a1, y0, y1, d0, d1) return a0, y0, d0, a1, y1, d1 end,
	},
	front = {
		len = W,
		face = Enum.NormalId.Front,
		map = function(a0, a1, y0, y1, d0, d1) return a0, y0, D - d0, a1, y1, D - d1 end,
	},
	left = {
		len = D,
		face = Enum.NormalId.Right,
		map = function(a0, a1, y0, y1, d0, d1) return d0, y0, a0, d1, y1, a1 end,
	},
	right = {
		len = D,
		face = Enum.NormalId.Left,
		map = function(a0, a1, y0, y1, d0, d1) return W - d0, y0, a0, W - d1, y1, a1 end,
	},
}

local function wbox(parent, wall, name, style, a0, a1, y0, y1, d0, d1, props)
	local x0, yy0, z0, x1, yy1, z1 = wall.map(a0, a1, y0, y1, d0, d1)
	return box(parent, name, style, x0, yy0, z0, x1, yy1, z1, props)
end

-- Wall panels with rectangular openings {a0, a1, y0, y1} (sorted, non-overlapping).
local function panels(parent, wall, openings)
	local a = 0
	for i, o in ipairs(openings) do
		if o[1] > a then
			wbox(parent, wall, "Panel", MAT.Wall, a, o[1], 0, H, -T, 0)
		end
		if o[3] > 0 then
			wbox(parent, wall, "PanelBelow" .. i, MAT.Wall, o[1], o[2], 0, o[3], -T, 0)
		end
		if o[4] < H then
			wbox(parent, wall, "PanelAbove" .. i, MAT.Wall, o[1], o[2], o[4], H, -T, 0)
		end
		a = o[2]
	end
	if a < wall.len then
		wbox(parent, wall, "Panel", MAT.Wall, a, wall.len, 0, H, -T, 0)
	end
end

-- Steel kick band (0-2.5), teal stripe (2.5-3) and top trim, over spans {a0, a1}.
local function trim(parent, wall, spans)
	for _, s in ipairs(spans) do
		wbox(parent, wall, "KickBand_Steel", MAT.Steel, s[1], s[2], 0, 2.5, 0, 0.15)
		wbox(parent, wall, "Stripe_Teal", MAT.Teal, s[1], s[2], 2.5, 3, 0, 0.12)
	end
	wbox(parent, wall, "TopTrim", MAT.Post, 0, wall.len, H - 0.4, H, 0, 0.3)
end

-- Yellow/black guard post (door jambs, slot edges).
local function guard(parent, wall, a0, a1, height)
	local g = folder("SafetyGuard", parent)
	for i = 0, math.ceil(height) - 1 do
		local style = (i % 2 == 0) and MAT.Yellow or MAT.Black
		wbox(g, wall, "Band" .. i, style, a0, a1, i, math.min(i + 1, height), 0, 0.8)
	end
	return g
end

-- BACK WALL ---------------------------------------------------------------
local DOOR_A0, DOOR_A1, DOOR_H = 17, 29, 10 -- roll-up door 12 x 10
local COOLER_A1, COOLER_D, COOLER_H = 12.5, 15, 10

do
	local wall = WALLS.back
	local back = folder("BackWall")

	panels(back, wall, { { DOOR_A0, DOOR_A1, 0, DOOR_H } })
	trim(back, wall, { { COOLER_A1, DOOR_A0 - 0.8 }, { DOOR_A1 + 0.8, W } })

	-- Roll-up door 12 (hero)
	local door = folder("RollUpDoor12", back)
	wbox(door, wall, "Curtain", MAT.RollDoor, DOOR_A0, DOOR_A1, 0.4, DOOR_H, -0.6, -0.4)
	wbox(door, wall, "BottomBar", MAT.Post, DOOR_A0, DOOR_A1, 0, 0.4, -0.65, -0.35)
	wbox(door, wall, "Hood", MAT.Post, DOOR_A0 - 0.8, DOOR_A1 + 0.8, DOOR_H, DOOR_H + 1.4, 0, 1.2)
	guard(door, wall, DOOR_A0 - 0.8, DOOR_A0, DOOR_H)
	guard(door, wall, DOOR_A1, DOOR_A1 + 0.8, DOOR_H)

	local sign = wbox(door, wall, "Sign_Receiving", MAT.Teal, 19, 27, 11.7, 13.3, 0, 0.2)
	label(sign, wall.face, "RECEIVING", Color3.new(1, 1, 1))

	-- "Truck here" lamp
	local lamp = folder("TruckLamp", back)
	wbox(lamp, wall, "Lamp", MAT.GreenLamp, 30.5, 31.1, 6.7, 7.3, 0, 0.6)
	local plate = wbox(lamp, wall, "Label", MAT.Wall, 31.3, 34.5, 6.5, 7.5, 0, 0.1)
	label(plate, wall.face, "TRUCK HERE", MAT.Black[1])

	-- Order tablet
	local tab = folder("OrderTablet", back)
	wbox(tab, wall, "Bezel", MAT.Black, 35, 38.5, 4.5, 7, 0, 0.25)
	local screen = wbox(tab, wall, "Screen", MAT.Screen, 35.25, 38.25, 4.75, 6.75, 0.25, 0.3)
	label(screen, wall.face, "ORDERS", MAT.Teal[1])
end

-- WALK-IN COOLER (against the back-left corner) -----------------------------
do
	local cooler = folder("WalkInCooler")
	local x1, z1, h = COOLER_A1, COOLER_D, COOLER_H
	local DA0, DA1, DH = 4.5, 9, 8 -- doorway on the front face
	local t = 0.5

	-- Right side and roof
	box(cooler, "SideWall", MAT.CoolWhite, x1 - t, 0, 0, x1, h, z1)
	box(cooler, "Roof", MAT.CoolWhite, 0, h - t, 0, x1, h, z1)
	-- Front face with doorway
	box(cooler, "FrontLeft", MAT.CoolWhite, 0, 0, z1 - t, DA0, h - t, z1)
	box(cooler, "FrontRight", MAT.CoolWhite, DA1, 0, z1 - t, x1 - t, h - t, z1)
	box(cooler, "FrontAbove", MAT.CoolWhite, DA0, DH, z1 - t, DA1, h - t, z1)

	-- Ice-blue frame (= cold zone)
	box(cooler, "Frame_Top", MAT.Ice, 0, h - 0.4, z1, x1, h, z1 + 0.15)
	box(cooler, "Frame_Corner", MAT.Ice, x1 - 0.4, 0, z1, x1, h, z1 + 0.15)
	box(cooler, "Door_FrameL", MAT.Ice, DA0 - 0.3, 0, z1, DA0, DH, z1 + 0.2)
	box(cooler, "Door_FrameR", MAT.Ice, DA1, 0, z1, DA1 + 0.3, DH, z1 + 0.2)
	box(cooler, "Door_FrameTop", MAT.Ice, DA0 - 0.3, DH, z1, DA1 + 0.3, DH + 0.3, z1 + 0.2)

	-- Walk-through PVC strip curtain
	local strips = folder("StripCurtain", cooler)
	local n = 6
	local w = (DA1 - DA0) / n
	for i = 0, n - 1 do
		box(strips, "Strip" .. i, MAT.IceGlass,
			DA0 + i * w + 0.05, 0.2, z1 - 0.3,
			DA0 + (i + 1) * w - 0.05, DH, z1 - 0.2,
			{ Transparency = 0.45, CanCollide = false, CastShadow = false })
	end

	-- Frosted window and COLD sign
	box(cooler, "Window", MAT.IceGlass, 9.8, 4.5, z1, 11.8, 6.5, z1 + 0.1, { Transparency = 0.25 })
	local sign = box(cooler, "Sign_Cold", MAT.Ice, 5, 8.6, z1 + 0.2, 8.5, 9.5, z1 + 0.3)
	label(sign, Enum.NormalId.Back, "❄ COLD", MAT.Teal[1])

	-- Steel kick band + teal stripe continue around the cooler
	box(cooler, "KickBand_Front", MAT.Steel, 0, 0, z1, DA0 - 0.3, 2.5, z1 + 0.15)
	box(cooler, "KickBand_Front2", MAT.Steel, DA1 + 0.3, 0, z1, x1 - 0.4, 2.5, z1 + 0.15)
	box(cooler, "Stripe_Front", MAT.Teal, 0, 2.5, z1, DA0 - 0.3, 3, z1 + 0.12)
	box(cooler, "Stripe_Front2", MAT.Teal, DA1 + 0.3, 2.5, z1, x1 - 0.4, 3, z1 + 0.12)
	box(cooler, "KickBand_Side", MAT.Steel, x1, 0, 0, x1 + 0.15, 2.5, z1)
	box(cooler, "Stripe_Side", MAT.Teal, x1, 2.5, 0, x1 + 0.12, 3, z1)
end

-- LEFT & FRONT WALLS --------------------------------------------------------
do
	local left = folder("LeftWall")
	panels(left, WALLS.left, {})
	trim(left, WALLS.left, { { COOLER_D, D } })

	local front = folder("FrontWall")
	panels(front, WALLS.front, {})
	trim(front, WALLS.front, { { 0, W } })

	-- Fill the outside corners where the walls meet
	box(left, "Corner_BackLeft", MAT.Wall, -T, 0, -T, 0, H, 0)
	box(front, "Corner_FrontLeft", MAT.Wall, -T, 0, D, 0, H, D + T)
	box(front, "Corner_FrontRight", MAT.Wall, W, 0, D, W + T, H, D + T)
	box(left, "Corner_BackRight", MAT.Wall, W, 0, -T, W + T, H, 0)
end

-- RIGHT WALL = kitchen partition (door 7 + crate slots) ---------------------
if CONFIG.BUILD_RIGHT_WALL then
	local wall = WALLS.right
	local right = folder("RightWall_KitchenPartition")
	local DOOR7 = { 3, 10, 0, 9 }
	local SLOTS = { -- crate pass-through slots, one per main shelf
		{ 16.5, 20.5, "FALAFEL" },
		{ 25, 29, "BREAD" },
		{ 33.5, 37.5, "SALAD" },
		{ 41.8, 45.8, "TAHINI" },
	}
	local SLOT_Y0, SLOT_Y1 = 3, 6.5

	local openings = { DOOR7 }
	for _, s in ipairs(SLOTS) do
		table.insert(openings, { s[1], s[2], SLOT_Y0, SLOT_Y1 })
	end
	panels(right, wall, openings)
	trim(right, wall, { { 0, DOOR7[1] - 0.8 }, { DOOR7[2] + 0.8, D } })

	guard(right, wall, DOOR7[1] - 0.8, DOOR7[1], DOOR7[4])
	guard(right, wall, DOOR7[2], DOOR7[2] + 0.8, DOOR7[4])
	local sign = wbox(right, wall, "Sign_Kitchen", MAT.Teal, 4, 9, 9.6, 10.8, 0, 0.2)
	label(sign, wall.face, "KITCHEN →", Color3.new(1, 1, 1))

	for _, s in ipairs(SLOTS) do
		local f = folder("CrateSlot_" .. s[3], right)
		wbox(f, wall, "Sill", MAT.Chrome, s[1] - 0.2, s[2] + 0.2, SLOT_Y0 - 0.2, SLOT_Y0, -T, 0.4)
		wbox(f, wall, "Lintel", MAT.Chrome, s[1] - 0.2, s[2] + 0.2, SLOT_Y1, SLOT_Y1 + 0.2, 0, 0.2)
		wbox(f, wall, "JambL", MAT.Chrome, s[1] - 0.2, s[1], SLOT_Y0, SLOT_Y1, 0, 0.2)
		wbox(f, wall, "JambR", MAT.Chrome, s[2], s[2] + 0.2, SLOT_Y0, SLOT_Y1, 0, 0.2)
		local tag = wbox(f, wall, "Label", MAT.Wall, s[1], s[2], SLOT_Y1 + 0.4, SLOT_Y1 + 1.3, 0, 0.1)
		label(tag, wall.face, s[3], MAT.Black[1])
	end
end

-- FLOOR MARKINGS (safety yellow = floor only) -------------------------------
do
	local marks = folder("FloorMarkings")
	local th = 0.05
	local NC = { CanCollide = false, CanQuery = false, CastShadow = false }

	-- Receiving zone border
	local RX0, RX1, RZ1, bw = 14, 31, 12.5, 0.4
	box(marks, "Receiving_L", MAT.Yellow, RX0, 0, 0, RX0 + bw, th, RZ1, NC)
	box(marks, "Receiving_R", MAT.Yellow, RX1 - bw, 0, 0, RX1, th, RZ1, NC)
	box(marks, "Receiving_B", MAT.Yellow, RX0, 0, RZ1 - bw, RX1, th, RZ1, NC)

	-- Yellow/black threshold under the roll-up door
	local n = 12
	local w = (DOOR_A1 - DOOR_A0) / n
	for i = 0, n - 1 do
		local style = (i % 2 == 0) and MAT.Yellow or MAT.Black
		box(marks, "Threshold" .. i, style, DOOR_A0 + i * w, 0, 0, DOOR_A0 + (i + 1) * w, th, 0.8, NC)
	end

	-- Dashed walk lane: receiving -> shelves
	local z = RZ1 + 0.5
	local i = 0
	while z + 1.5 <= D - 4 do
		box(marks, "Lane" .. i, MAT.Yellow, 27, 0, z, 27.4, th, z + 1.5, NC)
		z += 2.5
		i += 1
	end
end

root.Parent = workspace

if floor and CONFIG.RECOLOR_SELECTED_FLOOR then
	floor.Color = MAT.Floor[1]
	floor.Material = MAT.Floor[2]
	floor.Reflectance = 0
end

if recording then
	CHS:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end

local parts = 0
for _, d in ipairs(root:GetDescendants()) do
	if d:IsA("BasePart") then
		parts += 1
	end
end
print(("Storage_Walls built: %d parts%s"):format(parts, floor and (" around " .. floor:GetFullName()) or " at ORIGIN"))
if floor and math.abs(floor.Size.X - W) + math.abs(floor.Size.Z - D) > 0.5
	and math.abs(floor.Size.Z - W) + math.abs(floor.Size.X - D) > 0.5 then
	warn(("Selected floor is %.1f x %.1f, layout expects %g x %g"):format(floor.Size.X, floor.Size.Z, W, D))
end
