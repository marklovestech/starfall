FUNCTION int_max(arg1,arg2:integer):integer;
BEGIN
  IF arg1>=arg2
    THEN
      int_max:=arg1
    ELSE
      int_max:=arg2;
END;

FUNCTION int_min(arg1,arg2:integer):integer;
BEGIN
  IF arg1<=arg2
    THEN
      int_min:=arg1
    ELSE
      int_min:=arg2;
END;

