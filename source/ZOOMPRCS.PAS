{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : ZOOMPRCS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures handle all the stuff on the zoom map***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE fill_zoom_map_box(box_x,box_y,color:integer);
BEGIN
  FillPattern(box_x*zoom_map_box_width+zoom_map_left,
              box_y*zoom_map_box_height+zoom_map_top,
              (box_x+1)*zoom_map_box_width+zoom_map_left-2,
              (box_y+1)*zoom_map_box_height+zoom_map_top-2,
              color);
END;

PROCEDURE draw_zoom_map_element(block_x,block_y,
                                center_x_offset,center_y_offset:integer);
VAR
  block_color:integer;
BEGIN

  IF block_x<1
    THEN
      block_x:=block_x+world_width (* x axis does wrap around *)
    ELSE
      IF block_x>world_width
        THEN
          block_x:=block_x-world_width; (* both ways, even! *)

  block_color:=wm_blue; (* default color is water *)

  IF (block_y<1) OR (block_y>world_height)
    THEN
      block_color:=wm_white
    ELSE
      IF land_at(block_x,block_y)
        THEN
          IF ((block_x=base_block_x) AND (block_y=base_block_y))
            THEN
              BEGIN
                block_color:=zoom_map_base_color;
                IF zoom_map_base_color=wm_white
                  THEN
                    zoom_map_base_color:=wm_red
                  ELSE
                    zoom_map_base_color:=wm_white;
              END
            ELSE
              IF (present_in_human_resource_list(block_x,block_y))
                THEN
                  block_color:=wm_red
                ELSE
                  block_color:=wm_green;

  fill_zoom_map_box(center_x_offset+(sector_zoom_size DIV 2),
                    center_y_offset+(sector_zoom_size DIV 2),
                    block_color);
END;

PROCEDURE draw_zoom_map_row(block_y:integer);
VAR
  block_x:integer;
BEGIN
  FOR block_x:=current_block_x-(sector_zoom_size DIV 2)
            TO current_block_x+(sector_zoom_size DIV 2) DO
    BEGIN
      draw_zoom_map_element(block_x,block_y,
                            block_x-current_block_x,
                            block_y-current_block_y);
    END;
END;

FUNCTION block_on_zoom_map(block_x,block_y:integer):boolean;
BEGIN
  IF (block_x>=(current_block_x-(sector_zoom_size DIV 2))) AND
     (block_x<=(current_block_x+(sector_zoom_size DIV 2))) AND
     (block_y>=(current_block_y-(sector_zoom_size DIV 2))) AND
     (block_y<=(current_block_y+(sector_zoom_size DIV 2)))
    THEN
      block_on_zoom_map:=true
    ELSE
      block_on_zoom_map:=false;
END;

PROCEDURE draw_base_block_on_zoom_map;
BEGIN
  IF block_on_zoom_map(base_block_x,base_block_y)
    THEN
      BEGIN
        draw_zoom_map_element(base_block_x,base_block_y,
                              base_block_x-current_block_x,
                              base_block_y-current_block_y);
      END;
END;

PROCEDURE draw_zoom_map_column(block_x:integer);
VAR
  block_y:integer;
BEGIN
  FOR block_y:=current_block_y-(sector_zoom_size DIV 2)
            TO current_block_y+(sector_zoom_size DIV 2) DO
    BEGIN
      draw_zoom_map_element(block_x,block_y,
                            block_x-current_block_x,
                            block_y-current_block_y);
    END;
END;

PROCEDURE pickup_west_part_of_zoom_map;
BEGIN
  GetPic(zoom_map_picture^,
         zoom_map_left,
         zoom_map_bottom-2,
         zoom_map_right-zoom_map_box_width-2,
         zoom_map_top);
END;

PROCEDURE pickup_east_part_of_zoom_map;
BEGIN
  GetPic(zoom_map_picture^,
         zoom_map_left+zoom_map_box_width,
         zoom_map_bottom-2,
         zoom_map_right-2,
         zoom_map_top);
END;

PROCEDURE pickup_north_part_of_zoom_map;
BEGIN
  GetPic(zoom_map_picture^,
         zoom_map_left,
         zoom_map_bottom-zoom_map_box_height-2,
         zoom_map_right-2,
         zoom_map_top);
END;

PROCEDURE pickup_south_part_of_zoom_map;
BEGIN
  GetPic(zoom_map_picture^,
         zoom_map_left,
         zoom_map_bottom-2,
         zoom_map_right-2,
         zoom_map_top+zoom_map_box_height);
END;

PROCEDURE setdown_west_part_of_zoom_map;
BEGIN
  PutPic(zoom_map_picture^,
         zoom_map_left+zoom_map_box_width,
         zoom_map_bottom-2);
END;

PROCEDURE setdown_east_part_of_zoom_map;
BEGIN
  PutPic(zoom_map_picture^,
         zoom_map_left,
         zoom_map_bottom-2);
END;

PROCEDURE setdown_north_part_of_zoom_map;
BEGIN
  PutPic(zoom_map_picture^,
         zoom_map_left,
         zoom_map_bottom-2);
END;

PROCEDURE setdown_south_part_of_zoom_map;
BEGIN
  PutPic(zoom_map_picture^,
         zoom_map_left,
         zoom_map_bottom-zoom_map_box_height-2);
END;

PROCEDURE initialize_zoom_map_grid;
VAR
  x_loop : integer;
  y_loop : integer;
BEGIN
  draw_box(zoom_map_left-1,zoom_map_top-1,
           zoom_map_right-1,zoom_map_bottom-1,
           wm_red);
  draw_box(zoom_map_left-2,zoom_map_top-2,
           zoom_map_right,zoom_map_bottom,
           wm_blue);
  draw_box(zoom_map_left-3,zoom_map_top-3,
           zoom_map_right+1,zoom_map_bottom+1,
           wm_green);
  draw_box(zoom_map_left-4,zoom_map_top-4,
           zoom_map_right+2,zoom_map_bottom+2,
           wm_white);

  FOR x_loop:=current_block_x-(sector_zoom_size DIV 2)
           TO current_block_x+(sector_zoom_size DIV 2) DO
    draw_zoom_map_column(x_loop);
END;

PROCEDURE place_zoom_map_centerpiece;
BEGIN
  draw_box(zoom_map_left+(sector_zoom_size DIV 2)*zoom_map_box_width-1,
           zoom_map_top+(sector_zoom_size DIV 2)*zoom_map_box_height-1,
           zoom_map_left+(1+(sector_zoom_size DIV 2))*zoom_map_box_width-1,
           zoom_map_top+(1+(sector_zoom_size DIV 2))*zoom_map_box_height-1,
           wm_red);
END;

PROCEDURE remove_zoom_map_centerpiece;
BEGIN
  draw_box(zoom_map_left+(sector_zoom_size DIV 2)*zoom_map_box_width-1,
           zoom_map_top+(sector_zoom_size DIV 2)*zoom_map_box_height-1,
           zoom_map_left+(1+(sector_zoom_size DIV 2))*zoom_map_box_width-1,
           zoom_map_top+(1+(sector_zoom_size DIV 2))*zoom_map_box_height-1,
           wm_white);
END;

PROCEDURE draw_zoom_map_text;
BEGIN
  TextColor(wm_red);
  TextBackground(wm_blue);
  gotoxy(3,2); writeln('   Block       :                   ');
  gotoxy(3,3); writeln('   Longitude   :                   ');
  gotoxy(3,4); writeln('   Latitude    :                   ');
  gotoxy(3,5); writeln('   Altitude    :                   ');
END;

PROCEDURE draw_zoom_map_block_info;
BEGIN
  TextColor(wm_red);
  TextBackground(wm_blue);
  gotoxy(20,2); writeln(current_block_x:3,',',current_block_y:3);
  gotoxy(20,3); write_longitude_for(current_block_x);
  gotoxy(20,4); write_latitude_for(current_block_y);
  gotoxy(20,5); writeln(altitude_of(current_block_x,current_block_y):5,' m');
  gotoxy(32,2);
  IF (current_block_x=base_block_x) AND (current_block_y=base_block_y)
    THEN
      write('BASE')
    ELSE
      write('    ');
END;

FUNCTION block_ok_for_zoom(block_x,block_y:integer):boolean;
VAR
  temp_result : boolean;
BEGIN
  temp_result:=true;
  IF water_at(block_x,block_y)
    THEN
      temp_result:=false
    ELSE
      IF NOT human_resources_at(block_x,block_y)
        THEN
          temp_result:=false;
  block_ok_for_zoom:=temp_result;
END;

PROCEDURE display_zoom_map;
VAR
  loop : integer;
BEGIN
  GraphMode;
  Palette(wm_palette);
  GraphBackground(wm_background);
  FillScreen(wm_red);
  zoom_map_base_color:=wm_white;

  FOR loop:=1 to trunc((zoom_map_right-zoom_map_left)/zoom_map_box_width-1) DO
    BEGIN
      draw(zoom_map_left+loop*zoom_map_box_width-1,zoom_map_top,
           zoom_map_left+loop*zoom_map_box_width-1,zoom_map_bottom-2,
           wm_white);
    END;

  FOR loop:=1 to trunc((zoom_map_bottom-zoom_map_top)/zoom_map_box_height-1) DO
    BEGIN
      draw(zoom_map_left,zoom_map_top+loop*zoom_map_box_height-1,
           zoom_map_right-2,zoom_map_top+loop*zoom_map_box_height-1,
           wm_white);
    END;

  initialize_zoom_map_grid;
  place_zoom_map_centerpiece;
  draw_zoom_map_text;
  draw_zoom_map_block_info;
END;
