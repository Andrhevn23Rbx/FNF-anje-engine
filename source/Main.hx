package;

import backend.SSPlugin as ScreenShotPlugin;
import debug.FPSCounter;
import flixel.FlxGame;
import flixel.FlxG;
import flixel.util.FlxColor;
import lime.app.Application;
import openfl.Lib;
import openfl.display.Sprite;

using StringTools;

#if (linux || mac)
import lime.graphics.Image;
#end

#if desktop
import backend.ALSoftConfig; // Keep this for DCE protection
#end

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

class Main extends Sprite {
	final game = {
		width: 1280,
		height: 720,
		initialState: InitState.new,
		zoom: -1.0,
		framerate: 60,
		skipSplash: true,
		startFullscreen: false
	};

	public static var fpsVar:FPSCounter;

	public static function main():Void {
		Lib.current.addChild(new Main());
	}

	public function new() {
		super();

		#if windows
		@:functionCode('
		#include <Windows.h>
		SetProcessDPIAware();
		')
		#end

		CrashHandler.init();
		setupGame();
	}

	private function setupGame():Void {
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0) {
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		ClientPrefs.loadDefaultStuff();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		final funkinGame:FlxGame = new FlxGame(
			game.width, game.height, game.initialState, 
			#if (flixel < "5.0.0") game.zoom, #end
			game.framerate, game.framerate, game.skipSplash, game.startFullscreen
		);

		addChild(funkinGame);

		// FPS Counter
		fpsVar = new FPSCounter(3, 3, 0xFFFFFFFF);
		fpsVar.visible = ClientPrefs.showFPS;
		addChild(fpsVar);

		// === 60 FPS LOCK ===
		FlxG.fixedTimestep = true;            // Lock logic updates to 60 FPS
		FlxG.updateFramerate = game.framerate; // 60 logic FPS
		FlxG.drawFramerate = game.framerate;   // 60 render FPS
		FlxG.vsync = false;                   // Disable vsync to prevent double frame locks

		// === PLUGINS ===
		#if (!web && flixel < "5.5.0")
		FlxG.plugins.add(new ScreenShotPlugin());
		#elseif (flixel >= "5.6.0")
		FlxG.plugins.addIfUniqueType(new ScreenShotPlugin());
		#end

		// Prevent auto-pause when focus is lost
		FlxG.autoPause = false;

		// === PLATFORM-SPECIFIC ===
		#if (linux || mac)
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if windows
		WindowColorMode.setDarkMode();
		if (CoolUtil.hasVersion("Windows 10"))
			WindowColorMode.redrawWindowHeader();
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		// === Handle Resize ===
		FlxG.signals.gameResized.add(function(w, h) {
			if (FlxG.cameras != null) {
				for (cam in FlxG.cameras.list) {
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}
			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	public static function changeFPSColor(color:FlxColor) {
		fpsVar.textColor = color;
	}
}
