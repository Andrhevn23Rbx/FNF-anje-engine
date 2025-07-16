package;

import flixel.FlxG;
import flixel.FlxState;

class OutdatedState extends MusicBeatState
{
	public override function create()
	{
		// Instantly skip to MainMenuState
		FlxG.switchState(new MainMenuState());
	}

	public override function update(elapsed:Float)
	{
		// Do nothing since we're skipping the whole state
	}
}
