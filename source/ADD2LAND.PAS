
PROCEDURE add_to_land_list(x_coord,y_coord,climate:integer);
VAR
  new_one : land_list_ptr;
BEGIN
  (* Make new item *)

  new(new_one);

  (* Link into land list *)

  new_one^.next:=land_list_root;
  land_list_root:=new_one;

  (* initialize all fields *)

  new_one^.x:=x_coord;
  new_one^.y:=y_coord;
  new_one^.climate:=climate;
  new_one^.resources:=NIL;

  (* increment the length of the land list *)

  land_list_length :=succ(land_list_length);
END;
