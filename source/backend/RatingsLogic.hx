package backend;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import objects.Note;
import backend.ClientPrefs;
import backend.Rating;
import backend.Conductor;
import states.PlayState;

class RatingsLogic
{
    private var playState:PlayState;
    private var comboGroup:FlxSpriteGroup;

    public var ratingsData:Array<Rating>;
    public var totalNotesHit:Float = 0.0;
    public var totalPlayed:Int = 0;
    public var combo:Int = 0;
    
    public var ratingName:String = '?';
    public var ratingPercent:Float = 0;
    public var ratingFC:String = '';

    public function new(playState:PlayState, comboGroup:FlxSpriteGroup)
    {
        this.playState = playState;
        this.comboGroup = comboGroup;
        this.ratingsData = Rating.loadDefault();
    }

    public function popUpScore(note:Note):Void
    {
        var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
        
        if (playState.cpuControlled) return;
        
        if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0) 
            clearComboSprites();
        
        var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playState.playbackRate);
        
        processNoteData(note, daRating);
        
        createRatingSprite(daRating);
        createComboSprites();
        
        combo++;
        if(combo > 9999) combo = 9999;

        playState.RecalculateRating(false);
    }

    private function clearComboSprites():Void
    {
        for (s in comboGroup)
        {
            if (s == null) continue;
            comboGroup.remove(s);
            s.destroy();
        }
    }

    private function processNoteData(note:Note, rating:Rating):Void 
    {
        totalNotesHit += rating.ratingMod;
        note.ratingMod = rating.ratingMod;
        if(!note.ratingDisabled) rating.hits++;
        note.rating = rating.name;
        
        playState.songScore += rating.score;
        if(!note.ratingDisabled) 
        {
            playState.songHits++;
            totalPlayed++;
        }
        
        if(rating.noteSplash && !note.noteSplashData.disabled)
            playState.spawnNoteSplashOnNote(note);
    }

    private function createRatingSprite(rating:Rating):Void
    {
        var spr:FlxSprite = new FlxSprite();
        spr.loadGraphic(Paths.image(getImagePath(rating.image)));
        
        spr.screenCenter();
        spr.x = FlxG.width * 0.35 - 40;
        spr.y -= 60;
        
        spr.acceleration.y = 550 * playState.playbackRate * playState.playbackRate;
        spr.velocity.y = -FlxG.random.int(140, 175) * playState.playbackRate;
        spr.velocity.x = -FlxG.random.int(0, 10) * playState.playbackRate;
        
        spr.visible = !ClientPrefs.data.hideHud;
        spr.antialiasing = getAntialiasing();
        spr.setGraphicSize(Std.int(spr.width * getScale()));
        spr.updateHitbox();
        
        spr.x += ClientPrefs.data.comboOffset[0];
        spr.y -= ClientPrefs.data.comboOffset[1];
        
        comboGroup.add(spr);
        
        FlxTween.tween(spr, {alpha: 0}, 0.2 / playState.playbackRate, {
            onComplete: (_) -> spr.destroy(),
            startDelay: Conductor.crochet * 0.001 / playState.playbackRate
        });
    }

    private function createComboSprites():Void
    {
        if (combo >= 10) createComboSprite();
        if (combo > 1) createNumberSprites();
    }

    private function createComboSprite():Void
    {
        var baseX:Float = FlxG.width * 0.4;
        var baseY:Float = FlxG.height * 0.5 + 60;
        
        var comboSpr:FlxSprite = new FlxSprite();
        comboSpr.loadGraphic(Paths.image(getImagePath('combo')));
        comboSpr.screenCenter();
        comboSpr.x = baseX;
        comboSpr.y = baseY;
        
        setupComboPhysics(comboSpr);
        comboGroup.add(comboSpr);
        
        FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playState.playbackRate, {
            onComplete: (_) -> {
                comboGroup.remove(comboSpr);
                comboSpr.destroy();
            },
            startDelay: Conductor.crochet * 0.002 / playState.playbackRate
        });
    }

    private function createNumberSprites():Void
    {
        var baseX:Float = FlxG.width * 0.35;
        var baseY:Float = FlxG.height * 0.5 + 60;
        
        var comboStr:String = Std.string(combo).lpad('0', 3);
        for (i in 0...comboStr.length)
        {
            var numSpr:FlxSprite = new FlxSprite();
            numSpr.loadGraphic(Paths.image(getImagePath('nums/num' + comboStr.charAt(i))));
            numSpr.screenCenter();
            numSpr.x = baseX + (43 * i) - 90 + ClientPrefs.data.comboOffset[2];
            numSpr.y = baseY + 20 - ClientPrefs.data.comboOffset[3];
            
            setupNumberPhysics(numSpr);
            comboGroup.add(numSpr);
            
            FlxTween.tween(numSpr, {alpha: 0}, 0.2 / playState.playbackRate, {
                onComplete: (_) -> {
                    comboGroup.remove(numSpr);
                    numSpr.destroy();
                },
                startDelay: Conductor.crochet * 0.002 / playState.playbackRate
            });
        }
    }

    private function setupComboPhysics(spr:FlxSprite):Void
    {
        spr.acceleration.y = FlxG.random.int(200, 300) * playState.playbackRate * playState.playbackRate;
        spr.velocity.y = -FlxG.random.int(140, 160) * playState.playbackRate;
        spr.velocity.x = FlxG.random.float(-5, 5) * playState.playbackRate;
        
        spr.visible = !ClientPrefs.data.hideHud;
        spr.antialiasing = getAntialiasing();
        spr.setGraphicSize(Std.int(spr.width * getScale() * 0.8));
        spr.updateHitbox();
        
        spr.x += ClientPrefs.data.comboOffset[0];
        spr.y -= ClientPrefs.data.comboOffset[1];
    }

    private function setupNumberPhysics(spr:FlxSprite):Void
    {
        spr.acceleration.y = FlxG.random.int(200, 300) * playState.playbackRate * playState.playbackRate;
        spr.velocity.y = -FlxG.random.int(140, 160) * playState.playbackRate;
        spr.velocity.x = FlxG.random.float(-5, 5) * playState.playbackRate;
        
        spr.visible = !ClientPrefs.data.hideHud;
        spr.antialiasing = getAntialiasing();
        spr.setGraphicSize(Std.int(spr.width * getScale() * 0.8));
        spr.updateHitbox();
        
        spr.x += ClientPrefs.data.comboOffset[2];
        spr.y -= ClientPrefs.data.comboOffset[3];
    }

    private function getImagePath(name:String):String
    {
        var folder:String = PlayState.stageUI + "UI/";
        return folder + 'ratings/' + name;
        //return folder + name + PlayState.uiPostfix;
    }

    private function getAntialiasing():Bool
    {
        return (PlayState.stageUI != "normal") ? !PlayState.isPixelStage : ClientPrefs.data.antialiasing;
    }

    private function getScale():Float
    {
        return PlayState.isPixelStage ? PlayState.daPixelZoom * 0.85 : 0.7;
    }

    public function recalculateRating(badHit:Bool = false):Void 
    {
        ratingName = '?';
        if(totalPlayed != 0) 
        {
            ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
            
            ratingName = PlayState.ratingStuff[PlayState.ratingStuff.length-1][0];
            if(ratingPercent < 1)
                for (i in 0...PlayState.ratingStuff.length-1)
                    if(ratingPercent < PlayState.ratingStuff[i][1])
                    {
                        ratingName = PlayState.ratingStuff[i][0];
                        break;
                    }
        }
        calculateFC();
    }

    public function cacheAssets():Void
    {
        for (rating in ratingsData)
            Paths.image(getImagePath(rating.image));
        for (i in 0...10)
            Paths.image(getImagePath('nums/num' + i));
    }

    private function calculateFC():Void 
    {
        ratingFC = "";
        if (playState.songMisses == 0) 
        {
            if (ratingsData[2].hits > 0 || ratingsData[3].hits > 0)
                ratingFC = 'FC';
            else if (ratingsData[1].hits > 0)
                ratingFC = 'GFC';
            else if (ratingsData[0].hits > 0)
                ratingFC = 'SFC';
        } 
        else 
            ratingFC = (playState.songMisses < 10) ? 'SDCB' : 'Clear';
    }

    public function reset():Void
    {
        combo = 0;
    }

    public function destroy():Void
    {
        playState = null;
        comboGroup = null;
        ratingsData = null;
    }
}