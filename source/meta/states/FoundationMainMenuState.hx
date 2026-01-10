package meta.states;

import flixel.addons.transition.FlxTransitionableState;
import mobile.TouchUtil;

class FoundationMainMenuState extends MusicBeatState
{
	var buildings4:FlxSprite;
	var buildings3:FlxSprite;
	var buildings2:FlxSprite;
	var buildings1:FlxSprite;

    var gate:FlxSprite;

    var sky:FlxSprite;

    var tree:FlxSprite;
    var leaves:FlxSprite;

    var fadeIn:FlxSprite;
    var logo:FlxSprite;
    var pressEnter:FlxSprite;

    var enterFade:FlxTween;

    var canStart:Bool = false;
    var transitioning:Bool = false;
    public static var playMusic:Bool = true;

	override public function create()
	{
        #if desktop
		// Updating Discord Rich Presence
		DiscordClient.updatePresence(null, "At the entrance of Site-R");
		#end

        fadeIn = new FlxSprite(-100, -100).makeGraphic(FlxG.width*2, FlxG.height*2, FlxColor.BLACK);

        logo = new FlxSprite(0, 150).loadGraphic(Paths.image('menu/mainmenu/logo'));
        logo.antialiasing = ClientPrefs.globalAntialiasing;
        logo.alpha = 0;
        logo.screenCenter(X);

        pressEnter = new FlxSprite(0, 450).loadGraphic(Paths.image('menu/mainmenu/pressEnter'));
        pressEnter.antialiasing = ClientPrefs.globalAntialiasing;
        pressEnter.alpha = 0;
        pressEnter.screenCenter(X);

        var now:Date = Date.now();
        var hours:Int = now.getHours();

        if (hours >= 21 || hours <= 4) sky = new FlxSprite(-250, -50).loadGraphic(Paths.image('menu/mainmenu/night'));
        else if ((hours >= 5 && hours <= 13) || (hours >= 17 && hours <= 21)) sky = new FlxSprite(-250, -50).loadGraphic(Paths.image('menu/mainmenu/dusk'));
        else sky = new FlxSprite(-250, -50).loadGraphic(Paths.image('menu/mainmenu/day'));

        sky.antialiasing = ClientPrefs.globalAntialiasing;
        sky.scale.set(0.35, 0.35);
        sky.updateHitbox();

        buildings4 = new FlxSprite(400, 300).loadGraphic(Paths.image('menu/mainmenu/buildings4'));
        buildings4.antialiasing = ClientPrefs.globalAntialiasing;
        buildings4.scale.set(0.35, 0.35);
        buildings4.updateHitbox();

        buildings3 = new FlxSprite(100, -85).loadGraphic(Paths.image('menu/mainmenu/buildings3'));
        buildings3.antialiasing = ClientPrefs.globalAntialiasing;
        buildings3.scale.set(0.35, 0.35);
        buildings3.updateHitbox();

        buildings2 = new FlxSprite(350, 250).loadGraphic(Paths.image('menu/mainmenu/buildings2'));
        buildings2.antialiasing = ClientPrefs.globalAntialiasing;
        buildings2.scale.set(0.35, 0.35);
        buildings2.updateHitbox();

        buildings1 = new FlxSprite(450, 275).loadGraphic(Paths.image('menu/mainmenu/buildings1'));
        buildings1.antialiasing = ClientPrefs.globalAntialiasing;
        buildings1.scale.set(0.35, 0.35);
        buildings1.updateHitbox();

        gate = new FlxSprite(-150).loadGraphic(Paths.image('menu/mainmenu/gate'));
        gate.antialiasing = ClientPrefs.globalAntialiasing;
        gate.scale.set(0.35, 0.35);
        gate.updateHitbox();

        tree = new FlxSprite(225, -300).loadGraphic(Paths.image('menu/mainmenu/tree'));
        tree.antialiasing = ClientPrefs.globalAntialiasing;
        tree.scale.set(0.35, 0.35);
        tree.updateHitbox();

        leaves = new FlxSprite(-700, -800);
        leaves.antialiasing = ClientPrefs.globalAntialiasing;
        leaves.angle = 45;
        leaves.scale.set(0.35, 0.35);
        leaves.updateHitbox();
        leaves.frames = Paths.getSparrowAtlas('menu/mainmenu/leaves');
        leaves.animation.addByPrefix("leaves", "leaves", 24);
        leaves.animation.play("leaves", true);

        add(sky);
        add(buildings4);
        add(buildings3);
        add(tree);
        add(buildings2);
        add(buildings1);
        add(gate);
        add(leaves);

        add(fadeIn);

        add(logo);
        add(pressEnter);

        FlxTween.tween(fadeIn, {"alpha": 0}, 1.5, { onComplete: (twn) -> {
            FlxTween.tween(logo, {"alpha": 1}, 3, { onComplete: (twn) -> {
                canStart = true;
                enterFade = FlxTween.tween(pressEnter, {"alpha": 1}, 1);
                FlxTween.tween(fadeIn, {"alpha": 0.25}, 1);
            }});
        }});

        if (playMusic) {
            FlxG.sound.playMusic(Paths.music('titleScreen'), 0.7);
            FlxG.sound.music.fadeIn(1);
        }
        else {
            FlxG.sound.playMusic(Paths.sound('intro/ambOutsideSiteR'), 0.7);
            FlxG.sound.music.fadeIn(1);
        }
	}

    override public function update(dt:Float) {
        if (canStart && (controls.ACCEPT || TouchUtil.justPressed) && !transitioning) {
            transitioning = true;
            
            FlxG.sound.music.fadeOut(0.5, 0, (t) -> FlxG.sound.music = null);
            if (enterFade.active) enterFade.manager.completeAll();
            FlxTween.tween(logo, {"alpha": 0}, 0.25);
            FlxTween.tween(pressEnter, {"alpha": 0}, 0.25);
            FlxTween.tween(fadeIn, {"alpha": 1}, 0.5);

            new FlxTimer().start(0.5, (t) -> {
                FlxTransitionableState.skipNextTransIn = true;
                FlxTransitionableState.skipNextTransOut = true;
                FlxG.switchState(new FoundationOfficeState());
            });
        }
    }
}
