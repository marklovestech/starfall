{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : KEYWCLK.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure goes and updates the clock while      ***)
(***                 waiting for a key until a key is pressed.            ***)
(*** Input         : None.                                                ***)
(*** Output        : Key, and Function Key                                ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

{$U-}

FUNCTION get_key_with_clock(VAR Func_key:boolean):char;
VAR
  ch      : char;
BEGIN
  REPEAT
    current_keyboard_cycle_count:=succ(current_keyboard_cycle_count);
    IF current_keyboard_cycle_count>keyboard_wait_cycles
      THEN
        BEGIN
          current_keyboard_cycle_count:=0;
          IF NOT (mode IN [world_map,zoom_map,transportation_world_map,transportation_zoom_map])
            THEN
              BEGIN
                display_game_time_on_text;
                display_current_time_on_text;
              END;
          process_realtime_events;
        END;
    ch:=inkey(Func_key);
  UNTIL ch<>chr(0);
  get_key_with_clock:=ch;
END;
