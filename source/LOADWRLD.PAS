{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : LOADWRLD.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This is the procedure to load a world from disk.     ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE load_world;
VAR
  loop                  : integer;
  x_loop                : integer;
  y_loop                : integer;
  temp_str              : string10;
  temp_char             : char;
  val_proc_error        : integer;
  save_x_loop           : integer;
  hrll_ptr              : human_resource_list_ptr;
  file_ok               : boolean;

  PROCEDURE read_time(VAR time:time_type);
  BEGIN
    readln(world_file,time.date);
    readln(world_file,time.month);
    readln(world_file,time.year);
    readln(world_file,time.second);
    readln(world_file,time.minute);
    readln(world_file,time.hour);
  END;

  FUNCTION char_to_boolean(ch : char):boolean;
  BEGIN
    CASE ch OF
      'T'  : char_to_boolean:=true;
      'F'  : char_to_boolean:=false;
    END;
  END;

  FUNCTION read_resource_tree(parent:resource_ptr):resource_ptr;
  VAR
    temp_str  : string10;
    node      : resource_ptr;
    temp_char : char;
  BEGIN
    readln(world_file,temp_str);
    IF temp_str='DATA'
      THEN
        BEGIN
          new(node);
          node^.prev:=NIL;
          WITH node^ DO
            BEGIN
              readln(world_file,resource_num);
              readln(world_file,quantity);
              readln(world_file,flags);
            END;
          node^.parent:=parent;
          node^.next:=read_resource_tree(parent);
          IF node^.next<>NIL
            THEN
              node^.next^.prev:=node;
          node^.child:=read_resource_tree(node);
          read_resource_tree:=node;
        END
      ELSE
        read_resource_tree:=NIL;
  END;

  FUNCTION read_human_resource_list:human_resource_list_ptr;
  VAR
    temp_ptr : human_resource_list_ptr;
    new_one  : human_resource_list_ptr;
    first_one : human_resource_list_ptr;
    first     : boolean;
  BEGIN
    first:=true;
    first_one:=NIL;
    temp_ptr:=NIL;
    readln(world_file,temp_str);
    WHILE temp_str<>'NIL' DO
      BEGIN
        new(new_one);
        readln(world_file,new_one^.x);
        readln(world_file,new_one^.y);
        IF first
          THEN
            BEGIN
              first:=false;
              first_one:=new_one;
            END;
        new_one^.next:=NIL;
        new_one^.prev:=temp_ptr;
        IF temp_ptr<>NIL
          THEN
            temp_ptr^.next:=new_one;
        temp_ptr:=new_one;
        readln(world_file,temp_str);
      END;
    read_human_resource_list:=first_one;
  END;

  FUNCTION read_transportation_list:transportation_list_ptr;
  VAR
    temp_ptr : transportation_list_ptr;
    new_one  : transportation_list_ptr;
    first_one : transportation_list_ptr;
    first    : boolean;
  BEGIN
    first_one:=NIL;
    first:=true;
    temp_ptr:=NIL;
    readln(world_file,temp_str);
    WHILE temp_str<>'NIL' DO
      BEGIN
        new(new_one);
        readln(world_file,new_one^.x);
        readln(world_file,new_one^.y);
        readln(world_file,new_one^.distance);
        IF first
          THEN
            BEGIN
              first:=false;
              first_one:=new_one;
            END;
        new_one^.next:=NIL;
        new_one^.prev:=temp_ptr;
        IF temp_ptr<>NIL
          THEN
            temp_ptr^.next:=new_one;
        temp_ptr:=new_one;
        readln(world_file,temp_str);
      END;
    read_transportation_list:=first_one;
  END;

  FUNCTION read_pending_list:pending_ptr;
  VAR
    temp_ptr : pending_ptr;
    new_one  : pending_ptr;
    first_one : pending_ptr;
    first     : boolean;
  BEGIN
    first_one:=NIL;
    first:=true;
    temp_ptr:=NIL;
    readln(world_file,temp_str);
    WHILE temp_str<>'NIL' DO
      BEGIN
        new(new_one);
        readln(world_file,new_one^.x);
        readln(world_file,new_one^.y);
        readln(world_file,new_one^.action_type);
        read_time(new_one^.time_started);
        read_time(new_one^.estimated_completion_time);
        readln(world_file,new_one^.updates_left);
        readln(world_file,new_one^.speed);
        readln(world_file,new_one^.distance);
        IF first
          THEN
            BEGIN
              first:=false;
              first_one:=new_one;
            END;
        new_one^.resources_involved:=read_resource_tree(NIL);
        new_one^.objects_involved:=read_resource_tree(NIL);
        new_one^.transportation_list:=read_transportation_list;
        new_one^.next:=NIL;
        new_one^.prev:=temp_ptr;
        IF temp_ptr<>NIL
          THEN
            temp_ptr^.next:=new_one;
        temp_ptr:=new_one;
        readln(world_file,temp_str);
      END;
    read_pending_list:=first_one;
  END;

  FUNCTION read_log_list:log_ptr;
  VAR
    temp_ptr  : log_ptr;
    new_one   : log_ptr;
    first_one : log_ptr;
    first     : boolean;
  BEGIN
    first_one:=NIL;
    first:=true;
    temp_ptr:=NIL;
    readln(world_file,temp_str);
    WHILE temp_str<>'NIL' DO
      BEGIN
        new(new_one);
        readln(world_file,new_one^.x);
        readln(world_file,new_one^.y);
        readln(world_file,new_one^.action_desc);
        read_time(new_one^.completion_time);
        IF first
          THEN
            BEGIN
              first:=false;
              first_one:=new_one;
            END;
        new_one^.prev:=temp_ptr;
        new_one^.next:=NIL;
        IF temp_ptr<>NIL
          THEN
            temp_ptr^.next:=new_one;
        temp_ptr:=new_one;
        readln(world_file,temp_str);
      END;
    read_log_list:=first_one;
  END;

BEGIN
  REPEAT
    ClrScr;
    writeln('Load World from Disk');
    get_world_file_name;
    IF world_file_name<>'ABORT'
      THEN
        BEGIN
          ASSIGN(world_file,world_file_name);
          {$I-}
          reset(world_file);
          {$I+}

          file_ok:=(IOresult=0);

          IF NOT file_ok
            THEN
              BEGIN
                beep;
                writeln('Cannot open file : ',world_file_name);
                writeln;
                writeln('Press any key to continue');
                world_file_name:='WORLD.DAT';
                REPEAT UNTIL KeyPressed;
              END;
        END;
  UNTIL (world_file_name='ABORT') OR
        file_ok;

  IF world_file_name<>'ABORT'
    THEN
      BEGIN
        readln(world_file,world_name);

        writeln('Loading: ',world_name);
        writeln;
        write('Loading world picture.');

        FOR loop:=1 to world_picture_size DO
          BEGIN
            IF loop/50=loop DIV 50
              THEN
                write('.');
            readln(world_file,world_picture^[loop]);
          END;

        writeln;
        writeln;
        write('Clearing out any previous data in memory');

        FOR x_loop:=1 to world_width DO
          BEGIN
            write('.');
            FOR y_loop:=1 to world_height DO
              BEGIN
                IF world_matrix[x_loop]^[y_loop]<>NIL
                  THEN
                    BEGIN
                      delete_resource_tree(world_matrix[x_loop]^[y_loop]^.resources);
                      dispose(world_matrix[x_loop]^[y_loop]);
                      world_matrix[x_loop]^[y_loop]:=NIL;
                    END;
              END;
          END;

        writeln;
        writeln;
        write('Loading land list and resources');

        REPEAT
          readln(world_file,temp_str);
          IF temp_str<>'DATAEND'
            THEN
              BEGIN
                val(temp_str,x_loop,val_proc_error);
                IF x_loop<>save_x_loop
                  THEN
                    BEGIN
                      write('.');
                      save_x_loop:=x_loop;
                    END;
                readln(world_file,y_loop);
                new(world_matrix[x_loop]^[y_loop]);
                readln(world_file,world_matrix[x_loop]^[y_loop]^.climate);
                readln(world_file,world_matrix[x_loop]^[y_loop]^.altitude);
                world_matrix[x_loop]^[y_loop]^.resources:=read_resource_tree(NIL);
              END;
        UNTIL temp_str='DATAEND';

        writeln;
        writeln;
        writeln('Loading System Log');
        world_log_list_root:=read_log_list;

        writeln('Loading System Pending List');
        world_pending_list_root:=read_pending_list;

        writeln('Loading Misc. System Variables');

        { If anything in human resource list right now, zap it }

        IF human_resource_list_root<>NIL
          THEN
            BEGIN
              writeln('  Clearing previous occupation data.');
              hrll_ptr:=human_resource_list_root;
              WHILE hrll_ptr<>NIL DO
                BEGIN
                  IF hrll_ptr^.next=NIL { end of the line}
                    THEN
                      BEGIN
                        dispose(hrll_ptr);
                        hrll_ptr:=NIL;
                      END
                    ELSE
                      BEGIN
                        hrll_ptr:=hrll_ptr^.next;
                        dispose(hrll_ptr^.prev);
                      END;
                END;
            END;

        human_resource_list_root:=read_human_resource_list;

        readln(world_file,temp_char);
        new_planet:=char_to_boolean(temp_char);

        readln(world_file,base_block_x);
        readln(world_file,base_block_y);

        readln(world_file,temperate_latitude);

        read_time(game_time);
        read_time(game_time_increment);
        read_time(world_update_increment);
        read_time(time_to_next_update);

        readln(world_file,current_block_x);
        readln(world_file,current_block_y);

        readln(world_file,temp_char);
        trader_in_orbit:=char_to_boolean(temp_char);
        readln(world_file,temp_char);
        trader_called:=char_to_boolean(temp_char);

        trader_resource_tree_root:=read_resource_tree(NIL);

        readln(world_file,colony_financial_status);
        readln(world_file,current_debt_limit);

        close(world_file);

        time_world_last_saved:=game_time;
      END
    ELSE
      world_file_name:='WORLD.DAT';
END;
