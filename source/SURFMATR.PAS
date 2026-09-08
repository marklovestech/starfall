PROCEDURE create_surface_resource_matrix;
VAR
  temperature_loop    : integer;
  hydrograph_loop     : integer;
BEGIN
  ASSIGN(surface_matrix_file,'SURFMATR.DAT');
  rewrite(surface_matrix_file);
  FOR temperature_loop:=0 to 15 DO
    FOR hydrograph_loop := 0 to 15 DO
      BEGIN
        write('SURFACE MATRIX [',temperature_loop:2,',',hydrograph_loop:2,'] = ?');
        readln(surface_resource_matrix[temperature_loop,hydrograph_loop]);
        writeln(surface_matrix_file,
                surface_resource_matrix[temperature_loop,hydrograph_loop]);
      END;
  close(surface_matrix_file);
END;
