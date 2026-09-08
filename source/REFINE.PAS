{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : REFINE.PAS                                           ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Refinement Procedures                                ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE Refine;
VAR
  mineral_tree     : resource_ptr;
  equipment_tree   : resource_ptr;
  time             : integer;

  FUNCTION time_for_refinement(mineral_tree,equipment_tree : resource_ptr):integer;
  VAR
    base_resource_time        : real;
    base_equipment_efficiency : real;
    work_time                 : real;
  BEGIN
    base_resource_time:=0.0;
    WHILE mineral_tree<>NIL DO
      BEGIN
        base_resource_time:=base_resource_time+
          (mineral_tree^.quantity/resources[mineral_tree^.resource_num].refinement_speed);
        mineral_tree:=mineral_tree^.next;
      END;

    base_equipment_efficiency:=0.0;
    WHILE equipment_tree<>NIL DO
      BEGIN
        base_equipment_efficiency:=base_equipment_efficiency+
           (equipment_tree^.quantity*resources[equipment_tree^.resource_num].refinement_speed/100.0);
        equipment_tree:=equipment_tree^.next;
      END;

    work_time:=base_resource_time/base_equipment_efficiency;
  (* DEVELOPMENT CODE ONLY *)
    work_time:=work_time/15;

    time_for_refinement:=trunc(work_time);
  END;

  PROCEDURE add_refinement_item_to_pending_list(time       : integer;
                                                minerals   : resource_ptr;
                                                equipment  : resource_ptr);
  VAR
    temp_pending : pending_ptr;
  BEGIN
    temp_pending:=create_a_new_pending_item;
    WITH temp_pending^ DO
      BEGIN
        x:=current_block_x;
        y:=current_block_y;
        action_type:=refinement_action;
        time_started:=game_time;
        updates_left:=time;
        convert_updates_to_time(updates_left,estimated_completion_time);
        add_times(estimated_completion_time,time_started);
        resources_involved:=equipment;
        objects_involved:=minerals;
      END;
    add_to_pending_list(temp_pending);
  END;

BEGIN
  clear_block_text_prompt_line;
  TextColor(Block_mode_explanation_color);
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  writeln('REFINEMENT    ');
  resource_window_mode:=refinement_object_selection;
  mineral_tree:=get_selection_tree(world_matrix[current_block_x]^[current_block_y]^.resources);
  IF mineral_tree<>NIL
    THEN
      BEGIN
        resource_window_mode:=refinement_equipment_selection;
        equipment_tree:=get_selection_tree(world_matrix[current_block_x]^[current_block_y]^.resources);
        IF equipment_tree<>NIL
          THEN
            BEGIN
              time:=time_for_refinement(mineral_tree,equipment_tree);
              IF (sufficient_basic_resources(equipment_tree,time)) AND
                 (sufficient_active_resources(equipment_tree,time))
                THEN
                  BEGIN
                    add_refinement_item_to_pending_list(time,
                                                        mineral_tree,
                                                        equipment_tree);
                    refresh_screen;
                  END
                ELSE
                  BEGIN
                    beep;
                    display_block_text_message('REFINEMENT ABORTED: Not enough: ');
                    IF NOT sufficient_basic_resources(equipment_tree,time)
                      THEN
                        write('BASIC ');
                    IF NOT sufficient_active_resources(equipment_tree,time)
                      THEN
                        write('ACTIVE ');
                    write(' resources');
                    merge_list_into_tree(equipment_tree,
                                         world_matrix[current_block_x]^[current_block_y]^.resources,
                                         current_block_x,current_block_y);
                    merge_list_into_tree(mineral_tree,
                                         world_matrix[current_block_x]^[current_block_y]^.resources,
                                         current_block_x,current_block_y);
                    update_resource_window;
                  END;
            END
          ELSE
            BEGIN
              beep;
              display_block_text_message('REFINEMENT ABORTED: No valid equipment selected');
              merge_list_into_tree(mineral_tree,
                                   world_matrix[current_block_x]^[current_block_y]^.resources,
                                   current_block_x,current_block_y);
              update_resource_window;
            END;
      END
    ELSE
      BEGIN
        beep;
        display_block_text_message('REFINEMENT ABORTED: No valid minerals selected');
      END;
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  write('             ');
END;
