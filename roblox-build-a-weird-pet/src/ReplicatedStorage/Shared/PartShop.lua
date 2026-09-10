-- PartShop.lua
-- Lets players buy a *specific* part outright (with DNA) instead of only
-- getting random ones from the Part Generator, so they can deliberately
-- chase a combo they have in mind. Secret-rarity parts are excluded on
-- purpose -- those stay generator-only so the five curated secret pets
-- keep feeling like a real discovery instead of a checkout item.

local PartShop = {}

PartShop.PriceByRarity = {
	Common = 15,
	Uncommon = 30,
	Rare = 60,
	Epic = 120,
	Legendary = 250,
	Mythic = 500,
	-- Secret intentionally has no price: not purchasable.
}

function PartShop.isPurchasable(part)
	return PartShop.PriceByRarity[part.rarity] ~= nil
end

function PartShop.priceFor(part)
	return PartShop.PriceByRarity[part.rarity]
end

return PartShop
