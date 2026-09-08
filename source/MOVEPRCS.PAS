{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : MOVEPRCS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These are the procedures that move the various       ***)
(***                 cursors around on the world and zoom maps.           ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)


PROCEDURE zoom_map_move_east;
BEGIN
  increment_block_x(current_block_x);
  draw_zoom_map_block_info;
  remove_zoom_map_centerpiece;
  pickup_east_part_of_zoom_map;
  setdown_east_part_of_zoom_map;
  place_zoom_map_centerpiece;
  draw_zoom_map_column(current_block_x+(sector_zoom_size DIV 2));
END;

PROCEDURE zoom_map_move_west;
BEGIN
  decrement_block_x(current_block_x);
  draw_zoom_map_block_info;
  remove_zoom_map_centerpiece;
  pickup_west_part_of_zoom_map;
  setdown_west_part_of_zoom_map;
  place_zoom_map_centerpiece;
  draw_zoom_map_column(current_block_x-(sector_zoom_size DIV 2));
END;

PROCEDURE zoom_map_move_north;
BEGIN
  IF current_block_y>1
    THEN
      BEGIN
        decrement_block_y(current_block_y);
        draw_zoom_map_block_info;
        remove_zoom_map_centerpiece;
        pickup_north_part_of_zoom_map;
        setdown_north_part_of_zoom_map;
        place_zoom_map_centerpiece;
        draw_zoom_map_row(current_block_y-(sector_zoom_size DIV 2));
      END
    ELSE
      beep;
END;

PROCEDURE zoom_map_move_south;
BEGIN
  IF current_block_y<world_height
    THEN
      BEGIN
        increment_block_y(current_block_y);
        draw_zoom_map_block_info;
        remove_zoom_map_centerpiece;
        pickup_south_part_of_zoom_map;
        setdown_south_part_of_zoom_map;
        place_zoom_map_centerpiece;
        draw_zoom_map_row(current_block_y+(sector_zoom_size DIV 2));
      END
    ELSE
      beep;
END;

PROCEDURE world_map_move_east;
BEGIN
  remove_world_map_cursor;
  increment_block_x(current_block_x);
  draw_world_map_info;
  place_world_map_cursor;
END;

PROCEDURE world_map_move_west;
BEGIN
  remove_world_map_cursor;
  decrement_block_x(current_block_x);
  draw_world_map_info;
  place_world_map_cursor;
END;

PROCEDURE world_map_move_north;
BEGIN
  remove_world_map_cursor;
  decrement_block_y(current_block_y);
  draw_world_map_info;
  place_world_map_cursor;
END;

PROCEDURE world_map_move_south;
BEGIN
  remove_world_map_cursor;
  increment_block_y(current_block_y);
  draw_world_map_info;
  place_world_map_cursor;
END;

PROCEDURE world_map_move_east_fast;
VAR
  loop : integer;
BEGIN
  remove_world_map_cursor;
  FOR loop:=1 to world_map_fast_speed DO
    increment_block_x(current_block_x);
  draw_world_map_info;
  place_world_map_cursor;
END;

PROCEDURE world_map_move_west_fast;
VAR
  loop : integer;
BEGIN
  remove_world_map_cursor;
  FOR loop:=1 to world_map_fast_speed DO
    decrement_block_x(current_block_x);
  draw_world_map_info;
  place_world_map_cursor;
END;

PROCEDURE world_map_move_north_fast;
VAR
  loop : integer;
BEGIN
  remove_world_map_cursor;
  FOR loop:=1 to world_map_fast_speed DO
    decrement_block_y(current_block_y);
  draw_world_map_info;
  place_world_map_cursor;
END;

PROCEDURE world_map_move_south_fast;
VAR
  loop : integer;
BEGIN
  remove_world_map_cursor;
  FOR loop:=1 to world_map_fast_speed DO
    increment_block_y(current_block_y);
  draw_world_map_info;
  place_world_map_cursor;
END;
