{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : GETKEY.PAS                                           ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This file has various routines for dealing with      ***)
(***                 the keyboard.                                        ***)
(*** Input         : See particular subprogram                            ***)
(*** Output        : See particular subprogram                            ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

(****************************************************************************)
(*** INKEY : This function performs just like any BASIC inkey$ function.  ***)
(*** If there is no key at the keyboard, a null is returned, and if there ***)
(*** is a key, then it is returned.                                       ***)
(****************************************************************************)

{$U-}

FUNCTION inkey(VAR Func_key:boolean):char;
VAR
  ch:char;
BEGIN
  func_key:=false;
  ch:=chr(0);
  IF KeyPressed
    THEN
      BEGIN
        read(Kbd,ch);
        IF (ch=escape) and KeyPressed
          THEN
            BEGIN
              Read(Kbd,ch);
              func_key:=true;
            END;
      END;
  inkey:=ch;
END;

(****************************************************************************)
(*** GET KEY WITH CLOCK : This procedure manages to work on the keyboard  ***)
(*** even while it scans and updates the clock as necessary.              ***)
(****************************************************************************)

FUNCTION get_key_with_clock(VAR Func_key:boolean):char;
VAR
  ch:char;
  loop:integer;
BEGIN
  REPEAT
    display_current_time_on_text;
    loop:=0;
    REPEAT
      ch:=inkey(Func_key);
      loop:=succ(loop);
    UNTIL (loop>1500) OR (ch<>chr(0));
  UNTIL ch<>chr(0);
  get_key_with_clock:=ch;
END;

(****************************************************************************)
(*** GET KEY : This is not as exciting as the one above, but it does do   ***)
(*** a good job of getting a key from the keyboard.                       ***)
(****************************************************************************)

FUNCTION get_key(VAR Func_key:boolean):char;
VAR
  ch:char;
BEGIN
  func_key:=false;
  ch:=chr(0);
  Read(Kbd,ch);
  IF (ch=escape) and KeyPressed
    THEN
      BEGIN
        Read(Kbd,ch);
        func_key:=true;
      END;
  get_key:=ch;
END;

