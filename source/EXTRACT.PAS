{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : EXTRACT.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Extraction Procedures                                ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE Extract;
VAR
  mineral_tree   : resource_ptr;
  equipment_tree : resource_ptr;
  time           : integer;

  FUNCTION time_for_extraction(minerals   : resource_ptr;
                               equipment  : resource_ptr):integer;
  VAR
    base_mineral_time         : real;
    base_equipment_efficiency : real;
    work_time                 : real;
  BEGIN
    base_mineral_time:=0.0;
    WHILE minerals<>NIL DO
      BEGIN
        base_mineral_time:=base_mineral_time+
          (minerals^.quantity/resources[minerals^.resource_num].extraction_speed);
        minerals:=minerals^.next;
      END;

    base_equipment_efficiency:=0.0;
    WHILE equipment<>NIL DO
      BEGIN
        base_equipment_efficiency:=base_equipment_efficiency+
          (equipment^.quantity*resources[equipment^.resource_num].extraction_speed);
        equipment:=equipment^.next;
      END;

    work_time:=(base_mineral_time/base_equipment_efficiency);

  (* DEVELOPMENT CODE ONLY *)
    work_time :=work_time / 15;

    time_for_extraction:=trunc(work_time);
  END;

  PROCEDURE add_extraction_item_to_pending_list(time_updates   : integer;
                                                minerals       : resource_ptr;
                                                equipment      : resource_ptr);
  VAR
    temp_pending : pending_ptr;
  BEGIN
    temp_pending:=create_a_new_pending_item;
    WITH temp_pending^ DO
      BEGIN
        x:=current_block_x;
        y:=current_block_y;
        action_type:=extraction_action;
        time_started:=game_time;
        updates_left:=time_updates;
        convert_updates_to_time(time_updates,estimated_completion_time);
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
  writeln('EXTRACTION    ');
  resource_window_mode:=extraction_mineral_selection;
  mineral_tree:=get_selection_tree(world_matrix[current_block_x]^[current_block_y]^.resources);
  IF mineral_tree<>NIL
    THEN
      BEGIN
        resource_window_mode:=extraction_equipment_selection;
        equipment_tree:=get_selection_tree(world_matrix[current_block_x]^[current_block_y]^.resources);
        IF equipment_tree<>NIL
          THEN
            BEGIN
              time:=time_for_extraction(mineral_tree,equipment_tree);
              IF sufficient_basic_resources(equipment_tree,time) AND
                 sufficient_active_resources(equipment_tree,time)
                THEN
                  BEGIN
                    add_extraction_item_to_pending_list(time,
                                                        mineral_tree,
                                                        equipment_tree);
                    refresh_screen;
                  END
                ELSE
                  BEGIN
                    beep;
                    display_block_text_message('EXTRACTION ABORTED: Not enough ');
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
              display_block_text_message('EXTRACTION ABORTED: No valid equipment selected');
              merge_list_into_tree(mineral_tree,
                                   world_matrix[current_block_x]^[current_block_y]^.resources,
                                   current_block_x,current_block_y);
              update_resource_window;
            END;
      END
    ELSE
      BEGIN
        beep;
        display_block_text_message('EXTRACTION ABORTED: No valid minerals selected');
      END;
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  write('              ');
END;
