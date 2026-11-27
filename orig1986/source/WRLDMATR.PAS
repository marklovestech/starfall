(***** These routines process the three world matrix arrays -
       world_west, center, and east, to produce a large matrix
       of land ptr's called world_matrix ****)

FUNCTION world_matrix(x,y:integer):land_ptr;
BEGIN
  world_matrix:=NIL;
  CASE x OF
      1 ..  96 : world_matrix:=world_west^[x,y];
     97 .. 192 : world_matrix:=world_center^[x-96,y];
    193 .. 288 : world_matrix:=world_east^[x-192,y];
  END;
END;

PROCEDURE set_world_matrix(x,y:integer;
                           ptr:land_ptr);
BEGIN
  CASE x OF
      1 ..  96 : world_west^[x,y]:=ptr;
     97 .. 192 : world_center^[x-96,y]:=ptr;
    193 .. 288 : world_east^[x-192,y]:=ptr;
  END;
END;