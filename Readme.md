# Introduction
* Collect and distribute resources(including ammo) automatically, just like playing RTS game! 
* If you play sandbox mode, please create character first or it will lead script error. Open console, execute `/c game.player.create_character()`
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
* Supported resources: all items needed by all science pack + artillery shell. To avoid waste I set a max value. If the resource reach the limit the script will not collect it from machine, you can still use belt+inserter+chest to collect.

* "steam" will not be managed, because different temperature works different(nuclear power)

* Furnace batch mode: Click the FT button to select type and put furnace. If you don't like this select "none"

* Resources exchange: Click the button, follow the tips. Fluid types are not supported. If you want give back the resource, put the resource to chest.

# Settings

* `preferred-fuel`, default `coal`, if a burner is empty, try to refill it with this fuel-type first.
* `min-fuel`, default 1, Insert more fuel if fuel count is lower than this amount.
* `max-fuel`, default 20, Remove fuel if fuel count is higher than this amount. (Useful when 2+ burner miners mine into each other.)
* `preferred-ammo`, default `piercing-rounds-magazine`, What ammo to insert when a turret is out of ammo.
* `min-ammo`, default 10, Insert more ammo if ammo count is lower than this amount.
* `max-item`, default 2'000, Maximum number of items to store of each type.
* `max-liquid`, default 25'000, Maximum amount of liquid to store of each type.
* `min-item`, default 10, Minimum number of items to store of each type. Only auto-fill machines with items when we have more then this amount. This make sure you always have a few items available for handcrafting or placement.
* `item-columns`, default 28, How many items to show on each row. Lower this if you have other mods that also want to use the top-space.
* `ft-button`, default `true`, Show the Furnace-template configuration button. Turn off this to save space by hiding the button.
})