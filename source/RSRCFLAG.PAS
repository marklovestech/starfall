{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : RSRCFLAG.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These routines all deal, in various ways, with the   ***)
(***                 bits in the flags byte of a resource.                ***)
(*** Input         : See Particular Procedure                             ***)
(*** Output        : See Particular Procedure                             ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

(****************************************************************************)
(*** SET RESOURCE FLAG FOUND, EXTRACTED, SELECTED : These procedures set  ***)
(*** bits 0,1,2 respectively in the flags byte passed in to the value     ***)
(*** passed in in the value variable.                                     ***)
(****************************************************************************)

PROCEDURE Set_resource_flag_found(VAR flags: byte;
                                  value    : boolean);
BEGIN
  CASE value OF
    true  : flags:=flags OR 1;
    false : flags:=flags AND 254;
  END;
END;

PROCEDURE Set_resource_flag_extracted(VAR flags: byte;
                                      value    : boolean);
BEGIN
  CASE value OF
    true  : flags:=flags OR 2;
    false : flags:=flags AND 253;
  END;
END;

PROCEDURE Set_resource_flag_selected(VAR flags: byte;
                                     value    : boolean);
BEGIN
  CASE value OF
    true  : flags:=flags OR 4;
    false : flags:=flags AND 251;
  END;
END;

(****************************************************************************)
(*** VALUE OF RESOURCE FLAG FOUND, EXTRACTED, SELECTED : These three      ***)
(*** functions look into the flags byte passed in and return the value    ***)
(*** of that bit.                                                         ***)
(****************************************************************************)

FUNCTION Value_of_resource_flag_found(flags:byte):boolean;
BEGIN
  CASE flags AND 1 OF
    1 : Value_of_resource_flag_found:=true;
    0 : Value_of_resource_flag_found:=false;
  END;
END;

FUNCTION Value_of_resource_flag_extracted(flags:byte):boolean;
BEGIN
  CASE flags AND 2 OF
    2 : Value_of_resource_flag_extracted:=true;
    0 : Value_of_resource_flag_extracted:=false;
  END;
END;

FUNCTION Value_of_resource_flag_selected(flags:byte):boolean;
BEGIN
  CASE flags AND 4 OF
    4 : Value_of_resource_flag_selected:=true;
    0 : Value_of_resource_flag_selected:=false;
  END;
END;

(****************************************************************************)
(*** TEMPERATURE FROM CLIMATE : This looks into the climate byte and pulls***)
(*** off the upper 4 bits, which define the temperature, and pass them    ***)
(*** back.                                                                ***)
(****************************************************************************)

FUNCTION temperature_from_climate(climate:byte):byte;
BEGIN
  temperature_from_climate:=climate DIV 16;
END;

(****************************************************************************)
(*** MOISTURE FROM CLIMATE : This looks into the climate byte passed in   ***)
(*** and pulls off the lower 4 bits, which define the moisture, and pass  ***)
(*** them back.                                                           ***)
(****************************************************************************)

FUNCTION moisture_from_climate(climate:byte):byte;
BEGIN
  moisture_from_climate:=climate MOD 16;
END;

(****************************************************************************)
(*** SET TEMPERATURE : This procedure goes in and sets the upper 4 bits   ***)
(*** of the requested climate byte to be the given temperature.           ***)
(****************************************************************************)

PROCEDURE set_temperature(x,y,temp:integer);
BEGIN
  IF land_at(x,y)
    THEN
      world_matrix[x]^[y]^.climate:=
        moisture_from_climate(world_matrix[x]^[y]^.climate)+temp*16;
END;

(****************************************************************************)
(*** SET MOISTURE : This procedure goes in and sets the lower 4 bits of   ***)
(*** of the requested climte byte to be the given moisture.               ***)
(****************************************************************************)

PROCEDURE set_moisture(x,y,moisture:integer);
BEGIN
  IF land_at(x,y)
    THEN
      world_matrix[x]^[y]^.climate:=
        (world_matrix[x]^[y]^.climate DIV 16)*16 + moisture;
END;