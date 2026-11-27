Procedure Cls;

Begin { Cls }

    Write (#27#91#50#74);

End; { Cls }

Procedure Curse_on;

Begin { Curseon }

    Write (#27#91#108);

End; { Curseon }

Procedure Curse_off;

Begin { Curseoff }

    Write (#27#91#104);

End; { Curseoff }

Type

    St = String[7];

Const

    Black : St = 'XBlack';
    Red : St = 'Red';
    Green : St = 'Green';
    Yellow : St = 'Yellow';
    Blue : St = 'Blue';
    Magenta : St = 'Magenta';
    Cyan : St = 'Cyan';
    White : St = 'White';

Procedure Color(Col:St);

{ USAGE : Color(Red);

    Valid Colors Include:

        Black, Red, Green, Yellow, Blue, Magenta, Cyan and White.

}

Var

    Str : String[3];

Begin { Color }

    Case Upcase(Col[1]) of

        'X' : Str := '30m';
        'R' : Str := '31m';
        'G' : Str := '32m';
        'Y' : Str := '33m';
        'B' : Str := '34m';
        'M' : Str := '35m';
        'C' : Str := '36m';
        'W' : Str := '37m';

        Else

            Str := '37m';

    End; { case }

    Write (#27#91,Str);

End; { Color }
