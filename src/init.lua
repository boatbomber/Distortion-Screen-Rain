--[=[

	--Copyright boatbomber 2022--

	--Given under a MPL 2.0 License--
		Explanation of license: https://tldrlegal.com/license/mozilla-public-license-2.0-(mpl-2)

	--FEATURES--

	Creates droplets of "water" on the screen, with a distortion effect, giving great immersion
	for games that have rainy environments.

	Droplets will not spawn if the player is indoors or under cover of some sort.
	Droplets will not spawn if the camera is pointed down, as that is avoiding "getting rain in the eyes".

	--HOW TO USE--
	In a LocalScript, require this module and call :Enable(). You can optionally pass a settings table in Enable,
	or you can pass a settings table in a separate call to :Configure().
	You can also call :Disable() to make it stop spawning droplets.

	--WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING--

	THIS PRODUCT RELIES ON GLASS MATERIAL, THUS SHARING ALL THE LIMITATIONS OF GLASS.

	Non-opaque objects are currently not visible through glass.
	This includes, but is not limited to, transparent parts, decals on transparent
	parts, particles, and world-space gui objects.
	Additionally, it only looks right for users with graphic settings of at least 8.
	Hence, I've set it to only spawn droplets if the user has the graphics set high enough.

	--WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING-- --WARNING--
--]=]

-- Feel free to modify these settings

local Settings = {
	-- How many droplets spawn per second
	Rate = 5,

	-- How large the droplets roughly are (in studs)
	Size = 0.08,

	-- What color the droplets are tinted (leave as nil for a default realistic light blue)
	Tint = Color3.fromRGB(226, 244, 255),

	-- How long it takes for a droplet to fade
	Fade = 1.5,

	-- Update frequency
	UpdateFreq = 1 / 45,
}

-------------------------------------------------------------------------------------------------------
-- Modifications beyond this point may alter/break functionality if you don't know what you're doing --
-------------------------------------------------------------------------------------------------------

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Modules
local ObjectPool = require(script.ObjectPool)

-- Constants
local UP_VEC = Vector3.new(0, 1, 0)
local UNIT_VEC = Vector3.new(1, 1, 1)
local EMPTY_VEC = Vector3.new(0, 0, 0)

--Player related
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local GameSettings = UserSettings().GameSettings
local GlassGraphics = GameSettings.SavedQualityLevel.Value >= 8
GameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
	GlassGraphics = GameSettings.SavedQualityLevel.Value >= 8 or GameSettings.SavedQualityLevel.Value == 0
end)

--Settings defaulted
Settings.Rate = Settings.Rate or 5
Settings.Size = Settings.Size or 1.5
Settings.Tint = Settings.Tint or Color3.fromRGB(226, 244, 255)
Settings.Fade = Settings.Fade or 1.5
Settings.UpdateFreq = Settings.UpdateFreq or (1 / 45)

--Raycasting
local ignoreList, ignoreLength = {}, 0

local function addToIgnore(obj: Instance?)
	if obj then
		local index = ignoreLength + 1
		ignoreLength += 1
		ignoreList[index] = obj

		local connection
		connection = obj.AncestryChanged:Connect(function()
			if obj:IsDescendantOf(game) then
				return
			end
			connection:Disconnect()

			-- Perform a fast unordered table removal
			ignoreList[index] = ignoreList[ignoreLength]
			ignoreList[ignoreLength] = nil
			ignoreLength -= 1
		end)
	end
end

addToIgnore(Player.Character)
Player.CharacterAdded:Connect(addToIgnore)

--Droplet holder
local ScreenDroplets = Instance.new("Folder")
ScreenDroplets.Name = "ScreenDroplets"
ScreenDroplets.Parent = Camera
addToIgnore(ScreenDroplets)

local Animations = {}
local Offsets = {}
local CameraCF = Camera.CFrame

-- Keep objects in front of camera
local dropletCount = (Settings.Rate * Settings.Fade) * 3
RunService:BindToRenderStep("ScreenRainUpdate", Enum.RenderPriority.Camera.Value + 1, function()
	CameraCF = Camera.CFrame

	local droplets = table.create(dropletCount)
	local dropletCF = table.create(dropletCount)

	local i = 0
	for droplet, offset in pairs(Offsets) do
		i += 1
		dropletCF[i] = CameraCF * offset
		droplets[i] = droplet
	end
	dropletCount = i

	workspace:BulkMoveTo(droplets, dropletCF, Enum.BulkMoveMode.FireCFrameChanged)
end)

local DropletPool = nil
do
	-- Droplet prefab
	local DropletPrefab = Instance.new("Part")
	DropletPrefab.Name = "Droplet"
	DropletPrefab.Material = Enum.Material.Glass
	DropletPrefab.CastShadow = false
	DropletPrefab.CanCollide = false
	DropletPrefab.CanQuery = false
	DropletPrefab.CanTouch = false
	DropletPrefab.Anchored = true
	DropletPrefab.Transparency = 0.5
	DropletPrefab.Color = Settings.Tint
	DropletPrefab.Size = UNIT_VEC

	local MeshPrefab = Instance.new("SpecialMesh")
	MeshPrefab.Name = "Mesh"
	MeshPrefab.MeshType = Enum.MeshType.Sphere
	MeshPrefab.Parent = DropletPrefab

	DropletPool = ObjectPool.new(DropletPrefab, (Settings.Rate * Settings.Fade) * 3)
end

local function Cleanup(obj: Instance)
	Animations[obj] = nil
	Offsets[obj] = nil
	DropletPool:Return(obj)
end

--Returns whether the given position is under cover
local function UnderObject(pos, len)
	len = len or 120

	local hit, position = workspace:FindPartOnRayWithIgnoreList(Ray.new(pos, UP_VEC * len), ignoreList)
	if hit then
		return hit.Transparency ~= 1 and true or UnderObject(position + UP_VEC, len - (pos - position).Magnitude)
	else
		return false
	end
end

--Creates a random droplet on screen
local function CreateDroplet()
	local Scale = Settings.Size + (math.random((Settings.Size / 3) * -10, (Settings.Size / 3) * 10) / 10)

	local DropletMain = DropletPool:Get()
	DropletMain.Mesh.Scale = Vector3.new(Scale, Scale, Scale)
	DropletMain.Mesh.Offset = EMPTY_VEC
	DropletMain.Color = Settings.Tint
	DropletMain.Transparency = 0.7

	local DropletOffset = CFrame.new(math.random(-120, 120) / 100, math.random(-100, 100) / 100, -1)
	Offsets[DropletMain] = DropletOffset

	Animations[DropletMain] = {
		startClock = os.clock(),
		scale = Scale,
		stretch = (math.random(5, 10) / 10) * Scale,
		mesh = DropletMain.Mesh,
	}

	DropletMain.Parent = ScreenDroplets

	--Create droplet extrusions
	for _ = 1, math.random(4) do
		local ExtrusionScale = (Scale / 1.5) + (math.random((Scale / 3) * -100, (Scale / 3) * 100) / 100)

		local Extrusion = DropletPool:Get()
		Extrusion.Mesh.Scale = Vector3.new(ExtrusionScale, ExtrusionScale, ExtrusionScale)
		Extrusion.Mesh.Offset = EMPTY_VEC
		Extrusion.Color = Settings.Tint
		Extrusion.Transparency = 0.7

		local e2 = ExtrusionScale * 60
		local ExtrusionOffset = DropletOffset * CFrame.new(math.random(-e2, e2) / 100, math.random(-e2, e2) / 100, 0)
		Offsets[Extrusion] = ExtrusionOffset

		Animations[Extrusion] = {
			startClock = os.clock(),
			scale = ExtrusionScale,
			stretch = (math.random(5, 10) / 10) * ExtrusionScale,
			mesh = Extrusion.Mesh,
		}

		Extrusion.Parent = ScreenDroplets
	end
end

local ScreenRain = {
	Enabled = false,
	_activeUpdater = false,
}

function ScreenRain:Enable(settings)
	self.Enabled = true
	self:Configure(settings)

	if self._activeUpdater then
		return
	end
	self._activeUpdater = true

	-- Droplet spawn/animation loop
	local accumulatedChance = 0
	task.defer(function()
		local lastCheck = os.clock()

		while task.wait(Settings.UpdateFreq) do
			if (not self.Enabled) and (not next(Animations)) then
				self._activeUpdater = false
				break
			end

			debug.profilebegin("ScreenRainUpdate")
			local now = os.clock()

			debug.profilebegin("Animations")
			for Droplet, Data in pairs(Animations) do
				local startClock = Data.startClock

				local elapsed = now - startClock
				if elapsed >= Settings.Fade then
					Cleanup(Droplet)
					continue
				end

				local mesh, scale, stretch = Data.mesh, Data.scale, Data.stretch
				local alpha = (elapsed / Settings.Fade)
				local quint = alpha * alpha * alpha * alpha
				local y = scale + (stretch * quint)

				Droplet.Transparency = 0.7 + (0.3 * (alpha*alpha))
				mesh.Scale = Vector3.new(scale, y, scale)
				mesh.Offset = Vector3.new(0, y / -2, 0)
			end
			debug.profileend()

			debug.profilebegin("Droplet Creation")
			if self.Enabled and GlassGraphics and CameraCF.LookVector.Y > -0.4 and not UnderObject(CameraCF.Position) then
				accumulatedChance += (now - lastCheck) * Settings.Rate

				for _ = 1, math.floor(accumulatedChance) do
					CreateDroplet()
				end

				accumulatedChance %= 1
			else
				accumulatedChance %= 1
			end
			debug.profileend()

			lastCheck = now
			debug.profileend()
		end
	end)
end

function ScreenRain:Disable()
	self.Enabled = false
end

function ScreenRain:Configure(settings)
	if type(settings) == "table" then
		for k, v in pairs(settings) do
			Settings[k] = v
		end
	end
end

return ScreenRain
