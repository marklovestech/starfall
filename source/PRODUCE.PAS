{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : PRODUCE.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Production Procedures                                ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE Produce;
VAR
  production_selection_tree   : resource_ptr;
  ingredient_tree             : resource_ptr;
  desired_resource_tree       : resource_ptr;
  amount                      : real;
  temp_ptr                    : resource_ptr;
  save_ptr                    : resource_ptr;
  work_time                   : real;
  time                        : integer;
  new_pending                 : pending_ptr;

  PROCEDURE select_an_amount_of_resource_in_top_level_of_tree(resource_num : byte;
                                                             first        : resource_ptr;
                                                             amount_wanted: real);
  VAR
    temp_amount:real;
  BEGIN
    temp_amount:=0.0;
    WHILE (first<>NIL) AND (amount_wanted>0.0) DO
      BEGIN
        IF first^.resource_num=resource_num
          THEN
            IF (value_of_resource_flag_found(first^.flags)=true) AND
               (value_of_resource_flag_extracted(first^.flags)=true)
              THEN
                BEGIN
                  temp_amount:=temp_amount+first^.quantity;
                  select_tree_plus_root(first);
                  amount_wanted:=amount_wanted-first^.quantity;
                END;
        first:=first^.next;
      END;
  END;

  FUNCTION production_requirements_met(wanted_resource : integer;
                                       VAR source_tree     : resource_ptr):boolean;
  VAR
    current_level : ingredient_ptr;
    current_alternative : ingredient_ptr;
    action_possible     : boolean;
    resource_found      : boolean;
    temp_ptr            : resource_ptr;
  BEGIN
    work_time:=resources[wanted_resource].time_to_produce;
    action_possible:=true;
    current_level:=resources[wanted_resource].production_requirements;
    WHILE (current_level<>NIL) AND (action_possible) DO
      BEGIN
        resource_found:=false;
        current_alternative:=current_level;
        REPEAT
          IF (amount_of_resource_in_top_level_of_tree(current_alternative^.resource_num,source_tree)
              >=(current_alternative^.quantity*amount))
            THEN
              resource_found:=true;
          IF NOT resource_found
            THEN
              current_alternative:=current_alternative^.alternatives;
        UNTIL (resource_found) OR (current_alternative=NIL);
        IF resource_found
          THEN
            BEGIN
              select_an_amount_of_resource_in_top_level_of_tree(current_alternative^.resource_num,
                                                                source_tree,
                                                                current_alternative^.quantity*amount);
              temp_ptr:=make_selection_tree_from(source_tree);
              unselect_tree(temp_ptr);
              merge_list_into_tree(temp_ptr,new_pending^.resources_involved,
                                   current_block_x,current_block_y);
              work_time:=work_time*current_alternative^.time_factor;
              current_level:=current_level^.next; (* move down one *)
            END
          ELSE
            BEGIN
              action_possible:=false;
              beep;
              display_block_text_message('PRODUCTION ABORTED: Need ');
              write(current_level^.quantity*amount:10:0,
                    ' ',resources[current_level^.resource_num].resource_units,
                    ' ',resources[current_level^.resource_num].resource_name);
              merge_list_into_tree(new_pending^.resources_involved,
                                   source_tree,
                                   current_block_x,
                                   current_block_y);
            END;
      END;
    production_requirements_met:=action_possible;
  END;

  FUNCTION make_production_selection_tree:resource_ptr;
  VAR
    temp_ptr : resource_ptr;
    new_one  : resource_ptr;
    loop     : integer;
  BEGIN
    temp_ptr:=NIL;
    FOR loop:=max_resource DOWNTO 1 DO
      BEGIN
        IF resources[loop].produceable
          THEN
            BEGIN
              new_one:=create_a_new_resource;
              new_one^.quantity:=1.0;
              new_one^.resource_num:=loop;
              set_resource_flag_found(new_one^.flags,true);
              add_resource_to_top_level_of_tree(temp_ptr,new_one);
            END;
      END;
    make_production_selection_tree:=temp_ptr;
  END;

  PROCEDURE delete_production_tree;
  VAR
    temp_ptr   : resource_ptr;
    save_ptr   : resource_ptr;
  BEGIN
    temp_ptr:=production_selection_tree;
    WHILE temp_ptr<>NIL DO
      BEGIN
        save_ptr:=temp_ptr^.next;
        dispose(temp_ptr);
        temp_ptr:=save_ptr;
      END;
  END;

BEGIN
  clear_block_text_prompt_line;
  production_selection_tree:=make_production_selection_tree;
  TextColor(Block_mode_explanation_color);
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  writeln('PRODUCTION    ');
  resource_window_mode:=production_object_selection;
  desired_resource_tree:=get_selection_tree(production_selection_tree);
  IF desired_resource_tree<>NIL
    THEN
      BEGIN
        REPEAT
          clear_block_text_prompt_line;
          gotoxy(1,block_text_prompt_line);
          TextColor(Yellow);
          amount:=1.0;
          write('Produce how many [1.0] ?');
          get_real(amount);
          IF (amount<>int(amount)) OR (amount<0.0)
            THEN
              valid:=false;
        UNTIL valid;
        clear_block_text_prompt_line;
        IF amount>0.0
          THEN
            BEGIN
              new_pending:=create_a_new_pending_item;
              new_pending^.x:=current_block_x;
              new_pending^.y:=current_block_y;
              new_pending^.objects_involved:=desired_resource_tree;
              desired_resource_tree^.quantity:=amount;
              IF production_requirements_met(desired_resource_tree^.resource_num,
                                             world_matrix[current_block_x]^[current_block_y]^.resources)
                THEN
                  BEGIN
                    time:=trunc(work_time);
                    IF sufficient_active_resources(new_pending^.resources_involved,time) AND
                       sufficient_basic_resources(new_pending^.resources_involved,time)
                      THEN
                        BEGIN
                          new_pending^.time_started:=game_time;
                          new_pending^.updates_left:=time;
                          new_pending^.action_type:=production_action;
                          convert_updates_to_time(time,new_pending^.estimated_completion_time);
                          add_times(new_pending^.estimated_completion_time,
                                    new_pending^.time_started);
                          add_to_pending_list(new_pending);
                          update_resource_window;
                        END
                      ELSE
                        BEGIN
                          beep;
                          display_block_text_message('PRODUCTION ABORTED: Not enough ');
                          IF NOT sufficient_basic_resources(new_pending^.resources_involved,time)
                            THEN
                              write('BASIC ');
                          IF NOT sufficient_basic_resources(new_pending^.resources_involved,time)
                            THEN
                              write('ACTIVE ');
                          write('resources.');
                          update_resource_window;
                        END;
                  END
                ELSE
                  BEGIN
                    dispose(new_pending);
                    update_resource_window;
                  END;
            END
          ELSE
            BEGIN
              beep;
              clear_block_text_prompt_line;
              TextColor(LightRed+Blink);
              gotoxy(1,block_text_prompt_line);
              display_block_text_message('PRODUCTION ABORTED: User requested quantity of 0.');
              update_resource_window;
            END;
      END
    ELSE
      BEGIN
        beep;
        clear_block_text_prompt_line;
        TextColor(LightRed+Blink);
        gotoxy(1,block_text_prompt_line);
        display_block_text_message('PRODUCTION ABORTED: No target resource selected.');
        update_resource_window;
      END;
  delete_production_tree;
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  write('             ');
END;
