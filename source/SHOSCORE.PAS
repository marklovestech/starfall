{&H SHOSCORE - A program that displays the current score file }
{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : SHOSCORE.PAS                                         ***)
(*** Author        : Susan Gager                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Basically, this program allows the user control over ***)
(***                 what is in the current score file.  This program is  ***)
(***                 normally chained from the STARFALL main menu, and    ***)
(***                 it chains back to it when it is done.                ***)
(*** Input         : SCORFILE.DAT, user input of return or C              ***)
(*** Output        : If user presses C, then the output is to clear out   ***)
(***                 the score file.  If return is pressed, then no       ***)
(***                 besides the display exists.                          ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROGRAM score_routine(input,output);

CONST
    NUM_OF_SCORES = 15;
    return        = #13;

TYPE
    STRING30 = STRING[30];

    SCORE_RECORD = RECORD
                     NAME   : STRING30;
                     WORLD  : STRING30;
                     SCORE  : REAL;
                   END;

VAR
    SCORE_FILE     :  FILE OF SCORE_RECORD;
    CURRENT_SCORE  :  SCORE_RECORD;
    name           : string30;
    world          : string30;
    score          : real;
    ch             : char;
    main_program   : file;

{&H SHOSCORE - PROCEDURE DIVISION }
{&P}
(****************************************************************************)
(*** SHOSCORE - PROCEDURE DIVISION                                        ***)
(****************************************************************************)

PROCEDURE OPEN_SCORE_FILE_FOR_READ;

   BEGIN

     ASSIGN(SCORE_FILE,'SCORFILE.DAT');

     RESET(SCORE_FILE);

   END;


PROCEDURE CLOSE_SCORE_FILE;

   BEGIN

     CLOSE(SCORE_FILE);

   END;
(****************************************************************************)
(*** CLEAR OUT SCORE FILE : This procedure allows the user to clear the   ***)
(*** score file to blanks.  It has been found that especially bad players ***)
(*** tend to do this more than good ones.                                 ***)
(****************************************************************************)

PROCEDURE CLEAR_OUT_SCORE_FILE;

    VAR LOOP : INTEGER;

   BEGIN

     ASSIGN(SCORE_FILE,'SCORFILE.DAT');
     REWRITE(SCORE_FILE);

       CURRENT_SCORE.NAME  := 'NONE';
       CURRENT_SCORE.WORLD := 'NONE';
       CURRENT_SCORE.SCORE :=  0.0;

     FOR LOOP := 1 TO NUM_OF_SCORES DO

         BEGIN
           SEEK(SCORE_FILE,LOOP-1);
           WRITE(SCORE_FILE,CURRENT_SCORE);
         END;

       CLOSE_SCORE_FILE;

   END;

(****************************************************************************)
(*** DISPLAY SCORE FILE : This procedure reads in whatever is currently   ***)
(*** in the score file on disk and displays it on the screen.  The colors ***)
(*** are courtesy of MP's warped mind.  The procedure is courtesy of SG's ***)
(*** cute one.                                                            ***)
(****************************************************************************)

PROCEDURE DISPLAY_SCORE_FILE;

    VAR RANK: INTEGER;
        EMPTY_FILE: BOOLEAN;
    BEGIN

     CLRSCR;
     EMPTY_FILE:=TRUE;

     OPEN_SCORE_FILE_FOR_READ;

     TextColor(Yellow);
     gotoxy(33,1);
     writeln('STARFALL HALL OF FAME');
     writeln;
     TextColor(LightRed);
     WRITE('--------------------------------------------------------------------------------');
     WRITE('|RANK|        PLAYER NAME           |           WORLD NAME         |    SCORE  |');
     WRITE('|----|------------------------------|------------------------------|-----------|');
     RANK := 1;

         WHILE NOT (EOF (SCORE_FILE)) DO

            BEGIN
              SEEK(SCORE_FILE,RANK-1);

              READ(SCORE_FILE,CURRENT_SCORE);
                IF CURRENT_SCORE.NAME <> 'NONE' THEN
                     BEGIN
                       EMPTY_FILE:=FALSE;
                       TextColor(LightRed);  WRITE('| ');
                       TextColor(LightBlue); WRITE(RANK:2,' ');
                       TextColor(LightRed);  WRITE('|');
                       TextColor(LightBlue); WRITE(CURRENT_SCORE.NAME:30);
                       TextColor(LightRed);  WRITE('|');
                       TextColor(LightBlue); WRITE(CURRENT_SCORE.WORLD:30);
                       TextColor(LightRed);  WRITE('|');
                       TextColor(LightBlue); WRITE(CURRENT_SCORE.SCORE:11:0);
                       TextColor(LightRed);  WRITE('|');
                     END;

              RANK := RANK + 1;

            END;

     IF EMPTY_FILE
       THEN
         BEGIN
           TextColor(LightRed);     WRITE('|    |       ');
           TextColor(LightBlue);    WRITE('NO SCORES HAVE BEEN RECORDED IN THE HALL OF FAME');
           TextColor(LightRed);     WRITE('      |           |');
         END;

     WRITE('--------------------------------------------------------------------------------');
     CLOSE_SCORE_FILE;

    END;


{&H SHOSCORE - MAINLINE CODE }
{&P}
(****************************************************************************)
(*** SHOSCORE - MAINLINE CODE                                             ***)
(****************************************************************************)

BEGIN
  REPEAT
    DISPLAY_SCORE_FILE;
    gotoxy(1,20);
    TextColor(Yellow);
    writeln('Press <RETURN> to exit to STARFALL main menu.');
    write('Press C to clear out this score file.  ');
    REPEAT
      read(Kbd,ch);
    UNTIL ch IN [return,'c','C'];
    IF ch IN ['c','C']
      THEN
        CLEAR_OUT_SCORE_FILE;
  UNTIL ch=return;

  ASSIGN(main_program,'STARFALL.COM');
  EXECUTE(main_program);
END.