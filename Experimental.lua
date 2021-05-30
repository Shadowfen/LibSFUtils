-- LibSFUtils is already defined in prior loaded file

sfutil = LibSFUtils

-- -----------------------------------------------------------------------
-- experimental functions - not ready for prime-time
-- -----------------------------------------------------------------------


function sfutil.getDLCs()
	d("COLLECTIBLE_CATEGORY_TYPE_DLC = "..COLLECTIBLE_CATEGORY_TYPE_DLC)
    for categoryIndex = 1, GetNumCollectibleCategories() do
        local categoryName, numSubCategories, numCollectibles, unlockedCollectibles = 
				GetCollectibleCategoryInfo(categoryIndex)
		--d("categoryIndex="..categoryIndex.."  category Name="..categoryName)
		if(categoryName == "Stories") then
			d("Name: "..categoryName.."  Index: "..categoryIndex)
			d("Num subcategories: "..numSubCategories)
			for subcategoryIndex = 1, numSubCategories do
				local subCategoryName, subNumCollectibles, subNumUnlockedCollectibles = 
					GetCollectibleSubCategoryInfo(categoryIndex, subcategoryIndex)
				if( subCategoryName ~= nil ) then
					d("->SubName: "..subCategoryName.."  index: "..subcategoryIndex)
				else
					d("->Sub category Index: "..subcategoryIndex)
				end
				d("->Num subcollectibles: "..subNumCollectibles)	
				--
				local formattedSubcategoryName = 
					zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, subCategoryName)
				d("formattedSubcategoryName->"..formattedSubcategoryName)
				for coll=1, subNumCollectibles do
					local id = GetCollectibleId(categoryIndex, 
						subcategoryIndex, coll)
					local name, description, iconFile, deprecatedLockedIconFile, 
						unlocked, purchasable, active, categoryType, hint, 
						isPlaceholder = GetCollectibleInfo(id)
					local unlockState = GetCollectibleUnlockStateById(id)
					d("index: "..coll.."  id: "..id.."  Name: "..name.."  unlocked: "..sfutil.bool2str(unlocked).."  active: "..sfutil.bool2str(active))
 				end
				--]]
			end
		end
	end
end

function sfutil.getChapters()
    local name, _, numCollectibles, unlockedCollectibles, _, _, collectibleCategoryType = GetCollectibleCategoryInfo(COLLECTIBLE_CATEGORY_TYPE_CHAPTER)
     d("Number of Chapters: ".. numCollectibles)
    for i=1, numCollectibles do
        local collectibleId = GetCollectibleId(COLLECTIBLE_CATEGORY_TYPE_CHAPTER, nil, i)
        local collectibleName, _, _, _, unlocked = GetCollectibleInfo(collectibleId) 
			-- Will return true or false. If the user unlocked through ESO+ without buying DLC it will return true.
        d(sfutil.str("DLC ", collectibleName, "( ", collectibleId, ") unlocked : ",
			tostring(unlocked)))
    end
end

function sfutil.gettags(bagId,slotId)
	local itemLink = GetItemLink(bagId, slotId)
    for i=1, GetItemLinkNumItemTags(itemLink) do
        local itemTagDescription, itemTagCategory = GetItemLinkItemTagInfo(itemLink, i)
		d(sfutil.str("slot: ",slotId,"  category: ",itemTagCategory,"  desc: ",itemTagDescription))
    end
end