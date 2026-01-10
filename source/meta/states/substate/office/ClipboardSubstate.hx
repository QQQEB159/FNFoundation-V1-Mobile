package meta.states.substate.office;

class ClipboardSubstate extends MusicBeatSubstate {
    var currentPageNum:Int = 0;
    var currentPage:FlxSprite;

    var pages = [
        "doc05",
        "doc079"
    ];
    var unlockablePages = [
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

    var hintText:FlxText;

    var canClose:Bool = false;
    var stillScrolling:Bool = false;

    var exitTween:FlxTween;
    var enterTween:FlxTween;

    override function create() {
        super.create();

        new FlxTimer().start(0.1, (t) -> canClose = true);

        var bg:FlxSprite = new FlxSprite(-500, -500).makeGraphic(1, 1, FlxColor.BLACK);
        bg.cameras = [CoolUtil.getTopCam()];
        bg.setGraphicSize(20000, 20000);
        bg.alpha = 0.5;
        add(bg);

        hintText = new FlxText(FlxG.width - 350, FlxG.height-40);
        hintText.cameras = [CoolUtil.getTopCam()];
        hintText.setFormat(Paths.font('cour.ttf'), 24, FlxColor.WHITE);
        hintText.text = "Left/Right to scroll";
        add(hintText);

        for (i in 0...Std.int(Math.min(FlxG.save.data.foundation.finalStoryProgress, 10)))
            pages.push(unlockablePages[i]);

        changePage(0);
        
        addTouchPad("LEFT_RIGHT", "B_J");
		addTouchPadCamera();
    }

    function changePage(delta:Int) {
        if (stillScrolling) return;

        function createNewPage(instant:Bool = false) {
            if (currentPage != null) currentPage.destroy();

            currentPage = new FlxSprite(delta < 0 ? -1000 : FlxG.width + 500).loadGraphic(Paths.image("documents/" + pages[currentPageNum]));
            currentPage.scale.set(0.5, 0.5);
            currentPage.updateHitbox();
            // currentPage.screenCenter();
            currentPage.cameras = [CoolUtil.getTopCam()];
            currentPage.alpha = 0;
            add(currentPage);

            stillScrolling = false;

            if (!instant)
                enterTween = FlxTween.tween(currentPage, {x: FlxG.width/2 - currentPage.width/2, alpha: 1}, 0.5, {ease: FlxEase.quartOut});
            else {
                currentPage.alpha = 1;
                currentPage.x = FlxG.width/2 - currentPage.width/2;
                // new FlxTimer().start(0.25, (t) -> stillScrolling = false);
            }
        }

        // this logic doesnt fucking work - xeight
        // if (stillScrolling) {
        //     if (exitTween != null && exitTween.active) {
        //         exitTween.cancel();
        //         createNewPage(true);
        //     }
        //     if (enterTween != null && enterTween.active)
        //         enterTween.manager.completeAll();
        // };

        currentPageNum += delta;
        if (currentPageNum < 0)
            currentPageNum = pages.length - 1;
        else if (currentPageNum > pages.length - 1)
            currentPageNum = 0;

        FlxG.sound.play(Paths.sound("office/inventory/paper"));

        stillScrolling = true;

        if (currentPage != null) {
            exitTween = FlxTween.tween(currentPage, {x: delta < 0 ? FlxG.width + 500 : -1000, alpha: 0}, 0.35, {onComplete: (t) -> createNewPage(), ease: FlxEase.quartOut});
            // currentPage.destroy();
        }
        else
            createNewPage();
        
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.UI_LEFT_P)
            changePage(-1);
        if (controls.UI_RIGHT_P)
            changePage(1);

        if (controls.BACK && canClose) {
            FoundationInventorySubstate.inSubSubState = false;
            close();
        }
    }
}