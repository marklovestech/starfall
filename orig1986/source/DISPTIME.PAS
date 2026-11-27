{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : DISPTIME.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These are all sort of routines for the many          ***)
(***                 different displays of time.                          ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE display_current_time_on_text;
VAR
  cur_x : integer;
  cur_y : integer;
BEGIN
  update_time(real_time.hour,real_time.minute,real_time.second);
  cur_x:=wherex;
  cur_y:=wherey;
  gotoxy(73,1);
  TextColor(Clock_text_color);
  write(real_time.hour:2,':',real_time.minute:2,':',real_time.second:2);
  gotoxy(cur_x,cur_y);
END;

PROCEDURE display_time_on_text(time:time_type);
BEGIN
  write(time.hour:2,':',time.minute:2,' ',
        (time.month+1):2,'/',(time.date+1):2,'/',time.year:4);
END;

PROCEDURE display_game_time_on_text;
VAR
  curx,cury : integer;
BEGIN
  TextColor(game_time_display_color);
  curx:=wherex;
  cury:=wherey;
  gotoxy(game_time_display_x,game_time_display_y);
  display_time_on_text(game_time);
  gotoxy(curx,cury);
END;
