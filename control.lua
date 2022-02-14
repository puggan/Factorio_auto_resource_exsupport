local entitieslist
local entitiesidx={}
local reslist
local gui={}
local playerindex

local BUCKET=10
local lastaddentityindex={}

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
}

local _fuel={"solid-fuel","coal"}
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

function need_fuel(entity)
	return _fuel_list[entity.prototype.name]~=nil
end

function is_lab(entity)
	return "lab"==entity.prototype.name
end

local Kfluid={
	["crude-oil"]=1,
	["fluid-unknown"]=1,
	["heavy-oil"]=1,
	["light-oil"]=1,
	["lubricant"]=1,
	["petroleum-gas"]=1,
	["steam"]=1,
	["sulfuric-acid"]=1,
	["water"]=1,
}

function is_fluid(name)
	return Kfluid[name]~=nil
end

local Kfurnace={
	["stone-furnace"]=true,
	["steel-furnace"]=true,
	["electric-furnace"]=true,
}

function is_machine(entity)
	return Kmachine[entity.prototype.name]~=nil
end

function is_chest(entity)
	return Kchest[entity.prototype.name]~=nil
end

function is_accepted_type(entity)
	return is_machine(entity)
		or is_chest(entity)
		or need_fuel(entity)
		or is_lab(entity)
end

local Ksp={
	"automation-science-pack",
	"logistic-science-pack",
	"military-science-pack",
	"chemical-science-pack",
	"production-science-pack",
	"utility-science-pack",
}

function init()
	local store10K={
		"iron-ore",
		"copper-ore",
		"uranium-ore",
		"stone",
		"coal",
		"stone-brick",
		"iron-plate",
		"copper-plate",
		"steel-plate",
		"copper-cable",
		"iron-gear-wheel",
		"electronic-circuit",
		"pipe",
		
		"transport-belt",
		"inserter",
		
		"firearm-magazine",
		"piercing-rounds-magazine",
		"grenade",
		"stone-wall",
		
		"water",
		"steam",
		"crude-oil",
		"heavy-oil",
		"light-oil",
		"lubricant",
		"petroleum-gas",
		"plastic-bar",
		"sulfur",
		"advanced-circuit",
		"engine-unit",
		
		"iron-stick",
		"rail",
		"electric-furnace",
		"productivity-module",
		
		"sulfuric-acid",
		"processing-unit",
		"battery",
		"electric-engine-unit",
		"flying-robot-frame",
		
		"speed-module",
		
		"rocket-control-unit",
		"low-density-structure",
		"solid-fuel",
		
		"automation-science-pack",
		"logistic-science-pack",
		"military-science-pack",
		"chemical-science-pack",
		"production-science-pack",
		"utility-science-pack",
		}
	
	local store200={
		"solar-panel",
		"accumulator",
		"radar",
		"satellite"
		}
	
	entitieslist={}
	reslist={}
	for i=1,7 do
		entitieslist[i]= {}
		lastaddentityindex[i]=1
		for j=1,BUCKET do
			entitieslist[i][j]={}
		end
		reslist[i]= {}
		local f=function(items, n)
			for k,v in ipairs(items) do
				if reslist[i][v]==nil then
					reslist[i][v]={count=0,max=n}
				else
					reslist[i][v].max=n
				end
			end
		end
		
		f(store10K,1000)
		f(store200,200)
		global.ar={
			entitieslist=entitieslist,
			reslist=reslist,
			entitiesidx=entitiesidx,
			lastaddentityindex=lastaddentityindex,
		}
	end
end

function read_save()
	entitieslist=global.ar.entitieslist
    reslist=global.ar.reslist
	entitiesidx=global.ar.entitiesidx
	lastaddentityindex=global.ar.lastaddentityindex
end

function entity_size_str(player)
	local str=""
	for k,v in ipairs(entitieslist[player]) do
		str=str..table_size(v).." "
	end
	return str
end

function print_inventory(i)
	if i==nil then
		return
	end
	
	local f=function(j)
		if j==nil then
			return ""
		end
		local str="slot "..#j
		for k,v in pairs(j.get_contents()) do
			str=str.. " "..k.." "..v
		end
		return str
	end
	
	game.print("-----")
	game.print("output "..f(i.get_output_inventory()))
	--game.print("module "..f(i.get_module_inventory()))
	game.print("fuel "..f(i.get_fuel_inventory()))
	game.print("burnt "..f(i.get_burnt_result_inventory()))
	game.print("furnace_source "..f(i.get_inventory(defines.inventory.furnace_source)))	
	game.print("assembling_machine_input "..f(i.get_inventory(defines.inventory.assembling_machine_input)))
	game.print("turretammo "..f(i.get_inventory(defines.inventory.turret_ammo)))

	local f2=function(j)
		if j==nil then
			return ""
		end
		local str=""
		for k,v in pairs(j) do
			str=str.." "..k.." "..v
		end
		return str
	end
	
	game.print("fluid "..f2(i.get_fluid_contents()))
end

function deposit_res(playerid,name,num)
	if reslist[playerid][name] == nil then
		--this kind is ignored
		return 0
	end
	local obj=reslist[playerid][name]
	local prev=obj.count
	obj.count=math.min(obj.count+num, obj.max)
	local diff=obj.count-prev
	--game.print("player "..playerid.." deposit "..name.." "..diff)
	return diff
end

function withdraw_res(playerid,name,num)
	if reslist[playerid][name] == nil then
		--this kind is ignored
		return 0
	end
	local obj=reslist[playerid][name]
	local res=math.min(obj.count,num)
	obj.count=obj.count-res
	--game.print("withdraw "..playerid.." "..name.." "..res.." "..obj.count.." "..reslist[playerid][name].count)
	return res
end

function read_res(playerid,name)
	if reslist[playerid][name] == nil then
		--this kind is ignored
		return 0
	end
	local obj=reslist[playerid][name]
	return obj.count
end

function can_insert_res(playerid,name)
	if reslist[playerid][name] == nil then
		--this kind is ignored
		return 0
	end
	local obj=reslist[playerid][name]
	return obj.max-obj.count
end

function draw_res(player,name,n,entity)
	if 0==n then
		return
	end
	local text=name
	if n>0 then
		text=text.." + "
	else
		text=text.." - "
	end

	text=text..math.floor(math.abs(n))
	
	game.get_player(player).create_local_flying_text{
		text=text,
		position=entity.position}
end

function harvest_chest(entity)
	local inventory=entity.get_output_inventory()
	if inventory==nil then
		game.print("no inventory")
		return
	end
	
	if is_chest(entity) then
		harvest_chest(entity)
		return
	end
end

function print_recipe(entity)
	local re=entity.get_recipe()
	if re==nil then
		return
	end
	
	local str=""
	for i,v in ipairs(re.ingredients) do
		str=str.." "..v.name.." "..v.amount
	end
	str=str.." >>"
	for i,v in ipairs(re.products) do
		str=str.." "..v.name.." "..v.amount
	end
	game.print(entity.prototype.name.." recipe "..str)
end

function read_output(player,entity)
	local outputinventory=entity.get_output_inventory()
	if nil~=outputinventory then
		--k=prototype name v=number
		for k,v in pairs(outputinventory.get_contents()) do
			game.print("found "..k.." "..v)
			--must be not fluid
			local reserve=game.item_prototypes[k].stack_size
			if reserve>1 then
				reserve=reserve/2
			else
				reserve=0
			end
			if v>reserve then
				local n=v-reserve
				n=deposit_res(player,k, n)
				if n>0 then
					game.print("remove "..k.." "..n)
					outputinventory.remove({name=k,count=n})
				end
			end
		end
	end
	local fc=entity.get_fluid_contents()
	--game.print(entity.prototype.name.." fluid "..table_size(fc))
	for k,v in pairs(fc) do
		local n=deposit_res(player,k,v)
		entity.remove_fluid{name=k,amount=n}
	end
	return true
end

function try_get_from_entity(player,entity,name,n,inv)
	game.print(name.." "..n)
	local n1=can_insert_res(player,name)
	if n>n1 then
		n=n1
	end
	
	if n<1 then
		return 0
	end
	if is_fluid(name) then
		n=entity.remove_fluid{name=name,amount=n}
	else
		n=inv.remove{name=name,count=n}
	end
	
	draw_res(player,name,n,entity)
	deposit_res(player,name,n)
	return n
end

function try_put_to_entity(player,entity,name,n,inv)
	local n1=read_res(player,name)
	if n>n1 then
		n=n1
	end
	
	if n<1 then
		return 0
	end
	--game.print("try_put n "..n.." n1 "..n1)
	if is_fluid(name) then
		n=entity.insert_fluid{name=name,amount=n}
	else
		n=inv.insert{name=name,count=n}
	end
	draw_res(player,name,-n,entity)
	withdraw_res(player,name,n)
	return n
end

function do_chest(player,entity)
	if not is_chest(entity) then
		return false
	end
	local inv=entity.get_output_inventory()
	if nil~=inv then
		--k=prototype name v=number
		for k,v in pairs(inv.get_contents()) do
			try_get_from_entity(player,entity,k,v,inv)
		end
	end
	
	local fc=entity.get_fluid_contents()
	for k,v in pairs(fc) do
		try_get_from_entity(player,entity,k,v)
	end
	return true
end

function do_fuel(player,entity)
	if not need_fuel(entity) then
		return
	end
	
	local inv=entity.get_inventory(defines.inventory.fuel)
	if nil==inv then
		return
	end
	local MAX_FUEL=5
	
	--check every fuel
	local fc=inv.get_contents()
	for k,v in pairs(fc) do
		if v>MAX_FUEL then
			try_get_from_entity(player,entity,k,v-MAX_FUEL,inv)
		end
		
		if v<MAX_FUEL then
			try_put_to_entity(player,entity,k,MAX_FUEL-v,inv)
		end
	end
	
	--check again
	local n=inv.get_item_count()
	if n<1 then
		for k1,v1 in pairs(_fuel_list[entity.prototype.name]) do
			for k2,v2 in ipairs(v1) do
				if try_put_to_entity(player,entity,v2, MAX_FUEL, inv)>0 then
					break
				end
			end
		end
	end
end

function do_lab(player,entity)
	if not is_lab(entity) then
		return false
	end
	
	local inv=entity.get_inventory(defines.inventory.lab_input)
	for i,v in ipairs(Ksp) do
		local n=inv.get_item_count(v)
		if n<1 then
			try_put_to_entity(player,entity,v,1,inv)
		end
	end
	return true
end

function do_output(player,entity)
	local t=Koutput[entity.prototype.name]
	if not t then
		return false
	end
	
	for k,v in ipairs(t) do
		try_get_from_entity(player,entity,v,50,entity.get_output_inventory())
	end
	return true
end

function harvest_feed_entity(player,entity)
	--print_inventory(entity)
	
	if do_chest(player,entity) then
		return
	end
	if do_lab(player,entity) then
		return
	end

	do_fuel(player,entity)
	if false==is_machine(entity) then
		return
	end
	
	
	local recipe=entity.get_recipe()
	if recipe==nil then
		return
	end
	
	for k,v in ipairs(recipe.ingredients) do
		--game.print(v.name.." "..v.amount.." "..recipe.energy.." "..m)
		local inv=entity.get_inventory(defines.inventory.furnace_source)
		local n
		if is_fluid(v.name) then
			n=entity.get_fluid_count(v.name)
		else
			n=inv.get_item_count(v.name)
		end

		if n<v.amount*2 then
			try_put_to_entity(player,entity,v.name,v.amount,inv)
		end
	end
		
	local fc=entity.get_fluid_contents()
	--game.print(entity.prototype.name.." fluid "..table_size(fc))
	for k,v in ipairs(recipe.products) do
		try_get_from_entity(player,entity,v.name,v.amount,entity.get_output_inventory())
	end	
end

function harvest_feed(bucket)
	--k1=playerid  v1=its all entities
	for k1,v1 in pairs(entitieslist) do
		--k2=entity unique id v2=entity obj
		for k2,v2 in pairs(v1[bucket]) do
			if v2==nil then
				game.print(" is nil")
			elseif v2.valid ==false then
				--game.print("invalid entity")
				v1[curbucket][k2]=nil
			else
				harvest_feed_entity(k1,v2)
			end
		end
		
	end	
end

function on_res_click(event)
	if is_fluid(event.element.name) then
		return
	end
	local n=1
	if defines.mouse_button_type.left==event.button then
		if event.shift then
			n=game.item_prototypes[event.element.name].stack_size
		else
			n=1
		end
	end
	
	if defines.mouse_button_type.right==event.button then
		if event.shift then
			n=game.item_prototypes[event.element.name].stack_size/2
		else
			n=5
		end
	end
	if n<1 then
		n=1
	end
	n=withdraw_res(event.player_index,event.element.name,n)
	if n>0 then
		game.get_player(event.player_index).get_inventory(defines.inventory.character_main).insert{name=event.element.name,count=n}
	end
end

function show()	
	for k,v in ipairs(game.connected_players) do
		local f=function()
			return "entity "..entity_size_str(v.index)
		end

		local res=reslist[v.index]

		if nil==v.gui.top["restable"] then
			v.gui.top.add{type="table",column_count=28,name="restable"}
			v.gui.top.add{type="label",caption="",name="entityinfo"}
			gui[v.index]={}
			gui[v.index].restable=v.gui.top["restable"]
			gui[v.index].entityinfo=v.gui.top["entityinfo"]
			for k1,v1 in pairs(res) do
				local str
				if is_fluid(k1) then
					str="fluid/"..k1
				else
					str="item/"..k1
				end
				gui[v.index].restable.add{type="sprite-button",sprite=str,name=k1,}
				--gui[v.index].restable.add{type="label",caption="0",name=k1.."rescount"}
			end
		end
		
		
		if nil==gui[v.index] then
			gui[v.index]={}
			gui[v.index].restable=v.gui.top["restable"]
			gui[v.index].entityinfo=v.gui.top["entityinfo"]
		end
		
		
		for k1,v1 in pairs(res) do
			local g=gui[v.index].restable[k1]
			g.tooltip=v1.count
			if not is_fluid(k1) then
				g.tooltip=g.tooltip..". Click to get.[Left=1 Right=5 Shift+L=Stack Shift+R=Half stack]"
			end
			g.number=v1.count
		end
		
		gui[v.index].entityinfo.caption=f()
		
	end
end

function new_entity(entity)
	if is_accepted_type(entity)==false then
	   return
	end
	
	local player=entity.last_user.index
	game.print("player "..entity.last_user.index.." entity "..entity.unit_number.." bucket "..lastaddentityindex[player])
	entitieslist[player][lastaddentityindex[player]][entity.unit_number]=entity
	
	if entitiesidx[entity.unit_number]~=nil then
		game.print("ERROR this index is used "..player.." "..entity.unit_number)
	end
	entitiesidx[entity.unit_number]={
		playerid=player,
		idx=lastaddentityindex[player],
	}
	lastaddentityindex[player]=lastaddentityindex[player]+1
	if lastaddentityindex[player]>BUCKET then
		lastaddentityindex[player]=1
	end

end

function on_built_entity(event)
	local pt=event.created_entity.prototype
	--game.print("new "..pt.name)
	new_entity(event.created_entity)
end

function on_entity_cloned(event)
	local pt=event.destination.prototype
	--game.print("clone "..pt.name)
	new_entity(event.destination)
end

function remove_entity(entity)
	if is_accepted_type(entity)==false then
		return
	end
	local p=entitiesidx[entity.unit_number]
	if nil==p then
		game.print("unknown entity "..entity.prototype.name)
		return
	end
	local e=entitieslist[p.playerid][p.idx][entity.unit_number]
	if e==nil then
		game.print("invalid entity")
		return
	end
	
	game.print("remove "..entity.prototype.name)
	entitieslist[p.playerid][p.idx][entity.unit_number]=nil
	entitiesidx[entity.unit_number]=nil
end

function on_entity_died (event)
	--game.print("DIE "..event.entity.prototype.name)
	remove_entity(event.entity)
end

function on_entity_destroyed (event)
	--game.print("DESTROY "..event.entity.prototype.name)
	remove_entity(event.entity)
end



function on_player_mined_entity (event)
	--game.print("mine "..event.entity.prototype.name.." id "..event.entity.unit_number)
	remove_entity(event.entity)
end

script.on_event(defines.events.on_built_entity, on_built_entity)
script.on_event(defines.events.on_entity_cloned, on_entity_cloned)

local _bucket=1
script.on_event(defines.events.on_tick, function(event)
	if 0 == (event.tick%(4)) then	
		--game.print(event.tick)
		harvest_feed(_bucket)
		_bucket=_bucket+1
		if _bucket>BUCKET then
			_bucket=1
		end
		show()
	end
	
end)

script.on_event(defines.events.on_gui_click, on_res_click)

script.on_event(defines.events.on_entity_died, on_entity_died)
script.on_event(defines.events.on_entity_destroyed, on_entity_destroyed)
script.on_event(defines.events.on_player_mined_entity, on_player_mined_entity)

script.on_event(defines.events.on_robot_built_entity, function(event)
	game.print("robot build entity "..event.created_entity.prototype.name)
	new_entity(event.created_entity)
end)

script.on_event(defines.events.on_entity_cloned, function(event)
	game.print("clone entity "..event.destination.prototype.name)
	new_entity(event.destination)
end)

script.on_event(defines.events.on_trigger_created_entity, function(event)
	game.print("trigger create entity "..event.entity.prototype.name)
	new_entity(event.entity)
end)

script.on_event(defines.events.on_robot_mined_entity, function(event)
	game.print("robot mine entity "..event.entity.prototype.name)
	remove_entity(event.entity)
end)

script.on_load(read_save)
script.on_init(init)