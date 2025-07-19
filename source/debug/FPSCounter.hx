package debug;

import flixel.FlxG;
import flixel.util.FlxStringUtil;
import flixel.input.keyboard.FlxKey;
import lime.system.System as LimeSystem;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.KeyboardEvent;
import haxe.Timer;
import cpp.vm.Gc;

#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end

class FPSCounter extends TextField
{
    public static var instance:FPSCounter;
    public var currentFPS(default, null):Float;

    private var times:Array<Float>;
    private var deltaTimeout:Float = 0.0;
    private var timeoutDelay:Float = 50;
    private var colorTimer:Float = 0.0;

    public var os:String = '';

    public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFF)
    {
        super();
        instance = this;

        this.x = x;
        this.y = y;

        selectable = false;
        mouseEnabled = false;
        defaultTextFormat = new TextFormat("_sans", 14, color);
        autoSize = LEFT;
        multiline = true;

        times = [];
        currentFPS = 0;

        // OS Info
        if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
            os = 'OS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != "Unknown" ? getArch() : ""}' #end;
        else
            os = 'OS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != "Unknown" ? getArch() : ""}' #end + ' - ${LimeSystem.platformVersion}';

        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);

        text = "FPS: ";
    }

    override function __enterFrame(deltaTime:Float):Void
    {
        if (!ClientPrefs.showFPS) return;

        var now = Timer.stamp() * 1000;
        times.push(now);

        while (times.length > 0 && times[0] < now - 1000)
            times.shift();

        deltaTimeout += deltaTime;
        if (deltaTimeout < timeoutDelay) return;

        currentFPS = times.length;
        updateText();

        deltaTimeout = 0.0;
    }

    public dynamic function updateText():Void
    {
        var displayFPS = ClientPrefs.ffmpegMode ? ClientPrefs.targetFPS : Math.round(currentFPS);
        text = 'FPS: $displayFPS';

        if (ClientPrefs.ffmpegMode)
            text += ' (Rendering Mode)';
        else
            text += ' - ${FlxG.vsync ? "VSync" : "No VSync"}';

        if (ClientPrefs.showRamUsage)
        {
            var usedMem = FlxStringUtil.formatBytes(Gc.memInfo64(Gc.MEM_INFO_USAGE));
            text += '\nMemory: $usedMem';
        }

        if (ClientPrefs.debugInfo)
            text += '\n' + os;

        if (ClientPrefs.rainbowFPS)
        {
            colorTimer = (colorTimer % 360.0) + (1.0 / (ClientPrefs.framerate / 120));
            textColor = FlxColor.fromHSB(colorTimer, 1, 1);
        }
        else
        {
            var half = ClientPrefs.framerate / 2;
            var third = ClientPrefs.framerate / 3;
            var quarter = ClientPrefs.framerate / 4;

            if (currentFPS <= half && currentFPS >= third)
                textColor = 0xFFFFFF00; // Yellow
            else if (currentFPS <= third && currentFPS >= quarter)
                textColor = 0xFFFF8000; // Orange
            else if (currentFPS <= quarter)
                textColor = 0xFFFF0000; // Red
            else
                textColor = 0xFFFFFFFF; // White
        }
    }

    private function onKeyPress(event:KeyboardEvent):Void
    {
        if (event.keyCode == FlxKey.F11)
            FlxG.fullscreen = !FlxG.fullscreen;
    }

    #if cpp
    #if windows
    @:functionCode('
        SYSTEM_INFO osInfo;
        GetSystemInfo(&osInfo);
        switch(osInfo.wProcessorArchitecture)
        {
            case 9: return ::String("x86_64");
            case 5: return ::String("ARM");
            case 12: return ::String("ARM64");
            case 6: return ::String("IA-64");
            case 0: return ::String("x86");
            default: return ::String("Unknown");
        }
    ')
    #elseif (ios || mac)
    @:functionCode('
        const NXArchInfo *archInfo = NXGetLocalArchInfo();
        return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
    ')
    #else
    @:functionCode('
        struct utsname osInfo{};
        uname(&osInfo);
        return ::String(osInfo.machine);
    ')
    #end
    @:noCompletion
    private function getArch():String
    {
        return "Unknown";
    }
    #end
}
