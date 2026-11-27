PROGRAM trader_stuff;

VAR
  tloop : integer;
  tstart : integer;
  tend  : integer;
  cloop : integer;
  cstart : integer;
  cend : integer;
  base       : real;
  typical    : integer;

FUNCTION power(number,new_power:real):real;
BEGIN
  power:=exp(new_power*ln(number));
END;

FUNCTION max(arg1,arg2:real):real;
BEGIN
  IF arg1>=arg2
    THEN
      max:=arg1
    ELSE
      max:=arg2;
END;

FUNCTION min(arg1,arg2:real):real;
BEGIN
  IF arg1<=arg2
    THEN
      min:=arg1
    ELSE
      min:=arg2;
END;

FUNCTION reasonable_amount_of(typical : integer):real;
BEGIN
  reasonable_amount_of:=max(1.0,typical*0.1);
END;

FUNCTION value_of(you         : integer;
                  trader      : integer;
                  base        : real;
                  typical     : integer):real;
VAR
  direction:real;
  your_direction : real;
BEGIN
  IF trader>typical
    THEN
      direction:=-0.50
    ELSE
      IF trader<typical
        THEN
          direction:=1.25
        ELSE
          direction:=0;

  IF you>reasonable_amount_of(typical)
    THEN
      your_direction:=-0.05
    ELSE
      your_direction:=0.75;

  value_of:=min(abs((typical-trader)/trader),1.0)
                        *direction
                        *250
                        *power(abs((typical-trader+0.1)/trader),0.333333)
           + base*(0.75+your_direction*
                         sqrt(
                           abs(
                                (reasonable_amount_of(typical)-you)
                                /reasonable_amount_of(typical)
                              )
                             )
                   );
END;

BEGIN
  write('Start/end for trader loop ?');
  readln(tstart);
  readln(tend);
  write('How many does he/she normally have ?');
  readln(typical);
  write('Base value of this item ?');
  readln(base);

  write('Start/end for colonist loop ?');
  readln(cstart);
  readln(cend);

  FOR tloop:=tstart TO tend DO
    BEGIN
      FOR cloop:=cstart to cend DO
        BEGIN
          write('Trader_amount = ',tloop:5,' Colonist amount = ',cloop:5,' ');
          writeln(' Value = ',value_of(cloop,tloop,base,typical):5:2);
        END;
    END;
END.

