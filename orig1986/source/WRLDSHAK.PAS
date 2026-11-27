{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : WRLDSHAK.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This program lets the user modify the world          ***)
(***                 resources in any way that they deem necessary.       ***)
(***                 Note that this can be very dangerous, if the user    ***)
(***                 does not know what they are doing.                   ***)
(*** Input         : N/A                                                  ***)
(*** Output        : N/A                                                  ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROGRAM World_shaker(input,output,resource_file,main_program);

{$I CTVSEC.PAS}

CONST
  max_param                            = 59;
  invalid_resource                     = '<INVALID RESOURCE>';

VAR
  parameter_titles                     : ARRAY[1..max_param] of text_line_type;
  file_read                            : boolean;

{$I TIMER.PAS}
{$I GETKEY.PAS}
{$I GETVALUA.PAS}
{$I GETVALUS.PAS}
{$I NOISE.PAS}

(****************************************************************************)
(*** CREATE SURFACE RESOURCE MATRIX : This is a very unfriendly           ***)
(*** procedure which (sort of) allows you to modifiy the surface matrix.  ***)
(****************************************************************************)

PROCEDURE create_surface_resource_matrix;
VAR
  temperature_loop    : integer;
  hydrograph_loop     : integer;
BEGIN
  ASSIGN(surface_matrix_file,'SURFMATR.DAT');
  rewrite(surface_matrix_file);
  FOR temperature_loop:=0 to 15 DO
    FOR hydrograph_loop := 0 to 15 DO
      BEGIN
        REPEAT
          write('SURFACE MATRIX [',temperature_loop:2,',',hydrograph_loop:2,'] = ?');
          get_byte(surface_resource_matrix[temperature_loop,hydrograph_loop]);
        UNTIL valid;
        writeln(surface_matrix_file,
                surface_resource_matrix[temperature_loop,hydrograph_loop]);
      END;
  close(surface_matrix_file);
END;

(****************************************************************************)
(*** CLEAR RESOURCE : This clears out the contents of a resource to the   ***)
(*** default values                                                       ***)
(****************************************************************************)

PROCEDURE clear_resource(resource_number : byte);
BEGIN
  WITH resources[resource_number] DO
    BEGIN
      resource_name            := invalid_resource;
      resource_units           := '';
      score_value              := 0;
      base_cost                := 0.0;
      empty_weight             := 0.0;
      naturally_occuring       := false;
      subsurface_resource      := false;
      expendable               := false;
      movable                  := true;
      typical_trader_amount    := 0.0;
      typical_purity           := 0.0;
      basic_resource_need[1]   := 0;
      basic_resource_need[2]   := 0;
      basic_resource_need[3]   := 0;
      basic_resource_need[4]   := 0;
      basic_need_amount[1]     := 0.0;
      basic_need_amount[2]     := 0.0;
      basic_need_amount[3]     := 0.0;
      basic_need_amount[4]     := 0.0;
      active_resource_need[1]  := 0;
      active_resource_need[2]  := 0;
      active_resource_need[3]  := 0;
      active_resource_need[4]  := 0;
      active_need_amount[1]    := 0.0;
      active_need_amount[2]    := 0.0;
      active_need_amount[3]    := 0.0;
      active_need_amount[4]    := 0.0;

      usable_for_exploration   := false;
      exploration_speed        := 0.0;
      exploratory_test_effectiveness[1]  := 0;
      exploratory_test_effectiveness[2]  := 0;
      exploratory_test_effectiveness[3]  := 0;
      exploratory_test_effectiveness[4]  := 0;

      usable_for_extraction    := false;
      extraction_speed         := 0.0;
      extractable              := false;
      typical_deposit_size     := 0.0;
      likelihood_of_occurence  := 0;
      deposit_contagion_ratio  := 0;

      usable_for_development   := false;
      development_speed        := 0.0;
      developable              := false;
      development_result       := 0;
      start_resource_needed_to_develop := 0;
      end_resource_needed_to_develop   := 0;

      usable_for_refinement    := false;
      refinement_speed         := 0.0;
      refineable               := false;
      refinement_result        := 0;
      start_resource_needed_to_refine := 0;
      end_resource_needed_to_refine   := 0;

      usable_for_transportation:= false;
      cargo_capacity           := 0.0;
      air_speed                := 0.0;
      land_speed               := 0.0;
      water_speed              := 0.0;

      produceable              := false;
      time_to_produce          := 0;
      production_requirements  := NIL;
   END;
END;

(****************************************************************************)
(*** CLEAR ALL RESOURCES : This iteratively clears all 255 resources      ***)
(****************************************************************************)

PROCEDURE clear_all_resources;
VAR
  loop : integer;
BEGIN
  ClrScr;
  writeln('Programming Initialization:');
  writeln;
  write('Clearing out resources in memory :');
  FOR loop:=1 to max_resource DO
    BEGIN
      write('.');
      clear_resource(loop);
    END;
END;

(****************************************************************************)
(***  INIT PARAM TITLES : This puts the text for all 59 parameter titles  ***)
(***  into the parameter_titles array for later use.                      ***)
(****************************************************************************)

PROCEDURE init_param_titles;
BEGIN
  parameter_titles[1] := 'RESOURCE NAME      ';
  parameter_titles[2] := 'RESOURCE UNITS                    ';
  parameter_titles[3] := 'SCORE VALUE                       ';
  parameter_titles[4] := 'BASIC COST                        ';
  parameter_titles[5] := 'EMPTY WEIGHT                      ';
  parameter_titles[6] := 'NATURALLY OCCURING RESOURCE       ';
  parameter_titles[7] := 'SUBSURFACE RESOURCE               ';
  parameter_titles[8] := 'EXPENDABLE RESOURCE               ';
  parameter_titles[9] := 'MOVABLE RESOURCE                  ';
  parameter_titles[10] :='TYPICAL TRADER AMOUNT             ';
  parameter_titles[11] :='TYPICAL PURITY                    ';
  parameter_titles[12] :='BASIC RESOURCE NEED #1            ';
  parameter_titles[13] :='BASIC RESOURCE NEED #2            ';
  parameter_titles[14] :='BASIC RESOURCE NEED #3            ';
  parameter_titles[15] :='BASIC RESOURCE NEED #4            ';
  parameter_titles[16] :='BASIC NEED AMOUNT #1              ';
  parameter_titles[17] :='BASIC NEED AMOUNT #2              ';
  parameter_titles[18] :='BASIC NEED AMOUNT #3              ';
  parameter_titles[19] :='BASIC NEED AMOUNT #4              ';
  parameter_titles[20] :='ACTIVE RESOURCE NEED #1           ';
  parameter_titles[21] :='ACTIVE RESOURCE NEED #2           ';
  parameter_titles[22] :='ACTIVE RESOURCE NEED #3           ';
  parameter_titles[23] :='ACTIVE RESOURCE NEED #4           ';
  parameter_titles[24] :='ACTIVE NEED AMOUNT #1             ';
  parameter_titles[25] :='ACTIVE NEED AMOUNT #2             ';
  parameter_titles[26] :='ACTIVE NEED AMOUNT #3             ';
  parameter_titles[27] :='ACTIVE NEED AMOUNT #4             ';
  parameter_titles[28] :='USABLE FOR EXPLORATION            ';
  parameter_titles[29] :='EXPLORATION SPEED                 ';
  parameter_titles[30] :='EXPLORATORY TEST EFFECTIVENESS #1 ';
  parameter_titles[31] :='EXPLORATORY TEST EFFECTIVENESS #2 ';
  parameter_titles[32] :='EXPLORATORY TEST EFFECTIVENESS #3 ';
  parameter_titles[33] :='EXPLORATORY TEST EFFECTIVENESS #4 ';
  parameter_titles[34] :='USABLE FOR EXTRACTION             ';
  parameter_titles[35] :='EXTRACTION SPEED                  ';
  parameter_titles[36] :='EXTRACTABLE                       ';
  parameter_titles[37] :='TYPICAL DEPOSIT SIZE              ';
  parameter_titles[38] :='LIKELIHOOD OF OCCURENCE           ';
  parameter_titles[39] :='DEPOSIT CONTAGION RATIO           ';
  parameter_titles[40] :='USABLE FOR DEVELOPMENT            ';
  parameter_titles[41] :='DEVELOPMENT SPEED                 ';
  parameter_titles[42] :='DEVELOPABLE                       ';
  parameter_titles[43] :='DEVELOPMENT RESULT                ';
  parameter_titles[44] :='START RESOURCE NEEDED TO DEVELOP  ';
  parameter_titles[45] :='END RESOURCE NEEDED TO DEVELOP    ';
  parameter_titles[46] :='USABLE FOR REFINEMENT             ';
  parameter_titles[47] :='REFINEMENT SPEED                  ';
  parameter_titles[48] :='REFINEABLE                        ';
  parameter_titles[49] :='REFINEMENT RESULT                 ';
  parameter_titles[50] :='START RESOURCE NEEDED TO REFINE   ';
  parameter_titles[51] :='END RESOURCE NEEDED TO REFINE     ';
  parameter_titles[52] :='USABLE FOR TRANSPORTATION         ';
  parameter_titles[53] :='CARGO CAPACITY                    ';
  parameter_titles[54] :='AIR SPEED                         ';
  parameter_titles[55] :='LAND SPEED                        ';
  parameter_titles[56] :='WATER SPEED                       ';
  parameter_titles[57] :='PRODUCEABLE                       ';
  parameter_titles[58] :='TIME TO PRODUCE                   ';
  parameter_titles[59] :='PRODUCTION REQUIREMENTS           ';
END;

(****************************************************************************)
(*** BOOLEAN TO FILE : This function prepares a boolean for output        ***)
(*** to a text file.                                                      ***)
(****************************************************************************)

FUNCTION boolean_to_file(boolean_value:boolean):char;
BEGIN
  CASE boolean_value OF
    true   : boolean_to_file:='T';
    false  : boolean_to_file:='F';
  END;
END;

{$I RDRSRCFL.PAS}

(****************************************************************************)
(*** WRITE INGREDIENT TREE : This recursive procedure takes a tree in     ***)
(*** memory and converts each part of it to text before putting it out    ***)
(*** to the resource file.                                                ***)
(****************************************************************************)

  PROCEDURE write_ingredient_tree(tree_root: ingredient_ptr);
  BEGIN
    IF tree_root=NIL
      THEN
        writeln(resource_file,'NIL')
      ELSE
        BEGIN
          WITH tree_root^ DO
            BEGIN
              writeln(resource_file,'DATA');
              writeln(resource_file,resource_num);
              writeln(resource_file,quantity);
              writeln(resource_file,time_factor);
            END;
          write_ingredient_tree(tree_root^.next);
          write_ingredient_tree(tree_root^.alternatives);
        END;
  END;

(****************************************************************************)
(*** WRITE RESOURCE TO FILE : Here we take one resource, passed in, and   ***)
(*** convert it all to text before it is written out.                     ***)
(****************************************************************************)

PROCEDURE write_resource_to_file(VAR resource : resource_desc);
VAR
  temp_ptr : ingredient_ptr;
BEGIN
  WITH resource DO
    BEGIN
      writeln(resource_file,resource_name);
      writeln(resource_file,resource_units);
      writeln(resource_file,score_value);
      writeln(resource_file,base_cost);
      writeln(resource_file,empty_weight);
      writeln(resource_file,boolean_to_file(naturally_occuring));
      writeln(resource_file,boolean_to_file(subsurface_resource));
      writeln(resource_file,boolean_to_file(expendable));
      writeln(resource_file,boolean_to_file(movable));
      writeln(resource_file,typical_trader_amount);
      writeln(resource_file,typical_purity);
      writeln(resource_file,basic_resource_need[1]);
      writeln(resource_file,basic_resource_need[2]);
      writeln(resource_file,basic_resource_need[3]);
      writeln(resource_file,basic_resource_need[4]);
      writeln(resource_file,basic_need_amount[1]);
      writeln(resource_file,basic_need_amount[2]);
      writeln(resource_file,basic_need_amount[3]);
      writeln(resource_file,basic_need_amount[4]);
      writeln(resource_file,active_resource_need[1]);
      writeln(resource_file,active_resource_need[2]);
      writeln(resource_file,active_resource_need[3]);
      writeln(resource_file,active_resource_need[4]);
      writeln(resource_file,active_need_amount[1]);
      writeln(resource_file,active_need_amount[2]);
      writeln(resource_file,active_need_amount[3]);
      writeln(resource_file,active_need_amount[4]);

      writeln(resource_file,boolean_to_file(usable_for_exploration));
      writeln(resource_file,exploration_speed);
      writeln(resource_file,exploratory_test_effectiveness[1]);
      writeln(resource_file,exploratory_test_effectiveness[2]);
      writeln(resource_file,exploratory_test_effectiveness[3]);
      writeln(resource_file,exploratory_test_effectiveness[4]);

      writeln(resource_file,boolean_to_file(usable_for_extraction));
      writeln(resource_file,extraction_speed);
      writeln(resource_file,boolean_to_file(extractable));
      writeln(resource_file,typical_deposit_size);
      writeln(resource_file,likelihood_of_occurence);
      writeln(resource_file,deposit_contagion_ratio);

      writeln(resource_file,boolean_to_file(usable_for_development));
      writeln(resource_file,development_speed);
      writeln(resource_file,boolean_to_file(developable));
      writeln(resource_file,development_result);
      writeln(resource_file,start_resource_needed_to_develop);
      writeln(resource_file,end_resource_needed_to_develop);

      writeln(resource_file,boolean_to_file(usable_for_refinement));
      writeln(resource_file,refinement_speed);
      writeln(resource_file,boolean_to_file(refineable));
      writeln(resource_file,refinement_result);
      writeln(resource_file,start_resource_needed_to_refine);
      writeln(resource_file,end_resource_needed_to_refine);

      writeln(resource_file,boolean_to_file(usable_for_transportation));
      writeln(resource_file,cargo_capacity);
      writeln(resource_file,air_speed);
      writeln(resource_file,land_speed);
      writeln(resource_file,water_speed);

      writeln(resource_file,boolean_to_file(produceable));
      writeln(resource_file,time_to_produce);
      write_ingredient_tree(production_requirements);
    END; (* with *)
END;

(****************************************************************************)
(*** WRITE RESOURCE FILE : This procedure writes the entire array to disk ***)
(****************************************************************************)

PROCEDURE write_resource_file;
VAR
  choice:char;
  loop:integer;
BEGIN
  writeln;
  write('Writing file:');
  Assign(resource_file,'RESOURCE.DAT');
  rewrite(resource_file);
  FOR loop:=1 to max_resource DO
    BEGIN
      write('.');
      write_resource_to_file(resources[loop]);
    END;
  close(resource_file);
END;

(****************************************************************************)
(*** DISPLAY ONE ITEM : Hidden within this procedure are all sorts of     ***)
(*** obvious procedures, like DISPLAY INTEGER.  The purpose of this       ***)
(*** procedure is to figure out what type a parameter number is and then  ***)
(*** to display it in whatever format is necessary.                       ***)
(****************************************************************************)

PROCEDURE display_one_item(resource_number,parameter_number:integer;
                            printer:boolean);

PROCEDURE display_string30(VAR value : string30);
BEGIN
  CASE printer OF
    true : write(lst,value:30);
    false: write(value:30);
  END;
END;

PROCEDURE display_string10(VAR value : string10);
BEGIN
  CASE printer OF
    true   : write(lst,value:15);
    false  : write(value:15);
  END;
END;

PROCEDURE display_boolean(VAR value : boolean);
BEGIN
  CASE printer OF
    true     : CASE value of
                 true : write(lst,'True ':15);
                 false: write(lst,'False':15);
               END;
    false    : CASE value OF
                 true  : write('True ':15);
                 false : write('False':15);
               END;
  END;
END;

PROCEDURE display_byte(VAR value : byte);
BEGIN
  CASE printer OF
    true   : write(lst,value:15);
    false  : write(value:15);
  END;
END;

PROCEDURE display_integer(VAR value : integer);
BEGIN
  CASE printer OF
    true  : write(lst,value:15);
    false : write(value:15);
  END;
END;

PROCEDURE display_real(VAR value : real);
BEGIN
  CASE printer OF
    true  : write(lst,value:20:8);
    false : write(value:20:8);
  END;
END;

PROCEDURE display_one_ingredient(ingredient : ingredient_ptr);
BEGIN
  CASE printer OF
    true : writeln(lst,'        ',ingredient^.quantity:20:8,' ',
                   resources[ingredient^.resource_num].resource_units,' of ',
                   resources[ingredient^.resource_num].resource_name,' (',
                   ingredient^.time_factor:7:3,')');
    false: writeln('        ',ingredient^.quantity:20:8,' ',
                   resources[ingredient^.resource_num].resource_units,' of ',
                   resources[ingredient^.resource_num].resource_name,' (',
                   ingredient^.time_factor:7:3,')');
  END;
END;

PROCEDURE display_one_alternative(ingredient : ingredient_ptr);
BEGIN
  CASE printer OF
    true  : write(lst,'  OR ');
    false : write('  OR ');
  END;
  display_one_ingredient(ingredient);
END;

PROCEDURE display_ingredient_list(VAR resource_list_ptr : ingredient_ptr);
VAR
  temp_ptr : ingredient_ptr;
  temp_alternatives : ingredient_ptr;
BEGIN
  CASE printer OF
    true : writeln(lst);
    false : writeln;
  END;
  temp_ptr:=resource_list_ptr;
  WHILE temp_ptr<>NIL DO
    BEGIN
      display_one_ingredient(temp_ptr);
      temp_alternatives :=temp_ptr^.alternatives;
      WHILE temp_alternatives<>NIL DO
        BEGIN
          display_one_alternative(temp_alternatives);
          temp_alternatives:=temp_alternatives^.alternatives;
        END;
      temp_ptr:=temp_ptr^.next;
    END;
END;

(****************************************************************************)
(*** DISPLAY ONE ITEM - MAINLINE CODE                                     ***)
(****************************************************************************)

BEGIN
  WITH resources[resource_number] DO
    BEGIN
      CASE parameter_number OF
        1   : display_string30(resource_name);
        2   : display_string10(resource_units);
        3   : display_integer(score_value);
        4   : display_real(base_cost);
        5   : display_real(empty_weight);
        6   : display_boolean(naturally_occuring);
        7   : display_boolean(subsurface_resource);
        8   : display_boolean(expendable);
        9   : display_boolean(movable);
        10  : display_real(typical_trader_amount);
        11  : display_real(typical_purity);
        12  : display_byte(basic_resource_need[1]);
        13  : display_byte(basic_resource_need[2]);
        14  : display_byte(basic_resource_need[3]);
        15  : display_byte(basic_resource_need[4]);
        16  : display_real(basic_need_amount[1]);
        17  : display_real(basic_need_amount[2]);
        18  : display_real(basic_need_amount[3]);
        19  : display_real(basic_need_amount[4]);
        20  : display_byte(active_resource_need[1]);
        21  : display_byte(active_resource_need[2]);
        22  : display_byte(active_resource_need[3]);
        23  : display_byte(active_resource_need[4]);
        24  : display_real(active_need_amount[1]);
        25  : display_real(active_need_amount[2]);
        26  : display_real(active_need_amount[3]);
        27  : display_real(active_need_amount[4]);
        28  : display_boolean(usable_for_exploration);
        29  : display_real(exploration_speed);
        30  : display_byte(exploratory_test_effectiveness[1]);
        31  : display_byte(exploratory_test_effectiveness[2]);
        32  : display_byte(exploratory_test_effectiveness[3]);
        33  : display_byte(exploratory_test_effectiveness[4]);
        34  : display_boolean(usable_for_extraction);
        35  : display_real(extraction_speed);
        36  : display_boolean(extractable);
        37  : display_real(typical_deposit_size);
        38  : display_byte(likelihood_of_occurence);
        39  : display_byte(deposit_contagion_ratio);
        40  : display_boolean(usable_for_development);
        41  : display_real(development_speed);
        42  : display_boolean(developable);
        43  : display_byte(development_result);
        44  : display_byte(start_resource_needed_to_develop);
        45  : display_byte(end_resource_needed_to_develop);
        46  : display_boolean(usable_for_refinement);
        47  : display_real(refinement_speed);
        48  : display_boolean(refineable);
        49  : display_byte(refinement_result);
        50  : display_byte(start_resource_needed_to_refine);
        51  : display_byte(end_resource_needed_to_refine);
        52  : display_boolean(usable_for_transportation);
        53  : display_real(cargo_capacity);
        54  : display_real(air_speed);
        55  : display_real(land_speed);
        56  : display_real(water_speed);
        57  : display_boolean(produceable);
        58  : display_integer(time_to_produce);
        59  : display_ingredient_list(production_requirements);
      END; (* case *)
    END; (* with *)
END;

(****************************************************************************)
(*** DISPLAY ONE VALUE : Basically the same as DISPLAY ONE ITEM, this     ***)
(*** procedure takes printer echoing into account.                        ***)
(****************************************************************************)

PROCEDURE display_one_value(resource_number,parameter_number:integer;
                             printer:boolean);
BEGIN
  CASE printer OF
    false : write(resources[resource_number].resource_name,': ',parameter_titles[parameter_number],' = ');
    true  : write(lst,parameter_titles[parameter_number],' =');
  END;
  display_one_item(resource_number,parameter_number,printer);
  CASE printer OF
    false : writeln;
    true  : writeln(lst);
  END;
END;

(****************************************************************************)
(*** PAGE HEADER : Written for a Toshiba p1340 printer, this procedure    ***)
(*** print the current resource title at the top of the page in double    ***)
(*** width.                                                               ***)
(****************************************************************************)

PROCEDURE page_header(resource_num : integer);
BEGIN
  write(lst,formfeed);
  write(lst,'               ');
  write(lst,escape,chr(33));
  write(lst,escape,chr(73));
  writeln(lst,'*** ',resources[resource_num].resource_name,' ***');
  write(lst,escape,chr(74));
  write(lst,escape,chr(34));
  writeln(lst);
  writeln(lst);
END;

(****************************************************************************)
(*** PRINT ONE RESOURCE : This is called from the main menu in order to   ***)
(*** print all parameters of one resource to the printer.                 ***)
(****************************************************************************)

PROCEDURE print_one_resource;
VAR
  resource_number : byte;
  param_number    : byte;
BEGIN
  REPEAT
    write('Resource number ?');
    resource_number:=0;
    get_byte(resource_number);
  UNTIL valid;

  IF resource_number<>0
    THEN
      BEGIN
        page_header(resource_number);
        FOR param_number:=1 to max_param DO
          display_one_value(resource_number,param_number,true);
      END;
END;

(****************************************************************************)
(*** PRINT ONE PARAMETER : This is called from the main menu in order to  ***)
(*** print out all the different values of one parameter across all of    ***)
(*** the resources.                                                       ***)
(****************************************************************************)

PROCEDURE print_one_parameter;
VAR
  resource_number : byte;
  param_number    : byte;
BEGIN
  REPEAT
    write('Parameter number ?');
    param_number:=0;
    get_byte(param_number);
  UNTIL valid;

  FOR resource_number:=1 to max_resource DO
    BEGIN
      IF resources[resource_number].resource_name<>invalid_resource
        THEN
          BEGIN
            write(lst,resources[resource_number].resource_name,' : ');
            display_one_value(resource_number,param_number,true);
          END;
    END;
END;

(****************************************************************************)
(*** PRINT ALL RESOURCES : This procedure will allow the user to make a   ***)
(*** final copy of any number of resources (within a range specified by   ***)
(*** the user).                                                           ***)
(****************************************************************************)

PROCEDURE print_all_resources;
VAR
  start_resource : byte;
  end_resource   : byte;
  param_number   : byte;
  resource_number: byte;
BEGIN
  REPEAT
    write('Starting resource number ?');
    start_resource:=0;
    get_byte(start_resource);
    writeln;
  UNTIL valid;

  REPEAT
    write('Ending resource number ?');
    end_resource:=0;
    get_byte(end_resource);
    writeln;
  UNTIL valid;

  IF (start_resource<>0) AND (end_resource<>0)
     AND (start_resource<=end_resource)
    THEN
      BEGIN
        write(lst,escape,'L06');   (* 8 lpi *)
        FOR resource_number:=start_resource TO end_resource DO
          BEGIN
            IF resources[resource_number].resource_name<>invalid_resource
              THEN
                BEGIN
                  page_header(resource_number);
                  FOR param_number :=1 to max_param DO
                    BEGIN
                      write(lst,'               ');
                      display_one_value(resource_number,param_number,true);
                    END;
                END;
          END;
        writeln(lst,escape,'L08');  (* 6 lpi *)
      END;
END;

(****************************************************************************)
(*** EDIT A VALUE : This procedure (and all of the little ones below it)  ***)
(*** allow the user to intelligently edit the data in the resources array ***)
(****************************************************************************)

PROCEDURE edit_a_value(resource_number,parameter_number:integer);

PROCEDURE get_string30(VAR result:string30);
VAR
  temp:text_line_type;
BEGIN
  readln(temp);
  IF temp=''
    THEN
      valid:=true;

  IF NOT abort_request(temp)
    THEN
      IF temp<>''
        THEN
          IF length(temp)<=30
            THEN
              BEGIN
                valid:=true;
                result:=temp;
              END;
END;

PROCEDURE get_string10(VAR result:string10);
VAR
  temp:text_line_type;
BEGIN
  readln(temp);
  IF temp=''
    THEN
      valid:=true;

  IF NOT abort_request(temp)
    THEN
      IF temp<>''
        THEN
          IF length(temp)<=10
            THEN
              BEGIN
                valid:=true;
                result:=temp;
              END;
END;

FUNCTION create_a_new_ingredient:ingredient_ptr;
VAR
  temp_ptr : ingredient_ptr;
BEGIN
  new(temp_ptr);
  temp_ptr^.next:=NIL;
  temp_ptr^.alternatives:=NIL;
  temp_ptr^.resource_num:=0;
  temp_ptr^.quantity:=0.0;
  temp_ptr^.time_factor:=1.0;
  create_a_new_ingredient:=temp_ptr;
END;

PROCEDURE get_ingredient_info(VAR ingredient : ingredient_ptr);
BEGIN
  WITH ingredient^ DO
    BEGIN
      REPEAT
        write('Resource #      ?');
        get_byte(resource_num);
      UNTIL valid;

      REPEAT
        write('Quantity        ?');
        get_real(quantity);
      UNTIL valid;

      REPEAT
        write('Time factor     ?');
        get_real(time_factor);
      UNTIL valid;

    END;
END;

PROCEDURE set_next_pointers(ingredient_list,destination:ingredient_ptr);
VAR
  temp_ptr:ingredient_ptr;
BEGIN
  temp_ptr:=ingredient_list;
  WHILE temp_ptr<>NIL DO
    BEGIN
      temp_ptr^.next:=destination;
      temp_ptr:=temp_ptr^.alternatives;
    END;
END;

PROCEDURE get_ingredient_list(VAR resource_list_ptr:ingredient_ptr);
VAR
  temp_ptr        : ingredient_ptr;
  last_ptr        : ingredient_ptr;
  key             : char;
  fkey            : boolean;
  first           : boolean;
  first_of_last_level : ingredient_ptr;

BEGIN
  first:=true;

  (* Since no editing of a resource list is supported,    *)
  (* kill the sucker and make them start over, inputting. *)
  resource_list_ptr:=NIL; (* note that this does not reclaim the memory *)
                          (* previously used by this list.              *)

  last_ptr:=NIL;
  first_of_last_level:=NIL;

  REPEAT
    REPEAT
      writeln;
      TextColor(White);
      write('C)ontinue at next level, A)dd an alternative, Q)uit tree entry');
      key:=get_key_with_clock(fkey);
      writeln(key);
      TextColor(Yellow);
      IF (first) AND (key IN ['a','A']) AND (NOT fkey)
        THEN
          BEGIN
            beep;
            key:='x';
          END;
    UNTIL (key IN ['c','C','a','A','q','Q']) AND (NOT fkey);

    CASE key OF
      'c','C'  : BEGIN
                   temp_ptr:=create_a_new_ingredient;

                   IF first
                     THEN
                       BEGIN
                         resource_list_ptr:=temp_ptr;
                         first:=false;
                       END;

                   IF first_of_last_level<>NIL
                     THEN
                       set_next_pointers(first_of_last_level,temp_ptr);

                   get_ingredient_info(temp_ptr);
                   last_ptr:=temp_ptr;
                   first_of_last_level:=temp_ptr;
                 END;
      'a','A'  : BEGIN
                   temp_ptr:=create_a_new_ingredient;
                   IF last_ptr<>NIL
                     THEN
                       last_ptr^.alternatives:=temp_ptr;
                   get_ingredient_info(temp_ptr);
                   last_ptr:=temp_ptr;
                 END;
      'q','Q'  : ;
    END;
  UNTIL key IN ['q','Q'];
END;

(****************************************************************************)
(*** EDIT ONE VALUE - MAINLINE CODE                                       ***)
(****************************************************************************)

BEGIN
  valid:=false;
  REPEAT
    write(resource_number:3,':',parameter_titles[parameter_number],' [');
    display_one_item(resource_number,parameter_number,false);
    write('] ?');
    WITH resources[resource_number] DO
      BEGIN
        CASE parameter_number OF
          1   : get_string30(resource_name);
          2   : get_string10(resource_units);
          3   : get_integer(score_value);
          4   : get_real(base_cost);
          5   : get_real(empty_weight);
          6   : get_boolean(naturally_occuring);
          7   : get_boolean(subsurface_resource);
          8   : get_boolean(expendable);
          9   : get_boolean(movable);
          10  : get_real(typical_trader_amount);
          11  : get_real(typical_purity);
          12  : get_byte(basic_resource_need[1]);
          13  : get_byte(basic_resource_need[2]);
          14  : get_byte(basic_resource_need[3]);
          15  : get_byte(basic_resource_need[4]);
          16  : get_real(basic_need_amount[1]);
          17  : get_real(basic_need_amount[2]);
          18  : get_real(basic_need_amount[3]);
          19  : get_real(basic_need_amount[4]);
          20  : get_byte(active_resource_need[1]);
          21  : get_byte(active_resource_need[2]);
          22  : get_byte(active_resource_need[3]);
          23  : get_byte(active_resource_need[4]);
          24  : get_real(active_need_amount[1]);
          25  : get_real(active_need_amount[2]);
          26  : get_real(active_need_amount[3]);
          27  : get_real(active_need_amount[4]);
          28  : get_boolean(usable_for_exploration);
          29  : get_real(exploration_speed);
          30  : get_byte(exploratory_test_effectiveness[1]);
          31  : get_byte(exploratory_test_effectiveness[2]);
          32  : get_byte(exploratory_test_effectiveness[3]);
          33  : get_byte(exploratory_test_effectiveness[4]);
          34  : get_boolean(usable_for_extraction);
          35  : get_real(extraction_speed);
          36  : get_boolean(extractable);
          37  : get_real(typical_deposit_size);
          38  : get_byte(likelihood_of_occurence);
          39  : get_byte(deposit_contagion_ratio);
          40  : get_boolean(usable_for_development);
          41  : get_real(development_speed);
          42  : get_boolean(developable);
          43  : get_byte(development_result);
          44  : get_byte(start_resource_needed_to_develop);
          45  : get_byte(end_resource_needed_to_develop);
          46  : get_boolean(usable_for_refinement);
          47  : get_real(refinement_speed);
          48  : get_boolean(refineable);
          49  : get_byte(refinement_result);
          50  : get_byte(start_resource_needed_to_refine);
          51  : get_byte(end_resource_needed_to_refine);
          52  : get_boolean(usable_for_transportation);
          53  : get_real(cargo_capacity);
          54  : get_real(air_speed);
          55  : get_real(land_speed);
          56  : get_real(water_speed);
          57  : get_boolean(produceable);
          58  : get_integer(time_to_produce);
          59  : get_ingredient_list(production_requirements);
        END; (* case *)
      END; (* with *)
  UNTIL (valid) OR (abort_action);
END;

(****************************************************************************)
(*** EDIT A PRODUCTION LIST : This procedure is very unfriendly in that   ***)
(*** it does not allow the editing of a production list, but merely the   ***)
(*** reentry of one.                                                      ***)
(****************************************************************************)

PROCEDURE edit_a_production_list;
VAR
  resource_number : byte;
  param_number    : byte;
BEGIN
  REPEAT
    write('Resource number ?');
    resource_number:=0;
    get_byte(resource_number);
  UNTIL (valid) OR (resource_number=0);

  IF resource_number<>0
    THEN
      BEGIN
        param_number:=max_param;
        edit_a_value(resource_number,param_number);
      END;
END;

(****************************************************************************)
(*** EDIT ONE ITEM : This procedure lets the user edit any single item    ***)
(*** in the database - they specify both row and column here.             ***)
(****************************************************************************)

PROCEDURE edit_one_item;
VAR
  resource_number : byte;
  param_number    : byte;
BEGIN
  REPEAT
    write('Resource number ?');
    resource_number:=0;
    get_byte(resource_number);
  UNTIL (valid) OR (resource_number=0);

  IF resource_number<>0
    THEN
      BEGIN
        REPEAT
          write('Parameter number ?');
          param_number:=0;
          get_byte(param_number);
        UNTIL (valid) OR (param_number=0);
        IF param_number<>0
          THEN
            edit_a_value(resource_number,param_number);
      END;
END;

(****************************************************************************)
(*** EDIT ONE RESOURCE : This lets the user edit all of the parameters    ***)
(*** that go along with one resource.                                     ***)
(****************************************************************************)

PROCEDURE edit_one_resource;
VAR
  resource_number : byte;
  param_number    : byte;
BEGIN
  REPEAT
    write('Resource number ?');
    resource_number:=0;
    get_byte(resource_number);
  UNTIL (valid) OR (resource_number=0);

  IF resource_number<>0
    THEN
      BEGIN
        param_number:=1;
        REPEAT
          edit_a_value(resource_number,param_number);
          param_number:=succ(param_number);
        UNTIL (abort_action) OR (param_number>(max_param-1));
      END;
END;

(****************************************************************************)
(*** EDIT ONE PARAMETER : This procedure prompts the user for all the     ***)
(*** different values a resource parameter takes on as it goes across all ***)
(*** of the possible resources.                                           ***)
(****************************************************************************)

PROCEDURE edit_one_parameter;
VAR
  resource_number : byte;
  param_number    : byte;
BEGIN
  REPEAT
    write('Parameter number ?');
    param_number:=0;
    get_byte(param_number);
  UNTIL (valid) OR (param_number=0);

  REPEAT
    resource_number:=1;
    write('Start with resource number [1.0]');
    get_byte(resource_number);
  UNTIL valid;

  IF param_number<>0
    THEN
      BEGIN
        REPEAT
          edit_a_value(resource_number,param_number);
          resource_number:=succ(resource_number);
        UNTIL (abort_action) OR (resource_number>max_resource);
      END;
END;

(****************************************************************************)
(*** INITIAL FILE READ : This procedure was added to keep slightly stupid ***)
(*** people from overwriting a good file with an almost empty one.  Thus, ***)
(*** the computer will strongly suggest to the user that they read in the ***)
(*** old resource file before starting editing.                           ***)
(****************************************************************************)

PROCEDURE initial_file_read;
VAR
  question : boolean;
BEGIN
  REPEAT
    question:=true;
    ClrScr;
    writeln('Program Initialization:');
    writeln;
    write('Do you wish to read the resource file from the disk [Yes] ?');
    get_boolean(question);
  UNTIL valid;

  IF question
    THEN
      BEGIN
        read_resource_file;
        file_read:=true;
      END;
END;

(*****************************************************************************)
(***  WORLDSHAKER - MAINLINE CODE                                        *****)
(*****************************************************************************)

BEGIN
  init_param_titles;
  file_read:=false;
  clear_all_resources;
  initial_file_read;

  REPEAT
    REPEAT
      ClrScr;
      writeln('World-Shaker Resource Modification utility');
      writeln;
      writeln('      F1   Throw out changes/reread file');
      writeln('      F2   Write out current file');
      writeln('      F3   Edit 1 parameter of 1 resource');
      writeln('      F4   Edit production list of 1 resource');
      writeln('      F5   Edit all parameters of 1 resource');
      writeln('      F6   Edit all values of a resource parameter');
      writeln('      F7   Print out all parameters of 1 resource');
      writeln('      F8   Print out all values of a resource parameter');
      writeln('      F9   Print out all resources');
      writeln('      F10  Create Surface resource matrix');
      writeln('      Q    Quit to Genesis (save is NOT automatic)');
      writeln;
      IF NOT file_read
        THEN
          BEGIN
            writeln('**** NO FILE IN MEMORY YET ****');
            writeln;
          END;
      write('Choice ?');
      choice:=get_key_with_clock(fkey);
      writeln;
      writeln;
    UNTIL ((choice IN [F1,F2,F3,F4,F5,F6,F7,F8,F9,F10]) and (fkey))
       OR ((choice IN ['q','Q']) and (NOT fkey));

    abort_action:=false;

    CASE choice OF
      F1      : BEGIN
                  read_resource_file;
                  file_read:=true;
                END;
      F2      : write_resource_file;
      F3      : edit_one_item;
      F4      : edit_a_production_list;
      F5      : edit_one_resource;
      F6      : edit_one_parameter;
      F7      : print_one_resource;
      F8      : print_one_parameter;
      F9      : print_all_resources;
      F10     : create_surface_resource_matrix;
      'q','Q' : ;
    END; (* CASE *)
  UNTIL (choice IN ['q','Q']) and (NOT fkey);

  ASSIGN(main_program,'STARFALL.COM');
  EXECUTE(main_program);
END.
