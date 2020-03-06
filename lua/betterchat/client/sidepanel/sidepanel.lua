--includes
include("betterchat/client/sidepanel/panels/channels.lua")
include("betterchat/client/sidepanel/panels/players.lua")
include("betterchat/client/sidepanel/panels/members.lua")

local default_width = 110

renderSettingFuncs = {
	["string"] = function(sPanel, panel, data, y, w, h, setting)
		local textEntry = vgui.Create("DTextEntry", panel)
		textEntry:SetName("BC_SettingsEntry")
		textEntry:SetPos(w - default_width, y-1)
		textEntry:SetSize(default_width, 18)
		textEntry:SetText(data[setting.value])
		textEntry:SetTooltip(setting.extra)
		textEntry:SetUpdateOnType(false)
		textEntry:SetDisabled(setting.disabled or false)

		textEntry.data = data
		textEntry.val = setting.value
		textEntry.limit = setting.limit
		textEntry.trim = setting.trim
		textEntry.Think = function(self)
			if self.data.dataChanged[self.val] then
				self:SetText(self.data[self.val])
				self.data.dataChanged[self.val] = false
			end
		end
		textEntry.OnValueChange = function(self, val)
			if self.trim then
				val = string.Trim(val)
			end
			if #val == 0 then
				self:SetText(self.data[self.val])
			else
				self.data[self.val] = val
			end
			if setting.onChange then setting.onChange(data) end
			chatBox.saveData()
		end
		textEntry.OnLoseFocus = function(self) self:OnValueChange(self:GetText()) end
		textEntry.AllowInput = function(self, char)
			local txt = self:GetText()
			if self.trim then
				if #txt < 1 and char == ' ' then 
					return true 
				end
			end
			if self.limit then
				if #txt == self.limit then
					return true
				end
			end
			return false
		end


		return default_width
	end,
	["key"] = function(sPanel, panel, data, y, w, h, setting)
		local textEntry = vgui.Create("DTextEntry", panel)
		textEntry:SetName("BC_SettingsKeyEntry")
		textEntry:SetPos(w - default_width, y-1)
		textEntry:SetSize(default_width, 18)
		textEntry:SetFont("BC_Monospace")
		textEntry:SetDisabled(setting.disabled or false)

		textEntry:SetText("")
		textEntry:SetPlaceholderText(data[setting.value] and input.GetKeyEnum(data[setting.value]) or "NOT SET")

		textEntry:SetTooltip(setting.extra)
		textEntry:SetUpdateOnType(true)

		textEntry.data = data
		textEntry.val = setting.value
		textEntry.Think = function(self)
			if self.data.dataChanged[self.val] then
				self:SetPlaceholderText(self.data[self.val] and input.GetKeyEnum(self.data[self.val]) or "NOT SET")
				self.data.dataChanged[self.val] = false
			end
		end
		textEntry.OnKeyCodeTyped = function(self, val)
			if val ~= KEY_ESCAPE then
				if val == KEY_BACKSPACE then
					self.data[self.val] = nil
					self:SetPlaceholderText("NOT SET")
				else
					self.data[self.val] = val
					self:SetPlaceholderText(input.GetKeyEnum(val))
				end
				if setting.onChange then setting.onChange(data) end
				chatBox.saveData()
			else
				self:SetPlaceholderText(self.data[self.val] and input.GetKeyEnum(self.data[self.val]) or "NOT SET")
			end
			self:KillFocus()
			chatBox.graphics.textEntry:RequestFocus()
		end
		textEntry.OnFocusChanged = function(self, gained)
			if gained then
				self:SetPlaceholderText("Press key")
			end
		end
		textEntry.AllowInput = function(self, char)
			return true
		end

		return default_width
	end,
	["boolean"] = function(sPanel, panel, data, y, w, h, setting)
		local checkBox = vgui.Create("DCheckBox", panel)
		checkBox:SetPos(w - 16, y)
		checkBox:SetValue(data[setting.value])
		checkBox:SetTooltip(setting.extra)

		checkBox.Think = function(self)
			if self.data.dataChanged[self.val] then
				self:SetValue(self.data[self.val])
				self.data.dataChanged[self.val] = false
			end
		end
		checkBox.Paint = function(self, w, h)
			local disabled = self:GetDisabled()
			local ticked = self:GetChecked()
			local c = disabled and 80 or 120
			draw.RoundedBox(0,0,0,w,h,Color(c,c,c,255))
			draw.RoundedBox(0,2,2,w-4,h-4,Color(c-40,c-40,c-40,255))

			if ticked then
				if disabled then
					draw.RoundedBox(0,3,3,w-6,h-6,Color(50,80,80,255))
				else
					draw.RoundedBox(0,3,3,w-6,h-6,Color(0,255,255,255))
				end
			end
		end

		checkBox.data = data
		checkBox.val = setting.value
		checkBox.unique = setting.unique
		checkBox.OnChange = function(self, val)
			local changed = self.data[self.val] ~= val
			if self.unique and val then
				for k, v in pairs(chatBox.channels) do
					v[self.val] = false
				end
			end
			self.data[self.val] = val
			if changed then
				if setting.onChange then setting.onChange(data) end
				chatBox.saveData()
			end
		end
		if setting.unique then
			checkBox.Think = function(self)
				self:SetValue(self.data[self.val])
				self:SetDisabled(self.data[self.val])
				self:SetCursor( self.data[self.val] and "no" or "Hand")
			end
		end

		return 16
	end,
	["options"] = function(sPanel, panel, data, y, w, h, setting)
		if not setting.optionValues then setting.optionValues = setting.options end
		local width = setting.overrideWidth or default_width
		local comboBox = vgui.Create("DComboBox", panel)
		comboBox:SetSortItems(false)
		comboBox:SetPos( w - width, y-2 )
		comboBox:SetSize(width,18)
		comboBox:SetTooltip(setting.extra)
		comboBox:SetDisabled(setting.disabled or false)

		local options = setting.options
		for k = 1, #options do
			comboBox:AddChoice(options[k], setting.optionValues[k])
		end
		local val = data[setting.value]
		local idx
		for k = 1, #setting.optionValues do
			local v = setting.optionValues[k]
			if val == v then
				idx = k
			end
		end

		if not idx then return width end -- should never happen (somehow its value isnt one of the options)

		comboBox:ChooseOption(options[idx], idx)

		comboBox.data = data
		comboBox.val = setting.value
		comboBox.setting = setting

		comboBox.Think = function(self)
			if self.data.dataChanged[self.val] then
				local setting = self.setting
				local val = self.data[self.val]
				local idx
				for k = 1, #setting.optionValues do
					local v = setting.optionValues[k]
					if val == v then
						idx = k
					end
				end

				self:ChooseOption(setting.options[idx], idx)
				self.data.dataChanged[self.val] = false
			end
			if self:IsMenuOpen() and not self.Menu.thinkSet then
				self.Menu.thinkSet = true
				self.Menu.Paint = function(self2, w, h)
					if not chatBox.isOpen then
						self2:GetParent():CloseMenu()
					end
					if ( !self2:GetPaintBackground() ) then return end

					derma.SkinHook( "Paint", "Menu", self2, w, h )
					return true
				end
			end
		end

		comboBox.OnSelect = function(self, idx, name, val)
			local changed = self.data[self.val] ~= val
			self.data[self.val] = val
			
			if changed then 
				if setting.onChange then setting.onChange(data) end
				chatBox.saveData()
			end
		end

		return width
	end,
	["button"] = function(sPanel, panel, data, y, w, h, setting)
		local button = vgui.Create("DButton", panel)
		local width = setting.overrideWidth or default_width

		local confirm = setting.requireConfirm

		button:SetText(setting.text)
		button:SetDisabled(setting.disabled or false)

		local bw, bh = width, 18
		button:SetSize(bw, bh)
		button:SetPos(w - bw, y-2)
		button:SetTooltip(setting.extra)
		button.setting = setting
		button.data = data
		button.confirm = confirm
		button.lastClick = 0
		button.DoClick = function(self)
			if not self.confirm or (CurTime() - self.lastClick < 2) then
				self.setting.onClick(self.data, self.setting)
				self.lastClick = 0
				if self.setting.closeOnTrigger then
					--TODO: Close here, might not be needed tho, literally only for kicking bots via the menu
				end
			else
				self.lastClick = CurTime()
			end
		end

		button.Think = function(self)
			if self.confirm and CurTime() - self.lastClick < 2 then
				self:SetText("CONFIRM")
				self:SetTextColor(Color(255,0,0))
			else
				if self.setting.toggle then
					self:SetText(self.data[self.setting.value] and self.setting.toggleText or self.setting.text)
				else
					self:SetText(self.setting.text)
				end
				self:SetTextColor(Color(0,0,0))
			end
		end

		button.DoRightClick = function(self)
			if setting.onRightClick then
				setting.onRightClick(data.ply, setting)
			end
		end

		return bw
	end,
	["color"] = function(sPanel, panel, data, y, w, h, setting)
		local curCol = data[setting.value]
		local width = setting.overrideWidth or default_width
		local allowedAlpha = setting.allowAlpha

		local button = vgui.Create( "DColorButton", panel )

		button:SetDisabled(setting.disabled or false)

		local bw, bh = width, 18
		button:SetSize(bw, bh)
		button:SetPos(w - bw, y-2)
		button:SetFont("BC_MonospaceSmall")
		button:SetTooltip(setting.extra)
		button:SetColor( data[setting.value], true )

		button.Paint = function(self, w, h)
			local col = self:GetColor()
			draw.RoundedBox( 2, 0, 0, w, h, Color(0,0,0) )
			draw.RoundedBox( 2, 1, 1, w-2, h-2, col )
			draw.DrawText( self:GetText(), self:GetFont(), w/2, h/4, Color( 210, 210, 210, 255 ), TEXT_ALIGN_CENTER )
			return true
		end
		button.DoClick = function(self)
			CloseDermaMenus()
			local btnH = 20
			local w,h = 267,186 + btnH
			local mixerFrame = vgui.Create( "DFrame" )

			mixerFrame:SetTitle("")
			mixerFrame:SetSize( w, h )
			mixerFrame:SetPos(gui.MouseX(), gui.MouseY()-h)
			mixerFrame:MakePopup()
			mixerFrame:SetDraggable(false)
			mixerFrame:ShowCloseButton(false)
			mixerFrame:SetIsMenu(true)

			local mixer -- Init here so mixerFrame can grab it

			mixerFrame.Paint = function(self, w, h)
				chatBox.blur( self, 10, 20, 255 )
				draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 200 ) )
			end

			mixerFrame.Think = function(self)
				if not chatBox.isOpen then
					self:Remove()
				end
			end

			mixerFrame.OnRemove = function(self)
				timer.Remove("BC_ColorHideTimer")
			end

			mixer = vgui.Create( "DColorMixer", mixerFrame )
			mixer:SetPos(2,2)
			mixer:SetSize(w-4,h-4 - btnH)
			mixer:SetColor(table.Copy(data[setting.value]))
			mixer:SetPalette( false ) 		--Show/hide the palette			DEF:true
			mixer:SetAlphaBar(allowedAlpha)

			local lastDown = false
			timer.Create("BC_ColorHideTimer", 1/30, 0, function()
				if not input.IsMouseDown(MOUSE_LEFT) and not input.IsMouseDown(MOUSE_RIGHT) then 
					lastDown = false
					return 
				end
				if lastDown then return end
				lastDown = true
				local mx, my = gui.MousePos()
				if not Vector(mx, my):WithinAABox(Vector(mixerFrame:LocalToScreen(0,0)), Vector(mixerFrame:LocalToScreen(w, h))) then
					mixerFrame:Remove()
				end
			end)

			local backBtn = vgui.Create( "DButton", mixerFrame )
			backBtn:SetText("Back")
			backBtn:SetSize(87, btnH - 2)
			backBtn:SetPos(2, h-btnH)
			backBtn.DoClick = function(self)
				mixerFrame:Remove()
			end

			local defaultBtn = vgui.Create( "DButton", mixerFrame )
			defaultBtn:SetText("Default")
			defaultBtn:SetSize(87, btnH - 2)
			defaultBtn:SetPos(w/2 - 40, h-btnH)
			defaultBtn.DoClick = function(self)
				mixer:SetColor(table.Copy(setting.default))
			end

			local confirmBtn = vgui.Create( "DButton", mixerFrame )
			confirmBtn:SetText("Confirm")
			confirmBtn:SetSize(81, btnH - 2)
			confirmBtn:SetPos(w - 80 - 3, h-btnH)
			confirmBtn.DoClick = function(self)
				if data[setting.value] ~= mixer:GetColor() then
					data[setting.value] = table.Copy(mixer:GetColor())
					if setting.onChange then setting.onChange(data) end
					chatBox.saveData()
				end
				mixerFrame:Remove()
			end

		end

		button.Think = function(self)
			self:SetColor(data[setting.value], true)
			local col = data[setting.value]
			self:SetText(chatBox.padString(col.r, 3, nil, true) .. 
				"|" .. chatBox.padString(col.g, 3, nil, true) .. 
				"|" .. chatBox.padString(col.b, 3, nil, true) .. 
				(allowedAlpha and ("|" .. chatBox.padString(col.a, 3, nil, true)) or "")
			)
			self:SetCursor( self:GetDisabled() and "no" or "Hand")

			if data.dataChanged[val] then
				data.dataChanged[val] = false -- This one just auto updates
				CloseDermaMenus() -- Just to be sure ;)
			end
		end

		return bw
	end,
	["blank"] = function(sPanel, panel, data, y, w, h, setting)
		return 0
	end,
}

function input.GetKeyEnum( keyCode )
	local name = input.GetKeyName(keyCode)
	return "KEY_" .. string.upper(name)
end

function chatBox.renderSetting(sPanel, data, setting, k)
	local panel = sPanel:GetCanvas()
	local w, h = sPanel:GetSize()
	local y = k*20 + 12

	local noName = setting.overrideWidth == -1

	local label
	if not noName then
		label = vgui.Create("DLabel", panel)
		label:SetText(setting.name)
		if setting.nameColor then
			label:SetTextColor(setting.nameColor)
		end
		if setting.extra then
			label:SetTooltip(setting.extra)
		end
		label:SetPos(10, y)
		label:SizeToContents()
		label:SetMouseInputEnabled(true)
	else
		setting = table.Copy(setting)
		setting.overrideWidth = w - 39
	end

	if not data.dataChanged then data.dataChanged = {} end

	local elemWidth = renderSettingFuncs[setting.type](sPanel, panel, data, y, w - 32, h, setting) or 0

	if not noName then
		local line = vgui.Create("DShape", panel)
		line:SetType("Rect")
		local lw, lh = label:GetSize()
		line:SetPos(15 + lw, y+7)
		line:SetSize(w - 32 - 15 - lw - 5 - elemWidth, 1)
		line:SetColor(Color(200, 200, 200, 150))
	end
end

hook.Add("BC_PreInitPanels", "BC_InitSidePanels", function()
	chatBox.sidePanels = {}
	chatBox.sidePanelsIDX = 0
end)

hook.Add("BC_KeyCodeTyped", "BC_SidePanelShortCutHook", function(code, ctrl, shift)
	if code == KEY_S then
		if ctrl then
			if shift then
				-- local s = chatBox.sidePanels["Global Settings"]
				-- if s.isOpen then
				-- 	chatBox.closeSidePanel(s.name)
				-- else
				-- 	chatBox.openSidePanel(s.name)
				-- end
				local s = chatBox.sidePanels["Player"]
				if not chatBox.panelExists("Player", LocalPlayer():SteamID()) then
					chatBox.generatePlayerPanelEntry(LocalPlayer())
				end
				if s.isOpen then
					chatBox.closeSidePanel(s.name)
				else
					chatBox.openSidePanel(s.name, LocalPlayer():SteamID())
				end
			else
				local s = chatBox.sidePanels["Channel Settings"]
				if s.isOpen then
					chatBox.closeSidePanel(s.name)
				else
					chatBox.openSidePanel(s.name, chatBox.getActiveChannel().name)
				end
			end
			return true
		end
	end
end)

function chatBox.createSidePanel(name, width, data)
	local size = { x = width, y = chatBox.graphics.size.y - 33 }
	chatBox.sidePanelsIDX = chatBox.sidePanelsIDX + 1
	chatBox.sidePanelWidth = chatBox.sidePanelWidth or 0
	local _, h = chatBox.graphics.frame:GetSize()
	chatBox.sidePanelWidth = chatBox.sidePanelWidth + size.x + 2
	chatBox.graphics.frame:SetSize(chatBox.graphics.size.x + chatBox.sidePanelWidth, h)

	local icon = data.icon or "icons/cog.png"
	local rot = data.rotate
	local col = data.col or Color(255,255,255)
	local border = data.border or 0

	local mat = chatBox.materials.getMaterial(icon)

	chatBox.sidePanels[name] = {}
	local s = chatBox.sidePanels[name]
	s.graphics = {}
	local g = s.graphics
	s.idx = chatBox.sidePanelsIDX

	s.isOpen = false
	s.animState = 1
	s.animDelta = 0.03
	s.size = size
	s.name = name
	g.panels = {}

	g.pane = vgui.Create( "DFrame", chatBox.graphics.frame )
	g.pane:SetName("BC_SettingsPane")
	g.pane:SetPos( chatBox.graphics.size.x, 0 )
	g.pane:SetSize( s.size.x, s.size.y )
	g.pane:SetTitle( "" )
	g.pane:ShowCloseButton(false)
	g.pane:SetDraggable(false)
	g.pane:SetSizable(false)
	g.pane:MoveToFront()
	g.pane.name = name
	s.lastTime = CurTime()

	local pOldLayout = g.pane.PerformLayout
	function g.pane:PerformLayout()
		s.size.y = chatBox.graphics.size.y - 33
		self:SetSize( s.size.x, s.size.y )
		pOldLayout(self)
	end

	g.pane:SetKeyboardInputEnabled(true)
	g.pane:SetMouseInputEnabled(true)

	g.pane.Think = function(self)
		local s = chatBox.sidePanels[self.name]
		local g = s.graphics

		local xSum = chatBox.graphics.size.x
		for k, v in pairs(chatBox.sidePanels) do
			if v.idx < s.idx and v.animState > 0 then
				xSum = xSum + (v.animState*v.size.x) + 2
			end
		end

		local px, py = getFrom(1, xSum) + 2, 0
		local cx, cy = self:GetPos()
		if cx ~= px or cy ~= py then
			self:SetPos(px, py)
		end

		local w = getFrom(1, g.frame:GetSize())
		local px, py = w*s.animState - w, 0
		local cx, cy = g.frame:GetPos()
		if px ~= cx or py ~= cy then
			g.frame:SetPos(px, py)
		end

		if not chatBox.isOpen then 
			s.isOpen = false
		end

		local tPassed = CurTime() - s.lastTime
		if tPassed > 0.1 then tPassed = 0 end
		s.lastTime = CurTime()
		tPassed = tPassed * 150

		if s.isOpen and s.animState < 1 then
			s.animState = math.min(1, s.animState + (s.animDelta * tPassed))
		elseif not s.isOpen and s.animState > 0 then
			s.animState = math.max(0, s.animState - (s.animDelta * tPassed))
		end
	end
	g.pane.Paint = function(self, w, h)
		local s = chatBox.sidePanels[self.name]
		local g = s.graphics

		chatBox.blur( self, 10, 20, 255, w*s.animState, h )
		local x = w*s.animState - w
		draw.RoundedBox( 0, x, 0, w, h, Color( 20, 20, 20, 200 ) )
		draw.RoundedBox( 0, x+4, 27, w-8 - 23, h - 4 - 27, Color( 130, 130, 130, 100 ) )
		draw.RoundedBox( 0, x+4 + w-8 - 20, 27, 20, h - 4 - 27, Color( 130, 130, 130, 100 ) )

		draw.RoundedBox( 0, x+4, 4, 21, 21, Color( 130, 130, 130, 100 ) )
		surface.SetFont(chatBox.graphics.font)
		local tw, th = surface.GetTextSize(self.name)
		draw.RoundedBox( 0, x+4 + 23, 4, tw+8, 21, Color( 130, 130, 130, 100 ) )
		draw.DrawText(self.name, chatBox.graphics.font, x+8 + 23, 4 + (21-th)/2, Color(255, 255, 255, 190))

		surface.SetDrawColor(col)
		surface.SetMaterial(mat)
		surface.DrawTexturedRectRotated(x + 6 + 9,6 + 9,19 - border*2,19 - border*2, rot and (-CurTime()*15) or 0)
	end

	g.frame = vgui.Create( "DFrame", g.pane )
	g.frame:SetName("BC_SettingsFrame")
	g.frame:SetPos( 0,0 )
	g.frame:SetSize(g.pane:GetSize())
	g.frame:SetTitle( "" )
	g.frame:ShowCloseButton(false)
	g.frame:SetDraggable(false)
	g.frame:SetSizable(false)
	g.frame.Paint = nil
	g.frame.name = name

	local fOldLayout = g.frame.PerformLayout
	function g.frame:PerformLayout()
		self:SetSize(self:GetParent():GetSize())
		fOldLayout(self)
	end

	g.frame.closeBtn = vgui.Create( "DButton", g.frame )
	local btn = g.frame.closeBtn
	local pane = g.frame
	btn.name = name
	btn:SetPos( getFrom(1, g.frame:GetSize()) - 4 - 20, 4 )
	btn:SetSize(20, 20)
	btn:SetText("")
	btn.DoClick = function(self)
		chatBox.closeSidePanel(self.name)
	end
	btn.Paint = function(self, w, h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 130, 130, 130, 100 ) )
		local cross1 = {
			{ x = 2, y = 5},
			{ x = 5, y = 2},
			{ x = 18, y = 15},
			{ x = 15, y = 18},
		}
		local cross2 = {
			{ x = 2, y = 15},
			{ x = 15, y = 2},
			{ x = 18, y = 5},
			{ x = 5, y = 18},
		}

		surface.SetDrawColor(150, 150, 150, 255)
		draw.NoTexture()
		surface.DrawPoly(cross1)
		surface.DrawPoly(cross2)
	end
end

function chatBox.addToSidePanel(pName, name)
	local s = chatBox.sidePanels[pName]
	local g = s.graphics
	local p = vgui.Create( "DNiceScrollPanel", g.frame )
	p.graphics = g
	local w, h = g.frame:GetSize()
	p:SetSize(w - 8 - 8, h - 4 - 27 - 10)
	p:SetPos(4 + 5, 27 + 5)

	local oldLayout = p.PerformLayout
	function p:PerformLayout()
		local w, h = self.graphics.frame:GetSize()
		self:SetSize(w - 8 - 8, h - 4 - 27 - 10)
		self:SetPos(4 + 5, 27 + 5)
		oldLayout( self )
	end
	
	table.insert(g.panels, {Name = name, Panel = p})
	p:Hide()
	return p
end

function chatBox.getSidePanelChild(pName, name)
	local s = chatBox.sidePanels[pName]
	local g = s.graphics
	for k, v in pairs(g.panels) do
		if v.Name == name then
			return v.Panel
		end
	end
	return false
end


function chatBox.removeFromSidePanel(pName, name, dontClose)
	local s = chatBox.sidePanels[pName]
	local g = s.graphics
	if s.activePanel == name and not dontClose then
		chatBox.closeSidePanel(pName, true)
	end
	local success = false
	for k, p in pairs(g.panels) do
		if p.Name == name then
			p.Panel:Remove()
			table.remove(g.panels, k)
			success = true
			break
		end
	end
	return success
end

function chatBox.showSidePanel(pName, name)
	local s = chatBox.sidePanels[pName]
	s.activePanel = name
	local g = s.graphics
	if not name then name = g.panels[1].Name end
	for k, v in pairs(g.panels) do
		if v.Name == name then
			v.Panel:Show()
		else
			v.Panel:Hide()
		end
	end
end

function chatBox.panelExists(pName, name)
	local s = chatBox.sidePanels[pName]
	local g = s.graphics
	for k, v in pairs(g.panels) do
		if v.Name == name then
			return true
		end
	end
	return false
end

function chatBox.openSidePanel(pName, name)
	chatBox.showSidePanel(pName, name)
	chatBox.sidePanels[pName].isOpen = true
end

function chatBox.closeSidePanel(pName, noAnim)
	chatBox.graphics.textEntry:RequestFocus()
	chatBox.sidePanels[pName].isOpen = false
	if noAnim then
		chatBox.sidePanels[pName].animState = 0
	end
end