package meta.states;

import meta.data.PlayerSettings;
import flixel.addons.display.FlxPieDial;
import gameObjects.PsychVideoSprite;

class CutsceneState extends MusicBeatState
{
	var vid:String;
	var vidEndCallback:() -> Void;

	final _timeToSkip:Float = 1;

	public var holdingTime:Float = 0;
	public var skipSprite:FlxPieDial;

	var videoSprite:PsychVideoSprite;
    var canSkip:Bool = true;

	public function new(vid:String, canSkip:Bool = true)
	{
		super();

		this.vid = vid;
        this.canSkip = true;
		// this.vidEndCallback = () -> {
        //     FlxG.switchState(new meta.states.FoundationOfficeState());
        // };
	}

	override function create()
	{
		super.create();

		if (FlxG.sound.music != null)
            FlxG.sound.music.stop();

		videoSprite = new PsychVideoSprite();
		videoSprite.addCallback('onFormat', () ->
		{
			videoSprite.scale.set(0.7, 0.7);
			videoSprite.updateHitbox();
			videoSprite.screenCenter();
		});
		videoSprite.addCallback('onEnd', () ->
		{
			FlxG.sound.music.stop();
			FlxG.sound.music = null;
			FlxG.switchState(new meta.states.FoundationOfficeState());
			videoSprite.kill();
		});
		videoSprite.load(Paths.video(vid));
		videoSprite.antialiasing = true;
		add(videoSprite);

		videoSprite.play();

		skipSprite = new FlxPieDial(0, 0, 40, FlxColor.WHITE, 40, true, 24);
		skipSprite.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);
		skipSprite.x = FlxG.width - (skipSprite.width + 80);
		skipSprite.y = FlxG.height - (skipSprite.height + 72);
		skipSprite.amount = 0;
		add(skipSprite);
		
		addTouchPad("NONE", "A");
		addTouchPadCamera();
	}

	override function update(elapsed:Float)
	{
        super.update(elapsed);

        if (!canSkip) return;

		if (PlayerSettings.player1.controls.ACCEPT_HOLD)
		{
			holdingTime = Math.max(0, Math.min(_timeToSkip, holdingTime + elapsed));
		}
		else if (holdingTime > 0)
		{
			holdingTime = Math.max(0, FlxMath.lerp(holdingTime, -0.1, FlxMath.bound(elapsed * 3, 0, 1)));
		}
		updateSkipAlpha();

		if (holdingTime >= _timeToSkip)
		{
			videoSprite.bitmap.onEndReached.dispatch();
			trace('Skipped video');
			return;
		}
	}

	function updateSkipAlpha()
	{
		if (skipSprite == null)
			return;

		skipSprite.amount = Math.min(1, Math.max(0, (holdingTime / _timeToSkip) * 1.025));
		skipSprite.alpha = FlxMath.remapToRange(skipSprite.amount, 0.025, 1, 0, 1);
	}
}
