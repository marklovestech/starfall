{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : COLWINDO.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure goes and fills up a border with       ***)
(***                 asterisks of the requested color.                    ***)
(*** Input         : top and bottom of window and color to paint it.      ***)
(*** Output        : A pretty window border                               ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE color_window_border(top,bottom,color : integer);
VAR
  loop:integer;

  PROCEDURE write_asts;
  BEGIN
    write(asterisk_line);
  END;

BEGIN
  TextColor(color);
  gotoxy(1,top);
  write_asts;
  gotoxy(1,bottom);
  write_asts;

  FOR loop:=top TO bottom DO
    BEGIN
      gotoxy(1,loop);
      write('*');
      gotoxy(79,loop);
      write('*');
    END;
END;
