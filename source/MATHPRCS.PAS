{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : MATHPRCS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These two routines are quite obvious.  One determines***)
(***                 the minimum of two integers, and the other determines***)
(***                 the maximum of two integers.                         ***)
(*** Input         : Two integer arguments                                ***)
(*** Output        : One integer result                                   ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

FUNCTION int_max(arg1,arg2:integer):integer;
BEGIN
  IF arg1>=arg2
    THEN
      int_max:=arg1
    ELSE
      int_max:=arg2;
END;

FUNCTION int_min(arg1,arg2:integer):integer;
BEGIN
  IF arg1<=arg2
    THEN
      int_min:=arg1
    ELSE
      int_min:=arg2;
END;

