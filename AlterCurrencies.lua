-- DEFAULT_CHAT_FRAME:AddMessage('[AlterCurrencies] Showing currency amounts of any character when hovering over any currency on currency tab or any currency cost in items in merchant tabs.', 1,1,0)
AlterCurrencies = {}
AltC_DB = AltC_DB or {} -- Shared Variable

local unitName, realmName, unitClass, classColor
local AltC = AlterCurrencies

local AlterCurrencies_Frame = CreateFrame("Frame")
AlterCurrencies_Frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
AlterCurrencies_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")

--------------------------------------------------------------------------
-- Create a JSON dictionary in the shared variable with all necesary data:
-- - currency
--      - realm
--          - character
--              - amount
--------------------------------------------------------------------------
function AltC.UpdateTable(currencyId, currencyAmount)
    if AltC_DB[currencyId] == nil then
        AltC_DB[currencyId] = {}
    end
    
	if AltC_DB[currencyId][realmName] == nil then
		AltC_DB[currencyId][realmName] = {}
	end
	
	if AltC_DB[currencyId][realmName][unitName] == nil then
		AltC_DB[currencyId][realmName][unitName] = {}
	end
	
	AltC_DB[currencyId][realmName][unitName].colorStr = classColor
	AltC_DB[currencyId][realmName][unitName].currencyAmount = currencyAmount
end

-----------------------------------------------------------------------------------
-- Dinamically obtain the list of discovered currencies of the character and 
-- get the amount. Store this amount in the dictionary saved in the shared variable
-----------------------------------------------------------------------------------
function AltC.GetCurrencyAmounts()

    local currencyName, currencyAmount, isDiscovered = nil,nil,nil;
    
    for i = 1,C_CurrencyInfo.GetCurrencyListSize(),1 do

        local currencyLink = C_CurrencyInfo.GetCurrencyListLink(i);

        if currencyLink ~= nil then -- Ignore headers

            local currencyId = tonumber(string.match(C_CurrencyInfo.GetCurrencyListLink(i),"currency:(%d+)")) -- Get only the ID
            local currencyStruct = C_CurrencyInfo.GetCurrencyInfoFromLink(currencyLink); 

            currencyName = currencyStruct.name;
            currencyAmount = currencyStruct.quantity;
            isDiscovered = currencyStruct.discovered;

            if currencyId ~= nil and currencyName ~= nil and isDiscovered and currencyAmount >= 0 then
                AltC.UpdateTable(currencyId, currencyAmount) -- Store
            end
        end
    end
end

--------------------------
-- Get class color
--------------------------
function AltC.ClassColor()
	_, unitCLass = UnitClass("player")
	if unitCLass then
		classColor = RAID_CLASS_COLORS[unitCLass]["colorStr"]
	end
end

-------------------------------------------------
-- If any of the registered events triggers, get 
-- currency info and store it
------------------------------------------------
function AltC.OnEvent(self, event, arg1, arg2)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Fill global variables
		unitName = UnitName("player")
		realmName = GetRealmName()
        AltC.ClassColor()
        -- Get amounts and store them
        AltC.GetCurrencyAmounts()
	end
	
    if event == "CURRENCY_DISPLAY_UPDATE" and arg2 ~= 0 then
        -- Fill global variables
        unitName = UnitName("player")
		realmName = GetRealmName()
        AltC.ClassColor()
        -- Get amounts and store them
		AltC.GetCurrencyAmounts()
	end
end

----------------------
-- Hook text on tooltip
----------------------
function AltC.AddLine(tooltip, leftText, rightText)
	tooltip:AddDoubleLine(leftText, rightText)
	tooltip:Show() 
end

---------------------------------------------------
-- Append to tooltip text all currency information
---------------------------------------------------
function AltC.AddToTooltip(tooltip, id)
    if type(AltC_DB) == "table" and AltC_DB ~= nil then -- If shared variable have data
        for currencyId, value_DB in pairs(AltC_DB) do -- For each stored currency
            if id == currencyId then -- If the hover is on this currency 
                if type(value_DB) == "table" and value_DB ~= nil then
                    AltC.AddLine(tooltip, " ", " ") -- Space 
                    for realm, unit in pairs(value_DB) do
                        AltC.AddLine(tooltip, "|cffffffff-"..realm.."-|r", nil)
                    
                        local keys = {}
                    
                        for k in pairs(unit) do 
                            table.insert(keys, k) 
                        end
                    
                        table.sort(keys, function(a, b) -- Sort by amount
                            return unit[a]["currencyAmount"] > unit[b]["currencyAmount"]
                        end)
                    
                        for _, k in ipairs(keys) do -- Paint two columns: character --- amount
                            AltC.AddLine(tooltip, "|c"..unit[k]["colorStr"]..k.."|r", unit[k]["currencyAmount"]) 
                        end
                    end
                end
            end
        end
    end
end

-- Add amounts below Blizzard tooltip
hooksecurefunc(GameTooltip, "SetCurrencyToken", function(tooltip, index)
			local id = tonumber(string.match(C_CurrencyInfo.GetCurrencyListLink(index),"currency:(%d+)"))
			AltC.AddToTooltip(tooltip, id)
		end)
hooksecurefunc(GameTooltip, "SetMerchantCostItem", function(tooltip, item, currency)
			local itemTexture, itemValue, itemLink, currencyName = GetMerchantItemCostItem(item, currency)
			local id = tonumber(string.match(itemLink,"currency:(%d+)"))
			AltC.AddToTooltip(tooltip, id)
		end)

AlterCurrencies_Frame:SetScript("OnEvent", AltC.OnEvent)
