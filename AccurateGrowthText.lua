function _OnInit()
	kh2libstatus, kh2lib = pcall(require, "kh2lib")
	DebugEnabled = false

	if not kh2libstatus then
		print("ERROR (My Script): KH2-Lua-Library mod is not installed")
		CanExecute = false
		return
	end

    CanExecute = kh2lib.CanExecute
    if not CanExecute then
		print("Failed to Execute Script")
        return
    end

	RequireKH2LibraryVersion(1)
	RequirePCGameVersion()

	Log('Accurate Growth Levels v1.2.0')

	Now = kh2lib.Now
	Save = kh2lib.Save
	Sys3Pointer = kh2lib.Sys3Pointer
	PauseMenu = kh2lib.CurrentOpenMenu
	Sys3 = ReadPointer(Sys3Pointer)

	InitGrowth()
	HasRevertedGrowthText = false
end

function _OnFrame()
    if not CanExecute then
        return
    end

	if ReadByte(PauseMenu) == 0x0A then
		-- In Pause Menu, put everything back to normal
		if not HasRevertedGrowthText then
			for key, ability in pairs(Growth) do
				if DebugEnabled then Log("Reverting " .. key .. " in inventory") end
				RevertGrowthText(ability["anchor"], ability["baseLevelText"])
			end
		end
		HasRevertedGrowthText = true
	else
		-- In the field, fuck shit up
		for key, ability in pairs(Growth) do
			UpdateGrowthText(ability, key)
		end
		HasRevertedGrowthText = false
	end
end

function InitGrowth()
	Growth = {}
	Growth["highJump"]		= {anchor = Sys3+0x11754, baseLevelText = 0x064C, slot = Save+0x25CE, itemID = 0x05E, prev = -1}
	Growth["quickRun"]		= {anchor = Sys3+0x117B4, baseLevelText = 0x0654, slot = Save+0x25D0, itemID = 0x062, prev = -1}
	Growth["dodgeRoll"]		= {anchor = Sys3+0x11814, baseLevelText = 0x4E83, slot = Save+0x25D2, itemID = 0x234, prev = -1}
	Growth["aerialDodge"]	= {anchor = Sys3+0x11874, baseLevelText = 0x065C, slot = Save+0x25D4, itemID = 0x066, prev = -1}
	Growth["glide"]			= {anchor = Sys3+0x118D4, baseLevelText = 0x0664, slot = Save+0x25D6, itemID = 0x06A, prev = -1}
end

function RevertGrowthText(anchor, baseLevelText)
	local levels = GetLevelAnchors(anchor)

	for idx, lvl in pairs(levels) do
		local nameShift = idx * 2 - 2
		local descriptionShift = nameShift + 1

		WriteShort(lvl+0x8, baseLevelText + nameShift, true)		-- Ability Name
		WriteShort(lvl+0xA, baseLevelText + descriptionShift, true)	-- Ability Description
		if DebugEnabled then Log("Reverted Level " .. idx) end
	end
end

function UpdateGrowthText(growth, name)
	local levels = GetLevelAnchors(growth["anchor"])
	local slotAbility = ReadShort(growth["slot"]) & 0x0FFF

	if growth["prev"] ~= slotAbility or HasRevertedGrowthText then
		if slotAbility < growth["itemID"] then
			-- I don't have this growth at all, so set all growth text to Lvl 1
			if DebugEnabled then Log("Update " .. name .. " in field to Level 1") end
			for idx, lvl in pairs(levels) do
				WriteShort(lvl+0x8, growth["baseLevelText"], true)		-- Ability Name
				WriteShort(lvl+0xA, growth["baseLevelText"] + 1, true)	-- Ability Description
			end
		elseif slotAbility < (growth["itemID"] + 3) then
			-- I have this growth in my inventory, set all growth text to next level
			local nextLevel = (slotAbility - growth["itemID"] + 1) * 2
			local nextLevelName = growth["baseLevelText"] + nextLevel
			local nextLevelDescription = growth["baseLevelText"] + 1 + nextLevel

			if DebugEnabled then Log("Update ".. name .. " in field to Level " .. math.floor(nextLevel / 2) + 1) end
			
			for idx, lvl in pairs(levels) do
				WriteShort(lvl+0x8, nextLevelName, true)		-- Ability Name
				WriteShort(lvl+0xA, nextLevelDescription, true)	-- Ability Description
			end
		else
			-- Growth is Max Level
			if DebugEnabled then Log(name .. " is max level, no update required") end
		end
	else
		-- Already updated, no change needed
	end
	growth["prev"] = ReadShort(growth["slot"]) & 0x0FFF
end

function GetLevelAnchors(anchor)
	return {
		anchor,			-- Level 1
		anchor + 0x18,	-- Level 2
		anchor + 0x30,	-- Level 3
		anchor + 0x48	-- Max
	}
end
