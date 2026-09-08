{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : PENDPRCS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures are all of the routines to work     ***)
(***                 with the pending and log lists.                      ***)
(*** Input         : See particular subprogram                            ***)
(*** Output        : See particular subprogram                            ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY FUNCTION create_a_new_transportation_list_item_overlay:transportation_list_ptr;
  VAR
    temp_ptr : transportation_list_ptr;
  BEGIN
    new(temp_ptr);
    temp_ptr^.x:=0;
    temp_ptr^.y:=0;
    temp_ptr^.next:=NIL;
    temp_ptr^.prev:=NIL;
    temp_ptr^.distance:=0.0;
    create_a_new_transportation_list_item_overlay:=temp_ptr;
  END;

OVERLAY PROCEDURE initialize_pending_list;
BEGIN
  world_pending_list_root:=NIL;
END;

OVERLAY FUNCTION create_a_new_pending_item:pending_ptr;
VAR
  temp_ptr : pending_ptr;
BEGIN
  new(temp_ptr);
  WITH temp_ptr^ DO
    BEGIN
      next:=NIL;
      prev:=NIL;
      x:=-5;
      y:=-5;
      speed:=0.0;
      distance:=0.0;
      action_type:=0;
      time_started:=game_time;
      estimated_completion_time:=game_time;
      updates_left:=0;
      resources_involved:=NIL;
      objects_involved:=NIL;
      transportation_list:=NIL;
    END;
  create_a_new_pending_item:=temp_ptr;
END;

OVERLAY FUNCTION next_pending_for_block(current_pending  : pending_ptr):pending_ptr;
VAR
  temp_ptr  : pending_ptr;
  found_one : boolean;
BEGIN
  temp_ptr:=current_pending^.next;
  found_one:=false;
  WHILE (temp_ptr<>NIL) AND (NOT found_one) DO
    BEGIN
      IF (temp_ptr^.x=current_pending^.x) AND
         (temp_ptr^.y=current_pending^.y)
        THEN
          found_one:=true
        ELSE
          temp_ptr:=temp_ptr^.next;
    END;

  IF found_one
    THEN
      next_pending_for_block:=temp_ptr
    ELSE
      next_pending_for_block:=current_pending;
END;

OVERLAY FUNCTION first_pending_for_block(block_x,block_y: integer): pending_ptr;
VAR
  found    : boolean;
  temp_ptr : pending_ptr;
BEGIN
  found:=false;
  temp_ptr:=world_pending_list_root;
  WHILE (temp_ptr<>NIL) AND (NOT found) DO
    BEGIN
      IF (temp_ptr^.x=block_x) AND
         (temp_ptr^.y=block_y)
        THEN
          found:=true
        ELSE
          temp_ptr:=temp_ptr^.next;
    END;
  first_pending_for_block:=temp_ptr;
END;

OVERLAY FUNCTION prev_pending_for_block(current_pending  : pending_ptr):pending_ptr;
VAR
  temp_ptr  : pending_ptr;
  found_one : boolean;
BEGIN
  temp_ptr:=current_pending^.prev;
  found_one:=false;
  WHILE (temp_ptr<>NIL) AND (NOT found_one) DO
    BEGIN
      IF (temp_ptr^.x=current_pending^.x) AND
         (temp_ptr^.y=current_pending^.y)
        THEN
          found_one:=true
        ELSE
          temp_ptr:=temp_ptr^.prev;
    END;

  IF found_one
    THEN
      prev_pending_for_block:=temp_ptr
    ELSE
      prev_pending_for_block:=current_pending;
END;

OVERLAY PROCEDURE add_to_pending_list(new_item : pending_ptr);
VAR
  temp_ptr : pending_ptr;
BEGIN
  IF world_pending_list_root=NIL
    THEN
      world_pending_list_root:=new_item
    ELSE
      BEGIN
        temp_ptr:=world_pending_list_root;
        WHILE temp_ptr^.next<>NIL DO
          temp_ptr:=temp_ptr^.next;

        temp_ptr^.next:=new_item;
        new_item^.prev:=temp_ptr;
      END;
END;

OVERLAY PROCEDURE delete_from_pending_list(VAR item : pending_ptr);
BEGIN
  IF item<>NIL
    THEN
      BEGIN
        IF world_pending_list_root=item
          THEN
            world_pending_list_root:=item^.next;
        IF current_pending_window_item=item
          THEN
            BEGIN
              current_pending_window_item:=item^.next;
              IF current_pending_window_item=NIL
                THEN
                  current_pending_window_item:=item^.prev;
            END;
        IF current_pending_window_ptr=item
          THEN
            BEGIN
              current_pending_window_ptr:=item^.next;
              IF current_pending_window_ptr=NIL
                THEN
                  current_pending_window_ptr:=item^.prev;
            END;
        IF item^.next<>NIL
          THEN
            item^.next^.prev:=item^.prev;
        IF item^.prev<>NIL
          THEN
            item^.prev^.next:=item^.next;
        IF world_pending_list_root=item
          THEN
            world_pending_list_root:=item^.next;
        dispose(item);
      END;
END;

OVERLAY PROCEDURE display_pending_item(item : pending_ptr);
BEGIN
  write(' |',item^.x:3,'|',item^.y:3,'|');
  write(text_for_action_type(item^.action_type):25,'   ');
  write('|');
  display_time_on_text(item^.time_started);
  write('| ');
  display_time_on_text(item^.estimated_completion_time);
  write('|');
END;

OVERLAY PROCEDURE initialize_log_list;
BEGIN
  world_log_list_root:=NIL;
END;

OVERLAY FUNCTION create_a_new_log_item:log_ptr;
VAR
  temp_ptr : log_ptr;
BEGIN
  new(temp_ptr);
  WITH temp_ptr^ DO
    BEGIN
      next:=NIL;
      prev:=NIL;
      x:=-1;
      y:=-1;
      action_desc:='';
      completion_time:=game_time;
    END;
  create_a_new_log_item:=temp_ptr;
END;

OVERLAY FUNCTION next_log_for_block(current_log : log_ptr):log_ptr;
VAR
  temp_ptr  : log_ptr;
  found_one : boolean;
BEGIN
  temp_ptr:=current_log^.next;
  found_one:=false;
  WHILE (temp_ptr<>NIL) AND (NOT found_one) DO
    BEGIN
      IF (temp_ptr^.x=current_log^.x) AND
         (temp_ptr^.y=current_log^.y)
        THEN
          found_one:=true
        ELSE
          temp_ptr:=temp_ptr^.next;
    END;

  IF found_one
    THEN
      next_log_for_block:=temp_ptr
    ELSE
      next_log_for_block:=current_log;
END;

OVERLAY FUNCTION first_log_for_block(block_x,block_y: integer): log_ptr;
VAR
  found    : boolean;
  temp_ptr : log_ptr;
BEGIN
  found:=false;
  temp_ptr:=world_log_list_root;
  WHILE (temp_ptr<>NIL) AND (NOT found) DO
    BEGIN
      IF (temp_ptr^.x=block_x) AND
         (temp_ptr^.y=block_y)
        THEN
          found:=true
        ELSE
          temp_ptr:=temp_ptr^.next;
    END;
  first_log_for_block:=temp_ptr;
END;

OVERLAY FUNCTION prev_log_for_block(current_log : log_ptr ):log_ptr;
VAR
  temp_ptr  : log_ptr;
  found_one : boolean;
BEGIN
  temp_ptr:=current_log^.prev;
  found_one:=false;
  WHILE (temp_ptr<>NIL) AND (NOT found_one) DO
    BEGIN
      IF (temp_ptr^.x=current_log^.x) AND
         (temp_ptr^.y=current_log^.y)
        THEN
          found_one:=true
        ELSE
          temp_ptr:=temp_ptr^.prev;
    END;

  IF found_one
    THEN
      prev_log_for_block:=temp_ptr
    ELSE
      prev_log_for_block:=current_log;
END;

OVERLAY PROCEDURE add_to_log_list(new_item : log_ptr);
VAR
  temp_ptr : log_ptr;
BEGIN
  IF world_log_list_root=NIL
    THEN
      world_log_list_root:=new_item
    ELSE
      BEGIN
        temp_ptr:=world_log_list_root;
        WHILE temp_ptr^.next<>NIL DO
          temp_ptr:=temp_ptr^.next;

        temp_ptr^.next:=new_item;
        new_item^.prev:=temp_ptr;
      END;
END;

OVERLAY PROCEDURE delete_from_log_list(VAR item : log_ptr);
BEGIN
  IF item<>NIL
    THEN
      BEGIN
        IF world_log_list_root=item
          THEN
            world_log_list_root:=item^.next;
        IF current_log_window_item=item
          THEN
            BEGIN
              current_log_window_item:=item^.next;
              IF current_log_window_item=NIL
                THEN
                  current_log_window_item:=item^.prev;
            END;
        IF current_log_window_ptr=item
          THEN
            BEGIN
              current_log_window_ptr:=item^.next;
              IF current_log_window_ptr=NIL
                THEN
                  current_log_window_ptr:=item^.prev;
            END;
        IF item^.next<>NIL
          THEN
            item^.next^.prev:=item^.prev;
        IF item^.prev<>NIL
          THEN
            item^.prev^.next:=item^.next;
        IF world_log_list_root=item
          THEN
            world_log_list_root:=item^.next;
        dispose(item);
      END;
END;

OVERLAY PROCEDURE display_log_item(item : log_ptr);
BEGIN
  write(' |',item^.x:3,'|',item^.y:3,'|');
  write(item^.action_desc:30);
  write(' | ':17);
  display_time_on_text(item^.completion_time);
  write('|');
END;

