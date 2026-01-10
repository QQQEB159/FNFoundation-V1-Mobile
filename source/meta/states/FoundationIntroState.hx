package meta.states;

import gameObjects.shader.FunkinShader.FunkinRuntimeShader;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKeyList;
import flixel.addons.text.FlxTypeText;
import haxe.Json;
import flixel.FlxState;

class FoundationIntroState extends FlxState
{
	private static var introData:FoundationTypewriteFile;
	public static var currentSegment:FoundationTypewriteSegment;
	public static var currentLine:Int = -1;

	public static var pastText:String = "";
	public static var pastLine:FoundationTypewriteData;

	var typewriter:FlxTypeText;
	var screenOverlay:FlxSprite;
	var blackout:FlxSprite;

	var processInputs:Bool = false;

	private static var specialId:String = "";

	override function create()
	{
		super.create();

		Main.fpsVar.visible = false;

		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		meta.data.WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.updatePresence(null, "???");
		#end

		if (introData == null)
			introData = Json.parse(Paths.getTextFromFile('data/introdata.json'));

		if (currentSegment == null)
			currentSegment = getSegment("intro");

		typewriter = new FlxTypeText(150, 100, 950, "");
		typewriter.antialiasing = ClientPrefs.globalAntialiasing;
		typewriter.setFormat(Paths.font('cour.ttf'), 24);
		typewriter.showCursor = true;
		typewriter.sounds = [FlxG.sound.load(Paths.sound('intro/type'), 0.25)];
		typewriter.prefix = pastText;
		add(typewriter);

		screenOverlay = new FlxSprite().loadGraphic(Paths.image("menu/screenOverlay"));
		screenOverlay.antialiasing = ClientPrefs.globalAntialiasing;
        screenOverlay.screenCenter();
        add(screenOverlay);

		blackout = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		add(blackout);
        FlxTween.tween(blackout, {"alpha": 0}, 0.5);

		processNextLine();

		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music("intro"), 0.5);

		FoundationOptionsState.exitState = null;
		
		addTouchPad("NONE", "Y_N");
	}

	override function destroy()
	{
		super.destroy();

		Main.fpsVar.visible = ClientPrefs.showFPS;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// if (FlxG.keys.justPressed.P) {
		// 	changeSegmentTo("accepted");
		// }

		if (processInputs)
		{
			if (FlxG.keys.justPressed.ANY)
				onShitPressed(FlxG.keys.justPressed);
				
			if (touchPad.buttonY.justPressed)
			{
			    processInputs = false;
			    switch (FoundationIntroState.specialId)
			    {
				    case "truth":
					    changeSegmentTo("honest");
				    case "openOptions":
                        FoundationOptionsState.exitState = FoundationIntroState;
                        changeSegmentDry("disclaimer");

					    FlxTween.tween(blackout, {"alpha": 1}, 0.5, {
						    onComplete: (twn:FlxTween) ->
						    {
							    addPastText(pastLine.text);
							    pastLine = null;

							    FlxTransitionableState.skipNextTransIn = true;
							    FlxTransitionableState.skipNextTransOut = true;
							    FlxG.switchState(new FoundationOptionsState());
						    }
					    });
					
				    case "acceptDisclaimer":
					    changeSegmentTo("accepted");
			    }
			    FlxG.sound.play(Paths.sound("desktop/sKeyboard" + Std.string(FlxG.random.int(0, 4))));
			}
			else if (touchPad.buttonN.justPressed)
			{
			    processInputs = false;
			    switch (FoundationIntroState.specialId)
			    {
				    case "truth":
					    changeSegmentTo("lying");
				    case "openOptions":
					    changeSegmentTo("disclaimer");
				    case "acceptDisclaimer":
					    FlxG.sound.music.fadeOut();
					    changeSegmentTo("denied");
				FlxG.sound.play(Paths.sound("desktop/sKeyboard" + Std.string(FlxG.random.int(0, 4))));
			    }
			}
		}

        if (FlxG.keys.justPressed.ANY) {
            if (!FlxG.keys.justPressed.SPACE)
                FlxG.sound.play(Paths.sound("desktop/sKeyboardSpace"));
            else
                FlxG.sound.play(Paths.sound("desktop/sKeyboard" + Std.string(FlxG.random.int(0, 4))));
        }
	}

	function onShitPressed(keyList:FlxKeyList)
	{
		if (keyList.Y)
		{
			processInputs = false;
			switch (FoundationIntroState.specialId)
			{
				case "truth":
					changeSegmentTo("honest");
				case "openOptions":
                    FoundationOptionsState.exitState = FoundationIntroState;
                    changeSegmentDry("disclaimer");

					FlxTween.tween(blackout, {"alpha": 1}, 0.5, {
						onComplete: (twn:FlxTween) ->
						{
							addPastText(pastLine.text);
							pastLine = null;

							FlxTransitionableState.skipNextTransIn = true;
							FlxTransitionableState.skipNextTransOut = true;
							FlxG.switchState(new FoundationOptionsState());
						}
					});
					
				case "acceptDisclaimer":
					changeSegmentTo("accepted");
			}
		}
		else if (keyList.N)
		{
			processInputs = false;
			switch (FoundationIntroState.specialId)
			{
				case "truth":
					changeSegmentTo("lying");
				case "openOptions":
					changeSegmentTo("disclaimer");
				case "acceptDisclaimer":
					FlxG.sound.music.fadeOut();
					changeSegmentTo("denied");
			}
		}
	}

	function onAction()
	{
		switch (FoundationIntroState.specialId)
		{
			case "fadeMusic":
				FlxG.sound.music.fadeOut();
				processNextLine();
			case "startGauche":
				FlxTransitionableState.skipNextTransIn = true;
				FlxG.camera.alpha = 0;

				new FlxTimer().start(2, (t) ->
				{
					FlxG.switchState(new FoundationGaucheTitleState());
				});
			case "close":
				Sys.exit(0);
		}
	}

	function processNextLine()
	{
		currentLine += 1;
		var newLine:FoundationTypewriteData = FoundationIntroState.currentSegment.messages[currentLine];

		if (newLine.type == null)
			newLine.type = "message";

		if (newLine.clear != null && newLine.clear == true)
		{
			pastText = "";
			pastLine = null;
            typewriter.prefix = "";
            typewriter.text = "";
		}
		if (newLine.text != null /*&& (pastLine == null || pastLine.clear == null)*/) {
            if (newLine.type == "question")
                newLine.text += " (Y/N)";
            newLine.text += "\n\n";
        }
			

		switch (newLine.type)
		{
			case "delay":
				new FlxTimer().start(newLine.length, (t) ->
				{
					processNextLine();
				});
			case "question":
                new FlxTimer().start(1, (t) ->
				{
					typeLine(newLine, false);
                    typewriter.completeCallback = () ->
                    {
                        processInputs = true;
                        typewriter.completeCallback = null;
                    };
				});
				FoundationIntroState.specialId = newLine.id;
			case "action":
				FoundationIntroState.specialId = newLine.id;
				onAction();
			default:
				new FlxTimer().start(1, (t) ->
				{
					typeLine(newLine);
				});
		}
	}

	function addPastText(newText:String)
	{
		pastText += newText;
		typewriter.prefix = pastText;
	}

	function typeLine(message:FoundationTypewriteData, autoProceed:Bool = true)
	{
		if (pastLine != null)
			addPastText(pastLine.text);

		typewriter.resetText(message.text);
		typewriter.start(0.05, false, false, [], autoProceed ? processNextLine : null);

		pastLine = message;
	}

	function getSegment(name:String):FoundationTypewriteSegment
	{
		for (segment in introData.segments)
		{
			if (segment.name == name)
				return segment;
		}
		return null;
	}

	function changeSegmentTo(name:String)
	{
		currentSegment = getSegment(name);
		currentLine = -1;
		processNextLine();
	}

    function changeSegmentDry(name:String) {
        currentSegment = getSegment(name);
		currentLine = -1;
    }
}

typedef FoundationTypewriteFile =
{
	var segments:Array<FoundationTypewriteSegment>;
}

typedef FoundationTypewriteSegment =
{
	var name:String;
	var messages:Array<FoundationTypewriteData>;
}

typedef FoundationTypewriteData =
{
	var type:Null<String>;
	var text:Null<String>;
	var clear:Null<Bool>;
	var id:Null<String>;

	var length:Null<Float>;
}
