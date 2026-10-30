48 ELEMENTAL ICONS
===================

48 pixel-art icons for damage types, resistances, buffs and spell effects:
fire, ice, void, poison, arcane, radiation, gravity, plasma and more. True
pixel grid, limited palette, hard edges, no anti-aliasing, no half-transparent
pixels.


WHAT'S IN THE BOX
-----------------
png_32/            48 icons at 32x32   (source size)
png_64/            48 icons at 64x64
png_32_x4/  _x8/   nearest-neighbour upscales, ready to drop in
png_64_x4/  _x8/

aseprite/32/       48 indexed .aseprite source files
aseprite/64/       48 indexed .aseprite source files

atlas/             packed sprite sheets with JSON frame data
                   atlas_32.png (224x224) + atlas_32.json
                   atlas_64.png (448x448) + atlas_64.json

palette/           palette.gpl - the shared colour palette of the whole pack
                   opens in Aseprite, GIMP, Photoshop and Krita

preview/           promo sheets


WHY THE SOURCES MATTER
----------------------
Every icon ships as an indexed .aseprite file, not just a flattened PNG. Open
it, retint an element, add a pulse frame, swap the glow colour for your own
rarity tiers - the pack is a starting point, not a dead end.

The atlas JSON lists every frame by name and position, so Unity, Godot and
GameMaker can slice the sheet without any manual setup.


THE SET
-------
Classic Elements      8   flame, water droplet, ice shard, lightning,
                          earth stone, wind tornado, nature leaf, light sun

Dark & Arcane         8   void shadow, arcane galaxy, curse, nightmare,
                          corruption, gravity, chaos swirl, obsidian

Life & Death          8   blood droplet, poison skull, spirit ghost, holy,
                          spore, coral, thorn, tar

Alchemy & Hazard      8   acid, radiation, smoke, ash, ember, rust,
                          magma, metal shard

Crystal & Material    8   crystal, glass, silver, gold, bone, sand,
                          frost, steam

Cosmic & Mystic       8   cosmic, sonic, plasma, time, dream, aether,
                          static, prism

Files are named after the icon. void_shadow.png is called void_shadow.png -
no ID hunting, no renaming pass before you can use the pack.


LICENSE
-------
See LICENSE.txt


Missing an element from the set? Tell me - I read every message and packs get updated.
