{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : MAKETZON.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure uses a normal distribution around     ***)
(***                 45 degrees to generate where the temperate zone      ***)
(***                 on this new world is.                                ***)
(*** Input         : None.                                                ***)
(*** Output        : In global TEMPERATE LATITUDE                         ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE determine_temperate_zone;
VAR
  loop:integer;
BEGIN
  temperate_latitude:=0;
  FOR loop:=1 to 10 DO
    temperate_latitude:=temperate_latitude+random(10);
END;
