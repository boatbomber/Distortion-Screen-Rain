I made a version of this when glass first came out, and it got nice responses. Someone recently [**brought it back up**](https://twitter.com/Maxx_JNM/status/1094736319182487554), so I figured now is as good a time as any to remake it!


For games with rainy environments, having droplets on screen can really add immersion to the game.
My original inspiration for this was [**Hard Reset: Redux**](https://youtu.be/DsI9gmLZ664?t=1190). It was a small feature, but it felt so good. For showcase places, it's even better.
****
What does it do?
--
This creates small "water droplets" on the screen, using Glass material balls to give it a distortion effect.

****
Features:
--


- **Customization**
```Lua
local Settings	= {

	-- How many droplets spawn per second
	Rate = 8,

	-- How large the droplets roughly are (in studs)
	Size = 0.1,

	-- What color the droplets are tinted (leave as nil for a default realistic light blue)
	Tint = Color3.fromRGB(226, 244, 255),

	-- How long it takes for a droplet to fade
	Fade = 1.5,

}
```
- **Droplet Formation**

Using a bit of `math.random()`, it gives natural feeling droplet formations (not just single spheres) and gives some nice variations to the droplets.

- **Droplet "Running"**

Droplets are created via a SpecialMesh, allowing them to be streched down, imitating a "running" effect.

- **Coverage Detection**

If the camera goes under a roof, or tree, or any sort of cover, the raindrops will stop spawning.

- **Camera Angle Conditions**

If the player looks down, thus shielding his/her eyes from the rain, the droplets stop spawning.

- **Render Settings Compatibility**

Because Glass doesn't render properly on low graphic settings, if the player lowers his/her settings below 8, it stops rendering. This way, you don't have to worry about lower settings failing to run the game properly. They just won't have the extra bonus immersion. :man_shrugging:


Performance:
--
Steady 60FPS, ~0.5% CPU Usage, 30.0/s Rate
*(Many thanks to @howmanysmaII for optimizations!)*

Warning:
--
It relies on glass, and therefore brings with it all the limitations of Glass.

Non-opaque objects are currently not visible through glass. This includes, but is not limited to, transparent parts, decals on transparent parts, particles, and world-space gui objects.

****
Files:
--
[**Example place**](https://www.roblox.com/games/2843523612/Distortion-Droplets)

[**Roblox Library**](https://www.roblox.com/catalog/02843872705/redirect)

-----
-----
-----

### Enjoying my work? I love to create and share with the community, for free.
I make loads of free and open source scripts and modules for you all to use in your projects!
You can find a lot of them listed for you in my [portfolio](https://devforum.roblox.com/t/boatbomber-programmers-portfolio/426661/1). Enjoy!

If you'd like to help fund my work, check out my [Patreon](https://www.patreon.com/boatbomberrblx) or [PayPal](http://paypal.me/boatbomberrblx)!