{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : KEYPRCS.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These are the main procedures to handle the          ***)
(***                 interpretation of keys from the user.                ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE handle_text_screen_keys(key : char; fkey: boolean);
VAR
  trash_ptr : resource_ptr;
BEGIN
  IF fkey
    THEN
      CASE key OF
        F1     : BEGIN
                   mode:=world_map;
                   update_human_resource_list(current_block_x,current_block_y);
                   refresh_screen;
                 END;
        F2     : BEGIN
                   IF (base_block_x=current_block_x) AND
                      (base_block_y=current_block_y)
                     THEN
                       Trade
                     ELSE
                       beep;
                 END;
        F3     : Explore;
        F4     : Extract;
        F5     : Develop;
        F6     : Refine;
        F7     : Produce;
        F8     : Transport;
        F9     : edit_block_pending_window;
        F10    : edit_block_log_window;
  SHF1..SHF10  : display_function_key_help_screen(key);
        else   bad_key;
      END
    ELSE
      CASE key OF
        'h','H': display_help_screen('General Help Screen');
        't'    : compress_time;
        'T'    : display_help_screen('Time Control Help Screen');
        return : BEGIN
                   mode:=zoom_map;
                   update_human_resource_list(current_block_x,current_block_y);
                   refresh_screen;
                 END;
        'r'    : BEGIN
                   resource_window_mode:=general_editing;
                   clear_block_text_prompt_line;
                   trash_ptr:=get_selection_tree(world_matrix[current_block_x]^[current_block_y]^.resources);
                 END;
        'R'    : display_help_screen('Resource Window Help Screen');
        escape : display_help_screen('Block Screen Commands');
        else   bad_key;
      END;
END;

OVERLAY PROCEDURE handle_transportation_zoom_map_keys(key : char; fkey : boolean);
VAR
  old_x : integer;
  old_y : integer;
BEGIN
  old_x:=current_block_x;
  old_y:=current_block_y;
  IF fkey
    THEN
      CASE key OF
      F1       : BEGIN
                   mode:=transportation_world_map;
                   refresh_screen;
                 END;
      F8       : BEGIN
                   complete_transportation_entry;
                 END;
  SHF1..SHF10  : display_function_key_help_screen(key);
        Rarr   : BEGIN
                   zoom_map_move_east;
                   IF legal_move(old_x,old_y,current_block_x,current_block_y)
                     THEN
                       BEGIN
                         add_item_to_transportation_list(old_x,old_y,
                                                         current_block_x,
                                                         current_block_y);
                       END
                     ELSE
                       BEGIN
                         beep;
                         zoom_map_move_west;
                       END;
                 END;
        Larr   : BEGIN
                   zoom_map_move_west;
                   IF legal_move(old_x,old_y,current_block_x,current_block_y)
                     THEN
                       BEGIN
                         add_item_to_transportation_list(
                                                         old_x,old_y,
                                                         current_block_x,
                                                         current_block_y);
                       END
                     ELSE
                       BEGIN
                         beep;
                         zoom_map_move_east;
                       END;
                 END;
        Uarr   : BEGIN
                   zoom_map_move_north;
                   IF legal_move(old_x,old_y,current_block_x,current_block_y)
                     THEN
                       BEGIN
                         add_item_to_transportation_list(
                                                         old_x,old_y,
                                                         current_block_x,
                                                         current_block_y);
                       END
                     ELSE
                       BEGIN
                         beep;
                         zoom_map_move_south;
                       END;
                 END;
        Darr   : BEGIN
                   zoom_map_move_south;
                   IF legal_move(old_x,old_y,current_block_x,current_block_y)
                     THEN
                       BEGIN
                         add_item_to_transportation_list(
                                                         old_x,old_y,
                                                         current_block_x,
                                                         current_block_y);
                       END
                     ELSE
                       BEGIN
                         beep;
                         zoom_map_move_north;
                       END;
                 END;
        else   bad_key;
      END
    ELSE
      CASE key OF
        't'    : compress_time;
        'T'    : display_help_screen('Time Control Help Screen');
        return : BEGIN
                   mode:=transportation_world_map;
                   refresh_screen;
                 END;
        escape : display_help_screen('Sector Map Commands');
        'h','H': display_help_screen('General Help Screen');
        else   bad_key;
      END;
END;

OVERLAY PROCEDURE handle_zoom_map_keys(key : char; fkey : boolean);
BEGIN
  IF fkey
    THEN
      CASE key OF
      F1       : BEGIN
                   mode:=world_map;
                   refresh_screen;
                 END;
      F2       : BEGIN
                   IF (base_block_x=current_block_x) AND
                      (base_block_y=current_block_y)
                     THEN
                       Trade
                     ELSE
                       beep;
                 END;
  F3..F10      : BEGIN
                   IF block_ok_for_zoom(current_block_x,current_block_y)
                     THEN
                       BEGIN
                         possibly_allocate_a_surface_resource(current_block_x,current_block_y);
                         mode:=block_text;
                         block_text_mode:=no_mode;
                         resource_window_mode:=no_resource_window_mode;
                         refresh_screen;
                         CASE key OF
                           F3     : Explore;
                           F4     : Extract;
                           F5     : Develop;
                           F6     : Refine;
                           F7     : Produce;
                           F8     : Transport;
                           F9     : edit_block_pending_window;
                           F10    : edit_block_log_window;
                         END;
                       END
                     ELSE
                       beep;
                 END;
  SHF1..SHF10  : display_function_key_help_screen(key);
        Rarr   : zoom_map_move_east;
        Larr   : zoom_map_move_west;
        Uarr   : zoom_map_move_north;
        Darr   : zoom_map_move_south;
        else   bad_key;
      END
    ELSE
      CASE key OF
        space  : BEGIN
                   IF block_ok_for_zoom(current_block_x,current_block_y)
                     THEN
                       BEGIN
                         possibly_allocate_a_surface_resource(current_block_x,current_block_y);
                         mode:=block_text;
                         block_text_mode:=no_mode;
                         resource_window_mode:=no_resource_window_mode;
                         refresh_screen;
                       END
                     ELSE
                       beep;
                 END;
        'h','H': display_help_screen('General Help Screen');
        'B'    : display_help_screen('Base Help Screen');
        'b'    : BEGIN
                   IF (NOT trader_in_orbit) OR (new_planet)
                     THEN
                       change_base
                     ELSE
                       beep;
                 END;
        't'    : compress_time;
        'T'    : display_help_screen('Time Control Help Screen');
        return : BEGIN
                   mode:=world_map;
                   refresh_screen;
                 END;
        escape : display_help_screen('Sector Map Commands');
        else   bad_key;
      END;
END;

OVERLAY PROCEDURE handle_transportation_world_map_keys(key : char; fkey : boolean);
VAR
  old_x   : integer;
  old_y   : integer;
BEGIN
  old_x:=current_block_x;
  old_y:=current_block_y;
  IF fkey
    THEN
      CASE key OF
         F8    : BEGIN
                   complete_transportation_entry;
                 END;
   SHF1..SHF10 : display_function_key_help_screen(key);
         Rarr  : BEGIN
                   world_map_move_east;
                   IF legal_move(old_x,old_y,current_block_x,current_block_y)
                     THEN
                       BEGIN
                         add_item_to_transportation_list(
                                                         old_x,old_y,
                                                         current_block_x,
                                                         current_block_y);
                       END
                     ELSE
                       BEGIN
                         beep;
                         world_map_move_west;
                       END;
                 END;
         Larr  : BEGIN
                   world_map_move_west;
                   IF legal_move(old_x,old_y,current_block_x,current_block_y)
                     THEN
                       BEGIN
                         add_item_to_transportation_list(
                                                         old_x,old_y,
                                                         current_block_x,
                                                         current_block_y);
                       END
                     ELSE
                       BEGIN
                         beep;
                         world_map_move_east;
                       END;
                 END;
         Uarr  : BEGIN
                   world_map_move_north;
                   IF legal_move(old_x,old_y,current_block_x,current_block_y)
                     THEN
                       BEGIN
                         add_item_to_transportation_list(
                                                         old_x,old_y,
                                                         current_block_x,
                                                         current_block_y);
                       END
                     ELSE
                       BEGIN
                         beep;
                         world_map_move_south;
                       END;
                 END;
         Darr  : BEGIN
                   world_map_move_south;
                   IF legal_move(old_x,old_y,current_block_x,current_block_y)
                     THEN
                       BEGIN
                         add_item_to_transportation_list(
                                                         old_x,old_y,
                                                         current_block_x,
                                                         current_block_y);
                       END
                     ELSE
                       BEGIN
                         beep;
                         world_map_move_north;
                       END;
                 END;
         else  bad_key;
       END
     ELSE
       CASE key OF
         space : BEGIN
                   mode:=transportation_zoom_map;
                   refresh_screen;
                 END;
        't'    : compress_time;
        'T'    : display_help_screen('Time Control Help Screen');
        escape : display_help_screen('World Map Commands');
        'h','H': display_help_screen('General Help Screen');
        else   bad_key;
      END;
END;

OVERLAY PROCEDURE handle_world_map_keys(key : char; fkey : boolean);
BEGIN
  IF fkey
    THEN
      CASE key OF
          F2   : BEGIN
                   IF (base_block_x<>-1) AND
                      (base_block_y<>-1)
                     THEN
                       Trade
                     ELSE
                       beep;
                 END;
          F9   : BEGIN
                   mode:=world_text;
                   world_text_mode:=pending_list;
                   enable_world_pending_window;
                   refresh_screen;
                   edit_world_pending_window;
                   mode:=world_map;
                   refresh_screen;
                 END;
           F10 : BEGIN
                   mode:=world_text;
                   world_text_mode:=log_list;
                   enable_world_log_window;
                   refresh_screen;
                   edit_world_log_window;
                   mode:=world_map;
                   refresh_screen;
                 END;
   SHF1..SHF10 : display_function_key_help_screen(key);
         Rarr  : World_map_move_east;
         Larr  : World_map_move_west;
         Uarr  : World_map_move_north;
         Darr  : World_map_move_south;
         else  bad_key;
       END
     ELSE
       CASE key OF
         space : BEGIN
                   mode:=zoom_map;
                   refresh_screen;
                 END;
         SHRarr: World_map_move_east_fast;
         SHLarr: World_map_move_west_fast;
         SHUarr: World_map_move_north_fast;
         SHDarr: World_map_move_south_fast;
         'b'   : BEGIN
                   IF (NOT trader_in_orbit) OR (new_planet)
                     THEN
                       change_base
                     ELSE
                       beep;
                 END;
         'B'   : display_help_screen('Base Help Screen');
         'q'   : BEGIN
                   mode:=world_text;
                   world_text_mode:=verify_quit_mode;
                   verify_quit;
                   IF NOT quit
                     THEN
                       BEGIN
                         mode:=world_map;
                         refresh_screen;
                       END;
                 END;
        'Q'    : display_help_screen('Quitting the game');
        's'    : BEGIN
                   save_world;
                   refresh_screen;
                 END;
        'S'    : display_help_screen('Saving the world');
        'l'    : BEGIN
                   load_world;
                   refresh_screen;
                 END;
        'L'    : display_help_screen('Loading a world');
        'i'    : BEGIN
                   mode:=world_text;
                   world_text_mode:=world_inventory;
                   enable_world_inventory_window;
                   refresh_screen;
                   Edit_world_inventory_window;
                 END;
        'I'    : display_help_screen('World Inventory Help Screen');
        't'    : compress_time;
        'T'    : display_help_screen('Time Control Help Screen');
        escape : display_help_screen('World Map Commands');
        'h','H': display_help_screen('General Help Screen');
        else   bad_key;
      END;
END;
