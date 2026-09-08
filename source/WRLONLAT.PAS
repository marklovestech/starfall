{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : WRLONLAT.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures handle the writing of the longitude ***)
(***                 and latitude on all three major screens - world,     ***)
(***                 sector, and block.                                   ***)
(*** Input         : x position, y position                               ***)
(*** Output        : None, except that number is written to screen        ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE write_latitude_for(y_position:integer);
VAR
  blocks_from_equator : integer;
  degrees             : real;
  minutes             : real;
BEGIN
  blocks_from_equator:=abs(y_position-(world_height DIV 2));
  degrees:=((blocks_from_equator)/(world_height DIV 2))*90.00;
  minutes:=(degrees-trunc(degrees))*60.00;
  write(trunc(degrees):3,' ',trunc(minutes):2);
  IF y_position<(world_height DIV 2)
    THEN
      write(' N')
    ELSE
      IF y_position>(world_height DIV 2)
        THEN
          write(' S');
END;

OVERLAY PROCEDURE write_longitude_for(x_position:integer);
CONST
  center=144;
VAR
  blocks_from_center: integer;
  degrees           : real;
  minutes           : real;
BEGIN
  blocks_from_center:=abs(x_position-center);
  degrees:=((blocks_from_center)/center)*180.00;
  minutes:=(degrees-trunc(degrees))*60.00;
  write(trunc(degrees):3,' ',trunc(minutes):2);
  IF x_position<center
    THEN
      write(' W')
    ELSE
      IF x_position>center
        THEN
          write(' E');
END;
