# Factorio-Craftable-Quality



Allow quality to be craftable on demand as well as chance based.



Features
---------

- Lets you craft quality base items (plates, etc) from lower quality items with a 100% outcome. This lets you craft further quality items from all quality ingredients avoiding the random chance mechanics.
- Its intended to allowing crafting those one off items when wanted and not as a full replacement to the entire quality mechanic. For example making the bulk base ingredients for quality power armors and equipment on demand.
- The simplest use case is to use a filtered inserter to only remove the real quality item from the assembling machine and not the "conversion" item that will spoil. See Usage Notes for full details.



Usage Notes
---------

- The mod has to use the item spoilage mechanic. This means the crafted "conversion" items take a few seconds to change into the real quality items. For example going from the conversion "uncommon iron plate" item to a real "iron plate" of uncommon quality item. The recipe used has output inventory slots in the machines for both the conversion and real items. So the best setup is is to just use filtered inserters to only remove the real items from the machines.
- This spoilage process is best done by putting the conversion items into a chest and then only taking them out once they are the real item. When the items spoil in a chest or other inventory (player, car, etc) the conversion to the real item has near 0 performance impact on the game.
- The mod supports the conversion items spoiling in assembling machines, inserters hands, robots and on the ground. This does use a little game performance though.
- The mod doesn't handle the conversion items spoiling on belts. So a warning message is shown in-game and the item is placed on the ground should this occur. This is due to complexity and performance reasons.



Options
---------

-



Limitations
---------

- Any spoiling conversion items from this mod in a players inventory when in Editor mode will just be placed on the ground where they are. This can't be detected and looks the same as when an item spoils on the ground from the Factorio API notification.
- Spoiling on belts isn't handled as it's a far more complicated situation than other scenarios. A guess would have to be made on which side of the belt the item was on when it spoilt and this would have a noticeable impact on performance. Plus I just don't think there is a real need for this given the small number of these you'd be producing.
- I have to define each situation for when a conversion item spoils. So if you notice any items vanishing please report them as this is a situation I didn't expect a conversion item to be in when it spoils. e.g. it shouldn't be possible to have one inside a furnace at the point of spoiling, so this isn't coded for.



Notes
---------

- This was developed as a technical curiosity. It has to use the spoilage mechanic as the Factorio API currently doesn't allow recipe varying quality outputs.
- Items are included when they're crafted from raw resources or purely from fluids. We can't filter out any redundant items when there are multiple recipes to craft them as they're only redundant if the recipes are unlocked in a specific order. For example if you start on Vulcanus then copper wire is made from only a fluid and thus needs a conversion recipe, but for a Nauvis start copper wire conversion is un-needed.
- It will try and handle changes made by other mods, but may fail in places. Please do let me know of any failures, but equally I might just get bored and not handle them.