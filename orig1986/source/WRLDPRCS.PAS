{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : WRLDPRCS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These are all procedures to handle stuff on the      ***)
(***                 world map.                                           ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)


PROCEDURE remove_world_map_cursor;
BEGIN
  GraphWindow(wm_left,wm_top,wm_left+world_width+1,wm_top+world_height+1);
  PutPic(world_map_cursor_save,
         int_max(current_block_x-(sector_zoom_size DIV 2),0),
         int_min(current_block_y+(sector_zoom_size DIV 2),world_height+1));
  GraphWindow(0,0,319,199);
END;

PROCEDURE place_world_map_cursor;
BEGIN
  GraphWindow(wm_left,wm_top,wm_left+world_width+1,wm_top+world_height+1);
  GetPic(world_map_cursor_save,
         int_max(current_block_x-(sector_zoom_size DIV 2),0),
         int_min(current_block_y+(sector_zoom_size DIV 2),world_height+1),
         int_min(current_block_x+(sector_zoom_size DIV 2),world_width+1),
         int_max(current_block_y-(sector_zoom_size DIV 2),0));
  (* Now, draw a box here *)
  draw_box(current_block_x-(sector_zoom_size DIV 2),
           current_block_y+(sector_zoom_size DIV 2),
           current_block_x+(sector_zoom_size DIV 2),
           current_block_y-(sector_zoom_size DIV 2),
           wm_cursor_color);
  plot(current_block_x,
       current_block_y,
       wm_cursor_dot_color);
  GraphWindow(0,0,319,199);
END;

PROCEDURE increment_block_x(VAR block : integer);
BEGIN
  block:=block+1;
  IF block>world_width
    THEN
      block:=1;
END;

PROCEDURE decrement_block_x(VAR block : integer);
BEGIN
  block:=block-1;
  IF block<1
    THEN
      block:=world_width;
END;

PROCEDURE increment_block_y(VAR block : integer);
BEGIN
  block:=block+1;
  IF block>world_height
    THEN
      BEGIN
        block:=world_height;
        beep;
      END;
END;

PROCEDURE decrement_block_y(VAR block : integer);
BEGIN
  block:=block-1;
  IF block<1
    THEN
      BEGIN
        block:=1;
        beep;
      END;
END;

PROCEDURE draw_world_map_text;
BEGIN
  TextColor(wm_red);
  TextBackground(wm_blue);
  gotoxy(3,2); writeln('   Block      :                     ');
  gotoxy(3,3); writeln('   Longitude  :                     ');
  gotoxy(3,4); writeln('   Latitude   :                     ');
END;

PROCEDURE draw_world_map_info;
BEGIN
  TextColor(wm_red);
  TextBackground(wm_blue);
  gotoxy(20,2); writeln(current_block_x:3,',',current_block_y:3);
  gotoxy(20,3); write_longitude_for(current_block_x);
  gotoxy(20,4); write_latitude_for(current_block_y);
  gotoxy(32,2);
  IF (current_block_x=base_block_x) AND (current_block_y=base_block_y)
    THEN
      write('BASE')
    ELSE
      write('    ');
END;

PROCEDURE draw_human_resources_on_world_map;
VAR
  temp_ptr : human_resource_list_ptr;
BEGIN
  temp_ptr:=human_resource_list_root;
  WHILE temp_ptr<>NIL DO
    BEGIN
      draw_on_world_map(temp_ptr^.x,temp_ptr^.y,wm_red);
      temp_ptr:=temp_ptr^.next;
    END;
END;

PROCEDURE display_world_map;
BEGIN
  setup_world_map_graphics;
  restore_world_picture;
  draw_temperate_zone;
  draw_human_resources_on_world_map;
  place_world_map_cursor;
  draw_world_map_text;
  draw_world_map_info;
END;
