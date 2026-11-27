{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : EXPLORE.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Exploration routines.                                ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE Explore;
VAR
  exploration_equipment : resource_ptr;
  time                  : integer;

  FUNCTION time_for_exploration(equipment_tree:resource_ptr):integer;
  VAR
    max_time   : integer;
    item_time  : integer;
  BEGIN
    max_time:=0;
    WHILE equipment_tree<>NIL DO
      BEGIN
        WITH equipment_tree^ DO
          BEGIN
            IF (quantity=0.0) OR
               (resources[resource_num].exploration_speed=0)
              THEN
                item_time:=0
              ELSE
                item_time:=trunc(1/(quantity*(resources[resource_num].exploration_speed)));
            IF item_time>max_time
              THEN
                max_time:=item_time;
          END;
        equipment_tree:=equipment_tree^.next;
      END;
    time_for_exploration:=max_time DIV 15;
  END;

  PROCEDURE add_exploration_item_to_pending_list(time           : integer;
                                                 equipment_tree : resource_ptr);
  VAR
    temp_pending : pending_ptr;
  BEGIN
    temp_pending:=create_a_new_pending_item;
    WITH temp_pending^ DO
      BEGIN
        x:=current_block_x;
        y:=current_block_y;
        action_type:=exploration_action;
        time_started:=game_time;
        updates_left:=time;
        convert_updates_to_time(time,estimated_completion_time);
        add_times(estimated_completion_time,time_started);
        resources_involved:=equipment_tree;
      END;
    add_to_pending_list(temp_pending);
  END;

BEGIN
  clear_block_text_prompt_line;
  TextColor(Block_mode_explanation_color);
  Gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  writeln('EXPLORATION   ');
  resource_window_mode:=exploration_equipment_selection;
  exploration_equipment:=get_selection_tree(world_matrix[current_block_x]^[current_block_y]^.resources);
  IF exploration_equipment<>NIL
    THEN
      BEGIN
        time:=time_for_exploration(exploration_equipment);
        IF sufficient_basic_resources(exploration_equipment,time) AND
           sufficient_active_resources(exploration_equipment,time)
          THEN
            BEGIN
              add_exploration_item_to_pending_list(time,exploration_equipment);
              refresh_screen;
            END
          ELSE
            BEGIN
              beep;
              display_block_text_message('EXPLORATION ABORTED: Not enough ');
              IF NOT sufficient_basic_resources(exploration_equipment,time)
                THEN
                  write('BASIC ');
              IF NOT sufficient_active_resources(exploration_equipment,time)
                THEN
                  write('ACTIVE ');
              write(' resources');
              merge_list_into_tree(exploration_equipment,
                                   world_matrix[current_block_x]^[current_block_y]^.resources,
                                   current_block_x,current_block_y);
              update_resource_window;
            END;
      END
    ELSE
      BEGIN
        beep;
        display_block_text_message('EXPLORATION ABORTED: No valid equipment selected.');
      END;
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  write('             ');
END;
