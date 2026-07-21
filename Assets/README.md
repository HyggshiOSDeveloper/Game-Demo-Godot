Place sprite/texture assets here (plants, zombies, sun, lawn, UI icons).
All gameplay code references textures via exported Texture2D fields on
PlantData/ZombieData resources, or via placeholder ColorRect/Polygon2D
nodes when no texture is assigned, so the game runs without art.