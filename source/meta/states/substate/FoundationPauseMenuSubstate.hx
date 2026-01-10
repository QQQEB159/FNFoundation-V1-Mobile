package meta.states.substate;

import flixel.util.FlxSpriteUtil;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.mouse.FlxMouseEvent;
import flixel.addons.transition.FlxTransitionableState;

class FoundationPauseMenuSubstate extends MusicBeatSubstate
{
	public static var renderOverride:String = null;

	var render:FlxSprite;
	var buttons:Array<FlxSprite> = [];
	var arrow:FlxSprite;

	var cam:FlxCamera;

	var curSelected:Int = 0;

	override function create()
	{
		super.create();

		Paths.forceCaching = false;

		cam = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		cameras = [cam];

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.alpha = 1;
		bg.screenCenter(XY);
		bg.scrollFactor.set();
		add(bg);

		FlxTween.tween(bg, {alpha: 0.9}, 1);

		if (renderOverride == null)
			renderOverride = PlayState.SONG.song.toLowerCase();
		render = new FlxSprite(FlxG.width - 800, 150).loadGraphic(Paths.image('renders/' + renderOverride));
		render.antialiasing = ClientPrefs.globalAntialiasing;
		render.scale.set(0.75, 0.75);
		render.updateHitbox();
		add(render);

		createButtons();

		arrow = new FlxSprite(30).loadGraphic(Paths.image("menu/pause/pauseArrow"));
		arrow.antialiasing = ClientPrefs.globalAntialiasing;
		arrow.scale.set(0.5, 0.5);
		arrow.updateHitbox();
		add(arrow);

		addTouchPad("UP_DOWN", "A");
		addTouchPadCamera();
		
		changeOption(0, true);
	}

	override function destroy()
	{
		renderOverride = null;
		Paths.forceCaching = true;
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK)
			close();

		if (controls.UI_UP_P)
			changeOption(-1);
		if (controls.UI_DOWN_P)
			changeOption(1);

		if (controls.ACCEPT)
			selectOption();

		super.update(elapsed);
	}

	private function createButtons()
	{
		var menuOptions = ["Resume", "Restart", "Options", "Quit"];

		if (PlayState.introSequence)
			menuOptions.remove("Quit");

		var i:Int = 0;
		for (option in menuOptions)
		{
			var button = new FlxSprite(100, 200 + 100 * i);
			button.frames = Paths.getSparrowAtlas('menu/pause/pauseshit');
			button.animation.addByPrefix("idle", option + "0", 1);
			button.animation.addByPrefix("select", option + "_select", 1);
			button.animation.play("idle", true);

			button.scale.set(0.5, 0.5);
			button.updateHitbox();
			add(button);
			buttons.push(button);

			i += 1;
		}
	}

	private function changeOption(delta:Int = 0, ?first:Bool = false)
	{
		curSelected += delta;
		if (curSelected > buttons.length-1)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = buttons.length-1;

		arrow.y = buttons[curSelected].y + 10;

		for (button in buttons)
		{
			FlxSpriteUtil.setBrightness(button, 0);
			// button.animation.play("idle", true);
			// button.updateHitbox();
		}
		FlxSpriteUtil.setBrightness(buttons[curSelected], 1);
		// buttons[curSelected].animation.play("select", true);
		// buttons[curSelected].updateHitbox();
	}

	private function selectOption()
	{
		switch (curSelected)
		{
			case 0:
				close();
			case 1:
				restartSong();
			case 2:
				PlayState.instance.paused = true;
				PlayState.instance.vocals.volume = 0;
				FoundationOptionsState.exitState = PlayState;
				FlxG.switchState(new FoundationOptionsState());
			case 3:
				FoundationGameOverSubstate.videoOverride = "";
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				PlayState.explainedMechanic = false;
				Init.SwitchToPrimaryMenu(FoundationDesktopState);
				PlayState.cancelMusicFadeTween();
				FlxG.sound.playMusic(Paths.music(KUTValueHandler.getMenuMusic()));
				FlxG.sound.music.volume = 0.7;
				PlayState.changedDifficulty = false;
				PlayState.chartingMode = false;
		}
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if (noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			MusicBeatState.resetState();
		}
	}
}
