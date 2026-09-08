{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : DEVELOP.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Development Procedures                               ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE Develop;
VAR
  surface_resource_tree : resource_ptr;
  equipment_tree        : resource_ptr;
  time                  : integer;

  FUNCTION time_for_development(object_tree,equipment_tree : resource_ptr):integer;
  VAR
    base_resource_time        : real;
    base_equipment_efficiency : real;
    work_time                 : real;
  BEGIN
    base_resource_time:=0.0;
    WHILE object_tree<>NIL DO
      BEGIN
        base_resource_time:=base_resource_time+
          (object_tree^.quantity/resources[object_tree^.resource_num].development_speed);
        object_tree:=object_tree^.next;
      END;

    base_equipment_efficiency:=0.0;
    WHILE equipment_tree<>NIL DO
      BEGIN
        base_equipment_efficiency:=base_equipment_efficiency+
           (equipment_tree^.quantity*resources[equipment_tree^.resource_num].development_speed/100.0);
        equipment_tree:=equipment_tree^.next;
      END;

    work_time:=base_resource_time/base_equipment_efficiency;
  (* DEVELOPMENT CODE ONLY *)
    work_time:=work_time/15;

    time_for_development:=trunc(work_time);
  END;

  PROCEDURE add_development_item_to_pending_list(time       : integer;
                                                 objects    : resource_ptr;
                                                 equipment  : resource_ptr);
  VAR
    temp_pending : pending_ptr;
  BEGIN
    temp_pending:=create_a_new_pending_item;
    WITH temp_pending^ DO
      BEGIN
        x:=current_block_x;
        y:=current_block_y;
        action_type:=development_action;
        time_started:=game_time;
        updates_left:=time;
        convert_updates_to_time(time,estimated_completion_time);
        add_times(estimated_completion_time,time_started);
        resources_involved:=equipment;
        objects_involved:=objects;
      END;
    add_to_pending_list(temp_pending);
  END;

BEGIN
  clear_block_text_prompt_line;
  TextColor(Block_mode_explanation_color);
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  writeln('DEVELOPMENT   ');
  resource_window_mode:=development_object_selection;
  surface_resource_tree:=get_selection_tree(world_matrix[current_block_x]^[current_block_y]^.resources);
  IF surface_resource_tree<>NIL
    THEN
      BEGIN
        resource_window_mode:=development_equipment_selection;
        equipment_tree:=get_selection_tree(world_matrix[current_block_x]^[current_block_y]^.resources);
        IF equipment_tree<>NIL
          THEN
            BEGIN
              time:=time_for_development(surface_resource_tree,equipment_tree);
              IF (sufficient_basic_resources(equipment_tree,time)) AND
                 (sufficient_active_resources(equipment_tree,time))
                THEN
                  BEGIN
                    add_development_item_to_pending_list(time,
                                                         surface_resource_tree,
                                                         equipment_tree);
                    refresh_screen;
                  END
                ELSE
                  BEGIN
                    beep;
                    display_block_text_message('DEVELOPMENT ABORTED: Not enough: ');
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
                    merge_list_into_tree(surface_resource_tree,
                                         world_matrix[current_block_x]^[current_block_y]^.resources,
                                         current_block_x,current_block_y);
                    update_resource_window;
                  END;
            END
          ELSE
            BEGIN
              beep;
              display_block_text_message('DEVELOPMENT ABORTED: No valid equipment selected');
              merge_list_into_tree(surface_resource_tree,
                                   world_matrix[current_block_x]^[current_block_y]^.resources,
                                   current_block_x,current_block_y);
              update_resource_window;
            END;
      END
    ELSE
      BEGIN
        beep;
        display_block_text_message('DEVELOPMENT ABORTED: No valid surface resources selected');
      END;
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  write('            ');
END;
