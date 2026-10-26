-- The Sea Turtle's shape and colors, measured from cross-sections of
-- assets/source/SeaTurtle_source.blend (shell layers, belly, head, eyes,
-- flippers, tail) and its texture's colors.
-- Units: model units, ModelLength long from head to tail; X right, Y up,
-- head toward -Z; origin at the shell's center.
return {
	ModelLength = 1.95,
	Colors = {
		Shell = Color3.fromRGB(59, 65, 26),
		Skin = Color3.fromRGB(80, 83, 41),
		Belly = Color3.fromRGB(201, 248, 220),
		Eye = Color3.fromRGB(12, 17, 3),
	},
	Parts = {
		-- Domed shell, bottom layer to top.
		{ Name = "ShellBase", Color = "Shell", Center = Vector3.new(0, -0.005, 0), Size = Vector3.new(1.10, 0.20, 1.20) },
		{ Name = "ShellLayer2", Color = "Shell", Center = Vector3.new(0, 0.145, -0.0125), Size = Vector3.new(0.91, 0.10, 1.175) },
		{ Name = "ShellLayer3", Color = "Shell", Center = Vector3.new(0, 0.22, 0), Size = Vector3.new(0.76, 0.05, 1.10) },
		{ Name = "ShellLayer4", Color = "Shell", Center = Vector3.new(0, 0.27, -0.05), Size = Vector3.new(0.66, 0.05, 0.80) },
		{ Name = "ShellTop", Color = "Shell", Center = Vector3.new(0, 0.32, -0.05), Size = Vector3.new(0.49, 0.05, 0.50) },
		{ Name = "Belly", Color = "Belly", Center = Vector3.new(0, -0.23, 0), Size = Vector3.new(1.0, 0.25, 1.10) },
		{ Name = "Neck", Color = "Skin", Center = Vector3.new(0, -0.055, -0.70), Size = Vector3.new(0.35, 0.30, 0.20) },
		{ Name = "Head", Color = "Skin", Center = Vector3.new(0, -0.03, -0.925), Size = Vector3.new(0.40, 0.45, 0.25) },
		{ Name = "LeftEye", Color = "Eye", Center = Vector3.new(-0.21, -0.005, -0.915), Size = Vector3.new(0.03, 0.10, 0.14) },
		{ Name = "RightEye", Color = "Eye", Center = Vector3.new(0.21, -0.005, -0.915), Size = Vector3.new(0.03, 0.10, 0.14) },
		-- Wedge turned 180° so it tapers to a point toward the back.
		{ Name = "Tail", Color = "Skin", Wedge = true, Yaw = 180, Center = Vector3.new(0, -0.18, 0.735), Size = Vector3.new(0.10, 0.12, 0.32) },
	},
	-- Round paddle flippers, hinged at the shell's side edge (JointX).
	JointX = 0.53,
	FlipperThickness = 0.08,
	FlipperDroopDegrees = 15,
	Flippers = {
		{ Name = "FrontLeftFlipper", Side = -1, Front = true, Center = Vector3.new(-0.765, -0.255, -0.35), Diameter = 0.45 },
		{ Name = "FrontRightFlipper", Side = 1, Front = true, Center = Vector3.new(0.765, -0.255, -0.35), Diameter = 0.45 },
		{ Name = "BackLeftFlipper", Side = -1, Front = false, Center = Vector3.new(-0.63, -0.255, 0.54), Diameter = 0.33 },
		{ Name = "BackRightFlipper", Side = 1, Front = false, Center = Vector3.new(0.63, -0.255, 0.54), Diameter = 0.33 },
	},
}
