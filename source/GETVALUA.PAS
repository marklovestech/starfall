{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : GETVALUA.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This routine determines if the user is trying to     ***)
(***                 abort from on of the GETBYTE, GETINTEGER, etc        ***)
(***                 routines.                                            ***)
(*** Input         : A 80 character string typed by the user.             ***)
(*** Output        : True or false, depending of string                   ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

FUNCTION abort_request(entry : text_line_type):boolean;
BEGIN
  abort_request:=false;
  IF (entry='exit') OR
     (entry='EXIT') OR
     (entry='quit') OR
     (entry='QUIT') OR
     (entry='abort') OR
     (entry='ABORT') OR
     (entry='end') OR
     (entry='END')
    THEN
      BEGIN
        abort_request:=true;
        abort_action:=true;
      END;
END;
