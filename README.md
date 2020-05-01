
# BetterChat
A Better ChatBox that focuses on letting you make the ChatBox you want! BetterChat introduces channels, emotes, text modifiers, extensive per-channel settings, and even optional giphy support!

## NOTES: 
- This chat requires ULX, and integrates the support very thoroughly.
- To enable giphy support, you will need to generate a testing giphy key for your server.

## Feature list:
- Channels
  - Player
  - Team
  - Admin channel that integrates ulx asay
  - Group channels that can be user created and managed
  - Private Message channels that integrate ulx psay
  - Logs for admins, all messages from any channel, for all players are forwarded to this channel
  - Prints
  - Optional team overload (for DarkRP or DarkRP derivative gamemodes)
- Emotes (requires extract with gmad.exe to customise) 
- Giphy support (you will need to generate a beta API key [here](https://developers.giphy.com/))
- Nicer text input (all the normal text shortcuts you'd expect from a full text editor)
- Autocomplete (with visible suggestions) on player names, ulx commands and emote names. Suggestions based on usage
- Chat history
- Clickable links
- Discord style text modification (\**italics*\*, \*\***bold**\*\*, \~\~~~strike-through~~\~\~, \_\_underline\_\_)
- Text colouring, via `[#rrggbb]` (in hex, e.g. `[#ff0000]` for red), or `[@red]`. Colour tags set the text colour until the next colour tag. Use `[#]` to reset back to white.  
  Example usage: `[#ff0000]This is red, [@green]this is green, and [#]this is white :)`
- Extensive global and per-channel settings
- Customisable player quick access menu (quickly run ulx commands or any custom command on players via a menu)
- Fully integrated DarkRP Support (including groups, FAdmin, PM, etc.)
- Ulx permission support for all special features (giphy, groups, text modification, etc. )
- Plugin support
and many more smaller features, you just gotta try it out to find them all! :D

If a player on your server does not like this chat, it can be disabled in Q->options->BetterChat without error.

## Addon Compatibility:
Some chat based addons aren't fully compatible with BetterChat, I'll try to fix any I can, but some require the other addon to be changed. I'll list any addons that require this in the Compatibility Discussion, along with how to fix them.

### Currently Known Compatible Addons:
- DarkRP
- ATags (with and without DarkRP)

## Planned features:
- /code for gmod lua syntax highlighting (like steam's /code)
- Link pre-loading (simple website name acquired only by the sending client, for security)
- An admin options menu to outright disable some features

## Shortcuts:
- Ctrl + s : Toggles current channel's settings panel
- Ctrl + Shift + s : Toggles local player's quick access menu
- Ctrl + e : Toggles emote menu
- Ctrl + Backspace : Removes last word
- Ctrl + Shift + Backspace : Removes all before caret
- Ctrl + Tab : Next Channel (Or swap emote mode, when Emote menu open)
- Ctrl + Shift + Tab : Previous Channel
- Ctrl + 0,1 ...,9 : Select respective channel (Or insert respective emote, when emote menu open)
- Ctrl + w : Close tab
- Ctrl + o : Toggle open channel tab
- Tab : Autocomplete

## ConVars:
All global settings are stored as ConVars, every convar can have it's default set on the server using 
"[ConVar]_default"
Each of these settings can also be modified via Q->options->BetterChat, and will show more information on hover.
### This list contains all global settings ConVars:
- **bc_fadeTime** : Time for a chat message to fade (0 for never)
- **bc_chatHistory** : Number of messages received before old messages are deleted
- **bc_teamOpenPM** : Should opening team chat open to most recent unread PM
- **bc_rememberChannel** : Should betterchat remember your most recent channel when opening
- **bc_saveOpenChannels** : Should channels from your previous session be re-opened on join
- **bc_channelNumShortcut** : Should the shortcuts CTRL+[0-9] change channel
- **bc_acDisplay** : Should autocomplete suggestions be showed in the text input
- **bc_acUsage** : Should autocomplete order its suggestions based on your usage of them
- **bc_clickableLinks** : Should any hyperlinks posted to chat be clickable
- **bc_printChannelEvents** : Should messages like "Channel All created" be shown
- **bc_allowConsole** : Should any message starting with '%' be run as a console command instead
- **bc_convertEmotes** : Should emotes like ":)" be converted to their respective emoticon. Note this is purely client side, others will still see the emoticon
- **bc_showGifs** : Should gifs from !giphy (if it is enabled) be rendered
- **bc_doPop** : Should the chat ever play the Pop sound (based on other settings)
- **bc_doTick** : Should the chat ever play the Tick sound (based on other settings)
- **bc_formatColors** : Should colors typed in chat be displayed in their respective color
### This list contains all server settings ConVars:
- **bc_server_replaceTeam** : Replaces team channels with a separately networked team channel (separate per team). This is useful for StarWarsRP-like servers, where players often change rank, and team chat is disabled by default.
- **bc_server_removeTeam** : Disables the default team channel
- **bc_server_maxLength** : Maximum message length, gmod's default is 126
- **bc_server_giphyKey** : Set this if you wish to enable giphy support on your server. you will need to generate a beta API key [here](https://developers.giphy.com/) (it's free and easy, you will need to make an account though). then call `bc_server_giphyKey [yourkey]`.
- **bc_server_giphyHourlyLimit** : This defaults to 10, which I found to be a reasonable amount considering the limits on a beta API key. If your server does not have many players (or players don't often use this feature), feel free to increase this.
## ULX Permissions
- **bc_chatlogs** : Enables the 'Logs' channel which receives all messages from groups, PM, team, etc.
- **bc_giphy** : Ability to use !giphy if bc_server_giphykey is valid
- **bc_color** : Ability to use `[#ff0000]Red` in chat
- **bc_groups** : Ability to use BetterChat groups
- **bc_italics** : Ability to use `*italics*` in chat
- **bc_bold** : Ability to use `**bold**` in chat
- **bc_underline** : Ability to use `__underline__` in chat
- **bc_strike** : Ability to use `~~strike~~` in chat


## Extra
All channels are limited by the ULX chat cooldown ConVar: `ulx_chattime`  
If you wish to change the way this addon logs messages to console, you can use the `BC_onServerLog` hook.  
Usage:
```lua
-- channelType is one of the enums in bc.defines.channelTypes: GLOBAL, TEAM, GROUP, ADMIN, PRIVATE
-- channelName is a printable name for the channel, e.g. "Global", "Team - User", etc.
-- ... are the message structure as it would be printed to logs. Often includes: player, ": ", message
--     but can be different (e.g. for private messages)
-- This hook must RETURN the string to be printed, not print it itself. This is so ULX logs still function.

-- The following example shows how to recreate normal gmod logging - This means no logs for groups
hook.Add( "BC_onServerLog", "myHook", function( channelType, channelName, ... )
    local data = { ... }
    local sender = data[1]
    local senderName = "Console"
    local senderAlive = true
    if sender:IsValid() then
        senderName = sender:Nick()
        senderAlive = sender:Alive()
    end

    -- data[2] will likely be ": "
    local message = data[3]

    if channelType == bc.defines.channelTypes.GLOBAL then
        return ( senderAlive and "" or "*DEAD* " ) .. senderName .. ": " .. message
    elseif channelType == bc.defines.channelTypes.TEAM then
        -- By default, team only show if you're dead. Ofc this is wrong, but we're recreating default behaviour here.
        return ( senderAlive and "" or "*DEAD*(TEAM) " ) .. senderName .. ": " .. message
    elseif channelType == bc.defines.channelTypes.PRIVATE then
        -- data[2] is " -> "
        local receiver = data[3]
        -- data[4] is ": "
        message = data[5]

        -- Private messages, either via !psay, private channel, or /PM for DarkRP
        return senderName .. " to " .. receiver:Nick() .. ": " .. message
    elseif channelType == bc.defines.channelTypes.GROUP then
        -- Ignore group messages - the group id and name will be in channelName. Structure: "Group ${id} - ${name}"
        return ""
    elseif channelType == bc.defines.channelTypes.ADMIN then
        -- Admin messages using @, ulx asay, admin channel, or /adminhelp for DarkRP
        return senderName .. " to admins: " .. message
    end
end )
```

## Plugins
Plugin lua files can be placed in the lua/betterchat_plugins folder. These will be automatically networked and loaded on client and server based on the name.  
Plugins file names must be in the form `[sv|sh|cl]_{pluginName}.lua`  
For example:
- `sv_defaultserverlogging.lua`
- `sh_simpleplugin.lua`
- `cl_myplugin.lua`

Plugins can be reloaded on server and client via the `bc_reloadplugins` console command.  
If you wish your plugin to not be reloadable **on clients**, set the global `RELOADABLE` to `false`

## Nice little features:
- You can copy a text's colour in the right click menu
- You can copy a player's full name or steam id by either right clicking their name in chat or in the player quick access menu
- Left clicking on a players name in the player quick access menu lists all other players
- Double clicking a player's name in the chatBox opens a private channel
- You can also access settings of (and sometimes close) channels by right clicking the tab
- You can close some channels by middle clicking the channel tab name
- You can change which channel is displayed when the chat closes in channel settings
- Renaming a group channel in its settings does so globally, all clients in the group will see that name
- If you scroll up too far, a little "Back to the bottom" button will show up
- You can choose which channels show prints (from addons like wiremod)
- You can move the chatBox by dragging the top right corner, then right click this corner to return it to its default position

## Adding custom emotes:
**IMPORTANT**: This can be difficult, and sometimes does not work. I intend to change how this is done when I can, which will likely remove any custom emotes you add now. Proceed at your own risk :)
1. Extract BetterChat's `gma` file to folder, using `gmad.exe` in `GarrysMod\bin`. See [here](https://steamcommunity.com/sharedfiles/filedetails/?id=865959209) for how to do this
2. Navigate to `GarrysMod\garrysmod\addons\BetterChat\materials\spritesheets`
3. Convert your spritesheet to vtf. Use [this](https://sprays.tk/) to convert png to VTF (not VMT). IMPORTANT NOTE, your image height and width must be a power of 2 (32, 64, 128, 256, ...), you don't need to use the entire sheet, but vtf files require this. If you get an error using the converter, this is likely why. 
4. Copy the vmt from another spritesheet and rename it to the same as your spritesheet.
5. Open the vmt with a text editor and change line 3 to "$basetexture" "spritesheets/[YOURSPRITESHEET]" (without .vtf)
6. Create a json file with the same name as your spritesheet, and fill it in using the following format.
```
{
    "spriteWidth": 20,
    "spriteHeight": 20,
    "sprites": [
        {
            "posX": 0,
            "posY": 0,
            "name": "eyeroll",
            "chatStrings": [

            ]
        },
        {
            "posX": 1,
            "posY": 0,
            "name": "sidetongue",
            "chatStrings": [
                ":p", ":P"
            ]
        },

    ]
}
```
- spriteWidth and spriteHeight is the size of an individual sprite in pixels
- posX and posY are the position of the sprite in the sprite sheet, where 0,0 is top left (increase by 1 per sprite, not per pixel)
- Typing :mySprite: in chat will display a sprite with the name "mySprite"
- chatStrings is a list of extra strings to display the sprite. (this does not add ":"s, if you want `yourSprite` as an extra string, use `:yourSprite:`)
- The json file can also be a png file, as gross as this is, it's the only way to get steam to allow json in a materials folder, this is why emojis.png and gmodicons.png exist.

