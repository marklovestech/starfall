{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : HRLLPRCS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures all handle the human resource list. ***)
(*** Input         : See particular subprogram.                           ***)
(*** Output        : See particular subprogram.                           ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

(****************************************************************************)
(*** INITIALIZE HUMAN RESOURCE LIST : Pretty obvious, huh?                ***)
(****************************************************************************)

OVERLAY PROCEDURE initialize_human_resource_list;
BEGIN
  human_resource_list_root:=NIL;
END;

(****************************************************************************)
(*** ADD TO HUMAN RESOURCE LIST : This procedure takes in an X,Y coord.   ***)
(*** and links it into the human resource list at the beginning.  Thus,   ***)
(*** the most recently accessed blocks are accessed faster. Neat, huh?    ***)
(****************************************************************************)

OVERLAY PROCEDURE add_to_human_resource_list(x,y:integer);
VAR
  temp_ptr : human_resource_list_ptr;
BEGIN
  new(temp_ptr);
  temp_ptr^.next:=human_resource_list_root;
  temp_ptr^.prev:=NIL;
  temp_ptr^.x:=x;
  temp_ptr^.y:=y;
  IF temp_ptr^.next<>NIL
    THEN
      temp_ptr^.next^.prev:=temp_ptr;
  human_resource_list_root:=temp_ptr;
END;

(****************************************************************************)
(*** DELETE FROM HUMAN RESOURCE LIST : This procedure is handed an X,Y    ***)
(*** coordinate and it goes and looks in the human resource list to find  ***)
(*** if that block is there.  If so, it deletes it.  If not, it doesn't   ***)
(*** complain, it just goes on.                                           ***)
(****************************************************************************)

OVERLAY PROCEDURE delete_from_human_resource_list(x,y:integer);
VAR
  temp_ptr : human_resource_list_ptr;
BEGIN
  temp_ptr:=human_resource_list_root;
  WHILE temp_ptr<>NIL DO
    BEGIN
      IF (temp_ptr^.x=x) AND (temp_ptr^.y=y)
        THEN
          BEGIN
            IF temp_ptr=human_resource_list_root
              THEN
                BEGIN
                  human_resource_list_root:=temp_ptr^.next;
                  dispose(temp_ptr);
                END
              ELSE
                BEGIN
                  IF temp_ptr^.prev<>NIL
                    THEN
                      temp_ptr^.prev^.next:=temp_ptr^.next;
                  IF temp_ptr^.next<>NIL
                    THEN
                      temp_ptr^.next^.prev:=temp_ptr^.prev;
                  dispose(temp_ptr);
                END;
            temp_ptr:=NIL;
          END
        ELSE
          temp_ptr:=temp_ptr^.next;
    END;
END;

(****************************************************************************)
(*** SORT HUMAN RESOURCES LINKED LIST : In the world inventory, it is very***)
(*** useful to have the blocks that have resources appear in some sort of ***)
(*** coherent order.  That is what this procedure does.  Making two       ***)
(*** assumptions: 1) Turbo is blindingly fast, and 2) the human resource  ***)
(*** list is relatively short, we use a boring bubble to sort the list.   ***)
(****************************************************************************)

OVERLAY PROCEDURE sort_human_resources_linked_list;
VAR
  temp_ptr : human_resource_list_ptr;
  changed  : boolean;
  save_x   : integer;
  save_y   : integer;
BEGIN
  temp_ptr:=human_resource_list_root;
  IF temp_ptr<>NIL
    THEN
      BEGIN
        REPEAT
          changed:=false;
          temp_ptr:=human_resource_list_root;
          WHILE temp_ptr^.next<>NIL DO
            BEGIN
              IF (temp_ptr^.next^.x<temp_ptr^.x) OR
                 ((temp_ptr^.next^.x=temp_ptr^.x) AND
                  (temp_ptr^.next^.y<temp_ptr^.y))
                THEN
                  BEGIN
                    save_x:=temp_ptr^.x;
                    save_y:=temp_ptr^.y;
                    temp_ptr^.x:=temp_ptr^.next^.x;
                    temp_ptr^.y:=temp_ptr^.next^.y;
                    temp_ptr^.next^.x:=save_x;
                    temp_ptr^.next^.y:=save_y;
                    changed:=true;
                  END;
              temp_ptr:=temp_ptr^.next;
            END;
        UNTIL (NOT changed);
      END;
END;
