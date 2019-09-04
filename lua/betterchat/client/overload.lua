function chatBox.overloadFunctions()
	chatBox.overloadedFuncs = {}
	chatBox.overloadedFuncs.oldAddText = chat.AddText
	chat.AddText = function( ... )
		chatBox.print(...)
		-- Call the original function (replace some stuff)
		local data = {...}
		for k,v in pairs(data) do
			if type(v) == "table" and v.formatter and (v.type == "clickable" or v.type == "image") then
				data[k] = v.text
			end
		end
		chatBox.overloadedFuncs.oldAddText( unpack(data) )
	end

	chatBox.overloadedFuncs.oldGetChatBoxPos = chat.GetChatBoxPos
	chat.GetChatBoxPos = function() 
		return chatBox.graphics.frame:GetPos()
	end

	chatBox.overloadedFuncs.oldGetChatBoxSize = chat.GetChatBoxSize
	chat.GetChatBoxSize = function() 
		local xSum = chatBox.graphics.size.x
		for k, v in pairs(chatBox.sidePanels) do
			if v.animState > 0 then
				xSum = xSum + (v.animState*v.size.x) + 2
			end
		end

		return xSum, chatBox.graphics.size.y
	end

	chatBox.overloadedFuncs.plyMeta = FindMetaTable("Player")
	chatBox.overloadedFuncs.plyChatPrint = chatBox.overloadedFuncs.plyMeta.ChatPrint
	chatBox.overloadedFuncs.plyMeta.ChatPrint = function(self, str)
		chatBox.print(printBlue, str)

		chatBox.overloadedFuncs.plyChatPrint(self, str)
	end

	chatBox.overloadedFuncs.plyIsTyping = chatBox.overloadedFuncs.plyMeta.IsTyping
	chatBox.overloadedFuncs.plyMeta.IsTyping = function( ply )
		return chatBox.playersOpen[ply]
	end

	hook.Run("BC_Overload")

	chatBox.overloaded = true
end

function chatBox.returnFunctions()
	if not chatBox.overloaded then return end
	chat.AddText = chatBox.overloadedFuncs.oldAddText
	chat.GetChatBoxSize = chatBox.overloadedFuncs.oldGetChatBoxSize
	chat.GetChatBoxPos = chatBox.overloadedFuncs.oldGetChatBoxPos
	chatBox.overloadedFuncs.plyMeta.ChatPrint = chatBox.overloadedFuncs.plyChatPrint
	chatBox.overloadedFuncs.plyMeta.IsTyping = chatBox.overloadedFuncs.plyIsTyping
	chatBox.overloadedFuncs = {}
	hook.Run("BC_Overload_Undo")
	chatBox.overloaded = false
end