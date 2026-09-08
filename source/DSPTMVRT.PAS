
OVERLAY PROCEDURE display_time_vertically(x_pos, y_pos : integer;
                                  time         : time_type);
BEGIN
  gotoxy(x_pos,y_pos);
  writeln('Seconds    : ',time.second:4);
  gotoxy(x_pos,y_pos+1);
  writeln('Minutes    : ',time.minute:4);
  gotoxy(x_pos,y_pos+2);
  writeln('Hours      : ',time.hour:4);
  gotoxy(x_pos,y_pos+3);
  writeln('Days       : ',time.date:4);
  gotoxy(x_pos,y_pos+4);
  writeln('Months     : ',time.month:4);
  gotoxy(x_pos,y_pos+5);
  writeln('Years      : ',time.year:4);
END;
