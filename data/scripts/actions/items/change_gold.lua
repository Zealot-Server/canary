local config = {
	[ITEM_GOLD_COIN] = { changeTo = ITEM_PLATINUM_COIN },
	[ITEM_PLATINUM_COIN] = { changeBack = ITEM_GOLD_COIN, changeTo = ITEM_CRYSTAL_COIN },
	[ITEM_CRYSTAL_COIN] = { changeBack = ITEM_PLATINUM_COIN },
}

local changeGold = Action()

function changeGold.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local coin = config[item:getId()]
	if coin.changeTo and item:getCount() == 100 then
		-- Keep the converted coin in the same slot, even when the inventory is full.
		return item:transform(coin.changeTo, 1)
	elseif coin.changeBack then
		item:remove(1)
		player:addItem(coin.changeBack, 100)
		return true
	end
	return false
end

changeGold:id(ITEM_GOLD_COIN, ITEM_PLATINUM_COIN, ITEM_CRYSTAL_COIN)
changeGold:register()
