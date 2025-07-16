package;

import flixel.input.keyboard.FlxKey;

class StartupState extends MusicBeatState
{
	override public function create():Void
	{
		// Skip all splash screens, just switch to TitleState after a small delay to avoid hard cut
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		new FlxTimer().start(0.05, function(tmr:FlxTimer) {
			FlxG.switchState(new TitleState());
		});

		super.create();
	}

	override function update(elapsed:Float)
	{
		// Optionally allow ENTER to skip the delay
		if (FlxG.keys.justPressed.ENTER)
			FlxG.switchState(new TitleState());

		super.update(elapsed);
	}
}

