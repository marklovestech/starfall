{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : UPDABLPL.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : In this file are procedures for updating the block   ***)
(***                 pending, the block log, the world pending, and the   ***)
(***                 world log windows.                                   ***)
(*** Input         : None.                                                ***)
(*** Output        : None.                                                ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE update_block_pending_window_overlay;
VAR
  temp_ptr : pending_ptr;
  current_y : integer;
  save_ptr  : pending_ptr;
BEGIN
  Window(2,min_block_pending_window_y+1,78,max_block_pending_window_y);
  ClrScr;
  Window(2,min_block_pending_window_y,79,max_block_pending_window_y);
  current_y:=0;
  temp_ptr:=current_pending_window_ptr;
  IF temp_ptr=NIL
    THEN
      current_y:=-1;
  save_ptr:=NIL;
  WHILE (temp_ptr<>save_ptr) AND (current_y<3) DO
    BEGIN
      save_ptr:=temp_ptr;
      current_y:=succ(current_y);
      gotoxy(2,current_y+1);
      TextColor(LightRed);
      display_pending_item(temp_ptr);
      IF temp_ptr=current_pending_window_item
        THEN
          BEGIN
            gotoxy(1,wherey);
            TextColor(LightBlue);
            write('->');
            gotoxy(76,wherey);
            write('<-');
          END;
      temp_ptr:=next_pending_for_block(temp_ptr);
    END;
  Window(1,1,80,25);
END;

OVERLAY PROCEDURE update_world_pending_window_overlay;
VAR
  temp_ptr : pending_ptr;
  current_y : integer;
BEGIN
  Window(2,min_world_pending_window_y+1,78,max_world_pending_window_y);
  ClrScr;
  Window(2,min_world_pending_window_y,79,max_world_pending_window_y);
  current_y:=0;
  temp_ptr:=current_pending_window_ptr;
  IF temp_ptr=NIL
    THEN
      current_y:=-1;
  WHILE (temp_ptr<>NIL) AND (current_y<5) DO
    BEGIN
      current_y:=succ(current_y);
      gotoxy(2,current_y+1);
      TextColor(LightRed);
      display_pending_item(temp_ptr);
      IF temp_ptr=current_pending_window_item
        THEN
          BEGIN
            gotoxy(1,wherey);
            TextColor(LightBlue);
            write('->');
            gotoxy(76,wherey);
            write('<-');
          END;
      temp_ptr:=temp_ptr^.next;
    END;
  Window(1,1,80,25);
END;

OVERLAY PROCEDURE update_block_log_window_overlay;
VAR
  temp_ptr : log_ptr;
  current_y : integer;
  save_ptr  : log_ptr;
BEGIN
  Window(2,min_block_log_window_y+1,78,max_block_log_window_y);
  ClrScr;
  Window(2,min_block_log_window_y,79,max_block_log_window_y);
  current_y:=0;
  temp_ptr:=current_log_window_ptr;
  IF temp_ptr=NIL
    THEN
      current_y:=-1;
  save_ptr:=NIL;
  WHILE (temp_ptr<>save_ptr) AND (current_y<3) DO
    BEGIN
      save_ptr:=temp_ptr;
      current_y:=succ(current_y);
      gotoxy(2,current_y+1);
      TextColor(LightGreen);
      display_log_item(temp_ptr);
      IF temp_ptr=current_log_window_item
        THEN
          BEGIN
            gotoxy(1,wherey);
            TextColor(LightBlue);
            write('->');
            gotoxy(76,wherey);
            write('<-');
          END;
      temp_ptr:=next_log_for_block(temp_ptr);
    END;
  Window(1,1,80,25);
END;

OVERLAY PROCEDURE update_world_log_window_overlay;
VAR
  temp_ptr : log_ptr;
  current_y : integer;
BEGIN
  Window(2,min_world_log_window_y+1,78,max_world_log_window_y);
  ClrScr;
  Window(2,min_world_log_window_y,79,max_world_log_window_y);
  current_y:=0;
  temp_ptr:=current_log_window_ptr;
  IF temp_ptr=NIL
    THEN
      current_y:=-1;
  WHILE (temp_ptr<>NIL) AND (current_y<5) DO
    BEGIN
      current_y:=succ(current_y);
      gotoxy(2,current_y+1);
      TextColor(LightGreen);
      display_log_item(temp_ptr);
      IF temp_ptr=current_log_window_item
        THEN
          BEGIN
            gotoxy(1,wherey);
            TextColor(LightBlue);
            write('->');
            gotoxy(76,wherey);
            write('<-');
          END;
      temp_ptr:=temp_ptr^.next;
    END;
  Window(1,1,80,25);
END;
