{$U-}
PROGRAM graphics_editor;

CONST
  screen_width = 319;
  screen_height = 199;
  fast_move= 10;
  escape = #27;
  return = #13;
  Larr = #75;
  SHLarr = #52;
  Rarr = #77;
  SHRarr = #54;
  Uarr = #72;
  SHUarr = #56;
  Darr = #80;
  SHDarr = #50;
  F1 = #59;
  F2 = #60;
  F3 = #61;
  F4 = #62;
  F5 = #63;
  screen_size   = 5500;  (* real numbers @ 6 bytes apiece to hold a screen *)

TYPE
  graphics_screen_type = RECORD
                           data              : ARRAY[1..screen_size] OF real;
                           palette_number    : integer;
                           background_number : integer;
                         END;
  mode_type          = (text_mode,graphics_mode);
  text_line_type     = string[80];

VAR
  graphics_file      : FILE OF graphics_screen_type;
  current_screen     : graphics_screen_type;
  mode               : mode_type;
  quit               : boolean;
  key                : char;
  fkey               : boolean;
  cur_x              : integer;
  cur_y              : integer;
  current_color      : integer;
  cursor_mode        : (on,off);
  old_x              : integer;
  old_y              : integer;
  save_color         : integer;
  loop               : integer;
  valid              : boolean;
  abort_action       : boolean;
  draw_mode          : boolean;
{$I GRAPH.P}
{$I GETVALUA.PAS}
{$I GETVALUS.PAS}

PROCEDURE beep;
BEGIN
  write(chr(7));
END;

{$U-}

PROCEDURE take_off_cursor;
BEGIN
  Plot(old_x,old_y,save_color);
  cursor_mode:=off;
END;

PROCEDURE put_on_cursor;
BEGIN
  save_color:=GetDotColor(cur_x,cur_y);
  old_x:=cur_x;
  old_y:=cur_y;
  Plot(cur_x,cur_y,current_color);
  cursor_mode:=on;
END;

PROCEDURE blink_cursor;
BEGIN
  IF cursor_mode=on
    THEN
      BEGIN
        take_off_cursor;
      END
    ELSE
      BEGIN
        put_on_cursor;
      END
END;

PROCEDURE move_up_one;
BEGIN
  IF mode=graphics_mode
    THEN
      BEGIN
        take_off_cursor;
        cur_y:=pred(cur_y);
        IF cur_y<0
          THEN
            cur_y:=screen_height;
        put_on_cursor;
      END
    ELSE
      beep;
END;

PROCEDURE move_down_one;
BEGIN
  IF mode=graphics_mode
    THEN
      BEGIN
        take_off_cursor;
        cur_y:=succ(cur_y);
        IF cur_y>screen_height
          THEN
            cur_y:=0;
        put_on_cursor;
      END
    ELSE
      beep;
END;

PROCEDURE move_left_one;
BEGIN
  IF mode=graphics_mode
    THEN
      BEGIN
        take_off_cursor;
        cur_x:=pred(cur_x);
        IF cur_x<0
          THEN
            cur_x:=screen_width;
        put_on_cursor;
      END
    ELSE
      beep;
END;

PROCEDURE move_right_one;
BEGIN
  IF mode=graphics_mode
    THEN
      BEGIN
        take_off_cursor;
        cur_x:=succ(cur_x);
        IF cur_x>screen_width
          THEN
            cur_x:=0;
        put_on_cursor;
      END
    ELSE
      beep;
END;

PROCEDURE move_up_lots;
BEGIN
  IF mode=graphics_mode
    THEN
      BEGIN
        take_off_cursor;
        cur_y:=cur_y-fast_move;
        IF cur_y<0
          THEN
            cur_y:=screen_height+cur_y;
        put_on_cursor;
      END
    ELSE
      beep;
END;

PROCEDURE move_down_lots;
BEGIN
  IF mode=graphics_mode
    THEN
      BEGIN
        take_off_cursor;
        cur_y:=cur_y+fast_move;
        IF cur_y>screen_height
          THEN
            cur_y:=cur_y-screen_height;
        put_on_cursor;
      END
    ELSE
      beep;
END;

PROCEDURE move_left_lots;
BEGIN
  IF mode=graphics_mode
    THEN
      BEGIN
        take_off_cursor;
        cur_x:=cur_x-fast_move;
        IF cur_x<0
          THEN
            cur_x:=screen_width+cur_x;
        put_on_cursor;
      END
    ELSE
      beep;
END;

PROCEDURE move_right_lots;
BEGIN
  IF mode=graphics_mode
    THEN
      BEGIN
        take_off_cursor;
        cur_x:=cur_x+fast_move;
        IF cur_x>screen_width
          THEN
            cur_x:=cur_x-screen_width;
        put_on_cursor;
      END
    ELSE
      beep;
END;

{$U-}

FUNCTION inkey(VAR Func_key:boolean):char;
VAR
  ch:char;
BEGIN
  func_key:=false;
  ch:=chr(0);
  IF KeyPressed
    THEN
      BEGIN
        read(Kbd,ch);
        IF (ch=escape) and KeyPressed
          THEN
            BEGIN
              Read(Kbd,ch);
              func_key:=true;
            END;
      END;
  inkey:=ch;
END;

FUNCTION get_key(VAR Func_key:boolean):char;
VAR
  ch:char;
  loop:integer;
BEGIN
  REPEAT
    IF mode=graphics_mode
      THEN
        blink_cursor;
    loop:=0;
    REPEAT
      ch:=inkey(Func_key);
      loop:=succ(loop);
    UNTIL (loop>1500) OR (ch<>chr(0));
  UNTIL ch<>chr(0);
  get_key:=ch;
END;

{$U+}

PROCEDURE update_memory_image;
BEGIN
  IF mode=graphics_mode
    THEN
      GetPic(current_screen,1,screen_height,screen_width,1);
END;

PROCEDURE update_screen_image;
BEGIN
  IF mode=graphics_mode
    THEN
      PutPic(current_screen,1,screen_height);
END;

PROCEDURE display_menu;
BEGIN
  update_memory_image;
  mode:=text_mode;
  ClrScr;
  writeln('CGE - Clumsy Graphics Editor - Mark Porter - (C) Copyright 1986');
  writeln;
  writeln('Current x,y        : ',cur_x:3,',',cur_y:3);
  writeln('Current color      : ',current_color:2);
  writeln('Current palette    : ',current_screen.palette_number:2);
  writeln('Current background : ',current_screen.background_number:2);
  write('Mode               : ');
  IF draw_mode
    THEN
      writeln('DRAW')
    ELSE
      writeln('MOVE');
  writeln;
  writeln('Command            Description');
  writeln('----------------   --------------------------------------------------------');
  writeln(' Arrow Keys        Move cursor around on screen');
  writeln(' Shifted Arrows    Move cursor around fast');
  writeln(' S                 Save current picture to disk');
  writeln(' L                 Load a different picture from disk');
  writeln(' P                 Select a Palette');
  writeln(' A..D              Select a color (0=background)');
  writeln(' X                 Select a background color');
  writeln(' M                 Display this menu');
  writeln(' G                 Display graphics screen');
  writeln(' F1                Draw circle at current position');
  writeln(' F2                Fill shape at current position');
  writeln(' Q                 Quit CGE');
END;

PROCEDURE display_graphics;
BEGIN
  CASE current_screen.palette_number OF
    0     : BEGIN
              GraphMode; Palette(0);
            END;
    1     : BEGIN
              GraphMode; Palette(1);
            END;
    2     : BEGIN
              GraphColorMode; Palette(0);
            END;
    3     : BEGIN
              GraphColorMode; Palette(1);
            END;
    4     : BEGIN
              GraphColorMode; Palette(2);
            END;
    5     : BEGIN
              GraphColorMode; Palette(3);
            END;
    6     : BEGIN
              GraphColorMode; Palette(4);
            END;
  END;
  GraphBackground(current_screen.background_number);
  mode:=graphics_mode;
  update_screen_image;
END;

PROCEDURE refresh_screen;
BEGIN
  CASE mode OF
    text_mode      : display_menu;
    graphics_mode  : display_graphics;
  END;
END;

PROCEDURE save_current_picture;
VAR
  file_name : string[30];
BEGIN
  update_memory_image;
  IF mode=text_mode
    THEN
      BEGIN
        ClrScr;
        writeln('Save Current Picture:');
        writeln;
        writeln('Type in the filename, maximum of 30 characters.');
        writeln('In order to abort this option you may type the ');
        writeln('@ character anywhere in the filename.          ');
        writeln;
        write('FILENAME:');
      END;
  readln(file_name);
  IF Pos('@',file_name)=0
    THEN
      BEGIN
        ASSIGN(graphics_file,file_name);
        rewrite(graphics_file);
        write(graphics_file,current_screen);
        close(graphics_file);
      END
    ELSE
      beep;
  refresh_screen;
END;

PROCEDURE load_a_picture;
VAR
  file_name : string[30];
BEGIN
  update_memory_image;
  IF mode=text_mode
    THEN
      BEGIN
        ClrScr;
        writeln('Load a Picture:');
        writeln;
        writeln('Type in the filename, maximum of 30 characters.');
        writeln('In order to abort this option you may type the ');
        writeln('@ character anywhere in the filename.          ');
        writeln;
        write('FILENAME:');
      END;
  readln(file_name);
  IF Pos('@',file_name)=0
    THEN
      BEGIN
        ASSIGN(graphics_file,file_name);
        reset(graphics_file);
        read(graphics_file,current_screen);
        close(graphics_file);
      END
    ELSE
      beep;
  refresh_screen;
END;

PROCEDURE change_palette;
BEGIN
  update_memory_image;
  IF mode=text_mode
    THEN
      BEGIN
        ClrScr;
        writeln('Changing the Palette:');
        writeln;
        writeln('A    GRAPHMODE palette #0');
        writeln('B    GRAPHMODE palette #1');
        writeln('C    GRAPHCOLORMODE palette #0');
        writeln('D    GRAPHCOLORMODE palette #1');
        writeln('E    GRAPHCOLORMODE palette #2');
        writeln('F    GRAPHCOLORMODE palette #3');
        writeln;
        write('Choice?');
      END;
  REPEAT
    key:=get_key(fkey);
    key:=upcase(key);
    IF key IN ['A'..'F']
      THEN
        current_screen.palette_number:=ord(key)-ord('A');
  UNTIL (key IN ['A'..'F','a'..'f','@']) AND (NOT fkey);
  refresh_screen;
END;

PROCEDURE change_background;
BEGIN
  update_memory_image;
  IF mode=text_mode
    THEN
      BEGIN
        ClrScr;
        writeln('Changing the Background:');
        writeln;
        writeln('Type in a number for 0 to 15.');
        writeln(' In hexidecimal : A=10, B=11, C=12, D=13, E=14, F=15');
        write('Choice?');
      END;
  REPEAT
    key:=get_key(fkey);
    key:=upcase(key);
    IF key IN ['A'..'F']
      THEN
        current_screen.background_number:=ord(key)-ord('A')+10
      ELSE
        IF key IN ['0'..'9']
          THEN
            current_screen.background_number:=ord(key)-ord('0');
  UNTIL (key IN ['0'..'9','A'..'F','@']) AND (NOT fkey);
  refresh_screen;
END;

PROCEDURE set_color_to(color_key : char);
BEGIN
  current_color:=ord(upcase(color_key))-ord('A');
END;

PROCEDURE draw_circles;
VAR
  radius : integer;
  save_mode : mode_type;
BEGIN
  update_memory_image;
  IF (mode=text_mode)
    THEN
      BEGIN
        ClrScr;
        writeln('Drawing circles:');
        writeln;
        writeln('Input the circles radius, as an integer.');
        writeln('A radius of 0 will abort this action.');
        writeln;
        write('RADIUS: ');
      END;
  REPEAT
    get_integer(radius);
  UNTIL valid;
  IF radius<>0
    THEN
      BEGIN
        save_mode:=mode;
        mode:=graphics_mode;
        refresh_screen;
        circle(cur_x,cur_y,radius,current_color);
        update_memory_image;
        mode:=save_mode;
      END;
  refresh_screen;
END;

PROCEDURE fill_areas;
VAR
  border_color : integer;
  save_mode    : mode_type;
BEGIN
  update_memory_image;
  IF mode=text_mode
    THEN
      BEGIN
        ClrScr;
        writeln('Filling the current area:');
        writeln;
        writeln('Please type in a border color (to bound the fill).');
        writeln('between 0 and 3 inclusive. Any other entry will');
        writeln('abort this action.');
        writeln;
        write('BORDER COLOR: ');
      END;
  REPEAT
    get_integer(border_color);
  UNTIL valid;
  IF ((border_color>=0) OR
     (border_color<=3)) AND
     (border_color=trunc(border_color))
    THEN
      BEGIN
        save_mode:=mode;
        mode:=graphics_mode;
        refresh_screen;
        fillshape(cur_x,cur_y,current_color,border_color);
        update_memory_image;
        mode:=save_mode;
      END;
  refresh_screen;
END;

BEGIN
  quit:=false;
  cur_x:=screen_width DIV 2;
  cur_y:=screen_height DIV 2;
  current_color:=1;
  GraphMode;
  Palette(0);
  mode:=graphics_mode;
  current_screen.palette_number:=0; (* Graph Mode palette 0 *)
  current_screen.background_number:=0; (* black *)
  update_memory_image;
  cursor_mode:=off;
  save_color:=0;
  old_x:=cur_x;
  old_y:=cur_y;
  take_off_cursor;
  draw_mode:=false;
  display_menu;
  REPEAT
    IF draw_mode
      THEN
        cursor_mode:=off
      ELSE
        cursor_mode:=on;
    key:=get_key(fkey);
    IF (draw_mode) AND (cursor_mode=off)
      THEN
        put_on_cursor
      ELSE
        IF (NOT draw_mode) AND (cursor_mode=on)
          THEN
            take_off_cursor;
    IF fkey
      THEN
        CASE key OF
          Uarr     : move_up_one;
          Darr     : move_down_one;
          Larr     : move_left_one;
          Rarr     : move_right_one;
          F1       : draw_circles;
          F2       : fill_areas;
        END
      ELSE
        CASE key OF
          SHUarr   : move_up_lots;
          SHDarr   : move_down_lots;
          SHLarr   : move_left_lots;
          SHRarr   : move_right_lots;
          's','S'  : Save_current_picture;
          'l','L'  : Load_a_picture;
          'p','P'  : Change_palette;
          'a'..'f',
          'a'..'F' : set_color_to(key);
          'm','M'  : display_menu;
          'g','G'  : display_graphics;
          'X','x'  : change_background;
          'q','Q'  : quit:=true;
          'z','Z'  : BEGIN
                       IF draw_mode
                         THEN
                           draw_mode:=false
                         ELSE
                           draw_mode:=true;
                     END;
        END;
  UNTIL quit;
END.
