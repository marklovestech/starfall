{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : CHNGBASE.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This is the procedure that is called to change the   ***)
(***                 base.  It also calls a trader if this is the very    ***)
(***                 first base on the planet.                            ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE change_base;
VAR
  temp_pending : pending_ptr;
BEGIN
  IF land_at(current_block_x,current_block_y)
    THEN
      BEGIN
        IF (base_block_x=-1) OR (base_block_y=-1)
          THEN
            BEGIN
              base_block_x:=current_block_x;
              base_block_y:=current_block_y;
              temp_pending:=create_a_new_pending_item;
              temp_pending^.action_type:=trader_arriving_action;
              temp_pending^.x:=base_block_x;
              temp_pending^.y:=base_block_y;
              add_to_pending_list(temp_pending);
              finish_pending_item(temp_pending,100.0);
            END
          ELSE
            BEGIN
              base_block_x:=current_block_x;
              base_block_y:=current_block_y;
            END;
        refresh_screen;
      END
    ELSE
      beep;
END;
