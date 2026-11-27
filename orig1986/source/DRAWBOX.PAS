{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : DRAWBOX.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Draws a box defined by two points in the color given ***)
(*** Input         : X1,Y1,X2,Y2,COLOR                                    ***)
(*** Output        : A colored box                                        ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE draw_box(x1,y1,x2,y2,color:integer);
BEGIN
  draw(x1,y1,x2,y1,color);
  draw(x2,y1,x2,y2,color);
  draw(x2,y2,x1,y2,color);
  draw(x1,y2,x1,y1,color);
END;
