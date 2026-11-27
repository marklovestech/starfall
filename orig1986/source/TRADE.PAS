{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : TRADE.PAS                                            ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : Trading main procedure                               ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE Trade;
VAR
  temp_time : time_type;
  save_mode : main_program_mode_type;
BEGIN
  clear_block_text_prompt_line;
  save_mode:=mode;
  mode:=world_text;
  world_text_mode:=trade_mode;

  init_world_trade_screen;
  refresh_screen;

  IF (trader_in_orbit)
    THEN
      handle_trade_window_keys
    ELSE
      call_trader;
  IF (base_block_x<>-1) AND (base_block_y<>-1)
    THEN
      update_human_resource_list(base_block_x,base_block_y);
  mode:=save_mode;
  refresh_screen;
END;
