MsgAll = function(...)
	ULib.clientRPC(nil, "Msg", ...)
	Msg(...)
end

local oldPrintMessage = PrintMessage
function PrintMessage(type, message)
	if type == HUD_PRINTTALK then
		ULib.clientRPC(nil, "chatBox.print", printBlue, message)
	end
	oldPrintMessage(type, message)
end

local plyMeta = FindMetaTable("Player")
local oldPlyPrintMessage = plyMeta.PrintMessage
plyMeta.PrintMessage = function(self, type, message)
	if type == HUD_PRINTTALK then
		ULib.clientRPC(self, "chatBox.print", printBlue, message)
	end
	oldPlyPrintMessage(self, type, message)
end

local oldChatPrint = plyMeta.ChatPrint
plyMeta.ChatPrint = function(self, msg)
	ULib.clientRPC(self, "chatBox.print", printBlue, msg)
	oldChatPrint(self, msg)
end