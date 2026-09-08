{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : TRANSPRT.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Transportation Procedures                            ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE transport;
VAR
  vehicle_tree   : resource_ptr;
  quit           : boolean;
  done           : boolean;

  FUNCTION speed_of_tree(vehicle_tree        : resource_ptr;
                         transportation_mode : transportation_mode_type):real;
  VAR
    temp_speed : real;
  BEGIN
    temp_speed:=9.9999E25; (* a LARGE number, huh? *)
    WHILE vehicle_tree<>NIL DO
      BEGIN
        CASE transportation_mode OF
          air       : BEGIN
                        IF resources[vehicle_tree^.resource_num].air_speed<temp_speed
                          THEN
                            temp_speed:=resources[vehicle_tree^.resource_num].air_speed;
                      END;
          land      : BEGIN
                        IF resources[vehicle_tree^.resource_num].land_speed<temp_speed
                          THEN
                            temp_speed:=resources[vehicle_tree^.resource_num].land_speed;
                      END;
          water     : BEGIN
                        IF resources[vehicle_tree^.resource_num].water_speed<temp_speed
                          THEN
                            temp_speed:=resources[vehicle_tree^.resource_num].water_speed;
                      END;
        END;
        vehicle_tree:=vehicle_tree^.next;
      END;
    speed_of_tree:=temp_speed;
  END;

BEGIN
  clear_block_text_prompt_line;
  TextColor(Block_mode_explanation_color);
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  writeln('TRANSPORTATION');
  quit:=false;
  done:=false;
  REPEAT
    clear_block_text_prompt_line;
    gotoxy(1,block_text_prompt_line);
    TextColor(LightRed);
    TextBackground(Yellow); write('L');
    TextBackground(Black); write('and, ');
    TextBackground(Yellow); write('W');
    TextBackground(Black); write('ater, or ');
    TextBackground(Yellow); write('A');
    TextBackground(Black); write('ir transporation, or ');
    TextBackground(Yellow); write('Q');
    TextBackground(Black); write('uit ?');
    key:=get_key_with_clock(fkey);
    IF fkey
      THEN
        BEGIN
          CASE key OF
            SHF1..SHF10  : display_function_key_help_screen(key);
          END;
        END
      ELSE
        BEGIN
          CASE key OF
            escape  : display_function_key_help_screen(SHF8);
            'h','H' : display_help_screen('General Help Screen');
            'a','A' : BEGIN
                        current_transportation_mode:=air;
                        done:=true;
                      END;
            'l','L' : BEGIN
                        current_transportation_mode:=land;
                        done:=true;
                      END;
            'w','W' : BEGIN
                        current_transportation_mode:=water;
                        done:=true;
                      END;
            'q','Q' : quit:=true;
          END;
        END;
  UNTIL (quit) OR (done);

  clear_block_text_prompt_line;

  IF done
    THEN
      BEGIN
        resource_window_mode:=transportation_equipment_selection;
        vehicle_tree:=get_selection_tree(world_matrix[current_block_x]^[current_block_y]^.resources);
        IF vehicle_tree<>NIL
          THEN
            BEGIN
              IF sufficient_basic_resources(vehicle_tree,1) AND
                 sufficient_active_resources(vehicle_tree,1)
                THEN
                  BEGIN
                    current_transportation_pending:=create_a_new_pending_item;
                    WITH current_transportation_pending^ DO
                      BEGIN
                        x:=current_block_x;
                        y:=current_block_y;
                        action_type:=transportation_action;
                        time_started:=game_time;
                        updates_left:=0;
                        resources_involved:=vehicle_tree;
                        objects_involved:=NIL;
                        transportation_list:=create_a_new_transportation_list_item;
                        transportation_list^.x:=current_block_x;
                        transportation_list^.y:=current_block_y;
                        transportation_list^.distance:=0.0;
                        speed:=speed_of_tree(vehicle_tree,current_transportation_mode);
                        current_transportation_ptr:=transportation_list;
                      END;
                    mode:=transportation_zoom_map;
                    current_transportation_blocks:=0;
                    refresh_screen;
                  END
                ELSE
                  BEGIN
                    beep;
                    display_block_text_message('TRANSPORTION ABORTED: Not enough ');
                    IF NOT sufficient_basic_resources(vehicle_tree,1)
                      THEN
                        write('BASIC ');
                    IF NOT sufficient_active_resources(vehicle_tree,1)
                      THEN
                        write('ACTIVE ');
                    write('resources.');
                    merge_list_into_tree(vehicle_tree,
                                         world_matrix[current_block_x]^[current_block_y]^.resources,
                                         current_block_x,
                                         current_block_y);
                    update_resource_window;
                  END;
            END
          ELSE
            BEGIN
              beep;
              display_block_text_message('TRANSPORTATION ABORTED: No valid vehicles selected.');
              gotoxy(block_mode_explanation_x,block_mode_explanation_y);
              write('               ');
              update_resource_window;
            END;
      END
    ELSE
      BEGIN
        beep;
        display_block_text_message('TRANSPORTATION ABORTED: User aborted transportation type selection.');
        gotoxy(block_mode_explanation_x,block_mode_explanation_y);
        write('               ');
      END;
END;

OVERLAY PROCEDURE complete_transportation_entry;
VAR
  temp_time : time_type;
BEGIN
  WITH current_transportation_pending^ DO
    BEGIN
      updates_left:=trunc(distance/speed);
      IF updates_left=0
        THEN
          updates_left:=1;

      distance:=0.0; (* start over for counting *)
      convert_updates_to_time(updates_left,estimated_completion_time);
      add_times(estimated_completion_time,time_started);
    END;

  add_to_pending_list(current_transportation_pending);
  current_block_x:=current_transportation_pending^.x;
  current_block_y:=current_transportation_pending^.y;
  mode:=block_text;
  refresh_screen;
END;

OVERLAY FUNCTION legal_move(x1,y1,x2,y2 : integer):boolean;
VAR
  temp_val : boolean;
  time_needed : integer;
  done        : boolean;
BEGIN
  done:=false;
  temp_val:=false;
  IF (current_transportation_ptr<>NIL)
    THEN
      IF (current_transportation_ptr^.prev<>NIL)
        THEN
          IF (x2=current_transportation_ptr^.prev^.x) AND
             (y2=current_transportation_ptr^.prev^.y)
            THEN   (* they are doing a retrace to last position *)
              BEGIN
                temp_val:=true;
                done:=true;
              END;
  IF NOT done
    THEN
      BEGIN
        CASE current_transportation_mode OF
          air    : temp_val:=true; (* you can move anywhere *)
          land   : temp_val:=land_at(x2,y2);
          water  : BEGIN
                     IF current_transportation_ptr=NIL (* first move *)
                       THEN
                         BEGIN
                           temp_val:=water_at(x2,y2);
                         END
                       ELSE
                         BEGIN
                           IF water_at(x1,y1)
                             THEN
                               temp_val:=true
                             ELSE
                               BEGIN
                                 IF (x2=current_transportation_ptr^.x) AND
                                    (y2=current_transportation_ptr^.y)
                                   THEN
                                     temp_val:=true;
                               END;
                         END;
                   END;
        END;

        IF temp_val=true
          THEN
            BEGIN
              time_needed:=trunc(current_transportation_pending^.distance/current_transportation_pending^.speed);
              temp_val:=sufficient_active_resources(current_transportation_pending^.resources_involved,time_needed)
                        AND sufficient_basic_resources(current_transportation_pending^.resources_involved,time_needed);
            END;
      END;
  legal_move:=temp_val;
END;