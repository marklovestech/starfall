{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : CLRBTPLI.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : The procedure clears the block text prompt line.     ***)
(*** Input         : None.                                                ***)
(*** Output        : A blank line on the block text screen.               ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

  PROCEDURE clear_block_text_prompt_line;
  VAR
    curx:integer;
    cury:integer;
  BEGIN
    curx:=wherex;
    cury:=wherey;
    gotoxy(1,block_text_prompt_line);
    ClrEol;
    gotoxy(curx,cury);
  END;
