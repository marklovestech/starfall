{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : LANDPRIM.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures define all of the various things    ***)
(***                 that all of the programs need to do with the land.   ***)
(*** Input         : See particular procedure                             ***)
(*** Output        : See particular procedure                             ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

(****************************************************************************)
(*** WATER AT : Tells the user whether there is water at a certain X,Y    ***)
(*** coordinate on the world map.                                         ***)
(****************************************************************************)

FUNCTION water_at(x,y:integer):boolean;
BEGIN
  IF world_matrix[x]^[y]=NIL
    THEN
      water_at:=true
    ELSE
      water_at:=false;
END;

(****************************************************************************)
(*** LAND AT : Tells the user whether there is land at a certain X,Y      ***)
(*** coordinate on the world map.                                         ***)
(****************************************************************************)

FUNCTION land_at(x,y:integer):boolean;
BEGIN
  land_at:=NOT water_at(x,y);
END;

(****************************************************************************)
(*** ALTITUDE OF : This function goes in and looks at the land and sees   ***)
(*** what the altitude of a certain block is.                             ***)
(****************************************************************************)

FUNCTION altitude_of(x,y:integer):integer;
BEGIN
  IF land_at(x,y)
    THEN
      altitude_of:=world_matrix[x]^[y]^.altitude*100
    ELSE
      altitude_of:=0;
END;

(****************************************************************************)
(*** DISTANCE BETWEEN : Given two adjacent blocks, this function returns  ***)
(*** the distance (in km) between the two blocks.                         ***)
(****************************************************************************)

FUNCTION distance_between(x1,y1,x2,y2:integer):real;
VAR
  temp_distance : real;
BEGIN
  IF y1<>y2
    THEN
      temp_distance:=world_circumference/(world_height*2)
    ELSE
      IF x1<>x2
        THEN
          temp_distance:=world_circumference/(world_width)*(y1/(world_height DIV 2))
        ELSE
          temp_distance:=0.0;
  distance_between:=temp_distance;
END;