{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : TEMPZONE.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This draws on the three lines that go along with     ***)
(***                 temperate zones - the north one, the south one,      ***)
(***                 and the equator.                                     ***)
(*** Input         : None.                                                ***)
(*** Output        : Three lines on graphics screen                       ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE draw_temperate_zone;
VAR
  abs_deviation:integer;
  equator_y:integer;
BEGIN
  abs_deviation:=trunc((temperate_latitude/90)*(world_height/2));
  equator_y:=trunc(wm_y_coord+wm_tick_length+2+(world_height/2))-1;

  draw(wm_x_coord+wm_tick_length+1,
       equator_y-abs_deviation,
       wm_x_coord+1+wm_tick_length+world_width,
       equator_y-abs_deviation,
       wm_white);
  draw(wm_x_coord+wm_tick_length+1,
       equator_y+abs_deviation,
       wm_x_coord+1+wm_tick_length+world_width,
       equator_y+abs_deviation,
       wm_white);
  draw(wm_x_coord+wm_tick_length+1,
       equator_y,
       wm_x_coord+1+wm_tick_length+world_width,
       equator_y,
       wm_white);
END;
