--[=[
	
	--Copyright boatbomber 2019--
	
	--Given under a BSD 3-Clause License--
		Explanation of license:		https://tldrlegal.com/license/bsd-3-clause-license-(revised)
		
	--FEATURES--
	
	Creates droplets of "water" on the screen, with a distortion effect, giving great immersion
	for games that have rainy environments.
	
	Droplets will not spawn if the player is indoors or under cover of some sort.
	Droplets will not spawn if the camera is pointed down, as that is avoiding "getting rain in the eyes".
	
	
	--WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING--
	
	THIS PRODUCT RELIES ON GLASS MATERIAL, THUS SHARING ALL THE LIMITATIONS OF GLASS.
	
	Non-opaque objects are currently not visible through glass.
	This includes, but is not limited to, transparent parts, decals on transparent
	parts, particles, and world-space gui objects.
	Additionally, it only looks right for users with graphic settings of at least 8.
	Hence, I've set it to only spawn droplets if the user has the graphics set high enough.
	
	--WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING--
--]=]

-- Constants
local Settings = {
	--	Rate: How many droplets spawn per second
	Rate = 8;

	--	Size: How large the droplets roughly are (in studs)
	Size = 0.1;

	--	Tint: What color the droplets are tinted (leave as nil for a default realistic light blue)
	Tint = Color3.fromRGB(226, 244, 255);

	--	Fade: How long it takes for a droplet to fade
	Fade = 1.5;
}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UpVec = Vector3.new(0, 1, 0)
local DROPLET_SIZE = Vector3.new(1, 1, 1)
local EMPTY_CFRAME = CFrame.new()

----------------------------------------------------------------------------
---  Variables  ------------------------------------------------------------
----------------------------------------------------------------------------

--Player related
local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer
local GameSettings = UserSettings().GameSettings
local CanShow = GameSettings.SavedQualityLevel.Value >= 8

--Raycasting
local ignoreList = {Player.Character or Player.CharacterAdded:Wait()}
local IgnoreLength = 1

--Localizing
local ipairs = ipairs

--Settings localized
local Rate = Settings.Rate
local Size = Settings.Size
local Tint = Settings.Tint or Color3.fromRGB(226, 244, 255)
local Fade = Settings.Fade
--Fade tween
local fadeInfo = TweenInfo.new(Fade, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
local strechInfo = TweenInfo.new(Fade / 1.05, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local fadeGoal = {Transparency = 1}

local accumulatedChance = 0

----------------------------------------------------------------------------
---  Prefab Basic Objects  -------------------------------------------------
----------------------------------------------------------------------------
--Droplet holder
local ScreenBlock = Instance.new("Part")
ScreenBlock.Size = Vector3.new(2, 2, 2)
ScreenBlock.Transparency = 1
ScreenBlock.Anchored = true
ScreenBlock.CanCollide = false
ScreenBlock.Parent = Camera

local ScreenBlockCFrame = EMPTY_CFRAME

RunService:BindToRenderStep("ScreenRainUpdate", Enum.RenderPriority.Camera.Value + 1, function()
	ScreenBlockCFrame = Camera.CFrame
	ScreenBlock.CFrame = ScreenBlockCFrame
end)

----------------------------------------------------------------------------
---  Functions  ------------------------------------------------------------
----------------------------------------------------------------------------

local function DestroyDroplet(d)
	wait(Fade)

	-- Proper GC
	for _, Child in ipairs(d:GetChildren()) do
		local Index = table.find(ignoreList, Child)
		if Index then
			ignoreList[Index] = ignoreList[IgnoreLength]
			ignoreList[IgnoreLength] = nil
			IgnoreLength = IgnoreLength - 1
		end
	end

	local Index = table.find(ignoreList, d)
	if Index then
		ignoreList[Index] = ignoreList[IgnoreLength]
		ignoreList[IgnoreLength] = nil
		IgnoreLength = IgnoreLength - 1
	end

	d:Destroy()
end

--Returns whether the given position is under cover
local function UnderObject(pos, l)
	l = l or 120

	local hit, position = Workspace:FindPartOnRayWithIgnoreList(Ray.new(pos, UpVec * l), ignoreList)
	if hit then
		return hit.Transparency ~= 1 and true or UnderObject(position + UpVec, l - (pos - position).Magnitude)
	else
		return false
	end
end

--Creates a random droplet on screen
local function CreateDroplet()
	--Setup
	local stretch = 1 + math.random(15) / 10

	local RunAmount = math.random(4)
	local Tweens = table.create(RunAmount * 2 + 2)
	local TweensLength = 0

	local SizeOffset = math.random((Size / 3) * -10, (Size / 3) * 10) / 10
	local Scale = Size + SizeOffset
	local MeshScale = Vector3.new(Scale, Scale, Scale)

	--Main droplet object
	local DropletMain = Instance.new("Part")
	DropletMain.Material = Enum.Material.Glass
	DropletMain.CFrame = EMPTY_CFRAME
	DropletMain.CanCollide = false
	DropletMain.Transparency = 0.5
	DropletMain.Name = "Droplet_Main"
	DropletMain.Color = Tint
	DropletMain.Size = DROPLET_SIZE

	local Mesh = Instance.new("SpecialMesh")
	Mesh.MeshType = Enum.MeshType.Sphere
	Mesh.Scale = MeshScale
	Mesh.Parent = DropletMain

	--Create droplet extrusions
	for i = 1, RunAmount do
		local eSizeOffset = math.random(
			(Size / 3) * -100,
			(Size / 3) * 100
		) / 100

		local ExtrusionCFrame = CFrame.new(Vector3.new(
			math.random(-(Size * 40), Size * 40) / 100,
			math.random(-(Size * 40), Size * 40) / 100,
			0
			))

		local ExtrusionScale = Size / 1.5 + eSizeOffset
		local ExtrusionMeshScale = Vector3.new(ExtrusionScale, ExtrusionScale, ExtrusionScale)

		local Extrusion = Instance.new("Part")
		Extrusion.Material = Enum.Material.Glass
		Extrusion.CFrame = ExtrusionCFrame
		Extrusion.CanCollide = false
		Extrusion.Transparency = 0.5
		Extrusion.Name = "Extrusion_" .. i
		Extrusion.Color = Tint
		Extrusion.Size = DROPLET_SIZE

		local ExtrusionMesh = Instance.new("SpecialMesh")
		ExtrusionMesh.MeshType = Enum.MeshType.Sphere
		ExtrusionMesh.Scale = ExtrusionMeshScale
		ExtrusionMesh.Parent = Extrusion
		Extrusion.Parent = DropletMain

		local weld = Instance.new("Weld")
		weld.C0 = ExtrusionCFrame:Inverse() * EMPTY_CFRAME
		weld.Part0 = Extrusion
		weld.Part1 = DropletMain
		weld.Parent = Extrusion

		IgnoreLength = IgnoreLength + 1
		TweensLength = TweensLength + 1
		ignoreList[IgnoreLength] = Extrusion
		Tweens[TweensLength] = TweenService:Create(Extrusion, fadeInfo, fadeGoal)

		TweensLength = TweensLength + 1
		Tweens[TweensLength] = TweenService:Create(ExtrusionMesh, strechInfo, {
			Scale = Vector3.new(ExtrusionScale, ExtrusionScale * stretch, ExtrusionScale);
			Offset = Vector3.new(0, -(ExtrusionScale * stretch) / 2.05, 0);
		})
	end

	IgnoreLength = IgnoreLength + 1
	TweensLength = TweensLength + 1
	ignoreList[IgnoreLength] = DropletMain
	Tweens[TweensLength] = TweenService:Create(DropletMain, fadeInfo, fadeGoal)

	TweensLength = TweensLength + 1
	Tweens[TweensLength] = TweenService:Create(Mesh, strechInfo, {
		Scale = Vector3.new(Scale, Scale * stretch, Scale);
		Offset = Vector3.new(0, -(Scale * stretch) / 2.05, 0);
	})

	local NewCFrame = ScreenBlockCFrame:ToWorldSpace(CFrame.new(
		math.random(-100, 100) / 100,
		math.random(-100, 100) / 100,
		-1
		))

	DropletMain.CFrame = NewCFrame
	local weld = Instance.new("Weld")
	weld.C0 = NewCFrame:Inverse() * ScreenBlockCFrame
	weld.Part0 = DropletMain
	weld.Part1 = ScreenBlock
	weld.Parent = DropletMain

	for _, t in ipairs(Tweens) do
		t:Play()
	end

	local DestroyRoutine = coroutine.create(DestroyDroplet)
	coroutine.resume(DestroyRoutine, DropletMain)
	DropletMain.Parent = ScreenBlock
end

local function OnGraphicsChanged()
	CanShow = GameSettings.SavedQualityLevel.Value >= 8
end

GameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(OnGraphicsChanged)

----------------------------------------------------------------------------
---  Functionality Loop  ---------------------------------------------------
----------------------------------------------------------------------------

RunService.Heartbeat:Connect(function(deltaTime)
	accumulatedChance += deltaTime * Settings.Rate

	if CanShow and ScreenBlockCFrame.LookVector.Y > -0.4 and not UnderObject(ScreenBlockCFrame.Position) then
		for i = 1, math.floor(accumulatedChance) do
			CreateDroplet()
		end

		accumulatedChance %= 1
	else
		accumulatedChance %= 1
	end
end)