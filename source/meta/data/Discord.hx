package meta.data;

#if DISCORD_ALLOWED
import hxdiscord_rpc.Types;
import hxdiscord_rpc.Discord;
import sys.thread.Thread;

// coded this one from scratch to support buttons lmao -xeight
class DiscordClient {
    public static var discordThread:Thread;
    
    public static var initialized:Bool = false;

    public static function initialize() {
        final eventHandlers:DiscordEventHandlers = new DiscordEventHandlers();
        eventHandlers.ready = cpp.Function.fromStaticFunction(onReady);
        eventHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
        eventHandlers.errored = cpp.Function.fromStaticFunction(onError);
        Discord.Initialize("1389303467906044035", cpp.RawPointer.addressOf(eventHandlers), false, null);

        discordThread = Thread.create(function():Void
		{
			while (true)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end

				Discord.RunCallbacks();

				Sys.sleep(2);
			}
		});

        initialized = true;
    }

    public static function updatePresence(state:Null<String>, details:Null<String>) {
        var presence = new DiscordRichPresence();
        presence.type = DiscordActivityType_Playing;
        if (state != null) presence.state = state;
        if (details != null) presence.details = details;
        presence.largeImageKey = "icon";
        presence.largeImageText = "Friday Night Foundation Vol. 1";

        var twitterButton:DiscordButton = new DiscordButton();
        twitterButton.label = "Twitter";
        twitterButton.url = "https://twitter.com/foolsforhirehq";
        presence.buttons[0] = twitterButton;

        var gbButton:DiscordButton = new DiscordButton();
        gbButton.label = "GameBanana";
        gbButton.url = "https://gamebanana.com/mods/639505";
        presence.buttons[1] = gbButton;

        Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
    }

    public static function shutdown() {
        Discord.Shutdown();
    }

    private static function onReady(request:cpp.RawConstPointer<DiscordUser>) {
        var username:String = request[0].username;

        trace("[Discord] logged in as " + username);
    }

    private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		Sys.println('[Discord] Disconnected ($errorCode:$message)');
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		Sys.println('[Discord] Error ($errorCode:$message)');
	}
}
#end