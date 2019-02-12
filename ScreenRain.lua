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


local Settings	= {
	
--	Rate: How many droplets spawn per second
	Rate	= 8;
	
--	Size: How large the droplets roughly are (in studs)
	Size	= 0.1;
	
--	Tint: What color the droplets are tinted (leave as nil for a default realistic light blue)
	Tint	= Color3.fromRGB(226, 244, 255);
	
--	Fade: How long it takes for a droplet to fade
	Fade	= 1.5;
	
};


----------------------------------------------------------------------------
---  Variables  ------------------------------------------------------------
----------------------------------------------------------------------------

--Services
local RunService		= game:GetService("RunService")
local TweenService		= game:GetService("TweenService")

--Player related
local Camera		= workspace.CurrentCamera
local Player		= game.Players.LocalPlayer
local Mouse			= Player:GetMouse()
local GameSettings	= UserSettings().GameSettings

--Raycasting
local ignoreList	= {Player.Character or Player.CharacterAdded:Wait()}

--Localizing
local instance	= Instance.new
local rgbColor	= Color3.fromRGB
local random	= math.random
local v3, cf	= Vector3.new, CFrame.new

--Settings localized
local defaultColor = rgbColor(226, 244, 255)

local Rate = Settings.Rate
local Size = Settings.Size
local Tint = Settings.Tint
local Fade = Settings.Fade

--Fade tween
local fadeInfo		= TweenInfo.new(Fade,Enum.EasingStyle.Sine,  Enum.EasingDirection.In)
local strechInfo	= TweenInfo.new(Fade/1.05,Enum.EasingStyle.Quint,  Enum.EasingDirection.In)
local fadeGoal		= {Transparency = 1}

----------------------------------------------------------------------------
---  Prefab Basic Objects  -------------------------------------------------
----------------------------------------------------------------------------

--Droplet holder
local ScreenBlock = instance("Part")
	ScreenBlock.Size 			= v3(2,2,2)
	ScreenBlock.Transparency	= 1
	ScreenBlock.Anchored		= true
	ScreenBlock.CanCollide		= false
	ScreenBlock.Parent		= Camera

RunService:BindToRenderStep("ScreenUpdate", Enum.RenderPriority.Camera.Value + 1, function() ScreenBlock.CFrame = Camera.CFrame end)

--Droplet object
local Dropet_Prefab		= instance("Part")
	Dropet_Prefab.Material		= Enum.Material.Glass
	Dropet_Prefab.CanCollide	= false
	Dropet_Prefab.Transparency	= 0.5
	Dropet_Prefab.Name			= "Droplet_Main"
	Dropet_Prefab.Color			= Tint or defaultColor
	Dropet_Prefab.Size			= v3(1,1,1)
	
	local ObjectMesh	= instance("SpecialMesh")
		ObjectMesh.MeshType			= Enum.MeshType.Sphere
		ObjectMesh.Parent			= Dropet_Prefab

----------------------------------------------------------------------------
---  Functions  ------------------------------------------------------------
----------------------------------------------------------------------------

--Welds together two objects
local function Weld(a, b)
	local weld	= Instance.new("Weld")
		weld.C0 = a.CFrame:inverse() * b.CFrame
		
		weld.Part0 = a
		weld.Part1 = b
	weld.Parent = a
	
	return weld
end

--Returns whether the given position is under cover
local function UnderObject(pos)
	local ray = Ray.new(pos, v3(0,1,0) * 150)
	-- raycast
	local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
	if hit then
		if hit.Transparency == 1 then --It's invisible, thus a hidden non-gameplay part that doesn't count (so we check again above it)
			return UnderObject(position+v3(0,0.5,0))
		else return true
		end
	else
		return false
	end
end

--Creates a random droplet on screen
local function CreateDroplet()
	--Setup
	local stretch = 1+(random(1,15)/10)
	local Tweens		= {};
		
	--Main droplet object
	local DropletMain = Dropet_Prefab:Clone()	
	local SizeOffset 				= random((Size/3)*-10,(Size/3)*10)/10
		DropletMain.Mesh.Scale		= v3(Size+SizeOffset,Size+SizeOffset,Size+SizeOffset)
		DropletMain.CFrame			= cf()
	
	
	--Create droplet extrusions
	for i=1, random(1,4) do
		local Extrusion = Dropet_Prefab:Clone()
			Extrusion.Name		= "Extrusion_"..i
			local eSizeOffset			= random((Size/3)*-100,(Size/3)*100)/100
			Extrusion.Mesh.Scale		= v3((Size/1.5)+eSizeOffset, (Size/1.5)+eSizeOffset, (Size/1.5)+eSizeOffset)
			Extrusion.CFrame			= cf(v3(random(-(Size*40),(Size*40))/100,random(-(Size*40),(Size*40))/100,0))
			Extrusion.Parent			= DropletMain
		Weld(Extrusion, DropletMain)
		
		ignoreList[#ignoreList+1]	= Extrusion
		Tweens[#Tweens+1]	= TweenService:Create(Extrusion, fadeInfo, fadeGoal)
		local s,o = Extrusion.Mesh.Scale, Extrusion.Mesh.Offset
		Tweens[#Tweens+1]	= TweenService:Create(Extrusion.Mesh, strechInfo, {
			Scale	= v3(s.X, s.Y*(stretch), s.Z);
			Offset	= v3(0,-(s.Y*stretch)/2.05,0);
		})
	end
	
	ignoreList[#ignoreList+1]	= DropletMain
	Tweens[#Tweens+1]	= TweenService:Create(DropletMain, fadeInfo, fadeGoal)
	local s,o = DropletMain.Mesh.Scale, DropletMain.Mesh.Offset
	Tweens[#Tweens+1]	= TweenService:Create(DropletMain.Mesh, strechInfo, {
		Scale	= v3(s.X, s.Y*(stretch), s.Z);
		Offset	= v3(0,-(s.Y*stretch)/2.05,0);
	})
	
	DropletMain.CFrame = ScreenBlock.CFrame:toWorldSpace(cf(random(-100,100)/100, random(-100,100)/100, -1))
	Weld(DropletMain, ScreenBlock)
	
	for i, t in pairs(Tweens) do
		t:Play()
	end
	delay(Fade+0.1, function() DropletMain:Destroy() end)
	
	DropletMain.Parent = ScreenBlock
end


----------------------------------------------------------------------------
---  Functionality Loop  ---------------------------------------------------
----------------------------------------------------------------------------
math.randomseed(tick())

while wait(1/Rate) do
	--Only render droplets if:
		--Camera isn't looking down
		--Render settings are high enough
		--Camera isn't under an awning or roof or something
		
	if (Camera.CFrame.lookVector.Y>-0.4) and (GameSettings.SavedQualityLevel.Value >= 8) and (not UnderObject(Camera.CFrame.Position)) then
		CreateDroplet()
	end
end
