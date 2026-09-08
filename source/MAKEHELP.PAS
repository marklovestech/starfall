{&H MAKEHELP - Converts text file to Pascal typed Help file }
{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : MAKEHELP.PAS                                         ***)
(*** Author        : John Stevens                                         ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This program takes in a text file (HELPSRCE.TXT) and ***)
(***                 converts it to a typed, index random access file     ***)
(***                 readable by PLAYGAME and STARFALL.  Note that the    ***)
(***                 file is indexed by the file HELPINDX.DAT. The actual ***)
(***                 output comes out in HELPFILE.DAT.  The text file     ***)
(***                 may have control characters in it such as 'H',       ***)
(***                 which means to start a new sequence, 'L', which      ***)
(***                 means that this line is the last line of the current ***)
(***                 help sequence, and 'P' which means that this line is ***)
(***                 the last line of this screen page.                   ***)
(***                 In addition, the package will allow a textcolor      ***)
(***                 from 0..15 to be put in columns 2..3.  This enables  ***)
(***                 the designer of the help screens to have each line a ***)
(***                 different color - a fun thing to do.                 ***)
(*** Input         : HELPSRCE.TXT                                         ***)
(*** Output        : HELPFILE.DAT, HELPINDX.DAT                           ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROGRAM make_help_screen( INPUT, OUTPUT );

CONST
  max_lines        = 18;            (* 18 lines on a help screen *)

TYPE
  text_type        = string[80];
  string50         = string[50];

  screen_item      = RECORD
                       text_color     : byte;
                       text_line      : text_type;
                     END;

   help_page       = RECORD
                       screen_data    : ARRAY [ 1 .. max_lines ]
                                          OF screen_item;
                     END;

   help_index      = RECORD
                       sequence_title : string50;
                       start_screen   : integer;
                       end_screen     : integer;
                     END;

VAR
  i, j, k, l                     : INTEGER;            (* FORTRAN programming variables *)
  help_file                      : FILE of help_page;  (* HELPFILE.DAT                  *)
  help_index_file                : FILE of help_index; (* HELPINDX.DAT                  *)
  current_page                   : help_page;
  current_index                  : help_index;
  current_screen                 : integer;
  in_line                        : string[88];         (* the current input line from HELPSRCE.TXT *)
  help_source                    : TEXT;               (* HELPSRCE.TXT *)
  last_text_color                : byte;
  current_text_color             : string[2];          (* The string representation of the color *)

{&H MAKEHELP - PROCEDURE DIVISION }
{&P}
(****************************************************************************)
(*** COLOR OF TEXT : This procedure looks at columns 2 and 3 of in_line   ***)
(*** and tries to figure out just what color it all is.  If it cannot     ***)
(*** find a valid color on the line, it assigns the current line's color  ***)
(*** to be that of the last line with a valid color.  If the first line   ***)
(*** of a file is invalid, the color is defined to be WHITE (color 15.)   ***)
(****************************************************************************)

FUNCTION color_of_text : BYTE;
VAR
  text_color : integer;
BEGIN
  text_color := 10 * ( ORD( current_text_color[1] ) - ORD( '0' ) )
                     + ORD( current_text_color[2] ) - ORD( '0' );
  IF ( text_color <= 15 ) AND
     ( text_color >= 0 )
    THEN
      BEGIN
        color_of_text := text_color;
        TextColor(text_color);
        last_text_color:=text_color;
      END
    ELSE
      color_of_text := last_text_color;
END;

(****************************************************************************)
(*** ASSIGN CURRENT LINE : This procedure goes and puts the correct data  ***)
(*** from the current line of the input file out to the right place in    ***)
(*** the new file.                                                        ***)
(****************************************************************************)

PROCEDURE assign_current_line;
BEGIN
  current_page.screen_data[ i ].text_line:=Copy(in_line,9,length(in_line)-8);
  current_page.screen_data[ i ].text_color:= color_of_text;
  TextColor(current_page.screen_data[i].text_color);
  write(i:2);
  writeln(current_page.screen_data[i].text_line);
END;

(****************************************************************************)
(*** DISPLAY NEXT PAGE - While the file is being converted, MAKEHELP is   ***)
(*** courteous enough to show you what it is putting in the file.  This   ***)
(*** is the procedure that starts the next page on the screen at the      ***)
(*** same time as it starts the next page in the file.                    ***)
(****************************************************************************)

PROCEDURE display_next_page;
BEGIN
  ClrScr;
  writeln('TITLE: ',current_index.sequence_title);
  writeln('-------------------------------------');
END;

(****************************************************************************)
(*** OPEN FILES : This procedure goes out and opens up all 3 files needed ***)
(*** for MAKEHELP.  Note that there is no I/O checking.  This is a devel- ***)
(*** ment program and anyone using it should be smart, not stupid.  In    ***)
(*** other words, the user should never be let loose near this program.   ***)
(****************************************************************************)

PROCEDURE open_files;
BEGIN
  ASSIGN( help_file, 'HELPFILE.DAT' );
  ASSIGN( help_index_file, 'HELPINDX.DAT');
  ASSIGN( help_source, 'HELPSRCE.TXT' );
  RESET( help_source );
  REWRITE( help_file );
  REWRITE( help_index_file );
END;

(****************************************************************************)
(*** PROCESS FILE - This process actually does all the work of the        ***)
(*** program. It goes out and gets each line and interprets it according  ***)
(*** to its general mood at the moment and to some extent according to    ***)
(*** the directives in the file.                                          ***)
(****************************************************************************)

PROCEDURE process_file;
BEGIN
  WHILE NOT EOF( help_source ) DO
    BEGIN
        i := 1;
        FOR j := 1 TO max_lines DO
          current_page.screen_data[j].text_line:='';

        WHILE ( i <= max_lines ) AND NOT EOF( help_source ) DO
            BEGIN
                READLN( help_source, in_line );
                current_text_color[1] := in_line[2];
                current_text_color[2] := in_line[3];
                IF in_line[ 1 ] = 'H' THEN
                    BEGIN
                      current_index.sequence_title:=Copy(in_line,9,length(in_line)-8);
                        current_index.start_screen := current_screen;
                        display_next_page;
                      i:=0;
                    END
                ELSE IF in_line[ 1 ] = 'L' THEN
                    BEGIN
                        assign_current_line;
                        i := max_lines;
                        current_index.end_screen := current_screen;
                        WRITE( help_index_file, current_index );
                    END
                ELSE IF in_line[ 1 ] = 'P' THEN
                    BEGIN
                       assign_current_line;
                       i:=max_lines;
                       writeln('-------------------------------------PAGE BREAK--------------------------');
                    END
                ELSE
                  BEGIN
                    assign_current_line;
                  END;
              i:= i + 1;
            END;
        WRITE( help_file, current_page );
        current_screen :=succ(current_screen);
    END;
END;

(****************************************************************************)
(*** CLOSE FILES : Executed as the last thing in the program it closes up ***)
(*** all of our neat little new files.                                    ***)
(****************************************************************************)

PROCEDURE close_files;
BEGIN
  close(help_file);
  close(help_index_file);
  close(help_source);
END;

{&H MAKEHELP - MAINLINE CODE }
{&P}
(****************************************************************************)
(*** MAKEHELP - MAINLINE CODE                                             ***)
(****************************************************************************)

BEGIN
  open_files;
  current_screen := 0;
  last_text_color := 15; (* start out at white *)
  process_file;
  close_files;
END.
