{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : SURFRSRC.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures lay out the surface resources as    ***)
(***                 necessary.                                           ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE generate_natural_resource(resource_num : byte;
                                    land_loc     : land_ptr);
VAR
  new_resource    : resource_ptr;
  amount          : real;
BEGIN
  new_resource:=create_a_new_resource;
  new_resource^.resource_num:=resource_num;
  amount:=resources[resource_num].typical_deposit_size
         *((100+random(150)-75)/100);
  new_resource^.quantity:=amount;
  Set_resource_flag_found(new_resource^.flags,NOT resources[resource_num].subsurface_resource);
  Set_resource_flag_extracted(new_resource^.flags,NOT resources[resource_num].subsurface_resource);
  add_resource_to_top_level_of_tree(land_loc^.resources,new_resource);
END;

FUNCTION surface_resource_for(climate_value : byte):byte;
BEGIN
  surface_resource_for:=
    surface_resource_matrix[temperature_from_climate(climate_value),
                            moisture_from_climate(climate_value)];
END;

PROCEDURE allocate_a_surface_resource(x,y:integer);
VAR
  current_chunk : land_ptr;
  resource_num  : byte;
BEGIN
  current_chunk:=world_matrix[x]^[y];
  resource_num:=surface_resource_for(current_chunk^.climate);
  generate_natural_resource(resource_num,current_chunk);
END;

PROCEDURE possibly_allocate_a_surface_resource(x,y:integer);
BEGIN
  IF (world_matrix[x]^[y]^.resources=NIL) OR
     (NOT surface_resources_at(x,y))
    THEN
      allocate_a_surface_resource(x,y);
END;
