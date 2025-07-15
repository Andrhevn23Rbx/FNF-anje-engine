package debug;

import flixel.FlxG;
import flixel.util.FlxStringUtil;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import haxe.Timer;
import cpp.vm.Gc;

class FPSCounter extends TextField
{
	// Current displayed FPS
	public var currentFPS(default, null):Float;

	// Memory info: current and peak (bytes)
	inline public var memory(get, never):Float;
	inline function get_memory():Float
		return Gc.memInfo64(Gc.MEM_INFO_USAGE); // Current usage

	inline public var memPeak(get, never):Float;
	inline function get_memPeak():Float
		return Gc.memInfo64(Gc.MEM_INFO_PEAK); // Peak usage

	@:noCompletion private var times:Array<Float>;

	// FPS multiplier (used to adjust FPS display depending on playbackRate or similar)
	private var fpsMultiplier:Float = 1.0;

	// Time accumulator to limit updates for performance
	private var deltaTimeout:Float = 0.0;

	// Delay between updates in milliseconds
	public var timeoutDelay:Float = 50;

	// For rainbow FPS color cycling (degrees)
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

		// Remove old timestamps older than 1 second / fpsMultiplier
		while (times.length > 0 && times[0] < now - 1000 / fpsMultiplier)
			times.shift();

		// Delay updates to improve performance
		if (deltaTimeout < timeoutDelay)
		{
			deltaTimeout += deltaTime;
			return;
		}

		// Attempt to get playbackRate from PlayState if available (default to 1.0)
		if (Std.isOfType(FlxG.state, PlayState) && !PlayState.instance.trollingMode)
		{
			try { fpsMultiplier = PlayState.instance.playbackRate; }
			catch (e:Dynamic) { fpsMultiplier = 1.0; }
		}
		else fpsMultiplier = 1.0;

		// Calculate FPS
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
			if (ClientPrefs.showMaxRamUsage)
				text += " / " + FlxStringUtil.formatBytes(memPeak);
		}

		if (ClientPrefs.debugInfo)
		{
			text += '\nCurrent state: ${Type.getClassName(Type.getClass(FlxG.state))}';
			if (FlxG.state.subState != null)
				text += '\nCurrent substate: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';
			#if !linux
				text += "\nOS: " + '${System.platformLabel} ${System.platformVersion}';
			#end
		}

		// Handle rainbow FPS color effect
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
