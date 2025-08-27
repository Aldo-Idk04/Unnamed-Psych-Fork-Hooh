package states.songs;

import states.PlayState;
import objects.Character;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class Tutorial extends PlayState
{
    private var tutorialCameraTwn:FlxTween;
    
    override public function create():Void 
    {
        super.create();
}    }
    
    override public function moveCameraToCharacter(target:String):Void
    {
    }
    
    private function tweenCamIn():Void 
    {
        var targetZoom:Float = 1.3; 
        
        if (tutorialCameraTwn == null && FlxG.camera.zoom != targetZoom) 
        {
            tutorialCameraTwn = FlxTween.tween(FlxG.camera, {zoom: targetZoom}, 
                (Conductor.stepCrochet * 4 / 1000), {
                    ease: FlxEase.elasticInOut, 
                    onComplete: function (twn:FlxTween) {
                        tutorialCameraTwn = null;
                    }
                });
        }
    }
    
    override public function stepHit():Void 
    {
        super.stepHit();
    }
    
    override public function beatHit():Void 
    {
        super.beatHit();
    }
}