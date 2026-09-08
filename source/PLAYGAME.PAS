(* {$U+} *)
(* {$R+} *)
{&H PLAYGAME - Simulation of running a world }
{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : PLAYGAME.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This is the program called from the STARFALL main    ***)
(***                 menu that will let the user simulate the entire      ***)
(***                 world and still have time for lunch.                 ***)
(*** Input         : None.                                                ***)
(*** Output        : None. (or maybe a fun game)                          ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROGRAM play_the_game;

{$I CTVSEC.PAS  }  { Constant, Type and Variable Section                 }
{$I WMATRDEF.PAS}  { World Matrix TYPE & VAR definitions                 }
{$I PLAYCTVS.PAS}  { TYPES and VARS specifically for PLAYGAME            }
{$I FORWARDS.PAS}  { All of the FORWARD declarations                     }
{$I GRAPH306.P  }  { Graphics inclusion routines from TURBO              }
{$I NOISE.PAS   }  { Learn to make annoying noise to bother the user     }
{$I LANDPRIM.PAS}  { Primitive routines to handle land/water, etc        }
{$I MAPPRIMS.PAS}  { Primitive routines to draw on the maps, etc..       }
{$I MATHPRCS.PAS}  { All sorts of little math routines max, min, etc.    }
{$I WRLDPICS.PAS}  { Procedures for dealing with the world map picture   }
{$I GETVALUA.PAS}  { A primitive routine for GETVALUS, below             }
{$I DRAWBOX.PAS }  { Draw a box                                          }
{$I CLRTIME.PAS }  { Clear out a time variable                           }

(****************************************************************************)
(***                   OVERLAY FILE .000 STARTS HERE                      ***)
(****************************************************************************)

{$I GETVALUS.PAS}  { GetByte, GetInteger, etc input routines             }
{$I COLWINDO.PAS}  { Color a window border                               }
{$I TRNSPRIM.PAS}  { Primitive routines to do the transportation stuff   }

(****************************************************************************)
(***                    OVERLAY FILE .000 ENDS HERE                       ***)
(****************************************************************************)

{$I TIMEMATH.PAS}  { Procedures to do math with time variables           }
{$I RSRCFLAG.PAS}  { Procedures/Functions for the FLAGS in a resource    }
{$I TREEPRCS.PAS}  { Procedures to handle resource trees                 }
{$I UPDATIME.PAS}  { Update the current time from MSDOS                  }
{$I DISPTIME.PAS}  { Procedures for the different displays of time       }
{$I INKEY.PAS   }  { Procedure to scan keyboard                          }
{$I KEYWCLK.PAS }  { Procedure to wait for a key while updating everythin}
{$I WINVPRIM.PAS}  { Procedures to do the world inventory primitives     }
{$I PENDPRIM.PAS}  { Primitives procedures for the pending list          }
{$I TRADCSTS.PAS}  { Procedures to decide stuff list costs and values    }
{$I CLRBTPLI.PAS}  { Clear Block Text Prompt Line                        }
{$I DISPBTMS.PAS}  { Display Block Text Message                          }

(****************************************************************************)
(***                    OVERLAY FILE .001 STARTS HERE                     ***)
(****************************************************************************)

{$I HRLLPRCS.PAS}  { Human resource linked list procedures               }
{$I TRADPRIM.PAS}  { Primitive routines that trading needs               }
{$I WRLONLAT.PAS}  { Procedures to display latitude, longitude numbers   }
{$I PENDPRCS.PAS}  { Pending and log linked list routines                }
{$I DSPTMVRT.PAS}  { Display time vertically                             }

OVERLAY PROCEDURE draw_world_inventory_window_headers;
BEGIN
  TextColor(LightBlue);
  gotoxy(25,4);
  write('  World Inventory of Resources  ');
END;

OVERLAY PROCEDURE display_pending_window_headers;
BEGIN
  TextColor(LightRed);
  IF mode=block_text
    THEN
      gotoxy(2,min_block_pending_window_y)
    ELSE
      gotoxy(2,min_world_pending_window_y);
  writeln('--|-X-|-Y-|---DESCRIPTION OF ACTION----|---ENTRY TIME---|--EST TIME COMP--|--');
END;

OVERLAY PROCEDURE display_log_window_headers;
BEGIN
  TextColor(LightGreen);
  IF mode=block_text
    THEN
      gotoxy(2,min_block_log_window_y)
    ELSE
      gotoxy(2,min_world_log_window_y);
  writeln('--|-X-|-Y-|------DESCRIPTION OF ACTION------------------|---TIME LOGGED---|--');
END;

(****************************************************************************)
(***                    OVERLAY FILE .001 ENDS HERE                     ***)
(****************************************************************************)

PROCEDURE I_am_a_dummy;
BEGIN
END;

(****************************************************************************)
(***                    OVERLAY FILE .002 STARTS HERE                     ***)
(****************************************************************************)

OVERLAY PROCEDURE enable_world_inventory_window_border;
BEGIN
  Color_window_border(min_world_inventory_window_y-1,max_world_inventory_window_y+1,
                      window_selected_border_color);
END;

OVERLAY PROCEDURE enable_world_pending_window_border;
BEGIN
  Color_window_border(min_world_pending_window_y-1,max_world_pending_window_y+1,
                      window_selected_border_color);
END;

OVERLAY PROCEDURE enable_world_log_window_border;
BEGIN
  Color_window_border(min_world_log_window_y-1,max_world_log_window_y+1,
                      window_selected_border_color);
END;

OVERLAY PROCEDURE enable_world_inventory_window;
BEGIN
  current_inventory_land_item:=human_resource_list_root;
  IF current_inventory_land_item<>NIL
    THEN
      current_inventory_resource_item:=world_matrix[current_inventory_land_item^.x]
                                                  ^[current_inventory_land_item^.y]
                                                  ^.resources
    ELSE
      current_inventory_resource_item:=NIL;
END;

OVERLAY PROCEDURE enable_world_pending_window;
BEGIN
  current_pending_window_ptr:=world_pending_list_root;
  current_pending_window_item:=current_pending_window_ptr;
END;

OVERLAY PROCEDURE enable_world_log_window;
BEGIN
  current_log_window_ptr:=world_log_list_root;
  current_log_window_item:=current_log_window_ptr;
END;

OVERLAY PROCEDURE enable_resource_window(tree_root : resource_ptr);
BEGIN
  current_resource_window_ptr:=tree_root;
  current_resource_window_line:=-1;
  current_resource_window_item:=current_resource_window_ptr;
END;

OVERLAY PROCEDURE enable_resource_window_border;
BEGIN
  Color_window_border(min_resource_window_y-1,max_resource_window_y+1,
                      window_selected_border_color);
  draw_resource_window_mode_header;
END;

OVERLAY PROCEDURE disable_resource_window_border;
BEGIN
  Color_window_border(min_resource_window_y-1,max_resource_window_y+1,
                               window_normal_border_color);
  draw_resource_window_mode_header;
END;

OVERLAY PROCEDURE enable_block_pending_window;
BEGIN
  current_pending_window_ptr:=first_pending_for_block(current_block_x,current_block_y);
  current_pending_window_item:=current_pending_window_ptr;
END;

OVERLAY PROCEDURE enable_block_pending_window_border;
BEGIN
  Color_window_border(min_block_pending_window_y-1,max_block_pending_window_y+1,
                      window_selected_border_color);
END;

OVERLAY PROCEDURE disable_block_pending_window_border;
BEGIN
  Color_window_border(min_block_pending_window_y-1,max_block_pending_window_y+1,
                      window_normal_border_color);
END;

OVERLAY PROCEDURE enable_block_log_window;
BEGIN
  current_log_window_ptr:=first_log_for_block(current_block_x,current_block_y);
  current_log_window_item:=current_log_window_ptr;
END;

OVERLAY PROCEDURE enable_block_log_window_border;
BEGIN
  Color_window_border(min_block_log_window_y-1,max_block_log_window_y+1,
                      window_selected_border_color);
END;

OVERLAY PROCEDURE disable_block_log_window_border;
BEGIN
  Color_window_border(min_block_log_window_y-1,max_block_log_window_y+1,
                      window_normal_border_color);
END;

(****************************************************************************)
(***                    OVERLAY FILE .002 ENDS HERE                       ***)
(****************************************************************************)

{$I CHNGPILI.PAS}  { Change pending item to log item                        }

PROCEDURE abort_pending_item(temp_ptr:pending_ptr);
VAR
  amount_done   : real;
  total_updates : real;
  temp_time     : time_type;
  save_x        : integer;
  save_y        : integer;
BEGIN
  IF temp_ptr^.action_type<>trader_arriving_action
    THEN
      BEGIN
        temp_time := temp_ptr^.estimated_completion_time;
        subtract_times(temp_time,temp_ptr^.time_started);
        total_updates:=convert_time_to_updates(temp_time);
        amount_done:=100.0-(temp_ptr^.updates_left/total_updates);
        save_x:=temp_ptr^.x;
        save_y:=temp_ptr^.y;
        finish_pending_item(temp_ptr,amount_done);
        IF (save_x=current_block_x) AND
           (save_y=current_block_y) AND
           (mode=block_text)
          THEN
            BEGIN
              update_resource_window;
              update_block_pending_window;
              update_block_log_window;
            END;
      END
    ELSE
      bad_key;
END;

(****************************************************************************)
(***                    OVERLAY FILE .003 STARTS HERE                     ***)
(****************************************************************************)

OVERLAY PROCEDURE activate_world_inventory_window;
BEGIN
  enable_world_inventory_window;
  enable_world_inventory_window_border;
  update_world_inventory_window;
END;

OVERLAY PROCEDURE deactivate_world_inventory_window;
BEGIN
  Color_window_border(min_world_inventory_window_y-1,max_world_inventory_window_y+1,
                      window_normal_border_color);
END;

OVERLAY PROCEDURE activate_world_pending_window;
BEGIN
  enable_world_pending_window;
  enable_world_pending_window_border;
  update_world_pending_window;
END;

OVERLAY PROCEDURE deactivate_world_pending_window;
BEGIN
  Color_window_border(min_world_pending_window_y-1,max_world_pending_window_y+1,
                      window_normal_border_color);
END;

OVERLAY PROCEDURE activate_world_log_window;
BEGIN
  enable_world_log_window;
  enable_world_log_window_border;
  update_world_log_window;
END;

OVERLAY PROCEDURE deactivate_world_log_window;
BEGIN
  Color_window_border(min_world_log_window_y-1,max_world_log_window_y+1,
                      window_normal_border_color);
END;

OVERLAY PROCEDURE activate_resource_window(tree_root : resource_ptr);
BEGIN
  block_text_mode:=block_resource_window_mode;
  enable_resource_window(tree_root);
  unselect_tree(current_resource_window_ptr);
  enable_resource_window_border;
  Update_resource_window;
END;

OVERLAY PROCEDURE deactivate_resource_window;
BEGIN
  enable_resource_window(world_matrix[current_block_x]^[current_block_y]^.resources);
  update_resource_window;
  disable_resource_window_border;
  block_text_mode:=no_mode;
END;

OVERLAY PROCEDURE activate_block_pending_window;
BEGIN
  block_text_mode:=block_pending_window_mode;
  enable_block_pending_window;
  enable_block_pending_window_border;
  update_block_pending_window;
END;

OVERLAY PROCEDURE deactivate_block_pending_window;
BEGIN
  disable_block_pending_window_border;
  block_text_mode:=no_mode;
END;

OVERLAY PROCEDURE activate_block_log_window;
BEGIN
  block_text_mode:=block_log_window_mode;
  enable_block_log_window;
  enable_block_log_window_border;
  update_block_log_window;
END;

OVERLAY PROCEDURE deactivate_block_log_window;
BEGIN
  disable_block_log_window_border;
  block_text_mode:=no_mode;
END;

OVERLAY FUNCTION sufficient_basic_resources(resource_tree : resource_ptr;
                                            time          : integer):boolean;

FUNCTION sufficient_basic_resources_overlay(resource_tree : resource_ptr;
                                            time          : integer):boolean;
VAR
  temp_val : boolean;
  loop     : integer;
BEGIN
  temp_val:=true; (* assume innocent until proven guilty *)
  IF resource_tree<>NIL
    THEN
      BEGIN
        WITH resources[resource_tree^.resource_num] DO
          BEGIN
            (* First, check node *)
            FOR loop:=1 to 4 DO  (* Check all four possible needs *)
              BEGIN
                IF basic_resource_need[loop]<>0
                  THEN
                    BEGIN
                      IF resources[basic_resource_need[loop]].expendable
                        THEN
                          BEGIN
                            (* we do need to find some of this stuff *)
                            IF (amount_of_resource_in_top_level_of_tree(basic_resource_need[loop],
                                                                        resource_tree^.child)
                              <(basic_need_amount[loop]*time*resource_tree^.quantity))
                              THEN
                                temp_val:=false;
                          END
                        ELSE
                          BEGIN
                            IF (amount_of_resource_in_top_level_of_tree(basic_resource_need[loop],
                                                                        resource_tree^.child)
                              <(basic_need_amount[loop]*resource_tree^.quantity))
                               THEN
                                 temp_val:=false;
                          END;
                    END;
              END;
          END;
      (* Then, check children, and *)
        IF temp_val=true (* are we ok so far ? *)
          THEN
            temp_val:=sufficient_basic_resources_overlay(resource_tree^.child,time);
        IF temp_val=true (* are we still ok? *)
          THEN
            temp_val:=sufficient_basic_resources_overlay(resource_tree^.next,time);
      END;
   sufficient_basic_resources_overlay:=temp_val;
END;

BEGIN
   sufficient_basic_resources:=sufficient_basic_resources_overlay(resource_tree,time);
END;

OVERLAY FUNCTION use_basic_resources_up(resource_tree : resource_ptr;
                                        time          : integer):boolean;

FUNCTION use_basic_resources_up_overlay(resource_tree : resource_ptr;
                                 time          : integer):boolean;
VAR
  temp_val : boolean;
  loop     : integer;
BEGIN
  temp_val:=true;
  IF resource_tree<>NIL
    THEN
      BEGIN
        WITH resources[resource_tree^.resource_num] DO
          BEGIN
            FOR loop:=1 to 4 DO  (* Check all four possible needs *)
              BEGIN
                IF basic_resource_need[loop]<>0
                  THEN
                    BEGIN
                      IF resources[basic_resource_need[loop]].expendable
                        THEN
                          BEGIN
                            (* we do need to find some of this stuff *)
                            IF (amount_of_resource_in_top_level_of_tree(basic_resource_need[loop],
                                                                        resource_tree^.child)
                              <(basic_need_amount[loop]*time*resource_tree^.quantity))
                              THEN
                                BEGIN
                                  temp_val:=false;
                                  use_some_resource_from_top_level_of_tree(basic_resource_need[loop],
                                                                           amount_of_resource_in_top_level_of_tree(
                                                                           basic_resource_need[loop],resource_tree^.child),
                                                                           resource_tree^.child);
                                END
                              ELSE
                                BEGIN
                                  use_some_resource_from_top_level_of_tree(basic_resource_need[loop],
                                                                       basic_need_amount[loop]*time*resource_tree^.quantity,
                                                                       resource_tree^.child);
                                END;
                          END
                        ELSE
                          BEGIN
                            IF (amount_of_resource_in_top_level_of_tree(basic_resource_need[loop],
                                                                        resource_tree^.child)
                              <(basic_need_amount[loop]*resource_tree^.quantity))
                                THEN
                                  BEGIN
                                    temp_val:=false;
                                    use_some_resource_from_top_level_of_tree(basic_resource_need[loop],
                                                                             amount_of_resource_in_top_level_of_tree(
                                                                             basic_resource_need[loop],resource_tree^.child),
                                                                             resource_tree^.child);
                                  END
                                ELSE
                                  BEGIN
                                    use_some_resource_from_top_level_of_tree(basic_resource_need[loop],
                                                                      basic_need_amount[loop]*resource_tree^.quantity,
                                                                      resource_tree^.child);
                                  END
                          END;
                    END;
              END;
          END;
        temp_val:=temp_val AND use_basic_resources_up_overlay(resource_tree^.child,time);
        temp_val:=temp_val AND use_basic_resources_up_overlay(resource_tree^.next,time);
      END;
  use_basic_resources_up_overlay:=temp_val;
END;

BEGIN
  use_basic_resources_up:=use_basic_resources_up_overlay(resource_tree,time);
END;

OVERLAY FUNCTION sufficient_active_resources(resource_tree : resource_ptr;
                                     time          : integer):boolean;
VAR
  temp_val   : boolean;
  loop       : integer;
BEGIN
  temp_val:=true;
  (* This routine is a lot simpler, since we only need to check the top  *)
  (* level of the ENTIRE tree, and the top level of each subtree.  Thus, *)
  (* this process does not need to be recursive, but can be iterative.   *)
  WHILE resource_tree<>NIL DO (* step across the top level until done *)
    BEGIN
      WITH resources[resource_tree^.resource_num] DO
        BEGIN
          FOR loop:=1 to 4 DO (* Step through all active resource needs *)
            BEGIN
              IF active_resource_need[loop]<>0
                THEN
                  BEGIN
                    IF resources[active_resource_need[loop]].expendable
                      THEN
                        BEGIN
                          (* we really do need to have some of this stuff *)
                          IF (amount_of_resource_in_top_level_of_tree(active_resource_need[loop],
                                                                      resource_tree^.child)
                             <(active_need_amount[loop]*time*resource_tree^.quantity))
                            THEN
                              temp_val:=false; (* Not enough, I'm afraid *)
                        END
                      ELSE
                        BEGIN
                          IF (amount_of_resource_in_top_level_of_tree(active_resource_need[loop],
                                                                      resource_tree^.child)
                            <(active_need_amount[loop]*resource_tree^.quantity))
                            THEN
                              temp_val:=false; (* too bad *)
                        END;
                  END;
            END;
        END;
      resource_tree:=resource_tree^.next;
    END;
  sufficient_active_resources:=temp_val;
END;

OVERLAY FUNCTION use_active_resources_up(resource_tree : resource_ptr;
                                 time          : integer):boolean;
VAR
  temp_val   : boolean;
  loop       : integer;
BEGIN
  temp_val:=true;
  WHILE resource_tree<>NIL DO
    BEGIN
      WITH resources[resource_tree^.resource_num] DO
        BEGIN
          FOR loop:=1 to 4 DO (* Step through all active resource needs *)
            BEGIN
              IF active_resource_need[loop]<>0
                THEN
                  BEGIN
                    IF resources[active_resource_need[loop]].expendable
                      THEN
                        BEGIN
                          (* we really do need to have some of this stuff *)
                          IF (amount_of_resource_in_top_level_of_tree(active_resource_need[loop],
                                                                      resource_tree^.child)
                             <(active_need_amount[loop]*time*resource_tree^.quantity))
                            THEN
                              BEGIN
                                temp_val:=false; (* Not enough, I'm afraid *)
                                use_some_resource_from_top_level_of_tree(active_resource_need[loop],
                                 amount_of_resource_in_top_level_of_tree(active_resource_need[loop],resource_tree^.child),
                                 resource_tree^.child);
                              END
                            ELSE
                              BEGIN
                                use_some_resource_from_top_level_of_tree(active_resource_need[loop],
                                                                       active_need_amount[loop]*time*resource_tree^.quantity,
                                                                       resource_tree^.child);
                              END;
                        END
                      ELSE
                        BEGIN
                          IF (amount_of_resource_in_top_level_of_tree(active_resource_need[loop],
                                                                      resource_tree^.child)
                             <(active_need_amount[loop]*resource_tree^.quantity))
                            THEN
                              BEGIN
                                temp_val:=false; (* Not enough, I'm afraid *)
                                use_some_resource_from_top_level_of_tree(active_resource_need[loop],
                                 amount_of_resource_in_top_level_of_tree(active_resource_need[loop],resource_tree^.child),
                                 resource_tree^.child);
                              END
                            ELSE
                              BEGIN
                                use_some_resource_from_top_level_of_tree(active_resource_need[loop],
                                                                       active_need_amount[loop]*resource_tree^.quantity,
                                                                       resource_tree^.child);
                              END;

                        END;
                  END;
            END;
        END;
      resource_tree:=resource_tree^.next;
    END;
  use_active_resources_up:=temp_val;
END;

{$I COMPPEND.PAS}  { Procedures needed to complete a pending item        }

(****************************************************************************)
(***                    OVERLAY FILE .003 ENDS HERE                       ***)
(****************************************************************************)

PROCEDURE handle_updating_transportation_pending_item(VAR item : pending_ptr);
BEGIN
  item^.distance:=item^.distance+item^.speed;
  WHILE (item^.transportation_list^.distance=0.0) DO
    BEGIN
      IF item^.transportation_list<>NIL
        THEN
          BEGIN
            item^.transportation_list:=item^.transportation_list^.next;
            IF item^.transportation_list^.prev<>NIL
              THEN
                dispose(item^.transportation_list^.prev);
          END;
    END;

  WHILE (item^.distance>=item^.transportation_list^.distance) DO
    BEGIN
      IF (mode=world_map) OR (mode=transportation_world_map)
        THEN
          BEGIN
            IF NOT human_resources_at(item^.transportation_list^.x,
                                      item^.transportation_list^.y)
              THEN
                BEGIN
                  IF land_at(item^.transportation_list^.x,item^.transportation_list^.y)
                    THEN
                      draw_on_world_map(item^.transportation_list^.x,
                                        item^.transportation_list^.y,
                                        wm_green)
                    ELSE
                      draw_on_world_map(item^.transportation_list^.x,
                                        item^.transportation_list^.y,
                                        wm_blue);
                END;
          END;

      item^.distance:=item^.distance-item^.transportation_list^.distance;

      IF item^.transportation_list^.next<>NIL
        THEN
          BEGIN
            item^.transportation_list:=item^.transportation_list^.next;
            dispose(item^.transportation_list^.prev);
            item^.transportation_list^.prev:=NIL;
          END;

      IF item^.transportation_list^.next=NIL
        THEN
          abort_pending_item(item)
        ELSE
          IF (mode=world_map) OR (mode=transportation_world_map)
            THEN
              draw_on_world_map(item^.transportation_list^.x,
                                item^.transportation_list^.y,
                                wm_red);
    END;
END;

PROCEDURE update_pending_list;
VAR
  temp_ptr : pending_ptr;
  save_ptr : pending_ptr;
  update_windows : boolean;
BEGIN
  temp_ptr:=world_pending_list_root;
  WHILE temp_ptr<>NIL DO
    BEGIN
      save_ptr:=temp_ptr^.next;
      temp_ptr^.updates_left:=pred(temp_ptr^.updates_left);
      IF (temp_ptr^.updates_left>0)
        THEN
          BEGIN
            IF (NOT use_active_resources_up(temp_ptr^.resources_involved,1))
            OR (NOT use_basic_resources_up(temp_ptr^.resources_involved,1))
              THEN
                BEGIN
                  IF (temp_ptr^.x=current_block_x) AND
                     (temp_ptr^.y=current_block_y)
                    THEN
                      BEGIN
                        reupdate_resource_window:=true;
                        reupdate_log_and_pending_windows:=true;
                      END;
                  abort_pending_item(temp_ptr);
                END
              ELSE
                BEGIN
                  IF temp_ptr^.action_type=transportation_action
                    THEN
                      handle_updating_transportation_pending_item(temp_ptr);
                END;
          END
        ELSE
          BEGIN
            IF (temp_ptr^.x=current_block_x) AND
               (temp_ptr^.y=current_block_y)
              THEN
                BEGIN
                  reupdate_resource_window:=true;
                  reupdate_log_and_pending_windows:=true;
                END;
            finish_pending_item(temp_ptr,100.0);
          END;
      temp_ptr:=save_ptr;
    END;
END;

PROCEDURE check_basic_resources;
VAR
  temp_ptr : human_resource_list_ptr;
BEGIN
  temp_ptr:=human_resource_list_root;
  WHILE temp_ptr<>NIL DO
    BEGIN
      IF (temp_ptr^.x=current_block_x) AND
         (temp_ptr^.y=current_block_y)
        THEN
          reupdate_resource_window:=true;
      IF NOT use_basic_resources_up(world_matrix[temp_ptr^.x]^[temp_ptr^.y]^.resources,1)
        THEN
          BEGIN
            IF (temp_ptr^.x=current_block_x) AND
               (temp_ptr^.y=current_block_y)
              THEN
                reupdate_log_and_pending_windows:=true;
            make_bad_noise;
          END;
      temp_ptr:=temp_ptr^.next;
    END;
END;

PROCEDURE harass_player;
BEGIN
END;

PROCEDURE flip_base_color;
BEGIN
  CASE mode OF
    world_map,transportation_world_map : BEGIN
                  IF (base_block_x>=0) AND (base_block_y>=0)
                    THEN
                      BEGIN
                        IF get_map_value(base_block_x,base_block_y)=wm_red
                          THEN
                            draw_on_world_map(base_block_x,base_block_y,wm_white)
                          ELSE
                            draw_on_world_map(base_block_x,base_block_y,wm_red);
                          END;
                END;
    zoom_map,transportation_zoom_map  : draw_base_block_on_zoom_map;
  END;
END;

PROCEDURE process_realtime_events;
VAR
  save_time : time_type;
BEGIN
  add_times(game_time,game_time_increment);
  IF (mode IN [world_map,transportation_world_map,zoom_map,transportation_zoom_map])
    THEN
      flip_base_color;

  subtract_times(time_to_next_update,game_time_increment);
  IF time_less_than_or_equal_to_zero(time_to_next_update)
    THEN
      BEGIN
        time_to_next_update:=world_update_increment;
        reupdate_resource_window:=false;
        reupdate_log_and_pending_windows:=false;
        update_pending_list;
        check_basic_resources;
        harass_player;
        IF ((mode=world_text) AND (world_text_mode IN [pending_list,log_list,world_inventory]))
          THEN
            BEGIN
              IF reupdate_resource_window
                THEN
                  update_world_inventory_window;
              IF reupdate_log_and_pending_windows
                THEN
                  BEGIN
                    update_world_pending_window;
                    update_world_log_window;
                  END;
            END;
        IF (mode=block_text)
          THEN
            BEGIN
              IF reupdate_resource_window
                THEN
                  update_resource_window;
              IF reupdate_log_and_pending_windows
                THEN
                  BEGIN
                    update_block_pending_window;
                    update_block_log_window;
                  END;
            END;
      END;
END;

(****************************************************************************)
(***                    OVERLAY FILE .004 STARTS HERE                     ***)
(****************************************************************************)

{$I WINDOWS.PAS }  { Resource, Pending and Log window procedures         }
{$I TRADPRCS.PAS}  { All of the trading procedures                       }
{$I GETWRLDN.PAS}  { Get a world name                                    }
{$I TEMPZONE.PAS}  { Procedures for making/drawing the temperate zone    }
{$I INITSRMT.PAS}  { Initialize the surface resource matrix              }
{$I RDRSRCFL.PAS}  { Read the resource file                              }
{$I INITWMAT.PAS}  { Initialize the world matrix to NIL                  }
{$I INITSGTI.PAS}  { Initialize smallest game time increment             }

(****************************************************************************)
(***                    OVERLAY FILE .004 ENDS HERE                       ***)
(****************************************************************************)

{$I HRPRESNT.PAS}  { Determine if human resources are present            }
{$I HRLLUPDA.PAS}  { Update the human resource list                      }


(****************************************************************************)
(***                    OVERLAY FILE .005 STARTS HERE                     ***)
(****************************************************************************)

{ And here goes another overlay }
{$I UPDABLPL.PAS}  { UPDAte BLock Pending and Log windows.               }
{$I UPDAWINV.PAS}  { Update the world inventory window                   }
{$I DSPFKHLP.PAS}  { Display Function Key Help Screen Procedure          }

(****************************************************************************)
(***                    OVERLAY FILE .005 ENDS HERE                       ***)
(****************************************************************************)

PROCEDURE update_block_pending_window;
BEGIN
  update_block_pending_window_overlay;
END;

PROCEDURE update_block_log_window;
BEGIN
  update_block_log_window_overlay;
END;

PROCEDURE update_world_pending_window;
BEGIN
  update_world_pending_window_overlay;
END;

PROCEDURE update_world_log_window;
BEGIN
  update_world_log_window_overlay;
END;

PROCEDURE update_world_inventory_window;
BEGIN
  update_world_inventory_window_overlay;
END;

{$I SURFRSRC.PAS}
{$I SETWRLDM.PAS}
{$I WRLDPRCS.PAS}
{$I ZOOMPRCS.PAS}

(******************************************************************************)

PROCEDURE update_block_text_windows;
BEGIN
  disable_resource_window_border;
  disable_block_pending_window_border;
  disable_block_log_window_border;

  IF block_text_mode=block_resource_window_mode
    THEN
      enable_resource_window_border
    ELSE
      enable_resource_window(world_matrix[current_block_x]^[current_block_y]^.resources);

  update_resource_window;

  IF block_text_mode=block_pending_window_mode
    THEN
      enable_block_pending_window_border
    ELSE
      enable_block_pending_window;

  display_pending_window_headers;
  update_block_pending_window;

  IF block_text_mode=block_log_window_mode
    THEN
      enable_block_log_window_border
    ELSE
      enable_block_log_window;

  display_log_window_headers;
  update_block_log_window;
END;

PROCEDURE display_block_text_screen;
BEGIN
  ClrScr;
  update_block_text_windows;

  TextColor(Block_text_general_info_color);
  gotoxy(1,2);
  writeln('Location: ',current_block_x:3,',',current_block_y:3);
  gotoxy(1,3);
  writeln('Altitude: ',altitude_of(current_block_x,current_block_y):5,' m');
  gotoxy(31,2);
  write  ('Latitude : '); write_latitude_for(current_block_y);
  gotoxy(31,3);
  write  ('Longitude: '); write_longitude_for(current_block_x);
  gotoxy(56,2);
  writeln('Temperature: ',temperature_from_climate(world_matrix[current_block_x]^[current_block_y]^.climate):2);
  gotoxy(56,3);
  writeln('Moisture   : ',moisture_from_climate(world_matrix[current_block_x]^[current_block_y]^.climate):2);

  IF (current_block_x=base_block_x) AND (current_block_y=base_block_y)
    THEN
      BEGIN
        TextColor(LightRed+Blink);
        gotoxy(22,2);
        writeln('*BASE*');
      END;
END;

{$I COMPTIME.PAS}  { Compress Time routines                              }

(****************************************************************************)
(***                    OVERLAY FILE .006 STARTS HERE                     ***)
(****************************************************************************)

{$I CHNGBASE.PAS}  { Procedure to change where the current base is       }
{$I HELPPRCS.PAS}  { All of the active routines of the Help Utility      }

OVERLAY PROCEDURE update_world_trade_screen;
VAR
  loop : integer;
BEGIN
  Color_window_border(min_trade_window_y,
                      max_trade_window_y,
                      window_selected_border_color);
  TextColor(Brown);
  gotoxy(18,min_trade_window_y);
  write('  RESOURCE TITLE  ');
  gotoxy(36,min_trade_window_y);
  write('OWNED     VALUE  AVAIL.       COST  ');

  TextColor(White);
  gotoxy(35,2);
  writeln('Trading Display');

  update_trade_financial_status;

  update_trade_window;
END;

OVERLAY PROCEDURE update_time_compression_screen;
BEGIN
  ClrScr;
  gotoxy(33,3);
  TextColor(Time_speed_control_color);
  writeln('Time Speed Control');
  gotoxy(1,5);
  writeln('Minimum Time Increment');
  display_time_vertically(3,7,smallest_game_time_increment);
  gotoxy(57,5);
  writeln('Maximum Time Increment');
  display_time_vertically(59,7,world_update_increment);
  gotoxy(31,5);
  writeln('Current Time Increment');
  TextColor(Time_speed_control_color);
  display_time_vertically(33,7,game_time_increment);
END;

OVERLAY PROCEDURE draw_resource_window_mode_header_overlay;
BEGIN
  gotoxy(20,min_resource_window_y-1);
  TextColor(resource_window_mode_header_color);
  write('  ');
  CASE resource_window_mode OF
    no_resource_window_mode                : write('Resources Present in Block');
    general_editing                        : write('General Editing Mode');
    exploration_equipment_selection        : write('Select equipment to explore with');
    extraction_mineral_selection           : write('Select minerals you wish to extract');
    extraction_equipment_selection         : write('Select equipment to extract minerals with');
    development_object_selection           : write('Select surface resources to develop');
    development_equipment_selection        : write('Select equipment to develop surface with');
    refinement_object_selection            : write('Select unpure substances to refine');
    refinement_equipment_selection         : write('Select equipment to refine with');
    transportation_equipment_selection     : write('Select main objects of transportation');
    production_object_selection            : write('Select type of object to produce');
  END;
  write('  ');
END;

(****************************************************************************)
(***                    OVERLAY FILE .006 ENDS HERE                       ***)
(****************************************************************************)

PROCEDURE draw_resource_window_mode_header;
BEGIN
  draw_resource_window_mode_header_overlay;
END;

FUNCTION get_selection_tree(VAR tree_root : resource_ptr):resource_ptr;
VAR
  temp_ptr : resource_ptr;
BEGIN
  activate_resource_window(tree_root);
  edit_resource_window(tree_root);
  temp_ptr:=make_selection_tree_from(tree_root);
  unselect_tree(temp_ptr);
  get_selection_tree:=temp_ptr;
  resource_window_mode:=no_resource_window_mode;
  deactivate_resource_window;
END;

PROCEDURE draw_transportation_zoom_map_info;
BEGIN
  gotoxy(3,21); writeln('   START          : ',
                        current_transportation_pending^.x:3,',',
                        current_transportation_pending^.y:3,'         ');
  gotoxy(3,22); writeln('   DISTANCE       : ',
                        current_transportation_pending^.distance:6:0,' km       ');
  gotoxy(3,23); writeln('                  : ',
                        current_transportation_blocks:4,' blocks     ');
  gotoxy(3,24); writeln('   TIME           : ',
                        trunc(current_transportation_pending^.distance/current_transportation_pending^.speed)/3:7:2,
                        ' days    ');
END;

PROCEDURE init_world_trade_screen;
BEGIN
  enable_trade_window;
END;

PROCEDURE display_world_text;
BEGIN
  ClrScr;
  IF world_text_mode IN [pending_list,log_list,world_inventory]
    THEN
      BEGIN
        TextColor(White);
        gotoxy(25,2);
        write('WORLD-WIDE SUMMARY OF INFORMATION');
        deactivate_world_inventory_window;
        draw_world_inventory_window_headers;
        deactivate_world_pending_window;
        display_pending_window_headers;
        deactivate_world_log_window;
        display_log_window_headers;

        IF world_text_mode=world_inventory
          THEN
            enable_world_inventory_window_border
          ELSE
            enable_world_inventory_window;

        update_world_inventory_window;

        IF world_text_mode=pending_list
          THEN
            enable_world_pending_window_border
          ELSE
            enable_world_pending_window;

        update_world_pending_window;

        IF world_text_mode=log_list
          THEN
            enable_world_log_window_border
          ELSE
            enable_world_log_window;

        update_world_log_window;
      END
    ELSE
      BEGIN
        CASE world_text_mode OF
          trade_mode         : update_world_trade_screen;
          compress_time_mode : update_time_compression_screen;
        END;
      END;
END;

PROCEDURE refresh_screen;
BEGIN
  CASE mode OF
    world_map    : display_world_map;
    transportation_world_map : BEGIN
                                 display_world_map;
                                 gotoxy(10,5);
                                 writeln('  TRANSPORTATION MODE   ');
                               END;
    world_text   : display_world_text;
    zoom_map     : display_zoom_map;
    transportation_zoom_map   : BEGIN
                                 display_zoom_map;
                                 gotoxy(9,20);
                                 writeln('  TRANSPORTATION MODE   ');
                                 draw_transportation_zoom_map_info;
                               END;
    block_text   : display_block_text_screen;
  END;
END;

(****************************************************************************)
(***                    OVERLAY FILE .007 STARTS HERE                     ***)
(****************************************************************************)

{$I TRANSPRT.PAS}  { Routines to initiate a transportation action        }
{$I TRADE.PAS   }  { Main routine to call other trade routines           }
{$I EXPLORE.PAS }  { Routines to initiate an exploration action          }
{$I EXTRACT.PAS }  { Routines to initiate an extraction action           }
{$I DEVELOP.PAS }  { Routines to initiate a development action           }
{$I REFINE.PAS  }  { Routines to initiate a refinement action            }
{$I PRODUCE.PAS }  { Routines to initiate a production action            }
{$I VERIQUIT.PAS}  { Verify whether they really, really want to quit     }
{$I INITALL.PAS }  { Procedure that calls all of the initialization stuff}
{$I LOADWRLD.PAS}  { Load in a world from disk                           }
{$I SAVEWRLD.PAS}  { Save the world in memory to disk                    }

(****************************************************************************)
(***                    OVERLAY FILE .007 ENDS HERE                       ***)
(****************************************************************************)

PROCEDURE display_help_screen;
BEGIN
  display_help_screen_overlay(screen_name);
END;

PROCEDURE display_function_key_help_screen;
BEGIN
  display_function_key_help_screen_overlay(key);
END;

FUNCTION create_a_new_transportation_list_item;
BEGIN
  create_a_new_transportation_list_item:=
    create_a_new_transportation_list_item_overlay;
END;

PROCEDURE trader_arrives;
BEGIN
  trader_arrives_overlay;
END;

PROCEDURE trader_departs;
BEGIN
  trader_departs_overlay;
END;

PROCEDURE finish_pending_item; {( item        : pending_ptr;
                                  amount_done : real); }
VAR
  save_x,save_y : integer;
BEGIN
  save_x:=item^.x;
  save_y:=item^.y;
  CASE item^.action_type OF
    exploration_action     : finish_exploration_pending_item(item,amount_done);
    extraction_action      : finish_extraction_pending_item(item,amount_done);
    development_action     : finish_development_pending_item(item,amount_done);
    refinement_action      : finish_refinement_pending_item(item,amount_done);
    production_action      : finish_production_pending_item(item,amount_done);
    transportation_action  : finish_transportation_pending_item(item,amount_done);
    trader_arriving_action : finish_trader_arriving_pending_item(item);
    trader_leaving_action  : finish_trader_leaving_pending_item(item);
  END;
  update_human_resource_list(save_x,save_y);
  pending_item_completed_noise;
END;

{$I MOVEPRCS.PAS}  { Procedures to move the cursurs around, etc.         }
(****************************************************************************)
(***                    OVERLAY FILE .008 STARTS HERE                     ***)
(****************************************************************************)

{$I KEYPRCS.PAS }  { Procedures to deal with all of the keys             }

(****************************************************************************)
(***                    OVERLAY FILE .008 ENDS HERE                       ***)
(****************************************************************************)

BEGIN
  ASSIGN(param_file,'PARMS.DAT');
  reset(param_file);
  read(param_file,overlay_drive);
  close(param_file);
  OvrPath(overlay_drive); (* rem use ramdisk - yeah! *)
  initialize_the_place;
  load_world;

  IF game_time.year<>0 (* did we load in a file ? *)
    THEN
      BEGIN
        mode:=world_map;
        refresh_screen;

        REPEAT
          key:=get_key_with_clock(fkey);

          CASE mode OF
            world_map                : handle_world_map_keys(key,fkey);
            transportation_world_map : handle_transportation_world_map_keys(key,fkey);
            zoom_map                 : handle_zoom_map_keys(key,fkey);
            transportation_zoom_map  : handle_transportation_zoom_map_keys(key,fkey);
            block_text               : handle_text_screen_keys(key,fkey);
          END;
        UNTIL Quit;
      END;
  ASSIGN(main_program,'STARFALL.COM');
  Execute(main_program);
END.