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
	{ text = "All aboard! The Sea Cat sails new adventurers to the mainland." },
	{ text = "Level 8 and a vocation are all you need for a free passage." },
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
local mainlandTowns = {
	thais = {
		name = "Thais",
		id = TOWNS_LIST.THAIS,
		destination = Position(32310, 32210, 6),
		topic = 2,
	},
	carlin = {
		name = "Carlin",
		id = TOWNS_LIST.CARLIN,
		destination = Position(32387, 31820, 6),
		topic = 3,
	},
	venore = {
		name = "Venore",
		id = TOWNS_LIST.VENORE,
		destination = Position(32954, 32022, 6),
		topic = 4,
	},
}

local townTopics = {}
for _, town in pairs(mainlandTowns) do
	townTopics[town.topic] = town
end

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

local function travelToMainland(npc, creature, town)
	local player = Player(creature)
	local destinationTown = Town(town.id)

	if not destinationTown then
		npcHandler:say("The harbour is not ready yet. Please speak with me again shortly.", npc, creature)
		return
	end

	if not player:teleportTo(town.destination) then
		npcHandler:say("I cannot prepare the passage right now. Please speak with me again in a moment.", npc, creature)
		return
	end

	removeMainlandSmugglingItems(player)
	player:setTown(destinationTown)
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	player:setStorageValue(Storage.Dawnport.Mainland, 1)
	npcHandler:say("Cast off! Welcome to " .. town.name .. " and the mainland. May Zealot bring you great adventures!", npc, creature)
	npcHandler:resetNpc(creature)
	npcHandler:removeInteraction(npc, creature)
end

local function offerTownSelection(npc, creature)
	npcHandler:say("Your vocation is chosen and you are ready to leave Rookgaard. I can take you to {Thais}, {Carlin}, or {Venore} for free. Which city do you choose?", npc, creature)
	npcHandler:setTopic(Player(creature):getId(), 1)
end

local function greetCallback(npc, creature)
	local player = Player(creature)
	local playerId = player:getId()

	if player:getLevel() < 8 then
		npcHandler:setMessage(MESSAGE_GREET, "Welcome aboard the Sea Cat, |PLAYERNAME|. Reach level 8 first, then choose your vocation with Oressa before travelling to the mainland.")
	elseif player:getVocation():getId() == VOCATION.ID.NONE then
		npcHandler:setMessage(MESSAGE_GREET, "You are ready for the mainland, |PLAYERNAME|, but you must choose your vocation with Oressa first. Return when you are ready to sail.")
	else
		npcHandler:setTopic(playerId, 1)
		npcHandler:setMessage(MESSAGE_GREET, "Welcome aboard the Sea Cat, |PLAYERNAME|. Your vocation is chosen and you are ready to leave Rookgaard. I can take you to {Thais}, {Carlin}, or {Venore} for free. Which city do you choose?")
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	local selectedTown = townTopics[npcHandler:getTopic(playerId)]

	if MsgContains(message, "yes") and selectedTown then
		travelToMainland(npc, creature, selectedTown)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "no") and selectedTown then
		npcHandler:say("No trouble. Which city would you prefer: {Thais}, {Carlin}, or {Venore}?", npc, creature)
		npcHandler:setTopic(playerId, 1)
	elseif MsgContains(message, "thais") or MsgContains(message, "carlin") or MsgContains(message, "venore") then
		if player:getLevel() < 8 then
			npcHandler:say("The mainland is for adventurers level 8 or higher. Train here a little longer and return when you are ready.", npc, creature)
		elseif player:getVocation():getId() == VOCATION.ID.NONE then
			npcHandler:say("Before sailing, speak with Oressa in the temple and choose your vocation. Then I will take you to the mainland.", npc, creature)
		else
			local town = MsgContains(message, "thais") and mainlandTowns.thais or MsgContains(message, "carlin") and mainlandTowns.carlin or mainlandTowns.venore
			npcHandler:say("Do you want a free passage to " .. town.name .. "?", npc, creature)
			npcHandler:setTopic(playerId, town.topic)
		end
	elseif MsgContains(message, "mainland") or MsgContains(message, "passage") or MsgContains(message, "travel") or MsgContains(message, "sail") then
		if player:getLevel() < 8 then
			npcHandler:say("The mainland is for adventurers level 8 or higher. Train here a little longer and return when you are ready.", npc, creature)
		elseif player:getVocation():getId() == VOCATION.ID.NONE then
			npcHandler:say("Before sailing, speak with Oressa in the temple and choose your vocation. Then I will take you to the mainland.", npc, creature)
		else
			offerTownSelection(npc, creature)
		end
	elseif MsgContains(message, "no") and npcHandler:getTopic(playerId) == 1 then
		npcHandler:say("No trouble. Return whenever you are ready for the mainland.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	end

	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_FAREWELL, "Fair winds, traveller.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
