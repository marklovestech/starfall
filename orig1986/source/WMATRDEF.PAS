{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : WMATDEF.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These are the type and var declarations for the      ***)
(***                 matrix - the basic data structure for PLAYGAME       ***)
(*** Input         : N/A                                                  ***)
(*** Output        : N/A                                                  ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

TYPE

  world_mat_column_ptr                 = ^world_matrix_column;

  world_matrix_column                  = ARRAY[1..world_height]
                                         of land_ptr;

  world_mat_type                       = ARRAY[1..world_width]
                                         of world_mat_column_ptr;
VAR
  world_matrix                         : world_mat_type;
