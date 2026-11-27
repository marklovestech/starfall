{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : DISPBTMS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure displays the requested message in     ***)
(***                 angry blinking red on the block text prompt line.    ***)
(*** Input         : Message to be displayed                              ***)
(*** Output        : None.                                                ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE display_block_text_message(message : text_line_type);
BEGIN
  clear_block_text_prompt_line;
  TextColor(LightRed+Blink);
  gotoxy(1,block_text_prompt_line);
  write(message);
END;