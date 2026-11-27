{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : HELPPRCS.PAS                                         ***)
(*** Author        : Mark Porter & John Stevens                           ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This modules is passed in a screen name, from        ***)
(***                 literally anywhere, and it opens up the right files  ***)
(***                 and shows the user a help screen.                    ***)
(*** Input         : screen_name                                          ***)
(*** Output        : None, except for help screen is displayed            ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE display_help_screen_overlay(screen_name : string50);

  CONST
    dash_line = '--------------------------------------------------------------------------------';
    max_lines                            = 18;
    main_color                           = Yellow;
    main_background                      = Blue;

  TYPE
    screen_item                          = RECORD
                                             text_color   : byte;
                                             text_line    : text_line_type;
                                           END;

    help_page                            = RECORD
                                              screen_data :
                                                 ARRAY [ 1 .. max_lines ] of screen_item;
                                           END;

    help_index                           = RECORD
                                             sequence_title : string50;
                                             start_screen   : integer;
                                             end_screen     : integer;
                                           END;

VAR
  current_page                           : help_page;
  current_index                          : help_index;
  current_screen                         : INTEGER;
  help_file                              : FILE of help_page;
  help_index_file                        : FILE of help_index;
  save_mode                              : main_program_mode_type;

(****************************************************************************)
(*** UPDATE PAGE NUMBER : This procedure takes in a page number and prints***)
(*** it up in the upper-right corner of the screen, along with the max    ***)
(*** number of pages : X of Y                                             ***)
(****************************************************************************)

  PROCEDURE update_page_number(current_page : integer;
                               max_pages    : integer);
  BEGIN
    gotoxy(62,2);
    TextColor(main_color);
    TextBackground(main_background);
    write('Page ',current_page:2,' OF ',max_pages:2);
  END;

(****************************************************************************)
(*** MAKE SCREEN TEMPLATE : This procedure goes out to the screen and puts***)
(*** all of the basic stuff onto the screen so that it does not have to   ***)
(*** be updated every single time a screen is shown.                      ***)
(****************************************************************************)

  PROCEDURE make_screen_template;
  BEGIN
    ClrScr;
    TextColor(main_color);
    TextBackground(main_background);
    gotoxy(1,2);
    ClrEol;
    gotoxy(40-(length(screen_name) DIV 2),2);
    write(screen_name:length(screen_name));
    gotoxy(1,3);
    write(dash_line);
    gotoxy(1,22);
    write(dash_line);
    write('|  PgUp = previous page   |    Home = first page       |  <ESC> = resume play  |');
    write('|  PgDn = next page       |    End  = last page        |  1..9  = Show page #n |');
  END;

(****************************************************************************)
(*** SHOW SCREEN : This takes the current screen and displays it on the   ***)
(*** monitor.                                                             ***)
(****************************************************************************)

  PROCEDURE show_screen;
  VAR
    loop : integer;
  BEGIN
    window(1,4,80,21);
    TextBackground(black);
    ClrScr;
    FOR loop := 1 TO max_lines DO
      BEGIN
        TextColor(current_page.screen_data[loop].text_color );
        gotoxy(1,loop);
        write(current_page.screen_data[loop].text_line);
      END;
    Window(1,1,80,25);
  END;

(****************************************************************************)
(***  HANDLE SCREEN : Given a screen number, this routine goes and puts it***)
(***  up on the screen, including reading and all that other stuff.       ***)
(****************************************************************************)

  PROCEDURE handle_screen;
  BEGIN
    Seek(help_file,current_screen);
    Read(help_file,current_page);
    update_page_number(current_screen-current_index.start_screen+1,
                       current_index.end_screen-current_index.start_screen+1);
    show_screen;
  END;

(****************************************************************************)
(*** NEXT SCREEN, PREV SCREEN, FIRST SCREEN LAST SCREEN, INDEXED SCREEN : ***)
(*** all of these procedures just respond to the keys that the user hits  ***)
(*** in very simple ways.  They all call handle_screen.                   ***)
(****************************************************************************)

  PROCEDURE next_screen;
  BEGIN
    current_screen:=succ(current_screen);
    IF current_screen>current_index.end_screen
      THEN
        BEGIN
          current_screen:=current_index.end_screen;
          beep;
        END
      ELSE
        handle_screen;
  END;

  PROCEDURE prev_screen;
  BEGIN
    current_screen:=pred(current_screen);
    IF current_screen<current_index.start_screen
      THEN
        BEGIN
          current_screen:=current_index.start_screen;
          beep;
        END
      ELSE
        handle_screen;
  END;

  PROCEDURE first_screen;
  BEGIN
    IF current_screen<>current_index.start_screen
      THEN
        BEGIN
          current_screen:=current_index.start_screen;
          handle_screen;
        END
      ELSE
        beep;
  END;

  PROCEDURE last_screen;
  BEGIN
    IF current_screen<>current_index.end_screen
      THEN
        BEGIN
          current_screen:=current_index.end_screen;
          handle_screen;
        END
      ELSE
        beep;
  END;

  PROCEDURE indexed_screen;
  BEGIN
    IF current_screen=current_index.start_screen+(ord(key)-ord('1'))
      THEN
        beep
      ELSE
        BEGIN
          current_screen:=current_index.start_screen+(ord(key)-ord('1'));
          IF current_screen>current_index.end_screen
            THEN
              current_screen:=current_index.end_screen;
          handle_screen;
        END;
  END;

(****************************************************************************)
(*** DISPLAY HELP SCREEN - MAINLINE CODE                                  ***)
(****************************************************************************)

BEGIN
  save_mode:=mode;
  mode:=help_mode;
  ASSIGN( help_file,'HELPFILE.DAT' );
  ASSIGN( help_index_file,'HELPINDX.DAT');
  RESET( help_file );
  RESET( help_index_file );

  WHILE (NOT EOF(help_index_file)) AND
        (current_index.sequence_title<>screen_name) DO
    READ( help_index_file, current_index );

  IF NOT EOF(help_index_file) THEN
    BEGIN
      make_screen_template;
      current_screen := current_index.start_screen;
      handle_screen;

      REPEAT
        key := get_key_with_clock(fkey );
        IF fkey
          THEN
            CASE key OF
              PgUp   : prev_screen;
              PgDn   : next_screen;
              Home   : first_screen;
              Endkey : last_screen;
              else   bad_key;
            END
          ELSE
            CASE key OF
               '1'..'9' : indexed_screen;
               escape : ;
               else   bad_key;
             END;
      UNTIL (key = escape) AND (NOT fkey);
    END;
  CLOSE( help_file );
  CLOSE( help_index_file );
  mode:=save_mode;
  refresh_screen;
END;
