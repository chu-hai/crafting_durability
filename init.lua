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
end)


-------------------------------------------
----  Register crafting durability
-------------------------------------------
minetest.after(1, register_crafting_durability)

minetest.log("action", "[Crafting Durability] Loaded!")
