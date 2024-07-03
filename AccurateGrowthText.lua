function _OnInit()
	GameVersion = 0
	hasRevertedGrowthText = false
	print('Accurate Growth Levels v1.1.0')
end
	
function getVersion()
	if GAME_ID == 0x431219CC and ENGINE_TYPE == 'BACKEND' then --PC
		onPC = true
		if ReadString(0x09A92F0,4) == 'KH2J' then --EGS
			GameVersion = 2 -- Epic Version
			Now = 0x0716DF8
			Save = 0x09A92F0
			Sys3Pointer = 0x2AE5890
			PauseMenu = 0x743350
			Sys3 = ReadLong(Sys3Pointer)
		elseif ReadString(0x09A9830,4) == 'KH2J' then --Steam Global
			GameVersion = 3 -- Steam Global Version
			Now = 0x0717008
			Save = 0x09A9830
			Sys3Pointer = 0x2AE5DD0
			PauseMenu = 0x7435D0
			Sys3 = ReadLong(Sys3Pointer)
		elseif ReadString(0x09A8830,4) == 'KH2J' then --Steam JP
			GameVersion = 4 -- Steam JP Version
			Now = 0x0716008
			Save = 0x09A8830
			Sys3Pointer = 0x2AE4DD0
			PauseMenu = 0x7425D0
			Sys3 = ReadLong(Sys3Pointer)
		end
	end
end

function initGrowth()
	if onPC then
		highJump = {
			anchor = Sys3+0x11754,
			baseLevelText = 0x064C,
			slot = Save+0x25CE,
			itemID = 0x05E,
			prev = -1
		}
		quickRun = {
			anchor = Sys3+0x117B4,
			baseLevelText = 0x0654,
			slot = Save+0x25D0,
			itemID = 0x062,
			prev = -1
		}
		dodgeRoll = {
			anchor = Sys3+0x11814,
			baseLevelText = 0x4E83,
			slot = Save+0x25D2,
			itemID = 0x234,
			prev = -1
		}
		aerialDodge = {
			anchor = Sys3+0x11874,
			baseLevelText = 0x065C,
			slot = Save+0x25D4,
			itemID = 0x066,
			prev = -1
		}
		glide = {
			anchor = Sys3+0x118D4,
			baseLevelText = 0x0664,
			slot = Save+0x25D6,
			itemID = 0x06A,
			prev = -1
		}
	end
end

function _OnFrame()
	if GameVersion == 0 then --Get anchor addresses
		getVersion()
		initGrowth()
		return
	end

	if not onPC then
		return
	end
	
	if ReadByte(PauseMenu) == 3 then
		-- In Pause Menu, put everything back to normal
		if not hasRevertedGrowthText then
			revertGrowthText(highJump)
			revertGrowthText(quickRun)
			revertGrowthText(dodgeRoll)
			revertGrowthText(aerialDodge)
			revertGrowthText(glide)
			hasRevertedGrowthText = true
		end
	else
		-- In the field, fuck shit up
		updateGrowthText(highJump)
		updateGrowthText(quickRun)
		updateGrowthText(dodgeRoll)
		updateGrowthText(aerialDodge)
		updateGrowthText(glide)
		hasRevertedGrowthText = false
	end
end

function revertGrowthText(growth)
	lvl1 = growth["anchor"]
	lvl2 = lvl1 + 0x18
	lvl3 = lvl2 + 0x18
	lvl4 = lvl3 + 0x18
	WriteShort(lvl1+0x8, growth["baseLevelText"], onPC) -- Lvl 1
	WriteShort(lvl1+0xA, growth["baseLevelText"] + 1, onPC) -- Lvl 1 Description
	WriteShort(lvl2+0x8, growth["baseLevelText"] + 2, onPC) -- Lvl 2
	WriteShort(lvl2+0xA, growth["baseLevelText"] + 3, onPC) -- Lvl 2 Description
	WriteShort(lvl3+0x8, growth["baseLevelText"] + 4, onPC) -- Lvl 3
	WriteShort(lvl3+0xA, growth["baseLevelText"] + 5, onPC) -- Lvl 3 Description
	WriteShort(lvl4+0x8, growth["baseLevelText"] + 6, onPC) -- Max
	WriteShort(lvl4+0xA, growth["baseLevelText"] + 7, onPC) -- Max Description
end

function updateGrowthText(growth)
	lvl1 = growth["anchor"]
	lvl2 = lvl1 + 0x18
	lvl3 = lvl2 + 0x18
	lvl4 = lvl3 + 0x18
	slotAbility = ReadShort(growth["slot"]) & 0x0FFF
	if growth["prev"] ~= slotAbility or hasRevertedGrowthText then
		if slotAbility < growth["itemID"] then
			-- I don't have this growth at all, so set all growth text to Lvl 1
			WriteShort(lvl1+0x8, growth["baseLevelText"], onPC) -- Lvl 1
			WriteShort(lvl2+0x8, growth["baseLevelText"], onPC) -- Lvl 2
			WriteShort(lvl3+0x8, growth["baseLevelText"], onPC) -- Lvl 3
			WriteShort(lvl4+0x8, growth["baseLevelText"], onPC) -- Max
			WriteShort(lvl1+0xA, growth["baseLevelText"] + 1, onPC) -- Lvl 1 Description
			WriteShort(lvl2+0xA, growth["baseLevelText"] + 1, onPC) -- Lvl 2 Description
			WriteShort(lvl3+0xA, growth["baseLevelText"] + 1, onPC) -- Lvl 3 Description
			WriteShort(lvl4+0xA, growth["baseLevelText"] + 1, onPC) -- Max Description
		elseif slotAbility < (growth["itemID"] + 3) then
			-- I have this growth in my inventory, set all growth text to next level
			currentGrowthLevel = slotAbility - growth["itemID"] + 1
			nextLevelName = growth["baseLevelText"] + (2 * currentGrowthLevel)
			nextLevelDescription = growth["baseLevelText"] + 1 + (2 * currentGrowthLevel)
			WriteShort(lvl1+0x8, nextLevelName, onPC) -- Lvl 1
			WriteShort(lvl2+0x8, nextLevelName, onPC) -- Lvl 2
			WriteShort(lvl3+0x8, nextLevelName, onPC) -- Lvl 3
			WriteShort(lvl4+0x8, nextLevelName, onPC) -- Max
			WriteShort(lvl1+0xA, nextLevelDescription, onPC) -- Lvl 1 Description
			WriteShort(lvl2+0xA, nextLevelDescription, onPC) -- Lvl 2 Description
			WriteShort(lvl3+0xA, nextLevelDescription, onPC) -- Lvl 3 Description
			WriteShort(lvl4+0xA, nextLevelDescription, onPC) -- Max Description
		end
	end
	growth["prev"] = ReadShort(growth["slot"]) & 0x0FFF
end
