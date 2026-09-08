{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : HRPRESNT.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This function goes out and finds if a land item is   ***)
(***                 already present in the human resource list.          ***)
(*** Input         : x,y coordinate.                                      ***)
(*** Output        : boolean value of true or false                       ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

FUNCTION present_in_human_resource_list(x,y:integer):boolean;
VAR
  temp_ptr    : human_resource_list_ptr;
  temp_result : boolean;
BEGIN
  temp_result:=false;
  temp_ptr:=human_resource_list_root;
  WHILE (temp_ptr<>NIL) AND (temp_result=false) DO
    BEGIN
      IF (temp_ptr^.x=x) AND (temp_ptr^.y=y)
        THEN
          temp_result:=true
        ELSE
          temp_ptr:=temp_ptr^.next;
    END;
  present_in_human_resource_list:=temp_result;
END;
