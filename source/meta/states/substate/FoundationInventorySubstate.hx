package meta.states.substate;

import meta.states.substate.desktop.StickyNoteSubstate;
import meta.states.substate.office.ClipboardSubstate;
import flixel.input.mouse.FlxMouseEvent;
import haxe.Json;

class FoundationInventorySubstate extends MusicBeatSubstate
{
	var cam:FlxCamera;

	static var items:FoundationItemSchema;
	public static var inSubSubState:Bool = false;

	var canClose:Bool = false;

	var bg:FlxSprite;

	override function create()
	{
		super.create();

		new FlxTimer().start(0.1, (t) -> canClose = true);

		FoundationOfficeState.inSubstate = true;

		if (items == null)
			items = Json.parse(Paths.getTextFromFile('data/items.json'));

		cam = new FlxCamera();
		cam.bgColor.alpha = 0;
		FlxG.cameras.add(cam, false);

		bg = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
		bg.cameras = [cam];
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.alpha = 0.75;
		bg.updateHitbox();
		add(bg);

		var startX = 185;
		var distanceX = 200;
		var startY = 185;
		var distanceY = 200;

        var itemId = 0;
		for (row in 0...2)
		{
			for (it in 0...5)
			{
				var itemFrame:FlxSprite = new FlxSprite(startX + it * distanceX, startY + row * distanceY);
				itemFrame.antialiasing = ClientPrefs.globalAntialiasing;
				itemFrame.cameras = [cam];
				itemFrame.frames = Paths.getSparrowAtlas("menu/officenew/Inventory_assets");
				itemFrame.animation.addByPrefix("idle", "inventory_box");
				itemFrame.animation.play("idle");
				itemFrame.scale.set(0.5, 0.5);
				itemFrame.updateHitbox();
				add(itemFrame);

				if (items.items[itemId] == null)
				{
					itemId += 1;
					continue;
				}

				var item:FlxSprite = new FlxSprite(startX + it * distanceX + 25, startY + row * distanceY + 25 + items.items[itemId].offsetY);
				item.antialiasing = ClientPrefs.globalAntialiasing;
				item.cameras = [cam];
				item.frames = Paths.getSparrowAtlas("menu/officenew/Inventory_assets");
				item.animation.addByPrefix("idle", items.items[itemId].sprite);
				item.animation.play("idle");
				item.scale.set(0.25, 0.25);
				item.updateHitbox();
				add(item);

				var itemName:FlxText = new FlxText(itemFrame.x + 65, itemFrame.y + 135);
				itemName.antialiasing = ClientPrefs.globalAntialiasing;
				itemName.cameras = [cam];
				itemName.setFormat(Paths.font('cour.ttf'), 24);
				itemName.text = items.items[itemId].name;
				itemName.x -= itemName.width / 2;
				itemName.visible = false;
				add(itemName);

                var thisitemId = itemId;
				FlxMouseEvent.add(itemFrame, (s) -> onItemClicked(items.items[thisitemId].id), null, (s) -> onItemHovered(itemName),
					(s) -> onItemUnhovered(itemName), false, true, false);

				itemId += 1;
			}
		}
		
		addTouchPad("NONE", "B");
		addTouchPadCamera();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if ((controls.BACK || FlxG.keys.justPressed.Q || touchPad.buttonB.justPressed) && canClose) 
			close();
	}

	override function destroy()
	{
		FoundationOfficeState.inSubstate = false;
		inSubSubState = false;

		super.destroy();
	}
	
	private function onItemClicked(id:String)
	{
		if (inSubSubState)
			return;
		switch (id)
		{
			case "idCard":
				inSubSubState = true;
				openSubState(new StickyNoteSubstate("documents/idCard"));
			case "clipboard":
				inSubSubState = true;
				openSubState(new ClipboardSubstate());
			case "usb":
				CoolUtil.createCBMessage("Not yet.", 2);
				// close();
		}
	}

	private function onItemHovered(text:FlxText)
	{
		text.visible = true;
	}

	private function onItemUnhovered(text:FlxText)
	{
		text.visible = false;
	}
}

typedef FoundationItemSchema =
{
	var items:Array<FoundationItem>;
}

typedef FoundationItem =
{
	var id:String;
	var name:String;
	var sprite:String;
	var offsetY:Float;
}
