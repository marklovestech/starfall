{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : SETWRLDM.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This sets up the graphics screen to display the      ***)
(***                 world map.                                           ***)
(*** Input         : None.                                                ***)
(*** Output        : A setup screen.                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE setup_world_map_graphics;
BEGIN
  GraphMode;
  Palette(wm_palette);
  GraphBackground(wm_background);
  FillScreen(wm_red);
END;
