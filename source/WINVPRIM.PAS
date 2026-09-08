{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : WINVPRIM.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures are all of the primitive routines   ***)
(***                 that the world inventory window needs.               ***)
(*** Input         : See particular subprogram                            ***)
(*** Output        : See particular subprogram                            ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

  PROCEDURE next_active_land_item(VAR current_land_item : human_resource_list_ptr);
  BEGIN
    IF current_land_item^.next<>NIL
      THEN
        current_land_item:=current_land_item^.next;
  END;

  PROCEDURE prev_active_land_item(VAR current_land_item : human_resource_list_ptr);
  BEGIN
    IF current_land_item^.prev<>NIL
      THEN
        current_land_item:=current_land_item^.prev;
  END;

  PROCEDURE back_up_a_ptr_in_world_inventory(VAR current_ptr  : resource_ptr;
                                             VAR current_land : human_resource_list_ptr);
  VAR
    save_ptr : resource_ptr;
    save_land: human_resource_list_ptr;
  BEGIN
    save_ptr:=current_ptr;
    unstep_resource_ptr(current_ptr);
    IF save_ptr=current_ptr
      THEN
        BEGIN
          save_land:=current_land;
          prev_active_land_item(current_land);
          IF save_land<>current_land
            THEN
              current_ptr:=world_matrix[current_land^.x]^[current_land^.y]^.resources;
        END;
  END;

 PROCEDURE step_a_ptr_forward_in_world_inventory(VAR current_ptr  : resource_ptr;
                                                 VAR current_land : human_resource_list_ptr);
 VAR
    save_ptr : resource_ptr;
    save_land : human_resource_list_ptr;
  BEGIN
    save_ptr:=current_ptr;
    step_resource_ptr(current_ptr);
    IF save_ptr=current_ptr
      THEN
        BEGIN
          save_land:=current_land;
          next_active_land_item(current_land);
          IF save_land<>current_land
            THEN
              current_ptr:=world_matrix[current_land^.x]^[current_land^.y]^.resources;
        END;
  END;
