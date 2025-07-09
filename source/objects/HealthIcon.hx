package objects;

import openfl.utils.Assets;
import haxe.Json;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

typedef IconFile = {
	@:optional var offsets:Array<Int>;
	@:optional var animations:Array<IconAnimArray>;
	@:optional var scale:Float;
	@:optional var no_antialiasing:Bool;
	@:optional var animations_per_beats:Int;
}

typedef IconAnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var animOffsets:Map<String, Array<Float>> = new Map();
	public var defaultScale:Float = 1;
	public var animPerBeat:Int = 0;

	private var isPlayer:Bool = false;
	private var char:String = '';

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		if (char == '')
		{
			char = 'face';
			this.kill();
		}
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true) 
	{
		if(this.char != char) 
		{
			var name:String = 'icons/' + char;

			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon

			var jsonPath:String = null;
			if (Paths.fileExists('images/' + name + '.json', IMAGE))
			{
				#if MODS_ALLOWED
					jsonPath = File.getContent(Paths.modFolders('images/' + name + '.json'));
				#else
					jsonPath = File.getContent(Assets.getText('images/' + name + '.json'));
				#end
			}

			var graphic = Paths.image(name, allowGPU);
			var iSize:Float = Math.round(graphic.width / graphic.height);

			if(jsonPath != null) 
			{
				frames = Paths.getSparrowAtlas(name);
				var json:IconFile = Json.parse(jsonPath);

				if (json.animations_per_beats != null)
					animPerBeat = json.animations_per_beats;

				if(json.offsets != null)
				{
					for (i in 0...json.offsets.length - 1)
						iconOffsets[i] = ((width - 150) / iSize) + (isPlayer ? json.offsets[i] : -json.offsets[i]);
					//iconOffsets[1] = (height - 150) / iSize + (isPlayer ? json.offsets[1]: -json.offsets[1]);
				}
				if(json.scale != null)
				{
					setGraphicSize(Std.int(width * json.scale), Std.int(height * json.scale));
					//scale.set(json.scale, json.scale);
					defaultScale = json.scale;
				}
				if(json.no_antialiasing || !ClientPrefs.data.antialiasing)
					antialiasing = false;

				for (anim in json.animations)
				{
					var animName = anim.anim;
					var animPrefix = anim.name;
					var animFPS = anim.fps;
					var animLoop = anim.loop;
					var animIndices = anim.indices;
					var animOffsets = anim.offsets;
					if (animOffsets != null)
					{
						addOffset(animName, animOffsets[0], animOffsets[1]);
					}

					if(animIndices != null && animIndices.length > 0)
						animation.addByIndices(animName, animPrefix, animIndices, "", animFPS, animLoop, isPlayer);
					else
						animation.addByPrefix(animName, animPrefix, animFPS, animLoop, isPlayer);
				}
				playAnim('idle');
			}
			else
			{
				if (Paths.fileExists('images/' + name + '.xml', IMAGE))
				{
					graphic = Paths.image('icons/icon-face', allowGPU);
					iSize = Math.round(graphic.width / graphic.height);
					trace('Icon XML file found for: ' + name + ' but no JSON file. Using default icon.');
				}
				loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
				iconOffsets[0] = (width - 150) / iSize;
				iconOffsets[1] = (height - 150) / iSize;
				updateHitbox();

				animation.add(char, [for(i in 0...frames.frames.length) i], 0, false, isPlayer);
				animation.play(char);
				this.char = char;
				scale.set(defaultScale, defaultScale);

				if(char.endsWith('-pixel'))
					antialiasing = false;
				else
					antialiasing = ClientPrefs.data.antialiasing;
			}
			updateHitbox();
		}
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		//super.updateHitbox();
		if(autoAdjustOffset && animation.name == getCharacter())
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
	}

	public function getCharacter():String {
		return char;
	}

	public function playAnim(anim:String, force:Bool = false)
	{
		if (!hasAnimation(anim)) return;
		var oldAnim = animation?.curAnim?.name ?? "";
		animation.play(anim, force);
		var daOffset = animOffsets.get(anim);
		offset.set(daOffset[0], daOffset[1]);
	}

	//Taken from Friday Night Killin Source Code, Thx and sorry, M1 Aether
	inline function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	//Taken from Character.hx
	public function hasAnimation(anim:String):Bool
	{
		return animOffsets.exists(anim);
	}
}
