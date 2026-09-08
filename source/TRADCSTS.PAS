{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : TRADCSTS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These two procedures decide just how much stuff is   ***)
(***                 worth to the trader.                                 ***)
(*** Input         : Resource number to find out about                    ***)
(*** Output        : The cost or value of that resource to the trader     ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

FUNCTION cost_of(resource_num : byte):real;

BEGIN
  cost_of:=1.05*resources[resource_num].base_cost;
END;

FUNCTION value_of(resource_num : byte):real;
BEGIN
  value_of:=0.95*resources[resource_num].base_cost;
END;
