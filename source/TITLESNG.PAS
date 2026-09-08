(****************************************************************************)
(*** PLAY TITLE SONG : This song was composed solely for this game.  If   ***)
(*** there is doubt on this subject, one listening to the song will       ***)
(*** dispell all doubts.                                                  ***)
(****************************************************************************)

PROCEDURE play_title_song;
BEGIN
  WITH Notes DO
    BEGIN
      Play(3,E,quarter_note);
      Play(3,C,quarter_note);
      Play(3,E,quarter_note);
      Play(3,A,quarter_note);
      Play(3,E,quarter_note);
      Play(3,A,quarter_note);
      Play(4,C,quarter_note);
      Play(3,A,quarter_note);
      Play(4,C,quarter_note);
      Play(4,E,Whole_note+half_note);
    END;
END;
