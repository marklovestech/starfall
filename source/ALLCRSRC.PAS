{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : ALLCRSRC.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures handle allocating all of the        ***)
(***                 mineral resources during world generation.           ***)
(*** Input         : See particular subprogram.                           ***)
(*** Output        : See particular subprogram.                           ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

(****************************************************************************)
(*** ADD NEW RESOURCE TO LAND CHUNK : This links in the given resource    ***)
(*** into the top of the resource tree at the given land chunk            ***)
(****************************************************************************)

PROCEDURE add_new_resource_to_land_chunk( resource : resource_ptr;
                                          land_loc : land_list_ptr);
BEGIN
  resource^.next:=land_loc^.resources;
  IF land_loc^.resources<>NIL
    THEN
      land_loc^.resources^.prev:=resource;
  land_loc^.resources:=resource;
END;

(****************************************************************************)
(*** RANDOM MINERAL RESOURCE : This function goes out and scans the       ***)
(*** 'resources' array until it finds a mineral resource that it feels    ***)
(*** should be included on the planet.                                    ***)
(****************************************************************************)

FUNCTION random_mineral_resource:byte;
VAR
  temp:byte;
BEGIN
  REPEAT
    temp:=random(max_resource)+1;
  UNTIL  (resources[temp].naturally_occuring)
    AND  (random(100)<resources[temp].likelihood_of_occurence);
  random_mineral_resource:=temp;
END;

(****************************************************************************)
(*** RANDOM LAND LOC : This routine goes out and looks through the land   ***)
(*** list a random amount until it finds a very random land location.  It ***)
(*** returns this.                                                        ***)
(****************************************************************************)

FUNCTION random_land_loc:land_list_ptr;
VAR
  temp_ptr   : land_list_ptr;
BEGIN
  REPEAT
    temp_ptr:=world_matrix[random(world_width)+1]^[random(world_height)+1];
  UNTIL temp_ptr<>NIL;
  random_land_loc:=temp_ptr;
END;

(****************************************************************************)
(*** GENERATE NEW INITIALIZED RESOURCE : This procedure dynamically       ***)
(*** creates a new resource and initializes all of it's fields            ***)
(****************************************************************************)

FUNCTION generate_new_initialized_resource : resource_ptr;
VAR
  temp_ptr : resource_ptr;
BEGIN
  new(temp_ptr);
  WITH temp_ptr^ DO
    BEGIN
      next:=NIL;
      prev:=NIL;
      parent:=NIL;
      child:=NIL;
      resource_num:=0;
      quantity:=0.0;
      flags:=0;
      Set_resource_flag_found(flags,false);
      Set_resource_flag_extracted(flags,true);
      Set_resource_flag_selected(flags,false);
    END;
  generate_new_initialized_resource:=temp_ptr;
END;

(****************************************************************************)
(*** GENERATE NATURAL RESOURCE : Here, it has been decided that we need   ***)
(*** a resource at this land item.  So, we call all of the various        ***)
(*** to perform this task.                                                ***)
(****************************************************************************)

PROCEDURE generate_natural_resource(resource_num : byte;
                                    land_loc     : land_list_ptr);
VAR
  new_resource    : resource_ptr;
  amount          : real;
BEGIN
  new_resource:=generate_new_initialized_resource;
  new_resource^.resource_num:=resource_num;
  amount:=resources[resource_num].typical_deposit_size
         *((100+random(150)-75)/100);
  new_resource^.quantity:=amount;
  Set_resource_flag_found(new_resource^.flags,NOT resources[resource_num].subsurface_resource);
  Set_resource_flag_extracted(new_resource^.flags,NOT resources[resource_num].subsurface_resource);
  add_new_resource_to_land_chunk(new_resource,land_loc);
END;

(****************************************************************************)
(*** ALLOCATE SUBSURFACE RESOURCES : This procedure is the one that       ***)
(*** handles all of the procedures for allocating surfaces.               ***)
(****************************************************************************)

PROCEDURE allocate_subsurface_resources;
VAR
  num_of_mineral_deposits      : integer;
  loop                         : integer;
  resource_num                 : byte;
  land_loc                     : land_list_ptr;
BEGIN
  num_of_mineral_deposits:=
    trunc((base_land_percentage/100)*world_height*world_width
          *(base_mineral_percentage
          +random(modifier_mineral_percentage)
          -(modifier_mineral_percentage/2))/100);
  FOR loop:=1 to num_of_mineral_deposits DO
    BEGIN
      resource_num:=random_mineral_resource;
      land_loc:=random_land_loc;
      paint_land_chunk(land_loc,wm_white);
      generate_natural_resource(resource_num,land_loc);
    END;
END;

