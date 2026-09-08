PROGRAM test_help;

TYPE string30=string[30];
VAR
  fkey:boolean;

PROCEDURE beep;
BEGIN
  write(chr(7));
END;

PROCEDURE display_help_screen( screen_name : string30 );

CONST
        max_lines = 22;
        Pg_Up = #73;
        Pg_Dn = #81;
        Escape = #27;
        Up_String = ' <pg up> : previous screen ';
        Dn_String = ' <pg dn> : next screen ';
        Esc_String = ' <esc> : resume play ';
        Title_Color = White;
        Title_background = Blue;
        Prompt_color = Yellow;
        Prompt_background = Blue;

TYPE
        text_line_type = string[ 80 ];

        screen_item = RECORD
                        text_color : byte;
                        text_line : text_line_type;
                      END;

        help_page = RECORD
                        screen_data : ARRAY [ 1 .. max_lines ] of screen_item;
                    END;

        help_index = RECORD
                        sequence_title : string30;
                        start_screen : byte;
                        end_screen : byte;
                     END;

VAR
        i : INTEGER;

        matched : BOOLEAN;

        help_file : FILE of help_page;

        help_index_file : FILE of help_index;

        current_page : help_page;

        current_index : help_index;

        current_screen : INTEGER;

        response : CHAR;

        PROCEDURE show_screen;
        BEGIN
                CLRSCR;
                TextColor( title_color );
                TextBackground ( title_background);
                WRITELN( screen_name, '  #',
                        current_screen - current_index.start_screen + 1 );
                textbackground(black);
                FOR i := 1 TO max_lines DO
                    BEGIN
                        TextColor( current_page.screen_data[i].text_color );
                        IF length(current_page.screen_data[i].text_line)=80
                          THEN
                            write(current_page.screen_data[i].text_line)
                          ELSE
                             WRITELN ( current_page.screen_data[i].text_line );
                    END;

                TextColor( prompt_color );
                TextBackground(prompt_background);
                gotoxy(1,24);
                IF current_screen = current_index.start_screen THEN
                        WRITE( dn_string, '|', esc_string )
                ELSE IF current_screen = current_index.end_screen THEN
                        WRITE( up_string, '|', esc_string )
                ELSE
                        WRITE( dn_string, '|', up_string, '|', esc_string );
           TextBackground(Black);
        END;

        FUNCTION inkey( VAR Func_key : BOOLEAN ) : CHAR;
        VAR
                ch : CHAR;
        BEGIN
                func_key := false;
                ch := chr( 0 );
                IF KeyPressed THEN
                    BEGIN
                        READ( kbd, ch );
                        IF ( ch = escape ) and KeyPressed THEN
                            BEGIN
                                READ( kbd, ch );
                                func_key := true;
                            END;
                    END;
                inkey := ch;
        END;

BEGIN

        ASSIGN( help_file, 'HELPFILE.DAT' );
        ASSIGN( help_index_file, 'HELPINDX.DAT');
        RESET( help_file );
        RESET( help_index_file );

        WHILE (NOT EOF(help_index_file)) AND
              (current_index.sequence_title<>screen_name) DO
          READ( help_index_file, current_index );

        IF NOT EOF(help_index_file) THEN
            BEGIN

                SEEK( help_file, current_index.start_screen );
                current_screen := current_index.start_screen;
                READ( help_file, current_page );
                show_screen;

                REPEAT
                        response := inkey( fkey );

                        IF (( current_screen = current_index.start_screen )
                           AND ( response = Pg_Up )) OR (( response = Pg_Dn )
                           AND ( current_screen = current_index.end_screen ))
                        THEN
                                beep

                        ELSE IF response = Pg_Dn THEN
                            BEGIN
                                current_screen := current_screen + 1;
                                SEEK( help_file, current_screen );
                                READ( help_file, current_page );
                                show_screen;
                            END

                        ELSE IF response = Pg_Up THEN
                            BEGIN
                                current_screen := current_screen - 1;
                                SEEK( help_file, current_screen );
                                READ( help_file, current_page );
                                show_screen;
                            END;

                UNTIL response = Escape;
            END

        ELSE
            BEGIN
                WRITELN( 'No Help Screen on ', screen_name, ' found.' );
                WRITELN;
                WRITELN( 'Help screens are available on the following:' );
                WHILE NOT EOF( help_index_file ) DO
                    BEGIN
                        READ( help_index_file, current_index );
                        WRITELN( current_index.sequence_title );
                    END;
                WRITE( 'Which of these do you wish to view?' );
                READLN( screen_name );
                WHILE ( NOT EOF( help_index_file ) ) AND
                        ( screen_name <> current_index.sequence_title ) DO
                        READ( help_index_file, current_index );
                IF current_index.sequence_title = screen_name THEN
                        display_help_screen( screen_name );
            END;
        CLOSE( help_file );
        CLOSE( help_index_file );
END;

BEGIN
  display_help_screen('Exploring help screen.');
END.