{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : UPDAWINV.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure updates the world inventory window    ***)
(*** Input         : None.                                                ***)
(*** Output        : None.                                                ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE update_world_inventory_window_overlay;
VAR
  current_resource : resource_ptr;
  save_resource    : resource_ptr;
  current_land     : human_resource_list_ptr;
  current_y        : integer;
BEGIN
  Window(2,min_world_inventory_window_y,78,max_world_inventory_window_y);
  ClrScr;
  current_y:=1;
  current_resource:=current_inventory_resource_item;
  current_land:=current_inventory_land_item;
  save_resource:=NIL;
  WHILE (current_resource<>save_resource) AND
        (current_y<(max_world_inventory_window_y-min_world_inventory_window_y+2)) DO
    BEGIN
      save_resource:=current_resource;
      IF (current_resource=current_inventory_resource_item)
        THEN
          BEGIN
            TextColor(LightRed);
            gotoxy(1,current_y);
            write('->');
            gotoxy(76,current_y);
            write('<-');
          END;

      TextColor(LightBlue);
      gotoxy(3,current_y);
      write('|',current_land^.x:3,'|',current_land^.y:3,'| ',
              resources[current_resource^.resource_num].resource_name:30,' | ',
              current_resource^.quantity:12:2,' ',
              resources[current_resource^.resource_num].resource_units:10);
      IF (Value_of_resource_flag_extracted(current_resource^.flags)=false)
        THEN
          write(' U');
      current_y:=succ(current_y);
      step_a_ptr_forward_in_world_inventory(current_resource,
                                            current_land);
    END;
  Window(1,1,80,25);
END;