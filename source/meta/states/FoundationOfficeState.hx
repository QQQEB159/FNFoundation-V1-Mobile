package meta.states;

import meta.data.ProgressUtils;
import flixel.util.FlxSpriteUtil;
import gameObjects.PsychVideoSprite;
import meta.states.substate.desktop.StickyNoteSubstate;
import meta.states.substate.FoundationInventorySubstate;
import meta.data.ComputerVoicelines;
import flixel.addons.transition.FlxTransitionableState;
import meta.data.WeekData;
import meta.states.editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseEvent;

class FoundationOfficeState extends MusicBeatState
{
	var subtitleCamera:FlxCamera;

	var bg:FlxSprite;
	var table:FlxSprite;

	var hasEasterEgg:Bool = false;
	var easterEgg:FlxSprite;
	var easterEggID:Int = -1;

	var vivi:PsychVideoSprite;

	var leftSideBG:FlxSprite;
	var rightSideBG:FlxSprite;

	var computer:FlxSprite;
	var pcOn:FlxSprite;
	var rizzmaster:FlxSprite;

	public var curiosityStickyNote:FlxSprite;
	public var inventoryStickyNote:FlxSprite;

	var flipTheBirdToThatFuckassClankerThatIHate:FlxSprite;

	var debugKeys:Array<FlxKey>;

	public static var comingFromDesktop:Bool = false;
	public static var doParallax:Bool = true;

	var transitioning:Bool = false;

	public static var inSubstate:Bool = false;
	public static var turnedOn:Bool = false;

	var blackout:FlxSprite;
	var introBlackoutTween:FlxTween;
	var introZoomTween:FlxTween;

	var ambience:FlxSound;
	var onSound:FlxSound;
	var offSound:FlxSound;

	var voicelineHandler:ComputerVoicelines;

	public var idling:Bool = true;

	var idleTimer:Float = 0;

	public static var instance:FoundationOfficeState = null;

	override public function create()
	{
		persistentDraw = persistentUpdate = true;
		instance = this;

		FlxG.save.flush();

		Paths.forceCaching = false; // Disable GPU caching since it makes it impossible to use mouse events

		// Reset the seed again so voicelines are more random
		FlxG.random.resetInitialSeed();

		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		Paths.currentModDirectory = "Foundation";

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if desktop
		// Updating Discord Rich Presence
		if (FlxG.random.int(0, 10) == 0)
			DiscordClient.updatePresence(null, "Having crazy e-sex with 079");
		else
			DiscordClient.updatePresence(null, "Talking to 079");
		#end

		FlxG.camera.zoom = 0.75;
		FlxG.mouse.visible = true;

		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		subtitleCamera = new FlxCamera();
		subtitleCamera.bgColor.alpha = 0;
		FlxG.cameras.add(subtitleCamera, false);

		// createEasterEgg(1);

		createSprites();
		createInteractivity();

		ComputerVoicelines.setup(rizzmaster, this, subtitleCamera);

		blackout = new FlxSprite(-500, -500).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		add(blackout);

		introBlackoutTween = FlxTween.tween(blackout, {"alpha": 0}, 0.5);

		ambience = FlxG.sound.load(Paths.music('office-eerie'), 1, true);
		ambience.play();
		ambience.pause();

		onSound = FlxG.sound.load(Paths.sound('office/s079On'));
		offSound = FlxG.sound.load(Paths.sound('office/s079Off'));

		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('079'), 0.7);

		if (turnedOn)
			turnOn();

		if (comingFromDesktop)
		{
			FlxG.camera.zoom *= 2;
			introZoomTween = FlxTween.tween(FlxG.camera, {"zoom": FlxG.camera.zoom / 2}, 1, {ease: FlxEase.quadOut});
			comingFromDesktop = false;
		}

		if (!turnedOn)
		{
			ambience.fadeIn(1);
			FlxG.sound.music.pause();
		}
		
		addTouchPad("NONE", "A");
		addTouchPadCamera();
	}

	var keycombo:String = "";

	var t:Float = 0;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		t += elapsed;

		if (!FlxG.save.data.foundation.pickedUpCuriositySticky)
			FlxSpriteUtil.setBrightness(curiosityStickyNote, Math.abs(Math.sin(t))/5);

		if (!FlxG.save.data.foundation.pickedUpInventorySticky)
			FlxSpriteUtil.setBrightness(inventoryStickyNote, Math.abs(Math.sin(t))/5);

		if (inSubstate)
			return;

		if (!idling)
			idleTimer += elapsed;

		if (FlxG.keys.justPressed.ANY)
		{
			keycombo += FlxKey.toStringMap[FlxG.keys.firstJustPressed()];
			if (keycombo.contains("VIVI"))
			{
				vivi.visible = true;
				vivi.restart();
				keycombo = "";
			}
		}

		if (idleTimer >= 30)
		{
			var ratio:Float = FlxG.updateFramerate / 60; // Account for higher/lower refresh rates (hopefully) -xeight
			var roll = FlxG.random.int(1, cast 100 * ratio);
			if (roll == 1)
			{
				idleTimer = 0;
				idling = true;
				ComputerVoicelines.flags.push("played_idle");
				ComputerVoicelines.play("Idle" + Std.string(FlxG.random.int(1, 4)));
			}
		}

		if (FlxG.keys.justPressed.Q)
		{
			inSubstate = true;
			openSubState(new FoundationInventorySubstate());
			return;
		}

		if (FlxG.keys.justPressed.ANY)
		{
			if (!FlxG.keys.justPressed.SPACE)
				FlxG.sound.play(Paths.sound("desktop/sKeyboardSpace"));
			else
				FlxG.sound.play(Paths.sound("desktop/sKeyboard" + Std.string(FlxG.random.int(0, 4))));
		}

		if (!turnedOn) // i will not be ignored when i tell you to pause -xeight
			FlxG.sound.music.pause();

		if (!transitioning && doParallax)
		{
			// stole this from another mod sorry not sorry -xeight
			FlxG.camera.scroll.x = FlxMath.lerp(FlxG.camera.scroll.x, (FlxG.mouse.screenX - (FlxG.width / 2) - 500) * 0.015, (1 / 30) * 240 * elapsed);
			FlxG.camera.scroll.y = FlxMath.lerp(FlxG.camera.scroll.y, (FlxG.mouse.screenY - 6 - (FlxG.height / 2) - 300) * 0.015, (1 / 30) * 240 * elapsed);
		}

		if (FlxG.keys.justPressed.E)
		{
			flipTheBirdToThatFuckassClankerThatIHate.animation.play("fuckyou", true);
			flipTheBirdToThatFuckassClankerThatIHate.visible = true;
			flipTheBirdToThatFuckassClankerThatIHate.animation.finishCallback = (name) ->
			{
				flipTheBirdToThatFuckassClankerThatIHate.visible = false;
			}
		}

		if (controls.ACCEPT && !transitioning)
		{
			turnedOn = !turnedOn;
			turnedOn ? turnOn() : turnOff();
		}

		#if desktop
		if (FlxG.keys.anyJustPressed(debugKeys))
		{
			MusicBeatState.switchState(new MasterEditorMenu());
		}
		#end
	}

	override function destroy()
	{
		super.destroy();

		ambience.pause();
		ComputerVoicelines.stop();

		Paths.forceCaching = true;

		FlxG.camera.zoom = 1;
		FlxG.mouse.visible = false;
	}

	private function turnOn()
	{
		turnedOn = true;

		idling = false;

		ambience.fadeOut(3);
		FlxG.sound.music.play();
		if (!comingFromDesktop)
		{
			FlxG.sound.music.fadeIn();
			if (offSound.playing)
				offSound.stop();
			onSound.play();
		}

		bg.animation.play("on");
		leftSideBG.animation.play("on");
		rightSideBG.animation.play("on");
		computer.animation.play("on");
		curiosityStickyNote.animation.play("on");
		inventoryStickyNote.animation.play("on");
		pcOn.visible = true;
		rizzmaster.animation.play("neutral");

		if (hasEasterEgg)
		{
			easterEgg.animation.play("idle_on", true);

			if (easterEggID == 1)
				FlxTween.tween(easterEgg, {"alpha": 0}, 0.5);
		}

		leftSideBG.y += 9; // coverup for the whole thing moving when turning on idk why it does that i fucking hate flixel -xeight

		var shouldPlayFreeplayVoiceline:Bool = (ProgressUtils.isFreeplayUnlocked()
			&& !FlxG.save.data.foundation.unlockedFreeplay);
		var shouldPlayQuizVoiceline:Bool = (ProgressUtils.isQuizUnlocked() && !FlxG.save.data.foundation.doneQuiz);

		if (shouldPlayFreeplayVoiceline)
		{
			new FlxTimer().start(1, (t) ->
			{
				ComputerVoicelines.play("Freeplay");
			});
		}
		else if (shouldPlayQuizVoiceline)
			{
				new FlxTimer().start(1, (t) ->
				{
					ComputerVoicelines.play("Quiz");
				});

				ComputerVoicelines.flags.remove("freeplay_voiceline");
				ComputerVoicelines.neededFreeplay = "";
			}
		else if (!ComputerVoicelines.flags.contains("first_boot_of_the_day"))
			{
				ComputerVoicelines.flags.push("first_boot_of_the_day");
	
				var vlChoice = "MorningBoot1";
	
				var now:Date = Date.now();
				var hours:Int = now.getHours();
				if (hours >= 5 && hours <= 12)
					vlChoice = "MorningBoot" + Std.string(FlxG.random.int(1, 2));
				else if (hours >= 13 && hours <= 21)
					vlChoice = "AfternoonBoot" + Std.string(FlxG.random.int(1, 3));
				else
					vlChoice = "NightBoot" + Std.string(FlxG.random.int(1, 3));
	
				ComputerVoicelines.play(vlChoice);
			}
		else
		{
			new FlxTimer().start(1, (t) ->
			{
				if (turnedOn && ComputerVoicelines.flags.contains("freeplay_voiceline"))
				{
					ComputerVoicelines.flags.remove("freeplay_voiceline");

					// a bit of a hack but if it works it fucking works -xeight
					ComputerVoicelines.play(ComputerVoicelines.neededFreeplay);
					ComputerVoicelines.neededFreeplay = "";
				}
			});
		}

		
	}

	private function turnOff()
	{
		turnedOn = false;

		ComputerVoicelines.stop();
		idling = true;

		ambience.fadeIn(1);
		if (onSound.playing)
			onSound.stop();
		offSound.play();

		FlxG.sound.music.pause();

		bg.animation.play("off");
		leftSideBG.animation.play("off");
		rightSideBG.animation.play("off");
		computer.animation.play("off");
		curiosityStickyNote.animation.play("off");
		inventoryStickyNote.animation.play("off");
		pcOn.visible = false;
		rizzmaster.animation.play("blank");

		if (easterEgg != null)
			easterEgg.animation.play("idle_off", true);

		leftSideBG.y -= 9;
	}

	private function createInteractivity()
	{
		// computer Click
		FlxMouseEvent.add(computer, (s:FlxSprite) ->
		{
			if (!turnedOn || transitioning || inSubstate)
				return;

			transitioning = true;
			if (introBlackoutTween.active)
				introBlackoutTween.manager.completeAll();
			if (introZoomTween != null && introZoomTween.active)
				introZoomTween.cancel();

			FlxTween.tween(FlxG.camera.scroll, {"x": 0, "y": 0}, 0.25);
			FlxTween.tween(FlxG.camera, {"zoom": 0.75 * 2}, 1, {ease: FlxEase.quadInOut});
			FlxTween.tween(blackout, {"alpha": 1}, 0.5, {
				onComplete: (twn:FlxTween) ->
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					MusicBeatState.switchState(new FoundationDesktopState());
				}
			});
		});

		FlxMouseEvent.add(rizzmaster, (s:FlxSprite) ->
		{
			if (!turnedOn || transitioning || inSubstate)
				return;

			transitioning = true;
			if (introBlackoutTween.active)
				introBlackoutTween.manager.completeAll();
			if (introZoomTween != null && introZoomTween.active)
				introZoomTween.cancel();

			FlxTween.tween(FlxG.camera.scroll, {"x": 0, "y": 0}, 0.25);
			FlxTween.tween(FlxG.camera, {"zoom": 0.75 * 2}, 1, {ease: FlxEase.quadInOut});
			FlxTween.tween(blackout, {"alpha": 1}, 0.5, {
				onComplete: (twn:FlxTween) ->
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					MusicBeatState.switchState(new FoundationDesktopState());
				}
			});
		});

		FlxMouseEvent.add(curiosityStickyNote, (s:FlxSprite) ->
		{
			curiosityStickyNote.visible = false;
			inSubstate = true;
			FlxG.sound.play(Paths.sound("office/sticky1Pickup"));
			FlxG.save.data.foundation.pickedUpCuriositySticky = true;
			FlxSpriteUtil.setBrightness(curiosityStickyNote, 0);
			new FlxTimer().start(0.5, (t) ->
			{
				openSubState(new StickyNoteSubstate("menu/officenew/note1Full"));
			});
		});

		FlxMouseEvent.add(inventoryStickyNote, (s:FlxSprite) ->
		{
			inventoryStickyNote.visible = false;
			inSubstate = true;
			FlxG.sound.play(Paths.sound("office/sticky2Pickup"));
			FlxG.save.data.foundation.pickedUpInventorySticky = true;
			FlxSpriteUtil.setBrightness(inventoryStickyNote, 0);
			new FlxTimer().start(0.5, (t) ->
			{
				openSubState(new StickyNoteSubstate("menu/officenew/note2Full"));
			});
		});
	}

	private function createSprites()
	{
		bg = new FlxSprite(-725, -200);
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.frames = Paths.getSparrowAtlas('menu/officenew/bg');
		bg.animation.addByPrefix("off", "bg_off", 12, true);
		bg.animation.addByPrefix("on", "bg_on", 12, true);
		bg.animation.play("off", true);

		table = new FlxSprite(-350, 400);
		table.antialiasing = ClientPrefs.globalAntialiasing;
		table.scale.set(1, 1);
		table.frames = Paths.getSparrowAtlas('menu/officenew/table');
		table.animation.addByPrefix("off", "table_off", 12, true); // why would you even fucking make an xml if you didnt add more animations dumbass -xeight
		table.animation.play("off", true);
		table.updateHitbox();

		leftSideBG = new FlxSprite(-265, -35);
		leftSideBG.antialiasing = ClientPrefs.globalAntialiasing;
		leftSideBG.scrollFactor.set(1.1, 1.1);
		leftSideBG.frames = Paths.getSparrowAtlas('menu/officenew/leftside');
		leftSideBG.animation.addByPrefix("off", "leftside_off", 12, true);
		leftSideBG.animation.addByPrefix("on", "leftside_on", 12, true);
		leftSideBG.animation.play("off", true);
		leftSideBG.updateHitbox();

		rightSideBG = new FlxSprite(FlxG.width - 400, 0);
		rightSideBG.antialiasing = ClientPrefs.globalAntialiasing;
		rightSideBG.scrollFactor.set(1.1, 1.1);
		rightSideBG.frames = Paths.getSparrowAtlas('menu/officenew/rightside');
		rightSideBG.animation.addByPrefix("off", "rightside_off", 12, true);
		rightSideBG.animation.addByPrefix("on", "rightside_on", 12, true);
		rightSideBG.animation.play("off", true);
		rightSideBG.updateHitbox();

		computer = new FlxSprite(250, 125);
		computer.antialiasing = ClientPrefs.globalAntialiasing;
		computer.scrollFactor.set(1.1, 1.1);
		computer.frames = Paths.getSparrowAtlas('menu/officenew/computer');
		computer.animation.addByPrefix("off", "computer_off", 12, true);
		computer.animation.addByPrefix("on", "computer_off", 12, true);
		computer.animation.play("off", true);
		computer.updateHitbox();

		pcOn = new FlxSprite(rightSideBG.x + 215, rightSideBG.y + 280);
		pcOn.antialiasing = ClientPrefs.globalAntialiasing;
		pcOn.scrollFactor.set(1.1, 1.1);
		pcOn.frames = Paths.getSparrowAtlas('menu/officenew/glowey');
		pcOn.animation.addByPrefix("on", "glowbluething");
		pcOn.animation.play("on");
		pcOn.visible = false;

		curiosityStickyNote = new FlxSprite(rightSideBG.x + 150, rightSideBG.y + 150);
		curiosityStickyNote.antialiasing = ClientPrefs.globalAntialiasing;
		curiosityStickyNote.scrollFactor.set(1.1, 1.1);
		curiosityStickyNote.frames = Paths.getSparrowAtlas('menu/officenew/note1');
		curiosityStickyNote.animation.addByPrefix("on", "Note1_on", 12);
		curiosityStickyNote.animation.addByPrefix("off", "Note1_off", 1);
		curiosityStickyNote.animation.play("off");

		inventoryStickyNote = new FlxSprite(leftSideBG.x + 200, rightSideBG.y + 175);
		inventoryStickyNote.antialiasing = ClientPrefs.globalAntialiasing;
		inventoryStickyNote.scrollFactor.set(1.1, 1.1);
		inventoryStickyNote.frames = Paths.getSparrowAtlas('menu/officenew/note2');
		inventoryStickyNote.animation.addByPrefix("on", "note2_on", 12);
		inventoryStickyNote.animation.addByPrefix("off", "note2_off", 1);
		inventoryStickyNote.animation.play("off");

		flipTheBirdToThatFuckassClankerThatIHate = new FlxSprite(800, 350);
		flipTheBirdToThatFuckassClankerThatIHate.antialiasing = ClientPrefs.globalAntialiasing;
		flipTheBirdToThatFuckassClankerThatIHate.frames = Paths.getSparrowAtlas('menu/officenew/fuckyou079');
		flipTheBirdToThatFuckassClankerThatIHate.animation.addByPrefix("fuckyou", "fuckyou", 24, false);
		flipTheBirdToThatFuckassClankerThatIHate.visible = false;

		rizzmaster = new FlxSprite(computer.x + 165, computer.y + 40);
		rizzmaster.antialiasing = ClientPrefs.globalAntialiasing;
		rizzmaster.frames = Paths.getSparrowAtlas('menu/officenew/079dumbassface');
		rizzmaster.animation.addByPrefix("blank", "BlankScreen");
		rizzmaster.animation.addByPrefix("agitated", "Aggitated");
		rizzmaster.animation.addByPrefix("dead", "Dead");
		rizzmaster.animation.addByPrefix("likeaboss", "Liekaboss");
		rizzmaster.animation.addByPrefix("load", "Load");
		rizzmaster.animation.addByPrefix("neutral", "Neutral");
		rizzmaster.animation.addByPrefix("no", "No");
		rizzmaster.animation.addByPrefix("quiet", "Quiet");
		rizzmaster.animation.addByPrefix("sigh", "Sigh");
		rizzmaster.animation.addByPrefix("sleep", "Sleep");
		rizzmaster.animation.addByPrefix("snarky", "Snarky");
		rizzmaster.animation.addByPrefix("mateywhat", "WTF");
		rizzmaster.animation.addByPrefix("yawn", "Yawn");
		rizzmaster.animation.play(turnedOn ? "neutral" : "blank");

		vivi = new PsychVideoSprite(false);
		vivi.antialiasing = ClientPrefs.globalAntialiasing;
		vivi.x = rizzmaster.x + 25;
		vivi.y = rizzmaster.y + 50;
		vivi.scale.set(1, 1.275);
		vivi.updateHitbox();
		vivi.canSkip = false;
		vivi.load(Paths.video("vivi"));
		vivi.addCallback("onEnd", () ->
		{
			vivi.visible = false;
		});

		// evil fucking layering
		add(bg);
		if (hasEasterEgg && easterEggID == 1) // 372
			add(easterEgg);
		add(table);
		add(rightSideBG);
		add(rizzmaster);
		add(vivi);
		add(computer);
		add(pcOn);
		add(leftSideBG);
		if (hasEasterEgg && easterEggID == 0) // 066
			add(easterEgg);
		add(curiosityStickyNote);
		add(inventoryStickyNote);
		add(flipTheBirdToThatFuckassClankerThatIHate);
	}

	// these were cut from v1 due to being time consuming to add -xeight
	private function createEasterEgg(egg:Int)
	{
		easterEggID = egg;
		switch (egg)
		{
			case 0: // 066
				easterEgg = new FlxSprite(-100, 275);
				easterEgg.frames = Paths.getSparrowAtlas("menu/officenew/eastereggs/066");
				easterEgg.animation.addByPrefix("idle_off", "idle_off", 24);
				easterEgg.animation.addByPrefix("idle_on", "idle_on", 24);
				easterEgg.animation.addByPrefix("squash_off", "squash_off", 24);
				easterEgg.animation.addByPrefix("squash_on", "squash_on", 24);
				easterEgg.animation.play("idle_off", true);
				easterEgg.scale.set(0.75, 0.75);
				easterEgg.updateHitbox();

				var sound:FlxSound = null;

				FlxMouseEvent.add(easterEgg, (s) ->
				{
					var sounds:Array<String> = [
						"scp066bopeebo",
						"scp066eric_hi1",
						"scp066eric_hi2",
						"scp066eric_lo1",
						"scp066eric_lo2",
						"scp066guitar",
						"scp066impact",
						"scp066LOUD808",
						"scp066LOUDbrass",
						"scp066note1",
						"scp066note2",
						"scp066note3",
						"scp066note4",
						"scp066note5"
					];

					if (sound == null || !sound.playing)
						sound = FlxG.sound.play(Paths.sound("office/066/" + sounds[FlxG.random.int(0, sounds.length - 1)]));
				});
			case 1: // 372
				easterEgg = new FlxSprite(1000, -275);
				easterEgg.frames = Paths.getSparrowAtlas("menu/officenew/eastereggs/372");
				easterEgg.animation.addByPrefix("idle_off", "372_off", 24);
				easterEgg.animation.addByPrefix("idle_on", "372_on", 24);
				easterEgg.animation.play("idle_off", true);
				easterEgg.scale.set(0.75, 0.75);
				easterEgg.updateHitbox();
		}
	}
}
