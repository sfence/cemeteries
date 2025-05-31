
local modpath = core.get_modpath("name_generator")

name_generator.parse_lines(io.lines(modpath.."/data/creatures.cfg"))

local place_on = {"default:permafrost_with_stones",
							"default:dirt_with_snow",
							"default:dirt_with_grass",
							"default:dry_dirt_with_dry_grass",
							"default:sand",
							"default:desert_sand",
							"default:dirt_with_coniferous_litter",
							"default:dirt_with_rainforest_litter"}

local place_on_clever = {
		"default:permafrost_with_stones",
		"default:dirt_with_snow",
		"default:dirt_with_grass",
		"default:dry_dirt_with_dry_grass",
		"default:sand",
		"default:desert_sand",
		"default:dirt_with_coniferous_litter",
		"default:dirt_with_rainforest_litter",
		"default:snow"}
local biomes = {"tundra","taiga","snowy_grassland","grassland","grassland_dunes","coniferous_forest", "deciduous_forest", "savanna","rainforest"}

local base_fill = tonumber(core.settings:get("cemeteries_graves_fill_ration") or "0.0001")
local cemeteries_fill = tonumber(core.settings:get("cemeteries_cemeteries_fill_ration") or "0.000005")

core.register_decoration({
	name = "cemeteries:graves_simple",
	deco_type = "simple",
	decoration = "church_grave:grave_simple",
	sidelen = 4,
	place_on = place_on,
	y_min = -2,
	y_max = 80,
	fill_ratio = base_fill,
	param2 = 0,
	param2_max = 3,
	biomes = biomes,
})
core.register_decoration({
	name = "cemeteries:graves_fancy",
	deco_type = "simple",
	decoration = "church_grave:grave_fancy",
	sidelen = 4,
	place_on = place_on,
	y_min = -2,
	y_max = 80,
	fill_ratio = base_fill*0.5,
	param2 = 0,
	param2_max = 3,
	biomes = biomes,
})
core.register_decoration({
	name = "cemeteries:graves_named",
	deco_type = "simple",
	decoration = "church_grave:grave",
	sidelen = 4,
	place_on = place_on,
	y_min = -2,
	y_max = 80,
	fill_ratio = base_fill*0.1,
	param2 = 0,
	param2_max = 3,
	biomes = biomes,
})

core.register_decoration({
	name = "cemeteries:cemetrie_base",
	deco_type = "simple",
	decoration = "church_grave:grave",
	sidelen = 4,
	place_on = place_on,
	y_min = -2,
	y_max = 80,
	fill_ratio = cemeteries_fill,
	param2 = 4,
	param2_max = 255,
	biomes = biomes,
})

local cemetery_noise_sizex = {
		offset = 16,
		scale = 4,
		spread = {x = 100, y = 100, z = 100},
		seed = 69,
		octaves = 4,
		persist = 1,
		lacunarity = 2,
		flags = "default",
	}
local cemetery_noise_sizez = {
		offset = 16,
		scale = 4,
		spread = {x = 100, y = 100, z = 100},
		seed = 198,
		octaves = 4,
		persist = 1,
		lacunarity = 2,
		flags = "default",
	}

local cemetery_noise_wall = {
		offset = 2,
		scale = 1,
		spread = {x = 20, y = 20, z = 20},
		seed = 6879,
		octaves = 4,
		persist = 0.5,
		lacunarity = 2,
		flags = "default",
	}

local cemetery_noise_named_graves = {
		offset = 2000000000,
		scale = 2000000000,
		spread = {x = 10, y = 10, z = 10},
		seed = 9687,
		octaves = 3,
		persist = 1,
		lacunarity = 2,
		flags = "default",
	}

local function check_for_high_wall(pos, walls)
	local apos = vector.new(pos.x, pos.y+1, pos.z)
	for _,wall in pairs(walls) do
		if vector.distance(wall, pos) > 0.5 then
			if vector.distance(wall, apos) <= 1.1 then
				return true
			end
		end
	end
	return false
end

local function correct_cemetery_node_pos(pos)
	local node = core.get_node(pos)
	if not core.registered_nodes[node.name].buildable_to then
		pos.y = pos.y + 1
	else
		pos.y = pos.y - 1
		local node = core.get_node(pos)
		if core.get_item_group(node.name, "soil")==0 and core.get_item_group(node.name, "stone")==0 then
			pos = nil
		else
			pos.y = pos.y + 1
		end
	end
	return pos
end

local wall_treshold = 1.5

local function generate_cemetery(minp, maxp, pos, graves, param2)
	local wall_perlin = core.get_perlin(cemetery_noise_wall)
	local have_wall = math.floor(wall_perlin:get_2d(pos)/wall_treshold)
	
	if have_wall > 0 then
		if (pos.x == minp.x) or (pos.x == maxp.x) then
			have_wall = 0
		end
		if (pos.z == minp.z) or (pos.z == maxp.z) then
			have_wall = 0
		end
	end

	local size_x = math.round(core.get_perlin(cemetery_noise_sizex):get_2d(pos)/2)
	local size_z = math.round(core.get_perlin(cemetery_noise_sizez):get_2d(pos)/2)
	
	local minp = vector.new(
		math.max(minp.x, pos.x-size_x+have_wall),
		math.max(minp.y, pos.y-3),
		math.max(minp.z, pos.z-size_z+have_wall))
	local maxp = vector.new(
		math.min(maxp.x, pos.x+size_x-have_wall),
		math.min(maxp.y, pos.y+3),
		math.min(maxp.z, pos.z+size_z-have_wall))
	
	local found = core.find_nodes_in_area_under_air(minp, maxp, place_on_clever)

	--print("Cemetery wall "..have_wall.." with "..graves.." graves from "..core.pos_to_string(minp).." to "..core.pos_to_string(maxp))

	local graves_random = PcgRandom(core.get_perlin(cemetery_noise_named_graves):get_2d(pos))
	local second_name = name_generator.generate("human surname")
	local founds = #found
	::continue_while::
	while graves>0 and founds>0 do
		local index = math.random(#found)
		local gen = found[index]
		found[index] = nil
		
		founds = founds - 1
		if not gen then
			goto continue_while
		end
		
		gen = correct_cemetery_node_pos(vector.new(gen))
		if not gen then
			goto continue_while
		end
		
		graves = graves - 1
		if gen then
			
			local val = graves_random:next()
			if val > 0 then
				core.swap_node(gen, {name="church_grave:grave", param2=param2})
				local meta = core.get_meta(gen)
				local first_name
				if math.random(2)==1 then
					first_name = name_generator.generate("human male")
				else
					first_name = name_generator.generate("human female")
				end
				second_name = name_generator.generate("human surname")

				local person
				if (first_name:len()+second_name:len()) > 14 then
					person = first_name.."\n"..second_name
				else
					person = first_name.." "..second_name
				end

				meta:set_string("display_text", person)
				meta:set_string("infotext", "\""..person.."\"")
				core.registered_nodes["church_grave:grave"].on_construct(pos)
			elseif val > -1500000000 then
				core.swap_node(gen, {name="church_grave:grave_fancy", param2=param2})
			else
				core.swap_node(gen, {name="church_grave:grave_simple", param2=param2})
			end
		end
	end
	
	if have_wall > 0 then
		local entrance_side = graves_random:next(1, 4)
		local sides = {
			{
				minp = vector.new(minp.x-1, minp.y, minp.z-1),
				maxp = vector.new(maxp.x+1, maxp.y, minp.z-1),
				entrance = entrance_side == 1
			},
			{
				minp = vector.new(minp.x-1, minp.y, maxp.z+1),
				maxp = vector.new(maxp.x+1, maxp.y, maxp.z+1),
				entrance = entrance_side == 2
			},
			{
				minp = vector.new(minp.x-1, minp.y, minp.z-1),
				maxp = vector.new(minp.x-1, maxp.y, maxp.z+1),
				entrance = entrance_side == 3
			},
			{
				minp = vector.new(maxp.x+1, minp.y, minp.z-1),
				maxp = vector.new(maxp.x+1, maxp.y, maxp.z+1),
				entrance = entrance_side == 4
			},
		}
		for _,side in pairs(sides) do
			local pre_found = core.find_nodes_in_area_under_air(side.minp, side.maxp, place_on_clever)
			found = {}
			for _,pos in pairs(pre_found) do
				pos = correct_cemetery_node_pos(vector.new(pos))
				if pos then
					if (not side.entrance)
							or (math.abs(vector.distance(side.minp, pos) - vector.distance(side.maxp, pos))>1.3) then
						table.insert(found, pos)
						--print(core.pos_to_string(pos))
					end
				end
			end
			for _,wall in pairs(found) do
				wall = vector.new(wall)
				local noise = wall_perlin:get_2d(wall)
				if noise >= wall_treshold then
					core.set_node(wall, {name="walls:mossycobble"})
					if check_for_high_wall(wall, found) then
						wall.y = wall.y + 1
						core.set_node(wall, {name="walls:mossycobble"})
					end
					if noise >= 1.5*wall_treshold then
						wall.y = wall.y + 1
						--core.set_node(wall, {name="walls:mossycobble"})
					end
				end
			end
		end
	end
end

core.register_on_generated(function(minp, maxp, blockseed)
		local graves = core.find_nodes_in_area(minp, maxp, "church_grave:grave")
		for _,pos in pairs(graves) do
			local node = core.get_node(pos)
			local meta = core.get_meta(pos)
			local first_name
			if math.random(2)==1 then
				first_name = name_generator.generate("human male")
			else
				first_name = name_generator.generate("human female")
			end
			local second_name = name_generator.generate("human surname")

			local person
			if (first_name:len()+second_name:len()) > 14 then
				person = first_name.."\n"..second_name
			else
				person = first_name.." "..second_name
			end

			meta:set_string("display_text", person)
			meta:set_string("infotext", "\""..person.."\"")
			core.registered_nodes["church_grave:grave"].on_construct(pos)

			if node.param2>3 then
				local param = bit.rshift(node.param2, 2)
				node.param2 = bit.band(node.param2, 3)
				core.swap_node(pos, node)
				
				generate_cemetery(minp, maxp, pos, param, node.param2)
			end
		end
	end
)
