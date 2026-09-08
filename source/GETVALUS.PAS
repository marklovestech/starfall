{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : GETVALUS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These routines are a form of verified input.  What   ***)
(***                 they do is return a 'NOT valid' if they didnt like   ***)
(***                 the input.  This gives the calling procedure the     ***)
(***                 the descretion to do whatever it wants with this     ***)
(***                 stupid user.                                         ***)
(*** Input         : (For all) the default value                          ***)
(*** Output        : (For all) the new value, and VALID, either T or F    ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

(****************************************************************************)
(*** GET BOOLEAN : User may type Yes, Y, yes, True T or F, f, etc.        ***)
(****************************************************************************)

OVERLAY PROCEDURE get_boolean(VAR result:boolean);
VAR
  temp:text_line_type;
BEGIN
  readln(temp);
  IF temp=''
    THEN
      valid:=true;

  IF NOT abort_request(temp)
    THEN
      IF temp<>''
        THEN
          IF temp[1] IN ['y','Y','n','N','t','T','f','F']
            THEN
              BEGIN
                valid:=true;
                IF temp[1] IN ['y','Y','t','T']
                  THEN
                    result:=true
                  ELSE
                    result:=false;
              END;
END;

(****************************************************************************)
(*** GET BYTE : Note that a byte variable is one which goes from 0..255   ***)
(****************************************************************************)

OVERLAY PROCEDURE get_byte(VAR result:byte);
VAR
  temp:text_line_type;
  temp_val : real;
  garbage : integer;
BEGIN
  readln(temp);
  IF temp=''
    THEN
      valid:=true;

  IF NOT abort_request(temp)
    THEN
      IF temp<>''
        THEN
          BEGIN
            VAL(temp,temp_val,garbage);
            IF NOT ((temp_val<0) OR (temp_val>255)) AND (garbage=0)
              THEN
                IF temp_val=trunc(temp_val)
                  THEN
                    BEGIN
                      valid:=true;
                      result:=trunc(temp_val);
                    END;
          END;
END;

(******************************************************************************)
(*** GET INTEGER : This routine will accept and number from -32768 to 32767 ***)
(******************************************************************************)

OVERLAY PROCEDURE get_integer(VAR result:integer);
VAR
  temp:text_line_type;
  temp_val : real;
  garbage : integer;
BEGIN
  readln(temp);
  IF temp=''
    THEN
      valid:=true;

  IF NOT abort_request(temp)
    THEN
      IF temp<>''
        THEN
          BEGIN
            VAL(temp,temp_val,garbage);
            IF NOT ((temp_val<0) OR (temp_val>32767)) AND (garbage=0)
              THEN
                BEGIN
                  IF temp_val=trunc(temp_val)
                    THEN
                      BEGIN
                        valid:=true;
                        result:=trunc(temp_val);
                      END;
                END
              ELSE
                result:=0;
          END;
END;

(****************************************************************************)
(*** GET REAL : This routine will accept any number with any alphas.      ***)
(****************************************************************************)

OVERLAY PROCEDURE get_real(VAR result:real);
VAR
  temp : text_line_type;
  temp_val : real;
  garbage : integer;
BEGIN
  readln(temp);
  IF temp=''
    THEN
      valid:=true;

  IF NOT abort_request(temp)
    THEN
      IF temp<>''
        THEN
          BEGIN
            VAL(temp,temp_val,garbage);
            IF garbage=0
              THEN
                BEGIN
                  valid:=true;
                  result:=temp_val;
                END
              ELSE
                result:=0.0;
          END;
END;
