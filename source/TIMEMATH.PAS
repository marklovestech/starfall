{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : TIMEMATH.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : The following routines all have to do with doing     ***)
(***                 some sort of math on time variables.                 ***)
(*** Input         : See particular subprogram                            ***)
(*** Output        : See particular subprogram                            ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE add_times(VAR source_time, delta_time:time_type);
BEGIN
  source_time.second:=source_time.second+delta_time.second;
  WHILE source_time.second>=seconds_per_minute DO
    BEGIN
      source_time.minute:=succ(source_time.minute);
      source_time.second:=source_time.second-seconds_per_minute;
    END;

  source_time.minute:=source_time.minute+delta_time.minute;
  WHILE source_time.minute>=minutes_per_hour DO
    BEGIN
      source_time.hour:=succ(source_time.hour);
      source_time.minute:=source_time.minute-minutes_per_hour;
    END;

  source_time.hour:=source_time.hour+delta_time.hour;
  WHILE source_time.hour>=hours_per_day DO
    BEGIN
      source_time.date:=succ(source_time.date);
      source_time.hour:=source_time.hour-hours_per_day;
    END;

  source_time.date:=source_time.date+delta_time.date;
  WHILE source_time.date>=days_per_month DO
    BEGIN
      source_time.month:=succ(source_time.month);
      source_time.date:=source_time.date-days_per_month;
    END;

  source_time.month:=source_time.month+delta_time.month;
  WHILE source_time.month>=months_per_year DO
    BEGIN
      source_time.year:=succ(source_time.year);
      source_time.month:=source_time.month-months_per_year;
    END;

  source_time.year:=source_time.year+delta_time.year;
  (* we don't need to check for year overflow, since it has nowhere to go *)
END;

PROCEDURE subtract_times( VAR source_time,delta_time:time_type);
BEGIN
  source_time.second:=source_time.second-delta_time.second;
  WHILE source_time.second<0 DO
    BEGIN
      source_time.minute:=pred(source_time.minute);
      source_time.second:=source_time.second+seconds_per_minute;
    END;

  source_time.minute:=source_time.minute-delta_time.minute;
  WHILE source_time.minute<0 DO
    BEGIN
      source_time.hour:=pred(source_time.hour);
      source_time.minute:=source_time.minute+minutes_per_hour;
    END;

  source_time.hour:=source_time.hour-delta_time.hour;
  WHILE source_time.hour<0 DO
    BEGIN
      source_time.date:=pred(source_time.date);
      source_time.hour:=source_time.hour+hours_per_day;
    END;

  source_time.date:=source_time.date-delta_time.date;
  WHILE source_time.date<0 DO
    BEGIN
      source_time.month:=pred(source_time.month);
      source_time.date:=source_time.date+days_per_month;
    END;

  source_time.month:=source_time.month-delta_time.month;
  WHILE source_time.month<0 DO
    BEGIN
      source_time.year:=pred(source_time.year);
      source_time.month:=source_time.month+months_per_year;
    END;

  source_time.year:=source_time.year-delta_time.year;
END;

PROCEDURE convert_updates_to_time(updates   : integer;
                                  VAR time  : time_type);
BEGIN
  clear_time(time);
  time.year:=(updates DIV (months_per_year*days_per_month*3));
  updates:=updates-(time.year*months_per_year*days_per_month*3);

  time.month:=(updates DIV (days_per_month*3));
  updates:=updates-(time.month*days_per_month*3);

  time.date:=(updates DIV 3);
  updates:=updates-(time.date*3);

  time.hour:=8*updates;
END;

FUNCTION convert_time_to_updates(time : time_type):real;
BEGIN
  convert_time_to_updates:=time.year*months_per_year*days_per_month*3
                          +time.month*days_per_month*3
                          +time.date*3
                          +(time.hour/8);
END;

FUNCTION time_greater(time_one, time_two:time_type):boolean;
BEGIN
  IF time_one.year>time_two.year
    THEN
      time_greater:=true
    ELSE
      IF time_one.year<time_two.year
        THEN
          time_greater:=false
        ELSE
          IF time_one.month>time_two.month
            THEN
              time_greater:=true
            ELSE
              IF time_one.month<time_two.month
                THEN
                  time_greater:=false
                ELSE
                  IF time_one.date>time_two.date
                    THEN
                      time_greater:=true
                    ELSE
                      IF time_one.date<time_two.date
                        THEN
                          time_greater:=false
                        ELSE
                          IF time_one.hour>time_two.hour
                            THEN
                              time_greater:=true
                            ELSE
                              IF time_one.hour<time_two.hour
                                THEN
                                  time_greater:=false
                                ELSE
                                  IF time_one.minute>time_two.minute
                                    THEN
                                      time_greater:=true
                                    ELSE
                                      IF time_one.minute<time_two.minute
                                        THEN
                                          time_greater:=false
                                        ELSE
                                          IF time_one.second>time_two.second
                                            THEN
                                              time_greater:=true
                                            ELSE
                                              time_greater:=false;
END;

FUNCTION time_less_than_or_equal_to_zero(time : time_type):boolean;
BEGIN
  WITH time DO
    BEGIN
      IF ((second<0) OR
          (minute<0) OR
          (hour<0)   OR
          (date<0)   OR
          (month<0)  OR
          (year<0))  OR
            ((second=0) AND
             (minute=0) AND
             (hour=0)   AND
             (date=0)   AND
             (month=0)  AND
             (year=0))
       THEN
         time_less_than_or_equal_to_zero:=true
       ELSE
         time_less_than_or_equal_to_zero:=false;
    END;
END;
