{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : SAVEWRLD.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure saves the world to disk               ***)
(*** Input         : The world, as stored in memory                       ***)
(*** Output        : A large data file on disk                            ***)
(*** Special Notes : Floppies are a dangerous idea near this procedure    ***)
(****************************************************************************)

OVERLAY PROCEDURE save_world;
VAR
  loop          : integer;
  inner_loop    : integer;
  x_loop        : integer;
  y_loop        : integer;
  file_ok       : boolean;

(****************************************************************************)
(*** WRITE TIME : Given a time_type variable, this procedure writes out   ***)
(*** all of the fields in text form.                                      ***)
(****************************************************************************)

  PROCEDURE write_time(time : time_type);
  BEGIN
    writeln(world_file,time.date);
    writeln(world_file,time.month);
    writeln(world_file,time.year);
    writeln(world_file,time.second);
    writeln(world_file,time.minute);
    writeln(world_file,time.hour);
  END;

(****************************************************************************)
(*** BOOLEAN TO CHAR : This function prepares a boolean variable for      ***)
(*** output to the text file.                                             ***)
(****************************************************************************)

  FUNCTION boolean_to_char(bool : boolean):char;
  BEGIN
    CASE bool OF
      true   : boolean_to_char :='T';
      false  : boolean_to_char :='F';
    END;
  END;

(****************************************************************************)
(*** WRITE RESOURCE TREE : This is a fun, recursive procedure to write    ***)
(*** a resource tree to disk in text form.                                ***)
(****************************************************************************)

  PROCEDURE write_resource_tree(tree_root: resource_ptr;
                                parent   : resource_ptr);
  BEGIN
    IF tree_root=NIL
      THEN
        writeln(world_file,'NIL')
      ELSE
        BEGIN
          WITH tree_root^ DO
            BEGIN
              writeln(world_file,'DATA');
              writeln(world_file,resource_num);
              writeln(world_file,quantity);
              writeln(world_file,flags);
            END;
          write_resource_tree(tree_root^.next,parent);
          write_resource_tree(tree_root^.child,tree_root);
        END;
  END;

(****************************************************************************)
(*** WRITE HUMAN RESOURCE LIST : This procedure writes out the human      ***)
(*** resource list to disk.                                               ***)
(****************************************************************************)

  PROCEDURE write_human_resource_list;
  VAR
    hrll : human_resource_list_ptr;
  BEGIN
    hrll:=human_resource_list_root;

    WHILE hrll<>NIL DO
      BEGIN
        writeln(world_file,'DATA');
        writeln(world_file,hrll^.x);
        writeln(world_file,hrll^.y);
        hrll:=hrll^.next;
      END;

    writeln(world_file,'NIL');
  END;

(****************************************************************************)
(*** WRITE TRANSPORTATION LIST : This writes out the transportation list  ***)
(*** if any, for a pending item.                                          ***)
(****************************************************************************)

  PROCEDURE write_transportation_list(trans_ptr : transportation_list_ptr);
  BEGIN
    WHILE trans_ptr<>NIL DO
      BEGIN
        writeln(world_file,'DATA');
        writeln(world_file,trans_ptr^.x);
        writeln(world_file,trans_ptr^.y);
        writeln(world_file,trans_ptr^.distance);
        trans_ptr:=trans_ptr^.next;
      END;

    writeln(world_file,'NIL');
  END;

(****************************************************************************)
(*** WRITE PENDING LIST : Using NILs and DATAs and many smaller           ***)
(*** procedures, write out the pending list to disk.                      ***)
(****************************************************************************)

  PROCEDURE write_pending_list(pending_list : pending_ptr);
  BEGIN
    WHILE pending_list<>NIL DO
      BEGIN
        writeln(world_file,'DATA');
        writeln(world_file,pending_list^.x);
        writeln(world_file,pending_list^.y);
        writeln(world_file,pending_list^.action_type);
        write_time(pending_list^.time_started);
        write_time(pending_list^.estimated_completion_time);
        writeln(world_file,pending_list^.updates_left);
        writeln(world_file,pending_list^.speed);
        writeln(world_file,pending_list^.distance);
        write_resource_tree(pending_list^.resources_involved,NIL);
        write_resource_tree(pending_list^.objects_involved,NIL);
        write_transportation_list(pending_list^.transportation_list);
        pending_list:=pending_list^.next;
      END;

    writeln(world_file,'NIL');
  END;

(****************************************************************************)
(*** WRITE LOG LIST : Using NILs and DATAs, write the linked list to      ***)
(*** disk as text.                                                        ***)
(****************************************************************************)

  PROCEDURE write_log_list(log_list : log_ptr);
  BEGIN
    WHILE log_list<>NIL DO
      BEGIN
        writeln(world_file,'DATA');
        writeln(world_file,log_list^.x);
        writeln(world_file,log_list^.y);
        writeln(world_file,log_list^.action_desc);
        write_time(log_list^.completion_time);
        log_list:=log_list^.next;
      END;

    writeln(world_file,'NIL');
  END;

(****************************************************************************)
(*** SAVEWRLD - MAINLINE CODE                                             ***)
(****************************************************************************)

BEGIN
  get_world_name;

  REPEAT
    ClrScr;
    writeln('Saving the World to disk:');
    get_world_file_name;
    IF world_file_name<>'ABORT'
      THEN
        BEGIN
          ASSIGN(world_file,world_file_name);
          {$I-}
          rewrite(world_file);
          {$I+}

          file_ok:=(IOresult=0);

          IF NOT file_ok
            THEN
              BEGIN
                beep;
                writeln('Cannot open file : ',world_file_name);
                writeln;
                writeln('<Press any key to continue>');
                world_file_name:='WORLD.DAT';
                REPEAT UNTIL KeyPressed;
              END;
        END;
  UNTIL (world_file_name='ABORT') OR
        file_ok;

  IF world_file_name<>'ABORT'
    THEN
      BEGIN
        writeln(world_file,world_name);
        writeln('Saving : ',world_name);
        writeln;
        write('Saving world picture.');

        FOR loop:=1 to world_picture_size DO
          BEGIN
            IF loop/50=loop DIV 50
              THEN
                write('.');
            writeln(world_file,world_picture^[loop]);
          END;

        writeln;
        writeln;
        write('Saving land matrix and resources');

        FOR x_loop:=1 to world_width DO
          BEGIN
            write('.');
            FOR y_loop:=1 to world_height DO
              BEGIN
                IF land_at(x_loop,y_loop)
                  THEN
                    BEGIN
                      writeln(world_file,x_loop);
                      writeln(world_file,y_loop);
                      writeln(world_file,world_matrix[x_loop]^[y_loop]^.climate);
                      writeln(world_file,world_matrix[x_loop]^[y_loop]^.altitude);
                      write_resource_tree(world_matrix[x_loop]^[y_loop]^.resources,NIL);
                    END;
              END;
          END;
        writeln(world_file,'DATAEND');

        writeln;
        writeln;
        writeln('Saving System Log');
        write_log_list(world_log_list_root);

        writeln('Saving System Pending List');
        write_pending_list(world_pending_list_root);

        writeln('Saving Misc. System Variables');

        write_human_resource_list;

        writeln(world_file,boolean_to_char(new_planet));
        writeln(world_file,base_block_x);
        writeln(world_file,base_block_y);

        writeln(world_file,temperate_latitude);

        write_time(game_time);
        write_time(game_time_increment);
        write_time(world_update_increment);
        write_time(time_to_next_update);

        writeln(world_file,current_block_x);
        writeln(world_file,current_block_y);

        writeln(world_file,boolean_to_char(trader_in_orbit));
        writeln(world_file,boolean_to_char(trader_called));

        write_resource_tree(trader_resource_tree_root,NIL);

        writeln(world_file,colony_financial_status);
        writeln(world_file,current_debt_limit);

        close(world_file);

        time_world_last_saved := game_time;
      END
    ELSE
      world_file_name:='WORLD.DAT';
END;
