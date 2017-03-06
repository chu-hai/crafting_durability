local crafting_durability_lists = {}

-------------------------------------------
----  Local functions
-------------------------------------------
local function register_crafting_durability()
	local stack = ItemStack("default:stone")
	if not stack.get_meta then
		minetest.log("warning", "[Crafting Durability] Disabled. (ItemStackMetaRef is not implemented)")
		return
	end

	for k, v in pairs(minetest.registered_tools) do
		local durability = tonumber(v.crafting_durability) or 0
		if durability > 0 and not v.tool_capabilities then
			crafting_durability_lists[k] = math.min(durability, 65535)
		end
	end
end


-------------------------------------------
----  Register callbacks
-------------------------------------------
minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	local output_name = itemstack:get_name()
	local check_list = {}
	local name_cache = ""
	local item_kind = 0

	if crafting_durability_lists[output_name] then
		for _, old_stack in ipairs(old_craft_grid) do
			local name = old_stack:get_name()
			if name ~= "" then
				if not check_list[name] then
					check_list[name] = true
					name_cache = name
					item_kind = item_kind + 1
				end
			end
		end
	end

	if (item_kind == 1) and (output_name == name_cache) then
		-- for Repair craft
		local total_dur = 0
		local max_dur = crafting_durability_lists[name_cache]
		for _, old_stack in ipairs(old_craft_grid) do
			local name = old_stack:get_name()
			if name ~= "" then
				local dur = old_stack:get_meta():get_int("crafting_durability")
				total_dur = total_dur + (dur == 0 and max_dur or dur)
			end
		end
		total_dur = math.min(total_dur, max_dur)
		itemstack:get_meta():set_int("crafting_durability", total_dur)
		itemstack:set_wear(65535 - math.floor(total_dur / max_dur * 65535))
	else
		-- for Normal craft
		local new_craft_grid = craft_inv:get_list("craft")
		for idx, old_stack in ipairs(old_craft_grid) do
			local max_dur = crafting_durability_lists[old_stack:get_name()] or 0

			if (max_dur > 0) and (new_craft_grid[idx]:get_name() == "") then
				local new_stack = ItemStack(old_stack)
				local meta = new_stack:get_meta()
				local dur = meta:get_int("crafting_durability")
				if dur == 0 then
					dur = max_dur - 1
				else
					dur = dur - 1
				end

				if dur > 0 then
					meta:set_int("crafting_durability", dur)
					new_stack:add_wear(65535 / max_dur)
				else
					new_stack = ItemStack(nil)
				end
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
