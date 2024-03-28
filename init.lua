
local modpath = minetest.get_modpath("name_generator")

name_generator.parse_lines(io.lines(modpath.."/data/creatures.cfg"))

local place_on = {"default:permafrost_with_stones",
              "default:dirt_with_snow",
              "default:dirt_with_grass",
              "default:dry_dirt_with_dry_grass",
              "default:sand",
              "default:dirt_with_coniferous_litter",
              "default:dirt_with_rainforest_litter"}
local biomes = {"tundra","taiga","snowy_grassland","grassland","grassland_dunes","coniferous_forest", "deciduous_forest", "savanna","rainforest"}

local base_fill = tonumber(minetest.settings:get("cemeteries_graves_fill_ration") or "0.0001")

minetest.register_decoration({
  name = "cemeteries:graves_simple",
  deco_type = "simple",
  decoration = "church_grave:grave_simple",
  sidelen = 4,
  place_on = place_on,
  y_min = -2,
  y_max = 80,
  fill_ratio = base_fill,
  param0 = 0,
  param0_max = 3,
  biomes = biomes,
})
minetest.register_decoration({
  name = "cemeteries:graves_fancy",
  deco_type = "simple",
  decoration = "church_grave:grave_fancy",
  sidelen = 4,
  place_on = place_on,
  y_min = -2,
  y_max = 80,
  fill_ratio = base_fill*0.5,
  param0 = 0,
  param0_max = 3,
  biomes = biomes,
})
minetest.register_decoration({
  name = "cemeteries:graves_named",
  deco_type = "simple",
  decoration = "church_grave:grave",
  sidelen = 4,
  place_on = place_on,
  y_min = -2,
  y_max = 80,
  fill_ratio = base_fill*0.1,
  param0 = 0,
  param0_max = 3,
  biomes = biomes,
})

minetest.register_on_generated(function(minp, maxp, blockseed)
    local graves = minetest.find_nodes_in_area(minp, maxp, "church_grave:grave")
    for _,pos in pairs(graves) do
      local meta = minetest.get_meta(pos)
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
      minetest.registered_nodes["church_grave:grave"].on_construct(pos)
    end
  end
)
