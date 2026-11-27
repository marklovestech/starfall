{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : DSPFKHLP.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure decodes a function key into a call    ***)
(***                 to a help screen.                                    ***)
(*** Input         : key                                                  ***)
(*** Output        : help screen is displayed                             ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE display_function_key_help_screen_overlay(key : char);
BEGIN
  CASE key OF
    SHF1   : display_help_screen('Map Help Screen');
    SHF2   : display_help_screen('Trading Help Screen');
    SHF3   : display_help_screen('Exploration Help Screen');
    SHF4   : display_help_screen('Extraction Help Screen');
    SHF5   : display_help_screen('Development Help Screen');
    SHF6   : display_help_screen('Refinement Help Screen');
    SHF7   : display_help_screen('Production Help Screen');
    SHF8   : display_help_screen('Transportation Help Screen');
    SHF9   : display_help_screen('Pending List Help Screen');
    SHF10  : display_help_screen('Log List Help Screen');
  END;
END;
