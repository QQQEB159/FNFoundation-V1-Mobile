package meta.states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import haxe.Json;
import gameObjects.fUI.*;
import meta.states.substate.MusicBeatSubstate;

/**
	everyone really wanted me to make a custom options menu
	but i really didnt want to make a custom options menu
	so i made the custom options menu make itself instead

	-xeight
**/
class FoundationOptionsState extends MusicBeatSubstate
{
	public static var exitState:Class<FlxState> = null;

	var bg:FlxSprite;

    var tabs:Map<String, FlxGroup> = [
        "graphics" => new FlxGroup(),
        "audio" => new FlxGroup(),
        "controls" => new FlxGroup(),
        "advanced" => new FlxGroup()
    ];
    var tabButtons:Array<FlxSprite> = [];

	var blackout:FlxSprite;
	var introBlackoutTween:FlxTween;

	override function create()
	{
		// Paths.clearStoredMemory();
		// Paths.clearUnusedMemory();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.updatePresence(null, "Configuring the experience");
		#end

		Paths.forceCaching = false;

		FlxG.mouse.visible = true;

		if (FlxG.sound.music == null) {
			if (Type.getClassName(exitState) == "meta.states.FoundationIntroState")
				FlxG.sound.playMusic(Paths.music("intro"), 0.5);
			else
				FlxG.sound.playMusic(Paths.music('079'), 0.7);
		}
			

		bg = new FlxSprite().loadGraphic(Paths.image('menu/settings/settingsmenu'));
        bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.scale.set(0.65, 0.65);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

        createTabs();
		createOptions();
        switchTab("graphics");
        tabButtons[0].animation.play("select");

        for (tab in tabs)
            add(tab);

		blackout = new FlxSprite(-500, -500).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		add(blackout);

		introBlackoutTween = FlxTween.tween(blackout, {"alpha": 0}, 0.5);
		
		addTouchPad("NONE", "B");
		addTouchPadCamera();
	}

    override function destroy() {
        super.destroy();
        Paths.forceCaching = true;
		FlxG.mouse.visible = false;

		if (Type.getClassName(exitState) != "meta.states.FoundationIntroState" && Type.getClassName(exitState) != "meta.states.PlayState")
			exitState = null;

		ClientPrefs.saveSettings();
        FlxG.save.flush();
    }

	override function update(elapsed:Float)
	{
		super.update(elapsed);

        for (but in tabButtons) {
            if (FlxG.mouse.overlaps(but) && FlxG.mouse.justPressed) {
                switchTab(switch (but.ID) {
                    case 0:
                        "graphics";
					case 1:
						"audio";
                    case 2:
                        "controls";
                    case 3:
                        "advanced";
                    default:
                        "graphics";
                });

                for (b in tabButtons)
                    b.animation.play("idle");
                but.animation.play("select");
            }
                
        }

		if (controls.BACK)
		{
			if (introBlackoutTween.active)
				introBlackoutTween.manager.completeAll();
			FlxTween.tween(blackout, {"alpha": 1}, 0.5, {
				onComplete: (twn:FlxTween) ->
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					Init.SwitchToPrimaryMenu(exitState);
				}
			});
			// IntroState.returnedFromOptions = true;
		}
	}

    private function createTabs() {
        var i = 0;
        for (k in ["graphics", "audio", "controls", "advanced"]) {
            var tabButton = new FlxSprite(235 + i * 200, 75);
			tabButton.antialiasing = ClientPrefs.globalAntialiasing;
            tabButton.frames = Paths.getSparrowAtlas('menu/settings/Settings');
            tabButton.animation.addByPrefix("idle", k + "0", 1);
            tabButton.animation.addByPrefix("select", k + "_select0", 1);
            tabButton.scale.set(0.65, 0.65);
            tabButton.ID = i;
            tabButton.animation.play("idle");
            tabButton.updateHitbox();
            add(tabButton);

            tabButtons.push(tabButton);

            i += 1;
        }
    }

	private function createOptions()
	{
		var rawOptions:String = Paths.getTextFromFile('data/options.json');
		var optionsFile:FoundationOptionsFile = Json.parse(rawOptions);

		function getDefaultValue(name:String)
			return switch (name)
			{
				case "showFPS":
					Main.fpsVar.visible;
				default:
					Reflect.getProperty(ClientPrefs, name);
			}

		function onCheckmarkToggled(checkmark:FCheckmark)
		{
			Reflect.setProperty(ClientPrefs, checkmark.name, checkmark.state);
			switch (checkmark.name)
			{
				case "showFPS":
					if (Main.fpsVar != null)
						Main.fpsVar.visible = ClientPrefs.showFPS;
				case "globalAntialiasing":
					for (sprite in members)
					{
						var sprite:Dynamic = sprite; // Make it check for FlxSprite instead of FlxBasic
						var sprite:FlxSprite = sprite; // Don't judge me ok
						if (sprite != null && (sprite is FlxSprite) && !(sprite is FlxText))
						{
							sprite.antialiasing = ClientPrefs.globalAntialiasing;
						}
					}
			}
		}

		function onButtonPressed(button:FButton) {
			switch (button.name) {
				case "changeControls":
					openSubState(new meta.states.substate.settings.FoundationControlsSubstate());
				case "changeOffset":
					meta.data.options.NoteOffsetState.exitState = FoundationOptionsState;
					if (introBlackoutTween.active)
						introBlackoutTween.manager.completeAll();
					FlxTween.tween(blackout, {"alpha": 1}, 0.5, {
						onComplete: (twn:FlxTween) ->
						{
							FlxTransitionableState.skipNextTransIn = true;
							FlxTransitionableState.skipNextTransOut = true;
							LoadingState.loadAndSwitchState(new meta.data.options.NoteOffsetState());
						}
					});
					
				case "oldOptions":
					meta.data.options.OptionsState.exitState = FoundationOptionsState;
					if (introBlackoutTween.active)
						introBlackoutTween.manager.completeAll();
					FlxTween.tween(blackout, {"alpha": 1}, 0.5, {
						onComplete: (twn:FlxTween) ->
						{
							FlxTransitionableState.skipNextTransIn = true;
							FlxTransitionableState.skipNextTransOut = true;
							LoadingState.loadAndSwitchState(new meta.data.options.OptionsState());
						}
					});
			}
		}

		for (tab in optionsFile.tabs)
		{
			for (value in tab.values)
			{
                var tabGroup = tabs[tab.name];
				switch (value.control)
				{
					case "check":
						var check:FCheckmark = new FCheckmark(value.x, value.y, getDefaultValue(value.value), onCheckmarkToggled, value.value);
						check.antialiasing = ClientPrefs.globalAntialiasing;
						tabGroup.add(check);

						var label:FlxText = new FlxText(value.x + 75, value.y + 25);
						label.antialiasing = ClientPrefs.globalAntialiasing;
						label.setFormat(Paths.font('cour.ttf'), 32);
						label.text = value.label;
						tabGroup.add(label);
					case "button":
						var button:FButton = new FButton(value.x, value.y, onButtonPressed, value.value);
						button.antialiasing = ClientPrefs.globalAntialiasing;
						tabGroup.add(button);

						var label:FlxText = new FlxText(value.x + 165, value.y + 10);
						label.antialiasing = ClientPrefs.globalAntialiasing;
						label.setFormat(Paths.font('cour.ttf'), 32);
						label.text = value.label;
						// label.size = Std.int(label.size * (button.frameWidth / button.width));
						tabGroup.add(label);
					// case "slider":
					// 	var slider:FSlider = new FSlider(value.x, value.y, ClientPrefs, value.value, value.minRange, value.maxRange, null, value.value);
					// 	tabGroup.add(slider);
				}
			}
		}
	}

    private function switchTab(newTab:String) {
        for (tab in tabs) {
            for (item in tab) {
                item.visible = false;
            }
        }
        for (item in tabs[newTab]) {
            item.visible = true;
        }
    }
}

typedef FoundationOptionsFile =
{
	var tabs:Array<FoundationOptionsTab>;
}

typedef FoundationOptionsTab =
{
	var name:String;
	var values:Array<FoundationOptionsValue>;
}

typedef FoundationOptionsValue =
{
	var x:Float;
	var y:Float;
	var label:String;

	var control:String; // Checkmark/other stuff in the future
	var value:String;
	var defValue:Dynamic;
	var extra:Null<String>; // Any extra data I might need to know to hack this shit together

	var minRange:Null<Float>;
	var maxRange:Null<Float>;
}
