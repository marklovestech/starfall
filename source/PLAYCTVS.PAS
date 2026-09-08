{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : PLAYCTVS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These are the constants, types and variables that    ***)
(***                 are specifically for PLAYGAME and no other program.  ***)
(*** Input         : N/A                                                  ***)
(*** Output        : N/A                                                  ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

CONST
  solid_area_pattern : ARRAY[0..7] of byte =
                       ($FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF);
  { This pattern is used on the zoom map in order to fill in the squares.    }

TYPE
  main_program_mode_type       = (world_map,world_text,zoom_map,block_text,help_mode,
                                  transportation_world_map,
                                  transportation_zoom_map);
  { This type encompasses all of the various modes of the program.           }

  transportation_mode_type     = (air,land,water);
  { This type describes the kinds of transportation avaiable.                }

VAR
  quit                         : boolean;
  { This variable becomes true when the user finally decides to quit.        }

  param_file                   : text;
  { This is the file where we read to find out just where those overlays are }

  overlay_drive                : string30;
  { And this is the result of reading that file.                             }

  mode                         : main_program_mode_type;
  { This variable always has meaning as to where the player is and what is   }
  { happening in the world.                                                  }

  world_text_mode              : (pending_list,log_list,world_inventory,trade_mode,
                                  compress_time_mode,verify_quit_mode);
  { If in the world_text_mode, then the subdivisions above are possible      }

  resource_window_mode         : (no_resource_window_mode,
                                  exploration_equipment_selection,
                                  extraction_mineral_selection,
                                  extraction_equipment_selection,
                                  development_object_selection,
                                  development_equipment_selection,
                                  refinement_object_selection,
                                  refinement_equipment_selection,
                                  transportation_equipment_selection,
                                  production_object_selection,
                                  general_editing);
  { When editing the resource window, the above modes are possible           }

  block_text_mode              : (no_mode,block_resource_window_mode,
                                  block_pending_window_mode,
                                  block_log_window_mode);
  { When just in the block text plain, the above modes are possible          }

  key                          : char;
  { This is the key that is usually gotten by the user from get_key_with_clk }

  world_map_cursor_save        : ARRAY[1..sector_zoom_size,1..sector_zoom_size]
                                 of byte;
  { This is where we save the area on the world map when we plunk a cursor   }
  { there on the screen.                                                     }

  zoom_map_picture             : ^zoom_picture_type;
  { This is where the picture that is always currently displayed on the      }
  { zoom map is kept.                                                        }

  current_pending_window_ptr   : pending_ptr;
  current_pending_window_item  : pending_ptr;
  { These two pointers keep track of where we are in either pending window   }

  current_log_window_ptr       : log_ptr;
  current_log_window_item      : log_ptr;
  { These two pointers keep track of where we are in either log window       }

  current_resource_window_ptr  : resource_ptr;
  current_resource_window_line : integer;
  current_resource_window_item : resource_ptr;
  { These three pointers keep track of what is happening in the resource wind}

  current_trade_window_ptr     : resource_ptr;
  current_trade_window_line    : integer;
  current_trade_window_item    : resource_ptr;
  { These three pointers keep track of where we are in the trading window    }

  zoom_map_base_color          : integer;
  { This variable flips back and forth as the base color flips back & forth  }

  min_allowable_resource       : integer;
  max_allowable_resource       : integer;
  { These two variables are used in develop and refine in order to insure    }
  { no wandering outside of permissible resource boundaries is allowed.      }

  reupdate_resource_window     : boolean;
  reupdate_log_and_pending_windows : boolean;
  { These two variables are set while looking over the world.  If they are   }
  { true when the updating is completed, then the windows are updated.       }

  current_inventory_resource_item : resource_ptr;
  current_inventory_land_item  : human_resource_list_ptr;
  { These two variables keep track of where we are in the world inventory    }

  current_transportation_mode  : transportation_mode_type;
  current_transportation_ptr   : transportation_list_ptr;
  current_transportation_pending : pending_ptr;
  current_transportation_blocks  : integer;
  { All of these variable have various things to do with laying out a new    }
  { path for a transportation pending item.                                  }

