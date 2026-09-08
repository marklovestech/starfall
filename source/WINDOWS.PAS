{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : WINDOWS.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : In this file are all of the routines to work on the  ***)
(***                 resource window, block pending window, block log     ***)
(***                 window, world pending window, world log window, and  ***)
(***                 and world inventory window.                          ***)
(*** Input         : Generally none.                                      ***)
(*** Output        : Generally none.                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE edit_resource_window(VAR tree_root : resource_ptr);
VAR
  no_items_selected_yet : boolean;

  PROCEDURE move_resource_item_up_one;
  BEGIN
    decr_window_ptr(current_resource_window_item,
                    current_resource_window_ptr,
                    current_resource_window_line);
    Update_resource_window;
  END;

  PROCEDURE move_resource_item_down_one;
  BEGIN
    incr_window_ptr(current_resource_window_item,
                    current_resource_window_ptr,
                    current_resource_window_line,
                    min_resource_window_y,
                    max_resource_window_y);
    Update_resource_window;
  END;

  PROCEDURE get_development_resource_bounds(VAR min_val : integer;
                                            VAR max_val : integer;
                                            tree        : resource_ptr);
  VAR
    temp_ptr : resource_ptr;
  BEGIN
    (* Note: because of the constraints of the rules, we only have to check *)
    (* the top level items of a tree.  This is a great boon, for it allows  *)
    (* the use of an iterative rather than a recursive algorithm - there are *)
    (* too many of those in this code already.                               *)

     min_val:=0;
     max_val:=max_resource;

     temp_ptr:=tree;
     WHILE temp_ptr<>NIL DO
       BEGIN
         IF value_of_resource_flag_selected(temp_ptr^.flags)=true
           THEN
             BEGIN
               min_val:=int_max(min_val,resources[temp_ptr^.resource_num].start_resource_needed_to_develop);
               IF resources[temp_ptr^.resource_num].end_resource_needed_to_develop<>0
                 THEN
                   max_val:=int_min(max_val,resources[temp_ptr^.resource_num].end_resource_needed_to_develop);
             END;
         temp_ptr:=temp_ptr^.next;
       END;
  END;

  PROCEDURE get_refinement_resource_bounds(VAR min_val : integer;
                                           VAR max_val : integer;
                                           tree        : resource_ptr);
  VAR
    temp_ptr : resource_ptr;
  BEGIN
     min_val:=0;
     max_val:=max_resource;

     temp_ptr:=tree;
     WHILE temp_ptr<>NIL DO
       BEGIN
         IF value_of_resource_flag_selected(temp_ptr^.flags)=true
           THEN
             BEGIN
               min_val:=int_max(min_val,resources[temp_ptr^.resource_num].start_resource_needed_to_refine);
               IF resources[temp_ptr^.resource_num].end_resource_needed_to_refine<>0
                 THEN
                   max_val:=int_min(max_val,resources[temp_ptr^.resource_num].end_resource_needed_to_refine);
             END;
         temp_ptr:=temp_ptr^.next;
       END;
  END;

  FUNCTION top_level_unrelated_resource(test_resource : resource_ptr):boolean;
  BEGIN
    IF (test_resource^.child=NIL) AND
       (level_of_resource(test_resource)=1)
      THEN
        top_level_unrelated_resource:=true
      ELSE
        top_level_unrelated_resource:=false;
  END;

  FUNCTION top_level_resource(test_resource : resource_ptr):boolean;
  BEGIN
    IF level_of_resource(test_resource)=1
      THEN
        top_level_resource:=true
      ELSE
        top_level_resource:=false;
  END;

  FUNCTION selection_ok(current_item:resource_ptr):boolean;
  VAR
    temp_val : boolean;

  OVERLAY FUNCTION exploration_equipment_selection_ok:boolean;
  VAR
    temp_val  : boolean;
  BEGIN
    temp_val:=resources[current_item^.resource_num].usable_for_exploration;
    IF NOT temp_val
      THEN
        display_block_text_message('Item not usable for exploration.');
    exploration_equipment_selection_ok:=temp_val;
  END;

  OVERLAY FUNCTION extraction_mineral_selection_ok:boolean;
  VAR
    temp_val  : boolean;
  BEGIN
    temp_val:=false;
    IF top_level_unrelated_resource(current_item)
      THEN
        temp_val:=resources[current_item^.resource_num].extractable
      ELSE
        display_block_text_message('Not a top-level, simple item.');
    extraction_mineral_selection_ok:=temp_val;
  END;

  OVERLAY FUNCTION extraction_equipment_selection_ok:boolean;
  VAR
    temp_val  : boolean;
  BEGIN
    temp_val:=resources[current_item^.resource_num].usable_for_extraction;
    IF NOT temp_val
      THEN
        display_block_text_message('Item not usable for extraction.');
    extraction_equipment_selection_ok:=temp_val;
  END;

  OVERLAY FUNCTION development_object_selection_ok:boolean;
  VAR
    temp_val  : boolean;
  BEGIN
    temp_val:=false;
    IF (top_level_unrelated_resource(current_item))
      THEN
        IF (resources[current_item^.resource_num].developable)
          THEN
            IF (resources[current_item^.resource_num].start_resource_needed_to_develop>=min_allowable_resource)
               AND (resources[current_item^.resource_num].end_resource_needed_to_develop<=max_allowable_resource)
              THEN
                temp_val:=true
              ELSE
                display_block_text_message('Not compatible with other resources already selected.')
          ELSE
            display_block_text_message('Item is not developable.')
      ELSE
        display_block_text_message('Item is not a top-level, simple item.');
    development_object_selection_ok:=temp_val;
  END;

  OVERLAY FUNCTION development_equipment_selection_ok:boolean;
  VAR
    temp_val  : boolean;
  BEGIN
    temp_val:=false;
    IF (resources[current_item^.resource_num].usable_for_development)
      THEN
        IF (current_item^.resource_num>=min_allowable_resource) AND
           (current_item^.resource_num<=max_allowable_resource)
          THEN
            temp_val:=true
          ELSE
            display_block_text_message('Item is not compatible with previous selections.')
      ELSE
        display_block_text_message('Item is not usable for development.');
    development_equipment_selection_ok:=temp_val;
  END;

  OVERLAY FUNCTION refinement_object_selection_ok:boolean;
  VAR
    temp_val:boolean;
  BEGIN
    temp_val:=false;
    IF (top_level_unrelated_resource(current_item))
      THEN
        IF (resources[current_item^.resource_num].refineable)
          THEN
            IF (resources[current_item^.resource_num].start_resource_needed_to_refine>=min_allowable_resource)
               AND (resources[current_item^.resource_num].end_resource_needed_to_refine<=max_allowable_resource)
              THEN
                temp_val:=true
              ELSE
                display_block_text_message('Item is not compatible with previous selections.')
          ELSE
            display_block_text_message('Item is not refinable.')
      ELSE
        display_block_text_message('Item is not top-level and simple.');
    refinement_object_selection_ok:=temp_val;
  END;

  OVERLAY FUNCTION refinement_equipment_selection_ok:boolean;
  VAR
    temp_val  : boolean;
  BEGIN
    temp_val:=false;
    IF (resources[current_item^.resource_num].usable_for_refinement)
      THEN
        IF (current_item^.resource_num>=min_allowable_resource) AND
           (current_item^.resource_num<=max_allowable_resource)
          THEN
            temp_val:=true
          ELSE
            display_block_text_message('Item is not compatible with previous selections.')
      ELSE
        display_block_text_message('Item is not usable for refinement.');
    refinement_equipment_selection_ok:=temp_val;
  END;

  OVERLAY FUNCTION transportation_equipment_selection_ok:boolean;
  VAR
    temp_val  : boolean;
  BEGIN
    temp_val:=false;
    IF (resources[current_item^.resource_num].usable_for_transportation)
      THEN
        IF (amount_of_weight_in_tree(current_item)<=
           (resources[current_item^.resource_num].cargo_capacity*
           current_item^.quantity))
          THEN
            IF (movable_tree(current_item))
              THEN
                WITH resources[current_item^.resource_num] DO
                  BEGIN
                    CASE current_transportation_mode OF
                      air    : BEGIN
                                 IF air_speed>0.0
                                   THEN
                                     temp_val:=true
                                   ELSE
                                     display_block_text_message('Item not usable for air transportation.');
                               END;
                      land   : BEGIN
                                 IF land_speed>0.0
                                   THEN
                                     temp_val:=true
                                   ELSE
                                     display_block_text_message('Item not usable for land transportation.');
                               END;
                      water  : BEGIN
                                 IF water_speed>0.0
                                   THEN
                                     temp_val:=true
                                   ELSE
                                     display_block_text_message('Item not usable for water transportation.');
                               END;
                    END;
                  END
              ELSE
                display_block_text_message('One or more items in this tree is not movable.')
          ELSE
            BEGIN
              display_block_text_message('Item overloaded with cargo: Limit =');
              write(resources[current_item^.resource_num].cargo_capacity*current_item^.quantity:10:0);
            END
      ELSE
        display_block_text_message('Item not usable for transportation.');
    transportation_equipment_selection_ok:=temp_val;
  END;

  OVERLAY FUNCTION production_object_selection_ok:boolean;
  VAR
    temp_val  : boolean;
  BEGIN
    temp_val:=false;
    IF (top_level_unrelated_resource(current_item))
      THEN
        IF (no_items_selected_yet)
          THEN
            temp_val:=resources[current_item^.resource_num].produceable
          ELSE
            display_block_text_message('One type of item has already been selected for production.')
      ELSE
        display_block_text_message('Item is not top-level and simple.');
    production_object_selection_ok:=temp_val;
  END;

  BEGIN
    temp_val:=false;
    IF top_level_resource(current_item)
      THEN
        BEGIN
          CASE resource_window_mode OF
            general_editing                    : display_block_text_message('No selections allowed in General Editing.');
            exploration_equipment_selection    : temp_val:=exploration_equipment_selection_ok;
            extraction_mineral_selection       : temp_val:=extraction_mineral_selection_ok;
            extraction_equipment_selection     : temp_val:=extraction_equipment_selection_ok;
            development_object_selection       : temp_val:=development_object_selection_ok;
            development_equipment_selection    : temp_val:=development_equipment_selection_ok;
            refinement_object_selection        : temp_val:=refinement_object_selection_ok;
            refinement_equipment_selection     : temp_val:=refinement_equipment_selection_ok;
            transportation_equipment_selection : temp_val:=transportation_equipment_selection_ok;
            production_object_selection        : temp_val:=production_object_selection_ok;
          END;
        END
      ELSE
        display_block_text_message('Only top-level items can ever be selected.');
    selection_ok:=temp_val;
    IF temp_val=true
      THEN
        no_items_selected_yet:=false;
  END;

  PROCEDURE refigure_allowable_resources;
  BEGIN
    CASE resource_window_mode OF
      development_object_selection : get_development_resource_bounds(
                                       min_allowable_resource,
                                       max_allowable_resource,
                                       tree_root);
      refinement_object_selection  : get_refinement_resource_bounds(
                                       min_allowable_resource,
                                       max_allowable_resource,
                                       tree_root);
    END;
  END;

  PROCEDURE select_current_item;
  BEGIN
    IF selection_ok(current_resource_window_item)
      THEN
        BEGIN
          clear_block_text_prompt_line;
          select_tree_plus_root(current_resource_window_item);
          refigure_allowable_resources;
          Update_resource_window;
        END
      ELSE
        beep;
  END;

  PROCEDURE unselect_current_item;
  BEGIN
    no_items_selected_yet:=true;
    clear_block_text_prompt_line;
    unselect_tree_plus_root(current_resource_window_item);
    refigure_allowable_resources;
    Update_resource_window;
  END;

  PROCEDURE move_to_top_of_resource_list;
  BEGIN
    (* This code is the same as 'Enable_resource_window', farther down *)
    current_resource_window_ptr:=tree_root;
    current_resource_window_line:=-1;
    current_resource_window_item:=current_resource_window_ptr;

    Update_resource_window;
  END;

  PROCEDURE move_to_bottom_of_resource_list;
  VAR
    save_ptr : resource_ptr;
  BEGIN
    REPEAT
      save_ptr:=current_resource_window_item;
      step_resource_ptr(current_resource_window_item);
      current_resource_window_line:=succ(current_resource_window_line);
      IF current_resource_window_line>(max_resource_window_y-min_resource_window_y)
        THEN
          BEGIN
            step_resource_ptr(current_resource_window_ptr);
            current_resource_window_line:=max_resource_window_y-min_resource_window_y;
          END;
    UNTIL save_ptr=current_resource_window_item;
    update_resource_window;
  END;

  PROCEDURE move_one_page_down_in_resource_list;
  VAR
    save_ptr : resource_ptr;
    count    : integer;
  BEGIN
    count:=0;
    REPEAT
      save_ptr:=current_resource_window_item;
      step_resource_ptr(current_resource_window_item);
      current_resource_window_line:=succ(current_resource_window_line);
      IF current_resource_window_line>(max_resource_window_y-min_resource_window_y)
        THEN
          BEGIN
            step_resource_ptr(current_resource_window_ptr);
            current_resource_window_line:=max_resource_window_y-min_resource_window_y;
          END;
      count:=succ(count);
    UNTIL (save_ptr=current_resource_window_item) OR
          (count>=(max_resource_window_y-min_resource_window_y));
    update_resource_window;
  END;

  PROCEDURE move_one_page_up_in_resource_list;
  VAR
    save_ptr : resource_ptr;
    count    : integer;
  BEGIN
    count:=0;
    REPEAT
      save_ptr:=current_resource_window_item;
      unstep_resource_ptr(current_resource_window_item);
      current_resource_window_line:=pred(current_resource_window_line);
      IF current_resource_window_line<1
        THEN
          BEGIN
            unstep_resource_ptr(current_resource_window_ptr);
            current_resource_window_line:=1;
          END;
      count:=succ(count);
    UNTIL (save_ptr=current_resource_window_item) OR
          (count>=(max_resource_window_y-min_resource_window_y));
    update_resource_window;
  END;

  PROCEDURE group_current_item_in_one_level;
  BEGIN
    IF current_resource_window_item  (* you cannot do this at the top item *)
       <> tree_root
      THEN
        IF current_resource_window_item^.prev<>NIL (* must have a previous item *)
          THEN
            BEGIN
              demote_sibling_to_child(current_resource_window_item^.prev,
                                      current_resource_window_item);
              update_resource_window;
            END
          ELSE
            beep
      ELSE
        beep;
  END;

  PROCEDURE ungroup_current_item_out_one_level;
  BEGIN
    IF current_resource_window_item  (* you cannot do this at the top item *)
       <> tree_root
      THEN
        IF current_resource_window_item^.parent<>NIL (* must have a parent item *)
          THEN
            BEGIN
              advance_child_to_sibling(current_resource_window_item^.parent,
                                       current_resource_window_item);
              update_resource_window;
              WHILE current_resource_window_line=-1 DO
                BEGIN
                  step_resource_ptr(current_resource_window_ptr);
                  update_resource_window;
                END;
            END
          ELSE
            beep
      ELSE
        beep;
  END;

  PROCEDURE break_up_multiple_items;
  VAR
    amount : real;
  BEGIN
    IF current_resource_window_item^.quantity>1.0
      THEN
        BEGIN
          TextColor(Yellow);
          REPEAT
            amount:=1.0;
            clear_block_text_prompt_line;
            gotoxy(1,block_text_prompt_line);
            write('Decompose how many [1.0] ?');
            get_real(amount);
            IF amount<>int(amount)
              THEN
                valid:=false;
          UNTIL (amount>=0.0) AND
                (amount<=current_resource_window_item^.quantity) AND
                (valid);

          clear_block_text_prompt_line;

          IF amount<>0
            THEN
              BEGIN
                decompose_resource(current_resource_window_item,amount);
                Update_resource_window;
              END;
        END
      ELSE
        beep;
  END;

  PROCEDURE put_items_together;
  VAR
    beep_flag : boolean;
    save_ptr  : resource_ptr;
  BEGIN
    beep_flag:=true;
    IF current_resource_window_item^.next<>NIL
      THEN
        BEGIN
          IF current_resource_window_item^.next^.child=NIL
            THEN
              BEGIN
                save_ptr:=current_resource_window_item^.next;
                compress_resources(current_resource_window_item,
                                   current_resource_window_item^.next);
                IF save_ptr<>current_resource_window_item^.next (* did anything change?*)
                  THEN
                    BEGIN
                      IF current_resource_window_ptr=save_ptr (* did we trash the window ptr? *)
                        THEN
                          current_resource_window_ptr:=current_resource_window_item;
                      beep_flag:=false;
                    END;
              END;
        END;

    IF current_resource_window_item^.prev<>NIL
      THEN
        BEGIN
          IF current_resource_window_item^.prev^.child=NIL
            THEN
              BEGIN
                save_ptr:=current_resource_window_item^.prev;
                compress_resources(current_resource_window_item,
                                   current_resource_window_item^.prev);
                IF save_ptr<>current_resource_window_item^.prev (* did anything change? *)
                  THEN
                    BEGIN
                      IF current_resource_window_ptr=save_ptr (* did we trash the poor thing *)
                        THEN
                          current_resource_window_ptr:=current_resource_window_item;
                      beep_flag:=false;
                    END;
              END;
        END;

    IF beep_flag
      THEN
        beep
      ELSE
        update_resource_window;
  END;

  PROCEDURE swap_current_with_item_below;
  BEGIN
    IF current_resource_window_item^.next<>NIL
      THEN
        BEGIN
          IF current_resource_window_ptr=current_resource_window_item
            THEN
              current_resource_window_ptr:=current_resource_window_item^.next;

          IF current_resource_window_item=tree_root
            THEN
              tree_root:=
                current_resource_window_item^.next;

          swap_resources(current_resource_window_item,
                         current_resource_window_item^.next);
          update_resource_window;
          WHILE current_resource_window_line=-1 DO
            BEGIN
              step_resource_ptr(current_resource_window_ptr);
              update_resource_window;
            END;
        END
      ELSE
        beep;
  END;

  PROCEDURE swap_current_with_item_above;
  BEGIN
    IF current_resource_window_item^.prev<>NIL
      THEN
        BEGIN
          IF current_resource_window_ptr=current_resource_window_item^.prev
            THEN
              current_resource_window_ptr:=current_resource_window_item
            ELSE
              IF current_resource_window_ptr=current_resource_window_item
                THEN
                  decr_window_ptr(current_resource_window_ptr,
                                  current_resource_window_ptr,
                                  current_resource_window_line);
          IF current_resource_window_item^.prev=tree_root
            THEN
              tree_root:=
                current_resource_window_item;

          swap_resources(current_resource_window_item^.prev,
          current_resource_window_item);
          update_resource_window;
          WHILE current_resource_window_line=-1 DO
            BEGIN
              unstep_resource_ptr(current_resource_window_ptr);
              update_resource_window;
            END;
        END
      ELSE
        beep;
  END;

BEGIN
  no_items_selected_yet:=true;
  unselect_tree_plus_root(tree_root);
  refigure_allowable_resources;
  REPEAT
    key:=get_key_with_clock(fkey);
    IF fkey
      THEN
        CASE key OF
          Uarr   : move_resource_item_up_one;
          Darr   : move_resource_item_down_one;
          Rarr   : select_current_item;
          Larr   : unselect_current_item;
          Home   : move_to_top_of_resource_list;
          Endkey : move_to_bottom_of_resource_list;
          Inskey : Break_up_multiple_items;
          Delkey : Put_items_together;
          PgUp   : move_one_page_up_in_resource_list;
          PgDn   : move_one_page_down_in_resource_list;
     SHF1..SHF10 : display_function_key_help_screen(key);
          else   bad_key;
        END
      ELSE
        CASE key OF
          SHRarr : group_current_item_in_one_level;
          SHLarr : ungroup_current_item_out_one_level;
          return : ;
          '+'    : swap_current_with_item_below;
          '-'    : swap_current_with_item_above;
          escape : display_help_screen('Resource Window Commands');
          'R'    : display_help_screen('Resource Window Help Screen');
          'h','H': display_help_screen('General Help Screen');
          else   bad_key;
        END;
  UNTIL (NOT fkey) AND (key=return);
END;

OVERLAY PROCEDURE edit_block_pending_window;

  FUNCTION cursor_on_window:boolean;
  VAR
    temp_val : boolean;
    loop     : integer;
    temp_ptr : pending_ptr;
  BEGIN
    temp_val:=false;
    temp_ptr:=current_pending_window_ptr;
    FOR loop:=1 to (max_block_pending_window_y-min_block_pending_window_y) DO
      BEGIN
        IF current_pending_window_item=temp_ptr
          THEN
            temp_val:=true;
        temp_ptr:=next_pending_for_block(temp_ptr);
      END;
    cursor_on_window:=temp_val;
  END;

  PROCEDURE block_pending_up_arrow;
  BEGIN
    IF current_pending_window_item=current_pending_window_ptr
      THEN
        BEGIN
          current_pending_window_item:=prev_pending_for_block(current_pending_window_item);
          current_pending_window_ptr:=current_pending_window_item;
        END
      ELSE
        BEGIN
          current_pending_window_item:=prev_pending_for_block(current_pending_window_item);
        END;
    update_block_pending_window;
  END;

  PROCEDURE block_pending_down_arrow;
  BEGIN
    current_pending_window_item:=next_pending_for_block(current_pending_window_item);
    IF (NOT cursor_on_window)
      THEN
        current_pending_window_ptr:=next_pending_for_block(current_pending_window_ptr);
    update_block_pending_window;
  END;

  PROCEDURE block_pending_first;
  BEGIN
    current_pending_window_ptr:=first_pending_for_block(current_block_x,current_block_y);
    current_pending_window_item:=current_pending_window_ptr;
    update_block_pending_window;
  END;

  PROCEDURE block_pending_last;
  VAR
    save_ptr : pending_ptr;
  BEGIN
    REPEAT
      save_ptr:=current_pending_window_item;
      current_pending_window_item:=next_pending_for_block(current_pending_window_item);
      IF (NOT cursor_on_window)
        THEN
          current_pending_window_ptr:=next_pending_for_block(current_pending_window_ptr);
    UNTIL save_ptr=current_pending_window_item;
    update_block_pending_window;
  END;

  PROCEDURE block_pending_page_up;
  VAR
    loop : integer;
  BEGIN
    FOR loop:=1 to (max_block_pending_window_y-min_block_pending_window_y) DO
      block_pending_up_arrow;
  END;

  PROCEDURE block_pending_page_down;
  VAR
    loop : integer;
  BEGIN
    FOR loop:=1 to (max_block_pending_window_y-min_block_pending_window_y) DO
      block_pending_down_arrow;
  END;

  PROCEDURE delete_block_pending_item;
  VAR
    save_ptr : pending_ptr;
  BEGIN
    IF current_pending_window_item<>NIL
      THEN
        BEGIN
          save_ptr:=current_pending_window_item;
          block_pending_down_arrow;
          IF save_ptr=current_pending_window_item
            THEN
              block_pending_up_arrow;
          IF save_ptr=current_pending_window_item
            THEN
              BEGIN
                current_pending_window_item:=NIL;
                current_pending_window_ptr:=NIL;
              END;
          abort_pending_item(save_ptr);
          update_block_pending_window;
        END
      ELSE
        beep;
  END;

BEGIN
  TextColor(Block_mode_explanation_color);
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  writeln('PENDING LIST  ');
  activate_block_pending_window;
  REPEAT
    key:=get_key_with_clock(fkey);
    IF fkey
      THEN
        CASE key OF
          Uarr    : block_pending_up_arrow;
          Darr    : block_pending_down_arrow;
          Home    : block_pending_first;
          EndKey  : block_pending_last;
          PgUp    : block_pending_page_up;
          PgDn    : block_pending_page_down;
      SHF1..SHF10 : display_function_key_help_screen(key);
          else    bad_key;
        END
      ELSE
        CASE key OF
          SHRarr : delete_block_pending_item;
          return : ;
          escape : display_function_key_help_screen(SHF9);
          'h','H': display_help_screen('General Help Screen');
          else   bad_key;
        END;
  UNTIL (NOT fkey) AND (key=return);
  block_pending_first;
  update_block_pending_window;
  deactivate_block_pending_window;
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  write('             ');
END;

OVERLAY PROCEDURE edit_block_log_window;

  FUNCTION cursor_on_window:boolean;
  VAR
    temp_val : boolean;
    loop     : integer;
    temp_ptr : log_ptr;
  BEGIN
    temp_val:=false;
    temp_ptr:=current_log_window_ptr;
    FOR loop:=1 to (max_block_log_window_y-min_block_log_window_y) DO
      BEGIN
        IF current_log_window_item=temp_ptr
          THEN
            temp_val:=true;
        temp_ptr:=next_log_for_block(temp_ptr);
      END;
    cursor_on_window:=temp_val;
  END;

  PROCEDURE block_log_up_arrow;
  BEGIN
    IF current_log_window_item=current_log_window_ptr
      THEN
        BEGIN
          current_log_window_item:=prev_log_for_block(current_log_window_item);
          current_log_window_ptr:=current_log_window_item;
        END
      ELSE
        BEGIN
          current_log_window_item:=prev_log_for_block(current_log_window_item);
        END;
    update_block_log_window;
  END;

  PROCEDURE block_log_down_arrow;
  BEGIN
    current_log_window_item:=next_log_for_block(current_log_window_item);
    IF (NOT cursor_on_window)
      THEN
        current_log_window_ptr:=next_log_for_block(current_log_window_ptr);
    update_block_log_window;
  END;

  PROCEDURE block_log_first;
  BEGIN
    current_log_window_ptr:=first_log_for_block(current_block_x,current_block_y);
    current_log_window_item:=current_log_window_ptr;
    update_block_log_window;
  END;

  PROCEDURE block_log_last;
  VAR
    save_ptr : log_ptr;
  BEGIN
    REPEAT
      save_ptr:=current_log_window_item;
      current_log_window_item:=next_log_for_block(current_log_window_item);
      IF (NOT cursor_on_window)
        THEN
          current_log_window_ptr:=next_log_for_block(current_log_window_ptr);
    UNTIL save_ptr=current_log_window_item;
    update_block_log_window;
  END;

  PROCEDURE block_log_page_up;
  VAR
    loop : integer;
  BEGIN
    FOR loop:=1 to (max_block_log_window_y-min_block_log_window_y) DO
      block_log_up_arrow;
  END;

  PROCEDURE block_log_page_down;
  VAR
    loop : integer;
  BEGIN
    FOR loop:=1 to (max_block_log_window_y-min_block_log_window_y) DO
      block_log_down_arrow;
  END;

  PROCEDURE delete_block_log_item;
  VAR
    save_ptr : log_ptr;
  BEGIN
    IF current_log_window_item<>NIL
      THEN
        BEGIN
          save_ptr:=current_log_window_item;
          block_log_down_arrow;
          IF save_ptr=current_log_window_item
            THEN
              block_log_up_arrow;
          IF save_ptr=current_log_window_item
            THEN
              BEGIN
                current_log_window_item:=NIL;
                current_log_window_ptr:=NIL;
              END;
          delete_from_log_list(save_ptr);
          update_block_log_window;
        END
      ELSE
        beep;
  END;

BEGIN
  TextColor(Block_mode_explanation_color);
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  writeln('LOG LIST      ');
  activate_block_log_window;
  REPEAT
    key:=get_key_with_clock(fkey);
    IF fkey
      THEN
        CASE key OF
          Uarr    : block_log_up_arrow;
          Darr    : block_log_down_arrow;
          Home    : block_log_first;
          EndKey  : block_log_last;
          PgUp    : block_log_page_up;
          PgDn    : block_log_page_down;
      SHF1..SHF10 : display_function_key_help_screen(key);
          else    bad_key;
        END
      ELSE
        CASE key OF
          SHRarr : delete_block_log_item;
          return : ;
          escape : display_function_key_help_screen(SHF10);
          'h','H': display_help_screen('General Help Screen');
          else   bad_key;
        END;
  UNTIL (NOT fkey) AND (key=return);
  block_log_first;
  update_block_log_window;
  deactivate_block_log_window;
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  write('             ');
END;

OVERLAY PROCEDURE edit_world_pending_window;

  FUNCTION cursor_on_window:boolean;
  VAR
    temp_val : boolean;
    loop     : integer;
    temp_ptr : pending_ptr;
  BEGIN
    temp_val:=false;
    temp_ptr:=current_pending_window_ptr;
    FOR loop:=1 to (max_world_pending_window_y-min_world_pending_window_y) DO
      BEGIN
        IF current_pending_window_item=temp_ptr
          THEN
            temp_val:=true;
        temp_ptr:=temp_ptr^.next;
      END;
    cursor_on_window:=temp_val;
  END;

  PROCEDURE world_pending_up_arrow;
  BEGIN
    IF current_pending_window_item^.prev<>NIL
      THEN
        BEGIN
          IF current_pending_window_item=current_pending_window_ptr
            THEN
              BEGIN
                current_pending_window_item:=current_pending_window_item^.prev;
                current_pending_window_ptr:=current_pending_window_item;
              END
            ELSE
              BEGIN
                current_pending_window_item:=current_pending_window_item^.prev;
              END;
          update_world_pending_window;
        END
      ELSE
        beep;
  END;

  PROCEDURE world_pending_down_arrow;
  BEGIN
    IF current_pending_window_item^.next<>NIL
      THEN
        BEGIN
          current_pending_window_item:=current_pending_window_item^.next;
          IF (NOT cursor_on_window)
            THEN
              current_pending_window_ptr:=current_pending_window_ptr^.next;
          update_world_pending_window;
        END
      ELSE
        beep;
  END;

  PROCEDURE world_pending_first;
  BEGIN
    current_pending_window_ptr:=world_pending_list_root;
    current_pending_window_item:=current_pending_window_ptr;
    update_world_pending_window;
  END;

  PROCEDURE world_pending_last;
  BEGIN
    WHILE current_pending_window_item^.next<>NIL DO
      BEGIN
        current_pending_window_item:=current_pending_window_item^.next;
        IF (NOT cursor_on_window)
          THEN
            current_pending_window_ptr:=current_pending_window_ptr^.next;
      END;
    update_world_pending_window;
  END;

  PROCEDURE world_pending_page_up;
  VAR
    loop : integer;
  BEGIN
    FOR loop:=1 to (max_world_pending_window_y-min_world_pending_window_y) DO
      world_pending_up_arrow;
  END;

  PROCEDURE world_pending_page_down;
  VAR
    loop : integer;
  BEGIN
    FOR loop:=1 to (max_world_pending_window_y-min_world_pending_window_y) DO
      world_pending_down_arrow;
  END;

  PROCEDURE delete_world_pending_item;
  VAR
    save_ptr : pending_ptr;
  BEGIN
    IF current_pending_window_item<>NIL
      THEN
        BEGIN
          save_ptr:=current_pending_window_item;
          world_pending_down_arrow;
          IF save_ptr=current_pending_window_item (* if we didn't move *)
            THEN
              world_pending_up_arrow;
          IF save_ptr=current_pending_window_item (* if we are looking at the only one *)
            THEN
              BEGIN
                world_pending_list_root:=NIL;
                current_pending_window_item:=NIL;
                current_pending_window_ptr:=NIL;
              END;
          abort_pending_item(save_ptr);
          update_world_pending_window;
        END
      ELSE
        beep;
  END;

BEGIN
  activate_world_pending_window;
  REPEAT
    key:=get_key_with_clock(fkey);
    IF fkey
      THEN
        CASE key OF
          Uarr    : world_pending_up_arrow;
          Darr    : world_pending_down_arrow;
          Home    : world_pending_first;
          EndKey  : world_pending_last;
          PgUp    : world_pending_page_up;
          PgDn    : world_pending_page_down;
      SHF1..SHF10 : display_function_key_help_screen(key);
          else    bad_key;
        END
      ELSE
        CASE key OF
          SHRarr : delete_world_pending_item;
          return : ;
          escape : display_function_key_help_screen(SHF9);
          'h','H': display_help_screen('General Help Screen');
          else   bad_key;
        END;
  UNTIL (NOT fkey) AND (key=return);
  deactivate_world_pending_window;
END;

OVERLAY PROCEDURE edit_world_log_window;

  FUNCTION cursor_on_window:boolean;
  VAR
    temp_val : boolean;
    loop     : integer;
    temp_ptr : log_ptr;
  BEGIN
    temp_val:=false;
    temp_ptr:=current_log_window_ptr;
    FOR loop:=1 to (max_world_log_window_y-min_world_log_window_y) DO
      BEGIN
        IF current_log_window_item=temp_ptr
          THEN
            temp_val:=true;
        temp_ptr:=temp_ptr^.next;
      END;
    cursor_on_window:=temp_val;
  END;

  PROCEDURE world_log_up_arrow;
  BEGIN
    IF current_log_window_item^.prev<>NIL
      THEN
        BEGIN
          IF current_log_window_item=current_log_window_ptr
            THEN
              BEGIN
                current_log_window_item:=current_log_window_item^.prev;
                current_log_window_ptr:=current_log_window_item;
              END
            ELSE
              BEGIN
                current_log_window_item:=current_log_window_item^.prev;
              END;
          update_world_log_window;
        END
      ELSE
        beep;
  END;

  PROCEDURE world_log_down_arrow;
  BEGIN
    IF current_log_window_item^.next<>NIL
      THEN
        BEGIN
          current_log_window_item:=current_log_window_item^.next;
          IF (NOT cursor_on_window)
            THEN
              current_log_window_ptr:=current_log_window_ptr^.next;
          update_world_log_window;
        END
      ELSE
        beep;
  END;

  PROCEDURE world_log_first;
  BEGIN
    current_log_window_ptr:=world_log_list_root;
    current_log_window_item:=current_log_window_ptr;
    update_world_log_window;
  END;

  PROCEDURE world_log_last;
  BEGIN
    WHILE current_log_window_item^.next<>NIL DO
      BEGIN
        current_log_window_item:=current_log_window_item^.next;
        IF (NOT cursor_on_window)
          THEN
            current_log_window_ptr:=current_log_window_ptr^.next;
      END;
    update_world_log_window;
  END;

  PROCEDURE world_log_page_up;
  VAR
    loop : integer;
  BEGIN
    FOR loop:=1 to (max_world_log_window_y-min_world_log_window_y) DO
      world_log_up_arrow;
  END;

  PROCEDURE world_log_page_down;
  VAR
    loop : integer;
  BEGIN
    FOR loop:=1 to (max_world_log_window_y-min_world_log_window_y) DO
      world_log_down_arrow;
  END;

  PROCEDURE delete_world_log_item;
  VAR
    save_ptr : log_ptr;
  BEGIN
    IF current_log_window_item<>NIL
      THEN
        BEGIN
          save_ptr:=current_log_window_item;
          world_log_down_arrow;
          IF save_ptr=current_log_window_item (* if we didn't move *)
            THEN
              world_log_up_arrow;
          IF save_ptr=current_log_window_item (* if we are looking at the only entry *)
            THEN
              BEGIN
                world_log_list_root:=NIL;
                current_log_window_item:=NIL;
                current_log_window_ptr:=NIL;
              END;
          delete_from_log_list(save_ptr);
          update_world_log_window;
        END
      ELSE
        beep;
  END;

BEGIN
  activate_world_log_window;
  REPEAT
    key:=get_key_with_clock(fkey);
    IF fkey
      THEN
        CASE key OF
          Uarr    : world_log_up_arrow;
          Darr    : world_log_down_arrow;
          Home    : world_log_first;
          EndKey  : world_log_last;
          PgUp    : world_log_page_up;
          PgDn    : world_log_page_down;
      SHF1..SHF10 : display_function_key_help_screen(key);
          else    bad_key;
        END
      ELSE
        CASE key OF
          SHRarr : delete_world_log_item;
          return : ;
          escape : display_function_key_help_screen(SHF10);
          'h','H': display_help_screen('General Help Screen');
          else   bad_key;
        END;
  UNTIL (NOT fkey) AND (key=return);
  deactivate_world_log_window;
END;

OVERLAY PROCEDURE edit_world_inventory_window;

  PROCEDURE move_to_beginning_of_world_inventory;
  BEGIN
    current_inventory_land_item:=human_resource_list_root;
    IF current_inventory_land_item<>NIL
      THEN
        current_inventory_resource_item:=world_matrix[current_inventory_land_item^.x]
                                                    ^[current_inventory_land_item^.y]
                                                    ^.resources
      ELSE
        current_inventory_resource_item:=NIL;
    update_world_inventory_window;
  END;

  PROCEDURE move_to_end_of_world_inventory;
  VAR
    save_resource : resource_ptr;
  BEGIN
    REPEAT
      save_resource:=current_inventory_resource_item;
      step_a_ptr_forward_in_world_inventory(current_inventory_resource_item,
                                            current_inventory_land_item);
    UNTIL (save_resource=current_inventory_resource_item);
    update_world_inventory_window;
  END;

  PROCEDURE move_one_page_up_in_world_inventory;
  VAR
    loop : integer;
    save_land  : human_resource_list_ptr;
    save_resource : resource_ptr;
  BEGIN
    FOR loop:=1 to (max_world_inventory_window_y-min_world_inventory_window_y) DO
      BEGIN
        save_land:=current_inventory_land_item;
        save_resource:=current_inventory_resource_item;
        back_up_a_ptr_in_world_inventory(current_inventory_resource_item,
                                         current_inventory_land_item);
        IF (save_land=current_inventory_land_item) AND
           (save_resource=current_inventory_resource_item)
          THEN
            beep;
      END;
    update_world_inventory_window;
  END;

  PROCEDURE move_one_page_down_in_world_inventory;
  VAR
    loop : integer;
    save_land:human_resource_list_ptr;
    save_resource:resource_ptr;
  BEGIN
    FOR loop:=1 to (max_world_inventory_window_y-min_world_inventory_window_y) DO
      BEGIN
        save_land:=current_inventory_land_item;
        save_resource:=current_inventory_resource_item;
        step_a_ptr_forward_in_world_inventory(current_inventory_resource_item,
                                              current_inventory_land_item);
        IF (save_land=current_inventory_land_item) AND
           (save_resource=current_inventory_resource_item)
          THEN
            beep;
      END;
    update_world_inventory_window;
  END;

  PROCEDURE move_one_item_up_in_world_inventory;
  VAR
    save_land : human_resource_list_ptr;
    save_resource : resource_ptr;
  BEGIN
    save_resource:=current_inventory_resource_item;
    save_land:=current_inventory_land_item;
    back_up_a_ptr_in_world_inventory(current_inventory_resource_item,
                                     current_inventory_land_item);
    IF (save_resource=current_inventory_resource_item) AND
       (save_land=current_inventory_land_item)
      THEN
        beep
      ELSE
        update_world_inventory_window;
  END;

  PROCEDURE move_one_item_down_in_world_inventory;
  VAR
    save_land   : human_resource_list_ptr;
    save_resource : resource_ptr;
  BEGIN
    save_land:=current_inventory_land_item;
    save_resource:=current_inventory_resource_item;
    step_a_ptr_forward_in_world_inventory(current_inventory_resource_item,
                                          current_inventory_land_item);
    IF (save_land=current_inventory_land_item) AND
       (save_resource=current_inventory_resource_item)
      THEN
        beep
      ELSE
        update_world_inventory_window;
  END;

BEGIN
  move_to_beginning_of_world_inventory;

  REPEAT
    key:=get_key_with_clock(fkey);
    IF fkey
      THEN
        CASE key OF
          F1      : BEGIN
                      mode:=world_map;
                      refresh_screen;
                    END;
          Home    : move_to_beginning_of_world_inventory;
          EndKey  : move_to_end_of_world_inventory;
          PgUp    : move_one_page_up_in_world_inventory;
          PgDn    : move_one_page_down_in_world_inventory;
          Uarr    : move_one_item_up_in_world_inventory;
          Darr    : move_one_item_down_in_world_inventory;
      SHF1..SHF10 : display_function_key_help_screen(key);
          else    bad_key;
        END
      ELSE
        CASE key OF
          return  : BEGIN
                      mode:=world_map;
                      refresh_screen;
                    END;
          escape  : display_help_screen('World Inventory Help Screen');
          'h','H' : display_help_screen('General Help Screen');
          else    bad_key;
        END;
  UNTIL ((key=return) AND (NOT fkey)) OR
        ((key=F1) AND (fkey));
END;
