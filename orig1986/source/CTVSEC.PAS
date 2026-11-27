{&P}
(****************************************************************************)
(***             CONSTANTS SECTION - GLOBALS FOR STARFALL                 ***)
(****************************************************************************)

CONST
  current_keyboard_cycle_count         : integer = 0;   (* How many times have we polled the keyboard? *)
  keyboard_wait_cycles                 = 2200;          (* How many times to poll keyboard per second. *)

  screen_width                         = 319;           (* 319 pixels across                           *)
  screen_height                        = 199;           (* 199 pixels down                             *)
  wm_x_coord                           = 9;             (* Offset of world map from left side of screen*)
  wm_y_coord                           = 43;            (* Offset of world map from top of screen.     *)
  wm_top                               = 49;            (* 43 + a tick (5) + 1 line = 49               *)
  wm_left                              = 15;            (* 9 + a tick + 1 line = 15                    *)
  world_picture_size                   = 7000;          (* integers = 14000 bytes                      *)
  zoom_picture_size                    = 2100;          (* integers = 4200 bytes                       *)
  world_width                          = 288;           (* The world is 288 pixels across              *)
  world_height                         = 144;           (* The world is 144 pixels down                *)
  wm_tick_length                       = 5;             (* Each little tick on world map is five long. *)
  wm_sector_width                      = 8;             (* A sector is 8 wide                          *)
  wm_sector_height                     = 8;             (* A sector is 8 high                          *)
  wm_palette                           = 1;             (* This is the palette that gives RGB & white  *)
  wm_background                        = 10;            (* Background color of green                   *)
  wm_blue                              = 1;             (* Blue's number in the palette                *)
  wm_green                             = 0;             (* Green = background, so it gets 0 in palette *)
  wm_red                               = 2;             (* Red's number in the palette                 *)
  wm_cursor_color                      = 2;             (* The cursor is red.                          *)
  wm_white                             = 3;             (* White's place in the world map palette      *)
  wm_cursor_dot_color                  = 3;             (* Dot on wm cursor is white                   *)
  world_map_fast_speed                 = 8;             (* This is the speed shifted arrows move at    *)
  sector_zoom_size                     = 9;             (* The sector zoom map is 9X9                  *)
  zoom_map_left                        = 115;           (* The left side of the zoom map from side     *)
  zoom_map_top                         = 55;            (* The top of the zoom map from top of screen  *)
  zoom_map_right                       = 205;           (* ditto                                       *)
  zoom_map_bottom                      = 145;           (* ditto                                       *)
  zoom_map_box_width                   = 10;            (* The little boxes on the zoom                *)
  zoom_map_box_height                  = 10;            (* map are 10X10 pixels                        *)
  max_altitude                         = 240;           (* This corresponds to 24000 meters - high!    *)
  Asterisk_line                        =                (* This line is used on all windows.           *)
  '******************************************************************************';

  (**************************************************************************)
  (*** Ascii definitions of many of the keyboard characters:              ***)
  (**************************************************************************)

  space                                = #32;
  escape                               = #27;
  return                               = #13;
  bell                                 = #7;
  Larr              = #75;             SHLarr               = #52;
  Rarr              = #77;             SHRarr               = #54;
  Uarr              = #72;             SHUarr               = #56;
  Darr              = #80;             SHDarr               = #50;
  F1                = #59;             SHF1                 = #84;
  F2                = #60;             SHF2                 = #85;
  F3                = #61;             SHF3                 = #86;
  F4                = #62;             SHF4                 = #87;
  F5                = #63;             SHF5                 = #88;
  F6                = #64;             SHF6                 = #89;
  F7                = #65;             SHF7                 = #90;
  F8                = #66;             SHF8                 = #91;
  F9                = #67;             SHF9                 = #92;
  F10               = #68;             SHF10                = #93;
  Home              = #71;
  Endkey            = #79;
  Inskey            = #82;
  Delkey            = #83;
  PgUp              = #73;
  PgDn              = #81;
  formfeed          = #12;

  (**************************************************************************)
  (*** Continutation of constant definitions                              ***)
  (**************************************************************************)

  zm_x_coord                           = 0;             (* Coordinate of zoom map x                    *)
  zm_y_coord                           = 109;           (* Coordinate of zoom map y                    *)
  max_resource                         = 255;           (* There are 255 possible resources            *)
  block_text_prompt_line               = 4;             (* This is the line where we talk to the user  *)
  resource_window_mode_header_color    = Brown;         (* This says things like 'Enter equipment, etc.*)
  resource_window_cursor_color         = LightRed;      (* This is the color of the indicator arrow    *)
  block_text_general_info_color        = LightGray;     (* Color of Latitude, etc.                     *)
  resource_window_data_selected_color  = LightGreen;    (* Lights up green when you select it          *)
  resource_window_data_normal_color    = LightBlue;     (* And is normally blue                        *)
  max_resource_window_y                = 13;            (* These variables, and the ones below, are all*)
  min_resource_window_y                = 6;             (* used to indicate the limits of the various  *)
  min_block_pending_window_y           = 15;            (* windows:                                    *)
  max_block_pending_window_y           = 18;            (*     "                                  "    *)
  min_block_log_window_y               = 20;            (*     "                                  "    *)
  max_block_log_window_y               = 23;            (*     "                                  "    *)
  min_world_log_window_y               = 18;            (*     "                                  "    *)
  max_world_log_window_y               = 23;            (*     "                                  "    *)
  min_world_pending_window_y           = 11;            (*     "                                  "    *)
  max_world_pending_window_y           = 16;            (*     "                                  "    *)
  min_world_inventory_window_y         = 5;             (*     "                                  "    *)
  max_world_inventory_window_y         = 9;             (*     "                                  "    *)
  min_trade_window_y                   = 8;             (*     "                                  "    *)
  max_trade_window_y                   = 16;            (*     "                                  "    *)
  block_mode_explanation_color         : integer=White; (* Color that 'EXPLORE' lights up in           *)
  block_mode_explanation_x             = 1;             (* These two define where it says things like  *)
  block_mode_explanation_y             = 1;             (* 'EXPLORE', 'EXTRACT', etc.                  *)
  clock_text_color                     = Yellow;        (* This is the color the realtime clock is     *)
  window_selected_border_color         = Yellow;        (* When you enter a window, this color comes up*)
  window_normal_border_color           = Magenta;       (* This is the normal window border color      *)
  game_time_display_color              = LightRed;      (* Game time clock displays in this color      *)
  game_time_display_x                  = 35;            (* These two define where the game-time clock  *)
  game_time_display_y                  = 1;             (* displays.                                   *)
  trade_window_x                       = 2;             (* This is the offset into the trade window    *)
  cost_of_calling_trader               = 50000.00;      (* Expensive, huh?                             *)
  lowest_game_year                     = 2050;          (* These and the following ones define the     *)
  game_year_range                      = 250;           (* various time constants for the game.        *)
  seconds_per_minute                   = 60;            (*     "                                  "    *)
  minutes_per_hour                     = 60;            (*     "                                  "    *)
  hours_per_day                        = 24;            (*     "                                  "    *)
  days_per_month                       = 30;            (*     "                                  "    *)
  months_per_year                      = 12;            (*     "                                  "    *)
  world_circumference                  = 38500.0;       (* 38,500 km around the equator                *)
  time_speed_control_color             = LightBlue;     (* The whole screen comes up in this color     *)
  initial_debt_limit                   = -5950000.0;    (* Lots of money to start with  PLATINUM VISA  *)
  exploration_action                   = 001;           (* These and the following are the codes       *)
  extraction_action                    = 002;           (* for the various kinds of actions            *)
  development_action                   = 003;           (*     "                                  "    *)
  refinement_action                    = 004;           (*     "                                  "    *)
  production_action                    = 005;           (*     "                                  "    *)
  transportation_action                = 006;           (*     "                                  "    *)
  trader_arriving_action               = 007;           (*     "                                  "    *)
  trader_leaving_action                = 008;           (*     "                                  "

(****************************************************************************)
(***          TYPE DECLARATION SECTION - GLOBALS FOR STARFALL             ***)
(****************************************************************************)

TYPE
  text_line_type                       = string[80];
  string30                             = string[30];
  string50                             = string[50];
  string10                             = string[10];


  { This type is what is used whenever a time needs to be shown to the user  }
  time_type                            = RECORD
                                           date     : integer;
                                           month    : integer;
                                           year     : integer;
                                           hour     : integer;
                                           minute   : integer;
                                           second   : integer;
                                         END;

  { This type is needed in order to call up the system clock via a MS-DOS    }
  { function call.  For further information, see TURBO 3.0 Reference Manual  }
  registers                            = RECORD
                                           AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags
                                           : integer;
                                         END;

  { This is a buffer type of variable that is used by GETPIC and PUTPIC to   }
  { store a picture on the screen in memory and vice versa. For details on   }
  { how to figure correct buffer size, see page 173 of the TURBO 3.0         }
  { Reference Manual                                                         }
  world_picture_type                   = ARRAY[1..world_picture_size]
                                         of integer;

  { This is another buffer variable used to store the current picture of the  }
  { zoom map. In order to move it around quick, this is necessary             }
  zoom_picture_type                    = ARRAY[1..zoom_picture_size]
                                         of integer;

  { This is main dynamic storage type - It is how the resources are stored.   }
  { Resources are stored in trees under their parent land items.  Note that   }
  { resource trees are linked in all four directions - next, prev, child, and }
  { parent.  This makes editing a tree dynamically orders of magnitude easier.}
  resource_ptr                         = ^resource_type;
  resource_type                        = RECORD
                                           next         : resource_ptr;
                                           prev         : resource_ptr;
                                           child        : resource_ptr;
                                           parent       : resource_ptr;
                                           resource_num : byte;
                                           quantity     : real;
                                           flags        : byte;
                                         END;

  { This type is used to store what it takes to make something.  A tree of   }
  { ingredients is used by the program.  These sit under all resources in the}
  { resources array (see Below).  The system will always use the first       }
  { alternative first, if it can.                                            }
  ingredient_ptr                       = ^ingredient_item;
  ingredient_item                      = RECORD
                                           next            : ingredient_ptr;
                                           alternatives    : ingredient_ptr;
                                           resource_num    : byte;
                                           quantity        : real;
                                           time_factor     : real;
                                         END;

  { These variables store all the data for the world. For a                  }
  { more detailed description of this, see the beginning of the MAKEWRLD     }
  { program.                                                                 }
  land_ptr                             = ^land_item;
  land_item                            = RECORD
                                           altitude     : byte;
                                           climate      : byte;
                                           resources    : resource_ptr;
                                         END;

  { At all times, the system keeps track of which blocks have human resources}
  { and which don't.  This enables it to only look at those blocks which are }
  { active.  This makes updates about 3 orders of magnitude faster.          }
  human_resource_list_ptr              = ^human_resource_list_item;
  human_resource_list_item             = RECORD
                                           next  : human_resource_list_ptr;
                                           prev  : human_resource_list_ptr;
                                           x     : integer;
                                           y     : integer;
                                         END;

  { The program keeps a log of all of the actions which have happened in the }
  { world.  This linked list is how it does it.                              }
  log_ptr                              = ^log_item_type;
  log_item_type                        = RECORD
                                           next            : log_ptr;
                                           prev            : log_ptr;
                                           x               : integer;
                                           y               : integer;
                                           action_desc     : string30;
                                           completion_time : time_type;
                                         END;

  { When the user initiates a transportation pending item, we store the list }
  { that they type in.  As time goes by, we use up this list.                }
  { Note that this list is subordinate to the pending item that it is linked }
  { to.                                                                      }
  transportation_list_ptr              = ^transportation_item_type;
  transportation_item_type             = RECORD
                                           next     : transportation_list_ptr;
                                           prev     : transportation_list_ptr;
                                           x        : integer;
                                           y        : integer;
                                           distance : real;
                                         END;

  { The system, because it is operating in realtime (gametime-realtime, but  }
  { realtime in every sense of the word otherwise) needs to keep track of    }
  { everything that is going on.  This is the list that helps it do it.      }
  pending_ptr                          = ^pending_item_type;
  pending_item_type                    = RECORD
                                           next                      : pending_ptr;
                                           prev                      : pending_ptr;
                                           x                         : integer;
                                           y                         : integer;
                                           action_type               : byte;
                                           speed                     : real;
                                           distance                  : real;
                                           time_started              : time_type;
                                           estimated_completion_time : time_type;
                                           updates_left              : integer;
                                           resources_involved        : resource_ptr;
                                           objects_involved          : resource_ptr;
                                           transportation_list       : transportation_list_ptr;
                                         END;

  { This is the biggest record I ever want to see.  It is used to define     }
  { every single kind of resource that the game has.  This enables us to     }
  { define totally multipurpose resources, such as a space shuttle that      }
  { can explore, extract, develop, and refine, not to mention move.          }
  resource_desc = RECORD
                    resource_name            : string30;
                    resource_units           : string10;
                    score_value              : integer;
                    empty_weight             : real;
                    base_cost                : real;
                    naturally_occuring       : boolean;
                    subsurface_resource      : boolean;
                    expendable               : boolean;
                    movable                  : boolean;
                    typical_trader_amount    : real;
                    typical_purity           : real;
                    basic_resource_need      : ARRAY[1..4] of byte;
                    basic_need_amount        : ARRAY[1..4] of real;
                    active_resource_need     : ARRAY[1..4] of byte;
                    active_need_amount       : ARRAY[1..4] of real;
                    usable_for_exploration   : boolean;
                    exploration_speed        : real;
                    exploratory_test_effectiveness : ARRAY[1..4] of byte;
                    usable_for_extraction    : boolean;
                    extraction_speed         : real;
                    extractable              : boolean;
                    typical_deposit_size     : real;
                    likelihood_of_occurence  : byte;
                    deposit_contagion_ratio  : byte;
                    usable_for_development   : boolean;
                    development_speed        : real;
                    developable              : boolean;
                    development_result       : byte;
                    start_resource_needed_to_develop : byte;
                    end_resource_needed_to_develop   : byte;
                    usable_for_refinement    : boolean;
                    refinement_speed         : real;
                    refineable               : boolean;
                    refinement_result        : byte;
                    start_resource_needed_to_refine : byte;
                    end_resource_needed_to_refine : byte;
                    usable_for_transportation: boolean;
                    cargo_capacity           : real;
                    air_speed                : real;
                    land_speed               : real;
                    water_speed              : real;
                    produceable              : boolean;
                    time_to_produce          : integer;
                    production_requirements  : ingredient_ptr;
                  END;

(****************************************************************************)
(***             VARIABLE SECTION - GLOBALS FOR STARFALL                  ***)
(****************************************************************************)

VAR
  world_picture                        : ^world_picture_type;
  { Stores the picture of the current world out in dynamic memory            }

  resources                            : ARRAY[0..max_resource] OF resource_desc;
  { Stores all of the resource parameters in main memory - lots              }

  resource_file                        : text;
  { Holds all of the resource parameters that are read into resources array  }

  world_file_name                      : string30;
  { This is the name of the current world in memory                          }
  { It is the file name - i.e. the MS-DOS pathname                           }

  world_name                           : string30;
  { This is the text name - a user-friendly, cute name.                      }

  world_file                           : text;
  { This is the text file that all worlds are read out of and written into   }
  { For a full description on why it is a text file rather than a TYPEd file,}
  { see either LOADWRLD or SAVEWRLD.                                         }

  surface_resource_matrix              : ARRAY[0..15,0..15] of byte;
  { This variable holds what resource is determined by the various           }
  { combination of temperature and moisture.  It may be edited by            }
  { WRLDSHAK, and that is it.  It is used by MAKEWRLD, and PLAYGAME          }

  surface_matrix_file                  : text;
  { This is a text file where the surface matrix information is stored.      }

  temperate_latitude                   : integer;
  { This variable holds how far the temperature latitude is from the equator }

  main_program                         : file;
  { Used to chain back to the main program - STARFALL.COM                    }

  score_file                           : file;
  { This file holds the scores that the best users have gotten               }

  real_time                            : time_type;
  game_time                            : time_type;
  { These two variables store the system's concept of what time it is, in    }
  { both frames that matter to the user.                                     }

  game_time_increment                  : time_type;
  { This variable is used by time control to define how fast time goes by    }

  world_update_increment               : time_type;
  { This is set to a constant of 8 hours - the world is updated 3 times/day  }

  time_to_next_update                  : time_type;
  { This variable counts down to zero from world_update_increment evey second}

  choice                               : char;
  fkey                                 : boolean;
  { These vars are used by most things in the program to read the keyboard   }

  current_block_x                      : integer;
  current_block_y                      : integer;
  { These store the X,Y coordinates of the current block                     }

  smallest_game_time_increment         : time_type;
  { This is the absolute slowest that the game can be set to go             }

  trader_in_orbit                      : boolean;
  trader_called                        : boolean;
  trader_resource_tree_root            : resource_ptr;
  { These variables store the state of the trader, (crazy, tired, moody, etc)}
  { and also store the resources that this trader happens to have with him/her}

  time_world_last_saved                : time_type;
  { This is a user-friendly feature to warn the user if they haven't saved   }
  { the world lately.                                                        }

  new_planet                           : boolean;
  { This is a boolean variable which lets the system know whether to leash   }
  { the player in or let them do whatever they want.  Generally, this only   }
  { applies to moving the base.                                              }

  base_block_x                         : integer;
  base_block_y                         : integer;
  { These two define where the base, if any, is.  -1,-1 means no base        }

  valid                                : boolean;
  { This is used to tell whether a user input was valid or not.              }

  abort_action                         : boolean;
  { This is used to decide whether to abort an action.                       }

  human_resource_list_root             : human_resource_list_ptr;
  { This points into one end of the human resource linked list.              }

  current_debt_limit                   : real;
  colony_financial_status              : real;
  { These two variables add up together to define just how well the user is  }
  { doing, in a financial sense.                                             }

  world_pending_list_root              : pending_ptr;
  world_log_list_root                  : log_ptr;
  { These two define where the world pending and world log lists start in    }
  { memory.                                                                  }
