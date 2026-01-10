package meta.states;

import meta.data.ProgressUtils;
import flixel.util.FlxSpriteUtil;
import flixel.addons.transition.FlxTransitionSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.transition.FlxTransitionableState;
import meta.states.substate.desktop.*;
import flixel.group.FlxSpriteGroup;
import meta.states.FoundationOfficeState;
import meta.states.substate.MusicBeatSubstate;
import meta.data.options.OptionsState;
import flixel.input.mouse.FlxMouseEvent;

class FoundationDesktopState extends MusicBeatState
{
	public var blackout:FlxSprite;

	var introBlackoutTween:FlxTween;

	var bg:FlxSprite;
	var glass:FlxSprite;
	var taskbar:FlxSprite;

	var iconFrames:FlxAtlasFrames;

	var footageIcon:FlxSprite;
	var quitIcon:FlxSprite;
	var optionsIcon:FlxSprite;
	var resetSaveIcon:FlxSprite;
	var quizIcon:FlxSprite;
	var creditsIcon:FlxSprite;

	var footageName:FlxText;
	var quitName:FlxText;
	var optionsName:FlxText;
	var resetSaveName:FlxText;
	var quizName:FlxText;
	var creditsName:FlxText;

	var icons:Array<FlxSprite> = [];
	var names:Array<FlxText> = [];

	var newIcon:FlxSprite;

	var taskbarCamera:FlxCamera;

	var windows:Array<FoundationDesktopBaseWindow> = [];

	override public function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.updatePresence(null, "In the desktop");
		#end

		persistentDraw = persistentUpdate = true;

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		Paths.forceCaching = false; // Disable GPU caching since it makes it impossible to use mouse events

		FlxG.mouse.visible = true;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

		iconFrames = Paths.getSparrowAtlas("menu/desktopnew/desktopapps");

		taskbarCamera = new FlxCamera();
		taskbarCamera.bgColor.alpha = 0;
		FlxG.cameras.add(taskbarCamera, false);

		createSprites();
		createNames();
		createInteractivity();

		blackout = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		add(blackout);

		introBlackoutTween = FlxTween.tween(blackout, {"alpha": 0}, 0.5);

		// var ad:FoundationDesktopAdWindow = new FoundationDesktopAdWindow(50, 50);
		// add(ad);
	}

	override function destroy()
	{
		Paths.forceCaching = true;

		FlxG.mouse.visible = false;
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed)
			FlxG.sound.play(Paths.sound("desktop/sClick"), 2);
		if (FlxG.keys.justPressed.ANY)
		{
			if (FlxG.keys.justPressed.SPACE)
				FlxG.sound.play(Paths.sound("desktop/sKeyboardSpace"));
			else
				FlxG.sound.play(Paths.sound("desktop/sKeyboard" + Std.string(FlxG.random.int(0, 4))));
		}

		if (controls.BACK #if android || FlxG.android.justReleased.BACK #end)
		{
			if (introBlackoutTween.active)
				introBlackoutTween.manager.completeAll();
			for (window in windows) {
				FlxTween.tween(window, {"alpha": 0}, 0.1);
			}
			FlxTween.tween(blackout, {"alpha": 1}, 0.5, {
				onComplete: (twn:FlxTween) ->
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					FoundationOfficeState.comingFromDesktop = true;
					FlxG.switchState(new FoundationOfficeState());
				}
			});
		}
	}

	private function createInteractivity()
	{
		for (icon in icons)
		{
			FlxMouseEvent.add(icon, onIconPress, null, onIconHover, onIconUnhover, false, true, false);
		}
	}

	private function createSprites()
	{
		bg = new FlxSprite().loadGraphic(Paths.image('menu/desktopnew/BGs/BG' + Std.string(FlxG.random.int(1, 5))));
		bg.antialiasing = false;
		bg.scale.set(0.7, 0.7);
		bg.updateHitbox();

		glass = new FlxSprite().loadGraphic(Paths.image('menu/desktopnew/Layer1'));
		glass.antialiasing = ClientPrefs.globalAntialiasing;
		glass.scale.set(0.7, 0.7);
		glass.updateHitbox();

		taskbar = new FlxSprite(0, -35).loadGraphic(Paths.image('menu/desktopnew/Layer2'));
		taskbar.antialiasing = false;
		taskbar.scale.set(0.7, 0.7);
		taskbar.updateHitbox();
		taskbar.cameras = [taskbarCamera];

		footageIcon = new FlxSprite(50, 50);
		footageIcon.frames = iconFrames;
		footageIcon.animation.addByPrefix('idle', 'entries0', 1);
		footageIcon.animation.addByPrefix('select', 'entries0', 1); // FIXME: the animation offsets again bruh
		footageIcon.animation.addByPrefix('click', 'entriesclick', 24, false);
		footageIcon.animation.play('idle', true);
		footageIcon.scale.set(0.65, 0.65);
		footageIcon.updateHitbox();
		footageIcon.ID = 0;
		icons.push(footageIcon);

		quitIcon = new FlxSprite(FlxG.width - 150, 200);
		quitIcon.frames = iconFrames;
		quitIcon.animation.addByPrefix('idle', 'quit', 1);
		quitIcon.animation.addByPrefix('select', 'quit', 1); // FIXME: the animation offsets again bruh
		quitIcon.animation.addByPrefix('click', 'clickquit', 24, false);
		quitIcon.animation.play('idle', true);
		quitIcon.scale.set(0.75, 0.75);
		quitIcon.updateHitbox();
		quitIcon.ID = 1;
		icons.push(quitIcon);

		optionsIcon = new FlxSprite(30, 200);
		optionsIcon.frames = iconFrames;
		optionsIcon.animation.addByPrefix('idle', 'settings', 1, true);
		optionsIcon.animation.addByPrefix('select', 'settings', 1, true); // FIXME: the animation offsets again bruh
		optionsIcon.animation.addByPrefix('click', 'clicksettings', 24);
		optionsIcon.animation.play('idle', true);
		optionsIcon.scale.set(0.75, 0.75);
		optionsIcon.updateHitbox();
		optionsIcon.ID = 2;
		icons.push(optionsIcon);

		resetSaveIcon = new FlxSprite(FlxG.width - 140, 350);
		resetSaveIcon.frames = iconFrames;
		resetSaveIcon.animation.addByPrefix('idle', 'del_save0', 1);
		resetSaveIcon.animation.addByPrefix('select', 'del_save0', 1); // FIXME: the animation offsets again bruh
		resetSaveIcon.animation.addByPrefix('click', 'del_saveclick', 24, false);
		resetSaveIcon.animation.play('idle', true);
		resetSaveIcon.scale.set(0.75, 0.75);
		resetSaveIcon.updateHitbox();
		resetSaveIcon.ID = 3;
		icons.push(resetSaveIcon);

		quizIcon = new FlxSprite(FlxG.width / 2 - 150, 350);
		quizIcon.frames = iconFrames;
		quizIcon.animation.addByPrefix('idle', 'notes0', 1);
		quizIcon.animation.addByPrefix('select', 'notes0', 1); // FIXME: the animation offsets again bruh
		quizIcon.animation.addByPrefix('click', 'clicknotes', 24, false);
		quizIcon.animation.play('idle', true);
		quizIcon.scale.set(0.75, 0.75);
		quizIcon.updateHitbox();
		quizIcon.ID = 4;
		if (ProgressUtils.isQuizUnlocked())
			icons.push(quizIcon);

		creditsIcon = new FlxSprite(50, 350);
		creditsIcon.frames = iconFrames;
		creditsIcon.animation.addByPrefix('idle', 'footage0', 1);
		creditsIcon.animation.addByPrefix('select', 'footage0', 1); // FIXME: the animation offsets again bruh
		creditsIcon.animation.addByPrefix('click', 'clickfootage', 24, false);
		creditsIcon.animation.play('idle', true);
		creditsIcon.scale.set(0.75, 0.75);
		creditsIcon.updateHitbox();
		creditsIcon.ID = 5;
		if (ProgressUtils.isFreeplayUnlocked())
			icons.push(creditsIcon);

		add(bg);

		for (icon in icons)
		{
			icon.antialiasing = false;
			add(icon);
		}

		newIcon = new FlxSprite(footageIcon.x + 50, footageIcon.y - 15).loadGraphic(Paths.image("menu/desktopnew/new"));
		newIcon.scale.set(0.25, 0.25);
		newIcon.updateHitbox();
		if (ProgressUtils.isFreeplayUnlocked() && !FlxG.save.data.foundation.unlockedFreeplay)
			add(newIcon);

		if (ProgressUtils.isQuizUnlocked() && !FlxG.save.data.foundation.doneQuiz)
		{
			newIcon.setPosition(quizIcon.x + 50, quizIcon.y - 15);
			add(newIcon);
		}

		add(glass);
		add(taskbar);
	}

	private function createNames()
	{
		footageName = new FlxText(footageIcon.x - 15, footageIcon.y + 100);
		footageName.antialiasing = false;
		footageName.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
		footageName.text = "Footage";
		add(footageName);

		quitName = new FlxText(quitIcon.x + 20, quitIcon.y + 115);
		quitName.antialiasing = false;
		quitName.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
		quitName.text = "Quit";
		add(quitName);

		optionsName = new FlxText(optionsIcon.x, optionsIcon.y + 105);
		optionsName.antialiasing = false;
		optionsName.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
		optionsName.text = "Settings";
		add(optionsName);

		resetSaveName = new FlxText(resetSaveIcon.x - 30, resetSaveIcon.y + 125);
		resetSaveName.antialiasing = false;
		resetSaveName.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
		resetSaveName.text = "Reset Data";
		add(resetSaveName);

		if (ProgressUtils.isQuizUnlocked())
		{
			quizName = new FlxText(quizIcon.x, quizIcon.y + 125);
			quizName.antialiasing = false;
			quizName.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
			quizName.text = "Survey";
			add(quizName);
		}

		if (ProgressUtils.isFreeplayUnlocked())
		{
			creditsName = new FlxText(creditsIcon.x - 5, creditsIcon.y + 110);
			creditsName.antialiasing = false;
			creditsName.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
			creditsName.text = "Credits";
			add(creditsName);
		}
	}

	private function onIconPress(icon:FlxSprite)
	{
		icon.animation.play("click", true);
		icon.animation.finishCallback = (name) ->
		{
			icon.animation.play("select", true);
		};
		switch (icon.ID)
		{ // legendary hack in the fnf scene which i hate with burning passion but fuck is it useful -xeight
			case 0: // Footage
				var window = new FoundationDesktopFootageWindow(250, 100);
				windows.push(window);
				add(window);
				newIcon.visible = false;

				// if you have story progress and you go in instantly ask if you want to continue
					// removed almost instantly for being a bit too annoying -xeight
				// if (FlxG.save.data.foundation.storyProgress != null && FlxG.save.data.foundation.storyProgress > 0 && FlxG.save.data.foundation.storyProgress < 10) {
				// 	var contWindow = new FoundationDesktopContinueWindow(350, 200);
				// 	windows.push(contWindow);
				// 	add(contWindow);
				// }
			case 1: // Quit
				var window = new FoundationDesktopQuitSubstate(250, 100);
				windows.push(window);
				add(window);
			case 2: // Options
				if (introBlackoutTween.active)
					introBlackoutTween.manager.completeAll();
				FlxTween.tween(blackout, {"alpha": 1}, 0.5, {
					onComplete: (twn:FlxTween) ->
					{
						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;

						FoundationOptionsState.exitState = FoundationDesktopState;
						FlxG.switchState(new FoundationOptionsState());
					}
				});
			case 3: // Reset saves
				var window = new FoundationDesktopResetSaveWindow(250, 100);
				windows.push(window);
				add(window);
			case 4:
				if (introBlackoutTween.active)
					introBlackoutTween.manager.completeAll();
				FlxTween.tween(blackout, {"alpha": 1}, 0.5, {
					onComplete: (twn:FlxTween) ->
					{
						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;

						FlxG.switchState(new FoundationNewQuizState());
					}
				});
			case 5:
				if (introBlackoutTween.active)
					introBlackoutTween.manager.completeAll();
				FlxTween.tween(blackout, {"alpha": 1}, 0.5, {
					onComplete: (twn:FlxTween) ->
					{
						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;

						FlxG.switchState(new CutsceneState("credits"));
					}
				});
		}
		// trace("icon pressed!");
	}

	private function onIconHover(icon:FlxSprite)
	{
		// trace("icon hovered!");
		FlxSpriteUtil.setBrightness(icon, 0.25);
		icon.animation.play('select', true);
	}

	private function onIconUnhover(icon:FlxSprite)
	{
		// trace("icon unhovered!");
		FlxSpriteUtil.setBrightness(icon, 0);
		icon.animation.play('idle', true);
	}
}

class FoundationDesktopBaseWindow extends FlxTypedSpriteGroup<FlxSprite>
{
	var window:FlxSprite;
	var windowTitle:FlxText;
	var closeButton:FlxSprite;

	var moving:Bool = false;
	var moveOffset:FlxPoint;

	public function new(x:Float = 250, y:Float = 100)
	{
		super(x, y);
		// group.scale.set(0.5, 0.5);
		// group.alpha = 0.35;
		// FlxTween.tween(group, {"alpha": 1}, 0.75, {ease: FlxEase.quartOut});
		// function doUpdate(tween:FlxTween) {
		//     group.updateHitbox();
		// }
		// FlxTween.tween(group.scale, {"x": 1, "y": 1}, 0.35, {ease: FlxEase.quartOut, onUpdate: doUpdate});

		window = new FlxSprite().loadGraphic(Paths.image('menu/desktopnew/basewindow'));
		window.antialiasing = false;
		window.scale.set(0.75, 0.75);
		window.updateHitbox();
		// window.alpha = 0;
		add(window);

		windowTitle = new FlxText(35, 30);
		windowTitle.antialiasing = false;
		windowTitle.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		// group.add(windowTitle);

		closeButton = new FlxSprite(625, 20);
		closeButton.antialiasing = false;
		closeButton.frames = Paths.getSparrowAtlas('menu/desktopnew/basewindowbuttons');
		closeButton.animation.addByPrefix("idle", "basewindow_close", 1, true);
		closeButton.animation.addByPrefix("select", "basewindow_closeclick", 1, true);
		closeButton.scale.set(0.5, 0.5);
		closeButton.updateHitbox();
		add(closeButton);

		FlxMouseEvent.add(window, (sprite:FlxSprite) ->
		{
			moving = true;
			moveOffset = new FlxPoint(FlxG.mouse.x - sprite.x, FlxG.mouse.y - sprite.y);
		}, (sprite:FlxSprite) ->
			{
				moving = false;
			}, null, (sprite:FlxSprite) ->
			{
				moving = false;
			});

		FlxMouseEvent.add(closeButton, (sprite:FlxSprite) ->
		{
			remove(this);
			destroy();
		}, null, (sprite:FlxSprite) ->
			{
				FlxSpriteUtil.setBrightness(sprite, 0.25);
			}, (sprite:FlxSprite) ->
			{
				FlxSpriteUtil.setBrightness(sprite, 0);
				// if (sprite != null) sprite.animation.play("idle", true); // Causes a crash when closing the substate
			});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (moving)
		{
			var newPos = new FlxPoint(FlxG.mouse.x, FlxG.mouse.y);
			newPos -= moveOffset;
			this.setPosition(newPos.x, newPos.y);
		}

		// if (FlxG.mouse.justPressed) FlxG.sound.play(Paths.sound("desktop/click"));
	}
}
