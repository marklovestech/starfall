{&H MYLIST.PAS - A listing program that improves upon some others }
{&P }

(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : MYLIST.PAS                                           ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This program is a modification of TLIST.COM of TURBO ***)
(***                 fame. It labels the tops of the pages and brings in  ***)
(***                 the include files.  It also numbers the lines in the ***)
(***                 include file, a very useful addition.  This program  ***)
(***                 also adds two new compiler directives - &H and &P    ***)
(***                 These options put headers on the top of the pages    ***)
(***                 and paginate the file.                               ***)
(*** Input         : The file name to list and the file name to list to.  ***)
(*** Output        : The destination file.                                ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROGRAM program_lister(input,output);

CONST
  lines_per_page      = 55;    (* 55 lines of data per page  *)

  formfeed            = #12;

TYPE

  filename_type       = string[40];

  file_line_type      = string[255];

VAR
  current_line        : integer;           (* line on page *)
  line_number         : integer;           (* total line_number *)
  include_number      : integer;           (* line in include file *)
  main_name           : filename_type;     (* Name of main file *)
  include_name        : filename_type;     (* Name of include file *)
  file_line           : file_line_type;    (* current file line *)
  current_header_line : file_line_type;
  current_page_number : integer;
  dashed_line         : file_line_type;
  out_file            : text;              (* Listing file spec *)
  out_name            : filename_type;     (* Listing file name *)

{&H Main Procedure Division of MYLIST.PAS }
{&P}
(****************************************************************************)
(***  GET MAIN NAME  :  This procedure goes and gets the two needed file  ***)
(***  names from the user before it goes on.                              ***)
(****************************************************************************)

PROCEDURE get_main_name;
BEGIN
  ClrScr;
  writeln('MYLIST - Written by Mark Porter');
  writeln;
  writeln;
  write('File name to list      :');
  readln(main_name);
  writeln;
  write('File to list to [PRN:] :');
  readln(out_name);
  IF out_name=''
    THEN
      out_name:='PRN:';
END;

(****************************************************************************)
(*** FORMFEED : Here we just write an ascii 12 (FF) to the current file   ***)
(****************************************************************************)

PROCEDURE do_formfeed;
BEGIN
  writeln(out_file,formfeed);
END;

PROCEDURE initialize_printer;
BEGIN
  do_formfeed;
END;

(****************************************************************************)
(***  OPEN A NEW PAGE : Here we write out the beginning header of the new ***)
(***  page.  Note that this entire program is set up for a 132 column     ***)
(***  printer.                                                            ***)
(****************************************************************************)

PROCEDURE open_a_new_page;
VAR
  loop : integer;
BEGIN
  writeln(out_file,dashed_line);
  write(out_file,'                |');

  FOR loop:=18 to (66-(length(current_header_line) DIV 2)) DO
    write(out_file,' ');

  write(out_file,current_header_line);

  FOR loop:=66+(length(current_header_line) DIV 2) TO 115 DO
    write(out_file,' ');

  current_page_number:=succ(current_page_number);

  writeln(out_file,'Page : ',current_page_number:3,'      |');
  write(out_file,'                |  FILE : ',main_name);

  FOR loop:=24+length(main_name) TO 66 DO
    write(out_file,' ');

  write(out_file,'INCLUDED FILE : ',include_name);

  FOR loop:=66+17+length(include_name) TO 129 DO
    write(out_file,' ');

  writeln(out_file,'|');
  writeln(out_file,dashed_line);
  current_line:=1;
END;

PROCEDURE end_a_page;
BEGIN
  writeln(out_file,dashed_line);
  current_line:=1;
  do_formfeed;
END;

PROCEDURE print_a_line(line : file_line_type);
VAR
  loop : integer;
BEGIN
  line_number:=succ(line_number);
  current_line:=succ(current_line);
  IF include_name<>'NONE'
    THEN
      include_number:=succ(include_number);
  IF current_line>lines_per_page
    THEN
      BEGIN
        end_a_page;
        open_a_new_page;
      END;
  IF length(line)>100
    THEN
      BEGIN
        print_a_line(Copy(line,1,100));
        print_a_line(concat('/CONT/ : ',Copy(line,100,length(line)-99)));
      END
    ELSE
      BEGIN
        write(out_file,'                |',line_number:5,':',include_number:4,'|',line);
      (* This section usually prints a bar on the far right of the page. *)
      (* It has been taken out for development speed reasons.            *)
      (*  FOR loop:=28+length(line) TO 131 DO                            *)
      (*    write(out_file,' ');                                           *)
      (*    writeln(out_file,'|');                                         *)
        writeln(out_file);
      END;
END;

(****************************************************************************)
(*** PROCESS FILE : This is the main procedure of the program.  It looks  ***)
(*** through the file at all times for the various compiler directives,   ***)
(*** and acts accordingly.  Note that it is recursive, so that it may     ***)
(*** process include files inside of include files, etc.                  ***)
(****************************************************************************)

PROCEDURE process_file(file_name : filename_type);
VAR
  current_file : text;
  file_line    : file_line_type;
  command_part : string[4];
  success      : boolean;

BEGIN
  success:=false;
  assign(current_file,file_name);
  {$I-}  (* Make sure we don't bomb out of TURBO *)
  reset(current_file);
  {$I+}  (* Turn TURBO IO checking back on.      *)

  IF IORESULT=0
    THEN
      BEGIN
        success:=true;
        WHILE NOT EOF(current_file) DO
          BEGIN
            readln(current_file,file_line);
            print_a_line(file_line);
            IF length(file_line)>=4
              THEN
                BEGIN
                  command_part:=Copy(file_line,1,4);
                  IF (command_part='{&I ') OR
                     (command_part='{$I ')
                    THEN
                      BEGIN
                        include_name:=Copy(file_line,5,length(file_line)-4);
                        include_name:=Copy(include_name,1,Pos('}',include_name)-1);
                        include_number:=0;
                        process_file(include_name);
                        include_name:='NONE';
                        include_number:=0;
                      END
                    ELSE
                      IF (command_part='(*&I') OR
                         (command_part='(*$I')
                        THEN
                          BEGIN
                            include_name:=Copy(file_line,6,length(file_line)-5);
                            include_name:=Copy(include_name,1,Pos('*)',include_name)-1);
                            include_number:=0;
                            process_file(include_name);
                            include_name:='NONE';
                            include_number:=0;
                          END
                    ELSE
                      IF (command_part='{&P}') OR
                         (command_part='{&P ') OR
                         (command_part='(*&P')
                        THEN
                          BEGIN
                            end_a_page;
                            open_a_new_page;
                          END
                        ELSE
                          IF (command_part='{&H ')
                            THEN
                              BEGIN
                                current_header_line:=Copy(file_line,5,length(file_line)-4);
                                current_header_line:=Copy(current_header_line,1,Pos('}',current_header_line)-1);
                              END
                            ELSE
                              IF (command_part='(*&H')
                                THEN
                                  BEGIN
                                    current_header_line:=Copy(file_line,6,length(file_line)-5);
                                    current_header_line:=Copy(current_header_line,1,Pos('*)',current_header_line)-1);
                                  END;
                END;
          END;
      END
    ELSE
      BEGIN
        file_line:=concat('****** COULD NOT OPEN FILE : ',file_name,' *****');
        writeln(file_line);
        print_a_line(file_line);
      END;
  IF success
    THEN
      close(current_file);
END;

(****************************************************************************)
(*** INITIALIZATION : This procedure just initializes all of the variables***)
(*** needed in the program, including opening up the various files, etc.  ***)
(****************************************************************************)

PROCEDURE initialization;
BEGIN
  dashed_line:=concat('                ----------------------------------------------------------',
                      '-----------------------------------------------------------');
  current_page_number:=0;
  include_name:='NONE';
  line_number:=0;
  include_number:=0;
  get_main_name;
  ASSIGN(out_file,out_name);
  rewrite(out_file);
  current_header_line:=concat('Listing of ',main_name,'.');
  initialize_printer;
END;

{&H MYLIST.PAS - Main program segment }
{&P}
(****************************************************************************)
(*** MYLIST.PAS - MAINLINE CODE                                           ***)
(****************************************************************************)

BEGIN
  initialization;
  open_a_new_page;
  process_file(main_name);
  end_a_page;
  close(out_file);
END.