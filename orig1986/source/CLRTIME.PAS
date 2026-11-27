{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : CLRTIME.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Clears out a time variable                           ***)
(*** Input         : A unitialized time_type variable.                    ***)
(*** Output        : The same variable with all fields set to 0           ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE clear_time(VAR time:time_type);
BEGIN
  time.second:=0;
  time.minute:=0;
  time.hour:=0;
  time.date:=0;
  time.month:=0;
  time.year:=0;
END;
