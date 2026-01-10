package meta.states.substate.desktop;

import meta.data.ProgressUtils;
import flixel.addons.transition.FlxTransitionableState;
import meta.data.Song;
import meta.data.WeekData;
import meta.states.FoundationDesktopState.FoundationDesktopBaseWindow;
import meta.states.substate.MusicBeatSubstate;
import flixel.input.mouse.FlxMouseEvent;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;

class FoundationDesktopFootageWindow extends FoundationDesktopBaseWindow {
    var songs:Array<String> = [];
    var freeplays:Array<String> = [];

    var songTxts:FlxSpriteGroup;
    var songBgs:FlxSpriteGroup;

    var scrolledPast:Int = 0;
    var songsFit:Int = 6;
    
    var coverUp:FlxSprite;
    
    var scrollUpButton:FlxButton;
    var scrollDownButton:FlxButton;

    public static var transitioning:Bool = false;

    public function new(x:Float, y:Float) {
        super(x, y);

        windowTitle.text = "Secret Footage";

        WeekData.reloadWeekFiles(true);

        // FIXN'TME: Placeholder shit, replace with actual song list creation -xeight
        // 5 months later:
            // this shit is not placeholder anymore lmaoooooo -xeight
        songs = [
            "gauche",
            "story_mode",
            "evaluation",
            "locked in",
            "terminated",
            "vivisection",
            "captivated",
            "my world",
            "harlequin",
            "scopophobia",
            "recontainment",
            "disgusting"
        ];

        freeplays = [
            "mayhem",
            "ballin",
            "hopeless",
            "vasectomy"
        ];

        if (FlxG.save.data.foundation.finalStoryProgress != null && FlxG.save.data.foundation.finalStoryProgress >= 10 ) {
            FlxG.save.data.foundation.unlockedFreeplay = true;
            for (song in freeplays) {
                songs.push(song);
            }
        }

        songTxts = new FlxSpriteGroup();
        songBgs = new FlxSpriteGroup();

        var regex:EReg = ~/.*/;

        coverUp = new FlxSprite(26, 430).makeGraphic(655, 10, FlxColor.WHITE);
        coverUp.alpha = 0.15;
        add(coverUp);
        
        scrollUpButton = new FlxButton(690, 80, "↑", scrollUp);
        scrollUpButton.setGraphicSize(30, 30);
        scrollUpButton.updateHitbox();
        scrollUpButton.label.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.BLACK, CENTER);
        add(scrollUpButton);

        scrollDownButton = new FlxButton(690, 430, "↓", scrollDown);
        scrollDownButton.setGraphicSize(30, 30);
        scrollDownButton.updateHitbox();
        scrollDownButton.label.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.BLACK, CENTER);
        add(scrollDownButton);

        for (i in 0...songs.length) {
            var songBG = new FlxSprite(26, (50 * i) + 80).makeGraphic(655, 50, FlxColor.WHITE);
            songBG.color = FlxColor.BLACK;
            songBG.alpha = songs[i] != "story_mode" ? 0.25 : 0.15;
            songBgs.add(songBG);

            if (FlxG.save.data.foundation.songsBeaten.contains(songs[i].replace("-", " ")) || (songs[i] == "story_mode" && FlxG.save.data.foundation.finalStoryProgress >= 10)) {
                songBG.color = 0xFF004400;
            }
            // FlxMouseEvent.add(songBG, 
            //     (s:FlxSprite) -> {
            //         onSongSelect(s, songs[i]);
            //     }
            //     null,
            //     (s:FlxSprite) -> {
            //         s.color = FlxColor.GRAY;
            //     },
            //     (s:FlxSprite) -> {
            //         s.color = FlxColor.WHITE;
            //     }
            // ); // idk if there is a less messy way to do this lol -xeight

            var songTxt = new FlxText(26, (50 * i) + 80);
            songTxt.antialiasing = false;
            if (songs[i] == "story_mode" || (FlxG.save.data.foundation.songsSeen != null && FlxG.save.data.foundation.songsSeen.contains(songs[i].replace("-", " "))))
                songTxt.text = songs[i].replace(" ","_") + ".mp4";
            else {
                // songTxt.text = regex.replace(songs[i], "█") + ".mp4"; // vcr osd mono doesnt support this fuckass character oh well -xeight
                if (freeplays.contains(songs[i]))
                    songTxt.text = "[???].mp4";
                else
                    songTxt.text = "[REDACTED].mp4";
            }

            songTxt.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.BLACK);
            songTxts.add(songTxt);

            FlxMouseEvent.add(songBG,
                (sprite:FlxSprite) -> {
                    onSongSelect(sprite, songs[i]);
                },
                null,
                (sprite:FlxSprite) -> {
                    songTxt.setBorderStyle(OUTLINE, FlxColor.WHITE, 2);
                },
                (sprite:FlxSprite) -> {
                    songTxt.setBorderStyle(NONE);
                });

            if (i > songsFit) {
                songTxt.visible = false;
                songBG.visible = false;
            }
            else 
                coverUp.color = songBG.color;
        }

        add(songBgs);
        add(songTxts);
    }

    function scrollUp() {
        moveSongs(1);
    }

    function scrollDown() {
        moveSongs(-1);
    }
    
    function moveSongs(scroll:Int) {
        var shouldMove:Bool = true;
            
        scrolledPast -= scroll;

        if (scrolledPast < 0) {scrolledPast = 0; shouldMove = false;}
        else if (scrolledPast > songs.length - songsFit - 1) {scrolledPast = songs.length - songsFit - 1; shouldMove = false;}

        if (shouldMove) {
            for (i in 0...songTxts.length) {
                songTxts.members[i].y += 50 * scroll;
                songBgs.members[i].y += 50 * scroll;

                if (i < scrolledPast || i > songsFit + scrolledPast) {
                    songTxts.members[i].visible = false;
                    songBgs.members[i].visible = false;
                }
                else {
                    songTxts.members[i].visible = true;
                    songBgs.members[i].visible = true;
                }

                if (songBgs.members[i].visible)
                    coverUp.color = songBgs.members[i].color;
            }
        }
    }
    
    override function update(elapsed:Float) {
        super.update(elapsed);

        // debug shit remove before release
        // if (FlxG.keys.justPressed.E) {
        //     FlxG.save.data.foundation.unlockedFreeplay = false;
        //     FlxG.save.data.foundation.doneQuiz = false;
        //     // FlxG.save.data.foundation.storyProgress = 0;
        //     // FlxG.save.data.foundation.songsSeen = ["gauche"];
        // }

        #if debug
        if (FlxG.keys.justPressed.P) {
            ProgressUtils.unlockAll();
        }
        #end

        if (FlxG.mouse.wheel != 0) {
            var scroll = FlxG.mouse.wheel > 0 ? 1 : -1;
            var shouldMove:Bool = true;
            
            scrolledPast -= scroll;

            if (scrolledPast < 0) {scrolledPast = 0; shouldMove = false;}
            else if (scrolledPast > songs.length - songsFit - 1) {scrolledPast = songs.length - songsFit - 1; shouldMove = false;}

            if (shouldMove) {
                for (i in 0...songTxts.length) {
                    songTxts.members[i].y += 50 * scroll;
                    songBgs.members[i].y += 50 * scroll;

                    if (i < scrolledPast || i > songsFit + scrolledPast) {
                        songTxts.members[i].visible = false;
                        songBgs.members[i].visible = false;
                    }
                    else {
                        songTxts.members[i].visible = true;
                        songBgs.members[i].visible = true;
                    }

                    if (songBgs.members[i].visible)
                        coverUp.color = songBgs.members[i].color;
                }
            }
        }

        // if (controls.UI_DOWN_P) {
        //     scrolledPast += 1;
        //     for (i in 0...songTxts.length) {
        //         songTxts.members[i].y -= 50;
        //         songBgs.members[i].y -= 50;
        //     }
        // }
        // else if (controls.UI_UP_P) {
        //     scrolledPast -= 1;
        //     for (i in 0...songTxts.length) {
        //         songTxts.members[i].y += 50;
        //         songBgs.members[i].y += 50;
        //     }
        // }
    }

    private function onSongSelect(s:FlxSprite, song:String) {
        if (transitioning) return;

        // only deny if its a story_mode song
        if (song != "story_mode" && (!FlxG.save.data.foundation.songsSeen.contains(song) && !freeplays.contains(song))) {
            FlxG.sound.play(Paths.sound("desktop/deny"));
            // FlxG.camera.shake(0.015, 0.25);
            return;
        }

        if (song == "story_mode") {
            if (FlxG.save.data.foundation.storyProgress != null && FlxG.save.data.foundation.storyProgress > 0) {
                if (FlxG.save.data.foundation.storyProgress < 10)
                    FlxG.state.add(new FoundationDesktopContinueWindow(350, 200));
                else
                    startThing(song);
            }
            else
                startThing(song);
        }
        else
            startThing(song);

    }

    public static function startThing(song:String) {
        transitioning = true;
        FlxTransitionableState.skipNextTransOut = false;
        
        FlxG.sound.play(Paths.sound("desktop/confirm"));
        
        WeekData.setDirectoryFromWeek(WeekData.weeksLoaded["weekbreach"]);
        // very fucking jank but its like 12 am i cant be fucked to do better -xeight
        if (song == "story_mode") {
            var progress:Int = 0;
            if (FlxG.save.data.foundation.storyProgress != null)
                progress = Std.int(FlxG.save.data.foundation.storyProgress);

            if (progress >= 10)
                progress = 0;

            PlayState.isStoryMode = true;

            var playList:Array<String> = [];
            for (s in WeekData.weeksLoaded["weekbreach"].songs) {
                playList.push(s[0]);
            }

            playList = playList.slice(progress);

            PlayState.storyPlaylist = playList;

            PlayState.storyDifficulty = 2;

            PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + "-hard", PlayState.storyPlaylist[0].toLowerCase());
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;
        }
        else {
            PlayState.isStoryMode = false;

            PlayState.SONG = Song.loadFromJson(song + "-hard", song);
        }

        new FlxTimer().start(0.75, (t) -> {
            LoadingState.loadAndSwitchState(new PlayState(), true);
        });
    }
}