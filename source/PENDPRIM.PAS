{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : PENDPRIM.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This function does a lookup of an action type and    ***)
(***                 then returns the text that represents that action    ***)
(***                 type.                                                ***)
(*** Input         : Action type                                          ***)
(*** Output        : Text for action type                                 ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

FUNCTION text_for_action_type(action_type:byte):string30;
BEGIN
  CASE action_type OF
    exploration_action     : text_for_action_type:='MINERAL EXPLORATION';
    extraction_action      : text_for_action_type:='MINERAL EXTRACTION';
    development_action     : text_for_action_type:='SURFACE DEVELOPMENT';
    refinement_action      : text_for_action_type:='MINERAL REFINEMENT';
    production_action      : text_for_action_type:='RESOURCE PRODUCTION';
    transportation_action  : text_for_action_type:='TRANSPORTATION';
    trader_arriving_action : text_for_action_type:='TRADER WILL ARRIVE';
    trader_leaving_action  : text_for_action_type:='TRADER WILL LEAVE';
    else                     text_for_action_type:='MARK MESSED UP';
  END;
END;

