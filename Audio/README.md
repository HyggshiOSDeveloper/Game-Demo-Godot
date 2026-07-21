Place .ogg/.wav files here:
  music_menu.ogg, music_battle.ogg,
  sfx_plant.ogg, sfx_shoot.ogg, sfx_zombie_bite.ogg, sfx_zombie_die.ogg,
  sfx_explosion.ogg, sfx_sun_collect.ogg, sfx_win.ogg, sfx_lose.ogg
AudioManager.gd (autoload) loads these by path and will silently skip
any that are missing, so the game runs without audio assets too.