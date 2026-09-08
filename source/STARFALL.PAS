{&H STARFALL - MAIN MENU PROGRAM }
{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : STARFALL.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This is the main menu program that runs all of the   ***)
(***                 other programs in the STARFALL system.  For          ***)
(***                 information on the special considerations needed     ***)
(***                 when compiling many programs into one, see the       ***)
(***                 TURBO PASCAL 3.0 Reference Manual, Copyright 1985    ***)
(***                 by BORLAND, International.                           ***)
(*** Input         : None.                                                ***)
(*** Output        : None.                                                ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROGRAM StarFall;

CONST
  screen_size   = 5500;  (* real numbers @ 6 bytes apiece to hold a screen *)
  screen_height = 199;   (* Height of screen in pixels                     *)
  screen_width  = 319;   (* Width of screen in pixels                      *)

  escape = #27;          (* Various ASCII characters needed for HELPPRCS   *)
  PgUp = #73;            (*    "                                 "         *)
  PgDn = #81;            (*    "                                 "         *)
  Home = #71;            (*    "                                 "         *)
  EndKey = #79;          (*    "                                 "         *)

TYPE
  string30               = string[30];
  string50               = string[50];
  text_line_type         = string[80];

  { This variable holds the logo screen that is read in by this program.     }
  graphics_screen_type   = RECORD
                             data              : ARRAY[1..screen_size] OF real;
                             palette_number    : integer;
                             background_number : integer;
                           END;

  { This mode type is defined only to allow this program to interface with   }
  { the HELPPRCS routine later on in the code.                               }
  main_program_mode_type = (world_map,zoom_map,block_text,help_mode);

VAR
  graphics_file      : FILE OF graphics_screen_type;
  { This is where the logo comes in                                          }

  current_screen     : graphics_screen_type;
  { This is where the logo is stored while in memory                         }

  key                : char;
  fkey               : boolean;
  { These two are used in order to keep compatibility with everything else   }

  chain_file         : file;
  { This is the file that is used to chain the other programs in from here   }

  mode               : main_program_mode_type;

  temp_picture       : ARRAY[1..1500] of real;
  { This picture is used to store the starfall title as we zap it around     }

{$I GRAPH.P}
{$I NOISE.PAS}
{$I TITLESNG.PAS}

(****************************************************************************)
(*** REFRESH SCREEN : This is a dummy procedure to keep the HELPPRCS      ***)
(*** files happy, since they always feel the need to fix up the screen    ***)
(*** when they are done.                                                  ***)
(****************************************************************************)

PROCEDURE refresh_screen;
BEGIN
END;

(****************************************************************************)
(*** GET STARFALL TITLE : This takes the title off of its original place  ***)
(*** on the screen and sticks it into the buffer variable 'temp picture', ***)
(*** in preparation for being moved all around.                           ***)
(****************************************************************************)

PROCEDURE get_starfall_title;
BEGIN
  GetPic(temp_picture,40,55,220,15);
END;

(****************************************************************************)
(*** DISPLAY STARFALL TITLE : This procedure puts back the title at what- ***)
(*** ever place on the screen that the program desires - Note that TURBO  ***)
(*** is so 'friendly' as to do wraparound, so don't even try to do off-   ***)
(*** screen shadowing.                                                    ***)
(****************************************************************************)

PROCEDURE display_starfall_title(x_offset,y_offset : integer);
BEGIN
  PutPic(temp_picture,40+x_offset,55+y_offset);
END;

(****************************************************************************)
(*** DISPLAY PICTURE : This procedure displays the main logo screen.      ***)
(****************************************************************************)

PROCEDURE display_picture;
BEGIN
  PutPic(current_screen,1,screen_height);
END;

(****************************************************************************)
(*** DISPLAY GRAPHICS : Stolen directly from GRAFEDIT, this procedure     ***)
(*** looks at the palette number in the screen record and sets up the     ***)
(*** screen accordingly.                                                  ***)
(****************************************************************************)

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
  display_picture;
END;

(****************************************************************************)
(*** LOAD TITLE PICTURE : This procedure opens up the file that the logo  ***)
(*** is supposed to be in. Note that, for V1.0, there is no I/O checking. ***)
(*** It then reads it in and shuts the file again.                        ***)
(****************************************************************************)

PROCEDURE load_title_picture(picture_name : string30);
BEGIN
  ASSIGN(graphics_file,picture_name);
  reset(graphics_file);
  read(graphics_file,current_screen);
  close(graphics_file);
END;

{$I TIMER.PAS}
{$I GETKEY.PAS}

(****************************************************************************)
(*** DO TITLE PAGE GRAPHICS : This procedure brings in the STARFALL       ***)
(*** title, and then moves it around on the screen, while changing        ***)
(*** the colormap, in order to provide a "blinking" picture.              ***)
(****************************************************************************)

PROCEDURE do_title_page_graphics;
VAR
  loop : integer;
BEGIN
  display_graphics;
  get_starfall_title;
  ColorTable(3,3,3,3);
  display_starfall_title(0,0);
  FOR loop:=1 TO 50 DO
    BEGIN
      ColorTable(0,1,3,2);
      delay(loop);
      display_starfall_title(trunc((50-loop)*1.75),trunc((50-loop)*2.5));
      ColorTable(0,1,2,3);
      delay(loop);
      display_starfall_title(trunc((50-loop)*1.75),trunc((50-loop)*2.5));
    END;
END;

(****************************************************************************)
(*** DISPLAY TITLE PAGE : This loads in the logo from disk, zaps the title***)
(*** around on the screen for a bit, and the finally settles down and     ***)
(*** gives the user a menu.                                               ***)
(****************************************************************************)

PROCEDURE display_title_page;
BEGIN
  load_title_picture('STARFALL.PIC');
  do_title_page_graphics;
  TextColor(2);
  gotoxy(13,12);
  write('                        ');
  gotoxy(13,13);
  write('   STARFALL MAIN MENU   ');
  gotoxy(13,14);
  write('                        ');
  gotoxy(13,15);
  write('   I)nstructions        ');
  gotoxy(13,16);
  write('   S)tart game          ');
  gotoxy(13,17);
  write('   C)reate a new world  ');
  gotoxy(13,18);
  write('   E)xamine score file  ');
  gotoxy(13,19);
  write('   Q)uit STARFALL       ');
  gotoxy(13,20);
  write('                        ');
  gotoxy(13,21);
  write('   Choice ?             ');
  gotoxy(13,22);
  write('                        ');
END;

{$I HELPPRCS.PAS}

(****************************************************************************)
(*** INSTRUCTIONS : This procedure goes out to the help file and brings   ***)
(*** in this very large help screen (about 20 screen pages) and lets      ***)
(*** the user play with it.                                               ***)
(****************************************************************************)

PROCEDURE instructions;
BEGIN
  display_help_screen_overlay('Introduction to STARFALL');
  display_graphics;
END;

{&H STARFALL - MAINLINE CODE }
{&P}
(****************************************************************************)
(*** STARFALL - MAINLINE CODE                                             ***)
(****************************************************************************)

BEGIN
  REPEAT
    display_title_page;
    play_title_song;
    key:=get_key(fkey);

    CASE key OF
      'i','I'     : instructions;
      's','S'     : BEGIN
                      ASSIGN(chain_file,'PLAYGAME.COM');
                      EXECUTE(chain_file);
                    END;
      'c','C'     : BEGIN
                      ASSIGN(chain_file,'MAKEWRLD.COM');
                      EXECUTE(chain_file);
                    END;
      'e','E'     : BEGIN
                      ASSIGN(chain_file,'SHOSCORE.COM');
                      EXECUTE(chain_file);
                    END;
      'q','Q'     : ;
    END;
  UNTIL key IN ['q','Q'];
  ClrScr;
  writeln('STARFALL simulation complete.');
  writeln;
END.