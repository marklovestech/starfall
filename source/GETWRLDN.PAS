{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : GETWRLDN.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures go out and ask the user for the two ***)
(***                 kinds of names that we need for the world.           ***)
(*** Input         : None.                                                ***)
(*** Output        : The global variables WORLD_FILE_NAME and WORLD_NAME  ***)
(***                 are given the appropriate values, depending on which ***)
(***                 of the two procedures is called.                     ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE get_world_file_name;
VAR
  temp:string30;
BEGIN
  writeln;
  writeln;
  write('   File name of world or ABORT [',world_file_name,'] ? ');
  readln(temp);
  IF temp<>''
    THEN
      world_file_name:=temp;

  IF world_file_name='abort'
    THEN
      world_file_name:='ABORT';

  writeln;
END;

OVERLAY PROCEDURE get_world_name;
VAR
  temp:string30;
BEGIN
  ClrScr;
  writeln('Giving the world a title:');
  writeln;
  writeln;
  write('   Name of the world [',world_name,'] ?');
  readln(temp);
  IF temp<>''
    THEN
      world_name:=temp;
  writeln;
END;
