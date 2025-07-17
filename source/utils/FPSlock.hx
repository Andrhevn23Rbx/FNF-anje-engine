package;

import flixel.FlxG;

class FPSLock {
    
    public static function lock60FPS():Void {
        // Set draw and update framerate to 60 FPS
        FlxG.drawFramerate = 60;
        FlxG.updateFramerate = 60;
        
        // Fix the elapsed time per frame to 1/60 seconds
        FlxG.elapsed = 1.0 / 60.0;
        FlxG.maxElapsed = 1.0 / 60.0;
        
        // Disable vsync to avoid conflicts with frame limiting
        FlxG.vsync = false;
        
        // Also set game object framerates if available
        if (FlxG.game != null) {
            FlxG.game.drawFramerate = 60;
            FlxG.game.updateFramerate = 60;
            FlxG.game.frameRate = 60;
            FlxG.game.setFramerate(60);
        }
        
        trace("FPS locked at 60");
    }
}
