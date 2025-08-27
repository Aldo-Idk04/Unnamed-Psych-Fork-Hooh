package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;

/**
    The FPS class provides an easy-to-use monitor to display
    the current frame rate of an OpenFL project
**/
class FPSCounter extends TextField
{
    /**
        The current frame rate, expressed using frames-per-second
    **/
    public var currentFPS(default, null):Int;

    /**
        The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
    **/
    public var memoryMegas(get, never):Float;

    @:noCompletion private var times:Array<Float>;
    private var deltaTimeout:Float = 0.0;
    private var lastMemoryCheck:Float = 0.0;
    private var cachedMemory:Float = 0.0;
    private var lastFPS:Int = 0;
    private var lastTextUpdate:Float = 0.0;
    
    private static inline var UPDATE_INTERVAL:Float = 100.0;
    private static inline var MEMORY_UPDATE_INTERVAL:Float = 500.0;
    private static inline var FPS_WINDOW:Float = 1000.0; 
    private static inline var MAX_TIMES_LENGTH:Int = 300;

    public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
    {
        super();

        this.x = x;
        this.y = y;

        currentFPS = 0;
        selectable = false;
        mouseEnabled = false;
        defaultTextFormat = new TextFormat(Paths.font('crypt.ttf'), 16, color);
        autoSize = LEFT;
        multiline = true;
        text = "FPS: ";

        times = [];
        times.resize(MAX_TIMES_LENGTH);
        
        cachedMemory = get_memoryMegas();
        lastMemoryCheck = haxe.Timer.stamp() * 1000;
    }

    // Event Handlers
    private override function __enterFrame(deltaTime:Float):Void
    {
        final now:Float = haxe.Timer.stamp() * 1000;
        
        times.push(now);
        
        var cutoff:Float = now - FPS_WINDOW;
        var removeCount:Int = 0;
        
        for (i in 0...times.length) {
            if (times[i] >= cutoff) break;
            removeCount++;
        }
        
        if (removeCount > 0) {
            times.splice(0, removeCount);
        }
        
        if (times.length > MAX_TIMES_LENGTH) {
            times.splice(0, times.length - MAX_TIMES_LENGTH);
        }

        deltaTimeout += deltaTime;
        if (deltaTimeout < UPDATE_INTERVAL) {
            return;
        }

        var newFPS:Int = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
        
        if (Math.abs(newFPS - lastFPS) >= 1 || (now - lastTextUpdate) > 1000) {
            currentFPS = newFPS;
            lastFPS = newFPS;
            lastTextUpdate = now;
            updateText(now);
        }
        
        deltaTimeout = 0.0;
    }

    public dynamic function updateText(?now:Float):Void {
        if (now == null) now = haxe.Timer.stamp() * 1000;
        
        if (now - lastMemoryCheck > MEMORY_UPDATE_INTERVAL) {
            cachedMemory = get_memoryMegas();
            lastMemoryCheck = now;
        }
        
        var textBuf = new StringBuf();
        textBuf.add('FPS: ');
        textBuf.add(currentFPS);
        textBuf.add(' | Memory: ');
        textBuf.add(flixel.util.FlxStringUtil.formatBytes(cachedMemory));
        
        text = textBuf.toString();

        var newColor:Int = (currentFPS < FlxG.drawFramerate * 0.5) ? 0xFFFF0000 : 0xFFFFFFFF;
        if (textColor != newColor) {
            textColor = newColor;
        }
    }

    inline function get_memoryMegas():Float {
        #if cpp
        return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
        #else
        return System.totalMemory;
        #end
    }
    
    public function destroy():Void {
        times = null;
    }
}