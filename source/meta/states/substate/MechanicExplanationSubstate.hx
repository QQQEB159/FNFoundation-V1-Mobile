package meta.states.substate;

import meta.data.Controls;
import flixel.FlxSubState;

class MechanicExplanationSubstate extends MusicBeatSubstate
{
    var bg:FlxSprite;
    var mechanic:FlxSprite;
    var render:FlxSprite;
    var hint:FlxText;

    var canExit:Bool = true;
    var exiting:Bool = false;

    var renderTimer:FlxTimer;
    var renderTween:FlxTween;
    var mechanicTween:FlxTween;
    var hintTween:FlxTween;

    var cam:FlxCamera;

    var songs:Array<String> = [
        "locked in",
        "evaluation",
        "terminated",
        "vivisection",
        "captivated",
        "my world",
        "harlequin",
        "scopophobia",
        "recontainment",
        "disgusting"
    ];
    
	override function create()
	{
        PlayState.explainedMechanic = true;

        if (!songs.contains(PlayState.SONG.song.toLowerCase())) {
            finish();

            new FlxTimer().start(0.1, (t) -> close());
            return;
        }

        trace("Entered mechanic explanation");

        cam = new FlxCamera();
        cam.bgColor.alpha = 0;
        FlxG.cameras.add(cam, false);

        // PlayState.instance.doBeat = false;

        FlxG.sound.playMusic(Paths.music('inspection'));
        FlxG.sound.music.fadeIn(1);

        trace("Trying to add the explanation stuff");

        bg = new FlxSprite(-200, -200).makeGraphic(FlxG.width*2, FlxG.height*2, FlxColor.BLACK);
        bg.cameras = [cam];
        bg.alpha = 1;
        add(bg);

        render = new FlxSprite(-1000, 125).loadGraphic(Paths.image('renders/' + PlayState.SONG.song.toLowerCase()));
        render.antialiasing = ClientPrefs.globalAntialiasing;
        render.scale.set(0.75, 0.75);
        render.updateHitbox();
        render.cameras = [cam];
        add(render);

        mechanic = new FlxSprite(750, 1000).loadGraphic(Paths.image('documents/' + PlayState.SONG.song.toLowerCase()));
        mechanic.antialiasing = ClientPrefs.globalAntialiasing;
        mechanic.scale.set(0.5, 0.5);
        mechanic.updateHitbox();
        mechanic.cameras = [cam];
        add(mechanic);

        hint = new FlxText(15, 15);
        hint.text = "Press ENTER to continue...";
        // hint.antialiasing = ClientPrefs.globalAntialiasing;
        // hint.setFormat(Paths.font('cour.ttf'), 24, FlxColor.WHITE);
        hint.alpha = 1;
        // add(hint); // not worky idk

        trace("Added the stuff");

        mechanicTween = FlxTween.tween(mechanic, {"y": 10}, 3);

        renderTimer = new FlxTimer().start(3, (t) -> {
            renderTween = FlxTween.tween(render, {"x": 0}, 1, {ease: FlxEase.quintOut});
        });

        // hintTween = FlxTween.tween(hint, {"alpha": 1}, 1);

        // new FlxTimer().start(1, (timer:FlxTimer) -> {
        //     canExit = true;
            // trace("Can exit now");
        // });

        addTouchPad("NONE", "A");
		addTouchPadCamera();
        
        super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (PlayState.instance.getControl("ACCEPT") && canExit && !exiting)
		{
            exiting = true;
            if (mechanicTween != null && mechanicTween.active) mechanicTween.manager.completeAll();
            if (renderTimer != null && renderTimer.active) renderTimer.manager.completeAll();
            if (renderTween != null && renderTween.active) renderTween.manager.completeAll();
            if (hintTween != null && hintTween.active) hintTween.manager.completeAll();
            FlxTween.tween(render, {"x": -1000}, 1, {ease: FlxEase.quintOut});
            FlxTween.tween(mechanic, {"y": -1000}, 1, { ease: FlxEase.circOut});
            FlxTween.tween(hint, {"alpha": 0}, 1);

            FlxG.sound.music.fadeOut(0.5);

            new FlxTimer().start(1, (t) -> finish());
            
            FlxTween.tween(bg, {"alpha": 0}, 2, {onComplete: (twn:FlxTween) -> {
                close();
                FlxG.cameras.remove(cam);
            }});
		}
	}

    function finish() {
        PlayState.instance.doBeat = true;
        PlayState.instance.startCountdown();
    }
}
