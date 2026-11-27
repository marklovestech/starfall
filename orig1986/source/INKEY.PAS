{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : INKEY.PAS                                            ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This function goes and gets a key from the keyboard, ***)
(***                 if it can.  If it cannot, it returns null.           ***)
(*** Input         : None.                                                ***)
(*** Output        : Key and Functio Key                                  ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

{$U-}

FUNCTION inkey(VAR func_key:boolean):char;
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
