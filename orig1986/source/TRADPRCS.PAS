{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : TRADPRCS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These routines are all of the higher-level routines  ***)
(***                 for trading.                                         ***)
(*** Input         : None.                                                ***)
(*** Output        : None.                                                ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE call_trader;
VAR
  temp_time                 : time_type;
  time_until_trader_arrives : time_type;
  temp_pending              : pending_ptr;
  updates_left              : integer;
  loop                      : integer;
BEGIN
  IF NOT (trader_called)
    THEN
      BEGIN
        REPEAT
          TextColor(White);
          gotoxy(4,min_trade_window_y+3);
          write('There is no trader in orbit.');
          gotoxy(4,min_trade_window_y+5);
          write('Do you wish to call one [N] ?');
          key:=get_key_with_clock(fkey);
          IF fkey OR
            (NOT (key IN ['y','Y','n','N',return]))
            THEN
              bad_key;
        UNTIL (NOT fkey) AND (key IN ['y','Y','n','N',return]);
        IF key IN ['y','Y']
          THEN
            BEGIN
              updates_left:=0;
              FOR loop:=1 to 20 DO
                updates_left:=updates_left+random(30)+6;

              convert_updates_to_time(updates_left,time_until_trader_arrives);

              trader_called:=true;
              temp_pending:=create_a_new_pending_item;
              temp_pending^.x:=base_block_x;
              temp_pending^.y:=base_block_y;
              temp_pending^.action_type:=trader_arriving_action;

              temp_time:=game_time;
              add_times(temp_time,time_until_trader_arrives);
              temp_pending^.estimated_completion_time:=temp_time;

              temp_pending^.updates_left:=updates_left;
              temp_pending^.resources_involved:=NIL;
              temp_pending^.objects_involved:=NIL;

              add_to_pending_list(temp_pending);

              TextColor(White);
              gotoxy(trade_window_x+2,min_trade_window_y+1);
              writeln('Trader has been called.');
              gotoxy(trade_window_x+2,min_trade_window_y+3);
              writeln('Earth account debited ',cost_of_calling_trader:8:2);
              colony_financial_status:=colony_financial_status-cost_of_calling_trader;

              gotoxy(trade_window_x+2,min_trade_window_y+5);
              write('Date of arrival:  ');
              display_time_on_text(temp_time);
            END;
      END
    ELSE
      BEGIN
        TextColor(White);
        gotoxy(trade_window_x+2,min_trade_window_y+2);
        writeln('Trader is on course here already.');
        beep;
      END;
  gotoxy(trade_window_x+2,min_trade_window_y+7);
  writeln('Press <RETURN> to resume play.');
  REPEAT
    key:=get_key_with_clock(fkey);
    IF fkey
      THEN
        CASE key OF
          F1      : ;
      SHF1..SHF10 : display_function_key_help_screen(key);
          else    bad_key;
        END
      ELSE
        CASE key OF
          return  : ;
          else    bad_key;
        END;
  UNTIL (fkey AND (key=F1)) OR
        ((NOT fkey) AND (key=return));
END;

OVERLAY PROCEDURE trader_arrives_overlay;

BEGIN
  trader_called:=false;
  trader_in_orbit:=true;
  current_debt_limit:=current_debt_limit-cost_of_calling_trader;
END;

OVERLAY PROCEDURE trader_departs_overlay;
BEGIN
  trader_in_orbit:=false;
  new_planet:=false; (* this is so that, when the trader leaves the first *)
                     (* time, you can no longer play with your base as    *)
                     (* freely as you could *)

  IF (mode=world_text) AND (world_text_mode=trade_mode)
    THEN
      BEGIN
        (* the trader is going to walk out on them *)
        mode:=world_map;
        refresh_screen;
      END;
END;

OVERLAY PROCEDURE handle_trade_window_keys;

  PROCEDURE move_trade_item_up_one;
  BEGIN
    decr_window_ptr(current_trade_window_item,
                    current_trade_window_ptr,
                    current_trade_window_line);
    update_trade_window;
  END;

  PROCEDURE move_trade_item_down_one;
  BEGIN
    incr_window_ptr(current_trade_window_item,
                    current_trade_window_ptr,
                    current_trade_window_line,
                    min_trade_window_y,
                    max_trade_window_y);
    REPEAT
      IF (current_trade_window_line=-1) OR
         (current_trade_window_line>(max_trade_window_y-min_trade_window_y-2))
        THEN
          step_resource_ptr(current_trade_window_ptr);
      update_trade_window;
    UNTIL current_trade_window_line<>-1;
  END;

  PROCEDURE sell_x_of_current_item(amount : real);
  VAR
    trash : real;

  BEGIN
    IF amount_of_unlinked_resource_in_top_level_of_tree(current_trade_window_item^.resource_num,
                                  world_matrix[base_block_x]^[base_block_y]^.resources)
       >=amount
      THEN
        BEGIN
          trash:=delete_some_resource_from_top_level_of_tree(current_trade_window_item^.resource_num,
                                                             amount,
                                                             world_matrix[base_block_x]^[base_block_y]^.resources);
          current_trade_window_item^.quantity:=
            current_trade_window_item^.quantity+amount;
          colony_financial_status:=colony_financial_status
                                 + amount*value_of(current_trade_window_item^.resource_num);
          update_trade_window;
          update_trade_financial_status;
        END
      ELSE
        beep;
  END;

  PROCEDURE buy_x_of_current_item(amount : real);
  VAR
    temp_ptr : resource_ptr;
  BEGIN
    IF colony_financial_status-
       amount*cost_of(current_trade_window_item^.resource_num)
       >= current_debt_limit
      THEN
        BEGIN
          IF (current_trade_window_item^.quantity>=amount)
            THEN
              BEGIN
                current_trade_window_item^.quantity:=
                  current_trade_window_item^.quantity-amount;
                temp_ptr:=create_a_new_resource;
                set_resource_flag_extracted(temp_ptr^.flags,true);
                set_resource_flag_found(temp_ptr^.flags,true);
                temp_ptr^.quantity:=amount;
                temp_ptr^.resource_num:=current_trade_window_item^.resource_num;
                add_resource_to_top_level_of_tree(world_matrix[base_block_x]^[base_block_y]^.resources,
                                                  temp_ptr);
                colony_financial_status:=colony_financial_status
                  - amount*cost_of(current_trade_window_item^.resource_num);
                update_trade_window;
                update_trade_financial_status;
              END
            ELSE
              beep;
        END
      ELSE
        beep;
  END;

  PROCEDURE move_to_top_of_trade_list;
  BEGIN
    enable_trade_window;
    update_trade_window;
  END;

  PROCEDURE move_to_bottom_of_trade_list;
  VAR
    save_ptr : resource_ptr;
  BEGIN
    REPEAT
      save_ptr:=current_trade_window_item;
      step_resource_ptr(current_trade_window_item);
      current_trade_window_line:=succ(current_trade_window_line);
      IF current_trade_window_line>(max_trade_window_y-min_trade_window_y)
        THEN
          BEGIN
            step_resource_ptr(current_trade_window_ptr);
            current_trade_window_line:=max_trade_window_y-min_trade_window_y;
          END;
    UNTIL save_ptr=current_trade_window_item;
    update_trade_window;
  END;

  PROCEDURE move_one_page_down_in_trade_list;
  VAR
    save_ptr : resource_ptr;
    count    : integer;
  BEGIN
    count:=0;
    REPEAT
      save_ptr:=current_trade_window_item;
      step_resource_ptr(current_trade_window_item);
      current_trade_window_line:=succ(current_trade_window_line);
      IF current_trade_window_line>(max_trade_window_y-min_trade_window_y-2)
        THEN
          BEGIN
            step_resource_ptr(current_trade_window_ptr);
            current_trade_window_line:=max_trade_window_y-min_trade_window_y-2;
          END;
      count:=succ(count);
    UNTIL (save_ptr=current_trade_window_item) OR
          (count>=(max_trade_window_y-min_trade_window_y-2));
    update_trade_window;
  END;

  PROCEDURE move_one_page_up_in_trade_list;
  VAR
    save_ptr : resource_ptr;
    count    : integer;
  BEGIN
    count:=0;
    REPEAT
      save_ptr:=current_trade_window_item;
      unstep_resource_ptr(current_trade_window_item);
      current_trade_window_line:=pred(current_trade_window_line);
      IF current_trade_window_line<1
        THEN
          BEGIN
            unstep_resource_ptr(current_trade_window_ptr);
            current_trade_window_line:=1;
          END;
      count:=succ(count);
    UNTIL (save_ptr=current_trade_window_item) OR
          (count>=(max_trade_window_y-min_trade_window_y-2));
    update_trade_window;
  END;

  PROCEDURE clear_world_trade_prompt_line;
  BEGIN
    gotoxy(1,min_trade_window_y-1);
    ClrEol;
  END;

  PROCEDURE sell_many_of_current_item;
  VAR
    amount : real;
  BEGIN
    REPEAT
      TextColor(Yellow);
      amount:=1;
      clear_world_trade_prompt_line;
      write('Amount of item to sell [1.0] ?');
      get_real(amount);
      IF amount<>int(amount)
        THEN
          valid:=false;
    UNTIL valid;

    clear_world_trade_prompt_line;

    IF amount>0
      THEN
        sell_x_of_current_item(amount);
  END;

  PROCEDURE buy_many_of_current_item;
  VAR
    amount : real;
  BEGIN
    REPEAT
      TextColor(Yellow);
      amount:=1;
      clear_world_trade_prompt_line;
      write('Amount of item to buy [1.0] ?');
      get_real(amount);
      IF amount<>int(amount)
        THEN
          valid:=false;
    UNTIL valid;

    clear_world_trade_prompt_line;

    IF amount>0
      THEN
        buy_x_of_current_item(amount);
  END;

BEGIN
  REPEAT
    key:=get_key_with_clock(fkey);
    IF fkey
      THEN
        CASE key OF
          Uarr   : move_trade_item_up_one;
          Darr   : move_trade_item_down_one;
          Rarr   : sell_x_of_current_item(1.0);
          Larr   : buy_x_of_current_item(1.0);
          Home   : move_to_top_of_trade_list;
          Endkey : move_to_bottom_of_trade_list;
          PgUp   : move_one_page_up_in_trade_list;
          PgDn   : move_one_page_down_in_trade_list;
     SHF1..SHF10 : display_function_key_help_screen(key);
          else   bad_key;
        END
      ELSE
        CASE key OF
          SHRarr : sell_many_of_current_item;
          SHLarr : buy_many_of_current_item;
          return : ;
          escape : display_help_screen('Trade Commands');
          'h','H': display_help_screen('General Help Screen');
          else   bad_key;
        END;
  UNTIL ((NOT fkey) AND (key=return)) OR
        ((fkey) AND (key=F1));
END;
