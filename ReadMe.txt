List of changes:

0.1
setSpriteShader now has a bool for forcing the shader (ShaderFunctions-PlayState[initShader])
Same for createRuntimeShader and initLuaShader
The freeplay now has a toggle on and off for the voices whenever you are hearing a song on case they exist (FreeplayState-MusicPlayer) 
If the icon has a winning icon is gonna be shown on the freeplay whenever they got selected (FreeplayState)
For empty icons in the weeks.json is gonna remove it completely instead of showing the haxe icon (HealthIcon)

Added icons animated and built in winning icons (HealthIcon, PlayState)
Props added for them
iconsTweens (Bool)
icon.animPerBeat (Int)
icon.defaultScale (Float)

Different Icon Tween (PlayState[beatHit])
Replaced updateIconsScale with updateIconsTweens (PlayState)

Changed the logic for the icon frames and animations on updateIconsFrames (PlayState)

0.2

Added new function for Character.hx called invertAnimations (Missing FlxAnimate support)
callMethod example 
callMethod('boyfriend.invertAnimations')

"Fixed" callMethod args (ReflectFunctions)
now it accepts {''}, nil, {}, {nil}
Thx for the idea GhostGlowdev

Added secondaries Section (Ally, Jackal)
(SONG, ChartingState, Vslice, PlayState)

Added secondaries Notes 
(Note)

Added new value for the stages called "need_secondaries" (Bool)

Added new checkmarks for Ally and Jackal (Charting State)

Added lua var "secsSection" (FunkinLua, PlayState)

Added new characters notes (MetaNote, Song, PlayState, ChartingState)

0.3

Added secondaries cameras offsets

Added camera moving to the actual sec characters

Added support for sec characters for "cameraSetTarget" lua function

Added new suffix for the sustain notes that actually loops (-long)

