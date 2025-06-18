package objects;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import openfl.utils.AssetType;
import openfl.utils.Assets;

class HoldNote extends FlxSprite
{
    private var noteData:Int;
    public var isPlayer:Bool = false;
    public var rgbShader:RGBShaderReference;
    public var useRGBShader:Bool = true;
    
    public var isPixel:Bool = false;
    //public var holdState:HoldState = HIDDEN;

    
    public var parentStrum:StrumNote;
    public var parentNote:Note;

    private var animOffsets:Map<String, Array<Array<Float>>> = new Map();
    private var looping:Bool = false;
    
    public function new(x:Float = 0, y:Float = 0, noteData:Int, ?isPlayer:Bool = false)
    {
        super(x, y);
        
        this.noteData = noteData;
        /*this.isPlayer = isPlayer;
        */
        setupGraphics();
        setupAnimations();
        setupRGBShader();

        //centerOffsets();
        scrollFactor.set(0, 0);
        
        scrollFactor.set();
        antialiasing = ClientPrefs.data.antialiasing && !PlayState.isPixelStage;
        setGraphicSize(Std.int(width * 0.7));
        updateHitbox();
        
        alpha = 0.0001;
        //holdState = HIDDEN;
    }
    
    private function setupGraphics():Void
    {
        var prevFolder:String = '';
        if (PlayState.isPixelStage)
        {
            prevFolder = 'pixelUI/';
            isPixel = true;
        }

        var imagePath:String = useRGBShader ? 'holdCoverRGB' : 'holdCover_${noteData % 4}';
        frames = Paths.getSparrowAtlas(prevFolder + 'holdNotes/' + imagePath);

        if (useRGBShader) 
        {   
            var jsonPath:String = Paths.getPath('images/' + prevFolder + 'holdNotes/' + imagePath + '.json', TEXT);
            #if MODS_ALLOWED
            if (FileSystem.exists(jsonPath))
            #else
            if (Assets.exists(jsonPath))
            #end
            {
                trace('Loading hold note offsets from: ' + jsonPath);
                var data:Dynamic = '';
                #if MODS_ALLOWED
                data = haxe.Json.parse(File.getContent(jsonPath));
                #else
                data = haxe.Json.parse(Assets.getText(jsonPath));
                #end
                animOffsets.clear();
                var anims:Array<Dynamic> = cast data.animations;
                for (anim in anims) 
                {
                    var offsets:Array<Array<Float>> = [];
                    var arrOffsets:Array<Dynamic> = cast anim.offsets;
                    for (arr in arrOffsets)
                    {
                        offsets.push([Std.parseFloat(arr[0]), Std.parseFloat(arr[1])]);
                    }
                    animOffsets.set(anim.anim, offsets);
                }
            }
        }
    }
    
    private function setupAnimations():Void
    {
        var loopAnim:String = 'holdCover0';
        var endAnim:String = 'holdCoverEnd';
        if (!isPixel)
        {
            animation.addByPrefix('start', 'holdCoverStart', 24, false);
        }
        else
        {
            loopAnim = 'loop';
            endAnim = 'explode';
        }

        animation.addByPrefix('loop', 'holdCover0', 24, false);
        animation.addByIndices('end0', 'holdCoverEnd', [2, 3, 4, 5, 6], '', 24, false);
        animation.addByIndices('end1', 'holdCoverEnd', [7, 8], '', 24, false);
        //animation.addByPrefix('end', 'holdCoverEnd', 24, false);

        animation.finishCallback = function(anim:String):Void
        {
            if (anim == 'end0')
            {
                playAnim('end1', true);
            }
            if (anim == 'end1')
            {
                hide();
            }
            if (anim == 'start')
            {
                animation.play('loop', true);
                looping = true;
            }
        };
    }
    
    private function setupRGBShader():Void
    {
        if (useRGBShader)
        {
            rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData % 4));
            if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB) 
                rgbShader.enabled = false;
        }
    }
    
    public function appearForNote(note:Note, strum:StrumNote):Void
    {
        /*if (holdState == HIDDEN)
        {*/
            parentStrum = strum;
            parentNote = note;
            
            //x = (strum.x + strum.frameWidth / 2) - 55;
            //y = (strum.y + strum.frameHeight / 2) - 100;
            alpha = strum.alpha * 0.7;
            
            var animToPlay:String = getAnimationForNote(note);
            playAnim(animToPlay, animToPlay != 'loop');
            if (parentNote.noteData == 1)
                trace(offset.x + ' ' + offset.y);
         //   holdState = ACTIVE;
        //}
    }
    
    private function getAnimationForNote(note:Note):String
    {
        //I should probably use a switch here, but this is more readable and for now i will use only note.parent

        if (!note.isSustainNote) return '';
            
        if (note.animation.name.endsWith('end'))
            return 'end0';
        if (isPixel)
            looping = true;
        return looping ? 'loop' : 'start';
    
    }
    
    public function hide():Void
    {
        alpha = 0.0001;
        looping = false;
        //holdState = HIDDEN;
        parentStrum = null;
        parentNote = null;
    }
    
    public function updatePosition():Void
    {
        if (parentStrum != null)
        {
            //x = parentStrum.getGraphicMidpoint().x;
            //y = parentStrum.getGraphicMidpoint().y;
            x = parentStrum.getGraphicMidpoint().x - 215;
            y = parentStrum.getGraphicMidpoint().y - 230;
            if (parentNote != null && (parentNote.noteData == 1 || parentNote.noteData == 2))
            {
                x -= parentNote.noteData == 1 ? 8 : 5;
                y += parentNote.noteData == 1 ? 15 : -15;
            }
        }
    }
    public function playAnim(anim:String, force:Bool = false)
    {

        if (!animation.exists(anim)) return;
        animation.play(anim, force);

        var offsets = animOffsets.get(anim);
        var side = noteData % 4;
        offset.set(offsets[side][0], offsets[side][1]);
        /*if (offsets != null && offsets.length > side)
        {
            offset.x = offsets[side][0];
            offset.y = offsets[side][1];
        }*/
    }
    
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        //if (holdState == ACTIVE)
        if (alpha > 0.0001 && parentStrum != null)
            updatePosition();
    }
    
    public function changeNoteData(newNoteData:Int):Void
    {
        noteData = newNoteData;
        
        if (useRGBShader && rgbShader != null)
        {
            rgbShader.parent = Note.initializeGlobalRGBShader(noteData);
        }
        else
        {
            setupGraphics();
        }
    }

    inline function addOffset(name:String, arr:Array<Array<Float>>)
    {
        animOffsets[name] = arr;
    }
    
    /*override function destroy():Void
    {
        if (rgbShader != null)
        {
            rgbShader.destroy();
            rgbShader = null;
        }
        
        parentStrum = null;
        parentNote = null;
        
        super.destroy();
    }*/
    
}
enum HoldState
{
    HIDDEN;
    ACTIVE;
}