Type

    Set_of_Char = Set of Char;

Const

    Choice : Set_of_Char = ['A'..'C'];

Var

    Hr,Mn,Sc,Length : Integer;
    Key : Char;

{ Include Files }

(*{$I b:ansi.pas }  { Supported TI ANSI routines }*)

Function Inkey : Char;

Type

    Registers = record
                    AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags : Integer;
                end;

Var

    Regs : Registers;
    Key : Char;
    Mask : Integer;

Begin

    Mask := 64; { isolate the Zero Flag }
    Key := ' ';
    With Regs do
        Begin
            AX := $0600;
            DX := $00FF;
            MsDos(Regs);
            If ((Mask And Flags) = 0) then
                Key := Upcase(Chr(Lo(AX)));
        End;

    Inkey := Key;

End; { function Inkey }

Function Time : Integer;

Type

    Registers = record
                    AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags : Integer;
                end;

Var

    Regs : Registers;
    Hour, Min, Sec : integer;
    Total : integer;

Begin  { Time }

    With Regs do
        Begin
            AX := $2C00;
            MsDos(Regs);
            Hour := Hi(CX);
            Min  := Lo(CX);
            Sec  := Hi(DX);
        End;

    Total := Sec;
    Total := Min * 60 + Total;
    Total := Hour * 3600 + Total;

    Time := Total;

End; { procedure Time }

Function Timer(var Length:Integer;Choice:Set_of_Char):Char;

{ Length is the length of time the timer will run in seconds on input and
  the elapsed time on output.
  Choice is a set containing the valid returnable letters }

Var

    I, Dot_Start, Start, Stop, Delay : Integer;

Begin

    Key := ' ';
    Start := Time;
    Stop := Start + Length;

    Color(Green);
    Curse_Off;

    Dot_Start := (80 - Length*2) div 2;
    GotoXY(Dot_Start,25);

    For I := 1 to Length do
        Write('* ');

    Color(Red);
    GotoXY(Dot_Start,25);

    While (Time < Stop) and (Key = ' ') do

        Begin

            Write('* ');
            Delay := 1;
            While (Delay < 520) and (Key = ' ') do
                Begin
                    Key := Inkey;
                    If Not (Key in Choice) then
                        Key := ' ';
                    Delay := Delay + 1;
                End;
        End;

    Length := Time - Start;
    Timer := Key;
    Curse_On;

End; { procedure Timer }

