local entitieslist
local entitiesidx={}
local reslist
local gui={}
local playerindex
local furnace_type_index=1
script.on_event("autoresourceex-hide-restable", function(event)
	localplayer = game.players[event.player_index]
	if localplayer.gui.top.restable.visible == true then
		localplayer.gui.top.restable.visible = false
	else
		localplayer.gui.top.restable.visible = true
	end
  end)

  script.on_event("autoresourceex-run-onchange", function(event)
onchange()
  end)


local BUCKET=10
local lastaddentityindex={}
local Kchest={}
Kchest["wooden-chest"]=true
Kchest["iron-chest"]=true
Kchest["steel-chest"]=true
Kchest["storage-tank"]=true
Kchest["pumpjack"]=true

local store1M={
}
local store1K={
}

local store25K={
}
local store200={
}

local Kmachine={
}



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

function need_fuel(entity)
	return _fuel_list[entity.prototype.name]~=nil
end

function is_lab(entity)
	return "lab"==entity.prototype.name
end


function is_fluid(name)
	return game.fluid_prototypes[name] ~= nil
end

local Kfurnace={
	["stone-furnace"]=true,
	["steel-furnace"]=true,
	["electric-furnace"]=true,
}
function is_furnace(entity)
	return Kfurnace[entity.prototype.name]~=nil
end

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
	"space-science-pack",
}

function init()
	local list = {}
	for _, item in pairs(game.item_prototypes) do 
	list[#list+1] = item.name
	end
	store200 = list
	local list1 = {}
	for _, fluid in pairs(game.fluid_prototypes) do
	store25K[#store25K+1] = fluid.name
	end
	for _, entity in pairs(game.get_filtered_entity_prototypes({{filter = "crafting-machine"}})) do
	Kmachine[entity.name] = true
	end

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
		
		f(store1M,1000000)
		f(store1K,1000)
		f(store25K,25000)
		f(store200,2000)
		global.ar={
			entitieslist=entitieslist,
			reslist=reslist,
			entitiesidx=entitiesidx,
			lastaddentityindex=lastaddentityindex,
		}
	end
end

function onchange()
	local list = {}
	for _, item in pairs(game.item_prototypes) do 
	list[#list+1] = item.name
	end
	store200 = list
	local list1 = {}
	for _, fluid in pairs(game.fluid_prototypes) do
	store25K[#store25K+1] = fluid.name
	end
	for _, entity in pairs(game.get_filtered_entity_prototypes({{filter = "crafting-machine"}})) do
	Kmachine[entity.name] = true
	end
end

function read_save()	
	entitieslist=global.ar.entitieslist
    reslist=global.ar.reslist
	entitiesidx=global.ar.entitiesidx
	lastaddentityindex=global.ar.lastaddentityindex
	onchangeyet = true
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
	if n>=0 or n<0 then
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
		game.print(entity.prototype.name.." no inventory")
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
	--game.print(name.." "..n)
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

	if is_fluid(name) then
		n=entity.insert_fluid{name=name,amount=n}
	else
		n=inv.insert{name=name,count=n}
	end
	draw_res(player,name,-n,entity)
	withdraw_res(player,name,n)
	return n
end

function read_entity(entity,name)
	if is_fluid(name) then
		return entity.get_fluid_count(name)
	else
		return entity.get_item_count(name)
	end
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

local MAX_FUEL=3
function do_fuel(player,entity)
	if not need_fuel(entity) then
		return
	end
	
	local inv=entity.get_inventory(defines.inventory.fuel)

	for k1,v1 in pairs(_fuel_list[entity.prototype.name]) do
		for k2,v2 in ipairs(v1) do
			local n=MAX_FUEL
			if "water"==v2 then
				n=9999
			end
			
			local n1=read_entity(entity,v2)
			if n1> n then
				try_get_from_entity(player,entity,v2,n1-n,inv)
			end
			
			if n1<n then
				try_put_to_entity(player,entity,v2, n, inv)
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

function do_ssp(player,entity)
	if "rocket-silo"==entity.prototype.name then
		try_get_from_entity(player,entity,"space-science-pack",1000,entity.get_output_inventory())
	end
end

function do_furnace(player,e)
	local entity=e.entity
	if not is_furnace(entity) then
		return false
	end
	
	--get all output
	local inv=entity.get_output_inventory()
	for k,v in pairs(inv.get_contents()) do
		try_get_from_entity(player,entity,k,v,inv)
	end
	--decide what to burn based on current resource amount
	inv=entity.get_inventory(defines.inventory.furnace_source)
	
	local f=function(name,inv)
			local m1=10
			local cur=inv.get_item_count()
			if cur<m1 then
				return try_put_to_entity(player,entity,name,m1-cur,inv)
			end
			return 0
		end
	if not inv.is_empty() then
		local fc=inv.get_contents()
		for k,v in pairs(fc) do
			--game.print("source "..k)
			f(k,inv)
			e.furnace_source=k
		end
	else
		if e.furnace_source~=nil then
			f(e.furnace_source,inv)
		end
	end
	
end

function setres(n)
	reslist[1]["automation-science-pack"].count=n
	reslist[1]["logistic-science-pack"].count=n
	reslist[1]["military-science-pack"].count=n
	reslist[1]["chemical-science-pack"].count=n
	reslist[1]["production-science-pack"].count=n
	reslist[1]["utility-science-pack"].count=n
	reslist[1]["rocket-control-unit"].count=n
	reslist[1]["low-density-structure"].count=n
	reslist[1]["rocket-fuel"].count=n
end

function setmax(n)
	local r=reslist[1]
	r["crude-oil"].max=n
	r["heavy-oil"].max=n
	r["light-oil"].max=n
	r["lubricant"].max=n
	r["petroleum-gas"].max=n
	r["sulfuric-acid"].max=n
end

function harvest_feed_entity(player,e)
	local entity=e.entity
	--print_inventory(entity)
	
	do_ssp(player,entity)

	if do_chest(player,entity) then
		return
	end
	if do_lab(player,entity) then
		return
	end

	if do_furnace(player,e) then
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
	for k,v in ipairs(recipe.products) do
		try_get_from_entity(player,entity,v.name,9999,entity.get_output_inventory())
	end

	for k,v in ipairs(recipe.ingredients) do
		local inv=entity.get_inventory(defines.inventory.furnace_source)
		local n=read_entity(entity,v.name)
		local m=v.amount/(recipe.energy/entity.crafting_speed)*2
		--game.print(v.name.." "..v.amount.." "..recipe.energy.." "..n.." "..m)
		if m<v.amount then
			m=v.amount*2
		end
		if n<m then
			try_put_to_entity(player,entity,v.name,m-n,inv)
		end
	end
end

function harvest_feed(bucket)
	--k1=playerid  v1=its all entities
	for k1,v1 in pairs(entitieslist) do
		--k2=entity unique id v2=entity obj
		for k2,v2 in pairs(v1[bucket]) do
			if v2.entity==nil then
				game.print(" is nil")
			elseif v2.entity.valid ==false then
				--game.print("invalid entity")
				v1[bucket][k2]=nil
			else
				harvest_feed_entity(k1,v2)
			end
		end
		
	end	
end

local ft_option={"none","iron","copper","steel","stone-brick"}
local ft_src={
	["none"]="",
	["iron"]="iron-ore",
	["copper"]="copper-ore",
	["steel"]="iron-plate",
	["stone-brick"]="stone",
}

function ft_source()
	return ft_src[ft_option[furnace_type_index]]
end

function on_sel_change(event)
	if "gui_ft_setting"==event.element.name then
		furnace_type_index=event.element.selected_index
		game.get_player(event.player_index).gui.top["furnace_type"].caption="FT="..ft_source()
	end
end

function on_gui_click(event)
	if is_fluid(event.element.name) then
		return
	end
	
	if "furnace_type"==event.element.name then
		if nil ==gui[event.player_index].ft then
			gui[event.player_index].ft=game.get_player(event.player_index).gui.center.add{type="frame"}
			gui[event.player_index].ft.add{type="drop-down",items=ft_option,selected_index=furnace_type_index,name="gui_ft_setting"}
		else
			gui[event.player_index].ft.destroy()
			gui[event.player_index].ft=nil
		end
		return
	end
	
	local n=1
	if defines.mouse_button_type.left==event.button then
		if event.shift then
			local p= game.item_prototypes[event.element.name]
			if nil==p or nil==p.stack_size then
				game.print(event.element.name.." is nil")
			else
				n=game.item_prototypes[event.element.name].stack_size
			end
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

function create_gui(root,index)
	gui[index]={}
	gui[index].restable=root.add{type="table",column_count=28,name="restable"}
	gui[index].entityinfo=root.add{type="label",caption="",name="entityinfo"}
	local btn=root.add{type="button",caption="FT",name="furnace_type"}
	for k1,v1 in pairs(reslist[index]) do
		local str
		if is_fluid(k1) then
			str="fluid/"..k1
		else
			str="item/"..k1
		end
		gui[index].restable.add{type="sprite-button",sprite=str,name=k1,visible=shouldvisible}
	end

end

function show()
	for k,v in ipairs(game.connected_players) do
		local f=function()
			return "entity "..entity_size_str(v.index)
		end

		local res=reslist[v.index]

		if nil==v.gui.top["furnace_type"] then
			create_gui(v.gui.top,v.index)
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
			if reslist[1][k1].count==0 and settings.global["show-resources-with-0"].value == false then
				g.visible=false
			else
				g.visible=true
			end
		end
		
		gui[v.index].entityinfo.caption=f()
	end
end

function new_entity(entity)
	if is_accepted_type(entity)==false then
	   return
	end
	
	if nil==entity.last_user then
		game.print(entity.prototype.name.." has no last_user")
		return
	end
	local player=entity.last_user.index
	entitieslist[player][lastaddentityindex[player]][entity.unit_number]={entity=entity}
	local e=entitieslist[player][lastaddentityindex[player]][entity.unit_number]
	if entitiesidx[entity.unit_number]~=nil then
		--game.print("ERROR this index is used "..player.." "..entity.unit_number)
		return
	end
	entitiesidx[entity.unit_number]={
		playerid=player,
		idx=lastaddentityindex[player],
	}
	lastaddentityindex[player]=lastaddentityindex[player]+1
	if lastaddentityindex[player]>BUCKET then
		lastaddentityindex[player]=1
	end
	
	local ftsrc=ft_source()
	if is_furnace(entity) and #ftsrc>1 then
		e.furnace_source=ftsrc
	end
end

function on_built_entity(event)
	local pt=event.created_entity.prototype
	new_entity(event.created_entity)
end

function on_entity_cloned(event)
	local pt=event.destination.prototype
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
	
	entitieslist[p.playerid][p.idx][entity.unit_number]=nil
	entitiesidx[entity.unit_number]=nil
end

function on_entity_died (event)
	remove_entity(event.entity)
end

function on_player_mined_entity (event)
	remove_entity(event.entity)
end

script.on_event(defines.events.on_built_entity, on_built_entity)
script.on_event(defines.events.on_entity_cloned, on_entity_cloned)

local _bucket=1
script.on_event(defines.events.on_tick, function(event)
	if 0 == (event.tick%(5)) then	
		harvest_feed(_bucket)
		_bucket=_bucket+1
		if _bucket>BUCKET then
			_bucket=1
		end
	end
	if onchangeyet then
		onchange()
		onchangeyet = false
	end
	if 0 == (event.tick%(12)) then
		show()
	end
end)

script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_opened , function(event)
	if event.entity~=nil then
		if nil==event.entity.last_user then
			event.entity.last_user=game.get_player(event.player_index)
		end
		new_entity(event.entity)
	end
end)
script.on_event(defines.events.on_gui_selection_state_changed, on_sel_change)
script.on_event(defines.events.on_entity_died, on_entity_died)
script.on_event(defines.events.on_player_mined_entity, on_player_mined_entity)

script.on_event(defines.events.on_robot_built_entity, function(event)
	--game.print("robot build entity "..event.created_entity.prototype.name)
	new_entity(event.created_entity)
end)

script.on_event(defines.events.on_entity_cloned, function(event)
	--game.print("clone entity "..event.destination.prototype.name)
	new_entity(event.destination)
end)

script.on_event(defines.events.on_trigger_created_entity, function(event)
	--game.print("trigger create entity "..event.entity.prototype.name)
	new_entity(event.entity)
end)

script.on_event(defines.events.on_robot_mined_entity, function(event)
	--game.print("robot mine entity "..event.entity.prototype.name)
	remove_entity(event.entity)
end)
script.on_configuration_changed(onchange)
script.on_load(read_save)
script.on_init(init)