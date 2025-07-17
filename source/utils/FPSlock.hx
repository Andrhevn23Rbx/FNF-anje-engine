package;

import flixel.FlxG;

class FPSLock {
    
    public static function lock60FPS():Void {
        // Lock the logic and draw framerate to 60 FPS
        FlxG.fixedTimestep = true; // Use fixed timestep mode for consistent timing
        FlxG.updateFramerate = 60; // Game logic FPS
        FlxG.drawFramerate = 60;   // Rendering FPS

        // Set game object framerate if game is initialized
        if (FlxG.game != null) {
            FlxG.game.updateFramerate = 60;
            FlxG.game.drawFramerate = 60;
            FlxG.game.setFramerate(60);
        }

        trace("[FPSLock] FPS locked at 60.");
    }
}
