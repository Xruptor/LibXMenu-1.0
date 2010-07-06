--[[
	LibXMenu-1.0.lua
	Created By: Xruptor
	
	A simple DropDown library for creating interactive menus.
	
	Example using each available option:
	
		local dd1 = LibStub('LibXMenu-1.0'):New("DropDownName", database)
		dd1.db.color1val = { r = 0, g = 0, b = 0, a = 1, }
		dd1.initialize = function(self, lvl)
			if lvl == 1 then
				self:AddTitle(lvl, "My DropDown")
				self:AddList(lvl, "Font Size", "fontsize")
				self:AddList(lvl, "Advance List", "advancelist")
				self:AddColor(lvl, "Color 1", "color1val")
				self:AddToggle(lvl, "Switch", "switch")
				self:AddToggle(lvl, "Switch2", "switch2", otherdb, "otherdboption2")
			elseif lvl and lvl > 1 then
				local sub = UIDROPDOWNMENU_MENU_VALUE
				if sub == "fontsize" then
					--loop selection add
					for i = 5, 12, 1 do
						self:AddSelect(lvl, i, i, "fontsize", nil)
					end
				elseif sub == "advancelist" then
					--several different ways of adding selects
					self:AddSelect(lvl, i, i, db, "dboption1", nil)
					self:AddSelect(lvl, i, i, "dboption2", nil)
					self:AddSelect(lvl, i, i, nil, nil)
				end
			end
		end
		dd1.doUpdate = function()
			--fired after every menu selection click
			doDisplayUpdates();
		end
		
		ToggleDropDownMenu(1, nil, dd1, "cursor")
		
--]]

local MAJOR, MINOR = "LibXMenu-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

--DO NOT MODIFY
--Used to prevent checks from displaying on Menulist title options
local function HideCheck(item)
	if item and item.GetName and _G[item:GetName().."Check"] then
		_G[item:GetName().."Check"]:Hide()
	end
end

--[[
	lib:AddButton
		(NOTE:)	This function is automatically called by each menu item insertion.
				You should only use this function if your going to use your own custom button.
	lvl					- menu level 1,2,3 etc...
	text				- name of the menu item
	keepShownOnClick	- (optional) toggle if the menu item should be shown or not on click (true/false)
--]]

local function AddButton(self, lvl, text, keepshown)
	if not lvl then return end
	if not text then return end
	self.info.text = text
	self.info.keepShownOnClick = keepshown
	self.info.owner = self
	UIDropDownMenu_AddButton(self.info, lvl)
	wipe(self.info)
end

--[[
	lib:AddToggle
	lvl					- menu level 1,2,3 etc...
	text				- name of the menu item
	value				- element in the database table, used when arg1 and arg2 are both nil.  Example:  db[value]
	arg1				- custom database variable, if arg2 is nil then value is used as element.  Example:  arg1[value]
	arg2				- custom database element for arg1.  Example:  arg1[arg2]
	func				- define custom function for menu item
--]]

local function AddToggle(self, lvl, text, value, arg1, arg2, func)
	if not lvl then return end
	if not text then return end
	if not value then return end
	
	value = tonumber(value) or value
	self.info.arg1 = arg1
	self.info.arg2 = arg2
	self.info.func = func or function(item, arg1, arg2)
		if arg1 and arg2 then
			arg1[arg2] = not arg1[arg2]
		elseif arg1 then
			arg1[item.value] = not arg1[item.value]
		else
			item.owner.db[item.value] = not item.owner.db[item.value]
		end
		if item.owner.doUpdate then item.owner.doUpdate() end
	end
	if arg1 and arg2 then
		self.info.checked = arg1[arg2]
	elseif arg1 then
		self.info.checked = arg1[value]
	else
		self.info.checked = self.db[value]
	end
	AddButton(self, lvl, text, 1)
end

--[[
	lib:AddList
	lvl					- menu level 1,2,3 etc...
	text				- name of the menu item
	value				- menuList value, used in UIDROPDOWNMENU_MENU_VALUE when lvl > 1.
--]]

local function AddList(self, lvl, text, value)
	if not lvl then return end
	if not text then return end
	if not value then return end
	
	self.info.value = value
	self.info.hasArrow = true
	self.info.func = HideCheck
	AddButton(self, lvl, text, 1)
end

--[[
	lib:AddSelect
	lvl					- menu level 1,2,3 etc...
	text				- name of the menu item
	value				- 	Value in database to compare and store, default when arg1 and arg2 are nil.
							If arg1 and arg2 then value is stored in the arg1[arg2] table.
							If arg1 and not arg2 then value is stored in db[arg1] table.
							if not arg1 and arg2 then value is stored in arg2[value] table.
	arg1				- 	custom database variable, if arg2 then acts as primary database. Example: arg1[arg2]
							if not arg2 then arg1 is used as an element of the database table.  Example: db[arg1]
	arg2				- 	custom database variable, if arg1 then acts as an element in arg1 table. Example: arg1[arg2]
							if not arg1 then arg2 is used as custom database table with value as element.  Example: arg2[value]
	func				- define custom function for menu item
--]]

local function AddSelect(self, lvl, text, value, arg1, arg2, func)
	if not lvl then return end
	if not text then return end
	if not value then return end
	
	value = tonumber(value) or value
	self.info.arg1 = arg1
	self.info.arg2 = arg2
	self.info.value = value
	self.info.func = func or function(item, arg1, arg2)
		local val = tonumber(item.value) or item.value
		if arg1 and arg2 then
			arg1[arg2] = val
		elseif arg1 then
			item.owner.db[arg1] = val
		elseif arg2 then
			arg2[val] = val
		else
			item.owner.db[val] = val
		end
		local level, num = strmatch(item:GetName(), "DropDownList(%d+)Button(%d+)")
		level, num = tonumber(level) or 0, tonumber(num) or 0
		for i = 2, level, 1 do
			for j = 1, UIDROPDOWNMENU_MAXBUTTONS, 1 do
				local check = _G["DropDownList"..i.."Button"..j.."Check"]
				if check and i == level and j == num then
					check:Show()
				elseif item then
					check:Hide()
				end
			end
		end
		if item.owner.doUpdate then item.owner.doUpdate() end
	end
	if arg1 and arg2 then
		self.info.checked = arg1[arg2] == value
	elseif arg1 then
		self.info.checked = self.db[arg1] == value
	elseif arg2 then
		self.info.checked = arg2[value] == value
	else
		self.info.checked = self.db[value] == value
	end
	AddButton(self, lvl, text, 1)
end

--[[
	lib:AddButton
		(NOTE:)	A color table must be first established before using this function
	lvl					- menu level 1,2,3 etc...
	text				- name of the menu item
	value				- database element value or name. Example: db[value]
--]]

local function AddColor(self, lvl, text, value)
	if not lvl then return end
	if not text then return end
	if not value then return end
	
	local db = self.db[value]
	if not db then return end
	local SetColor = function(item)
		local colDB = _G[self:GetName()].db[UIDROPDOWNMENU_MENU_VALUE]
		if not colDB then return end
		local r, g, b, a
		if item then
			local pv = ColorPickerFrame.previousValues
			r, g, b, a = pv.r, pv.g, pv.b, 1 - pv.opacity
		else
			r, g, b = ColorPickerFrame:GetColorRGB()
			a = 1 - OpacitySliderFrame:GetValue()
		end
		colDB.r, colDB.g, colDB.b, colDB.a = r, g, b, a
		if _G[self:GetName()].doUpdate then _G[self:GetName()].doUpdate() end
	end
	self.info.hasColorSwatch = true
	self.info.hasOpacity = 1
	self.info.r, self.info.g, self.info.b, self.info.opacity = db.r, db.g, db.b, 1 - db.a
	self.info.swatchFunc, self.info.opacityFunc, self.info.cancelFunc = SetColor, SetColor, SetColor
	self.info.value = value
	self.info.func = UIDropDownMenuButton_OpenColorPicker
	AddButton(self, lvl, text, nil)
end

--[[
	lib:AddTitle
	lvl					- menu level 1,2,3 etc...
	text				- name of the menu item
--]]

local function AddTitle(self, lvl, text)
	if not lvl then return end
	if not text then return end
	self.info.isTitle = true
	AddButton(self, lvl, text)
end

--[[
	lib:AddCloseButton
	lvl					- menu level 1,2,3 etc...
	text				- name of the menu item
--]]

local function AddCloseButton(self, lvl, text)
	if not lvl then return end
	if not text then return end
	self.info.func = function() CloseDropDownMenus() end
	AddButton(self, lvl, text)
end

--[[
	lib:New
	selfName			- name of the dropdown menu
	db					- database for the dropdown menu to use
--]]

function lib:New(selfName, db)
	if not selfName then print("LibXMenu-1.0: Error, DropDown requires a name") return end
	if not db then print("LibXMenu-1.0: Error, DropDown requires a Database") return end
	
	local dd = CreateFrame("Frame", selfName, UIParent)
	dd.db = db
	dd.info = {}
	dd.displayMode = "MENU"
	dd.AddButton = AddButton
	dd.AddToggle = AddToggle
	dd.AddList = AddList
	dd.AddSelect = AddSelect
	dd.AddColor = AddColor
	dd.AddTitle = AddTitle
	dd.AddCloseButton = AddCloseButton
	dd.doUpdate = function() end
	return dd
end
