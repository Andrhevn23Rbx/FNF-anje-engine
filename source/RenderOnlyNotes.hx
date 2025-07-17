package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import Song;
import Conductor;
import haxe.Json;
import sys.io.File;

class RenderOnlyNotes extends FlxGroup
{
    public var fakeNotes:Array<FakeNote> = [];

    public function new(songFile:String)
    {
        super();

        loadChart(songFile);
    }

    public function loadChart(songFile:String):Void
    {
        // Load song JSON from file
        var rawJson:String = File.getContent(songFile);
        var songData:Dynamic = Json.parse(rawJson);

        var song:SwagSong = Song.parseJSONSong(rawJson);

        // Loop through notes
        for (section in song.notes)
        {
            for (note in section.sectionNotes)
            {
                var strumTime:Float = note[0];
                var noteData:Int = Std.int(note[1]);
                var mustPress:Bool = section.mustHitSection;

                if (mustPress) // Only render player's side
                {
                    fakeNotes.push(new FakeNote(strumTime, noteData));
                }
            }
        }
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        for (note in fakeNotes)
        {
            // Simple scroll down like FNF notes
            var centerY:Float = FlxG.height / 2;
            var speed:Float = 0.45; // Adjust scroll speed if needed

            note.sprite.y = centerY + (note.strumTime - Conductor.songPosition) * speed;

            // Optional: Hide notes when off screen
            if (note.sprite.y > FlxG.height + 100)
            {
                note.sprite.visible = false;
            }
            else
            {
                note.sprite.visible = true;
            }
        }

        // Example input: SPACE hits all notes
        if (FlxG.keys.justPressed.SPACE)
        {
            checkForHits();
        }
    }

    public function checkForHits():Void
    {
        var hitWindow:Float = 100;

        for (note in fakeNotes)
        {
            if (note.hit) continue;

            var diff = Math.abs(Conductor.songPosition - note.strumTime);

            if (diff <= hitWindow)
            {
                note.hit = true;
                note.sprite.alpha = 0.3; // Fade out on hit

                trace("Hit note at time: " + note.strumTime);
                break;
            }
        }
    }
}

class FakeNote
{
    public var strumTime:Float;
    public var noteData:Int;
    public var sprite:FlxSprite;
    public var hit:Bool = false;

    public function new(strumTime:Float, noteData:Int)
    {
        this.strumTime = strumTime;
        this.noteData = noteData;

        var noteX = 100 + noteData * 112; // Adjust for lane position

        sprite = new FlxSprite(noteX, 0);
        sprite.loadGraphic(Paths.image('NOTE_assets/arrowUP')); // Use your note image
        sprite.scrollFactor.set(0, 0);
    }
}
