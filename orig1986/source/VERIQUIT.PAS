{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : VERIQUIT.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Quit and score routines                              ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE verify_quit;
CONST
    NUM_OF_SCORES = 15;

TYPE
    SCORE_RECORD = RECORD
                     NAME   : STRING30;
                     WORLD  : STRING30;
                     SCORE  : REAL;
                   END;

VAR
    SCORE_FILE    :  FILE OF SCORE_RECORD;
    CURRENT_SCORE :  SCORE_RECORD;
    name : string30;
    world : string30;
    score : real;
    temp_char : char;
    person_name : string30;

PROCEDURE OPEN_SCORE_FILE_FOR_READ;

   BEGIN

     ASSIGN(SCORE_FILE,'SCORFILE.DAT');

     RESET(SCORE_FILE);

   END;


PROCEDURE CLOSE_SCORE_FILE;

   BEGIN

     CLOSE(SCORE_FILE);

   END;


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


FUNCTION WORLD_RANK_SCORE(SCORE : REAL) : BOOLEAN;

   VAR  TEST: BOOLEAN;

     BEGIN

       TEST := FALSE;

       OPEN_SCORE_FILE_FOR_READ;

         WHILE NOT(EOF (SCORE_FILE)) DO

           BEGIN

              READ(SCORE_FILE,CURRENT_SCORE);

                IF (SCORE >= CURRENT_SCORE.SCORE)
                 THEN  TEST := TRUE;

           END;

       WORLD_RANK_SCORE := TEST;
       CLOSE_SCORE_FILE;

     END;

FUNCTION WORLD_RANK_SPOT(SCORE : REAL) :INTEGER;

   VAR  COUNT : INTEGER;
        TEMP  : INTEGER;

      BEGIN

        TEMP := 0;

        COUNT := 0;

        OPEN_SCORE_FILE_FOR_READ;

           WHILE NOT (EOF (SCORE_FILE)) DO

              BEGIN

                READ(SCORE_FILE,CURRENT_SCORE);

                COUNT := COUNT + 1;

                IF TEMP=0
                  THEN
                    IF (SCORE >= CURRENT_SCORE.SCORE) THEN
                       TEMP := COUNT;

              END;

          CLOSE_SCORE_FILE;

          WORLD_RANK_SPOT:=TEMP;

      END;


PROCEDURE ADD_TO_SCORE_FILE(NAME : STRING30; WORLD : STRING30; SCORE : REAL);


      VAR  SPOT : INTEGER;
           TEMP_SCORE : SCORE_RECORD;
           LOOP : INTEGER;

        BEGIN

          SPOT := WORLD_RANK_SPOT(SCORE);

          OPEN_SCORE_FILE_FOR_READ;

          CURRENT_SCORE.NAME  := NAME;
          CURRENT_SCORE.WORLD := WORLD;
          CURRENT_SCORE.SCORE := SCORE;

            IF SPOT = NUM_OF_SCORES THEN
               BEGIN
                 SEEK(SCORE_FILE,19);
                 WRITE(SCORE_FILE,CURRENT_SCORE);
               END
            ELSE
               BEGIN
                 FOR LOOP := NUM_OF_SCORES-1 DOWNTO SPOT DO

                   BEGIN
                     SEEK(SCORE_FILE,LOOP-1);
                     READ(SCORE_FILE,TEMP_SCORE);
                     SEEK(SCORE_FILE,LOOP);
                     WRITE(SCORE_FILE,TEMP_SCORE);
                   END;

                SEEK(SCORE_FILE,SPOT-1);
                WRITE(SCORE_FILE,CURRENT_SCORE);

                CLOSE_SCORE_FILE;

               END;
        END;

  FUNCTION score_for_tree(tree_root : resource_ptr):real;
  BEGIN
    IF tree_root=NIL
      THEN
        score_for_tree:=0.0
      ELSE
        score_for_tree:=resources[tree_root^.resource_num].score_value
                      + score_for_tree(tree_root^.child)
                      + score_for_tree(tree_root^.next);
  END;

  FUNCTION find_game_score:real;
  VAR
    temp_score:real;
    x_loop          : integer;
    y_loop          : integer;
    hrll_ptr        : human_resource_list_ptr;
    pend_ptr        : pending_ptr;
  BEGIN
    ClrScr;
    temp_score:=0.0;
    writeln('Computing final score for game:');
    writeln;
    write('Scanning World          : ');
    hrll_ptr:=human_resource_list_root;
    WHILE hrll_ptr<>NIL DO
      BEGIN
        write('.');
        temp_score:=temp_score+score_for_tree(world_matrix[hrll_ptr^.x]^[hrll_ptr^.y]^.resources);
        hrll_ptr:=hrll_ptr^.next;
      END;

    writeln;
    writeln;
    writeln('Scanning Pending List : ');
    pend_ptr:=world_pending_list_root;
    WHILE pend_ptr<>NIL DO
      BEGIN
        write('.');
        temp_score:=temp_score+score_for_tree(pend_ptr^.resources_involved)
                              +score_for_tree(pend_ptr^.objects_involved);
        pend_ptr:=pend_ptr^.next;
      END;
    find_game_score:=temp_score;
  END;

BEGIN
  ClrScr;
  writeln('Program Termination:');
  gotoxy(1,4);
  write('This world has not been saved since : ');
  display_time_on_text(time_world_last_saved);

  REPEAT
    gotoxy(1,6);
    REPEAT
      write('Do you really want to quit [N] ?');
      temp_char:=get_key_with_clock(fkey);
    UNTIL (NOT fkey);
    writeln(temp_char);

    IF (temp_char=return)
      THEN
        temp_char:='N';
  UNTIL (temp_char IN ['y','Y','n','N']);

  IF (temp_char IN ['y','Y'])
    THEN
      BEGIN
        quit:=true;
        score:=find_game_score;
        IF world_rank_score(score)
          THEN
            BEGIN
              ClrScr;
              writeln('Updating the list of high scores:');
              writeln;
              writeln;
              writeln('Congratulations!  Your score deserves to be ranked with ');
              writeln('the best!  Please enter your name below, so that it may be ');
              writeln('recorded in the Starfall Hall of Fame:');
              writeln;
              write('NAME: ');
              readln(person_name);
              add_to_score_file(person_name,world_name,score);
              display_score_file;
            END;
      END
    ELSE
      quit:=false;
END;
