{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : RDRSRCFL.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure reads in the the massive file that    ***)
(***                 holds all of the resources on the disk.  This file   ***)
(***                 is accessed by WRLDSHAK, MAKEWRLD, PLAYGAME.         ***)
(*** Input         : RESOURCE.DAT file on default disk drive.             ***)
(*** Output        : A filled RESOURCES array.                            ***)
(*** Special Notes : This file is a text file because it is necessary     ***)
(***                 to store dynamically allocated trees on disk, and    ***)
(***                 Pascal is a little bit short in dynamically typed    ***)
(***                 records.                                             ***)
(****************************************************************************)

OVERLAY PROCEDURE read_resource_file;
VAR
  choice:char;
  loop:integer;

(************************************************************************)
(*** FILE TO BOOLEAN : This converts a T or F character to a boolean  ***)
(*** true or false after coming in from the file.                     ***)
(************************************************************************)

  FUNCTION file_to_boolean(file_value:char):boolean;
  BEGIN
    CASE file_value OF
      'T'  : file_to_boolean:=true;
      'F'  : file_to_boolean:=false;
    END;
  END;

(************************************************************************)
(*** READ INGREDIENT TREE : This procedure reads in an ingredient     ***)
(*** tree from the disk.  It uses the standard method of reading the  ***)
(*** word DATA from the file when there is a good node and the WORD   ***)
(*** word NIL when the tree is ending.                                ***)
(************************************************************************)

  FUNCTION read_ingredient_tree:ingredient_ptr;
  VAR
    temp_str  : string10;
    node      : ingredient_ptr;
    temp_char : char;
  BEGIN
    readln(resource_file,temp_str);
    IF temp_str='DATA'
      THEN
        BEGIN
          new(node);
          WITH node^ DO
            BEGIN
              readln(resource_file,resource_num);
              readln(resource_file,quantity);
              readln(resource_file,time_factor);
            END;
          node^.next:=read_ingredient_tree;
          node^.alternatives:=read_ingredient_tree;
          read_ingredient_tree:=node;
        END
      ELSE
        read_ingredient_tree:=NIL;
  END;

(************************************************************************)
(*** READ RESOURCE FROM FILE : This procedure goes out and reads in   ***)
(*** all of the many fields in the resource description record.       ***)
(************************************************************************)

  PROCEDURE read_resource_from_file(VAR resource : resource_desc );
  VAR
    file_boolean : char;
  BEGIN
    WITH resource DO
      BEGIN
        readln(resource_file,resource_name);
        readln(resource_file,resource_units);
        readln(resource_file,score_value);
        readln(resource_file,base_cost);
        readln(resource_file,empty_weight);
        readln(resource_file,file_boolean);
        naturally_occuring:=file_to_boolean(file_boolean);
        readln(resource_file,file_boolean);
        subsurface_resource:=file_to_boolean(file_boolean);
        readln(resource_file,file_boolean);
        expendable:=file_to_boolean(file_boolean);
        readln(resource_file,file_boolean);
        movable:=file_to_boolean(file_boolean);
        readln(resource_file,typical_trader_amount);
        readln(resource_file,typical_purity);
        readln(resource_file,basic_resource_need[1]);
        readln(resource_file,basic_resource_need[2]);
        readln(resource_file,basic_resource_need[3]);
        readln(resource_file,basic_resource_need[4]);
        readln(resource_file,basic_need_amount[1]);
        readln(resource_file,basic_need_amount[2]);
        readln(resource_file,basic_need_amount[3]);
        readln(resource_file,basic_need_amount[4]);
        readln(resource_file,active_resource_need[1]);
        readln(resource_file,active_resource_need[2]);
        readln(resource_file,active_resource_need[3]);
        readln(resource_file,active_resource_need[4]);
        readln(resource_file,active_need_amount[1]);
        readln(resource_file,active_need_amount[2]);
        readln(resource_file,active_need_amount[3]);
        readln(resource_file,active_need_amount[4]);
        readln(resource_file,file_boolean);
        usable_for_exploration:=file_to_boolean(file_boolean);
        readln(resource_file,exploration_speed);
        readln(resource_file,exploratory_test_effectiveness[1]);
        readln(resource_file,exploratory_test_effectiveness[2]);
        readln(resource_file,exploratory_test_effectiveness[3]);
        readln(resource_file,exploratory_test_effectiveness[4]);
        readln(resource_file,file_boolean);
        usable_for_extraction:=file_to_boolean(file_boolean);
        readln(resource_file,extraction_speed);
        readln(resource_file,file_boolean);
        extractable:=file_to_boolean(file_boolean);
        readln(resource_file,typical_deposit_size);
        readln(resource_file,likelihood_of_occurence);
        readln(resource_file,deposit_contagion_ratio);
        readln(resource_file,file_boolean);
        usable_for_development:=file_to_boolean(file_boolean);
        readln(resource_file,development_speed);
        readln(resource_file,file_boolean);
        developable:=file_to_boolean(file_boolean);
        readln(resource_file,development_result);
        readln(resource_file,start_resource_needed_to_develop);
        readln(resource_file,end_resource_needed_to_develop);
        readln(resource_file,file_boolean);
        usable_for_refinement:=file_to_boolean(file_boolean);
        readln(resource_file,refinement_speed);
        readln(resource_file,file_boolean);
        refineable:=file_to_boolean(file_boolean);
        readln(resource_file,refinement_result);
        readln(resource_file,start_resource_needed_to_refine);
        readln(resource_file,end_resource_needed_to_refine);
        readln(resource_file,file_boolean);
        usable_for_transportation:=file_to_boolean(file_boolean);
        readln(resource_file,cargo_capacity);
        readln(resource_file,air_speed);
        readln(resource_file,land_speed);
        readln(resource_file,water_speed);
        readln(resource_file,file_boolean);
        produceable:=file_to_boolean(file_boolean);
        readln(resource_file,time_to_produce);
        production_requirements:=read_ingredient_tree;
      END;
  END;

{&P}
(****************************************************************************)
(*** READ RESOURCE FILE : MAINLINE CODE                                   ***)
(****************************************************************************)

BEGIN
  ClrScr;
  writeln('Program Initialization:');
  writeln;
  write('Reading resource parameters [RESOURCE.DAT] :');
  Assign(resource_file,'RESOURCE.DAT');
  reset(resource_file);
  FOR loop:=1 to max_resource DO
    BEGIN
      write('.');
      read_resource_from_file(resources[loop]);
    END;
  close(resource_file);
END;
