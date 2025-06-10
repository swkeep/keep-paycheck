Config = Config or {}

local preset = {
     NPC_1 = {
          model = 'MP_F_ExecPA_01',
          variant = {
               -- hair
               [2] = { drawableId = 1, textureId = 0, },
               -- upper
               [3] = { drawableId = 2, textureId = 0, },
               -- lower
               [4] = { drawableId = 2, textureId = 2, },
               -- feet
               [6] = { drawableId = 0, textureId = 0, },
               -- teef
               [7] = { drawableId = 0, textureId = 2, },
               -- accs
               [8] = { drawableId = 2, textureId = 1, },
               -- jbib
               [11] = { drawableId = 1, textureId = 1, }
          },
          voice = 'A_F_Y_BUSINESS_02_WHITE_FULL_01',
          anim_dict = 'anim@amb@board_room@stenographer@computer@',
          anim = {
               'glance_board_01_left_amy_skater_01',
               'idle_01_right_amy_skater_01',
               'idle_02_left_amy_skater_01',
               'idle_02_right_amy_skater_01',
               'investigate_compueter_01_left_amy_skater_01',
               'investigate_computer_01_right_amy_skater_01',
               'look_around_01_left_amy_skater_01',
               'look_around_01_right_amy_skater_01',
               'look_around_02_left_amy_skater_01',
               'look_around_02_right_amy_skater_01',
               'scratch_leg_01_left_amy_skater_01',
               'scratch_leg_01_right_amy_skater_01',
               'tired_01_left_amy_skater_01',
               'tired_01_right_amy_skater_01',
          },
          -- flag = 1,
          -- freeze = true,
          -- invincible = true,
          -- blockevents = true,
     }
}

Config.simple_paycheck = false

Config.interaction = {
     spawn_distance = 50.0,
     despawn_distance = 70.0,
     npcs = {
          {
               preset = preset.NPC_1,
               coords = vector4(241.50, 227.0, 105.43, 145.0),
               box = {
                    minz_offset = -1,
                    maxz_offset = 1.75,
                    w = 1.5,
                    l = 2.35,
                    heading = 160.0
               }
          }
     }
}
