{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : INITSGTI.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure makes sure that the user can not make ***)
(***                 the world go slower than 1 minute per realtime second***)
(*** Input         : None.                                                ***)
(*** Output        : None.                                                ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE initialize_smallest_game_time_increment;
BEGIN
  clear_time(smallest_game_time_increment);
  smallest_game_time_increment.minute:=1;
END;
