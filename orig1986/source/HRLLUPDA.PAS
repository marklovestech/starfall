{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : HRLLUPDA.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure goes and takes care of whether a      ***)
(***                 given block should be in the human resource list.    ***)
(*** Input         : x,y coordinate.                                      ***)
(*** Output        : None.                                                ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE update_human_resource_list;
BEGIN
  IF present_in_human_resource_list(x,y)
    THEN
      BEGIN
        IF NOT human_resources_at(x,y)
          THEN
            delete_from_human_resource_list(x,y);
      END
    ELSE
      IF human_resources_at(x,y)
        THEN
          add_to_human_resource_list(x,y);
  sort_human_resources_linked_list;
END;
