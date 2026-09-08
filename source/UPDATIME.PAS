{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : UPDATIME.PAS                                         ***)
(*** Author        : Todd Carter, Intellisoft, Inc.                       ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure issues a MS-DOS interrupt, and        ***)
(***                 returns the system clock value to TURBO, in three    ***)
(***                 integer variables.                                   ***)
(*** Input         : None.                                                ***)
(*** Output        : Hour, Minute, Second : integer (current time)        ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE Update_Time(VAR Hour,Min,Sec:integer);

TYPE
    Registers = RECORD
                    AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags : Integer;
                END;

VAR
    Regs : Registers;

BEGIN
    WITH Regs DO
        BEGIN
            AX := $2C00;
            MsDos(Regs);
            Hour := Hi(CX);
            Min  := Lo(CX);
            Sec  := Hi(DX);
        END;
END;

