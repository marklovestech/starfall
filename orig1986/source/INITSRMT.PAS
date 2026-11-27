{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : INITSRMT.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This goes out and reads the surface resource matrix  ***)
(***                 from disk.                                           ***)
(*** Input         : SURFMATR.DAT on default drive.                       ***)
(*** Output        : A filled surface_resource_matrix array               ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE initialize_surface_resource_matrix;
VAR
  temperature_loop    : integer;
  hydrograph_loop     : integer;
BEGIN
  ClrScr;
  writeln('Program Initialization');
  writeln;
  write('Reading Surface Resource Matrix File [SURFMATR.DAT] :');
  ASSIGN(surface_matrix_file,'SURFMATR.DAT');
  reset(surface_matrix_file);
  FOR temperature_loop := 0 to 15 DO
    FOR hydrograph_loop := 0 to 15 DO
      BEGIN
        write('.');
        readln(surface_matrix_file,
               surface_resource_matrix[temperature_loop,hydrograph_loop]);
      END;
END;
