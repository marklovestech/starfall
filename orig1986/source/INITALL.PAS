{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : INITALL.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Initialize everything to start out PLAYGAME          ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE initialize_the_place;
BEGIN
  block_mode_explanation_color:=block_mode_explanation_color+Blink;
  world_file_name:='WORLD.DAT';
  world_name:='NEW EDEN';
  Randomize;
  pattern(solid_area_pattern);
  new(world_picture);
  new(zoom_map_picture);
  initialize_world_matrix;
  initialize_surface_resource_matrix;
  read_resource_file;
  initialize_smallest_game_time_increment;
  initialize_human_resource_list;
  initialize_pending_list;
  initialize_log_list;

  quit:=false;
  clear_time(game_time);
END;