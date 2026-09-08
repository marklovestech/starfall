{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : INITWMAT.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure goes out and initializes the world    ***)
(***                 matrix to NIL.                                       ***)
(*** Input         : None.                                                ***)
(*** Output        : 32600 NILs                                           ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE initialize_world_matrix;
VAR
  loop:integer;
  inner_loop:integer;
BEGIN
  ClrScr;
  writeln('Program Initialization :');
  writeln;
  write('Initializing world matrix :');
  FOR loop:=1 to world_width DO
    BEGIN
      new(world_matrix[loop]); (* create column of pointers *)
      write('.');
      FOR inner_loop:=1 to world_height DO
        world_matrix[loop]^[inner_loop]:=NIL;
    END;
END;
