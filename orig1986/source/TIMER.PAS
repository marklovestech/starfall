{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : TIMER.PAS                                            ***)
(*** Author        : Todd Carter, Intellisoft, Inc.                       ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure issues a MS-DOS interrupt, and        ***)
(***                 returns the system clock value to TURBO, in three    ***)
(***                 integer variables.                                   ***)
(*** Input         : None.                                                ***)
(*** Output        : Hour, Minute, Second : integer (current time)        ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE Update_Time(VAR Hour,Min,Sec:integer);

TYPE
    Registers = RECORD
                    AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags : Integer;
                END;

VAR
    Regs : Registers;

BEGIN
    WITH Regs DO
        BEGIN
            AX := $2C00;
            MsDos(Regs);
            Hour := Hi(CX);
            Min  := Lo(CX);
            Sec  := Hi(DX);
        END;
END;

(****************************************************************************)
(*** DISPLAY CURRENT TIME ON TEXT : This is a linking routine with update ***)
(*** time, above, and all it does is print the current time in the upper- ***)
(*** right corner of the screen in Yellow.                                ***)
(****************************************************************************)

PROCEDURE display_current_time_on_text;
VAR
  cur_x : integer;
  cur_y : integer;
  hour  : integer;
  minute : integer;
  second : integer;
BEGIN
  update_time(hour,minute,second);
  cur_x:=wherex;
  cur_y:=wherey;
  gotoxy(73,1);
  TextColor(Yellow);
  write(hour:2,':',minute:2,':',second:2);
  gotoxy(cur_x,cur_y);
END;