{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : TRADPRIM.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures are all of the primitive routines   ***)
(***                 that trade calls.                                    ***)
(*** Input         : See particular subprogram                            ***)
(*** Output        : See particular subprogram                            ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE enable_trade_window;
BEGIN
  current_trade_window_ptr:=trader_resource_tree_root;
  current_trade_window_item:=current_trade_window_ptr;
END;

OVERLAY PROCEDURE update_trade_financial_status;
BEGIN
  TextColor(White);
  gotoxy(7,min_trade_window_y-4);
  write('Current status:',colony_financial_status:10:2,'      ');
  gotoxy(30,min_trade_window_y-3);
  write('Remaining credit:',(colony_financial_status-current_debt_limit):10:2,'     ');
  gotoxy(50,min_trade_window_y-4);
  write('Debt limit:',current_debt_limit:10:2,'      ');
END;

OVERLAY PROCEDURE update_trade_window;
VAR
  current_y : integer;
  save_ptr  : resource_ptr;
  window_ptr: resource_ptr;
BEGIN
  Window(2,min_trade_window_y+1,
         78,max_trade_window_y-1);
  ClrScr;

  current_trade_window_line:=-1; (* this signals that the cursor is NOT on the screen *)
  current_y:=1;
  save_ptr:=NIL;
  window_ptr:=current_trade_window_ptr;

  WHILE ((current_y<=(max_trade_window_y-min_trade_window_y-1))
    AND (window_ptr<>save_ptr)) DO
    BEGIN
      save_ptr:=window_ptr;
      WITH window_ptr^ DO
        BEGIN
          IF window_ptr=current_trade_window_item
            THEN
              BEGIN
                TextColor(resource_window_cursor_color);
                gotoxy(1,current_y);
                write('->');
                gotoxy(74,current_y);
                write('<-');
                current_trade_window_line:=current_y;
              END;

          TextColor(resource_window_data_normal_color);
          gotoxy(3,current_y);
          write(resources[resource_num].resource_name:30,' ');

          write(amount_of_unlinked_resource_in_top_level_of_tree(window_ptr^.resource_num,
                world_matrix[base_block_x]^[base_block_y]^.resources):6:0);

          write(' ',value_of(window_ptr^.resource_num):10:2,' ',
                window_ptr^.quantity:6:0,' ',
                cost_of(window_ptr^.resource_num):10:2);

          current_y:=succ(current_y);
          step_resource_ptr(window_ptr);
        END;
    END;
  Window(1,1,80,25);
END;
