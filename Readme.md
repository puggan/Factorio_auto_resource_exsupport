# Introduction
* Collect and distribute resources(including ammo) automatically, just like playing RTS game! 
* If you play sandbox mode, please create character first or it will lead script error. Open console, execute "/c game.player.create_character()"
* If you find a bug feel free commit issue with details
* Do not support Multiplayer, never tested.
* In Wave Defense the system give you some turret and a rocket-silo at first, these can not be recognized by mod, you need click them open the GUI such the mod can get the event notify.
* Do not support previous save because game don't give a API to read all entities. The script only can get notify event by player building or robot building. If you load a previous save, game will run but the mod will not able to recognize all entities you built, you need rebuild them.
* May not work with some Mod.

# Demo
* Video : TBD
* Screenshot: ![](https://github.com/njikmf/Factorio_auto_resource/blob/master/Capture.PNG)

# How it works
* When you build a furnace/chest/machine/... the mod will remember it and collect production, add ingredients preiodicty. Because the lua API don't give such a "production complete" event notify, the script check this every XX ms.

# Performance
The entity number will affect the efficiency but I tested it with about 10000 entities it works well, CPU load <10%, 60 FPS stable

# Feature list
* Supported resources: all items needed by all science pack + artillery shell. To avoid waste I set a max value for each type. Check code for details. If the resource reach the limit the script will not collect it from machine, you can still use belt+inserter+chest to collect.
```
	local store100M={
		"iron-ore",
		"copper-ore",
		"uranium-ore",
		"stone",
		"coal",
		"water",
		}
	local store1K={
		"iron-plate",
		"copper-plate",
		"steel-plate",
		"stone-brick",
		}
	
	local store25K={
		"crude-oil",
		"heavy-oil",
		"light-oil",
		"lubricant",
		"petroleum-gas",
		"sulfuric-acid",
		}
	local store200={
		"transport-belt",
		"pipe",
		"inserter",
		"copper-cable",
		"iron-gear-wheel",
		"electronic-circuit",
		"stone-wall",
		"firearm-magazine",
		"piercing-rounds-magazine",
		"grenade",
		"plastic-bar",
		"sulfur",
		"advanced-circuit",
		"engine-unit",
		"iron-stick",
		"rail",
		"electric-furnace",
		"productivity-module",
		
		"processing-unit",
		"battery",
		"electric-engine-unit",
		"flying-robot-frame",
		
		"speed-module",
		
		"rocket-control-unit",
		"low-density-structure",
		"rocket-fuel",
		"solid-fuel",
		"automation-science-pack",
		"logistic-science-pack",
		"military-science-pack",
		"chemical-science-pack",
		"production-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"solar-panel",
		"accumulator",
		"radar",
		"explosives",
		"explosive-cannon-shell",
		"artillery-shell",
		}
```

* Supported "machine" types:  chest/furnace/assemblemachine/oilrefine/chemicalplant/turret are all "machine" that will be managed by mod. Check code for details
```
local Kchest={}
Kchest["wooden-chest"]=true
Kchest["iron-chest"]=true
Kchest["steel-chest"]=true
Kchest["storage-tank"]=true
Kchest["pumpjack"]=true

local Kmachine={
	["assembling-machine-1"]=true,
	["assembling-machine-2"]=true,
	["assembling-machine-3"]=true,
	["stone-furnace"]=true,
	["steel-furnace"]=true,
	["electric-furnace"]=true,
	["oil-refinery"]=true,
	["chemical-plant"]=true,
	["stone-furnace"]=true,
	["steel-furnace"]=true,
	["electric-furnace"]=true,
	["rocket-silo"]=true,
}

```

* specific ingredient:
```
local _fuel={"coal","solid-fuel"}
local _fuel_list={
	["gun-turret"]={{"piercing-rounds-magazine","firearm-magazine"}},
	["artillery-turret"]={{"artillery-shell"}},
	["flamethrower-turret"]={{"light-oil","heavy-oil","crude-oil"}},
	["boiler"]={_fuel,{"water"}},
	["burner-mining-drill"]={_fuel},
	["stone-furnace"]={_fuel},
	["steel-furnace"]={_fuel},
	["heat-exchanger"]={{"water"}},
}
```

* Max fuel: default value is 3, it means if a machine has 1 fuel, script will add 2 fuel; if it has 4 fuel, the script will take 1 fuel away.

* "steam" will not be managed, because different temperature works different(nuclear power)

* Furnace batch mode: Click the FT button to select type and put furnace. If you don't like this select "none"

* Resources exchange: Click the button, follow the tips. Fluid types are not supported. If want give back the resource, put the resource to chest.
