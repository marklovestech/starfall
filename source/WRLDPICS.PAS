{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : WRLDPICS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These two procedures load and save the world picture ***)
(***                 from and into memory.                                ***)
(*** Input         : None.                                                ***)
(*** Output        : None.                                                ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE save_world_picture;
BEGIN
  GetPic(world_picture^,wm_x_coord,screen_height,
                        screen_width-wm_x_coord,wm_y_coord);
END;

PROCEDURE restore_world_picture;
BEGIN
  PutPic(world_picture^,wm_x_coord,screen_height);
END;
