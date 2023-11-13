hasRevertedGrowthText = false
hasUpdatedGrowthText = false

prevHJ = 0
prevQR = 0
prevDR = 0
prevAD = 0
prevG = 0

function _OnInit()
	print('Accurate Growth Levels v1.0.0')
	GoAOffset = 0x7C
	if (GAME_ID == 0xF266B00B or GAME_ID == 0xFAF99301) and ENGINE_TYPE == "ENGINE" then --PCSX2
		if ENGINE_VERSION < 3.0 then
			print('LuaEngine is Outdated. Things might not work properly.')
		end
		onPC = false
		Now = 0x032BAE0 --Current Location
		Save = 0x032BB30 --Save File
		Sys3Pointer = 0x1C61AF8 --03system.bin Pointer Address
	elseif GAME_ID == 0x431219CC and ENGINE_TYPE == 'BACKEND' then --PC
		if ENGINE_VERSION < 5.0 then
			ConsolePrint('LuaBackend is Outdated. Things might not work properly.',2)
		end
		onPC = true
		Now = 0x0714DB8 - 0x56454E
		Save = 0x09A7070 - 0x56450E
		Sys3Pointer = 0x2AE3550 - 0x56454E
		PauseMenu = 0xBEBD28-0x56454E
	end
	havePrinted = false
end

function _OnFrame()
	if true then --Define current values for common addresses
		Place  = ReadShort(Now+0x00)
		if Place == 0xFFFF or not MSN then
			if not onPC then
				Sys3 = ReadInt(Sys3Pointer)
			else
				Sys3 = ReadLong(Sys3Pointer)
			end
		end
	end
	
	Slot70 = Save+0x25CE -- High Jump
	Slot71 = Save+0x25D0 -- Quick Run
	Slot72 = Save+0x25D2 -- Dodge Roll
	Slot73 = Save+0x25D4 -- Aerial Dodge
	Slot74 = Save+0x25D6 -- Glide
	
	if ReadByte(PauseMenu) == 3 then
		-- In Pause Menu, put everything back to normal
		if not hasRevertedGrowthText then
			revertGrowthText(Save+0x25CE, Sys3+0x11754, 0x064C) -- High Jump
			revertGrowthText(Save+0x25D0, Sys3+0x117B4, 0x0654) -- Quick Run
			revertGrowthText(Save+0x25D2, Sys3+0x11814, 0x4E83) -- Dodge Roll
			revertGrowthText(Save+0x25D4, Sys3+0x11874, 0x065C) -- Aerial Dodge
			revertGrowthText(Save+0x25D6, Sys3+0x118D4, 0x0664) -- Glide
			hasRevertedGrowthText = true
			hasUpdatedGrowthText = false
		end
	else
		-- In the field, fuck shit up
		if hasAbilityChanged(prevHJ, Save+0x25CE) then
			prevHJ = updateGrowthText(Save+0x25CE, 0x05E, Sys3+0x11754, 0x064C) -- High Jump
		end
		if hasAbilityChanged(prevQR, Save+0x25D0) then
			prevQR = updateGrowthText(Save+0x25D0, 0x062, Sys3+0x117B4, 0x0654) -- Quick Run
		end
		if hasAbilityChanged(prevDR, Save+0x25D2) then
			prevDR = updateGrowthText(Save+0x25D2, 0x234, Sys3+0x11814, 0x4E83) -- Dodge Roll
		end
		if hasAbilityChanged(prevAD, Save+0x25D4) then
			prevAD = updateGrowthText(Save+0x25D4, 0x066, Sys3+0x11874, 0x065C) -- Aerial Dodge
		end
		if hasAbilityChanged(prevG, Save+0x25D6) then
			prevG = updateGrowthText(Save+0x25D6, 0x06A, Sys3+0x118D4, 0x0664) -- Glide
		end
		hasRevertedGrowthText = false
	end
end

function hasAbilityChanged(prevAbility, slotNum)
	slotAbility = ReadShort(slotNum) & 0x0FFF
	return prevAbility ~= slotAbility
end

function revertGrowthText(slotNum, baseLevelAddress, baseLevelName)
	lvl1 = baseLevelAddress
	lvl2 = lvl1 + 0x18
	lvl3 = lvl2 + 0x18
	lvl4 = lvl3 + 0x18
	WriteShort(lvl1+0x8, baseLevelName, onPC) -- Lvl 1
	WriteShort(lvl1+0xA, baseLevelName + 1, onPC) -- Lvl 1 Description
	WriteShort(lvl2+0x8, baseLevelName + 2, onPC) -- Lvl 2
	WriteShort(lvl2+0xA, baseLevelName + 3, onPC) -- Lvl 2 Description
	WriteShort(lvl3+0x8, baseLevelName + 4, onPC) -- Lvl 3
	WriteShort(lvl3+0xA, baseLevelName + 5, onPC) -- Lvl 3 Description
	WriteShort(lvl4+0x8, baseLevelName + 6, onPC) -- Max
	WriteShort(lvl4+0xA, baseLevelName + 7, onPC) -- Max Description
end

function updateGrowthText(slotNum, baseAbilityAddress, baseLevelAddress, baseLevelName)
	lvl1 = baseLevelAddress
	lvl2 = lvl1 + 0x18
	lvl3 = lvl2 + 0x18
	lvl4 = lvl3 + 0x18
	slotAbility = ReadShort(slotNum) & 0x0FFF
	if slotAbility < baseAbilityAddress then
		-- I don't have this growth at all, so set all growth text to Lvl 1
		WriteShort(lvl1+0x8, baseLevelName, onPC) -- Lvl 1
		WriteShort(lvl1+0xA, baseLevelName + 1, onPC) -- Lvl 1 Description
		WriteShort(lvl2+0x8, baseLevelName, onPC) -- Lvl 2
		WriteShort(lvl2+0xA, baseLevelName + 1, onPC) -- Lvl 2 Description
		WriteShort(lvl3+0x8, baseLevelName, onPC) -- Lvl 3
		WriteShort(lvl3+0xA, baseLevelName + 1, onPC) -- Lvl 3 Description
		WriteShort(lvl4+0x8, baseLevelName, onPC) -- Max
		WriteShort(lvl4+0xA, baseLevelName + 1, onPC) -- Max Description
	elseif slotAbility < (baseAbilityAddress + 3) then
		-- I have this growth in my inventory, set all growth text to next level
		currentGrowthLevel = slotAbility - baseAbilityAddress + 1
		nextLevelName = baseLevelName + (2 * currentGrowthLevel)
		nextLevelDescription = baseLevelName + 1 + (2 * currentGrowthLevel)
		WriteShort(lvl1+0x8, nextLevelName, onPC) -- Lvl 1
		WriteShort(lvl1+0xA, nextLevelDescription, onPC) -- Lvl 1 Description
		WriteShort(lvl2+0x8, nextLevelName, onPC) -- Lvl 2
		WriteShort(lvl2+0xA, nextLevelDescription, onPC) -- Lvl 2 Description
		WriteShort(lvl3+0x8, nextLevelName, onPC) -- Lvl 3
		WriteShort(lvl3+0xA, nextLevelDescription, onPC) -- Lvl 3 Description
		WriteShort(lvl4+0x8, nextLevelName, onPC) -- Max
		WriteShort(lvl4+0xA, nextLevelDescription, onPC) -- Max Description
	end

	return slotAbility
end
