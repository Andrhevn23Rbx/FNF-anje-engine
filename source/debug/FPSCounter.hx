package debug;

import flixel.FlxG;
import flixel.util.FlxStringUtil;
import openfl.text.TextField;
import openfl.text.TextFormat;
import haxe.Timer;
import cpp.vm.Gc;

class FPSCounter extends TextField
{
    public var currentFPS(default, null):Float;

    // Only current memory usage is available
    public var memory(get, never):Float;

    inline function get_memory():Float
        return Gc.memInfo64(Gc.MEM_INFO_USAGE);

    @:noCompletion private var times:Array<Float>;

    private var fpsMultiplier:Float = 1.0;
    private var deltaTimeout:Float = 0.0;
    public var timeoutDelay:Float = 50;
    private var timeColor:Float = 0.0;

    public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
    {
        super();
        this.x = x;
        this.y = y;

        currentFPS = 0;
        selectable = false;
        mouseEnabled = false;
        defaultTextFormat = new TextFormat("_sans", 14, color);
        autoSize = LEFT;
        multiline = true;
        text = "FPS: ";

        times = [];
    }

    override function __enterFrame(deltaTime:Float):Void
    {
        if (!ClientPrefs.showFPS) return;

        var now = Timer.stamp() * 1000;
        times.push(now);

        while (times.length > 0 && times[0] < now - 1000 / fpsMultiplier)
            times.shift();

        if (deltaTimeout < timeoutDelay)
        {
            deltaTimeout += deltaTime;
            return;
        }

        if (Std.isOfType(FlxG.state, PlayState) && !PlayState.instance.trollingMode)
        {
            try { fpsMultiplier = PlayState.instance.playbackRate; }
            catch (e:Dynamic) { fpsMultiplier = 1.0; }
        }
        else fpsMultiplier = 1.0;

        currentFPS = Math.min(FlxG.drawFramerate, times.length) / fpsMultiplier;

        updateText();

        deltaTimeout = 0.0;
    }

    public dynamic function updateText():Void
    {
        text = "FPS: " + (ClientPrefs.ffmpegMode ? ClientPrefs.targetFPS : Math.round(currentFPS));

        if (ClientPrefs.ffmpegMode)
            text += " (Rendering Mode)";

        if (ClientPrefs.showRamUsage)
        {
            text += "\nMemory: " + FlxStringUtil.formatBytes(memory);
            // no peak memory info available
        }

        if (ClientPrefs.debugInfo)
        {
            text += '\nCurrent state: ${Type.getClassName(Type.getClass(FlxG.state))}';
            if (FlxG.state.subState != null)
                text += '\nCurrent substate: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';

            // Remove or comment out OS info because OpenFL System lacks those fields
            // #if !linux
            // text += "\nOS: " + 'Unknown OS';
            // #end
        }

        if (ClientPrefs.rainbowFPS)
        {
            timeColor = (timeColor % 360.0) + (1.0 / (ClientPrefs.framerate / 120));
            textColor = FlxColor.fromHSB(timeColor, 1, 1);
        }
        else if (!ClientPrefs.ffmpegMode)
        {
            textColor = 0xFFFFFFFF;

            var halfFPS = ClientPrefs.framerate / 2;
            var thirdFPS = ClientPrefs.framerate / 3;
            var quarterFPS = ClientPrefs.framerate / 4;

            if (currentFPS <= halfFPS && currentFPS >= thirdFPS)
                textColor = 0xFFFFFF00; // Yellow
            else if (currentFPS <= thirdFPS && currentFPS >= quarterFPS)
                textColor = 0xFFFF8000; // Orange
            else if (currentFPS <= quarterFPS)
                textColor = 0xFFFF0000; // Red
        }
    }
}
