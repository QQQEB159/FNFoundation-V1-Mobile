package meta.states;

import flixel.group.FlxSpriteGroup;
import meta.data.Song;
import mobile.TouchUtil;

class FoundationGaucheTitleState extends MusicBeatState
{
    var sky:FlxSprite;
    var logo:FlxSprite;
    var pressEnter:FlxSprite;
    var fuckassPlane:FlxSprite;

    var cloud1:FlxSprite;
    var cloud2:FlxSprite;
    var cloud3:FlxSprite;
    var clouds:FlxSpriteGroup;

    var canEnter:Bool = false;

	override function create()
	{
        super.create();

        #if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		meta.data.WeekData.loadTheFirstEnabledMod();

        #if desktop
		// Updating Discord Rich Presence
		DiscordClient.updatePresence(null, "In the air");
		#end

        Paths.currentModDirectory = "Foundation";

        clouds = new FlxSpriteGroup();
        clouds.alpha = 0;

        FoundationMainMenuState.playMusic = false;

        FlxG.sound.playMusic(Paths.sound("intro/gauche_ambience"), 1);
		FlxG.sound.music.fadeIn(1.5);

        sky = new FlxSprite().loadGraphic(Paths.image('menu/gauche/GaucheTitleBG'));
        sky.antialiasing = ClientPrefs.globalAntialiasing;
        sky.alpha = 0;

        logo = new FlxSprite(0, 0).loadGraphic(Paths.image('menu/gauche/GaucheFoundationLogo'));
        logo.antialiasing = ClientPrefs.globalAntialiasing;
        logo.scale.set(0.85, 0.85);
        logo.updateHitbox();
        logo.screenCenter(XY);
        logo.alpha = 0;

        pressEnter = new FlxSprite(0, 625).loadGraphic(Paths.image('menu/gauche/press_enter'));
        pressEnter.antialiasing = ClientPrefs.globalAntialiasing;
        pressEnter.screenCenter(X);
        pressEnter.alpha = 0;

        fuckassPlane = new FlxSprite(FlxG.width + 100).loadGraphic(Paths.image('menu/gauche/plane'));
        fuckassPlane.antialiasing = ClientPrefs.globalAntialiasing;
        fuckassPlane.scale.set(2, 2.15);
        fuckassPlane.updateHitbox();
        fuckassPlane.screenCenter(Y);
        fuckassPlane.y += 50;

        cloud1 = new FlxSprite(200, 300).loadGraphic(Paths.image('menu/gauche/Cloud1'));
        cloud1.antialiasing = ClientPrefs.globalAntialiasing;
        cloud1.scale.set(0.5, 0.5);
        cloud1.updateHitbox();
        clouds.add(cloud1);

        cloud2 = new FlxSprite(900, 100).loadGraphic(Paths.image('menu/gauche/Cloud2'));
        cloud2.antialiasing = ClientPrefs.globalAntialiasing;
        cloud2.scale.set(0.5, 0.5);
        cloud2.updateHitbox();
        clouds.add(cloud2);

        cloud3 = new FlxSprite(1300, 500).loadGraphic(Paths.image('menu/gauche/Cloud3'));
        cloud3.antialiasing = ClientPrefs.globalAntialiasing;
        cloud3.scale.set(0.5, 0.5);
        cloud3.updateHitbox();
        clouds.add(cloud3);

        add(sky);

        add(clouds);

        add(logo);
        add(pressEnter);
        add(fuckassPlane);

        FlxTween.tween(clouds, {"alpha": 1}, 1.5);

        FlxTween.tween(sky, {"alpha": 1}, 1, { onComplete: (t) -> {
            FlxTween.tween(logo, {"alpha": 1}, 3, {onComplete: (t) -> {
                canEnter = true;
                FlxTween.tween(pressEnter, {"alpha": 1}, 1);
            }});
        }});		
	}

    override function update(elapsed:Float) {
        super.update(elapsed);

        clouds.forEach((s:FlxSprite) -> {
            s.x -= 35 * elapsed;
            if (s.x < -450) s.x = FlxG.width + 100;
        });

        if (canEnter && (controls.ACCEPT || TouchUtil.justPressed)) {
            canEnter = false;
            FlxTween.tween(fuckassPlane, {"x": -2900}, 0.15);
            new FlxTimer().start(0.15, (t) -> {
                FlxG.camera.alpha = 0;

                PlayState.isStoryMode = false;
                PlayState.introSequence = true;

                FlxG.save.data.foundation.seenIntro = true;
                FlxG.save.flush();
        
                PlayState.SONG = Song.loadFromJson("gauche-hard", "gauche");
                LoadingState.loadAndSwitchState(new PlayState(), true);
            });
        }
    }
}
