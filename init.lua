local diff_table = {}
local item_attributes = {}

local max_durability = minetest.setting_get("crafting_durability.max_durability_limit") or 1000

-------------------------------------------
----  Local functions
-------------------------------------------
local function register_crafting_durability()
	-- Create diff value table
	for dur = 2, max_durability do
		local wear
		if dur > 256 then
			wear = math.floor(65535 / (dur - 1))
		else
			wear = math.floor(65535 / dur + 1)
		end

		local diff = 65536 - (wear * dur)
		if diff > 0 then
			diff_table[dur] = diff
		end
	end

	-- Create item attributes table
	for name, def in pairs(minetest.registered_tools) do
		local dur = nil
		local tbl = nil
		if type(def.crafting_durability) == "table" then
			tbl = def.crafting_durability
			dur = tonumber(tbl.durability) or 0
		else
			dur = tonumber(def.crafting_durability) or 0
		end

		dur = math.min(dur, max_durability)
		if dur > 1 and not def.tool_capabilities then
			item_attributes[name] = {}
			if dur > 256 then
				item_attributes[name].add_wear = math.floor(65535 / (dur - 1))
			else
				item_attributes[name].add_wear = math.floor(65535 / dur + 1)
			end
			item_attributes[name].durability = dur
		end
	end
end


-------------------------------------------
----  Register callbacks
-------------------------------------------
minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	local output_name = itemstack:get_name()
	local check_list = {}
	local item_kind = 0

	if item_attributes[output_name] then
		for _, old_stack in ipairs(old_craft_grid) do
			local name = old_stack:get_name()
			if name ~= "" then
				if not check_list[name] then
					check_list[name] = true
					item_kind = item_kind + 1
				end
			end
		end
	end
	if (item_kind == 1) and (output_name == next(check_list, nil)) then
		return itemstack
	end

	local new_craft_grid = craft_inv:get_list("craft")
	for idx, old_stack in ipairs(old_craft_grid) do
		local attr = item_attributes[old_stack:get_name()]
		if attr and (new_craft_grid[idx]:get_name() == "") then
			local diff = diff_table[attr.durability]
			local new_stack = ItemStack(old_stack)
			if diff and (new_stack:get_wear() == 0) then
				new_stack:set_wear(diff)
			end
			new_stack:add_wear(attr.add_wear)

			if not new_stack:is_empty() then
				craft_inv:set_stack("craft", idx, new_stack)
			end
		end
	end
	return itemstack
end)


-------------------------------------------
----  Register crafting durability
-------------------------------------------
minetest.after(1, register_crafting_durability)

minetest.log("action", "[Crafting Durability] Loaded!")
