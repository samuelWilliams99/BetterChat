chatBox.defines = {}

chatBox.defines.colors = {
    black = Color( 0, 0, 0 ),
    white = Color( 255, 255, 255 ),
    red = Color( 255, 0, 0 ),
    green = Color( 0, 255, 0 ),
    blue = Color( 0, 0, 255 ),

    brown = Color( 181, 101, 29 ),
    orange = Color( 255, 156, 0 ),
    yellow = Color( 255, 255, 0 ),
    purple = Color( 128, 0, 128 ),
    pink = Color( 255, 192, 203 ),
    gray = Color( 128, 128, 128 ),
    grey = Color( 128, 128, 128 ),

    cyan = Color( 0, 255, 255 ),
    teal = Color( 0, 128, 128 ),
    indigo = Color( 75, 0, 130 ),
    violet = Color( 238, 130, 238 ),
    lime = Color( 191, 255, 127 ),
    magenta = Color( 255, 0, 255 ),

    maroon = Color( 128, 0, 0 ),
    crimson = Color( 220, 20, 60 ),
    coral = Color( 255, 127, 80 ),
    salmon = Color( 250, 128, 114 ),
    gold = Color( 255, 215, 0 ),
    aqua = Color( 0, 255, 255 ),
    turquoise = Color( 64, 224, 208 ),
    navy = Color( 0, 0, 128 ),
    trombone = Color( 210, 181, 91 ),
    beige = Color( 245, 245, 220 ),
    silver = Color( 192, 192, 192 ),
    mauve = Color( 103, 49, 71 ),
    smaragdine = Color( 80, 200, 117 ),

    wheat = Color( 245, 222, 179 ),
    tomato = Color( 255, 89, 61 ),
    mustard = Color( 254, 220, 86 ),
    carrot = Color( 255, 105, 180 ),
    chocolate = Color( 210, 105, 30 ),
    peanut = Color( 121, 92, 50 ),
    banana = Color( 255, 0, 128 ),

    teamGreen = Color( 0, 170, 0 ),
    skyBlue = Color( 0, 255, 255 ),
    lightBlue = Color( 0, 140, 255 ),
    hotPink = Color( 255, 105, 180 ),
    printYellow = Color( 255, 222, 102 ),
    printBlue = Color( 137, 222, 255 ),
    ulxYou = Color( 75, 0, 130 ),
}


local colors = chatBox.defines.colors

function chatBox.defines.gray( x, a )
    if not colors["grey" .. x] then
        colors["grey" .. x] = Color( x, x, x, a or 255 )
    end
    return colors["grey" .. x]
end

chatBox.defines.theme = {
    foreground = chatBox.defines.gray( 150, 50 ),
    foregroundLight = chatBox.defines.gray( 205, 60 ),
    background = chatBox.defines.gray( 30, 200 ),
    buttonTextFocused = chatBox.defines.gray( 220 ),
    emoteAccent = Color( 65, 105, 225 ),
    dead = colors.red,

    team = colors.teamGreen,
    teamTextEntry = Color( 100, 200, 100 ),

    admin = colors.red,
    nonAdminText = colors.green,
    adminTextEntry = Color( 200, 100, 100 ),

    betterChat = colors.yellow,
    channels = colors.yellow,
    channelCog = chatBox.defines.gray( 50, 150 ),
    channelCogFocused = chatBox.defines.gray( 30, 230 ),

    group = colors.cyan,
    groupMembers = chatBox.defines.gray( 255 ),
    groupMembersFocused = chatBox.defines.gray( 230 ),
    groupTextEntry = Color( 100, 200, 200 ),

    logs = Color( 138, 43, 226 ),
    logsPrefix = colors.teamGreen,

    sidePanelAccent = chatBox.defines.gray( 180, 200 ),
    sidePanelForeground = chatBox.defines.gray( 80, 200 ),
    sidePanelCheckBox = colors.cyan,

    links = Color( 180, 200, 255 ),
    commands = chatBox.defines.gray( 190 ),
    inputText = colors.white,
    inputSuggestionText = colors.gray,

    textHighlight = colors.orange,
    timeStamps = colors.printYellow,
    server = colors.printBlue,
}

chatBox.defines.materials = {
    cog = Material( "icons/cog.png" ),
    groupBW = Material( "icons/groupBW.png" ),
    group = Material( "icon16/group.png" ),
    emoteButton = Material( "icons/emojiButton.png" ),
    gradientLeft = Material( "vgui/gradient-l" ),
    gradientUp = Material( "vgui/gradient-u" ),
}

chatBox.defines.consolePlayer = { isConsole = true }

chatBox.defines.channelTypes = {
    GLOBAL = 1,
    TEAM = 2,
    PRIVATE = 3,
    ADMIN = 4,
    GROUP = 5
}

chatBox.defines.giphyCommand = "!giphy"

chatBox.defines.networkStrings = {
    "BC_chatOpenState", "BC_sendPlayerState", "BC_playerReady", "BC_disable", -- Chat states
    "BC_PM", "BC_AM", "BC_GM", "BC_TM", "BC_LM", -- Messages (Private, Admin, Group, Team)
    "BC_sendULXCommands", "BC_userRankChange", -- Ulx
    "BC_sendGroups", "BC_updateGroup", "BC_newGroup", "BC_groupAccept", "BC_leaveGroup", "BC_deleteGroup", -- Groups
    "BC_forwardMessage", "BC_sayOverload", "BC_sendGif", "BC_playerDisconnected", -- Misc
 }
