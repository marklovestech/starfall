{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : NOISE.PAS                                            ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This module includes all of the various noisy thins  ***)
(***                 that the program will do.                            ***)
(*** Input         : None.                                                ***)
(*** Output        : Noise, differing depending on the procedure called   ***)
(*** Special Notes : The Play procedure is courtesy of TURBO PASCAL 3.0   ***)
(***                 BORLAND, International, Copyright 1985.              ***)
(****************************************************************************)

CONST
  quarter_note = 200;    (* These define how long a note is, in *)
  dotted_half  = 600;    (* milliseconds. Isn't TURBO neat?     *)
  half_note    = 400;    (*    "                           "    *)
  whole_note   = 800;    (*    "                           "    *)

TYPE
  NoteRecord = record
                  C,CF,D,DF,E,F,FF,G,GF,A,AF,B: integer;
               end;

CONST
  Notes : NoteRecord =
          (C:1;CF:2;D:3;DF:4;E:5;F:6;FF:7;G:8;GF:9;A:10;AF:11;B:12);

(****************************************************************************)
(*** BEEP - This is the sound that is made when the user hits a key that  ***)
(*** that might be valid at other times but that is not valid at this time***)
(*** for some various reason - like a tired computer.                     ***)
(****************************************************************************)

PROCEDURE beep;
BEGIN
  write(chr(7));
END;

(****************************************************************************)
(*** PLAY : Courtesy of BORLAND, International, Copyright 1985.           ***)
(****************************************************************************)

procedure Play(Octave,Note,Duration: integer);
var
  Frequency: real;
  I: integer;
begin
  Frequency:=32.625;
  { Compute C in Octave }
  for I:=1 to Octave do Frequency:=Frequency*2;
  { Increase frequency Note-1 times }
  for I:=1 to Note-1 do Frequency:=Frequency*1.059463094;
  if Duration<>0
    then
      begin
        Sound(Round(Frequency));
        Delay(Duration);
        NoSound;
      end
    else
      Sound(Round(Frequency));
end;

(****************************************************************************)
(***  BAD KEY : This is the sound that is made when the user strikes a    ***)
(***  key that is totally off the wall.                                   ***)
(****************************************************************************)

PROCEDURE bad_key;
BEGIN
  Play(6,4,250);
END;

(****************************************************************************)
(*** MAKE BAD NOISE : This is the noise that is made when the user lets   ***)
(*** people starve.  Hopefully, the noise is annoying, since the game     ***)
(*** does not actually put things into the pending list.                  ***)
(****************************************************************************)

PROCEDURE make_bad_noise;
BEGIN
  WITH notes DO
    BEGIN
      Play(3,C,300);
      Play(4,D,250);
      Play(6,F,150);
      Play(2,C,300);
      Play(0,C,350);
    END;
END;

(****************************************************************************)
(*** PENDING ITEM COMPLETED NOISE : This is the noise that is made by     ***)
(*** machine when a pending item finishes.                                ***)
(****************************************************************************)

PROCEDURE pending_item_completed_noise;
var
  click:integer;
BEGIN
 click:=1;
 repeat
   Play(5,7,19);
   click:=click+1;
 until click=17;
END;

