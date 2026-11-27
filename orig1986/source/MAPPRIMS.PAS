{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : MAPPRIMS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures let us draw on and look at the      ***)
(***                 world map.                                           ***)
(*** Input         : An X,Y coordinate, and a COLOR for DRAW.             ***)
(*** Output        : GET MAP VALUE returns a color number                 ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE draw_on_world_map(x,y,color:integer);
BEGIN
  plot(wm_x_coord+1+wm_tick_length+x,
       wm_y_coord+1+wm_tick_length+y,color);
END;

FUNCTION get_map_value(x,y:integer):integer;
BEGIN
  get_map_value:=GetDotColor(wm_x_coord+1+wm_tick_length+x,
                             wm_y_coord+1+wm_tick_length+y);
END;
