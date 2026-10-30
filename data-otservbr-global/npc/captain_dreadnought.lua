local internalNpcName = "Captain Dreadnought"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName
npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2
npcConfig.outfit = {
	lookType = 155,
	lookHead = 96,
	lookBody = 0,
	lookLegs = 78,
	lookFeet = 96,
	lookAddons = 1,
}
npcConfig.flags = {
	floorchange = false,
}
npcConfig.voices = {
	interval = 15000,
	chance = 50,
	{ text = "All aboard! The Sea Cat sails directly to the mainland." },
	{ text = "Level 8 and a vocation are all you need for a passage to Thais." },
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
local mainlandDestination = Position(32310, 32210, 6)

npcType.onThink = function(npc, interval)
	npcHandler:onThink(npc, interval)
end

npcType.onAppear = function(npc, creature)
	npcHandler:onAppear(npc, creature)
end

npcType.onDisappear = function(npc, creature)
	npcHandler:onDisappear(npc, creature)
end

npcType.onMove = function(npc, creature, fromPosition, toPosition)
	npcHandler:onMove(npc, creature, fromPosition, toPosition)
end

npcType.onSay = function(npc, creature, type, message)
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

local function travelToMainland(npc, creature)
	local player = Player(creature)
	local thais = Town(TOWNS_LIST.THAIS)

	if not thais then
		npcHandler:say("The harbour is not ready yet. Please speak with me again shortly.", npc, creature)
		return
	end

	removeMainlandSmugglingItems(player)
	player:setTown(thais)
	player:teleportTo(mainlandDestination)
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	player:setStorageValue(Storage.Dawnport.Mainland, 1)
	npcHandler:say("Cast off! Welcome to Thais and the mainland. May Zealot bring you great adventures!", npc, creature)
	npcHandler:resetNpc(creature)
	npcHandler:removeInteraction(npc, creature)
end

local function greetCallback(npc, creature)
	local player = Player(creature)

	if player:getLevel() < 8 then
		npcHandler:setMessage(MESSAGE_GREET, "Welcome aboard the Sea Cat, |PLAYERNAME|. Reach level 8 first, then choose your vocation with Oressa before travelling to the mainland.")
	elseif player:getVocation():getId() == VOCATION.ID.NONE then
		npcHandler:setMessage(MESSAGE_GREET, "You are ready for the mainland, |PLAYERNAME|, but you must choose your vocation with Oressa first. Return when you are ready to sail.")
	else
		npcHandler:setMessage(MESSAGE_GREET, "Welcome aboard the Sea Cat, |PLAYERNAME|. I can take you directly to Thais on the mainland for free. Say {mainland} when you are ready to depart.")
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if MsgContains(message, "mainland") or MsgContains(message, "passage") or MsgContains(message, "travel") or MsgContains(message, "sail") then
		if player:getLevel() < 8 then
			npcHandler:say("The mainland is for adventurers level 8 or higher. Train here a little longer and return when you are ready.", npc, creature)
		elseif player:getVocation():getId() == VOCATION.ID.NONE then
			npcHandler:say("Before sailing, speak with Oressa in the temple and choose your vocation. Then I will take you straight to Thais.", npc, creature)
		else
			npcHandler:say("The Sea Cat will take you directly to Thais on the mainland. The passage is free. Do you want to depart now?", npc, creature)
			npcHandler:setTopic(playerId, 1)
		end
	elseif MsgContains(message, "yes") and npcHandler:getTopic(playerId) == 1 then
		travelToMainland(npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "no") and npcHandler:getTopic(playerId) == 1 then
		npcHandler:say("No trouble. Return whenever you are ready for the mainland.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "thais") then
		npcHandler:say("Thais is the first mainland city for every new Zealot adventurer. Say {mainland} when you are ready to sail.", npc, creature)
	end

	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_FAREWELL, "Fair winds, traveller.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
