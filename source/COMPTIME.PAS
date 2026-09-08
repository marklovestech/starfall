{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : COMPTIME.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures are loaded in when time compression ***)
(***                 is called.                                           ***)
(*** Input         :                                                      ***)
(*** Output        :                                                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE compress_time;
VAR
  save_mode : main_program_mode_type;

  OVERLAY PROCEDURE compress_time_up_arrow;
  VAR
    temp_time : time_type;
  BEGIN
    clear_time(temp_time);
    temp_time.minute:=1;
    subtract_times(game_time_increment,temp_time);

    IF time_greater(smallest_game_time_increment,game_time_increment)
      THEN
        game_time_increment:=smallest_game_time_increment;
  END;

  OVERLAY PROCEDURE compress_time_sh_up_arrow;
  VAR
    temp_time : time_type;
  BEGIN
    clear_time(temp_time);
    temp_time.hour:=1;
    subtract_times(game_time_increment,temp_time);

    IF time_greater(smallest_game_time_increment,game_time_increment)
      THEN
        game_time_increment:=smallest_game_time_increment;
  END;

  OVERLAY PROCEDURE compress_time_dn_arrow;
  VAR
    temp_time : time_type;
  BEGIN
    clear_time(temp_time);
    temp_time.minute:=1;
    add_times(game_time_increment,temp_time);

    IF time_greater(game_time_increment,world_update_increment)
      THEN
        game_time_increment:=world_update_increment;
  END;

  OVERLAY PROCEDURE compress_time_sh_dn_arrow;
  VAR
    temp_time : time_type;
  BEGIN
    clear_time(temp_time);
    temp_time.hour:=1;
    add_times(game_time_increment,temp_time);

    IF time_greater(game_time_increment,world_update_increment)
      THEN
        game_time_increment:=world_update_increment;
  END;

BEGIN
  save_mode:=mode;
  mode:=world_text;
  world_text_mode:=compress_time_mode;
  refresh_screen;

  REPEAT
    TextColor(Time_speed_control_color);
    display_time_vertically(33,7,game_time_increment);
    key:=get_key_with_clock(fkey);

    IF fkey
      THEN
        CASE key OF
          F1    : ;
          Uarr  : Compress_time_up_arrow;
          Darr  : Compress_time_dn_arrow;
    SHF1..SHF10 : display_function_key_help_screen(key);
          else  bad_key;
        END
      ELSE
        CASE key OF
          return : ;
          SHUarr : Compress_time_sh_up_arrow;
          SHDarr : Compress_time_sh_dn_arrow;
          'h','H': display_help_screen('General Help Screen');
          'T',escape  : display_help_screen('Time Control Help Screen');
          else   bad_key;
        END;
  UNTIL ((key=return) AND (NOT fkey))
     OR ((key=F1) AND (fkey));
  mode:=save_mode;
  refresh_screen;
END;
