# BetterChat
A Better ChatBox that introduces channels, emotes, and many other features!
## NOTES: 
- This chat requires ULX (this will soon be changed though)
- My name is nowhere in this project, so my "credit" is given by a special join message. If you do not like this feature, it can be removed at lua/betterchat/sh_base.lua, at line 100

## Feature list:
- Channels
  - Player
  - Team
  - Admin channel that integrates ulx asay
  - Group channels that can be user created and managed
  - Private Message channels that integrate ulx psay
- Customisable emotes (requires extract with gmad.exe to customise) 
- Nicer text input (all the normal text shortcuts you'd expect from a full text editor)
- Autocomplete (with visible suggestions) on player names, ulx commands and emote names. Suggestions based on usage
- Chat history
- Clickable links (that do actually work)
- Extensive global and per-channel settings
- Customisable player quick access menu (quickly run ulx commands or any custom command on players via a menu)
- Fully integrated DarkRP Support (Including groups, FAdmin, PM, etc.)
and many more smaller features, you just gotta try it out to find them all! :D

The text display element (drichtext) has been rebuilt from scratch to fix and add features to the chat itself, something no other chat has done. (probably)

This addon has not yet undergone extensive testing (though I have tested it myself as best I can), if you wish to install this on a server, please notify me so I can monitor it while in use by a larger player-base. 
If a player on your server does not like this chat, it can be disabled in Q->options->BetterChat without error.

## Addon Compatibility:
Some chat based addons aren't fully compatible with BetterChat, I'll try to fix any I can, but some require the other addon to be changed. I'll list any addons that require this in the Compatibility Discussion, along with how to fix them.

## Currently Known Compatible Addons:
- DarkRP
- ATags (May not work with DarkRP)

## Planned features:
- Gif support using giphy (The text display can render gifs already, but there is not yet a way to actually send them)
- /code for gmod lua syntax highlighting (like steam's /code)
- Link pre-loading (simple website name acquired only by the sending client, for security)
- An admin options menu to outright disable some features

## Shortcuts:
- Ctrl + s : Toggles current channel's settings panel
- Ctrl + Shift + s : Toggles local player's quick access menu
- Ctrl + e : Toggles emote menu
- Ctrl + g : Toggle group menu
- Ctrl + Backspace : Removes last word
- Ctrl + Shift + Backspace : Removes all before caret
- Ctrl + Tab : Next Channel (Or swap emote mode, when Emote menu open)
- Ctrl + Shift + Tab : Previous Channel
- Ctrl + 0,1 ...,9 : Select respective channel (Or insert respective emote, when emote menu open)
- Tab : Autocomplete

## ConVars:
All global settings are stored as ConVars, every convar can have it's default set on the server using 
"[ConVar]_default"
### This list contains all global settings ConVars:
- bc_teamOpenPM
- bc_acDisplay
- bc_acUsage
- bc_clickableLinks
- bc_allowConsole
- bc_convertEmotes
- bc_doPop
- bc_doTick
- bc_formatColors
- bc_colorCmds
- bc_hideBugMessage

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
1. Navigate to BetterChat\materials\spritesheets
2. Convert your spritesheet to vtf. Use this[tf.heybey.org] to convert png to vtf. IMPORTANT NOTE, your image height and width must be a power of 2 (32, 64, 128, 256, ...), you don't need to use the entire sheet, but vtf files require this. If you get an error using the converter, this is likely why. 
3. Copy the vmt from another spritesheet and rename it to the same as your spritesheet.
4. Open the vmt with a text editor and change line 3 to "$basetexture" "spritesheets/[YOURSPRITESHEET]" (without .vtf)
5. Create a json file with the same name as your spritesheet, and fill it in using the following format.
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
- posX and posY are the position of the sprite in the sprite sheet, where 0,0 is top left
- Typing :name: in chat will display a sprite with the name "name"
- chatStrings is a list of extra strings to display the sprite.
- The json file can also be a png file, as gross as this is, it's the only way to get steam to allow json in a materials folder, this is why emojis.png and gmodicons.png exist.

